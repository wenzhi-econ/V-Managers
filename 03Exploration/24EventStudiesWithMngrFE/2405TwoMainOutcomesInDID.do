/* 
This do file runs DID-style regressions using manager fixed effects based measures.

RA: WWZ 
Time: 2025-05-16
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. discrete HF measures
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample_Simplified_WithMngrFEBasedMeasures.dta", clear 

/* label variable Post_Event "Post-event"
label variable FE50_LtoH_X_Post "LtoH $\times$ post-event"
label variable FE50_HtoH_X_Post "HtoH $\times$ post-event"
label variable FE50_HtoL_X_Post "HtoL $\times$ post-event"
label variable FE33_LtoH_X_Post "LtoH $\times$ post-event"
label variable FE33_HtoH_X_Post "HtoH $\times$ post-event"
label variable FE33_HtoL_X_Post "HtoL $\times$ post-event"
label variable WL1FE50_LtoH_X_Post "LtoH $\times$ post-event"
label variable WL1FE50_HtoH_X_Post "HtoH $\times$ post-event"
label variable WL1FE50_HtoL_X_Post "HtoL $\times$ post-event"
label variable WL1FE33_LtoH_X_Post "LtoH $\times$ post-event"
label variable WL1FE33_HtoH_X_Post "HtoH $\times$ post-event"
label variable WL1FE33_HtoL_X_Post "HtoL $\times$ post-event"
label variable SJ50_LtoH_X_Post "LtoH $\times$ post-event"
label variable SJ50_HtoH_X_Post "HtoH $\times$ post-event"
label variable SJ50_HtoL_X_Post "HtoL $\times$ post-event"
label variable SJ33_LtoH_X_Post "LtoH $\times$ post-event"
label variable SJ33_HtoH_X_Post "HtoH $\times$ post-event"
label variable SJ33_HtoL_X_Post "HtoL $\times$ post-event"
label variable WL1SJ50_LtoH_X_Post "LtoH $\times$ post-event"
label variable WL1SJ50_HtoH_X_Post "HtoH $\times$ post-event"
label variable WL1SJ50_HtoL_X_Post "HtoL $\times$ post-event"
label variable WL1SJ33_LtoH_X_Post "LtoH $\times$ post-event"
label variable WL1SJ33_HtoH_X_Post "HtoH $\times$ post-event"
label variable WL1SJ33_HtoL_X_Post "HtoL $\times$ post-event"
label variable CS50_LtoH_X_Post "LtoH $\times$ post-event"
label variable CS50_HtoH_X_Post "HtoH $\times$ post-event"
label variable CS50_HtoL_X_Post "HtoL $\times$ post-event"
label variable CS33_LtoH_X_Post "LtoH $\times$ post-event"
label variable CS33_HtoH_X_Post "HtoH $\times$ post-event"
label variable CS33_HtoL_X_Post "HtoL $\times$ post-event"
label variable WL1CS50_LtoH_X_Post "LtoH $\times$ post-event"
label variable WL1CS50_HtoH_X_Post "HtoH $\times$ post-event"
label variable WL1CS50_HtoL_X_Post "HtoL $\times$ post-event"
label variable WL1CS33_LtoH_X_Post "LtoH $\times$ post-event"
label variable WL1CS33_HtoH_X_Post "HtoH $\times$ post-event"
label variable WL1CS33_HtoL_X_Post "HtoL $\times$ post-event" */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. DID dummies in the regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global FE50_dummies Post_Event FE50_LtoH_X_Post FE50_HtoH_X_Post FE50_HtoL_X_Post 
global FE33_dummies Post_Event FE33_LtoH_X_Post FE33_HtoH_X_Post FE33_HtoL_X_Post 
global WL1FE50_dummies Post_Event WL1FE50_LtoH_X_Post WL1FE50_HtoH_X_Post WL1FE50_HtoL_X_Post 
global WL1FE33_dummies Post_Event WL1FE33_LtoH_X_Post WL1FE33_HtoH_X_Post WL1FE33_HtoL_X_Post 

