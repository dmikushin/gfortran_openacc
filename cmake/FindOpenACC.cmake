# FindOpenACC.cmake
#
# Find OpenACC support for Fortran, C and C++
# Based on gfortran-openacc-test implementation using gfortran-12
#
# This module provides:
#   add_openacc_to_target(target_name) - Macro to add OpenACC support to target
#
# Variables:
#   OpenACC_FOUND            - True if OpenACC support is available
#   OpenACC_GPU_ARCH         - GPU architecture to target (default: sm_53)
#   OpenACC_CUDA_HOME        - CUDA installation directory

if(OpenACC_FOUND)
    return()
endif()

# Set default GPU architecture if not specified
if(NOT DEFINED OpenACC_GPU_ARCH)
    set(OpenACC_GPU_ARCH "sm_53" CACHE STRING "GPU architecture for OpenACC (e.g., sm_53, sm_70, sm_75)")
endif()

# Find CUDA installation
if(NOT DEFINED OpenACC_CUDA_HOME)
    if(DEFINED ENV{CUDA_HOME})
        set(OpenACC_CUDA_HOME "$ENV{CUDA_HOME}")
    else()
        set(OpenACC_CUDA_HOME "/usr/local/cuda")
    endif()
endif()

# Check if CUDA is available
if(NOT EXISTS "${OpenACC_CUDA_HOME}/bin/ptxas")
    if(OpenACC_FIND_REQUIRED)
        message(FATAL_ERROR "CUDA not found at ${OpenACC_CUDA_HOME}. Please set OpenACC_CUDA_HOME or CUDA_HOME environment variable.")
    endif()
    return()
endif()

# Test if gfortran supports OpenACC
find_program(GFORTRAN12 gfortran-12)
if(GFORTRAN12)
    execute_process(
        COMMAND ${GFORTRAN12} -fopenacc --help
        RESULT_VARIABLE OPENACC_TEST_RESULT
        OUTPUT_QUIET
        ERROR_QUIET
    )
    if(OPENACC_TEST_RESULT EQUAL 0)
        set(OpenACC_FOUND TRUE)
    endif()
endif()

# If gfortran-12 not found, try regular gfortran
if(NOT OpenACC_FOUND)
    find_program(GFORTRAN gfortran)
    if(GFORTRAN)
        execute_process(
            COMMAND ${GFORTRAN} -fopenacc --help
            RESULT_VARIABLE OPENACC_TEST_RESULT
            OUTPUT_QUIET
            ERROR_QUIET
        )
        if(OPENACC_TEST_RESULT EQUAL 0)
            set(OpenACC_FOUND TRUE)
        endif()
    endif()
endif()

# Macro to add OpenACC support to any target
macro(add_openacc_to_target target_name)
    if(NOT TARGET ${target_name})
        message(FATAL_ERROR "Target ${target_name} does not exist")
    endif()

    # Create wrapper directory and ptxas wrapper script
    set(WRAPPER_DIR "${CMAKE_BINARY_DIR}/cuda_wrapper")
    file(MAKE_DIRECTORY "${WRAPPER_DIR}")

    set(PTXAS_WRAPPER "${WRAPPER_DIR}/ptxas")
    if(NOT EXISTS "${PTXAS_WRAPPER}")
        file(WRITE "${PTXAS_WRAPPER}" "#!/bin/bash
# Wrapper for ptxas to handle GPU architecture
GPU_ARCH=\${GPU_ARCH:-${OpenACC_GPU_ARCH}}

args=()
i=1
while [ \$i -le \$# ]; do
    arg=\${!i}
    case \"\$arg\" in
        --gpu-name)
            # Next argument should be the architecture
            ((i++))
            next_arg=\${!i}
            if [ \"\$next_arg\" = \"sm_30\" ]; then
                args+=(\"--gpu-name\" \"\${GPU_ARCH}\")
            else
                args+=(\"--gpu-name\" \"\$next_arg\")
            fi
            ;;
        *)
            args+=(\"\$arg\")
            ;;
    esac
    ((i++))
done

exec \"${OpenACC_CUDA_HOME}/bin/ptxas\" \"\${args[@]}\"
")
        execute_process(COMMAND chmod +x "${PTXAS_WRAPPER}")
    endif()

    # Add compile options
    target_compile_options(${target_name} PRIVATE
        "-fopenacc"
        "-foffload=nvptx-none"
        "-foffload-options=nvptx-none=-misa=${OpenACC_GPU_ARCH}"
    )

    # Add link options
    target_link_options(${target_name} PRIVATE
        "-fopenacc"
        "-foffload=nvptx-none"
        "-foffload-options=nvptx-none=-misa=${OpenACC_GPU_ARCH}"
    )

    # Setup environment for compilation and linking
    set_target_properties(${target_name} PROPERTIES
        RULE_LAUNCH_COMPILE "${CMAKE_COMMAND} -E env PATH=${WRAPPER_DIR}:$ENV{PATH} CUDA_HOME=${OpenACC_CUDA_HOME} GPU_ARCH=${OpenACC_GPU_ARCH}"
        RULE_LAUNCH_LINK "${CMAKE_COMMAND} -E env PATH=${WRAPPER_DIR}:$ENV{PATH} CUDA_HOME=${OpenACC_CUDA_HOME} GPU_ARCH=${OpenACC_GPU_ARCH}"
    )
endmacro()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenACC
    FOUND_VAR OpenACC_FOUND
    REQUIRED_VARS OpenACC_FOUND
    VERSION_VAR OpenACC_GPU_ARCH
)

if(OpenACC_FOUND)
    message(STATUS "Found OpenACC support")
    message(STATUS "  GPU Architecture: ${OpenACC_GPU_ARCH}")
    message(STATUS "  CUDA Home: ${OpenACC_CUDA_HOME}")
endif()