********************************************************************************
* REGRESSION RESULTS TABLE/FIGURE
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 

* choose the manager type !MANUAL INPUT!
global Label  FT  
global typeM  EarlyAgeM

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

*keep if Ei!=. 
gen KEi  = YearMonth - Ei 
gen Post = KEi >=0 if KEi!=.

gen JobbWL2 = WL==2
gen JobbWL3 = WL==3
gen JobbWL4Agg = WL>3 if WL!=.

merge m:1 Office SubFuncS StandardJob YearMonth using "$managersdta/NewOldJobs.dta" , keepusing(NewJob OldJob)
drop _merge 

merge m:1 StandardJob  YearMonth IDlseMHR Office  using "$managersdta/NewOldJobsManager.dta", keepusing(NewJobManager OldJobManager)
keep if _merge==3
drop _merge 

merge m:1  Office SubFuncS YearMonth using "$managersdta/Temp/ManagerJobs.dta", keepusing(JobWL2 JobWL3 JobWL4Agg UnitSize )
keep if _merge==3
drop _merge 

eststo clear 
foreach v in  JobWL2 OldJob NewJob  { // JobWL3 JobWL4Agg  NewJobManager OldJobManager
eststo `v': reghdfe `v' EarlyAgeM  if WL2==1 , cluster(IDlseMHR) a( Func YearMonth)
*eststo `v': reghdfe `v' EarlyAgeM  if WL2==1 , cluster(IDlseMHR) a( Func Country YearMonth)

} 

su JobWL2 OldJob NewJob if EarlyAgeM==0 & WL2==1

label var NewJob "Probability of job created"
label var OldJob "Probability of job destroyed"
label var  JobWL2 "Share of managerial jobs"

/*
coefplot    NewJob OldJob   JobWL2  ,  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample." "Controls include: function, year, month and country FE" "Standard errors clustered at the manager level. 95% Confidence Intervals.", span size(small)) legend(off) ///
aspect(0.4) xlabel(-0.008(0.002) 0.008) coeflabels(, ) ysize(6) xsize(8) ytick(,grid glcolor(black)) xline(0, lpattern(dash))
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/2.Descriptives/NewJob.pdf", replace
*/

**# ON PAPER FIGURE: NewJobAE.png
coefplot    NewJob OldJob   JobWL2  ,  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq  xlabel(-0.008(0.002) 0.008) ///
scale(1)  legend(off) coeflabels(, ) ysize(6) xsize(8) aspect(0.5) ytick(,grid glcolor(black)) xline(0, lpattern(dash))
graph export  "$analysis/Results/0.Paper/1.2.Descriptives Figures/NewJobA.pdf", replace


********************************************************************************
* SALES PRODUCTIVITY
********************************************************************************

********************************************************************************
* Gaining vs losing manager with employee ID fe
********************************************************************************

use "$managersdta/AllSameTeam.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )

gen Post = KEi >=0 if KEi!=.

