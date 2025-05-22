/* 
This do file generates relevant event dummies used for event studies.
The high-flyer measures are FE50 and FE33.

Input:
    "${TempData}/FinalAnalysisSample.dta"                                <== created in 0103_03 do file 

Output:
    "${TempData}/FinalAnalysisSample_Simplified_WithMngrFEBasedMeasures" <== main output 

RA: WWZ 
Time: 2025-05-13
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. process the estimated fixed effects datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/2402HFMeasure_MngrFEBased.dta", clear 
keep IDMngr_Pre IDMngr_Post FE50_Pre FE50_Post FE33_Pre FE33_Post PayFE_Pre PayFE_Post
keep if FE50_Pre!=.
duplicates drop 
save "${TempData}/2402HFMeasure_MngrFEBased_FEForMerge.dta", replace    

use "${TempData}/2402HFMeasure_MngrFEBased.dta", clear 
keep IDMngr_Pre IDMngr_Post WL1FE50_Pre WL1FE50_Post WL1FE33_Pre WL1FE33_Post WL1_PayFE_Pre WL1_PayFE_Post 
keep if WL1FE50_Pre!=.
duplicates drop 
save "${TempData}/2402HFMeasure_MngrFEBased_WL1FEForMerge.dta", replace    

use "${TempData}/2402HFMeasure_MngrFEBased.dta", clear 
keep IDMngr_Pre IDMngr_Post SJ50_Pre SJ50_Post SJ33_Pre SJ33_Post SJVCFE_Pre SJVCFE_Post
keep if SJ50_Pre!=.
duplicates drop 
save "${TempData}/2402HFMeasure_MngrFEBased_SJForMerge.dta", replace    

use "${TempData}/2402HFMeasure_MngrFEBased.dta", clear 
keep IDMngr_Pre IDMngr_Post WL1SJ50_Pre WL1SJ50_Post WL1SJ33_Pre WL1SJ33_Post WL1_SJVCFE_Pre WL1_SJVCFE_Post
keep if WL1SJ50_Pre!=.
duplicates drop 
save "${TempData}/2402HFMeasure_MngrFEBased_WL1SJForMerge.dta", replace 

use "${TempData}/2402HFMeasure_MngrFEBased.dta", clear 
keep IDMngr_Pre IDMngr_Post CS50_Pre CS50_Post CS33_Pre CS33_Post CSGCFE_Pre CSGCFE_Post
keep if CS50_Pre!=.
duplicates drop 
save "${TempData}/2402HFMeasure_MngrFEBased_CSForMerge.dta", replace 

use "${TempData}/2402HFMeasure_MngrFEBased.dta", clear 
keep IDMngr_Pre IDMngr_Post WL1CS50_Pre WL1CS50_Post WL1CS33_Pre WL1CS33_Post WL1_CSGCFE_Pre WL1_CSGCFE_Post
keep if WL1CS50_Pre!=.
duplicates drop 
save "${TempData}/2402HFMeasure_MngrFEBased_WL1CSForMerge.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge the estimated fixed effects datasets into the main dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 
order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post

merge m:1 IDMngr_Post using "${TempData}/2402HFMeasure_MngrFEBased_FEForMerge.dta",    keepusing(FE50_Post FE33_Post PayFE_Post)            keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/2402HFMeasure_MngrFEBased_FEForMerge.dta",    keepusing(FE50_Pre FE33_Pre PayFE_Pre)               keep(match master) nogenerate
merge m:1 IDMngr_Post using "${TempData}/2402HFMeasure_MngrFEBased_WL1FEForMerge.dta", keepusing(WL1FE50_Post WL1FE33_Post WL1_PayFE_Post)  keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/2402HFMeasure_MngrFEBased_WL1FEForMerge.dta", keepusing(WL1FE50_Pre WL1FE33_Pre WL1_PayFE_Pre)     keep(match master) nogenerate
merge m:1 IDMngr_Post using "${TempData}/2402HFMeasure_MngrFEBased_SJForMerge.dta",    keepusing(SJ50_Post SJ33_Post SJVCFE_Post)           keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/2402HFMeasure_MngrFEBased_SJForMerge.dta",    keepusing(SJ50_Pre SJ33_Pre SJVCFE_Pre)              keep(match master) nogenerate
merge m:1 IDMngr_Post using "${TempData}/2402HFMeasure_MngrFEBased_WL1SJForMerge.dta", keepusing(WL1SJ50_Post WL1SJ33_Post WL1_SJVCFE_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/2402HFMeasure_MngrFEBased_WL1SJForMerge.dta", keepusing(WL1SJ50_Pre WL1SJ33_Pre WL1_SJVCFE_Pre)    keep(match master) nogenerate
merge m:1 IDMngr_Post using "${TempData}/2402HFMeasure_MngrFEBased_CSForMerge.dta",    keepusing(CS50_Post CS33_Post CSGCFE_Post)           keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/2402HFMeasure_MngrFEBased_CSForMerge.dta",    keepusing(CS50_Pre CS33_Pre CSGCFE_Pre)              keep(match master) nogenerate
merge m:1 IDMngr_Post using "${TempData}/2402HFMeasure_MngrFEBased_WL1CSForMerge.dta", keepusing(WL1CS50_Post WL1CS33_Post WL1_CSGCFE_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/2402HFMeasure_MngrFEBased_WL1CSForMerge.dta", keepusing(WL1CS50_Pre WL1CS33_Pre WL1_CSGCFE_Pre)    keep(match master) nogenerate

sort  IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach measure in FE50 FE33 WL1FE50 WL1FE33 SJ50 SJ33 WL1SJ50 WL1SJ33 CS50 CS33 WL1CS50 WL1CS33 {
    generate `measure'_LtoL = .
    replace  `measure'_LtoL = 1 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_LtoL = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_LtoL = 0 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_LtoL = 0 if `measure'_Pre==1 & `measure'_Post==0

    generate `measure'_LtoH = .
    replace  `measure'_LtoH = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_LtoH = 1 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_LtoH = 0 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_LtoH = 0 if `measure'_Pre==1 & `measure'_Post==0

    generate `measure'_HtoH = .
    replace  `measure'_HtoH = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_HtoH = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_HtoH = 1 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_HtoH = 0 if `measure'_Pre==1 & `measure'_Post==0

    generate `measure'_HtoL = .
    replace  `measure'_HtoL = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_HtoL = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_HtoL = 0 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_HtoL = 1 if `measure'_Pre==1 & `measure'_Post==0
}

foreach measure in FE50 FE33 WL1FE50 WL1FE33 SJ50 SJ33 WL1SJ50 WL1SJ33 CS50 CS33 WL1CS50 WL1CS33 {
    label variable `measure'_LtoL "LtoL event group (based on `measure' measure)"
    label variable `measure'_LtoH "LtoH event group (based on `measure' measure)"
    label variable `measure'_HtoH "HtoH event group (based on `measure' measure)"
    label variable `measure'_HtoL "HtoL event group (based on `measure' measure)"
}

foreach measure in FE50 FE33 WL1FE50 WL1FE33 SJ50 SJ33 WL1SJ50 WL1SJ33 CS50 CS33 WL1CS50 WL1CS33 {
    generate `measure'_LtoL_X_Post = `measure'_LtoL * Post_Event
    generate `measure'_LtoH_X_Post = `measure'_LtoH * Post_Event
    generate `measure'_HtoH_X_Post = `measure'_HtoH * Post_Event
    generate `measure'_HtoL_X_Post = `measure'_HtoL * Post_Event
}

foreach measure in PayFE WL1_PayFE SJVCFE WL1_SJVCFE CSGCFE WL1_CSGCFE {
    generate `measure'_Diff = `measure'_Post - `measure'_Pre

    generate `measure'_Diff_sign = sign(`measure'_Diff)

    generate `measure'_Increase = .
    replace  `measure'_Increase = 0 if `measure'_Diff_sign==-1
    replace  `measure'_Increase = `measure'_Post - `measure'_Pre if `measure'_Diff_sign==1
    
    generate `measure'_Decrease = .
    replace  `measure'_Decrease = 0 if `measure'_Diff_sign==1
    replace  `measure'_Decrease = `measure'_Pre - `measure'_Post if `measure'_Diff_sign==-1
}


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. obtain a final version dataset for all event study results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth TransferSJVC IDlseMHR ChangeSalaryGradeC ONETDistC LogPayBonus LogPay LogBonus ///
    Event_Time Rel_Time Post_Event ///
    IDMngr_Pre IDMngr_Post PayFE_* WL1_PayFE_* SJVCFE_* WL1_SJVCFE_* CSGCFE_* WL1_CSGCFE_* ///
    CA30_* FE50_* FE33_* WL1FE50_* WL1FE33_* SJ50_* SJ33_* WL1SJ50_* WL1SJ33_* CS50_* CS33_* WL1CS50_* WL1CS33_*

order IDlse YearMonth TransferSJVC IDlseMHR ChangeSalaryGradeC ONETDistC LogPayBonus LogPay LogBonus ///
    Event_Time Rel_Time Post_Event ///
    IDMngr_Pre IDMngr_Post PayFE_* WL1_PayFE_* SJVCFE_* WL1_SJVCFE_* CSGCFE_* WL1_CSGCFE_* ///
    CA30_* FE50_* FE33_* WL1FE50_* WL1FE33_* SJ50_* SJ33_* WL1SJ50_* WL1SJ33_* CS50_* CS33_* WL1CS50_* WL1CS33_*

compress
save "${TempData}/FinalAnalysisSample_Simplified_WithMngrFEBasedMeasures.dta", replace
