# import pandas as pd
# import matplotlib.pyplot as plt

# # Load the CSV files
# df_para = pd.read_csv("durations_para.csv")
# df_seq = pd.read_csv("durations_seq.csv")

# # Compute the full process time as the sum of all duration columns
# duration_columns = ["Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration"]
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
df_para = pd.read_csv("durations_para.csv")
df_seq = pd.read_csv("durations_seq.csv")

# Define the duration columns (excluding Import and Export)
duration_columns = ["Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration"]

# Compute the full process time as the sum of filter duration columns
df_para["Total Process Time"] = df_para[duration_columns].sum(axis=1)
df_seq["Total Process Time"] = df_seq[duration_columns].sum(axis=1)

# Extract filenames without the full path
df_para["Image Name"] = df_para["Filename"].apply(lambda x: os.path.basename(x))
df_seq["Image Name"] = df_seq["Filename"].apply(lambda x: os.path.basename(x))

# Group the data into version A (parallel) and version B (sequential)
df_para["Version"] = "Version A"
df_seq["Version"] = "Version B"

# Create subplots with 3 rows
fig, axes = plt.subplots(3, 1, figsize=(14, 18))

# Plot 1: Process times between 0.1 and 1 seconds
df_para_filtered = df_para[(df_para["Total Process Time"] >= 0.1) & (df_para["Total Process Time"] <= 1)]
df_seq_filtered = df_seq[(df_seq["Total Process Time"] >= 0.1) & (df_seq["Total Process Time"] <= 1)]

# Plot for version A (parallel processing)
axes[0].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], 
               color='blue', label="Version A", marker='o', s=100, alpha=0.7)

# Plot for version B (sequential processing)
axes[0].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], 
               color='red', label="Version B", marker='x', s=80)

# Add annotations
for i, row in df_para_filtered.iterrows():
    axes[0].annotate(row["Image Name"], 
                    (row["Number Images"], row["Total Process Time"]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

for i, row in df_seq_filtered.iterrows():
    axes[0].annotate(row["Image Name"], 
                    (row["Number Images"], row["Total Process Time"]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

axes[0].set_xlabel("Number of Images")
axes[0].set_ylabel("Total Process Time (s)")
axes[0].set_title("Filter Process Time (0.1-1s) vs. Number of Images")
axes[0].legend()
axes[0].grid()

# Plot 2: Process times less than 0.1 seconds
df_para_filtered = df_para[df_para["Total Process Time"] < 0.1]
df_seq_filtered = df_seq[df_seq["Total Process Time"] < 0.1]

# Plot for version A (parallel processing)
axes[1].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], 
               color='blue', label="Version A", marker='o', s=100, alpha=0.7)

# Plot for version B (sequential processing)
axes[1].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], 
               color='red', label="Version B", marker='x', s=80)

