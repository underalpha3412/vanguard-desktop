@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call config.bat

if not exist "%~dp0logs" mkdir "%~dp0logs"
set "SETUP_LOG=%~dp0logs\setup.log"
set "BACKEND_DIR=%VANGUARD_APP_DIR%\backend"
set "FRONTEND_DIR=%VANGUARD_APP_DIR%\frontend"

echo.
echo  ============================================================
echo                    TEAM VANGUARD
echo                    DESKTOP INSTALLER
echo  ============================================================
echo.

if not exist "%VANGUARD_APP_DIR%\backend\requirements.txt" (
    echo [1/5] Downloading dashboard source...
    where git >nul 2>&1
    if errorlevel 1 (
        echo.
        echo [ERROR] Git is required. Install it from https://git-scm.com/download/win
        goto :failed
    )
    git clone --depth 1 "https://github.com/%VANGUARD_SOURCE_REPO%.git" "%VANGUARD_APP_DIR%" >"%SETUP_LOG%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Source download failed. Details: logs\setup.log
        goto :failed
    )
) else (
    echo [1/5] Dashboard source already present. Skipping download.
)

if not exist "%BACKEND_DIR%\requirements.txt" (
    echo [ERROR] backend\requirements.txt not found in downloaded source.
    goto :failed
)
if not exist "%FRONTEND_DIR%\package.json" (
    echo [ERROR] frontend\package.json not found in downloaded source.
    goto :failed
)

where py >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python 3.10+ is required. Install: https://www.python.org/downloads/windows/
    goto :failed
)
py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python 3.10+ is required. Install: https://www.python.org/downloads/windows/
    goto :failed
)

where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js 20+ is required. Install: https://nodejs.org/en/download/
    goto :failed
)
for /f %%V in ('node -p "process.versions.node.split('.')[0]"') do set "NODE_MAJOR=%%V"
if not defined NODE_MAJOR goto :node_error
if %NODE_MAJOR% LSS 20 goto :node_error

echo [2/5] Preparing Python environment...
if not exist "%BACKEND_DIR%\.venv\Scripts\python.exe" (
    py -3 -m venv "%BACKEND_DIR%\.venv" >>"%SETUP_LOG%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Python environment creation failed. Details: logs\setup.log
        goto :failed
    )
)
set "PYTHON=%BACKEND_DIR%\.venv\Scripts\python.exe"
for /f %%H in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath ''%BACKEND_DIR%\requirements.txt'').Hash"') do set "REQ_HASH=%%H"
set "REQ_STAMP=%BACKEND_DIR%\.venv\requirements.sha256"
set "INSTALL_PY=1"
if exist "%REQ_STAMP%" (
    set /p OLD_REQ_HASH=<"%REQ_STAMP%"
    if /i "%OLD_REQ_HASH%"=="%REQ_HASH%" set "INSTALL_PY=0"
)
if "%INSTALL_PY%"=="1" (
    "%PYTHON%" -m pip install --disable-pip-version-check -q -r "%BACKEND_DIR%\requirements.txt" >>"%SETUP_LOG%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Python dependencies failed. Details: logs\setup.log
        goto :failed
    )
    >"%REQ_STAMP%" echo %REQ_HASH%
) else (
    echo       Python packages already up to date.
)

echo [3/5] Preparing frontend...
for /f %%H in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath ''%FRONTEND_DIR%\package-lock.json'').Hash"') do set "NPM_HASH=%%H"
set "NPM_STAMP=%FRONTEND_DIR%\node_modules\.vanguard-lock.sha256"
set "INSTALL_NPM=1"
if exist "%NPM_STAMP%" (
    set /p OLD_NPM_HASH=<"%NPM_STAMP%"
    if /i "%OLD_NPM_HASH%"=="%NPM_HASH%" set "INSTALL_NPM=0"
)
if not exist "%FRONTEND_DIR%\node_modules" set "INSTALL_NPM=1"
if "%INSTALL_NPM%"=="1" (
    pushd "%FRONTEND_DIR%"
    call npm ci --no-audit --no-fund --silent >>"%SETUP_LOG%" 2>&1
    if errorlevel 1 (
        call npm install --no-audit --no-fund --silent >>"%SETUP_LOG%" 2>&1
        if errorlevel 1 (
            popd
            echo [ERROR] Frontend dependencies failed. Details: logs\setup.log
            goto :failed
        )
    )
    >"node_modules\.vanguard-lock.sha256" echo %NPM_HASH%
    popd
) else (
    echo       Frontend packages already up to date.
)

echo [4/5] NVIDIA Nemotron API key (optional)...
echo       Create a key at https://build.nvidia.com/
echo       Choose an NVIDIA API key for hosted inference.
set "NVIDIA_KEY="
set /p "NVIDIA_KEY=       Paste API key here (visible while typing), or press Enter to skip: "
set "VANGUARD_NVIDIA_KEY=%NVIDIA_KEY%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$key=[Environment]::GetEnvironmentVariable('VANGUARD_NVIDIA_KEY','Process'); $lines=@('NVIDIA_API_KEY=' + $key,'NVIDIA_MODEL=nvidia/nemotron-3.5-lightning-30b-a3b','DASHBOARD_ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173','MODEL_GO_PROFILE=server'); Set-Content -LiteralPath '%BACKEND_DIR%\.env' -Value $lines -Encoding ascii"
if errorlevel 1 (
    echo [ERROR] Could not save backend\.env.
    goto :failed
)
set "VANGUARD_NVIDIA_KEY="

echo [5/5] Setup complete.
echo.
echo  ============================================================
echo       INSTALLATION COMPLETE - STARTING VANGUARD
echo  ============================================================
echo.
call "%~dp0launch.bat"
exit /b 0

:node_error
echo [ERROR] Node.js 20+ is required. Install: https://nodejs.org/en/download/
goto :failed

:failed
echo.
echo  ============================================================
echo       SETUP STOPPED - SEE logs\setup.log FOR DETAILS
echo  ============================================================
echo.
pause
exit /b 1
