#! python3

"""
This file plots heatmaps for workers' job transition information 5 years after
the event.

Wang Wenzhi 
Time: 2024-10-30
"""

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 0. import necessary packages
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-0-1. Paths specification
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
import sys
import os

data_path = "E:\\__RA\\02MANAGERS\\Paper Managers\\Data\\02TempData"
sys.path.append(data_path)

results_path = "E:\\__RA\\02MANAGERS\\Paper Managers\\Results"

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-0-2. Other necessary packages
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

np.set_printoptions(threshold=sys.maxsize, linewidth=150)
pd.set_option("mode.copy_on_write", True)

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 1. load the dataset and create a transition matrix
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

dta_path = os.path.join(data_path, "temp_TransitionJobs_5yrsAfterEvents.dta")
transition_dta = pd.read_stata(dta_path, convert_categoricals=False)

for var in ["Func", "Func_5yrsLater", "SubFunc", "SubFunc_5yrsLater"]:
    transition_dta[var] = transition_dta[var].astype("Int64")

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-1-1. function transition matrix
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

func_pre = transition_dta["Func"].unique()
func_post = transition_dta["Func_5yrsLater"].unique()
func = np.union1d(func_pre, func_post)

# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-1-1. a function to calculate transition numbers
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


def calculate_transition_matrix(data, variable_prefix):

    #!! step 1. obtain column names based on the input
    column_before_move = f"{variable_prefix}"
    column_after_move = f"{variable_prefix}_5yrsLater"

    #!! step 2. obtain the comprehensive lists for the input variable
    lists_for_var = func

    #!! step 3. initialize a transition matrix
    transition_matrix = pd.DataFrame(
        0, index=lists_for_var, columns=lists_for_var
    )

    #!! step 4. count transitions
    for _, row in data.iterrows():
        transition_matrix.loc[
            row[column_before_move], row[column_after_move]
        ] += 1

    return transition_matrix


# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-1-2. a function to plot a heatmap
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


def plot_pcolormesh(
    matrix,
    value_dict,
    title,
    xlabel="post-event",
    ylabel="pre-event",
    output_name="output_fig.png",
):
    fig, ax = plt.subplots()
    c = ax.pcolormesh(matrix, cmap="viridis")
    fig.colorbar(c, ax=ax)

    for i in range(matrix.shape[0]):
        for j in range(matrix.shape[1]):
            ax.text(
                j + 0.5,
                i + 0.5,
                f"{matrix.iloc[i, j]}",
                ha="center",
                va="center",
                color="pink",
                fontsize="x-small",
            )
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)

    ax.set_xticks(np.arange(matrix.shape[1]) + 0.5, labels=value_dict)
    ax.set_yticks(np.arange(matrix.shape[0]) + 0.5, labels=value_dict)
    plt.setp(
        ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor"
    )
    plt.savefig(os.path.join(results_path, output_name), bbox_inches="tight")
    plt.show()


# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-1-3. calculate function transition matrices and draw heatmaps,
# !!          separately for LtoL and LtoH groups
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!

func_value_dict = [
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
    "Operations",
    "Data and Analytics",
]

func_tran_mat_LtoL = calculate_transition_matrix(
    transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], "Func"
)

func_tran_mat_LtoH = calculate_transition_matrix(
    transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], "Func"
)

plot_pcolormesh(
    func_tran_mat_LtoL,
    func_value_dict,
    "LtoL workers",
    "Function 5 years after the event",
    "Function at the event",
    "FuncTransition_LtoL.png",
)

plot_pcolormesh(
    func_tran_mat_LtoH,
    func_value_dict,
    "LtoH workers",
    "Function 5 years after the event",
    "Function at the event",
    "FuncTransition_LtoH.png",
)
