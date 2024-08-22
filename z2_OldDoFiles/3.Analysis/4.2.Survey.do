********************************************************************************
* ADDITIONAL DATA SOURCES FOR SUGGESTIVE EVIDENCE
* Exit survey and learning data 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

use "$managersdta/SwitchersAllSameTeam.dta", clear 
*gen Tenure2 = Tenure*Tenure

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
rename FT`v' E`v'	
rename KFT`v' KE`v'	
}
* create leads and lags 
foreach var in Ei {

gen `var'Post = K`var'>=0 & K`var' !=.
gen `var'PostDelta = `var'Post*DeltaM$MType
}

gen TenureM2 = TenureM*TenureM
gen Post = KEi >=0 if KEi!=.


* Univoice 2017-2021
********************************************************************************

merge m:1 IDlse Year using "$fulldta/Univoice.dta"
rename _merge _mergeU 

global univoiceAll Competition DevOpportunity EffectiveBarriers ExtraMile FeedbackAction GoodTechnologies Integrity Leaving LineManager LivePurpose  LeadershipInclusion PrioritiseControl Proud RecommendProducts Refer Satisfied StrategyWin TeamAgility TrustLeadership  USLP Wellbeing WorkLifeBalance AccessLearning ReportUnethical HeartCustomers FocusPerf LeadershipStrategy Inclusive

* Binary indicators 
foreach v in $univoiceAll {
	gen `v'B=0
	replace `v'B = 1 if `v'>=5
	replace `v'B=. if `v'==.
}

* Wellbeing 2018-2021
********************************************************************************

merge m:1 IDlse Year using "$fulldta/Wellbeing.dta"
rename _merge _mergeW

keep if _mergeU==3 | _mergeW==3 

global wellbeingAll LifeSat PhysicalH UnwellWork MentalH MentalH6Months SleepQuality FinancialConcern ShareSafe ManagerTalk StressMinimise LeaderRoleModel ManagerCare ManagerRoleModel WorkplaceSupport ManagerPrioritise WorkAmount WorkDecision Rewarded JobFairness OfferSupport PhysicalSupport StressSupport UnwellSupport AwareEAP AwareLamplighter AwareWorldMentalH AwareMindfulness AwarePW AwareThriveW  UseEAP UseLamplighter UseWorldMentalH UseMindfulness UsePW UseThriveW

* NOTE: Variables we do not use & keep in raw string format

* 2 variables (SupportObstacle, Support) are multiple choice questions with no clear ordering.
* 6 variables (HealthGoals, Constraints, SupportAccess, SupportAccessPrefer, WellbeingInfo, WellbeingFactor) allow multiple choice (such as: select top 3).
* 8 variables (HealthGoalsOther, ConstraintsOther, OtherResources, SuggestionWellbeing, RegularWellbeing, WellbeingInfoOther, WellbeingFactorOther, SupportObstacleOther) contain comments rather than responses to multiple choice questions.

* Binary indicators 
foreach v of varl $wellbeingAll {
	qui tab `v'
	di "levels in `v': `r(r)'"
	
	if `r(r)'==10 {
		gen `v'B = 0
		replace `v'B = 1 if `v'>=8
		replace `v'B = . if `v'==.
	}
	if `r(r)'==5 {
		gen `v'B = 0
		replace `v'B = 1 if `v'>=5
		replace `v'B = . if `v'==.
	}
	if `r(r)'==3 {
		gen `v'B = 0
		replace `v'B = 1 if `v'>=3
		replace `v'B = . if `v'==.
	}
	if `r(r)'==2 {
		gen `v'B = `v'
	}
	tab `v' `v'B,m
	* tab `v' `v'B,m nola

}

////////////////////////////////////////////////////////////////////////////////
* REGRESSIONS: COEFF ARE WEIGHTED AVERAGES 
////////////////////////////////////////////////////////////////////////////////

* If instead want to keep the levels, but avoid changing variable names below 
/* Uncomment as needed 
foreach var in  $univoiceAll $wellbeingAll {
	replace `var'B = `var'
}
**/

* UNIVOICE & WELLBEING 
********************************************************************************

