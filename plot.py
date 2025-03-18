# import pandas as pd
# import matplotlib.pyplot as plt

# # Load the CSV files
# df_para = pd.read_csv("durations_para_OpenMP.csv")
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
df_para = pd.read_csv("durations_para_OpenMP.csv")
df_seq = pd.read_csv("durations_seq.csv")

# Compute the full process time as the sum of filter duration columns
duration_columns = ["Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration"]
df_para["Total Process Time"] = df_para[duration_columns].sum(axis=1)
df_seq["Total Process Time"] = df_seq[duration_columns].sum(axis=1)

# Extract filenames without the full path
df_para["Image Name"] = df_para["Filename"].apply(lambda x: os.path.basename(x))
df_seq["Image Name"] = df_seq["Filename"].apply(lambda x: os.path.basename(x))

# Add OpenMP type if available
if "Using_OpenMP" in df_para.columns:
    df_para["Parallel Type"] = df_para["Using_OpenMP"].apply(
        lambda x: "OpenMP (images)" if "on images" in str(x).lower() else 
                 "OpenMP (pixels)" if "on pixels" in str(x).lower() else 
                 "No OpenMP" if str(x).lower() == "no" else "OpenMP"
    )
else:
    df_para["Parallel Type"] = "OpenMP"

# Add thread count if available
if "Number_Threads" in df_para.columns:
    df_para["Threads"] = df_para["Number_Threads"]
elif "Threads" in df_para.columns:
    df_para["Threads"] = df_para["Threads"]
else:
    df_para["Threads"] = "Unknown"

# Create subplots - now with 3 rows to include speedup
fig, axes = plt.subplots(3, 1, figsize=(12, 15))

# Plot 1: Process times between 1 and 6 seconds
df_para_filtered = df_para[(df_para["Total Process Time"] >= 1) & (df_para["Total Process Time"] <= 6)]
df_seq_filtered = df_seq[(df_seq["Total Process Time"] >= 1) & (df_seq["Total Process Time"] <= 6)]

axes[0].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], 
               color='b', label="OpenMP Processing")
axes[0].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], 
               color='r', label="Sequential Processing")

for i, txt in enumerate(df_para_filtered["Image Name"]):
    thread_info = f" ({df_para_filtered['Threads'].iloc[i]} threads)" if "Threads" in df_para_filtered.columns else ""
    axes[0].annotate(f"{txt}{thread_info}", 
                    (df_para_filtered["Number Images"].iloc[i], df_para_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')
for i, txt in enumerate(df_seq_filtered["Image Name"]):
    axes[0].annotate(txt, 
                    (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

axes[0].set_xlabel("Number of Images")
axes[0].set_ylabel("Total Process Time (s)")
axes[0].set_title("Total Filter Process Time (1-6s) vs. Number of Images")
axes[0].legend()
axes[0].grid()

# Plot 2: Process times between 0 and 1 seconds
df_para_filtered = df_para[df_para["Total Process Time"] <= 1]
df_seq_filtered = df_seq[df_seq["Total Process Time"] <= 1]

axes[1].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], 
               color='b', label="OpenMP Processing")
axes[1].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], 
               color='r', label="Sequential Processing")

