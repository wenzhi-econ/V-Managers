********************************************************************************
* Where do these workers transfer to? 
* Transition matrix - evaluating starting func and func 3 years after 
* only 6 biggest Func 
********************************************************************************

*use "$managersdta/SwitchersAllSameTeam.dta", clear 
use "$managersdta/SwitchersAllSameTeam2.dta", clear 

global Label FT // PromSG75  FT odd 

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

* Re-labelling some functions and subfunctions  
label define Func 99 `"Other"', modify // add label 
label define SubFunc 999 `"Other, Same Func."', modify // add label 
label define SubFunc 9999 `"Other, Diff. Func."', modify // add label 
label define SubFunc 63 `"Science\&Tech Discovery"', modify // add label 
label define SubFunc 56  `"R\&D General Mgmt"', modify // add label 
label define SubFunc 67 `"SC General Mgmt"', modify // add label 

******* SubFunctionS
ta SubFunc if Func ==11 , sort // SC (25% of employment)
ta SubFunc if Func ==10, sort // R&D (8% of employment)
ta SubFunc if Func ==3 , sort // CD (40% of employment)
ta SubFunc if Func ==9 , sort // MARKETING

local Label $Label 
foreach v in LLPost  LHPost HLPost HHPost {
	
bys IDlse: egen Func0`v' = mean(cond(KEi==0 & `Label'`v' == 1, Func, .))
bys IDlse: egen Func1`v' = mean(cond(KEi==36 & `Label'`v' == 1, Func, .))
bys IDlse: egen SubFunc0`v' = mean(cond(KEi==0 & `Label'`v' == 1, SubFunc, .))
bys IDlse: egen SubFunc1`v' = mean(cond(KEi==36 & `Label'`v' == 1, SubFunc, .))

* Function
********************************************************************************

gen BigFunc0`v' = 99 if Func0`v'!=.
replace BigFunc0`v' = Func0`v' if (Func0`v' == 3 | Func0`v' == 4 | Func0`v' == 5 | Func0`v' == 6 | Func0`v' == 7 | Func0`v' == 9 |  Func0`v' == 10 |  Func0`v' ==  11 ) 

gen BigFunc1`v' = 99 if Func1`v'!=.
replace BigFunc1`v' = Func1`v' if (Func1`v' == 3 | Func1`v' == 4 | Func1`v' == 5 | Func1`v' == 6 | Func1`v' == 7 | Func1`v' == 9 |  Func1`v' == 10 |  Func1`v' ==  11 ) 

label value BigFunc0`v' Func
label value BigFunc1`v' Func
label var BigFunc0`v' "Function at t=0"
label var BigFunc1`v' "Function at t=36"

* R&D 
********************************************************************************

gen BigSubFuncRD0`v' = 9999 if  SubFunc0`v'!=. // R&D FOCUS 
replace BigSubFuncRD0`v' = 999 if  BigFunc0`v'==10 // R&D FOCUS 

replace BigSubFuncRD0`v' = SubFunc0`v' if (SubFunc0`v' == 53 | SubFunc0`v' == 63 | SubFunc0`v' == 56 | SubFunc0`v' == 45 | SubFunc0`v' == 51 | SubFunc0`v' == 8 ) 

gen BigSubFuncRD1`v' = 9999 if  SubFunc1`v'!=.
replace BigSubFuncRD1`v' = 999 if  BigFunc1`v'==10 // R&D FOCUS 
replace BigSubFuncRD1`v' = SubFunc1`v' if (SubFunc1`v' == 53 | SubFunc1`v' == 63 | SubFunc1`v' == 56 | SubFunc1`v' == 45 | SubFunc1`v' == 51 | SubFunc1`v' == 8 ) 

* SC
********************************************************************************
gen BigSubFuncSC0`v' = 9999  if  SubFunc0`v'!=. // SC FOCUS 
replace BigSubFuncSC0`v' = 999 if  BigFunc0`v'==11 // SC FOCUS 

replace BigSubFuncSC0`v' = SubFunc0`v' if (SubFunc0`v' == 37 | SubFunc0`v' == 35 | SubFunc0`v' == 50 | SubFunc0`v' == 60 | SubFunc0`v' == 52 | SubFunc0`v' == 17 | SubFunc0`v' == 55 | SubFunc0`v' == 67 | SubFunc0`v' == 16) 

gen BigSubFuncSC1`v' = 9999 if  SubFunc1`v'!=.
replace BigSubFuncSC1`v' = 999 if  BigFunc1`v'==11 // SC FOCUS 

replace BigSubFuncSC1`v' = SubFunc1`v' if (SubFunc1`v' == 37 | SubFunc1`v' == 35 | SubFunc1`v' == 50 | SubFunc1`v' == 60 | SubFunc1`v' == 52 | SubFunc1`v' == 17 | SubFunc1`v' == 55 | SubFunc1`v' == 67 | SubFunc1`v' == 16 ) 

label value BigSubFuncSC0`v' SubFunc
label value BigSubFuncSC1`v' SubFunc
label value BigSubFuncRD0`v' SubFunc
label value BigSubFuncRD1`v' SubFunc

label var BigSubFuncRD0`v' "R\&D at t=0"
label var BigSubFuncRD1`v' "R\&D at t=36"
label var BigSubFuncSC0`v' "SC at t=0"
label var BigSubFuncSC1`v' "SC at t=36"

}

* TRANSITION MATRIX 
********************************************************************************

egen o = tag(IDlse)

local Label $Label 
**# ON PAPER TABLE: TransitionFTLLPost.tex
* ON PAPER TABLE: TransitionFTLHPost.tex
* ON PAPER TABLE: TransitionFTHLPost.tex
* ON PAPER TABLE: TransitionFTHHPost.tex
foreach v in LLPost  LHPost HLPost HHPost {
eststo clear
eststo: estpost tab BigFunc0`v'  BigFunc1`v' if o==1 & WLM2==1 , 
esttab using "$analysis/Results/0.Paper/3.3.Other Analysis/Transition`Label'`v'.tex", ///
	cell(rowpct(fmt(2))) unstack collabels("") nonumber noobs postfoot("\hline"  "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. Biggest eight functions only (98\% of employment). Rows indicate the functions at the start while columns indicate the functions 36 months after the manager transition.   ///
 "\end{tablenotes}") replace 
}
*eststo: estpost tab BigFunc0`v'  BigFunc1`v' if o==1 & WLM2==1

* R&D
local Label $Label 
**# ON PAPER TABLE: TransitionRDFTLHPost.tex
* ON PAPER TABLE: TransitionRDFTLLPost.tex
foreach v in LLPost  LHPost HLPost HHPost {
eststo clear
eststo: estpost tab BigSubFuncRD0`v'  BigSubFuncRD1`v' if o==1  & WLM2==1, 
esttab using "$analysis/Results/0.Paper/3.3.Other Analysis/TransitionRD`Label'`v'.tex",  ///
	cell(rowpct(fmt(2))) unstack collabels("") varlabels(`e(labels)') eqlabels(`e(eqlabels)') nonumber noobs postfoot("\hline"  "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. R\&D only (8\% of employment). Rows indicate the functions at the start while columns indicate the functions 36 months after the manager transition.   ///
 "\end{tablenotes}") replace 
}

* SC
local Label $Label 
**# ON PAPER TABLE: TransitionSCFTLHPost.tex
* ON PAPER TABLE: TransitionSCFTLLPost.tex
foreach v in LLPost  LHPost HLPost HHPost {
eststo clear
eststo: estpost tab BigSubFuncSC0`v'  BigSubFuncSC1`v' if o==1  & WLM2==1, 
esttab using "$analysis/Results/0.Paper/3.3.Other Analysis/TransitionSC`Label'`v'.tex",  ///
	cell(rowpct(fmt(2))) unstack collabels("") varlabels(`e(labels)') eqlabels(`e(eqlabels)') nonumber noobs postfoot("\hline"  "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. Supply Chain (SC) only (25\% of employment). Rows indicate the functions at the start while columns indicate the functions 36 months after the manager transition.   ///
 "\end{tablenotes}") replace 
}


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
gen  TransferSJDiffMSameFunc = TransferSJ 
replace TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace TransferSJDiffMSameFunc = 0 if TransferSJSameM==1
bys IDlse (YearMonth), sort: gen  TransferSJDiffMSameFuncC= sum( TransferSJDiffMSameFunc)

gen  TransferSJSameMSameFunc = TransferSJ 
replace TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace TransferSJSameMSameFunc = 0 if  TransferSJDiffMSameFunc==1
bys IDlse (YearMonth), sort: gen  TransferSJSameMSameFuncC= sum( TransferSJSameMSameFunc)

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

* mean 
su  TransferSJC TransferFuncC TransferSJSameMC if FTLLPost==1 & (KEi ==22 | KEi ==23 | KEi ==24)  
su  TransferSJC TransferFuncC TransferSJSameMC if FTHHPost==1 & (KEi ==22 | KEi ==23 | KEi ==24)  

