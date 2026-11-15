# Initial PyInstaller spec for the Vanguard FastAPI backend.
# Run from the dashboard backend folder via build_backend.bat.
from PyInstaller.utils.hooks import collect_all

datas = []
binaries = []
hiddenimports = []

for package in ["fastapi", "uvicorn", "pydantic", "model_go", "numpy", "scipy", "joblib", "requests", "httpx"]:
    try:
        d, b, h = collect_all(package)
        datas += d
        binaries += b
        hiddenimports += h
    except Exception:
        pass

# Include model_go's bundled local model/data assets.
datas += [
    ("model_go_v2/model_go_v2", "model_go_v2/model_go_v2"),
]

a = Analysis(
    ["ai_backend.py"],
    pathex=["."],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports + ["uvicorn.logging", "uvicorn.loops", "uvicorn.loops.auto", "uvicorn.protocols", "uvicorn.protocols.http", "uvicorn.protocols.websockets"],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=["tkinter", "matplotlib", "pytest"],
    noarchive=False,
)
pyz = PYZ(a.pure)
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name="vanguard-api",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
)
