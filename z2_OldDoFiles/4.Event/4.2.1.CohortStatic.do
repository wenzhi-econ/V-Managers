********************************************************************************
* EVENT STUDY 
* COHORT FE STATIC model 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label PromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

////////////////////////////////////////////////////////////////////////////////
* 1) 30 months window 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

gen YEi = year(dofm(Ei))
egen CountryYear = group(Country Year )

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}
* create leads and lags 
foreach var in EHL ELL EHH ELH {

gen `var'Post = K`var'>=0 & K`var' !=.

}

* selecting only needed variables 
*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* 2) COHORT INTERACTION TERMS 

*qui levelsof YEi, local(cohort) 
*foreach yy of local cohort {
		forval yy = 2014(1)2020 {
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
	forval yy =  2014(1)2020 {
		matrix shares`var'`yy' = J(1,1,.)
	}
	}

cap drop shares* 
foreach var in ELH ELL EHL EHH {
	forval yy = 2014(1)2020 {
			
summarize cohort`yy' if `var'Post == 1 

mat b_`yy' = r(mean)
matrix shares`var'`yy'[1,1] =b_`yy'
	
svmat shares`var'`yy'
}
}

des $eventinteract 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM IDlse  // IDlseMHR
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR  Female

* OUTCOME VARIABLES 
////////////////////////////////////////////////////////////////////////////////

* Time in division
gen o=1 
bys IDlse TransferInternalC (YearMonth), sort: gen TimeInternalC = sum(o)

* Time in function 
bys IDlse TransferFuncC (YearMonth), sort : gen TimeFuncC = sum(o)

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

global perf LogPayBonus ChangeSalaryGradeC PromWLC ProductivityStd VPA  
global move TransferInternalC TransferInternalLLC TransferInternalVC  TransferInternalSameMC  TransferInternalDiffMC  
global dist TransferFuncC ONETDistanceCB1 DiffField TimeInternalC TimeFuncC

la var LogPayBonus "Pay + bonus (logs)" 
la var ChangeSalaryGradeC "Prom. (salary)" 
la var PromWLC  "Prom. (work-level)"  
la var  VPA   "Perf. Appraisals" 
la var  ProductivityStd "Productivity"
la var LeaverPerm "Exit"
label var TransferInternalC "Transfer: sub-func/office"
label var  TransferInternalLLC  "Transfer (lateral)" 
label var TransferInternalVC  "Transfer (vertical)" 
label var TransferInternalSameMC  "Same M."
label var TransferInternalDiffMC "Diff. M."
label var TransferFuncC "Transfer Func" 
label var ONETDistanceCB1 "Task distance > 0" 
label var DiffField "Diff. Educ. Field" 
label var TimeInternalC  "Time in Sub-func"
label var TimeFuncC  "Time in Func"

* PERFORMANCE & EXIT  
 
eststo  clear
local i = 1 
foreach var in  $perf $move $dist  {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo `var': reghdfe `var' $eventinteract $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
sort IDlse YearMonth
coeffStaticCohort14, y(`var')

foreach v in LH1 LL1 L1 HL1 HH1 H1{
	su b`v'
	estadd scalar b`v' = r(mean)
	su se`v'
	estadd scalar se`v' = r(mean)
	gen `var'b`v' = b`v' 
	gen `var'se`v' = se`v' 
	ge `var'lb`v' = `var'b`v' -1.96*`var'se`v'
	ge `var'ub`v' = `var'b`v' +1.96*`var'se`v'

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
eststo `var': reghdfe `var' $eventinteract $cont , a( $exitFE   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
sort IDlse YearMonth
coeffStaticCohort14, y(`var')

foreach v in LH1 LL1 L1 HL1 HH1 H1{
	su b`v'
	estadd scalar b`v' = r(mean)
	su se`v'
	estadd scalar se`v' = r(mean)
	gen `var'b`v' = b`v' 
	gen `var'se`v' = se`v' 
	ge `var'lb`v' = `var'b`v' -1.96*`var'se`v'
	ge `var'ub`v' = `var'b`v' +1.96*`var'se`v'

}
}

* table 
********************************************************************************

global perfLeaver LogPayBonus ChangeSalaryGradeC PromWLC ProductivityStd VPA LeaverPerm  

foreach group in perfLeaver move dist{
esttab $`group'  using "$analysis/Results/4.Event/`group'$Label.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH1 seLH1 bLL1 seLL1 bL1 seL1 bHL1 seHL1 bHH1 seHH1 bH1 seH1 cmean N1 r2, labels("Post E\textsubscript{LH}" " " "Post E\textsubscript{LL}" " " "\hline Post E\textsubscript{LH}-E\textsubscript{LL}" " " "\hline Post E\textsubscript{HL}" " " "Post E\textsubscript{HH}" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}" " " " \hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}

* coefplot 
********************************************************************************

sort IDlse YearMonth

gen post = "Low to High" in 1
replace post = "High to Low" in 2
encode post, gen(postE)

foreach var in  $perfLeaver $move $dist   {
ge `var'coeff = .
replace `var'coeff = `var'bL1 in 1
replace `var'coeff = l.`var'bH1 in 2
ge `var'lb = `var'bL1- 1.96*`var'seL1 in 1
replace  `var'lb = l.`var'bH1- 1.96*l.`var'seH1 in 2
ge `var'ub = `var'bL1+ 1.96*`var'seL1 in 1
replace  `var'ub = l.`var'bH1+ 1.96*l.`var'seH1 in 2

local lab: variable label `var'
graph twoway (bar `var'coeff postE) (rcap `var'lb `var'ub postE), xlabel(1 "Low to High" 2 "High to Low" ) xtitle("") legend(off) title("`lab'")
graph export "$analysis/Results/4.Event/`var'$Label.png", replace 
graph save "$analysis/Results/4.Event/`var'$Label.gph", replace 
}




