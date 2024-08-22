********************************************************************************
* Delta specification for FE and also fast track
********************************************************************************

* LOAD PROGRAMS 
do "$analysis/DoFiles/3.FE/eventd.do"
do "$analysis/DoFiles/3.FE/pretrend.do"

use "$managersdta/AllSnapshotMCultureMType2015.dta", clear 
/*
use "$managersdta/AllSnapshotMCultureMType.dta", clear 
* Changing manager that transfers 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & (TransferInternalL1M==1 | TransferInternalL2M==1 | TransferInternalL3M==1 | TransferInternalF1M==1  | TransferInternalF2M==1  | TransferInternalF3M==1) 
replace  ChangeMR  = . if ChangeM==.
replace  ChangeMR  = . if IDlseMHR ==. 
 
* For Sun & Abraham only consider first event 
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1
*/

* productivity 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

* labor laws 
merge m:1 ISOCode Year using "$cleveldta/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF) 
drop if _merge==2
drop _merge

* Bayes 
merge m:1 IDlseMHR using  "$managersdta/MFEBayesID.dta", keepusing(MFEBayes)
drop if _merge ==2 
drop _merge 

* binary indicator for labor law 
bys ISOCode: egen c = mean(LaborRegWEF)
egen tt= tag(Country)
su c if tt==1, d
gen LaborRegWEFB = c>r(p50) & c!=.
drop tt c 

egen CountryYear = group(Country Year)

********************************************************************************
* Event study dummies 
********************************************************************************

xtset IDlse YearMonth 
gen diffM = d.EarlyAgeM // d.EarlyAge2015M / can be replace with d.MFEBayes
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag)
*gen DeltaM = d.EarlyAgeM // option 2 

foreach var in Ei {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.


local eventExit ""
local eventDeltaExit ""
su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
	gen L`l'`var'DeltaM = L`l'`var'*DeltaM

	if `l' > 0{
	local eventExit " `eventExit' L`l'`var'"
	local eventDeltaExit "`eventDeltaExit' L`l'`var'"
}
else{
}

}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
	gen F`l'`var'DeltaM = F`l'`var'*DeltaM
}

}

* if binning 
forval i=1(1)6{
	gen Lend`i'1 = KEi>=`i'1 & KEi!=.
	gen LendDeltaM`i'1 = Lend`i'1*DeltaM
	gen Fend`i'1 = KEi<= -`i'1 & KEi!=.
	gen FendDeltaM`i'1 = Fend`i'1*DeltaM
}

* LOOP TO QUICK GENERATE SET OF EVENT INDICATORS 

local c = 61 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local i = `d'/10
eventd, i(`i')

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

global eventDelta L*EiDeltaM F*EiDeltaM 
global event L*Ei F*Ei 
*global eventDelta $LeventDelta $FeventDelta
*global event $Levent $Fevent 

global eventDeltaExit $LeventDeltaExit $FeventDeltaExit 
* global eventDeltaExit `eventDeltaExit'
global eventExit $LeventExit $FeventExit 
* global eventExit `eventExit'

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM IDlse  
global exitFE CountryYear AgeBand AgeBandM  Func Female

* OUTCOME VARIABLES 
////////////////////////////////////////////////////////////////////////////////

* Time in division
gen o=1 
bys IDlse TransferInternalC: gen TimeInternalC = sum(o)

* Time in function 
bys IDlse TransferFuncC : gen TimeFuncC = sum(o)

* Activities ONET
egen ONETDistance = rowmean(ONETContextDistance ONETActivitiesDistance ONETAbilitiesDistance ONETSkillsDistance) 
egen ONETDistanceC = rowmean(ONETContextDistanceC ONETActivitiesDistanceC ONETAbilitiesDistanceC ONETSkillsDistanceC) 

foreach var in  ONETDistanceC ONETContextDistanceC ONETActivitiesDistanceC ONETAbilitiesDistanceC ONETSkillsDistanceC {
gen `var'B = `var'>0 if `var'!=. 
gen `var'B1 = `var'>0 if `var'!=. 
replace `var'B1 = 0 if `var'==. 
}

