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
    generate byte `event'_X_Pre_After86 = `event' * (Rel_Time > 86)
}

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    generate byte `event'_X_Pre_After84 = `event' * (Rel_Time > 84)
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_3. construct global macros used in regressions using different aggregation methods 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! Aggregation 1 (VM): Orignial Method
*&& month -1 is omitted as the reference group, so Line 127 iteration starts with 2
*&& <-36, -36, -35, ..., -3, -2, 0, 1, 2, ...,  +83, +84, and >+84

local max_pre_period  = 36 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre_VM `event'_X_Pre_Before36
    forvalues time = 2/`max_pre_period' {
        global `event'_X_Pre_VM ${`event'_X_Pre_VM} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post_VM ${`event'_X_Post_VM} `event'_X_Post`time'
    }
    global `event'_X_Post_VM ${`event'_X_Post_VM} `event'_X_Pre_After84
}
global reg_VM ${FT_LtoL_X_Pre_VM} ${FT_LtoL_X_Post_VM} ${FT_LtoH_X_Pre_VM} ${FT_LtoH_X_Post_VM} 

*!! Aggregation 2 (WZ): -1 month adjusted
*&& month -1 is omitted as the reference group, so Line 127 iteration starts with 2
*&& <-34, -34, -33, ..., -3, -2, 0, 1, 2, ...,  +85, +86, and >+86

local max_pre_period  = 34 
local max_post_period = 86

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre_WZ `event'_X_Pre_Before34
    forvalues time = 2/`max_pre_period' {
        global `event'_X_Pre_WZ ${`event'_X_Pre_WZ} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post_WZ ${`event'_X_Post_WZ} `event'_X_Post`time'
    }
    global `event'_X_Post_WZ ${`event'_X_Post_WZ} `event'_X_Pre_After86
}
global reg_WZ ${FT_LtoL_X_Pre_WZ} ${FT_LtoL_X_Post_WZ} ${FT_LtoH_X_Pre_WZ} ${FT_LtoH_X_Post_WZ} 

*!! Aggregation 3 (CP): month -1 and month 0 adjusted
*&& months -1, -2, and -3 are omitted as the reference group, so Line 127 iteration starts with 2
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

local max_pre_period  = 36 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre_CP `event'_X_Pre_Before36
    forvalues time = 4/`max_pre_period' {
        global `event'_X_Pre_CP ${`event'_X_Pre_CP} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post_CP ${`event'_X_Post_CP} `event'_X_Post`time'
    }
    global `event'_X_Post_CP ${`event'_X_Post_CP} `event'_X_Pre_After84
}
global reg_CP ${FT_LtoL_X_Pre_CP} ${FT_LtoL_X_Post_CP} ${FT_LtoH_X_Pre_CP} ${FT_LtoH_X_Post_CP} 

display "${regVM}"

display "${reg_WZ}"

display "${reg_CP}"


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure 1. Lateral Transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

eststo: reghdfe TransferSJVC ${reg_VM} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 


LH_minus_LL_VM, event_prefix(FT) pre_window_len(36) post_window_len(84) 

eststo: reghdfe TransferSJVC ${reg_WZ} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

LH_minus_LL_WZ, event_prefix(FT) pre_window_len(34) post_window_len(86) 

eststo: reghdfe TransferSJVC ${reg_CP} ///
    if ((Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

LH_minus_LL_CP, event_prefix(FT) pre_window_len(36) post_window_len(84) 


/* eststo: reghdfe TransferSJVC ${reg_WZ} ///
    if ((Mngr_both_WL2==1 & (FTLHB==1 | FTLLB==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 


eststo: reghdfe TransferSJVC ${reg_CP} ///
    if ((Mngr_both_WL2==1 & (FTLHB==1 | FTLLB==1)) | (Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) */


/* coeffLH1, c(`window') y(TransferSJVC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferSJVC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferSJVC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.05(0.05)0.2) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7.pdf", replace */
