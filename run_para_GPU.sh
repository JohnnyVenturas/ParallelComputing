#!/bin/bash

# This script runs the parallelized version of the sobel filter on all images in the images/original directory
# and saves the results in the images/processed_parallelized_GPU directory.
# The script also compares the results with the baseline and prints the results.

# Set the CUDA path


# Set the project directory
export PROJECT_DIRECTORY=$(pwd)
echo -e "Project directory set to $PROJECT_DIRECTORY \n"

make -f Makefile_para_GPU

INPUT_DIR=images/original
OUTPUT_DIR=images/processed_parallelized_GPU
mkdir $OUTPUT_DIR 2>/dev/null

# Clean the durations_para.csv file
> durations_para_GPU.csv

# possible to parallelize the following loop?


for i in $INPUT_DIR/*gif ; do
    DEST=$OUTPUT_DIR/`basename $i .gif`-sobel-para.gif
    FILENAME=$(basename $i)
    FILEDEST=$(basename $DEST)
    echo -e "\nProcessing $FILENAME -> $FILEDEST"

    ./sobelf_para $i $DEST
done

# Check the results
echo -e "\nResults check:"
echo "=============="
echo -e "Baseline:./images/baseline_result"
echo -e "Processed:./images/processed_parallelized_GPU"
echo ""
./check images/processed_parallelized_GPU


# Printing the results
echo -e "\n Printing results... \n"
python Compare_runtime.py

# plot results
python plot.py