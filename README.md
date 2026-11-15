# Vanguard Desktop Bootstrap

Windows bootstrap scripts for the Earth System Trend Detective dashboard.

## User experience

- `setup.bat` prints a short, one-line progress sequence. Detailed installer output is saved to `logs\setup.log`.
- The dashboard source is public and is cloned without GitHub sign-in.
- Python and frontend dependencies are installed only when missing or when their requirements/lockfile changes.
- The optional NVIDIA API key is visible while typing in CMD. Press Enter to skip.
- The key is written to `app\backend\.env` as four separate lines.
- `launch.bat` starts backend and frontend at the same time, waits for both to respond, then opens the browser.

## Requirements

- Windows 10/11
- Git for Windows
- Python 3.10+
- Node.js 20+ (includes npm)
- Internet access for first setup

Install links:
- Git: https://git-scm.com/download/win
- Python: https://www.python.org/downloads/windows/
- Node.js: https://nodejs.org/en/download/

## Run

1. Extract this folder.
2. Run `setup.bat` once.
3. For later launches, run `launch.bat` directly.

The first setup still needs to download/install dependencies. Subsequent setup runs skip dependency installation if the requirements and lockfile have not changed.

## NVIDIA API key

Create a hosted-inference API key at https://build.nvidia.com/ (sign in, open API Keys, create a key for hosted inference). Paste it when prompted. Input is intentionally visible while typing. The key is stored locally in `app\backend\.env`. Do not share or commit that file.

The `.env` file is written as:
```
NVIDIA_API_KEY=...
NVIDIA_MODEL=nvidia/nemotron-3.5-lightning-30b-a3b
DASHBOARD_ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
MODEL_GO_PROFILE=server
```

## Startup speed

Backend and Vite now start concurrently. The launcher no longer waits for the backend before starting the frontend. It checks both services and opens the browser only after they respond. Vite is invoked directly through its local executable rather than `npm run dev`.

First-ever dependency installation can still take time because packages must be downloaded. Later launches do not run pip or npm.

## Dashboard preservation

This repository changes installer scripts only. It does not edit dashboard React components, CSS, images, or backend application code. The dashboard source remains in its own repository.

## Logs

- Setup dependency/download output: `logs\setup.log`
- Backend and frontend run in their own minimized terminal windows.
