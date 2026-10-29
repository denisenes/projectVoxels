# projectVoxels

CUDA voxel raytracer with SFML window output.

![logo](logo.jpg)

## Requirements

- NVIDIA GPU (built/tested for compute capability 7.5, see `CMAKE_CUDA_ARCHITECTURES` in `CMakeLists.txt`)
- CUDA toolkit 13.x (`nvcc` + `cudart` headers)
- CMake ≥ 3.17, a C++17 compiler
- SFML 2.x development package (system-wide)

On WSL2 the GPU driver comes from the Windows host — install only the CUDA
toolkit, never the Linux driver.

### Debian/Ubuntu setup

```bash
sudo apt install cmake build-essential libsfml-dev libgl-dev pkg-config
```

CUDA toolkit (NVIDIA repo, Debian 12 channel also works on newer Debian):

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-nvcc-13-3 cuda-cudart-dev-13-3
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
```

> **Note (Debian trixie):** apt 3.0 verifies repos with `sqv`, which rejects
> NVIDIA's repo key (SHA-1 self-signature) and fails with
> `The repository ... is not signed`. Workaround: switch apt back to classic
> `gpgv` — `echo 'APT::Key::GPGVCommand "/usr/bin/gpgv";' | sudo tee /etc/apt/apt.conf.d/99-gpgv-compat`

## Build

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

## Run

Run from the repository root (assets `cross.png` and `sansation.ttf` are loaded
by relative path):

```bash
./build/voxelsWithCuda
```

On WSL2 the window opens via WSLg.

### Controls

| Input | Action |
|---|---|
| Mouse | Look around |
| Left / Right mouse button | Delete / add voxel |
| `Up` / `Down` | Increase / decrease movement speed |
| `+` / `-` | Increase / decrease mouse sensitivity |
| `V` | Toggle crosshair |
| `I` | Print camera debug info |
| `Esc` | Quit |

## Project layout

- `main.cu` — renderer, CUDA ray traversal kernel, main loop
- `geometry.cuh` — vectors, matrices, rays, boxes
- `voxel.cuh` — voxel structure
- `graphics/` — legacy bundled SFML 2.5.1 (Windows binaries; unused on Linux,
  the system SFML is linked instead)
- `PLAN.md` — porting plan from Windows to WSL2/Linux
