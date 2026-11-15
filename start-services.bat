@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call config.bat
set "BACKEND_DIR=%VANGUARD_APP_DIR%\backend"
set "FRONTEND_DIR=%VANGUARD_APP_DIR%\frontend"
set "PYTHON=%BACKEND_DIR%\.venv\Scripts\python.exe"

if not exist "%BACKEND_DIR%\.env" (
    echo [ERROR] backend\.env is missing. Run launch.bat to configure the NVIDIA API key.
    exit /b 1
)
"%PYTHON%" -c "from dotenv import dotenv_values; import sys; d=dotenv_values(r'%BACKEND_DIR%\.env'); sys.exit(0 if (d.get('NVIDIA_API_KEY') or '').strip() and (d.get('NVIDIA_MODEL') or '').strip() else 1)" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] NVIDIA API key or model is missing from backend\.env.
    exit /b 1
)
if not exist "%FRONTEND_DIR%\node_modules\vite\bin\vite.js" (
    echo [ERROR] Frontend Vite dependency is missing.
    exit /b 1
)

rem Start only services that are not already listening.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$bp=%VANGUARD_BACKEND_PORT%; $fp=%VANGUARD_FRONTEND_PORT%; $b=Test-NetConnection 127.0.0.1 -Port $bp -InformationLevel Quiet; $f=Test-NetConnection 127.0.0.1 -Port $fp -InformationLevel Quiet; if(-not $b){Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','cd /d ""%BACKEND_DIR%"" ^&^& .venv\Scripts\python.exe -m uvicorn ai_backend:app --env-file .env --host 127.0.0.1 --port %VANGUARD_BACKEND_PORT%' -WindowStyle Minimized}; if(-not $f){Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','cd /d ""%FRONTEND_DIR%"" ^&^& node_modules\.bin\vite.cmd --host 127.0.0.1 --port %VANGUARD_FRONTEND_PORT% --strictPort' -WindowStyle Minimized}"
if errorlevel 1 exit /b 1

echo       Waiting for backend and frontend...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0wait-for-services.ps1" -BackendPort %VANGUARD_BACKEND_PORT% -FrontendPort %VANGUARD_FRONTEND_PORT% -TimeoutSeconds 90
if errorlevel 1 (
    echo [ERROR] A service did not become ready. Check its minimized terminal window.
    exit /b 1
)
start "" "http://127.0.0.1:%VANGUARD_FRONTEND_PORT%"
echo.
echo  ============================================================
echo       VANGUARD IS RUNNING
echo       Dashboard: http://127.0.0.1:%VANGUARD_FRONTEND_PORT%
echo  ============================================================
exit /b 0
