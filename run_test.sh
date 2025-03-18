#!/bin/bash

make

INPUT_DIR=images/original
OUTPUT_DIR=images/processed_seq
mkdir $OUTPUT_DIR 2>/dev/null

# Clean the durations_seq.csv file
> durations_seq.csv

for i in $INPUT_DIR/*gif ; do
    DEST=$OUTPUT_DIR/`basename $i .gif`-sobel.gif
    echo "Running test on $i -> $DEST"

    ./sobel $i $DEST
done