* EDUCATION DISTANCE 

merge m:1 FuncS SubFuncS StandardJob using "$fulldta/EducationMainField.dta"
drop if _merge ==2 
drop _merge 

merge m:1 IDlse using "$fulldta/EducationMax.dta"
drop if _merge ==2 
drop _merge

gen DiffField = (FieldHigh1 != MajorField & FieldHigh2!= MajorField &  FieldHigh3!= MajorField) if (MajorField!=. & FieldHigh1!=. )

* VPA
gen VPA125 = VPA>=125 if VPA!=.

* TEAM SIZE AND PERFORMANCE 
xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus
bys IDlseMHR YearMonth: egen TeamPayG = mean(PayGrowth)
egen tt = tag(IDlseMHR YearMonth)

foreach v in TeamPayG TeamSize {
	bys IDlse: egen `v'0 = mean(cond( YearMonth == Ei,`v', .))
	bys IDlse: egen `v'Mean = mean(`v')
	replace `v'0 = `v'Mean if Ei==. // replace with overall mean if worker never experiences a manager change
	su `v'0 if tt==1 , d 
	gen Above`v'0 = `v'0 > r(p50) if `v'0 !=.
}
drop tt 

* VPA/Pay G HETEROGENEITY 
egen tt = tag(IDlse)

foreach v in PayGrowth VPA{
	bys IDlse: egen `v'0 = mean(cond( YearMonth == Ei,`v', .))
	bys IDlse : egen `v'Mean = mean(`v')
	replace `v'0 = `v'Mean if Ei==. // replace with overall mean if worker never experiences a manager change
	su `v'0 if tt==1 , d 
	gen Above`v'0 = `v'0 > r(p50) if `v'0 !=.
}
drop tt

////////////////////////////////////////////////////////////////////////////////
* LOOP- OLS
////////////////////////////////////////////////////////////////////////////////

label var LogPayBonus "Pay + bonus (logs)"
label var ChangeSalaryGradeC  "Prom. (salary)"
label var ChangeSalaryGradeVC  "Vertical Prom. (salary)"
label var PromWLC  "Prom. (work-level)"
label var PromWLVC  "Vertical Prom. (work-level)"
label var VPA "Perf. Appraisals"
label var VPA125 "Top Perf. Appr. (>125)"
label var ProductivityStd "Productivity (std)"

label var TransferInternalC  "Transfer (sub-func)"
la var  TransferInternalLLC "Transfer (lateral)" 
la var TransferInternalVC "Transfer (vertical)" 
la var TransferInternalSameMC "Transfer (same manager)" 
la var TransferInternalDiffMC "Transfer (diff. manager)"
label var TransferInternalSJC  "Transfer job (sub-func)"
la var  TransferInternalSJLLC "Transfer job (lateral)" 
la var TransferInternalSJVC "Transfer job (vertical)" 
la var TransferInternalSJSameMC "Transfer job (same manager)" 
la var TransferInternalSJDiffMC "Transfer job (diff. manager)"
label var TransferFuncC  "Transfer (func)"
label var ONETDistanceCB "Task distant transfer"
label var TimeInternalC "Time in sub-func"
label var TimeFuncC "Time in func"
label var DiffField "Educ. in diff. field"
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"

* outcomes with window 61, currently excluding: TransferInternalC PromWLC ChangeSalaryGradeC
* TransferInternalSJC   TransferInternalSJLLC   TransferInternalSJVC TransferInternalSJSameMC TransferInternalSJDiffMC
********************************************************************************

global yperf LogPayBonus  PromWLVC ChangeSalaryGradeVC  VPA VPA125
global ytransfer TransferInternalLLC TransferInternalVC TransferInternalSameMC  TransferInternalDiffMC   TransferFuncC ONETDistanceCB TimeInternalC TimeFuncC  DiffField 
global yexit LeaverPerm LeaverVol  LeaverInv

* outcomes with window 21
********************************************************************************
global prod ProductivityStd 

* $yperf // to change 
foreach var in $prod  {
local z: variable label `var'

