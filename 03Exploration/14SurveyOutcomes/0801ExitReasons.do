/* 
This do file compares firm leavers' exit reasons between those supervised by high-flyer managers and those who are supervised by low-flyer managers.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== constructed in 0104 do file 
    "${RawMNEData}/ExitSurvey.dta"                 <== raw data 

Results:
    "${Results}/FTExitReasons.tex"

RA: WWZ 
Time: 2025-01-13
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain exit reasons variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 
merge 1:1 IDlse YearMonth using "${RawMNEData}/ExitSurvey.dta", keepusing(ReasonAnotherOrg) keep(match)

keep  IDlse YearMonth IDlseMHR EarlyAgeM Office ISOCode Func ReasonAnotherOrg
order IDlse YearMonth IDlseMHR EarlyAgeM Office ISOCode Func ReasonAnotherOrg

keep if ReasonAnotherOrg!=.
tab ReasonAnotherOrg, gen(ReasonAnotherOrg)

label variable EarlyAgeM         "High Flyer Manager" 
label variable ReasonAnotherOrg4 "Change of career"
label variable ReasonAnotherOrg7 "Line manager"
label variable ReasonAnotherOrg2 "Cultural fit"
label variable ReasonAnotherOrg5 "Competitive pay"
label variable ReasonAnotherOrg1 "Career progression"
label variable ReasonAnotherOrg6 "Getting work done"
label variable ReasonAnotherOrg3 "Work-life balance"

save "${TempData}/temp_exitreasons.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_exitreasons.dta", clear 

eststo clear 
foreach var in ReasonAnotherOrg4 ReasonAnotherOrg7 ReasonAnotherOrg2 ReasonAnotherOrg5 ReasonAnotherOrg1 ReasonAnotherOrg6 ReasonAnotherOrg3 {
    reghdfe `var' EarlyAgeM, absorb(Office YearMonth ISOCode) cluster(IDlseMHR)
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
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker who left the firm and had the exit survey. Standard errors are clustered by manager. Controls include year-month, country, office, and function FE. The outcome variable equals to one if the worker left the firm due to the corresponding reason. The manager's quality is measured in the month of the worker's exit." "\end{tablenotes}")