* UNIVOICE 
global Uteam  LineManagerB InclusiveB   TeamAgilityB TrustLeadershipB LeadershipStrategyB  LeadershipInclusionB HeartCustomersB
global Ufocus FocusPerfB AccessLearningB PrioritiseControlB DevOpportunityB  WellbeingB ReportUnethicalB
global Uhappy WorkLifeBalanceB  SatisfiedB ReferB  ProudB  LivePurposeB LeavingB ExtraMileB   
global Ucompany StrategyWinB USLPB  GoodTechnologiesB CompetitionB EffectiveBarriersB IntegrityB RecommendProductsB

la var LineManagerB "Effective LM"
la var InclusiveB "Inclusive Team"
la var TeamAgilityB "Team Agility"
la var TrustLeadershipB "Trust Leaders"
la var LeadershipStrategyB  "Leaders \& Strategy" 
la var LeadershipInclusionB "Leaders \& Inclusion"
la var HeartCustomersB "Team Prioritises Customers"

la var FocusPerfB "Can Focus"
la var AccessLearningB "Learning Resources"
la var PrioritiseControlB "Can Prioritise"
la var DevOpportunityB  "Can Advance"
la var WellbeingB "Company Cares Wellbeing"
la var ReportUnethicalB "Can Report Unethical"

la var WorkLifeBalanceB  "Work Life Balance"
la var SatisfiedB "Job Satisfaction"
la var ReferB  "Refer Company"
la var ProudB  "Proud Company"
la var LeavingB "Intention to Stay"
la var LivePurposeB "Live Purpose"
la var ExtraMileB   "Extra Mile"

la var StrategyWinB "Company Strategy Win"
la var USLPB  "Job \& Sustainability"
la var GoodTechnologiesB  "Company Good Tech"
la var CompetitionB  "Company Better Competition"
la var EffectiveBarriersB "Company Removes team Barriers"
la var IntegrityB "Business Integrity"
la var RecommendProductsB "Recommend Products"

* WELLBEING 
egen AwareHealthB = rowmax( AwareEAPB AwareLamplighterB AwareWorldMentalHB AwareMindfulnessB AwarePWB AwareThriveWB)
egen UseHealthB = rowmax(UseEAPB UseLamplighterB UseWorldMentalHB UseMindfulnessB UsePWB UseThriveWB) 
global Whealth PhysicalHB MentalHB SleepQualityB LifeSatB
global Wtalk  ManagerTalkB  ManagerCareB ManagerPrioritiseB ManagerRoleModelB JobFairnessB  RewardedB 
global Wjob    OfferSupportB   StressSupportB  StressMinimiseB  WorkplaceSupportB  LeaderRoleModelB
global Waction AwareHealthB UseHealthB WorkAmountB  WorkDecisionB

la var LifeSatB "Life Satisfaction"
la var PhysicalHB "Physical Health"
la var UnwellWorkB "Work if Unwell" // to reverse code - not using it now 
la var MentalHB "Mental Health"
la var SleepQualityB "Sleep Quality"
la var ShareSafeB "Safe to Share"
la var ManagerTalkB "Can Talk LM"
la var ManagerCareB "Manager Cares Wellbeing"
la var ManagerPrioritiseB "Manager Prioritises Wellbeing"
la var StressMinimiseB "Company Minimises Stress"
la var LeaderRoleModelB "Leaders, Health Role Models"
la var ManagerRoleModelB "Manager, Health Role Model"
la var RewardedB "Recognition at Work"
la var WorkplaceSupportB "Workplace Support"
la var WorkAmountB   "Reasonable Work Hours"
la var WorkDecisionB "Autonomy at Work"
la var JobFairnessB "Fairness on the Job"
la var OfferSupportB "Company Wellbeing Support"
la var StressSupportB "Company Stress Support"
la var AwareHealthB "Aware of Health Programs"
la var UseHealthB "Use Health Programs"

* PRINCIPAL COMPONENT ANALYSIS 
* need to have variable of same unit 
* Univoice: all variables 1-5
* Wellbeing: most variables 1-5 (take out awareness, use, financial concernes, lifeSat). 
* Note that unwellWork has to be reverse coded 
********************************************************************************

