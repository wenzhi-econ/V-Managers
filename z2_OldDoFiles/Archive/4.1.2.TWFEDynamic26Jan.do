********************************************************************************
* EVENT STUDY 
* TWFE model 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label PromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

////////////////////////////////////////////////////////////////////////////////
* 1) 30 months window 
////////////////////////////////////////////////////////////////////////////////

use "$Managersdta/SwitchersAllSameTeam.dta", clear 
*use  "$Managersdta/AllSameTeam.dta", clear 
merge 1:1 IDlse YearMonth using  "$Managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

* generate useful variables 
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

gen YEi = year(dofm(Ei))
egen CountryYear = group(Country Year )

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
rename $Label`v'Post E`v'Post
}
* create leads and lags 
foreach var in EHL ELL EHH ELH {
su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

* if binning 
foreach var in LL LH HL HH {
forval i=20(10)`end'{
	gen Lend`var'`i' = KE`var'>`i' & KE`var'!=.
	gen Fend`var'`i' = KE`var'< -`i' & KE`var'!=.
}
}

* create list of event indicators if binning 
eventd, end(`end')
********************************************************************************
* * DUAL DOUBLE DIFFERENCES 
********************************************************************************

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM IDlse 
* IDlseMHR
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR Func Female

////////////////////////////////////////////////////////////////////////////////
* PRODUCTIVITY
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe ProductivityStd $event $cont, a( $abs   ) vce(cluster IDlseMHR)

local c = 21 // !PLUG! specify window 
local y = "ProductivityStd"
coeff1, c(`c') y(`y')
*placeboF, c(`c') // in disuse 
 
////////////////////////////////////////////////////////////////////////////////

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su jointLH
local jointLH = round(r(mean), 0.001)
su jointHL
local jointHL = round(r(mean), 0.001)

* final plots 
 tw connected bL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off) note("Pretrends p-value=`jointLH'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))
graph save  "$analysis/Results/4.Event/ProdSingleLow.gph", replace
graph export "$analysis/Results/4.Event/ProdSingleLow.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off) note("Pretrends p-value=`jointHL'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))
graph save  "$analysis/Results/4.Event/ProdSingleHigh.gph", replace
graph export "$analysis/Results/4.Event/ProdSingleHigh.png", replace


////////////////////////////////////////////////////////////////////////////////
* PAY
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe LogPayBonus $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff // program 
local c = 21 // !PLUG! specify window 
*placeboF, c(`c')

 tw connected b et1 if et1>-21 & et1<21, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et1 if et1>-21 & et1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(2)20) ///
xtitle(Months since manager change) title("Pay + Bonus (logs)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/PayDual.gph", replace
graph export "$analysis/Results/4.Event/PayDual.png", replace

* single differences 
coeff1, c(41) // program 

 tw connected bL et1 if et1>-21 & et1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL et1 if et1>-21 & et1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(2)20) ///
xtitle(Months since manager change) title("Pay + Bonus (logs)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/PaySingleLow.gph", replace
graph export "$analysis/Results/4.Event/PaySingleLow.png", replace

 tw connected bH1 et1 if et1>-21 & et1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-21 & et1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(2)20) ///
xtitle(Months since manager change) title("Pay + Bonus (logs)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/PaySingleHigh.gph", replace
graph export "$analysis/Results/4.Event/PaySingleHigh.png", replace

////////////////////////////////////////////////////////////////////////////////
* EXIT 
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe LeaverPerm $event $cont, a( $exitFE   ) vce(cluster IDlseMHR)

* double differences 
coeffSum // program 
gen hi = b1 +  se1*1.96
gen lo = b1 -  se1*1.96
 tw connected b et1 if et1>-31 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et1 if et1>-31 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-30(6)30) ///
xtitle(Months since manager change) title("Exit", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ExitDual.gph", replace
graph export "$analysis/Results/4.Event/ExitDual.png", replace
 
gen hiSum1 = bSum1 +  seSum1*1.96
gen loSum1 = bSum1 -  seSum1*1.96
 tw connected bSum1 et1 if et1>-31 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap loSum1 hiSum1 et1 if et1>-31 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-30(6)30) ///
