* Validation 


********************************************************************************
* Validation: Regressions - surveys
********************************************************************************

use "$Managersdta/Temp/JobMatchM.dta", clear 
merge 1:m IDlseMHR YearMonth using "$Managersdta/Managers.dta" 
drop _merge 
replace JobMatchPayM = . if YearMonth < = tm(2015m12)

bys IDlse Spell : egen zSG = max(cond(YearMonth == SpellStart, JobMatchSGM,.))
bys IDlse Spell : egen zPay = max(cond(YearMonth == SpellStart, JobMatchPayM,.))

replace JobMatchSGM = zSG
replace JobMatchPayM = zPay

egen JobMatchSGMZ= std(JobMatchSGM)
egen JobMatchPayMZ= std(JobMatchPayM)

egen z = cut(CumReporteesM), group(6)
replace CumReporteesM = z
drop z

*collapse JobMatchSGM JobMatchPayM CumReporteesM, by(IDlse YearMonth)

global survey AccessLearning CommSustainability Competition ContributeUSLP CulturalDiversity DevOpportunity EffectiveBarriers EmpowerDecisions ExtraMile FeedbackAction FocusPerf GoodTechnologies HeartCustomers Integrity LeadershipExperiment LeadershipInclusion LeadershipStrategy Learning Leaving LineManager LivePurpose PrioritiseControl Proud RecommendProducts Refer ReportUnethical Satisfied StrategyWin TeamAgility TeamCollaboration TrustLeadership USLP Wellbeing WorkLifeBalance


merge 1:1  IDlse YearMonth using "$Managersdta/UniVoiceSnapshotM" , keepusing( $survey )


replace WL = 4 if WL>=4
replace WLM = 4 if WLM>=4

*egen CountryYear = group(Country Year)
*egen TenureBand = cut(Tenure), group(10)
*egen TenureBandM = cut(TenureM), group(10) 
*global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
*global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
*global controlMacro i.CountryYear

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

egen JobMatchPayMZ = std(JobMatchPayM)
label var JobMatchPayMZ "M Match."
egen JobMatchPayDMZ = std(JobMatchPayDM)

label var JobMatchPayDMZ "M Match."




eststo clear
eststo: reghdfe LMZZ  JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if YearMonth==tm(2019m9) | YearMonth==tm(2018m9) | YearMonth==tm(2017m9)   ,  a(  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.TeamSizeC )  vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe alignZZ  JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if YearMonth==tm(2019m9) | YearMonth==tm(2018m9) | YearMonth==tm(2017m9) ,  a(   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.TeamSizeC )  vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe teamZZ  JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if YearMonth==tm(2019m9) | YearMonth==tm(2018m9) | YearMonth==tm(2017m9) ,  a(  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.TeamSizeC )  vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe jobsatZZ  JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if YearMonth==tm(2019m9) | YearMonth==tm(2018m9) | YearMonth==tm(2017m9) ,  a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.TeamSizeC )  vce(cluster IDlseMHR)
estadd ysumm

esttab using "$Results/4.4.Validation/JobMatchPayMZSurveys.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01) keep(JobMatchPayDMZ)  replace

eststo: reghdfe LivePurposeZ  JobMatchPayMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if YearMonth==tm(2019m9) | YearMonth==tm(2018m9) | YearMonth==tm(2017m9) ,  a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  )  vce(cluster IDlseMHR)
estadd ysumm


********************************************************************************
* Regressions - REWARDS
********************************************************************************

use "$Managersdta/Temp/JobMatchM.dta", clear 
rename IDlseMHR IDlse // manager as an employee
merge 1:1 IDlse YearMonth using "$Managersdta/Managers.dta" 
keep if _merge ==3

replace WL = 4 if WL>=4
replace JobMatchPayM = . if YearMonth < = tm(2015m12)
replace JobMatchPayDM = . if YearMonth < = tm(2015m12)

egen JobMatchSGMZ= std(JobMatchSGM)
egen JobMatchPayMZ= std(JobMatchPayM)
egen JobMatchSGDMZ= std(JobMatchSGDM)
egen JobMatchPayDMZ= std(JobMatchPayDM)
egen z = cut(CumReporteesM), group(6)
replace CumReporteesM = z
drop z

bys IDlseMHR YearMonth: egen TeamSize = count(IDlse)
egen TeamSizeC = cut(TeamSize) , group(10) // need to control for this 


label var LeaverInv "Inv Exit"
label var LeaverVol "Vol Exit"
label var LeaverPerm "Exit"
label var PromSalaryGrade "Promotion"
label var PromSalaryGradeC "Promotion"
label var LogPayBonus "Pay (logs)"
label var LogBonus "Bonus (logs)"
label var  JobMatchPayMZ "M Match"
label var PayBonus "Tot. Compensation"

* Main table
eststo clear
eststo: reghdfe LogPayBonus JobMatchPayDMZ c.Tenure##c.Tenure##i.Female,  a(  i.WL i.TeamSize i.AgeBand  )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe LogBonus JobMatchPayDMZ c.Tenure##c.Tenure##i.Female,  a( i.WL i.TeamSize i.AgeBand )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe VPA JobMatchPayDMZ c.Tenure##c.Tenure##i.Female,  a(  i.WL i.TeamSize i.AgeBand  )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe PromSalaryGrade JobMatchPayDMZ   c.Tenure##c.Tenure##i.Female,  a(  i.WL i.TeamSize  i.AgeBand   )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe LeaverPerm JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female,  a(   i.WL i.TeamSize  i.AgeBand  )  vce(cluster IDlse)
estadd ysumm


esttab using "$Results/4.4.Validation/JobMatchPayDMZ.tex", keep(JobMatchPayDMZ) stats(  ymean r2  N, fmt( %9.3f %9.3f %9.0g)  labels(   "Mean" "R-squared" "Number of obs."))  label   se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* with FE
eststo clear
eststo: reghdfe LogPayBonus JobMatchPayDMZ ,  a( i.IDlse i.WL i.TeamSize i.AgeBand )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe LogBonus JobMatchPayDMZ ,  a( i.IDlse i.WL i.TeamSize i.AgeBand  )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe VPA JobMatchPayDMZ ,  a( i.IDlse i.WL i.TeamSize i.AgeBand  )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe PromSalaryGrade JobMatchPayDMZ   ,  a(  i.IDlse i.WL i.TeamSize  i.AgeBand  )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe LeaverPerm JobMatchPayDMZ  ,  a(   i.WL i.TeamSize  i.AgeBand )  vce(cluster IDlse)
estadd ysumm


esttab using "$Results/4.4.Validation/JobMatchPayDMZFE.tex", keep(JobMatchPayDMZ) stats(  ymean r2  N, fmt( %9.3f %9.3f %9.0g)  labels(   "Mean" "R-squared" "Number of obs."))  label   se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


