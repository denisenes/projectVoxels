# Porting projectVoxels to WSL2/Linux — Plan

## Project inventory

| Component | Status on WSL2 |
|---|---|
| `main.cu` (863 lines, CUDA raycaster), `geometry.cuh`, `voxel.cuh` | Portable, except 3 cursor-call sites |
| `rayCast.cu` | Empty file (harmless) |
| `graphics/` — bundled SFML 2.5.1 headers + Windows `.lib`/`.dll` in `graphics/lib` | Unusable on Linux (MSVC libs) |
| `CMakeLists.txt` | Targets Windows: `find_library(... graphics/lib)`, links `sfml-main`, expects `nvcc` |
| `cmake-build-debug/` | Stale Windows CMake cache — delete |
| Assets: `cross.png`, `sansation.ttf` | Loaded by relative path → run from repo root |

Environment: Debian 13 (trixie), WSL2, WSLg working (`DISPLAY=:0`), GPU visible —
RTX 2060 (sm_75), driver 610.74 / CUDA UMD 13.3 via `/usr/lib/wsl/lib/libcuda.so.1`.
Missing: `nvcc`, `cmake`. Debian trixie dropped `nvidia-cuda-toolkit` → install CUDA
toolkit from NVIDIA directly. Available in apt: `cmake 3.31`, `libsfml-dev 2.6.2`
(API-compatible with bundled 2.5.1), `gcc-14`.

## Steps

1. **Install toolchain**
   - `apt install cmake build-essential libsfml-dev libgl-dev pkg-config`
   - CUDA toolkit 13.x (compiler + headers only — never the Linux driver, WSL provides it)
     via NVIDIA `cuda-keyring` deb repo (debian12 channel), minimal set:
     `cuda-cudart-dev-13-x cuda-nvcc-13-x`. Fallback: official `.run` installer
     with `--toolkit --no-driver`.
2. **Port the code (`main.cu`)**
   - Drop `winuser.h` / `Windows.h` includes.
   - Replace `SetCursorPos`/`GetCursorPos`+`POINT` (3 call sites) with cross-platform
     `sf::Mouse::setPosition` / `sf::Mouse::getPosition`.
   - Wrap `#define M_PI 3.1415` in `#ifndef M_PI`.
3. **Modernize `CMakeLists.txt`**
   - `find_package(SFML 2 COMPONENTS graphics window system REQUIRED)`,
     `find_package(OpenGL REQUIRED)`; link `sfml-graphics sfml-window sfml-system OpenGL::GL`.
   - Drop `sfml-main` (Windows-only) and `freetype` (transitive via SFML).
   - `set(CMAKE_CUDA_ARCHITECTURES 75)` (RTX 2060), C++17.
4. **Build**
   - Remove stale `cmake-build-debug`, then `cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build`.
   - Fix residual compile errors iteratively (nvcc/gcc-14 quirks).
5. **Run & verify**
   - `./build/voxelsWithCuda` from repo root (asset paths). Verify render, mouse-look,
     CUDA event timing. Benchmark per-frame `cudaMemcpy` + `setPixel` loop.
6. **Optional cleanups**: `build/` in `.gitignore`, build docs in `README.md`,
   ignore bundled Windows `graphics/lib`.

Risks are low: no exotic Windows APIs, no CUDA–OpenGL interop (rendering goes through
CPU + SFML texture), WSLg + CUDA both confirmed present. Main unknown is CUDA-repo
packaging on trixie — hence the runfile fallback.

## Result (completed)

All steps done. Notes beyond the original plan:

- **apt/Sequoia issue**: Debian trixie's apt 3.0 (sqv) rejects NVIDIA's repo key
  (SHA-1 self-signature). Fixed with `APT::Key::GPGVCommand "/usr/bin/gpgv"`.
- **MSVC-ism**: `BOX_SIZE.` (macro fused with dot) — conforming preprocessors reject
  it; removed the stray dot (3 sites).
- **Latent kernel bug**: `__syncthreads()` inside the divergent "ray hit voxel" branch
  of `traversePixels` deadlocked the block whenever any pixel hit sky (undefined
  behavior per CUDA docs). Fixed by initializing `sharedCam` in one thread + an
  unconditional barrier up front, and removing the divergent barrier. This was not
  a porting artifact — it is a real bug that could hang on Windows too.
- **Removed** `cudaDeviceSynchronize()` call from inside the kernel (debug leftover).
- Verified: builds clean with nvcc 13.3, renders correctly (sky, lit voxels, diffuse
  gradient, shadows) at ~4-5 fps at 1024x1024 on RTX 2060 via WSLg.

Open items: mouse-look relies on cursor warping (`sf::Mouse::setPosition`), which
WSLg may emulate unreliably — needs interactive testing.
