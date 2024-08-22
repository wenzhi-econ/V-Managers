/* 
Description of this do file:
    This do file generates new variables to describe manager quality. 
    The variables include:
        todo TO BE SUMMARIZED

This is copied from "1.Cleaning/1.4.MType".
Major changes of this file:
    I changed paths which contain raw datasets.
    To facilitate understanding of this do file, I added several comments.
    I slightly changed the order of several code blocks to make it easier to understand.
    I deleted some unnecessary that were originally commented out.

Input files:
    "${managersMNEdata}/ManagerIDReports.dta" (considered as raw data)
    "${managersMNEdata}/AllSnapshotWC_NewVars.dta" (output of "0101NewVars.do")

Temp files:
    "${tempdata}/Mlist.dta"
    "${tempdata}/MListChar.dta"

Output files:
    "${managersdta}/AllSnapshotWC_NewVars_Mngr.dta"

RA: WWZ 
Time: 18/3/2024
*/