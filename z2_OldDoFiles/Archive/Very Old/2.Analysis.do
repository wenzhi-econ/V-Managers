use "$Culturedta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth 

*keep if Year>2015 // to run faster 

********************************************************************************
* EVENT STUDY DUMMIES 
********************************************************************************

*from local to IA manager 
********************************************************************************

gsort IDlse YearMonth 
gen AllIAM = 0 
replace AllIAM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1] & IAM[_n] ==1 & IAM[_n-1] ==0   ) | ( IAM[1] ==1 & FirstYM==1) // event = 1 if change to IAM or start with IA manager 
replace AllIAM = . if IDlseMHR ==. 

* PW
gen AllIAMPW = AllIAM
replace AllIAMPW = 0 if BothPW==0

gen AllIAMNoPW = AllIAM
replace AllIAMNoPW = 0 if BothPW==1

* Cultural distance 
gen AllIAMHighD = AllIAM
su CulturalDistance if CulturalDistance!=0,d 
replace AllIAMHighD = 0 if CulturalDistance <= r(p50)

gen AllIAMLowD = AllIAM
su CulturalDistance if CulturalDistance!=0, d 
replace AllIAMLowD = 0 if CulturalDistance > r(p50) &  CulturalDistance!=.

*from local to outgroup manager 
********************************************************************************

gsort IDlse YearMonth 
gen OutGroupM = 0 
replace OutGroupM  = 1 if (IDlse[_n] == IDlse[_n-1] & OutGroup[_n] ==1 & OutGroup[_n-1] ==0  ) | ( OutGroup[1] ==1 & FirstYM==1)
replace OutGroupM = . if IDlseMHR ==. 

* PW
gen OutGroupMPW = OutGroupM
replace OutGroupMPW = 0 if BothPW==0

gen OutGroupMNoPW = OutGroupM
replace OutGroupMNoPW = 0 if BothPW==1

* from local to IA, only look at the first IA one 
********************************************************************************

gsort IDlse YearMonth 
gen FirstIAM = AllIAM  
replace FirstIAM = 0 if  RoundIAM!=1  

* PW
gen FirstIAMPW = FirstIAM
replace FirstIAMPW = 0 if BothPW==0

* No PW
gen FirstIAMNoPW = FirstIAM
replace FirstIAMNoPW = 0 if BothPW==1

* month of event 
gen z = YearMonth if FirstIAM == 1
bys IDlse: egen EventFirstIAM = min(z)
drop z 
format EventFirstIAM %tm 

bys IDlse: egen FlagFirstIAM = max(FirstIAM)
bys IDlse (YearMonth), sort: gen FirstIAMPost = sum(FirstIAM)

* all IA specification: change in manager (not IA)
********************************************************************************

gsort IDlse YearMonth 
gen ChangeM = 0 
replace ChangeM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1]   )
replace  ChangeM = 0 if AllIAM == 1 // taking away if manager is on IA
replace ChangeM = . if IDlseMHR ==. 

*EVENT
gen z = YearMonth if ChangeM == 1
bys IDlse: egen EventChangeM = min(z)
drop z 
format EventChangeM %tm 

*PW
gen ChangeMPW =ChangeM
replace ChangeMPW = 0 if BothPW==0

gen ChangeMNoPW = ChangeM
replace ChangeMNoPW = 0 if BothPW==1

* Outgroup specification
********************************************************************************

gen ChangeMOutGroup =  ChangeM
replace ChangeMOutGroup = 0 if OutGroupM==1

*PW
gen ChangeMOutGroupPW =ChangeMOutGroup
replace ChangeMOutGroupPW = 0 if BothPW==0

gen ChangeMOutGroupNoPW = ChangeMOutGroup
replace ChangeMOutGroupNoPW = 0 if BothPW==1

* first IA specification: change in manager (not first IA)
********************************************************************************

gsort IDlse YearMonth 
gen ChangeFirstM = 0 
replace ChangeFirstM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1]   )
replace  ChangeFirstM = 0 if FirstIAM == 1 
replace ChangeFirstM = . if IDlseMHR ==. 

* PW
gen ChangeFirstMPW =ChangeFirstM
replace ChangeFirstMPW = 0 if BothPW==0

