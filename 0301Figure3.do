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
local max_post_period = 86

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
    generate byte `event'_X_Pre_Before34 = `event' * (Rel_Time < -34)
}

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    generate byte `event'_X_Post_After86 = `event' * (Rel_Time > 86)
}

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    generate byte `event'_X_Post_After84 = `event' * (Rel_Time > 84)
}

save "${FinalData}/temp_fig3.dta", replace


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_3. construct a simplified dataset with only relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture log close
log using "${Results}/logfile_20240824_Figure3_PanelABD", replace text

use "${FinalData}/temp_fig3.dta", clear 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_4. construct global macros used in regressions 
*-?       using different aggregation methods 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! Aggregation 1 (VM): Orignial Method
*&& month -1 is omitted as the reference group, so Line 127 iteration starts with 2
*&& <-36, -36, -35, ..., -3, -2, 0, 1, 2, ...,  +83, +84, and >+84

capture macro drop FT_LtoL_X_Pre_VM 
capture macro drop FT_LtoH_X_Pre_VM 
capture macro drop FT_LtoL_X_Post_VM 
capture macro drop FT_LtoH_X_Post_VM 
capture macro drop reg_VM

local max_pre_period  = 36 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre_VM `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)2 {
        global `event'_X_Pre_VM ${`event'_X_Pre_VM} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post_VM ${`event'_X_Post_VM} `event'_X_Post`time'
    }
    global `event'_X_Post_VM ${`event'_X_Post_VM} `event'_X_Post_After84
}
global reg_VM ${FT_LtoL_X_Pre_VM} ${FT_LtoL_X_Post_VM} ${FT_LtoH_X_Pre_VM} ${FT_LtoH_X_Post_VM} 

*!! Aggregation 2 (WZ): -1 month adjusted
*&& month -1 is omitted as the reference group, so Line 127 iteration starts with 2
*&& <-34, -34, -33, ..., -3, -2, 0, 1, 2, ...,  +85, +86, and >+86

capture macro drop FT_LtoL_X_Pre_WZ 
capture macro drop FT_LtoH_X_Pre_WZ 
capture macro drop FT_LtoL_X_Post_WZ 
capture macro drop FT_LtoH_X_Post_WZ 
capture macro drop reg_WZ

local max_pre_period  = 34 
local max_post_period = 86

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre_WZ `event'_X_Pre_Before34
    forvalues time = `max_pre_period'(-1)2 {
        global `event'_X_Pre_WZ ${`event'_X_Pre_WZ} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post_WZ ${`event'_X_Post_WZ} `event'_X_Post`time'
    }
    global `event'_X_Post_WZ ${`event'_X_Post_WZ} `event'_X_Post_After86
}
global reg_WZ ${FT_LtoL_X_Pre_WZ} ${FT_LtoL_X_Post_WZ} ${FT_LtoH_X_Pre_WZ} ${FT_LtoH_X_Post_WZ} 

*!! Aggregation 3 (CP): month -1 and month 0 adjusted
*&& months -1, -2, and -3 are omitted as the reference group, so Line 127 iteration starts with 2
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

capture macro drop FT_LtoL_X_Pre_CP 
capture macro drop FT_LtoH_X_Pre_CP 
capture macro drop FT_LtoL_X_Post_CP 
capture macro drop FT_LtoH_X_Post_CP 
capture macro drop reg_CP

local max_pre_period  = 36 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre_CP `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre_CP ${`event'_X_Pre_CP} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post_CP ${`event'_X_Post_CP} `event'_X_Post`time'
    }
    global `event'_X_Post_CP ${`event'_X_Post_CP} `event'_X_Post_After84
}
global reg_CP ${FT_LtoL_X_Pre_CP} ${FT_LtoL_X_Post_CP} ${FT_LtoH_X_Pre_CP} ${FT_LtoH_X_Post_CP} 

display "${reg_VM}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre2 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre2 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 

display "${reg_WZ}"

    // FT_LtoL_X_Pre_Before34 FT_LtoL_X_Pre34 ... FT_LtoL_X_Pre2 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post86 FT_LtoL_X_Pre_After86 
    // FT_LtoH_X_Pre_Before34 FT_LtoH_X_Pre34 ... FT_LtoH_X_Pre2 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post86 FT_LtoH_X_Pre_After86 

