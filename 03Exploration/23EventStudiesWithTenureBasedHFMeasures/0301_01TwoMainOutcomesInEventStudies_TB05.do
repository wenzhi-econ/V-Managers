/* 
This do file runs event study regressions on two main outcomes of interest: TransferSJVC ChangeSalaryGradeC.
The high-flyer measure used here is TB05.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60].

Some key results (quarterly aggregated coefficients with their p-values, and other key summary statistics) are stored in the output file. 

Input: 
    "${TempData}/FinalAnalysisSample_Simplified_WithTenureBasedMeasures.dta"   <== created in 23/0103_02 do file

Output:
    "${Results}/006EventStudiesWithTenureBasedMeasures/20250502log_TwoMainOutcomes_MeasureTB05.txt"
    "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_MeasureTB05.dta"

RA: WWZ 
Time: 2025-05-02
*/

capture log close
log using "${Results}/006EventStudiesWithTenureBasedMeasures/20250502log_TwoMainOutcomes_MeasureTB05.txt", replace text

use "${TempData}/FinalAnalysisSample_Simplified_WithTenureBasedMeasures.dta", clear

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct variables and macros used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. TB05_LtoL_X_Pre1 TB05_LtoH_X_Post0 TB05_HtoH_X_Post12
For binned dummies, e.g. TB05_LtoL_X_Pre_Before36 TB05_LtoH_X_Post_After84
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. "event * relative period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate  TB05_Rel_Time = Rel_Time
summarize TB05_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 24 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! TB05_LtoL
generate byte TB05_LtoL_X_Pre_Before`max_pre_period' = TB05_LtoL * (TB05_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB05_LtoL_X_Pre`time' = TB05_LtoL * (TB05_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte TB05_LtoL_X_Post`time' = TB05_LtoL * (TB05_Rel_Time == `time')
}
generate byte TB05_LtoL_X_Post_After`Lto_max_post_period' = TB05_LtoL * (TB05_Rel_Time > `Lto_max_post_period')

*!! TB05_LtoH
generate byte TB05_LtoH_X_Pre_Before`max_pre_period' = TB05_LtoH * (TB05_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB05_LtoH_X_Pre`time' = TB05_LtoH * (TB05_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte TB05_LtoH_X_Post`time' = TB05_LtoH * (TB05_Rel_Time == `time')
}
generate byte TB05_LtoH_X_Post_After`Lto_max_post_period' = TB05_LtoH * (TB05_Rel_Time > `Lto_max_post_period')

*!! TB05_HtoH 
generate byte TB05_HtoH_X_Pre_Before`max_pre_period' = TB05_HtoH * (TB05_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB05_HtoH_X_Pre`time' = TB05_HtoH * (TB05_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte TB05_HtoH_X_Post`time' = TB05_HtoH * (TB05_Rel_Time == `time')
}
generate byte TB05_HtoH_X_Post_After`Hto_max_post_period' = TB05_HtoH * (TB05_Rel_Time > `Hto_max_post_period')

*!! TB05_HtoL 
generate byte TB05_HtoL_X_Pre_Before`max_pre_period' = TB05_HtoL * (TB05_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB05_HtoL_X_Pre`time' = TB05_HtoL * (TB05_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte TB05_HtoL_X_Post`time' = TB05_HtoL * (TB05_Rel_Time == `time')
}
generate byte TB05_HtoL_X_Post_After`Hto_max_post_period' = TB05_HtoL * (TB05_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 24 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop TB05_LtoL_X_Pre TB05_LtoL_X_Post TB05_LtoH_X_Pre TB05_LtoH_X_Post TB05_HtoH_X_Pre TB05_HtoH_X_Post TB05_HtoL_X_Pre TB05_HtoL_X_Post

foreach event in TB05_LtoL TB05_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in TB05_LtoL TB05_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in TB05_HtoH TB05_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in TB05_HtoH TB05_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${TB05_LtoL_X_Pre} ${TB05_LtoL_X_Post} ${TB05_LtoH_X_Pre} ${TB05_LtoH_X_Post} ${TB05_HtoH_X_Pre} ${TB05_HtoH_X_Post} ${TB05_HtoL_X_Pre} ${TB05_HtoL_X_Post}

display "${four_events_dummies}"

    // TB05_LtoL_X_Pre_Before24 TB05_LtoL_X_Pre24 ... TB05_LtoL_X_Pre4 TB05_LtoL_X_Post0 TB05_LtoL_X_Post1 ... TB05_LtoL_X_Post84 TB05_LtoL_X_Pre_After84 
    // TB05_LtoH_X_Pre_Before24 TB05_LtoH_X_Pre24 ... TB05_LtoH_X_Pre4 TB05_LtoH_X_Post0 TB05_LtoH_X_Post1 ... TB05_LtoH_X_Post84 TB05_LtoH_X_Pre_After84 
    // TB05_HtoH_X_Pre_Before24 TB05_HtoH_X_Pre24 ... TB05_HtoH_X_Pre4 TB05_HtoH_X_Post0 TB05_HtoH_X_Post1 ... TB05_HtoH_X_Post60 TB05_HtoH_X_Pre_After60 
    // TB05_HtoL_X_Pre_Before24 TB05_HtoL_X_Pre24 ... TB05_HtoL_X_Pre4 TB05_HtoL_X_Post0 TB05_HtoL_X_Post1 ... TB05_HtoL_X_Post60 TB05_HtoL_X_Pre_After60 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. event studies on the two main outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSJVC ChangeSalaryGradeC {

    if "`var'" == "TransferSJVC"       global title "Lateral move"
    if "`var'" == "ChangeSalaryGradeC" global title "Salary grade increase"

    if "`var'" == "TransferSJVC"       global number "1"
    if "`var'" == "ChangeSalaryGradeC" global number "2"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(TB05) pre_window_len(24)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    LH_minus_LL, event_prefix(TB05) pre_window_len(24) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
    graph save "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_Outcome${number}_`var'_Coef1_Gains.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(TB05) pre_window_len(24)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    HL_minus_HH, event_prefix(TB05) pre_window_len(24) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
    graph save "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_Outcome${number}_`var'_Coef2_Loss.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(TB05) pre_window_len(24)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(TB05) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    Double_Diff, event_prefix(TB05) pre_window_len(24) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_Outcome${number}_`var'_Coef3_GainsMinusLoss.gph", replace
    
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. store the event studies results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep ///
    PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* ///
    LtoL_* LtoH_* HtoH_* HtoL_* ///
    coef1_* coefp1_* coef2_* coefp2_* coef3_* coefp3_* coef4_* coefp4_* coef5_* coefp5_* coef6_* coefp6_* ///
    RI1_* rip1_* RI2_* rip2_* RI3_* rip3_*

keep if inrange(_n, 1, 41)

save "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_MeasureTB05.dta", replace 

log close
