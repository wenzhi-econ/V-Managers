
/* 
This do file compares employees' retention results between LtoL group and LtoH group.

*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a simplified dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    LeaverPerm ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH ///
    Office Func AgeBand Female

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    LeaverPerm ///
    WL2 ///
    FTLL FTLH FTHH  FTHL ///
    Office Func AgeBand Female 
        // IDs, manager info, outcome variables, sample restriction variable, treatment info, covariates

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_2. sample restriction variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

rename WL2 Mngr_both_WL2 

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

*!! calendar time of the event 
generate Event_Time = . 
replace  Event_Time = Calend_Time_FT_LtoL if Calend_Time_FT_LtoL!=. & Event_Time==.
replace  Event_Time = Calend_Time_FT_LtoH if Calend_Time_FT_LtoH!=. & Event_Time==.
replace  Event_Time = Calend_Time_FT_HtoL if Calend_Time_FT_HtoL!=. & Event_Time==.
replace  Event_Time = Calend_Time_FT_HtoH if Calend_Time_FT_HtoH!=. & Event_Time==.
format   Event_Time %tm

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_3. time when leaving the firm
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

bysort IDlse: egen Leaver = max(LeaverPerm)

bysort IDlse: egen temp = max(YearMonth)
generate Leave_Time = . 
replace  Leave_Time = temp if Leaver == 1
format Leave_Time %tm
drop temp

generate Rel_Leave_Time = Leave_Time - Event_Time

order IDlse YearMonth LeaverPerm Leaver Leave_Time Event_Time Rel_Leave_Time

label variable Leaver "=1, if the worker left the firm during the dataset period"
label variable Leave_Time "Time when the worker left the firm, missing if he stays during the sample period"
label variable Rel_Leave_Time "Leave_Time - Event_Time"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_4. outcome variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Leave_1yr   = inrange(Rel_Leave_Time, 0, 12)
generate Leave_2yrs  = inrange(Rel_Leave_Time, 0, 24)
generate Leave_3yrs  = inrange(Rel_Leave_Time, 0, 36)
generate Leave_4yrs  = inrange(Rel_Leave_Time, 0, 48)
generate Leave_5yrs  = inrange(Rel_Leave_Time, 0, 60)
generate Leave_6yrs  = inrange(Rel_Leave_Time, 0, 72)
generate Leave_7yrs  = inrange(Rel_Leave_Time, 0, 84)
generate Leave_8yrs  = inrange(Rel_Leave_Time, 0, 96)
generate Leave_9yrs  = inrange(Rel_Leave_Time, 0, 108)
generate Leave_10yrs = inrange(Rel_Leave_Time, 0, 120)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_5. keep only a cross-sectional of dataset for four treatment groups
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if (FT_LtoL==1) | (FT_LtoH==1) 
    //&& keep only LtoL and LtoH groups
keep if YearMonth == Event_Time 
    //&& keep one observation for one worker, 
    //&& this also ensures we are using control variables at the time of treatment
keep if Mngr_both_WL2 == 1
    //&& usual sample restriction

keep  IDlse FT_LtoL FT_LtoH Event_Time Leaver Leave_Time Rel_Leave_Time Leave_* Office Func AgeBand Female IDlseMHR
order IDlse FT_LtoL FT_LtoH Event_Time Leaver Leave_Time Rel_Leave_Time Leave_* Office Func AgeBand Female IDlseMHR

save "${FinalData}/temp_exit_outcomes.dta", replace

capture log close

log using "${Results}/logfile_20240906_ExitOutcomes", replace text

use "${FinalData}/temp_exit_outcomes.dta", clear 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? regression set 1. don't consider time constraints
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global exit_outcomes Leave_1yr Leave_2yrs Leave_3yrs Leave_4yrs Leave_5yrs Leave_6yrs Leave_7yrs Leave_8yrs Leave_9yrs Leave_10yrs

foreach var in $exit_outcomes {
    reghdfe `var' FT_LtoH, absorb(Office##Func##Event_Time AgeBand##Female) vce(cluster IDlseMHR)

    eststo `var'
}

coefplot ///
    (Leave_1yr, keep(FT_LtoH) rename(FT_LtoH = "Leave 1 yr") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_2yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 2 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_3yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 3 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_4yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 4 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_5yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 5 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_6yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 6 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_7yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 7 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_8yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 8 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_9yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 9 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_10yrs, keep(FT_LtoH) rename(FT_LtoH = "Leave 10 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    , ciopts(lwidth(2 ..)) levels(95) msymbol(d) mcolor(white) ///
    legend(off) xline(0, lpattern(dash)) ///
    title("Without event time constraints")

graph export "${Results}/Figure3C_FT_Gains_ExitOutcomes.png", replace  


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? regression set 2. consider time constraints
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize Event_Time, detail // max: 743
global LastMonth = r(max)

global exit_outcomes Leave_1yr Leave_2yrs Leave_3yrs Leave_4yrs Leave_5yrs Leave_6yrs Leave_7yrs Leave_8yrs Leave_9yrs Leave_10yrs
local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH if Event_Time <= ${LastPossibleEventTime}, absorb(Office##Func##Event_Time AgeBand##Female) vce(cluster IDlseMHR)

    eststo `var'_TC

    local i  = `i' + 1
}

coefplot ///
    (Leave_1yr_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 1 yr") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_2yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 2 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_3yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 3 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_4yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 4 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_5yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 5 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_6yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 6 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_7yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 7 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_8yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 8 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_9yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 9 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    (Leave_10yrs_TC, keep(FT_LtoH) rename(FT_LtoH = "Leave 10 yrs") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
    , ciopts(lwidth(2 ..)) levels(95) msymbol(d) mcolor(white) ///
    legend(off) xline(0, lpattern(dash)) ///
    title("With event time constraints")

graph export "${Results}/Figure3C_FT_Gains_ExitOutcomes_timeconstraints.png", replace  


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? report the regression table
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable FT_LtoH "L to H"
global exit_outcomes Leave_1yr Leave_2yrs Leave_3yrs Leave_4yrs Leave_5yrs Leave_6yrs Leave_7yrs Leave_8yrs Leave_9yrs Leave_10yrs
global exit_outcomes_TC Leave_1yr_TC Leave_2yrs_TC Leave_3yrs_TC Leave_4yrs_TC Leave_5yrs_TC Leave_6yrs_TC Leave_7yrs_TC Leave_8yrs_TC Leave_9yrs_TC Leave_10yrs_TC

esttab $exit_outcomes using "${Results}/Figure3C_FT_Gains_ExitOutcomes.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH) ///
    order(FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 N, labels("R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1 yr} & \multicolumn{1}{c}{Leave 2 yrs} & \multicolumn{1}{c}{Leave 3 yrs} & \multicolumn{1}{c}{Leave 4 yrs} & \multicolumn{1}{c}{Leave 5 yrs} & \multicolumn{1}{c}{Leave 6 yrs} & \multicolumn{1}{c}{Leave 7 yrs} & \multicolumn{1}{c}{Leave 8 yrs} & \multicolumn{1}{c}{Leave 9 yrs} & \multicolumn{1}{c}{Leave 10 yrs} \\") ///
    posthead("\multicolumn{11}{l}{\emph{Panel A: Without event time constraints}} \\") ///
    prefoot("") ///
    postfoot("\hline")


esttab $exit_outcomes_TC using "${Results}/Figure3C_FT_Gains_ExitOutcomes.tex", ///
    append style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH) ///
    order(FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 N, labels("R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("") ///
    posthead("\multicolumn{11}{l}{\emph{Panel B: With event time constraints}} \\") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only LtoL and LtoH groups. I report the regression coefficient on the dummy indicating the LtoH treatment group. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office, function, and event time, as well as the interaction between age band and gender. Standard errors are clustered at manager level. Even time constraint means whether to keep only those workers whose outcome variable can be measured given the dataset period." "\end{tablenotes}")

log close