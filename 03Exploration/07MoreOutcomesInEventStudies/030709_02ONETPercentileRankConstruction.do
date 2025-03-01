/* 
This do file transforms the raw ONET task intensity score to a percentile rank based on personnel records across all year-months.

Input:
    "${TempData}/temp_ONET_RawTaskIntensity.dta" <== created in 030709_01 do file 
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file

RA: WWZ
Time: 2025-02-17
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

merge m:1 StandardJob using "${TempData}/temp_ONET_RawTaskIntensity.dta", keep(match) nogenerate

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. cdf plots across all year months
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

codebook ONETSOCCode
    //&? 78 unique ONET occupation codes in all periods

cdfplot intensity_cognitive ///
    , xlabel(0(1)10, grid gstyle(dot)) xtitle("Raw cognitive task intensity", size(medlarge)) ///
    ylabel(0(0.1)1, grid gstyle(dot)) ytitle("Cumulative probability", size(medlarge)) ///
    title("Distribution of raw cognitive task intensity (scale 0-10)")
graph export "${Results}/Dist_RawTaskIntensity_Cognitive_WholeSample.png", replace as(png)

cdfplot intensity_routine ///
    , xlabel(0(1)10, grid gstyle(dot)) xtitle("Raw routine task intensity", size(medlarge)) ///
    ylabel(0(0.1)1, grid gstyle(dot)) ytitle("Cumulative probability", size(medlarge)) ///
    title("Distribution of raw routine task intensity (scale 0-10)")
graph export "${Results}/Dist_RawTaskIntensity_Routine_WholeSample.png", replace as(png)

cdfplot intensity_social ///
    , xlabel(0(1)10, grid gstyle(dot)) xtitle("Raw social task intensity", size(medlarge)) ///
    ylabel(0(0.1)1, grid gstyle(dot)) ytitle("Cumulative probability", size(medlarge)) ///
    title("Distribution of raw social task intensity (scale 0-10)")
graph export "${Results}/Dist_RawTaskIntensity_Social_WholeSample.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. calculate the fraction for each ONET occupation
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

    save "${TempData}/temp_ONET_FinalOccLevelPrank.dta", replace

restore 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. get the final MNE job-level dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep StandardJob ONETSOCCode prank_cognitive prank_routine prank_social intensity_cognitive_a-intensity_social
duplicates drop 

save "${TempData}/temp_ONET_FinalJobLevelPrank.dta", replace 
