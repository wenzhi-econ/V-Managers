
********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

use "$Managersdta/AllSnapshotMCultureMType.dta", clear 

* salary grade cleaning 
cap drop t
decode  SalaryGrade, gen(t)
gen SG = substr(t, 2, .)

********************************************************************************
* Balance Table
********************************************************************************
* TO DO wip is to add first month of manager 
global CHARS LogPayBonus LeaverVol TransferInternalSJC  ChangeSalaryGradeC PromWLC

balancetable EarlyAgeM  $CHARS using "$analysis/Results/4.MType/BalanceTeamEarlyAgeM.tex", ///
replace  pval vce(cluster IDlseMHR) cov(i.CountryMYear i.FuncM i.WLM i.FemaleM ) varlabels ctitles("Control" "Treatment" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." ///
"The difference in means is computed using robust standard errors." "Controlling for country X year, function, WL, and gender FE." "\end{tablenotes}")

balancetable EarlyTenureM  $CHARS using "$analysis/Results/4.MType/BalanceTeamEarlyTenureM.tex", ///
replace  pval vce(cluster IDlseMHR) cov(i.CountryMYear i.FuncM i.WLM i.FemaleM ) varlabels ctitles("Control" "Treatment" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)."  "Controlling for country X year, function, WL, and gender FE." ///
"The difference in means is computed using robust standard errors." "\end{tablenotes}")

********************************************************************************
*  reduced form regression  
********************************************************************************

ge SameSample =1 if LineManagerMeanB!=. & DirectorM !=. & VPAHighM!=. & PayBonusGrowthMB!=. &  ChangeSalaryGradeRMMeanB!=.  &   LeaverVolRMMeanB!=. & SGSpeedMB!=.

label var EarlyAgeM "Fast track M."
label var TeamSize "Team Size"
label var TransferInternalSJC  "Job transfer"
label var ChangeSalaryGradeC  "SG Change"
label var PromWLC  "Prom. WL"
label var LogPayBonus "Pay + bonus (logs)"
label var WLM "Work Level"
label var DirectorM "LM Director +"
label var VPAHighM "VPA M >=125"
label var LineManagerMean "Effective LM"
label var LineManagerMeanB "Effective LM"
label var PayBonusGrowthM "Salary Growth M"
label var PayBonusGrowthMB "Salary Growth M"
label var SGSpeedM "Prom. Speed"
label var SGSpeedMB "Prom. Speed"
label var ChangeSalaryGradeRMMean "Team mean prom."
label var ChangeSalaryGradeRMMeanB "Team mean prom."
label var LeaverVolRMMean "Team mean vol. exit"
label var LeaverVolRMMeanB "Team mean vol. exit"
label var LeaverVol "Exit (Vol.)"
label var Leaver "Exit"
label var LeaverPerm "Exit"


