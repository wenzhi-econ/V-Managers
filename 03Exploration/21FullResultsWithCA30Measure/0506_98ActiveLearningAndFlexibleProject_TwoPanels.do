/* 
This do file produces the active learning and flexible project table in the report.

RA: WWZ 
Time: 2025-05-02
*/

eststo clear 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. active learning panel 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
    //impt: use the analysis sample, i.e., keep only those workers who are in the event studies

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. obtain variables about active learning 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${RawMNEData}/ActiveLearn.dta"
    keep if _merge==3
    drop _merge  

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. keep only relevant variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if CA30_LtoL==1 | CA30_LtoH==1
    //impt: keep only LtoL and LtoH event workers

sort IDlse YearMonth
keep Year YearMonth IDlse Event_Time Rel_Time Post_Event ///
    CA30_LtoL CA30_LtoH IDMngr_Post ///
    Func Office Country Female AgeBand ///
    NumRecommend NumCompleted NumSkills

replace  NumRecommend  = 0 if NumRecommend==.
replace  NumCompleted  = 0 if NumCompleted==.
replace  NumSkills     = 0 if NumSkills   ==.

keep if Post_Event==1
    //impt: keep only post-event observations 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. collapse into employee-year level  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

*!! for a given year, select the largest reported values
collapse ///
    (mean) Event_Time CA30_LtoL CA30_LtoH IDMngr_Post ///
    (last) Func Office Country Female AgeBand ///
    (max) NumRecommend NumCompleted NumSkills ///
    (max) Post_Event, by(IDlse Year)

*!! across years, calculate the average reported values
collapse ///
    (mean) Event_Time CA30_LtoL CA30_LtoH IDMngr_Post ///
    (last) Func Office Country Female AgeBand ///
    (mean) NumRecommend NumCompleted NumSkills ///
    (max) Post_Event, by(IDlse)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. run regressions  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe NumSkills    CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumSkills
    summarize NumSkills if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)

reghdfe NumCompleted CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumCompleted
    summarize NumCompleted if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)

reghdfe NumRecommend CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumRecommend
    summarize NumRecommend if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)

generate NumSkillsB    = (NumSkills>=3) if NumSkills!=.
generate NumCompletedB = (NumCompleted>=5) if NumCompleted!=.
generate NumRecommendB = (NumRecommend>0) if NumRecommend!=.

reghdfe NumSkillsB    CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumSkillsB
    summarize NumSkillsB if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)

reghdfe NumCompletedB CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumCompletedB
    summarize NumCompletedB if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)  

reghdfe NumRecommendB CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumRecommendB
    summarize NumRecommendB if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)

generate NumSkillsB0    = (NumSkills>0) if NumSkills!=.
generate NumCompletedB0 = (NumCompleted>0) if NumCompleted!=.
generate NumRecommendB0 = (NumRecommend>0) if NumRecommend!=.

reghdfe NumSkillsB0    CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumSkillsB0
    summarize NumSkillsB0 if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)

reghdfe NumCompletedB0 CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumCompletedB0
    summarize NumCompletedB0 if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)  

