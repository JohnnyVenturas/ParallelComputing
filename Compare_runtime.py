import csv
from termcolor import colored

def read_csv(file_path):
    data = {}
    with open(file_path, mode='r') as file:
        reader = csv.DictReader(file)
        for row in reader:
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
            print(f"Comparing {filename}:")
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
    para_file = 'durations_para.csv'

    seq_data = read_csv(seq_file)
    para_data = read_csv(para_file)

    compare_durations(seq_data, para_data)