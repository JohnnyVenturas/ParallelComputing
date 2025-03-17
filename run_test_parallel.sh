#!/bin/bash

make

INPUT_DIR=images/original
OUTPUT_DIR=images/processed_parallel
mkdir $OUTPUT_DIR 2>/dev/null

for i in "$INPUT_DIR"/*gif ; do
    DEST="$OUTPUT_DIR"/$(basename "$i" .gif)-sobel.gif
    echo "Running test on $i -> $DEST"

    salloc -n 8 mpirun ./sobelf_mpi "$i" "$DEST"
done
