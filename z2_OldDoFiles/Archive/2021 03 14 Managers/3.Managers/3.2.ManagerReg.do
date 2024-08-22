* This do file looks at manager effect on FULL sample

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* Prepare Line Manager data 
********************************************************************************

use "$dta/UniVoiceSnapshotM", clear 
collapse LineManager, by(IDlseMHR YearMonth)
egen LineManagerZ = std(LineManager)
save "$Managersdta/Temp/LineManagerMonth.dta", replace

collapse LineManager, by(IDlseMHR)
hist LineManager, fraction color(navy) normal xtitle(Line Manager Scores)

********************************************************************************
* Merge data 
********************************************************************************

use "$Managersdta/Managers.dta", clear 

merge m:1 IDlseMHR using "$Managersdta/MFE.dta"
drop if _merge ==2
drop _merge 

merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/LineManagerMonth.dta"
drop if _merge ==2
drop _merge 

********************************************************************************
*
********************************************************************************

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlEFE i.WL  i.IDlse
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYear


* Job change during spell 
reghdfe  TransferPTitleDuringSpellC MFEPayWCZ  if BC ==0, a(   $controlM   $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleDuringSpellC MFEPayBCZ  if BC ==1, a(  $controlM  $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

* Het by non performing 
reghdfe  TransferPTitleDuringSpellC c.MFEPayWCZ##c.LogPayBonusPreS1y if BC==0, a(  $controlM  $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleDuringSpellC c.MFEPayBCZ##c.LogPayBonusPreS1y if BC==1, a(  $controlM   $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

* Job change after  spell
gen TransferPTitleCPostS1yD = TransferPTitleCPostS1y - TransferPTitleCStartS

gen TransferPTitleCPostS1yD = TransferPTitleCPostS1y - TransferPTitleCStartS


reghdfe  TransferPTitleCPostS1yD MFEPayWCZ  if BC ==0, a( $controlM   $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleCPostS1yD MFEPayBCZ  if BC ==1, a(   $controlM   $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

* Het by non performing 
reghdfe  TransferPTitleCPostS1yD c.MFEPayWCZ##c.LogPayBonusPreS1y if BC==0 , a(   $controlM   $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleCPostS1yD c.MFEPayBCZ##c.LogPayBonusPreS1y if BC==1 , a(   $controlM   $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

* Exit 
reghdfe  LeaverPerm MFEPayWCZ  if BC ==0 , a(  $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  LeaverPerm MFEPayBCZ  if BC ==1 , a(  $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)


* DYNAMICS 
gen PromSalaryGradeCPostS1yD = PromSalaryGradeCPostS1y - PromSalaryGradeCStartS


reghdfe  PromSalaryGradeC MFEPayZ L12.MFEPayWCZ if BC ==0  , a(  $controlM   $controlEFE $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  PromSalaryGradeCPostS1yD MFEPayZ L12.MFEPayWCZ if BC ==0  , a(  $controlM   $controlEFE $controlMacro  ) vce(cluster IDlseMHR)


********************************************************************************
* Validation: Regressions - surveys
********************************************************************************

use "$Managersdta/Temp/MSGLMeanRZ.dta", clear 

merge 1:m  IDlseMHR using "$Managersdta/UniVoiceSnapshotM"

replace WL = 4 if WL>=4
replace WLM = 4 if WLM>=4

egen CountryYear = group(Country Year)
egen TenureBand = cut(Tenure), group(10)
egen TenureBandM = cut(TenureM), group(10) 
global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYear


global survey AccessLearning CommSustainability Competition ContributeUSLP CulturalDiversity DevOpportunity EffectiveBarriers EmpowerDecisions ExtraMile FeedbackAction FocusPerf GoodTechnologies HeartCustomers Integrity LeadershipExperiment LeadershipInclusion LeadershipStrategy Learning Leaving LineManager LivePurpose PrioritiseControl Proud RecommendProducts Refer ReportUnethical Satisfied StrategyWin TeamAgility TeamCollaboration TrustLeadership USLP Wellbeing WorkLifeBalance

foreach var in $survey {
	egen `var'Z = std(`var')
}

egen alignZZ = rowmean(TrustLeadershipZ ProudZ HeartCustomersZ LeadershipStrategyZ StrategyWinZ)
egen align = rowmean(TrustLeadership Proud HeartCustomers LeadershipStrategy StrategyWin)
egen alignZ = std(align)
egen alignB = cut(align), group(2)
label var alignB "Alignment"
label var alignZ "Alignment"
label var alignZZ "Alignment"

*CulturalDiversity TeamCollaboration TeamAgility FocusPerf
egen teamZZ = rowmean( CulturalDiversityZ TeamAgilityZ TeamCollaborationZ  )
egen team = rowmean( CulturalDiversity TeamAgility TeamCollaboration )
egen teamZ = std(team)
egen teamB = cut(team), group(2)
label var teamB "Team Dynamics"
label var teamZ "Team Dynamics"
label var teamZZ "Team Dynamics"

egen LMZZ = rowmean( LineManagerZ PrioritiseControlZ LeadershipExperimentZ EmpowerDecisionsZ )
egen LM = rowmean( LineManager PrioritiseControl LeadershipExperiment EmpowerDecisions )
egen LMZ = std(LM)
label var LMZ "Manager"
label var LMZZ "Manager"

egen jobsatZZ = rowmean( ProudZ ExtraMileZ WellbeingZ LivePurposeZ SatisfiedZ  DevOpportunityZ LeavingZ ReferZ )
egen jobsat = rowmean( Proud ExtraMile Wellbeing LivePurpose Satisfied  DevOpportunity Leaving Refer )
egen jobsatZ = std(jobsat)
egen jobsatB = cut(jobsat), group(2)
label var jobsatB "Job Satisfaction"
label var jobsatZ "Job Satisfaction"
label var jobsatZZ "Job Satisfaction"

*WorkLifeBalance AccessLearning

label var MSGLMeanRZ "M Prom."


eststo clear
eststo: reghdfe LMZZ  MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM ,  a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear )  vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe alignZZ  MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM ,  a(   i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear )  vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe teamZZ  MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM ,  a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear )  vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe jobsatZZ  MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM ,  a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear)  vce(cluster IDlseMHR)
estadd ysumm


esttab using "$Results/3.2.ManagerReg/MSGLMeanRZSurveys.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01) keep(MSGLMeanRZ)  replace


********************************************************************************
* Regressions - REWARDS
********************************************************************************

use "$Managersdta/Temp/MSGLMeanRZ.dta", clear 
rename IDlseMHR IDlse // manager as an employee
merge 1:m IDlse using "$Managersdta/Managers.dta" 
keep if _merge ==3

replace WL = 4 if WL>=4

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYear

label var LeaverInv "Inv Exit"
label var LeaverVol "Vol Exit"
label var LeaverPerm "Exit"
label var PromSalaryGrade "Promotion"
label var PromSalaryGradeC "Promotion"
label var LogPayBonus "Pay (logs)"
label var  MSGLMeanRZ "M Prom."
label var PayBonus "Tot. Compensation"

* Main table
eststo clear

eststo: reghdfe LogPayBonus MSGLMeanRZ c.Tenure##c.Tenure##i.Female,  a( i.WL  i.AgeBand i.CountryYear )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe VPA MSGLMeanRZ c.Tenure##c.Tenure##i.Female,  a( i.WL  i.AgeBand i.CountryYear )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe PromSalaryGradeC MSGLMeanRZ   c.Tenure##c.Tenure##i.Female,  a(   i.WL  i.AgeBand i.CountryYear  )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe LeaverPerm MSGLMeanRZ  c.Tenure##c.Tenure##i.Female,  a(   i.WL  i.AgeBand i.CountryYear )  vce(cluster IDlse)
estadd ysumm


esttab using "$Results/3.2.ManagerReg/MSGLMeanRZReward.tex", keep(MSGLMeanRZ) stats( ymean r2  N, fmt(%9.3f %9.3f %9.0g)  labels(  "Mean" "R-squared" "Number of obs."))  label   se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace



