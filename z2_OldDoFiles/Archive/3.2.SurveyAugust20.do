********************************************************************************
* ADDITIONAL DATA SOURCES FOR SUGGESTIVE EVIDENCE
* Univoice, exit survey and learning data 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

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
********************************************************************************

global control AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM AgeBand##Female c.Tenure2##Female c.Tenure##Female
global abs IDlse Year WLM  // IDlseMHR

* $Uteam $Ufocus $Uhappy $Whealth  $Wtalk $Wjob $Waction

* Index 
********************************************************************************

* option for all coefficient plots
global coefopts keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample, post manager transition." "Controls include: year and country FE, managers' age group FE," "tenure and tenure squared interacted with managers' gender." "Standard errors clustered at the manager level. 95% Confidence Intervals.", span size(small)) legend(off) ///
aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black)) 

* First principal component 
********************************************************************************

* Cannot do Balanced sample (1 year pre and post) - because too few obs 
eststo clear 
foreach var in LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1{ 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( $control Year Country WLM )
qui sum `e(depvar)' if (e(sample) & Post==1 & EarlyAgeM==0)
estadd scalar Mean = r(mean)	
}
* outcome mean low flyer 
su LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1   if Post==1 & EarlyAgeM==0 

/* PLOT 1: with all details 
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("Pulse Survey: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash)) xscale(range(-.04 .1)) xlabel(-.04(0.02)0.1)
graph export "$analysis/Results/4.Event/Survey/Univoice2FT.pdf", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2FT.gph", replace 
*/

label var EarlyAgeM "High-flyer manager"
**# ON PAPER TABLE: Univoice2AFT.tex
esttab LineManagerB Uteampc1 Uhappypc1 Ufocuspc1 Ucompanypc1 using "$analysis/Results/0.Paper/3.2.Survey/Univoice2AFT.tex", replace ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(Mean N r2, fmt(3 0 4) labels("Mean, low-flyer" "N" "R-squared")) ///
label nofloat nonotes collabels(none) drop(_cons) ///
mtitles("Effective Leader" "Team Effectiveness" "Job Satisfaction" "Autonomy" "Company Effectiveness") ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-year-month. Data from the annual pulse survey run by the firm since 2017. Standard errors are clustered by manager. Survey indices are the first principal components of various survey questions, grouped together by theme as detailed in Appendix Table \ref{tab:construction}. I use binary variables: probability of answering 5 out of 5-point Likert Scale. Estimates obtained by running the model in equation \ref{eq:static}. Appendix Table \ref{tab:SurveyMean} Panel (a) shows that the results are very similar when using simple averages for the indices instead of the first principal component.  ///
"\end{tablenotes}")

/**# previously was a figure, ON PAPER FIGURE: Univoice2AFTE.pdf
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.04 .1)) xlabel(-.04(0.02)0.1)   
graph export "$analysis/Results/0.Paper/3.2.Survey/Univoice2AFT.pdf", replace 
graph save "$analysis/Results/0.Paper/3.2.Survey/Univoice2AFT.gph", replace
*/

* plot using the mean 
********************************************************************************

eststo clear 
foreach var in LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean WhealthpcMean WtalkpcMean WjobpcMean WawarepcMean  WusepcMean{ 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( $control Year Country WLM )
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)	
}
* outcome mean low flyer
su LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean WhealthpcMean WtalkpcMean WjobpcMean WawarepcMean  WusepcMean   if Post==1 & EarlyAgeM ==0

**# NEW ON PAPER TABLE: SurveyMean.tex (Top Panel)
esttab LineManagerB UteampcMean  UhappypcMean UfocuspcMean UcompanypcMean using "$analysis/Results/0.Paper/3.2.Survey/SurveyMean.tex", replace ///
prehead("\begin{tabular}{l*{5}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel (a): using averages for the indices}} \\\\[-1ex]") ///
fragment ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(Mean N r2, fmt(3 0 4) labels("Mean" "N" "R-squared")) ///
label nofloat nonotes collabels(none) drop(_cons) ///
mtitles("Effective Leader" "Team Effectiveness" "Job Satisfaction" "Autonomy" "Company Effectiveness") 

/**# previously was a figure, ON PAPER FIGURE: Univoice2MeanAFTE.pdf
coefplot LineManagerB UteampcMean  UhappypcMean UfocuspcMean UcompanypcMean, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.01 .04)) xlabel(-.01(0.01)0.04)   
graph export "$analysis/Results/0.Paper/3.2.Survey/Univoice2MeanAFT.pdf", replace 
graph save "$analysis/Results/0.Paper/3.2.Survey/Univoice2AMeanFT.gph", replace

* PLOT 3: WELLBEING SURVEY 
coefplot  Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1, ///
title("Wellbeing Survey: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
graph export "$analysis/Results/4.Event/Survey/Wellbeing2FT.pdf", replace 
graph save "$analysis/Results/4.Event/Survey/Wellbeing2FT.gph", replace
*/

* ROBUSTNESS: ONLY FIRST YEAR TO ADDRESS SELECTED SAMPLE ISSUE - PC
********************************************************************************

*Cannot do Balanced sample (1 year pre and post) - because too few obs 
eststo clear 
foreach var in LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 { // Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 & KEi <=12 , cluster(IDlseMHR) a( $control Year Country WLM  )	
}

/* PLOT 4, robustness: anonymized 
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.1 .1)) xlabel(-.1(0.02)0.1)   
graph export "$analysis/Results/4.Event/Survey/Univoice2AFT1Year.pdf", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2AFT1Year.gph", replace 
*/

* ROBUSTNESS: ONLY FIRST YEAR TO ADDRESS SELECTED SAMPLE ISSUE - MEAN
********************************************************************************

*Cannot do Balanced sample (1 year pre and post) - because too few obs 
eststo clear 
foreach var in  LineManagerB UteampcMean  UhappypcMean UfocuspcMean UcompanypcMean { // Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 & KEi <=12 , cluster(IDlseMHR) a( $control Year Country WLM  )	
}

/* PLOT 4, robustness: anonymized 
coefplot LineManagerB UteampcMean  UhappypcMean UfocuspcMean UcompanypcMean, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.1 .1)) xlabel(-.1(0.02)0.1)   
graph export "$analysis/Results/4.Event/Survey/Univoice2MeanAFT1Year.pdf", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2MeanAFT1Year.gph", replace 
*/

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

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/0.Paper/_CoeffProgram.do"

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
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)	
}

* option for all coefficient plots
global coefopts keep(1.EarlyAgeM#1.maxTransfer)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample, post manager transition." "Controls include: year, function and country FE." "Standard errors clustered at the manager level. 95% Confidence Intervals.", span size(small)) legend(off) ///
 aspect(0.4)  coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black)) 

/* ALL DETAILS 
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("Pulse Survey: het. effects of high flyer manager" "worker transfer - no worker transfer", pos(12) span si(large)) ///
 $coefopts xline(0, lpattern(dash)) xscale(range(-.2 .2)) xlabel(-.2(0.05)0.2)
graph export "$analysis/Results/4.Event/Survey/Univoice2TrFT.pdf", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2TrFT.gph", replace
*/ 

label var maxTransfer "Worker changed job"
label var EarlyAgeM "High-flyer manager"
**# ON PAPER TABLE: SurveyMean.tex (Bottom Panel)
estadd local label 1.EarlyAgeM#1.maxTransfer "High-flyer manager=1 × Worker changed job"

esttab LineManagerB Uteampc1 Uhappypc1 Ufocuspc1 Ucompanypc1 using "$analysis/Results/0.Paper/3.2.Survey/SurveyMean.tex", ///
posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel (b): heterogeneous effects by whether worker changes job}} \\\\[-1ex]") ///
fragment ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(Mean N r2, fmt(3 0 4) labels("Mean" "N" "R-squared")) ///
nofloat nonotes collabels(none) nonumbers nolines nomtitles ///
keep(1.EarlyAgeM#1.maxTransfer) label ///
rename(1.maxTransfer "Worker changed job") ///
append ///
prefoot("\hline") ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-year-month. Standard errors are clustered by manager. In Panel (a), survey indices are the average of various survey questions, grouped together by theme as detailed in Appendix Table \ref{tab:construction}. I use binary variables: probability of answering 5 out of 5-point Likert Scale.  Estimates obtained by running the model in equation \ref{eq:static}. In Panel (b), survey indices are the first principal components of various survey questions, grouped together by theme as detailed in Appendix Table \ref{tab:construction} and sample restricted to the first year since the manager transition. Estimates obtained by running the model in equation \ref{eq:static} interacting indicator for high-flyer manager with an indicator for whether the worker changes job. ///
"\end{tablenotes}") 

/**# previously was a figure, ON PAPER FIGURE: Univoice2ATrFTE.pdf
coefplot LineManagerB Uteampc1 Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("", pos(12) span si(large))  keep(1.EarlyAgeM#1.maxTransfer)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.2 .2)) xlabel(-.2(0.05)0.2)
graph export "$analysis/Results/0.Paper/3.2.Survey/Univoice2TrAFT.pdf", replace 
graph save "$analysis/Results/0.Paper/3.2.Survey/Univoice2ATrFT.gph", replace 
*/
/*
coefplot  Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1, ///
title("Wellbeing Survey: impact of high flyer manager"  "worker transfer - no worker transfer", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
graph export "$analysis/Results/4.Event/Survey/Wellbeing2TrFT.pdf", replace 
graph save "$analysis/Results/4.Event/Survey/Wellbeing2TrFT.gph", replace
*/

* MEAN 
********************************************************************************

eststo clear 
foreach var in   LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean  { // Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1
eststo `var':reghdfe `var'  EarlyAgeM##maxTransfer  if Post==1 & WL2==1 , cluster(IDlseMHR) a( Year Country Func )	// with SwitchersAllSameTeam2.dta 
*eststo `var':reghdfe `var'  EarlyAgeM##maxTransferLL  if Post==1 & WL2==1, cluster(IDlseMHR) a( $control Year Country )	
}

