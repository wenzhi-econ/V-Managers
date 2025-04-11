/* 
This do file runs event study regressions on three pay-relevant outcomes (LogPayBonus LogPay LogBonus) using the OM measure.

Input: 
    "${TempData}/031903FinalEventStudySample_SixHFMeasures.dta" <== created in 0104 do file

Output:
    "${Results}/20250410log_AgeBasedHF1_OM_PayOutcomes.txt"
    "${Results}/AgeBasedHF1_OM_PayOutcomes.dta"

RA: WWZ 
Time: 2024-11-19
*/
*/


capture log close
log using "${Results}/20250410log_AgeBasedHF1_OM_PayOutcomes", replace text

use "${TempData}/031903FinalEventStudySample_SixHFMeasures.dta", clear

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
For normal "event * relative period" dummies, e.g. OM_LtoL_X_Pre1 OM_LtoH_X_Post0 OM_HtoH_X_Post12
For binned dummies, e.g. OM_LtoL_X_Pre_Before36 OM_LtoH_X_Post_After84
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. "event * relative period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate OM_Rel_Time = Rel_Time

*!! time window of interest
local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! OM_LtoL
generate byte OM_LtoL_X_Pre_Before`max_pre_period' = OM_LtoL * (OM_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte OM_LtoL_X_Pre`time' = OM_LtoL * (OM_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte OM_LtoL_X_Post`time' = OM_LtoL * (OM_Rel_Time == `time')
}
generate byte OM_LtoL_X_Post_After`Lto_max_post_period' = OM_LtoL * (OM_Rel_Time > `Lto_max_post_period')

*!! OM_LtoH
generate byte OM_LtoH_X_Pre_Before`max_pre_period' = OM_LtoH * (OM_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte OM_LtoH_X_Pre`time' = OM_LtoH * (OM_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte OM_LtoH_X_Post`time' = OM_LtoH * (OM_Rel_Time == `time')
}
generate byte OM_LtoH_X_Post_After`Lto_max_post_period' = OM_LtoH * (OM_Rel_Time > `Lto_max_post_period')

*!! OM_HtoH 
generate byte OM_HtoH_X_Pre_Before`max_pre_period' = OM_HtoH * (OM_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte OM_HtoH_X_Pre`time' = OM_HtoH * (OM_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte OM_HtoH_X_Post`time' = OM_HtoH * (OM_Rel_Time == `time')
}
generate byte OM_HtoH_X_Post_After`Hto_max_post_period' = OM_HtoH * (OM_Rel_Time > `Hto_max_post_period')

