#### Description: This script reads the durations from the sequential and parallel versions of the program and compares them.

import csv
import os
from termcolor import colored

def read_csv(file_path, is_parallel=False):
    data = {}
    with open(file_path, mode='r') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if is_parallel:
                data[row['Filename']] = {
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
            print(f"\n Comparing {basename} (Images: {num_images}, Pixels: {num_pixels}):")
            for key in ["Import Duration", "Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration", "Export Duration"]:
                seq_duration = seq_data[filename][key]
                para_duration = para_data[filename][key]
                if para_duration < seq_duration:
                    print(f"  {key}: {colored(para_duration, 'green')} (faster than {seq_duration})")
                else:
                    print(f"  {key}: {colored(para_duration, 'red')} (slower than {seq_duration})")
        else:
            print(f"Filename {filename} not found in parallel data")

if __name__ == "__main__":
    seq_file = 'durations_seq.csv'
    para_file = 'durations_para_GPU.csv'

    seq_data = read_csv(seq_file)
    para_data = read_csv(para_file, is_parallel=True)

    compare_durations(seq_data, para_data)