global Whealthpc PhysicalHB MentalHB SleepQualityB 
global Wtalkpc  ManagerTalkB  ManagerCareB ManagerPrioritiseB ManagerRoleModelB JobFairnessB  RewardedB WorkAmountB  WorkDecisionB 
global Wjobpc    OfferSupportB   StressSupportB PhysicalSupportB StressMinimiseB  WorkplaceSupportB  LeaderRoleModelB 
global Wawarepc AwareEAPB AwareLamplighterB AwareWorldMentalHB  AwarePWB // 0-1 scale 
global Wusepc UseEAPB UseLamplighterB UseWorldMentalHB UsePWB  // 3 scale 
global Uteampc  LineManagerB InclusiveB   TeamAgilityB TrustLeadershipB  LeadershipInclusionB HeartCustomersB
global Ufocuspc  AccessLearningB PrioritiseControlB DevOpportunityB  WellbeingB ReportUnethicalB
global Uhappypc WorkLifeBalanceB  SatisfiedB ReferB  ProudB  LivePurposeB LeavingB ExtraMileB   
global Ucompanypc StrategyWinB USLPB  GoodTechnologiesB CompetitionB EffectiveBarriersB IntegrityB RecommendProductsB

* keeping LivePurpose ReportUnet Prioritise  LineManager but they are missing in 2017
 // Not used & why: 
 // Life Sat - 10 point scale; financial concerns 0-1; UnwellWork - to reverse code
 //  AwareThriveWB, UseThriveWB, only pre 2020
 //  AwareMindfulnessB, UseMindfulnessB, only in 2020
 // ShareSafeB MentalH6Months // only in 2020
// LeadershipStrategy FocusPerfB // missing in 2021
 
foreach group in  Whealthpc Wtalkpc Wjobpc Wawarepc  Wusepc Uteampc Ufocuspc Uhappypc Ucompanypc {
pca $`group'
predict `group'1 , score // get the first component 
egen `group'Mean = rowmean($`group') // simple average 

}

label var Whealthpc1 "Health and Wellbeing"
label var Wtalkpc1 "Manager Improves Wellbeing"
label var Wjobpc1 "Company Cares Wellbeing"
label var Wawarepc1  "Aware Health Pr."
label var Wusepc1 "Use Health Pr."

label var Uteampc1 "Team Effectivess"
label var Ufocuspc1 "Autonomy"
label var Uhappypc1 "Job Satisfaction"
label var Ucompanypc1 "Company Effectivess"

label var UteampcMean "Team Effectivess"
label var UfocuspcMean "Autonomy"
label var UhappypcMean "Job Satisfaction"
label var UcompanypcMean "Company Effectivess"

label var LineManagerB "Effective Leader"

* REGRESSIONS 
********************************************************************************

global control AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM AgeBand##Female c.Tenure2##Female c.Tenure##Female
global abs IDlse Year WLM  // IDlseMHR

* $Uteam $Ufocus $Uhappy $Whealth  $Wtalk $Wjob $Waction

* Index 
********************************************************************************

* option for all coefficient plots
global coefopts keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample, post manager transition." "Controls include: year and country FE, managers' age group FE," "tenure and tenure squared interacted with managers' gender." "Standard errors clustered at the manager level. 90% Confidence Intervals.", span size(small)) legend(off) ///
aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black)) 


* First principal component 
********************************************************************************

* Cannot do Balanced sample (1 year pre and post) - because too few obs 
eststo clear 
foreach var in LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1{ 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( $control Year Country WLM  )	
}
* outcome mean low flyer 
su LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1   if Post==1 & EarlyAgeM==0 

* PLOT 1: with all details 
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("Pulse Survey: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash)) xscale(range(-.04 .1)) xlabel(-.04(0.02)0.1)
graph export "$analysis/Results/4.Event/Survey/Univoice2FT.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2FT.gph", replace 

**# PLOT 2: anonymized  (ON PAPER)
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.04 .1)) xlabel(-.04(0.02)0.1)   
graph export "$analysis/Results/4.Event/Survey/Univoice2AFT.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2AFT.gph", replace

* plot using the mean 
********************************************************************************

