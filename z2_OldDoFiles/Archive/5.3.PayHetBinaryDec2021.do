********************************************************************************
* SUN & ABRAHAM ESTIMATION - STATIC - heterogeneity by baseline performance 
********************************************************************************

cd "$analysis"

////////////////////////////////////////////////////////////////////////////////
* import the data 
////////////////////////////////////////////////////////////////////////////////

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
gen PayGrowth_Low = PayGrowth0 <=0 
gen PayGrowth_High = PayGrowth0 > 0 if PayGrowth0 !=.

drop F*Ei 

keep if PayGrowth0!=.

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
* Define variables for cohort model 
////////////////////////////////////////////////////////////////////////////////

* 1) COHORT INTERACTION TERMS 
********************************************************************************

*qui levelsof YEi, local(cohort) 
*foreach yy of local cohort {
	forval yy = 2011(1)2020 {
			foreach h in _Low _High {
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
	foreach h in _Low _High {
		matrix shares`var'`yy'`h' = J(1,1,.)
	}
	}
	}

cap drop shares* 
foreach var in ELH ELL EHL EHH {
		forval yy = 2011(1)2020 {
		foreach h in _Low _High  {
	
summarize cohort`yy'`h' if `var'Post == 1 & PayGrowth`h'==1

mat b_`yy'`h' = r(mean) 

matrix shares`var'`yy'`h'[1,1] =b_`yy'`h'
	
*svmat shares`var'`yy'`h'
*rename shares`var'`yy'`h'1  shares`var'`yy'`h'
}

}
}

forval yy = 2011(1)2020 {
	foreach h in _Low _High {
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
coeffStaticCohortPayGrowth, het("_Low _High")

	foreach h in _Low1 _High1 {
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
coeffStaticCohortPayGrowth, het("_Low _High")

foreach h in _Low1 _High1 {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}
}

esttab using "$analysis/Results/5.Mechanisms/PerfHetPayGDiffB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_Low1 seL_Low1 bL_High1 seL_High1  bH_Low1 seH_Low1 bH_High1 seH_High1  cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/PerfHetPayGB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s( bLH_Low1 seLH_Low1 bLH_High1 seLH_High1 bLL_Low1 seLL_Low1 bLL_High1 seLL_High1 bHL_Low1 seHL_Low1 bHL_High1 seHL_High1 bHH_Low1 seHH_Low1 bHH_High1 seHH_High1  cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: High"  "  " "Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: High" " " "Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: High"  "  " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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
coeffStaticCohortPayGrowth, het("_Low _High")

	foreach h in _Low1 _High1   {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}
	
local i = `i' + 1

} 

esttab using "$analysis/Results/5.Mechanisms/TransfersHetPayGDiffB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_Low1 seL_Low1 bL_High1 seL_High1  bH_Low1 seH_Low1 bH_High1 seH_High1  cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Transfer: sub-func/office" "Transfer (lateral)" "Transfer (vertical)" "Transfer Function" "Same M." "Diff. M."   , pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/TransfersHetPayGB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s( bLH_Low1 seLH_Low1 bLH_High1 seLH_High1 bLL_Low1 seLL_Low1 bLL_High1 seLL_High1 bHL_Low1 seHL_Low1 bHL_High1 seHL_High1 bHH_Low1 seHH_Low1 bHH_High1 seHH_High1  cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: High"  "  " "Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: High" " " "Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: High"  "  " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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
coeffStaticCohortPayGrowth, het("_Low _High")

	foreach h in _Low1 _High1  {
foreach v in LH LL L HL HH H{
	su b`v'`h'
	estadd scalar b`v'`h' = r(mean)
	su se`v'`h'
	estadd scalar se`v'`h' = r(mean)
}
}

local i = `i' + 1

} 

esttab using "$analysis/Results/5.Mechanisms/MatchingHetPayGDiffB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bL_Low1 seL_Low1 bL_High1 seL_High1  bH_Low1 seH_Low1 bH_High1 seH_High1  cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/MatchingHetPayGB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s( bLH_Low1 seLH_Low1 bLH_High1 seLH_High1 bLL_Low1 seLL_Low1 bLL_High1 seLL_High1 bHL_Low1 seHL_Low1 bHL_High1 seHL_High1 bHH_Low1 seHH_Low1 bHH_High1 seHH_High1  cmean N1 r2, labels("Post E\textsubscript{LH}: Low" " " "Post E\textsubscript{LH}: High"  "  " "Post E\textsubscript{LL}: Low" " " "Post E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}: Low" " " "Post E\textsubscript{HL}: High" " " "Post E\textsubscript{HH}: Low" " " "Post E\textsubscript{HH}: High"  "  " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

////////////////////////////////////////////////////////////////////////////////
* ANALYSIS - TWFE
////////////////////////////////////////////////////////////////////////////////

* re-run intro part at beginning to import data if needed  

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

foreach l in ELH ELL  EHL EHH {
foreach h in _Low _High {
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

label var EHH_Low  "EHH: Low" 
label var EHH_High  "EHH: High" 

label var EHL_Low  "EHL: Low"
label var EHL_High  "EHL: High" 

label var ELL_Low  "ELL: Low"
label var ELL_High  "ELL: High"

label var ELH_Low "ELH: Low"
label var ELH_High  "ELH: High"

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

	foreach h in _Low _High  {
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

	foreach h in _Low _High {
	lincom ELH`h'  - ELL`h'
	estadd scalar bLow`h' = r(estimate)
	estadd scalar seLow`h' = r(se)

	lincom EHL`h' - EHH`h'
	estadd scalar bHigh`h' = r(estimate)
	estadd scalar seHigh`h' = r(se)

}
}



