#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void remplirMatrice(int *mat, int lignes, int colonnes, int *hors)
{
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int lig = blockIdx.y * blockDim.y + threadIdx.y;

    if (lig < lignes && col < colonnes) {
        mat[lig * colonnes + col] = lig * colonnes + col;
    } else {
        atomicAdd(hors, 1);
    }
}

int main(int argc, char* argv[])
{
    if (argc != 5) {
        printf("Utilisation : %s lignes colonnes blockDimX blockDimY\n", argv[0]);
        return 1;
    }

    int lignes = atoi(argv[1]);
    int colonnes = atoi(argv[2]);
    int blockX = atoi(argv[3]);
    int blockY = atoi(argv[4]);

    dim3 block(blockX, blockY);
    dim3 grille((colonnes + blockX - 1) / blockX,
                (lignes + blockY - 1) / blockY);

    int totalThreads = grille.x * grille.y * block.x * block.y;

    int *d_mat, *d_hors;
    cudaMalloc(&d_mat, lignes * colonnes * sizeof(int));
    cudaMalloc(&d_hors, sizeof(int));
    cudaMemset(d_hors, 0, sizeof(int));

    remplirMatrice<<<grille, block>>>(d_mat, lignes, colonnes, d_hors);
    cudaDeviceSynchronize();

    int *h_mat = (int*)malloc(lignes * colonnes * sizeof(int));
    int h_hors;

    cudaMemcpy(h_mat, d_mat, lignes * colonnes * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(&h_hors, d_hors, sizeof(int), cudaMemcpyDeviceToHost);

    printf("Matrice %dx%d :\n", lignes, colonnes);
    for (int i = 0; i < lignes; i++) {
        for (int j = 0; j < colonnes; j++)
            printf("%4d ", h_mat[i * colonnes + j]);
        printf("\n");
    }

    printf("\nDimensions de la grille : (%d, %d)\n", grille.x, grille.y);
    printf("Nombre total de threads lancés : %d\n", totalThreads);
    printf("Threads hors matrice : %d\n", h_hors);

    cudaFree(d_mat);
    cudaFree(d_hors);
    free(h_mat);

    return 0;
}