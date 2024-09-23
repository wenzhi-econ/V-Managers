/* 
This do file gets the HF measure for each individual, so that they can be merged with the skills data in the next step to contrast different skills by H-type managers and L-type managers.

Input:
    "${FinalData}/AllSnapshotMCulture.dta"

Output:
    "${TempData}/temp_HFMeasure.dta"

RA: WWZ 
Time: 2024-09-22
*/

use "${FinalData}/AllSnapshotMCulture.dta", clear 
keep IDlse EarlyAge
duplicates drop 

save "${TempData}/temp_HFMeasure.dta", replace


use "${TempData}/temp_HFMeasure.dta", clear 
merge 1:1 IDlse using "${TempData}/temp_SkillsAfterLDA.dta", keep(match) nogenerate

label variable Topic1_2 "Talent management skills"
label variable Topic2_2 "Strategy management skills"
label variable Topic1_3 "Project management skills"
label variable Topic2_3 "Strategy management skills"
label variable Topic3_3 "Talent management skills"
label variable Topic1_5 "Project management skills"
label variable Topic2_5 "Strategy management skills"
label variable Topic3_5 "Specific management skills 1"
label variable Topic4_5 "Specific management skills 2"
label variable Topic5_5 "Talent management skills"

balancetable (mean if EarlyAge == 0) (mean if EarlyAge == 1) (diff EarlyAge if EarlyAge != .) Topic1_2 Topic2_2 using "${Results}/SkillsAfterLDA_HvsL.tex", ///
    replace nonumbers nohead varlabels vce(robust) ///
    prehead("\begin{tabular}{l*{3}c}" "\hline\hline \\ [-1.5ex]" "& \multicolumn{3}{c}{{\bf Panel (a): 2-Topics LDA}} \\ [5pt]" "\hline" "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "& \multicolumn{1}{c}{L-type} & \multicolumn{1}{c}{H-type} & \multicolumn{1}{c}{Difference} \\""\hline" ) ///
    posthead("") ///
    postfoot("\hline \\ [-1.5ex]")

balancetable (mean if EarlyAge == 0) (mean if EarlyAge == 1) (diff EarlyAge if EarlyAge != .) Topic1_3 Topic2_3 Topic3_3 using "${Results}/SkillsAfterLDA_HvsL.tex", ///
    append nonumbers nohead varlabels vce(robust) ///
    prehead("& \multicolumn{3}{c}{{\bf Panel (b): 3-Topics LDA}} \\ [5pt]" "\hline" "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "& \multicolumn{1}{c}{L-type} & \multicolumn{1}{c}{H-type} & \multicolumn{1}{c}{Difference} \\""\hline" ) ///
    posthead("") ///
    postfoot("\hline \\ [-1.5ex]")

balancetable (mean if EarlyAge == 0) (mean if EarlyAge == 1) (diff EarlyAge if EarlyAge != .) Topic1_5 Topic2_5 Topic3_5 Topic4_5 Topic5_5 using "${Results}/SkillsAfterLDA_HvsL.tex", ///
    append nonumbers nohead varlabels vce(robust) ///
    prehead("& \multicolumn{3}{c}{{\bf Panel (c): 5-Topics LDA}} \\ [5pt]" "\hline" "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "& \multicolumn{1}{c}{L-type} & \multicolumn{1}{c}{H-type} & \multicolumn{1}{c}{Difference} \\""\hline" ) ///
    posthead("") ///
    postfoot("\hline\hline \end{tabular}")






