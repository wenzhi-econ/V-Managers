/* 
This do file runs event studies on additional outcomes.
    TransferSubFuncC TransferInternalC TransferOrg4C TransferOrg5C

Input: 
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== created in 0104 do file

Output:
    "${Results}/WithoutControlWorkers_FT_ProbJobV.dta"

RA: WWZ 
Time: 2024-11-12
*/

capture log close
log using "${Results}/logfile_20241114_WithoutControlWorkers_FT_AdditionalTransferOutcomes", replace text

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct outcome variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. TransferOrg4C
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferOrg4 = 0 if Org4!=.
replace  TransferOrg4 = 1 if IDlse==IDlse[_n-1] & Org4!=Org4[_n-1] & Org4!=.

generate temp = TransferOrg4
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & Org4!=.
gen TransferOrg4C = temp 
drop temp 

label variable TransferOrg4  "= 1 in the month when an individual's Org4 is diff. than the preceding"
label variable TransferOrg4C "cumulative count of Org4 transfers for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. TransferOrg5C
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferOrg5 = 0 if Org5!=.
replace  TransferOrg5 = 1 if IDlse==IDlse[_n-1] & Org5!=Org5[_n-1] & Org5!=.

generate temp = TransferOrg5
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & Org5!=.
gen TransferOrg5C = temp 
drop temp 

label variable TransferOrg5  "= 1 in the month when an individual's Org4 is diff. than the preceding"
label variable TransferOrg5C "cumulative count of Org4 transfers for an individual"

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Month0 is omitted as the reference group.
*&& 0, 1, 2, ...,  +83, +84, and >+84

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. event * period dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
summarize FT_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! FT_LtoL
generate byte FT_LtoL_X_Pre_Before`max_pre_period' = FT_LtoL * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_LtoL_X_Pre`time' = FT_LtoL * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte FT_LtoL_X_Post`time' = FT_LtoL * (FT_Rel_Time == `time')
}
generate byte FT_LtoL_X_Post_After`Lto_max_post_period' = FT_LtoL * (FT_Rel_Time > `Lto_max_post_period')

*!! FT_LtoH
generate byte FT_LtoH_X_Pre_Before`max_pre_period' = FT_LtoH * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_LtoH_X_Pre`time' = FT_LtoH * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte FT_LtoH_X_Post`time' = FT_LtoH * (FT_Rel_Time == `time')
}
generate byte FT_LtoH_X_Post_After`Lto_max_post_period' = FT_LtoH * (FT_Rel_Time > `Lto_max_post_period')

*!! FT_HtoH 
generate byte FT_HtoH_X_Pre_Before`max_pre_period' = FT_HtoH * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_HtoH_X_Pre`time' = FT_HtoH * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte FT_HtoH_X_Post`time' = FT_HtoH * (FT_Rel_Time == `time')
}
generate byte FT_HtoH_X_Post_After`Hto_max_post_period' = FT_HtoH * (FT_Rel_Time > `Hto_max_post_period')

