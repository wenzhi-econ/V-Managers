********************************************************************************
* EVENT STUDY - SYMMETRIC  
* TWFE model and Poisson 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse    // alternative, to try 
global exitFE CountryYear AgeBand AgeBandM Func Female

use "$managersdta/SwitchersAllSameTeam.dta", clear 
*merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
*drop if _merge ==2 
*drop _merge 

* odd or even Manager id for placebo events 
*gen odd = mod(IDlseMHR,2) 
gen odd = mod(ManagerNum,2) 

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-(`end') &  maxEi >=(`end') & Ei!=.
ta ii
keep if ii==1 // MANUAL INPUT - to remove if irrelevant

* Delta 
xtset IDlse YearMonth 
foreach var in odd EarlyAgeM MFEBayesPromSG75{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
}

* only keep relevant switchers 
keep if DeltaM$MType!=. 

* merge with random sample 
merge m:1 IDlse using "$managersdta/Temp/Random50.dta", keepusing(random50)
drop if _merge ==2 
drop _merge
*keep if random50==1

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
* Poisson 
////////////////////////////////////////////////////////////////////////////////

* LABEL VARS
global Poisson PromWLC ChangeSalaryGradeC TransferInternalC TransferFuncC ONETDistanceBC TransferSJC TransferInternalLLC TransferInternalVC  PromWLVC 
*global Poisson ChangeMC TransferInternalC TransferSJC  TransferInternalLLC TransferFuncC  

label var ChangeSalaryGradeC "Prom. (salary)"
label var ChangeSalaryGradeVC "Prom. (salary), vertical"
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
lab var ChangeMC "Transfer (team)"

* window lenght
local end = 30 // !PLUG! 
local window = 61 //  !PLUG! specify window - depends on outcome: window is 61 for all but 25 for salary and VPA and 21 for productivity
local Label $Label
foreach var in PromWLC $Poisson  {
local lab: variable label `var'
*eststo: ppmlhdfe   `var' $Delta $cont  , eform a( $abs $Event  ) vce(cluster IDlseMHR)
eststo: reghdfe   `var' $Delta $cont  , a(  $abs $Event  ) vce(cluster IDlseMHR)

local d = (`window' - 1)/2  // half window
local y = "`var'"
pretrendDelta, c(`window') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDelta = round(r(mean), 0.001)
  
event_plot,  stub_lag(L#EiDelta) stub_lead(F#EiDelta) trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`lab'", span pos(12))  note("Pretrends p-value=`jointDelta'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/`Label'Delta`var'.gph", replace
graph export "$analysis/Results/4.Event/`Label'Delta`var'.png", replace 
}

////////////////////////////////////////////////////////////////////////////////
* SALARY AND VPA: 24 months window 
////////////////////////////////////////////////////////////////////////////////

gen VPA100 = VPA>=100 if VPA!=.
gen VPA115 = VPA>=115 if VPA!=.

global perf LogPayBonus  VPA VPA100 VPA115 VPA125 ProductivityStd

*LABEL VARS
label var LogPayBonus "Pay + bonus (logs)"
label var VPA "Perf. Appraisals"
label var VPA100 "Perf. Appraisals>=100"
label var VPA115 "Perf. Appraisals>=115"
label var VPA125 "Perf. Appraisals>=125"
label var ProductivityStd "Productivity (standardized)"

local window = 25 // !PLUG! specify window - depends on outcome:  window is 61 for all but 25 for salary and VPA and 21 for productivity
local Label $Label
foreach var in $perf  {
local lab: variable label `var'

eststo: reghdfe `var' $Delta $cont , a( $abs $Event  ) vce(cluster IDlseMHR)

local d = (`window' - 1)/2  // half window
local y = "`var'"
pretrendDelta, c(`window') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDelta = round(r(mean), 0.001)
  
event_plot,  stub_lag(L#EiDelta) stub_lead(F#EiDelta) trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`lab'", span pos(12))  note("Pretrends p-value=`jointDelta'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/`Label'Delta`var'.gph", replace
graph export "$analysis/Results/4.Event/`Label'Delta`var'.png", replace 
}

////////////////////////////////////////////////////////////////////////////////
* Exit: 30 months window 
////////////////////////////////////////////////////////////////////////////////

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT MFEBayesPromSG
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse    // alternative, to try 
global exitFE Country YearMonth AgeBand AgeBandM Func Female

use "$managersdta/SwitchersAllSameTeam.dta", clear 
*merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
*drop if _merge ==2 
*drop _merge 

* odd or even Manager id for placebo events 
*gen odd = mod(IDlseMHR,2) 
gen odd = mod(ManagerNum,2) 

egen CountryYear = group(Country Year)

* Delta 
xtset IDlse YearMonth 
foreach var in odd EarlyAgeM MFEBayesPromSG75{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
}

* only keep relevant switchers 
keep if DeltaM$MType!=. 

* merge with random sample 
merge m:1 IDlse using "$managersdta/Temp/Random50.dta", keepusing(random50)
drop if _merge ==2 
drop _merge
*keep if random50==1

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

*LABEL VARS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"

local window = 61 // to be plugged in
local end = 30 // to be plugged in 
local Label $Label
foreach  y in  LeaverPerm LeaverVol LeaverInv {
eststo: reghdfe `y' $DeltaExit $cont, a( $exitFE  $EventExit ) vce(cluster IDlseMHR)
local lab: variable label `y'

local d = (`window' - 1)/2  // half window

event_plot,  stub_lag(L#EiDelta)  trimlag(`d')  lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(0(2)`d') title("`lab'", span pos(12))  yline(0, lcolor(maroon) lpattern(solid) ) xline(0, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/`Label'Delta`y'.gph", replace
graph export "$analysis/Results/4.Event/`Label'Delta`y'.png", replace 
   
}

