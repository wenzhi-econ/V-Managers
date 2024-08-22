********************************************************************************
* ADDITIONAL DATA SOURCES FOR SUGGESTIVE EVIDENCE
* Exit survey and learning data 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

use "$managersdta/SwitchersAllSameTeam2.dta", clear 

* odd or even Manager id for placebo events 
*gen odd = mod(IDlseMHR,2) 
gen odd = mod(ManagerNum,2) 

* Delta 
xtset IDlse YearMonth 
foreach var in odd EarlyAgeM MFEBayesPromSG75{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
}

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-(`end') &  maxEi >=(`end') & Ei!=.
ta ii
*keep if ii==1 // MANUAL INPUT - to remove if irrelevant

* only keep relevant switchers 
keep if DeltaM$MType!=. 

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}
* create leads and lags 
foreach var in Ei {

gen `var'Post = K`var'>=0 & K`var' !=.
gen `var'PostDelta = `var'Post*DeltaM$MType
}

gen TenureM2 = TenureM*TenureM
gen Post = KEi >=0 if KEi!=.

********************************************************************************
* 1. exit survey
********************************************************************************

merge 1:1 IDlse YearMonth using "$fulldta/ExitSurvey.dta", keepusing(ReasonLeaving ReasonAnotherOrg ReasonWithoutJob ReasonPersonal Rejoin Recommend )
drop _merge 

foreach v in ReasonLeaving ReasonAnotherOrg ReasonWithoutJob ReasonPersonal{
	tab `v', gen(`v')
}

global control AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM
label var MFEBayesPromSG75 "High Prom. Manager, p75"
label var EarlyAgeM "High Flyer Manager" 

eststo clear 
foreach var in ReasonLeaving1 ReasonLeaving2 ReasonLeaving3 ReasonLeaving4 ReasonLeaving5 ReasonLeaving6 ReasonLeaving7 ReasonAnotherOrg1 ReasonAnotherOrg2 ReasonAnotherOrg3  ReasonAnotherOrg4 ReasonAnotherOrg5 ReasonAnotherOrg6 ReasonAnotherOrg7{
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 & WL2==1, cluster(IDlseMHR) a( Year  )	
}

label var ReasonLeaving1 "Personal"
label var ReasonLeaving2 "Other"
label var ReasonLeaving3 "Prefer not to say"
label var ReasonLeaving4 "Self-employment"
label var ReasonLeaving5 "Join other org"
label var ReasonLeaving6 "Career break"
label var ReasonLeaving7 "No job"
label var  ReasonAnotherOrg1 "Career progression"
label var  ReasonAnotherOrg2 "Cultural fit"
label var  ReasonAnotherOrg3 "Work-life balance"
label var  ReasonAnotherOrg4 "Change of career"
label var  ReasonAnotherOrg5 "Competitive pay"
label var  ReasonAnotherOrg6 "Getting work done"
label var  ReasonAnotherOrg7 "Line manager"

* option for all coefficient plots
global coefopts keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample, post manager transition. Year FE included." "Standard errors clustered at the manager level. 90% Confidence Intervals.", span size(small)) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
* "Controls include: managers' age group FE, tenure and tenure squared interacted with managers' gender."

* reason for changing organization
coefplot  ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1  ReasonAnotherOrg6 ReasonAnotherOrg3   , ///
title("Reasons for joining another company:" "impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash)) 
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/5.Mechanisms/FTReasonAnotherOrg.png", replace

**# ON PAPER
coefplot  ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1  ReasonAnotherOrg6 ReasonAnotherOrg3 , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/5.Mechanisms/FTReasonAnotherOrgA.png", replace

* reasons for leaving 
coefplot  ReasonLeaving5  ReasonLeaving4 ReasonLeaving1  ReasonLeaving6 ReasonLeaving7 ReasonLeaving2 ReasonLeaving3, ///
title("Reasons for leaving: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/5.Mechanisms/FTReasonLeaving.png", replace

coefplot   ReasonLeaving5  ReasonLeaving4 ReasonLeaving1 ReasonLeaving6 ReasonLeaving7  ReasonLeaving2 ReasonLeaving3, ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/5.Mechanisms/FTReasonLeavingA.png", replace

********************************************************************************
/* 2. skills data 
********************************************************************************

Context on the dataset Active Learner

Learner has:
	- Shared at least one item with a colleague
	- Completed 5 items  - the file doesn't start reporting until they have reached 5
	- Have at least 3 skills on their profile. Cumulative for all years (explained below in "CHECKS" section.)

The KPI resets each year, is cumulative each month
*/

merge 1:1 IDlse YearMonth using "$fulldta/ActiveLearn.dta", keepusing(NumRecommend NumRecommendB NumRecommendYTD NumRecommendYTDF NumRecommendYTDB NumCompleted NumCompletedB NumCompletedYTD NumCompletedYTDF NumCompletedYTDB NumSkills NumSkillsF NumSkillsB ActiveLearner ActiveLearnerYTD ActiveLearnerC)
drop _merge 

eststo clear 
foreach var in  ActiveLearnerYTD   NumCompletedYTDB  NumRecommendYTDB NumSkillsB {
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( Year )	// WL2 takes away 2/3 of sample 
}

* baseline mean: 
su ActiveLearnerYTD   NumCompletedYTDB  NumRecommendYTDB NumSkillsB if Post==1  & EarlyAgeM ==0

label var ActiveLearnerYTD "Meeting all conditions: active learner"
label var NumRecommendYTDB "Shared items with colleagues>0"
label var  NumCompletedYTDB "Completed items>=5"
label var NumSkillsB  "Number of skills>=3"

coefplot    NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
graph export  "$analysis/Results/5.Mechanisms/FTActiveLearnA.png", replace


********************************************************************************
* 3.flex projects data 
********************************************************************************

merge m:1 IDlse using "$fulldta/FLEX.dta"
drop if _merge==2 
gen InFLEX = _merge==3
drop _merge 

* outcomes 
global FLEXProjectVar InFLEX ProjectRolesAppliedDummy ProjectRolesAssignedDummy ProjectRolesAcceptedDummy ProjectsCreatedDummy	
global FLEXPositionVar PositionsAppliedDummy PositionsAssignedDummy 
global FLEXOtherVar CompletedProfileDummy MyDevelopment AvailableMentor AvailableJobs
global FLEXHoursVar HoursAvailable	HoursUnlocked HoursWeeklyConsumedProject

eststo clear
foreach var in  $FLEXProjectVar $FLEXPositionVar $FLEXOtherVar $FLEXHoursVar  { 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 & WL2==1, cluster(IDlseMHR) a( Year ISOCode )	// WL2 takes away 2/3 of sample 
}

coefplot   NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD  , ///
title("Flexible projects: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
graph export  "$analysis/Results/5.Mechanisms/Flex.png", replace

**# ON PAPER
coefplot    NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
graph export  "$analysis/Results/5.Mechanisms/FlexA.png", replace

