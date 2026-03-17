@echo off
setlocal

set "ROOT=%~dp0"
set "PIDFILE=%ROOT%\.tmp_backend.pid"
set "OUTLOG=%ROOT%\.tmp_backend.out.log"
set "ERRLOG=%ROOT%\.tmp_backend.err.log"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "CACHE_BUSTER=%%i"
set "URL=http://127.0.0.1:8000/?v=%CACHE_BUSTER%"

cd /d "%ROOT%"

echo [Sparknote] Checking local server...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $r = Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/health -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"
if %errorlevel%==0 (
  echo [Sparknote] Server already running.
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Start-Process '%URL%' -ErrorAction Stop | Out-Null } catch {}"
  exit /b 0
)

echo [Sparknote] Cleaning previous backend instances...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pidFile = '%PIDFILE%'; if (Test-Path $pidFile) { try { $pid = Get-Content $pidFile | Select-Object -First 1; if ($pid) { Stop-Process -Id ([int]$pid) -Force -ErrorAction SilentlyContinue } } catch {}; Remove-Item $pidFile -Force -ErrorAction SilentlyContinue }"

echo [Sparknote] Starting backend in hidden singleton mode...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$root = '%ROOT%'; $outLog = '%OUTLOG%'; $errLog = '%ERRLOG%'; $pidFile = '%PIDFILE%'; if (Test-Path $outLog) { Remove-Item $outLog -Force -ErrorAction SilentlyContinue }; if (Test-Path $errLog) { Remove-Item $errLog -Force -ErrorAction SilentlyContinue }; $proc = Start-Process -FilePath (Join-Path $root '.\.venv\Scripts\python.exe') -ArgumentList '-m','uvicorn','backend.main:app','--host','127.0.0.1','--port','8000' -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru; Set-Content -Path $pidFile -Value $proc.Id"

echo [Sparknote] Waiting for server health check...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ok = $false; for ($i = 0; $i -lt 25; $i++) { try { $r = Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/health -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ok = $true; break } } catch {}; Start-Sleep -Milliseconds 800 }; if ($ok) { exit 0 } else { exit 1 }"

if %errorlevel% neq 0 (
  echo [Sparknote] Failed to start local server.
  echo [Sparknote] Please check logs:
  echo   %OUTLOG%
  echo   %ERRLOG%
  pause
  exit /b 1
)

echo [Sparknote] Ready: %URL%
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Start-Process '%URL%' -ErrorAction Stop | Out-Null } catch {}"
exit /b 0
