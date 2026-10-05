#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void inversion(unsigned char *img, int largeur, int hauteur, int *hors)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < largeur && y < hauteur) {
        int idx = y * largeur + x;
        img[idx] = 255 - img[idx];
    } else {
        atomicAdd(hors, 1);
    }
}

int main(int argc, char* argv[])
{
    if (argc != 3) {
        printf("Utilisation : %s largeur hauteur\n", argv[0]);
        return 1;
    }

    int largeur = atoi(argv[1]);
    int hauteur = atoi(argv[2]);
    int taille = largeur * hauteur;

    unsigned char *h_img = (unsigned char*)malloc(taille);
    unsigned char *h_ref = (unsigned char*)malloc(taille);

    for (int y = 0; y < hauteur; y++)
        for (int x = 0; x < largeur; x++) {
            h_img[y * largeur + x] = (x + y) % 256;
            h_ref[y * largeur + x] = 255 - ((x + y) % 256);
        }

    unsigned char *d_img;
    int *d_hors;
    cudaMalloc(&d_img, taille);
    cudaMalloc(&d_hors, sizeof(int));
    cudaMemset(d_hors, 0, sizeof(int));

    cudaMemcpy(d_img, h_img, taille, cudaMemcpyHostToDevice);

    dim3 block(16,16);
    dim3 grille((largeur + 15)/16,
                (hauteur + 15)/16);

    int totalThreads = grille.x * grille.y * 16 * 16;

    inversion<<<grille, block>>>(d_img, largeur, hauteur, d_hors);
    cudaDeviceSynchronize();

    cudaMemcpy(h_img, d_img, taille, cudaMemcpyDeviceToHost);

    int h_hors;
    cudaMemcpy(&h_hors, d_hors, sizeof(int), cudaMemcpyDeviceToHost);

    int correct = 1;
    for (int i = 0; i < taille; i++) {
        if (h_img[i] != h_ref[i]) {
            correct = 0;
            break;
        }
    }

    printf("Dimensions de la grille : (%d, %d)\n", grille.x, grille.y);
    printf("Nombre total de threads lancés : %d\n", totalThreads);
    printf("Threads hors image : %d\n", h_hors);
    printf("%s\n", correct ? "Vérification réussie" : "Erreur de vérification");

    cudaFree(d_img);
    cudaFree(d_hors);
    free(h_img);
    free(h_ref);

    return 0;
}