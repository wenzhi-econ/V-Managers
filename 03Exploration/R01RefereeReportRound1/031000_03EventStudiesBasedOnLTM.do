/* 
This do file runs event studies on the two main outcomes, based on the LT measure.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 
    "${TempData}/EventStudyDummies_LTM.dta"        <== created in 031000_02 do file 


RA: WWZ 
Time: 2024-12-20
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close
log using "${Results}/logfile_20241220_TwoMainOutcomesInEventStudies_LTM", replace text

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. get event study dummies based on LTM measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${TempData}/EventStudyDummies_LTM.dta", nogenerate

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*!! drop old event study dummies based on EarlyAgeM
drop ///
    FT_Mngr_both_WL2 FT_Never_ChangeM FT_Rel_Time ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    FT_Event_Time FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL

*!! new event study dummies 
order ///
    HFT_Mngr_both_WL2 HFT_Never_ChangeM HFT_Rel_Time ///
    HFT_LtoL HFT_LtoH HFT_HtoH HFT_HtoL ///
    HFT_Event_Time HFT_Calend_Time_LtoL HFT_Calend_Time_LtoH HFT_Calend_Time_HtoH HFT_Calend_Time_HtoL ///
    , after(ChangeMR)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate "event * relative period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
summarize HFT_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! HFT_LtoL
generate byte HFT_LtoL_X_Pre_Before`max_pre_period' = HFT_LtoL * (HFT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte HFT_LtoL_X_Pre`time' = HFT_LtoL * (HFT_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte HFT_LtoL_X_Post`time' = HFT_LtoL * (HFT_Rel_Time == `time')
}
generate byte HFT_LtoL_X_Post_After`Lto_max_post_period' = HFT_LtoL * (HFT_Rel_Time > `Lto_max_post_period')

*!! HFT_LtoH
generate byte HFT_LtoH_X_Pre_Before`max_pre_period' = HFT_LtoH * (HFT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte HFT_LtoH_X_Pre`time' = HFT_LtoH * (HFT_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte HFT_LtoH_X_Post`time' = HFT_LtoH * (HFT_Rel_Time == `time')
}
generate byte HFT_LtoH_X_Post_After`Lto_max_post_period' = HFT_LtoH * (HFT_Rel_Time > `Lto_max_post_period')

*!! HFT_HtoH 
generate byte HFT_HtoH_X_Pre_Before`max_pre_period' = HFT_HtoH * (HFT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte HFT_HtoH_X_Pre`time' = HFT_HtoH * (HFT_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte HFT_HtoH_X_Post`time' = HFT_HtoH * (HFT_Rel_Time == `time')
}
generate byte HFT_HtoH_X_Post_After`Hto_max_post_period' = HFT_HtoH * (HFT_Rel_Time > `Hto_max_post_period')

*!! HFT_HtoL 
generate byte HFT_HtoL_X_Pre_Before`max_pre_period' = HFT_HtoL * (HFT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte HFT_HtoL_X_Pre`time' = HFT_HtoL * (HFT_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte HFT_HtoL_X_Post`time' = HFT_HtoL * (HFT_Rel_Time == `time')
}
generate byte HFT_HtoL_X_Post_After`Hto_max_post_period' = HFT_HtoL * (HFT_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop HFT_LtoL_X_Pre HFT_LtoL_X_Post HFT_LtoH_X_Pre HFT_LtoH_X_Post HFT_HtoH_X_Pre HFT_HtoH_X_Post HFT_HtoL_X_Pre HFT_HtoL_X_Post

foreach event in HFT_LtoL HFT_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in HFT_LtoL HFT_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in HFT_HtoH HFT_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in HFT_HtoH HFT_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${HFT_LtoL_X_Pre} ${HFT_LtoL_X_Post} ${HFT_LtoH_X_Pre} ${HFT_LtoH_X_Post} ${HFT_HtoH_X_Pre} ${HFT_HtoH_X_Post} ${HFT_HtoL_X_Pre} ${HFT_HtoL_X_Post}

display "${four_events_dummies}"

    // HFT_LtoL_X_Pre_Before36 HFT_LtoL_X_Pre36 ... HFT_LtoL_X_Pre4 HFT_LtoL_X_Post0 HFT_LtoL_X_Post1 ... HFT_LtoL_X_Post84 HFT_LtoL_X_Pre_After84 
    // HFT_LtoH_X_Pre_Before36 HFT_LtoH_X_Pre36 ... HFT_LtoH_X_Pre4 HFT_LtoH_X_Post0 HFT_LtoH_X_Post1 ... HFT_LtoH_X_Post84 HFT_LtoH_X_Pre_After84 
    // HFT_HtoH_X_Pre_Before36 HFT_HtoH_X_Pre36 ... HFT_HtoH_X_Pre4 HFT_HtoH_X_Post0 HFT_HtoH_X_Post1 ... HFT_HtoH_X_Post60 HFT_HtoH_X_Pre_After60 
    // HFT_HtoL_X_Pre_Before36 HFT_HtoL_X_Pre36 ... HFT_HtoL_X_Pre4 HFT_HtoL_X_Post0 HFT_HtoL_X_Post1 ... HFT_HtoL_X_Post60 HFT_HtoL_X_Pre_After60 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. event studies on the two main outcomes based on LTM
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSJVC ChangeSalaryGradeC {

    if "`var'" == "TransferSJVC"       global title "Lateral move"
    if "`var'" == "ChangeSalaryGradeC" global title "Salary grade increase"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if (HFT_Mngr_both_WL2==1 & HFT_Never_ChangeM==0), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(HFT) pre_window_len(36)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    LH_minus_LL, event_prefix(HFT) pre_window_len(36) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)28, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
    graph save "${Results}/HFT_Gains_AllEstimates_`var'.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(HFT) pre_window_len(36)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    HL_minus_HH, event_prefix(HFT) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
    graph save "${Results}/HFT_Loss_AllEstimates_`var'.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(HFT) pre_window_len(36)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(HFT) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    Double_Diff, event_prefix(HFT) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/HFT_GainsMinusLoss_AllEstimates_`var'.gph", replace
    
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

save "${Results}/HFT_TwoMainOutcomes.dta", replace 

log close

