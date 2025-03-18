import pandas as pd
import matplotlib.pyplot as plt

# Load the CSV files
df_para = pd.read_csv("durations_para_GPU.csv")
df_seq = pd.read_csv("durations_seq.csv")

# Compute the full process time as the sum of all duration columns
duration_columns = ["Import Duration", "Gray Filter Duration", "Blur Filter Duration", "Sobel Filter Duration", "Export Duration"]
df_para["Total Process Time"] = df_para[duration_columns].sum(axis=1)
df_seq["Total Process Time"] = df_seq[duration_columns].sum(axis=1)

# Extract filenames without the full path
df_para["Image Name"] = df_para["Filename"].apply(lambda x: x.split("/")[-1])
df_seq["Image Name"] = df_seq["Filename"].apply(lambda x: x.split("/")[-1])

# Create subplots
fig, axes = plt.subplots(2, 1, figsize=(10, 10))

# Plot for process times between 1 and 6 seconds
df_para_filtered = df_para[(df_para["Total Process Time"] >= 1) & (df_para["Total Process Time"] <= 6)]
df_seq_filtered = df_seq[(df_seq["Total Process Time"] >= 1) & (df_seq["Total Process Time"] <= 6)]
axes[0].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], color='b', label="Parallel Processing")
axes[0].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], color='r', label="Sequential Processing")
for i, txt in enumerate(df_para_filtered["Image Name"]):
    axes[0].annotate(txt, (df_para_filtered["Number Images"].iloc[i], df_para_filtered["Total Process Time"].iloc[i]), fontsize=8, xytext=(5,5), textcoords='offset points')
for i, txt in enumerate(df_seq_filtered["Image Name"]):
    axes[0].annotate(txt, (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), fontsize=8, xytext=(5,5), textcoords='offset points')
axes[0].set_xlabel("Number of Images")
axes[0].set_ylabel("Total Process Time (s)")
axes[0].set_title("Total Process Time (1-6s) vs. Number of Images")
axes[0].legend()
axes[0].grid()

# Plot for process times between 0 and 1 seconds
df_para_filtered = df_para[df_para["Total Process Time"] <= 1]
df_seq_filtered = df_seq[df_seq["Total Process Time"] <= 1]
axes[1].scatter(df_para_filtered["Number Images"], df_para_filtered["Total Process Time"], color='b', label="Parallel Processing")
axes[1].scatter(df_seq_filtered["Number Images"], df_seq_filtered["Total Process Time"], color='r', label="Sequential Processing")
for i, txt in enumerate(df_para_filtered["Image Name"]):
    axes[1].annotate(txt, (df_para_filtered["Number Images"].iloc[i], df_para_filtered["Total Process Time"].iloc[i]), fontsize=8, xytext=(5,5), textcoords='offset points')
for i, txt in enumerate(df_seq_filtered["Image Name"]):
    axes[1].annotate(txt, (df_seq_filtered["Number Images"].iloc[i], df_seq_filtered["Total Process Time"].iloc[i]), fontsize=8, xytext=(5,5), textcoords='offset points')
axes[1].set_xlabel("Number of Images")
axes[1].set_ylabel("Total Process Time (s)")
axes[1].set_title("Total Process Time (0-1s) vs. Number of Images")
axes[1].legend()
axes[1].grid()

# Adjust layout and save plot
plt.tight_layout()
plt.savefig("plot.png")
plt.close()