gen ChangeFirstMNoPW = ChangeFirstM
replace ChangeFirstMNoPW = 0 if BothPW==1

********************************************************************************
* create event dummies 
********************************************************************************

xtset IDlse YearMonth 
local max_delta = `r(tmax)' - `r(tmin)'
local first_period = -24
local last_period = 36

global event AllIAM AllIAMNoPW AllIAMPW AllIAMLowD AllIAMHighD FirstIAM FirstIAMNoPW FirstIAMPW  ChangeM ChangeMNoPW ChangeMPW  ChangeFirstM ChangeFirstMNoPW ChangeFirstMPW OutGroupM OutGroupMPW OutGroupMNoPW ChangeMOutGroup ChangeMOutGroupPW ChangeMOutGroupNoPW

* lags
foreach x in $event {
	forvalues i = 0/`max_delta'{
		gen L`i'_`x' = L`i'.`x' == 1
}
}

*leads 
local omitted_threshold = - 1
foreach x in $event {
	forvalues i = -`max_delta'/`omitted_threshold'{
		local j = abs(`i')
		gen F`j'_`x' = F`j'.`x' == 1	
}
}

* absorbing lags/leads 
xtset IDlse YearMonth 
local max_delta = `r(tmax)' - `r(tmin)'
di `max_delta'
local first_period = -24
local last_period = 36
local omitted_threshold = - 1
foreach x in $event {
		forvalues i = 0/`max_delta'{
		if `i' > `last_period'{
				local L_absorb_`x' "`L_absorb_`x'' L`i'_`x' "  // absorbing end points

	}

	}
	*else di as text "Lags are less than specified"
	forvalues i = -`max_delta'/`omitted_threshold'{
		if `i' < `first_period'{
	local j = abs(`i')
	local F_absorb_`x' " `F_absorb_`x'' F`j'_`x'" // absorbing end points 
	}
	*else di as text "Leads are less than specified"

	}
	egen Lend_`x' = rowmax(`L_absorb_`x'')
	egen Fend_`x' = rowmax(`F_absorb_`x'')
}


*keep if FlagFirstIAM==1 

* list of leads and lags for regression 
********************************************************************************
 
foreach x in $event  {
	forvalues i = 0/36{
	local lags_`x' "`lags_`x'' L`i'_`x' " 

	}
	global lags_`x' "`lags_`x''"
	}

