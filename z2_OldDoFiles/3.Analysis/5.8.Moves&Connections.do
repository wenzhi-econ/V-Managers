********************************************************************************
* EVENT STUDY 
* SOCIALLY CONNECTED MOVES
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

global analysis "${user}/Managers"

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

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

eststo clear 
local Label $Label
foreach var in  TransferSJC TransferSJSameMSameFuncC TransferSJDiffMSameFuncC TransferFuncC {
	eststo `var': reghdfe   `var' `Label'LHPost  `Label'HLPost  `Label'HHPost `Label'LLPost if (WL2==1 ) & (  KEi ==-1 | KEi ==-2 | KEi ==-3  | KEi ==22 | KEi ==23 | KEi ==24 ) , a(  IDlse YearMonth ) vce(cluster IDlseMHR)

	su `var' if `Label'LLPost==1
local lm = round(r(mean), .01)
	su `var' if `Label'HHPost==1
local hm = round(r(mean), .01)

local lab: variable label `var'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(90) post
est store  `var'

}
* NOTE: results using window at 24 as 71% of workers have change manager after 2 years (so it does not make sense to look at within team changes)

**# ON PAPER
coefplot  (TransferSJC, keep(lc_1) rename(  lc_1  = "All lateral moves")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white)) ///
		(TransferSJSameMSameFuncC, keep(lc_1) rename( lc_1 = "Within team" ) ciopts(lwidth(2 ..) lcolor(orange ))  msymbol(d) mcolor(white)) ///
         (TransferSJDiffMSameFuncC, keep(lc_1) rename( lc_1 = "Different team, same function" ) ciopts(lwidth(2 ..) lcolor(cranberry ))  msymbol(d) mcolor(white)) ///
         (TransferFuncC, keep(lc_1) rename( lc_1 = "Different team, cross-functional" ) ciopts(lwidth(2 ..) lcolor(emerald))  msymbol(d) mcolor(white)) ///
, legend(off) title("Gaining a high-flyer manager", size(medsmall))  level(90) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 90% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span)   ///
aspectratio(.4) xscale(range(-0.01 0.15)) xlabel(-0.01(0.01)0.15)
graph export "$analysis/Results/5.Mechanisms/MovesDecompGain.png", replace // ysize(6) xsize(8)  
graph save "$analysis/Results/5.Mechanisms/MovesDecompGain.gph", replace 


