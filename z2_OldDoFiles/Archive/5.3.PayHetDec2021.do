********************************************************************************
* SUN & ABRAHAM ESTIMATION - STATIC - heterogeneity by baseline performance 
********************************************************************************

cd "$analysis"

use "$Managersdta/SwitchersAllSameTeam.dta", clear

********************************************************************************
* 1) Choose the manager type variable  
********************************************************************************

local Label PromSG75 // CHOOSE THE EVENT VARIABLE 
foreach i in LL LH HL HH{
rename `Label'`i' E`i'
rename `Label'`i'Post E`i'Post 
}

* Adjust event to the manager type in consideration 
replace Ei = . if ELL==. & ELH==. & EHL==. & EHH==. 
gen lastcohort = Ei==. // never-treated cohort

drop KEi 
foreach var in Ei {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.
} 

gen YEi = year(dofm(Ei))

keep if Ei!=. // only keep switchers of manager type chosen 

********************************************************************************
* 2) Determine performance at baseline: salary growth 
********************************************************************************

* DUMMY FOR BALANCED SAMPLE IN CALENDAR TIME
gen i = Year>2015 
bys IDlse: egen nmonth= count(cond(i==1, IDlse, .)) 
gen BalancedSample = (nmonth ==51 & i==1) 

* drop always treated individuals  (there are none)
bys IDlse: egen vv = var(EiPost) // if there is a cohort that is always treated, then we need to exclude this cohort from estimation.
drop if vv ==0 & EiPost==1 

foreach var in Ei {

forvalues l = 3/12 { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus
bys IDlse : egen PayGrowth0 = mean(cond(F6Ei==1 | F7Ei==1 | F8Ei==1 | F9Ei==1 | F10Ei==1 | F11Ei==1 | F12Ei==1 ,PayGrowth ,.)) // mean 6-12 months before meeting new manager 
bys IDlse : egen PayGrowthMean = mean(PayGrowth)
replace PayGrowth0 = PayGrowthMean if Ei==. // replace with overall mean if worker never experiences a manager change

su PayGrowth0 ,d 
gen PayGrowth_p25 = (PayGrowth0<r(p25) & PayGrowth0!=.)
replace PayGrowth_p25 = . if PayGrowth0==.
gen PayGrowth_p25p50 = (PayGrowth0>=r(p25) & PayGrowth0 <r(p50) & PayGrowth0!=.)
replace PayGrowth_p25p50 = . if PayGrowth0==.
gen PayGrowth_p50p75 = (PayGrowth0>=r(p50) & PayGrowth0 <r(p75) & PayGrowth0!=.)
replace PayGrowth_p50p75 = . if PayGrowth0==.
gen PayGrowth_p75p100 = (PayGrowth0 >=r(p75) & PayGrowth0!=.)
replace PayGrowth_p75p100 = . if PayGrowth0==.

drop F*Ei 

keep if PayGrowth0!=.

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

* 1) COHORT INTERACTION TERMS 
********************************************************************************

*qui levelsof YEi, local(cohort) 
*foreach yy of local cohort {
	forval yy = 2011(1)2020 {
			foreach h in _p25 _p25p50  _p50p75 _p75p100 {
			gen cohort`yy'`h' = (YEi == `yy' & PayGrowth`h'==1 ) 
	foreach l in ELL ELH EHL EHH {
			qui gen `l'_`yy'`h'  = cohort`yy'`h'* `l'Post 
			local eventinteract "`eventinteract' `l'_`yy'`h'"
	}
	}
	}

global eventinteractPayGrowth `eventinteract'
des $eventinteractPayGrowth 

* 2) COHORT SHARES, would be 110 maybe divide into quarters? or 6 months?  or 10 years?
********************************************************************************

foreach var in ELH ELL EHL EHH {
	forval yy = 2011/2020{
	foreach h in _p25 _p25p50  _p50p75 _p75p100 {
		matrix shares`var'`yy'`h' = J(1,1,.)
	}
	}
	}

cap drop shares* 
foreach var in ELH ELL EHL EHH {
		forval yy = 2011(1)2020 {
		foreach h in _p25 _p25p50  _p50p75 _p75p100  {
	
summarize cohort`yy'`h' if `var'Post == 1 & PayGrowth`h'==1

mat b_`yy'`h' = r(mean) 

matrix shares`var'`yy'`h'[1,1] =b_`yy'`h'
	
*svmat shares`var'`yy'`h'
*rename shares`var'`yy'`h'1  shares`var'`yy'`h'
}

}
}

