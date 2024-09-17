/* 
This do file aims to replicate Figure III, VIII, and IX in the paper (June 14, 2024 version) using two new HF measures.
The four outcome variables of interest are:
    TransferSJVC -- lateral transfers
    TransferFuncC -- cross-functional transfers
    PromWLC -- vertical moves
    ChangeSalaryGradeC -- salary grade increase
*/

capture log close
log using "${Results}/logfile_20240917_TransferOutcomes_TwoNewHFMeasures", replace text

use "${TempData}/temp_MainOutcomesInEventStudies_TwoNewHFMeasures.dta", clear 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group, so in Lines 30 and 42, iteration ends with 4.
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

local max_pre_period  = 36 
local max_post_period = 84

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. dummies for FT
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}
foreach event in FT_HtoH FT_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_HtoH FT_HtoL {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}

global FT_four_events_dummies ${FT_LtoL_X_Pre} ${FT_LtoL_X_Post} ${FT_LtoH_X_Pre} ${FT_LtoH_X_Post} ${FT_HtoH_X_Pre} ${FT_HtoH_X_Post} ${FT_HtoL_X_Pre} ${FT_HtoL_X_Post}

display "${FT_four_events_dummies}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 
    // FT_HtoH_X_Pre_Before36 FT_HtoH_X_Pre36 ... FT_HtoH_X_Pre4 FT_HtoH_X_Post0 FT_HtoH_X_Post1 ... FT_HtoH_X_Post84 FT_HtoH_X_Pre_After84 
    // FT_HtoL_X_Pre_Before36 FT_HtoL_X_Pre36 ... FT_HtoL_X_Pre4 FT_HtoL_X_Post0 FT_HtoL_X_Post1 ... FT_HtoL_X_Post84 FT_HtoL_X_Pre_After84 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-2. dummies for HF2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach event in HF2_LtoL HF2_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in HF2_LtoL HF2_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}
foreach event in HF2_HtoH HF2_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in HF2_HtoH HF2_HtoL {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}

global HF2_four_events_dummies ${HF2_LtoL_X_Pre} ${HF2_LtoL_X_Post} ${HF2_LtoH_X_Pre} ${HF2_LtoH_X_Post} ${HF2_HtoH_X_Pre} ${HF2_HtoH_X_Post} ${HF2_HtoL_X_Pre} ${HF2_HtoL_X_Post}

display "${HF2_four_events_dummies}"

    // HF2_LtoL_X_Pre_Before36 HF2_LtoL_X_Pre36 ... HF2_LtoL_X_Pre4 HF2_LtoL_X_Post0 HF2_LtoL_X_Post1 ... HF2_LtoL_X_Post84 HF2_LtoL_X_Pre_After84 
    // HF2_LtoH_X_Pre_Before36 HF2_LtoH_X_Pre36 ... HF2_LtoH_X_Pre4 HF2_LtoH_X_Post0 HF2_LtoH_X_Post1 ... HF2_LtoH_X_Post84 HF2_LtoH_X_Pre_After84 
    // HF2_HtoH_X_Pre_Before36 HF2_HtoH_X_Pre36 ... HF2_HtoH_X_Pre4 HF2_HtoH_X_Post0 HF2_HtoH_X_Post1 ... HF2_HtoH_X_Post84 HF2_HtoH_X_Pre_After84 
    // HF2_HtoL_X_Pre_Before36 HF2_HtoL_X_Pre36 ... HF2_HtoL_X_Pre4 HF2_HtoL_X_Post0 HF2_HtoL_X_Post1 ... HF2_HtoL_X_Post84 HF2_HtoL_X_Pre_After84 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-3. dummies for HF3
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach event in HF3_LtoL HF3_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in HF3_LtoL HF3_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}
foreach event in HF3_HtoH HF3_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in HF3_HtoH HF3_HtoL {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}

global HF3_four_events_dummies ${HF3_LtoL_X_Pre} ${HF3_LtoL_X_Post} ${HF3_LtoH_X_Pre} ${HF3_LtoH_X_Post} ${HF3_HtoH_X_Pre} ${HF3_HtoH_X_Post} ${HF3_HtoL_X_Pre} ${HF3_HtoL_X_Post}

