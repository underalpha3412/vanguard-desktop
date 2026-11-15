# Windows release checklist

- [ ] Set `VANGUARD_SOURCE_REPO` in `config.bat`.
- [ ] Keep this repository private.
- [ ] Confirm authorized users can authenticate with `gh auth login`.
- [ ] Test setup on a clean Windows 10 machine.
- [ ] Test setup on a clean Windows 11 machine.
- [ ] Confirm missing Python / Node.js / Git / GitHub CLI errors are clear.
- [ ] Confirm dashboard starts and browser opens.
- [ ] Confirm app still runs when NVIDIA key is skipped.
- [ ] Confirm Nemotron works when a valid key is entered.
- [ ] Confirm model_go forecasts work for more than one city.
- [ ] Test backend PyInstaller build on a clean machine.
- [ ] Do not include `.env`, keys, tokens, `.venv`, or `node_modules` in releases.
- [ ] Add a version number and changelog before distributing a release.
- [ ] Consider code signing and a separately reviewed EULA before public distribution.