* Delta of managerial talent 
foreach var in  EarlyAgeM  { // MFEBayesPromSG50 MFEBayesPromSG75 MFEBayesPromSG 
cap drop diffM Deltatag  DeltaM
xtset IDlse YearMonth 
gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag) 
gen Post`var' = Post*DeltaM
}

* gen variables 
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 
gen lt = log(TransferSJC+ 1)
*gen llt = log(TransferSJLLC+ 1)
*gen vt = log(TransferSJVC+ 1)

* how many workers
distinct IDlse if lp!=. & ISOCode == "IND"  //  3330
distinct IDlse if lp!=. & ISOCode == "IND" & KEi!=.  //   2541

************************************************************************
* FIGUREs in paper 
************************************************************************

* FIG1: gaining HF
************************************************************************

eststo clear 
eststo r1: reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth  )
*eststo r1: reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017, cluster(IDlseMHR) a( IDlse StandardJob YearMonth  ) // with Job FE Gharad check
eststo r2: reghdfe LogPayBonus  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=.& Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // wages are increasingly muchs less than proportionally 
eststo r3: reghdfe lt  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // first stage 

* robustness 
reghdfe lp  FTLHPost  FTLLPost FTHLPost FTHHPost   if   ISOCode =="IND"  & (KEi<=-1 | KEi>=24),  a( IDlse YearMonth  )
lincom    FTLHPost  -    FTLLPost

* baseline mean 
su TransferSJC Productivity PayBonus if ISOCode =="IND" & lp!=. & FTLL!=.
di 9800.484*0.42 // magnitudes reported in paper 

**# ON PAPER FIGURE: ProdPlotLHE.png
coefplot (r1,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) (r3,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(95) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1= "Sales bonus (in logs, INR)"  r2= "Pay (in logs, EUR)"  r3= "Lateral moves (in logs)" ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xtitle("% change")   xscale(range(0 50)) xlabel(0(10)50) title("Gaining a high-flyer manager", size(medium))
 *title("Past exposure to high-flyer")  
graph export "$analysis/Results/0.Paper/3.1.Productivity/ProdPlotLH.pdf", replace 
graph save "$analysis/Results/0.Paper/3.1.Productivity/ProdPlotLH.gph", replace

************************************************************************
* Mediation exercise 
************************************************************************

reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth  ) // alpha1
local alpha1 = _b[ PostEarlyAgeM]
reghdfe lt  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // theta 
local theta = _b[ PostEarlyAgeM]
reghdfe lp lt  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // beta 
local beta = _b[ lt ]

di `beta'*`theta'/`alpha1' // 44%

* losing a high flyer // BUT VERY FEW OBSERVATIONS 
********************************************************************************
eststo r1b: reghdfe lp  PostEarlyAgeM    if  (FTHL!=. | FTHH !=.) & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth  )
eststo r2b: reghdfe LogPayBonus  PostEarlyAgeM    if   (FTHL!=. | FTHH !=.)  & ISOCode =="IND" & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth )
eststo r3b: reghdfe lt  PostEarlyAgeM    if   (FTHL!=. | FTHH !=.)  & ISOCode =="IND"  & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth) // first stage
* baseline mean 
su TransferSJC Productivity PayBonus if ISOCode =="IND" & lp!=. & FTHH!=.

* FIG2: Moves under a high flyer vs low flyer 
********************************************************************************

bys IDlse : egen t1to5p = max(cond(KEi>0 & KEi<=60 &lp!=.,TransferSJ ,.))
bys IDlse : egen t1to3p = max(cond(KEi>0 & KEi<=36 &lp!=.,TransferSJ ,.))
bys IDlse : egen t1to2p = max(cond(KEi>0 & KEi<=24&lp!=.,TransferSJ ,.))

ta t1to5p // 40% people move 
eststo clear 
* People who change  - post productivity 
eststo r1: reghdfe lp  PostEarlyAgeM Post    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a( IDlse YearMonth  )
eststo r1b: reghdfe lp  FTLHPost  FTLLPost    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a( IDlse YearMonth  )
lincom    FTLHPost  -    FTLLPost

eststo r1c: reghdfe lp  PostEarlyAgeM Post    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==0, cluster(IDlseMHR) a( IDlse YearMonth  )

* People who do not change  - pre productivity 
gen HFpre = 1 if FTLH !=.
replace HFpre = 0 if FTLL !=.
eststo r2: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & Year>2017 & t1to5p==0, cluster(IDlseMHR) a(  YearMonth  )
eststo r2b: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & t1to5p==0, cluster(IDlseMHR) a(  YearMonth  )

* People who change  - pre productivity 
eststo r3: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a(  YearMonth  )
eststo r3b: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & t1to5p==1, cluster(IDlseMHR) a(  YearMonth  )

**# ON PAPER FIGURE: ProdMoversE.png
coefplot (r1,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2b,  rescale(100) keep(HFpre) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM HFpre )  levels(95) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1= "Movers, post manager transition"  r2b= "Non-movers, pre manager transition"  ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xtitle("% change")   xscale(range(0 100)) xlabel(0(10)100) title("Gaining a high-flyer manager, sales bonus", size(medium)) 
 *title("Past exposure to high-flyer")  
graph export "$analysis/Results/0.Paper/3.1.Productivity/ProdMovers.pdf", replace 
graph save "$analysis/Results/0.Paper/3.1.Productivity/ProdMovers.gph", replace
*note("First row is the impact of gaining a high-flyer manager on sales bonus  conditional on making a lateral move." "Second row is the differential sales bonus before gaining a high-flyer manager conditional on not making a lateral move after the manager transition.")


********************************************************************************
* ADDITIONAL DATA SOURCES FOR SUGGESTIVE EVIDENCE
* Exit survey and learning data 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

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
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( $control Year Country WLM  )	
}
* outcome mean low flyer 
su LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 Whealthpc1 Wtalkpc1 Wjobpc1 Wawarepc1  Wusepc1   if Post==1 & EarlyAgeM==0 

/* PLOT 1: with all details 
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("Pulse Survey: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash)) xscale(range(-.04 .1)) xlabel(-.04(0.02)0.1)
graph export "$analysis/Results/4.Event/Survey/Univoice2FT.pdf", replace 
graph save "$analysis/Results/4.Event/Survey/Univoice2FT.gph", replace 
*/

**# ON PAPER FIGURE: Univoice2AFTE.png
coefplot LineManagerB Uteampc1  Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.04 .1)) xlabel(-.04(0.02)0.1)   
graph export "$analysis/Results/0.Paper/3.2.Survey/Univoice2AFT.pdf", replace 
graph save "$analysis/Results/0.Paper/3.2.Survey/Univoice2AFT.gph", replace

* plot using the mean 
********************************************************************************

eststo clear 
foreach var in LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean WhealthpcMean WtalkpcMean WjobpcMean WawarepcMean  WusepcMean{ 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( $control Year Country WLM  )	
}
* outcome mean low flyer
su LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean WhealthpcMean WtalkpcMean WjobpcMean WawarepcMean  WusepcMean   if Post==1 & EarlyAgeM ==0

**# ON PAPER FIGURE: Univoice2MeanAFTE.png
coefplot LineManagerB UteampcMean  UhappypcMean UfocuspcMean UcompanypcMean, ///
title("", pos(12) span si(large))  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.01 .04)) xlabel(-.01(0.01)0.04)   
graph export "$analysis/Results/0.Paper/3.2.Survey/Univoice2MeanAFT.pdf", replace 
graph save "$analysis/Results/0.Paper/3.2.Survey/Univoice2AMeanFT.gph", replace

/* PLOT 3: WELLBEING SURVEY 
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

**# ON PAPER FIGURE: Univoice2ATrFTE.png
coefplot LineManagerB Uteampc1 Uhappypc1 Ufocuspc1 Ucompanypc1, ///
title("", pos(12) span si(large))  keep(1.EarlyAgeM#1.maxTransfer)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-.2 .2)) xlabel(-.2(0.05)0.2)
graph export "$analysis/Results/0.Paper/3.2.Survey/Univoice2TrAFT.pdf", replace 
graph save "$analysis/Results/0.Paper/3.2.Survey/Univoice2ATrFT.gph", replace 

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
graph export  "$analysis/Results/5.Mechanisms/FTReasonAnotherOrg.pdf", replace
*/

**# ON PAPER FIGURE: FTReasonAnotherOrgAE.png
coefplot  ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1  ReasonAnotherOrg6 ReasonAnotherOrg3 , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/0.Paper/3.2.Survey/FTReasonAnotherOrgA.pdf", replace

/* reasons for leaving 
coefplot  ReasonLeaving5  ReasonLeaving4 ReasonLeaving1  ReasonLeaving6 ReasonLeaving7 ReasonLeaving2 ReasonLeaving3, ///
title("Reasons for leaving: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/5.Mechanisms/FTReasonLeaving.pdf", replace

coefplot   ReasonLeaving5  ReasonLeaving4 ReasonLeaving1 ReasonLeaving6 ReasonLeaving7  ReasonLeaving2 ReasonLeaving3, ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
*headings(ReasonLeaving1 = "{bf:Exit company: reason}"  ReasonAnotherOrg1 = "{bf:Change org: reason}" ) 
graph export  "$analysis/Results/5.Mechanisms/FTReasonLeavingA.pdf", replace
*/

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

/*
coefplot   NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD  , ///
title("Active learning: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
graph export  "$analysis/Results/5.Mechanisms/FTActiveLearn.pdf", replace

coefplot    NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
graph export  "$analysis/Results/5.Mechanisms/FTActiveLearnA.pdf", replace
*/

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


foreach var in  $FLEXProjectVar $FLEXPositionVar $FLEXOtherVar $FLEXHoursVar  { 
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 & WL2==1, cluster(IDlseMHR) a( Year ISOCode )	// WL2 takes away 2/3 of sample 
}

/*
coefplot   NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD  , ///
title("Flexible projects: impact of high flyer manager", pos(12) span si(large))  $coefopts xline(0, lpattern(dash))
graph export  "$analysis/Results/5.Mechanisms/Flex.pdf", replace
*/

**# ON PAPER FIGURE: FlexAE.png
coefplot    NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
graph export  "$analysis/Results/0.Paper/3.2.Survey/FlexA.png", replace


********************************************************************************
* EVENT STUDY 
* SOCIALLY CONNECTED MOVES
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
coefplot  (TransferSJC, keep(lc_1) rename(  lc_1  = "All lateral moves")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white)) ///
		(TransferSJSameMSameFuncC, keep(lc_1) rename( lc_1 = "Within team" ) ciopts(lwidth(2 ..) lcolor(orange ))  msymbol(d) mcolor(white)) ///
         (TransferSJDiffMSameFuncC, keep(lc_1) rename( lc_1 = "Different team, same function" ) ciopts(lwidth(2 ..) lcolor(cranberry ))  msymbol(d) mcolor(white)) ///
         (TransferFuncC, keep(lc_1) rename( lc_1 = "Different team, cross-functional" ) ciopts(lwidth(2 ..) lcolor(emerald))  msymbol(d) mcolor(white)) ///
, legend(off) title("Gaining a high-flyer manager", size(medsmall))  level(95) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 95% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span)   ///
aspectratio(.4) xscale(range(-0.01 0.15)) xlabel(-0.01(0.01)0.15)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/MovesDecompGain.pdf", replace // ysize(6) xsize(8)  
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/MovesDecompGain.gph", replace 

/*
coefplot  (TransferSJC, keep(lc_2) rename(  lc_2  = "All lateral moves")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  ///
(TransferSJSameMSameFuncC, keep(lc_2) rename( lc_2 = "Within team" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) ///
   (TransferSJDiffMSameFuncC, keep(lc_2) rename( lc_2 = "Different team, same function" ) ciopts(lwidth(2 ..) lcolor(cranberry ))  msymbol(d) mcolor(white)   ) ///
(TransferFuncC, keep(lc_2) rename( lc_2 = "Different team, cross-functional" ) ciopts(lwidth(2 ..) lcolor(emerald))  msymbol(d) mcolor(white)   ) ///
 ,legend(off) title("Losing a high-flyer manager", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. An observation is a worker-year-month. Reporting 95% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span) ///
 ysize(6) xsize(8)   aspectratio(.4)   xscale(range(-0.01 0.15)) xlabel(-0.01(0.01)0.15)
graph export "$analysis/Results/5.Mechanisms/MovesDecompLose.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/MovesDecompLose.gph", replace 
*/

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

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(95) post
est store  conn`var'

}
* NOTE: results robust to having a window at 60 

