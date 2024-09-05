/* 
This do file aims to replicate Figure 3 in the paper. Commands are copied from "2.4 Event Study NoLoops.do" file.


*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplest possible dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    TransferSJVC TransferFuncC LeaverPerm ChangeSalaryGradeC ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH 

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    TransferSJVC TransferFuncC LeaverPerm ChangeSalaryGradeC ///
    WL2 ///
    FTLL FTLH FTHH  FTHL
        // IDs, manager info, outcome variables, sample restriction variable, treatment info

rename WL2 Mngr_both_WL2 

/* 
Original relative period to the corresponding event variables are: 
    KFTLL KFTLH KFTHL KFTHH
It is easy to show that my constructed variable Rel_Time is exactly the same as the original ones:
    count if Rel_Time!=. & KFTLL!=. & Rel_Time!=KFTLL // 0
    count if Rel_Time!=. & KFTLH!=. & Rel_Time!=KFTLH // 0
    count if Rel_Time!=. & KFTHL!=. & Rel_Time!=KFTHL // 0
    count if Rel_Time!=. & KFTHH!=. & Rel_Time!=KFTHH // 0
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_2. construct (individual level) event dummies 
*-?       and (individual-month level) relative dates to the event
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! calendar time of the event
rename FTLL Calend_Time_FT_LtoL
rename FTLH Calend_Time_FT_LtoH
rename FTHL Calend_Time_FT_HtoL
rename FTHH Calend_Time_FT_HtoH

*!! five event dummies: 4 types of treatment + 1 never-treated
generate FT_LtoL = 0 
replace  FT_LtoL = 1 if Calend_Time_FT_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if Calend_Time_FT_LtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if Calend_Time_FT_HtoL != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if Calend_Time_FT_HtoH != .

capture drop temp 
egen temp = rowtotal(FT_LtoL FT_LtoH FT_HtoL FT_HtoH)
generate Never_ChangeM = 1 - temp 
capture drop temp

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate Rel_Time = . 
replace  Rel_Time = YearMonth - Calend_Time_FT_LtoL if Calend_Time_FT_LtoL !=. 
replace  Rel_Time = YearMonth - Calend_Time_FT_LtoH if Calend_Time_FT_LtoH !=. 
replace  Rel_Time = YearMonth - Calend_Time_FT_HtoL if Calend_Time_FT_HtoL !=. 
replace  Rel_Time = YearMonth - Calend_Time_FT_HtoH if Calend_Time_FT_HtoH !=. 

label variable Rel_Time "relative date to the event, missing if the event is Never_ChangeM"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_3. construct "event * relative date" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
summarize Rel_Time, detail // range: [-131, +130]

*!! ordinary "event * relative date" dummies 

local max_pre_period  = 36 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    forvalues time = 1/`max_pre_period' {
        generate byte `event'_X_Pre`time' = `event' * (Rel_Time == -`time')
    }
}
foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    forvalues time = 0/`max_post_period' {
        generate byte `event'_X_Post`time' = `event' * (Rel_Time == `time')
    }
}

*!! binned absorbing "event * relative date" dummies for pre- and post-event periods 

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    generate byte `event'_X_Pre_Before36 = `event' * (Rel_Time < -36)
}

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    generate byte `event'_X_Post_After84 = `event' * (Rel_Time > 84)
}

save "${FinalData}/temp_fig3.dta", replace


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_4. construct a simplified dataset with only relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture log close
log using "${Results}/logfile_20240905_Figure3_PanelABD", replace text

use "${FinalData}/temp_fig3.dta", clear 

keep if inrange(_n, 1, 10000) 
    // used to test the codes
    // commented out when offically producing the results

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_5. construct global macros used in regressions 
*-?       using different aggregation methods 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! Aggregation 3 (CP): month -1 and month 0 adjusted
*&& months -1, -2, and -3 are omitted as the reference group, so Line 127 iteration starts with 2
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

capture macro drop FT_LtoL_X_Pre 
capture macro drop FT_LtoH_X_Pre 
capture macro drop FT_LtoL_X_Post 
capture macro drop FT_LtoH_X_Post 
capture macro drop events_LH_minus_LL

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
global events_LH_minus_LL ${FT_LtoL_X_Pre} ${FT_LtoL_X_Post} ${FT_LtoH_X_Pre} ${FT_LtoH_X_Post} 

display "${events_LH_minus_LL}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure A. Lateral Transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferSJVC ${events_LH_minus_LL} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(36)
global pretrend_TransferSJVC = r(pretrend)
global pretrend_TransferSJVC = string(${pretrend_TransferSJVC}, "%4.3f")
display ${pretrend_TransferSJVC}

LH_minus_LL, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(TransferSJVC)

twoway ///
    (scatter coeff_TransferSJVC quarter_TransferSJVC, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC ub_TransferSJVC quarter_TransferSJVC, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferSJVC})

graph export "${Results}/Figure3A_FT_Gains_TransferSJVC.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure B. Cross-functional Transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe TransferFuncC ${events_LH_minus_LL} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(36)
global pretrend_TransferFuncC = r(pretrend)
global pretrend_TransferFuncC = string(${pretrend_TransferFuncC}, "%4.3f")
display ${pretrend_TransferFuncC}

LH_minus_LL, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(TransferFuncC) 

twoway ///
    (scatter coeff_TransferFuncC quarter_TransferFuncC, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC ub_TransferFuncC quarter_TransferFuncC, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Lateral move, function", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_TransferFuncC})

graph export "${Results}/Figure3B_FT_Gains_TransferFuncC.png", replace


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure D. Salary grade
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ChangeSalaryGradeC ${events_LH_minus_LL} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(36)
global pretrend_ChangeSalaryGradeC = r(pretrend)
global pretrend_ChangeSalaryGradeC = string(${pretrend_ChangeSalaryGradeC}, "%4.3f")
display ${pretrend_ChangeSalaryGradeC}

LH_minus_LL, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(ChangeSalaryGradeC)

twoway ///
    (scatter coeff_ChangeSalaryGradeC quarter_ChangeSalaryGradeC, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC ub_ChangeSalaryGradeC quarter_ChangeSalaryGradeC, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Salary grade increase", span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_ChangeSalaryGradeC})

graph export "${Results}/Figure3D_FT_Gains_ChangeSalaryGradeC.png", replace


log close