reghdfe NumRecommendB0 CA30_LtoH, absorb(Event_Time Func#Office) vce(cluster IDMngr_Post)
    eststo NumRecommendB0
    summarize NumRecommendB0 if e(sample)==1 & CA30_LtoH==0
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. flexible project panel
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. merge the flexible project dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 
    //impt: focus only on the employees who are in the event study 
merge m:1 IDlse using "${RawMNEData}/FLEX.dta", keep(match) nogenerate 
    //&? the flexible project dataset is a snapshot of the platform information, thus a cross section 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. important sample restrictions  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if Rel_Time==0
    //impt: keep variables at the event time
keep if CA30_LtoL==1 | CA30_LtoH==1
    //&? keep only LtoL and LtoH workers
keep if YearMonthPurpose>=Event_Time
    //impt: the timing of the platform snapshot should be later than the event time 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. relative time from the event to the platform snapshot
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in  CompletedProfileDummy ProjectRolesAppliedDummy NrProjectRolesApplied {
    reghdfe `var' CA30_LtoH, absorb(Event_Time Office#Func) vce(cluster IDMngr_Post)
        eststo `var'
        summarize `var' if CA30_LtoL==1 & e(sample)==1
        estadd scalar cmean = r(mean)
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the regression table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers_A    "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"
global latex_numbers_B    "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"

global latex_titles_A     "& \multicolumn{1}{c}{Profile completed} & \multicolumn{1}{c}{\shortstack{Applied to any \\ project role}}  & \multicolumn{1}{c}{\shortstack{Number of project \\ roles applied}} \\"
global latex_titles_B     "& \multicolumn{1}{c}{\shortstack{Number of \\ skills}} & \multicolumn{1}{c}{\shortstack{Number of \\ completed items}}  & \multicolumn{1}{c}{\shortstack{Number of \\ shared items}} \\"
global latex_panel_A      "\addlinespace[5pt] \multicolumn{3}{c}{\emph{Panel (a): Active learning behavior}} \\ [7pt]"
global latex_panel_B      "\addlinespace[5pt] \multicolumn{3}{c}{\emph{Panel (b): Engagement in flexible projects}} \\ [7pt]"
global latex_file         "${Results}/004ResultsBasedOnCA30/ActiveLearningAndFlexibleProject_CrossSection.tex"

esttab CompletedProfileDummy ProjectRolesAppliedDummy NrProjectRolesApplied using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean r2 N, labels("Mean, LtoL" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}" "${latex_panel_A}") posthead("${latex_numbers_A}" "${latex_titles_A}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_midrule}")

esttab NumSkills NumCompleted NumRecommend using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean r2 N, labels("Mean, LtoL" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_panel_B}") posthead("${latex_numbers_B}" "${latex_titles_B}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")


global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers_A    "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"
global latex_numbers_B    "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"

global latex_titles_A     "& \multicolumn{1}{c}{Profile completed} & \multicolumn{1}{c}{\shortstack{Applied to any \\ project role}}  & \multicolumn{1}{c}{\shortstack{Number of project \\ roles applied}} \\"
global latex_titles_B     "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq 3$}} & \multicolumn{1}{c}{\shortstack{Number of \\ completed items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Number of \\ shared items $>$ 0}} \\"
global latex_panel_A      "\addlinespace[5pt] \multicolumn{3}{c}{\emph{Panel (a): Active learning behavior}} \\ [7pt]"
global latex_panel_B      "\addlinespace[5pt] \multicolumn{3}{c}{\emph{Panel (b): Engagement in flexible projects}} \\ [7pt]"
global latex_file         "${Results}/004ResultsBasedOnCA30/ActiveLearningAndFlexibleProject_CrossSection_Dummy.tex"

esttab CompletedProfileDummy ProjectRolesAppliedDummy NrProjectRolesApplied using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean r2 N, labels("Mean, LtoL" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}" "${latex_panel_A}") posthead("${latex_numbers_A}" "${latex_titles_A}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_midrule}")

esttab NumSkillsB NumCompletedB NumRecommendB using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean r2 N, labels("Mean, LtoL" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_panel_B}") posthead("${latex_numbers_B}" "${latex_titles_B}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")



global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers_A    "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"
global latex_numbers_B    "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"

global latex_titles_A     "& \multicolumn{1}{c}{Profile completed} & \multicolumn{1}{c}{\shortstack{Applied to any \\ project role}}  & \multicolumn{1}{c}{\shortstack{Number of project \\ roles applied}} \\"
global latex_titles_B     "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $> 0$}} & \multicolumn{1}{c}{\shortstack{Number of \\ completed items $> 0$}}  & \multicolumn{1}{c}{\shortstack{Number of \\ shared items $> 0$}} \\"
global latex_panel_A      "\addlinespace[5pt] \multicolumn{3}{c}{\emph{Panel (a): Active learning behavior}} \\ [7pt]"
global latex_panel_B      "\addlinespace[5pt] \multicolumn{3}{c}{\emph{Panel (b): Engagement in flexible projects}} \\ [7pt]"
global latex_file         "${Results}/004ResultsBasedOnCA30/ActiveLearningAndFlexibleProject_CrossSection_Dummy0.tex"

esttab CompletedProfileDummy ProjectRolesAppliedDummy NrProjectRolesApplied using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean r2 N, labels("Mean, LtoL" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}" "${latex_panel_A}") posthead("${latex_numbers_A}" "${latex_titles_A}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_midrule}")

esttab NumSkillsB0 NumCompletedB0 NumRecommendB0 using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) varlabels(CA30_LtoH "LtoH") ///
    stats(cmean r2 N, labels("Mean, LtoL" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_panel_B}") posthead("${latex_numbers_B}" "${latex_titles_B}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")