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
# -? s-1-1. full subfunction transition matrix
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

subfunc_pre = transition_dta["SubFunc"].unique()
subfunc_post = transition_dta["SubFunc_5yrsLater"].unique()
subfunc = np.union1d(subfunc_pre, subfunc_post)

# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-1-1. a function to calculate transition numbers
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


def calculate_transition_matrix_full(data, variable_prefix):

    #!! step 1. obtain column names based on the input
    column_before_move = f"{variable_prefix}"
    column_after_move = f"{variable_prefix}_5yrsLater"

    #!! step 2. obtain the comprehensive lists for the input variable
    lists_for_var = subfunc

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


def plot_pcolormesh_full(
    matrix,
    title,
    xlabel="post-event",
    ylabel="pre-event",
    output_name="output_fig.png",
):
    fig, ax = plt.subplots()
    c = ax.pcolormesh(matrix, cmap="viridis")
    fig.colorbar(c, ax=ax)

    # for i in range(matrix.shape[0]):
    #     for j in range(matrix.shape[1]):
    #         ax.text(
    #             j + 0.5,
    #             i + 0.5,
    #             f"{matrix.iloc[i, j]}",
    #             ha="center",
    #             va="center",
    #             color="pink",
    #             fontsize="x-small",
    #         )
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)

    plt.savefig(os.path.join(results_path, output_name), bbox_inches="tight")
    plt.show()


# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-1-3. calculate full subfunction transition matrices and draw heatmaps,
# !!          separately for LtoL and LtoH groups
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!

subfunc_tran_mat_LtoL = calculate_transition_matrix_full(
    transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], "Func"
)

subfunc_tran_mat_LtoH = calculate_transition_matrix_full(
    transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], "Func"
)

plot_pcolormesh_full(
    subfunc_tran_mat_LtoL,
    "LtoL workers",
    "Subfunction 5 years after the event",
    "Subfunction at the event",
    "Tran_AllSubFunc_All_Num_LtoL.png",
)

plot_pcolormesh_full(
    subfunc_tran_mat_LtoH,
    "LtoH workers",
    "Subfunction 5 years after the event",
    "Subfunction at the event",
    "Tran_AllSubFunc_All_Num_LtoH.png",
)

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-1-2. partial (top 10) subfunction transition matrix
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-2-1. top 10 subfunctions at the time of event
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!

subfunc_ranking = transition_dta["SubFunc"].value_counts()
subfunc_ranking.head(n=10)

transition_dta["SubFunc_T10"] = np.nan
transition_dta["SubFunc_T10"] = transition_dta["SubFunc_T10"].astype("Int64")
transition_dta.loc[(transition_dta["SubFunc"] == 13), "SubFunc_T10"] = 1
transition_dta.loc[(transition_dta["SubFunc"] == 37), "SubFunc_T10"] = 2
transition_dta.loc[(transition_dta["SubFunc"] == 53), "SubFunc_T10"] = 3
transition_dta.loc[(transition_dta["SubFunc"] == 14), "SubFunc_T10"] = 4
transition_dta.loc[(transition_dta["SubFunc"] == 50), "SubFunc_T10"] = 5
transition_dta.loc[(transition_dta["SubFunc"] == 39), "SubFunc_T10"] = 6
transition_dta.loc[(transition_dta["SubFunc"] == 24), "SubFunc_T10"] = 7
transition_dta.loc[(transition_dta["SubFunc"] == 22), "SubFunc_T10"] = 8
transition_dta.loc[(transition_dta["SubFunc"] == 35), "SubFunc_T10"] = 9
transition_dta.loc[(transition_dta["SubFunc"] == 52), "SubFunc_T10"] = 10
transition_dta.loc[(transition_dta["SubFunc_T10"].isna()), "SubFunc_T10"] = 11

transition_dta["SubFunc_5yrsLater_T10"] = np.nan
transition_dta["SubFunc_5yrsLater_T10"] = transition_dta[
    "SubFunc_5yrsLater_T10"
].astype("Int64")
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 13), "SubFunc_5yrsLater_T10"
] = 1
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 37), "SubFunc_5yrsLater_T10"
] = 2
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 53), "SubFunc_5yrsLater_T10"
] = 3
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 14), "SubFunc_5yrsLater_T10"
] = 4
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 50), "SubFunc_5yrsLater_T10"
] = 5
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 39), "SubFunc_5yrsLater_T10"
] = 6
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 24), "SubFunc_5yrsLater_T10"
] = 7
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 22), "SubFunc_5yrsLater_T10"
] = 8
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 35), "SubFunc_5yrsLater_T10"
] = 9
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater"] == 52), "SubFunc_5yrsLater_T10"
] = 10
transition_dta.loc[
    (transition_dta["SubFunc_5yrsLater_T10"].isna()), "SubFunc_5yrsLater_T10"
] = 11

subfunc_value_dict = [
    "Customer Management",
    "Make",
    "Product Development",
    "Customer and Account Management",
    "Planning",
    "Marketing Category",
    "Finance Services",
    "Finance Business Partnering",
    "Logistics",
    "Procurement",
    "Other",
]

subfunc_pre = transition_dta["SubFunc_T10"].unique()
subfunc_post = transition_dta["SubFunc_5yrsLater_T10"].unique()
subfunc = np.union1d(subfunc_pre, subfunc_post)

# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-2-2. a function to calculate transition numbers
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


def calculate_transition_matrix_T10(data, variable_prefix):

    #!! step 1. obtain column names based on the input
    column_before_move = f"{variable_prefix}_T10"
    column_after_move = f"{variable_prefix}_5yrsLater_T10"

    #!! step 2. obtain the comprehensive lists for the input variable
    lists_for_var = subfunc

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
# !! s-1-2-3. a function to plot a heatmap
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


def plot_pcolormesh_T10(
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
# !! s-1-2-4. calculate subfunction transition matrices and draw heatmaps,
# !!          separately for LtoL and LtoH groups
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


subfunc_tran_mat_LtoL = calculate_transition_matrix_T10(
    transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], "SubFunc"
)

subfunc_tran_mat_LtoH = calculate_transition_matrix_T10(
    transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], "SubFunc"
)

plot_pcolormesh_T10(
    subfunc_tran_mat_LtoL,
    subfunc_value_dict,
    "LtoL workers",
    "Subfunction 5 years after the event",
    "Subfunction at the event",
    "Tran_PartSubFunc_All_Num_LtoL.png",
)

plot_pcolormesh_T10(
    subfunc_tran_mat_LtoH,
    subfunc_value_dict,
    "LtoH workers",
    "Subfunction 5 years after the event",
    "Subfunction at the event",
    "Tran_PartSubFunc_All_Num_LtoH.png",
)