eststo clear 
foreach var in LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean WhealthpcMean WtalkpcMean WjobpcMean WawarepcMean  WusepcMean{ 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( $control Year Country WLM  )	
}
* outcome mean low flyer
su LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean WhealthpcMean WtalkpcMean WjobpcMean WawarepcMean  WusepcMean   if Post==1 & EarlyAgeM ==0

**# ON PAPER
coefplot LineManagerB UteampcMean  UhappypcMean UfocuspcMean UcompanypcMean, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.01 .04)) xlabel(-.01(0.01)0.04)   
graph export "$analysis/Results/4.Event/Survey/Univoice2MeanAFT.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2AMeanFT.gph", replace

/* PLOT 3: WELLBEING SURVEY 
coefplot  Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1, ///
title("Wellbeing Survey: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
graph export "$analysis/Results/4.Event/Survey/Wellbeing2FT.png", replace 
graph save "$analysis/Results/4.Event/Survey/Wellbeing2FT.gph", replace
*/

* ROBUSTNESS: ONLY FIRST YEAR TO ADDRESS SELECTED SAMPLE ISSUE - PC
********************************************************************************

*Cannot do Balanced sample (1 year pre and post) - because too few obs 
eststo clear 
foreach var in LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 { // Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 & KEi <=12 , cluster(IDlseMHR) a( $control Year Country WLM  )	
}

* PLOT 4, robustness: anonymized 
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.1 .1)) xlabel(-.1(0.02)0.1)   
graph export "$analysis/Results/4.Event/Survey/Univoice2AFT1Year.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2AFT1Year.gph", replace 

* ROBUSTNESS: ONLY FIRST YEAR TO ADDRESS SELECTED SAMPLE ISSUE - MEAN
********************************************************************************

*Cannot do Balanced sample (1 year pre and post) - because too few obs 
eststo clear 
foreach var in  LineManagerB UteampcMean  UhappypcMean UfocuspcMean UcompanypcMean { // Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 & KEi <=12 , cluster(IDlseMHR) a( $control Year Country WLM  )	
}

* PLOT 4, robustness: anonymized 
coefplot LineManagerB UteampcMean  UhappypcMean UfocuspcMean UcompanypcMean, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.1 .1)) xlabel(-.1(0.02)0.1)   
graph export "$analysis/Results/4.Event/Survey/Univoice2MeanAFT1Year.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2MeanAFT1Year.gph", replace 

* for Nick Dalton: development opportunity question 
********************************************************************************

reghdfe DevOpportunityB  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( $control Country WLM  )
su DevOpportunityB   if Post==1 & EarlyAgeM==0 
di    .0083664   /  .2072409 // increase by 4%
 
********************************************************************************
* HETEROGENEITY ANALYSIS - split by whether worker transferred or not 
* Are the workers that transferred unhappy? they wanted to escape the manager 
* I want to check the contemporaneous assessment of manager for workers that later transfer 
********************************************************************************

********************************************************************************
* HETEROGENEITY ANALYSIS - split by whether worker transferred or not 
* Are the workers that transferred unhappy? they wanted to escape the manager 
* I want to check the contemporaneous assessment of manager for workers that later transfer 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

use "$managersdta/SwitchersAllSameTeam2.dta", clear 
*gen Tenure2 = Tenure*Tenure

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
rename FT`v' E`v'	
rename KFT`v' KE`v'	
}
* create leads and lags 
foreach var in Ei {

gen `var'Post = K`var'>=0 & K`var' !=.
gen `var'PostDelta = `var'Post*DeltaM$MType
}

gen TenureM2 = TenureM*TenureM
gen Post = KEi >=0 if KEi!=.


* Univoice 2017-2021
********************************************************************************

merge m:1 IDlse Year using "$fulldta/Univoice.dta"
rename _merge _mergeU 

global univoiceAll Competition DevOpportunity EffectiveBarriers ExtraMile FeedbackAction GoodTechnologies Integrity Leaving LineManager LivePurpose  LeadershipInclusion PrioritiseControl Proud RecommendProducts Refer Satisfied StrategyWin TeamAgility TrustLeadership  USLP Wellbeing WorkLifeBalance AccessLearning ReportUnethical HeartCustomers FocusPerf LeadershipStrategy Inclusive

* Binary indicators 
foreach v in $univoiceAll {
	gen `v'B=0
	replace `v'B = 1 if `v'>=5
	replace `v'B=. if `v'==.
}

