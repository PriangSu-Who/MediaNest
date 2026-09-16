@echo off
setlocal
cd /d "%~dp0"
title MediaNest
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0MediaNest.ps1"
set "exitCode=%ERRORLEVEL%"
endlocal & exit /b %exitCode%
