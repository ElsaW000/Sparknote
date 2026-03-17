$ErrorActionPreference = "SilentlyContinue"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root ".tmp_backend.pid"
$outLog = Join-Path $root ".tmp_backend.out.log"
$errLog = Join-Path $root ".tmp_backend.err.log"
$pythonExe = Join-Path $root ".\.venv\Scripts\python.exe"

function Test-SparknoteHealth {
  try {
    $response = Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/health -TimeoutSec 2
    return $response.StatusCode -eq 200
  } catch {
    return $false
  }
}

if (Test-SparknoteHealth) {
  exit 0
}

if (Test-Path $pidFile) {
  try {
    $existingPid = Get-Content $pidFile | Select-Object -First 1
    if ($existingPid) {
      Stop-Process -Id ([int]$existingPid) -Force -ErrorAction SilentlyContinue
    }
  } catch {}
  Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $pythonExe)) {
  exit 1
}

if (Test-Path $outLog) {
  Remove-Item $outLog -Force -ErrorAction SilentlyContinue
}
if (Test-Path $errLog) {
  Remove-Item $errLog -Force -ErrorAction SilentlyContinue
}

$proc = Start-Process `
  -FilePath $pythonExe `
  -ArgumentList "-m", "uvicorn", "backend.main:app", "--host", "127.0.0.1", "--port", "8000" `
  -WorkingDirectory $root `
  -WindowStyle Hidden `
  -RedirectStandardOutput $outLog `
  -RedirectStandardError $errLog `
  -PassThru

Set-Content -Path $pidFile -Value $proc.Id

for ($i = 0; $i -lt 25; $i++) {
  if (Test-SparknoteHealth) {
    exit 0
  }
  Start-Sleep -Milliseconds 800
}

exit 1