/* ANONYMIZED 
coefplot LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean, ///
title("", pos(12) span si(large))  keep(1.EarlyAgeM#1.maxTransfer)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.2 .2)) xlabel(-.2(0.05)0.2)
graph export "$analysis/Results/4.Event/Survey/Univoice2MeanTrAFT.pdf", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2MeanTrAFT.gph", replace 
*/


********************************************************************************
* ADDITIONAL DATA SOURCES FOR SUGGESTIVE EVIDENCE
* Exit survey and learning data 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

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
global coefopts keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample, post manager transition. Year FE included." "Standard errors clustered at the manager level. 95% Confidence Intervals.", span size(small)) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
* "Controls include: managers' age group FE, tenure and tenure squared interacted with managers' gender."

/* reason for changing organization
coefplot  ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1  ReasonAnotherOrg6 ReasonAnotherOrg3   , ///
title("Reasons for joining another company:" "impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash)) 
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/0.Paper/3.2.Survey/FTReasonAnotherOrg.pdf", replace
*/


**# ON PAPER FIGURE: FTReasonLeavingAE.pdf
coefplot  ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1  ReasonAnotherOrg6 ReasonAnotherOrg3 , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/0.Paper/3.2.Survey/FTReasonAnotherOrgA.pdf", replace