for i, txt in enumerate(df_para_filtered["Image Name"]):
    thread_info = f" ({df_para_filtered['Threads'].iloc[i]} threads)" if "Threads" in df_para_filtered.columns else ""
    axes[1].annotate(f"{txt}{thread_info}", 
                    (df_para_filtered["Number Images"].iloc[i], df_para_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')
for i, txt in enumerate(df_seq_filtered["Image Name"]):
    axes[1].annotate(txt, 
                    (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), 
                    fontsize=8, xytext=(5,5), textcoords='offset points')

axes[1].set_xlabel("Number of Images")
axes[1].set_ylabel("Total Process Time (s)")
axes[1].set_title("Total Filter Process Time (0-1s) vs. Number of Images")
axes[1].legend()
axes[1].grid()

# Plot 3: Speedup calculation and visualization
# Merge datasets on Image Name to calculate speedup
merged_data = pd.merge(
    df_seq[["Image Name", "Total Process Time", "Number Images"]], 
    df_para[["Image Name", "Total Process Time", "Parallel Type", "Threads", "Number Images"]], 
    on="Image Name", 
    suffixes=('_seq', '_para')
)

# Calculate speedup
merged_data["Speedup"] = merged_data["Total Process Time_seq"] / merged_data["Total Process Time_para"]

# Sort by speedup for better visualization
merged_data = merged_data.sort_values("Speedup", ascending=False)

# Create color palette based on number of images
unique_img_counts = sorted(merged_data["Number Images_seq"].unique())
cmap = plt.cm.viridis
colors = [cmap(i/len(unique_img_counts)) for i, _ in enumerate(unique_img_counts)]
color_map = {count: color for count, color in zip(unique_img_counts, colors)}

# Bar chart of speedups with colored bars based on image count
bar_positions = range(len(merged_data))
bar_colors = [color_map[count] for count in merged_data["Number Images_seq"]]

bars = axes[2].bar(bar_positions, merged_data["Speedup"], color=bar_colors)
axes[2].set_xticks(bar_positions)
axes[2].set_xticklabels(merged_data["Image Name"], rotation=90, fontsize=8)
axes[2].set_ylabel("Speedup Factor (Sequential/OpenMP)")
axes[2].set_title("Filter Performance Speedup with OpenMP Parallelization")
axes[2].axhline(y=1, color='r', linestyle='--', label="Baseline (Sequential)")
axes[2].grid(axis='y')

# Add a color bar to show the image count scale
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(min(unique_img_counts), max(unique_img_counts)))
sm.set_array([])
cbar = plt.colorbar(sm, ax=axes[2])
cbar.set_label('Number of Images')

# Add annotations with number of images and thread count
for i, (_, row) in enumerate(merged_data.iterrows()):
    thread_info = f"{row['Threads']} threads" if row['Threads'] != "Unknown" else ""
    axes[2].annotate(f"{int(row['Number Images_seq'])} imgs\n{thread_info}\n{row['Speedup']:.1f}x", 
                   (i, row["Speedup"]), 
                   ha='center', va='bottom', fontsize=7)

# Add average speedup line
avg_speedup = merged_data["Speedup"].mean()
axes[2].axhline(y=avg_speedup, color='g', linestyle='-.', 
               label=f"Avg Speedup: {avg_speedup:.2f}x")
axes[2].legend()

# Add detailed analysis by thread count if available
if "Threads" in merged_data.columns and merged_data["Threads"].nunique() > 1:
    # Create a separate figure for thread-based analysis
    plt.figure(figsize=(10, 6))
    thread_analysis = merged_data.groupby("Threads")["Speedup"].agg(["mean", "min", "max"]).reset_index()
    thread_analysis = thread_analysis.sort_values("Threads")
    
    x = range(len(thread_analysis))
    plt.bar(x, thread_analysis["mean"], yerr=[
        thread_analysis["mean"] - thread_analysis["min"], 
        thread_analysis["max"] - thread_analysis["mean"]
    ], capsize=10, color='skyblue', width=0.6)
    
    plt.xticks(x, thread_analysis["Threads"])
    plt.xlabel("Number of Threads")
    plt.ylabel("Average Speedup Factor")
    plt.title("OpenMP Performance by Thread Count")
    plt.grid(axis='y')
    
    # Add value labels on top of bars
    for i, row in enumerate(thread_analysis.itertuples()):
        plt.text(i, row.mean, f"{row.mean:.2f}x", ha='center', va='bottom')
    
    plt.tight_layout()
    plt.savefig("openmp_thread_analysis.png", dpi=300)

# Adjust layout and save main plot
plt.figure(fig.number)  # Switch back to main figure
plt.tight_layout()
plt.savefig("openmp_performance_comparison.png", dpi=300)

# Create a focused view of top speedups
plt.figure(figsize=(10, 6))
top_speedups = merged_data.head(min(10, len(merged_data)))  # Top 10 or all if fewer
    
x = range(len(top_speedups))
plt.bar(x, top_speedups["Speedup"], color=bar_colors[:len(top_speedups)])
plt.xticks(x, top_speedups["Image Name"], rotation=45, ha='right')
plt.xlabel("Image")
plt.ylabel("Speedup Factor")
plt.title("Top OpenMP Performance Speedups")
plt.axhline(y=1, color='r', linestyle='--', label="Baseline (Sequential)")
plt.grid(axis='y')
    
for i, (_, row) in enumerate(top_speedups.iterrows()):
    thread_info = f"{row['Threads']} threads" if row['Threads'] != "Unknown" else ""
    plt.text(i, row["Speedup"], 
            f"{int(row['Number Images_seq'])} imgs\n{thread_info}\n{row['Speedup']:.2f}x", 
            ha='center', va='bottom', fontsize=8)
    
plt.tight_layout()
plt.savefig("top_openmp_speedups.png", dpi=300)

plt.close('all')