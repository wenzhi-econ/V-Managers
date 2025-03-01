#! python3

"""
This file plots heatmaps for occupation (task-based definition) transitions 1-7 years after the event,
separately for LtoL and LtoH workers.

RA: WWZ
Time: 2025-02-17
"""

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 0. import necessary packages and settings
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-0-1. path specification in the 01Main folder
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../01Main")))

import _pysetup as setup


def results(*args):
    """
    This function allows me to easily produce output to the results folder.
    """
    return os.path.join(setup.results_directory, *args)


# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-0-2. other necessary packages
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns

mpl.use("WebAgg")
# plt.style.use("seaborn-v0_8-whitegrid")
# print(sns.color_palette())

np.set_printoptions(threshold=sys.maxsize, linewidth=150)
pd.set_option("mode.copy_on_write", True)


# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 1. load the dataset
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# -? s-1-1. load the dataset
transition_dta = pd.read_stata(setup.data("temp_ONET_OccHeatMap.dta"), convert_categoricals=False)

# -? s-1-2. specify correct dtypes for function-related variables
OccTask_vars = transition_dta.columns[transition_dta.columns.str.startswith("OccTask")].to_list()
for var in OccTask_vars:
    transition_dta[var] = transition_dta[var].astype("Int64")

# -? s-1-3. fill in the missing values with 99
for var in transition_dta.columns:
    print(f"# of missing for {var}: {transition_dta[var].isnull().sum()}")

transition_dta = transition_dta.fillna(99)

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 2. obtain the function transition data
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-1. a dictionary indicating the mapping from values to OccTask variables
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

OccTask_value_dict = {
    1: "Cognitive",
    2: "Routine",
    3: "Social",
    99: "Missing",
}

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-2. a function to calculate the transition matrix
# -?        (adjustments for missing values are needed)
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?


def calculate_transition_matrix(data, year):
    #!! column names to be used in the worker-level dataset
    column_at_event = "OccTask0"
    column_after_event = f"OccTask{year}"

    #!! all possible function values
    OccTask_value_list = list(OccTask_value_dict.keys())

    #!! initialize a transition matrix (index and columns are function values)
    transition_mat = pd.DataFrame(0, index=OccTask_value_list, columns=OccTask_value_list)

    #!! count transitions
    for _, row in data.iterrows():
        transition_mat.loc[row[column_at_event], row[column_after_event]] += 1

    #!! adjust for missing values
    transition_mat = transition_mat.drop(99, axis=0)
    transition_mat = transition_mat.drop(99, axis=1)

    #!! get the ratio
    num_workers = transition_mat.sum().sum()
    transition_mat = transition_mat / num_workers
    print(f"# workers underlying the transition ratio matrix: {num_workers}")

    #!! additional test on the shape of the transition matrix
    assert transition_mat.shape == (3, 3)

    return transition_mat


# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-3. obtain all 2 (groups) * 7 (years) transition matrices
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

tran_1yr_LtoL = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 1)
tran_1yr_LtoH = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 1)
tran_2yr_LtoL = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 2)
tran_2yr_LtoH = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 2)
tran_3yr_LtoL = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 3)
tran_3yr_LtoH = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 3)
tran_4yr_LtoL = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 4)
tran_4yr_LtoH = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 4)
tran_5yr_LtoL = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 5)
tran_5yr_LtoH = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 5)
tran_6yr_LtoL = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 6)
tran_6yr_LtoH = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 6)
tran_7yr_LtoL = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 7)
tran_7yr_LtoH = calculate_transition_matrix(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 7)

diff_1yr = tran_1yr_LtoH - tran_1yr_LtoL
diff_2yr = tran_2yr_LtoH - tran_2yr_LtoL
diff_3yr = tran_3yr_LtoH - tran_3yr_LtoL
diff_4yr = tran_4yr_LtoH - tran_4yr_LtoL
diff_5yr = tran_5yr_LtoH - tran_5yr_LtoL
diff_6yr = tran_6yr_LtoH - tran_6yr_LtoL
diff_7yr = tran_7yr_LtoH - tran_7yr_LtoL

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 3. draw the heat map
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

func_list = [
    "Cognitive",
    "Routine",
    "Social",
]

