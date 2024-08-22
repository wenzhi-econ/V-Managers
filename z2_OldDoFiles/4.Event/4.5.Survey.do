********************************************************************************
* This dofile looks at manager quality and survey data: univoice and wellbeing
* balanced sample event study, window of 1 year 
* change in survey measures after transitioning to manager, comparing LH to LL and HL to HH
********************************************************************************

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

////////////////////////////////////////////////////////////////////////////////
* IMPORT DATA AND PREPARE COHORT SHARES 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 
keep if Year >=2017 // years available with survey data 

* EVENT STUDY VARIABLES 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label PromSG75 // PromSG75  FT odd 

gen YEi = year(dofm(Ei))

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

gen TenureM2 = TenureM*TenureM
egen CountryYear = group(Country Year)

* renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}
* create leads and lags 
foreach var in EHL ELL EHH ELH {

gen `var'Post = K`var'>=0 & K`var' !=.

}

egen Post = rowmax(EHLPost ELLPost EHHPost ELHPost)

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

* BALANCED SAMPLE FOR OUTCOMES 12 WINDOW
* window lenght
local end = 12 // to be plugged in 
local window = 25 // to be plugged in
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-(`end') &  maxEi >=(`end') & Ei!=.
ta ii
*keep if ii==1 // MANUAL INPUT - to remove if irrelevant

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
label var Ufocuspc1 "Agency"
label var Uhappypc1 "Job Satisfaction"
label var Ucompanypc1 "Company Effectivess"

* REGRESSIONS 
********************************************************************************

global control AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM AgeBand##Female c.Tenure2##Female c.Tenure##Female
global abs IDlse Year WLM  // IDlseMHR

* $Uteam $Ufocus $Uhappy $Whealth  $Wtalk $Wjob $Waction

* Index 
********************************************************************************

* Cannot do Balanced sample (1 year pre and post) - because too few obs 
eststo clear 
foreach var in Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 {
eststo `var': reghdfe `var'  ELHPost ELLPost EHLPost EHHPost   , cluster(IDlseMHR) a( $control Year WLM)	//  if WLM2==1 &  ii==1 & KEi >=-12 & KEi <=12

margins, expression(_b[ELHPost]- _b[ELLPost]) post
estimates store `var'1
estimates restore `var'
margins, expression(_b[EHLPost]- _b[EHHPost]) post
estimates store `var'2
}
* without FE for FT but with FE for PromSG75...
 
* option for all coefficient plots
global coefopts   levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Controls include: year FE, managers' work-level, and workers and managers'" "age group FE, tenure and tenure squared interacted with gender." "Standard errors clustered at the manager level. 90% Confidence Intervals.", span size(small)) legend(off) ///
graphregion(margin(5 5 2 2)) coeflabels(, angle(30) labsize(small)) ysize(6) xsize(8) 
*ytick(,grid glcolor(black)) 

* Univoice 
coefplot  (Ufocuspc11, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (Ufocuspc12, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (Uhappypc11, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (  Uhappypc12, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (Uteampc11 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (Uteampc12 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (Ucompanypc11, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (Ucompanypc12, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low"  ) $coefopts xline(0, lpattern(dash)) groups( Ufocuspc11 Ufocuspc12 = "{bf:Agency}" Uhappypc11 Uhappypc12 = "{bf:Job Satisfaction}" Uteampc11 Uteampc12 = "{bf:Team Effectivess}" Ucompanypc11 Ucompanypc12 = "{bf:Company Effectivess}" ) ///
title("Pulse Survey", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Univoice$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice$Label.gph", replace 

* Wellbeing
coefplot (Wtalkpc11, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (Wtalkpc12, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (Wjobpc11, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  ( Wjobpc12, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (Whealthpc11, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (Whealthpc12 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white))  (Wawarepc11, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (Wawarepc12, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (Wusepc11, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (Wusepc12, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)),   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low" 13 "Low to High" 14 "High to Low" ) $coefopts xline(0, lpattern(dash)) groups( Wtalkpc11 Wtalkpc12 = "{bf:Manager Improves Wellbeing}" Wjobpc11 Wjobpc12 = "{bf:Company Cares about Wellbeing}" Whealthpc11 Whealthpc12 = "{bf:Mental and Physical Health}" Wawarepc11 Wawarepc12 = "{bf:Awareness of Health Programs}"   Wusepc11 Wusepc12="{bf: Use of Health Programs}") ///
title("Wellbeing Survey", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Wellbeing$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Wellbeing$Label.gph", replace 


* individual variables 
********************************************************************************

eststo clear 
foreach var in $Uteampc $Ufocuspc $Uhappypc $Ucompanypc $Whealthpc $Wtalkpc $Wjobpc $Wawarepc  $Wusepc {
eststo `var': reghdfe `var'  ELHPost ELLPost EHLPost EHHPost   , cluster(IDlseMHR) a( $control Year WLM)	//  if WLM2==1 &  ii==1 & KEi >=-12 & KEi <=12

margins, expression(_b[ELHPost]- _b[ELLPost]) post
estimates store `var'1
estimates restore `var'
margins, expression(_b[EHLPost]- _b[EHHPost]) post
estimates store `var'2
}

* Univoice 
coefplot  ( AccessLearningB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   ( AccessLearningB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ( PrioritiseControlB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (  PrioritiseControlB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (DevOpportunityB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (DevOpportunityB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (WellbeingB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (WellbeingB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (ReportUnethicalB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (ReportUnethicalB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low" 13 "Low to High" 14 "High to Low"  ) $coefopts xline(0, lpattern(dash)) groups(AccessLearningB1   AccessLearningB2 = "{bf:Learning Resources}" PrioritiseControlB1 PrioritiseControlB2 = "{bf:Can Prioritise}" DevOpportunityB1 DevOpportunityB2 = "{bf: Can Advance}"  WellbeingB1  WellbeingB2 = "{bf:Company Cares Wellbeing}"   ReportUnethicalB1   ReportUnethicalB2 = "{bf:Can Report Unethical}"  ) ///
title("Pulse Survey: Agency", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Ufocus$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Ufocus$Label.gph", replace  

coefplot  ( WorkLifeBalanceB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   ( WorkLifeBalanceB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ( SatisfiedB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (  SatisfiedB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (ReferB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (ReferB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (ProudB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (ProudB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (LivePurposeB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (LivePurposeB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (LeavingB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (LeavingB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (ExtraMileB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (ExtraMileB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low" 13 "Low to High" 14 "High to Low"  16 "Low to High" 17 "High to Low"  19 "Low to High" 20 "High to Low"   ) $coefopts xline(0, lpattern(dash)) groups(WorkLifeBalanceB1   WorkLifeBalanceB2 = "{bf:Work Life Balance}" SatisfiedB1 SatisfiedB2 = "{bf:Job Satisfaction}" ReferB1 ReferB2 = "{bf:Refer Company}"  ProudB1  ProudB2 = "{bf:Proud Company}"   LivePurposeB1 LivePurposeB2 = "{bf:Live Purpose}" LeavingB1 LeavingB2 = "{bf:Intention to Stay}" ExtraMileB1 ExtraMileB2 =  "{bf:Extra Mile}" ) ///
title("Pulse Survey: Job satisfaction", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Uhappy$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Uhappy$Label.gph", replace  

coefplot  (LineManagerB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (LineManagerB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ( InclusiveB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (   InclusiveB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (TeamAgilityB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (TeamAgilityB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (TrustLeadershipB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (TrustLeadershipB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (HeartCustomersB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (HeartCustomersB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low"  13 "Low to High" 14 "High to Low"   ) $coefopts xline(0, lpattern(dash)) groups(  LineManagerB1  LineManagerB2 = "{bf:Effective Manager}" InclusiveB1 InclusiveB2 = "{bf:Inclusive Team}" TeamAgilityB1 TeamAgilityB2 = "{bf: Agile Team}"  TrustLeadershipB1  TrustLeadershipB2 = "{bf:Team Trust}"   HeartCustomersB1   HeartCustomersB2 = "{bf:Team Prioritises Customers}"  ) ///
title("Pulse Survey: Team Effectiveness", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Uteam$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Uteam$Label.gph", replace


coefplot  ( StrategyWinB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   ( StrategyWinB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ( USLPB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (  USLPB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (GoodTechnologiesB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (GoodTechnologiesB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (ProudB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (ProudB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (CompetitionB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (CompetitionB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (EffectiveBarriersB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (EffectiveBarriersB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (IntegrityB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (IntegrityB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (RecommendProductsB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (RecommendProductsB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low" 13 "Low to High" 14 "High to Low"  16 "Low to High" 17 "High to Low"  19 "Low to High" 20 "High to Low"  22 "Low to High" 23 "High to Low"  ) $coefopts xline(0, lpattern(dash)) groups(StrategyWinB1   StrategyWinB2 = "{bf:Company Strategy Win}" USLPB1 USLPB2 = "{bf:Job & Sustainability}" GoodTechnologiesB1 GoodTechnologiesB2 = "{bf:Company Good Tech}" ProudB1  ProudB2 = "{bf:Proud to work at Company}" CompetitionB1  CompetitionB2 = "{bf:Company Better Competition}"   EffectiveBarriersB1 EffectiveBarriersB2 = "{bf:Company Removes team Barriers}" IntegrityB1 IntegrityB2 =  "{bf:Business Integrity}" RecommendProductsB1 RecommendProductsB2 = "{bf:Recommend Products}") ///
title("Pulse Survey: Company Effectiveness", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Ucompany$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Ucompany$Label.gph", replace  

* Wellbeing 

coefplot  (PhysicalHB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (PhysicalHB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ( MentalHB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (   MentalHB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (SleepQualityB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (SleepQualityB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low"   ) $coefopts xline(0, lpattern(dash)) groups(  PhysicalHB1  PhysicalHB2 = "{bf:Physical Health}" MentalHB1 MentalHB2 = "{bf:Mental Health}" SleepQualityB1 SleepQualityB2 = "{bf: Sleep Quality}"    ) ///
title("Wellbeing Survey: Health", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Whealth$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Whealth$Label.gph", replace


coefplot  ( ManagerTalkB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   ( ManagerTalkB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ( ManagerCareB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (  ManagerCareB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (ManagerPrioritiseB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (ManagerPrioritiseB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (ManagerRoleModelB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (ManagerRoleModelB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (JobFairnessB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (JobFairnessB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (RewardedB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (RewardedB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (WorkAmountB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (WorkAmountB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (WorkDecisionB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (WorkDecisionB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low" 13 "Low to High" 14 "High to Low"  16 "Low to High" 17 "High to Low"  19 "Low to High" 20 "High to Low"  22 "Low to High" 23 "High to Low"  ) $coefopts xline(0, lpattern(dash)) groups(ManagerTalkB1   ManagerTalkB2 = "{bf:Can talk with Manager}" ManagerCareB1 ManagerCareB2 = "{bf:Manager Cares Wellbeing}" ManagerPrioritiseB1 ManagerPrioritiseB2 = "{bf:Manager Prioritises Wellbeing}" ManagerRoleModelB1 ManagerRoleModelB2 = "{bf:Manager, Health Role Model}" JobFairnessB1  JobFairnessB2 = "{bf:Fairness on the Job}"   RewardedB1 RewardedB2 = "{bf:Recognition at Work}" WorkAmountB1 WorkAmountB2 =  "{bf:Reasonable Work Hours}" WorkDecisionB1 WorkDecisionB2 = "{bf:Autonomy at Work}") ///
title("Wellbeing Survey: Manager Behavior", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Wtalk$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Wtalk$Label.gph", replace  

coefplot  ( OfferSupportB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   ( OfferSupportB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (StressSupportB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (  StressSupportB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (PhysicalSupportB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (PhysicalSupportB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (StressMinimiseB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (StressMinimiseB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (WorkplaceSupportB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (WorkplaceSupportB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (LeaderRoleModelB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (LeaderRoleModelB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white))  ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low" 13 "Low to High" 14 "High to Low"  16 "Low to High" 17 "High to Low"   ) $coefopts xline(0, lpattern(dash)) groups(OfferSupportB1   OfferSupportB2 = "{bf:Company Wellbeing Support}" StressSupportB1 StressSupportB2 = "{bf:Company Stress Support}" PhysicalSupportB1 PhysicalSupportB2 = "{bf:Company supports Physical Activity}"  StressMinimiseB1  StressMinimiseB2 = "{bf:Company Minimises Stress}"   WorkplaceSupportB1 WorkplaceSupportB2 = "{bf:Workplace Support}" LeaderRoleModelB1 LeaderRoleModelB2 =  "{bf:Leaders, Health Role Models}" ) ///
title("Wellbeing Survey: Company Support", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Wjob$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Wjob$Label.gph", replace 

coefplot  ( AwareEAPB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   ( AwareEAPB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (AwareLamplighterB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (  AwareLamplighterB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (AwareWorldMentalHB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (AwareWorldMentalHB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (AwarePWB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (AwarePWB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low"  ) $coefopts xline(0, lpattern(dash)) groups(AwareEAPB1 AwareEAPB2 = "{bf:Aware of Assistance Program}" AwareLamplighterB1 AwareLamplighterB2= "{bf:Aware of Lamplighter}" AwareWorldMentalHB1 AwareWorldMentalHB2 = "{bf:Aware of Mental Health Day}"  AwarePWB1  AwarePWB2 = "{bf:Aware of Purpose Workshop}" ) ///
title("Wellbeing Survey: Awareness of Health Programs", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Waware$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Waware$Label.gph", replace 

coefplot  ( UseEAPB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   ( UseEAPB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (UseLamplighterB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))  (  UseLamplighterB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ( UseWorldMentalHB1 , ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  ( UseWorldMentalHB2 , ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) (UsePWB1, ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white))   (UsePWB2, ciopts(lwidth(2 ..) lcolor(erose))  msymbol(o) mcolor(white)) ,   ylab(1 "Low to High" 2 "High to Low" 4 "Low to High" 5 "High to Low" 7 "Low to High" 8 "High to Low" 10 "Low to High" 11 "High to Low"  ) $coefopts xline(0, lpattern(dash)) groups(UseEAPB1 UseEAPB2 = "{bf:Use of Assistance Program}" UseLamplighterB1 UseLamplighterB2= "{bf:Use of Lamplighter}"  UseWorldMentalHB1  UseWorldMentalHB2 = "{bf: Use of Mental Health Day}"  UsePWB1  UsePWB2 = "{bf:Use of Purpose Workshop}" ) ///
title("Wellbeing Survey: Use of Health Programs", size(vlarge) span) 
graph export "$analysis/Results/4.Event/Survey/Wuse$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/Wuse$Label.gph", replace 


/* Variables for regressions 
********************************************************************************

des $eventinteract 
global cont  TeamSize c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs Year AgeBand AgeBandM IDlse  // IDlseMHR
global exitFE CountryYear AgeBand AgeBandM   IDlseMHR  Female

eststo  clear
* $Uteam $Ufocus $Uhappy $Ucompany $Whealth  $Wtalk $Wjob $Waction
foreach var in Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1  {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo `var': reghdfe `var' $eventinteract $cont if WLM2==1 & ii==1, a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
sort IDlse YearMonth

cap drop bH1 loH1 hiH1 pH1 seH1 bHL1 seHL1 bHH1 seHH1 bL1 loL1 hiL1 pL1 seL1 bLL1 seLL1 bLH1 seLH1
coeffStaticCohort14, y(`var')

foreach v in  LH1 LL1 L1 HL1 HH1 H1{
	sort IDlse YearMonth
	su b`v'
	estadd scalar b`v' = r(mean)
	su se`v'
	estadd scalar se`v' = r(mean)
	gen `var'b`v' = b`v' 
	gen `var'se`v' = se`v' 
	ge `var'lb`v' = `var'b`v' -1.96*`var'se`v'
	ge `var'ub`v' = `var'b`v' +1.96*`var'se`v'

}
} 

* tables 
********************************************************************************

esttab Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1  using "$analysis/Results/4.Event/Survey/PCAWellbeing$Label.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH1 seLH1 bLL1 seLL1 bL1 seL1 bHL1 seHL1 bHH1 seHH1 bH1 seH1 cmean N1 r2, labels("Post E\textsubscript{LH}" " " "Post E\textsubscript{LL}" " " "\hline Post E\textsubscript{LH}-E\textsubscript{LL}" " " "\hline Post E\textsubscript{HL}" " " "Post E\textsubscript{HH}" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}" " " " \hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Binary specification of the survey outcome: probability of answering 5 on a 5-point Likert scale. Controls include: worker FE, year FE, team size, and age group FE and quadratic in tenure for both employee and manager.  ///
"\end{tablenotes}") replace

esttab Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1  using "$analysis/Results/4.Event/Survey/PCAUnivoice$Label.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH1 seLH1 bLL1 seLL1 bL1 seL1 bHL1 seHL1 bHH1 seHH1 bH1 seH1 cmean N1 r2, labels("Post E\textsubscript{LH}" " " "Post E\textsubscript{LL}" " " "\hline Post E\textsubscript{LH}-E\textsubscript{LL}" " " "\hline Post E\textsubscript{HL}" " " "Post E\textsubscript{HH}" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}" " " " \hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Binary specification of the survey outcome: probability of answering 5 on a 5-point Likert scale. Controls include: worker FE, year FE, team size, and age group FE and quadratic in tenure for both employee and manager.  ///
"\end{tablenotes}") replace

/*
foreach group in Whealth  Uteam Ufocus Uhappy Wtalk Wjob Waction  {
esttab $`group' using "$analysis/Results/4.Event/Survey/`group'$Label.tex", label star(* 0.10 ** 0.05 *** 0.01) drop(*) se r2 ///
s(bLH1 seLH1 bLL1 seLL1 bL1 seL1 bHL1 seHL1 bHH1 seHH1 bH1 seH1 cmean N1 r2, labels("Post E\textsubscript{LH}" " " "Post E\textsubscript{LL}" " " "\hline Post E\textsubscript{LH}-E\textsubscript{LL}" " " "\hline Post E\textsubscript{HL}" " " "Post E\textsubscript{HH}" " " "\hline Post E\textsubscript{HL}-E\textsubscript{HH}" " " " \hline Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Binary specification of the survey outcome: probability of answering 5 on a 5-point Likert scale. Controls include: worker FE, year FE, team size, and age group FE and quadratic in tenure for both employee and manager.  ///
"\end{tablenotes}") replace
} 
*/ 

* coefplots 
********************************************************************************

sort IDlse YearMonth

gen post = "Low to High" in 1
replace post = "High to Low" in 2
encode post, gen(postE)

foreach var in Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 $Uteam $Ufocus $Uhappy $Whealth  $Wtalk $Wjob $Waction {
ge `var'coeff = .
replace `var'coeff = `var'bL1 in 1
replace `var'coeff = l.`var'bH1 in 2
ge `var'lb = `var'bL1- 1.96*`var'seL1 in 1
replace  `var'lb = l.`var'bH1- 1.96*l.`var'seH1 in 2
ge `var'ub = `var'bL1+ 1.96*`var'seL1 in 1
replace  `var'ub = l.`var'bH1+ 1.96*l.`var'seH1 in 2

local lab: variable label `var'
graph twoway (bar `var'coeff postE) (rcap `var'lb `var'ub postE), xlabel(1 "Low to High" 2 "High to Low" ) xtitle("") legend(off) title("`lab'") note("Notes. Binary specification, probability of answering 5 on a 5-point Likert scale.")
graph export "$analysis/Results/4.Event/Survey/`var'$Label.png", replace 
graph save "$analysis/Results/4.Event/Survey/`var'$Label.gph", replace 
}





