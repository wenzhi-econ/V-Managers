
/* 
Lines 927 - 979 from "2.4.Event Study NoLoops"

*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a simplified dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    TransferSJVC TransferFuncC LeaverPerm ChangeSalaryGradeC ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 KEi Ei ///
    FTHL FTLL FTHH FTLH ///
    Office Func AgeBand Female

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    TransferSJVC TransferFuncC LeaverPerm ChangeSalaryGradeC ///
    WL2 KEi Ei ///
    FTLL FTLH FTHH  FTHL ///
    Office Func AgeBand Female 
        // IDs, manager info, outcome variables, sample restriction variable, treatment info, covariates


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_2. sample restriction variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*todo: I don't really understand the sample restrictions here.
*&& The original sample restriction condition is /* if KEi>-1 & WL2==1 & cohort30==1 */.
*&& In the following comments, I copied some relative parts from do files used to generate KEi and cohort30 variables.
*&& I won't investigate deeper what is happening behind these variables. 

rename WL2 Mngr_both_WL2 

/* generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
bysort IDlse: egen mm = min(YearMonth)
replace ChangeM = 0  if YearMonth==mm & ChangeM==1
drop mm 

generate ChangeMR = 0 
replace  ChangeMR = 1 if ChangeM==1 
replace  ChangeMR = 0 if TransferInternal==1 | TransferSJ==1 
replace  ChangeMR = . if ChangeM==.
replace  ChangeMR = . if IDlseMHR==. 

bysort IDlse: egen    EiChange = min(cond(ChangeM==1, YearMonth, .))
bysort IDlse: egen    Ei       = mean(cond(ChangeMR==1 & YearMonth==EiChange, EiChange, .))
replace ChangeMR = 0 if YearMonth>Ei & ChangeMR==1
replace ChangeMR = 0 if ChangeMR==. 
format Ei %tm 

generate KEi = YearMonth - Ei   */

generate cohort30 = 1 if Ei >=tm(2014m1) & Ei <=tm(2018m12)
    // cohorts that have at least 36 months pre and after manager rotation 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_3. construct (individual level) event dummies 
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
*-? s1_4. construct "event * relative date" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
summarize Rel_Time, detail // range: [-131, +130]

*!! ordinary "event * relative date" dummies 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    forvalues time = 0/`max_post_period' {
        generate byte `event'_X_Post`time' = `event' * (Rel_Time == `time')
    }
}

*!! binned absorbing "event * relative date" dummies for pre- and post-event periods 
foreach event in FT_LtoL FT_LtoH FT_HtoL FT_HtoH {
    generate byte `event'_X_Post_After84 = `event' * (Rel_Time > 84)
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_5. save the dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

save "${FinalData}/temp_fig3_panelc.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure 3. Exit from the firm
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? construct global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture log close

log using "${Results}/logfile_20240825_Figure3_PanelC", replace text

use "${FinalData}/temp_fig3_panelc.dta", clear 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

capture macro drop FT_LtoL_X_Post 
capture macro drop FT_LtoH_X_Post 
capture macro drop eventsXreltime_dummies

local max_post_period = 84

foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}
global eventsXreltime_dummies ${FT_LtoL_X_Post} ${FT_LtoH_X_Post} 

display "${eventsXreltime_dummies}"

reghdfe LeaverPerm ${eventsXreltime_dummies} ///
    if (Mngr_both_WL2==1 | Never_ChangeM==1) & KEi > -1 & cohort30==1 ///
    , absorb(Office##Func##YearMonth  AgeBand##Female) vce(cluster IDlseMHR)

    /* if KEi>-1 & WL2==1 & cohort30==1 */

Exit_LH_minus_LL, event_prefix(FT) post_window_len(84)

rename (quarter_index coefficients lower_bound upper_bound) (qi_LeaverPerm coeff_LeaverPerm lb_LeaverPerm up_LeaverPerm)

twoway ///
    (scatter coeff_LeaverPerm qi_LeaverPerm, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_LeaverPerm up_LeaverPerm qi_LeaverPerm, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) ///
    xlabel(0(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Exit", span pos(12)) ///
    legend(off)

graph export "${Results}/Figure3_LeaverPerm_wControls.png", replace

reghdfe LeaverPerm ${eventsXreltime_dummies} ///
    if (Mngr_both_WL2==1) & KEi > -1 & cohort30==1 ///
    , absorb(Office##Func##YearMonth  AgeBand##Female) vce(cluster IDlseMHR)

Exit_LH_minus_LL, event_prefix(FT) post_window_len(84)

rename (quarter_index coefficients lower_bound upper_bound) (qi_LeaverPerm_noC coeff_LeaverPerm_noC lb_LeaverPerm_noC up_LeaverPerm_noC)

twoway ///
    (scatter coeff_LeaverPerm_noC qi_LeaverPerm_noC, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_LeaverPerm_noC up_LeaverPerm_noC qi_LeaverPerm_noC, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) ///
    xlabel(0(2)28) /// //ylabel(-0.05(0.05)0.2) ///
    xtitle(Quarters since manager change) title("Exit", span pos(12)) ///
    legend(off)

graph export "${Results}/Figure3_LeaverPerm_noControls.png", replace

log close