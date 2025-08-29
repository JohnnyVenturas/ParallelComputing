#include <stdio.h>
#include <cuda_runtime.h>

int main() {
    int deviceCount;
    cudaGetDeviceCount(&deviceCount);
    
    if (deviceCount == 0) {
        printf("No CUDA-capable GPU found\n");
        return 1;
    }
    
    printf("Found %d CUDA-capable device(s)\n", deviceCount);
    
    for (int i = 0; i < deviceCount; i++) {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);
        
        printf("\nDevice %d: \"%s\"\n", i, prop.name);
        printf("  Compute capability: %d.%d\n", prop.major, prop.minor);
        printf("  Max threads per block: %d\n", prop.maxThreadsPerBlock);
        printf("  Max threads per multiprocessor: %d\n", prop.maxThreadsPerMultiProcessor);
        printf("  Number of multiprocessors: %d\n", prop.multiProcessorCount);
        printf("  Warp size: %d\n", prop.warpSize);
        printf("  Max block dimensions: (%d, %d, %d)\n", 
               prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
        printf("  Max grid dimensions: (%d, %d, %d)\n", 
               prop.maxGridSize[0], prop.maxGridSize[1], prop.maxGridSize[2]);
        printf("  Shared memory per block: %zu bytes\n", prop.sharedMemPerBlock);
        printf("  Total global memory: %zu bytes\n", prop.totalGlobalMem);
        
        // Calculate some optimal values
        int warpsPerBlock = 256 / prop.warpSize;
        printf("\nWith 256 threads per block:\n");
        printf("  Warps per block: %d\n", warpsPerBlock);
        printf("  Blocks per multiprocessor (occupancy estimate): %d\n", 
               prop.maxThreadsPerMultiProcessor / 256);
    }
    
    return 0;
}