* AFTER MANAGER ROTATION 
eststo clear 
local Label $Label
foreach var in  TransferSJC TransferSJSameMSameFuncC TransferSJDiffMSameFuncC TransferFuncC {
	eststo `var': reghdfe   `var' `Label'LHPost  `Label'HLPost  `Label'HHPost `Label'LLPost if (WL2==1 ) & (  KEi ==-3 | KEi ==-2  | KEi ==-1 | KEi ==82 | KEi ==83  | KEi ==84) , a(  IDlse YearMonth ) vce(cluster IDlseMHR)

	su `var' if `Label'LLPost==1
local lm = round(r(mean), .01)
	su `var' if `Label'HHPost==1
local hm = round(r(mean), .01)

local lab: variable label `var'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(95) post
est store  `var'

}


**# ON PAPER FIGURE: MovesDecompGainAfter.pdf // TO PUT ON PAPER 
di 1/0.3510903  // factor to rescale so that coeff. sum up to 100 
coefplot  (TransferSJC, keep(lc_1) rename(  lc_1  = "All lateral moves") ylabel(, labsize(large)) noci  recast(bar) ) ///
		(TransferSJSameMSameFuncC, keep(lc_1) rename( lc_1 = "Within team" ) noci recast(bar)  ) ///
         (TransferSJDiffMSameFuncC, keep(lc_1) rename( lc_1 = "Different team, same function" ) noci recast(bar)  ) ///
         (TransferFuncC, keep(lc_1) rename( lc_1 = "Different team, cross-functional" ) noci  recast(bar) ) ///
, legend(off)   xline(0, lpattern(dash))   ///
 xscale(range(0 1)) xlabel(0(0.1)1, labsize(vlarge)) scheme(tab2) rescale(2.8482701) graphregion(margin(medium)) plotregion(margin(medium)) xsize(5) ysize(2)
 *title("Gaining a high-flyer manager, decomposition of lateral moves after rotation", size(large))
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/MovesDecompGainAfter.pdf", replace  
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/MovesDecompGainAfter.gph", replace 


********************************************************************************
* social connections table
********************************************************************************

egen ConnectedArea = rowmax( ConnectedSubFunc ConnectedOffice ConnectedOrg4)
label var Connected "Move within manager's network"
label var ConnectedL "Lateral move within manager's network"
label var ConnectedV "Prom. within manager's network"

egen iio = tag(IDlse)

foreach hh in ConnectedManager ConnectedArea Connected ConnectedL ConnectedV {
	
bys IDlse: egen `hh'0 = max(`hh')
foreach v in FTLHPost  FTHHPost   FTLLPost   FTHLPost{
gen `v'`hh'0= `v'*(1-`hh'0)
gen `v'`hh'1 = `v'*`hh'0
} 
} 

* these variables take value 1 for the entire duration of the manager-employee spell, 
* NOTE: they are missing before the manager transition! 

/* Already merged 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/MTransferConnectedAll.dta", keepusing( ///
Connected ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4 ///
ConnectedC ConnectedManagerC ConnectedSubFuncC ConnectedOfficeC ConnectedOrg4C ///
ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
ConnectedLC ConnectedManagerLC ConnectedSubFuncLC ConnectedOfficeLC ConnectedOrg4LC ///
ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ConnectedVC ConnectedManagerVC ConnectedSubFuncVC ConnectedOfficeVC ConnectedOrg4VC ) 
drop if _merge ==2
drop _merge 
*/ 

label var Connected "Move within manager's network"
label var ConnectedL "Lateral move within manager's network"
label var ConnectedV "Prom. within manager's network"

egen CountryYear = group(Country Year)

eststo clear 
* note that the social connections variables are only available post transition, since I am looking at the first manager transition for each worker! 
local Label $Label
foreach var in  Connected ConnectedL ConnectedV{
	 reghdfe   `var' `Label'LHPost  `Label'HLPost  `Label'HHPost `Label'LLPost if WL2==1 & ( KEi==24) , a(  Country YearMonth  ) vce(cluster IDlseMHR)
	 local r = e(r2)
	xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(95) post
est store  conn`var'
   estadd scalar r2 = `r' 
	su `var' if `Label'LLPost==1
local lm = round(r(mean), .01)
estadd scalar Mean_lm = r(mean)
	su `var' if `Label'HHPost==1
local hm = round(r(mean), .01)
estadd scalar Mean_hm = r(mean)	

local lab: variable label `var'


}
* NOTE: results robust to having a window at 60 

label var FTLHPost "High-flyer manager"

**# ON PAPER TABLE: NetworkGain.tex
esttab connConnected connConnectedL connConnectedV using "$analysis/Results/0.Paper/3.3.Other Analysis/NetworkGain.tex", replace ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(Mean_lm N r2, fmt(3 0 4) labels("Mean, low-flyer" "N" "R-squared")) ///
label nofloat nonotes collabels(none) ///
mtitles("Move within manager's network" "Lateral move within manager's network" "Vertical move within manager's network") ///
keep(lc_1)  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-year-month. Considering outcomes at 8 quarters since the manager transition (8 quarters is the average duration of a manager assignment to a team). I define a socially connected move based on whether the manager has ever worked (i) with the new manager the worker moves to and/or (ii) in the same sub-function and/or office as the job the worker moves to. Controlling for country and year-month FE. Standard errors are clustered by manager.  ///
"\end{tablenotes}")

/**# previously was a figure, ON PAPER FIGURE: NetworkGainE.png
coefplot  (connConnected, keep(lc_1) rename(  lc_1  = "Move within manager's network")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
 (connConnectedL, keep(lc_1) rename( lc_1 = "Lateral move within manager's network" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) ///
 (connConnectedV, keep(lc_1) rename( lc_1 = "Vertical move within manager's network" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ), ///
 legend(off) title("Gaining a high-flyer manager", size(medsmall))  level(95) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 95% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span)   ///
xscale(range(-0.05 0.05)) xlabel(-0.05(0.01)0.05)  aspectratio(.5)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/NetworkGain.pdf", replace // ysize(6) xsize(8)  
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/NetworkGain.gph", replace 
*/

/*
coefplot  (connConnected, keep(lc_2) rename(  lc_2  = "Move within manager's network")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  ///
(connConnectedL, keep(lc_2) rename( lc_2 = "Lateral move within manager's network" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) ///
(connConnectedV, keep(lc_2) rename( lc_2 = "Vertical move within manager's network" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ),  legend(off) title("Losing a high-flyer manager", size(medsmall))  level(95) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 95% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span) ///
  xscale(range(-0.2 0.2)) xlabel(-0.2(0.1)0.2) ysize(6) xsize(8)  ysc(outergap(50))  aspectratio(.5)
graph export "$analysis/Results/5.Mechanisms/NetworkLose.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/NetworkLose.gph", replace 
*/

* ADD SALARY OUTCOME: heterogeneity by whether worker ever moves to a previous of manager  
******************************************************************************
* generate interaction variables 
* these variables take value 1 for the entire duration of the manager-employee spell, 
* NOTE: they are missing before the manager transition! 
* note that the social connections variables are only available post transition, since I am looking at the first manager transition for each worker! 
* definition of Connected: egen Connected = rowmax(ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4)

local hh ConnectedArea //  ConnectedManager ConnectedArea  Connected
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

foreach  y in LogPayBonus { // $Keyoutcome $other ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 
* Salary results:  coeff=-.0230253; sd= .114687; p-value=0.841 
ta Connected0 if iio==1
ta ConnectedArea0 if iio==1
ta ConnectedManager0 if iio==1

* WITHOUT SALARY OUTCOME FOR NOW BECAUSE OF HUGE C.I.: (LogPayBonus, keep(lc_1) rename( lc_1 = "Salary, het. by move within manager's network" ) ciopts(lwidth(2 ..) lcolor(emerald))  msymbol(d) mcolor(white)   ), ///


* baseline transitions mean 
local Label $Label
foreach var in Connected ConnectedL ConnectedV{
su `var' if `Label'LLPost==1 & KEi==24
su `var' if `Label'HHPost==1& KEi==24
}


********************************************************************************
* PETER PRINCIPLE TABLE 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 
gen Post = KEi >=0 if KEi!=.

* Delta 
xtset IDlse YearMonth 
foreach var in EarlyAgeM{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
	gen Post`var'= Post* DeltaM`var'
}
* globals and other controls 
********************************************************************************

*gen Tenure2 = Tenure*Tenure
gen TenureM2 = TenureM*TenureM
egen CountryYear = group(Country Year)

global cont   AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM Female##AgeBand // c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs  Country YearMonth   // alternative, to try  YearMonth  IDlse   
global exitFE CountryYear AgeBand AgeBandM Func Female

gen PostEarlyAgeM1 = PostEarlyAgeM
label var PostEarlyAgeM "Gaining a high-flyer manager"
label var PostEarlyAgeM1 "Losing a high-flyer manager"

eststo clear 
eststo reg1: reghdfe LogPayBonus  PostEarlyAgeM  Female##c.Tenure##c.Tenure   if   WL==2 & (FTLH!=. | FTLL !=.) & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs  )
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)
eststo reg2: reghdfe LogPayBonus  PostEarlyAgeM1  Female##c.Tenure##c.Tenure  if   WL==2 & (FTHL!=. | FTHH !=.)  & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs )
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)