* Wellbeing 2018-2021
********************************************************************************

merge m:1 IDlse Year using "$fulldta/Wellbeing.dta"
rename _merge _mergeW

keep if _mergeU==3 | _mergeW==3 

global wellbeingAll LifeSat PhysicalH UnwellWork MentalH MentalH6Months SleepQuality FinancialConcern ShareSafe ManagerTalk StressMinimise LeaderRoleModel ManagerCare ManagerRoleModel WorkplaceSupport ManagerPrioritise WorkAmount WorkDecision Rewarded JobFairness OfferSupport PhysicalSupport StressSupport UnwellSupport AwareEAP AwareLamplighter AwareWorldMentalH AwareMindfulness AwarePW AwareThriveW  UseEAP UseLamplighter UseWorldMentalH UseMindfulness UsePW UseThriveW

* NOTE: Variables we do not use & keep in raw string format

* 2 variables (SupportObstacle, Support) are multiple choice questions with no clear ordering.
* 6 variables (HealthGoals, Constraints, SupportAccess, SupportAccessPrefer, WellbeingInfo, WellbeingFactor) allow multiple choice (such as: select top 3).
* 8 variables (HealthGoalsOther, ConstraintsOther, OtherResources, SuggestionWellbeing, RegularWellbeing, WellbeingInfoOther, WellbeingFactorOther, SupportObstacleOther) contain comments rather than responses to multiple choice questions.

* Binary indicators 
foreach v of varl $wellbeingAll {
	qui tab `v'
	di "levels in `v': `r(r)'"
	
	if `r(r)'==10 {
		gen `v'B = 0
		replace `v'B = 1 if `v'>=8
		replace `v'B = . if `v'==.
	}
	if `r(r)'==5 {
		gen `v'B = 0
		replace `v'B = 1 if `v'>=5
		replace `v'B = . if `v'==.
	}
	if `r(r)'==3 {
		gen `v'B = 0
		replace `v'B = 1 if `v'>=3
		replace `v'B = . if `v'==.
	}
	if `r(r)'==2 {
		gen `v'B = `v'
	}
	tab `v' `v'B,m
	* tab `v' `v'B,m nola

}

////////////////////////////////////////////////////////////////////////////////
* REGRESSIONS: COEFF ARE WEIGHTED AVERAGES 
////////////////////////////////////////////////////////////////////////////////

* If instead want to keep the levels, but avoid changing variable names below 
/* Uncomment as needed 
foreach var in  $univoiceAll $wellbeingAll {
	replace `var'B = `var'
}
**/

* UNIVOICE & WELLBEING 
********************************************************************************

* UNIVOICE 
global Uteam  LineManagerB InclusiveB   TeamAgilityB TrustLeadershipB LeadershipStrategyB  LeadershipInclusionB HeartCustomersB
global Ufocus FocusPerfB AccessLearningB PrioritiseControlB DevOpportunityB  WellbeingB ReportUnethicalB
global Uhappy WorkLifeBalanceB  SatisfiedB ReferB  ProudB  LivePurposeB LeavingB ExtraMileB   
global Ucompany StrategyWinB USLPB  GoodTechnologiesB CompetitionB EffectiveBarriersB IntegrityB RecommendProductsB

la var LineManagerB "Effective LM"
la var InclusiveB "Inclusive Team"
la var TeamAgilityB "Team Agility"
la var TrustLeadershipB "Trust Leaders"
la var LeadershipStrategyB  "Leaders \& Strategy" 
la var LeadershipInclusionB "Leaders \& Inclusion"
la var HeartCustomersB "Team Prioritises Customers"

la var FocusPerfB "Can Focus"
la var AccessLearningB "Learning Resources"
la var PrioritiseControlB "Can Prioritise"
la var DevOpportunityB  "Can Advance"
la var WellbeingB "Company Cares Wellbeing"
la var ReportUnethicalB "Can Report Unethical"

la var WorkLifeBalanceB  "Work Life Balance"
la var SatisfiedB "Job Satisfaction"
la var ReferB  "Refer Company"
la var ProudB  "Proud Company"
la var LeavingB "Intention to Stay"
la var LivePurposeB "Live Purpose"
la var ExtraMileB   "Extra Mile"

