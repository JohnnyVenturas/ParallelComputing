#!/bin/bash
# This script runs the parallelized version of the sobel filter on all images in the images/original directory
# and saves the results in the images/parallelized directory.
# The number of threads and MPI nodes to use are passed as arguments to the script.

if [ $# -lt 2 ]; then
    echo "Usage: $0 <num_threads> <num_mpi_nodes>"
    exit 1
fi

export OMP_NUM_THREADS=$1
export MPI_NODES=$2
echo -e "\n Running with $OMP_NUM_THREADS threads and $MPI_NODES MPI nodes \n"

# Set the project directory
export PROJECT_DIRECTORY=$(pwd)
echo -e "Project directory set to $PROJECT_DIRECTORY \n"

make -f Makefile_para

INPUT_DIR=images/original
OUTPUT_DIR=images/processed_parallelized
mkdir $OUTPUT_DIR 2>/dev/null

# Clean the durations_para.csv file
> durations_para.csv

# possible to parallelize the following loop?

for i in $INPUT_DIR/*gif ; do
    DEST=$OUTPUT_DIR/`basename $i .gif`-sobel-para.gif
    FILENAME=$(basename $i)
    FILEDEST=$(basename $DEST)
    echo -e "\nProcessing $FILENAME -> $FILEDEST"
    
    mpirun -np $MPI_NODES ./sobel_para $i $DEST
done

# Check the results
echo -e "\nResults check:"
echo "=============="
echo -e "Baseline:./images/baseline_result"
echo -e "Processed:./images/processed_parallelized"
echo ""
./check images/processed_parallelized 

# Printing the results in terminal
echo -e "\n Printing results... \n"
python Compare_runtime.py

# Plot visually 
python plot.py