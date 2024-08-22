********************************************************************************
* EVENT STUDY - SYMMETRIC - HETEROGENEITY ANALYSIS - baseline pay/performance
* TWFE model and Poisson 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label  FT // odd FT MFEBayesPromSG
global MType EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse  AgeBand AgeBandM WLM  // alternative, to try 
global exitFE Country YearMonth AgeBand AgeBandM WLM Func Female

use "$managersdta/SwitchersAllSameTeam.dta", clear 
*merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
*drop if _merge ==2 
*drop _merge 

* WL2 manager indicator 
bys IDlse: egen prewl = max(cond(KEi==-1 ,WLM,.))
bys IDlse: egen postwl = max(cond(KEi==0 ,WLM,.))
ge WL2 = prewl >1 & postwl>1 if prewl!=. & postwl!=.

* odd or even Manager id for placebo events 
*gen odd = mod(IDlseMHR,2) 
gen odd = mod(ManagerNum,2) 

/* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-(`end') &  maxEi >=(`end') & Ei!=.
ta ii
keep if ii==1 // MANUAL INPUT - to remove if irrelevant
*/

* Delta 
xtset IDlse YearMonth 
foreach var in odd EarlyAgeM MFEBayesPromSG75{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
}

* only keep relevant switchers 
keep if DeltaM$MType !=. 

* choose relevant delta 
rename DeltaM$MType DeltaM 

* create leads and lags 
foreach var in Ei {

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
	gen L`l'`var'Delta =  L`l'`var'*DeltaM

}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
	gen F`l'`var'Delta =  F`l'`var'*DeltaM

}
}

* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in

* if binning 
foreach var in Ei {
forval i=20(10)`end'{
	gen endL`var'`i' = K`var'>`i' & K`var'!=.
	gen endF`var'`i' = K`var'< -`i' & K`var'!=.
	gen endL`var'`i'Delta = endL`var'`i'*DeltaM
	gen endF`var'`i'Delta = endF`var'`i'*DeltaM
}
}

* create list of event indicators if binning 
local end = 30 // to be plugged in 
eventdDelta, end(`end')

global Delta F*Delta L*Delta // no binning 
global Event F*Ei L*Ei // no binning
global DeltaExit L*Delta // no binning 
global EventExit  L*Ei // no binning

global Delta $FEiDelta $LEiDelta // binning  
global Event $FEi $LEi // binning
global DeltaExit  $LExitEiDelta // binning  
global EventExit $LExitEi // binning

////////////////////////////////////////////////////////////////////////////////
* HETEROGENEITY  
////////////////////////////////////////////////////////////////////////////////

xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus
bys IDlse : egen PayGrowth0 = mean(cond(F6Ei==1 | F7Ei==1 | F8Ei==1 | F9Ei==1 | F10Ei==1 | F11Ei==1 | F12Ei==1 | F13Ei==1  | F14Ei==1  | F15Ei==1  | F16Ei==1 | F17Ei==1 | F18Ei==1 | F19Ei==1  | F20Ei==1 | F21Ei==1 | F22Ei==1 | F23Ei==1 | F24Ei==1,PayGrowth ,.)) // mean 6-24 months before meeting new manager 
bys IDlse : egen PayGrowthMean = mean(PayGrowth)
replace PayGrowth0 = PayGrowthMean if Ei==. // replace with overall mean if worker never experiences a manager change

su PayGrowth0 ,d 
gen PayGrowth_Low = PayGrowth0 <=0 
gen PayGrowth_High = PayGrowth0 > 0 if PayGrowth0 !=.
gen PayGrowth0B = PayGrowth0 > 0 if PayGrowth0 !=.

keep if PayGrowth0!=.

////////////////////////////////////////////////////////////////////////////////
* Exit: 30 months window 
////////////////////////////////////////////////////////////////////////////////

cap drop L0Ei L0EiDelta 
 
*LABEL VARS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"

local window = 61 // to be plugged in
local end = 30 // to be plugged in 
local Label $Label
foreach  var in  LeaverPerm  LeaverVol LeaverInv { 
eststo elow: reghdfe `var' $DeltaExit $cont if PayGrowth0B==0 & WL2==1 & (FTLL!=. | FTLH!=.), a( $exitFE  $EventExit ) vce(cluster IDlseMHR)
eststo ehigh: reghdfe `var' $DeltaExit $cont if PayGrowth0B==1 & WL2==1 & (FTLL!=. | FTLH!=.), a( $exitFE  $EventExit ) vce(cluster IDlseMHR)

local lab: variable label `var'

local d = (`window' - 1)/2  // half window
local y = "`var'"
 
event_plot elow ehigh,  stub_lag(L#EiDelta)  trimlag(`d')    ///
graph_opt(scheme(white_tableau) ///
xtitle("Months since manager change") ytitle("") xlabel(0(2)`d') ylabel(-0.01(0.005)0.01) ///
title("`lab'", span pos(12))  yline(0, lcolor(maroon) lpattern(dash) ) xline(0, lcolor(black) ///
lpattern(dash)) legend(order(1 "Low Baseline Pay Growth" 3 "High Baseline Pay Growth") region(style(none)) position(7) rows(1) )  ) ///
ciplottype(rcap) noautolegend 	lag_opt1(msymbol(Dh) color(ebblue)) lag_ci_opt1(color(ebblue)) ///
lag_opt2(msymbol(O) color(cranberry)) lag_ci_opt2(color(cranberry)) 
 
graph save  "$analysis/Results/5.Mechanisms/PayHet`Label'LH`var'.gph", replace
graph export "$analysis/Results/5.Mechanisms/PayHet`Label'LH`var'.png", replace 

eststo elow: reghdfe `var' $DeltaExit $cont if PayGrowth0B==0 & WL2==1 & (FTHL!=. | FTHH!=.), a( $exitFE  $EventExit ) vce(cluster IDlseMHR)
eststo ehigh: reghdfe `var' $DeltaExit $cont if PayGrowth0B==1 & WL2==1 & (FTHL!=. | FTHH!=.), a( $exitFE  $EventExit ) vce(cluster IDlseMHR)

local lab: variable label `var'

local d = (`window' - 1)/2  // half window
local y = "`var'"
 
event_plot elow ehigh,  stub_lag(L#EiDelta)  trimlag(`d')    ///
graph_opt(scheme(white_tableau) ///
xtitle("Months since manager change") ytitle("") xlabel(0(2)`d') ylabel(-0.01(0.005)0.01) ///
title("`lab'", span pos(12))  yline(0, lcolor(maroon) lpattern(dash) ) xline(0, lcolor(black) ///
lpattern(dash)) legend(order(1 "Low Baseline Pay Growth" 3 "High Baseline Pay Growth") region(style(none)) position(7) rows(1) )  ) ///
ciplottype(rcap) noautolegend 	lag_opt1(msymbol(Dh) color(ebblue)) lag_ci_opt1(color(ebblue)) ///
lag_opt2(msymbol(O) color(cranberry)) lag_ci_opt2(color(cranberry)) 
 
graph save  "$analysis/Results/5.Mechanisms/PayHet`Label'HL`var'.gph", replace
graph export "$analysis/Results/5.Mechanisms/PayHet`Label'HL`var'.png", replace 
}