*!! FT_HtoL 
generate byte FT_HtoL_X_Pre_Before`max_pre_period' = FT_HtoL * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_HtoL_X_Pre`time' = FT_HtoL * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte FT_HtoL_X_Post`time' = FT_HtoL * (FT_Rel_Time == `time')
}
generate byte FT_HtoL_X_Post_After`Hto_max_post_period' = FT_HtoL * (FT_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in FT_HtoH FT_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_HtoH FT_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${FT_LtoL_X_Pre} ${FT_LtoL_X_Post} ${FT_LtoH_X_Pre} ${FT_LtoH_X_Post} ${FT_HtoH_X_Pre} ${FT_HtoH_X_Post} ${FT_HtoL_X_Pre} ${FT_HtoL_X_Post}

display "${four_events_dummies}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 
    // FT_HtoH_X_Pre_Before36 FT_HtoH_X_Pre36 ... FT_HtoH_X_Pre4 FT_HtoH_X_Post0 FT_HtoH_X_Post1 ... FT_HtoH_X_Post60 FT_HtoH_X_Pre_After60 
    // FT_HtoL_X_Pre_Before36 FT_HtoL_X_Pre36 ... FT_HtoL_X_Pre4 FT_HtoL_X_Post0 FT_HtoL_X_Post1 ... FT_HtoL_X_Post60 FT_HtoL_X_Pre_After60 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. regressions on additional transfer outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSubFuncC TransferInternalC TransferOrg4C TransferOrg5C {

    if "`var'" == "TransferSubFuncC"  global title "Cross-subfunctional moves"
    if "`var'" == "TransferInternalC" global title "Internal transfers (either office, subfunction, or org4)"
    if "`var'" == "TransferOrg4C"     global title "Cross-org4 moves"
    if "`var'" == "TransferOrg5C"     global title "Cross-org5 moves"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if (FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    if "`var'" != ""     local var_name `var'

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(36)
        global PTGain_`var_name' = r(pretrend)
        global PTGain_`var_name' = string(${PTGain_`var_name'}, "%4.3f")
        generate PTGain_`var_name' = ${PTGain_`var_name'} if inrange(_n, 1, 41)

    *!! quarterly estimates
    LH_minus_LL, event_prefix(FT) pre_window_len(36) post_window_len(84) outcome(`var_name')
    twoway ///
        (scatter coeff_`var_name'_gains quarter_`var_name'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var_name'_gains ub_`var_name'_gains quarter_`var_name'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)28, grid gstyle(dot)) ///
        ylabel(, grid gstyle(dot)) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var_name'})
    graph save "${Results}/WithoutControlWorkers_FT_Gains_AllEstimates_`var_name'.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(FT) pre_window_len(36)
        global PTLoss_`var_name' = r(pretrend)
        global PTLoss_`var_name' = string(${PTLoss_`var_name'}, "%4.3f")
        generate PTLoss_`var_name' = ${PTLoss_`var_name'} if inrange(_n, 1, 41)

    *!! quarterly estimates
    HL_minus_HH, event_prefix(FT) pre_window_len(36) post_window_len(60) outcome(`var_name')
    twoway ///
        (scatter coeff_`var_name'_loss quarter_`var_name'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var_name'_loss ub_`var_name'_loss quarter_`var_name'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20, grid gstyle(dot)) /// 
        ylabel(, grid gstyle(dot)) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var_name'})
    graph save "${Results}/WithoutControlWorkers_FT_Loss_AllEstimates_`var_name'.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(FT) pre_window_len(36)
        global PTDiff_`var_name' = r(pretrend)
        global PTDiff_`var_name' = string(${PTDiff_`var_name'}, "%4.3f")
        generate PTDiff_`var_name' = ${PTDiff_`var_name'} if inrange(_n, 1, 41)

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(FT) post_window_len(60)
        global postevent_`var_name' = r(postevent)
        global postevent_`var_name' = string(${postevent_`var_name'}, "%4.3f")
        generate postevent_`var_name' = ${postevent_`var_name'} if inrange(_n, 1, 41)

    *!! quarterly estimates
    Double_Diff, event_prefix(FT) pre_window_len(36) post_window_len(60) outcome(`var_name')
    twoway ///
        (scatter coeff_`var_name'_ddiff quarter_`var_name'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var_name'_ddiff ub_`var_name'_ddiff quarter_`var_name'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-12(2)20, grid gstyle(dot)) /// 
        ylabel(, grid gstyle(dot)) ///
        xtitle(Quarters since manager change) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var_name'}" "Post coeffs. joint p-value = ${postevent_`var_name'}")
    graph save "${Results}/WithoutControlWorkers_FT_GainsMinusLoss_AllEstimates_`var_name'.gph", replace
    
}

keep coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* 
keep if inrange(_n, 1, 41)

save "${Results}/WithoutControlWorkers_FT_AdditionalTransferOutcomes.dta", replace 


log close 