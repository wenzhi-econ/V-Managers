/* 
The codes are adapted from Lines 158-270 of file "3.3.Other Analysis.do".
I have made great changes to the codes (even the regression itself has been modified).
See more discussion in "TaskReport/Replication of Figure4.html".

Input Dataset:
    "${FinalData}/AllSameTeam2.dta"
Output Results:
    "${Results}/Figure4_MovesDecompGain.png"

RA: WWZ 
Time: 2024-09-05
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplest possible dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    TransferSJ TransferSJC ///
    TransferFunc TransferFuncC ///
    TransferSJSameM ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH 

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    WL2 ///
    FTLL FTLH FTHH FTHL ///
    TransferSJ TransferSJC ///
    TransferFunc TransferFuncC ///
    TransferSJSameM

rename WL2 Mngr_both_WL2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_2. decompose TransferSJ into three categories:
*-?       (1) within team (same manager, same function)
*-?       (2) different team (different manager), and different function
*-?       (3) different team (different manager), but same function
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
sort IDlse YearMonth

*!! category (3): differnt manager + same function
generate TransferSJDiffMSameFunc = TransferSJ 
replace  TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace  TransferSJDiffMSameFunc = 0 if TransferSJSameM==1
bysort IDlse: generate TransferSJDiffMSameFuncC= sum(TransferSJDiffMSameFunc)

*!! category (1): same manager + same function
generate TransferSJSameMSameFunc = TransferSJ 
replace  TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace  TransferSJSameMSameFunc = 0 if TransferSJDiffMSameFunc==1
bysort IDlse: generate TransferSJSameMSameFuncC= sum(TransferSJSameMSameFunc)

*!! category (2): different manager + different function
*&& variable TransferFunc can accurately describe this category

label variable TransferSJC              "All lateral moves"
label variable TransferSJSameMSameFuncC "Within team lateral moves"
label variable TransferSJDiffMSameFunc  "Different team, same function lateral moves"
label variable TransferFuncC            "Different team, different function lateral moves"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_3. construct (individual level) event dummies 
*-?       and (individual-month level) relative dates to the event
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*!! calendar time of the event
rename FTLL Calend_Time_FT_LtoL
rename FTLH Calend_Time_FT_LtoH
rename FTHL Calend_Time_FT_HtoL
rename FTHH Calend_Time_FT_HtoH

*!! five event dummies: 4 types of treatment + 1 never-treated
generate FT_LtoL = 0 
replace  FT_LtoL = 1 if Calend_Time_FT_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if Calend_Time_FT_LtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if Calend_Time_FT_HtoL != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if Calend_Time_FT_HtoH != .

capture drop temp 
egen temp = rowtotal(FT_LtoL FT_LtoH FT_HtoL FT_HtoH)
generate Never_ChangeM = 1 - temp 
capture drop temp

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate Rel_Time = . 
replace  Rel_Time = YearMonth - Calend_Time_FT_LtoL if Calend_Time_FT_LtoL !=. 
replace  Rel_Time = YearMonth - Calend_Time_FT_LtoH if Calend_Time_FT_LtoH !=. 
replace  Rel_Time = YearMonth - Calend_Time_FT_HtoL if Calend_Time_FT_HtoL !=. 
replace  Rel_Time = YearMonth - Calend_Time_FT_HtoH if Calend_Time_FT_HtoH !=. 

label variable Rel_Time "relative date to the event, missing if the event is Never_ChangeM"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_5. construct "event * relative date" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*!! ordinary "event * relative date" dummies 
local max_pre_period  = 36 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    forvalues time = 1/`max_pre_period' {
        generate byte `event'_X_Pre`time' = `event' * (Rel_Time == -`time')
    }
}
foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    forvalues time = 0/`max_post_period' {
        generate byte `event'_X_Post`time' = `event' * (Rel_Time == `time')
    }
}

*!! binned absorbing "event * relative date" dummies for pre- and post-event periods 
foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    generate byte `event'_X_Pre_Before36 = `event' * (Rel_Time < -36)
}

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    generate byte `event'_X_Post_After84 = `event' * (Rel_Time > 84)
}

save "${FinalData}/temp_fig4.dta", replace

capture log close
log using "${Results}/logfile_20240905_Figure4", replace text

use "${FinalData}/temp_fig4.dta", clear 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_6. construct global macros used in regressions 
*-?       using different aggregation methods 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& months -1, -2, and -3 are omitted as the reference group, so Line 127 iteration starts with 2
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

capture macro drop FT_LtoL_X_Pre 
capture macro drop FT_LtoH_X_Pre 
capture macro drop FT_LtoL_X_Post 
capture macro drop FT_LtoH_X_Post 
capture macro drop events_LH_minus_LL

local max_pre_period  = 36 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}
global events_LH_minus_LL ${FT_LtoL_X_Pre} ${FT_LtoL_X_Post} ${FT_LtoH_X_Pre} ${FT_LtoH_X_Post} 

display "${events_LH_minus_LL}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions and create the coefplot
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSJC TransferSJSameMSameFuncC TransferSJDiffMSameFuncC TransferFuncC {
    reghdfe `var' ${events_LH_minus_LL} ///
        if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
        , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 
    
    *&& Quarter 8th estimate = the average of Month 22, Month 23, and Month 24 estimates
    xlincom (((FT_LtoH_X_Post22 - FT_LtoL_X_Post22) + (FT_LtoH_X_Post23 - FT_LtoL_X_Post23) + (FT_LtoH_X_Post24 - FT_LtoL_X_Post24))/3), level(95) post

    eststo `var'
}

coefplot ///
    (TransferSJC, keep(lc_1) rename(lc_1  = "All lateral moves")  noci recast(bar)) ///
    (TransferSJSameMSameFuncC, keep(lc_1) rename(lc_1 = "Within team") noci recast(bar)) ///
    (TransferSJDiffMSameFuncC, keep(lc_1) rename(lc_1 = "Different team, same function") noci recast(bar)) ///
    (TransferFuncC, keep(lc_1) rename(lc_1 = "Different team, cross-functional") noci recast(bar) ) ///
    , legend(off) xline(0, lpattern(dash)) ///
    xscale(range(0 0.1)) xsize(5) ysize(2) ylabel(, labsize(large)) ///
    scheme(tab2) /// // xlabel(0(0.1)1, labsize(vlarge)) rescale(12.822699)  ///
    graphregion(margin(medium)) plotregion(margin(medium)) ///
    title("Effects of gaining a high-flyer manager")

graph export "${Results}/Figure4_FT_Gains_TransferSJCDecomp.png", replace  

log close
