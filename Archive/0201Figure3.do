/* 
This do file aims to replicate Figure 3 in the paper.

Four outcomes variables are analyzed:
    TransferSJVC TransferFuncC LeaverPerm ChangeSalaryGradeC

*/

use "${FinalData}/EventStudySample.dta", clear 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. store EventXTime indicators in macros 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_1. sample 50% of the control workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
set seed 98034
capture drop temp_random_control
generate temp_random_control = runiform() if ind_tag==1 & Never_ChangeM==1 
recode temp_random_control (0/0.5 = 1) (0.5/1 = 0) 
bysort IDlse: egen random_control = mean(temp_random_control)
tabulate random_control if Never_ChangeM==1, missing 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_2. specify event window length 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global pre_window_length  = 34 
global post_window_length = 83

global max_pre_quarter_index  = trunc(${pre_window_length}/3) + 1 // 12 
global max_post_quarter_index = trunc(${post_window_length}/3)    // 28
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s2_1. create 8 global macros
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
There are 8 macros used in the regression (4 events times 2 period-indicators (pre vs post)).
They are ${HighFlyer1_LtoL_X_PreTimes} ${HighFlyer1_LtoH_X_PreTimes} ${HighFlyer1_HtoL_X_PreTimes} ${HighFlyer1_HtoH_X_PreTimes} ${HighFlyer1_LtoL_X_PostTimes} ${HighFlyer1_LtoH_X_PostTimes} ${HighFlyer1_HtoL_X_PostTimes} ${HighFlyer1_HtoH_X_PostTimes}.
Before running the regressions, we need to remove Pre1 in 
*/

/* 
And I consider three cases that contain different range of "event times period" indicators. 
*/
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s2_1_1. All indicators [-131,+130]
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
summarize Month_to_First_ChangeM, detail 
local max_pre_period  = -r(min)
local max_post_period =  r(max)

macro drop ///
    HighFlyer1_LtoL_X_PreALL HighFlyer1_LtoH_X_PreALL ///
    HighFlyer1_HtoL_X_PreALL HighFlyer1_HtoH_X_PreALL ///
    HighFlyer1_LtoL_X_PostALL HighFlyer1_LtoH_X_PostALL ///
    HighFlyer1_HtoL_X_PostALL HighFlyer1_HtoH_X_PostALL

foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    forvalues time = 1/`max_pre_period' {
        global `event'_X_PreALL ${`event'_X_PreALL} `event'_X_Pre`time'
    }
}
foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_PostALL ${`event'_X_PostALL} `event'_X_Post`time'
    }
}

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s2_1_2. Indicators inside [-84,+84] plus PreEnd85 and PostEnd85
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

macro drop ///
    HighFlyer1_LtoL_X_PreOLD HighFlyer1_LtoH_X_PreOLD ///
    HighFlyer1_HtoL_X_PreOLD HighFlyer1_HtoH_X_PreOLD ///
    HighFlyer1_LtoL_X_PostOLD HighFlyer1_LtoH_X_PostOLD ///
    HighFlyer1_HtoL_X_PostOLD HighFlyer1_HtoH_X_PostOLD

foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    forvalues time = 1/84 {
        global `event'_X_PreOLD ${`event'_X_PreOLD} `event'_X_Pre`time'
    }
    global `event'_X_PreOLD ${`event'_X_PreOLD} `event'_X_Pre_End85
}
foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    forvalues time = 0/84 {
        global `event'_X_PostOLD ${`event'_X_PostOLD} `event'_X_Post`time'
    }
    global `event'_X_PostOLD ${`event'_X_PostOLD} `event'_X_Post_End85
}

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s2_1_3. Indicators specified by event window length [-34, +86]
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

macro drop ///
    HighFlyer1_LtoL_X_PreWINDOW HighFlyer1_LtoH_X_PreWINDOW ///
    HighFlyer1_HtoL_X_PreWINDOW HighFlyer1_HtoH_X_PreWINDOW ///
    HighFlyer1_LtoL_X_PostWINDOW HighFlyer1_LtoH_X_PostWINDOW ///
    HighFlyer1_HtoL_X_PostWINDOW HighFlyer1_HtoH_X_PostWINDOW

foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    forvalues time = 1/$pre_window_length {
        global `event'_X_PreWINDOW ${`event'_X_PreWINDOW} `event'_X_Pre`time'
    }
}
foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    forvalues time = 0/$post_window_length {
        global `event'_X_PostWINDOW ${`event'_X_PostWINDOW} `event'_X_Post`time'
    }
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s2_2. create macros relevant to the regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! this is the macro storing the reference groups
global reference_group HighFlyer1_LtoL_X_Pre1 HighFlyer1_LtoH_X_Pre1 

