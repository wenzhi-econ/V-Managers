********************************************************************************
* SUN & ABRAHAM ESTIMATION - STATIC - heterogeneity by baseline performance 
********************************************************************************

cd "$analysis"

////////////////////////////////////////////////////////////////////////////////
* CREATE DATASET - DOES NOT HAVE TO BE RE RUN EACH TIME 
////////////////////////////////////////////////////////////////////////////////

* RUN MANUALLY!
*do "$analysis/DoFiles/4.Event/4.0.TWFEPrep.do"

********************************************************************************
* Determine performance at baseline 
********************************************************************************

foreach var in Ei {
gen K`var' = YearMonth - `var'

forvalues l = 3/12 { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

*use salary growth
********************************************************************************
gen PayGrowth = d.LogPayBonus
bys IDlse : egen PayGrowth0 = mean(cond(F6Ei==1 | F7Ei==1 | F8Ei==1 | F9Ei==1 | F10Ei==1 | F11Ei==1 | F12Ei==1 ,PayGrowth ,.)) // mean 6-12 months before meeting new manager 
bys IDlse : egen PayGrowthMean = mean(PayGrowth)
replace PayGrowth0 = PayGrowthMean if Ei==. // replace with overall mean if worker never experiences a manager change
 
gen PayGrowthLow0 = PayGrowth0<0
gen PayGrowthMed0 = PayGrowth0==0 & PayGrowth0!=.
gen PayGrowthHigh0 = PayGrowth0>0 & PayGrowth0!=.

gen PayGrowth_VL = PayGrowthLow0 
gen PayGrowth_VM = PayGrowthMed0 
gen PayGrowth_VH = PayGrowthHigh0

drop KEi F*Ei 

* 1) EVENT STUDY DUMMIES 
********************************************************************************

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
********************************************************************************

*qui levelsof YEi, local(cohort) 
*foreach yy of local cohort {
	forval yy = 2011(1)2020 {
			foreach h in _VL _VM _VH {
			gen cohort`yy'`h' = (YEi == `yy' & PayGrowth`h'==1 ) 
	foreach l in ELL ELH EHL EHH {
			qui gen `l'_`yy'`h'  = cohort`yy'`h'* `l'Post 
			local eventinteract "`eventinteract' `l'_`yy'`h'"
	}
	}
	}

global eventinteractPayGrowth `eventinteract'
des $eventinteractPayGrowth 

* 3) COHORT SHARES, would be 110 maybe divide into quarters? or 6 months?  or 10 years?
********************************************************************************

foreach var in ELH ELL EHL EHH {
	forval yy = 2011/2020{
	foreach h in _VL _VM _VH {
		matrix shares`var'`yy'`h' = J(1,1,.)
	}
	}
	}

cap drop shares* 
foreach var in ELH ELL EHL EHH {
		forval yy = 2011(1)2020 {
		foreach h in _VL _VM _VH  {
	
summarize cohort`yy'`h' if `var'Post == 1 & PayGrowth`h'==1

mat b_`yy'`h' = r(mean) 

matrix shares`var'`yy'`h'[1,1] =b_`yy'`h'
	
svmat shares`var'`yy'`h'
}

}
}
* regressions 
label var PayGrowth1000 "Low Performer"
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"

keep if PayGrowth0!=.

compress 
save "$Managersdta/HetPayG.dta", replace 

////////////////////////////////////////////////////////////////////////////////
* ANALYSIS - static cohort 
////////////////////////////////////////////////////////////////////////////////

use "$Managersdta/HetPayG.dta", clear 

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

forval yy = 2011(1)2020 {
	foreach h in _VL _VM _VH {
	foreach l in ELL ELH EHL EHH {
	local eventinteract "`eventinteract' `l'_`yy'`h'"
}
}
}

global eventinteractPayGrowth `eventinteract'
des $eventinteractPayGrowth 

des $eventinteractPayGrowth 
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

eststo  clear
local i = 1 
foreach var in  LogPayBonus ChangeSalaryGradeC PromWLC VPA {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventinteractPayGrowth $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohortVPA

	foreach h in _VL1 _VM1 _VH1 {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
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
eststo regE`i': reghdfe `var' $eventinteractPayGrowth $cont , a( $exitFE   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohortVPA

foreach h in _VL1 _VM1 _VH1 {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}
}

