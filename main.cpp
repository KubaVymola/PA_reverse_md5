#include <iostream>
#include <stdlib.h>

extern void crackMd5(const char * targetHash, int wordLength);

int main(int argc, char * argv[]) {
    char * targetHash;
    int wordLength;

    targetHash = argv[1];
    wordLength = atoi(argv[2]);

    std::cout << "Target hash: " << targetHash << std::endl;
    std::cout << "Word length: " << wordLength << std::endl;
    
    crackMd5(targetHash, wordLength);
}
