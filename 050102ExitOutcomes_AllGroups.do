/* 
This do file compares employees' retention results between LtoL group and LtoH group, and between HtoL group and HtoH group.

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
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHL FT_Calend_Time_HtoL
rename FTHH FT_Calend_Time_HtoH

*!! five event dummies: 4 types of treatment + 1 never-treated
generate FT_LtoL = 0 
replace  FT_LtoL = 1 if FT_Calend_Time_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if FT_Calend_Time_LtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if FT_Calend_Time_HtoL != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if FT_Calend_Time_HtoH != .

generate FT_Never_ChangeM = . 
replace  FT_Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  FT_Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! calendar time of the event 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

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

generate FT_Rel_Leave_Time = Leave_Time - FT_Event_Time

order IDlse YearMonth LeaverPerm Leaver Leave_Time FT_Event_Time FT_Rel_Leave_Time

label variable Leaver            "=1, if the worker left the firm during the dataset period"
label variable Leave_Time        "Time when the worker left the firm, missing if he stays during the sample period"
label variable FT_Rel_Leave_Time "Leave_Time - FT_Event_Time"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_4. outcome variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate LV_1yr   = inrange(FT_Rel_Leave_Time, 0, 12)
generate LV_2yrs  = inrange(FT_Rel_Leave_Time, 0, 24)
generate LV_3yrs  = inrange(FT_Rel_Leave_Time, 0, 36)
generate LV_4yrs  = inrange(FT_Rel_Leave_Time, 0, 48)
generate LV_5yrs  = inrange(FT_Rel_Leave_Time, 0, 60)
generate LV_6yrs  = inrange(FT_Rel_Leave_Time, 0, 72)
generate LV_7yrs  = inrange(FT_Rel_Leave_Time, 0, 84)
generate LV_8yrs  = inrange(FT_Rel_Leave_Time, 0, 96)
generate LV_9yrs  = inrange(FT_Rel_Leave_Time, 0, 108)
generate LV_10yrs = inrange(FT_Rel_Leave_Time, 0, 120)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_5. keep only a cross-sectional of dataset for four treatment groups
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: generate occurrence = _n 

keep if (YearMonth==FT_Event_Time & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1 & occurrence==1)
    //&& keep one observation for one worker, 
    //&& we are using control variables at the time of treatment for four treatment groups
    //&& we are using the first observation for control workers
keep if (Mngr_both_WL2==1 & FT_Never_ChangeM==0) | FT_Never_ChangeM==1
    //&& usual sample restriction

keep  IDlse FT_LtoL FT_LtoH FT_HtoL FT_HtoH FT_Never_ChangeM FT_Event_Time Leaver Leave_Time FT_Rel_Leave_Time LV_* Office Func AgeBand Female IDlseMHR
order IDlse FT_LtoL FT_LtoH FT_HtoL FT_HtoH FT_Never_ChangeM FT_Event_Time Leaver Leave_Time FT_Rel_Leave_Time LV_* Office Func AgeBand Female IDlseMHR

save "${TempData}/temp_ExitOutcomes.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions (cross-sectional)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close

log using "${Results}/logfile_20240922_ExitOutcomes", replace text

use "${TempData}/temp_ExitOutcomes.dta", clear 

*&& Note that we need to consider the time constraint due to the right-censoring nature of the dataset
summarize FT_Event_Time, detail // max: 743
global LastMonth = r(max)

global exit_outcomes LV_1yr LV_2yrs LV_3yrs LV_4yrs LV_5yrs LV_6yrs LV_7yrs LV_8yrs LV_9yrs LV_10yrs

label variable FT_LtoL "LtoL"
label variable FT_LtoH "LtoH"
label variable FT_HtoH "HtoH"
label variable FT_HtoL "HtoL"


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. HtoH versus HtoL; full fixed effects
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoL FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} | FT_Never_ChangeM==1, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female)
        eststo `var'
        test FT_LtoL = FT_LtoH
            local p_Lto = r(p)
            estadd scalar p_Lto = `p_Lto'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'

    local i  = `i' + 1
}

esttab $exit_outcomes using "${Results}/ExitOutcomes_AllGroups.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoL FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoL FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Lto p_Hto r2 N, labels("\hline p-values" "LtoL = LtoH" "HtoH = HtoL" "\hline R-squared" "Obs") fmt(%9.0g %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)}  & \multicolumn{1}{c}{(6)}  & \multicolumn{1}{c}{(7)}  & \multicolumn{1}{c}{(8)}  & \multicolumn{1}{c}{(9)}  & \multicolumn{1}{c}{(10)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample is a cross-sectional of workers who are in the event study. Only those workers whose outcome variable can be measured given the dataset period are kept. The control group is the omitted group. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event, while for control workers, these controls are at the first observation. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")


local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & FT_Never_ChangeM==0, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'

    local i  = `i' + 1
}

esttab $exit_outcomes using "${Results}/ExitOutcomes_ExcludeControl.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 N, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Obs") fmt(%9.0g %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)}  & \multicolumn{1}{c}{(6)}  & \multicolumn{1}{c}{(7)}  & \multicolumn{1}{c}{(8)}  & \multicolumn{1}{c}{(9)}  & \multicolumn{1}{c}{(10)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample is a cross-sectional of treatment workers who are in the event study. Only those workers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

log close