**# ON PAPER FIGURE: NetworkGainE.png
coefplot  (connConnected, keep(lc_1) rename(  lc_1  = "Move within manager's network")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
 (connConnectedL, keep(lc_1) rename( lc_1 = "Lateral move within manager's network" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) ///
 (connConnectedV, keep(lc_1) rename( lc_1 = "Vertical move within manager's network" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ), ///
 legend(off) title("Gaining a high-flyer manager", size(medsmall))  level(95) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 95% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span)   ///
xscale(range(-0.05 0.05)) xlabel(-0.05(0.01)0.05) ysc(outergap(50)) aspectratio(.5)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/NetworkGain.pdf", replace // ysize(6) xsize(8)  
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/NetworkGain.gph", replace 

/*
coefplot  (connConnected, keep(lc_2) rename(  lc_2  = "Move within manager's network")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  ///
(connConnectedL, keep(lc_2) rename( lc_2 = "Lateral move within manager's network" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) ///
(connConnectedV, keep(lc_2) rename( lc_2 = "Vertical move within manager's network" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ),  legend(off) title("Losing a high-flyer manager", size(medsmall))  level(95) xline(0, lpattern(dash))  note("Notes. An observation is a worker-year-month. Reporting 95% confidence intervals." "Looking at outcomes at 24 months after the manager transition." , span) ///
  xscale(range(-0.2 0.2)) xlabel(-0.2(0.1)0.2) ysize(6) xsize(8)  ysc(outergap(50))  aspectratio(.5)
graph export "$analysis/Results/5.Mechanisms/NetworkLose.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/NetworkLose.gph", replace 
*/

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
eststo reg2: reghdfe LogPayBonus  PostEarlyAgeM1  Female##c.Tenure##c.Tenure  if   WL==2 & (FTHL!=. | FTHH !=.)  & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs )

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
label var EarlyAgeM "Gaining a good manager"
label var EarlyAgeM1 "Losing a good manager"

* FINAL TABLE:  Performance, conditional on being promoted to manager
********************************************************************************

eststo reg3: reghdfe MScore  EarlyAgeM  Female##c.Tenure##c.Tenure   if   WL==2 & (FTLH!=. | FTLL !=.) & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs  )
eststo reg4: reghdfe MScore  EarlyAgeM1  Female##c.Tenure##c.Tenure  	  if   WL==2 & (FTHL!=. | FTHH !=.)  & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs )

esttab reg1 reg2 reg3 reg4, star(* 0.10 ** 0.05 *** 0.01) keep(   EarlyAgeM EarlyAgeM1 ) se label

* outcome mean
su MScore

/*
esttab reg1 reg2 reg3 reg4 using "$analysis/Results/5.Mechanisms/PeterPrinciple.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(*EarlyAgeM *EarlyAgeM1) se r2 ///
s(  N r2, labels( "N" "R-squared" ) ) rename(PostEarlyAgeM EarlyAgeM PostEarlyAgeM1 EarlyAgeM1) interaction("$\times$ ")    ///
nomtitles mgroups( "Pay (in logs) | Promoted to Manager" "Effective Leader scored by reportees", pattern(1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: country and year FE, worker tenure squared interacted with gender.  ///
\textit{Effective Leader} is the workers' anonymous rating of the manager via the survey question \textit{My line manager is an effective leader}. \textit{Effective Leader} is measured on a Likert scale 1 - 5 and the mean is 4.1. ///
"\end{tablenotes}") replace
*/

label var LogPayBonus "Pay (in logs) | Promoted to Manager"
label var  MScore "Effective Leader scored by reportees"

**# ON PAPER FIGURE: PeterPrincipleLHE.png
coefplot (reg1, rename(PostEarlyAgeM ="Pay (in logs) | Promoted to Manager" )) (reg3,rename(EarlyAgeM ="Effective Leader scored by reportees" )) ,  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
 aseq  aspect(0.4)  coeflabels(, ) ysize(6) xsize(8) xscale(range(0 .6)) xlabel(0(0.1)0.6) ///
title("Gaining a high flyer manager", pos(12) span si(medium)) ///
 xline(0, lpattern(dash)) keep(EarlyAgeM PostEarlyAgeM ) legend(off)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrincipleLH.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrincipleLH.gph", replace 

**# ON PAPER FIGURE: PeterPrincipleHLE.png
coefplot (reg2, rename(PostEarlyAgeM1 ="Pay (in logs) | Promoted to Manager" )) (reg4,rename(EarlyAgeM1 ="Effective Leader scored by reportees" )) ,  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
 aseq  aspect(0.4)  coeflabels(, ) ysize(6) xsize(8) xscale(range(-0.5 .5)) xlabel(-0.5(0.1)0.5) ///
title("Losing a high flyer manager", pos(12) span si(medium)) ///
 xline(0, lpattern(dash)) keep(EarlyAgeM1 PostEarlyAgeM1 ) legend(off)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrincipleHL.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/PeterPrincipleHL.gph", replace 

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
label var lAvPay "Av. Pay (logs)"

* Define variable globals 
label var ShareTransferSJ  "Lateral job change"
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

	local Label FT // FT PromSG75
egen `Label'HPre = rowmax( `Label'LHPre `Label'HHPre )
egen `Label'LPre = rowmax( `Label'LLPre `Label'HLPre )

