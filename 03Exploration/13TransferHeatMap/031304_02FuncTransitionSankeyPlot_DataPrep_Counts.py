#! python3

"""
This file prepares the data used for plotting Sankey plots under different conditions, separately for LtoL and
LtoH workers.

Note that the resulting dataset should have 16*16 rows, two variables indicting the function at the event time
and function after the event, and different columns for transition ratios under different conditions.

RA: WWZ 
Time: 2025-02-19
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


def tempdata(*args):
    """
    This function allows me to easily produce output to the 02TempData folder.
    """
    return os.path.join(setup.tempdata_directory, *args)


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
# &? the value label and tabulation info is in the 031301 do file

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


def tran_mat(data: pd.DataFrame, year: int, ratio_name: str = "Ratio") -> pd.DataFrame:
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

    #!! get the ratio (commented out)
    # num_workers = transition_mat.sum().sum()
    # transition_mat = transition_mat / num_workers
    # print(f"# workers underlying the transition ratio matrix: {num_workers}")
    num_workers = transition_mat.sum().sum()
    print(f"# workers underlying the transition ratio matrix: {num_workers}")

    #!! additional test on the shape of the transition matrix
    assert transition_mat.shape == (16, 16)

    #!! rename index and columns
    transition_mat["FuncAtEvent"] = transition_mat.index
    func_cols = [col for col in transition_mat.columns if col != "FuncAtEvent"]
    transition_mat = transition_mat.rename(
        columns=lambda col: "FuncAfter" + str(col) if col in func_cols else col
    )
    transition_mat = transition_mat.reset_index(drop=True)

    #!! reshape the transition matrix to long format with 3 variables: FuncAtEvent, FuncAfterEvent, Ratio
    transition_mat = pd.wide_to_long(
        df=transition_mat, stubnames="FuncAfter", i="FuncAtEvent", j="FuncAfterEvent"
    ).rename(columns={"FuncAfter": ratio_name})

    return transition_mat


# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-3. 2 (groups) * 7 (years) transition matrices among all workers
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

tran_1yr_LtoL_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 1, "Counts_1yr_LtoL_All")
tran_1yr_LtoH_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 1, "Counts_1yr_LtoH_All")
tran_2yr_LtoL_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 2, "Counts_2yr_LtoL_All")
tran_2yr_LtoH_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 2, "Counts_2yr_LtoH_All")
tran_3yr_LtoL_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 3, "Counts_3yr_LtoL_All")
tran_3yr_LtoH_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 3, "Counts_3yr_LtoH_All")
tran_4yr_LtoL_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 4, "Counts_4yr_LtoL_All")
tran_4yr_LtoH_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 4, "Counts_4yr_LtoH_All")
tran_5yr_LtoL_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 5, "Counts_5yr_LtoL_All")
tran_5yr_LtoH_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 5, "Counts_5yr_LtoH_All")
tran_6yr_LtoL_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 6, "Counts_6yr_LtoL_All")
tran_6yr_LtoH_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 6, "Counts_6yr_LtoH_All")
tran_7yr_LtoL_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoL"] == 1)], 7, "Counts_7yr_LtoL_All")
tran_7yr_LtoH_all = tran_mat(transition_dta.loc[(transition_dta["FT_LtoH"] == 1)], 7, "Counts_7yr_LtoH_All")

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-4. 2 (groups) * 7 (years) transition matrices among movers
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

tran_1yr_LtoL_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_1yr"] == 1))],
    year=1,
    ratio_name="Counts_1yr_LtoL_Movers",
)

tran_1yr_LtoH_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_1yr"] == 1))],
    year=1,
    ratio_name="Counts_1yr_LtoH_Movers",
)

tran_2yr_LtoL_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_2yr"] == 1))],
    year=2,
    ratio_name="Counts_2yr_LtoL_Movers",
)
tran_2yr_LtoH_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_2yr"] == 1))],
    year=2,
    ratio_name="Counts_2yr_LtoH_Movers",
)
tran_3yr_LtoL_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_3yr"] == 1))],
    year=3,
    ratio_name="Counts_3yr_LtoL_Movers",
)
tran_3yr_LtoH_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_3yr"] == 1))],
    year=3,
    ratio_name="Counts_3yr_LtoH_Movers",
)
tran_4yr_LtoL_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_4yr"] == 1))],
    year=4,
    ratio_name="Counts_4yr_LtoL_Movers",
)
tran_4yr_LtoH_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_4yr"] == 1))],
    year=4,
    ratio_name="Counts_4yr_LtoH_Movers",
)
tran_5yr_LtoL_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_5yr"] == 1))],
    year=5,
    ratio_name="Counts_5yr_LtoL_Movers",
)
tran_5yr_LtoH_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_5yr"] == 1))],
    year=5,
    ratio_name="Counts_5yr_LtoH_Movers",
)
tran_6yr_LtoL_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_6yr"] == 1))],
    year=6,
    ratio_name="Counts_6yr_LtoL_Movers",
)
tran_6yr_LtoH_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_6yr"] == 1))],
    year=6,
    ratio_name="Counts_6yr_LtoH_Movers",
)
tran_7yr_LtoL_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoL"] == 1) & (transition_dta["Movers_7yr"] == 1))],
    year=7,
    ratio_name="Counts_7yr_LtoL_Movers",
)
tran_7yr_LtoH_movers = tran_mat(
    transition_dta.loc[((transition_dta["FT_LtoH"] == 1) & (transition_dta["Movers_7yr"] == 1))],
    year=7,
    ratio_name="Counts_7yr_LtoH_Movers",
)

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-5. merge all the transition matrices
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

tran_ratio = tran_1yr_LtoL_all.join(
    [
        tran_1yr_LtoH_all,
        tran_2yr_LtoL_all,
        tran_2yr_LtoH_all,
        tran_3yr_LtoL_all,
        tran_3yr_LtoH_all,
        tran_4yr_LtoL_all,
        tran_4yr_LtoH_all,
        tran_5yr_LtoL_all,
        tran_5yr_LtoH_all,
        tran_6yr_LtoL_all,
        tran_6yr_LtoH_all,
        tran_7yr_LtoL_all,
        tran_7yr_LtoH_all,
        tran_1yr_LtoL_movers,
        tran_1yr_LtoH_movers,
        tran_2yr_LtoL_movers,
        tran_2yr_LtoH_movers,
        tran_3yr_LtoL_movers,
        tran_3yr_LtoH_movers,
        tran_4yr_LtoL_movers,
        tran_4yr_LtoH_movers,
        tran_5yr_LtoL_movers,
        tran_5yr_LtoH_movers,
        tran_6yr_LtoL_movers,
        tran_6yr_LtoH_movers,
        tran_7yr_LtoL_movers,
        tran_7yr_LtoH_movers,
    ],
    validate="one_to_one",
)

tran_ratio = tran_ratio.reset_index()

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-6. transform function values to function names
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

tran_ratio["FuncAtEvent"] = tran_ratio["FuncAtEvent"].map(func_value_dict).astype(str)
tran_ratio["FuncAfterEvent"] = tran_ratio["FuncAfterEvent"].map(func_value_dict).astype(str)

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-7. generate stata dataset
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

tran_ratio.to_stata(tempdata("temp_TranFunc_SankeyPlots_Counts.dta"), write_index=False)
