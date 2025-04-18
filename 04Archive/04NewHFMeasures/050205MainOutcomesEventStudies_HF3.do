/* 
This do file conducts event studies on the main outcomes of interest. 
In all regressions, all four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
It takes a very long time to produce the results. Therefore, for later convenience, all results (quarterly aggregated coefficients and p-values) will be stored in a do file. 

Input: 
    "${TempData}/03MainOutcomesInEventStudies.dta"

Output:


RA: WWZ 
Time: 2024-10-08
*/

capture log close
log using "${Results}/logfile_20241008_MainOutcomes_WithoutControlWorkers_MeasureHF3", replace text

use "${TempData}/05MainOutcomesInEventStudies_TwoNewHFMeasures.dta", clear

/* keep if inrange(_n, 1, 1000000)  */
    // used to test the codes
    // commented out when offically producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group, so in Lines 30 and 42, iteration ends with 4.
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

foreach event in HF3_LtoL HF3_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in HF3_LtoL HF3_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in HF3_HtoH HF3_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in HF3_HtoH HF3_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${HF3_LtoL_X_Pre} ${HF3_LtoL_X_Post} ${HF3_LtoH_X_Pre} ${HF3_LtoH_X_Post} ${HF3_HtoH_X_Pre} ${HF3_HtoH_X_Post} ${HF3_HtoL_X_Pre} ${HF3_HtoL_X_Post}

display "${four_events_dummies}"

    // HF3_LtoL_X_Pre_Before36 HF3_LtoL_X_Pre36 ... HF3_LtoL_X_Pre4 HF3_LtoL_X_Post0 HF3_LtoL_X_Post1 ... HF3_LtoL_X_Post84 HF3_LtoL_X_Pre_After84 
    // HF3_LtoH_X_Pre_Before36 HF3_LtoH_X_Pre36 ... HF3_LtoH_X_Pre4 HF3_LtoH_X_Post0 HF3_LtoH_X_Post1 ... HF3_LtoH_X_Post84 HF3_LtoH_X_Pre_After84 
    // HF3_HtoH_X_Pre_Before36 HF3_HtoH_X_Pre36 ... HF3_HtoH_X_Pre4 HF3_HtoH_X_Post0 HF3_HtoH_X_Post1 ... HF3_HtoH_X_Post60 HF3_HtoH_X_Pre_After60 
    // HF3_HtoL_X_Pre_Before36 HF3_HtoL_X_Pre36 ... HF3_HtoL_X_Pre4 HF3_HtoL_X_Post0 HF3_HtoL_X_Post1 ... HF3_HtoL_X_Post60 HF3_HtoL_X_Pre_After60 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. Transfer Outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSJVC TransferFuncC ChangeSalaryGradeC {

    if "`var'" == "TransferSJVC"       global title "Lateral move"
    if "`var'" == "TransferFuncC"      global title "Lateral move, function"
    if "`var'" == "ChangeSalaryGradeC" global title "Salary grade increase"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if (HF3_Mngr_both_WL2==1 & HF3_Never_ChangeM==0), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

        //&? Exclude all control workers.
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(HF3) pre_window_len(36)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'}

    *!! quarterly estimates
    LH_minus_LL, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)28) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
    graph save "${Results}/WithoutControlWorkers_HF3_Gains_AllEstimates_`var'.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(HF3) pre_window_len(36)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'}

    *!! quarterly estimates
    HL_minus_HH, event_prefix(HF3) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20) /// 
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
    graph save "${Results}/WithoutControlWorkers_HF3_Loss_AllEstimates_`var'.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(HF3) pre_window_len(36)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'}

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(HF3) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'}

    *!! quarterly estimates
    Double_Diff, event_prefix(HF3) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20) /// 
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/WithoutControlWorkers_HF3_GainsMinusLoss_AllEstimates_`var'.gph", replace
    
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. Salary Outcomes 
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

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if (HF3_Mngr_both_WL2==1 & HF3_Never_ChangeM==0), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

        //&? Exclude all control workers.
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(HF3) pre_window_len(36)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'}

    *!! quarterly estimates
    LH_minus_LL, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)28) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
    graph save "${Results}/WithoutControlWorkers_HF3_Gains_AllEstimates_`var'.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(HF3) pre_window_len(36)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'}

    *!! quarterly estimates
    HL_minus_HH, event_prefix(HF3) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20) /// 
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
    graph save "${Results}/WithoutControlWorkers_HF3_Loss_AllEstimates_`var'.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(HF3) pre_window_len(36)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'}

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(HF3) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'}

    *!! quarterly estimates
    Double_Diff, event_prefix(HF3) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20) /// 
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/WithoutControlWorkers_HF3_GainsMinusLoss_AllEstimates_`var'.gph", replace

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 5. Additional three-quarter estimates plot 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *&& Quarter 12 estimate is the average of Month 34, Month 35, and Month 36 estimates
    *&& Quarter 20 estimate is the average of Month 58, Month 59, and Month 60 estimates
    *&& Quarter 28 estimate is the average of Month 82, Month 83, and Month 84 estimates

    xlincom ///
        (((HF3_LtoH_X_Post34 - HF3_LtoL_X_Post34) + (HF3_LtoH_X_Post35 - HF3_LtoL_X_Post35) + (HF3_LtoH_X_Post36 - HF3_LtoL_X_Post36))/3) ///
        (((HF3_LtoH_X_Post58 - HF3_LtoL_X_Post58) + (HF3_LtoH_X_Post59 - HF3_LtoL_X_Post59) + (HF3_LtoH_X_Post60 - HF3_LtoL_X_Post60))/3) ///
        (((HF3_LtoH_X_Post82 - HF3_LtoL_X_Post82) + (HF3_LtoH_X_Post83 - HF3_LtoL_X_Post83) + (HF3_LtoH_X_Post84 - HF3_LtoL_X_Post84))/3) ///
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
        xlabel(, labsize(vlarge)) // ///
        // ${yaxis_setup}

    graph save "${Results}/WithoutControlWorkers_HF3_Gains_ThreeQuarterEstimates_`var'.gph", replace
}

keep PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* 

save "${Results}/WithoutControlWorkers_HF3_MainResults.dta", replace 

log close
