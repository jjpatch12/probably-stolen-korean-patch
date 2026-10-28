@echo off
setlocal DisableDelayedExpansion
chcp 65001 >nul
title Probably Stolen Korean Patch
if "%~1"=="" (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\ApplyPatch.ps1" -Restore
) else (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\ApplyPatch.ps1" -GamePath "%~1" -Restore
)
set "patch_result=%errorlevel%"
echo.
pause
exit /b %patch_result%
