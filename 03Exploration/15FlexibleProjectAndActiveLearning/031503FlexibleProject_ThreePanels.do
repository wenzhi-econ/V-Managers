/* 
This do file explores the an employee's past manager type on his current active learning and flexible project engagement activities.

RA: WWZ
Time: 2025-03-30
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge the additional dataset to the main data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

merge m:1 IDlse using "${RawMNEData}/FLEX.dta", keepusing(CompletedProfileDummy AvailableJobs AvailableMentor PositionsAppliedDummy)
    drop if _merge==2 
    generate InFLEX = (_merge==3)
    label variable InFLEX "Registered on Platform"
    drop _merge 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. other variables for regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
//&? Notes: Consider only those employees who have ever experienced a manager change event.
//impt: This is not the sample of employees in the event studies, as we do not impose the work level restrictions.

*!! s-1-2-1. restrict the regression sample
generate Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .

*!! s-1-2-2. an employee's past manager information 
sort  IDlse YearMonth
xtset IDlse YearMonth, monthly
foreach lag in 12 24 36 48 60 {
    generate EarlyAgeM_lag`lag' = L`lag'.EarlyAgeM
    label variable EarlyAgeM_lag`lag' "High-flyer manager, `lag' months ago"
}

order IDlse YearMonth IDlseMHR ///
    EarlyAgeM EarlyAgeM_lag12 EarlyAgeM_lag24 EarlyAgeM_lag36 EarlyAgeM_lag48 EarlyAgeM_lag60

label variable EarlyAgeM "High-flyer manager "
label variable EarlyAgeM_lag12 "High-flyer manager, 12 months ago"
label variable EarlyAgeM_lag24 "High-flyer manager, 24 months ago"
label variable EarlyAgeM_lag36 "High-flyer manager, 36 months ago"
label variable EarlyAgeM_lag48 "High-flyer manager, 48 months ago"
label variable EarlyAgeM_lag60 "High-flyer manager, 60 months ago"

save "${TempData}/temp_FlexibleProject.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_FlexibleProject.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. no-lagging regressions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo clear
foreach var in InFLEX CompletedProfileDummy AvailableJobs AvailableMentor PositionsAppliedDummy { 
    reghdfe `var' EarlyAgeM if Post==1 & Year>2019, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'0
        summarize `var' if e(sample)==1 & EarlyAgeM==0 
        estadd scalar cmean = r(mean)
}
esttab InFLEX0 CompletedProfileDummy0 AvailableJobs0 AvailableMentor0 PositionsAppliedDummy0
    //&? test passed: it generates exactly the same results as the 01Main/0506.do file 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. manager 3 years before the outcome measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in InFLEX CompletedProfileDummy AvailableJobs AvailableMentor PositionsAppliedDummy { 
    reghdfe `var' EarlyAgeM_lag36 if Post==1 & Year>2019, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'3
        summarize `var' if e(sample)==1 & EarlyAgeM_lag36==0 
        estadd scalar cmean = r(mean)
}
esttab InFLEX3 CompletedProfileDummy3 AvailableJobs3 AvailableMentor3 PositionsAppliedDummy3

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. manager 5 years before the outcome measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in InFLEX CompletedProfileDummy AvailableJobs AvailableMentor PositionsAppliedDummy { 
    reghdfe `var' EarlyAgeM_lag60 if Post==1 & Year>2019, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'5
        summarize `var' if e(sample)==1 & EarlyAgeM_lag60==0 
        estadd scalar cmean = r(mean)
}
esttab InFLEX5 CompletedProfileDummy5 AvailableJobs5 AvailableMentor5 PositionsAppliedDummy5

esttab InFLEX0 CompletedProfileDummy0 AvailableJobs0 AvailableMentor0 PositionsAppliedDummy0 using "${Results}/FTFlexibleProjects_ThreePanel_035.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Registered on Platform} & \multicolumn{1}{c}{Profile Completed}  & \multicolumn{1}{c}{Available for Jobs} & \multicolumn{1}{c}{Available for Mentors} & \multicolumn{1}{c}{Applied to Position}  \\") ///
    posthead("\midrule") ///
    postfoot("\midrule")

esttab InFLEX3 CompletedProfileDummy3 AvailableJobs3 AvailableMentor3 PositionsAppliedDummy3 using "${Results}/FTFlexibleProjects_ThreePanel_035.tex", ///
    append style(tex) fragment nocons label nofloat nobaselevels se nonumbers ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("") ///
    posthead("") ///
    postfoot("\midrule")

esttab InFLEX5 CompletedProfileDummy5 AvailableJobs5 AvailableMentor5 PositionsAppliedDummy5 using "${Results}/FTFlexibleProjects_ThreePanel_035.tex", ///
    append style(tex) fragment nocons label nofloat nobaselevels se nonumbers ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("") ///
    posthead("") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Data are taken from flexible project program at the firm since 2020 that allows workers to apply for short-term projects inside the company but outside their current team. \emph{Registered on the platform} indicates whether the employee created an account on the flexible projects platform. The remaining outcomes are for those employees that registered on the platform: \emph{Profile Completed} indicates whether the profile on the platform is fully completed; \emph{Available for Jobs} indicates whether the employee is available for jobs; \emph{Available for Mentors} indicates whether the employee is available for mentors; and \emph{Applied to Position} indicates whether the employee has applied to a position on the platform. In the first panel, the regressor is the employee's current manager type; while in the last two panels, the regressor is the employee's lagged manager type. Controls include country and year FE." "\end{tablenotes}")