* Adding survey variables
********************************************************************************
/* only run if want to update dataset
preserve 
* list of workers that become managers 
keep if   WL==2 & (FTLH!=. | FTLL !=.) & WL2==1 & Post==1
keep  IDlse YearMonth 
rename IDlse IDlseMHR
save "$managersdta/Temp/ListWbecM.dta", replace
restore 
*/

* how manager is scored by workers 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/ListWbecM.dta" , // list of workers
keep if _merge==3
drop _merge
gen month = month(dofm(YearMonth))
merge m:1 IDlse Year using "$fulldta/Univoice.dta"
bys IDlseMHR Year: egen MScore = mean(LineManager)
gen  EarlyAgeM1=  EarlyAgeM  
label var EarlyAgeM "Gaining a high-flyer manager"
label var EarlyAgeM1 "Losing a high-flyer manager"

* FINAL TABLE:  Performance, conditional on being promoted to manager
********************************************************************************

eststo reg3: reghdfe MScore  EarlyAgeM  Female##c.Tenure##c.Tenure   if   WL==2 & (FTLH!=. | FTLL !=.) & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs  )
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)
eststo reg4: reghdfe MScore  EarlyAgeM1  Female##c.Tenure##c.Tenure  if   WL==2 & (FTHL!=. | FTHH !=.)  & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs )
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)

esttab reg1 reg2 reg3 reg4, star(* 0.10 ** 0.05 *** 0.01) keep(   EarlyAgeM EarlyAgeM1 ) se label

* outcome mean
su MScore

label var LogPayBonus "Pay (in logs) | Promoted to Manager"
label var  MScore "Effective Leader scored by reportees | Promoted to Manager"


**# ON PAPER TABLE: PeterPrinciple.tex (new structure)
esttab reg1 reg2 reg3 reg4 using "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrinciple.tex", replace ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(N r2, fmt( 0 4) labels( "N" "R-squared")) ///
label nofloat nonotes collabels(none) ///
nomtitles mgroups( "Pay + bonus (in logs) | Promoted to Manager" "Effective Leader scored by reportees", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(})) ///
keep(*EarlyAgeM *EarlyAgeM1) rename(PostEarlyAgeM EarlyAgeM PostEarlyAgeM1 EarlyAgeM1) ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
Controls include: country and year-month FE, worker tenure squared interacted with gender. ///
\textit{Pay + bonus (in logs) | Promoted to Manager} is the sum of regular pay and additional bonuses of workers promoted to managers. \textit{Effective Leader} is the workers' anonymous rating of the manager via the survey question \textit{My line manager is an effective leader}. \textit{Effective Leader} is measured on a Likert scale 1 - 5, it is asked every year in the annual survey and the overall mean is 4.1. ///
"\end{tablenotes}")

/* PeterPrinciple.tex (old structure)
esttab reg1 reg2 reg3 reg4 using "$analysis/Results/5.Mechanisms/PeterPrinciple.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(*EarlyAgeM *EarlyAgeM1) se r2 ///
s(  N r2, labels( "N" "R-squared" ) ) rename(PostEarlyAgeM EarlyAgeM PostEarlyAgeM1 EarlyAgeM1) interaction("$\times$ ")    ///
nomtitles mgroups( "Pay (in logs) | Promoted to Manager" "Effective Leader scored by reportees", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: country and year FE, worker tenure squared interacted with gender.  ///
\textit{Effective Leader} is the workers' anonymous rating of the manager via the survey question \textit{My line manager is an effective leader}. \textit{Effective Leader} is measured on a Likert scale 1 - 5 and the mean is 4.1. ///
"\end{tablenotes}") replace
*/

/**# previously a figure, ON PAPER FIGURE: PeterPrincipleLHE.png
coefplot (reg1, rename(PostEarlyAgeM ="Pay (in logs) | Promoted to Manager" )) (reg3,rename(EarlyAgeM ="Effective Leader scored by reportees" )) ,  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
 aseq  aspect(0.4)  coeflabels(, ) ysize(6) xsize(8) xscale(range(0 .6)) xlabel(0(0.1)0.6) ///
title("Gaining a high flyer manager", pos(12) span si(medium)) ///
 xline(0, lpattern(dash)) keep(EarlyAgeM PostEarlyAgeM ) legend(off)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrincipleLH.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrincipleLH.gph", replace 

**#  previously a figure, ON PAPER FIGURE: NewJobAE.png
coef ON PAPER FIGURE: PeterPrincipleHLE.png
coefplot (reg2, rename(PostEarlyAgeM1 ="Pay (in logs) | Promoted to Manager" )) (reg4,rename(EarlyAgeM1 ="Effective Leader scored by reportees" )) ,  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
 aseq  aspect(0.4)  coeflabels(, ) ysize(6) xsize(8) xscale(range(-0.5 .5)) xlabel(-0.5(0.1)0.5) ///
title("Losing a high flyer manager", pos(12) span si(medium)) ///
 xline(0, lpattern(dash)) keep(EarlyAgeM1 PostEarlyAgeM1 ) legend(off)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrincipleHL.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrincipleHL.gph", replace 
*/

**************************** team level analysis at the month level - ASYMMETRIC

use "$managersdta/Temp/TeamSwitchers.dta" , clear 
 xtset  IDteam YearMonth

cap drop EarlyAgeM 
gen IDlseMHR = IDlseMHRPrePost 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MType.dta" , keepusing(EarlyAgeM)
*keep if Year>2013 // post sample only if using PromSG75
drop if _merge ==2 
drop _merge 

bys IDteam: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys IDteam: egen minK = min(KEi)
bys IDteam: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

foreach var in FT { // Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015
	
xtset IDteam YearMonth 
gen diff`var' = d.EarlyAgeM // can be replace with d.EarlyAgeM
gen Delta`var'tag = diff`var' if KEi==0
bys IDteam: egen Delta`var' = mean(Delta`var'tag)

drop  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
gen `var'LHPost = KEi >=0 & `var'LH!=.
gen `var'LLPost = KEi >=0 & `var'LL!=.
gen `var'HHPost = KEi >=0 & `var'HH!=.
gen `var'HLPost = KEi >=0 & `var'HL!=.

egen `var'Post = rowmax( `var'LHPost `var'LLPost `var'HLPost `var'HHPost ) 

gen `var'PostDelta = `var'Post*Delta`var'
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
label var `var'Post "Event"
label var `var'PostDelta "Event*Delta M. Talent"
label var Delta`var' "Delta M. Talent"
} 

foreach Label in FT { //  Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
	replace `var'Pre = . if `Label'LH==. & `Label'LL ==. & `Label'HH ==. & `Label'HL ==. // missing for non-switchers
	
}
	label var  `Label'LHPre "Low to High"
	label  var `Label'LLPre "Low to Low"
	label  var `Label'HLPre "High to Low"
	label var  `Label'HHPre "High to High"
}

* Table: Prom. (salary) / Pay Growth / Pay (CV) /   Perf. Appraisals (CV)
* Table: exit firm / change team / join team /  job change same m 
* Table: ShareSameG ShareSameAge ShareSameNationality ShareSameOffice

foreach var in FT Effective PromSG75 PromWL75  PromSG50 PromWL50{
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
} 

gen lAvPay = log(AvPay)
label var lAvPay "Pay + Bonus (logs)"

* Define variable globals 
label var ShareTransferSJ  "Lateral moves"
label var  ShareSameNationality "Same Nationality"

global perf  ShareChangeSalaryGrade SharePromWL lAvPay  CVPay  CVVPA  // AvPayGrowth
global move   ShareTransferSJ  
global homo  ShareSameG  ShareSameAge  ShareSameOffice  ShareSameNationality 
*ShareSameCountry  
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracNat TeamFracCountry    
global job NewJob OldJob NewJobManager OldJobManager
global out  SpanM SharePromWL AvPay AvProductivityStd SDProductivityStd  ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat

* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 
* TeamEthFrac

foreach var in FuncM WLM AgeBandM CountryM  FemaleM{
bys IDteam YearMonth: egen m`var' = mode(`var'), max
replace m`var'  = round(m`var' ,1)
replace `var' = m`var'
}

global controls  FuncM WLM AgeBandM CountryM Year
global cont SpanM c.TenureM##c.TenureM##i.FemaleM

* WL2 managers
bys IDteam: egen prewl = max(cond(KEi==-1,WLM,.))
bys IDteam: egen postwl = max(cond(KEi==0,WLM,.))
ge WL2 = prewl >1 & postwl>1

* generate categories for coefficient of variation 
local var FT // FT PromSG75
gen trans = 1 if `var'LHPost==1 
replace trans = 2 if `var'LLPost==1
replace trans = 3 if `var'HLPost==1
replace trans = 4 if `var'HHPost==1
label def trans 1 "Low to High" 2 "Low to Low" 3 "High to Low" 4 "High to High" 
label value trans trans 

* independent variable - regressor 
gen HighF1 = trans==1
gen HighF2 = trans ==3

gen HighF1p = FTLH!=. & KEi<0
gen HighF2p = FTHL!=. & KEi<0

********************************************************************************
* TEAM INEQUALITY - CV
********************************************************************************

