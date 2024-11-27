/* 
This do file combines workers' outcomes and a set of event dummies based on managers' quality measure -- "EarlyAgeM".

Input:
    "${TempData}/01WorkersOutcomes.dta" <== constructed in 0101 do file 
    "${TempData}/03EventStudyDummies_EarlyAgeM.dta" <== constructed in 0103_01 do file 

Output:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta"

RA: WWZ 
Time: 2024-10-08
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct the main dataset used in event studies 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/01WorkersOutcomes.dta", clear 

merge 1:1 IDlse YearMonth using "${TempData}/03EventStudyDummies_EarlyAgeM.dta", generate(_merge_outcome_EarlyAgeM)

order IDlse YearMonth IDlseMHR ///
    EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    TransferSJVC TransferFuncC LogPayBonus LogPay LogBonus ChangeSalaryGradeC ///
    StandardJob Func SalaryGrade Office SubFunc Org4 OfficeCode Pay Bonus Benefit Package

save "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", replace

