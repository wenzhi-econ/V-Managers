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

job_pre = transition_dta["ONETName"].unique()
job_post = transition_dta["ONETName_5yrsLater"].unique()
job = np.union1d(job_pre, job_post)

# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-1-1. a function to calculate transition numbers
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


def calculate_transition_matrix_full(data, variable_prefix):

    #!! step 1. obtain column names based on the input
    column_before_move = f"{variable_prefix}"
    column_after_move = f"{variable_prefix}_5yrsLater"

    #!! step 2. obtain the comprehensive lists for the input variable
    lists_for_var = job

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

job_tran_mat_LtoL = calculate_transition_matrix_full(
    transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], "ONETName"
)

job_tran_mat_LtoH = calculate_transition_matrix_full(
    transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], "ONETName"
)

plot_pcolormesh_full(
    job_tran_mat_LtoL,
    "LtoL workers",
    "ONET job name 5 years after the event",
    "ONET job name at the event",
    "ONETNameTransition_LtoL_Full.png",
)

plot_pcolormesh_full(
    job_tran_mat_LtoH,
    "LtoH workers",
    "Subfunction 5 years after the event",
    "Subfunction at the event",
    "ONETNameTransition_LtoH_Full.png",
)

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-1-2. partial (top 10) subfunction transition matrix
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-2-1. top 10 subfunctions at the time of event
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!

job_ranking = transition_dta["ONETName"].value_counts()
job_ranking.head(n=10)

transition_dta["ONETName_T10"] = np.nan
transition_dta["ONETName_T10"] = transition_dta["ONETName_T10"].astype("Int64")
transition_dta.loc[
    (
        transition_dta["ONETName"]
        == "Sales Representatives, Wholesale and Manufacturing, Except Technical and Scientific Products"
    ),
    "ONETName_T10",
] = 1
transition_dta.loc[
    (
        transition_dta["ONETName"]
        == "Production, Planning, and Expediting Clerks"
    ),
    "ONETName_T10",
] = 2
transition_dta.loc[
    (
        transition_dta["ONETName"]
        == "First-Line Supervisors of Non-Retail Sales Workers"
    ),
    "ONETName_T10",
] = 3
transition_dta.loc[
    (
        transition_dta["ONETName"]
        == "Industrial Engineering Technologists and Technicians"
    ),
    "ONETName_T10",
] = 4
transition_dta.loc[
    (
        transition_dta["ONETName"]
        == "Market Research Analysts and Marketing Specialists"
    ),
    "ONETName_T10",
] = 5
transition_dta.loc[
    (
        transition_dta["ONETName"]
        == "Bookkeeping, Accounting, and Auditing Clerks"
    ),
    "ONETName_T10",
] = 6
transition_dta.loc[
    (transition_dta["ONETName"] == "Public Relations Specialists"),
    "ONETName_T10",
] = 7
transition_dta.loc[
    (
        transition_dta["ONETName"]
        == "First-Line Supervisors of Production and Operating Workers"
    ),
    "ONETName_T10",
] = 8
transition_dta.loc[
    (transition_dta["ONETName"] == "Financial and Investment Analysts"),
    "ONETName_T10",
] = 9
transition_dta.loc[
    (transition_dta["ONETName"] == "Industrial Engineers"), "ONETName_T10"
] = 10
transition_dta.loc[(transition_dta["ONETName_T10"].isna()), "ONETName_T10"] = (
    11
)

transition_dta["ONETName_5yrsLater_T10"] = np.nan
transition_dta["ONETName_5yrsLater_T10"] = transition_dta[
    "ONETName_5yrsLater_T10"
].astype("Int64")
transition_dta.loc[
    (
        transition_dta["ONETName_5yrsLater"]
        == "Sales Representatives, Wholesale and Manufacturing, Except Technical and Scientific Products"
    ),
    "ONETName_5yrsLater_T10",
] = 1
transition_dta.loc[
    (
        transition_dta["ONETName_5yrsLater"]
        == "Production, Planning, and Expediting Clerks"
    ),
    "ONETName_5yrsLater_T10",
] = 2
transition_dta.loc[
    (
        transition_dta["ONETName_5yrsLater"]
        == "First-Line Supervisors of Non-Retail Sales Workers"
    ),
    "ONETName_5yrsLater_T10",
] = 3
transition_dta.loc[
    (
        transition_dta["ONETName_5yrsLater"]
        == "Industrial Engineering Technologists and Technicians"
    ),
    "ONETName_5yrsLater_T10",
] = 4
transition_dta.loc[
    (
        transition_dta["ONETName_5yrsLater"]
        == "Market Research Analysts and Marketing Specialists"
    ),
    "ONETName_5yrsLater_T10",
] = 5
transition_dta.loc[
    (
        transition_dta["ONETName_5yrsLater"]
        == "Bookkeeping, Accounting, and Auditing Clerks"
    ),
    "ONETName_5yrsLater_T10",
] = 6
transition_dta.loc[
    (transition_dta["ONETName_5yrsLater"] == "Public Relations Specialists"),
    "ONETName_5yrsLater_T10",
] = 7
transition_dta.loc[
    (
        transition_dta["ONETName_5yrsLater"]
        == "First-Line Supervisors of Production and Operating Workers"
    ),
    "ONETName_5yrsLater_T10",
] = 8
transition_dta.loc[
    (
        transition_dta["ONETName_5yrsLater"]
        == "Financial and Investment Analysts"
    ),
    "ONETName_5yrsLater_T10",
] = 9
transition_dta.loc[
    (transition_dta["ONETName_5yrsLater"] == "Industrial Engineers"),
    "ONETName_5yrsLater_T10",
] = 10
transition_dta.loc[
    (transition_dta["ONETName_5yrsLater_T10"].isna()), "ONETName_5yrsLater_T10"
] = 11

job_value_dict = [
    "Sales Representatives, Wholesale and Manufacturing, Except Technical and Scientific Products",
    "Production, Planning, and Expediting Clerks",
    "First-Line Supervisors of Non-Retail Sales Workers",
    "Industrial Engineering Technologists and Technicians",
    "Market Research Analysts and Marketing Specialists",
    "Bookkeeping, Accounting, and Auditing Clerks",
    "Public Relations Specialists",
    "First-Line Supervisors of Production and Operating Workers",
    "Financial and Investment Analysts",
    "Industrial Engineers",
    "Other",
]

job_pre = transition_dta["ONETName_T10"].unique()
job_post = transition_dta["ONETName_5yrsLater_T10"].unique()
job = np.union1d(job_pre, job_post)

# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-2-2. a function to calculate transition numbers
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


def calculate_transition_matrix_T10(data, variable_prefix):

    #!! step 1. obtain column names based on the input
    column_before_move = f"{variable_prefix}_T10"
    column_after_move = f"{variable_prefix}_5yrsLater_T10"

    #!! step 2. obtain the comprehensive lists for the input variable
    lists_for_var = job

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
                color="white",
                fontsize="x-small",
            )
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)

    ax.set_xticks(np.arange(matrix.shape[1]) + 0.5, labels=value_dict)
    ax.set_yticks(np.arange(matrix.shape[0]) + 0.5, labels=value_dict)
    plt.setp(
        ax.get_xticklabels(), rotation=30, ha="right", rotation_mode="anchor"
    )
    plt.savefig(os.path.join(results_path, output_name), bbox_inches="tight")
    plt.show()


# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!
# !! s-1-2-4. calculate subfunction transition matrices and draw heatmaps,
# !!          separately for LtoL and LtoH groups
# !!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!#!!


job_tran_mat_LtoL = calculate_transition_matrix_T10(
    transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], "ONETName"
)

job_tran_mat_LtoH = calculate_transition_matrix_T10(
    transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], "ONETName"
)

plot_pcolormesh_T10(
    job_tran_mat_LtoL,
    job_value_dict,
    "LtoL workers",
    "Job 5 years after the event",
    "Job at the event",
    "ONETNameTransition_LtoL_T10.png",
)

plot_pcolormesh_T10(
    job_tran_mat_LtoH,
    job_value_dict,
    "LtoH workers",
    "Job 5 years after the event",
    "Job at the event",
    "ONETNameTransition_LtoH_T10.png",
)
