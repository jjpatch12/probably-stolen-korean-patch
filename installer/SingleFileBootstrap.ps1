$ErrorActionPreference='Stop';[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false);$OutputEncoding=[Text.UTF8Encoding]::new($false)
$d=Join-Path ([IO.Path]::GetTempPath()) ('PSKR_SINGLE_'+[Guid]::NewGuid().ToString('N'))
try{
$s=[IO.File]::ReadAllText($env:PSKR_SELF,[Text.Encoding]::UTF8);$m="`r`n:__PSKR_DATA__`r`n";$i=$s.LastIndexOf($m,[StringComparison]::Ordinal)
if($i -lt 0){throw '패치 데이터가 없습니다.'}
$b=[Convert]::FromBase64String($s.Substring($i+$m.Length));[IO.Directory]::CreateDirectory($d)|Out-Null;$z=Join-Path $d 'payload.zip';[IO.File]::WriteAllBytes($z,$b)
Add-Type -AssemblyName System.IO.Compression.FileSystem;[IO.Compression.ZipFile]::ExtractToDirectory($z,$d)
Write-Host 'Probably Stolen 한국어 패치 1.0'
while($true){
$n=Read-Host '[1] 설치  [2] 원본 복원  [3] 안내/폰트 라이선스  [0] 종료 (기본 1)'
if($n -eq '0'){exit 0}
if($n -eq '3'){
foreach($f in @('README_KO.txt','licenses/neodgm-LICENSE.txt','licenses/notosanskr-OFL.txt')){Write-Host ([IO.File]::ReadAllText((Join-Path $d $f),[Text.Encoding]::UTF8))}
continue}
if($n -eq '' -or $n -eq '1' -or $n -eq '2'){break}
Write-Host '0~3 중에서 선택하세요.'
}
& (Join-Path $d 'tools/ApplyPatch.ps1') -GamePath $env:PSKR_TARGET -Restore:($n -eq '2')
exit $LASTEXITCODE
}catch{Write-Host ('오류: '+$_.Exception.Message) -ForegroundColor Red;exit 1}
finally{
$base=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\';$p=[IO.Path]::GetFullPath($d)
if($p.StartsWith($base,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $p).StartsWith('PSKR_SINGLE_') -and (Test-Path -LiteralPath $p)){Remove-Item -LiteralPath $p -Recurse -Force}
}
