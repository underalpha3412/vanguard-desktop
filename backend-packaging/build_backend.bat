@echo off
setlocal
set "ROOT=%~dp0.."
set "APP=%ROOT%\app"
set "BACKEND=%APP%\backend"

if not exist "%BACKEND%\ai_backend.py" (
  echo [ERROR] Dashboard source not found. Run setup.bat first.
  exit /b 1
)
if not exist "%BACKEND%\.venv\Scripts\python.exe" (
  echo [ERROR] Backend virtual environment missing. Run setup.bat first.
  exit /b 1
)

"%BACKEND%\.venv\Scripts\python.exe" -m pip install pyinstaller
if errorlevel 1 exit /b 1

cd /d "%BACKEND%"
"%BACKEND%\.venv\Scripts\python.exe" -m PyInstaller --clean --noconfirm "%ROOT%\backend-packaging\vanguard_backend.spec"
if errorlevel 1 exit /b 1

echo Build finished. Inspect backend\dist and test it on a clean Windows PC.