xtitle(Months since manager change) title("Exit - cumulative", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ExitDualSum.gph", replace
graph export "$analysis/Results/4.Event/ExitDualSum.png", replace

* single differences 
coeffSum1 // program 

 tw connected bL et1 if et1>-31 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL et1 if et1>-31 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-30(6)30) ///
xtitle(Months since manager change) title("Exit", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ExitSingleLow.gph", replace
graph export "$analysis/Results/4.Event/ExitSingleLow.png", replace

 tw connected bH1 et1 if et1>-31 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-31 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-30(6)30) ///
xtitle(Months since manager change) title("Exit", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ExitSingleHigh.gph", replace
graph export "$analysis/Results/4.Event/ExitSingleHigh.png", replace

gen hiLSum1 = bLSum1 +  seLSum1*1.96
gen loLSum1 = bLSum1 -  seLSum1*1.96
 tw connected bLSum1 et1 if et1>-31 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap loLSum1 hiLSum1 et1 if et1>-31 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-30(6)30) ///
xtitle(Months since manager change) title("Exit - cumulative", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ExitSingleLowSum.gph", replace
graph export "$analysis/Results/4.Event/ExitSingleLowSum.png", replace

gen hiHSum1 = bHSum1 +  seHSum1*1.96
gen loHSum1 = bHSum1 -  seHSum1*1.96
 tw connected bHSum1 et1 if et1>-31 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap loHSum1 hiHSum1 et1 if et1>-31 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-30(6)30) ///
