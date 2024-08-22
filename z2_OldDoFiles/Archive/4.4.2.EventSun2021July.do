********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

///////////////////////
* IMPORT DATASET 
///////////////////////

do "$analysis/DoFiles/4.Event/4.0.EventImportSun.do"
xtset IDlse YearMonth  

*CHECK mutually exclusive : each individual only has 1 event 
egen a = rowtotal( ChangeMR ChangeAgeMHighLow  ChangeAgeMHighHigh  ChangeAgeMLowLow  ChangeAgeMLowHigh)
* any case with a ==1 is because previous manager EarlyAgeM is not defined as manager is missing 
drop a 
egen a = rowtotal(  ChangeAgeMHighLow  ChangeAgeMHighHigh  ChangeAgeMLowLow  ChangeAgeMLowHigh) // max a is 1 
bys IDlse: egen x = sum(a)
drop a x 

* VARIABLES 
global event F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh F*ChangeAgeMLowLow L*ChangeAgeMLowLow
global cont  Tenure TenureM Tenure2 Tenure2M
global abs AgeBand AgeBandM  IDlseMHR IDlse  CountryYM 
global exitFE  CountryYM AgeBand AgeBandM  IDlseMHR Female Func

// Estimation with eventstudyinteract of Sun and Abraham (2020)

sum Ei
gen lastcohort = Ei==r(max) // dummy for the latest- or 
replace lastcohort =1 if Ei==. // never-treated cohort

////////////////////////////////////////////////////////////////////////////////
* PAY
////////////////////////////////////////////////////////////////////////////////

eventstudyinteract LogPayBonus $event , vce(cluster IDlseMHR) absorb( $abs )  covariates( $cont ) cohort(Ei) control_cohort(lastcohort)

event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-14(1)5) ///
	title("Sun and Abraham (2020)")) stub_lag(L#event) stub_lead(F#event) together

matrix sa_b = e(b_iw) // storing the estimates for later
matrix sa_v = e(V_iw)

////////////////////////////////////////////////////////////////////////////////
* PAY
////////////////////////////////////////////////////////////////////////////////

eventstudyinteract LeaverPerm $event , vce(cluster IDlseMHR) absorb( $exitFE )  covariates( $cont ) cohort(Ei) control_cohort(lastcohort)
