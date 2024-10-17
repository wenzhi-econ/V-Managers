/* 
This do file compares H- and L-type managers in flexible project engagement.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0104 do file 
    "${RawMNEData}/FLEX.dta"

Results:
    "${Results}/FTFlexibleProjects_SelfConstructedData.tex"

RA: WWZ 
Time: 2024-10-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain variables about workers' project engagement in the firm
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. project engagement variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

merge m:1 IDlse using "${RawMNEData}/FLEX.dta", keepusing(CompletedProfileDummy AvailableJobs AvailableMentor PositionsAppliedDummy)
drop if _merge==2 
generate InFLEX = (_merge==3)
label variable InFLEX "Registered on Platform"
drop _merge 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. auxilary variable for regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .

save "${TempData}/temp_FLEX.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_FLEX.dta", clear 

eststo clear
foreach var in InFLEX CompletedProfileDummy AvailableJobs AvailableMentor PositionsAppliedDummy  { 
    reghdfe `var' EarlyAgeM if Post==1 & Year>2019, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'
        summarize `var' if e(sample)==1 & EarlyAgeM==0 
        estadd scalar cmean = r(mean)
}

foreach var in InFLEX CompletedProfileDummy AvailableJobs AvailableMentor PositionsAppliedDummy  { 
    reghdfe `var' EarlyAgeM if Post==1 & Year>2019 & FT_Mngr_both_WL2==1, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'_WL2
        summarize `var' if e(sample)==1 & EarlyAgeM==0 
        estadd scalar cmean = r(mean)
}

esttab InFLEX CompletedProfileDummy AvailableJobs AvailableMentor PositionsAppliedDummy using "${Results}/FTFlexibleProjects_SelfConstructedData.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    keep(EarlyAgeM) varlabels(EarlyAgeM "High-flyer manager ") ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Registered on Platform} & \multicolumn{1}{c}{Profile Completed}  & \multicolumn{1}{c}{Available for Jobs} & \multicolumn{1}{c}{Available for Mentors} & \multicolumn{1}{c}{Applied to Position}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Data are taken from flexible project program at the firm since 2020 that allows workers to apply for short-term projects inside the company but outside their current team. \emph{Registered on the platform} indicates whether the employee created an account on the flexible projects platform. The remaining outcomes are for those employees that registered on the platform: \emph{Profile Completed} indicates whether the profile on the platform is fully completed; \emph{Available for Jobs} indicates whether the employee is available for jobs; \emph{Available for Mentors} indicates whether the employee is available for mentors; and \emph{Applied to Position} indicates whether the employee has applied to a position on the platform. Controls include country and year FE." "\end{tablenotes}")

esttab InFLEX_WL2 CompletedProfileDummy_WL2 AvailableJobs_WL2 AvailableMentor_WL2 PositionsAppliedDummy_WL2 using "${Results}/FTFlexibleProjects_SelfConstructedData_WL2.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    keep(EarlyAgeM) varlabels(EarlyAgeM "High-flyer manager ") ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Registered on Platform} & \multicolumn{1}{c}{Profile Completed}  & \multicolumn{1}{c}{Available for Jobs} & \multicolumn{1}{c}{Available for Mentors} & \multicolumn{1}{c}{Applied to Position}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Data are taken from flexible project program at the firm since 2020 that allows workers to apply for short-term projects inside the company but outside their current team. \emph{Registered on the platform} indicates whether the employee created an account on the flexible projects platform. The remaining outcomes are for those employees that registered on the platform: \emph{Profile Completed} indicates whether the profile on the platform is fully completed; \emph{Available for Jobs} indicates whether the employee is available for jobs; \emph{Available for Mentors} indicates whether the employee is available for mentors; and \emph{Applied to Position} indicates whether the employee has applied to a position on the platform. Controls include country and year FE." "\end{tablenotes}")
