********************************************************************************
* This dofile looks at managers of BC & WC workers 
********************************************************************************

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* Preliminary graphs
********************************************************************************

/* Get random sample
use "$Managersdta/Managers.dta", clear 
sample 5
save "$temp/5percent.dta", replace 
*/

use "$temp/5percent.dta", clear 


preserve 
collapse (sum) Spell, by(IDlse BC)
tw hist Spell if BC==0 ,  frac bcolor(teal%60) || hist Spell if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle(No. of manager spells per employee)
restore 

********************************************************************************
* Variable preparation 
********************************************************************************

rename PromSpeed* TimetoProm* 

* Replace speed of prom vars as they are 0 when there is no promotion
foreach var in TimetoProm ChangeSalaryGradeSpeed TimetoPromM ChangeSalaryGradeSpeedM{
replace  `var' = 999 if `var' ==0 
}

* Tenure FE 
egen TenureBand = cut(Tenure), group(10)
egen TenureBandM = cut(TenureM), group(10) 

* I do not have PromSalaryGradePostS1y> create it by looking at the difference in cum promotion across time periods
gen PromSalaryGradePostS1m = PromSalaryGradeCPostS1m - PromSalaryGradeCM 
gen PromSalaryGradePostS6m = PromSalaryGradeCPostS6m - PromSalaryGradeCPostS1m
gen PromSalaryGradePostS1y = PromSalaryGradeCPostS1y - PromSalaryGradeCPostS6m
gen PromSalaryGradePostS2y = PromSalaryGradeCPostS2y - PromSalaryGradeCPostS1y
gen PromSalaryGradePostS3y = PromSalaryGradeCPostS3y - PromSalaryGradeCPostS2y
* Employee 
gen PromSalaryGradePostS1mE = PromSalaryGradeCPostS1mE - PromSalaryGradeC
gen PromSalaryGradePostS6mE = PromSalaryGradeCPostS6mE - PromSalaryGradeCPostS1mE
gen PromSalaryGradePostS1yE = PromSalaryGradeCPostS1yE - PromSalaryGradeCPostS6mE
gen PromSalaryGradePostS2yE = PromSalaryGradeCPostS2yE - PromSalaryGradeCPostS1yE
gen PromSalaryGradePostS3yE = PromSalaryGradeCPostS3yE - PromSalaryGradeCPostS2yE

gen TransferSubFuncPostS1mE = TransferSubFuncCPostS1mE - TransferSubFuncC
gen TransferSubFuncPostS6mE = TransferSubFuncCPostS6mE - TransferSubFuncCPostS1mE 
gen TransferSubFuncPostS1yE = TransferSubFuncCPostS1yE - TransferSubFuncCPostS6mE
gen TransferSubFuncPostS2yE = TransferSubFuncCPostS2yE - TransferSubFuncCPostS1yE
gen TransferSubFuncPostS3yE = TransferSubFuncCPostS3yE - TransferSubFuncCPostS2yE

/* Exit variables: replace missing with 1 for employee (these variables are never missing for employee)
*the variable should only be missing if employee exits in the timeframe of the previous spell period variable 

foreach s in yE y{ // managers and employees 
replace LeaverInvPostS1`s' = 1 if  LeaverInvPostS1`s' ==. 
replace LeaverVolPostS1`s' = 1 if  LeaverVolPostS1`s' ==. 
replace LeaverPermPostS1`s' = 1 if  LeaverPermPostS1`s' ==. 

} 

forval i= 2(1)6  {
foreach s in yE y { // managers and employees 
	local d = `i' - 1
	di `d'
	replace LeaverInvPostS`i'`s' = 1 if  (LeaverInvPostS`i'`s' ==. & `d'==0) | ( LeaverInvPostS`i'`s' ==. & LeaverInvPostS`d'`s'!=1 & `d'>0) 
	replace	LeaverVolPostS`i'`s'= 1 if  (LeaverVolPostS`i'`s' ==. & `d'==0) | ( LeaverVolPostS`i'`s' ==. & LeaverVolPostS`d'`s'!=1 & `d'>0) 
	replace	LeaverPermPostS`i'`s'= 1 if  (LeaverPermPostS`i'`s' ==. & `d'==0) | ( LeaverPermPostS`i'`s' ==. & LeaverPermPostS`d'`s'!=1 & `d'>0) 
}
}
*/
* Transfer variable at the spell level 
bys IDlse Spell: egen TransferSubFuncSpell = max(TransferSubFunc)
bys IDlse Spell: egen TransferPTitleSpell  = max(TransferPTitle)
bys IDlse Spell: egen PromSalaryGradeSpell = max(PromSalaryGrade) 

