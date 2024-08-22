********************************************************************************
* SUN & ABRAHAM ESTIMATION - STATIC
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType2015.dta", clear 
do "$analysis/DoFiles/7.Robustness/_CoeffProgram2015.do"

merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

////////////////////////////////////////////////////////////////////////////////

xtset IDlse YearMonth 

////////////////////////////////////////////////////////////////////////////////
* Define variables for manager type defined on half sample only 
////////////////////////////////////////////////////////////////////////////////

* 1) EVENT STUDY DUMMIES 

* never-treated  
replace Ei = . if ELL==. & ELH==. & EHL==. & EHH==. 
gen lastcohort = Ei==. // never-treated cohort

* Window around event time and event post indicator 
*  Ei EH EL
foreach var in Ei EHL ELL EHH ELH {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

}

* drop always treated individuals  (there are none)
bys IDlse: egen vv = var(EiPost) // if there is a cohort that is always treated, then we need to exclude this cohort from estimation.
drop if vv ==0 & EiPost==1 

gen YEi = year(dofm(Ei))

* DUMMY FOR BALANCED SAMPLE IN CALENDAR TIME
gen i = Year>2015 
bys IDlse: egen nmonth= count(cond(i==1, IDlse, .)) 
gen BalancedSample = (nmonth ==51 & i==1) 

* 2) COHORT INTERACTION TERMS 

