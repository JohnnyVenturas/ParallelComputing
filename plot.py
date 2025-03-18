import pandas as pd
import matplotlib.pyplot as plt
import os

# Load the CSV files
df_para = pd.read_csv("durations_para_MPI.csv")
df_seq = pd.read_csv("durations_seq.csv")

# Check and rename columns if needed for the MPI data
para_columns = df_para.columns.tolist()

# Map for possible column name variations
column_map = {
    "Filename": ["Filename"],
    "Import Duration": ["Import Duration", "Import_Duration"],
    "Gray Filter Duration": ["Gray Filter Duration", "Gray_Filter_Duration"],
    "Blur Filter Duration": ["Blur Filter Duration", "Blur_Filter_Duration"],
    "Sobel Filter Duration": ["Sobel Filter Duration", "Sobel_Filter_Duration"],
    "Export Duration": ["Export Duration", "Export_Duration"],
    "Number Images": ["Number Images", "Number_Images"],
    "Number Pixels": ["Number Pixels", "Number_Pixels"]
}

# Function to find the actual column name in the DataFrame
def find_column(df, possible_names):
    for name in possible_names:
        if name in df.columns:
            return name
    return None

# Standardize column names in both dataframes
standardized_columns = {}
for std_name, variations in column_map.items():
    para_col = find_column(df_para, variations)
    if para_col and para_col != std_name:
        standardized_columns[para_col] = std_name

# Rename columns if needed
if standardized_columns:
    df_para = df_para.rename(columns=standardized_columns)

# Define the duration columns
duration_columns = ["Import Duration", "Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration", "Export Duration"]

# Compute the full process time as the sum of all duration columns
df_para["Total Process Time"] = df_para[duration_columns].sum(axis=1)
df_seq["Total Process Time"] = df_seq[duration_columns].sum(axis=1)

# Extract filenames without the full path
df_para["Image Name"] = df_para["Filename"].apply(lambda x: os.path.basename(x))
df_seq["Image Name"] = df_seq["Filename"].apply(lambda x: os.path.basename(x))

# Add information about parallelization strategy
if "Using_MPI" in df_para.columns:
    df_para["Parallel Type"] = "MPI"
    # Extract number of processes if available
    if "Number_Processes" in df_para.columns:
        df_para["Processes"] = df_para["Number_Processes"]
    else:
        # Try to extract from Using_MPI if it contains this info
        try:
            df_para["Processes"] = df_para["Using_MPI"].apply(lambda x: int(x.split(',')[1]) if isinstance(x, str) and ',' in x else 0)
        except:
            df_para["Processes"] = 0
elif "Using_OpenMP" in df_para.columns:
    df_para["Parallel Type"] = df_para["Using_OpenMP"].apply(
        lambda x: "OpenMP (images)" if "on images" in str(x) else 
                 "OpenMP (pixels)" if "on pixels" in str(x) else 
                 "No OpenMP" if str(x).lower() == "no" else "OpenMP"
    )
else:
    df_para["Parallel Type"] = "Parallel"

# Create plots with various views
fig, axes = plt.subplots(3, 1, figsize=(12, 15))

# Plot 1: Process times between 1 and 6 seconds
df_para_filtered = df_para[(df_para["Total Process Time"] >= 1) & (df_para["Total Process Time"] <= 6)]
df_seq_filtered = df_seq[(df_seq["Total Process Time"] >= 1) & (df_seq["Total Process Time"] <= 6)]

axes[0].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], 
               color='b', label="Parallel (MPI) Processing")
axes[0].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], 
               color='r', label="Sequential Processing")

for i, txt in enumerate(df_para_filtered["Image Name"]):
    axes[0].annotate(txt, (df_para_filtered["Number Images"].iloc[i], df_para_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')
for i, txt in enumerate(df_seq_filtered["Image Name"]):
    axes[0].annotate(txt, (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

axes[0].set_xlabel("Number of Images")
axes[0].set_ylabel("Total Process Time (s)")
axes[0].set_title("Total Process Time (1-6s) vs. Number of Images")
axes[0].legend()
axes[0].grid()

# Plot 2: Process times between 0 and 1 seconds
df_para_filtered = df_para[df_para["Total Process Time"] <= 1]
df_seq_filtered = df_seq[df_seq["Total Process Time"] <= 1]

axes[1].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], 
               color='b', label="Parallel (MPI) Processing")
axes[1].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], 
               color='r', label="Sequential Processing")

for i, txt in enumerate(df_para_filtered["Image Name"]):
    axes[1].annotate(txt, (df_para_filtered["Number Images"].iloc[i], df_para_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')
for i, txt in enumerate(df_seq_filtered["Image Name"]):
    axes[1].annotate(txt, (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

axes[1].set_xlabel("Number of Images")
axes[1].set_ylabel("Total Process Time (s)")
axes[1].set_title("Total Process Time (0-1s) vs. Number of Images")
axes[1].legend()
axes[1].grid()

# Plot 3: Speedup comparison
# Merge datasets on Filename to calculate speedup
merged_data = pd.merge(df_seq[["Filename", "Total Process Time"]], 
                      df_para[["Filename", "Total Process Time", "Number Images"]], 
                      on="Filename", 
                      suffixes=('_seq', '_para'))

merged_data["Speedup"] = merged_data["Total Process Time_seq"] / merged_data["Total Process Time_para"]
merged_data["Image Name"] = merged_data["Filename"].apply(lambda x: os.path.basename(x))

# Sort by speedup for better visualization
merged_data = merged_data.sort_values("Speedup", ascending=False)

# Bar chart of speedups
bar_positions = range(len(merged_data))
axes[2].bar(bar_positions, merged_data["Speedup"], color='g')
axes[2].set_xticks(bar_positions)
axes[2].set_xticklabels(merged_data["Image Name"], rotation=90, fontsize=8)
axes[2].set_ylabel("Speedup Factor (Sequential/MPI)")
axes[2].set_title("Performance Speedup with MPI Parallelization")
axes[2].axhline(y=1, color='r', linestyle='--', label="Baseline (Sequential)")
axes[2].legend()
axes[2].grid(axis='y')

# Add annotations with number of images
for i, (_, row) in enumerate(merged_data.iterrows()):
    axes[2].annotate(f"{int(row['Number Images'])} imgs", 
                   (i, row["Speedup"]), 
                   ha='center', va='bottom', fontsize=7)

# Adjust layout and save plot
plt.tight_layout()
plt.savefig("mpi_performance_plot.png", dpi=300)
plt.close()

# Create a second figure focusing only on the most significant speedups
plt.figure(figsize=(10, 6))

# Filter for significant speedups (>10x) if they exist, otherwise top 5
significant_speedups = merged_data[merged_data["Speedup"] > 10] if any(merged_data["Speedup"] > 10) else merged_data.head(5)

bar_positions = range(len(significant_speedups))
plt.bar(bar_positions, significant_speedups["Speedup"], color='g')
plt.xticks(bar_positions, significant_speedups["Image Name"], rotation=45, ha='right', fontsize=10)
plt.ylabel("Speedup Factor (Sequential/MPI)")
plt.title("Top MPI Performance Speedups")
plt.axhline(y=1, color='r', linestyle='--', label="Baseline (Sequential)")

for i, (_, row) in enumerate(significant_speedups.iterrows()):
    plt.annotate(f"{int(row['Number Images'])} imgs\n{row['Speedup']:.1f}x", 
               (i, row["Speedup"]), 
               ha='center', va='bottom', fontsize=9)

plt.legend()
plt.grid(axis='y')
plt.tight_layout()
plt.savefig("top_speedups.png", dpi=300)
plt.close()