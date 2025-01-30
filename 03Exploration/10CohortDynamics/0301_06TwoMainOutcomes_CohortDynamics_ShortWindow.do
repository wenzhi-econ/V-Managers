/* 
This do file computes a variant version of cohort-average treatment effects based on Liyang Sun and Sarah Abraham, "Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects," Journal of Econometrics 225, no. 2 (2021): 175–99, https://doi.org/10.1016/j.jeconom.2020.09.006.

Original codes are adapted from "4.2.2.CohortDynamic.do" and "_CoeffProgram.do"

To reduce the computational burden, the time window is shortened to [-6, +36] in this do file. (The original time window is [-60, +84].)

RA: WWZ 
Time: 2024-12-24
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare the interaction terms
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close
log using "${Results}/logfile_20241224_TwoMainOutcomes_CohortDynamics_ShortWindow", replace text

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep a panel of event workers

keep if inrange(FT_Rel_Time, -7, 37)
    //&? keep only relative periods [-7, +37]
    //&? In event studies, I use only periods [-6, +36]. The two more periods are kept for robustness.

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. the ordinary event * relative periods indicators
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. FT_LtoL_X_Pre1 FT_LtoH_X_Post0 FT_HtoH_X_Post12
For binned dummies, e.g. FT_LtoL_X_Pre_Before36 FT_LtoH_X_Post_After84
*/
summarize FT_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 6 
local Lto_max_post_period = 36
local Hto_max_post_period = 36

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
*-? s-1-2. global macros for the ordinary event * relative periods indicators
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 6 
local Lto_max_post_period = 36
local Hto_max_post_period = 36

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

    // FT_LtoL_X_Pre_Before6 FT_LtoL_X_Pre6 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post36 FT_LtoL_X_Pre_After36 
    // FT_LtoH_X_Pre_Before6 FT_LtoH_X_Pre6 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post36 FT_LtoH_X_Pre_After36 
    // FT_HtoH_X_Pre_Before6 FT_HtoH_X_Pre6 ... FT_HtoH_X_Pre4 FT_HtoH_X_Post0 FT_HtoH_X_Post1 ... FT_HtoH_X_Post36 FT_HtoH_X_Pre_After36 
    // FT_HtoL_X_Pre_Before6 FT_HtoL_X_Pre6 ... FT_HtoL_X_Pre4 FT_HtoL_X_Post0 FT_HtoL_X_Post1 ... FT_HtoL_X_Post36 FT_HtoL_X_Pre_After36 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. interaction with cohort indicators (which year the event takes place)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate YEi = year(dofm(FT_Event_Time))

forval yy = 2011(1)2020 {
    generate byte cohort`yy' = (YEi == `yy') 
    foreach l in $four_events_dummies {
        generate byte `l'_`yy'  = cohort`yy'* `l' 
        local eventinteract "`eventinteract' `l'_`yy'"
    }
}
global eventinteract `eventinteract'
display "${eventinteract}"

    // FT_LtoL_X_Pre_Before6_2011 FT_LtoL_X_Pre6_2011 ... FT_LtoL_X_Pre4_2011 FT_LtoL_X_Post0_2011 FT_LtoL_X_Post1_2011 ... FT_LtoL_X_Post36_2011 FT_LtoL_X_Pre_After36_2011
    // ...
    // FT_LtoL_X_Pre_Before6_2020 FT_LtoL_X_Pre6_2020 ... FT_LtoL_X_Pre4_2020 FT_LtoL_X_Post0_2020 FT_LtoL_X_Post1_2020 ... FT_LtoL_X_Post36_2020 FT_LtoL_X_Pre_After36_2020
    // ...
    // FT_HtoL_X_Pre_Before6_2011 FT_HtoL_X_Pre6_2011 ... FT_HtoL_X_Pre4_2011 FT_HtoL_X_Post0_2011 FT_HtoL_X_Post1_2011 ... FT_HtoL_X_Post36_2011 FT_HtoL_X_Pre_After36_2011 
    // ...
    // FT_HtoL_X_Pre_Before6_2020 FT_HtoL_X_Pre6_2020 ... FT_HtoL_X_Pre4_2020 FT_HtoL_X_Post0_2020 FT_HtoL_X_Post1_2020 ... FT_HtoL_X_Post36_2020 FT_HtoL_X_Pre_After36_2020

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSJVC ChangeSalaryGradeC {

    if "`var'" == "TransferSJVC"       global title "Lateral move"
    if "`var'" == "ChangeSalaryGradeC" global title "Salary grade increase"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${eventinteract} if (FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) & inrange(FT_Rel_Time, -6, 36), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! quarterly estimates
    LH_minus_LL_CohortDynamics, event_prefix(FT) pre_window_len(6) post_window_len(36) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-2(2)12, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off)
    graph save "${Results}/FT_Gains_AllEstimates_`var'_CohortDynamics_Pre6Post36.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! quarterly estimates
    HL_minus_HH_CohortDynamics, event_prefix(FT) pre_window_len(6) post_window_len(36) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-2(2)12, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off)
    graph save "${Results}/FT_Loss_AllEstimates_`var'_CohortDynamics_Pre6Post36.gph", replace   
    
}

keep coeff_* quarter_* lb_* ub_* 

keep if inrange(_n, 1, 41)

save "${Results}/FT_TwoMainOutcomes_CohortDynamics_Pre6Post36.dta", replace 

log close