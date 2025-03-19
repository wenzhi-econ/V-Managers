/* 
This set of do files (0507) investigates whether H-type managers are more likely to move their subordinates to their pre-existing networks.

In this do file, I create post-event managers' pre-event colleagues experiences (their managers, their subordinates, and their same-level colleagues).

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 

Output:
    "${TempData}/temp_PostEventMngrs.dta"
        a list of post-event managers and their earliest involved event dates
    "${TempData}/temp_PostEventMngrs_PastMngrInfo.dta"
        for these managers, all their experienced managers before the earliest involved event dates
    "${TempData}/temp_PostEventMngrs_PastSubOrdinatesInfo.dta"
        for these managers, all their experienced subordinates before the earliest involved event dates
    "${TempData}/temp_AllTeamComposition.dta"
        a list of workers inside a team, which is defined by the (IDlseMHR, YearMonth) pair
    "${TempData}/temp_PostEventMngrs_PastColleaguesInfo.dta"
        for these managers, all their experienced same-level colleagues before the earliest involved event dates

RA: WWZ 
Time: 2024-12-20
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of post-event managers 
*??         and their earliest involved event dates 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers 

keep if FT_Rel_Time==0
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
*?? step 2. collect all post-event managers' managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 
generate long IDlseMHRMHR = IDlseMHR
drop IDlseMHR

rename IDlse IDlseMHR
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs.dta", keep(match) nogenerate
    //&? a full panel of relevant post-event managers 

keep if YearMonth < min_EventTime
    //&? a panel of relevant post-event managers, keep only pre-event periods 
    //&? 9,974 different identifiable managers 

keep  IDlseMHR YearMonth IDlseMHRMHR
order IDlseMHR YearMonth IDlseMHRMHR

sort IDlseMHR YearMonth
egen IDlseMHRMHR_id  = group(IDlseMHR IDlseMHRMHR)
egen IDlseMHRMHR_tag = tag(IDlseMHRMHR_id)

sort IDlseMHR YearMonth
bysort IDlseMHR: generate cum_IDlseMHRMHR_tag = sum(IDlseMHRMHR_tag)
keep if cum_IDlseMHRMHR_tag>0
    //&? drop those post-event managers with missing manager info 

summarize cum_IDlseMHRMHR_tag, detail //&? [1, 16]

forvalues j = 1/16 {
    generate temp_IDlseMHRMHR_`j' = .
    replace  temp_IDlseMHRMHR_`j' = IDlseMHRMHR if cum_IDlseMHRMHR_tag==`j' & IDlseMHRMHR_tag==1
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen IDlseMHRMHR_`j' = mean(temp_IDlseMHRMHR_`j')
    drop temp_IDlseMHRMHR_`j'
}

keep IDlseMHR IDlseMHRMHR_1 - IDlseMHRMHR_16
duplicates drop 
    //&? 9,945 different identifiable post-event managers 

compress
save "${TempData}/temp_PostEventMngrs_PastMngrInfo.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. collect all post-event managers' subordinates 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs.dta", keep(match) nogenerate
    //&? a full panel of relevant post-event managers 

keep if YearMonth < min_EventTime
    //&? a panel of relevant post-event managers, keep only pre-event periods 
    //&? 9,974 different identifiable managers 

merge 1:m IDlseMHR YearMonth using "${TempData}/04MainOutcomesInEventStudies.dta", keepusing(IDlse) keep(match) nogenerate
    //&? get post-event managers' subordinates ids

bysort IDlseMHR YearMonth: generate TeamSize = _N
drop if TeamSize>10
    //&? impose the team size restriction

rename IDlse IDlseMHRSub

keep  IDlseMHR YearMonth IDlseMHRSub
order IDlseMHR YearMonth IDlseMHRSub

sort IDlseMHR YearMonth IDlseMHRSub
egen IDlseMHRSub_id  = group(IDlseMHR IDlseMHRSub)
egen IDlseMHRSub_tag = tag(IDlseMHRSub_id)

sort IDlseMHR YearMonth
bysort IDlseMHR: generate cum_IDlseMHRSub_tag = sum(IDlseMHRSub_tag)

summarize cum_IDlseMHRSub_tag, detail //&? [1, 60]

forvalues j = 1/60 {
    generate temp_IDlseMHRSub_`j' = .
    replace  temp_IDlseMHRSub_`j' = IDlseMHRSub if cum_IDlseMHRSub_tag==`j' & IDlseMHRSub_tag==1
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen IDlseMHRSub_`j' = mean(temp_IDlseMHRSub_`j')
    drop temp_IDlseMHRSub_`j'
}

keep IDlseMHR IDlseMHRSub_1 - IDlseMHRSub_60
duplicates drop 
    //&? 7,052 different identifiable post-event managers 

compress
save "${TempData}/temp_PostEventMngrs_PastSubOrdinatesInfo.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. collect all post-event managers' same-level colleagues 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. team composition
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep  IDlse YearMonth IDlseMHR
order IDlseMHR YearMonth IDlse
sort  IDlseMHR YearMonth IDlse

egen IDTeam = group(IDlseMHR YearMonth)
drop if IDTeam==.
    //&? drop teams with missing manager info 
bysort IDTeam: generate TeamSize = _N 
drop if TeamSize > 10
    //&? impose the team size restriction 

bysort IDTeam: generate IDTeamMember = _n 

forvalues j = 1/10 {
    generate temp_IDColleague_`j' = .
    replace  temp_IDColleague_`j' = IDlse if IDTeamMember==`j'
    sort IDTeam YearMonth
    bysort IDTeam: egen IDColleague_`j' = mean(temp_IDColleague_`j')
    drop temp_IDColleague_`j'
}

keep IDlseMHR YearMonth IDTeam IDColleague_*
duplicates drop 
    //&? a list of members inside a team (defined by the (IDlseMHR, YearMonth) pair)

save "${TempData}/temp_AllTeamComposition.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. post-event manager level team composition
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! get team composition
use "${TempData}/04MainOutcomesInEventStudies.dta", clear 
keep IDlse YearMonth IDlseMHR
merge m:1 IDlseMHR YearMonth using "${TempData}/temp_AllTeamComposition.dta", keep(match) nogenerate

*!! get a list of post-event managers 
drop IDlseMHR
rename IDlse IDlseMHR 
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs.dta", keep(match) nogenerate
    //&? a full (in the sense that we can identify his colleagues) panel of relevant post-event managers 

keep if YearMonth < min_EventTime
    //&? a panel of relevant post-event managers, keep only pre-event periods 
    //&? 9,173 different identifiable managers 

sort IDlseMHR YearMonth

*!! a full list of colleagues before the event (long format)
keep IDlseMHR YearMonth IDColleague_*
reshape long IDColleague_, i(IDlseMHR YearMonth) j(temp)
drop YearMonth
duplicates drop 
drop if IDColleague_==.

*!! a wide form of colleagues before the event 
sort IDlseMHR IDColleague_
bysort IDlseMHR: generate num_colleagues = _N 
summarize num_colleagues, detail //&? [1, 165]
drop num_colleagues

drop temp
bysort IDlseMHR: generate temp = _n 
reshape wide IDColleague_, i(IDlseMHR) j(temp)

save "${TempData}/temp_PostEventMngrs_PastColleaguesInfo.dta", replace
    //&? 9,173 different identifiable managers