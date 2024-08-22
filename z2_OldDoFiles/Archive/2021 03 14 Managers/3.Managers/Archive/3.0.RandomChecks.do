********************************************************************************
*
* THIS DOFILE TESTS FOR RANDOM ASSIGNMENT MANAGERS- EMPLOYEES 
*
********************************************************************************

********************************************************************************
* RMSE CHECK
********************************************************************************

use "$Full/Results/3.1.ManagerFE/AllFEM.dta", clear 
merge 1:m IDlseMHR using "$dta/AllSnapshotWCCultureC.dta"

* CARD ET AL 2013 
* worker FE and manager FE (without interactions)
*reghdfe PromSalaryGradeC c.Tenure##c.Tenure##Female, absorb(IDlseMHR IDlse Func CountryYear AgeBand ) cluster(IDlseMHR) 
* y = PromSalaryGrade; RMSE  ==0.0855
* y = PromSalaryGradeC; RMSE  == 0.2763


* separate dummy variable for each worker-manager match
*reghdfe PromSalaryGradeC c.Tenure##c.Tenure##Female, absorb(IDlseMHR#IDlse Func CountryYear AgeBand ) cluster(IDlseMHR) 
* y = PromSalaryGrade; Improvement >>> (0.0855 − 0.0842)/0.0855 = .01520468
* y = PromSalaryGradeC; Improvement >>> (0.2763 − 0.1628)/0.2763 = 0.41

/*
For comparison, they found an improvement of (0.119 − 0.103)/0.119 = 0.134 after controlling for worker-establishment match quality, which they interpret as a small improvement in fit that “limits the scope for potential endogeneity.
*/

********************************************************************************
* REGRESS CURRENT EMPLOYEE PERFORMANCE with FUTURE TEAM CHARS
********************************************************************************

* Macro-trends 

egen OfficeYear = group(Office Year)

by IDlse (YearMonth), sort: gen changeM = (IDlseMHR != IDlseMHR[_n-1] & _n>1 )
by IDlse (YearMonth), sort: gen IDtime = sum(changeM)

bys IDlseMHR YearMonth: egen TeamProm = total(PromSalaryGrade)
bys IDlseMHR YearMonth: egen TeamSizeC = count(IDlse)
replace TeamProm = TeamProm /(TeamSizeC)

bys IDlseMHR YearMonth: egen TeamLogPayBonus = total(LogPayBonus)
replace TeamLogPayBonus = TeamLogPayBonus/TeamSizeC

foreach var in Func OfficeYear AgeBand AgeBandM Female FemaleM{
bys IDlse IDtime: egen M`var'= mode(`var'), minmode
}

collapse TransferSubFuncC TransferPTitleC MonthsPTitle PromSalaryGradeC  PRSnapshot PRI  LogBonus  LogPay VPAM VPAMeanM PayM PayMeanM  BonusM BonusMeanM PRM PRIM PRMeanM TransferCountryM TransferCountryCM PromWLCM PromSalaryGradeCM DemotionSalaryGradeCM TransferPTitleM TransferPTitleCM TransferSubFuncM TransferSubFuncCM TransferFuncCM TransferSubFuncLateralM TransferSubFuncLateralCM TransferFuncLateralM TransferFuncLateralCM TransferPTitleLateralM TransferPTitleLateralCM PromSalaryGradeVerticalM PromSalaryGradeVerticalCM PromSalaryGradeLateralM PromSalaryGradeLateralCM MonthsPTitleM MonthsSubFuncM MonthsPromSalaryGradeM   Tenure TenureM WLM TenureWLM TeamProm TeamLogPayBonus MFunc MOfficeYear MAgeBand MAgeBandM MFemale MFemaleM , by(IDlse IDlseMHR IDtime) // collapse dataset at the spell level 
* MFEProm MFEPay MFEVPA MFEPR
tsset IDlse IDtime
egen TeamPromZ = std(TeamProm)
egen TeamLogPayBonusZ = std(TeamLogPayBonus)
label var PRSnapshot "Perf. Score"
label var PRI "Perf. Score"
*label var MFEProm "Manager VA"
label var LogBonus "Bonus (logs)"
label var LogPay "Pay (logs)"
label var  TeamPromZ "Team Mean Promotion (std)"
label var  TransferPTitleC "Transfer PTitle"
label var  TransferSubFuncC "Transfer SubFunc"
label var  PromSalaryGradeC "Promotion"
label var  TransferPTitleCM "Transfer PTitle M"
label var  TransferSubFuncCM "Transfer SubFunc M"
label var  PromSalaryGradeCM "Promotion M"
label var  MonthsPromSalaryGradeM "Months since Prom M"
label var TeamLogPayBonusZ "Team Mean Pay+Bonus (logs, std)"
label var BonusM "Bonus M"
label var PRM "Perf. Score M"
label var PRIM "Perf. Score M"
label var LogBonusM "Bonus M (logs)"