xtitle(Months since manager change) title("Exit - cumulative", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ExitSingleHighSum.gph", replace
graph export "$analysis/Results/4.Event/ExitSingleHighSum.png", replace

////////////////////////////////////////////////////////////////////////////////
* PROMWLC
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe PromWLC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff, c(121) // program 

 tw connected b et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Promotion (work level)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/PromWLCDual.gph", replace
graph export "$analysis/Results/4.Event/PromWLCDual.png", replace

* single differences 
coeff1, c(121) // program 

 tw connected bL et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Promotion (work level)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/PromWLCSingleLow.gph", replace
graph export "$analysis/Results/4.Event/PromWLCSingleLow.png", replace

 tw connected bH1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Promotion (work level)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/PromWLCSingleHigh.gph", replace
graph export "$analysis/Results/4.Event/PromWLCSingleHigh.png", replace

////////////////////////////////////////////////////////////////////////////////
* ChangeSalaryGradeC
////////////////////////////////////////////////////////////////////////////////
eststo: reghdfe ChangeSalaryGradeC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff, c(121) // program 

 tw connected b et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Promotion (salary)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ChangeSalaryGradeCDual.gph", replace
graph export "$analysis/Results/4.Event/ChangeSalaryGradeCDual.png", replace

* single differences 
coeff1, c(121) // program 

 tw connected bL1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Promotion (salary)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ChangeSalaryGradeCSingleLow.gph", replace
graph export "$analysis/Results/4.Event/ChangeSalaryGradeCSingleLow.png", replace

 tw connected bH1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Promotion (salary)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/ChangeSalaryGradeCSingleHigh.gph", replace
graph export "$analysis/Results/4.Event/ChangeSalaryGradeCSingleHigh.png", replace

////////////////////////////////////////////////////////////////////////////////
* TransferInternalSJC
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe TransferInternalSJC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff, c(121) // program 

 tw connected b et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJCDual.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJCDual.png", replace

* single differences 
coeff1, c(121) // program 

 tw connected bL et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJCSingleLow.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJCSingleLow.png", replace

 tw connected bH1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJCSingleHigh.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJCSingleHigh.png", replace

////////////////////////////////////////////////////////////////////////////////
* TransferInternalSJDiffMC
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe TransferInternalSJDiffMC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff, c(121) // program 

 tw connected b et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division, diff. manager", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJDiffMCDual.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJDiffMCDual.png", replace

* single differences 
coeff1, c(121) // program 

 tw connected bL1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division, diff. manager", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJDiffMCSingleLow.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJDiffMCSingleLow.png", replace

 tw connected bH1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division, diff. manager", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJDiffMCSingleHigh.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJDiffMCSingleHigh.png", replace

////////////////////////////////////////////////////////////////////////////////
* TransferInternalSJSameMC
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe TransferInternalSJSameMC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff, c(121) // program 

 tw connected b1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division, same manager", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJSameMCDual.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJSameMCDual.png", replace

* single differences 
coeff1, c(121) // program 

 tw connected bL1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division, same manager", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJSameMCSingleLow.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJSameMCSingleLow.png", replace

 tw connected bH1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division, same manager", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TransferInternalSJSameMCSingleHigh.gph", replace
graph export "$analysis/Results/4.Event/TransferInternalSJSameMCSingleHigh.png", replace

////////////////////////////////////////////////////////////////////////////////
* TimeInternalC  
////////////////////////////////////////////////////////////////////////////////

* Time in division
gen o=1 
bys IDlse TransferInternalC (YearMonth), sort: gen TimeInternalC = sum(o)
drop o 

eststo: reghdfe TimeInternalC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff, c(121) // program 

 tw connected b1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Number of months: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TimeInternalCTWFE.gph", replace
graph export "$analysis/Results/4.Event/TimeInternalCTWFE.png", replace

* single differences 
coeff1, c(121) // program 

 tw connected bL1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Number of months: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TimeInternalCSingleLowTWFE.gph", replace
graph export "$analysis/Results/4.Event/TimeInternalCSingleLowTWFE.png", replace

 tw connected bH1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Number of months: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TimeInternalCSingleHighTWFE.gph", replace
graph export "$analysis/Results/4.Event/TimeInternalCSingleHighTWFE.png", replace

////////////////////////////////////////////////////////////////////////////////
*  VPA 
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe VPA $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff, c(121) // program 

 tw connected b1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Performance Appraisals", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/VPATWFE.gph", replace
graph export "$analysis/Results/4.Event/VPATWFE.png", replace

* single differences 
coeff1, c(121)  // program 

 tw connected bL1 et1 if et1>-21 & et1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>-21 & et1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(6)20) ///
xtitle(Months since manager change) title("Performance Appraisals", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/VPAELHTWFE.gph", replace
graph export "$analysis/Results/4.Event/VPAELHTWFE.png", replace

 tw connected bH1 et1 if et1>-21 & et1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-21 & et1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(6)20) ///
xtitle(Months since manager change) title("Performance Appraisals", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/VPAEHLTWFE.gph", replace
graph export "$analysis/Results/4.Event/VPAEHLTWFE.png", replace


////////////////////////////////////////////////////////////////////////////////
*  TimeFuncC 
////////////////////////////////////////////////////////////////////////////////

* Time in function 
gen o =1 
bys IDlse TransferFuncC (YearMonth), sort : gen TimeFuncC = sum(o)
drop o 

eststo: reghdfe TimeFuncC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

* double differences 
coeff, c(121) // program 

 tw connected b1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Number of months: function", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TimeFuncCTWFE.gph", replace
graph export "$analysis/Results/4.Event/TimeFuncCTWFE.png", replace

* single differences 
coeff1, c(121) // program 

 tw connected bL1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Number of months: function", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TimeFuncCSingleLowTWFE.gph", replace
graph export "$analysis/Results/4.Event/TimeFuncCSingleLowTWFE.png", replace

 tw connected bH1 et1 if et1>-61 & et1<61, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-61 & et1<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Number of months: function", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TimeFuncCSingleHighTWFE.gph", replace
graph export "$analysis/Results/4.Event/TimeFuncCSingleHighTWFE.png", replace




