# import pandas as pd
# import matplotlib.pyplot as plt

# # Load the CSV files
# df_para = pd.read_csv("durations_para_GPU.csv")
# df_seq = pd.read_csv("durations_seq.csv")

# # Compute the full process time as the sum of all duration columns
# duration_columns = ["Import Duration", "Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration", "Export Duration"]
# df_para["Total Process Time"] = df_para[duration_columns].sum(axis=1)
# df_seq["Total Process Time"] = df_seq[duration_columns].sum(axis=1)

# # Extract filenames without the full path
# df_para["Image Name"] = df_para["Filename"].apply(lambda x: x.split("/")[-1])
# df_seq["Image Name"] = df_seq["Filename"].apply(lambda x: x.split("/")[-1])

# # Create subplots
# fig, axes = plt.subplots(2, 1, figsize=(10, 10))

# # Plot for process times between 1 and 6 seconds
# df_para_filtered = df_para[(df_para["Total Process Time"] >= 1) & (df_para["Total Process Time"] <= 6)]
# df_seq_filtered = df_seq[(df_seq["Total Process Time"] >= 1) & (df_seq["Total Process Time"] <= 6)]
# axes[0].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], color='b', label="Parallel Processing")
# axes[0].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], color='r', label="Sequential Processing")
# for i, txt in enumerate(df_para_filtered["Image Name"]):
#     axes[0].annotate(txt, (df_para_filtered["Number Images"].iloc[i], df_para_filtered["Total Process Time"].iloc[i]), fontsize=8, xytext=(5,5), textcoords='offset points')
# for i, txt in enumerate(df_seq_filtered["Image Name"]):
#     axes[0].annotate(txt, (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), fontsize=8, xytext=(5,5), textcoords='offset points')
# axes[0].set_xlabel("Number of Images")
# axes[0].set_ylabel("Total Process Time (s)")
# axes[0].set_title("Total Process Time (1-6s) vs. Number of Images")
# axes[0].legend()
# axes[0].grid()

# # Plot for process times between 0 and 1 seconds
# df_para_filtered = df_para[df_para["Total Process Time"] <= 1]
# df_seq_filtered = df_seq[df_seq["Total Process Time"] <= 1]
# axes[1].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], color='b', label="Parallel Processing")
# axes[1].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], color='r', label="Sequential Processing")
# for i, txt in enumerate(df_para_filtered["Image Name"]):
#     axes[1].annotate(txt, (df_para_filtered["Number Images"].iloc[i], df_para_filtered["Total Process Time"].iloc[i]), fontsize=8, xytext=(5,5), textcoords='offset points')
# for i, txt in enumerate(df_seq_filtered["Image Name"]):
#     axes[1].annotate(txt, (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), fontsize=8, xytext=(5,5), textcoords='offset points')
# axes[1].set_xlabel("Number of Images")
# axes[1].set_ylabel("Total Process Time (s)")
# axes[1].set_title("Total Process Time (0-1s) vs. Number of Images")
# axes[1].legend()
# axes[1].grid()

# # Adjust layout and save plot
# plt.tight_layout()
# plt.savefig("plot.png")
# plt.close()

import pandas as pd
import matplotlib.pyplot as plt
import os
import numpy as np

# Load the CSV files
df_gpu = pd.read_csv("durations_para_GPU.csv")
df_seq = pd.read_csv("durations_seq.csv")

# Define the duration columns (excluding Import and Export)
duration_columns = ["Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration"]

# Compute the full process time as the sum of filter duration columns
df_gpu["Total Process Time"] = df_gpu[duration_columns].sum(axis=1)
df_seq["Total Process Time"] = df_seq[duration_columns].sum(axis=1)

# Extract filenames without the full path
df_gpu["Image Name"] = df_gpu["Filename"].apply(lambda x: os.path.basename(x))
df_seq["Image Name"] = df_seq["Filename"].apply(lambda x: os.path.basename(x))

# Add information about acceleration
df_gpu["Acceleration"] = "GPU"

# Create subplots with 3 rows
fig, axes = plt.subplots(3, 1, figsize=(12, 15))

# Plot 1: Process times between 0.1 and 1 seconds
df_gpu_filtered = df_gpu[(df_gpu["Total Process Time"] >= 0.1) & (df_gpu["Total Process Time"] <= 1)]
df_seq_filtered = df_seq[(df_seq["Total Process Time"] >= 0.1) & (df_seq["Total Process Time"] <= 1)]

axes[0].scatter(df_gpu_filtered["Number Images"], df_gpu_filtered["Total Process Time"], 
               color='g', label="GPU Processing", marker='o', s=80, alpha=0.7)
axes[0].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], 
               color='r', label="Sequential Processing", marker='x', s=80)

for i, txt in enumerate(df_gpu_filtered["Image Name"]):
    axes[0].annotate(txt, 
                    (df_gpu_filtered["Number Images"].iloc[i], df_gpu_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')
for i, txt in enumerate(df_seq_filtered["Image Name"]):
    axes[0].annotate(txt, 
                    (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

axes[0].set_xlabel("Number of Images")
axes[0].set_ylabel("Total Process Time (s)")
axes[0].set_title("Filter Process Time (0.1-1s) vs. Number of Images")
axes[0].legend()
axes[0].grid()

# Plot 2: Process times less than 0.1 seconds
df_gpu_filtered = df_gpu[df_gpu["Total Process Time"] < 0.1]
df_seq_filtered = df_seq[df_seq["Total Process Time"] < 0.1]

axes[1].scatter(df_gpu_filtered["Number Images"], df_gpu_filtered["Total Process Time"], 
               color='g', label="GPU Processing", marker='o', s=80, alpha=0.7)
axes[1].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], 
               color='r', label="Sequential Processing", marker='x', s=80)

for i, txt in enumerate(df_gpu_filtered["Image Name"]):
    axes[1].annotate(txt, 
                    (df_gpu_filtered["Number Images"].iloc[i], df_gpu_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')
for i, txt in enumerate(df_seq_filtered["Image Name"]):
    axes[1].annotate(txt, 
                    (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

axes[1].set_xlabel("Number of Images")
axes[1].set_ylabel("Total Process Time (s)")
axes[1].set_title("Filter Process Time (<0.1s) vs. Number of Images")
axes[1].legend()
axes[1].grid()

# Plot 3: Speedup calculation and visualization
# Merge datasets on Image Name to calculate speedup
merged_data = pd.merge(
    df_seq[["Image Name", "Total Process Time", "Number Images"]], 
    df_gpu[["Image Name", "Total Process Time", "Number Images", "Number Pixels"]], 
    on="Image Name", 
    suffixes=('_seq', '_gpu')
)

# Calculate speedup
merged_data["Speedup"] = merged_data["Total Process Time_seq"] / merged_data["Total Process Time_gpu"]

# Sort by speedup for better visualization
merged_data = merged_data.sort_values("Speedup", ascending=False)

# Create color palette based on number of pixels (not images for GPU comparison)
# Convert pixels to millions for better scaling
merged_data["Pixels (M)"] = merged_data["Number Pixels"] / 1000000
pixel_range = merged_data["Pixels (M)"].copy()

# Create a logarithmic color map for better visualization of pixel counts
cmap = plt.cm.plasma
norm = plt.Normalize(pixel_range.min(), pixel_range.max())
colors = [cmap(norm(p)) for p in pixel_range]

# Bar chart of speedups with colored bars based on pixel count
bar_positions = range(len(merged_data))

bars = axes[2].bar(bar_positions, merged_data["Speedup"], color=colors)
axes[2].set_xticks(bar_positions)
axes[2].set_xticklabels(merged_data["Image Name"], rotation=90, fontsize=8)
axes[2].set_ylabel("Speedup Factor (Sequential/GPU)")
axes[2].set_title("GPU Filter Performance Speedup")
axes[2].axhline(y=1, color='r', linestyle='--', label="Baseline (Sequential)")
axes[2].grid(axis='y')

# Add a color bar to show the pixel count scale
sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array([])
cbar = plt.colorbar(sm, ax=axes[2])
cbar.set_label('Pixels (Millions)')

# Add annotations with number of images and pixel count
for i, (_, row) in enumerate(merged_data.iterrows()):
    axes[2].annotate(f"{int(row['Number Images_gpu'])} imgs\n{row['Pixels (M)']:.1f}M px\n{row['Speedup']:.1f}x", 
                   (i, row["Speedup"]), 
                   ha='center', va='bottom', fontsize=7)

# Add average speedup line
avg_speedup = merged_data["Speedup"].mean()
axes[2].axhline(y=avg_speedup, color='g', linestyle='-.', 
               label=f"Avg Speedup: {avg_speedup:.2f}x")
axes[2].legend()

# Adjust layout and save main plot
plt.tight_layout()
plt.savefig("gpu_performance_comparison.png", dpi=300)

# Create additional analyses

# 1. Pixel count vs Speedup analysis
plt.figure(figsize=(10, 6))
plt.scatter(merged_data["Pixels (M)"], merged_data["Speedup"], 
           c=merged_data["Number Images_gpu"], cmap="viridis", 
           s=100, alpha=0.7)

# Add annotations with image names
for i, (_, row) in enumerate(merged_data.iterrows()):
    plt.annotate(row["Image Name"], 
                (row["Pixels (M)"], row["Speedup"]), 
                fontsize=8, xytext=(5,5), textcoords='offset points')

plt.xscale('log')  # Log scale for pixel count
plt.xlabel("Pixels (Millions) - Log Scale")
plt.ylabel("Speedup Factor")
plt.title("GPU Speedup vs. Image Size")
plt.grid(True, which="both", ls="--")
plt.colorbar(label="Number of Images")
plt.tight_layout()
plt.savefig("gpu_speedup_vs_size.png", dpi=300)

# 2. Detailed filter-by-filter comparison for top speedup images
# Select top 5 speedup images
top_speedup_images = merged_data.head(5)["Image Name"].tolist()

# Filter data for these images
df_gpu_top = df_gpu[df_gpu["Image Name"].isin(top_speedup_images)]
df_seq_top = df_seq[df_seq["Image Name"].isin(top_speedup_images)]

# Create a stacked bar chart comparing filter times
plt.figure(figsize=(14, 8))

# Set width of bars
barWidth = 0.35
 
# Set positions of bars on X axis
r1 = np.arange(len(top_speedup_images))
r2 = [x + barWidth for x in r1]

# Create a DataFrame with the required data for plotting
plot_data = pd.DataFrame(index=top_speedup_images)

# Add sequential data
for col in duration_columns:
    filter_name = col.replace(" Duration", "")
    plot_data[f"{filter_name}_seq"] = [df_seq_top[df_seq_top["Image Name"] == img][col].values[0] 
                                     if not df_seq_top[df_seq_top["Image Name"] == img].empty else 0 
                                     for img in top_speedup_images]

# Add GPU data
for col in duration_columns:
    filter_name = col.replace(" Duration", "")
    plot_data[f"{filter_name}_gpu"] = [df_gpu_top[df_gpu_top["Image Name"] == img][col].values[0] 
                                     if not df_gpu_top[df_gpu_top["Image Name"] == img].empty else 0 
                                     for img in top_speedup_images]

# Create the stacked bar chart
# Sequential bars
bottom_seq = np.zeros(len(top_speedup_images))
bottom_gpu = np.zeros(len(top_speedup_images))

colors = ['#3274A1', '#E1812C', '#3A923A']
hatches = ['/', '\\', 'x']

for i, col in enumerate(duration_columns):
    filter_name = col.replace(" Duration", "")
    
    # Sequential bars
    plt.bar(r1, plot_data[f"{filter_name}_seq"], bottom=bottom_seq, color=colors[i], 
           width=barWidth, edgecolor='white', label=f'{filter_name} (Sequential)', hatch=hatches[i])
    bottom_seq += plot_data[f"{filter_name}_seq"].values
    
    # GPU bars
    plt.bar(r2, plot_data[f"{filter_name}_gpu"], bottom=bottom_gpu, color=colors[i], alpha=0.7,
           width=barWidth, edgecolor='white', label=f'{filter_name} (GPU)')
    bottom_gpu += plot_data[f"{filter_name}_gpu"].values

# Add labels and legend
plt.xlabel('Image', fontweight='bold')
plt.ylabel('Processing Time (s)')
plt.xticks([r + barWidth/2 for r in range(len(top_speedup_images))], top_speedup_images, rotation=45, ha='right')
plt.title('Filter-by-Filter Comparison for Top GPU Speedup Images')
plt.legend()
plt.tight_layout()
plt.savefig("gpu_filter_comparison.png", dpi=300)

# 3. Create a focused view of top speedups
plt.figure(figsize=(10, 6))
top_speedups = merged_data.head(min(10, len(merged_data)))  # Top 10 or all if fewer
    
x = range(len(top_speedups))
plt.bar(x, top_speedups["Speedup"], color=colors[:len(top_speedups)])
plt.xticks(x, top_speedups["Image Name"], rotation=45, ha='right')
plt.xlabel("Image")
plt.ylabel("Speedup Factor")
plt.title("Top GPU Performance Speedups")
plt.axhline(y=1, color='r', linestyle='--', label="Baseline (Sequential)")
plt.grid(axis='y')
    
for i, (_, row) in enumerate(top_speedups.iterrows()):
    plt.text(i, row["Speedup"], 
            f"{int(row['Number Images_gpu'])} imgs\n{row['Pixels (M)']:.1f}M px\n{row['Speedup']:.2f}x", 
            ha='center', va='bottom', fontsize=8)
    
plt.tight_layout()
plt.savefig("top_gpu_speedups.png", dpi=300)

plt.close('all')