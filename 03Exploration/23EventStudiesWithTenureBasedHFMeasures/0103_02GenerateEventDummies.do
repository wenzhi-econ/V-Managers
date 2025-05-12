/* 
This do file generates relevant event dummies used for event studies.

Input:
    "${TempData}/FinalFullSample.dta"                   <== created in 0101_01 do file 
    "${TempData}/0103_01CrossSectionalEventWorkers.dta" <== created in 0103_01 do file 

Output:
    "${TempData}/0103_02EventWorkersPanel_WithEventDummies" <== main output 

Description of the output dataset:
    (1) The dataset contains only event workers.
    (2) It contains workers' event group based on the CA30 high-flyer measure.

RA: WWZ 
Time: 2025-04-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge event dates to the outcome dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

generate Event_Time_1monthbefore = Event_Time - 1
format Event_Time_1monthbefore %tm
label variable Event_Time_1monthbefore "Event month - 1"
order IDlse YearMonth IDlseMHR Event_Time Event_Time_1monthbefore IDMngr_Pre IDMngr_Post

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

rename YearMonth YearMonth_Save

rename Event_Time YearMonth
merge m:1 IDMngr_Post YearMonth using "${TempData}/0102_03HFMeasure_TenureBased.dta"
    drop if _merge==2
    drop _merge 
rename (TB03 TB04 TB05) (TB03_Post TB04_Post TB05_Post)
rename YearMonth Event_Time

rename Event_Time_1monthbefore YearMonth
merge m:1 IDMngr_Pre YearMonth using "${TempData}/0102_03HFMeasure_TenureBased.dta"
    drop if _merge==2
    drop _merge 
rename (TB03 TB04 TB05) (TB03_Pre TB04_Pre TB05_Pre)
rename YearMonth Event_Time_1monthbefore

rename YearMonth_Save YearMonth

sort  IDlse YearMonth
order IDlse YearMonth IDlseMHR Event_Time Event_Time_1monthbefore IDMngr_Pre IDMngr_Post TB03_Pre TB04_Pre TB05_Pre TB03_Post TB04_Post TB05_Post

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach measure in TB03 TB04 TB05 {
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

foreach measure in TB03 TB04 TB05 {
    label variable `measure'_LtoL "LtoL event group (based on `measure' measure)"
    label variable `measure'_LtoH "LtoH event group (based on `measure' measure)"
    label variable `measure'_HtoH "HtoH event group (based on `measure' measure)"
    label variable `measure'_HtoL "HtoL event group (based on `measure' measure)"
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. obtain a final version dataset for all event study results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth TransferSJVC IDlseMHR ChangeSalaryGradeC ONETDistC LogPayBonus LogPay LogBonus ///
    Event_Time IDMngr_Pre IDMngr_Post Rel_Time Post_Event ///
    TB03_Pre TB04_Pre TB05_Pre TB03_Post TB04_Post TB05_Post ///
    CA30_LtoL CA30_LtoH CA30_HtoL CA30_HtoH TB*

order IDlse YearMonth TransferSJVC IDlseMHR ChangeSalaryGradeC ONETDistC LogPayBonus LogPay LogBonus ///
    Event_Time IDMngr_Pre IDMngr_Post Rel_Time Post_Event ///
    TB03_Pre TB04_Pre TB05_Pre TB03_Post TB04_Post TB05_Post ///
    CA30_LtoL CA30_LtoH CA30_HtoL CA30_HtoH TB*

save "${TempData}/FinalAnalysisSample_Simplified_WithTenureBasedMeasures.dta", replace