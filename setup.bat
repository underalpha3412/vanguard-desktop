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

rem Detect a usable Python 3.10+ interpreter and Node.js 20+.
set "NEED_PYTHON=1"
set "NEED_NODE=1"

if exist "%~dp0runtimes\python\python.exe" (
    "%~dp0runtimes\python\python.exe" -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
    if not errorlevel 1 set "NEED_PYTHON=0"
)
if "%NEED_PYTHON%"=="1" (
    where py >nul 2>&1
    if not errorlevel 1 (
        py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
        if not errorlevel 1 set "NEED_PYTHON=0"
    )
)
if "%NEED_PYTHON%"=="1" (
    where python >nul 2>&1
    if not errorlevel 1 (
        python -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
        if not errorlevel 1 set "NEED_PYTHON=0"
    )
)

if exist "%~dp0runtimes\node\node.exe" (
    "%~dp0runtimes\node\node.exe" -e "process.exit(parseInt(process.versions.node.split('.')[0],10)>=20?0:1)" >nul 2>&1
    if not errorlevel 1 set "NEED_NODE=0"
)
if "%NEED_NODE%"=="1" if exist "%ProgramFiles%\nodejs\node.exe" (
    "%ProgramFiles%\nodejs\node.exe" -e "process.exit(parseInt(process.versions.node.split('.')[0],10)>=20?0:1)" >nul 2>&1
    if not errorlevel 1 set "NEED_NODE=0"
)
if "%NEED_NODE%"=="1" (
    where node >nul 2>&1
    if not errorlevel 1 (
        node -e "process.exit(parseInt(process.versions.node.split('.')[0],10)>=20?0:1)" >nul 2>&1
        if not errorlevel 1 set "NEED_NODE=0"
    )
)

if not "%NEED_PYTHON%%NEED_NODE%"=="00" (
    if exist "%~dp0Vanguard-Setup-Guide.html" start "" "%~dp0Vanguard-Setup-Guide.html"
    echo [1/6] Checking internet and installing missing prerequisites...
    set "PREREQ_ARGS="
    if "%NEED_PYTHON%"=="1" set "PREREQ_ARGS=%PREREQ_ARGS% -NeedPython"
    if "%NEED_NODE%"=="1" set "PREREQ_ARGS=%PREREQ_ARGS% -NeedNode"
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure-prerequisites.ps1" %PREREQ_ARGS%
    if errorlevel 1 goto :failed
)

rem Refresh PATH for runtimes installed during this setup process.
if exist "%~dp0runtimes\node\node.exe" set "PATH=%~dp0runtimes\node;%PATH%"
if exist "%ProgramFiles%\nodejs\node.exe" set "PATH=%ProgramFiles%\nodejs;%PATH%"
if exist "%~dp0runtimes\python\python.exe" set "PATH=%~dp0runtimes\python;%PATH%"

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
rem Prefer the exact interpreter installed and verified by Vanguard's prerequisite installer.
if exist "%~dp0runtimes\python\python.exe" set "PY_LAUNCHER=%~dp0runtimes\python\python.exe"
if not defined PY_LAUNCHER if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PY_LAUNCHER=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if not defined PY_LAUNCHER (
    where py >nul 2>&1 && set "PY_LAUNCHER=py -3"
)
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

rem Fetch the shared judging .env from the dashboard repository.
rem The file must be committed at backend/.env in the public source repository.
echo [5/6] Downloading shared NVIDIA configuration...
if not exist "%BACKEND_DIR%" mkdir "%BACKEND_DIR%"
set "ENV_URL=https://raw.githubusercontent.com/%VANGUARD_SOURCE_REPO%/main/backend/.env"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='%ENV_URL%'; $p='%BACKEND_DIR%\.env'; try { Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile ($p+'.download') -TimeoutSec 30; if ((Get-Item ($p+'.download')).Length -lt 20) { throw 'Downloaded .env file is empty or too small.' }; Move-Item -Force ($p+'.download') $p } catch { Remove-Item ($p+'.download') -Force -ErrorAction SilentlyContinue; Write-Error ('Could not download shared backend .env: '+$_.Exception.Message); exit 1 }"
if errorlevel 1 (
    echo [ERROR] Shared backend .env could not be downloaded.
    echo         Confirm backend\.env is committed to the public GitHub repository.
    goto :failed
)
"%PYTHON%" -c "from dotenv import dotenv_values; import sys; d=dotenv_values(r'%BACKEND_DIR%\.env'); sys.exit(0 if (d.get('NVIDIA_API_KEY') or '').strip() and (d.get('NVIDIA_MODEL') or '').strip() else 1)" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Downloaded backend\.env is missing NVIDIA_API_KEY or NVIDIA_MODEL.
    goto :failed
)
echo       Shared NVIDIA configuration downloaded and verified.

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
