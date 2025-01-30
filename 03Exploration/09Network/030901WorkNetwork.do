/* 
This do file investigates work-related (subfunction, office, org4) within-network moves.

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
*?? step 2. collect all experienced SubFunc OfficeCode Org4
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 
drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs.dta", keep(match) nogenerate
    //&? a full panel of relevant post-event managers 

keep if YearMonth < min_EventTime
    //&? a panel of relevant post-event managers, keep only pre-event periods 
    //&? 9,974 different identifiable managers 

keep  IDlseMHR YearMonth SubFunc Func OfficeCode Org4
order IDlseMHR YearMonth Func SubFunc OfficeCode Org4

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. individual-work level id manipulation 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! individual-work level id 
sort IDlseMHR YearMonth
egen SubFunc_id    = group(IDlseMHR SubFunc)
egen OfficeCode_id = group(IDlseMHR OfficeCode)
egen Org4_id       = group(IDlseMHR Org4)

*!! tag different ids 
egen SubFunc_tag    = tag(SubFunc_id)
egen OfficeCode_tag = tag(OfficeCode_id)
egen Org4_tag       = tag(Org4_id)

*!! how many different ids (i.e., jobs) a manager has experienced 
sort IDlseMHR YearMonth
bysort IDlseMHR: generate cum_SubFunc_tag    = sum(SubFunc_tag)
bysort IDlseMHR: generate cum_OfficeCode_tag = sum(OfficeCode_tag)
bysort IDlseMHR: generate cum_Org4_tag       = sum(Org4_tag)

summarize cum_SubFunc_tag,    detail //&? [1, 8] 
summarize cum_OfficeCode_tag, detail //&? [1, 7]
summarize cum_Org4_tag,       detail //&? [1, 9]

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. generate variables to store past experiences 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

forvalues j = 1/8 {
    generate temp_SubFunc_`j' = .
    replace  temp_SubFunc_`j' = SubFunc if cum_SubFunc_tag==`j'
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen SubFunc_`j' = mode(temp_SubFunc_`j')
    drop temp_SubFunc_`j'
}
forvalues j = 1/7 {
    generate temp_OfficeCode_`j' = .
    replace  temp_OfficeCode_`j' = SubFunc if cum_OfficeCode_tag==`j'
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen OfficeCode_`j' = mode(temp_OfficeCode_`j')
    drop temp_OfficeCode_`j'
}
forvalues j = 1/9 {
    generate temp_Org4_`j' = .
    replace  temp_Org4_`j' = Org4 if cum_Org4_tag==`j'
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen Org4_`j' = mode(temp_Org4_`j')
    drop temp_Org4_`j'
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. keep only relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep  IDlseMHR SubFunc_* OfficeCode_* Org4_*
drop  *id *tag
order IDlseMHR SubFunc_* OfficeCode_* Org4_*
duplicates drop 

label values SubFunc_*    SubFunc
label values OfficeCode_* OfficeCode
label values Org4_*       Org4

save "${TempData}/temp_PostEventMngrs_PastWorkInfo.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions on a cross-section of event workers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. keep only relevant info 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

sort IDlse YearMonth
bysort IDlse: egen long PostEventMngr = mean(cond(FT_Rel_Time==0, IDlseMHR, .))
replace IDlseMHR = PostEventMngr
    //&? keep only post-event manager ids, instead of true manager ids

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers

keep if FT_Rel_Time==36 | FT_Rel_Time==48 | FT_Rel_Time==60 | FT_Rel_Time==72 | FT_Rel_Time==84
    //&? keep 3, 4, 5, 6, 7 years after the event 

keep IDlse YearMonth IDlseMHR FT_* SubFunc OfficeCode Org4 Country Func
    //&? 15,499 different workers 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. merge post-event managers' past work experiences
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs_PastWorkInfo.dta", keep(match) nogenerate

codebook IDlse       //&? 14,576 different workers 
codebook IDlseMHR    //&? 6,292 different post-event managers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. generate outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

generate Same_SubFunc = 0
forvalues j = 1/8 {
    replace Same_SubFunc = 1 if SubFunc == SubFunc_`j'
}

generate Same_OfficeCode = 0
forvalues j = 1/7 {
    replace Same_OfficeCode = 1 if OfficeCode == OfficeCode_`j'
}

generate Same_Org4 = 0
forvalues j = 1/9 {
    replace Same_Org4 = 1 if Org4 == Org4_`j'
}

egen Same_WorkInfo = rowmax(Same_SubFunc Same_OfficeCode Same_Org4)

save "${TempData}/temp_Network_WorkInfo.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. run regressions  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_Network_WorkInfo.dta", clear 

foreach var in Same_SubFunc Same_OfficeCode Same_Org4 Same_WorkInfo {
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

esttab Same_SubFunc_3yrs Same_OfficeCode_3yrs Same_Org4_3yrs Same_WorkInfo_3yrs using "${Results}/WorkNetwork_3yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Same subfunction} & \multicolumn{1}{c}{Same office} & \multicolumn{1}{c}{Same Org4} & \multicolumn{1}{c}{Same subfunction, office, or Org4} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past work experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is of the same work 3 years after the manager change event." "\end{tablenotes}")

foreach var in Same_SubFunc Same_OfficeCode Same_Org4 Same_WorkInfo {
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

esttab Same_SubFunc_4yrs Same_OfficeCode_4yrs Same_Org4_4yrs Same_WorkInfo_4yrs using "${Results}/WorkNetwork_4yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Same subfunction} & \multicolumn{1}{c}{Same office} & \multicolumn{1}{c}{Same Org4} & \multicolumn{1}{c}{Same subfunction, office, or Org4} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past work experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is of the same work 4 years after the manager change event." "\end{tablenotes}")

foreach var in Same_SubFunc Same_OfficeCode Same_Org4 Same_WorkInfo {
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

esttab Same_SubFunc_5yrs Same_OfficeCode_5yrs Same_Org4_5yrs Same_WorkInfo_5yrs using "${Results}/WorkNetwork_5yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Same subfunction} & \multicolumn{1}{c}{Same office} & \multicolumn{1}{c}{Same Org4} & \multicolumn{1}{c}{Same subfunction, office, or Org4} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past work experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is of the same work 5 years after the manager change event." "\end{tablenotes}")

foreach var in Same_SubFunc Same_OfficeCode Same_Org4 Same_WorkInfo {
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

esttab Same_SubFunc_6yrs Same_OfficeCode_6yrs Same_Org4_6yrs Same_WorkInfo_6yrs using "${Results}/WorkNetwork_6yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Same subfunction} & \multicolumn{1}{c}{Same office} & \multicolumn{1}{c}{Same Org4} & \multicolumn{1}{c}{Same subfunction, office, or Org4} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past work experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is of the same work 6 years after the manager change event." "\end{tablenotes}")

foreach var in Same_SubFunc Same_OfficeCode Same_Org4 Same_WorkInfo {
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

esttab Same_SubFunc_7yrs Same_OfficeCode_7yrs Same_Org4_7yrs Same_WorkInfo_7yrs using "${Results}/WorkNetwork_7yrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Same subfunction} & \multicolumn{1}{c}{Same office} & \multicolumn{1}{c}{Same Org4} & \multicolumn{1}{c}{Same subfunction, office, or Org4} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of only those event workers. Standard errors clustered at the manager level. Controls include: country and year FE. For each worker, I calculate his post-event manager's past work experience (before the manager change event), and the outcome variable is a dummy indicating whether the worker is of the same work 7 years after the manager change event." "\end{tablenotes}")