la var StrategyWinB "Company Strategy Win"
la var USLPB  "Job \& Sustainability"
la var GoodTechnologiesB  "Company Good Tech"
la var CompetitionB  "Company Better Competition"
la var EffectiveBarriersB "Company Removes team Barriers"
la var IntegrityB "Business Integrity"
la var RecommendProductsB "Recommend Products"

* WELLBEING 
egen AwareHealthB = rowmax( AwareEAPB AwareLamplighterB AwareWorldMentalHB AwareMindfulnessB AwarePWB AwareThriveWB)
egen UseHealthB = rowmax(UseEAPB UseLamplighterB UseWorldMentalHB UseMindfulnessB UsePWB UseThriveWB) 
global Whealth PhysicalHB MentalHB SleepQualityB LifeSatB
global Wtalk  ManagerTalkB  ManagerCareB ManagerPrioritiseB ManagerRoleModelB JobFairnessB  RewardedB 
global Wjob    OfferSupportB   StressSupportB  StressMinimiseB  WorkplaceSupportB  LeaderRoleModelB
global Waction AwareHealthB UseHealthB WorkAmountB  WorkDecisionB

la var LifeSatB "Life Satisfaction"
la var PhysicalHB "Physical Health"
la var UnwellWorkB "Work if Unwell" // to reverse code - not using it now 
la var MentalHB "Mental Health"
la var SleepQualityB "Sleep Quality"
la var ShareSafeB "Safe to Share"
la var ManagerTalkB "Can Talk LM"
la var ManagerCareB "Manager Cares Wellbeing"
la var ManagerPrioritiseB "Manager Prioritises Wellbeing"
la var StressMinimiseB "Company Minimises Stress"
la var LeaderRoleModelB "Leaders, Health Role Models"
la var ManagerRoleModelB "Manager, Health Role Model"
la var RewardedB "Recognition at Work"
la var WorkplaceSupportB "Workplace Support"
la var WorkAmountB   "Reasonable Work Hours"
la var WorkDecisionB "Autonomy at Work"
la var JobFairnessB "Fairness on the Job"
la var OfferSupportB "Company Wellbeing Support"
la var StressSupportB "Company Stress Support"
la var AwareHealthB "Aware of Health Programs"
la var UseHealthB "Use Health Programs"

* PRINCIPAL COMPONENT ANALYSIS 
* need to have variable of same unit 
* Univoice: all variables 1-5
* Wellbeing: most variables 1-5 (take out awareness, use, financial concernes, lifeSat). 
* Note that unwellWork has to be reverse coded 
********************************************************************************

global Whealthpc PhysicalHB MentalHB SleepQualityB 
global Wtalkpc  ManagerTalkB  ManagerCareB ManagerPrioritiseB ManagerRoleModelB JobFairnessB  RewardedB WorkAmountB  WorkDecisionB 
global Wjobpc    OfferSupportB   StressSupportB PhysicalSupportB StressMinimiseB  WorkplaceSupportB  LeaderRoleModelB 
global Wawarepc AwareEAPB AwareLamplighterB AwareWorldMentalHB  AwarePWB // 0-1 scale 
global Wusepc UseEAPB UseLamplighterB UseWorldMentalHB UsePWB  // 3 scale 
global Uteampc  LineManagerB InclusiveB   TeamAgilityB TrustLeadershipB  LeadershipInclusionB HeartCustomersB
global Ufocuspc  AccessLearningB PrioritiseControlB DevOpportunityB  WellbeingB ReportUnethicalB
global Uhappypc WorkLifeBalanceB  SatisfiedB ReferB  ProudB  LivePurposeB LeavingB ExtraMileB   
global Ucompanypc StrategyWinB USLPB  GoodTechnologiesB CompetitionB EffectiveBarriersB IntegrityB RecommendProductsB

* keeping LivePurpose ReportUnet Prioritise  LineManager but they are missing in 2017
 // Not used & why: 
 // Life Sat - 10 point scale; financial concerns 0-1; UnwellWork - to reverse code
 //  AwareThriveWB, UseThriveWB, only pre 2020
 //  AwareMindfulnessB, UseMindfulnessB, only in 2020
 // ShareSafeB MentalH6Months // only in 2020
