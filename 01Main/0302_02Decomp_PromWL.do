/* 
This do file decomposes workers' vertical promotions into three categories.

In particular, I create three variables PromWLSameSubFuncC PromWLDiffSubFuncC PromWLDiffFuncC such that 
    PromWLC = PromWLSameSubFuncC + PromWLDiffSubFuncC + PromWLDiffFuncC

Then, I run event studies regressions on these four variables and report quarter 28 estimates.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month 0 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [0, +84], while for HtoH and HtoL groups, the relative time period is [0, +60].

Input: 
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file

Output:
    "${Results}/logfile_20241127_DecompPromWLC.txt"

Results:
    "${Results}/FT_Gains_DecompPromWLC_Q28.gph"

RA: WWZ 
Time: 2024-11-19
*/

capture log close
log using "${Results}/logfile_20241127_DecompPromWLC", replace text

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers 

codebook PromWLC 
    //&? at most two vertical promotions 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. decompose PromWL into three categories:
*??         (1) within subfunction 
*??         (2) within function, outside subfunction 
*??         (3) outside function
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. function and subfunction info at event time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Func_Event    = mean(cond(FT_Rel_Time==0, Func, .))
bysort IDlse: egen SubFunc_Event = mean(cond(FT_Rel_Time==0, SubFunc, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. function and subfunction info at promotion dates 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen YM_PromWL1 = min(cond(PromWLC==1, YearMonth, .))
bysort IDlse: egen YM_PromWL2 = min(cond(PromWLC==2, YearMonth, .))

sort IDlse YearMonth
bysort IDlse: egen Func_PromWL1    = mean(cond(YearMonth==YM_PromWL1, Func, .))
bysort IDlse: egen SubFunc_PromWL1 = mean(cond(YearMonth==YM_PromWL1, SubFunc, .))

sort IDlse YearMonth
bysort IDlse: egen Func_PromWL2    = mean(cond(YearMonth==YM_PromWL2, Func, .))
bysort IDlse: egen SubFunc_PromWL2 = mean(cond(YearMonth==YM_PromWL2, SubFunc, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. decomposition 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate PromWLSameSubFunc = PromWL
replace  PromWLSameSubFunc = 0 if PromWLSameSubFunc==1 & YearMonth==YM_PromWL1 & SubFunc_Event!=SubFunc_PromWL1
replace  PromWLSameSubFunc = 0 if PromWLSameSubFunc==1 & YearMonth==YM_PromWL2 & SubFunc_Event!=SubFunc_PromWL2

generate PromWLDiffSubFunc = PromWL
replace  PromWLDiffSubFunc = 0 if PromWLDiffSubFunc==1 & YearMonth==YM_PromWL1 & (SubFunc_Event==SubFunc_PromWL1 | Func_Event!=Func_PromWL1)
replace  PromWLDiffSubFunc = 0 if PromWLDiffSubFunc==1 & YearMonth==YM_PromWL2 & (SubFunc_Event==SubFunc_PromWL2 | Func_Event!=Func_PromWL2)

generate PromWLDiffFunc = PromWL
replace  PromWLDiffFunc = 0 if PromWLDiffFunc==1 & YearMonth==YM_PromWL1 & Func_Event==Func_PromWL1
replace  PromWLDiffFunc = 0 if PromWLDiffFunc==1 & YearMonth==YM_PromWL2 & Func_Event==Func_PromWL2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. cumulative sum of these decomposed variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in PromWLSameSubFunc PromWLDiffSubFunc PromWLDiffFunc {
    generate temp = `var'
    by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 & `var'!=.
    replace temp = 0 if temp==. & `var'!=.
    generate `var'C = temp 
    drop temp 
}

sort IDlse YearMonth 
order IDlse YearMonth PromWLC PromWLSameSubFuncC PromWLDiffSubFuncC PromWLDiffFuncC

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Month 0 is omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. FT_LtoL_X_Post1 FT_LtoH_X_Post1 FT_HtoH_X_Post12
For binned dummies, e.g. FT_LtoH_X_Post_After84 FT_HtoH_X_Post_After60
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. event * period dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
summarize FT_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! FT_LtoL
forvalues time = 0/`Lto_max_post_period' {
    generate byte FT_LtoL_X_Post`time' = FT_LtoL * (FT_Rel_Time == `time')
}
generate byte FT_LtoL_X_Post_After`Lto_max_post_period' = FT_LtoL * (FT_Rel_Time > `Lto_max_post_period')

*!! FT_LtoH
forvalues time = 0/`Lto_max_post_period' {
    generate byte FT_LtoH_X_Post`time' = FT_LtoH * (FT_Rel_Time == `time')
}
generate byte FT_LtoH_X_Post_After`Lto_max_post_period' = FT_LtoH * (FT_Rel_Time > `Lto_max_post_period')