esttab using "$analysis/Results/5.Mechanisms/PerfTWFEHetPayGDiffB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLow_Low seLow_Low bLow_High seLow_High  bHigh_Low seHigh_Low bHigh_High seHigh_High  cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/PerfTWFEHetPayGB.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EL*_* EH*_*) se r2 ///
s(cmean N1 r2, labels("Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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

	foreach h in _Low _High {
	lincom ELH`h'  - ELL`h'
	estadd scalar bLow`h' = r(estimate)
	estadd scalar seLow`h' = r(se)

	lincom EHL`h' - EHH`h'
	estadd scalar bHigh`h' = r(estimate)
	estadd scalar seHigh`h' = r(se)

}
	
local i = `i' + 1

} 

esttab using "$analysis/Results/5.Mechanisms/TransfersTWFEHetPayGDiffB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLow_Low seLow_Low bLow_High seLow_High  bHigh_Low seHigh_Low bHigh_High seHigh_High  cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Transfer: sub-func/office" "Transfer (lateral)" "Transfer (vertical)" "Transfer Function" "Same M." "Diff. M."   , pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/TransfersTWFEHetPayGB.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EL*_* EH*_*) se r2 ///
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

	foreach h in _Low _High {
	lincom ELH`h'  - ELL`h'
	estadd scalar bLow`h' = r(estimate)
	estadd scalar seLow`h' = r(se)

	lincom EHL`h' - EHH`h'
	estadd scalar bHigh`h' = r(estimate)
	estadd scalar seHigh`h' = r(se)

}

local i = `i' + 1

} 


esttab using "$analysis/Results/5.Mechanisms/MatchingTWFEHetPayGDiffB.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLow_Low seLow_Low bLow_High seLow_High  bHigh_Low seHigh_Low bHigh_High seHigh_High  cmean N1 r2, labels( "Post E\textsubscript{LH}-E\textsubscript{LL}: Low" " " "Post E\textsubscript{LH}-E\textsubscript{LL}: High"  "  " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}: Low" " " "Post E\textsubscript{HL}-E\textsubscript{HH}: High" " " "\hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

esttab using "$analysis/Results/5.Mechanisms/MatchingTWFEcHetPayGB.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EL*_* EH*_*) se r2 ///
s(cmean N1 r2, labels("Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Task distance > 0" "Time in Sub-func" "Time in Func", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
