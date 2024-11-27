/* 
This do file decomposes workers' lateral moves into three categories.

In particular, I create three variables TransferSJSameMSameFuncC TransferSJDiffMSameFuncC TransferFuncC such that 
    TransferSJC = TransferSJSameMSameFuncC + TransferSJDiffMSameFuncC + TransferFuncC

Then, I run event studies regressions on these four variables and report quarter 8 and quarter 28 estimates.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month 0 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [0, +84], while for HtoH and HtoL groups, the relative time period is [0, +60].

Input: 
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file

Output:
    "${Results}/logfile_20241127_DecompTransferSJC.txt"

Results:
    "${Results}/FT_Gains_DecompTransferSJC_DuringMngrRotation_Q8.gph"
    "${Results}/FT_Gains_DecompTransferSJC_AfterMngrRotation_Q28.gph"

RA: WWZ 
Time: 2024-11-19
*/


capture log close
log using "${Results}/logfile_20241127_DecompTransferSJC", replace text

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. decompose TransferSJ into three categories:
*??         (1) within team (same manager, same function)
*??         (2) different team (different manager), and different function
*??         (3) different team (different manager), but same function
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. auxiliary variable: ChangeM and TransferSJSameM
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! first month for a worker
sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

*!! if the worker changes his manager 
capture drop ChangeM
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

*!! lateral transfer under the same manager
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. decomposition 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

*!! category (3): different manager + same function
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

label variable TransferSJC               "All lateral moves"
label variable TransferSJSameMSameFuncC  "Within team lateral moves"
label variable TransferSJDiffMSameFuncC  "Different team, same function lateral moves"
label variable TransferFuncC             "Different team, different function lateral moves"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. FT_LtoL_X_Pre1 FT_LtoH_X_Post0 FT_HtoH_X_Post12
For binned dummies, e.g. FT_LtoL_X_Pre_Before36 FT_LtoH_X_Post_After84
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. event * period dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
summarize FT_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! FT_LtoL
generate byte FT_LtoL_X_Pre_Before`max_pre_period' = FT_LtoL * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_LtoL_X_Pre`time' = FT_LtoL * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte FT_LtoL_X_Post`time' = FT_LtoL * (FT_Rel_Time == `time')
}
generate byte FT_LtoL_X_Post_After`Lto_max_post_period' = FT_LtoL * (FT_Rel_Time > `Lto_max_post_period')

*!! FT_LtoH
generate byte FT_LtoH_X_Pre_Before`max_pre_period' = FT_LtoH * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_LtoH_X_Pre`time' = FT_LtoH * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte FT_LtoH_X_Post`time' = FT_LtoH * (FT_Rel_Time == `time')
}
generate byte FT_LtoH_X_Post_After`Lto_max_post_period' = FT_LtoH * (FT_Rel_Time > `Lto_max_post_period')

*!! FT_HtoH 
generate byte FT_HtoH_X_Pre_Before`max_pre_period' = FT_HtoH * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_HtoH_X_Pre`time' = FT_HtoH * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte FT_HtoH_X_Post`time' = FT_HtoH * (FT_Rel_Time == `time')
}
generate byte FT_HtoH_X_Post_After`Hto_max_post_period' = FT_HtoH * (FT_Rel_Time > `Hto_max_post_period')

