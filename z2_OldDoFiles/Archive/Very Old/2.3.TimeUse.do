* Analysing time use data 

use "$dta/WPAHC.dta", clear

global survey Trust Clarity Integrity BusinessBreach Sustainability Inclusive Diversity TeamAgility CustomersHeart FocusDecision Empowerement CollaborateEffective Experiment LMEffective Proud Balance ExtraMile Purpose AccessLearning CareerDev Wellbeing Refer JobUSLP ContributeUSLP NotLeaving Satisfied RemovingBarriers ControlPrioritising ActionSurvey Technology RecommendProducts StrategyWin Competition

global time multitasking_meeting_hours meeting_hours_with_skip_level meeting_hours__short_ meeting_hours__small_ internal_network_size external_network_size total_focus_hours after_hours_email_hours email_hours conflicting_meeting_hours redundant_meeting_hours collaboration_hours_external low_quality_meeting_hours after_hours_meeting_hours meeting_hours_with_manager meeting_hours_with_manager_11 meeting_hours workweek_span

global timeS meeting_hours_with_skip_level total_focus_hours after_hours_email_hours email_hours low_quality_meeting_hours after_hours_meeting_hours meeting_hours_with_manager meeting_hours_with_manager_11 meeting_hours workweek_span

foreach var in  $timeS {
	xtile  `var'Q=`var', n(4)
		egen `var'B = cut(`var'), group(2)
	}
	
	replace meeting_hours_with_manager_11B = 0 if meeting_hours_with_manager_11 ==0
	
		replace meeting_hours_with_manager_11B = 1 if meeting_hours_with_manager_11 >0
	
foreach var in $survey $time {
	replace `var' = . if  `var' ==0
	egen `var'Z = std(`var')
	egen `var'C = cut(`var'), group(2)
	*xtile  `var'Q=`var', n(4)

	
}

egen align = rowmean(Trust Proud CustomersHeart  StrategyWin)
egen alignZ = std(align)
gen alignB = 1 if align>=4
replace alignB = 0 if align<4
label var alignB "Alignment"
label var alignZ "Alignment"


*CulturalDiversity TeamCollaboration TeamAgility FocusPerf
egen team = rowmean( LMEffective Experiment Empowerement )
egen teamZ = std(team)
gen teamB = 1 if team>=4
replace teamB = 0 if team<4
label var teamB "Team Dynamics"
label var teamZ "Team Dynamics"


egen jobsat = rowmean( ExtraMile Wellbeing Purpose Satisfied  CareerDev NotLeaving Refer )
egen jobsatZ = std(jobsat)
gen jobsatB = 1 if jobsat>=4
replace jobsatB = 0 if jobsat<4
label var jobsatB "Job Satisfaction"
label var jobsatZ "Job Satisfaction"

*WorkLifeBalance AccessLearning

* MAIN TABLE

label var meeting_hours_with_manager_11 "Meeting Hours 1-1 with Manager"
label var meeting_hours_with_manager "Meeting Hours with Manager"
label var workweek_span  "Work Week Span"

eststo clear
eststo:reghdfe alignB meeting_hours_with_manager_11 if meeting_hours_with_manager_11>0  , absorb( TenureBand##Gender  Function   Country AgeBand  ) cluster(IDlseMS)
estadd ysumm
eststo:reghdfe teamB meeting_hours_with_manager_11 if meeting_hours_with_manager_11>0 , absorb( TenureBand##Gender  Function   Country AgeBand  ) cluster(IDlseMS)
estadd ysumm
eststo:reghdfe jobsatB meeting_hours_with_manager_11 if meeting_hours_with_manager_11>0 , absorb( TenureBand##Gender  Function   Country AgeBand ) cluster(IDlseMS) 
estadd ysumm


eststo: reghdfe alignB  meeting_hours_with_manager  , absorb( TenureBand##Gender  Function   Country AgeBand ) cluster(IDlseMS)
estadd ysumm
eststo: reghdfe teamB  meeting_hours_with_manager , absorb( TenureBand##Gender  Function   Country AgeBand ) cluster(IDlseMS)
estadd ysumm
eststo: reghdfe jobsatB  meeting_hours_with_manager , absorb( TenureBand##Gender  Function   Country AgeBand ) cluster(IDlseMS)
estadd ysumm

/*eststo: reghdfe alignB  workweek_span , absorb( TenureBand##Gender  Function   Country AgeBand ) cluster(IDlseMS)
estadd ysumm
eststo: reghdfe teamB  workweek_span , absorb( TenureBand##Gender  Function   Country AgeBand ) cluster(IDlseMS)
estadd ysumm
eststo: reghdfe jobsatB workweek_span, absorb( TenureBand##Gender  Function   Country AgeBand ) cluster(IDlseMS) 
estadd ysumm
*/
esttab using "$Full/Results/2.3.TimeUse/TimeUseManager.tex",  stats( r2 ymean N, fmt(%9.3f %9.3f %9.0g) labels("R-squared" "Mean" "Number of obs.")) keep(meeting_hours_with_manager_11 meeting_hours_with_manager ) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace
 


/*

reghdfe ExtraMileC meeting_hours_with_manager_11Z , absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 

reghdfe ExtraMileZ meeting_hours_with_managerZ , absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 

reghdfe LMEffectiveZ after_hours_email_hoursZ , absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 

reghdfe ExtraMileZ meeting_hours_with_manager_11Z , absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 

reghdfe EmpowerementZ meeting_hours_with_manager_11Z , absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 


reghdfe TrustC meeting_hours_with_manager_11Z , absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 

reghdfe BalanceC  workweek_spanZ, absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 

reghdfe LMEffectiveC workweek_spanZ, absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 

reghdfe ExtraMileC workweek_spanZ, absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS) 

reghdfe PurposeC workweek_spanZ, absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS)

reghdfe CollaborateEffectiveC workweek_spanZ, absorb( TenureBand Function WL Gender Country Month AgeBand ) cluster(IDlseMS)