// LeadershipStrategy FocusPerfB // missing in 2021
 
foreach group in  Whealthpc Wtalkpc Wjobpc Wawarepc  Wusepc Uteampc Ufocuspc Uhappypc Ucompanypc {
pca $`group'
predict `group'1 , score // get the first component 
egen `group'Mean = rowmean($`group') // simple average 

}

label var Whealthpc1 "Health and Wellbeing"
label var Wtalkpc1 "Manager Improves Wellbeing"
label var Wjobpc1 "Company Cares Wellbeing"
label var Wawarepc1  "Aware Health Pr."
label var Wusepc1 "Use Health Pr."

label var Uteampc1 "Team Effectivess"
label var Ufocuspc1 "Autonomy"
label var Uhappypc1 "Job Satisfaction"
label var Ucompanypc1 "Company Effectivess"

label var UteampcMean "Team Effectivess"
label var UfocuspcMean "Autonomy"
label var UhappypcMean "Job Satisfaction"
label var UcompanypcMean "Company Effectivess"

label var LineManagerB "Effective Leader"

* REGRESSIONS 

bys IDlse: egen maxTransfer = max(cond(Post==1, TransferSJ,.))
bys IDlse: egen maxTransferLL = max(cond(Post==1, TransferSJLL,.))

* Cannot do Balanced sample (1 year pre and post) - because too few obs 
eststo clear 
foreach var in   LineManagerB  Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1  { // Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1
eststo `var':reghdfe `var'  EarlyAgeM##maxTransfer  if Post==1 & WL2==1 , cluster(IDlseMHR) a( Year Country Func )	// with SwitchersAllSameTeam2.dta 
*eststo `var':reghdfe `var'  EarlyAgeM##maxTransferLL  if Post==1 & WL2==1, cluster(IDlseMHR) a( $control Year Country )	
}
* option for all coefficient plots
global coefopts keep(1.EarlyAgeM#1.maxTransfer)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample, post manager transition." "Controls include: year, function and country FE." "Standard errors clustered at the manager level. 90% Confidence Intervals.", span size(small)) legend(off) ///
 aspect(0.4)  coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black)) 

 * ALL DETAILS 
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("Pulse Survey: het. effects of high flyer manager" "worker transfer - no worker transfer", pos(12) span si(large)) ///
 $coefopts xline(0, lpattern(dash)) xscale(range(-.2 .2)) xlabel(-.2(0.05)0.2)
graph export "$analysis/Results/4.Event/Survey/Univoice2TrFT.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2TrFT.gph", replace 

**# ANONYMIZED (ON PAPER)
coefplot LineManagerB Uteampc1 Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("", pos(12) span si(large))  keep(1.EarlyAgeM#1.maxTransfer)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.2 .2)) xlabel(-.2(0.05)0.2)
graph export "$analysis/Results/4.Event/Survey/Univoice2TrAFT.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2ATrFT.gph", replace 

/*
coefplot  Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1, ///
title("Wellbeing Survey: impact of high flyer manager"  "worker transfer - no worker transfer", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
graph export "$analysis/Results/4.Event/Survey/Wellbeing2TrFT.png", replace 
graph save "$analysis/Results/4.Event/Survey/Wellbeing2TrFT.gph", replace
*/
* MEAN 
********************************************************************************

eststo clear 
foreach var in   LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean  { // Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1
eststo `var':reghdfe `var'  EarlyAgeM##maxTransfer  if Post==1 & WL2==1 , cluster(IDlseMHR) a( Year Country Func )	// with SwitchersAllSameTeam2.dta 
*eststo `var':reghdfe `var'  EarlyAgeM##maxTransferLL  if Post==1 & WL2==1, cluster(IDlseMHR) a( $control Year Country )	
}

* ANONYMIZED 
coefplot LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean, ///
title("", pos(12) span si(large))  keep(1.EarlyAgeM#1.maxTransfer)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.2 .2)) xlabel(-.2(0.05)0.2)
graph export "$analysis/Results/4.Event/Survey/Univoice2MeanTrAFT.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2MeanTrAFT.gph", replace 
