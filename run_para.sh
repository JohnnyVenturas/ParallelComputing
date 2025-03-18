#!/bin/bash
# This script runs the parallelized version of the sobel filter on all images in the images/original directory
# and saves the results in the images/parallelized directory.
# The number of threads is passed as an argument, and MPI nodes are dynamically set based on image count.

if [ $# -lt 1 ]; then
    echo "Usage: $0 <num_threads>"
    exit 1
fi

export OMP_NUM_THREADS=$1
echo -e "\n Running with $OMP_NUM_THREADS threads and dynamic MPI nodes based on GIF image count \n"

# Set the project directory
export PROJECT_DIRECTORY=$(pwd)
echo -e "Project directory set to $PROJECT_DIRECTORY \n"

make -f Makefile_para

INPUT_DIR=images/original
OUTPUT_DIR=images/processed_parallelized
mkdir -p $OUTPUT_DIR 2>/dev/null

# Clean the durations_para.csv file
> durations_para.csv

# Function to count images in a GIF file
count_images() {
    local gif_file=$1
    # Use gifsicle to get image count (if installed)
    if command -v gifsicle &> /dev/null; then
        image_count=$(gifsicle --info "$gif_file" | grep -c "image #")
        echo $image_count
        return
    fi
    
    # Alternative using imagemagick (if installed)
    if command -v identify &> /dev/null; then
        image_count=$(identify "$gif_file" | wc -l)
        echo $image_count
        return
    fi
    
    # If no tools available, use a default value
    echo "1"
}

# Process each GIF file
for i in $INPUT_DIR/*gif ; do
    DEST=$OUTPUT_DIR/`basename $i .gif`-sobel-para.gif
    FILENAME=$(basename $i)
    FILEDEST=$(basename $DEST)
    
    # Count the number of images in the GIF
    IMAGE_COUNT=$(count_images "$i")
    
    # Set MPI_NODES based on image count (minimum 1)
    MPI_NODES=$IMAGE_COUNT
    
    # Limit the number of MPI nodes to a reasonable maximum (e.g., number of CPU cores)
    MAX_NODES=$(nproc 2>/dev/null || echo 8)  # Use available cores or default to 8
    if [ $MPI_NODES -gt $MAX_NODES ]; then
        MPI_NODES=$MAX_NODES
    fi
    
    echo -e "\nProcessing $FILENAME -> $FILEDEST with $MPI_NODES MPI nodes (based on $IMAGE_COUNT images)"
    
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