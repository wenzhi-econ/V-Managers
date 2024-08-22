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

* WL2 manager indicator 
bys IDlse: egen prewl = max(cond(KEi==-1 ,WLM,.))
bys IDlse: egen postwl = max(cond(KEi==0 ,WLM,.))
ge WL2 = prewl >1 & postwl>1 if prewl!=. & postwl!=.

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

* HETEROGENEITY BY SAME GENDER AND NATIONALITY 
foreach var in SameGender SameNationality{
	bys IDlse: egen `var'0 = mean(cond(KEi ==0,`var',.))
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
	gen L`l'`var'SameG = L`l'`var'*SameGender0
	gen L`l'`var'SameN = L`l'`var'*SameNationality0
	gen L`l'`var'Delta =  L`l'`var'*DeltaM
	gen L`l'`var'DeltaSameG =  L`l'`var'*DeltaM*SameGender0
	gen L`l'`var'DeltaSameN =  L`l'`var'*DeltaM*SameNationality0


}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
	gen F`l'`var'SameG = F`l'`var'*SameGender0
	gen F`l'`var'SameN = F`l'`var'*SameNationality0
	gen F`l'`var'Delta =  F`l'`var'*DeltaM
	gen F`l'`var'DeltaSameG =  F`l'`var'*DeltaM*SameGender0
	gen F`l'`var'DeltaSameN =  F`l'`var'*DeltaM*SameNationality0

}
}

* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in

* if binning 
foreach var in Ei {
forval i=20(10)`end'{
	gen endL`var'`i' = K`var'>`i' & K`var'!=.
	gen endL`var'`i'SameG =endL`var'`i'*SameGender0
	gen endL`var'`i'SameN =endL`var'`i'*SameNationality0
	
	gen endF`var'`i' = K`var'< -`i' & K`var'!=.
	gen endF`var'`i'SameG =endF`var'`i'*SameGender0
	gen endF`var'`i'SameN =endF`var'`i'*SameNationality0
	
	gen endL`var'`i'Delta = endL`var'`i'*DeltaM
	gen endL`var'`i'DeltaSameG =  endL`var'`i'*DeltaM*SameGender0
	gen endL`var'`i'DeltaSameN =  endL`var'`i'*DeltaM*SameNationality0
	
	gen endF`var'`i'Delta = endF`var'`i'*DeltaM
	gen endF`var'`i'DeltaSameG =  endF`var'`i'*DeltaM*SameGender0
	gen endF`var'`i'DeltaSameN =  endF`var'`i'*DeltaM*SameNationality0
}
}

* create list of event indicators if binning 
local end = 30 // to be plugged in 
eventdDelta, end(`end')
eventdDeltaHET, end(`end') het(SameG)
eventdDeltaHET, end(`end') het(SameN)


global Delta F*Delta L*Delta // no binning 
global Event F*Ei L*Ei // no binning
global DeltaExit L*Delta // no binning 
global EventExit  L*Ei // no binning

global Delta $FEiDelta $LEiDelta // binning  
global DeltaSameG $FEiDeltaSameG $LEiDeltaSameG // binning  
global DeltaSameN $FEiDeltaSameN $LEiDeltaSameN // binning  

global DeltaExit  $LExitEiDelta // binning  
global DeltaExitSameG  $LExitEiDeltaSameG // binning  
global DeltaExitSameN  $LExitEiDeltaSameN // binning  

global Event $FEi $LEi // binning
global EventSameG $FEiSameG $LEiSameG // binning
global EventSameN $FEiSameN $LEiSameN // binning

global EventExit $LExitEi // binning
global EventExitSameG $LExitEiSameG // binning
global EventExitSameN $LExitEiSameN // binning


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
local het SameG // SameN SameG requires MANUAL input 
foreach var in ChangeSalaryGradeC  {
local lab: variable label `var'
*eststo: ppmlhdfe   `var' $Delta $cont  , eform a( $abs $Event  ) vce(cluster IDlseMHR)
eststo `het': reghdfe   `var' $DeltaSameG $cont if  WL2==1 , a(  $abs $Event  $Delta  ) vce(cluster IDlseMHR) //  SameN SameG requires MANUAL input 
local d = `end'

local d = (`window' - 1)/2  // half window
local y = "`var'"
pretrendDeltaHET, c(`window') y(`y') het(`het')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDelta = round(r(mean), 0.001)

event_plot `het',  stub_lag(L#EiDelta`het') stub_lead(F#EiDelta`het') trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change", size(medsmall)) ytitle("Same Gender - Different Gender", size(medium)) xlabel(-`d'(2)`d') title("`lab'", span pos(12))  note("Pretrends p-value=`jointDelta'", size(medsmall)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/5.Mechanisms/`het'`Label'Delta`var'.gph", replace
graph export "$analysis/Results/5.Mechanisms/`het'`Label'Delta`var'.png", replace 
}

