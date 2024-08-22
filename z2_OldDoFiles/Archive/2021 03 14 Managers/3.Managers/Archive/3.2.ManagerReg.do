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

use "$dta/UniVoiceSnapshotWCCulture", clear 
collapse LineManager, by(IDlseMHR YearMonth)
save "$Managersdta/Temp/LineManagerMonth.dta", replace

collapse LineManager, by(IDlseMHR)
hist LineManager, fraction color(navy) normal xtitle(Line Manager Scores)


********************************************************************************
* FULL SAMPLE vs UFLP  
********************************************************************************

use "$dta/AllSnapshotWCCultureC.dta", clear
merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/LineManagerMonth.dta", keepusing(LineManager)
drop if _merge ==2
drop _merge 
drop if FlagUFLP == 1 // not UFLP employees 
*keep if  EmpStatus == 7 & (EmpType==9 | EmpType== 12 | EmpType== 13 ) // regular employees 

egen z = std(LineManager)
replace LineManager = z

* merge FE
merge m:1 IDlseMHR using "$Graduates/Results/4.ManagerFE/AllFEM.dta"
drop if _merge ==2
drop _merge 

* Macro-trends 
*egen CountryYear = group(Country Year)
egen OfficeYear = group(Office Year)

by IDlse (YearMonth), sort: gen changeM= (IDlseMHR != IDlseMHR[_n-1] & _n>1 )
by IDlse (YearMonth), sort: gen IDtime = sum(changeM)

* Collapse data at the manager-spell level 
 collapse PromSalaryGrade PRSnapshot LogPayBonus  LeaverPerm LeaverInv LeaverVol  LogBonus  LogPay Tenure MFEPay MFEProm   (max) Func OfficeYear AgeBand AgeBandM Female WL WLM, by(IDlse IDlseMHR IDtime)

tsset IDlse IDtime

global controls OfficeYear Func WL AgeBand Tenure Female

egen MFEPromZ = std(MFEProm)

label var WLM "Manager WL"
label var LeaverInv "Inv Exit"
label var LeaverVol "Vol Exit"
label var LeaverPerm "Exit"
label var PromSalaryGrade "Promotion"
label var MFEPromZ "Manager VA (std)"
label var LogPayBonus "Log(Pay)"

*keep if LineManager!=.

keep if WL < 4
gen WLMDiff = WLM -WL 
replace WLMDiff = 0  if WLMDiff <0
gen WLDiffInd = 1 if WLMDiff>=1
replace WLDiffInd = 0 if WLMDiff==0
 
* Main table - differences in WL with manager and manager FE
********************************************************************************

eststo clear
eststo: reghdfe LeaverPerm  WLDiffInd ,  a( $controls  )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe LeaverInv  WLDiffInd ,  a( $controls  )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe LeaverVol  WLDiffInd ,  a( $controls  )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe LeaverPerm  MFEPromZ ,  a( $controls  )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe LeaverInv  MFEPromZ ,  a( $controls  )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe LeaverVol  MFEPromZ ,  a( $controls  )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe F.LogPayBonus  WLDiffInd,  a(  $controls  )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe F.LogPayBonus  MFEPromZ,  a(  $controls  )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
esttab, se r2 compress   star(* 0.10 ** 0.05 *** 0.01) nocons
esttab using "$Full/Results/3.2.ManagerReg/FULLMain.tex",  stats(r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) label  drop(_cons ) se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

********************************************************************************
* Regressions - surveys
********************************************************************************

use "$Full/Results/3.1.ManagerFE/AllFEM.dta", clear 
*rename IDlseMHR IDlse

merge 1:m IDlseMHR using "$dta/UniVoiceSnapshotWCCulture"

global survey AccessLearning CommSustainability Competition ContributeUSLP CulturalDiversity DevOpportunity EffectiveBarriers EmpowerDecisions ExtraMile FeedbackAction FocusPerf GoodTechnologies HeartCustomers Integrity LeadershipExperiment LeadershipInclusion LeadershipStrategy Learning Leaving LineManager LivePurpose PrioritiseControl Proud RecommendProducts Refer ReportUnethical Satisfied StrategyWin TeamAgility TeamCollaboration TrustLeadership USLP Wellbeing WorkLifeBalance

global FE  MFELeaver MFEPay MFEProm MFEVPA MFEPR



foreach var in  $FE {
	egen `var'B = cut(`var'), group(2)
}