eststo: reghdfe `var' $eventDelta $cont, a( $abs $event  ) vce(cluster IDlseMHR)

local c = 21 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "`var'"
pretrendDeltaM, c(`c') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDeltaM = round(r(mean), 0.001)

event_plot,  stub_lag(L#EiDeltaM) stub_lead(F#EiDeltaM) trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`z'", span pos(12))  note("Pretrends p-value=`jointDeltaM'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/FastTrack/TWFE`var'.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFE`var'.png", replace 
}

* EXIT

foreach var in $yexit {
local z: variable label `var'

eststo: reghdfe `var' $eventDeltaExit $cont, a( $exitFE $eventExit ) vce(cluster IDlseMHR)

local c = 61 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "`var'"

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)


event_plot,  stub_lag(L#EiDeltaM) stub_lead(F#EiDeltaM) trimlag(`d') trimlead(0) lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(0(2)`d') title("`z'", span pos(12)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(0, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/FastTrack/TWFE`var'.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFE`var'.png", replace 
}

////////////////////////////////////////////////////////////////////////////////
* HET BY LABOR LAW 
////////////////////////////////////////////////////////////////////////////////

foreach var in VPA  {  
	forval ll=0/1{
local z: variable label `var'

eststo L`ll': reghdfe `var' $eventDelta $cont if LaborRegWEFB ==`ll', a( $abs $event  ) vce(cluster IDlseMHR)

local c = 21 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "`var'"
pretrendDeltaM, c(`c') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDeltaM = round(r(mean), 0.001)
}
event_plot L0 L1,  stub_lag(L#EiDeltaM L#EiDeltaM) stub_lead(F#EiDeltaM F#EiDeltaM) trimlag(`d') trimlead(`d') lead_ci_opt1(lcolor(eltblue))   lag_ci_opt1(lcolor(eltblue)) lag_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_ci_opt2(lcolor(lavender))   lag_ci_opt2(lcolor(lavender)) lag_opt2(lcolor(lavender)  mcolor(lavender)) lead_opt2(lcolor(lavender)  mcolor(lavender)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`z': het by labor law", span pos(12))   yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(order(2 "Below median" 6 "Above median") position(7) cols(2))   )    ciplottype(rcap) 
*note("Pretrends p-value=`jointDeltaM'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))
graph save  "$analysis/Results/4.Event/FastTrack/TWFE`var'LL.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFE`var'LL.png", replace 
}

* EXIT

foreach var in $yexit {
		forval ll=0/1{
local z: variable label `var'

eststo L`ll': reghdfe `var' $eventDeltaExit $cont if LaborRegWEFB ==`ll' , a( $exitFE $eventExit ) vce(cluster IDlseMHR)

local c = 61 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "`var'"

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)


event_plot L0 L1,  stub_lag(L#EiDeltaM L#EiDeltaM) stub_lead(F#EiDeltaM F#EiDeltaM) trimlag(`d') trimlead(0) lead_ci_opt1(lcolor(eltblue))   lag_ci_opt1(lcolor(eltblue)) lag_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_ci_opt2(lcolor(lavender))   lag_ci_opt2(lcolor(lavender)) lag_opt2(lcolor(lavender)  mcolor(lavender)) lead_opt2(lcolor(lavender)  mcolor(lavender)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(0(2)`d') title("`z': het by labor law", span pos(12)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(0, lcolor(maroon) lpattern(solid)) legend(order(2 "Below median" 6 "Above median") position(7) cols(2))   )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/FastTrack/TWFE`var'LL.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFE`var'LL.png", replace 
}

////////////////////////////////////////////////////////////////////////////////
* HET BY TEAM PAY G or TEAM SIZE 
////////////////////////////////////////////////////////////////////////////////

foreach var in VPA  {  
	forval ll=0/1{
local z: variable label `var'

eststo T`ll': reghdfe `var' $eventDelta $cont if AboveTeamPayG0 ==`ll', a( $abs $event  ) vce(cluster IDlseMHR)

local c = 21 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "`var'"
pretrendDeltaM, c(`c') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDeltaM = round(r(mean), 0.001)
}
event_plot T0 T1,  stub_lag(L#EiDeltaM L#EiDeltaM) stub_lead(F#EiDeltaM F#EiDeltaM) trimlag(`d') trimlead(`d') lead_ci_opt1(lcolor(eltblue))   lag_ci_opt1(lcolor(eltblue)) lag_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_ci_opt2(lcolor(lavender))   lag_ci_opt2(lcolor(lavender)) lag_opt2(lcolor(lavender)  mcolor(lavender)) lead_opt2(lcolor(lavender)  mcolor(lavender)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`z': het by team perf.", span pos(12))   yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(order(2 "Below median" 6 "Above median") position(7) cols(2))   )    ciplottype(rcap) 
*note("Pretrends p-value=`jointDeltaM'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))
graph save  "$analysis/Results/4.Event/FastTrack/TWFE`var'TeamG.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFE`var'TeamG.png", replace 
}

* EXIT

foreach var in $yexit {
		forval ll=0/1{
local z: variable label `var'

eststo T`ll': reghdfe `var' $eventDeltaExit $cont if AboveTeamPayG0 ==`ll' , a( $exitFE $eventExit ) vce(cluster IDlseMHR)

local c = 61 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "`var'"

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)


event_plot T0 T1,  stub_lag(L#EiDeltaM L#EiDeltaM) stub_lead(F#EiDeltaM F#EiDeltaM) trimlag(`d') trimlead(0) lead_ci_opt1(lcolor(eltblue))   lag_ci_opt1(lcolor(eltblue)) lag_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_ci_opt2(lcolor(lavender))   lag_ci_opt2(lcolor(lavender)) lag_opt2(lcolor(lavender)  mcolor(lavender)) lead_opt2(lcolor(lavender)  mcolor(lavender)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(0(2)`d') title("`z': het by team perf.", span pos(12)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(0, lcolor(maroon) lpattern(solid)) legend(order(2 "Below median" 6 "Above median") position(7) cols(2))   )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/FastTrack/TWFE`var'TeamG.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFE`var'TeamG.png", replace 
}

////////////////////////////////////////////////////////////////////////////////
* HET BY VPA0 OR PayGrowth0
////////////////////////////////////////////////////////////////////////////////

foreach var in VPA  {  
	forval ll=0/1{
local z: variable label `var'

eststo T`ll': reghdfe `var' $eventDelta $cont if AboveVPA0 ==`ll', a( $abs $event  ) vce(cluster IDlseMHR)

local c = 21 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "`var'"
pretrendDeltaM, c(`c') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDeltaM = round(r(mean), 0.001)
}
event_plot T0 T1,  stub_lag(L#EiDeltaM L#EiDeltaM) stub_lead(F#EiDeltaM F#EiDeltaM) trimlag(`d') trimlead(`d') lead_ci_opt1(lcolor(eltblue))   lag_ci_opt1(lcolor(eltblue)) lag_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_ci_opt2(lcolor(lavender))   lag_ci_opt2(lcolor(lavender)) lag_opt2(lcolor(lavender)  mcolor(lavender)) lead_opt2(lcolor(lavender)  mcolor(lavender)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("`z': het by perf. appraisal", span pos(12))   yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(order(2 "Below median" 6 "Above median") position(7) cols(2))   )    ciplottype(rcap) 
*note("Pretrends p-value=`jointDeltaM'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))
graph save  "$analysis/Results/4.Event/FastTrack/TWFE`var'TeamG.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFE`var'TeamG.png", replace 
}

* EXIT

foreach var in $yexit {
		forval ll=0/1{
local z: variable label `var'

eststo T`ll': reghdfe `var' $eventDeltaExit $cont if AboveVPA0 ==`ll' , a( $exitFE $eventExit ) vce(cluster IDlseMHR)

local c = 61 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "`var'"

cap drop ymeanF1
su `y' if KEi == 0 // modified 
gen ymeanF1 = r(mean) 

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)


event_plot T0 T1,  stub_lag(L#EiDeltaM L#EiDeltaM) stub_lead(F#EiDeltaM F#EiDeltaM) trimlag(`d') trimlead(0) lead_ci_opt1(lcolor(eltblue))   lag_ci_opt1(lcolor(eltblue)) lag_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_opt1(lcolor(eltblue)  mcolor(eltblue)) lead_ci_opt2(lcolor(lavender))   lag_ci_opt2(lcolor(lavender)) lag_opt2(lcolor(lavender)  mcolor(lavender)) lead_opt2(lcolor(lavender)  mcolor(lavender)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(0(2)`d') title("`z': het by perf. appraisal", span pos(12)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(0, lcolor(maroon) lpattern(solid)) legend(order(2 "Below median" 6 "Above median") position(7) cols(2))   )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/FastTrack/TWFE`var'TeamG.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFE`var'TeamG.png", replace 
}


////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
* PRODUCTIVITY - OLS
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe ProductivityStd $eventDelta $cont, a( $abs $event  ) vce(cluster IDlseMHR)

local c = 21 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "ProductivityStd"
pretrendDeltaM, c(`c') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDeltaM = round(r(mean), 0.001)

event_plot,  stub_lag(L#EiDeltaM) stub_lead(F#EiDeltaM) trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("Productivity", span pos(12))  note("Pretrends p-value=`jointDeltaM'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/FastTrack/TWFEProdDeltaM.gph", replace
graph export "$analysis/Results/4.Event/FastTrack/TWFEProdDeltaM.png", replace 

////////////////////////////////////////////////////////////////////////////////
* PRODUCTIVITY - BORUSYAK 
////////////////////////////////////////////////////////////////////////////////

count if DeltaM!=.
gen w2  = DeltaM/r(N)
gen w1  = 1/r(N)
gen weight = w2- w1 
did_imputation ProductivityStd IDlse YearMonth  Ei , sum wrt(weight)  cluster(IDlseMHR) fe( $abs $event ) controls(  $cont )  nose horizons(0/`c') pretrend(`c')

event_plot, default_look trimlag(`c') graph_opt( xtitle("Months since manager change") ytitle("Average causal effect") ///
	title("Productivity, Borusyak et al. (2021) imputation estimator") xlabel(-`c'(3)`c') scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.Event/FastTrack/Imputation/DIDProdDeltaM.gph", replace
graph export  "$analysis/Results/4.Event/FastTrack/Imputation/DIDProdDeltaM.png", replace

////////////////////////////////////////////////////////////////////////////////
* PRODUCTIVITY - SUN 
////////////////////////////////////////////////////////////////////////////////

gen controlcohort = Ei==. // dummy for the latest- or never-treated cohort

eventstudyinteract ProductivityStd $eventDelta ,  vce(cluster IDlseMHR) absorb( $abs $event) cohort(Ei) control_cohort(controlcohort)

local c = 21 // !PLUG! specify window - depends on outcome:  window is 61 for all but 21 for productivity
local d = (`c' - 1)/2  // half window
local y = "ProductivityStd"
pretrendDeltaM, c(`c') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDeltaM = round(r(mean), 0.001)

event_plot e(b_iw)#e(V_iw), stub_lag(L#EiDeltaM) stub_lead(F#EiDeltaM) trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(white_tableau) xtitle("Months since manager change") ytitle("Sun and Abraham (2020)") xlabel(-`d'(2)`d') title("Productivity", span pos(12))  note("Pretrends p-value=`jointDeltaM'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 

event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Months since manager change") ytitle("Average causal effect") title("Productivity, Sun and Abraham (2020)")) stub_lag(L#EiDeltaM) stub_lead(F#EiDeltaM) 




