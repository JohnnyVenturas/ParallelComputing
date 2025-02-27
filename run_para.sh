#!/bin/bash

make -f Makefile_para

INPUT_DIR=images/original
OUTPUT_DIR=images/parallelized
mkdir $OUTPUT_DIR 2>/dev/null

for i in $INPUT_DIR/*gif ; do
    DEST=$OUTPUT_DIR/`basename $i .gif`-sobel-para.gif
    echo "Running test on $i -> $DEST"

    ./sobelf_para $i $DEST
done
