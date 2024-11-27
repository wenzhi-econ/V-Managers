/* 
This do file aims to replicate Figure V in the paper (June 14, 2024 version).
The four outcome variables of interest are:
    LogPayBonus LogPay LogBonus PromWLC

Input: 
    "${TempData}/temp_MainOutcomesInEventStudies.dta"

Output:
    4 coefficient plots (4 outcome variables, 1 figure for each outcome variable)

RA: WWZ 
Time: 2024-09-19
*/

capture log close
log using "${Results}/logfile_20240920_SalaryOutcomes", replace text

use "${TempData}/temp_MainOutcomesInEventStudies.dta", clear 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group, so in Lines 30 and 42, iteration ends with 4.
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

capture macro drop FT_LtoL_X_Pre
capture macro drop FT_LtoL_X_Post
capture macro drop FT_LtoH_X_Pre
capture macro drop FT_LtoH_X_Post
capture macro drop FT_HtoH_X_Pre
capture macro drop FT_HtoH_X_Post
capture macro drop FT_HtoL_X_Pre
capture macro drop FT_HtoL_X_Post

local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

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
*?? step 1. run regressions and present quarterly coefficients 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in LogPayBonus LogPay LogBonus {

    if "`var'" == "LogPayBonus" global title "Pay + bonus (logs)"
    if "`var'" == "LogPay"      global title "Pay (logs)"
    if "`var'" == "LogBonus"    global title "Bonus (logs)"

    if "`var'" == "LogBonus" {
        global yaxis_setup "ylabel(0(0.5)1.5) yscale(range(0 1.5))"
    }
    else {
        global yaxis_setup "ylabel(0(0.05)0.15) yscale(range(0 0.15))"
    }


    reghdfe `var' ${four_events_dummies} ///
        if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
        , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

    *&& Quarter 12 estimate is the average of Month 34, Month 35, and Month 36 estimates
    *&& Quarter 20 estimate is the average of Month 58, Month 59, and Month 60 estimates
    *&& Quarter 28 estimate is the average of Month 82, Month 83, and Month 84 estimates

    xlincom ///
        (((FT_LtoH_X_Post34 - FT_LtoL_X_Post34) + (FT_LtoH_X_Post35 - FT_LtoL_X_Post35) + (FT_LtoH_X_Post36 - FT_LtoL_X_Post36))/3) ///
        (((FT_LtoH_X_Post58 - FT_LtoL_X_Post58) + (FT_LtoH_X_Post59 - FT_LtoL_X_Post59) + (FT_LtoH_X_Post60 - FT_LtoL_X_Post60))/3) ///
        (((FT_LtoH_X_Post82 - FT_LtoL_X_Post82) + (FT_LtoH_X_Post83 - FT_LtoL_X_Post83) + (FT_LtoH_X_Post84 - FT_LtoL_X_Post84))/3) ///
        , level(95) post

    eststo `var'

    coefplot  ///
        (`var', keep(lc_1) rename(lc_1 = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
        (`var', keep(lc_2) rename(lc_2 = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
        (`var', keep(lc_3) rename(lc_3 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
        , ciopts(lwidth(2 ..)) levels(95) vertical legend(off) ///
        graphregion(margin(medium)) plotregion(margin(medium)) ///
        msymbol(d) mcolor(white) ///
        title("${title}", size(vlarge)) ///
        yline(0, lpattern(dash)) ///
        xlabel(, labsize(vlarge)) ///
        ${yaxis_setup}

    graph save "${Results}/FT_Gains_ThreeQuarterEstimates_`var'.gph", replace
}


log close