@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call config.bat

set "BACKEND_DIR=%VANGUARD_APP_DIR%\backend"
set "FRONTEND_DIR=%VANGUARD_APP_DIR%\frontend"
set "PYTHON=%BACKEND_DIR%\.venv\Scripts\python.exe"
set "BACKEND_RUNNING=0"
set "FRONTEND_RUNNING=0"

if not exist "%~dp0logs" mkdir "%~dp0logs"

echo       Checking existing Vanguard services...

rem Probe backend health before checking any local Python files.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try{$r=Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:%VANGUARD_BACKEND_PORT%/health' -TimeoutSec 2; if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){exit 0}else{exit 1}}catch{exit 1}" >nul 2>&1
if not errorlevel 1 (
  set "BACKEND_RUNNING=1"
  echo       Backend is already healthy. Reusing it.
)

rem Probe frontend before checking node_modules or Vite.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try{$r=Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:%VANGUARD_FRONTEND_PORT%/' -TimeoutSec 2; if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){exit 0}else{exit 1}}catch{exit 1}" >nul 2>&1
if not errorlevel 1 (
  set "FRONTEND_RUNNING=1"
  echo       Frontend is already healthy. Reusing it.
)

rem Start backend only when its health endpoint is not responding.
if "%BACKEND_RUNNING%"=="0" (
  echo       Backend is stopped. Preparing backend startup...
  if not exist "%PYTHON%" (
    echo [ERROR] Backend Python environment is missing. Run setup.bat to repair it.
    exit /b 1
  )
  if not exist "%BACKEND_DIR%\ai_backend.py" (
    echo [ERROR] Backend source is missing. Run setup.bat.
    exit /b 1
  )
  if not exist "%BACKEND_DIR%\.env" (
    echo [ERROR] backend\.env is missing. Run setup.bat to enter your NVIDIA API key.
    exit /b 1
  )
  "%PYTHON%" -c "from dotenv import dotenv_values; import sys; d=dotenv_values(r'%BACKEND_DIR%\.env'); sys.exit(0 if (d.get('NVIDIA_API_KEY') or '').strip() and (d.get('NVIDIA_MODEL') or '').strip() else 1)" >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] NVIDIA API key or model is missing. Run setup.bat to repair configuration.
    exit /b 1
  )
  start "Vanguard Backend" /min "%ComSpec%" /k ""%~dp0run-backend.bat""
)

rem Start frontend only when its HTTP server is not responding.
if "%FRONTEND_RUNNING%"=="0" (
  echo       Frontend is stopped. Preparing frontend startup...
  if not exist "%FRONTEND_DIR%\node_modules\.bin\vite.cmd" (
    echo [ERROR] Vite dependencies are missing. Run setup.bat to repair them.
    exit /b 1
  )
  start "Vanguard Frontend" /min "%ComSpec%" /k ""%~dp0run-frontend.bat""
)

echo       Waiting for required services...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0wait-for-services.ps1" -BackendPort %VANGUARD_BACKEND_PORT% -FrontendPort %VANGUARD_FRONTEND_PORT% -TimeoutSeconds 90
if errorlevel 1 (
  echo [ERROR] A service did not become ready.
  echo Check logs\backend.log and logs\frontend.log.
  exit /b 1
)

start "" "http://127.0.0.1:%VANGUARD_FRONTEND_PORT%"
echo.
echo  ============================================================
echo       VANGUARD IS RUNNING
echo       Dashboard: http://127.0.0.1:%VANGUARD_FRONTEND_PORT%
echo  ============================================================
exit /b 0
