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
merge m:1 IDlse using "$Managersdta/Temp/MFE.dta"
 

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYear

xtset IDlse YearMonth

********************************************************************************
* regressions
********************************************************************************

* Transfer
reghdfe  TransferPTitleDuringSpellC MFEPayWCZ  if BC ==0, a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleDuringSpellC MFEPayBCZ  if BC ==1, a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

* Het by non performing 
reghdfe  TransferPTitleDuringSpellC MFEPayWCZ LogBonusPreS1yE c.MFEPayWCZ##c.LogBonusPreS1yE if BC==0, a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleDuringSpellC MFEPayBCZ LogBonusPreS1yE c.MFEPayBCZ##c.LogBonusPreS1yE if BC==1, a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

* CHANGE IN PTITLE

gen TransferPTitleCPostS1yD = TransferPTitleCPostS1y - TransferPTitleCStartS

reghdfe  TransferPTitleCPostS1yD MFEPayWCZ  if BC ==0, a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleCPostS1yD MFEPayBCZ  if BC ==1, a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

* Het by non performing 
reghdfe  TransferPTitleLateralCPostS1yD MFEPayWCZ LogBonusPreS1y c.MFEPayWCZ##c.LogBonusPreS1yE if BC==0 , a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleLateralCPostS1yD MFEPayBCZ LogBonusPreS1y c.MFEPayBCZ##c.LogBonusPreS1y if BC==1 , a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

