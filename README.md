# Vanguard Desktop Bootstrap

## How it works
- Run either `setup.bat` or `launch.bat`. Both call the same idempotent startup flow.
- If Git, Python or Node.js is missing, the launcher first checks internet access, then offers/starts automatic installation through Windows Package Manager (`winget`).
- If internet is unavailable, it stops before downloading source or installing dependencies.
- Dashboard source is cloned only if missing.
- Python and npm dependencies are installed only if missing or their requirements/lockfile changed.
- NVIDIA API key is mandatory. The first run prompts for it with visible CMD input and saves it in `app\backend\.env`. Later runs reuse the saved key.
- Backend starts with Uvicorn's explicit `--env-file .env` so the saved NVIDIA key is loaded on every launch.
- Existing running services are reused to avoid duplicate backend/frontend processes.

## Requirements
- Windows 10/11
- Windows Package Manager (`winget`) for automatic Git/Python/Node installation
- Internet connection for first-time setup and dependency downloads
- Git, Python 3.10+, Node.js 20+ are installed automatically if missing.

If winget is unavailable, install/update **App Installer** from Microsoft Store and rerun.

## Run
1. Extract the installer folder.
2. Run `setup.bat` for the first launch, or `launch.bat`. They behave identically.
3. Enter a valid NVIDIA hosted-inference API key when prompted. The key is required and saved for future launches.
4. For subsequent launches, run `launch.bat`. It skips downloads and dependency installation when everything is already present.

## NVIDIA key
Create a hosted-inference API key at https://build.nvidia.com/ (sign in, open API Keys, create a key for hosted inference). Input is intentionally visible while typing. Key is stored locally in `app\backend\.env`. Do not share or commit this file.

The environment file is written with one setting per line:
- `NVIDIA_API_KEY=...`
- `NVIDIA_MODEL=nvidia/nemotron-3.5-lightning-30b-a3b`
- `DASHBOARD_ALLOWED_ORIGINS=...`
- `MODEL_GO_PROFILE=server`

A key being present does not guarantee NVIDIA accepts it. HTTP 401/403 means NVIDIA rejected the key or its access. Generate a valid hosted-inference key if that occurs.

## Dashboard preservation
Only installer/launcher scripts are changed. No React components, CSS, chart code, images, assets, or backend application source files are modified.

## Logs
- Setup and dependency output: `logs\setup.log`
- Backend/frontend run in separate minimized terminal windows.


## API key storage fix (revision)
The launcher writes the key through the installed Python `python-dotenv` library with quoted value handling, then immediately reads the file back and verifies both `NVIDIA_API_KEY` and `NVIDIA_MODEL` before starting services. This safely handles punctuation in generated keys.


## Startup diagnostics
Backend and frontend are started in separate minimized CMD windows that remain open if a process exits. Their console output is captured in `logs\backend.log` and `logs\frontend.log`.


## Second-launch reliability fix
The launcher checks ports independently and uses the Windows `start` command to open visible minimized CMD windows for services that are not already listening. It avoids starting duplicate services when a port is already active. Backend and frontend logs are recreated on each fresh service start.

## Repeated-launch dependency check fix
The npm lockfile stamp is stored in `frontend\.vanguard-lock.sha256`, outside `node_modules`, because `npm ci` replaces `node_modules`. The launcher validates the exact Vite command shim used to start the frontend (`node_modules\.bin\vite.cmd`) both after dependency installation and before service startup.


## Relaunch behaviour
Every launch checks real HTTP readiness:
- Backend: `http://127.0.0.1:8000/health`
- Frontend: `http://127.0.0.1:5173/`

If a service responds successfully, it is reused. If it is stopped or not responding, its corresponding CMD runner is started again. Once both are ready, the browser opens. A different program occupying one of the configured ports can prevent Vanguard from binding to that port; in that case inspect the corresponding service log.


## Setup vs. Launch (important)
- `setup.bat` is for first installation or repair. It checks prerequisites, downloads source when absent, installs/updates Python and npm dependencies, and requests/saves the NVIDIA key when needed.
- `launch.bat` is the fast daily launcher. It does not run Git, pip, npm, winget, or dependency installation.
- Every launch first probes the backend `/health` endpoint and the frontend `/` endpoint. Healthy services are reused even if local dependency folders are unavailable. Only a stopped/unhealthy service is started, and only that service's local prerequisites are checked.
- If a stopped service is missing its local runtime/dependencies/configuration, `launch.bat` asks the user to run `setup.bat` for repair.
- The dashboard source, UI, charts, styles, and backend application code are not modified by this installer change.


## Git is not required
The setup process downloads the public dashboard repository as a GitHub ZIP archive using Windows PowerShell. Git for Windows is not required or installed. Python and Node.js remain required for the current source-based backend/frontend setup.


## Automatic Python and Node.js installation
Setup checks for a working Python 3.10+ interpreter and Node.js 20+ by executing version checks (it does not rely only on `where py`). If either is missing, it checks internet access before downloading.
- Python is downloaded from the official python.org release directory and installed for the current Windows user.
- Node.js LTS is downloaded from the official nodejs.org distribution index and extracted as a portable runtime under `runtimes\node`. It does not require a machine-wide Node.js installation or administrator access.
- `config.bat` adds the portable Node.js runtime to PATH for future launches.
- Winget is not required for Python or Node.js installation.
The installer currently targets 64-bit Windows (x64).
