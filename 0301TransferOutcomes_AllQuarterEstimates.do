/* 
This do file aims to replicate Figure III, VIII, and IX in the paper (June 14, 2024 version).
The four outcome variables of interest are:
    TransferSJVC -- lateral transfers
    TransferFuncC -- cross-functional transfers
    PromWLC -- vertical moves
    ChangeSalaryGradeC -- salary grade increase
*/

capture log close
log using "${Results}/logfile_20240917_TransferOutcomes", replace text

use "${TempData}/temp_MainOutcomesInEventStudies.dta", clear 

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

global four_events_dummies ${FT_LtoL_X_Pre} ${FT_LtoL_X_Post} ${FT_LtoH_X_Pre} ${FT_LtoH_X_Post} ${FT_HtoH_X_Pre} ${FT_HtoH_X_Post} ${FT_HtoL_X_Pre} ${FT_HtoL_X_Post}

display "${four_events_dummies}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 
    // FT_HtoH_X_Pre_Before36 FT_HtoH_X_Pre36 ... FT_HtoH_X_Pre4 FT_HtoH_X_Post0 FT_HtoH_X_Post1 ... FT_HtoH_X_Post84 FT_HtoH_X_Pre_After84 
    // FT_HtoL_X_Pre_Before36 FT_HtoL_X_Pre36 ... FT_HtoL_X_Pre4 FT_HtoL_X_Post0 FT_HtoL_X_Post1 ... FT_HtoL_X_Post84 FT_HtoL_X_Pre_After84 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 1. Lateral Transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferSJVC ${four_events_dummies} ///
    if ((Mngr_both_WL2==1) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-1. Gaining a HF manager
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

graph export "${Results}/FT_Gains_TransferSJVC.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-2. Losing a HF manager
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

graph export "${Results}/FT_Loss_TransferSJVC.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-1-3. Testing for asymmetries
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

graph export "${Results}/FT_GainsMinusLoss_TransferSJVC.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 2. Cross-functional Transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferFuncC ${four_events_dummies} ///
    if ((Mngr_both_WL2==1) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-1. Gaining a HF manager
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

graph export "${Results}/FT_Gains_TransferFuncC.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-2. Losing a HF manager
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

graph export "${Results}/FT_Loss_TransferFuncC.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-2-3. Testing for asymmetries
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

graph export "${Results}/FT_GainsMinusLoss_TransferFuncC.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 3. Work-level promotions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe PromWLC ${four_events_dummies} ///
    if ((Mngr_both_WL2==1) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-1. Gaining a HF manager
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

graph export "${Results}/FT_Gains_PromWLC.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-2. Losing a HF manager
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

graph export "${Results}/FT_Loss_PromWLC.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-3-3. Testing for asymmetries
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

graph export "${Results}/FT_GainsMinusLoss_PromWLC.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Outcome 4.  Salary grade
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ChangeSalaryGradeC ${four_events_dummies} ///
    if ((Mngr_both_WL2==1) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-1. Gaining a HF manager
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

graph export "${Results}/FT_Gains_ChangeSalaryGradeC.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-2. Losing a HF manager
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

graph export "${Results}/FT_Loss_ChangeSalaryGradeC.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? O-4-3. Testing for asymmetries
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

graph export "${Results}/FT_GainsMinusLoss_ChangeSalaryGradeC.png", replace

log close