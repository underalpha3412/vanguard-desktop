@echo off
rem Public dashboard source repository.
set "VANGUARD_SOURCE_REPO=underalpha3412/Be-An-Earth-System-Trend-Detective"
set "VANGUARD_APP_DIR=%~dp0app"
set "VANGUARD_BACKEND_PORT=8000"
set "VANGUARD_FRONTEND_PORT=5173"

rem Use Vanguard-local portable Node.js when present.
if exist "%~dp0runtimes\node\node.exe" set "PATH=%~dp0runtimes\node;%PATH%"

rem Prefer Vanguard-local Python runtime when present.
if exist "%~dp0runtimes\python\python.exe" set "PATH=%~dp0runtimes\python;%PATH%"
