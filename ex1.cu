#include <stdio.h>
#include <stdlib.h>

__global__ void kernel()
{
    int globalId =
        (blockIdx.y * gridDim.x + blockIdx.x) *
        (blockDim.x * blockDim.y) +
        (threadIdx.y * blockDim.x + threadIdx.x);

    printf("Block(%d,%d) Thread(%d,%d) -> Global: %d\n",
           blockIdx.x, blockIdx.y,
           threadIdx.x, threadIdx.y,
           globalId);
}

int main(int argc, char *argv[])
{
    if (argc != 5) {
        printf("Usage: %s gridDimX gridDimY blockDimX blockDimY\n", argv[0]);
        return 1;
    }

    int gridDimX  = atoi(argv[1]);
    int gridDimY  = atoi(argv[2]);
    int blockDimX = atoi(argv[3]);
    int blockDimY = atoi(argv[4]);

    dim3 grid(gridDimX, gridDimY);
    dim3 block(blockDimX, blockDimY);

    kernel<<<grid, block>>>();
    cudaDeviceSynchronize();

    return 0;
}