global controls  FuncM CountryM Year // WLM AgeBandM 
global cont SpanM // c.TenureM##c.TenureM##i.FemaleM

eststo clear
local i = 1
local Label FT // FT PromSG75
label var  `Label'HPre  "High-flyer manager"

foreach y in  $perf $move $homo $div {
	
eststo reg`i':	reghdfe `y'  `Label'HPre `Label'LPre $cont if SpanM>1 & KEi<=-6 & KEi >=-36 & WLM==2,  cluster(IDlseMHR) a( $controls )
local lbl : variable label `y'
estadd local Controls "Yes" , replace
estadd local TeamFE "No" , replace
estadd ysumm 
local i = `i' +1

}

esttab  reg1 reg2 reg3  reg5 reg6  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

esttab  reg7  reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

esttab reg11 reg12 reg13 reg14  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) )  keep( *HPre  )

********************************************************************************
* This do files conducts team level analysis at the month level - ASYMMETRIC
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

********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE 
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
		 (creg3FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Share good perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg4FE,  keep(lc_1) transform(* = 100*(@))  rename(  lc_1  = "Share bottom perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg2FE,  keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Coeff. variation in perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 , aspectratio(.6) legend(off) title("Gaining a high-flyer manager", size(medsmall)) xtitle("Percentage points, monthly frequency") level(95) xline(0, lpattern(dash)) ///
		 note("Notes. An observation is a team-year-month. Reporting 95% confidence intervals." "Looking at outcomes within 24 months since the manager transition." , span) ///
		 ysize(6) xsize(8) xscale(range(-0.5 1.5) ) xlabel(-0.5(0.25)1.5, ) ylabel(,labsize(medsmall))
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/TeamCoeffLH.pdf", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/TeamCoeffLH.gph", replace 


********************************************************************************
* This dofile does heterogeneity analysis using at 60 months window 
********************************************************************************

global Label FT
use "$managersdta/AllSameTeam2.dta", clear 

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

*keep if Ei!=. 
gen KEi  = YearMonth - Ei 

*merge m:1 IDlse using  "$managersdta/Temp/Random25v.dta" // "$managersdta/Temp/Random10v.dta",
*drop _merge 
*rename random25 random
*keep if Ei!=. | random==1

* LABEL VARS
label var ChangeSalaryGradeC "Salary grade increase"
label var ChangeSalaryGradeSameMC "Salary grade increase, same manager"
label var ChangeSalaryGradeDiffMC "Salary grade increase, diff. manager"
label var PromWLC "Vertical move"
label var PromWLSameMC "Vertical move, same manager"
label var PromWLDiffMC "Vertical move, diff. manager"
label var PromWLVC "Vertical move"
label var TransferInternalC "Lateral move"
label var TransferInternalSameMC "Lateral move, same manager"
label var TransferInternalDiffMC "Lateral move, diff. manager"
label var TransferInternalLLC "Lateral move, lateral"
label var TransferInternalVC "Lateral move, vertical"
label var TransferSJC "Lateral move"
label var TransferSJSameMC "Lateral move, same manager"
label var TransferSJDiffMC "Lateral move, diff. manager"
label var TransferSJLLC "Lateral move, lateral"
label var TransferSJVC "Lateral move"
label var TransferFuncC "Lateral move, function"
label var TransferSubFuncC "Lateral move"
label var ONETDistanceBC "Task-distant move, ONET"
label var ONETDistanceC "Task-distant move, ONET"
label var ONETSkillsDistanceC "Task-distant move, ONET"
label var DiffField "Education-distant move, field"

label var LogPayBonus "Pay (logs)"

* tag manager and worker 
egen mm = tag(IDlseMHR)
egen iio = tag(IDlse)

*HET: BASELINE CHARS FOR HETEROGENEITY 
********************************************************************************

*HET: UFLP status flag for managers 
rename IDlse IDlse2
gen IDlse = IDlseMHR
merge m:1 IDlse YearMonth using "$managersdta/AllSnapshotMCultureMType.dta", keepusing(FlagUFLP )
drop if _merge ==2
ta _merge // 99% are matched 
drop _merge 
rename FlagUFLP FlagUFLPM
drop IDlse
rename IDlse2 IDlse 

* HET: ACROSS SUBFUNCTION AND FUNCTION 
bys IDlse: egen SubFuncPost = mean(cond(KEi ==36, SubFunc,.)) 
bys IDlse: egen SubFuncPre = mean(cond(KEi ==-1, SubFunc,.)) 
gen DiffSF = SubFuncPost!= SubFuncPre if SubFuncPost!=. & SubFuncPre!=. // 27% change SF

* HET: ACROSS HAVING DONE AT LEAST 1 LATERAL JOB TRANSFERS 
bys IDlse: egen TrPost1y = mean(cond(KEi ==12, TransferSJLLC,.)) 
bys IDlse: egen TrPost2y = mean(cond(KEi ==24, TransferSJLLC,.)) 
bys IDlse: egen TrPost3y = mean(cond(KEi ==36, TransferSJLLC,.)) 
bys IDlse: egen TrPre = mean(cond(KEi ==-1, TransferSJLLC,.)) 
gen DiffSJ1y = TrPost1y!= TrPre if TrPost1y!=. & TrPre!=. // 20% change JOB
gen DiffSJ2y = TrPost2y!= TrPre if TrPost2y!=. & TrPre!=. // 35% change JOB
gen DiffSJ3y = TrPost3y!= TrPre if TrPost3y!=. & TrPre!=. // 45% change JOB

* HET: ACROSS HAVING DONE AT LEAST 1 LATERAL JOB TRANSFERS 
bys IDlse: egen TrMPost1y = mean(cond(KEi ==12, TransferSJDiffMC,.)) 
bys IDlse: egen TrMPost2y = mean(cond(KEi ==24,  TransferSJDiffMC,.)) 
bys IDlse: egen TrMPost3y = mean(cond(KEi ==36,  TransferSJDiffMC,.)) 
bys IDlse: egen TrMPre = mean(cond(KEi ==-1,  TransferSJDiffMC,.)) 
gen DiffSJM1y = TrMPost1y!= TrMPre if TrMPost1y!=. & TrMPre!=. // 20% change JOB
gen DiffSJM2y = TrMPost2y!= TrMPre if TrMPost2y!=. & TrMPre!=. // 35% change JOB
gen DiffSJM3y = TrMPost3y!= TrMPre if TrMPost3y!=. & TrMPre!=. // 45% change JOB

* HET: remaining with same manager 
bys IDlse: egen MPost1y = mean(cond(KEi ==12, IDlseMHR,.)) 
bys IDlse: egen MPost2y = mean(cond(KEi ==24, IDlseMHR,.)) 
bys IDlse: egen MPost2hy = mean(cond(KEi ==30, IDlseMHR,.)) 
bys IDlse: egen MPost3y = mean(cond(KEi ==36, IDlseMHR,.)) 
bys IDlse: egen MPost5y = mean(cond(KEi ==60, IDlseMHR,.)) 
bys IDlse: egen MPre = mean(cond(KEi ==0, IDlseMHR,.)) 
gen DiffM1y = MPost1y!= MPre if MPost1y!=. & MPre!=. // 42%
gen DiffM2y = MPost2y!= MPre if MPost2y!=. & MPre!=. // 67%
gen DiffM3y = MPost3y!= MPre if MPost3y!=. & MPre!=. // 81%
gen DiffM5y = MPost5y!= MPre if MPost5y!=. & MPre!=. // 91%

* HET: indicator for 15-35 window of manager transition 
bys IDlse: egen m2y= max(cond(KEi ==-1 & MonthsSJM>=15 & MonthsSJM<=35,1,0))

* HET: average team performance before transition
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MType.dta", keepusing(AvPayGrowth  )
keep if _merge!=2
drop _merge 

bys IDlse: egen TeamPerf0 = mean(cond(KEi >=-24 & KEi<0,AvPayGrowth, .))
su TeamPerf0 if iio==1,d
gen TeamPerf0B = TeamPerf0 > `r(p50)' if TeamPerf0!=.

su TeamPerf0 if mm==1,d
gen TeamPerfM0B = TeamPerf0 > `r(p50)' if TeamPerf0!=.

* HET: worker performance 
xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus 
foreach var in PayGrowth { //  LogPayBonus VPA PayGrowth
	bys IDlse: egen `var'0 = mean(cond(KEi<=-1 & KEi >=-24, `var' , .))
	su `var'0 if iio==1,d
	gen WPerf0B = `var'0 > `r(p50)' if `var'0!=.
	gen WPerf0p10B = `var'0 <= `r(p10)' if `var'0!=.
	gen WPerf0p90B = `var'0 >= `r(p90)' if `var'0!=.
}

* p90 vs p10 worker baseline performance 
gen WPerf0p10p90B = 0 if WPerf0p10B==1
replace WPerf0p10p90B = 1 if WPerf0p90B ==1

* HET: heterogeneity by office size + tenure of manager + same gender + same nationality + same office + task distant func

* construct indicator for task distant function 
egen ff = tag(Func)
bys Func: egen avONET = mean( ONETDistance)
su avONET if ff==1 , d 
gen dFunc = avONET  >= r(p75) if avONET !=. // using the 75th percentile 
ta Func dFunc if ff==1 

* get baseline values 
foreach v in FlagUFLPM OfficeSize TenureM  SameGender SameNationality SameOffice SameCountry dFunc {
bys IDlse: egen `v'0= mean(cond( KEi ==0,`v',.))
}

