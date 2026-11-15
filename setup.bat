@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call config.bat

echo.
echo  ============================================
echo       TEAM VANGUARD - DESKTOP SETUP
echo  ============================================
echo.

if "%VANGUARD_SOURCE_REPO%"=="YOUR_GITHUB_OWNER/YOUR_DASHBOARD_REPO" (
  echo [ERROR] Edit config.bat and set VANGUARD_SOURCE_REPO first.
  pause
  exit /b 1
)

where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Git for Windows is not installed.
  echo Download: https://git-scm.com/download/win
  pause
  exit /b 1
)

where gh >nul 2>&1
if errorlevel 1 (
  echo [ERROR] GitHub CLI is not installed. It is required to access the private repository.
  echo Download: https://cli.github.com/
  pause
  exit /b 1
)

where py >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Python launcher was not found.
  echo Install Python 3.10 or newer: https://www.python.org/downloads/windows/
  echo During installation, enable "Add Python to PATH".
  pause
  exit /b 1
)

py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
if errorlevel 1 (
  py -3 --version
  echo [ERROR] Python 3.10 or newer is required. Install it from https://www.python.org/downloads/windows/
  pause
  exit /b 1
)

where npm >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Node.js/npm was not found.
  echo Install Node.js 20 LTS: https://nodejs.org/en/download/
  pause
  exit /b 1
)

for /f "tokens=1 delims=v." %%A in ('node --version') do set NODE_MAJOR=%%A
if %NODE_MAJOR% LSS 20 (
  echo [ERROR] Node.js 20 or newer is required. Detected:
  node --version
  echo Download: https://nodejs.org/en/download/
  pause
  exit /b 1
)

echo [1/5] Checking GitHub authentication...
gh auth status >nul 2>&1
if errorlevel 1 (
  echo Sign in to GitHub. Your account must have access to %VANGUARD_SOURCE_REPO%.
  gh auth login
  if errorlevel 1 (
    echo [ERROR] GitHub authentication did not complete.
    pause
    exit /b 1
  )
)

echo [2/5] Downloading Vanguard source...
if not exist "%VANGUARD_APP_DIR%" (
  gh repo clone "%VANGUARD_SOURCE_REPO%" "%VANGUARD_APP_DIR%"
  if errorlevel 1 (
    echo [ERROR] Could not clone the source repository. Check the repo name and your access.
    pause
    exit /b 1
  )
) else (
  echo Existing app folder found. Keeping it; use launch.bat to run it.
)

if not exist "%VANGUARD_APP_DIR%\backend\requirements.txt" (
  echo [ERROR] Expected backend\requirements.txt was not found in the source repo.
  pause
  exit /b 1
)
if not exist "%VANGUARD_APP_DIR%\frontend\package.json" (
  echo [ERROR] Expected frontend\package.json was not found in the source repo.
  pause
  exit /b 1
)

echo [3/5] Preparing Python environment...
if not exist "%VANGUARD_APP_DIR%\backend\.venv\Scripts\python.exe" (
  py -3 -m venv "%VANGUARD_APP_DIR%\backend\.venv"
  if errorlevel 1 goto :failed
)
"%VANGUARD_APP_DIR%\backend\.venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 goto :failed
"%VANGUARD_APP_DIR%\backend\.venv\Scripts\python.exe" -m pip install -r "%VANGUARD_APP_DIR%\backend\requirements.txt"
if errorlevel 1 goto :failed

echo [4/5] Installing frontend packages...
cd /d "%VANGUARD_APP_DIR%\frontend"
call npm install
if errorlevel 1 goto :failed

echo [5/5] NVIDIA Nemotron setup (optional)...
set "NVIDIA_KEY="
set /p "NVIDIA_KEY=Paste NVIDIA API key, or press Enter to skip AI insights: "
(
  echo NVIDIA_API_KEY=%NVIDIA_KEY%
  echo NVIDIA_MODEL=nvidia/nemotron-3.5-lightning-30b-a3b
  echo DASHBOARD_ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
  echo MODEL_GO_PROFILE=server
) > "%VANGUARD_APP_DIR%\backend\.env"

echo.
echo Setup completed. Starting Vanguard...
call "%~dp0launch.bat"
exit /b 0

:failed
echo.
echo [ERROR] Setup failed. Review the error above, check your internet connection, and run setup.bat again.
pause
exit /b 1
