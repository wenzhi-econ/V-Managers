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
*-? s-1-1. project engagement variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 



merge m:1 IDlse using "${RawMNEData}/FLEX.dta"
drop if _merge==2 
generate InFLEX = (_merge==3)
label variable InFLEX "Registered on Platform"
drop _merge 

keep if Rel_Time==0

keep if CA30_LtoL==1 | CA30_LtoH==1

keep if YearMonthPurpose>=Event_Time

generate Rel_Platform_Time = YearMonthPurpose - Event_Time


reghdfe InFLEX CA30_LtoH, absorb(Event_Time) vce(robust)


keep if InFLEX==1

global controls Rel_Platform_Time Female#AgeBand

foreach var in ProfileCompleteness NrProjectsCreated NrProjectRolesApplied NrPositionsApplied NrProjectRolesAccepted NrPositionsAccepted NrProjectRolesAssigned NrPositionsAssigned {
    reghdfe `var' CA30_LtoH, absorb($controls) vce(robust)
}

foreach var in ProfileCompleteness NrProjectRolesApplied {
    reghdfe `var' CA30_LtoH, absorb($controls) vce(robust)
}

foreach var in CompletedProfileDummy {
    reghdfe `var' CA30_LtoH, absorb($controls) vce(robust)
}

foreach var in ProjectRolesAppliedDummy {
    reghdfe `var' CA30_LtoH, absorb($controls) vce(robust)
}

foreach var in HoursAvailable AvailableProjectRoles AvailableJobs AvailableMentor AccessOpportunities AccessCandidate {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time Office#Func Female#AgeBand) vce(robust)
}

foreach var in AvailableJobs AvailableMentor {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time Office#Func Female#AgeBand) vce(robust)
}

foreach var in ProjectRolesAppliedDummy PositionsAppliedDummy ProjectRolesAcceptedDummy PositionsAcceptedDummy ProjectRolesAssignedDummy PositionsAssignedDummy {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time Office#Func Female#AgeBand) vce(robust)
}

reghdfe AvailableJobs CA30_LtoH, absorb(Rel_Platform_Time) vce(robust)


foreach var in CompletedProfileDummy ProfileCompleteness NrProjectRolesApplied {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time Female#AgeBand Office#Func) vce(robust)
}
reghdfe ProjectRolesAppliedDummy CA30_LtoH, absorb(Rel_Platform_Time Female#AgeBand Office#Func) vce(robust)

foreach var in CompletedProfileDummy ProfileCompleteness NrProjectRolesApplied {
    reghdfe `var' CA30_LtoH, absorb(Female#AgeBand Office#Func) vce(robust)
}
reghdfe ProjectRolesAppliedDummy CA30_LtoH, absorb(Female#AgeBand Office#Func) vce(robust)



reghdfe AvailableJobs CA30_LtoH, absorb(Female#AgeBand) vce(robust)

reghdfe AvailableMentor CA30_LtoH, absorb(Rel_Platform_Time Female#AgeBand) vce(robust)

foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Event_Time) vce(robust)
}
    // last three 

foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Office#Func) vce(robust)
}
    // first three 

foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Office#Func ISOCode) vce(robust)
}
    // first three 

foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Female#AgeBand Office#Func) vce(robust)
}
    //only first three 


foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Event_Time) vce(robust)
}
    //only last three 

foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time) vce(robust)
}
    //last four 


foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time Female#AgeBand) vce(robust)
}
    //last three

foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Rel_Platform_Time ISOCode) vce(robust)
}
    //last two 



foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Office#Func) vce(robust)
}
    //first three 

foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Office#Func Female#AgeBand) vce(robust)
}
    //first three

foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Office#Func Event_Time) vce(robust)
}
    //first three 


foreach var in CompletedProfileDummy NrProjectRolesApplied ProjectRolesAppliedDummy AvailableProjectRoles AvailableJobs AvailableMentor HoursAvailable {
    reghdfe `var' CA30_LtoH, absorb(Office#Func Rel_Platform_Time) vce(robust)
}
    //first two 