display "${reg_CP}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure 1. Lateral Transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 1_1. Lateral Transfers + VM Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe TransferSJVC ${reg_VM} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_VM, event_prefix(FT) pre_window_len(36)
global pretrend_LH_minus_LL_VM = r(pretrend)
global pretrend_LH_minus_LL_VM = string(${pretrend_LH_minus_LL_VM}, "%4.3f")
display ${pretrend_LH_minus_LL_VM}

LH_minus_LL_VM, event_prefix(FT) pre_window_len(36) post_window_len(84) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_TransferSJVC_VM coeff_TransferSJVC_VM lb_TransferSJVC_VM up_TransferSJVC_VM)

twoway ///
    (scatter coeff_TransferSJVC_VM qi_TransferSJVC_VM, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_VM up_TransferSJVC_VM qi_TransferSJVC_VM, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_VM})

graph export "${Results}/Figure3_TransferSJVC_VM.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 1_2. Lateral Transfers + WZ Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe TransferSJVC ${reg_WZ} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_WZ, event_prefix(FT) pre_window_len(34)
global pretrend_LH_minus_LL_WZ = r(pretrend)
global pretrend_LH_minus_LL_WZ = string(${pretrend_LH_minus_LL_WZ}, "%4.3f")
display ${pretrend_LH_minus_LL_WZ}

LH_minus_LL_WZ, event_prefix(FT) pre_window_len(34) post_window_len(86) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_TransferSJVC_WZ coeff_TransferSJVC_WZ lb_TransferSJVC_WZ up_TransferSJVC_WZ)

twoway ///
    (scatter coeff_TransferSJVC_WZ qi_TransferSJVC_WZ, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_WZ up_TransferSJVC_WZ qi_TransferSJVC_WZ, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_WZ})

graph export "${Results}/Figure3_TransferSJVC_WZ.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 1_3. Lateral Transfers + CP Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe TransferSJVC ${reg_CP} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_CP, event_prefix(FT) pre_window_len(36)
global pretrend_LH_minus_LL_CP = r(pretrend)
global pretrend_LH_minus_LL_CP = string(${pretrend_LH_minus_LL_CP}, "%4.3f")
display ${pretrend_LH_minus_LL_CP}
LH_minus_LL_CP, event_prefix(FT) pre_window_len(36) post_window_len(84) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_TransferSJVC_CP coeff_TransferSJVC_CP lb_TransferSJVC_CP up_TransferSJVC_CP)

twoway ///
    (scatter coeff_TransferSJVC_CP qi_TransferSJVC_CP, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJVC_CP up_TransferSJVC_CP qi_TransferSJVC_CP, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_CP})

graph export "${Results}/Figure3_TransferSJVC_CP.png", replace


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure 2. Cross-functional Transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 2_1. Cross-functional Transfers + VM Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe TransferFuncC ${reg_VM} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_VM, event_prefix(FT) pre_window_len(36)
global pretrend_LH_minus_LL_VM = r(pretrend)
global pretrend_LH_minus_LL_VM = string(${pretrend_LH_minus_LL_VM}, "%4.3f")
display ${pretrend_LH_minus_LL_VM}

LH_minus_LL_VM, event_prefix(FT) pre_window_len(36) post_window_len(84) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_TransferFuncC_VM coeff_TransferFuncC_VM lb_TransferFuncC_VM up_TransferFuncC_VM)

twoway ///
    (scatter coeff_TransferFuncC_VM qi_TransferFuncC_VM, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_VM up_TransferFuncC_VM qi_TransferFuncC_VM, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_VM})

graph export "${Results}/Figure3_TransferFuncC_VM.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 2_2. Cross-functional Transfers + WZ Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe TransferFuncC ${reg_WZ} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_WZ, event_prefix(FT) pre_window_len(34)
global pretrend_LH_minus_LL_WZ = r(pretrend)
global pretrend_LH_minus_LL_WZ = string(${pretrend_LH_minus_LL_WZ}, "%4.3f")
display ${pretrend_LH_minus_LL_WZ}

LH_minus_LL_WZ, event_prefix(FT) pre_window_len(34) post_window_len(86) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_TransferFuncC_WZ coeff_TransferFuncC_WZ lb_TransferFuncC_WZ up_TransferFuncC_WZ)

