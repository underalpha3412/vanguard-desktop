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

## 2. Configure the dashboard source repository

Edit `config.bat` and set:

```bat
set "VANGUARD_SOURCE_REPO=YOUR_GITHUB_OWNER/YOUR_DASHBOARD_REPO"
```

The account running setup must have access to that private repository.

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

