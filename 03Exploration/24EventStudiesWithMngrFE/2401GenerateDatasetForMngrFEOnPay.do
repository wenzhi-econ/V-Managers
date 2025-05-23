/* 
This do file generates the do file used for estimating manager fixed effects on their subordinates' pay outcomes.

Input:
    "${TempData}/0103_01CrossSectionalEventWorkers.dta" <== created in 0103_01 do file 
    "${TempData}/FinalFullSample.dta"                   <== created in 0101_01 do file 

RA: WWZ 
Time: 2025-05-13
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. identify a list of involving event managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0103_01CrossSectionalEventWorkers.dta", clear 

keep IDlse IDMngr_Pre IDMngr_Post
rename (IDMngr_Pre IDMngr_Post) (IDMngr0 IDMngr1)
reshape long IDMngr, i(IDlse) j(Post)

keep IDMngr 
duplicates drop 
    //&? 14,687 distinct involving event managers 
rename IDMngr IDlseMHR

save "${TempData}/2401_AListOfInvolvingEventMngrs.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. estimate manager fixed effects on the set of event managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

merge m:1 IDlseMHR using "${TempData}/2401_AListOfInvolvingEventMngrs.dta", keep(match) nogenerate 
    //impt: keep only those employee-month observations where the employee's manager is in the list of event managers

keep  Year YearMonth IDlse IDlseMHR WL LogPayBonus TransferSJVC ChangeSalaryGradeC
order Year YearMonth IDlse IDlseMHR WL LogPayBonus TransferSJVC ChangeSalaryGradeC

sort IDlse YearMonth

save "${TempData}/2401EmployeePanelUsedForMngrFE.dta", replace 

