# Vanguard Desktop (Windows)

Private Windows distribution/bootstrap repository for Team Vanguard's Earth System Trend Detective dashboard.

## What this repository does

- Checks for Git, GitHub CLI, Python 3.10+, Node.js 20+, and npm.
- Authenticates to GitHub so an authorized user can fetch the private dashboard source repository.
- Clones the configured dashboard repository into a local `app` folder.
- Creates a Python virtual environment and installs backend requirements.
- Installs frontend npm dependencies.
- Asks for an NVIDIA API key (optional) and writes it to the local backend `.env`.
- Starts the FastAPI backend and Vite frontend, then opens the dashboard in the default browser.

> This is an initial bootstrap release, not yet a signed Windows installer. It requires Git, GitHub CLI, Python, and Node.js to be installed first. The setup script gives clear download links when one is missing.

## 1. Create the private GitHub repository

Create a private repository named `vanguard-desktop`, then upload the contents of this folder to its `main` branch.

## 2. Dashboard source repository

`config.bat` is preconfigured to fetch:

`underalpha3412/Be-An-Earth-System-Trend-Detective`

The account running setup must have access to that repository. The current setup script expects the source repository to contain `backend\requirements.txt` and `frontend\package.json`. Confirm that layout before distributing this bootstrap installer.

## 3. Requirements on the user's Windows PC

- Git for Windows
- GitHub CLI (`gh`)
- Python 3.10 or newer
- Node.js 20 or newer (includes npm)

Install links:
- Git: https://git-scm.com/download/win
- GitHub CLI: https://cli.github.com/
- Python: https://www.python.org/downloads/windows/
- Node.js LTS: https://nodejs.org/en/download/

During Python installation, enable **Add Python to PATH**.

## 4. Run

Double-click `setup.bat`. The script checks prerequisites, asks the user to authenticate with GitHub if needed, fetches the private source repository, installs dependencies, and asks for the optional NVIDIA API key.

After setup, double-click `launch.bat` to start Vanguard.

## 5. Backend packaging

`backend-packaging/` contains a starting PyInstaller spec and build script. Build it from the dashboard source repository after installing backend dependencies:

```bat
cd app\backend
..\..\backend-packaging\build_backend.bat
```

The spec is a starting point. `model_go` uses bundled model assets and may need additional hidden imports or data entries after testing on a clean Windows machine. Do not claim the executable is portable until that clean-machine test passes.

## Security notes

- Never commit `.env`, API keys, GitHub tokens, or credentials.
- NVIDIA keys are stored locally in `app\backend\.env`; they are not sent to this repository.
- Users need explicit access to the private source repository. Do not embed a personal GitHub token in the batch file.
- A private repository limits access through GitHub, but does not prevent an authorized recipient from copying files after download. For stronger protection, distribute compiled binaries, sign releases, use a licence/EULA, and keep sensitive server-side logic off client machines.

## Repository visibility

Keep this repository **Private**. Also keep the dashboard source repository private if access should be restricted.
