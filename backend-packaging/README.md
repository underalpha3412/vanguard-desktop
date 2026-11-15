# Packaging the Python backend

The current dashboard backend is FastAPI (`ai_backend.py`) and imports the bundled `model_go` package from a nested vendor directory.

## Initial build

1. Clone the dashboard source repo into the `app` folder using `setup.bat`.
2. Open Command Prompt in `app\backend`.
3. Install PyInstaller into the backend virtual environment:

```bat
.venv\Scripts\python.exe -m pip install pyinstaller
```

4. Run the packaging script from the desktop repository root:

```bat
backend-packaging\build_backend.bat
```

The first spec is a starting point, not a guarantee that every model asset and dynamic import has been captured. Test on a clean Windows 10/11 machine without Python installed. If model loading fails, add the missing hidden imports or data files to `vanguard_backend.spec`.

Do not bundle `.env` or any NVIDIA API key into the executable.
