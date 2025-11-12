FC = gfortran-12
# GPU architecture - Quadro P500 has Compute Capability 6.1
# GCC-12 supports: sm_30, sm_35, sm_53, sm_70, sm_75, sm_80
# For CC 6.1, we use sm_53 (closest supported)
# You can override this by setting GPU_ARCH=sm_XX on command line
GPU_ARCH ?= sm_53

# OpenACC flags with configurable GPU architecture
# Use wrapper to avoid hardcoded sm_30 in nvptx-as
ACCFLAGS_GPU = -fopenacc -foffload=nvptx-none -foffload-options=nvptx-none=-misa=$(GPU_ARCH)
CFLAGS = -g -O3 -Wall

vector_add_openacc: vector_add_openacc.f90
	CUDA_HOME=/usr/local/cuda GPU_ARCH=$(GPU_ARCH) PATH="$(PWD)/cuda_wrapper:$(PATH)" $(FC) $(CFLAGS) $(ACCFLAGS_GPU) -o $@ $<

test: vector_add_openacc
	ACC_DEVICE_TYPE=nvidia GOMP_DEBUG=1 ./vector_add_openacc

clean:
	rm -f vector_add_openacc *.o *.mod
