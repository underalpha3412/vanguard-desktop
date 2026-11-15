@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call config.bat

echo.
echo  ============================================================
echo                    TEAM VANGUARD
echo                  STARTING DASHBOARD
echo  ============================================================
echo.

if not exist "%~dp0logs" mkdir "%~dp0logs"

rem Do not run installation checks here. Reuse healthy services first.
call "%~dp0start-services.bat"
if errorlevel 1 (
  echo.
  echo  ============================================================
  echo       VANGUARD COULD NOT START
  echo       If this is a first-time install, run setup.bat.
  echo       See logs\backend.log and logs\frontend.log.
  echo  ============================================================
  echo.
  pause
  exit /b 1
)
exit /b 0
