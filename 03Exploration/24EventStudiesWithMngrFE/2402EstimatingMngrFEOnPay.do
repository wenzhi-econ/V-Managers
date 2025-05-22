/* 
This do file estimates manager fixed effects on their subordinates' pay outcomes.

Input:
    "${TempData}/2401EmployeePanelUsedForMngrFE.dta"  <== created in 2401 do file 

RA: WWZ 
Time: 2025-05-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. main programs run on cluster 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/2401EmployeePanelUsedForMngrFE.dta", clear 

/* keep if inrange(_n, 1, 10000) */

reghdfe LogPayBonus i.YearMonth, absorb(IDlse PayFE=IDlseMHR)
reghdfe LogPayBonus i.YearMonth if WL==1, absorb(IDlse WL1_PayFE=IDlseMHR)

reghdfe TransferSJVC i.YearMonth, absorb(IDlse SJVCFE=IDlseMHR)
reghdfe TransferSJVC i.YearMonth if WL==1, absorb(IDlse WL1_SJVCFE=IDlseMHR)

reghdfe ChangeSalaryGradeC i.YearMonth, absorb(IDlse CSGCFE=IDlseMHR)
reghdfe ChangeSalaryGradeC i.YearMonth if WL==1, absorb(IDlse WL1_CSGCFE=IDlseMHR)

keep IDlseMHR PayFE WL1_PayFE SJVCFE WL1_SJVCFE CSGCFE WL1_CSGCFE
duplicates drop 
    //&? a cross-section of event managers

foreach var in PayFE WL1_PayFE SJVCFE WL1_SJVCFE CSGCFE WL1_CSGCFE {
    summarize `var' if `var'!=., detail 
    global median = r(p50)
    generate `var'50 = (`var' >= ${median}) if `var'!=.

    xtile temp_`var' = `var' if `var'!=., nquantiles(3)
    generate `var'33 = . 
    replace  `var'33 = 0 if temp_`var'==1 | temp_`var'==2 
    replace  `var'33 = 1 if temp_`var'==3
}

rename (PayFE50 PayFE33 SJVCFE50 SJVCFE33 CSGCFE50 CSGCFE33) (FE50 FE33 SJ50 SJ33 CS50 CS33)
rename (WL1_PayFE50 WL1_PayFE33 WL1_SJVCFE50 WL1_SJVCFE33 WL1_CSGCFE50 WL1_CSGCFE33) (WL1FE50 WL1FE33 WL1SJ50 WL1SJ33 WL1CS50 WL1CS33)

keep IDlseMHR ///
    PayFE WL1_PayFE SJVCFE WL1_SJVCFE CSGCFE WL1_CSGCFE ///
    FE50 FE33 WL1FE50 WL1FE33 SJ50 SJ33 ///
    WL1SJ50 WL1SJ33 CS50 CS33 WL1CS50 WL1CS33
duplicates drop

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. modify the dataset for the convenience of merge  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate long IDMngr_Pre  = IDlseMHR
generate long IDMngr_Post = IDlseMHR
foreach var in PayFE WL1_PayFE SJVCFE WL1_SJVCFE CSGCFE WL1_CSGCFE {
    generate `var'_Pre  = `var'
    generate `var'_Post = `var'
}
foreach var in FE50 FE33 WL1FE50 WL1FE33 SJ50 SJ33 WL1SJ50 WL1SJ33 CS50 CS33 WL1CS50 WL1CS33 {
    generate `var'_Pre  = `var'
    generate `var'_Post = `var'
}

drop IDlseMHR ///
    PayFE WL1_PayFE SJVCFE WL1_SJVCFE CSGCFE WL1_CSGCFE ///
    FE50 FE33 WL1FE50 WL1FE33 SJ50 SJ33 ///
    WL1SJ50 WL1SJ33 CS50 CS33 WL1CS50 WL1CS33

save "${TempData}/2402HFMeasure_MngrFEBased.dta", replace 