* created binary indicators if needed 
su OfficeSize0 if iio==1, d 
gen OfficeSizeHigh0 = OfficeSize0> 300 if OfficeSize0!=.
bys EarlyAgeM: su TenureM0 if mm==1, d 
gen TenureMHigh0 = TenureM0>= 7 // median value for FT manager 

* HET: heterogeneity by age 
bys IDlse: egen Age0 = mean(cond(KEi==0,AgeBand,.))
gen Young0 = Age0==1 if Age0!=.

* HET: heterogeneity by tenure 
bys IDlse: egen Tenure0 = mean(cond(KEi==0,Tenure,.))
su Tenure0 if iio==1, d 
gen TenureLow0 = Tenure0 <=2 if Tenure0!=. 

* HET: labor law 
merge m:1 ISOCode Year using "$cleveldta/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF LaborRegWEFB) // /2.WB EmployingWorkers.dta ; 2.ILO EPLex.dta (EPLex )
keep if _merge!=2
drop _merge 

bys IDlse: egen LaborRegHigh0= mean(cond( KEi ==0,LaborRegWEFB,.))
 gen ISOCode0= ISOCode if KEi==0
 gen Country0= CountryS if KEi==0

preserve 
collapse LaborRegHigh0, by( ISOCode0 Country0) // LaborRegHigh0 LaborRegWEFC
export excel "$analysis/Results/5.Mechanisms/LaborLawCountry", replace 
restore 

