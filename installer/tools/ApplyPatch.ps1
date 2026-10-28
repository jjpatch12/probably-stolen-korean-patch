param([string]$GamePath='', [switch]$Restore, [switch]$NonInteractive)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$PackageRoot=Split-Path -Parent $PSScriptRoot
function Hash([string]$Path) {
    $stream=[IO.File]::OpenRead($Path); $algorithm=[Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $algorithm.Dispose(); $stream.Dispose() }
}
function SaveJson($Value,[string]$Path) { $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8 }
function Within([string]$Root,[string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative)) { throw 'Absolute manifest path rejected.' }
    $base=[IO.Path]::GetFullPath($Root).TrimEnd('\')+'\'
    $path=[IO.Path]::GetFullPath((Join-Path $base $Relative))
    if (!$path.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { throw 'Path escapes game/package folder.' }
    return $path
}
function GameFolder {
    if (!$GamePath) {
        foreach ($candidate in @($PackageRoot,(Split-Path -Parent $PackageRoot))) {
            if (Test-Path -LiteralPath (Join-Path $candidate 'Probably Stolen.exe')) { return $candidate }
        }
        if ($NonInteractive) { throw 'GamePath is required.' }
        Add-Type -AssemblyName System.Windows.Forms
        $dialog=New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description='Probably Stolen.exe가 있는 게임 폴더를 선택하세요.'
        $dialog.ShowNewFolderButton=$false
        if ($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw '폴더 선택을 취소했습니다.' }
        return $dialog.SelectedPath
    }
    return (Resolve-Path -LiteralPath $GamePath).Path
}
function EnsureStopped {
    if (Get-Process -Name 'Probably Stolen' -ErrorAction SilentlyContinue) { throw '게임을 종료한 뒤 다시 실행하세요.' }
}
function RemoveWork([string]$Path) {
    if (!$Path) { return }
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    $resolved=[IO.Path]::GetFullPath($Path)
    if (!$resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or !(Split-Path -Leaf $resolved).StartsWith('PSKR_')) { throw 'Invalid temporary cleanup path.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
$workPath=$null
try {
    $game=GameFolder
    if (!(Test-Path -LiteralPath (Join-Path $game 'Probably Stolen.exe')) -or !(Test-Path -LiteralPath (Join-Path $game 'Probably Stolen_Data'))) { throw 'Probably Stolen.exe와 Data 폴더가 있는 위치를 선택하세요.' }
    EnsureStopped
    $backupRoot=Within $game 'PSKorean_Backup'
    $latestPath=Within $backupRoot 'latest.json'
    if ($Restore) {
        if (!(Test-Path -LiteralPath $latestPath)) { throw '이 설치기로 만든 복원 기록이 없습니다.' }
        $latest=Get-Content -LiteralPath $latestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $snapshot=Within $backupRoot $latest.folder
        $state=Get-Content -LiteralPath (Join-Path $snapshot 'state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($state.status -eq 'restored') { Write-Host '이미 복원했습니다.'; exit 0 }
        if ($state.status -ne 'installed') { throw '완료된 설치 기록이 아닙니다. backup 폴더의 원본을 확인하세요.' }
        foreach ($entry in $state.files) {
            $dest=Within $game $entry.path
            if (!(Test-Path -LiteralPath $dest) -or (Hash $dest) -ne $entry.installed_sha256) { throw "설치 후 변경된 파일이 있어 복원을 중단했습니다: $($entry.path)" }
            if ($entry.existed) {
                $saved=Within $snapshot $entry.path
                if ((Hash $saved) -ne $entry.original_sha256) { throw "백업 해시 불일치: $($entry.path)" }
            }
        }
        $workPath=Join-Path ([IO.Path]::GetTempPath()) ('PSKR_'+[Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $workPath | Out-Null
        foreach ($entry in $state.files) {
            $dest=Within $game $entry.path; $copy=Within $workPath $entry.path
            New-Item -ItemType Directory -Path (Split-Path -Parent $copy) -Force | Out-Null
            Copy-Item -LiteralPath $dest -Destination $copy
        }
        try {
            EnsureStopped
            foreach ($entry in $state.files) {
                $dest=Within $game $entry.path
                if ($entry.existed) { Copy-Item -LiteralPath (Within $snapshot $entry.path) -Destination $dest -Force; if ((Hash $dest) -ne $entry.original_sha256) { throw 'Restored file checksum mismatch.' } }
                else { Remove-Item -LiteralPath $dest -Force }
            }
        } catch {
            foreach ($entry in $state.files) { Copy-Item -LiteralPath (Within $workPath $entry.path) -Destination (Within $game $entry.path) -Force }
            throw
        }
        $state.status='restored'; SaveJson $state (Join-Path $snapshot 'state.json')
        Write-Host '원본 복원 완료. 세이브와 게임 설정은 변경하지 않았습니다.' -ForegroundColor Green
        exit 0
    }
    $manifest=Get-Content -LiteralPath (Join-Path $PackageRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $pending=@()
    foreach ($entry in $manifest.files) {
        $dest=Within $game $entry.path
        $exists=Test-Path -LiteralPath $dest -PathType Leaf
        $current=if ($exists) { Hash $dest } else { '' }
        if ($current -eq $entry.target_sha256) { continue }
        if (($entry.source_sha256 -and (!$exists -or $current -ne $entry.source_sha256)) -or (!$entry.source_sha256 -and $exists)) { throw "지원하는 원본과 다른 파일입니다. 원본 복구 후 설치하세요: $($entry.path)" }
        $patch=Within $PackageRoot $entry.patch
        if (!(Test-Path -LiteralPath $patch) -or (Hash $patch) -ne $entry.patch_sha256) { throw "패치 파일 손상: $($entry.patch)" }
        $pending+=,$entry
    }
    if (!$pending.Count) { Write-Host '이미 최신 한국어 패치가 적용되어 있습니다.' -ForegroundColor Green; exit 0 }
    foreach ($dep in $manifest.dependencies) {
        $path=Within $game $dep.path
        if (!(Test-Path -LiteralPath $path) -or (Hash $path) -ne $dep.sha256) { throw "지원하는 게임 원본 버전이 아닙니다: $($dep.path)" }
    }
    Add-Type -Path (Join-Path $PSScriptRoot 'PatchEngine.cs')
    $workPath=Join-Path ([IO.Path]::GetTempPath()) ('PSKR_'+[Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $workPath | Out-Null
    foreach ($entry in $pending) {
        Write-Host ('패치 생성: '+$entry.path)
        $dest=Within $game $entry.path; $staged=Within $workPath $entry.path
        New-Item -ItemType Directory -Path (Split-Path -Parent $staged) -Force | Out-Null
        $source=if ($entry.source_sha256) { $dest } else { $null }
        [PSKoreanDelta]::Apply($source,(Within $PackageRoot $entry.patch),$staged)
        if ((Hash $staged) -ne $entry.target_sha256) { throw "패치 생성 검증 실패: $($entry.path)" }
    }
    EnsureStopped
    # Recheck originals after all patched outputs have been prepared.
    foreach ($entry in $pending) {
        $dest=Within $game $entry.path
        if ($entry.source_sha256) { if ((Hash $dest) -ne $entry.source_sha256) { throw '원본 파일이 설치 준비 도중 변경됐습니다.' } }
        elseif (Test-Path -LiteralPath $dest) { throw '설치 대상이 준비 도중 생성됐습니다.' }
    }
    $folder=(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)
    $snapshot=Within $backupRoot $folder
    New-Item -ItemType Directory -Path $snapshot -Force | Out-Null
    $state=[pscustomobject]@{status='prepared';version=$manifest.version;files=@()}
    foreach ($entry in $pending) {
        $dest=Within $game $entry.path; $exists=Test-Path -LiteralPath $dest
        if ($exists) {
            $saved=Within $snapshot $entry.path
            New-Item -ItemType Directory -Path (Split-Path -Parent $saved) -Force | Out-Null
            Copy-Item -LiteralPath $dest -Destination $saved
            if ((Hash $saved) -ne $entry.source_sha256) { throw '백업 검증 실패.' }
        }
        $state.files+=,[pscustomobject]@{path=$entry.path;existed=$exists;original_sha256=$entry.source_sha256;installed_sha256=$entry.target_sha256}
    }
    SaveJson $state (Join-Path $snapshot 'state.json')
    try {
        foreach ($entry in $pending) {
            $dest=Within $game $entry.path
            New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
            Copy-Item -LiteralPath (Within $workPath $entry.path) -Destination $dest -Force
            if ((Hash $dest) -ne $entry.target_sha256) { throw '설치 후 파일 검증 실패.' }
        }
        $state.status='installed'; SaveJson $state (Join-Path $snapshot 'state.json')
        SaveJson ([pscustomobject]@{folder=$folder}) $latestPath
    } catch {
        foreach ($entry in $state.files) {
            $dest=Within $game $entry.path
            if ($entry.existed) { Copy-Item -LiteralPath (Within $snapshot $entry.path) -Destination $dest -Force }
            elseif (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
        }
        $state.status='rolled_back'; SaveJson $state (Join-Path $snapshot 'state.json')
        throw
    }
    Write-Host '한국어 패치 설치 완료! 게임 언어를 English로 설정하세요.' -ForegroundColor Green
    Write-Host ('원본 백업: '+$snapshot)
    Write-Host '복원은 같은 BAT를 다시 실행하고 [2] 원본 복원을 선택하세요.'
    exit 0
} catch {
    Write-Host ('오류: '+$_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    if ($workPath) { RemoveWork $workPath }
}