global FE  MAgeBand  MFunc  MOfficeYear   MAgeBandM MFemaleM

global FEInd  IDlse MAgeBand  MFunc  MOfficeYear   MAgeBandM MFemaleM

*IDlseMHR IDlse

save "$temp/Spell.dta", replace 
********************************************************************************
* TEAM table
********************************************************************************

use "$temp/Spell.dta", clear 

eststo clear
eststo: reghdfe  PRI F.TeamPromZ c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.TeamPromZ c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.TeamPromZ c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  PRI F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/Team1.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.TeamPromZ F.TeamLogPayBonusZ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


eststo clear
eststo: reghdfe  TransferPTitleC F.TeamPromZ c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.TeamPromZ c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.TeamPromZ c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferPTitleC F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/Team2.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.TeamPromZ F.TeamLogPayBonusZ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

********************************************************************************
* MANAGER table
********************************************************************************

use "$temp/Spell.dta", clear 

eststo clear
eststo: reghdfe  PRI F.PRIM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.PRIM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.PRIM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  PRI F.LogBonusM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.LogBonusM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.LogBonusM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/Manager1.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.PRIM F.LogBonusM) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

eststo clear
eststo: reghdfe  TransferPTitleC F.PRIM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.PRIM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.PRIM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferPTitleC F.LogBonusM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.LogBonusM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.LogBonusM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/Manager2.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.PRIM F.LogBonusM) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

********************************************************************************
* MANAGER transfers table
********************************************************************************

eststo clear
eststo: reghdfe  PRI F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  PRI F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale, absorb( $FE ) cluster(IDlseMHR) 
estadd ysumm


esttab using "$Full/Results/3.0.RandomChecks/ManagerTransfers1.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.TransferSubFuncCM  F.MonthsPromSalaryGradeM) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01) replace


eststo clear
eststo: reghdfe  TransferPTitleC F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferPTitleC F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale , absorb( $FE  ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/ManagerTransfers2.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.TransferSubFuncCM  F.MonthsPromSalaryGradeM) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)  replace




* WITH EMPLOYEE FE

********************************************************************************
* TEAM table
********************************************************************************

use "$temp/Spell.dta", clear 
global FEInd  IDlse MAgeBand  MFunc  MOfficeYear   MAgeBandM MFemaleM

eststo clear
eststo: reghdfe  PRI F.TeamPromZ c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.TeamPromZ c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.TeamPromZ c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  PRI F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/TeamInd1.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.TeamPromZ F.TeamLogPayBonusZ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


eststo clear
eststo: reghdfe  TransferPTitleC F.TeamPromZ c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.TeamPromZ c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.TeamPromZ c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferPTitleC F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.TeamLogPayBonusZ c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/TeamInd2.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.TeamPromZ F.TeamLogPayBonusZ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

********************************************************************************
* MANAGER table
********************************************************************************

use "$temp/Spell.dta", clear 

eststo clear
eststo: reghdfe  PRI F.PRIM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.PRIM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.PRIM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  PRI F.LogBonusM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.LogBonusM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.LogBonusM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/ManagerInd1.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.PRIM F.LogBonusM) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

eststo clear
eststo: reghdfe  TransferPTitleC F.PRIM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.PRIM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.PRIM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferPTitleC F.LogBonusM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.LogBonusM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.LogBonusM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/ManagerInd2.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.PRIM F.LogBonusM) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

********************************************************************************
* MANAGER transfers table
********************************************************************************

eststo clear
eststo: reghdfe  PRI F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  PRI F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogBonus F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe LogPay  F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale, absorb( $FEInd ) cluster(IDlseMHR) 
estadd ysumm


esttab using "$Full/Results/3.0.RandomChecks/ManagerTransfersInd1.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.TransferSubFuncCM  F.MonthsPromSalaryGradeM) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01) replace


eststo clear
eststo: reghdfe  TransferPTitleC F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.TransferSubFuncCM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferPTitleC F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe  TransferSubFuncC F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm
eststo: reghdfe   PromSalaryGradeC F.MonthsPromSalaryGradeM c.Tenure##c.Tenure##MFemale , absorb( $FEInd  ) cluster(IDlseMHR) 
estadd ysumm

esttab using "$Full/Results/3.0.RandomChecks/ManagerTransfersInd2.tex",   stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  keep(F.TransferSubFuncCM  F.MonthsPromSalaryGradeM) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)  replace