/* window lenght
local end = 30 // !PLUG! 
local window = 61 //  !PLUG! specify window - depends on outcome: window is 61 for all but 25 for salary and VPA and 21 for productivity
local Label $Label
foreach var in ChangeSalaryGradeC  {
local lab: variable label `var'
*eststo: ppmlhdfe   `var' $Delta $cont  , eform a( $abs $Event  ) vce(cluster IDlseMHR)
eststo SameGender0: reghdfe   `var' $Delta $cont  if SameGender0 ==0 , a(  $abs $Event  ) vce(cluster IDlseMHR) //   

eststo SameGender1: reghdfe   `var' $Delta  $cont if SameGender0 ==1, a(   $abs $Event  ) vce(cluster IDlseMHR) //   
local d = `end'
event_plot SameGender0 SameGender1,  stub_lag(L#EiDelta) stub_lead(F#EiDelta) trimlag(`d') trimlead(`d') graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`lab'", span pos(12)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(order(1 "Different Gender" 5 "Same Gender") region(style(none)) position(7) rows(1) ))    ciplottype(rcap)  noautolegend lag_opt1(msymbol(Dh) color(ebblue)) lag_ci_opt1(color(ebblue)) lead_opt1(msymbol(Dh) color(ebblue)) lead_ci_opt1(color(ebblue)) ///
lag_opt2(msymbol(O) color(dkorange)) lag_ci_opt2(color(dkorange)) lead_opt2(msymbol(O) color(dkorange)) lead_ci_opt2(color(dkorange))
graph save  "$analysis/Results/5.Mechanisms/SameG`Label'Delta`var'.gph", replace
graph export "$analysis/Results/5.Mechanisms/SameG`Label'Delta`var'.png", replace 

}

* window lenght
local end = 30 // !PLUG! 
local window = 61 //  !PLUG! specify window - depends on outcome: window is 61 for all but 25 for salary and VPA and 21 for productivity
local Label $Label
foreach var in ChangeSalaryGradeC  {
local lab: variable label `var'
*eststo: ppmlhdfe   `var' $Delta $cont  , eform a( $abs $Event  ) vce(cluster IDlseMHR)
eststo SameNat0: reghdfe   `var' $Delta $cont  if SameNationality0 ==0 , a(  $abs $Event  ) vce(cluster IDlseMHR) //   SameNationality

eststo SameNat1: reghdfe   `var' $Delta  $cont if SameNationality0 ==1, a(   $abs $Event  ) vce(cluster IDlseMHR) //   SameNationality

local d = `end'
event_plot SameNat0 SameNat1,  stub_lag(L#EiDelta) stub_lead(F#EiDelta) trimlag(`d') trimlead(`d') graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`lab'", span pos(12)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(order(1 "Different Nationality" 5 "Same Nationality") region(style(none)) position(7) rows(1) ))    ciplottype(rcap)  noautolegend lag_opt1(msymbol(Dh) color(ebblue)) lag_ci_opt1(color(ebblue)) lead_opt1(msymbol(Dh) color(ebblue)) lead_ci_opt1(color(ebblue)) ///
lag_opt2(msymbol(O) color(dkorange)) lag_ci_opt2(color(dkorange)) lead_opt2(msymbol(O) color(dkorange)) lead_ci_opt2(color(dkorange))
graph save  "$analysis/Results/5.Mechanisms/SameNat`Label'Delta`var'.gph", replace
graph export "$analysis/Results/5.Mechanisms/SameNat`Label'Delta`var'.png", replace 

}
