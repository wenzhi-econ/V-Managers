/* 
This do file generates three tenure-based HF measures (TB03 TB04 TB05). 

Notes: 
    (1) This measure is only defined for those employees who have ever been of work level 2 in the dataset.

Input:
    "${RawMNEData}/AllSnapshotWC.dta"      <== raw data 

Output:
    "${TempData}/0102_03EverWL2WorkerPanel.dta"             <== auxiliary dataset, which will be useful in many circumstances
    "${TempData}/0102_03HFMeasure_TenureBased.dta"          <== main output

Description of the main output dataset:
    (1) It contains the full panel of those employees who have ever been WL2 in the dataset.
    (2) Only for those employees can current age-based HF measure be constructed.
    (3) The variables are named as: IDlseMHR IDMngr_Pre IDMngr_Post YearMonth CA30.
        (a) The three ID variables are exactly the same. Their existence is for the convenience of future merge.
        (b) The existence of YearMonth means that the dataset is in employee-year-month level. Even though the HF measure is individual-specific (i.e., doesn't vary with time), in the future merge, we also wish the employee's manager is in the dataset at the same time.
        (c) CA30 is the HF measure. 

impt: "${TempData}/0102_03HFMeasure.dta" will be used frequently, in particular if we requires full sample with HF measure.

RA: WWZ 
Time: 2025-04-16
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain a dataset for HF measure construction
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. generate a list of employees who have been WL2 in the data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawMNEData}/AllSnapshotWC.dta", clear

*!! get any employee who is of WL2 at any point in the data 
generate WL2 = (WL==2) if WL!=.
sort IDlse YearMonth
bysort IDlse: egen Ever_WL2 = max(WL2)

keep if Ever_WL2==1
    //&? a panel of workers who are ever WL2 in the data 
    //&? 33,198 distinct workers, with overall 2,334,020 worker-month observations

*!! generate a Post variable indicating the worker has reached manager level
generate Post_WL2 = (WL>=2) if WL!=. 

keep IDlse YearMonth Post_WL2 Ever_WL2
duplicates drop 

save "${TempData}/0102_03EverWL2WorkerPanel.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. restrict the data to the employees who have been WL2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawMNEData}/AllSnapshotWC.dta", clear

keep  IDlse YearMonth AgeBand Tenure WL Year
order IDlse Year YearMonth AgeBand Tenure WL

sort   IDlse YearMonth
bysort IDlse: generate occurrence = _n 
bysort IDlse: generate ind_count = _N

merge 1:1 IDlse YearMonth using "${TempData}/0102_03EverWL2WorkerPanel.dta", keep(match) nogenerate
    //impt: I only keep employees who have ever been work level 2 in the dataset.
    //impt: all managers that are involved in the event study are included,
    //impt: since we impose the restriction that event managers's work level must be 2 at the time of event.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. for employees whose promotion to WL2 can be observed
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. identify employees whose promotion to WL2 can be observed
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-2-1-1. month at which the work level increases from 1 to 2
sort IDlse YearMonth 
generate WL2Prom = . 
replace  WL2Prom = 1 if IDlse[_n]==IDlse[_n-1] & WL[_n]==2 & WL[_n-1]==1

*!! s-2-1-2. investigate those employees with multiple times of promotion
bysort IDlse: egen total_WL2Prom = total(WL2Prom)
tabulate total_WL2Prom if occurrence==1, missing
    //&? some margin cases with multiple times of promotion to WL2
/* 
total_WL2Pr |
         om |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     19,952       60.10       60.10
          1 |     12,973       39.08       99.18
          2 |        261        0.79       99.96
          3 |         10        0.03       99.99
          4 |          2        0.01      100.00
------------+-----------------------------------
      Total |     33,198      100.00
*/

*!! s-2-1-3. employees with observable promotion to WL2
bysort IDlse: egen q_witness_WL2Prom = max(WL2Prom)
tabulate q_witness_WL2Prom if occurrence==1, missing 
/* 
q_witness_W |
     L2Prom |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     13,246       39.90       39.90
          . |     19,952       60.10      100.00
------------+-----------------------------------
      Total |     33,198      100.00
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. at the month of promotion, values of AgeBand and AgeContinuous 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen Tenure_atWL2Prom = max(cond(WL2Prom==1, Tenure, .))
    //&? if an employee has multiple times promotion from WL1 to WL2 (which is very likely to be a measurement error),
    //&? by using max, I consider their last promotion as the true promotion to calculate tenure at promotion

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. for employees whose promotion to WL2 cannot be observed
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sort IDlse YearMonth
bysort IDlse: egen Min_Tenure_atWL2 = min(cond(WL==2, Tenure, .))

order IDlse YearMonth WL q_witness_WL2Prom Tenure Tenure_atWL2Prom Min_Tenure_atWL2

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. create an age-based high-flyer measure  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate TB03 = . 
replace  TB03 = 1 if q_witness_WL2Prom==1 & Tenure_atWL2Prom<=3
replace  TB03 = 0 if q_witness_WL2Prom==1 & Tenure_atWL2Prom>3
replace  TB03 = 1 if q_witness_WL2Prom==. & Min_Tenure_atWL2<=3
replace  TB03 = 0 if q_witness_WL2Prom==. & Min_Tenure_atWL2>3

generate TB04 = . 
replace  TB04 = 1 if q_witness_WL2Prom==1 & Tenure_atWL2Prom<=4
replace  TB04 = 0 if q_witness_WL2Prom==1 & Tenure_atWL2Prom>4
replace  TB04 = 1 if q_witness_WL2Prom==. & Min_Tenure_atWL2<=4
replace  TB04 = 0 if q_witness_WL2Prom==. & Min_Tenure_atWL2>4

generate TB05 = . 
replace  TB05 = 1 if q_witness_WL2Prom==1 & Tenure_atWL2Prom<=5
replace  TB05 = 0 if q_witness_WL2Prom==1 & Tenure_atWL2Prom>5
replace  TB05 = 1 if q_witness_WL2Prom==. & Min_Tenure_atWL2<=5
replace  TB05 = 0 if q_witness_WL2Prom==. & Min_Tenure_atWL2>5

codebook TB03 TB04 TB05

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. save only relevant variables for future merge 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth TB*

rename IDlse IDlseMHR
generate long IDMngr_Pre  = IDlseMHR
generate long IDMngr_Post = IDlseMHR
    //&? these three id variables are exactly the same.
    //&? different names are used for future merge. 

save "${TempData}/0102_03HFMeasure_TenureBased.dta", replace
