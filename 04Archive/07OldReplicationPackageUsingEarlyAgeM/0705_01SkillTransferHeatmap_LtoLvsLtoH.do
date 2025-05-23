/* 
This do file shows the transfer heat map, after characterizing a job as an occupation with a specific task.

Notes: a job is classified into either a cognitive, routine, or social occupation based on its highest task intensity.

Input: 
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 
    "${TempData}/0702ONET_FinalJobLevelPrank.dta"  <== created in 0107_02 do file 

Output:
    "${TempData}/temp_ONET_OccHeatMap.dta"

Description of the output dataset:
    (1) An individual-level dataset containing one's job classification at the event time, and 1-7 years after the event.
    (2) It only contains workers in the event studies, and workers in the LtoL and LtoH groups.

RA: WWZ 
Time: 2025-03-19
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of event workers: task info
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep a panel of relevant workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
keep if FT_LtoH==1 | FT_LtoL==1
    //&? a panel of LtoL and LtoH event workers 
    //&? 25,001 unique workers

keep IDlse YearMonth FT_Rel_Time FT_Event_Time FT_LtoL FT_LtoH Func StandardJob

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. obtain ONET task intensity measures 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 StandardJob using "${TempData}/0702ONET_FinalJobLevelPrank.dta"
    //&? constructed in 030709_02 do file 
    keep if _merge==3
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                       139,475
        from master                   138,700  (_merge==1)
        from using                        775  (_merge==2)

    Matched                         1,517,845  (_merge==3)
    -----------------------------------------
*/

codebook ONETSOCCode
    //&? 67 unique ONET occupation codes in all periods


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. variable: OccTask
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate OccTask = .
replace  OccTask = 1 if (prank_cognitive > prank_routine  ) & (prank_cognitive > prank_social)
replace  OccTask = 2 if (prank_routine   > prank_cognitive) & (prank_routine   > prank_social)
replace  OccTask = 3 if (prank_social    > prank_cognitive) & (prank_social    > prank_routine)
    //&? classify a job as a cognitive, routine, or social occupation based on its highest task intensity
    //&? 0 missing values for this variable 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. 1-7 years after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_1yrLater = FT_Event_Time + 12
generate FT_2yrLater = FT_Event_Time + 24
generate FT_3yrLater = FT_Event_Time + 36
generate FT_4yrLater = FT_Event_Time + 48
generate FT_5yrLater = FT_Event_Time + 60
generate FT_6yrLater = FT_Event_Time + 72
generate FT_7yrLater = FT_Event_Time + 84

format   FT_1yrLater %tm 
format   FT_2yrLater %tm 
format   FT_3yrLater %tm 
format   FT_4yrLater %tm 
format   FT_5yrLater %tm 
format   FT_6yrLater %tm 
format   FT_7yrLater %tm 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. task information at different times 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

bysort IDlse: egen OccTask0 = mean(cond(YearMonth==FT_Event_Time, OccTask, .))
bysort IDlse: egen OccTask1 = mean(cond(YearMonth==FT_1yrLater,   OccTask, .))
bysort IDlse: egen OccTask2 = mean(cond(YearMonth==FT_2yrLater,   OccTask, .))
bysort IDlse: egen OccTask3 = mean(cond(YearMonth==FT_3yrLater,   OccTask, .))
bysort IDlse: egen OccTask4 = mean(cond(YearMonth==FT_4yrLater,   OccTask, .))
bysort IDlse: egen OccTask5 = mean(cond(YearMonth==FT_5yrLater,   OccTask, .))
bysort IDlse: egen OccTask6 = mean(cond(YearMonth==FT_6yrLater,   OccTask, .))
bysort IDlse: egen OccTask7 = mean(cond(YearMonth==FT_7yrLater,   OccTask, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-6. keep a cross section of relevant event workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time==0
    //&? keep a cross-section of relevant event workers 
    //&? 19,580 unique workers 
keep if OccTask0!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-6. reshape long so that cdfplot command can be used
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep IDlse FT_LtoL FT_LtoH OccTask0 OccTask1 OccTask2 OccTask3 OccTask4 OccTask5 OccTask6 OccTask7

save "${TempData}/temp_ONET_OccHeatMap.dta", replace
