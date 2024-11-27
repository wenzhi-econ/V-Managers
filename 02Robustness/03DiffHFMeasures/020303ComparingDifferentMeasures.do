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

use "${TempData}/03MainOutcomesInEventStudies_EarlyAgeM_HF2M_HF2SM.dta", clear 

keep  IDlse YearMonth IDlseMHR FT_Rel_Time FT_Mngr_both_WL2 EarlyAgeM HF2M HF2SM 
order IDlse YearMonth IDlseMHR FT_Rel_Time FT_Mngr_both_WL2 EarlyAgeM HF2M HF2SM 

keep if FT_Mngr_both_WL2==1
keep if inrange(FT_Rel_Time, -1, 0)

drop IDlse YearMonth
duplicates drop 

summarize EarlyAgeM
summarize HF2M
summarize HF2SM

correlate EarlyAgeM HF2M HF2SM