""" Determine the scale of the heatmaps
list_of_transition_matrices = [
    tran_1yr_LtoL,
    tran_1yr_LtoH,
    tran_2yr_LtoL,
    tran_2yr_LtoH,
    tran_3yr_LtoL,
    tran_3yr_LtoH,
    tran_4yr_LtoL,
    tran_4yr_LtoH,
    tran_5yr_LtoL,
    tran_5yr_LtoH,
    tran_6yr_LtoL,
    tran_6yr_LtoH,
    tran_7yr_LtoL,
    tran_7yr_LtoH,
]
for mat in list_of_transition_matrices:
    print(mat.min().min())
    print(mat.max().max())

# &? a proper and consistent scale [0, 0.45]

list_of_diff_matrices = [
    tran_1yr_LtoH - tran_1yr_LtoL,
    tran_2yr_LtoH - tran_2yr_LtoL,
    tran_3yr_LtoH - tran_3yr_LtoL,
    tran_4yr_LtoH - tran_4yr_LtoL,
    tran_5yr_LtoH - tran_5yr_LtoL,
    tran_6yr_LtoH - tran_6yr_LtoL,
    tran_7yr_LtoH - tran_7yr_LtoL,
]
for mat in list_of_diff_matrices:
    print(mat.min().min())
    print(mat.max().max())

# &? a proper and consistent scale [-0.06, 0.06]
"""


def plot_heatmap(data, year, group, diff=False, fig_name=None):
    plt.close("all")
    fig, ax = plt.subplots(layout="constrained")
    if not diff:
        c = ax.imshow(data, vmin=0, vmax=0.45, cmap="Blues")
    elif diff:
        c = ax.imshow(data, vmin=-0.06, vmax=0.06, cmap="coolwarm")
    fig.colorbar(c, ax=ax)
    ax.grid(False)
    ax.set_title(f"{year} after the event, {group}")
    ax.set_xlabel(f"Occupation {year} after the event")
    ax.set_ylabel("Occupation at the event")
    ax.set_xticks(np.arange(data.shape[1]), labels=func_list)
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor")
    ax.set_yticks(np.arange(data.shape[0]), labels=func_list)
    if fig_name is not None:
        plt.savefig(fig_name)
    plt.show()


plot_heatmap(tran_1yr_LtoL, "1 year", "LtoL", False, results("Tran_OccTask_1yr_LtoL.png"))
plot_heatmap(tran_1yr_LtoH, "1 year", "LtoH", False, results("Tran_OccTask_1yr_LtoH.png"))
plot_heatmap(diff_1yr, "1 year", "LtoH - LtoL", True, results("Tran_OccTask_1yr_LtoHvsLtoL.png"))

plot_heatmap(tran_2yr_LtoL, "2 years", "LtoL", False, results("Tran_OccTask_2yr_LtoL.png"))
plot_heatmap(tran_2yr_LtoH, "2 years", "LtoH", False, results("Tran_OccTask_2yr_LtoH.png"))
plot_heatmap(diff_2yr, "2 years", "LtoH - LtoL", True, results("Tran_OccTask_2yr_LtoHvsLtoL.png"))

plot_heatmap(tran_3yr_LtoL, "3 years", "LtoL", False, results("Tran_OccTask_3yr_LtoL.png"))
plot_heatmap(tran_3yr_LtoH, "3 years", "LtoH", False, results("Tran_OccTask_3yr_LtoH.png"))
plot_heatmap(diff_3yr, "3 years", "LtoH - LtoL", True, results("Tran_OccTask_3yr_LtoHvsLtoL.png"))

plot_heatmap(tran_4yr_LtoL, "4 years", "LtoL", False, results("Tran_OccTask_4yr_LtoL.png"))
plot_heatmap(tran_4yr_LtoH, "4 years", "LtoH", False, results("Tran_OccTask_4yr_LtoH.png"))
plot_heatmap(diff_4yr, "4 years", "LtoH - LtoL", True, results("Tran_OccTask_4yr_LtoHvsLtoL.png"))

plot_heatmap(tran_5yr_LtoL, "5 years", "LtoL", False, results("Tran_OccTask_5yr_LtoL.png"))
plot_heatmap(tran_5yr_LtoH, "5 years", "LtoH", False, results("Tran_OccTask_5yr_LtoH.png"))
plot_heatmap(diff_5yr, "5 years", "LtoH - LtoL", True, results("Tran_OccTask_5yr_LtoHvsLtoL.png"))

plot_heatmap(tran_6yr_LtoL, "6 years", "LtoL", False, results("Tran_OccTask_6yr_LtoL.png"))
plot_heatmap(tran_6yr_LtoH, "6 years", "LtoH", False, results("Tran_OccTask_6yr_LtoH.png"))
plot_heatmap(diff_6yr, "6 years", "LtoH - LtoL", True, results("Tran_OccTask_6yr_LtoHvsLtoL.png"))

plot_heatmap(tran_7yr_LtoL, "7 years", "LtoL", False, results("Tran_OccTask_7yr_LtoL.png"))
plot_heatmap(tran_7yr_LtoH, "7 years", "LtoH", False, results("Tran_OccTask_7yr_LtoH.png"))
plot_heatmap(diff_7yr, "7 years", "LtoH - LtoL", True, results("Tran_OccTask_7yr_LtoHvsLtoL.png"))
