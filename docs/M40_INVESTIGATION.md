# Tesla M40 / Maxwell sm_52 investigation

## Status

The CUDA 12 build and setup-selection path admit compute capability 5.2 when the existing experimental older-NVIDIA
option is enabled. A Windows Tesla M40 24 GB host compiled this revision, passed the device and kernel smoke tests, and
generated a short response. This establishes experimental M40 inference for this tested configuration, not general
stability, answer quality, or benchmark performance.

## Baseline

- Repository commit inspected: `296b59d2f73c8f04a805df29c2fa97655adace78` (2026-10-14).
- Existing legacy path: CUDA 12.x with `STRATA_EXPERIMENTAL_SM60=ON`, previously limited to compute capability 6.0 and
  newer.
- Existing runtime check: `src/core/device.cu` rejected devices below compute capability 6.0 in that build.
- Existing setup selection: `setup.py` selected the legacy CUDA 12 engine for devices from 6.0 through 7.0.
- Existing instruction fallbacks: `include/strata/kernels/dp4a.hpp` substitutes a byte-wise dot-product implementation
  below sm_61 and removes `__nanosleep` below sm_70.
- The initial source review environment had no `nvcc` or CUDA device; host validation was therefore required.

## Initial change

- Lowered the experimental CMake architecture floor and CUDA device check to sm_52.
- Included sm_52 devices in setup's opt-in CUDA 12 selection. The default CUDA 13 path remains unchanged.
- Added setup tests for M40 detection and engine selection.
- Marked M40 as unvalidated in the older-GPU documentation.

## Validation so far

- `python -m unittest tools.test_setup_older_gpus tools.test_setup_choices` — passed (69 tests).
- `git diff --check` — passed.
- Windows host: CUDA Toolkit 12.9.86, MSVC 19.44.35229.0 (Visual Studio 2022 Build Tools), CMake 4.4.4,
  Tesla M40 24 GB (compute capability 5.2), NVIDIA driver 582.78.
- CMake configure: `STRATA_ENABLE_CUDA=ON`, `STRATA_BUILD_TESTS=ON`, `STRATA_EXPERIMENTAL_SM60=ON`,
  `CMAKE_CUDA_ARCHITECTURES=52` — passed.
- Release build of `strata` and `strata-device` — passed. CUDA compilation emitted expected deprecated-target and
  source warnings; no compile errors.
- `strata-device --list-devices` — reported Tesla M40 24 GB, compute capability 5.2, with no architecture rejection.
- `strata-device --selftest` — passed; allocated and exercised the 64 MiB device arena and refused over-allocation.
- Six synthetic GPU parity tests passed on the M40: `dequant_s2_parity`, `s2_gemv_parity`, `iq_multi_parity`,
  `mmvq_multi_parity`, `mmvq_il_parity`, and `dequant_wide_parity`.
- Setup completed for Coder IQ1_M and generated `run-coder-iq1_m.bat` using the experimental CUDA 12 engine.
- End-to-end smoke inference completed at context 131072. A short 8-token answer took 287 ms (27.9 generated tokens/s);
  its 22-token prompt took 636 ms (34.6 prompt tokens/s). A preceding request capped at 32 tokens ended in reasoning
  without a final answer (22.5 generated tokens/s). These short requests are smoke checks, not representative benchmarks.
- Not yet validated: sustained or repeated inference, answer quality, long-context correctness, memory pressure over time,
  server concurrency, vision, or performance against another backend.

## Next validation

Run a longer coding prompt and several repeated requests, watch VRAM/RAM and the server log for CUDA errors, then record
the results. Keep CUDA 13 disabled for this target: it has no offline code generation for sm_52.
