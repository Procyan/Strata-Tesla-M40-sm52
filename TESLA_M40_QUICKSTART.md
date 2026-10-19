# Tesla M40 (Maxwell sm_52) — experimental Strata port

This repository preserves the first Tesla M40 compatibility port of [Strata](https://github.com/Niko1221/Strata), based on upstream commit `296b59d2` and M40 integration commit `17f3033a`.

**Original source snapshot:** [v0.1.0-m40-original](https://github.com/Procyan/Strata-Tesla-M40-sm52/releases/tag/v0.1.0-m40-original) (the source tag is available even without a manually published GitHub Release).

**Status:** Experimental. On one Windows Tesla M40 24 GB system the CUDA build, device self-test, six GPU parity tests, and a short end-to-end inference smoke test passed. This does **not** establish long-run reliability or general model compatibility. Details: [M40 investigation](docs/M40_INVESTIGATION.md).

## Tested environment

- NVIDIA Tesla M40 24 GB, Maxwell compute capability **5.2**
- Windows; NVIDIA driver **582.78**
- CUDA Toolkit **12.9.86** (**not CUDA 13**, which drops Maxwell code generation)
- Visual Studio 2022 Build Tools, MSVC **19.44.35229.0**
- CMake **4.4.4**

## Download and build from source (Windows PowerShell)

Install Git, the CUDA 12.9 toolkit, CMake, Python dependencies required by Strata, and Visual Studio 2022 C++ Build Tools. Use a Visual Studio developer PowerShell so the MSVC compiler is on PATH.

```powershell
git clone https://github.com/Procyan/Strata-Tesla-M40-sm52.git
cd Strata-Tesla-M40-sm52
git checkout v0.1.0-m40-original
nvcc --version
nvidia-smi
cmake -S . -B build-m40 -DSTRATA_ENABLE_CUDA=ON -DSTRATA_BUILD_TESTS=ON -DSTRATA_EXPERIMENTAL_SM60=ON -DCMAKE_CUDA_ARCHITECTURES=52
cmake --build build-m40 --config Release --target strata strata-device --parallel 4
.\build-m40\Release\strata-device.exe --list-devices
.\build-m40\Release\strata-device.exe --selftest
```

Depending on the CMake generator, executables may instead be directly under `build-m40\`. Building with tests enabled supports further kernel verification; refer to [docs/M40_INVESTIGATION.md](docs/M40_INVESTIGATION.md) for the six tests actually run.

**Note:** `STRATA_EXPERIMENTAL_SM60=ON` is the historical flag name; the M40 patch extends this experimental path down to `sm_52`. The `CMAKE_CUDA_ARCHITECTURES=52` setting explicitly targets Maxwell.

The original smoke test used **Coder IQ1_M** with a **131072** context setting, but setup requires the model weights and additional host RAM/storage. A GPU-compatible compilation alone does not download a model or prove model execution on another system. See the upstream [installation guide](docs/INSTALL.md) and the M40 investigation for context.

## Contributing

Fork this repository, create a branch, test your changes, and open a pull request with GPU details, CUDA/driver/tool versions, build command, and reproducible logs. In particular, longer inference runs and other Maxwell GPUs need independent testing.

This is a community compatibility fork, **not** an official NVIDIA or original Strata release. Keep upstream attribution and existing license and third-party notices intact. The tagged original snapshot is preserved; later documentation and changes should be committed separately.
