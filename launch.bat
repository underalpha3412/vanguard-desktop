@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call config.bat

set "BACKEND_DIR=%VANGUARD_APP_DIR%\backend"
set "FRONTEND_DIR=%VANGUARD_APP_DIR%\frontend"

if not exist "%BACKEND_DIR%\.venv\Scripts\python.exe" (
    echo [ERROR] Vanguard is not installed. Run setup.bat first.
    pause
    exit /b 1
)
if not exist "%FRONTEND_DIR%\node_modules\vite\bin\vite.js" (
    echo [ERROR] Frontend packages are missing. Run setup.bat first.
    pause
    exit /b 1
)

echo.
echo  ============================================================
echo                    TEAM VANGUARD
echo                    STARTING DASHBOARD
echo  ============================================================
echo.
echo [1/3] Starting backend and frontend together...

rem Start both processes in parallel. Do not wait for the API before starting Vite.
start "Vanguard API" /min cmd /c "cd /d ""%BACKEND_DIR%"" && .venv\Scripts\python.exe -m uvicorn ai_backend:app --host 127.0.0.1 --port %VANGUARD_BACKEND_PORT%"
start "Vanguard Dashboard" /min cmd /c "cd /d ""%FRONTEND_DIR%"" && node_modules\.bin\vite.cmd --host 127.0.0.1 --port %VANGUARD_FRONTEND_PORT% --strictPort"

echo [2/3] Waiting for both services to become ready...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0wait-for-services.ps1" -BackendPort %VANGUARD_BACKEND_PORT% -FrontendPort %VANGUARD_FRONTEND_PORT% -TimeoutSeconds 90
if errorlevel 1 (
    echo.
    echo [WARNING] Startup is taking longer than expected.
    echo Check the minimized Vanguard API and Dashboard windows for errors.
    echo You can still open http://127.0.0.1:%VANGUARD_FRONTEND_PORT% manually.
    pause
    exit /b 1
)

echo [3/3] Opening dashboard...
start "" "http://127.0.0.1:%VANGUARD_FRONTEND_PORT%"
echo.
echo  ============================================================
echo       VANGUARD IS RUNNING
echo       Dashboard: http://127.0.0.1:%VANGUARD_FRONTEND_PORT%
echo       Backend:   http://127.0.0.1:%VANGUARD_BACKEND_PORT%
echo  ============================================================
echo.