*!! these are three macros representing three cases
global GainHF_ALL ///
    ${HighFlyer1_LtoL_X_PreALL} ${HighFlyer1_LtoL_X_PostALL} /// 
    ${HighFlyer1_LtoH_X_PreALL} ${HighFlyer1_LtoH_X_PostALL} 

global GainHF_OLD ///
    ${HighFlyer1_LtoL_X_PreOLD} ${HighFlyer1_LtoL_X_PostOLD} /// 
    ${HighFlyer1_LtoH_X_PreOLD} ${HighFlyer1_LtoH_X_PostOLD} 

global GainHF_WINDOW ///
    ${HighFlyer1_LtoL_X_PreWINDOW} ${HighFlyer1_LtoL_X_PostWINDOW} ///
    ${HighFlyer1_LtoH_X_PreWINDOW} ${HighFlyer1_LtoH_X_PostWINDOW} 

*!! these are three macros used in the regression 
global GainHF_ALL_for_reg:    list global(GainHF_ALL) - global(reference_group)

global GainHF_OLD_for_reg:    list global(GainHF_OLD) - global(reference_group)

global GainHF_WINDOW_for_reg: list global(GainHF_WINDOW) - global(reference_group)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions for comparison 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* capture drop test_1 
capture drop test_2 
capture drop test_3 
egen test_1 = rowtotal(Never_ChangeM HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH)
codebook test_1 
    // in this dataset, each worker belongs to one and only one treatement group

egen test_2 = rowtotal(${all_events})
codebook test_2 if inrange(Month_to_First_ChangeM, -${pre_window_length}, ${post_window_length})
    // todo this is to be discussed!
    // how to specify the right reference group 
    // in the regression sample, variables ${events} are perfectly colinear
    // but we only need to drop *one period for one treatment group* for the sake of identification  */

//&& The logic of the if condition is as follows:
//&& First, we include all workers from the control group in the sample. (Never_ChangeM==1)
//&& Next, we include workers from two treatment groups in the sample. (HighFlyer1_LtoL==1 | HighFlyer1_LtoH==1)
//&& Finally, we restrict workers from the treatment groups to those whose pre- and post-managers are both at WL2. (Mngr_both_WL2==1 & (HighFlyer1_LtoL==1 | HighFlyer1_LtoH==1))
//&& To speed up the estimation, we can use only 20% of the control workers. That is, replace (Never_ChangeM==1) with (random_control==1).

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s3_1. using all "event times period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* reghdfe ChangeSalaryGradeC ${GainHF_ALL_for_reg} ///
    if ((Never_ChangeM==1) | (Mngr_both_WL2==1 & (HighFlyer1_LtoL==1 | HighFlyer1_LtoH==1))) ///
    , absorb(i.IDlse i.YearMonth) vce(cluster IDlseMHR) 

LH_minus_LL, ///
    pre_window_len(${pre_window_length}) post_window_len(${post_window_length}) ///
    outcome(ChangeSalaryGradeC) event_prefix(HighFlyer1)

twoway ///
    (scatter coefficients quarter_index, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lower_bound upper_bound quarter_index, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-${max_pre_quarter_index}(2)${max_post_quarter_index}) ylabel(-0.1(0.1)0.3) ///
    xtitle(Quarters since manager change) title(ChangeSalaryGradeC, span pos(12)) ///
    legend(off)
graph export "${DoFiles}/summary/summary1_without_period_constraints.png", replace */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s3_2. using the same "event times period" dummies as the old file does 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe ChangeSalaryGradeC ${GainHF_OLD_for_reg} ///
    if ((Never_ChangeM==1) | (Mngr_both_WL2==1 & (HighFlyer1_LtoL==1 | HighFlyer1_LtoH==1))) ///
    , absorb(i.IDlse i.YearMonth) vce(cluster IDlseMHR) 

LH_minus_LL, ///
    pre_window_len(${pre_window_length}) post_window_len(${post_window_length}) ///
    outcome(ChangeSalaryGradeC) event_prefix(HighFlyer1)

twoway ///
    (scatter coefficients quarter_index, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lower_bound upper_bound quarter_index, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-${max_pre_quarter_index}(2)${max_post_quarter_index}) ylabel(-0.1(0.1)0.3) ///
    xtitle(Quarters since manager change) title(ChangeSalaryGradeC, span pos(12)) ///
    legend(off)
graph export "${DoFiles}/summary/summary2_same_period_constraints.png", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s3_3. using only those "event times period" dummies in the event window  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* reghdfe ChangeSalaryGradeC ${GainHF_WINDOW_for_reg} ///
    if inrange(Month_to_First_ChangeM, -${pre_window_length}, ${post_window_length}) ///
        & ((Never_ChangeM==1) | (Mngr_both_WL2==1 & (HighFlyer1_LtoL==1 | HighFlyer1_LtoH==1))) ///
    , absorb(i.IDlse i.YearMonth) vce(cluster IDlseMHR) 