eststo lh: reg CVPay HighF1 if KEi >=12  & KEi <=60 & trans <3  & WL2 ==1, vce( cluster IDlseMHR)
eststo hl: reg CVPay HighF2 if KEi >=12 & KEi <=60 & trans >=3 & trans!=.  & WL2 ==1, vce( cluster IDlseMHR)
label var HighF1 "Pay inequality, gain good manager" 
 label var HighF2 "Pay inequality, lose good manager" 

* option for all coefficient plots
global coefopts keep(HighF*)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
 aseq ///
scale(1)  legend(off) ///
aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black)) 

/*
coefplot lh hl,   $coefopts xline(0, lpattern(dash)) xscale(range(-.1 .1)) xlabel(-.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlot.pdf", replace 
graph save "$analysis/Results/8.Team/CVPlot.gph", replace 
*/

* separately by time horizon 
********************************************************************************

forval i = 1/12{
foreach v in lhp`i' hlp`i' {
gen `v' = 1 
label var `v' "-`i'"
}
}

* AVOID OVERCROWDED LABELS ON GRAPH 
forval i = 1(2)11{
foreach v in lhp`i' hlp`i' {
label var `v' " "
}
}


forval j = 1/29{
foreach v in lh`j' hl`j'  {
gen `v' = 1 
local c = `j'-1
label var `v' "`c'"
}
}

* AVOID OVERCROWDED LABELS ON GRAPH 
forval j = 2(2)28{
foreach v in lh`j' hl`j'  {
local c = `j'-1
label var `v' " "
}
}

eststo clear
eststo lhp1: reg CVPay HighF1p if KEi >=-3  & KEi <0 & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp1: reg CVPay HighF2p if KEi >=-3 & KEi <0 & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = -3
forval i = 2/12{
local m = `i'*3

eststo lhp`i': reg CVPay HighF1p if KEi >=-`m'  & KEi <-`m1' & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp`i': reg CVPay HighF2p if KEi >=-`m' & KEi <-`m1' & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = `m'
} 

eststo lh1: reg CVPay HighF1 if KEi >=0  & KEi <3 & trans <3  & WL2 ==1, vce( cluster IDlseMHR)
eststo hl1: reg CVPay HighF2 if KEi >=0 & KEi <3 & trans >=3 & trans!=.  & WL2 ==1, vce( cluster IDlseMHR)
local m1 = 3
forval i = 2/29{
local m = `i'*3 -1 

eststo lh`i': reg CVPay HighF1 if KEi >=`m1'  & KEi <=`m' & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hl`i': reg CVPay HighF2 if KEi >=`m1' & KEi <=`m' & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = `m'
} 

* SIMPLE GRAPH LH
********************************************************************************
/*
coefplot  ( lh12 , keep(HighF1) rename(  HighF1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 ( lh20, keep(HighF1) rename(  HighF1  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  ( lh28 , keep(HighF1) rename(  HighF1 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)   ///
 title("Coefficient of variation in pay, team level", size(medsmall))  levels(95) xline(0, lpattern(dash))  xlabel(0(0.02)0.1) ///
note("Notes. Plotting estimates at 12, 20 and 28 quarters after manager transition. Reporting 95% confidence intervals.", span)
graph export "$analysis/Results/8.Team/CVPlotLH.pdf", replace 
graph save "$analysis/Results/8.Team/CVPlotLH.gph", replace 
*/

