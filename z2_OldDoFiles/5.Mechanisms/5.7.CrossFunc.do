********************************************************************************
* EVENT STUDY 
* WAGE INCREASES AFTER TRANSFER: separately by whether workers changed subfunction 
* TO UNDERSTAND THE IMPORTANCE OF THE MATCHING CHANNEL 
* FE model 
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

* WL2 manager indicator 
bys IDlse: egen prewl = max(cond(KEi==-1 ,WLM,.))
bys IDlse: egen postwl = max(cond(KEi==0 ,WLM,.))
ge WL2 = prewl >1 & postwl>1 if prewl!=. & postwl!=.

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

* ACROSS SUBFUNCTION AND FUNCTION 
bys IDlse: egen SubFuncPost = mean(cond(KEi ==30, SubFunc,.)) 
bys IDlse: egen SubFuncPre = mean(cond(KEi ==-1, SubFunc,.)) 
gen DiffSF = SubFuncPost!= SubFuncPre if SubFuncPost!=. & SubFuncPre!=. // 27% change SF 

* only keep relevant switchers 
keep if DeltaM$MType!=. 

/* merge with random sample 
merge m:1 IDlse using "$managersdta/Temp/Random50.dta", keepusing(random50)
drop if _merge ==2 
drop _merge
*keep if random50==1
**/

* choose relevant delta 
rename DeltaM$MType DeltaM 

* create leads and lags 
foreach var in Ei {

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
	gen L`l'`var'DiffSF = L`l'`var'*DiffSF
	gen L`l'`var'Delta =  L`l'`var'*DeltaM
	gen L`l'`var'DeltaDiffSF =  L`l'`var'*DeltaM*DiffSF


}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
	gen F`l'`var'DiffSF = F`l'`var'*DiffSF
	gen F`l'`var'Delta =  F`l'`var'*DeltaM
	gen F`l'`var'DeltaDiffSF =  F`l'`var'*DeltaM*DiffSF

}
}

* window lenght
local endL = 60 // to be plugged in 
local endF = 30 // to be plugged in 

* if binning 
foreach var in Ei {
forval i=12(2)`endF'{
	
	gen endF`var'`i' = K`var'< -`i' & K`var'!=.
	gen endF`var'`i'DiffSF =endF`var'`i'*DiffSF
	
	gen endF`var'`i'Delta = endF`var'`i'*DeltaM
	gen endF`var'`i'DeltaDiffSF =  endF`var'`i'*DeltaM*DiffSF
}
}

foreach var in Ei {
forval i=20(10)`endL'{
	gen endL`var'`i' = K`var'>`i' & K`var'!=.
	gen endL`var'`i'DiffSF =endL`var'`i'*DiffSF

	gen endL`var'`i'Delta = endL`var'`i'*DeltaM
	gen endL`var'`i'DeltaDiffSF =  endL`var'`i'*DeltaM*DiffSF
}
}

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
label var LogPayBonus "Pay + bonus (logs)"

* create list of event indicators if binning 
local endL = 30 // to be plugged in 
local endF = 30 // to be plugged in 

eventdDeltaW, endL(`endL') endF(`endF')
eventdDeltaHETW, endL(`endL') endF(`endF') het(DiffSF)

global Delta F*Delta L*Delta // no binning 
global Event F*Ei L*Ei // no binning
global DeltaExit L*Delta // no binning 
global EventExit  L*Ei // no binning

global Delta $FEiDelta $LEiDelta // binning  
global DeltaDiffSF $FEiDeltaDiffSF $LEiDeltaDiffSF // binning  

global DeltaExit  $LExitEiDelta // binning  
global DeltaExitDiffSF  $LExitEiDeltaDiffSF // binning  

global Event $FEi $LEi // binning
global EventDiffSF $FEiDiffSF $LEiDiffSF // binning

global EventExit $LExitEi // binning
global EventExitDiffSF $LExitEiDiffSF // binning

* Locals
local endL = 30 // to be plugged in: 60 for Prom WL
local endF = 30 // to be plugged in: 12 for Prom WL
local Label $Label
local het DiffSF 
  
foreach var in  ChangeSalaryGradeC { // PromWLC ChangeSalaryGradeC 
local lab: variable label `var'
*eststo: ppmlhdfe   `var' $Delta $cont  , eform a( $abs $Event  ) vce(cluster IDlseMHR)
eststo `het'`var': reghdfe   `var' $Delta $DeltaDiffSF $cont if WL2==1 & (FTLL!=. | FTLH!=.) , a(  $abs $Event  ) vce(cluster IDlseMHR) // DiffSF requires MANUAL input 
eststo `het'`var'1
 
local y = "`var'"
pretrendDeltaHETW, c(`endF') y(`y') het(`het')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDelta = round(r(mean), 0.001)
su jointH
local jointDeltaH = round(r(mean), 0.001)

* Low baseline 
cap drop ymeanF1L
su `y' if KEi == -1 &  (`Label'LL!=. | `Label'LH!=.)  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.01)

event_plot `het'`var' `het'`var'1,  stub_lag(L#EiDelta L#EiDelta`het') stub_lead(F#EiDelta F#EiDelta`het') trimlag(`endL') trimlead(`endF') lead_ci_opt1(lcolor(ebblue))   lag_ci_opt1(lcolor(ebblue)) lag_opt1(lcolor(ebblue)  mcolor(ebblue)) lead_opt1(lcolor(ebblue)  mcolor(ebblue)) lead_ci_opt2(lcolor(cranberry))   lag_ci_opt2(lcolor(cranberry)) lag_opt2(lcolor(cranberry)  mcolor(cranberry)) lead_opt2(lcolor(cranberry)  mcolor(cranberry)) graph_opt(scheme(white_tableau) xtitle("Months since manager change", size(medsmall)) ytitle("`lab'", size(medium)) xlabel(-`endF'(3)`endL') title("`lab'", span pos(12))  note("Pretrends p-value=`jointDelta' (same subfunc) and  p-value=`jointDeltaH' (diff. subfunc) ", size(medsmall)) ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) yline(0, lcolor(black) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(order(1 "Same subfunction" 5 "Different subfunction") rows(1) position(1) region(style(none)))  )    ciplottype(rcap) 
graph save  "$analysis/Results/5.Mechanisms/`het'`Label'LH`var'.gph", replace
graph export "$analysis/Results/5.Mechanisms/`het'`Label'LH`var'.png", replace 

event_plot `het'`var',  stub_lag(L#EiDelta`het') stub_lead(F#EiDelta`het') trimlag(`endL') trimlead(`endF') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change", size(medsmall)) ytitle("Different subfunction - same subfunction ", size(medium)) xlabel(-`endF'(3)`endL') title("`lab'", span pos(12))  note("Pretrends p-value=`jointDeltaH'", size(medsmall)) ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) yline(0, lcolor(black) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/5.Mechanisms/`het'Diff`Label'LH`var'.gph", replace
graph export "$analysis/Results/5.Mechanisms/`het'Diff`Label'LH`var'.png", replace

event_plot `het'`var',  stub_lag(L#EiDelta) stub_lead(F#EiDelta) trimlag(`endL') trimlead(`endF') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change", size(medsmall)) ytitle("Same subfunction", size(medium)) xlabel(-`endF'(3)`endL') title("`lab'", span pos(12))  note("Pretrends p-value=`jointDelta'", size(medsmall)) ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(black) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/5.Mechanisms/`het'Same`Label'LH`var'.gph", replace
graph export "$analysis/Results/5.Mechanisms/`het'Same`Label'LH`var'.png", replace 

}


