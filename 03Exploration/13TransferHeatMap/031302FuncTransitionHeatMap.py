#! python3

"""
This file plots heatmaps for function transition 1-7 years after the event,
separately for LtoL and LtoH event workers.

RA: WWZ
Time: 2025-02-20
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
transition_dta = pd.read_stata(setup.data("temp_TranFunc_LtoLvsLtoH.dta"), convert_categoricals=False)

# -? s-1-2. specify correct dtypes for function-related variables
func_cols = [
    var for var in transition_dta.columns if var != "FT_LtoL" and var != "FT_LtoH" and var != "IDlse"
]
for var in func_cols:
    transition_dta[var] = transition_dta[var].astype("Int64")

# -? s-1-3. fill in the missing values with 99
for var in transition_dta.columns:
    print(f"# of missing for {var}: {transition_dta[var].isnull().sum()}")

transition_dta = transition_dta.fillna(99)

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 2. obtain the function transition data
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-1. a dictionary indicating the mapping from values to function info
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# &? the value label and tabulation info is in the 0901 do file

func_value_dict = {
    1: "Audit",
    2: "Communications",
    3: "Customer Development",
    4: "Finance",
    5: "General Management",
    6: "Human Resources",
    7: "Information Technology",
    8: "Legal",
    9: "Marketing",
    10: "Research/Development",
    11: "Supply Chain",
    12: "Workplace Services",
    14: "Information and Analytics",
    15: "Project Management",
    16: "Operations",
    17: "Data and Analytics",
    99: "Missing",
}

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-2. a function to calculate the transition matrix
# -?        (adjustments for missing values are needed)
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?


def calculate_transition_matrix(data, year):
    #!! column names to be used in the worker-level dataset
    column_at_event = "Func0"
    column_after_event = f"Func{year}"

    #!! all possible function values
    func_value_list = list(func_value_dict.keys())

    #!! initialize a transition matrix (index and columns are function values)
    transition_mat = pd.DataFrame(0, index=func_value_list, columns=func_value_list)

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
    assert transition_mat.shape == (16, 16)

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

# &? a proper and consistent scale [0, 0.4]

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

# &? a proper and consistent scale [-0.15, 0.15]
"""

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 3. draw the heat map
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

func_list = [
    "Audit",
    "Communications",
    "Customer Development",
    "Finance",
    "General Management",
    "Human Resources",
    "Information Technology",
    "Legal",
    "Marketing",
    "Research/Development",
    "Supply Chain",
    "Workplace Services",
    "Information and Analytics",
    "Project Management",
    "Operations",
    "Data and Analytics",
]

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-3-1. a function to plot the heatmap
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?


def heatmap(data, year, group, diff=False, fig_name=None):
    plt.close("all")
    fig, ax = plt.subplots(layout="constrained")
    if not diff:
        c = ax.imshow(data, vmin=0, vmax=0.4, cmap="Blues")
    elif diff:
        c = ax.imshow(data, vmin=-0.15, vmax=0.15, cmap="coolwarm")
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


# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-3-2. difference in LtoH and LtoL transition matrices
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

heatmap(
    tran_1yr_LtoH - tran_1yr_LtoL,
    "1 year",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_1yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_2yr_LtoH - tran_2yr_LtoL,
    "2 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_2yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_3yr_LtoH - tran_3yr_LtoL,
    "3 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_3yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_4yr_LtoH - tran_4yr_LtoL,
    "4 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_4yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_5yr_LtoH - tran_5yr_LtoL,
    "5 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_5yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_6yr_LtoH - tran_6yr_LtoL,
    "6 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_6yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_7yr_LtoH - tran_7yr_LtoL,
    "7 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_7yr_LtoHvsLtoL.png"),
)

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-3-3. separate for LtoL and LtoH workers
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

heatmap(tran_1yr_LtoH, "1 year", "LtoH", diff=False, fig_name=results("Tran_Func_1yr_LtoH.png"))
heatmap(tran_2yr_LtoH, "2 year", "LtoH", diff=False, fig_name=results("Tran_Func_2yr_LtoH.png"))
heatmap(tran_3yr_LtoH, "3 year", "LtoH", diff=False, fig_name=results("Tran_Func_3yr_LtoH.png"))
heatmap(tran_4yr_LtoH, "4 year", "LtoH", diff=False, fig_name=results("Tran_Func_4yr_LtoH.png"))
heatmap(tran_5yr_LtoH, "5 year", "LtoH", diff=False, fig_name=results("Tran_Func_5yr_LtoH.png"))
heatmap(tran_6yr_LtoH, "6 year", "LtoH", diff=False, fig_name=results("Tran_Func_6yr_LtoH.png"))
heatmap(tran_7yr_LtoH, "7 year", "LtoH", diff=False, fig_name=results("Tran_Func_7yr_LtoH.png"))

