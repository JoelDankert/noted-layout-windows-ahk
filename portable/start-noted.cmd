@echo off
setlocal
set "BASE=%~dp0.."
if exist "%BASE%\neo20-noted.exe" (
  start "" "%BASE%\neo20-noted.exe" noted
  exit /b 0
)
if not exist "%BASE%\runtime\AutoHotkeyU64.exe" (
  echo Portable AutoHotkeyU64.exe fehlt in runtime\.
  pause
  exit /b 1
)
start "" "%BASE%\runtime\AutoHotkeyU64.exe" "%BASE%\neo-ahk\neo20-all.ahk" noted
