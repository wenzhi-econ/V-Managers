/* 
This do file compares H- and L-type managers in flexible project engagement.

Input:
    "${TempData}/FinalAnalysisSample.dta"          <== created in 0103_03 do file 
    "${RawMNEData}/FLEX.dta"                       <== raw data

Output:
    "${Results}/FTFlexibleProjects.tex"

RA: WWZ 
Time: 2025-04-18
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain variables about workers' project engagement in the firm
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge the flexible project dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 
    //impt: focus only on the employees who are in the event study 
merge m:1 IDlse using "${RawMNEData}/FLEX.dta", keep(match) nogenerate 
    //&? the flexible project dataset is a snapshot of the platform information, thus a cross section 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. important sample restrictions  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if Rel_Time==0
    //impt: keep variables at the event time
keep if CA30_LtoL==1 | CA30_LtoH==1
    //&? keep only LtoL and LtoH workers
keep if YearMonthPurpose>=Event_Time
    //impt: the timing of the platform snapshot should be later than the event time 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. relative time from the event to the platform snapshot
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Rel_Platform_Time = YearMonthPurpose - Event_Time
    //&? relative time from the event to the platform snapshot


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. summary of the regression results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
//&? This step comes after step 2, where I try out different specifications for different outcomes. 
//&? I manually move this step here to produce the table needed for the task report.

local i = 0
foreach var in AvailableJobs AvailableMentor HoursAvailable AvailableProjectRoles ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    local i = `i' + 1
    regress `var' CA30_LtoH, vce(cluster IDMngr_Post)
        eststo reg`i'_NoC
        summarize `var' if CA30_LtoL==1 & e(sample)==1
        estadd scalar cmean = r(mean)
}

local i = 0
foreach var in AvailableJobs AvailableMentor HoursAvailable AvailableProjectRoles ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    local i = `i' + 1
    reghdfe `var' CA30_LtoH, absorb(Event_Time Female#AgeBand) vce(cluster IDMngr_Post)
        eststo reg`i'_NoOF
        summarize `var' if CA30_LtoL==1 & e(sample)==1
        estadd scalar cmean = r(mean)
}

local i = 0
foreach var in AvailableJobs AvailableMentor HoursAvailable AvailableProjectRoles ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    local i = `i' + 1
    reghdfe `var' CA30_LtoH, absorb(Event_Time Office#Func) vce(cluster IDMngr_Post)
        eststo reg`i'_WithOF
        summarize `var' if CA30_LtoL==1 & e(sample)==1
        estadd scalar cmean = r(mean)
}


esttab reg1_NoC reg2_NoC reg3_NoC reg4_NoC reg5_NoC reg6_NoC reg7_NoC reg8_NoC ///
    using "${Results}/004ResultsBasedOnCA30/CA30_FlexibleProject_DiffControls_3Panels.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean N, labels("Mean, LtoL group" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Available for jobs} & \multicolumn{1}{c}{Available for mentors}  & \multicolumn{1}{c}{Number of hours available} & \multicolumn{1}{c}{Available for project roles} & \multicolumn{1}{c}{Profile completeness degree} & \multicolumn{1}{c}{Profile completed} & \multicolumn{1}{c}{Number of project roles applied} & \multicolumn{1}{c}{Applied to any project role} \\") ///
    posthead("\midrule" "\multicolumn{8}{l}{Panel (a): No controls} \\ [7pt]") ///
    prefoot("\midrule")  ///
    postfoot("\midrule")

esttab reg1_NoOF reg2_NoOF reg3_NoOF reg4_NoOF reg5_NoOF reg6_NoOF reg7_NoOF reg8_NoOF ///
    using "${Results}/004ResultsBasedOnCA30/CA30_FlexibleProject_DiffControls_3Panels.tex", ///
    append style(tex) fragment nocons label nofloat nobaselevels se nonumbers ///
    nomtitles collabels(,none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean N, labels("Mean, LtoL group" "N") fmt(%9.3f %9.0f)) ///
    prehead("") ///
    posthead("\multicolumn{8}{l}{Panel (b): Control for $\mathtt{Event_Time \;\;\; Female\#AgeBand}$ } \\ [7pt]") ///
    prefoot("\midrule")  ///
    postfoot("\midrule")

esttab reg1_WithOF reg2_WithOF reg3_WithOF reg4_WithOF reg5_WithOF reg6_WithOF reg7_WithOF reg8_WithOF ///
    using "${Results}/004ResultsBasedOnCA30/CA30_FlexibleProject_DiffControls_3Panels.tex", ///
    append style(tex) fragment nocons label nofloat nobaselevels se nonumbers ///
    nomtitles collabels(,none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean N, labels("Mean, LtoL group" "N") fmt(%9.3f %9.0f)) ///
    prehead("") ///
    posthead("\multicolumn{8}{l}{Panel (c): Control for $\mathtt{Event_Time \;\;\; Office\#Func}$} \\ [7pt]") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is an employee. Regression sample includes those employees who are in the LtoL and LtoH event groups, and also show up in the flexible project platform. The regressor is whether the employee is in the LtoH group. Standard errors are clustered in the post-event manager level. In panel (a), there are no controls. In panel (b), I control for event time, and the interaction of gender and age band fixed effects. In panel (c), I control for event time, and the interaction of office and function fixed effects." "\end{tablenotes}")



*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. outcome set 1: Office#Func really matters 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Female#AgeBand Office#Func) cluster(IDMngr_Post)
        eststo `var'
        summarize `var' if CA30_LtoL==1 & e(sample)==1
        estadd scalar cmean = r(mean)
}

esttab ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy ///
     using "${Results}/004ResultsBasedOnCA30/CA30_FlexibleProject_VarSet1.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean N, labels("Mean, LtoL group" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Profile completeness degree} & \multicolumn{1}{c}{Complete profile}  & \multicolumn{1}{c}{Number of project roles applied} & \multicolumn{1}{c}{Applied to any project role}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. Standard errors are clustered by the destination manager in the event. Data are taken from flexible project program at the firm since 2020 that allows workers to apply for short-term projects inside the company but outside their current team. The program dataset is a snapshot for an employee's project participation information, the regression sample includes those matched employees in the event studies, and the snapshot month is later than their event time. Controls include event time fixed effect, the interaction of female and age band fixed effects, and the interaction of office and function fixed effects." "\end{tablenotes}")

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-1-1. all other specifications I have tried 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    regress `var' CA30_LtoH, vce(robust)
}

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Office Event_Time) cluster(IDMngr_Post)
}

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Func Event_Time) cluster(IDMngr_Post)
}
    //impt" all the above specifications are not significant

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Office#Func) cluster(IDMngr_Post)
}
    //impt: basically, for this set of outcomes, once Office#Func is controlled, they all tend to be significantly positive.

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Office#Func Event_Time) cluster(IDMngr_Post)
}

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Female#AgeBand Office#Func) cluster(IDMngr_Post)
}

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Office#Func) cluster(IDMngr_Post)
}

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time Female#AgeBand Office#Func) cluster(IDMngr_Post)
}

foreach var in ProfileCompleteness CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time Office#Func) cluster(IDMngr_Post)
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. outcome set 2: exclusion of Office#Func matters 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

replace HoursAvailable = 0 if HoursAvailable==.

foreach var in AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Female#AgeBand) cluster(IDMngr_Post)
        eststo `var'
        summarize `var' if CA30_LtoL==1 & e(sample)==1
        estadd scalar cmean = r(mean)
}

esttab AvailableJobs AvailableMentor HoursAvailable ///
     using "${Results}/004ResultsBasedOnCA30/CA30_FlexibleProject_VarSet2.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean N, labels("Mean, LtoL group" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Available for jobs} & \multicolumn{1}{c}{Available for mentors}  & \multicolumn{1}{c}{Number of hours available} \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. Standard errors are clustered by the destination manager in the event. Data are taken from flexible project program at the firm since 2020 that allows workers to apply for short-term projects inside the company but outside their current team. The program dataset is a snapshot for an employee's project participation information, the regression sample includes those matched employees in the event studies, and the snapshot month is later than their event time. Controls include event time fixed effect, and the interaction of female and age band fixed effects." "\end{tablenotes}")

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-2-1. all other specifications I have tried 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    regress `var' CA30_LtoH, vce(robust)
}
    //&? already very good 

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time) vce(robust)
} 

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time Female#AgeBand) vce(robust)
} 

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time ISOCode) vce(robust)
}  

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Event_Time) vce(robust)
}

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Female#AgeBand) vce(robust)
}

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    regress `var' CA30_LtoH, absorb(ISOCode) vce(robust)
}

    //&? all the above four sets are good enough 

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Female#AgeBand Office#Func) vce(robust)
}
    //impt: no longer significant

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Office#Func) vce(robust)
} 

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Office#Func Event_Time) vce(robust)
} 

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Office#Func Rel_Platform_Time) vce(robust)
} 

foreach var in AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Office#Func Rel_Platform_Time Female#AgeBand) vce(robust)
} 

