********************************************************************************
**                       IA AND UFLP DATASETS                                 **
**                              7 Nov, 2020                                   **
/*******************************************************************************

This do-file creates datasets for selected samples 

*/

* directory
cd "$Managersdta"
use "$Managersdta/Managers.dta", clear

preserve

* RoundIA for Manager 
by IDlse (YearMonth), sort: gen ManagerRound = (IDlseMHR != IDlseMHR[_n-1] & _n > 1)
by IDlse (YearMonth), sort: gen ManagerRoundcum = sum(ManagerRound)
replace ManagerRound =  ManagerRoundcum +1
drop ManagerRoundcum
label var ManagerRound "How many managers employee changes"

* IAManager
gen IAManager = 1 if EmpTypeM>=3 & EmpTypeM<=5
replace IAManager =0 if IAManager ==. 
label var IAManager "=1 if IDlse's manager is on IA"
by IDlse (YearMonth), sort: gen Count = _n
* RoundIA for Employee
by IDlse (YearMonth), sort: gen RoundIA = (IDlseMHR != IDlseMHR[_n-1] & _n > 1  & FlagIAEmp ==1)
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIA)
replace RoundIA =  RoundIAcum 
drop RoundIAcum

by IDlse: egen RoundIAMax = max(RoundIA)
label var RoundIA "Number of time the employee has had a manager on IA"
keep if RoundIAMax < 2 & RoundIAMax > 0 // drop employees that had RoundIA>1 or that never had an IA manager 
by IDlse (YearMonth), sort: gen MonthsIA1 = Count if (IDlseMHR != IDlseMHR[_n-1] & _n > 1  & RoundIA==1  & RoundIA[_n-1]==0)
by IDlse: egen MonthsIA1Max = max(MonthsIA1)
replace MonthsIA1 = MonthsIA1Max
label var MonthsIA1 "Number of months on IA1 for the employee"
drop MonthsIA1Max
gen WindowIA1 = Count - MonthsIA1
replace WindowIA1 = 999 if WindowIA1==.

/* loops for when I want to consider more than 1 IA round per employee
forval i=1(1)9{
by IDlse: gen MonthIA`i' = Count if (IDlseMHR != IDlseMHR[_n-1] & _n > 1  & RoundIA==`i'  & RoundIA[_n-1]==`i'-1)
by IDlse: egen MonthIA`i'Max = max(MonthIA`i')
replace MonthIA`i' = MonthIA`i'Max
drop MonthIA`i'Max
gen WindowIA`i' = Count - MonthIA`i'
replace WindowIA`i' = 999 if WindowIA`i'==.
}

foreach var in CulturalDistance OutGroup KinshipDistance{
by IDlse: gen `var'IA1 = `var' if (IDlseMHR != IDlseMHR[_n-1] & _n > 1  & RoundIA==1  & RoundIA[_n-1]==1-1) 
by IDlse: egen `var'IA1Max = max(`var'IA1)
replace `var'IA1 = `var'IA1Max
* replace `var'IA1 = 999 if `var'IA1 == . // only to run if full sample 
drop `var'IA1Max
}
*/
* Save dataset
compress
save "$Managersdta/IA.dta", replace

restore 

preserve

keep if FlagIA ==1 
* Save dataset
compress
save "$Managersdta/IAManager.dta", replace

restore 


preserve 

* Sample selection
keep if  FlagUFLP == 1 // only keep employees that ever did UFLP 
* Save dataset
compress
save "$Managersdta/GraduatesRaw.dta", replace

restore 