*Reduced form 
foreach  x in EarlyAgeM EarlyTenureM {
	eststo  clear 
	foreach var in LogPayBonus LeaverVol TransferInternalSJC  ChangeSalaryGradeC PromWLC {
 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
eststo: reghdfe `var'  `x' c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "No" , replace
estadd scalar cmean = `cmean'
eststo: reghdfe `var'   `x' c.Tenure##c.Tenure TeamSize , a(IDlse AgeBand CountryYM AgeBandM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'

} 

esttab using "$analysis/Results/4.MType/EE`x'.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N r2, labels("Controls" "Employee FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize Tenure c.Tenure#c.Tenure ) ///
 nomtitles mgroups("`:variable label LogPayBonus'" "`:variable label Leaver'" "`:variable label TransferInternalSJC'" "`:variable label ChangeSalaryGradeC'" "`: variable label  PromWLC'", pattern(1 0  1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
} 

* with WL OF MANAGER 
foreach  x in EarlyAgeM EarlyTenureM {
	eststo  clear 
	foreach var in LogPayBonus LeaverVol TransferInternalSJC  ChangeSalaryGradeC PromWLC {
 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
eststo: reghdfe `var'  `x' c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM WLM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "No" , replace
estadd scalar cmean = `cmean'
eststo: reghdfe `var'   `x' c.Tenure##c.Tenure TeamSize , a(IDlse CountryYM WLM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'

} 

esttab using "$analysis/Results/4.MType/EE`x'WL.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N r2, labels("Controls" "Employee FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize Tenure c.Tenure#c.Tenure ) ///
 nomtitles mgroups("`:variable label LogPayBonus'" "`:variable label Leaver'" "`:variable label TransferInternalSJC'" "`:variable label ChangeSalaryGradeC'" "`: variable label  PromWLC'", pattern(1 0  1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
} 


* OTHER MANAGER TYPES 
foreach var in LogPayBonus Leaver TransferInternalSJC  ChangeSalaryGradeC PromWLC{
 local lbl : variable label `var'
eststo  clear 
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
eststo: reghdfe `var'  LineManagerMeanB c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var' DirectorM c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  VPAHighM c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  PayBonusGrowthMB c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  SGSpeedMB c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  ChangeSalaryGradeRMMeanB c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  LeaverVolRMMeanB c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
esttab , se star(* 0.10 ** 0.05 *** 0.01)   drop(_cons TeamSize *Tenure*)

esttab using "$analysis/Results/4.MType/RFMType`var'.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls cmean N r2, labels("Controls"  "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize *Tenure*) ///
 nomtitles mgroups("`lbl'", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}

* IV
eststo  clear 
mean Leaver
mat coef=e(b)
local cmean = coef[1,1]
eststo: ivreghdfe Leaver (TransferInternalSJC = LineManagerMeanB) c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "LineManagerMeanB" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = DirectorM) c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "DirectorM" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = VPAHighM) c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "VPAHighM" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = PayBonusGrowthMB) c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "PayBonusGrowthMB" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = SGSpeedMB) c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "SGSpeedMB" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = ChangeSalaryGradeRMMeanB) c.Tenure##c.Tenure TeamSize, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "ChangeSalaryGradeRMMeanB" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = LeaverVolRMMeanB) c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "LeaverVolRMMeanB" , replace
estadd scalar cmean = `cmean'
esttab , se star(* 0.10 ** 0.05 *** 0.01)   drop( TeamSize *Tenure*)

esttab using "$analysis/Results/4.MType/IVMTypeExit.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls IV cmean N r2, labels("Controls" "IV" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop( TeamSize *Tenure*) ///
 nomtitles mgroups("Exit", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

* IV - KEEPING SAMPLE CONSTANT
eststo  clear 
mean Leaver
mat coef=e(b)
local cmean = coef[1,1]
eststo: ivreghdfe Leaver (TransferInternalSJC = LineManagerMeanB) c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "LineManagerMeanB" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = DirectorM) c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "DirectorM" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = VPAHighM) c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "VPAHighM" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = PayBonusGrowthMB) c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "PayBonusGrowthMB" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = SGSpeedMB) c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "SGSpeedMB" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = ChangeSalaryGradeRMMeanB) c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "ChangeSalaryGradeRMMeanB" , replace
estadd scalar cmean = `cmean'
eststo:  ivreghdfe Leaver (TransferInternalSJC = LeaverVolRMMeanB) c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local IV "LeaverVolRMMeanB" , replace
estadd scalar cmean = `cmean'
esttab , se star(* 0.10 ** 0.05 *** 0.01)   drop( TeamSize *Tenure*)

esttab using "$analysis/Results/4.MType/IVMTypeExitS.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls IV cmean N r2, labels("Controls" "IV" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop( TeamSize *Tenure*) ///
 nomtitles mgroups("Exit", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

********************************************************************************
* Evidence on talent hoarding 
********************************************************************************
xtset IDlse YearMonth
reghdfe ChangeSalaryGradeC EarlyAgeM##l12.c.VPA, a(IDlse CountryYM) vce(cluster IDlseMHR)

eststo: ivreghdfe Leaver (TransferInternalSJC = EarlyAgeM) c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)


********************************************************************************
* reduced form regression by similarity: same gender and same nationality 
********************************************************************************

* how managers improve retention 
ge SameSample =1 if LineManagerMeanB!=. & DirectorM !=. & VPAHighM!=. & PayBonusGrowthMB!=. &  ChangeSalaryGradeRMMeanB!=.  &   LeaverVolRMMeanB!=. & SGSpeedMB!=.

label var TeamSize "Team Size"
label var TransferInternalSJC  "Job transfer"
label var ChangeSalaryGradeC  "SG Change"
label var PromWLC  "Prom. WL"
label var LogPayBonus "Pay + bonus (logs)"
label var WLM "Work Level"
label var DirectorM "LM Director +"
label var VPAHighM "VPA M >=125"
label var LineManagerMean "Effective LM"
label var LineManagerMeanB "Effective LM"
label var PayBonusGrowthM "Salary Growth M"
label var PayBonusGrowthMB "Salary Growth M"
label var SGSpeedM "Prom. Speed"
label var SGSpeedMB "Prom. Speed"
label var ChangeSalaryGradeRMMean "Team mean prom."
label var ChangeSalaryGradeRMMeanB "Team mean prom."
label var LeaverVolRMMean "Team mean vol. exit"
label var LeaverVolRMMeanB "Team mean vol. exit"

foreach var in LogPayBonus Leaver TransferInternalSJC  ChangeSalaryGradeC PromWLC{
	eststo clear 
eststo: reghdfe `var'  SameGender c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var'  SameGender c.Tenure##c.Tenure TeamSize , a( IDlse CountryYM) cluster(IDlseMHR)
eststo: reghdfe `var'  SameNationality c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var'  SameNationality c.Tenure##c.Tenure TeamSize , a( IDlse CountryYM) cluster(IDlseMHR)
eststo: reghdfe `var'  SameOffice c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var' SameOffice c.Tenure##c.Tenure TeamSize , a( IDlse CountryYM) cluster(IDlseMHR)
eststo: reghdfe `var'  SameCountry c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var'  SameCountry c.Tenure##c.Tenure TeamSize , a( IDlse CountryYM) cluster(IDlseMHR)
esttab using "$analysis/Results/4.MType/`var'Similarity.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls cmean N r2, labels("Controls"  "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize *Tenure*) ///
 nomtitles mgroups("`lbl'", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}


