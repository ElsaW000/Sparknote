@echo off
setlocal

set "TASK_NAME=Sparknote Backend"
set "STARTUP_BAT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Sparknote Backend Autostart.bat"

echo [Sparknote] Removing autostart task...
schtasks /Delete /F /TN "%TASK_NAME%"
if exist "%STARTUP_BAT%" del /f /q "%STARTUP_BAT%"

echo [Sparknote] Autostart removed.
exit /b 0
