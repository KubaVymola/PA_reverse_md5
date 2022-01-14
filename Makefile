all: main.cpp md_crack.cu
	nvcc -g -o main.bin main.cpp md_crack.cu
