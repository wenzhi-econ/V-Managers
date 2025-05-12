/* 
This do file shows the transfer heat map, after characterizing a job as an occupation with a specific task.

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
Time: 2025-04-29
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

keep IDlse YearMonth Rel_Time Event_Time CA30_LtoL CA30_LtoH Func StandardJob ONETDistC

graph twoway ///
    (kdensity ONETDistC if CA30_LtoH==1 & Rel_Time==24) ///
    (kdensity ONETDistC if CA30_LtoL==1 & Rel_Time==24) ///
    (kdensity ONETDistC if CA30_LtoH==1 & Rel_Time==84) ///
    (kdensity ONETDistC if CA30_LtoL==1 & Rel_Time==84) ///
    , legend(label(1 "LtoH, 2 years later") label(2 "LtoL, 2 years later") label(3 "LtoH, 7 years later") label(4 "LtoL, 7 years later")) ///
    scheme(tab2)

graph export "${Results}/004ResultsBasedOnCA30/Dist_ONETDistC_LtoHvsLtoL.png", replace as(png)