*qui levelsof YEi, local(cohort) 
*foreach yy of local cohort {
		forval yy = 2016(1)2020 {
			gen cohort`yy' = (YEi == `yy') 
	foreach l in ELL ELH EHL EHH {
			qui gen `l'_`yy'  = cohort`yy'* `l'Post 
			local eventinteract "`eventinteract' `l'_`yy'"
	}
	}

global eventinteract `eventinteract'
des $eventinteract 

* 3) COHORT SHARES, would be 110 maybe divide into quarters? or 6 months?  or 10 years?

foreach var in ELH ELL EHL EHH {
	forval yy = 2016/2020{
		matrix shares`var'`yy' = J(1,1,.)
	}
	}

cap drop shares* 
foreach var in ELH ELL EHL EHH {
	forval yy = 2016(1)2020 {
			
summarize cohort`yy' if `var'Post == 1 

mat b_`l' = r(mean)
matrix shares`var'`yy'[1,1] =b_`l'
	
svmat shares`var'`yy'
}
}

des $eventinteract 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR  Female

* OUTCOME VARIABLES 
////////////////////////////////////////////////////////////////////////////////

* Time in division
gen o=1 
bys IDlse TransferInternalC: gen TimeInternalC = sum(o)

* Time in function 
bys IDlse TransferFuncC : gen TimeFuncC = sum(o)

* Activities ONET
egen ONETDistance = rowmean(ONETContextDistance ONETActivitiesDistance ONETAbilitiesDistance ONETSkillsDistance) 
egen ONETDistanceC = rowmean(ONETContextDistanceC ONETActivitiesDistanceC ONETAbilitiesDistanceC ONETSkillsDistanceC) 

foreach var in  ONETDistanceC ONETContextDistanceC ONETActivitiesDistanceC ONETAbilitiesDistanceC ONETSkillsDistanceC {
gen `var'B = `var'>0 if `var'!=. 
gen `var'B1 = `var'>0 if `var'!=. 
replace `var'B1 = 0 if `var'==. 
}


////////////////////////////////////////////////////////////////////////////////
* 4) FINAL COEFF: WEIGHTED AVERAGES 
////////////////////////////////////////////////////////////////////////////////

* PERFORMANCE & EXIT  
* VPA 

eststo  clear
local i = 1 
foreach var in  LogPayBonus ChangeSalaryGradeC PromWLC VPA {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventinteract $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohort2015

foreach v in LH1 LL1 L1 HL1 HH1 H1{
	su b`v'
	estadd scalar b`v' = r(mean)
	su se`v'
	estadd scalar se`v' = r(mean)
}

local i = `i' + 1

} 

foreach var in  LeaverPerm {
		
 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regE`i': reghdfe `var' $eventinteract $cont , a( $exitFE   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohort2015

foreach v in LH1 LL1 L1 HL1 HH1 H1{
	su b`v'
	estadd scalar b`v' = r(mean)
	su se`v'
	estadd scalar se`v' = r(mean)
}
}

esttab using "$analysis/Results/7.Robustness/PerfStatic2015.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH1 seLH1 bLL1 seLL1 bL1 seL1 bHL1 seHL1 bHH1 seHH1 bH1 seH1 cmean N1 r2, labels("Post E\textsubscript{LH}" " " "Post E\textsubscript{LL}" " " "\hline Post E\textsubscript{LH}-E\textsubscript{LL}" " " "\hline Post E\textsubscript{HL}" " " "Post E\textsubscript{HH}" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}" " " " \hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
 nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

* TRANSFERS 
eststo  clear
local i = 1 
	foreach var in TransferInternalC TransferInternalLLC TransferInternalVC  TransferFuncC TransferInternalSameMC  TransferInternalDiffMC {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventinteract $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohort2015

foreach v in LH1 LL1 L1 HL1 HH1 H1{
	su b`v'
	estadd scalar b`v' = r(mean)
	su se`v'
	estadd scalar se`v' = r(mean)
}

local i = `i' + 1

} 

esttab using "$analysis/Results/7.Robustness/TransfersStatic2015.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH1 seLH1 bLL1 seLL1 bL1 seL1 bHL1 seHL1 bHH1 seHH1 bH1 seH1 cmean N1 r2, labels("Post E\textsubscript{LH}" " " "Post E\textsubscript{LL}" " " "\hline Post E\textsubscript{LH}-E\textsubscript{LL}" " " "\hline Post E\textsubscript{HL}" " " "Post E\textsubscript{HH}" " " " \hline Post E\textsubscript{HL}-E\textsubscript{HH}" " " " \hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
 nomtitles mgroups("Transfer: sub-func/office" "Transfer (lateral)" "Transfer (vertical)" "Transfer Function" "Same M." "Diff. M."   , pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace


* MATCHING 
* ONETAbilitiesDistanceCB1  ONETSkillsDistanceCB1 ONETDistanceCB
eststo  clear
local i = 1
	foreach var in  ONETDistanceCB1 TimeInternalC TimeFuncC   {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventinteract $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohort2015

foreach v in LH1 LL1 L1 HL1 HH1 H1{
	su b`v'
	estadd scalar b`v' = r(mean)
	su se`v'
	estadd scalar se`v' = r(mean)
}

local i = `i' + 1

} 

esttab using "$analysis/Results/7.Robustness/MatchingStatic2015.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH1 seLH1 bLL1 seLL1 bL1 seL1 bHL1 seHL1 bHH1 seHH1 bH1 seH1 cmean N1 r2, labels("Post E\textsubscript{LH}" " " "Post E\textsubscript{LL}" " " "\hline Post E\textsubscript{LH}-E\textsubscript{LL}" " " "\hline Post E\textsubscript{HL}" " " "Post E\textsubscript{HH}" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}" " " " \hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
 nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace


* EDUCATION DISTANCE 
decode Func, gen(FuncS)

merge m:1 FuncS SubFuncS StandardJobCode using "$fulldta/EducationMainField.dta"
drop if _merge ==2 
drop _merge 

merge m:1 IDlse using "$fulldta/EducationMax.dta"
drop if _merge ==2 
drop _merge

gen DiffField = (FieldHigh1 != MajorField & FieldHigh2!= MajorField &  FieldHigh3!= MajorField) if (MajorField!=. & FieldHigh1!=. )

eststo : reghdfe DiffField $eventinteract $cont , a( $abs   ) vce(cluster IDlseMHR)
coeffStaticCohort2015
* only  482,264 obs 
* find ELH-ELL: -.0444348 ; pvalue: 0.040
* no effect on EHH-EHL 

