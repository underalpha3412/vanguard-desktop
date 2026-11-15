@echo off
setlocal
cd /d "%~dp0"
call config.bat

if not exist "%VANGUARD_APP_DIR%\backend\.venv\Scripts\python.exe" (
  echo [ERROR] Vanguard is not installed. Run setup.bat first.
  pause
  exit /b 1
)
if not exist "%VANGUARD_APP_DIR%\frontend\node_modules" (
  echo [ERROR] Frontend dependencies are missing. Run setup.bat again.
  pause
  exit /b 1
)

echo Starting Vanguard backend...
start "Vanguard API" cmd /k "cd /d ""%VANGUARD_APP_DIR%\backend"" && .venv\Scripts\python.exe -m uvicorn ai_backend:app --host 127.0.0.1 --port %VANGUARD_BACKEND_PORT%"

echo Waiting for backend...
set /a tries=0
:wait_backend
set /a tries+=1
powershell -NoProfile -Command "try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:%VANGUARD_BACKEND_PORT%/health -TimeoutSec 2 ^| Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 goto backend_ready
if %tries% GEQ 30 (
  echo [WARNING] Backend did not respond yet. The frontend will still start.
  goto start_frontend
)
timeout /t 2 /nobreak >nul
goto wait_backend

:backend_ready
echo Backend is responding.

:start_frontend
echo Starting Vanguard dashboard...
start "Vanguard Dashboard" cmd /k "cd /d ""%VANGUARD_APP_DIR%\frontend"" && npm run dev -- --host 127.0.0.1"

timeout /t 4 /nobreak >nul
start "" "http://127.0.0.1:%VANGUARD_FRONTEND_PORT%"
echo Vanguard launch commands have been started.
