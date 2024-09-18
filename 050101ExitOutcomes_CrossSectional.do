
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

keep if (FT_LtoL==1) | (FT_LtoH==1) | (FT_HtoL==1) | (FT_HtoH==1)
    //&& keep only four treatment groups
keep if YearMonth == FT_Event_Time 
    //&& keep one observation for one worker, 
    //&& this also ensures we are using control variables at the time of treatment
keep if Mngr_both_WL2 == 1
    //&& usual sample restriction

keep  IDlse FT_LtoL FT_LtoH FT_HtoL FT_HtoH FT_Event_Time Leaver Leave_Time FT_Rel_Leave_Time LV_* Office Func AgeBand Female IDlseMHR
order IDlse FT_LtoL FT_LtoH FT_HtoL FT_HtoH FT_Event_Time Leaver Leave_Time FT_Rel_Leave_Time LV_* Office Func AgeBand Female IDlseMHR

save "${TempData}/temp_ExitOutcomes.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions (cross-sectional)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close

log using "${Results}/logfile_20240906_ExitOutcomes", replace text

use "${TempData}/temp_ExitOutcomes.dta", clear 

*&& Note that we need to consider the time constraint due to the right-censoring nature of the dataset
summarize FT_Event_Time, detail // max: 743
global LastMonth = r(max)

