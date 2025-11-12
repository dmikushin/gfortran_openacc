cmake_minimum_required(VERSION 3.16)

# Try to find gfortran-12 first
find_program(GFORTRAN12 gfortran-12)
if(GFORTRAN12)
    set(CMAKE_Fortran_COMPILER ${GFORTRAN12})
endif()

project(gfortran_openacc LANGUAGES Fortran)

# Add the cmake directory to the module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Find OpenACC support
find_package(OpenACC REQUIRED)

# Set the GPU architecture (can be overridden with -DOpenACC_GPU_ARCH=sm_XX)
if(NOT DEFINED OpenACC_GPU_ARCH)
    set(OpenACC_GPU_ARCH "sm_53" CACHE STRING "GPU architecture for OpenACC")
endif()

# Create the test executable using the original Fortran source
add_executable(vector_add_openacc vector_add_openacc.f90)

# Add OpenACC support to target
add_openacc_to_target(vector_add_openacc)

# Enable testing with CTest
enable_testing()

# Add OpenACC test
add_test(NAME openacc_vector_add_test
    COMMAND ${CMAKE_COMMAND} -E env ACC_DEVICE_TYPE=nvidia GOMP_DEBUG=1 $<TARGET_FILE:vector_add_openacc>
)

