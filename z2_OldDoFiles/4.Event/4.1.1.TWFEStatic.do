********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

use "$managersdta/AllSnapshotMCultureMType.dta", clear 

label var EarlyAgeM "Fast track M."
label var TeamSize "Team Size"
label var TransferInternalSJC  "Job transfer"
label var ChangeSalaryGradeC  "SG Change"
label var PromWLC  "Prom. WL"
label var LogPayBonus "Pay + bonus (logs)"

* now run 4.0.EventImportSun.do 

foreach var in Ei EH EL EHL ELL EHH ELH {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

*su K`var'
*forvalues l = 0/`r(max)' {
*	gen L`l'`var' = K`var'==`l'
*}
*local mmm = -(`r(min)' +1)
*forvalues l = 2/`mmm' { // normalize -1 and r(min)
*	gen F`l'`var' = K`var'==-`l'
*}
}

xtset IDlse YearMonth
gen ONETActivitiesDistanceCB = ONETActivitiesDistanceC>0 if ONETActivitiesDistanceC!=. 
gen ONETActivitiesDistanceCB1 = ONETActivitiesDistanceC>0 if ONETActivitiesDistanceC!=. 
replace ONETActivitiesDistanceCB1 = 0 if ONETActivitiesDistanceC==. 

//////////////////////////////////////////////////////////////////////////////// 
* Transfers
////////////////////////////////////////////////////////////////////////////////

* other variables TransferInternalSJLLC  TransferInternalSJSameMLLC  TransferInternalSJDiffMLLC TransferInternalSJC  TransferInternalSJSameMC  TransferInternalSJDiffMC   
label var ELLPost "Post E\textsubscript{LL}"
label var ELHPost "Post E\textsubscript{LH}"
label var EHLPost "Post E\textsubscript{HL}"
label var EHHPost "Post E\textsubscript{HH}"
eststo clear 
foreach v in TransferInternalC  TransferInternalSameMC  TransferInternalDiffMC TransferFuncC ONETActivitiesDistanceCB1 {
local lbl : variable label `v'
mean `v' if IDlseMHR!=. 
mat coef=e(b)
local cmean = coef[1,1]
count if  `v' !=. & IDlseMHR!=. 
local N1 = r(N)
eststo: reghdfe `v' ELLPost ELHPost EHLPost EHHPost c.Tenure##c.Tenure c.TenureM##c.TenureM TeamSize , a( AgeBand CountryYM AgeBandM IDlseMHR IDlse) cluster(IDlseMHR)
test  ELHPost = ELLPost
estadd scalar pvalue1 = r(p)
test  EHLPost = EHHPost
estadd scalar pvalue2 = r(p)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
}
* more transfers but entirely under different manager (under same manager there is no difference)
esttab using "$analysis/Results/5.Transfers/TransfersLDist1.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(cmean N1 r2 pvalue1 pvalue2, labels( "Mean" "\hline N" "R-squared" "\hline E\textsubscript{LL} = E\textsubscript{LH}" "E\textsubscript{HL} = E\textsubscript{HH}" ) ) interaction("$\times$ ")  nobaselevels  drop(_cons TeamSize Tenure c.Tenure#c.Tenure TenureM c.TenureM#c.TenureM ) ///
 nomtitles mgroups("Transfers all (lateral)" "Same M." "Diff. M."  "Transfer Function" "Task distance > 0" , pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: employee FE, country x time FE, manager FE, team size, and age group FE, tenure and tenure squared of manager and employee. ///
"\end{tablenotes}") replace

//////////////////////////////////////////////////////////////////////////////// 
* NEW & OLD JOB
////////////////////////////////////////////////////////////////////////////////

*use  "$managersdta/AllSnapshotMCultureMType.dta", clear 

merge m:1 Office SubFuncS StandardJob YearMonth using "$managersdta/NewOldJobs.dta" , keepusing(NewJob OldJob)
drop _merge 

*do "$analysis/DoFiles/4.Event/4.0.TWFEPrep" // only consider first event as with new did estimators 

merge m:1 StandardJob  YearMonth IDlseMHR Office  using "$managersdta/NewOldJobsManager.dta", keepusing(NewJobManager OldJobManager)
drop _merge

* other variables TransferInternalSJLLC  TransferInternalSJSameMLLC  TransferInternalSJDiffMLLC TransferInternalSJC  TransferInternalSJSameMC  TransferInternalSJDiffMC   
label var ELLPost "Post E\textsubscript{LL}"
label var ELHPost "Post E\textsubscript{LH}"
label var EHLPost "Post E\textsubscript{HL}"
label var EHHPost "Post E\textsubscript{HH}"
eststo clear 
foreach v in NewJob OldJob NewJobManager OldJobManager  {
local lbl : variable label `v'
mean `v' if IDlseMHR!=. 
mat coef=e(b)
local cmean = coef[1,1]
count if  `v' !=. & IDlseMHR!=. 
local N1 = r(N)
eststo: reghdfe `v' ELLPost ELHPost EHLPost EHHPost c.Tenure##c.Tenure c.TenureM##c.TenureM TeamSize , a( AgeBand CountryYM AgeBandM IDlseMHR IDlse) cluster(IDlseMHR)
test  ELHPost = ELLPost
estadd scalar pvalue1 = r(p)
test  EHLPost = EHHPost
estadd scalar pvalue2 = r(p)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
}
* more transfers but entirely under different manager (under same manager there is no difference)
esttab using "$analysis/Results/5.Mechanisms/NewOldJob.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(cmean N1 r2 pvalue1 pvalue2, labels( "Mean" "\hline N" "R-squared" "\hline E\textsubscript{LL} = E\textsubscript{LH}" "E\textsubscript{HL} = E\textsubscript{HH}" ) ) interaction("$\times$ ")  nobaselevels  drop(_cons TeamSize Tenure c.Tenure#c.Tenure TenureM c.TenureM#c.TenureM ) ///
 nomtitles mgroups("New Job" "Old Job" "New Job (Manager)" "Old Job (Manager)" , pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: employee FE, country x time FE, manager FE, team size, and age group FE, tenure and tenure squared of manager and employee. ///
"\end{tablenotes}") replace

esttab est1 est2 using "$analysis/Results/5.Mechanisms/NewOldJob1.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(cmean N1 r2 pvalue1 pvalue2, labels( "Mean" "\hline N" "R-squared" "\hline E\textsubscript{LL} = E\textsubscript{LH}" "E\textsubscript{HL} = E\textsubscript{HH}" ) ) interaction("$\times$ ")  nobaselevels  drop(_cons TeamSize Tenure c.Tenure#c.Tenure TenureM c.TenureM#c.TenureM ) ///
 nomtitles mgroups("New Job" "Old Job" "New Job (Manager)" "Old Job (Manager)" , pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: employee FE, country x time FE, manager FE, team size, and age group FE, tenure and tenure squared of manager and employee. ///
"\end{tablenotes}") replace

////////////////////////////////////////////////////////////////////////////////
* EDUCATION 
////////////////////////////////////////////////////////////////////////////////

merge m:1 FuncS SubFuncS StandardJobS StandardJobCode using "$fulldta/EducationMainField.dta"
drop if _merge ==2 
drop _merge 

merge 1:1 IDlse YearMonth using "$fulldta/Education.dta"
drop if _merge ==2 
drop _merge

gen DiffField = (FieldHigh1 != MajorField & FieldHigh2!= MajorField &  FieldHigh3!= MajorField) if (MajorField!=. & FieldHigh1!=. )


