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
echo              SETUP / INSTALLING DASHBOARD
echo  ============================================================
echo.

rem Check required tools. Only install what is missing.
set "NEED_PYTHON=0"
set "NEED_NODE=0"
where py >nul 2>&1
if errorlevel 1 (
    where python >nul 2>&1
    if errorlevel 1 set "NEED_PYTHON=1"
)
where node >nul 2>&1 || set "NEED_NODE=1"
if "%NEED_NODE%"=="0" (
    node -e "process.exit(parseInt(process.versions.node.split('.')[0],10)>=20?0:1)" >nul 2>&1
    if errorlevel 1 set "NEED_NODE=1"
)

if not "%NEED_PYTHON%%NEED_NODE%"=="00" (
    echo [1/6] Checking internet and installing missing prerequisites...
    set "PREREQ_ARGS="
    if "%NEED_PYTHON%"=="1" set "PREREQ_ARGS=%PREREQ_ARGS% -NeedPython"
    if "%NEED_NODE%"=="1" set "PREREQ_ARGS=%PREREQ_ARGS% -NeedNode"
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure-prerequisites.ps1" %PREREQ_ARGS%
    if errorlevel 1 goto :failed
)

rem Source download is needed only once.
if not exist "%BACKEND_DIR%\requirements.txt" (
    echo [2/6] Checking internet before downloading Vanguard...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try {$r=Invoke-WebRequest -UseBasicParsing https://github.com -TimeoutSec 8; if($r.StatusCode -lt 500){exit 0}else{exit 1}} catch {exit 1}"
    if errorlevel 1 (
        echo [ERROR] Internet is unavailable. Source download has been stopped.
        goto :failed
    )
    if exist "%VANGUARD_APP_DIR%" rmdir /s /q "%VANGUARD_APP_DIR%"
    echo       Downloading dashboard source directly from GitHub...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $repo='%VANGUARD_SOURCE_REPO%'; $url='https://github.com/'+$repo+'/archive/refs/heads/main.zip'; $tmp=Join-Path $env:TEMP ('vanguard-source-'+[guid]::NewGuid().ToString('N')); $zip=Join-Path $tmp 'source.zip'; New-Item -ItemType Directory -Path $tmp -Force | Out-Null; try { Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip; Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force; $src=Get-ChildItem -LiteralPath $tmp -Directory | Where-Object { $_.Name -ne '' } | Select-Object -First 1; if(-not $src){throw 'GitHub archive did not contain a source folder'}; New-Item -ItemType Directory -Path '%VANGUARD_APP_DIR%' -Force | Out-Null; Get-ChildItem -LiteralPath $src.FullName -Force | Move-Item -Destination '%VANGUARD_APP_DIR%'; } finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }" >"%SETUP_LOG%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Dashboard download failed. See logs\setup.log
        goto :failed
    )
) else (
    echo [2/6] Dashboard source already downloaded.
)

if not exist "%BACKEND_DIR%\requirements.txt" (
    echo [ERROR] backend\requirements.txt is missing.
    goto :failed
)
if not exist "%FRONTEND_DIR%\package.json" (
    echo [ERROR] frontend\package.json is missing.
    goto :failed
)

rem Verify Python 3.10+ and install backend requirements only when the hash changes.
echo [3/6] Checking Python environment...
set "PY_LAUNCHER="
where py >nul 2>&1 && set "PY_LAUNCHER=py -3"
if not defined PY_LAUNCHER (
    where python >nul 2>&1 && set "PY_LAUNCHER=python"
)
if not defined PY_LAUNCHER (
    echo [ERROR] Python is still unavailable. Restart Windows and try again.
    goto :failed
)
%PY_LAUNCHER% -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python 3.10 or newer is required.
    goto :failed
)
if not exist "%BACKEND_DIR%\.venv\Scripts\python.exe" (
    %PY_LAUNCHER% -m venv "%BACKEND_DIR%\.venv" >>"%SETUP_LOG%" 2>&1
    if errorlevel 1 goto :failed
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
    echo       Installing / updating Python packages...
    "%PYTHON%" -m pip install --disable-pip-version-check -q -r "%BACKEND_DIR%\requirements.txt" >>"%SETUP_LOG%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Python dependency installation failed. See logs\setup.log
        goto :failed
    )
    >"%REQ_STAMP%" echo %REQ_HASH%
) else (
    echo       Python packages already installed.
)