**# ON PAPER FIGURE: CVPlotLHAE.png
coefplot  ( lh12 , keep(HighF1) rename(  HighF1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 ( lh20, keep(HighF1) rename(  HighF1  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  ( lh28 , keep(HighF1) rename(  HighF1 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)   ///
 title("Coefficient of variation in pay, team level", size(medsmall))  levels(95) xline(0, lpattern(dash))  xlabel(0(0.02)0.1)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/CVPlotLHA.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/CVPlotLHA.gph", replace 

/* SIMPLE GRAPH HL
********************************************************************************

coefplot  ( hl12 , keep(HighF2) rename(  HighF2  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 ( hl20, keep(HighF2) rename(  HighF2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  ( hl28 , keep(HighF2) rename(  HighF2 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)   ///
 title("Coefficient of variation in pay, team level", size(medsmall))  levels(95) xline(0, lpattern(dash))  xlabel(-0.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotHLA.pdf", replace 
graph save "$analysis/Results/8.Team/CVPlotHLA.gph", replace 

coefplot  ( hl12 , keep(HighF2) rename(  HighF2  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 ( hl20, keep(HighF2) rename(  HighF2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  ( hl28 , keep(HighF2) rename(  HighF2 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)   ///
 title("Coefficient of variation in pay, team level", size(medsmall))  levels(95) xline(0, lpattern(dash))  xlabel(-0.1(0.02)0.1) ///
 note("Notes. Plotting estimates at 12, 20 and 28 quarters after manager transition. Reporting 95% confidence intervals.", span)
graph export "$analysis/Results/8.Team/CVPlotHL.pdf", replace 
graph save "$analysis/Results/8.Team/CVPlotHL.gph", replace 

********************************************************************************
* FULL GRAPH 
********************************************************************************

* option for all coefficient plots
* lwidth(0.8 ..)  msymbol() aspect(0.4) ysize(8) xsize(8)
global coefopts keep(HighF*)  levels(95) ///
ciopts(recast(rcap) lcolor(ebblue))  mcolor(ebblue) /// 
 aseq swapnames xline(12, lcolor(maroon) lpattern(dash))  yline(0, lcolor(maroon) lpattern(dash)) ///
scale(1)  vertical legend(off) ///
 coeflabels(, )   ytick(,grid glcolor(black))  xtitle(Quarters since manager change) omitted
 
su CVPay  if KEi>=58 & KEi<=60 & FTLL!=.
di  0.05/  .2803382 // 18%

eststo lhp1: reg CVPay HighF1p if KEi >=1  & KEi <=1 & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp1: reg CVPay HighF2p if KEi >=1 & KEi <=1 & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)

coefplot lhp12 lhp11 lhp10 lhp9 lhp8 lhp7 lhp6 lhp5 lhp4 lhp3 lhp2 lhp1 lh1 lh2 lh3 lh4 lh5 lh6 lh7 lh8 lh9 lh10 lh11 lh12 lh13 lh14 lh15 lh16 lh17 lh18 lh19 lh20 lh21  ,   ///
 title("Coefficient of variation in pay, team-level") $coefopts  yscale(range(-.06 .06)) ylabel(-.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotYearLHQ5.pdf", replace 
graph save "$analysis/Results/8.Team/CVPlotYearLHQ5.gph", replace 

coefplot hlp12 hlp11 hlp10 hlp9 hlp8 hlp7 hlp6 hlp5 hlp4 hlp3 hlp2 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10 hl11 hl12 hl13 hl14 hl15 hl16 hl17 hl18 hl19 hl20 hl21 ,   ///
 title("Coefficient of variation in pay, team-level")  $coefopts  yscale(range(-.25 .25)) ylabel(-.25(0.05)0.25)
graph export "$analysis/Results/8.Team/CVPlotYearHLQ5.pdf", replace 
graph save "$analysis/Results/8.Team/CVPlotYearHLQ5.gph", replace 

coefplot lhp12 lhp11 lhp10 lhp9 lhp8 lhp7 lhp6 lhp5 lhp4 lhp3 lhp2 lhp1 lh1 lh2 lh3 lh4 lh5 lh6 lh7 lh8 lh9 lh10 lh11 lh12 lh13 lh14 lh15 lh16 lh17 lh18 lh19 lh20 lh21  lh22 lh23 lh24 lh25 lh26 lh27 lh28 lh29 ,   ///
 title("Coefficient of variation in pay, team-level") $coefopts  yscale(range(-.06 .06)) ylabel(-.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotYearLHQ7.pdf", replace 
graph save "$analysis/Results/8.Team/CVPlotYearLHQ7.gph", replace 

coefplot hlp12 hlp11 hlp10 hlp9 hlp8 hlp7 hlp6 hlp5 hlp4 hlp3 hlp2 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10 hl11 hl12 hl13 hl14 hl15 hl16 hl17 hl18 hl19 hl20 hl21 hl22 hl23 hl24 hl25 hl26 hl27 hl28 hl29 ,   ///
 title("Coefficient of variation in pay, team-level")  $coefopts  yscale(range(-.25 .25)) ylabel(-.25(0.05)0.25)
graph export "$analysis/Results/8.Team/CVPlotYearHLQ7.pdf", replace 
graph save "$analysis/Results/8.Team/CVPlotYearHLQ7.gph", replace 

* Event study
********************************************************************************

drop   FTLowHigh  FTLowLow
gen FTLowHigh = KEi==0 & trans==1
gen FTLowLow = KEi==0 & trans==2

esplot CVPay if     (FTLH!=. | FTLL!=. ) & WL2 ==1, event( FTLowHigh, save) compare( FTLowLow, save) window(-12 60 , ) period(3) estimate_reference  legend(off) yline(0) xline(-1)  xlabel(-12(2)20) xtitle(Quarters since manager change)  vce(cluster IDlseMHR)
graph export "$analysis/Results/8.Team/FTEventCVLH.pdf", replace 
graph save "$analysis/Results/8.Team/FTEventCVLH.gph", replace

esplot CVPay if     (FTHL!=. | FTHH!=. ) & WL2 ==1, event( FTHighLow, save) compare( FTHighHigh, save) window(-12 60 , ) period(3) estimate_reference  legend(off) yline(0) xline(-1)  xlabel(-12(2)20) xtitle(Quarters since manager change)  vce(cluster IDlseMHR) 
graph export "$analysis/Results/8.Team/FTEventCVHL.pdf", replace 
graph save "$analysis/Results/8.Team/FTEventCVHL.gph", replace

********************************************************************************
* LOW TO HIGH 
********************************************************************************

* Baseline mean 
bys IDteam: egen tranInv = mean(trans)
su CVPay if KEi <0 & KEi >=-36& WL2==1
su CVPay if KEi <0 & KEi >=-36& tranInv <3 & WL2==1
su CVPay if KEi <0 & KEi >=-36& tranInv >=3 & tranInv<=4 & WL2==1

local Label FT // FT PromSG75
distinct IDteam if KEi >=12 & KEi <=36 & trans ==1 & WL2==1
local n1 =     r(ndistinct) 
distinct IDteam if KEi >=12 & KEi <=36 & trans ==2  & WL2==1
local n2 =     r(ndistinct)
cibar CVPay if KEi >=12 & KEi <=36 & trans <3  & WL2 ==1, level(95) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay") note("Notes. Average monthly coeff. var in pay, 1-3 years of the manager transition." "Standard errors clustered at the manager level. 95% confidence intervals""`n1' teams in the low to high group and `n2' teams in the low to low group.", size(medsmall)) ytitle("Percentage points") scheme(white_ptol) legend(rows(1) position(1)) yscale(range(0.28 0.36)) ylabel(0.28(0.01)0.36)) 
graph export "$analysis/Results/8.Team/`Label'FunnelCVLH.pdf", replace 
graph save "$analysis/Results/8.Team/`Label'FunnelCVLH.gph", replace

********************************************************************************
* HIGH to LOW
********************************************************************************

local Label FT // FT PromSG75
distinct IDteam if KEi >=12 & KEi <=36 & trans ==3  & WL2==1
local n1 =     r(ndistinct) 
distinct IDteam if KEi >=12 & KEi <=36 & trans ==4 & WL2==1
local n2 =     r(ndistinct) 
cibar CVPay if KEi >=12 & KEi <=36 & trans >=3 & trans<=4 & WL2==1, level(95) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay") note("Notes. Average monthly coeff. var in pay, 1-3 years of the manager transition." "Standard errors clustered at the manager level. 95% confidence intervals" "`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue)  legend(rows(1) position(1)) yscale(range(0.28 0.36)) ylabel(0.28(0.01)0.36) ) 
graph export "$analysis/Results/8.Team/`Label'FunnelCVHL.pdf", replace 
graph save "$analysis/Results/8.Team/`Label'FunnelCVHL.gph", replace
*/

********************************************************************************
* ENDOGENOUS MOBILITY CHECKS 
********************************************************************************

********************************************************************************
* 1) INSTEAD OF LOOKING AT MANAGER TRANSITIONS, LOOK SIMPLY AT FUTURE MANAGER, NOT MANAGERIAL CHANGES
* this test checks: can I predict the future manager quality, irrespective of which manager I had before? this pools together teams that had a bad or a good manager as the start so this also tells me that the future manager type is unrelated to previous manager type (not more likely to get a high manager if previously I had a high manager)
* the previous test, looking at manager change, says, given a team starts with the same type of manager quality, can I predict whether it gets a good or a bad manager next? so given I start with a low manager, does it matter my performance to get a high/low manager next?  
********************************************************************************

use "$managersdta/Temp/TeamSwitchers.dta" , clear 
 xtset  IDteam YearMonth

cap drop EarlyAgeM 
gen IDlseMHR = IDlseMHRPrePost 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MType.dta" , keepusing(EarlyAgeM)
*keep if Year>2013 // post sample only if using PromSG75
drop if _merge ==2 
drop _merge 

bys IDteam: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys IDteam: egen minK = min(KEi)
bys IDteam: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

foreach var in FT { // Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015
	
xtset IDteam YearMonth 
gen diff`var' = d.EarlyAgeM // can be replace with d.EarlyAgeM
gen Delta`var'tag = diff`var' if KEi==0
bys IDteam: egen Delta`var' = mean(Delta`var'tag)

drop  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
gen `var'LHPost = KEi >=0 & `var'LH!=.
gen `var'LLPost = KEi >=0 & `var'LL!=.
gen `var'HHPost = KEi >=0 & `var'HH!=.
gen `var'HLPost = KEi >=0 & `var'HL!=.

egen `var'Post = rowmax( `var'LHPost `var'LLPost `var'HLPost `var'HHPost ) 

gen `var'PostDelta = `var'Post*Delta`var'
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
label var `var'Post "Event"
label var `var'PostDelta "Event*Delta M. Talent"
label var Delta`var' "Delta M. Talent"
} 

foreach Label in FT { //  Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
	replace `var'Pre = . if `Label'LH==. & `Label'LL ==. & `Label'HH ==. & `Label'HL ==. // missing for non-switchers
	
}
	label var  `Label'LHPre "Low to High"
	label  var `Label'LLPre "Low to Low"
	label  var `Label'HLPre "High to Low"
	label var  `Label'HHPre "High to High"
}

* fix double counting issue 
ta FTLLPre FTHLPre 
ta FTLHPre FTHHPre 
ta FTLLPost FTHLPost 
ta FTLHPost FTHHPost

replace FTLLPre=0 if FTHLPre ==1
replace FTLHPre=0 if FTHHPre ==1

replace FTLLPost=0 if FTHLPost ==1
replace FTLHPost=0 if FTHHPost ==1

* Table: Prom. (salary) / Pay Growth / Pay (CV) /   Perf. Appraisals (CV)
* Table: exit firm / change team / join team /  job change same m 
* Table: ShareSameG ShareSameAge ShareSameNationality ShareSameOffice

foreach var in FT Effective PromSG75 PromWL75  PromSG50 PromWL50{
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
} 

gen lAvPay = log(AvPay)


* Define variable globals & label variables 

global perf  lAvPay ShareChangeSalaryGrade SharePromWL    // AvPayGrowth CVPay  CVVPA 
global move ShareTransferSJSameM //  ShareTransferSJ  
global homo  ShareSameG  ShareSameAge  ShareSameOffice  ShareSameNationality 
*ShareSameCountry  
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracNat // TeamFracCountry    
global job NewJob OldJob NewJobManager OldJobManager
global out  SpanM SharePromWL AvPay AvProductivityStd SDProductivityStd  ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat

label var ShareChangeSalaryGrade "Salary grade increase"
label var SharePromWL "Vertical move (WL)"
label var lAvPay "Salary (logs)"
label var CVVPA "Perf. ratings (C.V.)" 
label var ShareTransferSJ  "Lateral move"

label var TeamFracGender "Diversity, gender"
label var TeamFracAge "Diversity, age"
label var TeamFracOffice "Diversity, office"
label var TeamFracNat "Diversity, nationality"

label var ShareSameG "Same gender"
label var ShareSameAge "Same age"
label var ShareSameOffice "Same office"
label var ShareSameNationality "Same nationality" 

* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 
* TeamEthFrac

foreach var in FuncM WLM AgeBandM CountryM  FemaleM{
bys IDteam YearMonth: egen m`var' = mode(`var'), max
replace m`var'  = round(m`var' ,1)
replace `var' = m`var'
}


global controls FuncM CountryM Year // FuncM WLM AgeBandM 
global cont  // c.TenureM##c.TenureM##i.FemaleM

local i = 1
local Label FT // FT PromSG75
egen `Label'HPre = rowmax( `Label'LHPre `Label'HHPre )
egen `Label'LPre = rowmax( `Label'LLPre `Label'HLPre )

label var  `Label'HPre  "High-flyer manager"

eststo clear
local Label FT // FT PromSG75
foreach y in  $perf $move $homo $div {
	
eststo reg`i':	reghdfe `y'  `Label'HPre `Label'LPre $cont if SpanM>1 & KEi<=-6 & KEi >=-36 & WLM==2,  cluster(IDlseMHR) a( $controls )
local lbl : variable label `y'
estadd local Controls "Yes" , replace
estadd local TeamFE "No" , replace
estadd ysumm 
local i = `i' +1

}

esttab  reg1 reg2 reg3  reg4  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

esttab  reg5 reg6 reg7  reg8  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

esttab reg9  reg10 reg11  reg12 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) )  keep( *HPre  )


* TABLES TO EXPORT 
********************************************************************************

local Label FT // FT PromSG75