display "${HF3_four_events_dummies}"

    // HF3_LtoL_X_Pre_Before36 HF3_LtoL_X_Pre36 ... HF3_LtoL_X_Pre4 HF3_LtoL_X_Post0 HF3_LtoL_X_Post1 ... HF3_LtoL_X_Post84 HF3_LtoL_X_Pre_After84 
    // HF3_LtoH_X_Pre_Before36 HF3_LtoH_X_Pre36 ... HF3_LtoH_X_Pre4 HF3_LtoH_X_Post0 HF3_LtoH_X_Post1 ... HF3_LtoH_X_Post84 HF3_LtoH_X_Pre_After84 
    // HF3_HtoH_X_Pre_Before36 HF3_HtoH_X_Pre36 ... HF3_HtoH_X_Pre4 HF3_HtoH_X_Post0 HF3_HtoH_X_Post1 ... HF3_HtoH_X_Post84 HF3_HtoH_X_Pre_After84 
    // HF3_HtoL_X_Pre_Before36 HF3_HtoL_X_Pre36 ... HF3_HtoL_X_Pre4 HF3_HtoL_X_Post0 HF3_HtoL_X_Post1 ... HF3_HtoL_X_Post84 HF3_HtoL_X_Pre_After84 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 1. Lateral Transfers * FT measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferSJVC ${four_events_dummies} ///
    if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-1. Gaining a HF manager * FT measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

LH_minus_LL, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_gains quarter_TransferSJVC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_gains ub_TransferSJVC_gains quarter_TransferSJVC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferSJVC})

graph export "${Results}/FT_Gains_TransferSJVC_AllEstimates_OwnEventDummies.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-2. Losing a HF manager * FT measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(FT) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

HL_minus_HH, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_loss quarter_TransferSJVC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_loss ub_TransferSJVC_loss quarter_TransferSJVC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferSJVC})

graph export "${Results}/FT_Loss_TransferSJVC_AllEstimates_OwnEventDummies.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-3. Testing for asymmetries * FT measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(FT) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

postevent_Double_Diff, event_prefix(FT) post_window_len(84)
global postevent_TransferSJVC = r(postevent)
global postevent_TransferSJVC = string(${postevent_TransferSJVC}, "%4.3f")
display ${postevent_TransferSJVC}

Double_Diff, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_ddiff quarter_TransferSJVC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_ddiff ub_TransferSJVC_ddiff quarter_TransferSJVC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_TransferSJVC}" "Post coeffs. joint p-value = ${postevent_TransferSJVC}")

graph export "${Results}/FT_GainsMinusLoss_TransferSJVC_AllEstimates_OwnEventDummies.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 1. Lateral Transfers * HF2 Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferSJVC ${HF2_four_events_dummies} ///
    if ((HF2_Mngr_both_WL2==1) | (HF2_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-1. Gaining a HF manager * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(HF2) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

LH_minus_LL, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_gains quarter_TransferSJVC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_gains ub_TransferSJVC_gains quarter_TransferSJVC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferSJVC})

graph export "${Results}/HF2_Gains_TransferSJVC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-2. Losing a HF manager * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(HF2) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

HL_minus_HH, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_loss quarter_TransferSJVC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_loss ub_TransferSJVC_loss quarter_TransferSJVC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferSJVC})

graph export "${Results}/HF2_Loss_TransferSJVC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-3. Testing for asymmetries * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(HF2) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

postevent_Double_Diff, event_prefix(HF2) post_window_len(84)
global postevent_TransferSJVC = r(postevent)
global postevent_TransferSJVC = string(${postevent_TransferSJVC}, "%4.3f")
display ${postevent_TransferSJVC}

Double_Diff, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_ddiff quarter_TransferSJVC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_ddiff ub_TransferSJVC_ddiff quarter_TransferSJVC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_TransferSJVC}" "Post coeffs. joint p-value = ${postevent_TransferSJVC}")

graph export "${Results}/HF2_GainsMinusLoss_TransferSJVC_AllEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 1. Lateral Transfers * HF3 Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferSJVC ${HF3_four_events_dummies} ///
    if ((HF3_Mngr_both_WL2==1) | (HF3_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-1. Gaining a HF manager * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(HF3) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

LH_minus_LL, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_gains quarter_TransferSJVC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_gains ub_TransferSJVC_gains quarter_TransferSJVC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferSJVC})

graph export "${Results}/HF3_Gains_TransferSJVC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-2. Losing a HF manager * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(HF3) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

HL_minus_HH, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_loss quarter_TransferSJVC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_loss ub_TransferSJVC_loss quarter_TransferSJVC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferSJVC})

