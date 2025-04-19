/* 
This do file compares key variables between H- and L-type managers.
The focus in this do file is plotting the distribution of managers across functions, separately for high- and low-flyer managers.

Notes:
    The sample includes all employees who have ever been WL2 in the dataset.

Input:
    "${TempData}/FinalFullSample.dta"              <== created in 0101_01 do file 
    "${TempData}/0102_03EverWL2WorkerPanel.dta"    <== created in 0102_03 do file
    "${TempData}/0102_03HFMeasure.dta"             <== created in 0102_03 do file


RA: WWZ 
Time: 2025-04-19
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain the final dataset used for manager comparison
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only those employees who have ever been WL2 in the data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
Notes:
    (1) HF measure CA30 is only defined on those employees who have ever been WL2 in the data.
    (2) The comparison between high-flyer managers and low-flyer managers do not occur in the sample of event managers.
    (3) The comparison takes place among all employees whose HF measure can be identified.
*/

use "${TempData}/FinalFullSample.dta", clear

merge 1:1 IDlse YearMonth using "${TempData}/0102_03EverWL2WorkerPanel.dta"
    keep if _merge==3
    drop _merge 
    //impt: keep the panel of employees who have ever been WL2 in the data

drop IDlseMHR
    //&? to avoid confusion, drop this variable
    //&? we are already considering these WL2 managers, we are not interested in their managers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. obtain HF measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

rename IDlse IDlseMHR
    //&? for the sake of merge, as the id variable in the using dataset is IDlseMHR
merge 1:1 IDlseMHR YearMonth using "${TempData}/0102_03HFMeasure.dta"
    drop _merge 
    //&? as expected, all observations are matched 
rename IDlseMHR IDlse

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. check the function distribution 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. keep a cross-sectional of managers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop occurrence
sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
    //&? impt: these variables are time-invariant. 
    //&? thus, for each person, we need only one observation (restricted by condition if occurrence==1)

keep if occurrence==1
    //impt: even if a manager's function could be time-varying, we consider only his first function in the dataset.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. function aggregation 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

tabulate Func, missing 

generate func_cd = (Func==3)  if !missing(Func)
generate func_m  = (Func==9)  if !missing(Func)
generate func_sc = (Func==11) if !missing(Func)
generate func_rd = (Func==10) if !missing(Func)
generate func_fi = (Func==4)  if !missing(Func)
generate func_o  = 1           if !missing(Func)
replace  func_o  = 0 if (func_cd==1 | func_m==1 | func_sc==1 | func_rd==1 | func_fi==1)

label variable func_cd "Sales function"
label variable func_m  "Marketing function"
label variable func_sc "Supply chain function"
label variable func_rd "Research/Development function"
label variable func_fi "Finance function"
label variable func_o  "Other functions"

generate FuncAgg = . 
replace  FuncAgg = 1 if func_cd==1
replace  FuncAgg = 2 if func_m ==1
replace  FuncAgg = 3 if func_sc==1
replace  FuncAgg = 4 if func_rd==1
replace  FuncAgg = 5 if func_fi==1
replace  FuncAgg = 6 if func_o ==1

tab FuncAgg, missing
    //&? 84% of managers are in the largest five functions 
/* 
    FuncAgg |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      7,572       22.81       22.81
          2 |      6,653       20.04       42.85
          3 |      6,729       20.27       63.12
          4 |      3,562       10.73       73.85
          5 |      3,330       10.03       83.88
          6 |      5,352       16.12      100.00
------------+-----------------------------------
      Total |     33,198      100.00
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. calculate share of managers in each function, separately for H and L
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep IDlse Func func_cd - FuncAgg CA30

sort FuncAgg CA30 IDlse
bysort FuncAgg CA30: egen count_func_ca30 = count(IDlse)

sort CA30 FuncAgg IDlse
bysort CA30: egen count_ca30 = count(IDlse)

generate share_func_ca30 = count_func_ca30 / count_ca30
keep FuncAgg CA30 share_func_ca30
duplicates drop

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. plot the function distribution 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

graph twoway ///
    (bar share_func_ca30 FuncAgg if CA30==0, bcolor(ebblue%30)) ///
    (bar share_func_ca30 FuncAgg if CA30==1, bcolor(red%30)) ///
    , legend(label(1 "Low-flyer managers") label(2 "High-flyer managers") position(2) ring(0)) ///
    xlabel(1 "Sales" 2 "Marketing" 3 "Supply chain" 4 "R&D" 5 "Finance" 6 "Others") xtitle("Function", size(medlarge)) ///
    ytitle("Share of managers", size(medlarge))

graph export "${Results}/004ResultsBasedOnCA30/CA30_DistOfFuncs_MngrHvsL.png", replace as(png)