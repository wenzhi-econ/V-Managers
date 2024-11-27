/* 
This do file does event studies based on MFEBayesLogPay measure.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0102 do file.
    "${TempData}/temp_MngrID_MFEBayesLogPay.dta" <== constructed in 0804 do file
    "${TempData}/temp_workersubsample_MFEBayesLogPay.dta" <== constructed in 0804 do file

RA: WWZ 
Time: 2024-11-05
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge MFEBayesLogPay measure 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close 

log using "${Results}/logfile_20241110_MFEBayesLogPay_Restrictions", replace text

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

keep if FT_Rel_Time!=. 
keep if FT_Mngr_both_WL2==1
    //&? keep a worker panel that contains only the event workers 

merge m:1 IDlseMHR using "${TempData}/temp_MngrID_MFEBayesLogPay_Restrictions.dta", keep(match master) nogenerate

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. MFEBayesLogPay measure for pre- and post-event managers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sort IDlse YearMonth 
bysort IDlse: egen MFEBayesLogPay_Med_Pre  = mean(cond(FT_Rel_Time==-1, MFEBayesLogPay_Med, .))
bysort IDlse: egen MFEBayesLogPay_Med_Post = mean(cond(FT_Rel_Time==0 , MFEBayesLogPay_Med, .))

bysort IDlse: egen MFEBayesLogPay_p75_Pre  = mean(cond(FT_Rel_Time==-1, MFEBayesLogPay_p75, .))
bysort IDlse: egen MFEBayesLogPay_p75_Post = mean(cond(FT_Rel_Time==0 , MFEBayesLogPay_p75, .))

order IDlse YearMonth IDlseMHR EarlyAgeM FT_Rel_Time MFEBayesLogPay_Med_Pre MFEBayesLogPay_Med_Post MFEBayesLogPay_p75_Pre MFEBayesLogPay_p75_Post

keep if MFEBayesLogPay_Med_Pre!=. & MFEBayesLogPay_Med_Post!=.
    //&? keep those workers whose both pre- and post-event managers can be identified 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. event dummies for different measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate MFEBayesLogPay_Med_LtoL = (MFEBayesLogPay_Med_Pre==0 & MFEBayesLogPay_Med_Post==0)
generate MFEBayesLogPay_Med_LtoH = (MFEBayesLogPay_Med_Pre==0 & MFEBayesLogPay_Med_Post==1)
generate MFEBayesLogPay_Med_HtoH = (MFEBayesLogPay_Med_Pre==1 & MFEBayesLogPay_Med_Post==1)
generate MFEBayesLogPay_Med_HtoL = (MFEBayesLogPay_Med_Pre==1 & MFEBayesLogPay_Med_Post==0)

generate MFEBayesLogPay_p75_LtoL = (MFEBayesLogPay_p75_Pre==0 & MFEBayesLogPay_p75_Post==0)
generate MFEBayesLogPay_p75_LtoH = (MFEBayesLogPay_p75_Pre==0 & MFEBayesLogPay_p75_Post==1)
generate MFEBayesLogPay_p75_HtoH = (MFEBayesLogPay_p75_Pre==1 & MFEBayesLogPay_p75_Post==1)
generate MFEBayesLogPay_p75_HtoL = (MFEBayesLogPay_p75_Pre==1 & MFEBayesLogPay_p75_Post==0)

sort IDlse YearMonth 
bysort IDlse: generate occurrence = _n 
count if occurrence==1 & MFEBayesLogPay_Med_LtoL==1 // 4,126
count if occurrence==1 & MFEBayesLogPay_Med_LtoH==1 // 3,438
count if occurrence==1 & MFEBayesLogPay_Med_HtoH==1 // 3,455
count if occurrence==1 & MFEBayesLogPay_Med_HtoL==1 // 4,152

count if occurrence==1 & MFEBayesLogPay_p75_LtoL==1 // 9,023
count if occurrence==1 & MFEBayesLogPay_p75_LtoH==1 // 2,317
count if occurrence==1 & MFEBayesLogPay_p75_HtoH==1 // 965
count if occurrence==1 & MFEBayesLogPay_p75_HtoL==1 // 2,866

generate MFEBayesLogPay_Med_Rel_Time = FT_Rel_Time
generate MFEBayesLogPay_p75_Rel_Time = FT_Rel_Time

generate MFEBayesLogPay_Med_Mngr_both_WL2 = FT_Mngr_both_WL2
generate MFEBayesLogPay_p75_Mngr_both_WL2 = FT_Mngr_both_WL2

generate MFEBayesLogPay_Med_Never_ChangeM = FT_Never_ChangeM
generate MFEBayesLogPay_p75_Never_ChangeM = FT_Never_ChangeM

order IDlse YearMonth ///
    MFEBayesLogPay_Med_Rel_Time MFEBayesLogPay_Med_LtoL MFEBayesLogPay_Med_LtoH MFEBayesLogPay_Med_HtoH MFEBayesLogPay_Med_HtoL MFEBayesLogPay_Med_Mngr_both_WL2 ///
    MFEBayesLogPay_p75_Rel_Time MFEBayesLogPay_p75_LtoL MFEBayesLogPay_p75_LtoH MFEBayesLogPay_p75_HtoH MFEBayesLogPay_p75_HtoL MFEBayesLogPay_p75_Mngr_both_WL2 ///
    TransferSJVC TransferFuncC ChangeSalaryGradeC PromWLC LeaverPerm

save "${TempData}/temp_MainOutcomesInEventStudies_MFEBayesLogPay.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. run regressions on 3 transfer outcomes (based on MFEBayesLogPay_Med)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_MainOutcomesInEventStudies_MFEBayesLogPay.dta", clear 

merge m:1 IDlse using "${TempData}/temp_workersubsample_MFEBayesLogPay.dta", keep(match master) nogenerate 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. construct global macros used in regressions (based on MFEBayesLogPay_Med)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& Months -1, -2, and -3 are omitted as the reference group.
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-1. generate event * relative period dummies (based on MFEBayesLogPay_Med) 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

summarize MFEBayesLogPay_Med_Rel_Time, detail // range: [-114, +129]

*!! time window of interest
local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! MFEBayes_Med_LtoL
generate byte MFEBayes_Med_LtoL_X_Pre_Before`max_pre_period' = MFEBayesLogPay_Med_LtoL * (MFEBayesLogPay_Med_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte MFEBayes_Med_LtoL_X_Pre`time' = MFEBayesLogPay_Med_LtoL * (MFEBayesLogPay_Med_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte MFEBayes_Med_LtoL_X_Post`time' = MFEBayesLogPay_Med_LtoL * (MFEBayesLogPay_Med_Rel_Time == `time')
}
generate byte MFEBayes_Med_LtoL_X_Post_After`Lto_max_post_period' = MFEBayesLogPay_Med_LtoL * (MFEBayesLogPay_Med_Rel_Time > `Lto_max_post_period')

*!! MFEBayes_Med_LtoH
generate byte MFEBayes_Med_LtoH_X_Pre_Before`max_pre_period' = MFEBayesLogPay_Med_LtoH * (MFEBayesLogPay_Med_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte MFEBayes_Med_LtoH_X_Pre`time' = MFEBayesLogPay_Med_LtoH * (MFEBayesLogPay_Med_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte MFEBayes_Med_LtoH_X_Post`time' = MFEBayesLogPay_Med_LtoH * (MFEBayesLogPay_Med_Rel_Time == `time')
}
generate byte MFEBayes_Med_LtoH_X_Post_After`Lto_max_post_period' = MFEBayesLogPay_Med_LtoH * (MFEBayesLogPay_Med_Rel_Time > `Lto_max_post_period')

*!! MFEBayes_Med_HtoH 
generate byte MFEBayes_Med_HtoH_X_Pre_Before`max_pre_period' = MFEBayesLogPay_Med_HtoH * (MFEBayesLogPay_Med_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte MFEBayes_Med_HtoH_X_Pre`time' = MFEBayesLogPay_Med_HtoH * (MFEBayesLogPay_Med_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte MFEBayes_Med_HtoH_X_Post`time' = MFEBayesLogPay_Med_HtoH * (MFEBayesLogPay_Med_Rel_Time == `time')
}
generate byte MFEBayes_Med_HtoH_X_Post_After`Hto_max_post_period' = MFEBayesLogPay_Med_HtoH * (MFEBayesLogPay_Med_Rel_Time > `Hto_max_post_period')

*!! MFEBayes_Med_HtoL 
generate byte MFEBayes_Med_HtoL_X_Pre_Before`max_pre_period' = MFEBayesLogPay_Med_HtoL * (MFEBayesLogPay_Med_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte MFEBayes_Med_HtoL_X_Pre`time' = MFEBayesLogPay_Med_HtoL * (MFEBayesLogPay_Med_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte MFEBayes_Med_HtoL_X_Post`time' = MFEBayesLogPay_Med_HtoL * (MFEBayesLogPay_Med_Rel_Time == `time')
}
generate byte MFEBayes_Med_HtoL_X_Post_After`Hto_max_post_period' = MFEBayesLogPay_Med_HtoL * (MFEBayesLogPay_Med_Rel_Time > `Hto_max_post_period')

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-2. global macros used in regressions (based on MFEBayesLogPay_Med)
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

foreach event in MFEBayes_Med_LtoL MFEBayes_Med_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in MFEBayes_Med_LtoL MFEBayes_Med_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in MFEBayes_Med_HtoH MFEBayes_Med_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in MFEBayes_Med_HtoH MFEBayes_Med_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global MFEBayes_Med_dummies ${MFEBayes_Med_LtoL_X_Pre} ${MFEBayes_Med_LtoL_X_Post} ${MFEBayes_Med_LtoH_X_Pre} ${MFEBayes_Med_LtoH_X_Post} ${MFEBayes_Med_HtoH_X_Pre} ${MFEBayes_Med_HtoH_X_Post} ${MFEBayes_Med_HtoL_X_Pre} ${MFEBayes_Med_HtoL_X_Post}

display "${MFEBayes_Med_dummies}"

    // MFEBayes_Med_LtoL_X_Pre_Before36 MFEBayes_Med_LtoL_X_Pre36 ... MFEBayes_Med_LtoL_X_Pre4 MFEBayes_Med_LtoL_X_Post0 MFEBayes_Med_LtoL_X_Post1 ... MFEBayes_Med_LtoL_X_Post84 MFEBayes_Med_LtoL_X_Pre_After84 
    // MFEBayes_Med_LtoH_X_Pre_Before36 MFEBayes_Med_LtoH_X_Pre36 ... MFEBayes_Med_LtoH_X_Pre4 MFEBayes_Med_LtoH_X_Post0 MFEBayes_Med_LtoH_X_Post1 ... MFEBayes_Med_LtoH_X_Post84 MFEBayes_Med_LtoH_X_Pre_After84 
    // MFEBayes_Med_HtoH_X_Pre_Before36 MFEBayes_Med_HtoH_X_Pre36 ... MFEBayes_Med_HtoH_X_Pre4 MFEBayes_Med_HtoH_X_Post0 MFEBayes_Med_HtoH_X_Post1 ... MFEBayes_Med_HtoH_X_Post60 MFEBayes_Med_HtoH_X_Pre_After60 
    // MFEBayes_Med_HtoL_X_Pre_Before36 MFEBayes_Med_HtoL_X_Pre36 ... MFEBayes_Med_HtoL_X_Pre4 MFEBayes_Med_HtoL_X_Post0 MFEBayes_Med_HtoL_X_Post1 ... MFEBayes_Med_HtoL_X_Post60 MFEBayes_Med_HtoL_X_Pre_After60 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. Transfer Outcomes (based on MFEBayesLogPay_Med)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in TransferSJVC TransferFuncC ChangeSalaryGradeC {

    if "`var'" == "TransferSJVC"       global title "Lateral move"
    if "`var'" == "TransferFuncC"      global title "Lateral move, function"
    if "`var'" == "ChangeSalaryGradeC" global title "Salary grade increase"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${MFEBayes_Med_dummies} ///
        if (MFEBayesLogPay_Med_Mngr_both_WL2==1 & MFEBayesLogPay_Med_Never_ChangeM==0 & subsample==1) ///
        , absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

        //&? Exclude all control workers.
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(MFEBayes_Med) pre_window_len(36)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'}

    *!! quarterly estimates
    LH_minus_LL, event_prefix(MFEBayes_Med) pre_window_len(36) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)28) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
    graph save "${Results}/WithoutControlWorkers_MFEBayesLogPay_Med_Gains_AllEstimates_`var'_Restrictions.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(MFEBayes_Med) pre_window_len(36)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'}

    *!! quarterly estimates
    HL_minus_HH, event_prefix(MFEBayes_Med) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20) /// 
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
    graph save "${Results}/WithoutControlWorkers_MFEBayesLogPay_Med_Loss_AllEstimates_`var'_Restrictions.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(MFEBayes_Med) pre_window_len(36)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'}

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(MFEBayes_Med) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'}

    *!! quarterly estimates
    Double_Diff, event_prefix(MFEBayes_Med) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20) /// 
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/WithoutControlWorkers_MFEBayesLogPay_Med_GainsMinusLoss_AllEstimates_`var'_Restrictions.gph", replace
    
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. run regressions on 3 transfer outcomes (based on MFEBayesLogPay_p75)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_MainOutcomesInEventStudies_MFEBayesLogPay.dta", clear 

merge m:1 IDlse using "${TempData}/temp_workersubsample_MFEBayesLogPay.dta", keep(match master) nogenerate 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-1. construct global macros used in regressions (based on MFEBayesLogPay_p75)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& Months -1, -2, and -3 are omitted as the reference group.
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-1-1. generate event * relative period dummies (based on MFEBayesLogPay_p75) 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

summarize MFEBayesLogPay_p75_Rel_Time, detail // range: [-114, +129]

*!! time window of interest
local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! MFEBayes_p75_LtoL
generate byte MFEBayes_p75_LtoL_X_Pre_Before`max_pre_period' = MFEBayesLogPay_p75_LtoL * (MFEBayesLogPay_p75_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte MFEBayes_p75_LtoL_X_Pre`time' = MFEBayesLogPay_p75_LtoL * (MFEBayesLogPay_p75_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte MFEBayes_p75_LtoL_X_Post`time' = MFEBayesLogPay_p75_LtoL * (MFEBayesLogPay_p75_Rel_Time == `time')
}
generate byte MFEBayes_p75_LtoL_X_Post_After`Lto_max_post_period' = MFEBayesLogPay_p75_LtoL * (MFEBayesLogPay_p75_Rel_Time > `Lto_max_post_period')

*!! MFEBayes_p75_LtoH
generate byte MFEBayes_p75_LtoH_X_Pre_Before`max_pre_period' = MFEBayesLogPay_p75_LtoH * (MFEBayesLogPay_p75_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte MFEBayes_p75_LtoH_X_Pre`time' = MFEBayesLogPay_p75_LtoH * (MFEBayesLogPay_p75_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte MFEBayes_p75_LtoH_X_Post`time' = MFEBayesLogPay_p75_LtoH * (MFEBayesLogPay_p75_Rel_Time == `time')
}
generate byte MFEBayes_p75_LtoH_X_Post_After`Lto_max_post_period' = MFEBayesLogPay_p75_LtoH * (MFEBayesLogPay_p75_Rel_Time > `Lto_max_post_period')

*!! MFEBayes_p75_HtoH 
generate byte MFEBayes_p75_HtoH_X_Pre_Before`max_pre_period' = MFEBayesLogPay_p75_HtoH * (MFEBayesLogPay_p75_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte MFEBayes_p75_HtoH_X_Pre`time' = MFEBayesLogPay_p75_HtoH * (MFEBayesLogPay_p75_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte MFEBayes_p75_HtoH_X_Post`time' = MFEBayesLogPay_p75_HtoH * (MFEBayesLogPay_p75_Rel_Time == `time')
}
generate byte MFEBayes_p75_HtoH_X_Post_After`Hto_max_post_period' = MFEBayesLogPay_p75_HtoH * (MFEBayesLogPay_p75_Rel_Time > `Hto_max_post_period')

*!! MFEBayes_p75_HtoL 
generate byte MFEBayes_p75_HtoL_X_Pre_Before`max_pre_period' = MFEBayesLogPay_p75_HtoL * (MFEBayesLogPay_p75_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte MFEBayes_p75_HtoL_X_Pre`time' = MFEBayesLogPay_p75_HtoL * (MFEBayesLogPay_p75_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte MFEBayes_p75_HtoL_X_Post`time' = MFEBayesLogPay_p75_HtoL * (MFEBayesLogPay_p75_Rel_Time == `time')
}
generate byte MFEBayes_p75_HtoL_X_Post_After`Hto_max_post_period' = MFEBayesLogPay_p75_HtoL * (MFEBayesLogPay_p75_Rel_Time > `Hto_max_post_period')

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-1-2. global macros used in regressions (based on MFEBayesLogPay_p75) 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

foreach event in MFEBayes_p75_LtoL MFEBayes_p75_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in MFEBayes_p75_LtoL MFEBayes_p75_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in MFEBayes_p75_HtoH MFEBayes_p75_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in MFEBayes_p75_HtoH MFEBayes_p75_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global MFEBayes_p75_dummies ${MFEBayes_p75_LtoL_X_Pre} ${MFEBayes_p75_LtoL_X_Post} ${MFEBayes_p75_LtoH_X_Pre} ${MFEBayes_p75_LtoH_X_Post} ${MFEBayes_p75_HtoH_X_Pre} ${MFEBayes_p75_HtoH_X_Post} ${MFEBayes_p75_HtoL_X_Pre} ${MFEBayes_p75_HtoL_X_Post}

display "${MFEBayes_p75_dummies}"

    // MFEBayes_p75_LtoL_X_Pre_Before36 MFEBayes_p75_LtoL_X_Pre36 ... MFEBayes_p75_LtoL_X_Pre4 MFEBayes_p75_LtoL_X_Post0 MFEBayes_p75_LtoL_X_Post1 ... MFEBayes_p75_LtoL_X_Post84 MFEBayes_p75_LtoL_X_Pre_After84 
    // MFEBayes_p75_LtoH_X_Pre_Before36 MFEBayes_p75_LtoH_X_Pre36 ... MFEBayes_p75_LtoH_X_Pre4 MFEBayes_p75_LtoH_X_Post0 MFEBayes_p75_LtoH_X_Post1 ... MFEBayes_p75_LtoH_X_Post84 MFEBayes_p75_LtoH_X_Pre_After84 
    // MFEBayes_p75_HtoH_X_Pre_Before36 MFEBayes_p75_HtoH_X_Pre36 ... MFEBayes_p75_HtoH_X_Pre4 MFEBayes_p75_HtoH_X_Post0 MFEBayes_p75_HtoH_X_Post1 ... MFEBayes_p75_HtoH_X_Post60 MFEBayes_p75_HtoH_X_Pre_After60 
    // MFEBayes_p75_HtoL_X_Pre_Before36 MFEBayes_p75_HtoL_X_Pre36 ... MFEBayes_p75_HtoL_X_Pre4 MFEBayes_p75_HtoL_X_Post0 MFEBayes_p75_HtoL_X_Post1 ... MFEBayes_p75_HtoL_X_Post60 MFEBayes_p75_HtoL_X_Pre_After60 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-2. Transfer Outcomes (based on MFEBayesLogPay_p75)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in TransferSJVC TransferFuncC ChangeSalaryGradeC {

    if "`var'" == "TransferSJVC"       global title "Lateral move"
    if "`var'" == "TransferFuncC"      global title "Lateral move, function"
    if "`var'" == "ChangeSalaryGradeC" global title "Salary grade increase"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${MFEBayes_p75_dummies} if (MFEBayesLogPay_p75_Mngr_both_WL2==1 & MFEBayesLogPay_p75_Never_ChangeM==0 & subsample==1), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

        //&? Exclude all control workers.
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(MFEBayes_p75) pre_window_len(36)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'}

    *!! quarterly estimates
    LH_minus_LL, event_prefix(MFEBayes_p75) pre_window_len(36) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)28) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
    graph save "${Results}/WithoutControlWorkers_MFEBayesLogPay_p75_Gains_AllEstimates_`var'_Restrictions.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(MFEBayes_p75) pre_window_len(36)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'}

    *!! quarterly estimates
    HL_minus_HH, event_prefix(MFEBayes_p75) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20) /// 
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
    graph save "${Results}/WithoutControlWorkers_MFEBayesLogPay_p75_Loss_AllEstimates_`var'_Restrictions.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(MFEBayes_p75) pre_window_len(36)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'}

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(MFEBayes_p75) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'}

    *!! quarterly estimates
    Double_Diff, event_prefix(MFEBayes_p75) pre_window_len(36) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20) /// 
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/WithoutControlWorkers_MFEBayesLogPay_p75_GainsMinusLoss_AllEstimates_`var'_Restrictions.gph", replace
    
}

log close 