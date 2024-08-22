





use "$managersdta/SwitchersAllSameTeam2.dta", clear 
********************************************************************************
* EVENT STUDY 
* DECOMPOSING LATERAL MOVES + SOCIALLY CONNECTED MOVES
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse    // alternative, to try 
global exitFE CountryYear AgeBand AgeBandM Func Female

use "$managersdta/AllSameTeam2.dta", clear 
*merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
*drop if _merge ==2 
*drop _merge 

* odd or even Manager id for placebo events 
*gen odd = mod(IDlseMHR,2) 
gen odd = mod(ManagerNum,2) 

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

*keep if Ei!=. 
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
*keep if ii==1 // MANUAL INPUT - to remove if irrelevant

********************************************************************************
* decomposing total job changes 
********************************************************************************

* generating the 4th cateogry which is transfer within function and changing manager 
generate TransferSJDiffMSameFunc = TransferSJ 
replace  TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace  TransferSJDiffMSameFunc = 0 if TransferSJSameM==1
bys IDlse (YearMonth), sort: generate TransferSJDiffMSameFuncC= sum(TransferSJDiffMSameFunc)

generate TransferSJSameMSameFunc = TransferSJ 
replace  TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace  TransferSJSameMSameFunc = 0 if TransferSJDiffMSameFunc==1
bys IDlse (YearMonth), sort: generate TransferSJSameMSameFuncC= sum(TransferSJSameMSameFunc)

* DURING MANAGER ASSIGNMENT 
eststo clear 
local Label $Label
foreach var in  TransferSJC TransferSJSameMSameFuncC TransferSJDiffMSameFuncC TransferFuncC {
	eststo `var': reghdfe   `var' `Label'LHPost  `Label'HLPost  `Label'HHPost `Label'LLPost if (WL2==1 ) & (  KEi ==-1 | KEi ==-2 | KEi ==-3  | KEi ==22 | KEi ==23 | KEi ==24 ) , a(  IDlse YearMonth ) vce(cluster IDlseMHR)

	su `var' if `Label'LLPost==1
local lm = round(r(mean), .01)
	su `var' if `Label'HHPost==1
local hm = round(r(mean), .01)

local lab: variable label `var'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(95) post
est store  `var'

}
* NOTE: results using window at 24 as 71% of workers have change manager after 2 years (so it does not make sense to look at within team changes)

**# ON PAPER FIGURE: MovesDecompGainE.png
di 1/.0779867 // = 12.822699 factor to rescale so that coeff. sum up to 100 
coefplot  (TransferSJC, keep(lc_1) rename(  lc_1  = "All lateral moves" )  ylabel(, labsize(large)) noci  recast(bar) ) ///
		(TransferSJSameMSameFuncC, keep(lc_1) rename( lc_1 = "Within team" ) noci recast(bar)  ) ///
         (TransferSJDiffMSameFuncC, keep(lc_1) rename( lc_1 = "Different team, same function" ) noci recast(bar)  ) ///
         (TransferFuncC, keep(lc_1) rename( lc_1 = "Different team, cross-functional" ) noci  recast(bar) ) ///
, legend(off)   xline(0, lpattern(dash))   ///
 xscale(range(0 1)) xlabel(0(0.1)1, labsize(vlarge)) scheme(tab2) rescale(12.822699)   graphregion(margin(medium)) plotregion(margin(medium)) xsize(5) ysize(2)
 *title("Gaining a high-flyer manager, decomposition of lateral moves during rotation", size(large))
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/MovesDecompGain.pdf", replace  
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/MovesDecompGain.gph", replace 