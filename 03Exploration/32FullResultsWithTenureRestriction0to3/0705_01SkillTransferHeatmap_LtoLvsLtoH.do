/* 
This do file shows the transfer heat map, after characterizing a job as an occupation with a specific task.

Special notes:
    (1) Only those employees whose tenure at the event time is in the range of [0,2] are included.

Notes: a job is classified into either a cognitive, routine, or social occupation based on its highest task intensity.

Input: 
    "${TempData}/FinalAnalysisSample.dta"          <== created in 0104 do file 
    "${TempData}/0101_03FinalJobLevelPrank.dta"    <== created in 0101_03 do file 

Output:
    "${TempData}/070501_OccTransferMap.dta"

Description of the output dataset:
    (1) An individual-level dataset containing one's job classification at the event time, and 1-7 years after the event.
    (2) It only contains workers in the event studies, and workers in the LtoL and LtoH groups.

RA: WWZ 
Time: 2025-05-22
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of event workers: task info
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep a panel of relevant workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if CA30_LtoH==1 | CA30_LtoL==1
    //&? a panel of LtoL and LtoH event workers 

keep if inrange(TenureAtEvent, 0, 2)
    //impt: keep only those employees whose tenure at the event time is in the range of [0,2]

keep IDlse YearMonth Rel_Time Event_Time CA30_LtoL CA30_LtoH Func StandardJob

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. obtain ONET task intensity measures 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop prank_cognitive
capture drop prank_routine
capture drop prank_social

merge m:1 StandardJob using "${TempData}/0101_03FinalJobLevelPrank.dta", keepusing(prank_cognitive prank_routine prank_social ONETSOCCode)
    keep if _merge==3
    drop _merge 

codebook ONETSOCCode
    //&? 62 unique ONET occupation codes in all periods

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. variable: OccTask
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate OccTask = .
replace  OccTask = 1 if (prank_cognitive > prank_routine  ) & (prank_cognitive > prank_social)
replace  OccTask = 2 if (prank_routine   > prank_cognitive) & (prank_routine   > prank_social)
replace  OccTask = 3 if (prank_social    > prank_cognitive) & (prank_social    > prank_routine)
    //&? classify a job as a cognitive, routine, or social occupation based on its highest task intensity

codebook OccTask
    //&? 0 missing values for this variable 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. 1-7 years after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Time_1yrLater = Event_Time + 12
generate Time_2yrLater = Event_Time + 24
generate Time_3yrLater = Event_Time + 36
generate Time_4yrLater = Event_Time + 48
generate Time_5yrLater = Event_Time + 60
generate Time_6yrLater = Event_Time + 72
generate Time_7yrLater = Event_Time + 84

format   Time_1yrLater %tm 
format   Time_2yrLater %tm 
format   Time_3yrLater %tm 
format   Time_4yrLater %tm 
format   Time_5yrLater %tm 
format   Time_6yrLater %tm 
format   Time_7yrLater %tm 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. task information at different times 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

bysort IDlse: egen OccTask0 = mean(cond(YearMonth==Event_Time,      OccTask, .))
bysort IDlse: egen OccTask1 = mean(cond(YearMonth==Time_1yrLater,   OccTask, .))
bysort IDlse: egen OccTask2 = mean(cond(YearMonth==Time_2yrLater,   OccTask, .))
bysort IDlse: egen OccTask3 = mean(cond(YearMonth==Time_3yrLater,   OccTask, .))
bysort IDlse: egen OccTask4 = mean(cond(YearMonth==Time_4yrLater,   OccTask, .))
bysort IDlse: egen OccTask5 = mean(cond(YearMonth==Time_5yrLater,   OccTask, .))
bysort IDlse: egen OccTask6 = mean(cond(YearMonth==Time_6yrLater,   OccTask, .))
bysort IDlse: egen OccTask7 = mean(cond(YearMonth==Time_7yrLater,   OccTask, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-6. keep a cross section of relevant event workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if Rel_Time==0
    //&? keep a cross-section of relevant event workers 
    //&? 19,580 unique workers 
keep if OccTask0!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-6. reshape long so that cdfplot command can be used
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep IDlse CA30_LtoL CA30_LtoH OccTask0 OccTask1 OccTask2 OccTask3 OccTask4 OccTask5 OccTask6 OccTask7

save "${TempData}/070501_OccTransferMap_TenureRestriction0to2.dta", replace