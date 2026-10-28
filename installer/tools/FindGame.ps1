function Find-PSGame {
    param([string]$GamePath='', [string]$BatPath='', [string]$WorkingDirectory='',
          [string[]]$SearchRoots=@(), [string[]]$SteamRoots=@(),
          [bool]$UseSystemLocations=$true, [switch]$NonInteractive)
    function IsGame([string]$Path) {
        return ($Path -and (Test-Path -LiteralPath (Join-Path $Path 'Probably Stolen.exe') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $Path 'Probably Stolen_Data') -PathType Container))
    }
    function NormalizeGame([string]$Path) {
        if (!$Path) { return $null }
        try {
            $p=[IO.Path]::GetFullPath($Path.Trim('"'))
            if ($p.Length -gt ([IO.Path]::GetPathRoot($p)).Length) { $p=$p.TrimEnd('\','/') }
            if (Test-Path -LiteralPath $p -PathType Leaf) {
                if ([IO.Path]::GetFileName($p) -ine 'Probably Stolen.exe') { return $null }
                $p=Split-Path -Parent $p
            }
            if (IsGame $p) { return $p }
            if ((Split-Path -Leaf $p) -ieq 'Probably Stolen_Data') {
                $p=Split-Path -Parent $p
                if (IsGame $p) { return $p }
            }
        } catch { return $null }
        return $null
    }
    if ($GamePath) {
        $explicit=NormalizeGame $GamePath
        if (!$explicit) { throw '지정한 위치에 Probably Stolen.exe와 Data 폴더가 없습니다.' }
        Write-Host ('게임 경로: '+$explicit)
        return $explicit
    }
    # The original BAT location is authoritative; extraction/temp folders are never searched.
    if ($BatPath) {
        $nearby=Split-Path -Parent ([IO.Path]::GetFullPath($BatPath))
        for ($level=0;$level -lt 3 -and $nearby;$level++) {
            $local=NormalizeGame $nearby
            if ($local) { Write-Host ('게임 자동 인식: '+$local); return $local }
            $parent=Split-Path -Parent $nearby
            if ($parent -eq $nearby) { break }; $nearby=$parent
        }
    }
    if (!$WorkingDirectory) { $WorkingDirectory=(Get-Location).Path }
    $working=NormalizeGame $WorkingDirectory
    if ($working) { Write-Host ('게임 자동 인식: '+$working); return $working }
    $found=New-Object 'System.Collections.Generic.List[string]'
    $seen=@{}
    function AddGame([string]$Path) {
        $valid=NormalizeGame $Path
        if ($valid -and !$seen.ContainsKey($valid)) { $seen[$valid]=$true; [void]$found.Add($valid) }
    }
    function ScanChildren([string]$Root) {
        if (!$Root -or !(Test-Path -LiteralPath $Root -PathType Container)) { return }
        AddGame $Root
        foreach ($dir in @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue)) { AddGame $dir.FullName }
    }
    $roots=New-Object 'System.Collections.Generic.List[string]'
    foreach ($r in $SearchRoots) { if ($r) { [void]$roots.Add($r) } }
    $steam=New-Object 'System.Collections.Generic.List[string]'
    foreach ($r in $SteamRoots) { if ($r) { [void]$steam.Add($r) } }
    if ($BatPath) { [void]$roots.Add((Split-Path -Parent ([IO.Path]::GetFullPath($BatPath)))) }
    if ($UseSystemLocations) {
        foreach ($folder in @([Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('MyDocuments'))) {
            if ($folder) { [void]$roots.Add($folder) }
        }
        if ($env:USERPROFILE) {
            foreach ($leaf in @('Desktop','Downloads','Games')) { [void]$roots.Add((Join-Path $env:USERPROFILE $leaf)) }
        }
        $pf86=[Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
        if ($pf86) { [void]$steam.Add((Join-Path $pf86 'Steam')) }
        if ($env:ProgramFiles) { [void]$steam.Add((Join-Path $env:ProgramFiles 'Steam')) }
        foreach ($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
            $values=Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
            if ($values) {
                foreach ($name in @('SteamPath','InstallPath')) {
                    $property=$values.PSObject.Properties[$name]
                    if ($property -and $property.Value) { [void]$steam.Add([string]$property.Value) }
                }
            }
        }
        foreach ($base in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) {
            foreach ($key in @(Get-ChildItem -LiteralPath $base -ErrorAction SilentlyContinue)) {
                $v=Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction SilentlyContinue
                if (!$v) { continue }
                $title=$v.PSObject.Properties['DisplayName']; $location=$v.PSObject.Properties['InstallLocation']
                if ($title -and $location -and $title.Value -like '*Probably Stolen*') { AddGame ([string]$location.Value) }
            }
        }
    }
    foreach ($root in $roots) { ScanChildren $root }
    $libraries=New-Object 'System.Collections.Generic.List[string]'; $librarySeen=@{}
    foreach ($root in $steam) {
        if (!$root -or !(Test-Path -LiteralPath $root -PathType Container)) { continue }
        if (!$librarySeen.ContainsKey($root)) { $librarySeen[$root]=$true; [void]$libraries.Add($root) }
        $vdf=Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf -PathType Leaf) {
            $text=[IO.File]::ReadAllText($vdf)
            foreach ($match in [regex]::Matches($text,'"(?:path|\d+)"\s*"([^"\r\n]+)"')) {
                $path=$match.Groups[1].Value.Replace('\\','\')
                if ([IO.Path]::IsPathRooted($path) -and !$librarySeen.ContainsKey($path)) {
                    $librarySeen[$path]=$true; [void]$libraries.Add($path)
                }
            }
        }
    }
    foreach ($library in $libraries) { ScanChildren (Join-Path $library 'steamapps\common') }
    if ($found.Count -eq 1) { Write-Host ('게임 자동 인식: '+$found[0]); return $found[0] }
    if ($found.Count -gt 1) {
        if ($NonInteractive) { throw '게임 설치가 여러 곳에서 발견됐습니다. 경로를 지정하세요.' }
        Write-Host '게임이 여러 곳에서 발견됐습니다. 적용할 위치를 선택하세요.'
        for ($i=0;$i -lt $found.Count;$i++) { Write-Host (('  [{0}] {1}' -f ($i+1),$found[$i])) }
        while ($true) {
            $choice=Read-Host '번호 (0: 취소)'; $number=0
            if ([int]::TryParse($choice,[ref]$number)) {
                if ($number -eq 0) { throw '게임 선택을 취소했습니다.' }
                if ($number -gt 0 -and $number -le $found.Count) { return $found[$number-1] }
            }
        }
    }
    if ($NonInteractive) { throw '게임을 자동으로 찾지 못했습니다.' }
    Write-Host '게임을 자동으로 찾지 못했습니다. 설치 폴더를 한 번 선택하세요.'
    Add-Type -AssemblyName System.Windows.Forms
    $dialog=New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description='Probably Stolen.exe가 있는 게임 폴더를 선택하세요.'; $dialog.ShowNewFolderButton=$false
    if ($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw '폴더 선택을 취소했습니다.' }
    $selected=NormalizeGame $dialog.SelectedPath
    if (!$selected) { throw '선택한 폴더에 Probably Stolen.exe와 Data 폴더가 없습니다.' }
    return $selected
}
