********************************************************************************
* EVENT STUDY 
* SOCIALLY CONNECTED MOVES
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

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei
gen Post = KEi>=0

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-(`end') &  maxEi >=(`end') & Ei!=.
ta ii
keep if ii==1 // MANUAL INPUT - to remove if irrelevant

* add social connections 
* these variables take value 1 for the entire duration of the manager-employee spell, 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/MTransferConnectedAll.dta", keepusing( ///
Connected ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4 ///
ConnectedC ConnectedManagerC ConnectedSubFuncC ConnectedOfficeC ConnectedOrg4C ///
ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
ConnectedLC ConnectedManagerLC ConnectedSubFuncLC ConnectedOfficeLC ConnectedOrg4LC ///
ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ConnectedVC ConnectedManagerVC ConnectedSubFuncVC ConnectedOfficeVC ConnectedOrg4VC ) 
drop if _merge ==2
drop _merge 

label var Connected "Move within manager's network"
label var ConnectedL "Lateral move within manager's network"
label var ConnectedV "Prom. within manager's network"

egen CountryYear = group(Country Year)

* note that the social connections variables are only available post transition, since I am looking at the first manager transition for each worker! 
local Label $Label
foreach var in Connected ConnectedL ConnectedV{
	eststo `var': reghdfe   `var' `Label'LHPost  `Label'HLPost  `Label'HHPost `Label'LLPost  $cont if WL2==1 & KEi >=0 & KEi <=30, a(  $exitFE  ) vce(cluster IDlseMHR)

	su `var' if `Label'LLPost==1
local lm = round(r(mean), .01)
	su `var' if `Label'HHPost==1
local hm = round(r(mean), .01)


	local lab: variable label `var'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(95) post
est store  conn

coefplot  (conn, keep(lc_1) rename(  lc_1  = "Gain good manager")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (conn, keep(lc_2) rename( lc_2 = "Lose good manager" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ),  legend(off) title("`lab'")  level(95) xline(0, lpattern(dash))  xscale(range(-0.05 0.05)) xlabel(-0.2(0.05)0.2) note("Notes. An observation is a worker-year-month." "Looking at outcomes up to 30 months after the manager transition." "Controls: country x time, age and function fe, tenure and tenure squared of manager x gender." "Mean, low-low manager change= `lm'; Mean, high-high manager change= `hm'" "Standard errors clustered at the manager level. Reporting 95% confidence intervals.", span)  ysize(5)
graph export "$analysis/Results/5.Mechanisms/`Label'`var'.png", replace 
graph save "$analysis/Results/5.Mechanisms/`Label'`var'.gph", replace  

}

* baseline transitions mean 
foreach var in Connected ConnectedL ConnectedV{
su `var' if `Label'LLPost==1 | `Label'HHPost==1
}

/* 


local Label $Label
foreach var in Connected ConnectedL ConnectedV{
	eststo `var': reghdfe   `var' `Label'LLPost `Label'LHPost  `Label'HLPost  `Label'HHPost  $cont if WL2==1 & KEi >=-30 & KEi <=30, a(  $abs  ) vce(cluster IDlseMHR)

	su `var' if `Label'LLPost ==0 & `Label'LHPost ==0
local lm = round(r(mean), .01)
	su `var' if `Label'HLPost ==0 & `Label'HHPost ==0
local hm = round(r(mean), .01)


	local lab: variable label `var'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(95) post
est store  conn

coefplot  (conn, keep(lc_1) rename(  lc_1  = "Gain good manager")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (conn, keep(lc_2) rename( lc_2 = "Lose good manager" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ),  legend(off) title("`lab'")  level(95) xline(0, lpattern(dash))  xscale(range(-0.05 0.05)) xlabel(-0.2(0.05)0.2) note("Notes. An observation is a worker-year-month. Static event study regression" "Event window of 30 months before and after the manager transition." "Controls: worker and time fe, tenure and tenure squared of manager interacted with gender." "Baseline Mean, low quality manager= `lm'; Baseline Mean, high quality manager= `hm'" "Standard errors clustered at the manager level. Reporting 95% confidence intervals.", span)  ysize(5)
graph export "$analysis/Results/5.Mechanisms/`Label'`var'.png", replace 
graph save "$analysis/Results/5.Mechanisms/`Label'`var'.gph", replace  

}





Table: 
esttab reg1FE reg2FE reg3FE reg4FE  using "$analysis/Results/8.Team/`Label'Perf.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{LtoH - LtoL}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}" "HtoL - HtoH" "p-value:" ) )  interaction("$\times$ ")  nobaselevels  keep(*LLPost *LHPost *HHPost *HLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace
