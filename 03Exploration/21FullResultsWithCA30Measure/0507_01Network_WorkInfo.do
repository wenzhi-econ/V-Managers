/* 
This set of do files (0507) investigates whether H-type managers are more likely to move their subordinates to their pre-existing networks.

In this do file, I create post-event managers' pre-event work experiences in subfunctions, and offices.

Input:
    "${TempData}/FinalAnalysisSample.dta" <== created in 0104 do file 

Output:
    "${TempData}/temp_PostEventMngrs.dta"
        a list of post-event managers and their earliest involved event dates
    "${TempData}/temp_PostEventMngrs_PastWorkInfo.dta"
        for these managers, all their experienced subfunctions and offices before the earliest involved event dates

RA: WWZ 
Time: 2025-04-29
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of post-event managers 
*??         and their earliest involved event dates 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

keep if Rel_Time==0
    //&? a cross-sectional of event workers (at the time of event)

keep IDlseMHR YearMonth
duplicates drop 
    //&? all relevant (post-event manager, event time) pairs

sort IDlseMHR YearMonth
bysort IDlseMHR: egen min_EventTime = min(YearMonth)
format min_EventTime %tm
keep if YearMonth == min_EventTime
    //&? a cross-sectional of post-event managers

keep IDlseMHR min_EventTime
    //&? a list of post-event managers, and their earliest involved event dates 
    //&? 10,423 different managers

save "${TempData}/temp_PostEventMngrs.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. collect all experienced SubFunc OfficeCode
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 
drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs.dta", keep(match) nogenerate
    //&? a full panel of relevant post-event managers 

keep if YearMonth < min_EventTime
    //&? a panel of relevant post-event managers, keep only pre-event periods 
    //&? 9,974 different identifiable managers 

keep  IDlseMHR YearMonth SubFunc Func OfficeCode
order IDlseMHR YearMonth Func SubFunc OfficeCode

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. individual-work level id manipulation 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! individual-work level id 
sort IDlseMHR YearMonth
egen SubFunc_id    = group(IDlseMHR SubFunc)
egen OfficeCode_id = group(IDlseMHR OfficeCode)

*!! tag different ids 
egen SubFunc_tag    = tag(SubFunc_id)
egen OfficeCode_tag = tag(OfficeCode_id)

*!! how many different tags (i.e., subfunctions, and offices) a manager has experienced 
sort IDlseMHR YearMonth
bysort IDlseMHR: generate cum_SubFunc_tag    = sum(SubFunc_tag)
bysort IDlseMHR: generate cum_OfficeCode_tag = sum(OfficeCode_tag)

summarize cum_SubFunc_tag,    detail //&? [1, 8] 
summarize cum_OfficeCode_tag, detail //&? [1, 7]

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. generate variables to store past experiences 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

forvalues j = 1/8 {
    generate temp_SubFunc_`j' = .
    replace  temp_SubFunc_`j' = SubFunc if cum_SubFunc_tag==`j' & SubFunc_tag==1
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen SubFunc_`j' = mean(temp_SubFunc_`j')
    drop temp_SubFunc_`j'
}
forvalues j = 1/7 {
    generate temp_OfficeCode_`j' = .
    replace  temp_OfficeCode_`j' = SubFunc if cum_OfficeCode_tag==`j' & OfficeCode_tag==1
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen OfficeCode_`j' = mean(temp_OfficeCode_`j')
    drop temp_OfficeCode_`j'
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. keep only relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep  IDlseMHR SubFunc_* OfficeCode_* 
drop  *id *tag
order IDlseMHR SubFunc_* OfficeCode_* 
duplicates drop 

label values SubFunc_*    SubFunc

compress
save "${TempData}/temp_PostEventMngrs_PastWorkInfo.dta", replace