/*
**# ON PAPER TABLE: PreFTPerf.tex
esttab  reg1 reg2 reg3  reg4 using "$analysis/Results/0.Paper/3.3.Other Analysis/Pre`Label'Perf.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(ymean N r2 , labels("\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. \textit{Salary (logs)} is the log of the average salary in the team; \textit{Salary grade increase} is share of workers with a salary increase; \textit{Vertical move (WL)} is share of workers with a work-level promotion; and \textit{Lateral move} is share of workers that make a lateral move.   ///
"\end{tablenotes}") replace

* \textit{Perf. Appraisals (C.V.)} is the coefficient of variation in the performance appraisals; 
**# ON PAPER TABLE: PreFTHomo.tex
esttab  reg5 reg6 reg7  reg8 using "$analysis/Results/0.Paper/3.3.Other Analysis/Pre`Label'Homo.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(ymean N r2 , labels( "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level.  Controls include: function, country and year FE. Each outcome variable is the share of workers that share the same characteristic with the manager (gender, age group, office, nationality). ///
"\end{tablenotes}") replace

**# ON PAPER TABLE: PreFTDiv.tex
esttab reg9  reg10 reg11  reg12 using "$analysis/Results/0.Paper/3.3.Other Analysis/Pre`Label'Div.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s( ymean N r2 , labels( "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE.  Each outcome variable is a fractionalization index (1- Herfindahl–Hirschman index) for the relevant characteristic; it is 0 when all team members are the same and it is 1 when there is maximum team diversity. ///
"\end{tablenotes}") replace
*/

* merge three tables above into one with 3 panels
********************************************************************************

**# ON PAPER TABLE: PreFTCombined.tex (Panel A)
esttab reg1 reg2 reg3 reg4 using "$analysis/Results/0.Paper/3.3.Other Analysis/PreFTCombined.tex", ///
replace ///
prehead("\begin{tabular}{l*{4}{c}} \hline\hline \\ \multicolumn{5}{c}{\textit{Panel (a): team performance}} \\\\[-1ex]") ///
fragment ///
label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(ymean N r2 , labels("Mean" "N" "R-squared")) ///
interaction("$\times$") nobaselevels keep(*HPre) ///
nofloat nonotes

* PreFTCombined.tex (Panel B)
esttab reg9 reg10 reg11 reg12 using "$analysis/Results/0.Paper/3.3.Other Analysis/PreFTCombined.tex", ///
prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (b): team diversity}} \\\\[-1ex]") ///
fragment ///
append ///
label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(ymean N r2 , labels( "Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre ) ///
nofloat nonotes

* PreFTCombined.tex (Panel C)
esttab reg5 reg6 reg7 reg8 using "$analysis/Results/0.Paper/3.3.Other Analysis/PreFTCombined.tex", ///
prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (c): team homophily with managers}} \\\\[-1ex]") ///
fragment ///
append ///
label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s( ymean N r2 , labels( "Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. In Panel (a), \textit{Salary (logs)} is the log of the average salary in the team; \textit{Salary grade increase} is share of workers with a salary increase; \textit{Vertical move (WL)} is share of workers with a work-level promotion; and \textit{Lateral move} is share of workers that make a lateral move. In Panel (b), each outcome variable is a fractionalization index (1- Herfindahl–Hirschman index) for the relevant characteristic; it is 0 when all team members are the same and it is 1 when there is maximum team diversity. In Panel (c), each outcome variable is the share of workers that share the same characteristic with the manager (gender, age group, office, nationality). ///
"\end{tablenotes}")

* COMPUTATION OF SIGNIFICANCE WITH MULTIPLE HYPOTHESIS TESTING 
* 12 hypotheses, at least one significant at 10% level: di 1-(0.9)^12 = 72% chance 
* 12 hypotheses, at least one significant at 5% level: di 1-(0.95)^12 = 46% chance 
* 24 hypotheses, at least one significant at 5% level: di 1-(0.95)^24 = 71% chance 


********************************************************************************
* 2) MANAGER TRANSITIONS - CROSS SECTION PRE  - ASYMMETRIC
********************************************************************************

eststo clear

local i = 1
local Label FT // FT PromSG75

foreach y in $perf $move $homo $div {
	
	eststo reg`i'A: reghdfe `y' `Label'LHPre `Label'HHPre `Label'HLPre `Label'LLPre $cont if SpanM>1 & KEi<=-6 & KEi >=-36 & WLM==2 , cluster(IDlseMHR) a($controls)
	local lbl : variable label `y'
	lincom `Label'HLPre - `Label'HHPre
	estadd scalar pvalue2 = r(p)
	estadd scalar diff2 = r(estimate)
	estadd scalar se_diff2 = r(se)  
	lincom `Label'LHPre - `Label'LLPre
	estadd scalar pvalue1 = r(p)
	estadd scalar diff1 = r(estimate)
	estadd scalar se_diff1 = r(se)  
	estadd local Controls "Yes", replace
	estadd local TeamFE "No", replace
	estadd ysumm 
	local i = `i' + 1
}


esttab reg1A reg2A reg3A  reg4A ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s( Controls TeamFE ymean N r2 diff1 pvalue1 se_diff1 diff2 pvalue2 se_diff2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "Standard Error:" "HtoL - HtoH" "p-value:" "Standard Error:") ) keep( *LHPre *HHPre  *HLPre *LLPre ) 

esttab reg5A reg6A reg7A  reg8A ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s( Controls TeamFE ymean N r2 diff1 pvalue1 se_diff1 diff2 pvalue2 se_diff2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "Standard Error:" "HtoL - HtoH" "p-value:" "Standard Error:") ) keep( *LHPre *HHPre  *HLPre *LLPre ) 

esttab reg9A  reg10A reg11A  reg12A,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s( Controls TeamFE ymean N r2 diff1 pvalue1 se_diff1 diff2 pvalue2 se_diff2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "Standard Error:" "HtoL - HtoH" "p-value:" "Standard Error:") ) keep( *LHPre *HHPre  *HLPre *LLPre ) 

* TABLES TO EXPORT 
********************************************************************************

local Label FT // FT PromSG75

/*
**# ON PAPER TABLE: PreFTPerfTR.tex
esttab reg1A reg2A reg3A  reg4A using "$analysis/Results/0.Paper/3.3.Other Analysis/Pre`Label'PerfTR.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s( ymean N r2  diff2 pvalue2, labels( "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) )  interaction("$\times$ ")  nobaselevels  keep( *LHPre *HHPre  *HLPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. \textit{Salary (logs)} is the log of the average salary in the team; \textit{Salary grade increase} is share of workers with a salary increase; \textit{Vertical move (WL)} is share of workers with a work-level promotion; and \textit{Lateral move} is share of workers that make a lateral move. ///
"\end{tablenotes}") replace

**# ON PAPER TABLE: PreFTHomoTR.tex
esttab reg5A reg6A reg7A  reg8A  using "$analysis/Results/0.Paper/3.3.Other Analysis/Pre`Label'HomoTR.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s( ymean N r2  diff2 pvalue2, labels( "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) ) interaction("$\times$ ")  nobaselevels  keep( *LHPre  *HHPre  *HLPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. Each outcome variable is the share of workers that share the same characteristic with the manager (gender, age group, office, nationality).  ///
"\end{tablenotes}") replace

**# ON PAPER TABLE: PreFTDivTR.tex
esttab reg9A  reg10A reg11A  reg12A using "$analysis/Results/0.Paper/3.3.Other Analysis/Pre`Label'DivTR.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s( ymean N r2  diff2 pvalue2, labels( "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) ) interaction("$\times$ ")  nobaselevels  keep( *LHPre  *HHPre  *HLPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. Each outcome variable is a fractionalization index (1- Herfindahl–Hirschman index) for the relevant characteristic; it is 0 when all team members are the same and it is 1 when there is maximum team diversity.  ///
"\end{tablenotes}") replace
*/

* merge three tables above into one with 3 panels
********************************************************************************

* Manual adjustments for tex table to be done after running the code:
* remove the three \hline in excess
* add the double significane star to first row col. 4 panel (a)

**# ON PAPER TABLE: PreFTCombinedTR.tex (Panel A)
esttab reg1A reg2A reg3A reg4A using "$analysis/Results/0.Paper/3.3.Other Analysis/PreFTCombinedTR.tex", ///
replace ///
prehead("\begin{tabular}{l*{4}{c}} \hline\hline \\ \multicolumn{5}{c}{\textit{Panel (a): team performance}} \\\\[-1ex]") ///
fragment ///
label ///
stats( diff1 pvalue1 diff2 pvalue2 ymean N r2, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean" "N" "R-squared") ) ///
interaction("$\times$") nobaselevels nofloat nonotes  noobs ///
drop( *LHPre *HHPre *HLPre *LLPre _cons ) 

* PreFTCombinedTR.tex (Panel B)
esttab reg9A reg10A reg11A reg12A using "$analysis/Results/0.Paper/3.3.Other Analysis/PreFTCombinedTR.tex", ///
prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (b): team diversity}} \\\\[-1ex]") ///
fragment ///
append ///
label ///
s( diff1 pvalue1 diff2 pvalue2 ymean N r2, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean" "N" "R-squared") ) ///  
interaction("$\times$ ") nofloat nonotes nobaselevels noobs ///
drop( *LHPre *HHPre *HLPre *LLPre _cons ) ///

* PreFTCombinedTR.tex (Panel C)
esttab reg5A reg6A reg7A reg8A using "$analysis/Results/0.Paper/3.3.Other Analysis/PreFTCombinedTR.tex", ///
prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (c): team homophily with managers}} \\\\[-1ex]") ///
fragment ///
append ///
label ///
s( diff1 pvalue1 diff2 pvalue2 ymean N r2, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean" "N" "R-squared") ) /// 
interaction("$\times$ ") nobaselevels nofloat nonotes noobs ///
drop( *LHPre *HHPre *HLPre *LLPre _cons ) ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. In Panel (a), \textit{Salary (logs)} is the log of the average salary in the team; \textit{Salary grade increase} is share of workers with a salary increase; \textit{Vertical move (WL)} is share of workers with a work-level promotion; and \textit{Lateral move} is share of workers that make a lateral move. In Panel (b), each outcome variable is a fractionalization index (1- Herfindahl–Hirschman index) for the relevant characteristic; it is 0 when all team members are the same and it is 1 when there is maximum team diversity. In Panel (c), each outcome variable is the share of workers that share the same characteristic with the manager (gender, age group, office, nationality). ///
"\end{tablenotes}")