foreach var in $survey{
	gen `var'B= 1 if `var' >=4
	replace `var'B= 0 if `var' <=3
	
}

* Macro-trends 
egen CountryYear = group(Country Year)
egen OfficeYear = group(Office Year)

egen align = rowmean(TrustLeadership Proud HeartCustomers LeadershipStrategy StrategyWin)
egen alignZ = std(align)
egen alignB = cut(align), group(2)
label var alignB "Alignment"
label var alignZ "Alignment"

*CulturalDiversity TeamCollaboration TeamAgility FocusPerf
egen team = rowmean( LineManager LeadershipExperiment EmpowerDecisions )
egen teamZ = std(team)
egen teamB = cut(team), group(2)
label var teamB "Team Dynamics"
label var teamZ "Team Dynamics"

egen jobsat = rowmean( ExtraMile Wellbeing LivePurpose Satisfied  DevOpportunity Leaving Refer )
egen jobsatZ = std(jobsat)
egen jobsatB = cut(jobsat), group(2)
label var jobsatB "Job Satisfaction"
label var jobsatZ "Job Satisfaction"

*WorkLifeBalance AccessLearning

label var MFELeaverB "Manager VA Exit"
label var MFEPromB "Manager VA Promotion"
label var MFELeaverZ "Manager VA Exit"
label var MFEPromZ "Manager VA Promotion"
label var MFEPayZ "Manager VA Pay"

global controls OfficeYear Func AgeBand EmpStatus EmpType

* Main table -all
eststo clear

eststo: reghdfe alignZ  MFEPromZ c.Tenure##c.Tenure##Female ,  a( $controls )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe alignZ  MFEPromZ c.Tenure##c.Tenure##Female ,  a( $controls IDlse)  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
eststo: reghdfe teamZ  MFEPromZ c.Tenure##c.Tenure##Female ,  a( $controls )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe teamZ  MFEPromZ c.Tenure##c.Tenure##Female ,  a( $controls IDlse)  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace
eststo: reghdfe jobsatZ  MFEPromZ c.Tenure##c.Tenure##Female ,  a( $controls )  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "No" , replace
eststo: reghdfe jobsatZ  MFEPromZ c.Tenure##c.Tenure##Female ,  a( $controls IDlse)  vce(cluster IDlseMHR)
estadd ysumm
estadd local EmployeeFE "Yes" , replace

esttab using "$Full/Results/3.1.ManagerFE/ManagerFESurveys.tex",  stats(EmployeeFE r2 N, fmt(%9.3f %9.3f %9.0g)  labels("Employee FE" "R-squared" "Number of obs.")) keep(  MFEPromZ) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


********************************************************************************
* Regressions - REWARDS
********************************************************************************

use "$Full/Results/3.1.ManagerFE/AllFEM.dta", clear 
rename IDlseMHR IDlse // manager as an employee
merge 1:m IDlse using "$dta/AllSnapshotWCCultureC.dta" 

global FE MFELeaver MFEPay MFEProm MFEVPA MFEPR


* Macro-trends 
egen CountryYear = group(Country Year)
egen OfficeYear = group(Office Year)

label var LeaverInv "Inv Exit"
label var LeaverVol "Vol Exit"
label var LeaverPerm "Exit"
label var PromSalaryGrade "Promotion"
label var LogPayBonus "Pay (logs)"
label var  MFELeaverZ "Manager VA in Exit"
label var  MFEPromZ "Manager VA in Promotion"
label var  MFEPayZ "Manager VA in Pay"
label var PayBonus "Tot. Compensation"

global controls OfficeYear Func AgeBand

* Main table
eststo clear

eststo: reghdfe LogPayBonus MFEPromZ c.Tenure##c.Tenure##Female ,  a( $controls )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe PromSalaryGrade MFEPromZ c.Tenure##c.Tenure##Female ,  a(   $controls )  vce(cluster IDlse)
estadd ysumm
eststo: reghdfe LeaverPerm MFEPromZ c.Tenure##c.Tenure##Female ,  a(   $controls )  vce(cluster IDlse)
estadd ysumm

esttab using "$Full/Results/3.1.ManagerFE/ManagerReward.tex", keep( MFEPromZ ) stats( r2 ymean N, fmt(%9.3f %9.3f %9.0g)  labels( "R-squared" "Mean" "Number of obs.")) label   se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

