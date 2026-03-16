@echo off
setlocal

set "ROOT=%~dp0"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "CACHE_BUSTER=%%i"
set "URL=http://127.0.0.1:8000/?v=%CACHE_BUSTER%"

cd /d "%ROOT%"

echo [Sparknote] Checking local server...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $r = Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/health -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"
if %errorlevel%==0 (
  echo [Sparknote] Server already running.
  start "" "%URL%"
  exit /b 0
)

echo [Sparknote] Starting backend in dedicated window...
start "Sparknote Backend" cmd /k "cd /d %ROOT% && .\.venv\Scripts\python.exe -m uvicorn backend.main:app --host 127.0.0.1 --port 8000"

echo [Sparknote] Waiting for server health check...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ok = $false; for ($i = 0; $i -lt 25; $i++) { try { $r = Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/health -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ok = $true; break } } catch {}; Start-Sleep -Milliseconds 800 }; if ($ok) { exit 0 } else { exit 1 }"

if %errorlevel% neq 0 (
  echo [Sparknote] Failed to start local server.
  echo [Sparknote] Please check the "Sparknote Backend" window for errors.
  pause
  exit /b 1
)

echo [Sparknote] Ready: %URL%
start "" "%URL%"
exit /b 0