esttab using "$analysis/Results/5.Mechanisms/PerfStaticHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_VL1 seL_VL1 bL_VM1 seL_VM1 bL_VH1 seL_VH1  bH_VL1 seH_VL1 bH_VM1 seH_VM1 bH_VH1 seH_VH1 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/PerfStaticHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH_VL1 seLH_VL1 bLH_VM1 seLH_VM1 bLH_VH1 seLH_VH1 bLL_VL1 seLL_VL1 bLL_VM1 seLL_VM1 bLL_VH1 seLL_VH1  bHL_VL1 seHL_VL1 bHL_VM1 seHL_VM1 bHL_VH1 seHL_VH1 bHH_VL1 seHH_VL1 bHH_VM1 seHH_VM1 bHH_VH1 seHH_VH1 cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: Med" " " "Post E\textsubscript{LH}: High" " " "\hline Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: Med" " " "Post E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: Med" " " "Post E\textsubscript{HL}: High" " " "\hline Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: Med" " " "Post E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

* TRANSFERS 
eststo  clear
local i = 1 
	foreach var in  TransferInternalC TransferInternalLLC TransferInternalVC  TransferFuncC TransferInternalSameMC  TransferInternalDiffMC {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventinteractPayGrowth $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohortVPA

	foreach h in _VL1 _VM1 _VH1 {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}
	
local i = `i' + 1

} 

esttab using "$analysis/Results/5.Mechanisms/TransfersStaticHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_VL1 seL_VL1 bL_VM1 seL_VM1 bL_VH1 seL_VH1  bH_VL1 seH_VL1 bH_VM1 seH_VM1 bH_VH1 seH_VH1 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Transfer: sub-func/office" "Transfer (lateral)" "Transfer (vertical)" "Transfer Function" "Same M." "Diff. M."   , pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/TransfersStaticHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH_VL1 seLH_VL1 bLH_VM1 seLH_VM1 bLH_VH1 seLH_VH1 bLL_VL1 seLL_VL1 bLL_VM1 seLL_VM1 bLL_VH1 seLL_VH1  bHL_VL1 seHL_VL1 bHL_VM1 seHL_VM1 bHL_VH1 seHL_VH1 bHH_VL1 seHH_VL1 bHH_VM1 seHH_VM1 bHH_VH1 seHH_VH1 cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: Med" " " "Post E\textsubscript{LH}: High" " " "\hline Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: Med" " " "Post E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: Med" " " "Post E\textsubscript{HL}: High" " " "\hline Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: Med" " " "Post E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Transfer: sub-func/office" "Transfer (lateral)" "Transfer (vertical)" "Transfer Function" "Same M." "Diff. M."   , pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

* MATCHING 
* ONETAbilitiesDistanceCB1  ONETSkillsDistanceCB1 ONETDistanceCB
eststo  clear
local i = 1
	foreach var in ONETDistanceCB1 TimeInternalC TimeFuncC   {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventinteractPayGrowth $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohortVPA

	foreach h in _VL1 _VM1 _VH1 {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}

local i = `i' + 1

} 


esttab using "$analysis/Results/5.Mechanisms/MatchingStaticHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_VL1 seL_VL1 bL_VM1 seL_VM1 bL_VH1 seL_VH1  bH_VL1 seH_VL1 bH_VM1 seH_VM1 bH_VH1 seH_VH1 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/MatchingStaticHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH_VL1 seLH_VL1 bLH_VM1 seLH_VM1 bLH_VH1 seLH_VH1 bLL_VL1 seLL_VL1 bLL_VM1 seLL_VM1 bLL_VH1 seLL_VH1  bHL_VL1 seHL_VL1 bHL_VM1 seHL_VM1 bHL_VH1 seHL_VH1 bHH_VL1 seHH_VL1 bHH_VM1 seHH_VM1 bHH_VH1 seHH_VH1 cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: Med" " " "Post E\textsubscript{LH}: High" " " "\hline Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: Med" " " "Post E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: Med" " " "Post E\textsubscript{HL}: High" " " "\hline Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: Med" " " "Post E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

////////////////////////////////////////////////////////////////////////////////
* ANALYSIS - TWFE
////////////////////////////////////////////////////////////////////////////////

use "$Managersdta/HetPayG.dta", clear 

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

