# Image Processing Project

## Repository Structure

### Image Folders
- `baseline_result/`: Original process results *(do not modify)*
- `original/`: Backup of baseline results for retraining
- `processed_parallelized/`: Images processed using parallelized method
- `processed_sequential/`: Images processed using sequential method

### Compilation Artifacts
- `obj/`: Object files for sequential C code
- `obj_para_OpenMP/`: Object files for parallelized C code

### Source Code
- `src/`: Sequential C source files
- `src_para_OpenMP/`: Parallelized C source files (names end with `_para`)

### Utility Folders
- `check/`: Script to verify image matching between processed and baseline folders

## Project Components

### Key Files
- `Compare_runtime.py`: Runtime comparison between sequential and parallelized processes
- `Makefile`: Compilation commands for sequential version
- `Makefile_para_OpenMP`: Compilation commands for parallelized version using only OpenMP
- `durations_para_OpenMP.csv` and `durations_seq.csv`: Runtime duration logs

## Execution Guide

### Basic Command
```bash
# Sequential processing
./run_test.sh

# Parallelized processing
./run_para.sh <nb_threads>
```

### Parallelized Run Workflow
The `./run_para.sh` script executes:
1. Compile parallelized code version
2. Reset `durations_para_OpenMP.csv`
3. Generate processed images
4. Populate duration logs
5. Verify processed images using check script
6. Compare step-wise runtime:
   - Image Import (load pixels)
   - Gray Filter
   - Blur Filter
   - Sobel Filter
   - Image Export (store pixels)

## ⚠️ Important Notes
- Sequential results: `./images/processed_sequential`
- Parallelized results: `./images/processed_parallelized`

## 🔍 Performance Tracking
Track performance differences between sequential and parallelized implementations using generated CSV logs.