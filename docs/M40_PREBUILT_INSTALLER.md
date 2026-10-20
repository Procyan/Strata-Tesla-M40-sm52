# Tesla M40 no-compiler installer

The normal `START-HERE.bat` / `setup.py` installer already detects an NVIDIA Maxwell sm_52 GPU and attempts the M40-specific precompiled Windows CUDA 12 release:

`https://github.com/Procyan/Strata-Tesla-M40-sm52/releases/download/v0.1.0-m40-original/strata-windows-x64-cuda12.zip`

**Important:** Installer logic alone does not supply a binary. Until an appropriate asset is published at that URL, Strata will fall back to local compilation. The engine must match Strata's minimum engine version and include `sm_52` code.

## One-time release creation

1. On the already working Tesla M40 machine, build or retain the working CUDA12 engine in `engine-cuda12/` under a current checkout of the fork.
2. Confirm the model works with that binary; do not ship an untested binary.
3. Run this from a PowerShell terminal in the repo root (single line):

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\publish_m40_release.ps1`

This creates `strata-windows-x64-cuda12.zip` locally, prints its SHA-256 and does not upload by default. It checks that `BUILD.json` declares `sm_52`, enforces minimum version 0.1.44.1, preserves `strata.exe`, optional `strata_kq.dll`, and optional `strata-vision.exe`, and changes the packaged manifest to `source: prebuilt` so the installer does not rebuild it on source changes.

4. Install and authenticate GitHub CLI (`gh auth login`) with permission to upload releases for the fork.
5. To publish, rerun with `-Upload`:

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\publish_m40_release.ps1 -Upload`

The installer then downloads the published archive and, when possible, verifies the release SHA-256 through the GitHub API. If absent, too old, or incompatible, it still falls back to compilation. Vision requires `strata-vision.exe`; the publisher includes it only if locally built, and the installer may compile vision if it is missing.

## Safety

This is not an automatic cross-compile. A working sm_52 binary must exist first. Do not publish an untested engine, do not delete the original working engine, and validate installation on a clean Windows machine before advertising no-compiler support. The publisher does not modify the currently installed engine.
