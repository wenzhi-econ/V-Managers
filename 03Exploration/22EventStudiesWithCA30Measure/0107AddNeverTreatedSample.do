/* 
This do file adds a sample of never treated employees to the baseline final analysis sample.
The high-flyer measure used here is CA30.

Notes:
    (1) It is not so clear about the definition of never-treated employees.
    (2) Here, I explicitly use only those employee-month observations when the employee is of WL1, and never experiences a manager transition event during his WL1 periods.

Input:
    "${TempData}/FinalFullSample.dta"                   <== created in 0101 do file 
    "${TempData}/0103_01CrossSectionalEventWorkers.dta" <== created in 0103_01 do file 
    "${TempData}/FinalAnalysisSample.dta"               <== created in 0103_03 do file 

RA: WWZ 
Time: 2025-05-12
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. find those never treated employees 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. the work-level restriction
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if WL == 1
    //impt: keep only those employee-month observations where the employee is of work level 1

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. create ChangeM: all manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

drop temp_first_month 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. if the employee experiences any manager change in this WL1 career
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Ever_ChangeM = max(ChangeM)
keep if Ever_ChangeM==0
    //impt: keep only those employees who have never changed their managers in their WL1 periods

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. double check they are not in the baseline analysis sample
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlse using "${TempData}/0103_01CrossSectionalEventWorkers.dta"
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                       993,211
        from master                   963,831  (_merge==1)
        from using                     29,380  (_merge==2)

    Matched                             1,756  (_merge==3)
    -----------------------------------------
*/
    //&? only a limited number of employees are also in the baseline analysis sample 
keep if _merge==1
    //impt: keep only those employees who are not in the baseline analysis sample 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. keep only relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep IDlse YearMonth IDlseMHR TransferSJVC ChangeSalaryGradeC LogPayBonus LogPay LogBonus 

save "${TempData}/0107NeverTreatedSample.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. append never-treated sample to the baseline analysis sample 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
    //&? 1,884,145 observations, 29,470 distinct employees 

keep ///
    IDlse YearMonth IDlseMHR TransferSJVC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    Rel_Time Event_Time Post_Event CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL IDMngr_Pre IDMngr_Post

append using "${TempData}/0107NeverTreatedSample.dta"
sort IDlse YearMonth
    //&? 2,847,976 observations, 99,600 distinct employees 

save "${TempData}/FinalAnalysisSample_WithNeverTreatedSample.dta", replace 
