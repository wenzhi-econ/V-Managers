////////////////////////////////////////////////////////////////////////////////
* EVENT STUDY BALANCED SAMPLE 
////////////////////////////////////////////////////////////////////////////////

* 1) outcomes with 30 months window 
use  "$Managersdta/Switchers.dta", clear 

local end = 30 // to be plugged in 
local window = 61 // to be plugged in

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii

keep if ii==1

keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei EL EH ELH EHH ELL EHL KEi KELL KELH KEHH KEHL ///
Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ///
ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow ///
PromWLC   PromWLVC  ChangeSalaryGradeC ///
TransferInternalLLC TransferInternalVC TransferFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  ///
VPA  LogPayBonus 

* if binning 
foreach var in LL LH HL HH {
forval i=20(10)`end'{
	gen Lend`var'`i' = KE`var'>=`i' & KE`var'!=.
	gen Fend`var'`i' = KE`var'<= -`i' & KE`var'!=.
}
}

* create event coefficients 
eventd, end(`end')

***************************LABEL VARS*******************************************

label var ChangeSalaryGradeC "Prom. (salary)"
label var PromWLC "Prom. (work-level)"
label var PromWLVC "Prom., vertical (work-level)"
label var TransferInternalC "Transfer (sub-func)"
label var TransferInternalLLC "Transfer (sub-func), lateral"
label var TransferInternalVC "Transfer (sub-func), vertical"
label var TransferFuncC "Transfer (function)"

////////////////////////////////////////////////////////////////////////////////
* REGRESSIONS 
////////////////////////////////////////////////////////////////////////////////

egen CountryYear = group(Country Year)
*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM WLM IDlse  
global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

foreach  y in   PromWLVC TransferInternalC TransferInternalLLC TransferInternalVC TransferFuncC ChangeSalaryGradeC PromWLC{
eststo: reghdfe `y' $event $cont, a( $exitFE   ) vce(cluster IDlseMHR)
local lab: variable label `y'

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end')  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Switchers/`y'DualnoFE.gph", replace
graph export "$analysis/Results/4.Switchers/`y'DualnoFE.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Switchers/`y'ELHnoFE.gph", replace
graph export "$analysis/Results/4.Switchers/`y'ELHnoFE.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Switchers/`y'EHLnoFE.gph", replace
graph export "$analysis/Results/4.Switchers/`y'EHLnoFE.png", replace
}

////////////////////////////////////////////////////////////////////////////////
* 2) 12 months window 
////////////////////////////////////////////////////////////////////////////////

use  "$Managersdta/Switchers.dta", clear 

local end = 10 // to be plugged in 
local window = 21 // to be plugged in 

* BALANCED SAMPLE FOR OUTCOMES 12 WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end' & LogPayBonus!=.
ta ii

keep if ii==1

* Other outcomes 
gen VPA100 = VPA>=100 if VPA!=.
gen VPA115 = VPA>=115 if VPA!=.

keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei EL EH ELH EHH ELL EHL KEi KELL KELH KEHH KEHL ///
Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ///
ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow ///
PromWLC   PromWLVC  ChangeSalaryGradeC ///
TransferInternalLLC TransferInternalVC TransferFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  ///
VPA  VPA125 VPA100 VPA115 LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen Lend`var'`end' = KE`var'>=`end'  & KE`var'!=.
	gen Fend`var'`end'  = KE`var'<= -`end'  & KE`var'!=.
}

eventd, end(`end')

***************************LABEL VARS*******************************************

label var ChangeSalaryGradeC "Prom. (salary)"
label var PromWLC "Prom. (work-level)"
label var PromWLVC "Prom., vertical (work-level)"
label var TransferInternalC "Transfer (sub-func)"
label var TransferInternalLLC "Transfer (sub-func), lateral"
label var TransferInternalVC "Transfer (sub-func), vertical"
label var TransferFuncC "Transfer (function)"
label var LogPayBonus "Pay + bonus (logs)"
label var VPA "Perf. Appraisals"
label var VPA100 "Perf. Appraisals>=100"
label var VPA115 "Perf. Appraisals>=115"
label var VPA125 "Perf. Appraisals>=125"

////////////////////////////////////////////////////////////////////////////////
* REGRESSIONS 
////////////////////////////////////////////////////////////////////////////////

egen CountryYear = group(Country Year)
*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM WLM IDlse  
global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female
global absnoFE CountryYear AgeBand AgeBandM   WLM  Func Female  

* WITHOUT EMPLOYEE FE 

local end = 10 // to be plugged in 
local window = 21 // to be plugged in 

foreach  y in   LogPayBonus VPA VPA100 VPA115 VPA125 {
eststo: reghdfe `y' $event $cont, a( $exitFE   ) vce(cluster IDlseMHR)
local lab: variable label `y'

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end')  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Switchers/`y'DualnoFE.gph", replace
graph export "$analysis/Results/4.Switchers/`y'DualnoFE.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(`end'(2)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Switchers/`y'ELHnoFE.gph", replace
graph export "$analysis/Results/4.Switchers/`y'ELHnoFE.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Switchers/`y'EHLnoFE.gph", replace
graph export "$analysis/Results/4.Switchers/`y'EHLnoFE.png", replace
}
