@echo off
setlocal
cd /d "%~dp0"
call config.bat
set "FRONTEND_DIR=%VANGUARD_APP_DIR%\frontend"
set "LOG=%~dp0logs\frontend.log"
if not exist "%~dp0logs" mkdir "%~dp0logs"
if exist "%LOG%" del /q "%LOG%"
echo [Vanguard Frontend] Starting at %DATE% %TIME%
echo Frontend folder: %FRONTEND_DIR%
if not exist "%FRONTEND_DIR%\node_modules\.bin\vite.cmd" (
  echo [ERROR] Vite is not installed in %FRONTEND_DIR%\node_modules
  goto :end
)
cd /d "%FRONTEND_DIR%"
call node_modules\.bin\vite.cmd --host 127.0.0.1 --port %VANGUARD_FRONTEND_PORT% --strictPort >> "%LOG%" 2>&1
echo.
echo [Vanguard Frontend] Process exited with code %ERRORLEVEL%.
echo Full output: %LOG%
:end
echo.
echo This window is intentionally left open so startup errors are visible.
pause
