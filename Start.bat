@echo off
cd /d "%~dp0"
start "" powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "%~dp0DotTraceUI.ps1"
exit