********************************************************************************
* Variables 
********************************************************************************

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYear  
* MQ: 1m and 1y before and after spell 
global MQPre TimetoPromPreS1y TimetoPromPreS1m VPAPreS1y VPAPreS1m PRIPreS1y PRIPreS1m BonusPreS1y BonusPreS1m 
global MQPost PromSalaryGradeCPostS1y PromSalaryGradeCPostS1m PromSalaryGradePostS1m PromSalaryGradePostS1y TimetoPromPostS1y TimetoPromPostS1m VPAPostS1y VPAPostS1m PRIPostS1y PRIPostS1m BonusPostS1y BonusPostS1m 

global EPre TimetoPromPreS1yE TimetoPromPreS1mE VPAPreS1yE VPAPreS1mE PRIPreS1yE PRIPreS1mE BonusPreS1yE BonusPreS1mE 
global EDuring PromSalaryGradeC  PromSalaryGrade  TimetoProm  VPA  PRI  Bonus LeaverInv LeaverVol LeaverPerm 
global EPost PromSalaryGradeCPostS1yE PromSalaryGradeCPostS1mE PromSalaryGradePostS1mE PromSalaryGradePostS1yE TimetoPromPostS1yE TimetoPromPostS1mE VPAPostS1yE VPAPostS1mE PRIPostS1yE PRIPostS1mE BonusPostS1yE BonusPostS1mE LeaverInvPostS1yE LeaverVolPostS1yE LeaverPermPostS1yE LeaverInvPostS1mE LeaverVolPostS1mE LeaverPermPostS1mE

********************************************************************************
* BALANCE TABLES
********************************************************************************

* Balance checks - MQ = PRI 
* !TEMP!, just to run the code 
replace PRIPreS1yE = PRI
replace PRIPreS1mE = PRI
replace TimetoPromPreS1mE = TimetoProm
replace TimetoPromPreS1yE = TimetoProm

* 4 PANELS TABLE: 1 per MQ variable 

 eststo clear 
foreach var in PRIPreS1yE PRIPreS1mE TimetoPromPreS1mE TimetoPromPreS1yE  { // with and without employee FE
 
eststo: reghdfe `var'   PRIPreS1y  , a( $controlE $controlM $controlMacro ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  PRIPreS1y   , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
esttab using "$Full/Results/3.0.RandomChecks/BCPRIManager.tex",   prehead("\begin{tabular}{l*{8}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel A: Pre Spell 1 year}} \\\\[-1ex]") ///
fragment drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

 eststo clear 
foreach var in PRIPreS1yE PRIPreS1mE TimetoPromPreS1mE TimetoPromPreS1yE  { // with and without employee FE
 
eststo: reghdfe `var'   PRIPreS1m  , a( $controlE $controlM $controlMacro ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  PRIPreS1m   , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
esttab using "$Full/Results/3.0.RandomChecks/BCPRIManager.tex",  posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel B: Pre Spell 1 month}} \\\\[-1ex]") fragment  ///
nomtitles nonumbers nolines prefoot("\hline")   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   append

 eststo clear 
foreach var in PRIPreS1yE PRIPreS1mE TimetoPromPreS1mE TimetoPromPreS1yE  { // with and without employee FE
 
eststo: reghdfe `var'   PRIPostS1m , a( $controlE $controlM $controlMacro ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  PRIPostS1m   , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
esttab using "$Full/Results/3.0.RandomChecks/BCPRIManager.tex", posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel C: Post Spell 1 month}} \\\\[-1ex]") fragment  ///
nomtitles nonumbers nolines prefoot("\hline")   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   append

 eststo clear 
foreach var in PRIPreS1yE PRIPreS1mE TimetoPromPreS1mE TimetoPromPreS1yE  { // with and without employee FE
 
eststo: reghdfe `var'   PRIPostS1y , a( $controlE $controlM $controlMacro ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  PRIPostS1y   , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
esttab using "$Full/Results/3.0.RandomChecks/BCPRIManager.tex",  posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel D: Post Spell 1 year}} \\\\[-1ex]") fragment nomtitles nonumbers nolines prefoot("\hline") postfoot("\hline\hline \end{tabular}") drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   append