LH_minus_LL, ///
    pre_window_len(${pre_window_length}) post_window_len(${post_window_length}) ///
    outcome(ChangeSalaryGradeC) event_prefix(HighFlyer1)

twoway ///
    (scatter coefficients quarter_index, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lower_bound upper_bound quarter_index, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-${max_pre_quarter_index}(2)${max_post_quarter_index}) ylabel(-0.1(0.1)0.3) ///
    xtitle(Quarters since manager change) title(ChangeSalaryGradeC, span pos(12)) ///
    legend(off)
graph export "${DoFiles}/summary/summary3_with_period_constraints.png", replace */


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s3_4. using old those "event times period" dummies plus random selected controls   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* reghdfe ChangeSalaryGradeC ${GainHF_OLD_for_reg} ///
    if ((random_control==1) | (Mngr_both_WL2==1 & (HighFlyer1_LtoL==1 | HighFlyer1_LtoH==1))) ///
    , absorb(i.IDlse i.YearMonth) vce(cluster IDlseMHR) 

LH_minus_LL, ///
    pre_window_len(${pre_window_length}) post_window_len(${post_window_length}) ///
    outcome(ChangeSalaryGradeC) event_prefix(HighFlyer1)

twoway ///
    (scatter coefficients quarter_index, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lower_bound upper_bound quarter_index, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-${max_pre_quarter_index}(2)${max_post_quarter_index}) ylabel(-0.1(0.1)0.3) ///
    xtitle(Quarters since manager change) title(ChangeSalaryGradeC, span pos(12)) ///
    legend(off)

graph export "${DoFiles}/summary/summary4_same_period_constraints_random50.png", replace */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s3_5. using all "event times period" dummies plus random selected controls   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* reghdfe ChangeSalaryGradeC ${GainHF_ALL_for_reg} ///
    if ((random_control==1) | (Mngr_both_WL2==1 & (HighFlyer1_LtoL==1 | HighFlyer1_LtoH==1))) ///
    , absorb(i.IDlse i.YearMonth) vce(cluster IDlseMHR) 

LH_minus_LL, ///
    pre_window_len(${pre_window_length}) post_window_len(${post_window_length}) ///
    outcome(ChangeSalaryGradeC) event_prefix(HighFlyer1)

twoway ///
    (scatter coefficients quarter_index, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lower_bound upper_bound quarter_index, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-${max_pre_quarter_index}(2)${max_post_quarter_index}) ylabel(-0.1(0.1)0.3) ///
    xtitle(Quarters since manager change) title(ChangeSalaryGradeC, span pos(12)) ///
    legend(off)

graph export "${DoFiles}/summary/summary5_without_period_constraints_random50.png", replace */


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. run regressions for paper results  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
/* 
local var_index = 1
local var_label_1 "Lateral move"
local var_label_2 "Lateral move, function"
local var_label_3 "Salary grade increase"

foreach var in TransferSJVC TransferFuncC ChangeSalaryGradeC {

    reghdfe `var' ${GainHF_OLD_for_reg} ///
    if ((Never_ChangeM==1) | (Mngr_both_WL2==1 & (HighFlyer1_LtoL==1 | HighFlyer1_LtoH==1))) ///
    , absorb(i.IDlse i.YearMonth) vce(cluster IDlseMHR) 

    LH_minus_LL_pretrend, ///
        pre_window_len(${pre_window_length}) outcome(`var') event_prefix(HighFlyer1)
    summarize jointF
    local pre_trend_p_value = round(r(mean), 0.001)

    LH_minus_LL, ///
        pre_window_len(${pre_window_length}) post_window_len(${post_window_length}) ///
        outcome(`var') event_prefix(HighFlyer1)


    if `var_index' == 1 {
        local ylabel "ylabel(-0.05(0.05)0.2)"
    }
    if `var_index' == 2 {
        local ylabel "ylabel(-0.05(0.05)0.1)"
    }
    if `var_index' == 3 {
        local ylabel "ylabel(-0.1(0.1)0.3)"
    }

    twoway ///
        (scatter coefficients quarter_index, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lower_bound upper_bound quarter_index, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-${max_pre_quarter_index}(2)${max_post_quarter_index}) xtitle(Quarters since manager change) ///
        `ylabel' ///
        title("`var_label_`var_index''", span pos(12)) ///
        legend(off) ///
        note("Pre-trends joint p-value = `pre_trend_p_value'")
    graph save   "${Results}/`var'.gph", replace
    graph export "${Results}/`var'.png", replace

    local var_index = `var_index' + 1
} */

