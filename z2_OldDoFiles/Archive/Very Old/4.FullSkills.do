
* This do files looks at whether changing a lot of subfuctions helps or hurts wages 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

********************************************************************************
* Transfers for sub function - accounting for selection 
******************************************************************************** 

use "$data/dta/AllSnapshotWCCultureC", clear 

by IDlse: egen Duration =  count(YearMonth)
by IDlse: egen LeaverTag = max(LeaverPerm)
egen OfficeYear= group(Office Year )

global controls  OfficeYear Func Cohort
gen Stayer = 1 - LeaverPerm
gen StayerTag = 1 - LeaverTag

* Residualize by controls variables 
foreach var in TransferSubFuncC LogPayBonus  Stayer StayerTag{
reghdfe  `var'    , a(  $controls ) cluster(IDlse) resid
predict `var'R, res
}

*xtheckman LogPayBonus TransferSubFuncCTag  i.OfficeYear i.Func i.Cohort, select(StayerTag = TransferSubFuncCTag  i.OfficeYear i.Func i.Cohort) // takes ages to run
heckman LogPayBonusR TransferSubFuncCR Tenure , select(StayerTag = TransferSubFuncCR Tenure ) 

reghdfe PromSalaryGradeC TransferSubFuncC Tenure, a($controls IDlse )
reghdfe PromSalaryGradeC TransferCountryC Tenure, a($controls IDlse )

