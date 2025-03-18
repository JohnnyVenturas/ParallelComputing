import csv
import os
from termcolor import colored

def read_csv(file_path, is_parallel=False):
    data = {}
    with open(file_path, mode='r') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if is_parallel:
                # Nettoie les espaces avant et après les valeurs
                using_openmp = row['Using_OpenMP'].strip()
                using_gpu = row['Using_GPU'].strip()
                
                # Handle the case with or without MPI_Processes column
                mpi_processes = int(row.get('MPI_Processes', 0)) if 'MPI_Processes' in row else 0
                
                data[row['Filename']] = {
                    'Using_OpenMP': using_openmp,
                    'Using_GPU': using_gpu,
                    'MPI_Processes': mpi_processes,
                    'Number Images': int(row['Number Images']),
                    'Number Pixels': int(row['Number Pixels']),
                    'Import Duration': float(row['Import Duration']),
                    'Gray Filter Duration': float(row['Gray Filter Duration']),
                    'Blur Filter Duration': float(row['Blur Filter Duration']),
                    'Sobel Filter Duration': float(row['Sobel Filter Duration']),
                    'Export Duration': float(row['Export Duration'])
                }
            else:
                data[row['Filename']] = {
                    'Import Duration': float(row['Import Duration']),
                    'Gray Filter Duration': float(row['Gray Filter Duration']),
                    'Blur Filter Duration': float(row['Blur Filter Duration']),
                    'Sobel Filter Duration': float(row['Sobel Filter Duration']),
                    'Export Duration': float(row['Export Duration'])
                }
    return data

def compare_durations(seq_data, para_data):
    for filename in seq_data:
        if filename in para_data:
            basename = os.path.basename(filename)
            num_images = para_data[filename]['Number Images']
            num_pixels = para_data[filename]['Number Pixels']
            mpi_processes = para_data[filename]['MPI_Processes']
            
            # Simplifie l'affichage OpenMP pour correspondre aux besoins
            openmp_value = para_data[filename]['Using_OpenMP']
            if openmp_value == "No":
                openmp_display = "None"
            elif "on images" in openmp_value:
                openmp_display = "on images"
            elif "on pixels" in openmp_value:
                openmp_display = "on pixels"
            else:
                openmp_display = openmp_value
            
            # Affiche les informations sur quatre lignes
            print(f"\n Comparing {basename} (Images: {num_images}, Pixels: {num_pixels})")
            print(f" OpenMP: {openmp_display}")
            print(f" GPU: {para_data[filename]['Using_GPU']}")
            print(f" MPI Processes: {mpi_processes}")
            
            for key in ["Import Duration", "Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration", "Export Duration"]:
                seq_duration = seq_data[filename][key]
                para_duration = para_data[filename][key]
                
                speedup = seq_duration / para_duration if para_duration > 0 else float('inf')
                
                if para_duration < seq_duration:
                    print(f"  {key}: {colored(para_duration, 'green')} (faster than {seq_duration}, speedup: {speedup:.2f}x)")
                else:
                    slowdown = para_duration / seq_duration if seq_duration > 0 else float('inf')
                    print(f"  {key}: {colored(para_duration, 'red')} (slower than {seq_duration}, slowdown: {slowdown:.2f}x)")
        else:
            print(f"Filename {filename} not found in parallel data")

if __name__ == "__main__":
    seq_file = 'durations_seq.csv'
    para_file = 'durations_para.csv'
    
    seq_data = read_csv(seq_file)
    para_data = read_csv(para_file, is_parallel=True)
    
    compare_durations(seq_data, para_data)