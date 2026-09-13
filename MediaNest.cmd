@echo off
setlocal
cd /d "%~dp0"
title MediaNest
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0MediaNest.ps1"
if errorlevel 1 (
  echo.
  echo MediaNest closed because of an error.
  pause
)
endlocal
