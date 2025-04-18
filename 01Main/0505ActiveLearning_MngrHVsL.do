/* 
This do file compares H- and L-type managers in active learning activities.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 
    "${RawMNEData}/ActiveLearn.dta"                <== raw data 

Results:
    "${Results}/FTActiveLearn.tex"

RA: WWZ 
Time: 2025-01-13
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain variables about workers' active learning in the firm
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. active learning variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

merge 1:1 IDlse YearMonth using "${RawMNEData}/ActiveLearn.dta", keepusing(ActiveLearnerYTD NumCompletedYTDB NumRecommendYTDB NumSkillsB)
keep if _merge==3
drop _merge 

label variable NumSkillsB        "Number of skills >= 3"
label variable NumCompletedYTDB  "Completed items >= 5"
label variable NumRecommendYTDB  "Shared items with colleagues>0"
label variable ActiveLearnerYTD  "Meeting all conditions: active learner"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. auxiliary variable for regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .

save "${TempData}/temp_ActiveLearn.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_ActiveLearn.dta", clear 

capture drop Year
generate Year = year(dofm(YearMonth))

replace ActiveLearnerYTD = 0 if ActiveLearnerYTD==. ///
    & (NumSkillsB==0 | NumCompletedYTDB==0 | NumRecommendYTDB==0)
replace ActiveLearnerYTD = 1 if ActiveLearnerYTD==. ///
    & (NumSkillsB==1 & NumCompletedYTDB==1 & NumRecommendYTDB==1)

order IDlse YearMonth IDlseMHR ///
    EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    Post NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD

eststo clear 

foreach var in NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD {
    reghdfe `var' EarlyAgeM if Post==1, absorb(Year ISOCode) cluster(IDlseMHR)
        eststo `var'
        summarize `var' if e(sample)==1 & EarlyAgeM==0 
        estadd scalar cmean = r(mean)
}

esttab NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD using "${Results}/FTActiveLearn.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    keep(EarlyAgeM) varlabels(EarlyAgeM "High-flyer manager ") ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues $>$ 0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Controls include year FE and contry FE. Data from the internal talent matching platform. \emph{Number of skills $\geq$ 3} equals to 1 if the worker has more than 3 skills in the platform. \emph{Completed items $\geq$ 5} equals to 1 if the worker has completed more than 5 items in the platform. \emph{Shared items with colleagues $>$ 0} equals to 1 if the worker has done items with colleagues. \emph{Active learner} equals to 1 if the worker meets all the above three conditions." "\end{tablenotes}")