********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE, team level analysis at the month level - ASYMMETRIC
********************************************************************************

global Label FT

use "$managersdta/Teams.dta" , clear 

*keep if Year>2013 // post sample only 

bys team: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys team: egen minK = min(KEi)
bys team: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

* only select WL2+ managers 
bys team: egen WLMEi =mean(cond(KEi == 0, WLM,.))
bys team: egen WLMEiPre =mean(cond(KEi ==- 1, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1 if (WLMEi !=. & WLMEiPre !=.)

foreach var in FT {
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
label  var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label  var  `var'HHPost "High to High"
} 

foreach Label in FT {
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
	replace `var'Pre = . if `Label'LH==. & `Label'LL ==. & `Label'HH ==. & `Label'HL ==. // missing for non-switchers
	
}
	label  var  `Label'LHPre "Low to High"
	label  var `Label'LLPre "Low to Low"
	label  var `Label'HLPre "High to Low"
	label  var  `Label'HHPre "High to High"
}

* Table: Prom. (salary) / Pay Growth / Pay (CV) /   Perf. Appraisals (CV)
* Table: exit firm / change team / join team /  job change same m 
* Table: ShareSameG ShareSameAge ShareSameNationality ShareSameOffice

* Define variable globals 
global perf   AvPayGrowth CVVPA VPA101 VPAL80
global move  ShareTeamLeavers ShareTransferFunc   ShareLeaver  //ShareTransferSJ
global homo  ShareSameG  ShareSameAge  ShareSameOffice ShareSameCountry F1ShareConnected F1ShareConnectedL F1ShareConnectedV
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracCountry    
global out  ShareTeamJoiners   CVPay    ShareChangeSalaryGrade SharePromWL AvPay AvProductivityStd SDProductivityStd ShareExitTeam ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat 
* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 
global charsExitFirm  LeaverPermFemale LeaverPermAge20 LeaverPermEcon LeaverPermSci LeaverPermHum  LeaverPermNewHire LeaverPermTenure5 LeaverPermEarlyAge LeaverPermPayGrowth1yAbove1 
global charsExitTeam ExitTeamFemale ExitTeamAge20 ExitTeamEcon ExitTeamSci ExitTeamHum  ExitTeamNewHire ExitTeamTenure5 ExitTeamEarlyAge ExitTeamPayGrowth1yAbove1 
global charsJoinTeam  ChangeMFemale ChangeMAge20 ChangeMEcon ChangeMSci ChangeMHum  ChangeMNewHire ChangeMTenure5 ChangeMEarlyAge ChangeMPayGrowth1yAbove1 
global charsChangeTeam F1ChangeMFemale F1ChangeMAge20 F1ChangeMEcon F1ChangeMSci F1ChangeMHum  F1ChangeMNewHire F1ChangeMTenure5 F1ChangeMEarlyAge F1ChangeMPayGrowth1yAbove1  

* TeamEthFrac
global controls  FuncM WLM AgeBandM CountryM Year
global cont SpanM c.TenureM##c.TenureM##i.FemaleM 

* regressions 
********************************************************************************

sort IDlseMHR YearMonth

eststo clear
local i = 1
	local Label FT // FT PromSG75
foreach y in  $perf $move     { // $homo $div

/*mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
*/

eststo reg`i'FE:	reghdfe `y' $`Label'   if WLM2==1 & KEi<=24 & KEi>=-24, a(   team Year) cluster(IDlseMHR)

local lbl : variable label `y'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(95) post
est store  creg`i'FE
local i = `i' +1
}
su AvPayGrowth ShareTeamLeavers ShareTransferFunc   ShareLeaver CVVPA VPA101 VPAL80  if FTLLPost ==1

* Altogether LH
**# ON PAPER FIGURE: TeamCoeffLHE.png
coefplot (creg5FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Job change, lateral")  ciopts(lwidth(2 ..) lcolor(ebblue) ) msymbol(d) mcolor(white) ) /// 
		 (creg6FE,  keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Job change, cross-function")  ciopts(lwidth(2 ..) lcolor(ebblue) ) msymbol(d) mcolor(white) ) /// 
		 (creg7FE,  keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Exit from firm")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) /// 
		 (creg1FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Average pay growth" )  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg3FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Share good perf. ratings")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg4FE,  keep(lc_1) transform(* = 100*(@))  rename(  lc_1  = "Share bottom perf. ratings")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg2FE,  keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Coeff. variation in perf. ratings")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 , aspectratio(.6) legend(off) title("Gaining a high-flyer manager", size(medsmall)) xtitle("Percentage points, monthly frequency") level(95) xline(0, lpattern(dash)) ///
		 ysize(6) xsize(8) xscale(range(-0.5 1.5) ) xlabel(-0.5(0.25)1.5, ) ylabel(,labsize(medsmall))
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/TeamCoeffLH.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/TeamCoeffLH.gph", replace 


**********************************************************************
* PLOT: NEW HIRES + INCOMING WORKERS 
**********************************************************************

******-> First new hires 

use "$managersdta/AllSameTeam2.dta", clear 

gen Post = KEi >=0 if KEi!=.

keep if TenureMin<1 // select new hires 
bys IDlse: egen my = min(YearMonth)
format my %tm
gen year1 = my + 12 
gen year2 = my + 24 
gen year3 = my + 36
gen year4 = my + 48
gen year5 = my + 60
gen year7 = my + 84

gen yearmid = my + 6
format year1 %tm // first year of new hire 

* New Hires 

bys IDlse: egen HF0 = mean(cond(YearMonth ==my , EarlyAgeM, .) )
bys IDlse: egen WLM0 = mean(cond(YearMonth ==my , WLM, .) )


* NEW HIRES: By manager transition
****************************************************************************

foreach var in  LogPayBonus { // PayGrowth LogPay LogBonus VPA VPA100 VPA125 ChangeSalaryGradeC  TransferSJLLC
eststo reg1: reghdfe `var' HF0   if  WLM0==2 &  YearMonth ==year5 , cluster(IDlseMHR) a( YearMonth Country  )
eststo regLH: reghdfe `var' HF0   if  WLM0==2  & (FTHH!=. | FTLH !=.) & Post==1 & YearMonth ==year5 , cluster(IDlseMHR) a( YearMonth Country  )
eststo regHL: reghdfe `var' HF0   if  WLM0==2  & (FTHL!=. | FTLL !=.) & Post==1& YearMonth ==year5 , cluster(IDlseMHR) a( YearMonth Country  )
}

eststo reg2: reghdfe TransferSJLLC HF0   if  WLM0==2 &  YearMonth <=year5 , cluster(IDlseMHR) a( YearMonth Country  )

/** OLD FIGURE 
gen reg1 =1 
gen regLH =1 
gen regHL = 1 
label var reg1 "Hiring manager: high-flyer"
label var regLH "Next manager: high-flyer"
label var regHL "Next manager: low-flyer"
coefplot reg1 regLH regHL, ///
title("Pay + bonus in logs, new hires", pos(12) span si(medsmall))  keep(HF0)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(0 .15)) xlabel(0(0.03)0.15)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/NewHireLH.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/NewHireLH.gph", replace
*/


*****-> Second incoming workers 

use "$managersdta/AllSameTeam2.dta", clear 

gen ChangeMRNew = ChangeM
replace ChangeMRNew =0 if ChangeMR ==1
replace  ChangeMRNew  = . if IDlseMHR ==. 

bys IDlse: egen my = min(cond(ChangeMRNew==1,YearMonth,.))
keep if my!=. // select incoming workers 
format my %tm
gen year1 = my + 12 
gen year2 = my + 24 
gen year3 = my + 36
gen year4 = my + 48
gen year5 = my + 60
gen year7 = my + 84
format year1 %tm // first year of incoming worker 

bys IDlse: egen HF0 = mean(cond(YearMonth ==my , EarlyAgeM, .) )
bys IDlse: egen WLM0 = mean(cond(YearMonth ==my , WLM, .) )

* INCOMING WORKERS: hired in by high flyer manager
****************************************************************************

eststo reg3: reghdfe LogPayBonus HF0   if  WLM0==2 &  YearMonth ==year5, cluster(IDlseMHR) a( YearMonth Country  )
eststo reg4: reghdfe TransferSJLLC HF0   if  WLM0==2 &  YearMonth <=year5, cluster(IDlseMHR) a( YearMonth Country  )

**# ON PAPER FIGURE: NewIncomingE.png 
gen reg1 =1 
gen reg2 =1 
gen reg3 =1 
gen reg4 =1 
label var reg1 "Pay + bonus in logs, new hires"
label var reg2 "Lateral moves, new hires"
label var reg3 "Pay + bonus in logs, incoming worker from other team"
label var reg4 "Lateral moves, incoming worker from other team"
coefplot reg1 reg2 reg3 reg4, ///
title("Hiring manager is high-flyer", pos(12) span si(medsmall))  keep(HF0)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-0.12 .12)) xlabel(-0.12(0.03)0.12)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/NewIncoming.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/NewIncoming.gph", replace

