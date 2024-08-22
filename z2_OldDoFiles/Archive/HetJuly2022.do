********************************************************************************
* EVENT STUDY 
* Heterogeneities 
* FE model 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label pay75F60 // odd FT PromSG75 pay75F60
global MType  MFEBayesLogPayF6075  // EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 MFEBayesLogPayF6075 MFEBayesLogPayF7275 

do "$user/Managers/DoFiles/4.Event/_CoeffProgram.do"

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse    // alternative, to try 
global exitFE CountryYear AgeBand AgeBandM Func Female

global analysis  "/Users/virginiaminni/Desktop/Managers Temp" // temp for the results 

use "$Managersdta/SwitchersAllSameTeam2.dta", clear 
*use "$Managersdta/SwitchersAllSameTeam.dta", clear 
*merge 1:1 IDlse YearMonth using  "$Managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
*drop if _merge ==2 
*drop _merge 

* WL2 manager indicator 
bys IDlse: egen prewl = max(cond(KEi==-1 ,WLM,.))
bys IDlse: egen postwl = max(cond(KEi==0 ,WLM,.))
ge WL2 = prewl >1 & postwl>1 if prewl!=. & postwl!=.

* BALANCED SAMPLE FOR OUTCOMES 36 WINDOW
* window lenght
local end = 36 // to be plugged in 
local window = 73 // to be plugged in
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-(`end') &  maxEi >=(`end') & Ei!=.
ta ii
*keep if ii==1 // MANUAL INPUT - to remove if irrelevant

* Delta 
xtset IDlse YearMonth 
foreach var in oddManager EarlyAgeM MFEBayesLogPayF6075{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
}

* only keep relevant switchers 
keep if DeltaM$MType!=. 

*HET: BASELINE CHARS FOR HETEROGENEITY 
********************************************************************************

* ACROSS SUBFUNCTION AND FUNCTION 
bys IDlse: egen SubFuncPost = mean(cond(KEi ==36, SubFunc,.)) 
bys IDlse: egen SubFuncPre = mean(cond(KEi ==-1, SubFunc,.)) 
gen DiffSF = SubFuncPost!= SubFuncPre if SubFuncPost!=. & SubFuncPre!=. // 27% change SF 

* HET: indicator for 15-35 window of manager transition 
bys IDlse: egen m2y= max(cond(KEi ==-1 & MonthsSJM>=15 & MonthsSJM<=35,1,0))

* HET: average team performance before transition
merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/MType.dta", keepusing(AvPayGrowth  )
keep if _merge!=2
drop _merge 

bys IDlse: egen TeamPerf0 = mean(cond(KEi >=-24 & KEi<0,AvPayGrowth, .))
egen iio = tag(IDlse)
su TeamPerf0 if iio==1,d
gen TeamPerf0B = TeamPerf0 > `r(p50)' if TeamPerf0!=.

* heterogeneity by office size + tenure of manager 
foreach v in OfficeSize TenureM {
bys IDlse: egen `v'0= mean(cond( KEi ==0,`v',.))
}

su OfficeSize0 , d 
gen OfficeSizeHigh0 = OfficeSize0>= r(p50)
bys EarlyAgeM: su TenureM0 , d 
gen TenureMHigh0 = TenureM0>= 7 // median value for FT manager 

* heterogeneity by age 
bys IDlse: egen Age0 = mean(cond(KEi==0,AgeBand,.))
gen Young0 = Age0==1 if Age0!=.

* labor law 
merge m:1 ISOCode Year using "$cleveldta/2.WEF ProblemFactor.dta", keepusing(LaborRegWEFB LaborRegWEF)
keep if _merge!=2
drop _merge 
********************************************************************************

stop

********************************* HETEROGENEITY ANALYSIS **********************************
local Label $Label 
local het TenureMHigh0 // TenureMHigh0 OfficeSizeHigh0
local hetL "Manager tenure" // "Manager tenure" "Office size"

esplot PromWLC  if (`Label'LL !=. |    `Label'LH!=.) & WL2 ==1, event( `Label'LowHigh, save) compare( `Label'LowLow, save) window(-36 36 , bin ) period(3) estimate_reference  legend(off) yline(0) xline(-1)  xlabel(-12(2)12) xtitle(Quarters since manager change) 


esplot PromWLC if  (`Label'HL !=. |    `Label'HH!=.) & WL2 ==1, event( `Label'HighLow, save) compare( `Label'HighHigh, save) window(-36 36 , bin ) period(3) estimate_reference  legend(off) yline(0) xline(-1)  xlabel(-12(2)12) xtitle(Quarters since manager change) 

local Label $Label
local het TenureMHigh0 // TenureMHigh0 OfficeSizeHigh0
local hetL "Manager tenure" // "Manager tenure" "Office size"

foreach  v in  LogPayBonus TransferSJC PromWLC   TransferSJLLC TransferInternalLLC  TransferFuncC TransferInternalC  ChangeSalaryGradeC  ONETDistanceBC  $diffM $sameM TransferInternalVC  PromWLVC  TransferSJLLC {

local lab: variable label `v'
esplot `v' if   ( `Label'LL !=. |    `Label'LH!=.) & Year>2010  & WL2 ==1 &  m2y==1, by(`het') event( `Label'LowHigh, nogen) compare( `Label'LowLow, nogen) window(-36 36 , bin ) period(3) estimate_reference vce(cluster IDlseMHR) absorb( IDlse  Year Tenure)   yline(0) xline(-1)  xlabel(-12(2)12) name(`v'LH, replace) xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "`hetL', low" 3 "`hetL', high"))
graph save  "$analysis/Results/4.EventQ/`het'`Label'`v'ELH.gph", replace
graph export "$analysis/Results/4.EventQ/`het'`Label'`v'ELH.png", replace

esplot `v' if   ( `Label'HL !=. |    `Label'HH!=.) & Year>2010 & WL2 ==1  &  m2y==1, by(`het') event( `Label'HighLow, nogen) compare( `Label'HighHigh, nogen) window(-36 36 , bin ) period(3) estimate_reference vce(cluster IDlseMHR) absorb( IDlse  Year Tenure)  yline(0) xline(-1)  xlabel(-12(2)12)  name(`v'HL, replace) xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "`hetL', low" 3 "`hetL', high"))
graph save  "$analysis/Results/4.EventQ/`het'`Label'`v'EHL.gph", replace
graph export "$analysis/Results/4.EventQ/`het'`Label'`v'EHL.png", replace
}

********************************************************************************

/* merge with random sample 
merge m:1 IDlse using "$Managersdta/Temp/Random50.dta", keepusing(random50)
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
local endL = 36 // to be plugged in 
local endF = 36 // to be plugged in 

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
forval i=36{
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
label var LogPayBonus "Pay (logs)"

* create list of event indicators if binning 
local endL = 36 // to be plugged in 
local endF = 36 // to be plugged in 

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
local endL = 36 // to be plugged in: 60 for Prom WL
local endF = 36 // to be plugged in: 12 for Prom WL
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




