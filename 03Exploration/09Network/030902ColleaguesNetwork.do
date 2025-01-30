/* 
This do file investigates college-related (managers, subordinates, same-level colleagues) within-network moves.

RA: WWZ 
Time: 2024-12-19
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
    //&? a cross-sectional of event workers

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
    replace  temp_IDlseMHRMHR_`j' = IDlseMHRMHR if cum_IDlseMHRMHR_tag==`j'
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen IDlseMHRMHR_`j' = mode(temp_IDlseMHRMHR_`j')
    drop temp_IDlseMHRMHR_`j'
}

keep IDlseMHR IDlseMHRMHR_1 - IDlseMHRMHR_16
duplicates drop 
    //&? 9,945 different identifiable post-event managers 

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

merge m:m IDlseMHR YearMonth using "${TempData}/04MainOutcomesInEventStudies.dta", keepusing(IDlse) keep(match) nogenerate
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
    replace  temp_IDlseMHRSub_`j' = IDlseMHRSub if cum_IDlseMHRSub_tag==`j'
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen IDlseMHRSub_`j' = mode(temp_IDlseMHRSub_`j')
    drop temp_IDlseMHRSub_`j'
}

keep IDlseMHR IDlseMHRSub_1 - IDlseMHRSub_60
duplicates drop 
    //&? 9,945 different identifiable post-event managers 

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
    bysort IDTeam: egen IDColleague_`j' = mode(temp_IDColleague_`j')
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
    //&? 9173 different identifiable managers


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. run regressions on a cross-section of event workers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-1. keep only relevant info 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

generate long IDlseMHRTrue = IDlseMHR

sort IDlse YearMonth
bysort IDlse: egen long PostEventMngr = mean(cond(FT_Rel_Time==0, IDlseMHR, .))
replace IDlseMHR = PostEventMngr
    //&? keep only post-event manager ids, instead of true manager ids in this variable

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers

keep if FT_Rel_Time==36 | FT_Rel_Time==48 | FT_Rel_Time==60 | FT_Rel_Time==72 | FT_Rel_Time==84
    //&? keep 3, 4, 5, 6, 7 years after the event 

keep IDlse YearMonth IDlseMHR IDlseMHRTrue FT_* SubFunc OfficeCode Org4 Country Func
    //&? 15,499 different workers 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-2. merge post-event managers' network info 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs_PastMngrInfo.dta",         keep(match master) nogenerate
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs_PastSubOrdinatesInfo.dta", keep(match master) nogenerate
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs_PastColleaguesInfo.dta",   keep(match master) nogenerate

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-3. generate outcome variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

*!! true manager is post-event manager's manager

egen num_IDlseMHRMHR_miss = rowmiss(IDlseMHRMHR_1 - IDlseMHRMHR_16)

generate Same_MHRMHR = 0 if IDlseMHRTrue != .
replace  Same_MHRMHR = . if num_IDlseMHRMHR_miss==16
    //&? adjust for nonidentification case 

forvalues j = 1/16 {
    replace Same_MHRMHR = 1 if IDlseMHRTrue == IDlseMHRMHR_`j' & IDlseMHRTrue != .
}

*!! true manager is post-event manager's subordinates

egen num_IDlseMHRSub_miss = rowmiss(IDlseMHRSub_1 - IDlseMHRSub_60)

generate Same_MHRSub = 0 if IDlseMHRTrue != .
replace  Same_MHRSub = . if num_IDlseMHRSub_miss==60
    //&? adjust for nonidentification case 

forvalues j = 1/60 {
    replace Same_MHRSub = 1 if IDlseMHRTrue == IDlseMHRSub_`j' & IDlseMHRTrue != .
}

*!! true manager is post-event manager's same-level colleagues

egen num_IDColleague_miss = rowmiss(IDColleague_1 - IDColleague_165)

generate Same_MHRColleague = 0 if IDlseMHRTrue != .
replace  Same_MHRColleague = . if num_IDColleague_miss==165
    //&? adjust for nonidentification case 

forvalues j = 1/165 {
    replace Same_MHRColleague = 1 if IDlseMHRTrue == IDColleague_`j' & IDlseMHRTrue != .
}

egen Same_PeopleInfo = rowmax(Same_MHRMHR Same_MHRSub Same_MHRColleague)

save "${TempData}/temp_Network_PeopleInfo.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-4. run regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?


use "${TempData}/temp_Network_PeopleInfo.dta", clear 

foreach var in Same_MHRMHR Same_MHRSub Same_MHRColleague {
    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Rel_Time==36, absorb(FT_Event_Time Country) cluster(IDlseMHR)
        eststo `var'_3yrs
    lincom FT_LtoH 
        estadd scalar diff1 = r(estimate)
        estadd scalar p_value1 = r(p)
        estadd scalar se_diff1 = r(se)
    lincom FT_HtoL-FT_HtoH
        estadd scalar diff2 = r(estimate)
        estadd scalar p_value2 = r(p)
        estadd scalar se_diff2 = r(se)
    summarize `var' if e(sample)==1 & FT_LtoL==1
        estadd scalar mean_LtoL = r(mean)
}

esttab Same_MHRMHR_3yrs Same_MHRSub_3yrs Same_MHRColleague_3yrs using "${Results}/PeopleNetwork_3yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Post-event manager's managers} & \multicolumn{1}{c}{Post-event manager's subordinates} & \multicolumn{1}{c}{Post-event manager's same-level colleagues} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past colleague experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is under the supervision within the post-event manager's people network 3 years after the manager change event." "\end{tablenotes}")

foreach var in Same_MHRMHR Same_MHRSub Same_MHRColleague {
    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Rel_Time==48, absorb(FT_Event_Time Country) cluster(IDlseMHR)
        eststo `var'_4yrs
    lincom FT_LtoH 
        estadd scalar diff1 = r(estimate)
        estadd scalar p_value1 = r(p)
        estadd scalar se_diff1 = r(se)
    lincom FT_HtoL-FT_HtoH
        estadd scalar diff2 = r(estimate)
        estadd scalar p_value2 = r(p)
        estadd scalar se_diff2 = r(se)
    summarize `var' if e(sample)==1 & FT_LtoL==1
        estadd scalar mean_LtoL = r(mean)
}

esttab Same_MHRMHR_4yrs Same_MHRSub_4yrs Same_MHRColleague_4yrs using "${Results}/PeopleNetwork_4yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Post-event manager's managers} & \multicolumn{1}{c}{Post-event manager's subordinates} & \multicolumn{1}{c}{Post-event manager's same-level colleagues} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past colleague experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is under the supervision within the post-event manager's people network 4 years after the manager change event." "\end{tablenotes}")

foreach var in Same_MHRMHR Same_MHRSub Same_MHRColleague {
    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Rel_Time==60, absorb(FT_Event_Time Country) cluster(IDlseMHR)
        eststo `var'_5yrs
    lincom FT_LtoH 
        estadd scalar diff1 = r(estimate)
        estadd scalar p_value1 = r(p)
        estadd scalar se_diff1 = r(se)
    lincom FT_HtoL-FT_HtoH
        estadd scalar diff2 = r(estimate)
        estadd scalar p_value2 = r(p)
        estadd scalar se_diff2 = r(se)
    summarize `var' if e(sample)==1 & FT_LtoL==1
        estadd scalar mean_LtoL = r(mean)
}

esttab Same_MHRMHR_5yrs Same_MHRSub_5yrs Same_MHRColleague_5yrs using "${Results}/PeopleNetwork_5yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Post-event manager's managers} & \multicolumn{1}{c}{Post-event manager's subordinates} & \multicolumn{1}{c}{Post-event manager's same-level colleagues} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past colleague experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is under the supervision within the post-event manager's people network 5 years after the manager change event." "\end{tablenotes}")

foreach var in Same_MHRMHR Same_MHRSub Same_MHRColleague {
    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Rel_Time==72, absorb(FT_Event_Time Country) cluster(IDlseMHR)
        eststo `var'_6yrs
    lincom FT_LtoH 
        estadd scalar diff1 = r(estimate)
        estadd scalar p_value1 = r(p)
        estadd scalar se_diff1 = r(se)
    lincom FT_HtoL-FT_HtoH
        estadd scalar diff2 = r(estimate)
        estadd scalar p_value2 = r(p)
        estadd scalar se_diff2 = r(se)
    summarize `var' if e(sample)==1 & FT_LtoL==1
        estadd scalar mean_LtoL = r(mean)
}

esttab Same_MHRMHR_6yrs Same_MHRSub_6yrs Same_MHRColleague_6yrs using "${Results}/PeopleNetwork_6yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Post-event manager's managers} & \multicolumn{1}{c}{Post-event manager's subordinates} & \multicolumn{1}{c}{Post-event manager's same-level colleagues} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past colleague experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is under the supervision within the post-event manager's people network 6 years after the manager change event." "\end{tablenotes}")

foreach var in Same_MHRMHR Same_MHRSub Same_MHRColleague {
    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Rel_Time==84, absorb(FT_Event_Time Country) cluster(IDlseMHR)
        eststo `var'_7yrs
    lincom FT_LtoH 
        estadd scalar diff1 = r(estimate)
        estadd scalar p_value1 = r(p)
        estadd scalar se_diff1 = r(se)
    lincom FT_HtoL-FT_HtoH
        estadd scalar diff2 = r(estimate)
        estadd scalar p_value2 = r(p)
        estadd scalar se_diff2 = r(se)
    summarize `var' if e(sample)==1 & FT_LtoL==1
        estadd scalar mean_LtoL = r(mean)
}

esttab Same_MHRMHR_7yrs Same_MHRSub_7yrs Same_MHRColleague_7yrs using "${Results}/PeopleNetwork_7yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Post-event manager's managers} & \multicolumn{1}{c}{Post-event manager's subordinates} & \multicolumn{1}{c}{Post-event manager's same-level colleagues} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past colleague experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is under the supervision within the post-event manager's people network 7 years after the manager change event." "\end{tablenotes}")
