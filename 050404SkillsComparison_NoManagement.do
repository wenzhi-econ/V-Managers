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
merge 1:1 IDlse using "${TempData}/temp_SkillsAfterLDA_NoM.dta", keep(match) nogenerate


label variable Topic1_3_NoM "Business skills"
label variable Topic2_3_NoM "Specific skills"
label variable Topic3_3_NoM "Talent management skills"

balancetable (mean if EarlyAge == 0) (mean if EarlyAge == 1) (diff EarlyAge if EarlyAge != .) Topic1_3_NoM Topic2_3_NoM Topic3_3_NoM using "${Results}/SkillsAfterLDA_HvsL_NoM.tex", ///
    replace nonumbers nohead varlabels vce(robust) ///
    prehead("\begin{tabular}{l*{3}c}" "\hline\hline \\ [-1.5ex]" "\hline" "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "& \multicolumn{1}{c}{L-type} & \multicolumn{1}{c}{H-type} & \multicolumn{1}{c}{Difference} \\""\hline" ) ///
    posthead("") ///
    postfoot("\hline\hline \end{tabular}")