heatmap(tran_1yr_LtoL, "1 year", "LtoL", diff=False, fig_name=results("Tran_Func_1yr_LtoL.png"))
heatmap(tran_2yr_LtoL, "2 year", "LtoL", diff=False, fig_name=results("Tran_Func_2yr_LtoL.png"))
heatmap(tran_3yr_LtoL, "3 year", "LtoL", diff=False, fig_name=results("Tran_Func_3yr_LtoL.png"))
heatmap(tran_4yr_LtoL, "4 year", "LtoL", diff=False, fig_name=results("Tran_Func_4yr_LtoL.png"))
heatmap(tran_5yr_LtoL, "5 year", "LtoL", diff=False, fig_name=results("Tran_Func_5yr_LtoL.png"))
heatmap(tran_6yr_LtoL, "6 year", "LtoL", diff=False, fig_name=results("Tran_Func_6yr_LtoL.png"))
heatmap(tran_7yr_LtoL, "7 year", "LtoL", diff=False, fig_name=results("Tran_Func_7yr_LtoL.png"))

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 4. extension: focus on job movers
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-4-1. re-calculate the transition matrices for job movers
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

tran_1yr_LtoL = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_1yr"] == 1))], 1
)
tran_1yr_LtoH = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_1yr"] == 1))], 1
)
tran_2yr_LtoL = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_2yr"] == 1))], 2
)
tran_2yr_LtoH = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_2yr"] == 1))], 2
)
tran_3yr_LtoL = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_3yr"] == 1))], 3
)
tran_3yr_LtoH = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_3yr"] == 1))], 3
)
tran_4yr_LtoL = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_4yr"] == 1))], 4
)
tran_4yr_LtoH = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_4yr"] == 1))], 4
)
tran_5yr_LtoL = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_5yr"] == 1))], 5
)
tran_5yr_LtoH = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_5yr"] == 1))], 5
)
tran_6yr_LtoL = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_6yr"] == 1))], 6
)
tran_6yr_LtoH = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_6yr"] == 1))], 6
)
tran_7yr_LtoL = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_7yr"] == 1))], 7
)
tran_7yr_LtoH = calculate_transition_matrix(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_7yr"] == 1))], 7
)

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-4-2. heatmaps for LtoH-LtoL
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

heatmap(
    tran_1yr_LtoH - tran_1yr_LtoL,
    "1 year",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_JobMovers_1yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_2yr_LtoH - tran_2yr_LtoL,
    "2 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_JobMovers_2yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_3yr_LtoH - tran_3yr_LtoL,
    "3 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_JobMovers_3yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_4yr_LtoH - tran_4yr_LtoL,
    "4 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_JobMovers_4yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_5yr_LtoH - tran_5yr_LtoL,
    "5 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_JobMovers_5yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_6yr_LtoH - tran_6yr_LtoL,
    "6 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_JobMovers_6yr_LtoHvsLtoL.png"),
)
heatmap(
    tran_7yr_LtoH - tran_7yr_LtoL,
    "7 years",
    "LtoH - LtoL",
    diff=True,
    fig_name=results("Tran_Func_JobMovers_7yr_LtoHvsLtoL.png"),
)

heatmap(tran_1yr_LtoH, "1 year", "LtoH", diff=False, fig_name=results("Tran_Func_JobMovers_1yr_LtoH.png"))
heatmap(tran_2yr_LtoH, "2 year", "LtoH", diff=False, fig_name=results("Tran_Func_JobMovers_2yr_LtoH.png"))
heatmap(tran_3yr_LtoH, "3 year", "LtoH", diff=False, fig_name=results("Tran_Func_JobMovers_3yr_LtoH.png"))
heatmap(tran_4yr_LtoH, "4 year", "LtoH", diff=False, fig_name=results("Tran_Func_JobMovers_4yr_LtoH.png"))
heatmap(tran_5yr_LtoH, "5 year", "LtoH", diff=False, fig_name=results("Tran_Func_JobMovers_5yr_LtoH.png"))
heatmap(tran_6yr_LtoH, "6 year", "LtoH", diff=False, fig_name=results("Tran_Func_JobMovers_6yr_LtoH.png"))
heatmap(tran_7yr_LtoH, "7 year", "LtoH", diff=False, fig_name=results("Tran_Func_JobMovers_7yr_LtoH.png"))

heatmap(tran_1yr_LtoL, "1 year", "LtoL", diff=False, fig_name=results("Tran_Func_JobMovers_1yr_LtoL.png"))
heatmap(tran_2yr_LtoL, "2 year", "LtoL", diff=False, fig_name=results("Tran_Func_JobMovers_2yr_LtoL.png"))
heatmap(tran_3yr_LtoL, "3 year", "LtoL", diff=False, fig_name=results("Tran_Func_JobMovers_3yr_LtoL.png"))
heatmap(tran_4yr_LtoL, "4 year", "LtoL", diff=False, fig_name=results("Tran_Func_JobMovers_4yr_LtoL.png"))
heatmap(tran_5yr_LtoL, "5 year", "LtoL", diff=False, fig_name=results("Tran_Func_JobMovers_5yr_LtoL.png"))
heatmap(tran_6yr_LtoL, "6 year", "LtoL", diff=False, fig_name=results("Tran_Func_JobMovers_6yr_LtoL.png"))
heatmap(tran_7yr_LtoL, "7 year", "LtoL", diff=False, fig_name=results("Tran_Func_JobMovers_7yr_LtoL.png"))
