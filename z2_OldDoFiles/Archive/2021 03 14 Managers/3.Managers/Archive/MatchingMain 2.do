********************************************************************************
* This dofile looks at managers of BC & WC workers 
********************************************************************************

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"


/* Get random sample
use "$Managersdta/Managers.dta", clear 
sample 5
save "$temp/5percent.dta", replace 
*/

*use "$temp/5percent.dta", clear 
use "$Managersdta/Managers.dta", clear 

global controlE WL BC Female AgeBand TenureBand Func
global controlM WLM FemaleM AgeBandM TenureBandM FuncM
global controlMacro CountryYear

foreach var in $controlE $controlM $controlMacro {
	bys IDlse Spell: egen `var'Mode = mode(`var'), maxmode
	replace `var' = `var'Mode
}

gsort IDlse YearMonth
collapse PRIPreS2y PRIPreS1y  PromSalaryGradeCPreS2y PromSalaryGradeCPreS1y PRIPostS2y PRIPostS1y  PromSalaryGradeCPostS2y PromSalaryGradeCPostS1y  P   TransferPTitleDuringSpellC PRI PromSalaryGradeC  TimetoProm LogBonus TimetoChangeSalaryGrade BonusPost1yE BonusPost2yE PRIPost1yE PRIPost2yE PromSalaryGradeCPost1yE   PromSalaryGradeCPost2yE    TimetoPromPost1yE  TimetoPromPost2yE (firstnm) $controlE $controlM $controlMacro (max) LeaverPerm LeaverPermPost1yE LeaverPermPost2yE, by(IDlse Spell)

save "$temp/SpellReg.dta", replace

* to swap:   PromSalaryGradeC with TimetoPromPostS2y TimetoPromPostS1y 

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
* OUTCOMES DURING  SPELL 
********************************************************************************

*global EDuring PromSalaryGradeC  PromSalaryGrade  TimetoProm  VPA  PRI  Bonus LeaverInv LeaverVol LeaverPerm

*PromSalaryGradeCPreS2yE PromSalaryGradeCPreS1yE
foreach MQ in PRIPreS2y PRIPreS1y PRIPostS2y PRIPostS1y    {
 eststo clear 
foreach var in PRI PromSalaryGradeC  TimetoProm LogBonus   { // with and without employee FE
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
esttab using "$Full/Results/3.2.ManagerReg/During`MQ'.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PR" "Promotion" "Time to Promotion" "Bonus (logs)" "Exit" , pattern(1 0 1 0 1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}



* Do we more transfer? 
********************************************************************************

eststo clear 
foreach MQ in PRIPreS2y PRIPreS1y PRIPostS2y PRIPostS1y   {

eststo: reghdfe TransferPTitleDuringSpellC  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe  TransferPTitleDuringSpellC   `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace

}
esttab using "$Full/Results/3.2.ManagerReg/DuringTr.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))  nomtitles mgroups("Job change during spell", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* Split sample with and without transfer 
********************************************************************************

bys IDlse Spell: egen TransferPTitleDuringSpellCMax = max(TransferPTitleDuringSpellC)

foreach MQ in PRIPreS2y PRIPreS1y PRIPostS2y PRIPostS1y  {
 eststo clear 
foreach var in PRI PromSalaryGradeC  TimetoProm LogBonus LeaverPerm  { // with and without employee FE

eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC==0 & TransferPTitleDuringSpellCMax==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace

eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC==0 & TransferPTitleDuringSpellCMax>0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace

eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC>0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace


}

esttab using "$Full/Results/3.2.ManagerReg/During`MQ'byTr.tex", stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PRI" "Promotion" "Time to Promotion" "Bonus (logs)" "Exit", pattern(1 0 0 1 0 0 1 0 0 1 0 0 1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

}

* AFTER SPELL
********************************************************************************


*PromSalaryGradeCPreS2yE PromSalaryGradeCPreS1yE
foreach MQ in PRIPreS2y PRIPreS1y PRIPostS2y PRIPostS1y    {
 eststo clear 
foreach var in PRIPost1yE PromSalaryGradeCPost1yE  TimetoPromPost1yE LogBonusPost1yE   { // with and without employee FE
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
esttab using "$Full/Results/3.2.ManagerReg/Post1yE`MQ'.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PR" "Promotion" "Time to Promotion" "Bonus (logs)" "Exit" , pattern(1 0 1 0 1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}


* BY TRANSFER 

foreach MQ in PRIPreS2y PRIPreS1y PRIPostS2y PRIPostS1y  {
 eststo clear 
foreach var in PRIPost1yE PromSalaryGradeCPost1yE  TimetoPromPost1yE LogBonusPost1yE LeaverPermPost1yE  { // with and without employee FE

eststo: reghdfe `var'  `MQ'  if  TransferPTitleDuringSpellCMax==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace

eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC>0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace


}

esttab using "$Full/Results/3.2.ManagerReg/Post1yE`MQ'byTr.tex", stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PRI" "Promotion" "Time to Promotion" "Bonus (logs)" "Exit", pattern(1 0  1  0 1  0 1  0 1  0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

}



********************************************************************************




* AT SPELL LEVEL

foreach MQ in PRIPreS2y PRIPreS1y PRIPostS2y PRIPostS1y  {
 eststo clear 
foreach var in PRI PromSalaryGradeC  TimetoProm LogBonus   { // with and without employee FE
eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC==0  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe `var'  `MQ'   if TransferPTitleDuringSpellC==0, a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
}
foreach var in  LeaverPerm { // without employee FE only
eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
}
esttab using "$Full/Results/3.2.ManagerReg/During`MQ'byTr.tex",  prehead("\begin{tabular}{l*{2}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Job transfer}} \\\\[-1ex]") ///
fragment ///
 drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

 eststo clear 
foreach var in PRI PromSalaryGradeC  TimetoProm LogBonus   { // with and without employee FE
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