# Add annotations
for i, row in df_para_filtered.iterrows():
    axes[1].annotate(row["Image Name"], 
                    (row["Number Images"], row["Total Process Time"]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

for i, row in df_seq_filtered.iterrows():
    axes[1].annotate(row["Image Name"], 
                    (row["Number Images"], row["Total Process Time"]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

axes[1].set_xlabel("Number of Images")
axes[1].set_ylabel("Total Process Time (s)")
axes[1].set_title("Filter Process Time (<0.1s) vs. Number of Images")
axes[1].legend()
axes[1].grid()

# Plot 3: Performance improvement calculation and visualization
# Merge datasets on Image Name to calculate performance improvement
merged_data = pd.merge(
    df_seq[["Image Name", "Total Process Time", "Number Images"]], 
    df_para[["Image Name", "Total Process Time", "Number Images", "Number Pixels"]], 
    on="Image Name", 
    suffixes=('_B', '_A')
)

# Calculate performance improvement factor
merged_data["Performance Improvement"] = merged_data["Total Process Time_B"] / merged_data["Total Process Time_A"]

# Sort by performance improvement for better visualization
merged_data = merged_data.sort_values("Performance Improvement", ascending=False)

# Create a color scale based on the number of pixels
merged_data["Pixels (M)"] = merged_data["Number Pixels"] / 1000000
pixel_range = merged_data["Pixels (M)"]
cmap = plt.cm.viridis
norm = plt.Normalize(pixel_range.min(), pixel_range.max())
colors = [cmap(norm(p)) for p in pixel_range]

# Bar chart of performance improvements
bar_positions = range(len(merged_data))
bars = axes[2].bar(bar_positions, merged_data["Performance Improvement"], color=colors)
axes[2].set_xticks(bar_positions)
axes[2].set_xticklabels(merged_data["Image Name"], rotation=90, fontsize=8)
axes[2].set_ylabel("Performance Improvement Factor (B/A)")
axes[2].set_title("Performance Improvement by Image")
axes[2].axhline(y=1, color='r', linestyle='--', label="Baseline")
axes[2].grid(axis='y')

# Add a color bar to show the pixel count scale
sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array([])
cbar = plt.colorbar(sm, ax=axes[2])
cbar.set_label('Pixels (Millions)')

# Add annotations with number of images and pixel count
for i, (_, row) in enumerate(merged_data.iterrows()):
    axes[2].annotate(f"{int(row['Number Images_A'])} imgs\n{row['Pixels (M)']:.1f}M px\n{row['Performance Improvement']:.1f}x", 
                   (i, row["Performance Improvement"]), 
                   ha='center', va='bottom', fontsize=7)

# Add average improvement line
avg_improvement = merged_data["Performance Improvement"].mean()
axes[2].axhline(y=avg_improvement, color='g', linestyle='-.', 
               label=f"Avg Improvement: {avg_improvement:.2f}x")
axes[2].legend()

# Adjust layout and save main plot
plt.tight_layout()
plt.savefig("performance_comparison.png", dpi=300)

# Additional analysis - filter breakdown
plt.figure(figsize=(14, 8))

# Select top performing images
top_images = merged_data.head(5)["Image Name"].tolist()

# Filter data for these images
df_para_top = df_para[df_para["Image Name"].isin(top_images)]
df_seq_top = df_seq[df_seq["Image Name"].isin(top_images)]

# Create a grouped bar chart for filter-by-filter comparison
fig, ax = plt.subplots(figsize=(14, 8))
bar_width = 0.35
opacity = 0.8
index = np.arange(len(top_images))

# Create bar data
for i, filter_name in enumerate([col.replace(" Duration", "") for col in duration_columns]):
    version_a_times = []
    version_b_times = []
    
    for img in top_images:
        para_row = df_para_top[df_para_top["Image Name"] == img]
        seq_row = df_seq_top[df_seq_top["Image Name"] == img]
        
        if not para_row.empty and not seq_row.empty:
            version_a_times.append(para_row[f"{filter_name} Duration"].values[0])
            version_b_times.append(seq_row[f"{filter_name} Duration"].values[0])
        else:
            version_a_times.append(0)
            version_b_times.append(0)
    
    # Plot bars for this filter
    pos_a = index + i*bar_width*2
    pos_b = pos_a + bar_width
    
    ax.bar(pos_a, version_a_times, bar_width, alpha=opacity, color='blue', label=f"{filter_name} (A)" if i==0 else "")
    ax.bar(pos_b, version_b_times, bar_width, alpha=opacity, color='red', label=f"{filter_name} (B)" if i==0 else "")

# Set labels and title
ax.set_xlabel('Image')
ax.set_ylabel('Process Time (s)')
ax.set_title('Filter-Specific Processing Times Comparison')
ax.set_xticks(index + bar_width*1.5)
ax.set_xticklabels(top_images, rotation=45, ha='right')
ax.legend()
ax.grid(axis='y')

plt.tight_layout()
plt.savefig("filter_comparison.png", dpi=300)

plt.close('all')