coefplot  (TransferSJC, keep(lc_2) rename(  lc_2  = "All lateral moves")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  ///
(TransferSJSameMSameFuncC, keep(lc_2) rename( lc_2 = "Within team" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) ///
   (TransferSJDiffMSameFuncC, keep(lc_2) rename( lc_2 = "Different team, same function" ) ciopts(lwidth(2 ..) lcolor(cranberry ))  msymbol(d) mcolor(white)   ) ///
(TransferFuncC, keep(lc_2) rename( lc_2 = "Different team, cross-functional" ) ciopts(lwidth(2 ..) lcolor(emerald))  msymbol(d) mcolor(white)   ) ///
 ,legend(off) title("Losing a high-flyer manager", size(medsmall))  level(90) xline(0, lpattern(dash))  ///
 note("Notes. An observation is a worker-year-month. Reporting 90% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span) ///
 ysize(6) xsize(8)   aspectratio(.4)   xscale(range(-0.01 0.15)) xlabel(-0.01(0.01)0.15)
graph export "$analysis/Results/5.Mechanisms/MovesDecompLose.png", replace 
graph save "$analysis/Results/5.Mechanisms/MovesDecompLose.gph", replace 

* mean 
su  TransferSJC TransferFuncC TransferSJSameMC if FTLLPost==1 & (KEi ==22 | KEi ==23 | KEi ==24)  
su  TransferSJC TransferFuncC TransferSJSameMC if FTHHPost==1 & (KEi ==22 | KEi ==23 | KEi ==24)  

********************************************************************************
* add social connections 
********************************************************************************

* these variables take value 1 for the entire duration of the manager-employee spell, 
* NOTE: they are missing before the manager transition! 
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

eststo clear 
* note that the social connections variables are only available post transition, since I am looking at the first manager transition for each worker! 
local Label $Label
foreach var in  Connected ConnectedL ConnectedV{
	eststo `var': reghdfe   `var' `Label'LHPost  `Label'HLPost  `Label'HHPost `Label'LLPost if WL2==1 & ( KEi==24) , a(  Country##YearMonth AgeBand##Female Func ) vce(cluster IDlseMHR)

	su `var' if `Label'LLPost==1
local lm = round(r(mean), .01)
	su `var' if `Label'HHPost==1
local hm = round(r(mean), .01)

local lab: variable label `var'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(90) post
est store  conn`var'

}
* NOTE: results robust to having a window at 60 

**# ON PAPER
coefplot  (connConnected, keep(lc_1) rename(  lc_1  = "Move within manager's network")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
 (connConnectedL, keep(lc_1) rename( lc_1 = "Lateral move within manager's network" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) ///
 (connConnectedV, keep(lc_1) rename( lc_1 = "Vertical move within manager's network" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ), ///
 legend(off) title("Gaining a high-flyer manager", size(medsmall))  level(90) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 90% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span)   ///
xscale(range(-0.05 0.05)) xlabel(-0.05(0.01)0.05) ysc(outergap(50)) aspectratio(.5)
graph export "$analysis/Results/5.Mechanisms/NetworkGain.png", replace // ysize(6) xsize(8)  
graph save "$analysis/Results/5.Mechanisms/NetworkGain.gph", replace 

coefplot  (connConnected, keep(lc_2) rename(  lc_2  = "Move within manager's network")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  ///
(connConnectedL, keep(lc_2) rename( lc_2 = "Lateral move within manager's network" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) ///
(connConnectedV, keep(lc_2) rename( lc_2 = "Vertical move within manager's network" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ),  legend(off) title("Losing a high-flyer manager", size(medsmall))  level(90) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 90% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span) ///
  xscale(range(-0.2 0.2)) xlabel(-0.2(0.1)0.2) ysize(6) xsize(8)  ysc(outergap(50))  aspectratio(.5)
graph export "$analysis/Results/5.Mechanisms/NetworkLose.png", replace 
graph save "$analysis/Results/5.Mechanisms/NetworkLose.gph", replace 


* baseline transitions mean 
local Label $Label
foreach var in Connected ConnectedL ConnectedV{
su `var' if `Label'LLPost==1 & KEi==24
su `var' if `Label'HHPost==1& KEi==24
}

********************************************************************************
* Decomposing total VERTICAL transfers: within sub-function, function or across function 
********************************************************************************

* Load dataset 
* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

global analysis "${user}/Managers"

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse    // alternative, to try 
global exitFE CountryYear AgeBand AgeBandM Func Female

use "$Managersdta/AllSameTeam2.dta", clear 
*merge 1:1 IDlse YearMonth using  "$Managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
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

* take promotion at 5 years 
* same place at baseline - but note that this can only be defined ex post - cannot do event study 
* different place but same as month before
* different place and different than month before 

* Baseline averages 
********************************************************************************

* generating the 3rd category which is vertical transfer across subfunction 
gen PromWLL = PromWL 
replace PromWLL = 0 if TransferInternal==0
bys IDlse (YearMonth), sort: gen  PromWLLC= sum(PromWLL)

su PromWL PromWLV PromWLL PromWLSameM  PromWLDiffM
di    .0006219  /.0013971 // 45% are within subfunction 
di    .0005244   /.0013971 // 38% are keeping same manager 

ta PromWL TransferFunc, row // large majority of promotions (92%) are within function 
ta PromWL TransferSubFunc, row // & also within subfunction (65%) 
 
* Look at time of the vertical transfer and then check whether it is in same sub function of month before versus subfunction of time at baseline 
********************************************************************************

* subfunction at baseline 
bys IDlse: egen SF0 = mean(cond(KEi==0, SubFunc, .))
bys IDlse: egen SJM0 = mean(cond(KEi==0, StandardJobCodeM, .))
count if StandardJobCode==SJM0 & KEi>0 & WL2==1
* How many workers take the place of the manager? 
gen TakeSJM = StandardJobCode==SJM0 if KEi>0 & WL2==1
bys IDlse: egen TakeSJMFraction = max(TakeSJM) // tagging all workers who take the place of the manager 
egen oo = tag(IDlse) if KEi>0
ta  TakeSJMFraction if FTLLPost==1 & WL2==1
ta  TakeSJMFraction if FTLHPost==1 & WL2==1 // if anything lower ratio taking the place of the manager 
di  10.78 -  10.09  // 0.69 higher for LL
ta  TakeSJMFraction if FTLLPost==1 & oo==1 & WL2==1
ta  TakeSJMFraction if FTLHPost==1 & oo==1 & WL2==1
di 7.87 - 6.85  // 1.02 higher for LL
 
* even more precise: promoted to the exact position of the manager 
gen PromWLTakeSJM = PromWL
replace PromWLTakeSJM = 0 if TakeSJM==0 
bys IDlse (YearMonth), sort: gen  PromWLTakeSJMC= sum(PromWLTakeSJM)

gen LLInd = FTLL!=. if (FTLL!=. | FTLH!=.)
ttest PromWLTakeSJMC if KEi>0 & WL2==1,  by( LLInd) unequal  
ttest TakeSJMFraction if KEi>0 & WL2==1, by( LLInd) unequal  


label value SF0 SubFunc 

*Case 1: ALL
su PromWLC if KEi == 60 & (FTLLPost==1) & (WL2==1 )
su PromWLC if KEi == 60 & (FTLHPost==1) & (WL2==1 )

su PromWLVC if KEi == 60 & (FTLLPost==1) & (WL2==1 )
su PromWLVC if KEi == 60 & (FTLHPost==1) & (WL2==1 )

su PromWLLC if KEi == 60 & (FTLLPost==1) & (WL2==1 )
su PromWLLC if KEi == 60 & (FTLHPost==1) & (WL2==1 )
* half is within SF and half is across - same as overall averages in the full sample 
* the proportions remain the same but all within function? 

*Case 2: SAME AS BASELINE 
su PromWLC if KEi == 60 & (FTLLPost==1) & SubFunc ==SF0 & (WL2==1 )
su PromWLC if KEi == 60 & (FTLHPost==1) & SubFunc ==SF0 & (WL2==1 )

*Case 3: DIFF BASELINE & DIFF SF FROM BEFORE 
su PromWLC if KEi == 60 & (FTLLPost==1) & SubFunc !=SF0 & (WL2==1 )
su PromWLC if KEi == 60 & (FTLHPost==1) & SubFunc !=SF0 & (WL2==1 )

*Case 4: DIFF BASELINE BUT SAME SF AS BEFORE 
su PromWLVC if KEi == 60 & (FTLLPost==1) & SubFunc !=SF0 & (WL2==1 )
su PromWLVC if KEi == 60 & (FTLHPost==1) & SubFunc !=SF0 & (WL2==1 )


gen  TransferSJSameMSameFunc = TransferSJ 
replace TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace TransferSJSameMSameFunc = 0 if  TransferSJDiffMSameFunc==1
bys IDlse (YearMonth), sort: gen  TransferSJSameMSameFuncC= sum( TransferSJSameMSameFunc)

eststo clear 
local Label $Label
foreach var in  PromWLC PromWLLC PromWLVC  {
	eststo `var': reghdfe   `var' `Label'LHPost  `Label'HLPost  `Label'HHPost `Label'LLPost if (WL2==1 ) & (   KEi ==-1 | KEi ==-2 | KEi ==-3  | KEi ==58 | KEi ==59 | KEi ==60 ) , a(  IDlse YearMonth ) vce(cluster IDlseMHR)

	su `var' if `Label'LLPost==1
local lm = round(r(mean), .01)
	su `var' if `Label'HHPost==1
local hm = round(r(mean), .01)

local lab: variable label `var'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(90) post
est store  `var'

}
* NOTE: regression results as very similar to raw averages. Taking 5 years since that is max level reached of promotions and then it levels off  

coefplot  (PromWLC, keep(lc_1) rename(  lc_1  = "All vertical moves")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white)) ///
		(PromWLVC, keep(lc_1) rename( lc_1 = "Within subfunction" ) ciopts(lwidth(2 ..) lcolor(orange ))  msymbol(d) mcolor(white)) ///
         (PromWLLC, keep(lc_1) rename( lc_1 = "Different sub-function" ) ciopts(lwidth(2 ..) lcolor(cranberry ))  msymbol(d) mcolor(white)) ///
		 , legend(off) title("Gaining a high-flyer manager", size(medsmall))  level(90) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 90% confidence intervals." "Looking at outcomes at 60 months after the manager transition." , span)   ///
aspectratio(.4) xscale(range(-0.01 0.05)) xlabel(-0.01(0.01)0.05)
graph export "$analysis/Results/5.Mechanisms/VerticalMovesDecompGain.png", replace // ysize(6) xsize(8)  
graph save "$analysis/Results/5.Mechanisms/VerticalMovesDecompGain.gph", replace 
       *  (TransferFuncC, keep(lc_1) rename( lc_1 = "Different team, cross-functional" ) ciopts(lwidth(2 ..) lcolor(emerald))  msymbol(d) mcolor(white)) ///


