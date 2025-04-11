/* 
This do file generates relevant event dummies used for event studies.

Input:
    "${TempData}/01WorkersOutcomes.dta" <== created in 0101 do file 
    "${TempData}/031902PreAndPostEventMngr_WideShape.dta" <== created in 031902

RA: WWZ 
Time: 2025-04-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge event dates to the outcome dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/01WorkersOutcomes.dta", clear 

merge m:1 IDlse using "${TempData}/031902PreAndPostEventMngr_WideShape.dta"
    keep if _merge==3
    drop _merge

codebook IDlse
    //&? expected to be 29,826; and it is; perfect

order IDlse YearMonth IDlseMHR Event_Time Event_Time_1monthbefore IDMngr_Pre IDMngr_Post

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

rename YearMonth YearMonth_Save

rename Event_Time YearMonth
merge m:1 IDMngr_Post YearMonth using "${TempData}/031902SixHighFlyerMeasures.dta"
    drop if _merge==2
    drop _merge 
order OM DA30 CA30 CA31 CA32 CA33, after(IDMngr_Post)
rename (OM DA30 CA30 CA31 CA32 CA33) (OM_Post DA30_Post CA30_Post CA31_Post CA32_Post CA33_Post)
rename YearMonth Event_Time

rename Event_Time_1monthbefore YearMonth
merge m:1 IDMngr_Pre YearMonth using "${TempData}/031902SixHighFlyerMeasures.dta"
    drop if _merge==2
    drop _merge 
order OM DA30 CA30 CA31 CA32 CA33, after(IDMngr_Pre)
rename (OM DA30 CA30 CA31 CA32 CA33) (OM_Pre DA30_Pre CA30_Pre CA31_Pre CA32_Pre CA33_Pre)
rename YearMonth Event_Time_1monthbefore

rename YearMonth_Save YearMonth

codebook IDlse
    //&? expected to be 29,826; and it is; perfect 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sort IDlse YearMonth

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. Rel_Time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Rel_Time = YearMonth - Event_Time, after(Event_Time)
drop Event_Time_1monthbefore

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach measure in OM DA30 CA30 CA31 CA32 CA33 {

    generate `measure'_LtoL = .
    replace  `measure'_LtoL = 1 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_LtoL = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_LtoL = 0 if `measure'_Pre==1 & `measure'_Post==0
    replace  `measure'_LtoL = 0 if `measure'_Pre==1 & `measure'_Post==1

    generate `measure'_LtoH = .
    replace  `measure'_LtoH = 1 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_LtoH = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_LtoH = 0 if `measure'_Pre==1 & `measure'_Post==0
    replace  `measure'_LtoH = 0 if `measure'_Pre==1 & `measure'_Post==1

    generate `measure'_HtoH = .
    replace  `measure'_HtoH = 1 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_HtoH = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_HtoH = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_HtoH = 0 if `measure'_Pre==1 & `measure'_Post==0

    generate `measure'_HtoL = .
    replace  `measure'_HtoL = 1 if `measure'_Pre==1 & `measure'_Post==0
    replace  `measure'_HtoL = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_HtoL = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_HtoL = 0 if `measure'_Pre==1 & `measure'_Post==1
}
order OM_LtoL - CA33_HtoL, after(Rel_Time)

order IDlse YearMonth IDlseMHR Event_Time Rel_Time IDMngr_Pre IDMngr_Post ///
    OM_Pre OM_Post OM_LtoL OM_LtoH OM_HtoH OM_HtoL ///
    DA30_Pre DA30_Post DA30_LtoL DA30_LtoH DA30_HtoH DA30_HtoL ///
    CA30_Pre CA30_Post CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL ///
    CA31_Pre CA31_Post CA31_LtoL CA31_LtoH CA31_HtoH CA31_HtoL ///
    CA32_Pre CA32_Post CA32_LtoL CA32_LtoH CA32_HtoH CA32_HtoL ///
    CA33_Pre CA33_Post CA33_LtoL CA33_LtoH CA33_HtoH CA33_HtoL 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. check the variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

codebook IDlse if OM_LtoL!=.
    //&? expected to be 29,610 (current reported numbers)
    //&? reality is 29,797
    //todo find out the sources of this inconsistency 

codebook IDlse if DA30_LtoL!=.

drop if OM_LtoL==.


save "${TempData}/031903FinalEventStudySample_SixHFMeasures.dta", replace