/*
* reasons for leaving 
coefplot  ReasonLeaving5  ReasonLeaving4 ReasonLeaving1  ReasonLeaving6 ReasonLeaving7 ReasonLeaving2 ReasonLeaving3, ///
title("Reasons for leaving: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/0.Paper/3.2.Survey/FTReasonLeaving.pdf", replace

coefplot   ReasonLeaving5  ReasonLeaving4 ReasonLeaving1 ReasonLeaving6 ReasonLeaving7  ReasonLeaving2 ReasonLeaving3, ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/0.Paper/3.2.Survey/FTReasonLeavingA.pdf", replace
*/

********************************************************************************
* 2. FLEX 
********************************************************************************

*merge 1:1 IDlse YearMonth using "$fulldta/FLEX.dta"
merge m:1 IDlse using "$fulldta/FLEX.dta"

drop if _merge==2
gen InFLEX = _merge==3
label var InFLEX "Registered on Platform"
drop _merge

egen Apply = rowmax( PositionsAppliedDummy ProjectRolesAppliedDummy) 
egen Accept = rowmax(ProjectRolesAcceptedDummy  PositionsAcceptedDummy )
egen Assign = rowmax( ProjectRolesAssignedDummy PositionsAssignedDummy)

* FLEX
global FLEXProjectVar ProjectRolesAppliedDummy ProjectRolesAssignedDummy ProjectRolesAcceptedDummy ProjectsCreatedDummy	
global FLEXPositionVar InFLEX PositionsAppliedDummy PositionsAssignedDummy 
global FLEXOtherVar CompletedProfileDummy AvailableMentor AvailableJobs MyDevelopment
global FLEXHoursVar HoursAvailable	HoursUnlocked HoursWeeklyConsumedProject
* other vars: Apply Accept Assign NrProjectRolesApplied NrPositionsApplied NrProjectRolesAccepted NrPositionsAccepted NrProjectRolesAssigned  NrPositionsAssigned