foreach var in LogPayBonus Leaver TransferInternalSJC  ChangeSalaryGradeC PromWLC{
	eststo clear 
eststo: reghdfe `var'  EarlyAgeM##SameGender c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var'  EarlyAgeM##SameGender c.Tenure##c.Tenure TeamSize , a( IDlse CountryYM) cluster(IDlseMHR)
eststo: reghdfe `var'  EarlyAgeM##SameNationality c.Tenure##c.Tenure TeamSize  , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var'  EarlyAgeM##SameNationality c.Tenure##c.Tenure TeamSize , a( IDlse CountryYM) cluster(IDlseMHR)
eststo: reghdfe `var'  EarlyAgeM##SameOffice c.Tenure##c.Tenure TeamSize  , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var'  EarlyAgeM##SameOffice c.Tenure##c.Tenure TeamSize , a( IDlse CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var'  EarlyAgeM##SameCountry c.Tenure##c.Tenure TeamSize , a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
*eststo: reghdfe `var'  EarlyAgeM##SameCountry c.Tenure##c.Tenure TeamSize , a( IDlse CountryYM) cluster(IDlseMHR)
esttab using "$analysis/Results/4.MType/Early`var'Similarity.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls cmean N r2, labels("Controls"  "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize *Tenure*) ///
 nomtitles mgroups("`lbl'", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}


*Reduced form 
foreach var in LogPayBonus Leaver TransferInternalSJC  ChangeSalaryGradeC PromWLC{
 local lbl : variable label `var'
eststo  clear 
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
eststo: reghdfe `var'  LineManagerMeanB##SameGender c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var' DirectorM##SameGender c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  VPAHighM##SameGender c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  PayBonusGrowthMB##SameGender c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  SGSpeedMB##SameGender c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  ChangeSalaryGradeRMMeanB##SameGender c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo:  reghdfe `var'  LeaverVolRMMeanB##SameGender c.Tenure##c.Tenure TeamSize if SameSample ==1, a( Female Func AgeBand CountryYM) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
esttab , se star(* 0.10 ** 0.05 *** 0.01)   drop(_cons TeamSize *Tenure*)

esttab using "$analysis/Results/4.MType/RFMType`var'Gender.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls cmean N r2, labels("Controls"  "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize *Tenure*) ///
 nomtitles mgroups("`lbl'", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}



