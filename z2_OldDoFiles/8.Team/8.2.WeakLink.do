********************************************************************************
* EVENT STUDY - WEAKEST LINK - HOW IS THE LOWEST PERFORMER DOING AFTER EXPOSED TO TALENTED MANAGERS 
* FE model 
********************************************************************************

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType EarlyAgeM   // odd EarlyAgeM MFEBayesPromSG75

local Label $Label

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global absFT YearMonth IDlse AgeBand AgeBandM WLM // for FT MType 
global absPromSG75  YearMonth IDlse // for PromSG75 
global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

use "$managersdta/SwitchersAllSameTeam2.dta", clear 

egen CountryYear = group(Country Year)

* odd or even Manager id for placebo events 
*gen odd = mod(IDlseMHR,2) 
gen odd = mod(ManagerNum,2) 

local end = 40 // to be plugged in 12
local window = 81 // to be plugged in 25

* identify the lowest performer: lowest VPA or lowest pay growth/pay in the two previous years 
********************************************************************************

xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus 
foreach var in VPA PayGrowth LogPayBonus {
	bys IDlse: egen `var'0 = mean(cond(KEi<=-1 & KEi >=-24, `var' , .))
	bys IDlseMHR YearMonth: egen min`var'0 = min(cond( KEi == 0 , `var' , .) )
	bys IDlse: egen weak`var' = max(cond (`var'0 == min`var'0 & `var'0 !=. & KEi==0 , 1, 0) ) 
}

keep if weakVPA ==1 | weakPayGrowth==1 | weakLogPayBonus ==1 // lowest performers at baseline 

* BALANCED SAMPLE FOR OUTCOMES WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii
*keep if ii==1

********************************************************************************
* Symmetric 
******************************************************************************** 

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
local end = 40 // to be plugged in 
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
local end = 40 // to be plugged in 
eventdDelta, end(`end')

global Delta F*Delta L*Delta // no binning 
global Event F*Ei L*Ei // no binning
global DeltaExit L*Delta // no binning 
global EventExit  L*Ei // no binning

global Delta $FEiDelta $LEiDelta // binning  
global Event $FEi $LEi // binning
global DeltaExit  $LExitEiDelta // binning  
global EventExit $LExitEi // binning

local window = 61 // !PLUG! specify window - depends on outcome:  window is 61 for all but 25 for salary and VPA and 21 for productivity

local Label $Label
label var TransferSJC "Number of job changes"
label var TransferInternalC "Number of transfers"
label var LogPayBonus "Pay growth"
foreach y in  TransferInternalC TransferSJC LogPayBonus { // 
local lab: variable label `y'

eststo: reghdfe `y' $Delta $cont if weakPayGrowth ==1, a( $absFT  $Event  ) vce(cluster IDlseMHR) // $abs`Label'

local d = (`window' - 1)/2  // half window
pretrendDelta, c(`window') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDelta = round(r(mean), 0.001)

/*  
event_plot,  stub_lag(L#EiDelta) stub_lead(F#EiDelta) trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`z'", span pos(12))  note("Pretrends p-value=`jointDelta'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 

graph save  "$analysis/Results/4.Event/WeakLink/`Label'`y'Delta.gph", replace
graph export "$analysis/Results/4.Event/WeakLink/`Label'`y'Delta.png", replace
*/
********************************************************************************
* Overall change in salary for lowest performer 
* Looking at the wages 1/2/3 years past the manager 
* Report the post period average:  By taking a simple average of the post-period coefficients, I do not have to assume a parametric form for the effects
*﻿ I report the three average treatment effects because I expect there to be a performance lag and, thus, the effects should increase over time. 
********************************************************************************

local Label $Label

* Year 1/2/3
xlincom  (( (L1EiDelta) +  (L2EiDelta) + (L3EiDelta) + (L4EiDelta) + (L5EiDelta) + (L6EiDelta) + (L7EiDelta) + (L8EiDelta) + (L9EiDelta) + (L10EiDelta) + (L11EiDelta) + (L12EiDelta) )/12) ///
(( (L13EiDelta) + (L14EiDelta) + (L15EiDelta)+ (L16EiDelta)+ (L17EiDelta)+ (L18EiDelta) + (L19EiDelta) + (L20EiDelta) + (L21EiDelta) + (L22EiDelta) + (L23EiDelta) + (L24EiDelta))/12) ///
(( (L25EiDelta) + (L26EiDelta) + (L27EiDelta)+ (L28EiDelta)+ (L29EiDelta)+ (L30EiDelta) + (L31EiDelta) + (L32EiDelta) + (L33EiDelta) + (L34EiDelta) + (L35EiDelta) + (L36EiDelta) )/12) ///
 , level(90) post

est store  weak
* note: weakPayGrowth works for FT, weakVPA works for PromSG75
* Symmetric  
coefplot  (weak, keep(lc_1) rename(  lc_1  = "Year 1"))  (weak, keep(lc_2) rename( lc_2 = "Year 2" )) (weak, keep(lc_3) rename( lc_3 = "Year 3" )) , ciopts(recast(rcap)) legend(off) title("`lab' for the lowest performer at baseline")   recast(bar ) vertical note("Notes. Reporting a simple average for the post-transition coefficients in an event-study regression" "for the worker with the lowest performance appraisals in the team in the two years before the transition. ", span) level(90)
graph export "$analysis/Results/8.Team/`Label'Weak`y'Delta.png", replace 
graph save "$analysis/Results/8.Team/`Label'Weak`y'Delta.gph", replace    

}

********************************************************************************
* Asymmetric 
******************************************************************************** 

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM   // odd EarlyAgeM MFEBayesPromSG75

local Label $Label

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

local end = 40 // to be plugged in 12
local window = 81 // to be plugged in 25

* Bin the event window 
foreach var in LL LH HL HH {
	gen endL`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen endF`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
local end = 40 // to be plugged in 12
local window = 81 // to be plugged in 25

eventd, end(`end')

********************************* REGRESSIONS **********************************

local end = 40 // to be plugged in 12
local window = 81 // to be plugged in 25

global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local Label $Label
*LABEL VARS
label var TransferSJC "Number of job changes"
label var TransferInternalC "Number of transfers"
label var LogPayBonus "Pay growth"
foreach y in TransferSJC TransferInternalC LogPayBonus {
	
eststo: reghdfe `y' $event $cont  if weakPayGrowth==1, a(   $absFT ) vce(cluster IDlseMHR) // $abs`Label'
local lab: variable label `y'

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)

/* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/WeakLink/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/WeakLink/`Label'`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/4.Event/WeakLink/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/WeakLink/`Label'`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/4.Event/WeakLink/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/WeakLink/`Label'`y'EHL.png", replace
*/
********************************************************************************
* Overall change in salary for lowest performer 
* Looking at the wages 1/2/3 years past the manager 
* Report the post period average:  By taking a simple average of the post-period coefficients, I do not have to assume a parametric form for the effects
*﻿ I report the three average treatment effects because I expect there to be a performance lag and, thus, the effects should increase over time. 
********************************************************************************

local Label $Label

* Year 1/2/3
xlincom  (( (L1ELH - L1ELL) +  (L2ELH - L2ELL) + (L3ELH - L3ELL) + (L4ELH - L4ELL) + (L5ELH - L5ELL) + (L6ELH - L6ELL) + (L7ELH - L7ELL) + (L8ELH - L8ELL) + (L9ELH - L9ELL) + (L10ELH - L10ELL) + (L11ELH - L11ELL) + (L12ELH - L12ELL) )/12) ///
 ( ( (L1EHL - L1EHH) +  (L2EHL - L2EHH) + (L3EHL - L3EHH) + (L4EHL - L4EHH) + (L5EHL - L5EHH) + (L6EHL - L6EHH) + (L7EHL - L7EHH) + (L8EHL - L8EHH) + (L9EHL - L9EHH) + (L10EHL - L10EHH) + (L11EHL - L11EHH) + (L12EHL - L12EHH) )/12) ///
(( (L13ELH - L13ELL) + (L14ELH - L14ELL) + (L15ELH - L15ELL)+ (L16ELH - L16ELL)+ (L17ELH - L17ELL)+ (L18ELH - L18ELL) + (L19ELH - L19ELL) + (L20ELH - L20ELL) + (L21ELH - L21ELL) + (L22ELH - L22ELL) + (L23ELH - L23ELL) + (L24ELH - L24ELL))/12) ///
( ( (L13EHL - L13EHH) + (L14EHL - L14EHH) + (L15EHL - L15EHH)+ (L16EHL - L16EHH)+ (L17EHL - L17EHH)+ (L18EHL - L18EHH) + (L19EHL - L19EHH) + (L20EHL - L20EHH) + (L21EHL - L21EHH) + (L22EHL - L22EHH) + (L23EHL - L23EHH) + (L24EHL - L24EHH))/12) ///
(( (L25ELH - L25ELL) + (L26ELH - L26ELL) + (L27ELH - L27ELL)+ (L28ELH - L28ELL)+ (L29ELH - L29ELL)+ (L30ELH - L30ELL) + (L31ELH - L31ELL) + (L32ELH - L32ELL) + (L33ELH - L33ELL) + (L34ELH - L34ELL) + (L35ELH - L35ELL) + (L36ELH - L36ELL))/12) ///
( ( (L25EHL - L25EHH) + (L26EHL - L26EHH) + (L27EHL - L27EHH)+ (L28EHL - L28EHH)+ (L29EHL - L29EHH)+ (L30EHL - L30EHH) + (L31EHL - L31EHH) + (L32EHL - L32EHH) + (L33EHL - L33EHH) + (L34EHL - L34EHH) + (L35EHL - L35EHH) + (L36EHL - L36EHH))/12) ///
 , level(90) post

est store  weak
* note: weakPayGrowth works for FT, weakVPA works for PromSG75
* Low to high 
coefplot  (weak, keep(lc_1) rename(  lc_1  = "Year 1"))  (weak, keep(lc_3) rename( lc_3 = "Year 2" )) (weak, keep(lc_5) rename( lc_5 = "Year 3" )) , ciopts(recast(rcap)) legend(off) title("`lab' for the lowest performer at baseline" "Low to High versus Low to Low")   recast(bar ) vertical note("Notes. Reporting a simple average for the post-transition coefficients in an event-study regression" "for the worker with the lowest performance appraisals in the team in the two years before the transition. ", span) level(90)
graph export "$analysis/Results/8.Team/`Label'Weak`y'LH.png", replace 
graph save "$analysis/Results/8.Team/`Label'Weak`y'LH.gph", replace  

* high to low 
coefplot  (weak, keep(lc_2) rename(  lc_2  = "Year 1"))  (weak, keep(lc_4) rename( lc_4 = "Year 2" )) (weak, keep(lc_6) rename( lc_6 = "Year 3" )) , ciopts(recast(rcap)) legend(off) title("`lab' for the lowest performer at baseline" "High to Low versus High to High")   recast(bar ) vertical note("Notes. Reporting a simple average for the post-transition coefficients in an event-study regression" "for the worker with the lowest performance appraisals in the team in the two years before the transition. ", span) level(90)
graph export "$analysis/Results/8.Team/`Label'Weak`y'HL.png", replace 
graph save "$analysis/Results/8.Team/`Label'Weak`y'HL.gph", replace
}