graph export "${Results}/HF3_Loss_TransferSJVC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-3. Testing for asymmetries * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(HF3) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

postevent_Double_Diff, event_prefix(HF3) post_window_len(84)
global postevent_TransferSJVC = r(postevent)
global postevent_TransferSJVC = string(${postevent_TransferSJVC}, "%4.3f")
display ${postevent_TransferSJVC}

Double_Diff, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC_ddiff quarter_TransferSJVC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_ddiff ub_TransferSJVC_ddiff quarter_TransferSJVC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_TransferSJVC}" "Post coeffs. joint p-value = ${postevent_TransferSJVC}")

graph export "${Results}/HF3_GainsMinusLoss_TransferSJVC_AllEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 2. Cross-functional Transfers * FT Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferFuncC ${four_events_dummies} ///
    if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-1. Gaining a HF manager * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

LH_minus_LL, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_gains quarter_TransferFuncC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_gains ub_TransferFuncC_gains quarter_TransferFuncC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferFuncC})

graph export "${Results}/FT_Gains_TransferFuncC_AllEstimates_OwnEventDummies.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-2. Losing a HF manager * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(FT) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

HL_minus_HH, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_loss quarter_TransferFuncC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_loss ub_TransferFuncC_loss quarter_TransferFuncC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferFuncC})

graph export "${Results}/FT_Loss_TransferFuncC_AllEstimates_OwnEventDummies.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-3. Testing for asymmetries * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(FT) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

postevent_Double_Diff, event_prefix(FT) post_window_len(84)
global postevent_TransferFuncC = r(postevent)
global postevent_TransferFuncC = string(${postevent_TransferFuncC}, "%4.3f")
display ${postevent_TransferFuncC}

Double_Diff, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_ddiff quarter_TransferFuncC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_ddiff ub_TransferFuncC_ddiff quarter_TransferFuncC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_TransferFuncC}" "Post coeffs. joint p-value = ${postevent_TransferFuncC}")

graph export "${Results}/FT_GainsMinusLoss_TransferFuncC_AllEstimates_OwnEventDummies.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 2. Cross-functional Transfers * HF2 Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferFuncC ${HF2_four_events_dummies} ///
    if ((HF2_Mngr_both_WL2==1) | (HF2_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-1. Gaining a HF manager * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(HF2) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

LH_minus_LL, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_gains quarter_TransferFuncC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_gains ub_TransferFuncC_gains quarter_TransferFuncC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferFuncC})

graph export "${Results}/HF2_Gains_TransferFuncC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-2. Losing a HF manager * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(HF2) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

HL_minus_HH, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_loss quarter_TransferFuncC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_loss ub_TransferFuncC_loss quarter_TransferFuncC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferFuncC})

graph export "${Results}/HF2_Loss_TransferFuncC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-3. Testing for asymmetries * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(HF2) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

postevent_Double_Diff, event_prefix(HF2) post_window_len(84)
global postevent_TransferFuncC = r(postevent)
global postevent_TransferFuncC = string(${postevent_TransferFuncC}, "%4.3f")
display ${postevent_TransferFuncC}

Double_Diff, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_ddiff quarter_TransferFuncC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_ddiff ub_TransferFuncC_ddiff quarter_TransferFuncC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_TransferFuncC}" "Post coeffs. joint p-value = ${postevent_TransferFuncC}")

graph export "${Results}/HF2_GainsMinusLoss_TransferFuncC_AllEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 2. Cross-functional Transfers * HF3 Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferFuncC ${HF3_four_events_dummies} ///
    if ((HF3_Mngr_both_WL2==1) | (HF3_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-1. Gaining a HF manager * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(HF3) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

LH_minus_LL, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_gains quarter_TransferFuncC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_gains ub_TransferFuncC_gains quarter_TransferFuncC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferFuncC})

graph export "${Results}/HF3_Gains_TransferFuncC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-2. Losing a HF manager * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(HF3) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

HL_minus_HH, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_loss quarter_TransferFuncC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_loss ub_TransferFuncC_loss quarter_TransferFuncC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferFuncC})

graph export "${Results}/HF3_Loss_TransferFuncC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-3. Testing for asymmetries * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(HF3) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

postevent_Double_Diff, event_prefix(HF3) post_window_len(84)
global postevent_TransferFuncC = r(postevent)
global postevent_TransferFuncC = string(${postevent_TransferFuncC}, "%4.3f")
display ${postevent_TransferFuncC}

