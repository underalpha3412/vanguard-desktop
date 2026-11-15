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
