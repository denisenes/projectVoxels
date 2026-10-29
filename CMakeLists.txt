cmake_minimum_required(VERSION 3.17)
project(voxelsWithCuda LANGUAGES CUDA CXX)

set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)

# RTX 2060 (Turing, compute capability 7.5)
set(CMAKE_CUDA_ARCHITECTURES 75)

add_executable(voxelsWithCuda main.cu rayCast.cu geometry.cuh voxel.cuh)
set_target_properties(voxelsWithCuda PROPERTIES CUDA_SEPARABLE_COMPILATION ON)

# System SFML 2.x (the bundled graphics/ tree contains Windows-only binaries)
find_package(SFML 2 COMPONENTS graphics window system REQUIRED)
find_package(OpenGL REQUIRED)

target_link_libraries(voxelsWithCuda PRIVATE sfml-graphics sfml-window sfml-system OpenGL::GL)