* Balance checks - MQ = TimetoProm 

 eststo clear 
foreach var in PRIPreS1yE PRIPreS1mE TimetoPromPreS1mE TimetoPromPreS1yE  { // with and without employee FE
 
eststo: reghdfe `var'  TimetoPromPreS1y  , a( $controlE $controlM $controlMacro ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  TimetoPromPreS1y   , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
esttab using "$Full/Results/3.0.RandomChecks/BCTimetoPromManager.tex",   prehead("\begin{tabular}{l*{8}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel A: Pre Spell 1 year}} \\\\[-1ex]") ///
fragment drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

 eststo clear 
foreach var in PRIPreS1yE PRIPreS1mE TimetoPromPreS1mE TimetoPromPreS1yE  { // with and without employee FE
 
eststo: reghdfe `var'   TimetoPromPreS1m  , a( $controlE $controlM $controlMacro ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  TimetoPromPreS1m  , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
esttab using "$Full/Results/3.0.RandomChecks/BCTimetoPromManager.tex",  posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel B: Pre Spell 1 month}} \\\\[-1ex]") fragment  ///
nomtitles nonumbers nolines prefoot("\hline")   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   append

 eststo clear 
foreach var in PRIPreS1yE PRIPreS1mE TimetoPromPreS1mE TimetoPromPreS1yE  { // with and without employee FE
 
eststo: reghdfe `var'  TimetoPromPostS1y , a( $controlE $controlM $controlMacro ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  TimetoPromPostS1y , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
esttab using "$Full/Results/3.0.RandomChecks/BCTimetoPromManager.tex", posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel C: Post Spell 1 month}} \\\\[-1ex]") fragment  ///
nomtitles nonumbers nolines prefoot("\hline")   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   append

 eststo clear 
foreach var in PRIPreS1yE PRIPreS1mE TimetoPromPreS1mE TimetoPromPreS1yE  { // with and without employee FE
 
eststo: reghdfe `var'   TimetoPromPostS1m , a( $controlE $controlM $controlMacro ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  TimetoPromPostS1m  , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR )
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
esttab using "$Full/Results/3.0.RandomChecks/BCTimetoPromManager.tex",  posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel D: Post Spell 1 year}} \\\\[-1ex]") fragment nomtitles nonumbers nolines prefoot("\hline") postfoot("\hline\hline \end{tabular}") drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   append


********************************************************************************
* OUTCOMES DURING  SPELL 
********************************************************************************

*global EDuring PromSalaryGradeC  PromSalaryGrade  TimetoProm  VPA  PRI  Bonus LeaverInv LeaverVol LeaverPerm


