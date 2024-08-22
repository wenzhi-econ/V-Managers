********************************************************************************
* EVENT STUDY BALANCED SAMPLE 
* FE model 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label PromSG75

////////////////////////////////////////////////////////////////////////////////
* 1) 30 months window 
////////////////////////////////////////////////////////////////////////////////

use "$Managersdta/SwitchersAllSameTeam.dta", clear 

* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii
keep if ii==1

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
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

* selecting only needed variables 
*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* if binning 
foreach var in LL LH HL HH {
forval i=20(10)`end'{
	gen Lend`var'`i' = KE`var'>`i' & KE`var'!=.
	gen Fend`var'`i' = KE`var'< -`i' & KE`var'!=.
}
}

* create list of event indicators if binning 
eventd, end(`end')

********************************* REGRESSIONS **********************************

* LABEL VARS
label var ChangeSalaryGradeC "Prom. (salary)"
label var PromWLC "Prom. (work-level)"
label var PromWLVC "Prom., vertical (work-level)"
label var TransferInternalC "Transfer (sub-func)"
label var TransferInternalLLC "Transfer (sub-func), lateral"
label var TransferInternalVC "Transfer (sub-func), vertical"
label var TransferSJC "Job Transfer"
label var TransferSJLLC "Job Transfer, lateral"
label var TransferSJVC "Job Transfer, vertical"
label var TransferFuncC "Transfer (function)"
label var TransferSubFuncC "Transfer (sub-function)"

egen CountryYear = group(Country Year)
*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM WLM IDlse  
global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

foreach  y in PromWLC TransferInternalC TransferFuncC TransferSJC TransferInternalLLC TransferInternalVC  ChangeSalaryGradeC    PromWLVC{
eststo: reghdfe `y' $event $cont, a( $abs   ) vce(cluster IDlseMHR)
local lab: variable label `y'

* Mean at -1
cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/Balance/`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/4.Event/Balance/`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/4.Event/Balance/`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'EHL.png", replace
}

////////////////////////////////////////////////////////////////////////////////
* 2) 12 months window - PAY
////////////////////////////////////////////////////////////////////////////////

use "$Managersdta/SwitchersAllSameTeam.dta", clear 

keep if LogPayBonus!=.

local end = 12 // to be plugged in 
local window = 25 // to be plugged in 

* BALANCED SAMPLE FOR OUTCOMES 12 WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'  
ta ii

keep if ii==1

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

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

*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen Lend`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen Fend`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
eventd, end(`end')

********************************* REGRESSIONS **********************************

*LABEL VARS
label var LogPayBonus "Pay + bonus (logs)"

egen CountryYear = group(Country Year)
*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM WLM IDlse  
global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

foreach  y in   LogPayBonus {
eststo: reghdfe `y' $event $cont, a( $abs   ) vce(cluster IDlseMHR)
local lab: variable label `y'

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/Balance/`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/4.Event/Balance/`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/4.Event/Balance/`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'EHL.png", replace
}

////////////////////////////////////////////////////////////////////////////////
* 3) 12 months window - VPA
////////////////////////////////////////////////////////////////////////////////

use "$Managersdta/SwitchersAllSameTeam.dta", clear 

keep if VPA!=.

local end = 12 // to be plugged in 
local window = 25 // to be plugged in 

* BALANCED SAMPLE FOR OUTCOMES 12 WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'  
ta ii

keep if ii==1

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

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
* Other outcomes 
gen VPA100 = VPA>=100 if VPA!=.
gen VPA115 = VPA>=115 if VPA!=.

*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen Lend`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen Fend`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
eventd, end(`end')

********************************* REGRESSIONS **********************************

*LABEL VARS
label var VPA "Perf. Appraisals"
label var VPA100 "Perf. Appraisals>=100"
label var VPA115 "Perf. Appraisals>=115"
label var VPA125 "Perf. Appraisals>=125"

egen CountryYear = group(Country Year)
*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM WLM IDlse  
global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

foreach  y in VPA VPA100 VPA115 VPA125 {
eststo: reghdfe `y' $event $cont, a( $abs   ) vce(cluster IDlseMHR)
local lab: variable label `y'

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/Balance/`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/4.Event/Balance/`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/4.Event/Balance/`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'EHL.png", replace
}

///////////////////////////////////////////////////////////////////////////////
* EXIT
///////////////////////////////////////////////////////////////////////////////

use "$Managersdta/SwitchersAllSameTeam.dta", clear 

local end = 30 // to be plugged in 
local window = 61 // to be plugged in

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

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

*************************** REGRESSIONS ***************************************

*LABEL VARS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"

egen CountryYear = group(Country Year)
*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH // binning 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM WLM IDlse  
global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

local window = 61 // to be plugged in
local end = 30 // to be plugged in 

foreach  y in  LeaverPerm LeaverVol LeaverInv {
eststo: reghdfe `y' $event $cont, a( $exitFE   ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeffExit, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.01)

 tw connected b1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(0(3)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/Balance/`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'Dual.png", replace

* single differences 
coeffExit1, c(`window') y(`y') // program 

 tw connected bL1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(0(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/Balance/`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'ELH.png", replace

 tw connected bH1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(0(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/Balance/`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/Balance/`y'EHL.png", replace
} 

