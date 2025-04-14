/* 
This do file explores the an employee's past manager type on his current active learning and flexible project engagement activities.

RA: WWZ
Time: 2025-03-27
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge the additional dataset to the main data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

merge 1:1 IDlse YearMonth using "${RawMNEData}/ActiveLearn.dta", keepusing(ActiveLearnerYTD NumCompletedYTDB NumRecommendYTDB NumSkillsB)
    drop if _merge==2
    drop _merge 

replace ActiveLearnerYTD = 0 if ActiveLearnerYTD==. ///
    & (NumSkillsB==0 | NumCompletedYTDB==0 | NumRecommendYTDB==0)
replace ActiveLearnerYTD = 1 if ActiveLearnerYTD==. ///
    & (NumSkillsB==1 & NumCompletedYTDB==1 & NumRecommendYTDB==1)

label variable NumSkillsB        "Number of skills >= 3"
label variable NumCompletedYTDB  "Completed items >= 5"
label variable NumRecommendYTDB  "Shared items with colleagues>0"
label variable ActiveLearnerYTD  "Meeting all conditions: active learner"

capture drop Year
generate Year = year(dofm(YearMonth))

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

save "${TempData}/temp_ActiveLearning.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_ActiveLearning.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. no-lagging regressions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo clear
foreach var in NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD {
    reghdfe `var' EarlyAgeM if Post==1, absorb(Year ISOCode) cluster(IDlseMHR)
        eststo `var'0
        summarize `var' if e(sample)==1 & EarlyAgeM==0 
        estadd scalar cmean = r(mean)
}

esttab NumSkillsB0 NumCompletedYTDB0 NumRecommendYTDB0 ActiveLearnerYTD0
    //&? test passed: it generates exactly the same results as the 01Main/0505.do file 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. manager 1 year before the outcome measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD { 
    reghdfe `var' EarlyAgeM_lag12 if Post==1, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'1
        summarize `var' if e(sample)==1 & EarlyAgeM_lag12==0 
        estadd scalar cmean = r(mean)
}
esttab NumSkillsB1 NumCompletedYTDB1 NumRecommendYTDB1 ActiveLearnerYTD1

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. manager 2 years before the outcome measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD { 
    reghdfe `var' EarlyAgeM_lag24 if Post==1, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'2
        summarize `var' if e(sample)==1 & EarlyAgeM_lag24==0 
        estadd scalar cmean = r(mean)
}
esttab NumSkillsB2 NumCompletedYTDB2 NumRecommendYTDB2 ActiveLearnerYTD2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. manager 3 years before the outcome measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD { 
    reghdfe `var' EarlyAgeM_lag36 if Post==1, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'3
        summarize `var' if e(sample)==1 & EarlyAgeM_lag36==0 
        estadd scalar cmean = r(mean)
}
esttab NumSkillsB3 NumCompletedYTDB3 NumRecommendYTDB3 ActiveLearnerYTD3

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. manager 4 years before the outcome measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD { 
    reghdfe `var' EarlyAgeM_lag48 if Post==1, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'4
        summarize `var' if e(sample)==1 & EarlyAgeM_lag48==0 
        estadd scalar cmean = r(mean)
}
esttab NumSkillsB4 NumCompletedYTDB4 NumRecommendYTDB4 ActiveLearnerYTD4

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-6. manager 5 years before the outcome measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in NumSkillsB NumCompletedYTDB NumRecommendYTDB ActiveLearnerYTD { 
    reghdfe `var' EarlyAgeM_lag60 if Post==1, absorb(Year ISOCode) cluster(IDlseMHR)  
        eststo `var'5
        summarize `var' if e(sample)==1 & EarlyAgeM_lag60==0 
        estadd scalar cmean = r(mean)
}
esttab NumSkillsB5 NumCompletedYTDB5 NumRecommendYTDB5 ActiveLearnerYTD5

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the regression tables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable EarlyAgeM "High-flyer manager "
label variable EarlyAgeM_lag12 "High-flyer manager, 12 months ago"
label variable EarlyAgeM_lag24 "High-flyer manager, 24 months ago"
label variable EarlyAgeM_lag36 "High-flyer manager, 36 months ago"
label variable EarlyAgeM_lag48 "High-flyer manager, 48 months ago"
label variable EarlyAgeM_lag60 "High-flyer manager, 60 months ago"

esttab NumSkillsB0 NumCompletedYTDB0 NumRecommendYTDB0 ActiveLearnerYTD0 using "${Results}/FTActiveLearn_Lag0.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues $>$ 0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Controls include year FE and contry FE. Data from the internal talent matching platform. \emph{Number of skills $\geq$ 3} equals to 1 if the worker has more than 3 skills in the platform. \emph{Completed items $\geq$ 5} equals to 1 if the worker has completed more than 5 items in the platform. \emph{Shared items with colleagues $>$ 0} equals to 1 if the worker has done items with colleagues. \emph{Active learner} equals to 1 if the worker meets all the above three conditions." "\end{tablenotes}")


esttab NumSkillsB1 NumCompletedYTDB1 NumRecommendYTDB1 ActiveLearnerYTD1 using "${Results}/FTActiveLearn_Lag1.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues $>$ 0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Controls include year FE and contry FE. Data from the internal talent matching platform. \emph{Number of skills $\geq$ 3} equals to 1 if the worker has more than 3 skills in the platform. \emph{Completed items $\geq$ 5} equals to 1 if the worker has completed more than 5 items in the platform. \emph{Shared items with colleagues $>$ 0} equals to 1 if the worker has done items with colleagues. \emph{Active learner} equals to 1 if the worker meets all the above three conditions." "\end{tablenotes}")


esttab NumSkillsB2 NumCompletedYTDB2 NumRecommendYTDB2 ActiveLearnerYTD2 using "${Results}/FTActiveLearn_Lag2.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues $>$ 0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Controls include year FE and contry FE. Data from the internal talent matching platform. \emph{Number of skills $\geq$ 3} equals to 1 if the worker has more than 3 skills in the platform. \emph{Completed items $\geq$ 5} equals to 1 if the worker has completed more than 5 items in the platform. \emph{Shared items with colleagues $>$ 0} equals to 1 if the worker has done items with colleagues. \emph{Active learner} equals to 1 if the worker meets all the above three conditions." "\end{tablenotes}")


esttab NumSkillsB3 NumCompletedYTDB3 NumRecommendYTDB3 ActiveLearnerYTD3 using "${Results}/FTActiveLearn_Lag3.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues $>$ 0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Controls include year FE and contry FE. Data from the internal talent matching platform. \emph{Number of skills $\geq$ 3} equals to 1 if the worker has more than 3 skills in the platform. \emph{Completed items $\geq$ 5} equals to 1 if the worker has completed more than 5 items in the platform. \emph{Shared items with colleagues $>$ 0} equals to 1 if the worker has done items with colleagues. \emph{Active learner} equals to 1 if the worker meets all the above three conditions." "\end{tablenotes}")


esttab NumSkillsB4 NumCompletedYTDB4 NumRecommendYTDB4 ActiveLearnerYTD4 using "${Results}/FTActiveLearn_Lag4.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues $>$ 0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Controls include year FE and contry FE. Data from the internal talent matching platform. \emph{Number of skills $\geq$ 3} equals to 1 if the worker has more than 3 skills in the platform. \emph{Completed items $\geq$ 5} equals to 1 if the worker has completed more than 5 items in the platform. \emph{Shared items with colleagues $>$ 0} equals to 1 if the worker has done items with colleagues. \emph{Active learner} equals to 1 if the worker meets all the above three conditions." "\end{tablenotes}")


esttab NumSkillsB5 NumCompletedYTDB5 NumRecommendYTDB5 ActiveLearnerYTD5 using "${Results}/FTActiveLearn_Lag5.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    stats(cmean N, labels("Mean, low-flyer" "N") fmt(%9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues $>$ 0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Controls include year FE and contry FE. Data from the internal talent matching platform. \emph{Number of skills $\geq$ 3} equals to 1 if the worker has more than 3 skills in the platform. \emph{Completed items $\geq$ 5} equals to 1 if the worker has completed more than 5 items in the platform. \emph{Shared items with colleagues $>$ 0} equals to 1 if the worker has done items with colleagues. \emph{Active learner} equals to 1 if the worker meets all the above three conditions." "\end{tablenotes}")