******************************************		       						     
*         Author: Virginia Minni
*        Created: January 2020                                 
*     Last Modified: 12 Sep, 2020 					     
******************************************

* This do file prepares the Culture data for IA analysis and UFLP analysis using the alternative dataset based on IDlseMHRanagerHR.

********************************************************************************
  * 0. Setting path to directory
********************************************************************************
  
clear all
set more off

cd "$data"

use "$data/dta/AllSnapshotWCCulture.dta", clear 

********************************************************************************
  * Independent variables / clustering
********************************************************************************

* FirstYear FE
bys IDlse : egen FirstYearM = min(YearMonth)
label var  FirstYearM "FirstYear = min(YearMonth)"

bys IDlse : egen FirstYear = min(Year)
label var  FirstYear "FirstYear = min(Year)"

* Entry
gen Entry = 1 if FirstYearM ==YearMonth 
replace Entry = 0 if Entry==.
label var  Entry "=1 for first year month in the dataset"

* Clustering 
egen Block = group(Office Func)
order Block, a(YearMonth)

egen CountryYear = group(Country Year)
*egen Match = group(IDlse IDlseMHR)

* Team ID
bys IDlseMHR YearMonth: egen TeamID = sum(IDlse)
order TeamID, a(IDlseMHR)
label var TeamID "bys IDlseMHR YearMonth: egen TeamID = sum(IDlse)" 

********************************************************************************
 * Outcome variables - PR / Salary / VPA / Leaver / Promotion Change / Job Change Variables
********************************************************************************

* PR:  Log perf score
gen LogPR = ln(PR + 1)
gen LogPRSnapshot = ln(PRSnapshot +1)

* SALARY: LogPay, bonus, benefit, package   
gen LogPay = log(Pay)
gen LogBonus = log(Bonus+1)
gen LogBenefit = log(Benefit+1)
gen LogPackage = log(Package)
gen PayBonus = Pay + Bonus
gen LogPayBonus = log(PayBonus)
gen BonusPayRatio = Bonus/Pay

* VPA: LogVPA
gen LogVPA = log(VPA+1)

/* This code moved to FullSample 2.3.Cleaning Merge.do
* LEAVE: Leaver
local LeaverVar Leaver LeaverVol LeaverInv LeaverPerm LeaverTemp

foreach v in `LeaverVar' {
replace `v' = 0 if `v' !=1
}
* replacing 
replace LeaverInv =. if LeaverType == 2 & Leaver == 1
replace LeaverVol =. if LeaverType == 2 & Leaver == 1

*/
bys IDlse: egen LeaverID = sum(Leaver) // equals >1 for leavers (individual level variable)

gsort IDlse YearMonth
gen WeirdLeave = 1 if IDlse == IDlse[_n-1] & YearMonth == YearMonth[_n-1]+1 & Leaver[_n-1] == 1 & LeaverID>=1
replace WeirdLeave = 1 if IDlse == IDlse[_n+1] & YearMonth == YearMonth[_n+1]-1 & Leaver[_n] == 1 & LeaverID>=1

br IDlse YearMonth Leaver LeaverType if WeirdLeave == 1

* 2 such cases, with LeaverType == 2 ("LVR"), IDlse == 701247, 701250

* recoding these

foreach v in `LeaverVar' {
replace `v' = . if WeirdLeave ==1
}

drop WeirdLeave LeaverID

* I drop the promotion variable that was here as they are generated in FullSample 2.2.GenVar.do
/* PROMOTION !TO UPDATE - NO LONGER NEEDED?!
sort IDlse YearMonth
bys IDlse: gen PromChange = (SalaryGrade != SalaryGrade[_n-1]) if _n!=1
replace PromChange = 0 if PromChange == . // if there is no preceding Obs. for an individual, these variables are coded as MV.
* exception: data error, IDlse changes from WL1 to Wl2 and then back to WL1 after  2 months 
replace  PromChange =0 if IDlse == 439568 (*/

********************************************************************************
  * Flags
********************************************************************************

* FlagManager
bys IDlse: egen FlagManager= max(Manager)
label var FlagManager "=1 if IDlse ever was a manager"

* FlagIA
gen IA = 1 if EmpType >=3 & EmpType <=5
replace IA =0 if IA==.
by IDlse: egen FlagIA= max(IA)
label var FlagIA "=1 if IDlse ever did an IA"

* FlagIAEmp - flag if employee has IA manager
gen FlagIAEmp = 1 if   EmpTypeM>=3 & EmpTypeM<=5
replace FlagIAEmp = 0 if FlagIAEmp==.
label var FlagIAEmp  "=1 if IDlse's manager is on IA"

* FlagIAManager
bys IDlse: egen FlagIAManager= max(FlagIAEmp)
label var FlagIAManager "=1 if IDlse ever had an IA manager"

* FlagUFLP 
by IDlse: egen FlagUFLP= max(UFLPStatus)
label var FlagUFLP "=1 if IDlse ever was UFLP"

********************************************************************************
* Save final datasets
********************************************************************************

*keep if ( (EmpType >=3 & EmpType <=7) | EmpType==9 | EmpType== 12 | EmpType== 13) // only keep regular and IAs IDlse
compress
save "$data/dta/AllSnapshotWCCultureC", replace 

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