********************************************************************************
* This dofile looks at manager quality and survey data: univoice and wellbeing
* COHORT FE STATIC
* change in survey measures after transitioning to manager, comparing LH to LL
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

////////////////////////////////////////////////////////////////////////////////
* IMPORT DATA AND PREPARE COHORT SHARES 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 
keep if Year >=2017 // years available with survey data 

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

* Wellbeing 2018-2020
********************************************************************************

merge m:1 IDlse Year using "$fulldta/Wellbeing.dta"
rename _merge _mergeW

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
* REGRESSIONS
////////////////////////////////////////////////////////////////////////////////

* If instead want to keep the levels, but avoid changing variable names below 
/* Uncomment as needed 
foreach var in  $univoiceAll $wellbeingAll {
	replace `var'B = `var'
}
*/
* Variables for regressions 
********************************************************************************

egen CountryYear = group(Country Year)

des $eventinteract 
global cont  TeamSize c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs Year AgeBand AgeBandM IDlse  // IDlseMHR
global exitFE CountryYear AgeBand AgeBandM   IDlseMHR  Female

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
la var HeartCustomersB "Team Prioritise Customers"

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
la var ManagerPrioritiseB "Manager Prioritise Wellbeing"
la var StressMinimiseB "Minimise Stress"
la var LeaderRoleModelB "Leaders, Health Model"
la var ManagerRoleModelB "Manager, Health Model"
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
predict `group'1 , score 
}

label var Whealthpc1 "Health"
label var Wtalkpc1 "Manager Improves Wellbeing"
label var Wjobpc1 "Company Cares Wellbeing"
label var Wawarepc1  "Aware Health Pr."
label var Wusepc1 "Use Health Pr."

label var Uteampc1 "Team Effectivess"
label var Ufocuspc1 "Agency"
label var Uhappypc1 "Job Satisfaction"
label var Ucompanypc1 "Company Effectivess"

foreach group in  Whealthpc Wtalkpc Wjobpc Wawarepc  Wusepc Uteampc Ufocuspc Uhappypc Ucompanypc {
egen `group'Av = rowmean( $`group')
}

* REGRESSIONS 
********************************************************************************

eststo  clear
* Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 
foreach var in WhealthpcAv WtalkpcAv WjobpcAv WawarepcAv  WusepcAv UteampcAv UfocuspcAv UhappypcAv UcompanypcAv  {

 local lab : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo `var': reghdfe `var' EiPost EiPostDelta , a( IDlse    ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

} 

eststo  clear
* $Uteam $Ufocus $Uhappy $Ucompany $Whealth  $Wtalk $Wjob $Waction
foreach var in $Uteam $Ufocus $Uhappy $Ucompany $Whealth  $Wtalk $Wjob $Waction {

 local lab : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo `var': reghdfe `var' EiPost EiPostDelta , a( IDlse  Year  ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

} 


* coefplots 
********************************************************************************

	local Label FT //   FT PromSG75
* $Uteam $Ufocus $Uhappy $Ucompany $Whealth  $Wtalk $Wjob $Waction
foreach var in Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1 Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1  {
local lab : variable label `var'

coefplot `var'  , levels(90) ///
keep(*Post*) vertical recast(bar )  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq scheme(burd5) barwidth(0.5)  addplot(scatter @b @at, ms(i) mlabel( @b) mlabpos(2) mlabcolor(black) mlabsize(medlarge)) format(%9.2g) ///
coeflabels(  reg1FE = "{bf:`lab'}", labsize(medlarge)  ) ///
note("Notes. An observation is a worker-month. Controls include: worker fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Binary specification, probability of answering 5 on a 5-point Likert scale." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) ytitle(Percentage points, size(medlarge)) yscale(range(0 0.2)) ylabel(0(0.05)0.2)
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/4.Event/Survey/`Label'`var'.png", replace
graph save  "$analysis/4.Event/Survey/`Label'`var'.gph", replace

}

* tables 
********************************************************************************

esttab Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1  using "$analysis/Results/4.Event/Survey/PCAWellbeing$Label.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EiPost EiPostDelta) se r2 ///
s( cmean N1 r2, labels("Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
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