* GENDER OF MANAGER
bys IDlse: egen FemaleM0= mean(cond( KEi ==0,FemaleM,.))

* gender norms
gen Cohort = AgeBand
merge m:1 ISOCode Cohort using "$cleveldta/3.WB FMShares Decade.dta", keepusing(FMShareWB FMShareEducWB)
drop if _merge==2
drop _merge  

egen cc= tag(ISOCode)
bys IDlse: egen FMShareWB0= mean(cond( KEi ==0,FMShareWB,.))
bys IDlse: egen FMShareEducWB0= mean(cond( KEi ==0,FMShareEducWB,.))

merge m:1 ISOCode Year using "$cleveldta/2.WB WBL.dta", keepusing(WBL Mobility Workplace Pay Marriage Parenthood  Entrepreneurship Assets Pension)
drop if _merge==2
drop _merge 
bys IDlse: egen WBL0= mean(cond( KEi ==0,WBL,.))

* Univoice 
merge m:1 IDlseMHR Year using "$managersdta/LMScore.dta", keepusing(LMScore)
drop _merge 
bys IDlse: egen LMScore0= mean(cond( KEi ==0,LMScore,.)) // taking the score of the LM 
gen HighLM0 = LMScore0 >4 if LMScore0!=.

********************************************************************************
* REGRESSIONS
********************************************************************************

* FM share categories 
su FMShareWB0, d 
local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)
gen FMShareWB0C = 1 if FMShareWB0<=`p25'
replace FMShareWB0C = 2 if FMShareWB0>`p25' & FMShareWB0<=`p50'
replace FMShareWB0C = 3 if FMShareWB0>`p50' & FMShareWB0<=`p75'
replace FMShareWB0C = 4 if FMShareWB0> `p75' & FMShareWB0!=.
tab FMShareWB0C, gen(FMShareWB0C)

su FMShareEducWB0, d
gen LowFLFP0 = 1 if FMShareEducWB0 <=0.89 // median 
replace LowFLFP0 = 0 if LowFLFP0 ==. & FMShareEducWB0 !=.

* job diversity - task distance 
bys Office YearMonth: egen JobDivOffice = mean(ONETSkillsDistanceC) 
bys IDlse: egen JobDivOffice0= mean(cond( KEi ==0,JobDivOffice,.))
su JobDivOffice0 if iio==1, d 
gen JobDiv0 = JobDivOffice0 > 0.05 if JobDivOffice0!=. 

egen oj = group(Office StandardJobE)
bys Office YearMonth: egen JobNumOffice = total(oj) 
bys IDlse: egen JobNumOffice0= mean(cond( KEi ==0,JobNumOffice,.))
su JobNumOffice0 if iio==1, d 
gen JobNum0 = JobNumOffice0 > `r(p50)' if JobNumOffice0!=. 

* constructing interaction variables
rename WPerf0B WPerf0
rename WPerf0p10p90B WPerf0p10p900
rename TeamPerf0B TeamPerfBase0
rename TeamPerfM0B TeamPerfMBase0
rename DiffM2y DiffM2y0
rename DiffSJ2y  DiffSJ2y0
rename DiffSJM3y  DiffSJM3y0

* gender of worker 
gen Female0 = Female 

foreach hh in DiffSJ2y Female FemaleM HighLM FlagUFLPM JobNum JobDiv LowFLFP DiffSJM3y  DiffM2y TeamPerfMBase   TeamPerfBase WPerf0p10p90 WPerf OfficeSizeHigh  LaborRegHigh  TenureMHigh TenureLow Young SameGender SameOffice{
foreach v in FTLHPost  FTHHPost   FTLLPost   FTHLPost{
gen `v'`hh'0= `v'*(1-`hh'0)
gen `v'`hh'1 = `v'*`hh'0
} 
} 

********************************************************************************
* Binary heterogeneity 
********************************************************************************

* (KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60)
* (KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==22 | KEi ==23 | KEi ==24)
* (KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==10 | KEi ==11 | KEi ==12) 

********************************************************************************
* LINE MANAGER SCORE (UNIVOICE)
********************************************************************************

* Note that the data is at the manager and year level and it is only available since 2017, so maximum time window avaiable is 4 years 
* so consider window up at 3 years after 

local hh HighLM // JobDiv JobNum
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1
*su $hetCoeff if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==46 | KEi ==47 | KEi ==48 )
*su $hetCoeff if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==34 | KEi ==35 | KEi ==36)
*su $hetCoeff if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==22 | KEi ==23 | KEi ==24)

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==34 | KEi ==35 | KEi ==36), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==34 | KEi ==35 | KEi ==36 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm


ta HighLM0 if iio==1 

/* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Worker assessment of manager (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 36 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between workers whose manager has an average score above or below 4." "The share of workers with a manager with an average score above 4 is 56%.", span)
graph export "$analysis/Results/5.Mechanisms/HFLMScore.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HFLMScore.gph", replace 
*/

********************************************************************************
* MANAGER DID THE GRADUATE PROGRAMME 
********************************************************************************

local hh FlagUFLPM // JobDiv JobNum
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta FlagUFLPM0 if iio==1 

/* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Manager did graduate program (yes - no)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between workers whose manager did or did not do the graduate program." "The share of workers with a manager that did the graduate program is 4%.", span)
graph export "$analysis/Results/5.Mechanisms/HFlagUFLPM.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HJFlagUFLPM.gph", replace 

*xscale(range(-0.05 0.15)) xlabel(-0.05(0.01)0.05)
*/

********************************************************************************
* JOB DIVERSITY AT THE OFFICE LEVEL  - number of jobs 
********************************************************************************

local hh JobNum // JobDiv JobNum
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta JobNum0 if iio==1 

**# ON PAPER FIGURE: HJobNumE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Job diversity in the office (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between offices with high and low number of different jobs (above and below median)." "The share of workers in offices with above median number of different jobs is 50%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HJobNum.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HJobNum.gph", replace 
  
*xscale(range(-0.05 0.15)) xlabel(-0.05(0.01)0.05)

********************************************************************************
* JOB DIVERSITY AT THE OFFICE LEVEL  - job diversity (ONET)
********************************************************************************

local hh JobDiv // JobDiv JobNum
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta JobDiv0 if iio==1 

/*
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Job diversity measured by tasks in the office (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between offices with high and low job diversity (above and below median)." "The share of workers in offices with above median job diversity is 44%." "Job diversity is measured as average task distance across jobs in each office using O*NET data.", span)
graph export "$analysis/Results/5.Mechanisms/HJobDiv.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HJobDiv.gph", replace 
*/

********************************************************************************
* careers of women in countries with low FLFP 
********************************************************************************

local hh LowFLFP
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if Female==1 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if Female==1 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm


ta LowFLFP0 if iio==1 & Female ==1

/* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Female over male labor force participation (low - high), women only", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between women in countries with the female over male labor force participation ratio" "below and above median." "The share of women in countries with the female over male labor force participation ratio below median is 38%.", span)
graph export "$analysis/Results/5.Mechanisms/HFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HFLFP.gph", replace 

*xscale(range(-0.05 0.15)) xlabel(-0.05(0.01)0.05)
*/
 
********************************************************************************
* careers of men in countries with low FLFP 
********************************************************************************