Double_Diff, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(TransferFuncC)

twoway ///
    (scatter coeff_TransferFuncC_ddiff quarter_TransferFuncC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_ddiff ub_TransferFuncC_ddiff quarter_TransferFuncC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_TransferFuncC}" "Post coeffs. joint p-value = ${postevent_TransferFuncC}")

graph export "${Results}/HF3_GainsMinusLoss_TransferFuncC_AllEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 3. Work-level promotions * FT Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe PromWLC ${four_events_dummies} ///
    if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-1. Gaining a HF manager * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

LH_minus_LL, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_gains quarter_PromWLC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_gains ub_PromWLC_gains quarter_PromWLC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_PromWLC})

graph export "${Results}/FT_Gains_PromWLC_AllEstimates_OwnEventDummies.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-2. Losing a HF manager * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(FT) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

HL_minus_HH, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_loss quarter_PromWLC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_loss ub_PromWLC_loss quarter_PromWLC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_PromWLC})

graph export "${Results}/FT_Loss_PromWLC_AllEstimates_OwnEventDummies.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-3. Testing for asymmetries * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(FT) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

postevent_Double_Diff, event_prefix(FT) post_window_len(84)
global postevent_PromWLC = r(postevent)
global postevent_PromWLC = string(${postevent_PromWLC}, "%4.3f")
display ${postevent_PromWLC}

Double_Diff, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_ddiff quarter_PromWLC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_ddiff ub_PromWLC_ddiff quarter_PromWLC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_PromWLC}" "Post coeffs. joint p-value = ${postevent_PromWLC}")

graph export "${Results}/FT_GainsMinusLoss_PromWLC_AllEstimates_OwnEventDummies.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 3. Work-level promotions * HF2 Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe PromWLC ${HF2_four_events_dummies} ///
    if ((HF2_Mngr_both_WL2==1) | (HF2_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-1. Gaining a HF manager * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(HF2) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

LH_minus_LL, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_gains quarter_PromWLC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_gains ub_PromWLC_gains quarter_PromWLC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_PromWLC})

graph export "${Results}/HF2_Gains_PromWLC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-2. Losing a HF manager * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(HF2) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

HL_minus_HH, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_loss quarter_PromWLC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_loss ub_PromWLC_loss quarter_PromWLC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_PromWLC})

graph export "${Results}/HF2_Loss_PromWLC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-3. Testing for asymmetries * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(HF2) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

postevent_Double_Diff, event_prefix(HF2) post_window_len(84)
global postevent_PromWLC = r(postevent)
global postevent_PromWLC = string(${postevent_PromWLC}, "%4.3f")
display ${postevent_PromWLC}

Double_Diff, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_ddiff quarter_PromWLC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_ddiff ub_PromWLC_ddiff quarter_PromWLC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_PromWLC}" "Post coeffs. joint p-value = ${postevent_PromWLC}")

graph export "${Results}/HF2_GainsMinusLoss_PromWLC_AllEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 3. Work-level promotions * HF3 Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe PromWLC ${HF3_four_events_dummies} ///
    if ((HF3_Mngr_both_WL2==1) | (HF3_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-1. Gaining a HF manager * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(HF3) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

LH_minus_LL, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_gains quarter_PromWLC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_gains ub_PromWLC_gains quarter_PromWLC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_PromWLC})

graph export "${Results}/HF3_Gains_PromWLC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-2. Losing a HF manager * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(HF3) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

HL_minus_HH, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_loss quarter_PromWLC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_loss ub_PromWLC_loss quarter_PromWLC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_PromWLC})

graph export "${Results}/HF3_Loss_PromWLC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-3. Testing for asymmetries * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(HF3) pre_window_len(36)
global pretrend_PromWLC = r(pretrend)
global pretrend_PromWLC = string(${pretrend_PromWLC}, "%4.3f")
display ${pretrend_PromWLC}

postevent_Double_Diff, event_prefix(HF3) post_window_len(84)
global postevent_PromWLC = r(postevent)
global postevent_PromWLC = string(${postevent_PromWLC}, "%4.3f")
display ${postevent_PromWLC}

Double_Diff, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(PromWLC)

twoway ///
    (scatter coeff_PromWLC_ddiff quarter_PromWLC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_PromWLC_ddiff ub_PromWLC_ddiff quarter_PromWLC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Work-level promotions", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_PromWLC}" "Post coeffs. joint p-value = ${postevent_PromWLC}")

