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
  echo [ERROR] Python 3.10 or newer is required.
  echo Download: https://www.python.org/downloads/windows/
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

for /f %%A in ('node -p "process.versions.node.split('.')[0]"') do set "NODE_MAJOR=%%A"
if not defined NODE_MAJOR (
  echo [ERROR] Could not determine Node.js version.
  pause
  exit /b 1
)
if %NODE_MAJOR% LSS 20 (
  echo [ERROR] Node.js 20 or newer is required. Detected:
  node --version
  echo Download: https://nodejs.org/en/download/
  pause
  exit /b 1
)

echo [1/5] Checking public dashboard source...
if not exist "%VANGUARD_APP_DIR%" (
  git clone --depth 1 "https://github.com/%VANGUARD_SOURCE_REPO%.git" "%VANGUARD_APP_DIR%"
  if errorlevel 1 (
    echo [ERROR] Could not download the public source repository.
    echo Check repository visibility, URL, and internet connection.
    pause
    exit /b 1
  )
) else (
  echo Existing app folder found. Keeping it; delete app to download a fresh copy.
)

if not exist "%VANGUARD_APP_DIR%\backend\requirements.txt" (
  echo [ERROR] Expected backend\requirements.txt was not found.
  pause
  exit /b 1
)
if not exist "%VANGUARD_APP_DIR%\frontend\package.json" (
  echo [ERROR] Expected frontend\package.json was not found.
  pause
  exit /b 1
)

 echo [2/5] Preparing Python environment...
if not exist "%VANGUARD_APP_DIR%\backend\.venv\Scripts\python.exe" (
  py -3 -m venv "%VANGUARD_APP_DIR%\backend\.venv"
  if errorlevel 1 goto :failed
)
"%VANGUARD_APP_DIR%\backend\.venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 goto :failed
"%VANGUARD_APP_DIR%\backend\.venv\Scripts\python.exe" -m pip install -r "%VANGUARD_APP_DIR%\backend\requirements.txt"
if errorlevel 1 goto :failed

 echo [3/5] Installing frontend packages...
cd /d "%VANGUARD_APP_DIR%\frontend"
call npm ci
if errorlevel 1 (
  echo [INFO] npm ci could not use the lockfile. Trying npm install...
  call npm install
  if errorlevel 1 goto :failed
)

 echo [4/5] NVIDIA Nemotron setup (optional)...
echo A key is optional. Press Enter to skip AI-generated insights.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$secure = Read-Host 'NVIDIA API key (input hidden, optional)' -AsSecureString; $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure); try { $key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr); $lines = @('NVIDIA_API_KEY=' + $key, 'NVIDIA_MODEL=nvidia/nemotron-3.5-lightning-30b-a3b', 'DASHBOARD_ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173', 'MODEL_GO_PROFILE=server'); Set-Content -LiteralPath '%VANGUARD_APP_DIR%\backend\.env' -Value $lines -Encoding ascii } finally { if ($ptr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) } }"
if errorlevel 1 goto :failed

 echo [5/5] Setup complete. Starting Vanguard...
call "%~dp0launch.bat"
exit /b 0

:failed
echo.
echo [ERROR] Setup failed. Review the error above and run setup.bat again.
pause
exit /b 1