foreach x in $event {
	forvalues i = 2/24{
	local leads_`x' "`leads_`x'' F`i'_`x' "
	}	
	global leads_`x' "`leads_`x''"
	}
	
global absorb Lend_AllIAM Fend_AllIAM Lend_ChangeM Fend_ChangeM Lend_FirstIAM Fend_FirstIAM Lend_ChangeFirstM Fend_ChangeFirstM Lend_AllIAMPW Fend_AllIAMPW Lend_AllIAMNoPW Fend_AllIAMNoPW Lend_ChangeMPW Fend_ChangeMPW Lend_ChangeMNoPW Fend_ChangeMNoPW Lend_FirstIAMPW Fend_FirstIAMPW Lend_FirstIAMNoPW Fend_FirstIAMNoPW Lend_ChangeFirstMPW Fend_ChangeFirstMPW Lend_ChangeFirstMNoPW Fend_ChangeFirstMNoPW    Lend_AllIAMHighD Fend_AllIAMHighD Lend_AllIAMLowD Fend_AllIAMLowD    Lend_OutGroupM Fend_OutGroupM Lend_OutGroupMPW Fend_OutGroupMPW Lend_OutGroupMNoPW Fend_OutGroupMNoPW Lend_ChangeMOutGroup Fend_ChangeMOutGroup Lend_ChangeMOutGroupPW Fend_ChangeMOutGroupPW Lend_ChangeMOutGroupNoPW Fend_ChangeMOutGroupNoPW

compress 

// only keep relevant vars 
preserve 
keep IDlse YearMonth Year IDlseMHR IAM RoundIAM $event AgeBand Country  Func Tenure WL WLM Female ///
DiffCountry BothPW CulturalDistance DiffLanguage ///
LogPayBonus Leaver TransferSubFuncC TransferInternalC PromWLC  VPA  PRI ///
  $leads_AllIAM $lags_AllIAM $leads_ChangeM $lags_ChangeM  $leads_FirstIAM $lags_FirstIAM $leads_ChangeFirstM $lags_ChangeFirstM  $leads_AllIAMPW $lags_AllIAMPW $leads_AllIAMNoPW $lags_AllIAMNoPW $leads_ChangeMPW $lags_ChangeMPW $leads_ChangeMNoPW $lags_ChangeMNoPW  $leads_FirstIAMPW $lags_FirstIAMPW $leads_FirstIAMNoPW $lags_FirstIAMNoPW $leads_ChangeFirstMPW $lags_ChangeFirstMPW $leads_ChangeFirstMNoPW $lags_ChangeFirstMNoPW $leads_AllIAMHighD $lags_AllIAMHighD $leads_AllIAMLowD $lags_AllIAMLowD $lags_OutGroupM $leads_OutGroupM $lags_OutGroupMPW $leads_OutGroupMPW $lags_OutGroupMNoPW $leads_OutGroupMNoPW $lags_ChangeMOutGroup $leads_ChangeMOutGroup $lags_ChangeMOutGroupPW $leads_ChangeMOutGroupPW  $lags_ChangeMOutGroupNoPW $leads_ChangeMOutGroupNoPW $absorb
  
save "$Culturedta/AllSnapshotMCultureEvent.dta", replace 
restore 


********************************************************************************
* MODEL
********************************************************************************

use "$Culturedta/AllSnapshotMCultureEvent.dta", clear 

* outgroup 
reghdfe LogPayBonus $leads_OutGroupM $lags_OutGroupM $leads_ChangeMOutGroup $lags_ChangeMOutGroup  Lend_OutGroupM Fend_OutGroupM Lend_ChangeMOutGroup Fend_ChangeMOutGroup c.Tenure##c.Tenure  , absorb(Country#YearMonth Func WL WLM  DiffCountry IDlse IDlseMHR  ) vce(cluster IDlseMHR)

regsave $leads_OutGroupM $lags_OutGroupM $leads_ChangeMOutGroup $lags_ChangeMOutGroup using "$analysis/Results/2.Analysis/OEventPay.dta", ci replace

* outgroup 
reghdfe LogPayBonus $leads_OutGroupM $lags_OutGroupM $leads_ChangeMOutGroup $lags_ChangeMOutGroup  Lend_OutGroupM Fend_OutGroupM Lend_ChangeMOutGroup Fend_ChangeMOutGroup c.Tenure##c.Tenure  , absorb(Country#YearMonth Func  DiffCountry IDlse IDlseMHR  ) vce(cluster IDlseMHR)

regsave $leads_OutGroupM $lags_OutGroupM $leads_ChangeMOutGroup $lags_ChangeMOutGroup using "$analysis/Results/2.Analysis/OEventPay.dta", ci replace

* all IA 
reghdfe LogPayBonus $leads_AllIAM $lags_AllIAM $leads_ChangeM $lags_ChangeM  Lend_AllIAM Fend_AllIAM Lend_ChangeM Fend_ChangeM c.Tenure##c.Tenure  , absorb(Country#YearMonth Func  DiffCountry  ) vce(cluster IDlseMHR)

cap drop coef se t ci_lower ci_upper 
gen coef = .
gen se = .
gen t = . 
	forvalues i = 2/24{
	nlcom	Lead`i'D: _b[F`i'_AllIAM] -  _b[F`i'_ChangeM]
	matrix b = r(b)
    matrix V = r(V)
    scalar b_Lead`i'D = b[1,1]
    scalar v_Lead`i'D = sqrt(V[1,1])
	local j = `i' 
	replace coef = scalar(b_Lead`i'D) in `j'
	replace se = scalar(v_Lead`i'D) in `j'
	replace t = -`i' in `j'

	}
	 
	forvalues i = 0/36{
	nlcom	Lag`i'D: _b[L`i'_AllIAM] -  _b[L`i'_ChangeM]
	matrix b = r(b)
    matrix V = r(V)
    scalar b_Lag`i'D = b[1,1]
    scalar v_Lag`i'D = sqrt(V[1,1])
	local j = `i' + 25
	replace coef = scalar(b_Lag`i'D) in `j'
	replace se = scalar(v_Lag`i'D) in `j'
	replace t = `i' in `j'

	}
	
gen ci_lower = coef - 1.96*se
gen ci_upper = coef + 1.96*se

twoway (scatter coef t, color(orange) )  (rcap ci_lower ci_upper t, color(orange)) , xtitle("Event Time (months)") ///
ytitle("Pay + bonus (logs)") xlabel(-24(3)36) yline(0) xline(-1,lpattern(-)) legend(order(1 "IAM - ChangeM" )) title("IA M Effect")

regsave $leads_AllIAM $lags_AllIAM $leads_ChangeM $lags_ChangeM using "$analysis/Results/2.Analysis/EventPayNoFE.dta", ci replace

* first IA 
reghdfe LogPayBonus $leads_FirstIAM $lags_FirstIAM $leads_ChangeFirstM $lags_ChangeFirstM  Lend_FirstIAM Fend_FirstIAM Lend_ChangeFirstM Fend_ChangeFirstM c.Tenure##c.Tenure   , absorb(Country#YearMonth Func  DiffCountry IDlse IDlseMHR  ) vce(cluster IDlseMHR) // RRR

cap drop coef se t ci_lower ci_upper 
gen coef = .
gen se = .
gen t = . 
	forvalues i = 2/24{
	nlcom	Lead`i'D: _b[F`i'_FirstIAM] -  _b[F`i'_ChangeFirstM]
	matrix b = r(b)
    matrix V = r(V)
    scalar b_Lead`i'D = b[1,1]
    scalar v_Lead`i'D = sqrt(V[1,1])
	local j = `i' 
	replace coef = scalar(b_Lead`i'D) in `j'
	replace se = scalar(v_Lead`i'D) in `j'
	replace t = -`i' in `j'

	}
	 
	forvalues i = 0/36{
	nlcom	Lag`i'D: _b[L`i'_FirstIAM] -  _b[L`i'_ChangeFirstM]
	matrix b = r(b)
    matrix V = r(V)
    scalar b_Lag`i'D = b[1,1]
    scalar v_Lag`i'D = sqrt(V[1,1])
	local j = `i' + 25
	replace coef = scalar(b_Lag`i'D) in `j'
	replace se = scalar(v_Lag`i'D) in `j'
	replace t = `i' in `j'

	}
	
gen ci_lower = coef - 1.96*se
gen ci_upper = coef + 1.96*se

twoway (scatter coef t, color(orange) )  (rcap ci_lower ci_upper t, color(orange)) , xtitle("Event Time (months)") ///
ytitle("Pay + bonus (logs)") xlabel(-24(3)36) yline(0) xline(-1,lpattern(-)) legend(order(1 "IAM - ChangeM" )) title("IA M Effect")

regsave $leads_FirstIAM $lags_FirstIAM $leads_ChangeFirstM $lags_ChangeFirstM using "$analysis/Results/2.Analysis/EventPayFirst.dta", ci replace  

* all IA PW
reghdfe LogPayBonus $leads_AllIAMPW $lags_AllIAMPW $leads_AllIAMNoPW $lags_AllIAMNoPW $leads_ChangeMPW $lags_ChangeMPW $leads_ChangeMNoPW $lags_ChangeMNoPW  Lend_AllIAMPW Fend_AllIAMPW Lend_AllIAMNoPW Fend_AllIAMNoPW Lend_ChangeMPW Fend_ChangeMPW Lend_ChangeMNoPW Fend_ChangeMNoPW c.Tenure##c.Tenure   , absorb(Country#YearMonth Func  DiffCountry IDlse IDlseMHR ) vce(cluster IDlseMHR)

regsave $leads_AllIAMPW $lags_AllIAMPW $leads_AllIAMNoPW $lags_AllIAMNoPW $leads_ChangeMPW $lags_ChangeMPW $leads_ChangeMNoPW $lags_ChangeMNoPW using "$analysis/Results/2.Analysis/EventPayPW.dta", ci replace

* first IA PW
reghdfe LogPayBonus $leads_FirstIAMPW $lags_FirstIAMPW $leads_FirstIAMNoPW $lags_FirstIAMNoPW $leads_ChangeFirstMPW $lags_ChangeFirstMPW $leads_ChangeFirstMNoPW $lags_ChangeFirstMNoPW   Lend_FirstIAMPW Fend_FirstIAMPW Lend_FirstIAMNoPW Fend_FirstIAMNoPW Lend_ChangeFirstMPW Fend_ChangeFirstMPW Lend_ChangeFirstMNoPW Fend_ChangeFirstMNoPW c.Tenure##c.Tenure   , absorb(Country#YearMonth Func  DiffCountry IDlse IDlseMHR ) vce(cluster IDlseMHR)

regsave $leads_FirstIAMPW $lags_FirstIAMPW $leads_FirstIAMNoPW $lags_FirstIAMNoPW $leads_ChangeFirstMPW $lags_ChangeFirstMPW $leads_ChangeFirstMNoPW $lags_ChangeFirstMNoPW using "$analysis/Results/2.Analysis/EventPayFirstPW.dta", ci replace 

* all IA - high vs low distance 
reghdfe LogPayBonus $leads_AllIAMHighD $lags_AllIAMHighD $leads_AllIAMLowD $lags_AllIAMLowD  Lend_AllIAMHighD Fend_AllIAMHighD Lend_AllIAMLowD Fend_AllIAMLowD c.Tenure##c.Tenure  , absorb(Country#YearMonth Func  DiffCountry IDlse IDlseMHR ) vce(cluster IDlseMHR)

regsave $leads_AllIAMHighD $lags_AllIAMHighD $leads_AllIAMLowD $lags_AllIAMLowD using "$analysis/Results/2.Analysis/EventPayDistance.dta", ci replace

* GRAPHS 24 leads and 36 lags 
********************************************************************************

frame create graphs 
frame change graphs 
use "$analysis/Results/2.Analysis/EventPay.dta", clear 
gen t1 = _n + 1
replace t1 = -t1
replace t1 = _n -24 if t1<=-25
replace t1 = . if t1 >36
gen t2 = _n  - 59
replace t2 = . if t2 <2
replace t2 = -t2
replace t2 = _n - 84 if t2<=-25

twoway (scatter coef t1, color(orange) ) (scatter  coef t2, color(blue) ) (rcap ci_lower ci_upper t1, color(orange)) (rcap ci_lower ci_upper t2, color(blue))  , xtitle("Event Time (months)") ///
ytitle("Pay + bonus (logs)") xlabel(-24(3)36) yline(0) xline(-1,lpattern(-)) legend(order(1 "IA" 2 "Change M")) title("IA M Effect")
graph export "$analysis/Results/2.Analysis/EventPay.png", replace

use "$analysis/Results/2.Analysis/OEventPayNoFE.dta", clear

gen t1 = _n + 1
replace t1 = -t1
replace t1 = _n -24 if t1<=-25
replace t1 = . if t1 >36
gen t2 = _n  - 59
replace t2 = . if t2 <2
replace t2 = -t2
replace t2 = _n - 84 if t2<=-25

twoway (scatter coef t1, color(orange) ) (scatter  coef t2, color(blue) ) (rcap ci_lower ci_upper t1, color(orange)) (rcap ci_lower ci_upper t2, color(blue))  , xtitle("Event Time (months)") ///
ytitle("Pay + bonus (logs)") xlabel(-24(3)36) yline(0) xline(-1,lpattern(-)) legend(order(1 "OutGroup" 2 "Change M")) title("IA M Effect")
graph export "$analysis/Results/2.Analysis/OEventPayNoFE.png", replace



********************************************************************************

* window 
sort IDlse YearMonth
gen o=1-FirstIAMPost
by IDlse:gen oo=sum(o)
bys IDlse:egen moo=max(oo)
gen Window=oo-moo if FlagFirstIAM==1
gen uu=FirstIAMPost 
bys IDlse:gen h=sum(uu)
replace  Window=h if FirstIAMPost==1
replace Window = Window-1
drop o h oo moo uu 

********************************************************************************

*CulturalDistance DiffLanguage OutGroup LinguisticDistance ReligionDistance GeneticDistance
reghdfe LogPayBonus CultDistIndex , a(Country Year Func IDlse ) vce(cluster IDlseMHR)
reghdfe LogPayBonus CulturalDistance , a(Country Year Func  ) vce(cluster IDlseMHR)
reghdfe VPA IAM##c.CulturalDistance c.Tenure##c.Tenure DiffCountry, a(Country Year Func   ) vce(cluster IDlseMHR)

reghdfe LogPayBonus OutGroup##SamePW c.Tenure##c.Tenure DiffCountry, a(Country Year Func IDlse IDlseMHR ) vce(cluster IDlseMHR)
reghdfe VPA OutGroup##SamePW c.Tenure##c.Tenure DiffCountry, a(Country Year Func IDlse IDlseMHR ) vce(cluster IDlseMHR)
reghdfe Leaver OutGroup##SamePW c.Tenure##c.Tenure DiffCountry, a(Country Year Func IDlseMHR ) vce(cluster IDlseMHR)

* EVENT 
********************************************************************************

eventdd LogPayBonus c.Tenure##c.Tenure if FlagFirstIAM==1, hdfe a(Country Year Func IDlse  DiffCountry ) timevar(Window) ci(rcap) leads(25) lags(37) graph_op(ytitle("Pay + Bonus (logs)") xtitle(Event time) xscale(range(-7(2)7)) xlabel(-24(3)36) ) vce(cluster IDlseMHR)  accum    noend  
graph export "$analysis/Results/2.Analysis/LogPayBonusEFE.png" , replace 

eventdd PromWLC c.Tenure##c.Tenure if FlagFirstIAM==1, hdfe a(Country Year Func IDlse  DiffCountry ) timevar(Window) ci(rcap) leads(25) lags(37) graph_op(ytitle("Promotion") xtitle(Event time) xscale(range(-7(2)7)) xlabel(-24(3)36) ) vce(cluster IDlseMHR)  accum    noend  
graph export "$analysis/Results/2.Analysis/PromWLCEFE.png" , replace 

eventdd Leaver c.Tenure##c.Tenure if FlagFirstIAM==1, hdfe a(Country Year Func  DiffCountry ) timevar(Window) ci(rcap) leads(2) lags(48) graph_op(ytitle("Exit") xtitle(Event time) xscale(range(-7(2)7)) xlabel(-2(3)48) ) vce(cluster IDlseMHR)  accum    noend  
graph export "$analysis/Results/2.Analysis/Leaver.png" , replace 

* TO BE DONE ANNUAL 
eventdd VPA c.Tenure##c.Tenure if FlagFirstIAM==1, hdfe a(Country Year Func IDlse  DiffCountry ) timevar(Window) ci(rcap) leads(12) lags(36) graph_op(ytitle("VPA") xtitle(Event time) xscale(range(-7(2)7)) xlabel(-12(3)36) ) vce(cluster IDlseMHR)  accum
graph export "$analysis/Results/2.Analysis/VPAEFE.png" , replace 

global outcomes LogPayBonus Leaver TransferInternalC VPA PRI PromWLC TransferSubFuncC 
global outcomesFE LogPayBonus TransferInternalC VPA PRI PromWLC TransferSubFuncC 


set scheme s1rcolor
esplot LogPayBonus if FlagFirstIAM==1, by(SamePW) event( FirstIAM) window(-20 36) 
esplot LogPayBonus if FlagFirstIAM==1, by(SamePW) event( FirstIAM) compare(ChangeM) window(-20 36) 


foreach y in $outcomes {

eventdd `y' c.Tenure##c.Tenure, hdfe a(Country#Year Func  DiffCountry ) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("`y'") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "`y'.png" , replace 


eventdd `y' c.Tenure##c.Tenure, hdfe a(Country#Year Func  DiffCountry IDlseMHR) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("`y'") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "`y'MFE.png" , replace 

}

foreach y in $outcomesFE {

eventdd `y' c.Tenure##c.Tenure, hdfe a(Country#Year Func IDlse  DiffCountry ) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("`y'") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "`y'EFE.png" , replace 


eventdd `y' c.Tenure##c.Tenure, hdfe a(Country#Year Func  DiffCountry IDlse IDlseMHR) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("`y'") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "`y'EFEMFE.png" , replace 

}

* only flag  the individuals that had the IA

foreach y in $outcomes {

eventdd `y' c.Tenure##c.Tenure if FlagFirstIAM==1, hdfe a(Country#Year Func  DiffCountry ) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("`y'") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "Flag`y'.png" , replace 


eventdd `y' c.Tenure##c.Tenure if FlagFirstIAM==1, hdfe a(Country#Year Func  DiffCountry IDlseMHR) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("`y'") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "Flag`y'MFE.png" , replace 

}


foreach y in $outcomesFE {

eventdd `y' c.Tenure##c.Tenure if FlagFirstIAM==1, hdfe a(Country#Year Func IDlse  DiffCountry ) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("`y'") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "Flag`y'EFE.png" , replace 


eventdd `y' c.Tenure##c.Tenure if FlagFirstIAM==1, hdfe a(Country#Year Func  DiffCountry IDlse IDlseMHR) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("`y'") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "Flag`y'EFEMFE.png" , replace 

}


  
eventdd LogPayBonus c.Tenure##c.Tenure, hdfe a(Country Year Func IDlseMHR DiffCountry ) timevar(Window) ci(rcap) leads(36) lags(36) graph_op(ytitle("Pay + Bonus (logs)") xtitle(Event time) xlabel(-36(6)36) ) vce(cluster IDlseMHR)  accum
graph export "" 

eventdd Leaver c.Tenure##c.Tenure, hdfe a(Country Year Func IDlse DiffCountry ) timevar(Window) ci(rcap) leads(12) lags(12) graph_op(ytitle("Pay + Bonus (logs)") xtitle(Event time) xscale(range(-7(2)7)) xlabel(-12(1)12) ) vce(cluster IDlseMHR)      inrange

esplot LogPayBonus , window(-12 12) event(FirstIAM) controls(c.Tenure##c.Tenure) absorb(Country Year Func IDlse  DiffCountry ) vce(cluster IDlseMHR)


* MANAGER HAS DONE IA 
********************************************************************************

use "$Culturedta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth

keep if FlagIA ==1 

drop RoundIA 
* Generating Round IA info
bys IDlse: egen m = min(YearMonth)
by IDlse (YearMonth), sort: gen RoundIA1 =  (IA != IA[_n-1] & _n > 1 & IA==1)   
replace RoundIA1 = 1 if (IA ==1 & YearMonth==m) 
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIA1)
drop RoundIA1 
rename RoundIAcum RoundIA

gsort IDlse YearMonth 
gen FirstIA = 0 
replace FirstIA = 1 if (IDlse[_n] == IDlse[_n-1] & IA[_n] ==1 & IA[_n-1] ==0 & RoundIA==1  )
replace FirstIA = 1 if (IA ==1 & YearMonth==m) 
bys IDlse (YearMonth), sort: gen FirstIAPost = sum(FirstIA)

by IDlse: egen FlagDrop= max(FirstIA)
drop if FlagDrop ==0 // could be individuals that did IA after 2020m3

* window 
sort IDlse YearMonth
gen o=1-FirstIAPost
by IDlse:gen oo=sum(o)
bys IDlse:egen moo=max(oo)
gen WindowIA=oo-moo 
gen uu=FirstIAPost 
bys IDlse:gen h=sum(uu)
replace  WindowIA=h if FirstIAPost==1
replace WindowIA = WindowIA-1
drop o h oo moo uu 

eventdd LogPayBonus c.Tenure##c.Tenure, hdfe a(Country YearMonth Func DiffCountry ) timevar(WindowIA) ci(rcap) leads(36) lags(48) graph_op(ytitle("Pay + Bonus (logs)") xtitle(Event time) xscale(range(-7(2)7)) xlabel(-36(6)48) ) vce(cluster IDlse)      inrange
*>> perfectly linear trend, I need a control group, but not problem without individual FE
* 





/*/

* Generating Round IA info
by IDlse (YearMonth), sort: gen RoundIA1 = (Country != Country[_n-1] & _n > 1 & IA==1)
by IDlse (YearMonth), sort: gen RoundIA2 = (IA[_n] & _n==1)
gen RoundIA = RoundIA1 + RoundIA2
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIA)
drop RoundIA1 RoundIA2 RoundIA
rename RoundIAcum RoundIA

net install allston, from("https://raw.githubusercontent.com/dballaelliott/allston/master/")
net install esplot, from("https://raw.githubusercontent.com/dballaelliott/esplot/pkg/")

esplot LogPayBonus if Year>2017, window(-12 12) event(FirstIA) compare(ChangeM) 