*!! FT_HtoH 
forvalues time = 0/`Hto_max_post_period' {
    generate byte FT_HtoH_X_Post`time' = FT_HtoH * (FT_Rel_Time == `time')
}
generate byte FT_HtoH_X_Post_After`Hto_max_post_period' = FT_HtoH * (FT_Rel_Time > `Hto_max_post_period')

*!! FT_HtoL 
forvalues time = 0/`Hto_max_post_period' {
    generate byte FT_HtoL_X_Post`time' = FT_HtoL * (FT_Rel_Time == `time')
}
generate byte FT_HtoL_X_Post_After`Hto_max_post_period' = FT_HtoL * (FT_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop FT_LtoL_X_Post FT_LtoH_X_Post FT_HtoH_X_Post FT_HtoL_X_Post

foreach event in FT_LtoL FT_LtoH {
    forvalues time = 1/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in FT_HtoH FT_HtoL {
    forvalues time = 1/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${FT_LtoL_X_Post} ${FT_LtoH_X_Post} ${FT_HtoH_X_Post} ${FT_HtoL_X_Post}

display "${four_events_dummies}"

    // FT_LtoL_X_Post1 FT_LtoL_X_Post2 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Post1 FT_LtoH_X_Post2 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 
    // FT_HtoH_X_Post1 FT_HtoH_X_Post2 ... FT_HtoH_X_Post60 FT_HtoH_X_Pre_After60 
    // FT_HtoL_X_Post1 FT_HtoL_X_Post2 ... FT_HtoL_X_Post60 FT_HtoL_X_Pre_After60 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. Post variable 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_Post = (FT_Rel_Time>=0) if FT_Rel_Time!=.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions and create the coefplot
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in PromWLC PromWLSameSubFuncC PromWLDiffSubFuncC PromWLDiffFuncC {

    reghdfe `var' ${four_events_dummies} if ((FT_Mngr_both_WL2==1) & (FT_Post==1)), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

    *&& Quarter 28th estimate = the average of Month 82, Month 83, and Month 84 estimates
    xlincom (lc_1 = ((FT_LtoH_X_Post82 - FT_LtoL_X_Post82) + (FT_LtoH_X_Post83 - FT_LtoL_X_Post83) + (FT_LtoH_X_Post84 - FT_LtoL_X_Post84))/3), level(95) post

    eststo `var'
}

coefplot ///
    (PromWLC,            keep(lc_1) rename(lc_1 = "All vertical promotions")  noci recast(bar)) ///
    (PromWLSameSubFuncC, keep(lc_1) rename(lc_1 = "Same subfunction") noci recast(bar)) ///
    (PromWLDiffSubFuncC, keep(lc_1) rename(lc_1 = "Different subfunction, same function") noci recast(bar)) ///
    (PromWLDiffFuncC,    keep(lc_1) rename(lc_1 = "Different function") noci recast(bar) ) ///
    , legend(off) xline(0, lpattern(dash)) ///
    xsize(5) ysize(2) ylabel(, labsize(large)) ///
    xscale(r(0 0.03)) xlabel(0(0.005)0.03, grid gstyle(dot) labsize(medlarge)) ///
    scheme(tab2) ///
    graphregion(margin(medium)) plotregion(margin(medium)) ///
    title("Effects of gaining a high-flyer manager", size(large))

graph save "${Results}/FT_Gains_DecompPromWLC_Q28.gph", replace


log close 