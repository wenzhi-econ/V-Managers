/* 
This set of do files (0507) investigates whether H-type managers are more likely to move their subordinates to their pre-existing networks.

In this do file, I run a set of cross-sectional regressions on whether the event worker is in their post-event managers' pre-existing networks within given years after the event.

Input:
    "${TempData}/FinalFullSample.dta" <== created in 0101_01 do file 

Output:
    "${TempData}/temp_PostEventMngrs.dta"
        a list of post-event managers and their earliest involved event dates
    "${TempData}/temp_PostEventMngrs_PastWorkInfo.dta"
        for these managers, all their experienced subfunctions and offices before the earliest involved event dates

RA: WWZ 
Time: 2025-04-29
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant dataset  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only event workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 

generate long IDlseMHRTrue = IDlseMHR
    //&? managers in reality 

sort IDlse YearMonth
bysort IDlse: egen long PostEventMngr = mean(cond(Rel_Time==0, IDlseMHR, .))
replace IDlseMHR = PostEventMngr
    //&? post-event managers, instead of true managers

keep if Rel_Time==36 | Rel_Time==84
    //&? keep 3 and 7 years after the event 

keep  IDlse YearMonth IDlseMHR IDlseMHRTrue Rel_Time Event_Time CA30_* SubFunc OfficeCode Country
order IDlse YearMonth IDlseMHR IDlseMHRTrue Rel_Time Event_Time CA30_* SubFunc OfficeCode Country

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
    CA30_* Same_SubFunc Same_OfficeCode Same_WorkInfo Same_MHRMHR Same_MHRSub Same_MHRColleague Same_MHR

save "${TempData}/temp_Network.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_Network.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. 3 years after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in Same_WorkInfo Same_MHRMHR Same_MHRSub Same_MHRColleague Same_MHR {
    reghdfe `var' CA30_LtoH CA30_HtoH CA30_HtoL if Rel_Time==36, absorb(Event_Time Country) cluster(IDlseMHR)
        local r_squared = e(r2)    
        summarize `var' if e(sample)==1 & CA30_LtoL==1
            local mean_LtoL = r(mean)
        xlincom (CA30_LtoH) (CA30_HtoL-CA30_HtoH), post
            eststo `var'_3yrs
            estadd scalar mean_LtoL = `mean_LtoL'
            estadd scalar r_squared = `r_squared'
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. 7 years after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in Same_WorkInfo Same_MHRMHR Same_MHRSub Same_MHRColleague Same_MHR {
    reghdfe `var' CA30_LtoH CA30_HtoH CA30_HtoL if Rel_Time==84, absorb(Event_Time Country) cluster(IDlseMHR)
        local r_squared = e(r2)    
        summarize `var' if e(sample)==1 & CA30_LtoL==1
            local mean_LtoL = r(mean)
        xlincom (CA30_LtoH) (CA30_HtoL-CA30_HtoH), post
            eststo `var'_7yrs
            estadd scalar mean_LtoL = `mean_LtoL'
            estadd scalar r_squared = `r_squared'
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the regression table   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} \\"
global latex_titles       "& \multicolumn{1}{c}{Same subfunction or office} & \multicolumn{1}{c}{Manager's managers} & \multicolumn{1}{c}{Manager's subordinates} & \multicolumn{1}{c}{Manager's same-level colleagues} & \multicolumn{1}{c}{Same manager} \\"
global latex_panel_A      "\addlinespace[5pt] \multicolumn{5}{c}{\emph{Panel (a): 3 years after the event}} \\ [7pt]"
global latex_panel_B      "\addlinespace[5pt] \multicolumn{5}{c}{\emph{Panel (b): 7 years after the event}} \\ [7pt]"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_Network_toHvstoL.tex"

esttab Same_WorkInfo_3yrs Same_MHRMHR_3yrs Same_MHRSub_3yrs Same_MHRColleague_3yrs Same_MHR_3yrs using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(lc_1 lc_2) order(lc_1 lc_2) varlabels(lc_1 "LtoH - LtoL" lc_2 "HtoL - HtoH") ///
    stats(mean_LtoL r_squared N, labels("Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_titles}" "${latex_numbers}" "${latex_panel_A}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_midrule}")

esttab Same_WorkInfo_7yrs Same_MHRMHR_7yrs Same_MHRSub_7yrs Same_MHRColleague_7yrs Same_MHR_7yrs using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(lc_1 lc_2) order(lc_1 lc_2) varlabels(lc_1 "LtoH - LtoL" lc_2 "HtoL - HtoH") ///
    stats(mean_LtoL r_squared N, labels("Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_panel_B}") posthead("") ///
    prefoot("${latex_midrule}") ///
    postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The regression sample consists of those event workers 3 or 7 years after the event. Standard errors clustered at the manager level. Controls include: country and event time FE. In column (1), for each worker, I obtain a list of his incoming manager's experienced subfunctions and offices (before the manager change event), and the outcome variable is a dummy indicating whether the worker's subfunction or office is in the list. In columns (2)-(4), I obtain different lists of his incoming manager's colleagues with whom he has worked before the event time, and the outcome variable is a dummy indicating whether the worker's manager 3 or 7 years after the event is in these lists. In column (5), the outcome variable is a dummy indicating whether the worker's manager 3 or 7 years after the event is the same incoming manager in the event." "\end{tablenotes}")
