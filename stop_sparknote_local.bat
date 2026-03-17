@echo off
setlocal

set "ROOT=%~dp0"
set "PIDFILE=%ROOT%\.tmp_backend.pid"

echo Stopping Sparknote local backend...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pidFile = '%PIDFILE%'; if (Test-Path $pidFile) { try { $pid = Get-Content $pidFile | Select-Object -First 1; if ($pid) { Stop-Process -Id ([int]$pid) -Force -ErrorAction SilentlyContinue } } catch {}; Remove-Item $pidFile -Force -ErrorAction SilentlyContinue }"

echo Done.
exit /b 0