********************************************************************************
* BAYES ESTIMATOR OF MANAGER FE IN PROMOTIONS
********************************************************************************

********************************************************************************
* LOAD DATA 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
*use "$managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

********************************************************************************
* Define top manager based on data 2011-2015 only - first event based on half sample only
********************************************************************************

xtset IDlse YearMonth

gen F60LogPayBonus = f60.LogPayBonus // 5 years after 
gen F72LogPayBonus = f72.LogPayBonus // 5 years after 

keep if Year<2014 // first 3 (<2014) or 4 (<2015) years !MANUAL INPUT! 

drop if IDlseMHR==. 

*-*- Restriction #1
bys IDlseMHR : egen minYM= min(YearMonth)
bys IDlseMHR : egen maxYM= max(YearMonth)
format (minYM maxYM) %tm
gen MDuration =  maxYM - minYM 
su MDuration, d 

keep if MDuration >=24 // only managers that are in the sample as managers for at least 2 years (circa 25 percentile)

*-*- Restriction #2
egen ttI = tag(IDlse IDlseMHR)
bys IDlseMHR: egen TotWorkers = sum(ttI)
su TotWorkers, d
su TotWorkers if ttI==1, d
 
keep if TotWorkers > 9 // (p25), minimum number of workers above 9 otw too noisy 


xtset IDlse YearMonth
foreach v in ChangeSalaryGrade PromWL{ // taking into account when promoted under different manager, creates missing values for the last period a worker is present
gen F1`v' = f.`v'
} 


* estimate FE and their SDs - to apply bayes shrinkage 
//////////////////////////////////////////////////////////

su   F60LogPayBonus F72LogPayBonus ChangeSalaryGrade PromWL  F1ChangeSalaryGrade F1PromWL

foreach v in  F60LogPayBonus F72LogPayBonus F1ChangeSalaryGrade F1PromWL LeaverPerm LeaverInv LeaverVol {
	xtset IDlse YearMonth
	* first de-mean the outcome to reduce computational demands
	areg `v' c.Tenure##c.Tenure##i.Female i.Func i.AgeBand i.Year, a(   ISOCode  )   // residualize on managers FE
	predict res`v', res
	* then compute the manager FE and their SD 
	areg res`v', a(IDlseMHR) // F-test significant <0.000 
	predict `v'MFEb, d
	replace `v'MFEb=`v'MFEb+_b[_cons]
	predict resid`v', r
	generate sqres`v'=resid`v'^2
	egen N`v'=count(sqres`v'), by(IDlseMHR)
	summarize sqres`v', meanonly
	generate `v'MFEse=sqrt(r(mean)*e(N)/e(df_r)/N`v')

*fese res`v' , a(IDlseMHR) s(`v'MFE) oonly // estimate sd 
}

* R squared if 55% when looking at future pay 

* compute random effects to compare 
//////////////////////////////////////////////////////////

foreach v in  F60LogPayBonus F72LogPayBonus F1ChangeSalaryGrade F1PromWL LeaverPerm LeaverInv LeaverVol {
	xtset IDlse YearMonth
	reghdfe `v' i.Func i.AgeBand, res(`v'R) a( i.Year i.Country)
	mixed `v'R c.Tenure##c.Tenure##i.Female  ||  IDlseMHR: ,  vce(cluster IDlseMHR)
	 predict `v'Mixed, reffects 
}	
collapse *Mixed *MFEb *MFEse , by(IDlseMHR)
*keep IDlse YearMonth IDlseMHR  MFEse  MFEb // homoscedastic only
compress 
save "$managersdta/Temp/MFEBayes.dta", replace 

* Bayes shrinkage 
//////////////////////////////////////////////////////////

use "$managersdta/Temp/MFEBayes.dta", clear 

foreach v in  F60LogPayBonus F72LogPayBonus F1ChangeSalaryGrade F1PromWL LeaverPerm LeaverInv LeaverVol {
ebayes `v'MFEb `v'MFEse , gen(`v'Bayes)   var(`v'Bayesvar) rawvar(`v'Bayesrawvar) uvar(`v'Bayesuvar) theta(`v'Bayestheta)  bee(`v'Bayesbee)

*-*- Restriction #3: trim top 1% because of long tails 
winsor2 `v'Bayes , trim cuts(0 99) suffix(T) //  
*ebayes MFEb MFEse [vars] [if], [absorb() gen() bee() theta() var() uvar() rawvar() by()
}

rename F1ChangeSalaryGradeBayesT MFEBayesPromSG
rename F1PromWLBayesT MFEBayesPromWL
rename LeaverPermBayesT MFEBayesLeaver
rename LeaverVolBayesT MFEBayesLeaverVol
rename LeaverInvBayesT MFEBayesLeaverInv
rename F60LogPayBonusBayesT MFEBayesLogPayF60
rename F72LogPayBonusBayesT MFEBayesLogPayF72

su MFEBayesPromSG, d
local pSG = r(p75)
su  MFEBayesPromWL, d
local pWL = r(p75)
su MFEBayesLogPayF60, d
local pS = r(p75)

/*
kdensity MFEBayesPromSG , bcolor(red%50)   xline(`pSG' , lcolor(red) ) xaxis(1 2) xlabel(`pSG' "p75", axis(2)) title( "Empirical Bayes Shrunk Manager Fixed Effect on Salary Prom.") xtitle("") xtitle("", axis(2))
graph save "$analysis/Results/3.FE/MFEBayesPromSG.gph", replace 
graph export "$analysis/Results/3.FE/MFEBayesPromSG.pdf", replace 
*/

**# ON PAPER FIGURE: MFEBayesPaynoNotes.pdf
kdensity MFEBayesLogPayF60 if MFEBayesLogPayF60>-2, bcolor(red%50)   xline(`pS' , lcolor(red) ) xaxis(1 2) xlabel(`pS' "p75", axis(2)) title( "Empirical Bayes Shrunk Manager Fixed Effect on Pay") xtitle("") xtitle("", axis(2)) note("Looking at a 5 years horizon.")
graph save "$analysis/Results/0.Paper/Other Analysis/MFEBayesPay.gph", replace 
graph export "$analysis/Results/0.Paper/Other Analysis/MFEBayesPay.pdf", replace 

/*
su MFEBayesLogPayF60, d
local pS = r(p75)
hist MFEBayesLogPayF60 if MFEBayesLogPayF60>-2, bcolor(red%50)   xline(`pS' , lcolor(navy) ) xaxis(1 2) xlabel(`pS' "p75", axis(2)) title( "Empirical Bayes Shrunk Manager Fixed Effect on Pay") xtitle("") xtitle("", axis(2))  note("Looking at a 5 years horizon.")
graph save "$analysis/Results/3.FE/MFEBayesPayHist.gph", replace 
graph export "$analysis/Results/3.FE/MFEBayesPayHist.pdf", replace 

kdensity  MFEBayesPromWL, bcolor(%80) xline(`pWL', lcolor(red))  xaxis(1 2) xlabel(`pWL' "p75", axis(2))  title( "Empirical Bayes Shrunk Manager Fixed Effect on WL Prom.") xtitle("") xtitle("", axis(2))
graph save "$analysis/Results/3.FE/MFEBayesPromWL.gph", replace 
graph export "$analysis/Results/3.FE/MFEBayesPromWL.pdf", replace 
*/

foreach var in MFEBayesLogPayF60 MFEBayesLogPayF72 MFEBayesPromSG MFEBayesPromWL  MFEBayesLeaver MFEBayesLeaverVol MFEBayesLeaverInv {
	su `var', d
	gen `var'75 = `var' >=r(p75) if `var'!=.
	gen `var'50 = `var' >r(p50) if `var'!=.

} 

pwcorr MFEBayesPromSG MFEBayesPromWL MFEBayesLeaver MFEBayesLeaverVol MFEBayesLeaverInv // there is a negative correlation and this may be due because good managers improve retention 
pwcorr MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesLeaver75 MFEBayesLeaverVol75 MFEBayesLeaverInv75 // there is a negative correlation and this may be due because good managers improve retention 

compress
*save "$managersdta/Temp/MFEBayes2015.dta", replace 
save "$managersdta/Temp/MFEBayes2014.dta", replace // NOTE: input the date! !MANUAL INPUT! 
