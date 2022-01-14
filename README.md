# Usage

## Compile with

$ make

or 

$ nvcc -o reverse_md5.bin main.bin md_crack.cu

## Run with

$ ./reverse_md5.bin \<md5-hash-to-crack\> \<target-word-length\>

e.g.

$ ./reverse_md5.bin 79c2b46ce2594ecbcb5b73e928345492 4

# Remarks

- Will return a word from which the given hash has originated.

- User needs to know the length of the word a priori, but that can be fixed by incrementing the length of the searched word.

- Can crack 5-letters-long password in less than 5 hours on a single A100 GPU.

# Author

Jakub Výmola (VYM0038), VŠB-FEI, 2021-2022
Course: Parallel algorithms