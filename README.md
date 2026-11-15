# Vanguard Desktop Bootstrap

This repository contains the Windows bootstrap scripts for the Earth System Trend Detective dashboard.

## Current stage: developer bootstrap

The current `setup.bat` downloads the **public** dashboard source from the repository configured in `config.bat`, creates a Python virtual environment, installs backend and frontend dependencies, optionally stores an NVIDIA API key in the dashboard's local `backend/.env`, and launches the application.

### Requirements for this bootstrap version

- Windows 10/11
- Git for Windows
- Python 3.10 or newer (Python launcher `py`)
- Node.js 20 or newer with npm
- Internet access

The installer reports download links if Git, Python, or Node.js are missing. It does not silently install system runtimes.

## Install and run

1. Download/extract this repository.
2. Confirm `config.bat` points to `underalpha3412/Be-An-Earth-System-Trend-Detective`.
3. Run `setup.bat`.
4. Enter an NVIDIA API key at the hidden prompt, or press Enter to skip AI-generated insights.

Run `launch.bat` again later to start the backend and dashboard.

## Dashboard preservation

The installer is deliberately separate from the dashboard source. Do not edit `frontend/src`, `frontend/public`, or frontend configuration as part of installer work. The dashboard UI is treated as frozen. Any future production-serving change must be isolated and verified against a frontend file-hash baseline before release.

## Next packaging stage

This is **not yet a standalone EXE or final end-user installer**. It still requires Git, Python, Node.js, and npm. The next stage is to build the existing frontend without changing its source components, package the Python backend and Model V2 assets, and test the result on a clean Windows machine. PyInstaller packaging is experimental until runtime imports, model files, and forecast endpoints are verified.

## Secrets

- Never commit `.env`, API keys, GitHub tokens, `.venv`, or `node_modules`.
- The optional NVIDIA key is entered with hidden terminal input and written to the local backend `.env`. That local file contains the key in plaintext because the current backend reads it as an environment variable. Protect the Windows account and never upload that file.
- Do not embed a personal GitHub token in an installer.

## Source repository

`https://github.com/underalpha3412/Be-An-Earth-System-Trend-Detective`
