/* 
This do file transforms the raw ONET task intensity score to a percentile rank based on personnel records across all year-months.

Input:
    "${TempData}/0701ONET_RawTaskIntensity.dta"    <== created in 0107_01 do file 
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file

Output:
    "${TempData}/temp_ONET_Title.dta" 
            <== auxiliary dataset
            <== will be removed if $if_erase_temp_file==1
    "${TempData}/0702ONET_FinalOccLevelPrank.dta" 
            <== occupation-level dataset with final task intensity measures
            <== this dataset is used to construct the descriptive table in the ONET appendix in the paper
    "${TempData}/0702ONET_FinalJobLevelPrank.dta" 
            <== main output dataset 
            <== this dataset will be merged with the main dataset when analyzing ONET outcomes
            <== specifically, this dataset will be used in 0301_04 do file

RA: WWZ
Time: 2025-03-12
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. mapping from ONET occupation codes to ONET occupation titles
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

import excel using "${RawONETData}/Skills.xlsx", firstrow clear

keep ONETSOCCode Title
duplicates drop 
save "${TempData}/temp_ONET_Title.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct the percentile rank for each ONET occupation manually
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge to get the raw intensity measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep IDlse YearMonth StandardJob

merge m:1 StandardJob using "${TempData}/0701ONET_RawTaskIntensity.dta", keep(match) nogenerate

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. calculate a fraction (i.e., percentile rank) for each occupation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach task in cognitive routine social {
    sort intensity_`task' IDlse
    generate rank_`task' = _n
    generate total_`task' = _N
    generate cdf_`task' = rank_`task' / total_`task'

    sort ONETSOCCode IDlse
    bysort ONETSOCCode: egen prank_`task' = max(cdf_`task')
}
    //&? interpretation: in 2011m12, the value for a particular ONET occupation code indicates the fraction of workers whose task intensity is no greater than the corresponding occupation

label variable prank_cognitive "Cognitive task intensity percentile rank"
label variable prank_routine   "Routine task intensity percentile rank"
label variable prank_social    "Social task intensity percentile rank"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. get the final occupation-level dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

preserve

    keep ONETSOCCode prank_cognitive prank_routine prank_social intensity_cognitive_a-intensity_social
    duplicates drop 

    merge 1:1 ONETSOCCode using "${TempData}/temp_ONET_Title.dta", nogenerate keep(match)

    order ONETSOCCode Title prank_cognitive prank_routine prank_social

    save "${TempData}/0702ONET_FinalOccLevelPrank.dta", replace

restore 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. get the final MNE job-level dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep StandardJob ONETSOCCode prank_cognitive prank_routine prank_social intensity_cognitive_a-intensity_social
duplicates drop 

save "${TempData}/0702ONET_FinalJobLevelPrank.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. erase temporary files
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

if $if_erase_temp_file==1 {
    erase "${TempData}/temp_ONET_Title.dta"
}
