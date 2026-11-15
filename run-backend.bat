@echo off
setlocal
cd /d "%~dp0"
call config.bat
set "BACKEND_DIR=%VANGUARD_APP_DIR%\backend"
set "PYTHON=%BACKEND_DIR%\.venv\Scripts\python.exe"
set "LOG=%~dp0logs\backend.log"
if not exist "%~dp0logs" mkdir "%~dp0logs"
if exist "%LOG%" del /q "%LOG%"
echo [Vanguard Backend] Starting at %DATE% %TIME%
echo Backend folder: %BACKEND_DIR%
if not exist "%PYTHON%" (
  echo [ERROR] Python virtual environment not found: %PYTHON%
  goto :end
)
if not exist "%BACKEND_DIR%\ai_backend.py" (
  echo [ERROR] ai_backend.py not found in %BACKEND_DIR%
  goto :end
)
cd /d "%BACKEND_DIR%"
"%PYTHON%" -m uvicorn ai_backend:app --env-file .env --host 127.0.0.1 --port %VANGUARD_BACKEND_PORT% >> "%LOG%" 2>&1
echo.
echo [Vanguard Backend] Process exited with code %ERRORLEVEL%.
echo Full output: %LOG%
:end
echo.
echo This window is intentionally left open so startup errors are visible.
pause