global SJ50_dummies Post_Event SJ50_LtoH_X_Post SJ50_HtoH_X_Post SJ50_HtoL_X_Post 
global SJ33_dummies Post_Event SJ33_LtoH_X_Post SJ33_HtoH_X_Post SJ33_HtoL_X_Post 
global WL1SJ50_dummies Post_Event WL1SJ50_LtoH_X_Post WL1SJ50_HtoH_X_Post WL1SJ50_HtoL_X_Post 
global WL1SJ33_dummies Post_Event WL1SJ33_LtoH_X_Post WL1SJ33_HtoH_X_Post WL1SJ33_HtoL_X_Post 

global CS50_dummies Post_Event CS50_LtoH_X_Post CS50_HtoH_X_Post CS50_HtoL_X_Post 
global CS33_dummies Post_Event CS33_LtoH_X_Post CS33_HtoH_X_Post CS33_HtoL_X_Post 
global WL1CS50_dummies Post_Event WL1CS50_LtoH_X_Post WL1CS50_HtoH_X_Post WL1CS50_HtoL_X_Post 
global WL1CS33_dummies Post_Event WL1CS33_LtoH_X_Post WL1CS33_HtoH_X_Post WL1CS33_HtoL_X_Post 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. run regressions on lateral moves 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe TransferSJVC ${FE50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_FE50
reghdfe TransferSJVC ${WL1FE50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_WL1FE50
reghdfe TransferSJVC ${FE33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_FE33
reghdfe TransferSJVC ${WL1FE33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_WL1FE33

reghdfe TransferSJVC ${SJ50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_SJ50
reghdfe TransferSJVC ${WL1SJ50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_WL1SJ50
reghdfe TransferSJVC ${SJ33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_SJ33
reghdfe TransferSJVC ${WL1SJ33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_WL1SJ33

reghdfe TransferSJVC ${CS50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_CS50
reghdfe TransferSJVC ${WL1CS50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_WL1CS50
reghdfe TransferSJVC ${CS33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_CS33
reghdfe TransferSJVC ${WL1CS33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Lateral_WL1CS33

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. run regressions on salary grade increase 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe ChangeSalaryGradeC ${FE50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_FE50
reghdfe ChangeSalaryGradeC ${WL1FE50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_WL1FE50
reghdfe ChangeSalaryGradeC ${FE33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_FE33
reghdfe ChangeSalaryGradeC ${WL1FE33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_WL1FE33

reghdfe ChangeSalaryGradeC ${SJ50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_SJ50
reghdfe ChangeSalaryGradeC ${WL1SJ50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_WL1SJ50
reghdfe ChangeSalaryGradeC ${SJ33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_SJ33
reghdfe ChangeSalaryGradeC ${WL1SJ33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_WL1SJ33

reghdfe ChangeSalaryGradeC ${CS50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_CS50
reghdfe ChangeSalaryGradeC ${WL1CS50_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_WL1CS50
reghdfe ChangeSalaryGradeC ${CS33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_CS33
reghdfe ChangeSalaryGradeC ${WL1CS33_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Vertical_WL1CS33

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. store results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

label variable Post_Event "Post_Event"

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{FE50} & \multicolumn{1}{c}{FE33} & \multicolumn{1}{c}{SJ50} & \multicolumn{1}{c}{SJ33} & \multicolumn{1}{c}{CS50} & \multicolumn{1}{c}{CS33} \\"
global latex_outcome      "& \multicolumn{6}{c}{Outcome: $\mathtt{TransferSJVC}$} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/007EventStudiesWithMngrFEBasedMeasures/Outcome1_TransferSJVC_Type1_FE.tex"

esttab Lateral_FE50 Lateral_FE33 Lateral_SJ50 Lateral_SJ33 Lateral_CS50 Lateral_CS33 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(Post_Event FE50_LtoH_X_Post FE50_HtoH_X_Post FE50_HtoL_X_Post FE33_LtoH_X_Post FE33_HtoH_X_Post FE33_HtoL_X_Post SJ50_LtoH_X_Post SJ50_HtoH_X_Post SJ50_HtoL_X_Post SJ33_LtoH_X_Post SJ33_HtoH_X_Post SJ33_HtoL_X_Post CS50_LtoH_X_Post CS50_HtoH_X_Post CS50_HtoL_X_Post CS33_LtoH_X_Post CS33_HtoH_X_Post CS33_HtoL_X_Post) order(Post_Event FE50_LtoH_X_Post FE50_HtoH_X_Post FE50_HtoL_X_Post FE33_LtoH_X_Post FE33_HtoH_X_Post FE33_HtoL_X_Post SJ50_LtoH_X_Post SJ50_HtoH_X_Post SJ50_HtoL_X_Post SJ33_LtoH_X_Post SJ33_HtoH_X_Post SJ33_HtoL_X_Post CS50_LtoH_X_Post CS50_HtoH_X_Post CS50_HtoL_X_Post CS33_LtoH_X_Post CS33_HtoH_X_Post CS33_HtoL_X_Post) ///
    stats(N, labels("N") fmt(%9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_outcome}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")


global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{WL1FE50} & \multicolumn{1}{c}{WL1FE33} & \multicolumn{1}{c}{WL1SJ50} & \multicolumn{1}{c}{WL1SJ33} & \multicolumn{1}{c}{WL1CS50} & \multicolumn{1}{c}{WL1CS33} \\"
global latex_outcome      "& \multicolumn{6}{c}{Outcome: $\mathtt{TransferSJVC}$} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/007EventStudiesWithMngrFEBasedMeasures/Outcome1_TransferSJVC_Type2_WL1FE.tex"

esttab Lateral_WL1FE50 Lateral_WL1FE33 Lateral_WL1SJ50 Lateral_WL1SJ33 Lateral_WL1CS50 Lateral_WL1CS33 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(Post_Event WL1FE50_LtoH_X_Post WL1FE50_HtoH_X_Post WL1FE50_HtoL_X_Post WL1FE33_LtoH_X_Post WL1FE33_HtoH_X_Post WL1FE33_HtoL_X_Post WL1SJ50_LtoH_X_Post WL1SJ50_HtoH_X_Post WL1SJ50_HtoL_X_Post WL1SJ33_LtoH_X_Post WL1SJ33_HtoH_X_Post WL1SJ33_HtoL_X_Post WL1CS50_LtoH_X_Post WL1CS50_HtoH_X_Post WL1CS50_HtoL_X_Post WL1CS33_LtoH_X_Post WL1CS33_HtoH_X_Post WL1CS33_HtoL_X_Post) order(Post_Event WL1FE50_LtoH_X_Post WL1FE50_HtoH_X_Post WL1FE50_HtoL_X_Post WL1FE33_LtoH_X_Post WL1FE33_HtoH_X_Post WL1FE33_HtoL_X_Post WL1SJ50_LtoH_X_Post WL1SJ50_HtoH_X_Post WL1SJ50_HtoL_X_Post WL1SJ33_LtoH_X_Post WL1SJ33_HtoH_X_Post WL1SJ33_HtoL_X_Post WL1CS50_LtoH_X_Post WL1CS50_HtoH_X_Post WL1CS50_HtoL_X_Post WL1CS33_LtoH_X_Post WL1CS33_HtoH_X_Post WL1CS33_HtoL_X_Post) ///
    stats(N, labels("N") fmt(%9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_outcome}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{FE50} & \multicolumn{1}{c}{FE33} & \multicolumn{1}{c}{SJ50} & \multicolumn{1}{c}{SJ33} & \multicolumn{1}{c}{CS50} & \multicolumn{1}{c}{CS33} \\"
global latex_outcome      "& \multicolumn{6}{c}{Outcome: $\mathtt{ChangeSalaryGradeC}$} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/007EventStudiesWithMngrFEBasedMeasures/Outcome2_ChangeSalaryGradeC_Type1_FE.tex"

esttab Vertical_FE50 Vertical_FE33 Vertical_SJ50 Vertical_SJ33 Vertical_CS50 Vertical_CS33 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(Post_Event FE50_LtoH_X_Post FE50_HtoH_X_Post FE50_HtoL_X_Post FE33_LtoH_X_Post FE33_HtoH_X_Post FE33_HtoL_X_Post SJ50_LtoH_X_Post SJ50_HtoH_X_Post SJ50_HtoL_X_Post SJ33_LtoH_X_Post SJ33_HtoH_X_Post SJ33_HtoL_X_Post CS50_LtoH_X_Post CS50_HtoH_X_Post CS50_HtoL_X_Post CS33_LtoH_X_Post CS33_HtoH_X_Post CS33_HtoL_X_Post) order(Post_Event FE50_LtoH_X_Post FE50_HtoH_X_Post FE50_HtoL_X_Post FE33_LtoH_X_Post FE33_HtoH_X_Post FE33_HtoL_X_Post SJ50_LtoH_X_Post SJ50_HtoH_X_Post SJ50_HtoL_X_Post SJ33_LtoH_X_Post SJ33_HtoH_X_Post SJ33_HtoL_X_Post CS50_LtoH_X_Post CS50_HtoH_X_Post CS50_HtoL_X_Post CS33_LtoH_X_Post CS33_HtoH_X_Post CS33_HtoL_X_Post) ///
    stats(N, labels("N") fmt(%9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_outcome}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")


global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{WL1FE50} & \multicolumn{1}{c}{WL1FE33} & \multicolumn{1}{c}{WL1SJ50} & \multicolumn{1}{c}{WL1SJ33} & \multicolumn{1}{c}{WL1CS50} & \multicolumn{1}{c}{WL1CS33} \\"
global latex_outcome      "& \multicolumn{6}{c}{Outcome: $\mathtt{ChangeSalaryGradeC}$} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/007EventStudiesWithMngrFEBasedMeasures/Outcome2_ChangeSalaryGradeC_Type2_WL1FE.tex"

esttab Vertical_WL1FE50 Vertical_WL1FE33 Vertical_WL1SJ50 Vertical_WL1SJ33 Vertical_WL1CS50 Vertical_WL1CS33 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(Post_Event WL1FE50_LtoH_X_Post WL1FE50_HtoH_X_Post WL1FE50_HtoL_X_Post WL1FE33_LtoH_X_Post WL1FE33_HtoH_X_Post WL1FE33_HtoL_X_Post WL1SJ50_LtoH_X_Post WL1SJ50_HtoH_X_Post WL1SJ50_HtoL_X_Post WL1SJ33_LtoH_X_Post WL1SJ33_HtoH_X_Post WL1SJ33_HtoL_X_Post WL1CS50_LtoH_X_Post WL1CS50_HtoH_X_Post WL1CS50_HtoL_X_Post WL1CS33_LtoH_X_Post WL1CS33_HtoH_X_Post WL1CS33_HtoL_X_Post) order(Post_Event WL1FE50_LtoH_X_Post WL1FE50_HtoH_X_Post WL1FE50_HtoL_X_Post WL1FE33_LtoH_X_Post WL1FE33_HtoH_X_Post WL1FE33_HtoL_X_Post WL1SJ50_LtoH_X_Post WL1SJ50_HtoH_X_Post WL1SJ50_HtoL_X_Post WL1SJ33_LtoH_X_Post WL1SJ33_HtoH_X_Post WL1SJ33_HtoL_X_Post WL1CS50_LtoH_X_Post WL1CS50_HtoH_X_Post WL1CS50_HtoL_X_Post WL1CS33_LtoH_X_Post WL1CS33_HtoH_X_Post WL1CS33_HtoL_X_Post) ///
    stats(N, labels("N") fmt(%9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_outcome}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")
