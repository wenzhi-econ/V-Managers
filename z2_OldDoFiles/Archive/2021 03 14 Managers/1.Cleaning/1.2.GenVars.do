******************************************		       						     
*         Author: Virginia Minni                            
*     Last Modified: 7 Nov, 2020 					     
******************************************

* This do file generates relevant variables
* input: "$Managersdta/AllSnapshotM.dta"
* output: "$Managersdta/Managers.dta"

********************************************************************************
  * 0. Setting path to directory
********************************************************************************
  
clear all
set more off

cd "$Managersdta"

use "$Managersdta/AllSnapshotM.dta", clear 

********************************************************************************
  * Independent variables / clustering
********************************************************************************

* Labelling 
label var  MasterType "Expat (IA ) or local employee"

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

* Tenure FE 
egen TenureBand = cut(Tenure), group(10)
egen TenureBandM = cut(TenureM), group(10) 

* PR:  Log perf score
gen LogPR = ln(PR + 1)
gen LogPRSnapshot = ln(PRSnapshot +1)

* VPA: LogVPA
gen LogVPA = log(VPA+1)

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

********************************************************************************
  * Job transfers during spell
********************************************************************************

* TRANSFER PTITLE 
gen  TransferPTitleDuringSpell = TransferPTitle
replace  TransferPTitleDuringSpell = 0 if YearMonth == SpellStart  | YearMonth == SpellEnd
label var TransferPTitleDuringSpell "=1 if employee changes job during manager spell"

gen z = TransferPTitleDuringSpell
by IDlse Spell (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & TransferPTitleDuringSpell !=.
gen TransferPTitleDuringSpellC = z 
drop z 
label var  TransferPTitleDuringSpellC "CUMSUM from dummy=1 in the month when employee changes job during manager spell"

* TRANSFER PTITLE LATERAL
gen  TransferPTitleLateralDuringSpell = TransferPTitleLateral
replace  TransferPTitleLateralDuringSpell = 0 if YearMonth == SpellStart  | YearMonth == SpellEnd
label var TransferPTitleLateralDuringSpell "=1 if employee changes job (lateral only) during manager spell"

gen z = TransferPTitleLateralDuringSpell
by IDlse Spell (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & TransferPTitleLateralDuringSpell !=.
gen TransferPTitleLateralDuringSC = z 
drop z 
label var  TransferPTitleLateralDuringSC "CUMSUM from dummy=1 in the month when employee changes job (lateral only) during manager spell"

* SUBFUNC 
gen  TransferSubFuncDuringSpell = TransferSubFunc
replace  TransferSubFuncDuringSpell = 0 if YearMonth == SpellStart  | YearMonth == SpellEnd
label var TransferSubFuncDuringSpell "=1 if employee changes subfunc during manager spell"

gen z = TransferSubFuncDuringSpell
by IDlse Spell (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & TransferSubFuncDuringSpell !=.
gen TransferSubFuncDuringSpellC = z 
drop z 
label var  TransferSubFuncDuringSpellC "CUMSUM from dummy=1 in the month when employee changes subfunc during manager spell"

* Timing of change in transfer  
bys IDlse TransferPTitleC: egen TransferPTitleEvent = min(YearMonth)
format  TransferPTitleEvent %tm
gen TransferPTitleEventPre1y = TransferPTitleEvent - 12
format  TransferPTitleEventPre1y %tm
gen TransferPTitleEventPost1y = TransferPTitleEvent + 12
format  TransferPTitleEventPost1y %tm

egen IDTransfer = group(IDlse TransferPTitleEvent)

compress
save "$Managersdta/Managers.dta", replace 

********************************************************************************
  * Change in performance for employees that change job 
********************************************************************************

cap drop o
gen o = 1 
collapse o , by(IDlse TransferPTitleEvent TransferPTitleEventPre1y TransferPTitleEventPost1y )

egen IDTransfer = group(IDlse TransferPTitleEvent)
drop if IDTransfer ==.
isid IDTransfer
drop o
egen Ind = cut(IDTransfer), group(20)
replace Ind = Ind+1
compress
compress
save "$temp/TransferTimeE.dta", replace // dataset at transfer level 

forval sample = 1/20{

use "$temp/TransferTimeE.dta", clear    
keep if Ind == `sample'
joinby IDlse using  "$Managersdta/Managers.dta" 

* Generate transfer level variables for employee 

* these are the EQ variables
local prepost LogPayBonus Pay Bonus PR PRI PRSnapshot VPA TimetoProm TimetoChangeSG PromSalaryGradeC ChangeSalaryGradeC

foreach var in  `prepost' {
	
bys IDTransfer: egen `var'StartT  = max(cond(YearMonth == TransferPTitleEvent, `var', .))
label var  `var'StartT  "`var' at the start of job transfer" 

	forval i= 1(1)1{
bys IDTransfer: egen `var'PostT`i'y  = max(cond(YearMonth == TransferPTitleEventPost`i'y, `var', .))
label var  `var'PostT`i'y  "`var' `i' year(s) post job transfer" 
 

bys IDTransfer: egen `var'PreT`i'y  = max(cond(YearMonth == TransferPTitleEventPre`i'y, `var', .)) 
label var  `var'PreT`i'y  "`var' `i' year(s) pre job transfer" 

}
}


 local ETransfer LogPayBonusStartT PayStartT BonusStartT PRStartT PRIStartT PRSnapshotStartT VPAStartT TimetoPromStartT TimetoChangeSGStartT PromSalaryGradeCStartT ChangeSalaryGradeCStartT   LogPayBonusPostT1y PayPostT1y BonusPostT1y PRPostT1y PRIPostT1y PRSnapshotPostT1y VPAPostT1y TimetoPromPostT1y TimetoChangeSGPostT1y PromSalaryGradeCPostT1y ChangeSalaryGradeCPostT1y LogPayBonusPreT1y PayPreT1y BonusPreT1y PRPreT1y PRIPreT1y PRSnapshotPreT1y VPAPreT1y TimetoPromPreT1y TimetoChangeSGPreT1y PromSalaryGradeCPreT1y ChangeSalaryGradeCPreT1y

compress
collapse `ETransfer', by(IDTransfer) fast
* Compressing and saving ETransferChar
compress
save "$Managersdta/Temp/ETransferChar`sample'.dta", replace

} 

use "$Managersdta/Temp/ETransferChar1.dta", clear 
forval i=2(1)20{
append using "$Managersdta/Temp/ETransferChar`i'.dta"
}
compress
save "$Managersdta/Temp/ETransferChar.dta", replace



********************************************************************************
* Merging Managers with ETransferChar 
********************************************************************************

* Adding ETransferChar variables by merging the file with Managers.dta

use "$Managersdta/Managers.dta", clear 

merge m:1 IDTransfer using "$Managersdta/Temp/ETransferChar.dta"
keep if _merge !=2
drop _merge 

isid IDlse YearMonth
compress
save "$Managersdta/Managers.dta", replace

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
* Save final dataset
********************************************************************************


* drop unnecessary vars 
drop PLeave  OUCode  OUSubGroupCode HRSupvsMgrID  SnapshotDate FlagDupM  DupMDuration  
drop WUID  - HRSupvsNM 


*keep if ( (EmpType >=3 & EmpType <=7) | EmpType==9 | EmpType== 12 | EmpType== 13) // only keep regular and IAs IDlse
compress
save "$Managersdta/Managers.dta", replace 