* Exit 
reghdfe  LeaverPerm MFEPayWCZ  if BC ==0 , a(  $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  LeaverPerm MFEPayBCZ  if BC ==1 , a(  $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)


* DYNAMICS 

PromSalaryGradeC MFEPayZ L12.MFEPayZ , a(  IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

* VALIDATION

collapse MFEPayZ , by(IDlseMHR)
rename IDlseMHR IDlse 
rename MFEPayZ ManagerQ
save "$Managersdta/Temp/MFE.dta", replace 
 use "$Managersdta/Managers.dta", clear 
merge m:1 IDlse using "$Managersdta/Temp/MFE.dta"

reghdfe  LogPayBonus ManagerQZ  if BC ==0 , a(    $controlE $controlMacro  ) vce(cluster IDlse)

reghdfe  PromSalaryGradeC ManagerQZ  if BC ==0 , a(    $controlE $controlMacro  ) vce(cluster IDlse)

reghdfe  LineManager ManagerQZ  if BC ==0 , a(    $controlE $controlMacro  ) vce(cluster IDlse)

reghdfe  LeaverPerm ManagerQZ  if BC ==0 , a(    $controlE $controlMacro  ) vce(cluster IDlse)

* Transfer FE
reghdfe TransferPTitleDuringSpellC  , a( MFETransfer = IDlseMHR     EFETransfer= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

* CORRELATION BTW FE 
tddens  MFEPay MFETransfer 
corr MFEPay MFETransfer



reghdfe TransferPTitleLateralPostS1yD , a( MFETransferD = IDlseMHR     EFETransferD= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)




* once chars are created need to reg change in performance against 



gen LogPayBonusPostSyED = LogPayBonus

* Do you transfer more with good manager? 
reghdfe TransferPTitleDuringSpellC   LogBonusM  , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR)


* Do you transfer more post spell with good manager? 
reghdfe TransferPTitleCPostS1y   LogBonusM  , a( $controlE $controlM $controlMacro IDlse  ) vce(cluster IDlseMHR)



global controlE WL BC Female AgeBand TenureBand Func
global controlM WLM FemaleM AgeBandM TenureBandM FuncM
global controlMacro CountryYear

bys IDlse Spell: egen TransferPTitleDuringSpellCMax = max(TransferPTitleDuringSpellC)


foreach var in $controlE $controlM $controlMacro {
	bys IDlse Spell: egen `var'Mode = mode(`var'), maxmode
	replace `var' = `var'Mode
}

gsort IDlse YearMonth
collapse PRIPreS2y PRIPreS1y  PromSalaryGradeCPreS2y PromSalaryGradeCPreS1y PRIPostS2y PRIPostS1y  PromSalaryGradeCPostS2y PromSalaryGradeCPostS1y     PRI PromSalaryGradeC  TimetoProm LogBonus TimetoChangeSalaryGrade BonusPostS1yE BonusPostS2yE PRIPostS1yE PRIPostS2yE PromSalaryGradeCPostS1yE   PromSalaryGradeCPostS2yE  Tenure MonthsSG MonthsPTitle  (firstnm) $controlE $controlM $controlMacro (max) LeaverPerm LeaverPermPostS1yE LeaverPermPostS2yE TransferPTitleDuringSpellC TransferPTitleDuringSpellCMax, by(IDlse Spell IDlseMHR)

save "$temp/SpellReg.dta", replace

* to swap:   PromSalaryGradeC with TimetoPromPostS2y TimetoPromPostS1y 
* quick fixes
collapse Tenure MonthsSG MonthsPTitle, by(IDlse Spell IDlseMHR)
merge 1:1 IDlse Spell IDlseMHR using "$temp/SpellReg.dta"
gen TimetoPromOld = TimetoProm
replace TimetoProm = Tenure*12 if TimetoProm==999 // tenure in months 
gen LogBonusPostS1yE  = log(BonusPostS1yE + 1  )

save "$temp/SpellReg.dta", replace

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
use "$temp/SpellReg.dta", clear 

keep if BC ==0 
*PromSalaryGradeCPreS2yE PromSalaryGradeCPreS1yE
foreach MQ in  PRIPreS1y PRIPostS1y    {
 eststo clear 
foreach var in PromSalaryGradeC  TimetoProm LogBonus   { // with and without employee FE
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
esttab using "$Results/3.2.ManagerReg/During`MQ'WC.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PR" "Promotion" "Time to Promotion" "Bonus (logs)" "Exit" , pattern(1 0 1 0 1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}

*BC 


*global EDuring PromSalaryGradeC  PromSalaryGrade  TimetoProm  VPA  PRI  Bonus LeaverInv LeaverVol LeaverPerm
use "$temp/SpellReg.dta", clear 

keep if BC ==1
*PromSalaryGradeCPreS2yE PromSalaryGradeCPreS1yE
foreach MQ in  PRIPreS1y PRIPostS1y    {
 eststo clear 
foreach var in  LogBonus   { // with and without employee FE
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
esttab using "$Results/3.2.ManagerReg/During`MQ'BC.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups( "Bonus (logs)" "Exit" , pattern(1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}


* Do we more transfer? 
********************************************************************************

use "$temp/SpellReg.dta", clear 
keep if BC==0
eststo clear 
foreach MQ in  PRIPreS1y  PRIPostS1y   {

eststo: reghdfe TransferPTitleDuringSpellC  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe  TransferPTitleDuringSpellC   `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace

}
esttab using "$Results/3.2.ManagerReg/DuringTrWC.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))  nomtitles mgroups("Job change during spell", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


use "$temp/SpellReg.dta", clear 
keep if BC==1
eststo clear 
foreach MQ in  PRIPreS1y  PRIPostS1y   {

eststo: reghdfe TransferPTitleDuringSpellC  `MQ'  , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe  TransferPTitleDuringSpellC   `MQ'   , a( $controlE $controlM $controlMacro IDlse ) vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace

}
esttab using "$Results/3.2.ManagerReg/DuringTrBC.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs."))  nomtitles mgroups("Job change during spell", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* Split sample with and without transfer 
********************************************************************************

use "$temp/SpellReg.dta", clear
keep if BC ==0  
foreach MQ in PRIPreS1y   PRIPostS1y  {
 eststo clear 
foreach var in PromSalaryGradeC  TimetoProm LogBonus LeaverPerm  { // with and without employee FE

eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local JobTransfer "No" , replace

eststo: reghdfe `var'  `MQ'  if  TransferPTitleDuringSpellC>0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local JobTransfer "Yes" , replace



}

esttab using "$Results/3.2.ManagerReg/During`MQ'byTrWC.tex", stats(JobTransfer r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Job Change" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups( "Promotion" "Time to Promotion" "Bonus (logs)" "Exit", pattern( 1 0 1  0 1 0  1  0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

}

* AFTER SPELL
********************************************************************************
use "$temp/SpellReg.dta", clear 
keep if BC==0
*PromSalaryGradeCPreS2yE PromSalaryGradeCPreS1yE
foreach MQ in  PRIPreS1y PRIPostS1y    {
 eststo clear 
foreach var in PRIPostS1yE PromSalaryGradeCPostS1yE  LogBonusPostS1yE   { // with and without employee FE
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
esttab using "$Results/3.2.ManagerReg/Post1yE`MQ'WC.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PR" "Promotion"  "Bonus (logs)" "Exit" , pattern( 1 0 1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}


* BY TRANSFER 

foreach MQ in  PRIPreS1y PRIPostS1y  {
 eststo clear 
foreach var in PRIPostS1yE PromSalaryGradeCPostS1yE   LogBonusPostS1yE LeaverPermPostS1yE  { // with and without employee FE

eststo: reghdfe `var'  `MQ'  if  TransferPTitleDuringSpellC==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local JobTransfer "No" , replace

eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC>0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local JobTransfer "Yes" , replace


}

esttab using "$Results/3.2.ManagerReg/Post1yE`MQ'byTrWC.tex", stats(JobTransfer r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Job Change" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PRI" "Promotion"  "Bonus (logs)" "Exit", pattern( 1  0 1  0 1  0 1  0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

}

*BC

use "$temp/SpellReg.dta", clear 
keep if BC==1
*PromSalaryGradeCPreS2yE PromSalaryGradeCPreS1yE
foreach MQ in  PRIPreS1y PRIPostS1y    {
 eststo clear 
foreach var in  LogBonusPostS1yE   { // with and without employee FE
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
esttab using "$Results/3.2.ManagerReg/Post1yE`MQ'BC.tex",  stats(EmployeeFE r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Employee FE" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PR" "Promotion"  "Bonus (logs)" "Exit" , pattern( 1 0 1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
}


* BY TRANSFER 

foreach MQ in  PRIPreS1y PRIPostS1y  {
 eststo clear 
foreach var in    LogBonusPostS1yE LeaverPermPostS1yE  { // with and without employee FE

eststo: reghdfe `var'  `MQ'  if  TransferPTitleDuringSpellC==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local JobTransfer "No" , replace

eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC>0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local JobTransfer "Yes" , replace


}

esttab using "$Results/3.2.ManagerReg/Post1yE`MQ'byTrBC.tex", stats(JobTransfer r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Job Change" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PRI" "Promotion"  "Bonus (logs)" "Exit", pattern( 1  0 1  0 1  0 1  0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

}


* DURING 

* BY TRANSFER 

foreach MQ in  PRIPreS1y PRIPostS1y  {
 eststo clear 
foreach var in    LogBonus LeaverPerm  { // with and without employee FE

eststo: reghdfe `var'  `MQ'  if  TransferPTitleDuringSpellC==0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local JobTransfer "No" , replace

eststo: reghdfe `var'  `MQ'  if TransferPTitleDuringSpellC>0 , a( $controlE $controlM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
estadd local JobTransfer "Yes" , replace


}

esttab using "$Results/3.2.ManagerReg/During`MQ'byTrBC.tex", stats(JobTransfer r2 ymean N , fmt(%9.3f %9.3f %9.3f %9.0g) labels("Job Change" "\midrule R-squared" "Mean" "Number of obs.")) nomtitles mgroups("PRI" "Promotion"  "Bonus (logs)" "Exit", pattern( 1  0 1  0 1  0 1  0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

}

