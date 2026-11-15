# Installer audit notes

- The dashboard ZIP contains `backend/requirements.txt`, `backend/ai_backend.py`, `backend/model_go_v2/model_go_v2/`, and `frontend/package.json`.
- The frontend uses Vite and exposes the backend base URL through `VITE_API_URL`, defaulting to `http://127.0.0.1:8000`.
- The FastAPI app defines `/health` and `/forecast` routes.
- The bootstrap scripts have been updated to use public HTTPS Git cloning rather than requiring GitHub CLI authentication.
- The setup script now checks Node's major version without parsing the `v` prefix and uses `npm ci` with an `npm install` fallback.
- NVIDIA key entry is hidden in the terminal. The backend currently reads `.env`, so the local key is still stored as plaintext in that file; do not commit or share it.
- The frontend source has not been edited. A SHA-256 baseline is included in `docs/frontend-integrity-baseline.sha256` for subsequent verification.

## Not yet verified

- Windows batch execution on Windows 10/11.
- Package installation on a clean Windows machine.
- PyInstaller output and inclusion of all Model V2 assets/dynamic imports.
- Runtime behavior of `/health`, `/forecast`, and `/analyze-graph` after packaging.
- Production frontend hosting. The current launch flow uses the Vite development server and is intended for setup/testing, not final distribution.
