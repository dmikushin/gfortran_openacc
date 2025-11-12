# Getting OpenACC program to run on GPU with GCC 12

This works for official GCC 12 packaged for Ubuntu 22.04.

GCC 13 unfortunately has some missing files.

## Prerequisites

Some dependencies are essential, such as:

```
sudo apt install gcc-12-offload-nvptx
```

## Usage

```
make
make test
```

## Testing

Use `nvidia-smi -l 1` to continuously monitor the GPU usage during the test: you should notice the GPU utilization.

