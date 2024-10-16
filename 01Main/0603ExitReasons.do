/* 
This do file compares H- and L-type managers in flexible project engagement.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0104 do file 
    "${RawMNEData}/ExitSurvey.dta"

Results:
    "${Results}/FTFlexibleProjects_SelfConstructedData.tex"

RA: WWZ 
Time: 2024-10-15
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain variables about workers' active learning in the firm
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. exit reasons variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

merge 1:1 IDlse YearMonth using "${RawMNEData}/ExitSurvey.dta", ///
    keepusing(ReasonAnotherOrg) nogenerate 

tab ReasonAnotherOrg, gen(ReasonAnotherOrg)

label variable EarlyAgeM         "High Flyer Manager" 
label variable ReasonAnotherOrg4 "Change of career"
label variable ReasonAnotherOrg7 "Line manager"
label variable ReasonAnotherOrg2 "Cultural fit"
label variable ReasonAnotherOrg5 "Competitive pay"
label variable ReasonAnotherOrg1 "Career progression"
label variable ReasonAnotherOrg6 "Getting work done"
label variable ReasonAnotherOrg3 "Work-life balance"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. auxilary variable for regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .

save "${TempData}/temp_exitreasons.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_exitreasons.dta", clear 

order IDlse YearMonth IDlseMHR ///
    EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    LeaverPerm ReasonAnotherOrg*

keep if ReasonAnotherOrg!=.

eststo clear 
foreach var in ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1 ReasonAnotherOrg6 ReasonAnotherOrg3 {
    reghdfe `var' EarlyAgeM if Post==1 & FT_Mngr_both_WL2==1, absorb(Year) cluster(IDlseMHR)
        eststo `var'
        summarize `var' if e(sample)==1 & EarlyAgeM==0
        estadd scalar cmean = r(mean)
}

esttab ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1 ReasonAnotherOrg6 ReasonAnotherOrg3 using "${Results}/FTExitReasons.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    keep(EarlyAgeM) varlabels(EarlyAgeM "High-flyer manager ") ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Change of career} & \multicolumn{1}{c}{Line manager}  & \multicolumn{1}{c}{Cultural fit} & \multicolumn{1}{c}{Competitive pay} & \multicolumn{1}{c}{Career progression} & \multicolumn{1}{c}{Getting work done} & \multicolumn{1}{c}{Work-life balance}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker who left the firm and had the exit survey. Standard errors are clustered by manager. Controls include year FE. The outcome variable equals to one if the worker left the firm due to the corresponding reason. Only those workers in the event studies are considered." "\end{tablenotes}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions considering the event managers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_exitreasons.dta", clear 

order IDlse YearMonth IDlseMHR ///
    EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    LeaverPerm ReasonAnotherOrg*

sort IDlse YearMonth 
bysort IDlse: egen EarlyAgeM_Event = mean(cond(FT_Rel_Time==0, EarlyAgeM, .))

keep if ReasonAnotherOrg!=.

foreach var in ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1 ReasonAnotherOrg6 ReasonAnotherOrg3 {
    reghdfe `var' EarlyAgeM_Event if Post==1 & FT_Mngr_both_WL2==1, absorb(Year) cluster(IDlseMHR)
        eststo `var'_E
        summarize `var' if e(sample)==1 & EarlyAgeM==0
        estadd scalar cmean = r(mean)
}

esttab ReasonAnotherOrg4_E ReasonAnotherOrg7_E ReasonAnotherOrg2_E ReasonAnotherOrg5_E ReasonAnotherOrg1_E ReasonAnotherOrg6_E ReasonAnotherOrg3_E using "${Results}/FTExitReasons_EventMngr.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    keep(EarlyAgeM_Event) varlabels(EarlyAgeM_Event "High-flyer manager ") ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Change of career} & \multicolumn{1}{c}{Line manager}  & \multicolumn{1}{c}{Cultural fit} & \multicolumn{1}{c}{Competitive pay} & \multicolumn{1}{c}{Career progression} & \multicolumn{1}{c}{Getting work done} & \multicolumn{1}{c}{Work-life balance}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker who left the firm and had the exit survey. Standard errors are clustered by manager. Controls include year FE. The outcome variable equals to one if the worker left the firm due to the corresponding reason. Only those workers in the event studies are considered." "\end{tablenotes}")






