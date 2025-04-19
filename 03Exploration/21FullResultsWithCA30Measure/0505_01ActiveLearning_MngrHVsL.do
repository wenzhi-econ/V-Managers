/* 
This do file compares H- and L-type managers in active learning activities.

Input:
    "${TempData}/FinalAnalysisSample.dta" <== created in 0103_03 do file 
    "${RawMNEData}/ActiveLearn.dta"       <== raw data 

Results:
    "${Results}/FTActiveLearn.tex"

RA: WWZ 
Time: 2025-04-16
*/

replace ActiveLearnerYTD = 0 if ActiveLearnerYTD==. & (NumSkillsB==0 | NumCompletedYTDB==0 | NumRecommendYTDB==0)
replace ActiveLearnerYTD = 1 if ActiveLearnerYTD==. & (NumSkillsB==1 & NumCompletedYTDB==1 & NumRecommendYTDB==1)

label variable NumSkillsB        "Number of skills >= 3"
label variable NumCompletedYTDB  "Completed items >= 5"
label variable NumRecommendYTDB  "Shared items with colleagues>0"
label variable ActiveLearnerYTD  "Meeting all conditions: active learner"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain variables about workers' active learning in the firm
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
    //impt: use the analysis sample, i.e., keep only those workers who are in the event studies

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. obtain variables about active learning 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${RawMNEData}/ActiveLearn.dta"
    drop if _merge==2
    drop _merge  

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. obtain variables about managers' quality 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR YearMonth using "${TempData}/0102_03HFMeasure.dta", keepusing(CA30)
    drop if _merge==2
    drop _merge 
rename CA30 CA30M 
order CA30M, after(IDlseMHR)

sort IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

eststo clear 

foreach var in NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD {
    reghdfe `var' CA30M if Post_Event==1, absorb(ISOCode Year) cluster(IDlseMHR)
        eststo `var'
        summarize `var' if e(sample)==1 & CA30M==0 
        estadd scalar cmean = r(mean)
}

esttab NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD, star

esttab NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD using "${Results}/004ResultsBasedOnCA30/CA30_ActiveLearning.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    keep(CA30M) varlabels(CA30M "High-flyer manager ") ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues $>$ 0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Controls include year FE and contry FE. Data from the internal talent matching platform. \emph{Number of skills $\geq$ 3} equals to 1 if the worker has more than 3 skills in the platform. \emph{Completed items $\geq$ 5} equals to 1 if the worker has completed more than 5 items in the platform. \emph{Shared items with colleagues $>$ 0} equals to 1 if the worker has done items with colleagues. \emph{Active learner} equals to 1 if the worker meets all the above three conditions." "\end{tablenotes}")