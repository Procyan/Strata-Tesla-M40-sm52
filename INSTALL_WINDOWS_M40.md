# Install and test Strata on NVIDIA Tesla M40 (Windows x64)

This guide is for the **experimental precompiled Windows x64** Tesla M40 (Maxwell, compute capability `sm_52`) port of [Strata](https://github.com/Niko1221/Strata).

**Important:** The binary file is named **`Strata-M40-Windows-x64.zip`** (not x86). The project source tag is `v0.1.0-m40-original`. A GitHub source-code ZIP is **not** the compiled program.

> **Release status:** The package passed a Windows Tesla M40 device-detection and 64 MiB allocation self-test from a separate extracted folder. Full model inference from this portable ZIP has **not yet been validated**. The source tag does not by itself prove that the compiled ZIP has been attached to a GitHub Release.

## 1. Prerequisites — install these first

| Requirement | Notes |
|---|---|
| Windows 10 / 11 x64 | 64-bit Windows is required. |
| NVIDIA Tesla M40 24 GB | Tested GPU: Maxwell `sm_52`; other GPUs not validated by this package. |
| NVIDIA driver | Must recognize the M40 and support CUDA 12.9 applications. Tested driver was 582.78. Get a suitable M40 Windows driver through [NVIDIA's driver search](https://www.nvidia.com/Download/index.aspx). |
| Microsoft Visual C++ Redistributable **x64** | Install from Microsoft's [official x64 download](https://aka.ms/vc14/vc_redist.x64.exe). The binaries import MSVCP140, MSVCP140_ATOMIC_WAIT, VCRUNTIME140 and VCRUNTIME140_1. |
| Free disk space | Allow about 2 GB for the downloaded ZIP and extracted program. Model files require additional space. |
| RAM | The device self-test is lightweight; full model use requires considerably more RAM (64 GB or more may be useful, depending on the model). |

**You do not need Visual Studio, CMake, Git, Python or the full CUDA Toolkit merely to test the precompiled binaries.** The provided ZIP includes CUDA 12.9 runtime DLLs (`cudart64_12.dll`, `cublas64_12.dll`, `cublasLt64_12.dll`). A working NVIDIA driver is still mandatory.

Open PowerShell and confirm the card appears:

```powershell
nvidia-smi
```

If the card is not listed, fix driver/hardware detection first. A model already using most VRAM can interfere with full model loading, though the small device self-test may still succeed.

## 2. Download the compiled ZIP

Go to **[GitHub Releases](https://github.com/Procyan/Strata-Tesla-M40-sm52/releases)** and look for an attached asset named `Strata-M40-Windows-x64.zip`.

**Do not download “Source code (zip)” as a substitute**: it does not include the compiled executables. If the binary asset is not listed, the publisher still needs to upload it.

Save the file in your normal Downloads directory.

## 3. Extract (no administrator rights normally needed)

Install into a dedicated directory in your user profile to avoid conflicting with any existing Strata installation:

```powershell
$zip = Join-Path $env:USERPROFILE 'Downloads\Strata-M40-Windows-x64.zip'
$dest = Join-Path $env:LOCALAPPDATA 'Strata-M40'
if (-not (Test-Path -LiteralPath $zip)) { throw "Missing ZIP: $zip" }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force
Get-ChildItem -LiteralPath $dest -File | Select-Object Name,Length
```

You should see `strata.exe`, `strata-device.exe`, `strata_kq.dll`, `cudart64_12.dll`, `cublas64_12.dll`, `cublasLt64_12.dll` and `SHA256SUMS.txt`. Keep the files together; do not place CUDA DLLs in `System32`.

## 4. Check integrity

The archive includes `SHA256SUMS.txt`. This command verifies **every entry in that manifest** against the extracted file:

```powershell
$dest = Join-Path $env:LOCALAPPDATA 'Strata-M40'
Get-Content (Join-Path $dest 'SHA256SUMS.txt') | ForEach-Object {
    if ($_ -match '^([a-fA-F0-9]{64})\s+(.+)$') {
        $expected = $matches[1]; $name = $matches[2]
        $actual = (Get-FileHash -LiteralPath (Join-Path $dest $name) -Algorithm SHA256).Hash
        if ($actual -ne $expected) { throw "HASH MISMATCH: $name" }
        Write-Host "OK: $name"
    } else { throw "Invalid SHA256SUMS entry: $_" }
}
```

These hashes detect extraction errors or modifications relative to the included manifest. For authenticity, the repository owner should also publish the **ZIP's SHA-256 hash separately** on the GitHub Release page.

## 5. Detect the GPU and run the device self-test

```powershell
$exe = Join-Path $env:LOCALAPPDATA 'Strata-M40\strata-device.exe'
& $exe --list-devices
if ($LASTEXITCODE -ne 0) { throw "GPU detection failed, exit code $LASTEXITCODE" }
& $exe --selftest
if ($LASTEXITCODE -ne 0) { throw "GPU self-test failed, exit code $LASTEXITCODE" }
Write-Host 'M40 DEVICE SELF-TEST PASSED'
```

Successful detection should mention `Tesla M40 24GB` and `compute capability 5.2`. A successful self-test ends with `strata-device selftest OK` and exit code 0.

The memory planner may print `DOES NOT FIT` if another model has occupied most of the card. This is not necessarily a device self-test failure; the final self-test result is decisive.

## 6. Running an AI model

This ZIP **does not contain model weights, a ready-to-use model configuration, or a complete model installer**. The first verified step is GPU compatibility testing, not chatting with a model. To perform inference, follow the model setup documentation in this repository and obtain a supported model and its configuration. A previous experimental smoke test used Coder IQ1_M, but sustained inference, long contexts, and portability across other PCs remain unverified.

If you encounter problems, open [an issue](https://github.com/Procyan/Strata-Tesla-M40-sm52/issues) and include the GPU model, driver version, `nvidia-smi` output, complete self-test output, and any errors. Do not upload private credentials or model files.

## Credit and status

Original project: [Niko1221/Strata](https://github.com/Niko1221/Strata). This experimental compatibility fork retains upstream history and its licensing notices. The original `sm_52` port is preserved under tag `v0.1.0-m40-original`.

See [Tesla M40 investigation](docs/M40_INVESTIGATION.md) for the test environment and limitations, and [Tesla M40 quick-start](TESLA_M40_QUICKSTART.md) for source-compilation instructions.
