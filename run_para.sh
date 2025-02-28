#!/bin/bash

# This script runs the parallelized version of the sobel filter on all images in the images/original directory
# and saves the results in the images/parallelized directory.
# The number of threads to use is passed as an argument to the script.

if [ -z "$1" ]; then
    echo "Usage: $0 <num_threads>"
    exit 1
fi

export OMP_NUM_THREADS=$1
echo "Running with $OMP_NUM_THREADS threads"

make -f Makefile_para

INPUT_DIR=images/original
OUTPUT_DIR=images/processed_parallelized
mkdir $OUTPUT_DIR 2>/dev/null

# Clean the durations_para.csv file
# > durations_para.csv

for i in $INPUT_DIR/*gif ; do
    DEST=$OUTPUT_DIR/`basename $i .gif`-sobel-para.gif
    echo "Running test on $i -> $DEST"

    ./sobelf_para $i $DEST
done
