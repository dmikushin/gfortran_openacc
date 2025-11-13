# OpenACC with GFortran: CMake Integration and GPU Compilation

This project demonstrates OpenACC GPU acceleration using GFortran with proper CMake integration. It includes workarounds for several technical challenges in the GCC OpenACC toolchain.

## Technical Problems and Workarounds

### GPU Architecture Mismatch
**Problem**: GFortran's nvptx backend defaults to `sm_30` architecture, but modern GPUs require newer architecture like `sm_80` for A100.

**Solution**: Custom `ptxas` wrapper script that intercepts GPU architecture arguments and replaces `sm_30` with the target architecture (configurable via `OpenACC_GPU_ARCH`).

### Environment Setup Complexity
**Problem**: OpenACC compilation requires specific environment variables (`CUDA_HOME`, `GPU_ARCH`) and PATH modifications during both compilation and linking phases.

**Solution**: CMake `RULE_LAUNCH_COMPILE` and `RULE_LAUNCH_LINK` properties to inject environment setup via `cmake -E env`.

### CMake Integration Challenge
**Problem**: Standard CMake patterns like `find_package()` and `target_link_libraries()` don't naturally fit OpenACC's compilation model which requires flags and environment setup that cannot be handled by an interface library linking alone.

**Solution**: Simple macro `add_openacc_to_target()` that directly applies all necessary compile flags, link flags, and environment configuration to any target.

## CMake Integration

This project provides a complete CMake module for OpenACC integration similar to how MPI is handled in CMake.

### Usage

```cmake
cmake_minimum_required(VERSION 3.16)

# Find GFortran with OpenACC support
find_program(GFORTRAN12 gfortran-12)
if(GFORTRAN12)
    set(CMAKE_Fortran_COMPILER ${GFORTRAN12})
endif()

project(my_project LANGUAGES Fortran)

# Add cmake module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Find OpenACC support
find_package(OpenACC REQUIRED)

# Create executable
add_executable(my_openacc_app main.f90)

# Add OpenACC support - applies all flags and environment setup
add_openacc_to_target(my_openacc_app)
```

### Configuration Options

- `OpenACC_GPU_ARCH`: Target GPU architecture (default: `sm_53`)
- `OpenACC_CUDA_HOME`: CUDA installation path (default: `/usr/local/cuda`)
- `OpenACC_SAVE_PTX`: Save PTX intermediate code during compilation (default: `OFF`)

Example:
```bash
cmake -DOpenACC_GPU_ARCH=sm_70 -DOpenACC_SAVE_PTX=ON ..
```

When `OpenACC_SAVE_PTX` is enabled, the compiler will save intermediate PTX files in the build directory alongside object files. This is useful for:
- Debugging GPU code generation
- Analyzing PTX assembly
- Understanding compiler optimizations

### What the Macro Does

`add_openacc_to_target(target_name)` automatically:

1. **Applies Compilation Flags**: `-fopenacc -foffload=nvptx-none -foffload-options=nvptx-none=-misa=${OpenACC_GPU_ARCH}`
2. **Applies Link Flags**: Same as compilation flags for proper GPU code generation
3. **Creates ptxas Wrapper**: Intercepts and corrects GPU architecture during compilation
4. **Sets Environment**: Configures `PATH`, `CUDA_HOME`, and `GPU_ARCH` for both compilation and linking

## Proof of Concept

The original proof of concept demonstrates basic OpenACC functionality with GCC 12 on Ubuntu 22.04.

### Prerequisites

Essential dependencies for OpenACC support:

```bash
sudo apt install gcc-12-offload-nvptx gfortran-12
```

GCC 13 unfortunately has missing files and is not recommended.

### Makefile Usage

For quick testing without CMake:

```bash
make
make test
```

To save PTX intermediate code with Makefile:

```bash
make SAVE_PTX=1
```

This will generate `.ptx` and other intermediate files in the current directory.

### CMake Build

```bash
mkdir build && cd build
cmake ..
make -j$(nproc)
ctest -V
```

### Testing GPU Utilization

Monitor GPU usage during execution:
```bash
nvidia-smi -l 1
```

You should observe GPU utilization spikes during OpenACC kernel execution.

## Implementation Details

### Vector Addition Test

The test program (`vector_add_openacc.f90`) performs vector addition on 10 million elements across 100 iterations:

```fortran
!$acc parallel loop copyin(a, b) copyout(c)
do i = 1, N
    c(i) = a(i) + b(i)
end do
!$acc end parallel loop
```

### Debug Output

With `GOMP_DEBUG=1`, the test shows detailed GPU kernel execution including:
- PTX code generation targeting correct GPU architecture
- Kernel launch parameters (gangs, workers, vectors)
- Memory transfer operations

This comprehensive approach provides a robust foundation for OpenACC development with CMake while addressing the technical challenges of the GCC OpenACC toolchain.
