/* 
This do file combines workers' outcomes and a set of event dummies based on three measures.
    EarlyAgeM
    HF2M
    HF2SM

Input:
    "${TempData}/01WorkersOutcomes.dta"
    "${TempData}/02EventStudyDummies_EarlyAgeM.dta"
    "${TempData}/02EventStudyDummies_HF2M_HF2SM.dta"

Output:
    "${TempData}/03MainOutcomesInEventStudies_EarlyAgeM_HF2M_HF2SM.dta"

RA: WWZ 
Time: 2024-10-08
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct the main dataset used in event studies 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/01WorkersOutcomes.dta", clear 

merge 1:1 IDlse YearMonth using "${TempData}/02EventStudyDummies_EarlyAgeM.dta", generate(_merge_outcome_EarlyAgeM)
merge 1:1 IDlse YearMonth using "${TempData}/02EventStudyDummies_HF2M_HF2SM.dta", generate(_merge_outcome_HF2M_HF2SM)

order IDlse YearMonth IDlseMHR ///
    EarlyAgeM HF2M HF2SM ///
    FT_Mngr_both_WL2 HF2_Mngr_both_WL2 HF2S_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    HF2_Never_ChangeM HF2_Rel_Time HF2_LtoL HF2_LtoH HF2_HtoH HF2_HtoL ///
    HF2S_Never_ChangeM HF2S_Rel_Time HF2S_LtoL HF2S_LtoH HF2S_HtoH HF2S_HtoL ///
    TransferSJVC TransferFuncC LogPayBonus LogPay LogBonus ChangeSalaryGradeC ///
    StandardJob Func SalaryGrade Office SubFunc Org4 OfficeCode Pay Bonus Benefit Package

save "${TempData}/03MainOutcomesInEventStudies_EarlyAgeM_HF2M_HF2SM.dta", replace