global exit_outcomes LV_1yr LV_2yrs LV_3yrs LV_4yrs LV_5yrs LV_6yrs LV_7yrs LV_8yrs LV_9yrs LV_10yrs

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. LtoL versus LtoH; full fixed effects
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH if FT_Event_Time<=${LastPossibleEventTime} & (FT_LtoH==1 | FT_LtoL==1), vce(cluster IDlseMHR) ///
        absorb(Office##Func##FT_Event_Time AgeBand##Female)

    eststo `var'_Lto_Full

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. HtoH versus HtoL; full fixed effects
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & (FT_HtoL==1 | FT_HtoH==1), vce(cluster IDlseMHR) ///
        absorb(Office##Func##FT_Event_Time AgeBand##Female)

    eststo `var'_Hto_Full

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. LtoL versus LtoH; No FT_Event_Time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH if FT_Event_Time<=${LastPossibleEventTime} & (FT_LtoH==1 | FT_LtoL==1), vce(cluster IDlseMHR) ///
        absorb(Office##Func AgeBand##Female)

    eststo `var'_Lto_NoET

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. HtoH versus HtoL; No FT_Event_Time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & (FT_HtoL==1 | FT_HtoH==1), vce(cluster IDlseMHR) ///
        absorb(Office##Func AgeBand##Female)

    eststo `var'_Hto_NoET

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. LtoL versus LtoH; Solo FT_Event_Time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH if FT_Event_Time<=${LastPossibleEventTime} & (FT_LtoH==1 | FT_LtoL==1), vce(cluster IDlseMHR) ///
        absorb(Office##Func AgeBand##Female FT_Event_Time)

    eststo `var'_Lto_SoloET

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-6. HtoH versus HtoL; Solo FT_Event_Time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & (FT_HtoL==1 | FT_HtoH==1), vce(cluster IDlseMHR) ///
        absorb(Office##Func AgeBand##Female FT_Event_Time)

    eststo `var'_Hto_SoloET

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-7. LtoL versus LtoH; Solo Office and Func
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH if FT_Event_Time<=${LastPossibleEventTime} & (FT_LtoH==1 | FT_LtoL==1), vce(cluster IDlseMHR) ///
        absorb(Office Func AgeBand##Female)

    eststo `var'_Lto_SoloOF

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-8. HtoH versus HtoL; Solo Office and Func
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & (FT_HtoL==1 | FT_HtoH==1), vce(cluster IDlseMHR) ///
        absorb(Office Func AgeBand##Female)

    eststo `var'_Hto_SoloOF

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-9. LtoL versus LtoH; Solo Office and Func
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH if FT_Event_Time<=${LastPossibleEventTime} & (FT_LtoH==1 | FT_LtoL==1), vce(cluster IDlseMHR) ///
        absorb(Office Func AgeBand##Female FT_Event_Time)

    eststo `var'_Lto_OFET

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-10. HtoH versus HtoL; Solo Office and Func
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & (FT_HtoL==1 | FT_HtoH==1), vce(cluster IDlseMHR) ///
        absorb(Office Func AgeBand##Female FT_Event_Time)

    eststo `var'_Hto_OFET

    local i  = `i' + 1
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. report the regression table
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable FT_LtoH "L to H"
label variable FT_HtoL "H to L"

global O1_Lto_Full LV_1yr_Lto_Full LV_2yrs_Lto_Full LV_3yrs_Lto_Full LV_4yrs_Lto_Full LV_5yrs_Lto_Full LV_6yrs_Lto_Full LV_7yrs_Lto_Full LV_8yrs_Lto_Full LV_9yrs_Lto_Full LV_10yrs_Lto_Full

global O2_Hto_Full LV_1yr_Hto_Full LV_2yrs_Hto_Full LV_3yrs_Hto_Full LV_4yrs_Hto_Full LV_5yrs_Hto_Full LV_6yrs_Hto_Full LV_7yrs_Hto_Full LV_8yrs_Hto_Full LV_9yrs_Hto_Full LV_10yrs_Hto_Full

global O3_Lto_NoET LV_1yr_Lto_NoET LV_2yrs_Lto_NoET LV_3yrs_Lto_NoET LV_4yrs_Lto_NoET LV_5yrs_Lto_NoET LV_6yrs_Lto_NoET LV_7yrs_Lto_NoET LV_8yrs_Lto_NoET LV_9yrs_Lto_NoET LV_10yrs_Lto_NoET

global O4_Hto_NoET LV_1yr_Hto_NoET LV_2yrs_Hto_NoET LV_3yrs_Hto_NoET LV_4yrs_Hto_NoET LV_5yrs_Hto_NoET LV_6yrs_Hto_NoET LV_7yrs_Hto_NoET LV_8yrs_Hto_NoET LV_9yrs_Hto_NoET LV_10yrs_Hto_NoET

global O5_Lto_SoloET LV_1yr_Lto_SoloET LV_2yrs_Lto_SoloET LV_3yrs_Lto_SoloET LV_4yrs_Lto_SoloET LV_5yrs_Lto_SoloET LV_6yrs_Lto_SoloET LV_7yrs_Lto_SoloET LV_8yrs_Lto_SoloET LV_9yrs_Lto_SoloET LV_10yrs_Lto_SoloET

global O6_Hto_SoloET LV_1yr_Hto_SoloET LV_2yrs_Hto_SoloET LV_3yrs_Hto_SoloET LV_4yrs_Hto_SoloET LV_5yrs_Hto_SoloET LV_6yrs_Hto_SoloET LV_7yrs_Hto_SoloET LV_8yrs_Hto_SoloET LV_9yrs_Hto_SoloET LV_10yrs_Hto_SoloET

global O7_Lto_SoloOF LV_1yr_Lto_SoloOF LV_2yrs_Lto_SoloOF LV_3yrs_Lto_SoloOF LV_4yrs_Lto_SoloOF LV_5yrs_Lto_SoloOF LV_6yrs_Lto_SoloOF LV_7yrs_Lto_SoloOF LV_8yrs_Lto_SoloOF LV_9yrs_Lto_SoloOF LV_10yrs_Lto_SoloOF

global O8_Hto_SoloOF LV_1yr_Hto_SoloOF LV_2yrs_Hto_SoloOF LV_3yrs_Hto_SoloOF LV_4yrs_Hto_SoloOF LV_5yrs_Hto_SoloOF LV_6yrs_Hto_SoloOF LV_7yrs_Hto_SoloOF LV_8yrs_Hto_SoloOF LV_9yrs_Hto_SoloOF LV_10yrs_Hto_SoloOF

global O9_Lto_OFET LV_1yr_Lto_OFET LV_2yrs_Lto_OFET LV_3yrs_Lto_OFET LV_4yrs_Lto_OFET LV_5yrs_Lto_OFET LV_6yrs_Lto_OFET LV_7yrs_Lto_OFET LV_8yrs_Lto_OFET LV_9yrs_Lto_OFET LV_10yrs_Lto_OFET

global O10_Hto_OFET LV_1yr_Hto_OFET LV_2yrs_Hto_OFET LV_3yrs_Hto_OFET LV_4yrs_Hto_OFET LV_5yrs_Hto_OFET LV_6yrs_Hto_OFET LV_7yrs_Hto_OFET LV_8yrs_Hto_OFET LV_9yrs_Hto_OFET LV_10yrs_Hto_OFET

esttab $O1_Lto_Full using "${Results}/ExitOutcomes_Lto_Full.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH) ///
    order(FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ ") ///
    posthead() ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only LtoL and LtoH groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the LtoH treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office, function, and event time, as well as the interaction between age band and gender. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O3_Lto_NoET using "${Results}/ExitOutcomes_Lto_NoET.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH) ///
    order(FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ ") ///
    posthead() ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only LtoL and LtoH groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the LtoH treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O5_Lto_SoloET using "${Results}/ExitOutcomes_Lto_SoloET.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH) ///
    order(FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ ") ///
    posthead() ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only LtoL and LtoH groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the LtoH treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, the interaction between age band and gender, as well as the event time fixed effects. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O7_Lto_SoloOF using "${Results}/ExitOutcomes_Lto_SoloOF.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH) ///
    order(FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ ") ///
    posthead() ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only LtoL and LtoH groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the LtoH treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the office fixed effects, function fixed effects, and fixed effects of the interaction between age band and gender. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O9_Lto_OFET using "${Results}/ExitOutcomes_Lto_OFET.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH) ///
    order(FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ ") ///
    posthead() ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only LtoL and LtoH groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the LtoH treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the office fixed effects, function fixed effects, event time fixed effects, and fixed effects of the interaction between age band and gender. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O2_Hto_Full using "${Results}/ExitOutcomes_Hto_Full.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_HtoL) ///
    order(FT_HtoL) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)}  & \multicolumn{1}{c}{(6)}  & \multicolumn{1}{c}{(7)}  & \multicolumn{1}{c}{(8)}  & \multicolumn{1}{c}{(9)}  & \multicolumn{1}{c}{(10)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only HtoH and HtoL groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the HtoL treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office, function, and event time, as well as the interaction between age band and gender. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O4_Hto_NoET using "${Results}/ExitOutcomes_Hto_NoET.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_HtoL) ///
    order(FT_HtoL) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)}  & \multicolumn{1}{c}{(6)}  & \multicolumn{1}{c}{(7)}  & \multicolumn{1}{c}{(8)}  & \multicolumn{1}{c}{(9)}  & \multicolumn{1}{c}{(10)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only HtoH and HtoL groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the HtoL treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O6_Hto_SoloET using "${Results}/ExitOutcomes_Hto_SoloET.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_HtoL) ///
    order(FT_HtoL) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)}  & \multicolumn{1}{c}{(6)}  & \multicolumn{1}{c}{(7)}  & \multicolumn{1}{c}{(8)}  & \multicolumn{1}{c}{(9)}  & \multicolumn{1}{c}{(10)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only HtoH and HtoL groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the HtoL treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, the interaction between age band and gender, as well as the event time fixed effects. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O8_Hto_SoloOF using "${Results}/ExitOutcomes_Hto_SoloOF.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_HtoL) ///
    order(FT_HtoL) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)}  & \multicolumn{1}{c}{(6)}  & \multicolumn{1}{c}{(7)}  & \multicolumn{1}{c}{(8)}  & \multicolumn{1}{c}{(9)}  & \multicolumn{1}{c}{(10)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only HtoH and HtoL groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the HtoL treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the office fixed effects, function fixed effects, and fixed effects of the interaction between age band and gender. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

esttab $O10_Hto_OFET using "${Results}/ExitOutcomes_Hto_OFET.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_HtoL) ///
    order(FT_HtoL) ///
    b(3) se(2) ///
    stats(r2 N, labels("\hline R-squared" "Obs") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  & \multicolumn{1}{c}{Leave 6yrs}  & \multicolumn{1}{c}{Leave 7yrs}  & \multicolumn{1}{c}{Leave 8yrs}  & \multicolumn{1}{c}{Leave 9yrs}  & \multicolumn{1}{c}{Leave 10yrs} \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)}  & \multicolumn{1}{c}{(6)}  & \multicolumn{1}{c}{(7)}  & \multicolumn{1}{c}{(8)}  & \multicolumn{1}{c}{(9)}  & \multicolumn{1}{c}{(10)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Sample includes only HtoH and HtoL groups. Only those workers whose outcome variable can be measured given the dataset period are kept. Regression coefficients on the dummy indicating the HtoL treatment group are reproted. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the office fixed effects, function fixed effects, event time fixed effects, and fixed effects of the interaction between age band and gender. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")





log close