foreach l in ELH ELL  EHL EHH {
foreach h in _VL _VM _VH {
	gen `l'`h' = `l'Post*PayGrowth`h'
	local eventTWFE "`eventTWFE' `l'`h'"
}
}


global eventTWFE `eventTWFE'
des $eventTWFE 

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR  Female


////////////////////////////////////////////////////////////////////////////////
* 4) FINAL COEFF: WEIGHTED AVERAGES 
////////////////////////////////////////////////////////////////////////////////

* PERFORMANCE & EXIT
label var EHH_VL  "EHH: Low"
label var EHH_VM  "EHH: Med"  
label var EHH_VH  "EHH: High" 
label var EHL_VL  "EHL: Low"
label var EHL_VM  "EHL: Med"  
label var EHL_VH  "EHL: High" 
label var ELL_VL  "ELL: Low"
label var ELL_VM  "ELL: Med"  
label var ELL_VH  "ELL: High"
label var ELH_VL  "ELH: Low"
label var ELH_VM  "ELH: Med"  
label var ELH_VH  "ELH: High"

eststo  clear
local i = 1 
foreach var in  LogPayBonus ChangeSalaryGradeC PromWLC VPA {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventTWFE $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

	foreach h in _VL _VM _VH {
	lincom ELH`h'  - ELL`h'
	estadd scalar bLow`h' = r(estimate)
	estadd scalar seLow`h' = r(se)

	lincom EHL`h' - EHH`h'
	estadd scalar bHigh`h' = r(estimate)
	estadd scalar seHigh`h' = r(se)

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
eststo regE`i': reghdfe `var' $eventTWFE $cont , a( $exitFE   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

	foreach h in _VL _VM _VH {
	lincom ELH`h'  - ELL`h'
	estadd scalar bLow`h' = r(estimate)
	estadd scalar seLow`h' = r(se)

	lincom EHL`h' - EHH`h'
	estadd scalar bHigh`h' = r(estimate)
	estadd scalar seHigh`h' = r(se)

}
}

esttab using "$analysis/Results/5.Mechanisms/PerfTWFEStaticHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EL*_* EH*_*) se r2 ///
s(cmean N1 r2, labels("Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/PerfTWFEStaticHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLow_VL seLow_VL  bLow_VM seLow_VM bLow_VH seLow_VH bHigh_VL seHigh_VL  bHigh_VM seHigh_VM bHigh_VH seHigh_VH cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

* TRANSFERS 
eststo  clear
local i = 1 
	foreach var in  TransferInternalC TransferInternalLLC TransferInternalVC  TransferFuncC TransferInternalSameMC  TransferInternalDiffMC {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventTWFE $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

	foreach h in _VL _VM _VH {
	lincom ELH`h'  - ELL`h'
	estadd scalar bLow`h' = r(estimate)
	estadd scalar seLow`h' = r(se)

	lincom EHL`h' - EHH`h'
	estadd scalar bHigh`h' = r(estimate)
	estadd scalar seHigh`h' = r(se)

}
	
local i = `i' + 1

} 

esttab using "$analysis/Results/5.Mechanisms/TransfersTWFEStaticHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLow_VL seLow_VL  bLow_VM seLow_VM bLow_VH seLow_VH bHigh_VL seHigh_VL  bHigh_VM seHigh_VM bHigh_VH seHigh_VH cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Transfer: sub-func/office" "Transfer (lateral)" "Transfer (vertical)" "Transfer Function" "Same M." "Diff. M."   , pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/TransfersTWFEStaticHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EL*_* EH*_*) se r2 ///
s(cmean N1 r2, labels("Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Transfer: sub-func/office" "Transfer (lateral)" "Transfer (vertical)" "Transfer Function" "Same M." "Diff. M."   , pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

* MATCHING 
* ONETAbilitiesDistanceCB1  ONETSkillsDistanceCB1 ONETDistanceCB
eststo  clear
local i = 1
	foreach var in ONETDistanceCB1 TimeInternalC TimeFuncC   {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var' $eventTWFE $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

	foreach h in _VL _VM _VH {
	lincom ELH`h'  - ELL`h'
	estadd scalar bLow`h' = r(estimate)
	estadd scalar seLow`h' = r(se)

	lincom EHL`h' - EHH`h'
	estadd scalar bHigh`h' = r(estimate)
	estadd scalar seHigh`h' = r(se)

}

local i = `i' + 1

} 


esttab using "$analysis/Results/5.Mechanisms/MatchingTWFEStaticHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLow_VL seLow_VL  bLow_VM seLow_VM bLow_VH seLow_VH bHigh_VL seHigh_VL  bHigh_VM seHigh_VM bHigh_VH seHigh_VH cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/MatchingTWFEStaticHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EL*_* EH*_*) se r2 ///
s(cmean N1 r2, labels("Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace





