/* 
This do file conducts event studies on the main outcomes of interest. 
In all regressions, all four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
It takes a very long time to produce the results. Therefore, for later convenience, all results (quarterly aggregated coefficients and p-values) will be stored in a do file. 

The outcome variable can only be defined for post-event periods, so the coef programs should be stored in 2024, 0205, and 0206 do files.

Input: 
    "${TempData}/03MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0104 do file

Output:
    "${Results}/WithoutControlWorkers_FT_PromWL.dta"

RA: WWZ 
Time: 2024-10-16
*/

capture log close
log using "${Results}/logfile_2024106_PromWL_WithoutControlWorkers_EarlyAgeM", replace text

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group, so in Lines 30 and 42, iteration ends with 4.
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. event * period dummies 
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
*-? s-0-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local Lto_max_post_period = 84
local Hto_max_post_period = 60

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
*-? s-0-3. Post variable 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_Post = (FT_Rel_Time>=0) if FT_Rel_Time!=.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. Transfer Outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in PromWLC {

    if "`var'" == "PromWLC" {
        global title "Work-level promotions"
    }

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if (FT_Mngr_both_WL2==1 & FT_Post==1), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

        //&? Exclude all control workers.
        //&? No need to add FT_Never_ChangeM==0 restriction as FT_Post is only defined for this group.
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! quarterly estimates
    LH_minus_LL_OnlyPost, event_prefix(FT) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) ///
        xlabel(0(2)28) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off)
    graph save "${Results}/WithoutControlWorkers_FT_Gains_AllEstimates_`var'.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! quarterly estimates
    HL_minus_HH_OnlyPost, event_prefix(FT) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) ///
        xlabel(0(2)20) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off)
    graph save "${Results}/WithoutControlWorkers_FT_Loss_AllEstimates_`var'.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! post-event joint p-value
    postevent_Double_Diff_OnlyPost, event_prefix(FT) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'}

    *!! quarterly estimates
    Double_Diff_OnlyPost, event_prefix(FT) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) ///
        xlabel(0(2)20) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note("Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/WithoutControlWorkers_FT_GainsMinusLoss_AllEstimates_`var'.gph", replace
    
}

keep coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* 

save "${Results}/WithoutControlWorkers_FT_PromWL.dta", replace 

log close