rem Check Node 20+ and install npm dependencies only if lockfile changes.
echo [4/6] Checking frontend environment...
where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is unavailable. Restart Windows and run launch.bat again.
    goto :failed
)
node -e "process.exit(parseInt(process.versions.node.split('.')[0],10)>=20?0:1)" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js 20 or newer is required.
    goto :failed
)
if not exist "%FRONTEND_DIR%\package-lock.json" (
    echo [ERROR] frontend\package-lock.json is missing.
    goto :failed
)
for /f %%H in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath ''%FRONTEND_DIR%\package-lock.json'').Hash"') do set "NPM_HASH=%%H"
rem Keep the stamp OUTSIDE node_modules because npm ci replaces that folder.
set "NPM_STAMP=%FRONTEND_DIR%\.vanguard-lock.sha256"
set "OLD_NPM_HASH="
set "INSTALL_NPM=1"
if exist "%NPM_STAMP%" (
    set /p OLD_NPM_HASH=<"%NPM_STAMP%"
    if /i "%OLD_NPM_HASH%"=="%NPM_HASH%" set "INSTALL_NPM=0"
)
if not exist "%FRONTEND_DIR%\node_modules\.bin\vite.cmd" set "INSTALL_NPM=1"
if "%INSTALL_NPM%"=="1" (
    echo       Installing / updating frontend packages...
    pushd "%FRONTEND_DIR%"
    call npm ci --no-audit --no-fund --silent >>"%SETUP_LOG%" 2>&1
    if errorlevel 1 (
        call npm install --no-audit --no-fund --silent >>"%SETUP_LOG%" 2>&1
        if errorlevel 1 (
            popd
            echo [ERROR] Frontend dependency installation failed. See logs\setup.log
            goto :failed
        )
    )
    popd
    if not exist "%FRONTEND_DIR%\node_modules\.bin\vite.cmd" (
        echo [ERROR] npm completed but Vite executable is still missing.
        echo         See logs\setup.log for the npm output.
        goto :failed
    )
    >"%NPM_STAMP%" echo %NPM_HASH%
) else (
    echo       Frontend packages already installed.
)

rem Mandatory persistent NVIDIA key. Existing non-empty key is preserved.
echo [5/6] Checking NVIDIA Nemotron API key...
if not exist "%BACKEND_DIR%\.env" goto :get_key
"%PYTHON%" -c "from dotenv import dotenv_values; import sys; d=dotenv_values(r'%BACKEND_DIR%\.env'); sys.exit(0 if (d.get('NVIDIA_API_KEY') or '').strip() else 1)" >nul 2>&1
if not errorlevel 1 (
    echo       NVIDIA API key already saved. Reusing it.
    goto :start_app
)

:get_key
echo.
echo  ------------------------------------------------------------
echo  NVIDIA API KEY REQUIRED
echo  Create your key at https://build.nvidia.com/
echo  Sign in, open API Keys, and create a hosted-inference key.
echo  ------------------------------------------------------------
set "NVIDIA_KEY="
set /p "NVIDIA_KEY=Paste your NVIDIA API key (visible while typing): "
if not defined NVIDIA_KEY (
    echo [ERROR] API key is mandatory. Vanguard cannot start without it.
    goto :failed
)
set "VANGUARD_NVIDIA_KEY=%NVIDIA_KEY%"
"%PYTHON%" -c "import os; from dotenv import set_key; p=r'%BACKEND_DIR%\.env'; k=os.environ.get('VANGUARD_NVIDIA_KEY','').strip(); assert k, 'API key input was empty'; set_key(p,'NVIDIA_API_KEY',k,quote_mode='always'); set_key(p,'NVIDIA_MODEL','nvidia/nemotron-3.5-lightning-30b-a3b',quote_mode='never'); set_key(p,'DASHBOARD_ALLOWED_ORIGINS','http://localhost:%VANGUARD_FRONTEND_PORT%,http://127.0.0.1:%VANGUARD_FRONTEND_PORT%',quote_mode='always'); set_key(p,'MODEL_GO_PROFILE','server',quote_mode='never')"
if errorlevel 1 (
    echo [ERROR] Could not save API key to backend\.env. See logs\setup.log.
    set "VANGUARD_NVIDIA_KEY="
    goto :failed
)
"%PYTHON%" -c "from dotenv import dotenv_values; import sys; d=dotenv_values(r'%BACKEND_DIR%\.env'); sys.exit(0 if (d.get('NVIDIA_API_KEY') or '').strip() and (d.get('NVIDIA_MODEL') or '').strip() else 1)" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Saved .env did not pass validation. The key was not accepted for startup.
    set "VANGUARD_NVIDIA_KEY="
    goto :failed
)
set "NVIDIA_KEY="
set "VANGUARD_NVIDIA_KEY="
echo       API key and model saved and verified in backend\.env.

:start_app
echo [6/6] Starting Vanguard...
call "%~dp0start-services.bat"
if errorlevel 1 goto :failed
exit /b 0

:failed
echo.
echo  ============================================================
echo       VANGUARD COULD NOT START
echo       Check logs\setup.log for installation details.
echo  ============================================================
echo.
pause
exit /b 1
