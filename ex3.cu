#include <stdio.h>
#include <cuda_runtime.h>

#define N 1000000

__global__ void doubler(float *data)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N)
        data[i] *= 2.0f;
}

int main()
{
    float *h_data = (float*)malloc(N * sizeof(float));
    float *d_data;
    cudaMalloc(&d_data, N * sizeof(float));

    int taillesBloc[] = {32, 64, 128, 256, 512, 1024};

    for (int k = 0; k < 6; k++) {

        int tailleBloc = taillesBloc[k];
        int nbBlocs = (N + tailleBloc - 1) / tailleBloc;
        int totalThreads = nbBlocs * tailleBloc;
        int inutiles = totalThreads - N;

        for (int i = 0; i < N; i++)
            h_data[i] = 1.0f;

        cudaMemcpy(d_data, h_data, N * sizeof(float), cudaMemcpyHostToDevice);

        cudaEvent_t debut, fin;
        cudaEventCreate(&debut);
        cudaEventCreate(&fin);

        cudaEventRecord(debut);
        doubler<<<nbBlocs, tailleBloc>>>(d_data);
        cudaEventRecord(fin);
        cudaEventSynchronize(fin);

        float temps;
        cudaEventElapsedTime(&temps, debut, fin);

        cudaMemcpy(h_data, d_data, N * sizeof(float), cudaMemcpyDeviceToHost);

        int correct = 1;
        for (int i = 0; i < N; i++) {
            if (h_data[i] != 2.0f) {
                correct = 0;
                break;
            }
        }

        printf("Taille du bloc : %d\n", tailleBloc);
        printf("Nombre de blocs : %d\n", nbBlocs);
        printf("Threads totaux : %d\n", totalThreads);
        printf("Threads inutiles : %d\n", inutiles);
        printf("Temps d'exécution (ms) : %f\n", temps);
        printf("Vérification : %s\n\n", correct ? "OK" : "ERREUR");

        cudaEventDestroy(debut);
        cudaEventDestroy(fin);
    }

    cudaFree(d_data);
    free(h_data);
    return 0;
}