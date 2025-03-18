import csv
import os
from termcolor import colored

def read_csv(file_path, is_parallel=False):
    data = {}
    with open(file_path, mode='r') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if is_parallel:
                # Handle MPI CSV format
                if 'Using_MPI' in row:
                    data[row['Filename']] = {
                        'Parallel_Type': 'MPI',
                        'Processes': int(row['Number_Processes']) if 'Number_Processes' in row else int(row.get('Using_MPI', '0').split(',')[1]) if ',' in row.get('Using_MPI', '0') else 0,
                        'Number Images': int(row.get('Number_Images', row.get('Number Images', 0))),
                        'Number Pixels': int(row.get('Number_Pixels', row.get('Number Pixels', 0))),
                        'Import Duration': float(row.get('Import_Duration', row.get('Import Duration', 0))),
                        'Gray Filter Duration': float(row.get('Gray_Filter_Duration', row.get('Gray Filter Duration', 0))),
                        'Blur Filter Duration': float(row.get('Blur_Filter_Duration', row.get('Blur Filter Duration', 0))),
                        'Sobel Filter Duration': float(row.get('Sobel_Filter_Duration', row.get('Sobel Filter Duration', 0))),
                        'Export Duration': float(row.get('Export_Duration', row.get('Export Duration', 0)))
                    }
                # Handle OpenMP CSV format (existing format)
                else:
                    data[row['Filename']] = {
                        'Parallel_Type': 'OpenMP',
                        'OpenMP': row.get('Using_OpenMP', 'No'),
                        'GPU': row.get('Using_GPU', 'No'),
                        'Number Images': int(row['Number Images']),
                        'Number Pixels': int(row['Number Pixels']),
                        'Import Duration': float(row['Import Duration']),
                        'Gray Filter Duration': float(row['Gray Filter Duration']),
                        'Blur Filter Duration': float(row['Blur Filter Duration']),
                        'Sobel Filter Duration': float(row['Sobel Filter Duration']),
                        'Export Duration': float(row['Export Duration'])
                    }
            else:
                # Sequential CSV format
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
            
            # Display info based on parallel type
            parallel_type = para_data[filename].get('Parallel_Type', 'Unknown')
            
            if parallel_type == 'MPI':
                processes = para_data[filename].get('Processes', 0)
                print(f"\n Comparing {basename} (Images: {num_images}, Pixels: {num_pixels})")
                print(f" MPI: Yes, Processes: {processes}")
            else:  # OpenMP
                openmp_value = para_data[filename].get('OpenMP', 'No')
                gpu_value = para_data[filename].get('GPU', 'No')
                
                # Simplify the OpenMP display
                if "on images" in openmp_value:
                    openmp_display = "on images"
                elif "on pixels" in openmp_value:
                    openmp_display = "on pixels"
                else:
                    openmp_display = openmp_value
                
                print(f"\n Comparing {basename} (Images: {num_images}, Pixels: {num_pixels})")
                print(f" OpenMP: {openmp_display}, GPU: {gpu_value}")
            
            # Compare durations regardless of parallel type
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
    para_file = 'durations_para_MPI.csv'
    
    seq_data = read_csv(seq_file)
    para_data = read_csv(para_file, is_parallel=True)
    
    compare_durations(seq_data, para_data)