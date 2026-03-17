@echo off
setlocal

set "ROOT=%~dp0"
set "TASK_NAME=Sparknote Backend"
set "PS_SCRIPT=%ROOT%run_sparknote_background.ps1"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "STARTUP_BAT=%STARTUP_DIR%\Sparknote Backend Autostart.bat"

echo [Sparknote] Registering autostart task...
schtasks /Create /F /SC ONLOGON /RL LIMITED /TN "%TASK_NAME%" /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%PS_SCRIPT%\""

if %errorlevel% neq 0 (
  echo [Sparknote] Task Scheduler registration failed, falling back to Startup folder...
  if not exist "%STARTUP_DIR%" mkdir "%STARTUP_DIR%"
  > "%STARTUP_BAT%" echo @echo off
  >> "%STARTUP_BAT%" echo powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
  if %errorlevel% neq 0 (
    echo [Sparknote] Failed to create Startup folder launcher.
    exit /b 1
  )
)

echo [Sparknote] Starting background backend once...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

if %errorlevel% neq 0 (
  echo [Sparknote] Background start failed. Please check:
  echo   %ROOT%\.tmp_backend.out.log
  echo   %ROOT%\.tmp_backend.err.log
  exit /b 1
)

echo [Sparknote] Autostart installed successfully.
exit /b 0