twoway ///
    (scatter coeff_TransferFuncC_WZ qi_TransferFuncC_WZ, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_WZ up_TransferFuncC_WZ qi_TransferFuncC_WZ, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_WZ})

graph export "${Results}/Figure3_TransferFuncC_WZ.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 2_3. Cross-functional Transfers + CP Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe TransferFuncC ${reg_CP} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_CP, event_prefix(FT) pre_window_len(36)
global pretrend_LH_minus_LL_CP = r(pretrend)
global pretrend_LH_minus_LL_CP = string(${pretrend_LH_minus_LL_CP}, "%4.3f")
display ${pretrend_LH_minus_LL_CP}
LH_minus_LL_CP, event_prefix(FT) pre_window_len(36) post_window_len(84) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_TransferFuncC_CP coeff_TransferFuncC_CP lb_TransferFuncC_CP up_TransferFuncC_CP)

twoway ///
    (scatter coeff_TransferFuncC_CP qi_TransferFuncC_CP, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferFuncC_CP up_TransferFuncC_CP qi_TransferFuncC_CP, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_CP})

graph export "${Results}/Figure3_TransferFuncC_CP.png", replace


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure 4. Salary grade
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 4_1. Salary grade + VM Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe ChangeSalaryGradeC ${reg_VM} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_VM, event_prefix(FT) pre_window_len(36)
global pretrend_LH_minus_LL_VM = r(pretrend)
global pretrend_LH_minus_LL_VM = string(${pretrend_LH_minus_LL_VM}, "%4.3f")
display ${pretrend_LH_minus_LL_VM}

LH_minus_LL_VM, event_prefix(FT) pre_window_len(36) post_window_len(84) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_ChangeSalaryGradeC_VM coeff_ChangeSalaryGradeC_VM lb_ChangeSalaryGradeC_VM up_ChangeSalaryGradeC_VM)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_VM qi_ChangeSalaryGradeC_VM, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_VM up_ChangeSalaryGradeC_VM qi_ChangeSalaryGradeC_VM, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_VM})

graph export "${Results}/Figure3_ChangeSalaryGradeC_VM.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 4_2. Salary grade + WZ Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe ChangeSalaryGradeC ${reg_WZ} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_WZ, event_prefix(FT) pre_window_len(34)
global pretrend_LH_minus_LL_WZ = r(pretrend)
global pretrend_LH_minus_LL_WZ = string(${pretrend_LH_minus_LL_WZ}, "%4.3f")
display ${pretrend_LH_minus_LL_WZ}

LH_minus_LL_WZ, event_prefix(FT) pre_window_len(34) post_window_len(86) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_ChangeSalaryGradeC_WZ coeff_ChangeSalaryGradeC_WZ lb_ChangeSalaryGradeC_WZ up_ChangeSalaryGradeC_WZ)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_WZ qi_ChangeSalaryGradeC_WZ, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_WZ up_ChangeSalaryGradeC_WZ qi_ChangeSalaryGradeC_WZ, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_WZ})

graph export "${Results}/Figure3_ChangeSalaryGradeC_WZ.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? Subfigure 4_3. Salary grade + CP Aggregation
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo: reghdfe ChangeSalaryGradeC ${reg_CP} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

pretrend_LH_minus_LL_CP, event_prefix(FT) pre_window_len(36)
global pretrend_LH_minus_LL_CP = r(pretrend)
global pretrend_LH_minus_LL_CP = string(${pretrend_LH_minus_LL_CP}, "%4.3f")
display ${pretrend_LH_minus_LL_CP}
LH_minus_LL_CP, event_prefix(FT) pre_window_len(36) post_window_len(84) 
rename (quarter_index coefficients lower_bound upper_bound) (qi_ChangeSalaryGradeC_CP coeff_ChangeSalaryGradeC_CP lb_ChangeSalaryGradeC_CP up_ChangeSalaryGradeC_CP)

twoway ///
    (scatter coeff_ChangeSalaryGradeC_CP qi_ChangeSalaryGradeC_CP, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_CP up_ChangeSalaryGradeC_CP qi_ChangeSalaryGradeC_CP, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-12(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title(Lateral move, span pos(12)) ///
    legend(off) note(Pre-trends joint p-value = ${pretrend_LH_minus_LL_CP})

graph export "${Results}/Figure3_ChangeSalaryGradeC_CP.png", replace


log close