eststo clear 
foreach var in    InFLEX CompletedProfileDummy AvailableJobs  AvailableMentor PositionsAppliedDummy   { // PositionsAppliedDummy ProjectRolesAppliedDummy $FLEXPositionVar $FLEXOtherVar 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 & Year>2019 , cluster(IDlseMHR) a( Year Country)	// WL2 takes away 2/3 of sample 
qui sum `e(depvar)' if (e(sample) & Post==1 & Year>2019 & EarlyAgeM==0)
estadd scalar Mean = r(mean)
}

/*
esttab $FLEXProjectVar , se star(* 0.10 ** 0.05 *** 0.01) keep( EarlyAgeM)  nocons nobaselevels
esttab $FLEXPositionVar  , se star(* 0.10 ** 0.05 *** 0.01) keep( EarlyAgeM)  nocons nobaselevels
esttab $FLEXOtherVar  , se star(* 0.10 ** 0.05 *** 0.01) keep( EarlyAgeM)  nocons nobaselevels
*/

* option for all coefficient plots
global coefopts keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample, post manager transition. Year and country FE included." "Standard errors clustered at the manager level. 95% Confidence Intervals.", span size(small)) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
* "Controls include: managers' age group FE, tenure and tenure squared interacted with managers' gender."

/*coefplot InFLEX CompletedProfileDummy AvailableJobs  AvailableMentor PositionsAppliedDummy  , ///
title("Flexible Projects: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
graph export  "$analysis/Results/0.Paper/3.2.Survey/Flex.pdf", replace
*/


* baseline mean 
su  InFLEX CompletedProfileDummy AvailableJobs  AvailableMentor PositionsAppliedDummy if Post==1 & Year>2019 & EarlyAgeM==0

label var EarlyAgeM "High-flyer manager"
**# ON PAPER TABLE: FlexA.tex
esttab InFLEX CompletedProfileDummy AvailableJobs  AvailableMentor PositionsAppliedDummy using "$analysis/Results/0.Paper/3.2.Survey/FlexA.tex", replace ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(Mean N r2, fmt(3 0 4) labels("Mean, low-flyer" "N" "R-squared")) ///
label nofloat nonotes collabels(none) drop(_cons) ///
mtitles("Registered on Platform" "Profile Completed" "Available for Jobs" "Available for Mentors" "Applied to Position") ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Data are taken from flexible project program at the firm since 2020 that allows workers to apply for short-term projects inside the company but outside their current team. \textit{Registered on the platform} indicates whether the employee created an account on the flexible projects platform. The remaining outcomes are for those employees that registered on the platform: \textit{Profile Completed} indicates whether the profile on the platform is fully completed; \textit{Available for Jobs} indicates whether the employee is available for jobs; \textit{Available for Mentors} indicates whether the employee is available for mentors; and \textit{Applied to Position} indicates whether the employee has applied to a position on the platform.  Controls include country and year FE. Estimates are obtained by running the model in equation \ref{eq:static}.  ///
"\end{tablenotes}")

/**# previously was a figure, ON PAPER FIGURE: FlexAE.pdf
coefplot  InFLEX CompletedProfileDummy AvailableJobs  AvailableMentor PositionsAppliedDummy , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
graph export  "$analysis/Results/0.Paper/3.2.Survey/FlexA.pdf", replace
*/