forval yy = 2011(1)2020 {
	foreach h in _p25 _p25p50 _p50p75 _p75p100 {
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

* LABELS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"

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
coeffStaticCohortPayGrowth

	foreach h in _p251 _p25p501 _p50p751 _p75p1001 {
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
coeffStaticCohortPayGrowth

foreach h in _p251 _p25p501  _p50p751 _p75p1001 {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}
}

esttab using "$analysis/Results/5.Mechanisms/PerfHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_p251 seL_p251 bL_p25p501 seL_p25p501 bL_p50p751 seL_p50p751 bL_p50p751 seL_p50p751 bL_p75p1001 seL_p75p1001  bH_p251 seH_p251 bH_p25p501 seH_p25p501 bH_p50p751 seH_p50p751 bH_p75p1001 seH_p75p1001 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med Low"  "  " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med High" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med High" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/PerfHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH_p251 seLH_p251 bLH_p25p501 seLH_p25p501 bLH_p50p751 seLH_p50p751 bLH_p75p1001 seLH_p75p1001 bLL_p251 seLL_p251 bLL_p25p501 seLL_p25p501 bLL_p75p1001 seLL_p75p1001  bHL_p251 seHL_p251 bHL_p25p501 seHL_p25p501 bHL_p75p1001 seHL_p75p1001 bHH_p251 seHH_p251 bHH_p25p501 seHH_p25p501 bHH_p50p751 seHH_p50p751 bHH_p75p1001 seHH_p75p1001 cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: Med" " " "Post E\textsubscript{LH}: High" " " "\hline Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: Med" " " "Post E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: Med" " " "Post E\textsubscript{HL}: High" " " "\hline Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: Med" " " "Post E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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
coeffStaticCohortPayGrowth

	foreach h in _p251 _p25p501  _p50p751 _p75p1001 {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}
	
local i = `i' + 1

} 

esttab using "$analysis/Results/5.Mechanisms/TransfersHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_p251 seL_p251 bL_p25p501 seL_p25p501 bL_p50p751 seL_p50p751 bL_p75p1001 seL_p75p1001  bH_p251 seH_p251 bH_p25p501 seH_p25p501 bH_p50p751 seH_p50p751 bH_p75p1001 seH_p75p1001 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med Low"  "  " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med High" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med High" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Transfer: sub-func/office" "Transfer (lateral)" "Transfer (vertical)" "Transfer Function" "Same M." "Diff. M."   , pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/TransfersHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH_p251 seLH_p251 bLH_p25p501 seLH_p25p501 bLH_p50p751 seLH_p50p751 bLH_p75p1001 seLH_p75p1001 bLL_p251 seLL_p251 bLL_p25p501 seLL_p25p501 bLL_p75p1001 seLL_p75p1001  bHL_p251 seHL_p251 bHL_p25p501 seHL_p25p501 bHL_p75p1001 seHL_p75p1001 bHH_p251 seHH_p251 bHH_p25p501 seHH_p25p501 bHH_p50p751 seHH_p50p751 bHH_p75p1001 seHH_p75p1001 cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: Med" " " "Post E\textsubscript{LH}: High" " " "\hline Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: Med" " " "Post E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: Med" " " "Post E\textsubscript{HL}: High" " " "\hline Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: Med" " " "Post E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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
coeffStaticCohortPayGrowth

	foreach h in _p251 _p25p501  _p50p751 _p75p1001 {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}

local i = `i' + 1

} 


esttab using "$analysis/Results/5.Mechanisms/MatchingHetPayGDiff.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_p251 seL_p251 bL_p25p501 seL_p25p501 bL_p50p751 seL_p50p751 bL_p75p1001 seL_p75p1001  bH_p251 seH_p251 bH_p25p501 seH_p25p501 bH_p50p751 seH_p50p751 bH_p75p1001 seH_p75p1001 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med Low"  "  " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med High" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med High" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/MatchingHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH_p251 seLH_p251 bLH_p25p501 seLH_p25p501 bLH_p50p751 seLH_p50p751 bLH_p75p1001 seLH_p75p1001 bLL_p251 seLL_p251 bLL_p25p501 seLL_p25p501 bLL_p75p1001 seLL_p75p1001  bHL_p251 seHL_p251 bHL_p25p501 seHL_p25p501 bHL_p75p1001 seHL_p75p1001 bHH_p251 seHH_p251 bHH_p25p501 seHH_p25p501 bHH_p50p751 seHH_p50p751 bHH_p75p1001 seHH_p75p1001 cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: Med" " " "Post E\textsubscript{LH}: High" " " "\hline Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: Med" " " "Post E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: Med" " " "Post E\textsubscript{HL}: High" " " "\hline Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: Med" " " "Post E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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
foreach h in _p25 _p25p50  _p50p75 _p75p100 {
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
label var EHH_p25  "EHH: Low"
label var EHH_p25p50  "EHH: Med Low" 
label var EHH_p50p75  "EHH: Med High"  
label var EHH_p75p100  "EHH: High" 

label var EHL_p25  "EHL: Low"
label var EHL_p25p50  "EHL: Med Low"  
label var EHL_p50p75  "EHL: Med High"  
label var EHL_p75p100  "EHL: High" 

label var ELL_p25  "ELL: Low"
label var ELL_p25p50  "ELL: Med Low"  
label var ELL_p50p75  "ELL: Med High"  
label var ELL_p75p100  "ELL: High"

label var ELH_p25  "ELH: Low"
label var ELH_p25p50  "ELH: Med Low"  
label var ELH_p50p75  "ELH: Med High"  
label var ELH_p75p100  "ELH: High"

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

	foreach h in _p25 _p25p50  _p50p75 _p75p100 {
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

	foreach h in _p25 _p25p50  _p50p75 _p75p100 {
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
s(bLow_p25 seLow_p25  bLow_p25p50 seLow_p25p50 bLow_p50p75 seLow_p50p75 bLow_p75p100 seLow_p75p100 bHigh_p25 seHigh_p25  bHigh_p25p50 seHigh_p25p50 bHigh_p50p75 seHigh_p50p75 bHigh_p75p100 seHigh_p75p100 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med Low"  "  " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med High" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med High" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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

	foreach h in _p25 _p25p50  _p50p75 _p75p100 {
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
s(bLow_p25 seLow_p25  bLow_p25p50 seLow_p25p50 bLow_p50p75 seLow_p50p75 bLow_p75p100 seLow_p75p100 bHigh_p25 seHigh_p25  bHigh_p25p50 seHigh_p25p50 bHigh_p50p75 seHigh_p50p75 bHigh_p75p100 seHigh_p75p100 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med Low"  "  " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med High" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med High" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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

	foreach h in _p25 _p25p50  _p50p75 _p75p100 {
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
s(bLow_p25 seLow_p25  bLow_p25p50 seLow_p25p50 bLow_p50p75 seLow_p50p75 bLow_p75p100 seLow_p75p100 bHigh_p25 seHigh_p25  bHigh_p25p50 seHigh_p25p50 bHigh_p50p75 seHigh_p50p75 bHigh_p75p100 seHigh_p75p100 cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med Low"  "  " "Post E\textsubscript{LH}-E\textsubscript{LL}: Med High" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: Med High" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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
