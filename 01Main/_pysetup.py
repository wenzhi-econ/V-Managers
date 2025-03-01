#! python3

"""
This file should be imported in all python scripts used in this project to
specify working directory and data paths.

RA: WWZ 
Time: 2025-01-30
"""

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 1. set up paths used for all python script files
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

import os
import getpass

# !! set up working directory based on user name
user_name = getpass.getuser()

if user_name == "wang":
    working_directory = "E:\\__RA\\02MANAGERS"
    os.chdir(working_directory)

# !! set up folders
jmp_directory = os.path.join(working_directory, "Paper Managers")
dofiles_directory = os.path.join(jmp_directory, "DoFiles")
results_directory = os.path.join(jmp_directory, "Results")

finaldata_directory = os.path.join(jmp_directory, "Data")
tempdata_directory = os.path.join(finaldata_directory, "02TempData")


# !! function to access datasets in the TempData folder
def data(*args):
    """
    This function allows me to easily access the dataset stored in the TempData folder.
    """
    return os.path.join(tempdata_directory, *args)
