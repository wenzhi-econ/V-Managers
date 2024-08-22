/* EVENT STUDY COMMANDS

	You'll need the following commands:
		- did_imputation (Borusyak et al. 2021): currently available at https://github.com/borusyak/did_imputation
		- did_multiplegt (de Chaisemartin and D'Haultfoeuille 2020): available on SSC
		- eventstudyinteract (San and Abraham 2020): available on SSC
		- scdid (Callaway and Sant'Anna 2020): currently available at https://friosavila.github.io/playingwithstata/main_csdid.html

Also:  ssc install did2s // two-stage difference-in-differences approach
ssc install did_multiplegt
net install csdid, from ("https://raw.githubusercontent.com/friosavila/csdid_drdid/main/code/") replace
net install github, from("https://haghish.github.io/github/")
github install lsun20/eventstudyinteract

* could not install did_imputation & event_plot directly (had to copy & paste)
net install did_imputation, from("https://github.com/borusyak/did_imputation")

*/ 
		
////////////////////////////////////////////////////////////////////////////////
* EXAMPLES USING PURPOSE 
////////////////////////////////////////////////////////////////////////////////

use "${user}/PurposePaper/Data/dta/PurposeAnalysisPanel.dta", clear 
keep if RCTSample ==1 
keep if Year >2017 & Year <2021
drop if PWBefore ==1

global control0  Tenure0 Tenuresq0 i.FuncGroup0 i.WL0 
global PW VirtualPW   //  PWCancelledB PWNoShowB  PWWithdrawnB  ShareSamePWIDB  SamePWIDM

bys IDlse: egen m = max(YearMonth) // time of event 
gen Ei = PWMonth 
replace Ei = m + 1 if Ei==.
format Ei %tm 
gen K = YearMonth-Ei 								// "relative time", i.e. the number periods since treated (could be missing if never-treated)

/* Variables needed 
1) TreatmentTime >> can be transformed into first manager encounter
2) Time of treatment time invariant within individual (MonthPW)
3) Event window or event dummies directly

I could have multiple events 
*/
// 1. Estimation with did_imputation of Borusyak et al. (2021)
did_imputation LogPayBonus IDlse YearMonth  Ei, allhorizons pretrend(12) autosample  
event_plot, default_look trimlag(12) graph_opt( xtitle("Periods since the event") ytitle("Average causal effect") ///
	title("Borusyak et al. (2021) imputation estimator") xlabel(-12(3)24) scheme(aurora) )   ciplottype(rcap) savecoef
	
did_imputation VPA IDlse YearMonth  Ei, allhorizons pretrend(12) autosample  
event_plot, default_look trimlag(12) graph_opt( xtitle("Periods since the event") ytitle("Average causal effect") ///
	title("Borusyak et al. (2021) imputation estimator") xlabel(-12(3)24) scheme(aurora) )   ciplottype(rcap) savecoef

// 2. Estimation with did_multiplegt of de Chaisemartin and D'Haultfoeuille (2020)
did_multiplegt LogPayBonus IDlse YearMonth TreatmentTime, robust_dynamic dynamic(5) placebo(5) breps(100) cluster(IDlse) 
event_plot e(estimates)#e(variances), default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") ///
	title("de Chaisemartin and D'Haultfoeuille (2020)") xlabel(-4(1)4)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
// 3. Estimation with cldid of Callaway and Sant'Anna (2020)
csdid LogPayBonus , ivar(IDlse) time(YearMonth) gvar(Ei) notyet
estat event, estore(cs) // this produces and stores the estimates at the same time
event_plot cs, default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-36(3)24) ///
	title("Callaway and Sant'Anna (2020)")) stub_lag(E#) stub_lead(E_#) together
	
// 4. Estimation with eventstudyinteract of Sun and Abraham (2020)
sum Ei
gen lastcohort = Ei==r(max) // dummy for the latest- or never-treated cohort
forvalues l = 0/24 {
	gen L`l'event = K==`l'
}
forvalues l = 1/24 {
	gen F`l'event = K==-`l'
}
drop F1event // normalize K=-1 (and also K=-15) to zero
eventstudyinteract LogPayBonus L*event F*event, vce(cluster IDlse) absorb( YearMonth) cohort(Ei) control_cohort(lastcohort)
event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-36(3)24) ///
	title("Sun and Abraham (2020)")) stub_lag(L#event) stub_lead(F#event) together ciplottype(rcap)
	
// 5. TWFE OLS estimation (only correct if treatment effect homogeneity). Some groups could be binned.
reghdfe LogPayBonus F*event L*event, a(YearMonth) cluster(IDlse)
event_plot, default_look stub_lag(L#event) stub_lead(F#event) together graph_opt(xtitle("Months since the event") ytitle("OLS coefficients") xlabel(-36(3)24) title("OLS"))

	
	
