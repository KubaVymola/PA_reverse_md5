#include <stdio.h>
#include "md5_mine.cu"

// __device__ const char alphabet[] = {
//     'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
//     'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
//     'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
//     'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
//     '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
// };

const char alphabet[] = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
};


__device__ const int alphabetSize = sizeof(alphabet) / sizeof(char);

/**
 * To copy output from the device to the host
 */
__device__ char * my_strcpy(char *dest, uint8_t *src, int length){
    for (int i = 0; i < length; i++) {
        dest[i] = (char)src[i];
    }

    dest[length] = 0;
    
    return dest;
}

__device__ int hex2int(char ch) {
    if (ch >= '0' && ch <= '9')
        return ch - '0';
    if (ch >= 'A' && ch <= 'F')
        return ch - 'A' + 10;
    if (ch >= 'a' && ch <= 'f')
        return ch - 'a' + 10;
    return -1;
}

__device__ bool compareTargetHash(const char * targetHash, uint8_t * digest) {
    for (int i = 0; i < 16; i++) {
        int hashIntVal = hex2int(targetHash[i * 2]) * 16 + hex2int(targetHash[i * 2 + 1]);

        if (hashIntVal != digest[i]) return false;
    }
    return true;
}

__device__ bool nextWord(int * indexes, int wordLength) {
    for (int i = wordLength - 1; i >= 6; i--) {
        indexes[i] = indexes[i] + 1;
        
        if (indexes[i] < alphabetSize) return true;

        indexes[i] = 0;
    }

    return false;
}

__device__ void indexesToChars(int * indexes, uint8_t * chars, int wordLength, char * alphabet) {
    for (int i = 0; i < wordLength; i++) {
        chars[i] = (uint8_t)alphabet[indexes[i]];
    }
}

__device__ void printArray(int * array, int length) {
    for (int i = 0; i < length; i++) {
        printf("%d,", array[i]);
    }

    printf("\n");
}

__device__ void printDigest(uint8_t * digest) {
    printf("Digest: ");
    
    for (int i = 0; i < 16; i++) {
        printf("%x,", digest[i]);
    }
    printf("\n");
}

__global__ void kernelCrackMd5(const char * targetHash, int wordLength, char * output, char * alphabet) {
    uint8_t digest[16];

    int * currentWord = (int *)malloc(sizeof(int) * wordLength);
    uint8_t * currentChars = (uint8_t *)malloc(sizeof(uint8_t) * wordLength + 1);
    currentChars[wordLength] = 0;

    // Get first 6 digits from coordinates in the grid
    int digit0 = blockIdx.x % alphabetSize;
    int digit1 = (blockIdx.x - digit0) / alphabetSize;

    int digit2 = blockIdx.y % alphabetSize;
    int digit3 = (blockIdx.y - digit2) / alphabetSize;
    
    int digit4 = blockIdx.z % alphabetSize;
    int digit5 = (blockIdx.z - digit4) / alphabetSize;

    // If word is shorter than six digits, do not execute comparison multiple times for given word
    if (wordLength > 0) currentWord[0] = digit0;
    else if (digit0 != 0) return;

    if (wordLength > 1) currentWord[1] = digit1;
    else if (digit1 != 0) return;

    if (wordLength > 2) currentWord[2] = digit2;
    else if (digit2 != 0) return;

    if (wordLength > 3) currentWord[3] = digit3;
    else if (digit3 != 0) return;

    if (wordLength > 4) currentWord[4] = digit4;
    else if (digit4 != 0) return;

    if (wordLength > 5) currentWord[5] = digit5;
    else if (digit5 != 0) return;

    for (int i = 6; i < wordLength; i++) {
        currentWord[i] = 0;
    }

    // Get all permutations for the remainder of the word
    // Calculate hashes for all permutations
    do {
        indexesToChars(currentWord, currentChars, wordLength, alphabet);
        md5(currentChars, wordLength, digest);

        if (compareTargetHash(targetHash, digest)) {
            printf("Target word: %s\n", currentChars);
            my_strcpy(output, currentChars, wordLength);
        }

    } while (nextWord(currentWord, wordLength));

    free(currentWord);
    free(currentChars);
}

void crackMd5(const char * targetHash, int wordLength) {
    char * h_Output = (char *)malloc(sizeof(char) * wordLength + 1);
    
    // Device memory to store the output word
    char* d_Output;
    cudaMalloc(&d_Output, sizeof(char) * wordLength + 1);

    char* d_TargetHash;
    cudaMalloc(&d_TargetHash, sizeof(char) * 32);
    cudaMemcpy(d_TargetHash, targetHash, sizeof(char) * 32, cudaMemcpyHostToDevice);

    char* d_alphabet;
    cudaMalloc(&d_alphabet, sizeof(alphabet));
    cudaMemcpy(d_alphabet, alphabet, sizeof(alphabet), cudaMemcpyHostToDevice);

    const int size = alphabetSize;
    
    dim3 blocks(size * size, size * size, size * size);
    kernelCrackMd5<<<blocks, 1>>>(d_TargetHash, wordLength, d_Output, d_alphabet);

    // Copy the output word from device to host
    cudaMemcpy(h_Output, d_Output, sizeof(char) * wordLength + 1, cudaMemcpyDeviceToHost);

    cudaFree(d_Output);
    cudaFree(d_TargetHash);
    cudaFree(d_alphabet);
}
