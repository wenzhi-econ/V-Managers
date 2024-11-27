/* 
This do file runs event studies on a set of ONET outcomes.

Input: 
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== created in 0104 do file

Output:
    "${Results}/WithoutControlWorkers_FT_ONETResults.dta"

RA: WWZ 
Time: 2024-11-12
*/

capture log close
log using "${Results}/logfile_20241114_WithoutControlWorkers_FT_ONETBC", replace text

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct outcome variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. match firm's job names to ONET job names
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

decode SubFunc, gen(SubFuncS)
decode Func, gen(FuncS)

xtset IDlse YearMonth 
encode StandardJob, gen(StandardJobE)
generate StandardJobEBefore = l.StandardJobE
label value StandardJobEBefore StandardJobE
decode StandardJobEBefore, gen(StandardJobBefore)

generate StandardJobCodeBefore = l.StandardJobCode

generate SubFuncBefore = l.SubFunc
label value SubFuncBefore SubFunc
decode SubFuncBefore, gen(SubFuncSBefore)

generate FuncBefore = l.Func
label value FuncBefore Func
decode FuncBefore, gen(FuncSBefore)

merge m:1 FuncS SubFuncS StandardJob StandardJobCode ///
    using  "${RawONETData}/SJ Crosswalk.dta", keepusing(ONETCode ONETName)
        drop if _merge==2
        drop _merge 

merge m:1 FuncSBefore SubFuncSBefore StandardJobBefore StandardJobCodeBefore ///
    using  "${RawONETData}/SJ Crosswalk.dta", keepusing(ONETCodeBefore ONETNameBefore)
        drop if _merge==2
        drop _merge 

merge m:1 ONETCode ONETCodeBefore using  "${RawONETData}/Distance.dta" , ///
    keepusing(ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance)
        drop if _merge==2
        drop _merge  

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate cummulative sum of task measures difference
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance{
    replace `var' = 0 if (ONETCode==ONETCodeBefore & ONETCodeBefore!="" & ONETCode!="")
    replace `var' = 0 if TransferSJC==0 
    generate z =  `var'
    by IDlse (YearMonth), sort: replace z = z[_n-1] if _n>1 & StandardJob[_n]==StandardJob[_n-1]
    replace z = 0 if z ==. & ONETCode==ONETCodeBefore & ONETCodeBefore!="" & ONETCode!=""
    generate `var'C = z 
    replace `var'C = 0 if TransferSJC==0
    drop z 
}

egen ONETDistance = rowmean(ONETContextDistance ONETActivitiesDistance ONETAbilitiesDistance ONETSkillsDistance) 
egen ONETDistanceC = rowmean(ONETContextDistanceC ONETActivitiesDistanceC ONETAbilitiesDistanceC ONETSkillsDistanceC) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. modify the TransferFunc and TransferFuncC variable 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

replace TransferFunc = 0 if ONETDistance==.
    //&? only 1915 observations are affected

capture drop TransferFuncC
generate temp = TransferFunc
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & Func!=.
generate TransferFuncC = temp 
drop temp 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. count version of ONET variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate ONETB = (ONETDistance>0) if ONETDistance!=.

capture drop ONETBC
generate temp = ONETB
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & ONETDistance!=.
generate ONETBC = temp 
drop temp 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group, so in Lines 30 and 42, iteration ends with 4.
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

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
*?? step 3. regressions on ONET Outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in ONETBC {

    if "`var'" != "" global title "Count of ONET task moves"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if (FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    if "`var'" == "ONETBC"     local var_name ONETBC

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
    graph save "${Results}/WithoutControlWorkers_FT_Gains_AllEstimates_`var_name'_ONETModified.gph", replace
    
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
    graph save "${Results}/WithoutControlWorkers_FT_Loss_AllEstimates_`var_name'_ONETModified.gph", replace   

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
    graph save "${Results}/WithoutControlWorkers_FT_GainsMinusLoss_AllEstimates_`var_name'_ONETModified.gph", replace
    
}

keep PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* 
keep if inrange(_n, 1, 41)

save "${Results}/WithoutControlWorkers_FT_ONETBC.dta", replace 

log close
