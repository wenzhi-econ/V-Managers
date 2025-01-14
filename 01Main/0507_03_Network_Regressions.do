/* 
This set of do files (0606) investigates whether H-type managers are more likely to move their subordinates to their pre-existing networks.

In this do file, I run a set of cross-sectional regressions on whether the event worker is in their post-event managers' pre-existing networks within given years after the event.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 

Output:
    "${TempData}/temp_PostEventMngrs.dta"
        a list of post-event managers and their earliest involved event dates
    "${TempData}/temp_PostEventMngrs_PastWorkInfo.dta"
        for these managers, all their experienced subfunctions and offices before the earliest involved event dates

RA: WWZ 
Time: 2024-12-20
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant dataset  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only event workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

generate long IDlseMHRTrue = IDlseMHR
    //&? managers in reality 

sort IDlse YearMonth
bysort IDlse: egen long PostEventMngr = mean(cond(FT_Rel_Time==0, IDlseMHR, .))
replace IDlseMHR = PostEventMngr
    //&? post-event managers, instead of true managers

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers

keep if FT_Rel_Time==36 | FT_Rel_Time==84
    //&? keep 3 and 7 years after the event 

keep  IDlse YearMonth IDlseMHR IDlseMHRTrue FT_* SubFunc OfficeCode Country
order IDlse YearMonth IDlseMHR IDlseMHRTrue FT_* SubFunc OfficeCode Country

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge post-event managers' past work experiences
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs_PastWorkInfo.dta",         keep(match master) nogenerate

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge post-event managers' past colleagues experiences
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs_PastMngrInfo.dta",         keep(match master) nogenerate
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs_PastSubOrdinatesInfo.dta", keep(match master) nogenerate
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs_PastColleaguesInfo.dta",   keep(match master) nogenerate

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. generate outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

*!! s-1-3-1. if the worker's subfunction in the list of post-event managers' pre-event subfunction experiences
egen num_SubFunc_miss = rowmiss(SubFunc_1 - SubFunc_8)
generate Same_SubFunc = 0 if SubFunc!=.
replace  Same_SubFunc = . if num_SubFunc_miss==8 //&? non-identification case 
forvalues j = 1/8 {
    replace Same_SubFunc = 1 if SubFunc == SubFunc_`j'
}

*!! s-1-3-2. if the worker's office in the list of post-event managers' pre-event office experiences
egen num_OfficeCode_miss = rowmiss(OfficeCode_1 - OfficeCode_7)
generate Same_OfficeCode = 0 if OfficeCode!=.
replace  Same_OfficeCode = . if num_OfficeCode_miss==7 //&? non-identification case 
forvalues j = 1/7 {
    replace Same_OfficeCode = 1 if OfficeCode == OfficeCode_`j'
}

*!! s-1-3-3. if the worker's work in the list of post-event managers' pre-event work experiences (any of subfunction, or office)
egen Same_WorkInfo = rowmax(Same_SubFunc Same_OfficeCode)

*!! s-1-3-4. if the worker's true manager in the list of post-event managers' pre-event managers
egen num_IDlseMHRMHR_miss = rowmiss(IDlseMHRMHR_1 - IDlseMHRMHR_16)
generate Same_MHRMHR = 0 if IDlseMHRTrue != .
replace  Same_MHRMHR = . if num_IDlseMHRMHR_miss==16 //&? non-identification case 
forvalues j = 1/16 {
    replace Same_MHRMHR = 1 if IDlseMHRTrue == IDlseMHRMHR_`j' & IDlseMHRTrue != .
}

*!! s-1-3-4. if the worker's true manager in the list of post-event managers' pre-event subordinates
egen num_IDlseMHRSub_miss = rowmiss(IDlseMHRSub_1 - IDlseMHRSub_60)

generate Same_MHRSub = 0 if IDlseMHRTrue != .
replace  Same_MHRSub = . if num_IDlseMHRSub_miss==60 //&? non-identification case 
forvalues j = 1/60 {
    replace Same_MHRSub = 1 if IDlseMHRTrue == IDlseMHRSub_`j' & IDlseMHRTrue != .
}

*!! s-1-3-4. if the worker's true manager in the list of post-event managers' pre-event same-level colleagues
egen num_IDColleague_miss = rowmiss(IDColleague_1 - IDColleague_165)
generate Same_MHRColleague = 0 if IDlseMHRTrue != .
replace  Same_MHRColleague = . if num_IDColleague_miss==165 //&? non-identification case 
forvalues j = 1/165 {
    replace Same_MHRColleague = 1 if IDlseMHRTrue == IDColleague_`j' & IDlseMHRTrue != .
}

*!! s-1-3-5. if the worker's true manager is just the post-event manager
generate Same_MHR = 0 if IDlseMHRTrue != .
replace  Same_MHR = 1 if IDlseMHR == IDlseMHRTrue

order IDlse YearMonth IDlseMHR IDlseMHRTrue ///
    FT_* Same_SubFunc Same_OfficeCode Same_WorkInfo Same_MHRMHR Same_MHRSub Same_MHRColleague Same_MHR

save "${TempData}/temp_Network.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_Network.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. 3 years after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in Same_WorkInfo Same_MHRMHR Same_MHRSub Same_MHRColleague Same_MHR {
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

esttab Same_WorkInfo_3yrs Same_MHRMHR_3yrs Same_MHRSub_3yrs Same_MHRColleague_3yrs Same_MHR_3yrs using "${Results}/Network_toHvstoL.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\hline\hline \\" "& \multicolumn{1}{c}{Same subfunction or office} & \multicolumn{1}{c}{Manager's managers} & \multicolumn{1}{c}{Manager's subordinates} & \multicolumn{1}{c}{Manager's same-level colleagues} & \multicolumn{1}{c}{Same manager} \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} \\") ///
    posthead("\\[-1ex] \multicolumn{6}{c}{\emph{Panel (a): 3 years after the event}} \\\\[-1ex]") ///
    prefoot("\hline") ///
    postfoot("\hline")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. 7 years after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in Same_WorkInfo Same_MHRMHR Same_MHRSub Same_MHRColleague Same_MHR {
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

esttab Same_WorkInfo_7yrs Same_MHRMHR_7yrs Same_MHRSub_7yrs Same_MHRColleague_7yrs Same_MHR_7yrs using "${Results}/Network_toHvstoL.tex", ///
    append style(tex) fragment nocons label nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("") ///
    posthead("\\[-1ex] \multicolumn{6}{c}{\emph{Panel (b): 7 years after the event}} \\\\[-1ex]") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of those event workers 3 or 7 years after the event. Standard errors clustered at the manager level. Controls include: country and event time FE. In column (1), for each worker, I obtain a list of his incoming manager's experienced subfunctions and offices (before the manager change event), and the outcome variable is a dummy indicating whether the worker's subfunction or office is in the list. In columns (2)-(4), I obtain different lists of his incoming manager's colleagues with whom he has worked before the event time, and the outcome variable is a dummy indicating whether the worker's manager 3 or 7 years after the event is in these lists. In column (5), the outcome variable is a dummy indicating whether the worker's manager 3 or 7 years after the event is the same incoming manager in the event." "\end{tablenotes}")