*!! FT_HtoL 
generate byte FT_HtoL_X_Pre_Before`max_pre_period' = FT_HtoL * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_HtoL_X_Pre`time' = FT_HtoL * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte FT_HtoL_X_Post`time' = FT_HtoL * (FT_Rel_Time == `time')
}
generate byte FT_HtoL_X_Post_After`Hto_max_post_period' = FT_HtoL * (FT_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop FT_LtoL_X_Pre FT_LtoL_X_Post FT_LtoH_X_Pre FT_LtoH_X_Post FT_HtoH_X_Pre FT_HtoH_X_Post FT_HtoL_X_Pre FT_HtoL_X_Post

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in FT_HtoH FT_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_HtoH FT_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${FT_LtoL_X_Pre} ${FT_LtoL_X_Post} ${FT_LtoH_X_Pre} ${FT_LtoH_X_Post} ${FT_HtoH_X_Pre} ${FT_HtoH_X_Post} ${FT_HtoL_X_Pre} ${FT_HtoL_X_Post}

display "${four_events_dummies}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 
    // FT_HtoH_X_Pre_Before36 FT_HtoH_X_Pre36 ... FT_HtoH_X_Pre4 FT_HtoH_X_Post0 FT_HtoH_X_Post1 ... FT_HtoH_X_Post60 FT_HtoH_X_Pre_After60 
    // FT_HtoL_X_Pre_Before36 FT_HtoL_X_Pre36 ... FT_HtoL_X_Pre4 FT_HtoL_X_Post0 FT_HtoL_X_Post1 ... FT_HtoL_X_Post60 FT_HtoL_X_Pre_After60 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions and create the coefplot
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSJC TransferSJSameMSameFuncC TransferSJDiffMSameFuncC TransferFuncC {

    reghdfe `var' ${four_events_dummies} if ((FT_Mngr_both_WL2==1) & (FT_Never_ChangeM==0)), absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 
    
    *&& Quarter 8th estimate = the average of Month 22, Month 23, and Month 24 estimates
    *&& Quarter 28th estimate = the average of Month 82, Month 83, and Month 84 estimates
    xlincom ///
        (lc_1 = ((FT_LtoH_X_Post22 - FT_LtoL_X_Post22) + (FT_LtoH_X_Post23 - FT_LtoL_X_Post23) + (FT_LtoH_X_Post24 - FT_LtoL_X_Post24))/3) ///
        (lc_2 = ((FT_LtoH_X_Post82 - FT_LtoL_X_Post82) + (FT_LtoH_X_Post83 - FT_LtoL_X_Post83) + (FT_LtoH_X_Post84 - FT_LtoL_X_Post84))/3) ///
        , level(95) post

    eststo `var'
}

coefplot ///
    (TransferSJC,              keep(lc_1) rename(lc_1 = "All lateral moves")                noci recast(bar)) ///
    (TransferSJSameMSameFuncC, keep(lc_1) rename(lc_1 = "Within team")                      noci recast(bar)) ///
    (TransferSJDiffMSameFuncC, keep(lc_1) rename(lc_1 = "Different team, same function")    noci recast(bar)) ///
    (TransferFuncC,            keep(lc_1) rename(lc_1 = "Different team, cross-functional") noci recast(bar) ) ///
    , legend(off) xline(0, lpattern(dash)) ///
    xscale(range(0 0.1)) xlabel(0(0.01)0.1, grid gstyle(dot) labsize(medlarge)) ///
    ylabel(, labsize(large)) ///
    xsize(5) ysize(2) ///
    scheme(tab2) ///
    graphregion(margin(medium)) plotregion(margin(medium)) ///
    title("Effects of gaining a high-flyer manager", size(large))

graph save "${Results}/FT_Gains_DecompTransferSJC_DuringMngrRotation_Q8.gph", replace

coefplot ///
    (TransferSJC,              keep(lc_2) rename(lc_2 = "All lateral moves")                noci recast(bar)) ///
    (TransferSJSameMSameFuncC, keep(lc_2) rename(lc_2 = "Within team")                      noci recast(bar)) ///
    (TransferSJDiffMSameFuncC, keep(lc_2) rename(lc_2 = "Different team, same function")    noci recast(bar)) ///
    (TransferFuncC,            keep(lc_2) rename(lc_2 = "Different team, cross-functional") noci recast(bar) ) ///
    , legend(off) xline(0, lpattern(dash)) ///
    xscale(range(0 0.35)) xlabel(0(0.05)0.35, grid gstyle(dot) labsize(medlarge)) ///
    ylabel(, labsize(large)) ///
    xsize(5) ysize(2) ///
    scheme(tab2) ///
    graphregion(margin(medium)) plotregion(margin(medium)) ///
    title("Effects of gaining a high-flyer manager", size(large))

graph save "${Results}/FT_Gains_DecompTransferSJC_AfterMngrRotation_Q28.gph", replace

log close