foreach MQ in PRIPreS1y PRIPreS1m PRIPostS1m  PRIPostS1y  PRIPostS2y  {
 eststo clear 
foreach var in PRI PromSalaryGradeC   TimetoProm  { // with and without employee FE
eststo: reghdfe `var'  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPerm { // without employee FE only
eststo: reghdfe `var'  `MQ'   , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
esttab using "$Full/Results/3.2.ManagerReg/During`MQ'.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}


* Do we more transfer? 
foreach MQ in PRIPreS1y PRIPreS1m PRIPostS1m  PRIPostS1y  PRIPostS2y  {
 eststo clear 
eststo: reghdfe TransferSubFuncSpell  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe  TransferSubFuncSpell   `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace

esttab using "$Full/Results/3.2.ManagerReg/During`MQ'Tr.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

}

* Split sample with and without transfer 

foreach MQ in PRIPreS1y PRIPreS1m PRIPostS1m  PRIPostS1y  PRIPostS2y  {
 eststo clear 
foreach var in PRI PromSalaryGradeC   TimetoProm  { // with and without employee FE
eststo: reghdfe `var'  `MQ'  if TransferSubFuncSpell==1, a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   if TransferSubFuncSpell==1, a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPerm { // without employee FE only
eststo: reghdfe `var'  `MQ'  if TransferSubFuncSpell==1 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
esttab using "$Full/Results/3.2.ManagerReg/During`MQ'byTr.tex",  prehead("\begin{tabular}{l*{2}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Job transfer}} \\\\[-1ex]") ///
fragment ///
 drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

 eststo clear 
foreach var in PRI PromSalaryGradeC   TimetoProm  { // with and without employee FE
eststo: reghdfe `var'  `MQ'  if TransferSubFuncSpell==0, a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   if TransferSubFuncSpell==0, a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPerm { // without employee FE only
eststo: reghdfe `var'  `MQ'  if TransferSubFuncSpell==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
 esttab using "$Full/Results/3.2.ManagerReg/During`MQ'byTr.tex", posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: No job transfer}} \\\\[-1ex]") fragment  ///
nomtitles nonumbers nolines prefoot("\hline") postfoot("\hline\hline \end{tabular}") /// 
stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)  append
}


********************************************************************************
* OUTCOMES 1m after  SPELL 
********************************************************************************

foreach MQ in PRIPreS1y PRIPreS1m PRIPostS1m  PRIPostS1y  PRIPostS2y  {
 eststo clear 
foreach var in PRIPostS1mE PromSalaryGradeCPostS1mE   TimetoPromPostS1mE  { // with and without employee FE
eststo: reghdfe `var'  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPermPostS1mE { // without employee FE only
eststo: reghdfe `var'  `MQ'   , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
esttab using "$Full/Results/3.2.ManagerReg/1m`MQ'.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}



********************************************************************************
* OUTCOMES 1y after  SPELL 
********************************************************************************

foreach MQ in PRIPreS1y PRIPreS1m PRIPostS1m  PRIPostS1y  PRIPostS2y  {
 eststo clear 
foreach var in PRIPostS1yE PromSalaryGradeCPostS1yE   TimetoPromPostS1yE  { // with and without employee FE
eststo: reghdfe `var'  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPermPostS1yE { // without employee FE only
eststo: reghdfe `var'  `MQ'   , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
esttab using "$Full/Results/3.2.ManagerReg/1y`MQ'.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}

* Do we more transfer? 
foreach MQ in PRIPreS1y PRIPreS1m PRIPostS1m  PRIPostS1y  PRIPostS2y  {

eststo: reghdfe TransferSubFuncPostS6mE  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe  TransferSubFuncPostS6mE   `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace

esttab using "$Full/Results/3.2.ManagerReg/1y`MQ'Tr.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

}

* Split sample with and without transfer 

foreach MQ in PRIPreS1y PRIPreS1m PRIPostS1m  PRIPostS1y  PRIPostS2y  {
 eststo clear 
foreach var in PRIPostS1yE PromSalaryGradeCPostS1yE   TimetoPromPostS1yE  { // with and without employee FE
eststo: reghdfe `var'  `MQ'  if TransferSubFuncPostS6mE==1, a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   if TransferSubFuncPostS6mE==1, a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPermPostS1yE { // without employee FE only
eststo: reghdfe `var'  `MQ'  if TransferSubFuncPostS6mE==1 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
esttab using "$Full/Results/3.2.ManagerReg/1y`MQ'byTr.tex",  prehead("\begin{tabular}{l*{2}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Job transfer}} \\\\[-1ex]") ///
fragment ///
 stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

 eststo clear 
foreach var in PRIPostS1yE PromSalaryGradeCPostS1yE   TimetoPromPostS1yE  { // with and without employee FE
eststo: reghdfe `var'  `MQ'  if TransferSubFuncPostS6mE==0, a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   if TransferSubFuncPostS6mE==0, a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPermPostS1yE { // without employee FE only
eststo: reghdfe `var'  `MQ'  if TransferSubFuncPostS6mE==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
 esttab using "$Full/Results/3.2.ManagerReg/1y`MQ'byTr.tex", posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: No job transfer}} \\\\[-1ex]") fragment  ///
nomtitles nonumbers nolines prefoot("\hline") postfoot("\hline\hline \end{tabular}") /// 
stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)  append
}


********************************************************************************
* OUTCOMES 2y after  SPELL 
********************************************************************************

foreach MQ in PRIPreS1y PRIPreS1m PRIPostS1m  PRIPostS1y  PRIPostS2y  {
 eststo clear 
foreach var in PRIPostS2yE PromSalaryGradeCPostS2yE   TimetoPromPostS2yE  { // with and without employee FE
eststo: reghdfe `var'  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPermPostS2yE { // without employee FE only
eststo: reghdfe `var'  `MQ'   , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
esttab using "$Full/Results/3.2.ManagerReg/2y`MQ'.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}