graph export "${Results}/HF3_GainsMinusLoss_PromWLC_AllEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 4. Salary grade * FT Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ChangeSalaryGradeC ${four_events_dummies} ///
    if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-1. Gaining a HF manager * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

LH_minus_LL, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC})

graph export "${Results}/FT_Gains_ChangeSalaryGradeC_AllEstimates_OwnEventDummies.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-2. Losing a HF  * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(FT) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

HL_minus_HH, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_loss quarter_ChangeSalaryGradeC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss quarter_ChangeSalaryGradeC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC})

graph export "${Results}/FT_Loss_ChangeSalaryGradeC_AllEstimates_OwnEventDummies.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-3. Testing for asymmetries * FT Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(FT) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

postevent_Double_Diff, event_prefix(FT) post_window_len(84)
global postevent_ChangeSalaryGradeC = r(postevent)
global postevent_ChangeSalaryGradeC = string(${postevent_ChangeSalaryGradeC}, "%4.3f")
display ${postevent_ChangeSalaryGradeC}

Double_Diff, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_ddiff quarter_ChangeSalaryGradeC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_ddiff ub_ChangeSalaryGradeC_ddiff quarter_ChangeSalaryGradeC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC}" "Post coeffs. joint p-value = ${postevent_ChangeSalaryGradeC}")

graph export "${Results}/FT_GainsMinusLoss_ChangeSalaryGradeC_AllEstimates_OwnEventDummies.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 4.  Salary grade * HF2 Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ChangeSalaryGradeC ${HF2_four_events_dummies} ///
    if ((HF2_Mngr_both_WL2==1) | (HF2_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-1. Gaining a HF manager * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(HF2) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

LH_minus_LL, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC})

graph export "${Results}/HF2_Gains_ChangeSalaryGradeC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-2. Losing a HF manager * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(HF2) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

HL_minus_HH, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_loss quarter_ChangeSalaryGradeC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss quarter_ChangeSalaryGradeC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC})

graph export "${Results}/HF2_Loss_ChangeSalaryGradeC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-3. Testing for asymmetries * HF2 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(HF2) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

postevent_Double_Diff, event_prefix(HF2) post_window_len(84)
global postevent_ChangeSalaryGradeC = r(postevent)
global postevent_ChangeSalaryGradeC = string(${postevent_ChangeSalaryGradeC}, "%4.3f")
display ${postevent_ChangeSalaryGradeC}

Double_Diff, event_prefix(HF2) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_ddiff quarter_ChangeSalaryGradeC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_ddiff ub_ChangeSalaryGradeC_ddiff quarter_ChangeSalaryGradeC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC}" "Post coeffs. joint p-value = ${postevent_ChangeSalaryGradeC}")

graph export "${Results}/HF2_GainsMinusLoss_ChangeSalaryGradeC_AllEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 4.  Salary grade * HF3 Measure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ChangeSalaryGradeC ${HF3_four_events_dummies} ///
    if ((HF3_Mngr_both_WL2==1) | (HF3_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-1. Gaining a HF manager * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_LH_minus_LL, event_prefix(HF3) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

LH_minus_LL, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC})

graph export "${Results}/HF3_Gains_ChangeSalaryGradeC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-2. Losing a HF manager * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_HL_minus_HH, event_prefix(HF3) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

HL_minus_HH, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_loss quarter_ChangeSalaryGradeC_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss quarter_ChangeSalaryGradeC_loss, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC})

graph export "${Results}/HF3_Loss_ChangeSalaryGradeC_AllEstimates.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-3. Testing for asymmetries * HF3 Measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

pretrend_Double_Diff, event_prefix(HF3) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

postevent_Double_Diff, event_prefix(HF3) post_window_len(84)
global postevent_ChangeSalaryGradeC = r(postevent)
global postevent_ChangeSalaryGradeC = string(${postevent_ChangeSalaryGradeC}, "%4.3f")
display ${postevent_ChangeSalaryGradeC}

Double_Diff, event_prefix(HF3) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_ddiff quarter_ChangeSalaryGradeC_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_ddiff ub_ChangeSalaryGradeC_ddiff quarter_ChangeSalaryGradeC_ddiff, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note("Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC}" "Post coeffs. joint p-value = ${postevent_ChangeSalaryGradeC}")

graph export "${Results}/HF3_GainsMinusLoss_ChangeSalaryGradeC_AllEstimates.png", replace

log close