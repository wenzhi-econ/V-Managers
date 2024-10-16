/* 
This do file combines workers' outcomes and a set of event dummies.

RA: WWZ 
Time: 2024-10-08
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. self-constructed dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/01WorkersOutcomes.dta", clear 

merge 1:1 IDlse YearMonth using "${TempData}/04EventStudyDummies_TwoNewHFMeasures.dta", generate(_merge_outcome_eventdummies)

order IDlse YearMonth IDlseMHR ///
    HF2M HF3M ///
    HF2_Rel_Time HF2_Mngr_both_WL2 HF2_LtoL HF2_LtoH HF2_HtoH HF2_HtoL HF2_Never_ChangeM ///
    HF3_Rel_Time HF3_Mngr_both_WL2 HF3_LtoL HF3_LtoH HF3_HtoH HF3_HtoL HF3_Never_ChangeM ///
    TransferSJVC TransferFuncC LogPayBonus LogPay LogBonus ChangeSalaryGradeC ///
    StandardJob Func SalaryGrade Office SubFunc Org4 OfficeCode Pay Bonus Benefit Package

/* drop if _merge_outcome_eventdummies == 1 */
    //&? No event information, mostly likely because missing manager id. 

save "${TempData}/05MainOutcomesInEventStudies_TwoNewHFMeasures.dta", replace