local hh  LowFLFP
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC  { // $Keyoutcome $other  TransferFuncC
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if Female==0 &   (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if  Female==0 &  (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta LowFLFP0 if iio==1 & Female ==0

* Female==1 & SameGender==1 >> positive (worse for equal countries)
* Female==0 & SameGender==1  >> negative (better for equal countries )
/*
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Female over male labor force participation (low - high), men only", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between men in countries with the female over male labor force participation ratio" "below and above median." "The share of men in countries with the female over male labor force participation ratio below median is 46%.", span)
graph export "$analysis/Results/5.Mechanisms/HFLFPMen.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HFLFPMen.gph", replace 
*/

********************************************************************************
* gender gap and low FLFP
********************************************************************************

local hh   LowFLFP
global hetCoeff FTLHPost`hh'0##Female FTHLPost`hh'0##Female  FTLLPost`hh'0##Female  FTHHPost`hh'0##Female   ///
FTLHPost`hh'1##Female  FTHLPost`hh'1##Female  FTLLPost`hh'1##Female  FTHHPost`hh'1##Female 

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC  { // $Keyoutcome $other  TransferFuncC
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (1.FTLHPost`hh'1#1.Female - 1.FTLLPost`hh'1#1.Female - 1.FTLHPost`hh'0#1.Female + 1.FTLLPost`hh'0#1.Female) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (1.FTLHPost`hh'1#1.Female - 1.FTLLPost`hh'1#1.Female - 1.FTLHPost`hh'0#1.Female + 1.FTLLPost`hh'0#1.Female) , level(95) post
est store  LeaverPerm

ta LowFLFP0 if iio==1 

**# ON PAPER FIGURE: HFLFPFemaleGapE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Female over male labor force participation (low - high), gender gap", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between the gender gap (women - men) in countries with the" "female over male labor force participation ratio below and above median." "The share of workers in countries with the female over male labor force participation ratio below median is 48%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HFLFPFemaleGap.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HFLFPFemaleGap.gph", replace 

********************************************************************************
* same gender as manager 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC   { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==10 | KEi ==11 | KEi ==12), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

eststo PromWLC: reghdfe PromWLC $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==4 | KEi ==5 | KEi ==6), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  PromWLC

ta SameGender0 if iio==1 

**# ON PAPER FIGURE: HGenderE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender", size(medsmall))  level(95) xline(0, lpattern(dash)) xscale(range(-0.05 0.05)) xlabel(-0.05(0.01)0.05) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager." "The share of workers sharing same gender with manager is 62%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HGender.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HGender.gph", replace 

********************************************************************************
* WOMAN in low FLFP country: does it matter to have manager of same gender? 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in  ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if LowFLFP0==1 & Female==1 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if LowFLFP0==1 & Female==1 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameGender0 if iio==1 & LowFLFP0==1 & Female==1

/* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender (women, low FLFP countries)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager for women in low FLFP." "The share of women in low FLFP countries sharing same gender with manager is 45%.", span)
graph export "$analysis/Results/5.Mechanisms/HGenderFemaleLowFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HGenderFemaleLowFLFP.gph", replace 
*/

********************************************************************************
* WOMAN in high FLFP country: does it matter to have manager of same gender? 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in  ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if LowFLFP0==0 & Female==1 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if LowFLFP0==0 & Female==1 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameGender0 if iio==1 & LowFLFP0==0 & Female==1

/* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender (women, high FLFP countries)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager for women in high FLFP." "The share of women in high FLFP countries sharing same gender with manager is 47%.", span)
graph export "$analysis/Results/5.Mechanisms/HGenderFemaleHighFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HGenderFemaleHighFLFP.gph", replace 
*/

********************************************************************************
* MEN in low FLFP country: does it matter to have manager of same gender? 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in  ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if LowFLFP0==1 & Female==0 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if LowFLFP0==1 & Female==0 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameGender0 if iio==1 & LowFLFP0==1 & Female==0

/* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender (men, low FLFP countries)", size(medsmall))  level(95) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager for men in low FLFP." "The share of men in low FLFP countries sharing same gender with manager is 76%.", span)
graph export "$analysis/Results/5.Mechanisms/HGenderMaleLowFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HGenderMaleLowFLFP.gph", replace 
*xscale(range(-0.05 0.05)) xlabel(-0.05(0.01)0.05)
*/

********************************************************************************
* MEN in high FLFP country: does it matter to have manager of same gender? 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in  ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if LowFLFP0==0 & Female==0 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if LowFLFP0==0 & Female==0 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameGender0 if iio==1 & LowFLFP0==0 & Female==0

/* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender (men, high FLFP countries)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager for men in high FLFP." "The share of men in high FLFP countries sharing same gender with manager is 72%.", span)
graph export "$analysis/Results/5.Mechanisms/HGenderMaleHighFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HGenderMaleHighFLFP.gph", replace 
*/

********************************************************************************
* same office 
********************************************************************************

local hh SameOffice
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameOffice0 if iio==1

**# ON PAPER FIGURE: HOfficeE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC, keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm , keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same office - different office", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the office with the manager." "The share of workers in the same office of manager is 71%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HOffice.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HOffice.gph", replace 

********************************************************************************
* Young worker  
********************************************************************************

local hh Young
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta Young0 if iio==1 

**# ON PAPER FIGURE: HYoungE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)  ///
 title("Worker age (below 30 - above 30)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between being under and over 30 years old." "The share of workers under 30 years old is 42%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HYoung.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HYoung.gph", replace 

********************************************************************************
* Worker below 2 years of tenure   
********************************************************************************

local hh TenureLow
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta TenureLow0 if iio==1 

**# ON PAPER FIGURE: HTenureE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.1 0.2)) xlabel(-0.1(0.05)0.2) ///
 title("Worker tenure (low - high)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between being under and over 2 years of tenure." "The share of workers under 2 years of tenure is 66%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HTenure.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HTenure.gph", replace 

********************************************************************************
* Manager above 7 years of tenure   
********************************************************************************

local hh TenureMHigh
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

local hh TenureMHigh
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Office##YearMonth##Func  AgeBand##Female  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta TenureMHigh0 if mm==1 

**# ON PAPER FIGURE: HTenureME.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.1 0.4)) xlabel(-0.1(0.1)0.4) ///
 title("Manager tenure (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between having the manager with over and under 7 years of tenure." "The share of managers above 7 years of tenure is 77%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HTenureM.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HTenureM.gph", replace 

********************************************************************************
*office size   
********************************************************************************

local hh  OfficeSizeHigh
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta OfficeSizeHigh0 if iio==1

**# ON PAPER FIGURE: HLargeOfficeE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.1 0.4)) xlabel(-0.1(0.1)0.4) ///
 title("Office size, number of workers (large - small)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between large and small offices (above and below median number of workers)." "The share of workers in offices with more than 300 workers (above median) is 55%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HLargeOffice.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HLargeOffice.gph", replace 

********************************************************************************
* Labor regulations     
********************************************************************************
 
local hh  LaborRegHigh
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta LaborRegHigh0 if iio==1
 
**# ON PAPER FIGURE: HLawE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.1 0.4)) xlabel(-0.1(0.1)0.4) ///
 title("Stringency of country labor laws (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between countries having stricter and laxer labor laws (above and below median)." "The share of workers in countries with more stringent labor laws is 43%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HLaw.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HLaw.gph", replace 

********************************************************************************
* Changed Job      
********************************************************************************

local hh DiffSJ2y
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta DiffSJ2y0 if iio==1
 
**# ON PAPER FIGURE: HDiffSJE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.2 0.2)) xlabel(-0.2(0.1)0.2) ///
 title("Job change within 2 years (yes - no)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between workers changing and not changing job within 2 years of the manager transition." "The share of workers that change job within 2 years of the manager transition is 41%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HDiffSJ.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HDiffSJ.gph", replace 

********************************************************************************
* Changed Manager     
********************************************************************************

local hh DiffM2y
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1
su $hetCoeff
eststo clear 
foreach  y in   ChangeSalaryGradeC  TransferSJLLC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

* ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60)
eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta DiffM2y0 if iio==1
 
**# ON PAPER FIGURE: HDiffME.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
(TransferSJLLC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) scale(0.96) legend(off) xscale(range(-0.25 0.25)) xlabel(-0.25(0.1)0.25) ///
 title("Manager change within 2 years (yes - no)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between workers changing and not changing the manager within 2 years of the transition." "The share of workers that change manager within 2 years is 71%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HDiffM.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HDiffM.gph", replace

********************************************************************************
* team performance   
********************************************************************************

local hh TeamPerfMBase
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta TeamPerfMBase0 if iio==1

**# ON PAPER FIGURE: HTeamE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.4 0.4)) xlabel(-0.4(0.1)0.4) ///
 title("Team past pay growth (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
"Showing the differential impact between better and worse performing teams at baseline." "The share of workers in teams with above median pay growth in the 2 years preceding the manager change is 48%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HTeam.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HTeam.gph", replace

********************************************************************************
* worker performance   
********************************************************************************

local hh WPerf
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta WPerf0 if iio==1

**# ON FIGURE FIGURE: HWPerfE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-1 0.5)) xlabel(-1(0.25)0.5) ///
 title("Worker past pay growth (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
"Showing the differential impact between better and worse performing workers at baseline." "The share of workers with above median pay growth in the 2 years preceding the manager change is 41%.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HWPerf.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HWPerf.gph", replace


********************************************************************************
* worker performance   
********************************************************************************

local hh  WPerf0p10p90
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta  WPerf0p10B  if iio==1
ta  WPerf0p90B  if iio==1

**# ON PAPER FIGURE: HWPerfpE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)  xscale(range(-1 0.5)) xlabel(-1(0.25)0.5) ///
 title("Worker past pay growth (p90- p10)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
"Showing the differential impact between the top 10% and the bottom 10% workers in terms performance at baseline." "Top 10% versus the bottom 10% of workers in terms of average pay growth in the 2 years before the manager transition.", span)
graph export "$analysis/Results/0.Paper/3.4.Het/HWPerfp.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HWPerfp.gph", replace
*xscale(range(-0.5 0.4)) xlabel(-0.5(0.1)0.4)
