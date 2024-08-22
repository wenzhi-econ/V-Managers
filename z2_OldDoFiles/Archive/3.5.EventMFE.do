********************************************************************************
* Delta specification for FE and also fast track
********************************************************************************

use "$Managersdta/AllSnapshotMCultureMType.dta", clear
merge 1:1 IDlse YearMonth using  "$Managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 
 
xtset IDlse YearMonth 

keep if Year>2015

merge m:1 IDlseMHR using "$analysis/Results/3.FE/MFEBayes.dta" , keepusing(MFEBayes)
egen tM = tag(IDlseMHR)
ta _merge // I am left with 77% of obs (lose 0 from using dataset but 23% from master)

keep if _merge ==3 
drop _merge 

egen CountryYear = group(Country Year)

********************************************************************************
* Event study dummies 
********************************************************************************

* Changing manager that transfers 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & (TransferInternalL1M==1 | TransferInternalL2M==1 | TransferInternalL3M==1 | TransferInternalF1M==1  | TransferInternalF2M==1  | TransferInternalF3M==1) 
replace  ChangeMR  = . if ChangeM==.
replace  ChangeMR  = . if IDlseMHR ==. 
 
* For Sun & Abraham only consider first event 
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1

xtset IDlse YearMonth 
gen diffM = d.MFEBayes // can be replace with d.EarlyAgeM
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag)
*gen DeltaM = d.EarlyAgeM // option 2 

foreach var in Ei {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
	gen L`l'`var'DeltaM = L`l'`var'*DeltaM

}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
	gen F`l'`var'DeltaM = F`l'`var'*DeltaM
}

}

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

global eventDelta L*EiDeltaM F*EiDeltaM 
global event L*Ei F*Ei 

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM IDlse  
global exitFE CountryYear AgeBand AgeBandM  Func Female

gen Tenure2 = Tenure^2
gen TenureM2 = TenureM^2

////////////////////////////////////////////////////////////////////////////////
* PRODUCTIVITY - OLS
////////////////////////////////////////////////////////////////////////////////

eststo: reghdfe ProductivityStd $eventDelta $cont, a( $abs $event  ) vce(cluster IDlseMHR)

local c = 21 // !PLUG! specify window 
local d = (`c' - 1)/2  // half window
local y = "ProductivityStd"
pretrendDeltaM, c(`c') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDeltaM = round(r(mean), 0.001)

event_plot,  stub_lag(L#EiDeltaM) stub_lead(F#EiDeltaM) trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(gg_tableau) xtitle("Months since manager change") ytitle("OLS coefficients") xlabel(-`d'(2)`d') title("Productivity", span pos(12))  note("Pretrends p-value=`jointDeltaM'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 
graph save  "$analysis/Results/4.Event/TWFEProdDeltaMFE.gph", replace
graph export "$analysis/Results/4.Event/TWFEProdDeltaMFE.png", replace 
 *lcolor(ebblue)  mcolor(ebblue)
////////////////////////////////////////////////////////////////////////////////

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
graph save  "$analysis/Results/4.Event/Imputation/DIDProdDeltaFE.gph", replace
graph export  "$analysis/Results/4.Event/Imputation/DIDProdDeltaMFE.png", replace

////////////////////////////////////////////////////////////////////////////////
* PRODUCTIVITY - SUN 
////////////////////////////////////////////////////////////////////////////////

gen controlcohort = Ei==. // dummy for the latest- or never-treated cohort

eventstudyinteract ProductivityStd $eventDelta ,  vce(cluster IDlseMHR) absorb( $abs $event) cohort(Ei) control_cohort(controlcohort)

local c = 21 // !PLUG! specify window 
local d = (`c' - 1)/2  // half window
local y = "ProductivityStd"
pretrendDeltaM, c(`c') y(`y')

su ymeanF1
local ymeanF1 = round(r(mean), 0.01)
su joint
local jointDeltaM = round(r(mean), 0.001)

local c = 21 // !PLUG! specify window 
local d = (`c' - 1)/2  // half window
event_plot e(b_iw)#e(V_iw), stub_lag(L#EiDeltaM) stub_lead(F#EiDeltaM) trimlag(`d') trimlead(`d') lead_ci_opt(lcolor(ebblue))   lag_ci_opt(lcolor(ebblue)) lag_opt(lcolor(ebblue)  mcolor(ebblue)) lead_opt(lcolor(ebblue)  mcolor(ebblue)) graph_opt(scheme(gg_tableau) xtitle("Months since manager change") ytitle("Sun and Abraham (2020)") xlabel(-`d'(2)`d') title("Productivity", span pos(12))  note("Pretrends p-value=`jointDeltaM'") ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) yline(0, lcolor(maroon) lpattern(solid) ) xline(-1, lcolor(maroon) lpattern(solid)) legend(off)  )    ciplottype(rcap) 

event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Months since manager change") ytitle("Average causal effect") title("Productivity, Sun and Abraham (2020)")) stub_lag(L#EiDeltaM) stub_lead(F#EiDeltaM) 