*!! OM_HtoL 
generate byte OM_HtoL_X_Pre_Before`max_pre_period' = OM_HtoL * (OM_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte OM_HtoL_X_Pre`time' = OM_HtoL * (OM_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte OM_HtoL_X_Post`time' = OM_HtoL * (OM_Rel_Time == `time')
}
generate byte OM_HtoL_X_Post_After`Hto_max_post_period' = OM_HtoL * (OM_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop OM_LtoL_X_Pre OM_LtoL_X_Post OM_LtoH_X_Pre OM_LtoH_X_Post OM_HtoH_X_Pre OM_HtoH_X_Post OM_HtoL_X_Pre OM_HtoL_X_Post

foreach event in OM_LtoL OM_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in OM_LtoL OM_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in OM_HtoH OM_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in OM_HtoH OM_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${OM_LtoL_X_Pre} ${OM_LtoL_X_Post} ${OM_LtoH_X_Pre} ${OM_LtoH_X_Post} ${OM_HtoH_X_Pre} ${OM_HtoH_X_Post} ${OM_HtoL_X_Pre} ${OM_HtoL_X_Post}

display "${four_events_dummies}"

    // OM_LtoL_X_Pre_Before36 OM_LtoL_X_Pre36 ... OM_LtoL_X_Pre4 OM_LtoL_X_Post0 OM_LtoL_X_Post1 ... OM_LtoL_X_Post84 OM_LtoL_X_Pre_After84 
    // OM_LtoH_X_Pre_Before36 OM_LtoH_X_Pre36 ... OM_LtoH_X_Pre4 OM_LtoH_X_Post0 OM_LtoH_X_Post1 ... OM_LtoH_X_Post84 OM_LtoH_X_Pre_After84 
    // OM_HtoH_X_Pre_Before36 OM_HtoH_X_Pre36 ... OM_HtoH_X_Pre4 OM_HtoH_X_Post0 OM_HtoH_X_Post1 ... OM_HtoH_X_Post60 OM_HtoH_X_Pre_After60 
    // OM_HtoL_X_Pre_Before36 OM_HtoL_X_Pre36 ... OM_HtoL_X_Pre4 OM_HtoL_X_Post0 OM_HtoL_X_Post1 ... OM_HtoL_X_Post60 OM_HtoL_X_Pre_After60 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. Salary Outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in LogPayBonus LogPay LogBonus {

    if "`var'" == "LogPayBonus" global title "Pay + bonus (logs)"
    if "`var'" == "LogPay"      global title "Pay (logs)"
    if "`var'" == "LogBonus"    global title "Bonus (logs)"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(OM) pre_window_len(36)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    LH_minus_LL, event_prefix(OM) pre_window_len(36) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)28, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
    graph save "${Results}/AgeBasedHF1_OM_AllEstimates1_Gains_`var'.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(OM) pre_window_len(36)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    HL_minus_HH, event_prefix(OM) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
    graph save "${Results}/AgeBasedHF1_OM_AllEstimates2_Loss_`var'.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(OM) pre_window_len(36)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(OM) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    Double_Diff, event_prefix(OM) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/AgeBasedHF1_OM_AllEstimates3_GainsMinusLoss_`var'.gph", replace

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 5. Additional three-quarter estimates plot 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *&& Quarter 12 estimate is the average of Month 34, Month 35, and Month 36 estimates
    *&& Quarter 20 estimate is the average of Month 58, Month 59, and Month 60 estimates
    *&& Quarter 28 estimate is the average of Month 82, Month 83, and Month 84 estimates

    xlincom ///
        (((OM_LtoH_X_Post34 - OM_LtoL_X_Post34) + (OM_LtoH_X_Post35 - OM_LtoL_X_Post35) + (OM_LtoH_X_Post36 - OM_LtoL_X_Post36))/3) ///
        (((OM_LtoH_X_Post58 - OM_LtoL_X_Post58) + (OM_LtoH_X_Post59 - OM_LtoL_X_Post59) + (OM_LtoH_X_Post60 - OM_LtoL_X_Post60))/3) ///
        (((OM_LtoH_X_Post82 - OM_LtoL_X_Post82) + (OM_LtoH_X_Post83 - OM_LtoL_X_Post83) + (OM_LtoH_X_Post84 - OM_LtoL_X_Post84))/3) ///
        , level(95) post

    eststo `var'

    if "`var'" == "LogBonus" {
        global yaxis_setup "ylabel(0(0.5)1.5, labsize(medsmall)) yscale(range(0 1.5))"
    }
    else {
        global yaxis_setup "ylabel(0(0.05)0.15, labsize(medsmall)) yscale(range(0 0.15))"
    }

    coefplot  ///
        (`var', keep(lc_1) rename(lc_1 = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
        (`var', keep(lc_2) rename(lc_2 = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
        (`var', keep(lc_3) rename(lc_3 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
        , ciopts(lwidth(2 ..)) levels(95) vertical legend(off) ///
        graphregion(margin(medium)) plotregion(margin(medium)) ///
        msymbol(d) mcolor(white) ///
        title("${title}", span pos(12)) ///
        yline(0, lpattern(dash)) ///
        xlabel(, labsize(medlarge)) ///
        ${yaxis_setup}

    graph save "${Results}/AgeBasedHF1_OM_ThreeQuarterEstimates_`var'.gph", replace
}

keep ///
    PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* ///
    LtoL_* LtoH_* HtoH_* HtoL_* ///
    coef1_* coefp1_* coef2_* coefp2_* coef3_* coefp3_* coef4_* coefp4_* coef5_* coefp5_* coef6_* coefp6_* ///
    RI1_* rip1_* RI2_* rip2_* RI3_* rip3_*

keep if inrange(_n, 1, 41)


save "${Results}/AgeBasedHF1_OM_PayOutcomes.dta", replace 

log close
