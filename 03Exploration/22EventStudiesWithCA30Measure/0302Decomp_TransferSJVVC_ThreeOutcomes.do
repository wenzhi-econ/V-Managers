/* 
This do file decomposes workers' lateral moves into two categories.
The high-flyer measure used here is CA30.

In particular, I obtain two variables from the original dataset: TransferSJSameMVC TransferSJDiffMVC, and use them as outcomes in event studies.

Then, I run event studies regressions on these four variables and report quarter 8 and quarter 28 estimates.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month 0 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [0, +84], while for HtoH and HtoL groups, the relative time period is [0, +60].

Input: 
    "${TempData}/FinalAnalysisSample.dta"       <== created in 0103_03 do file
    "${FinalData}/Temp/AllSnapshotMCulture.dta" <== take as given, dataset from the original codes

Output:
    "${Results}/005EventStudiesWithCA30/20250516log_DecompTransferSJVVC.txt"

RA: WWZ 
Time: 2025-05-16
*/

capture log close
log using "${Results}/005EventStudiesWithCA30/20250516log_DecompTransferSJVVC.txt", replace text

use "${TempData}/FinalAnalysisSample.dta", clear 

/* keep if inrange(_n, 1, 1000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. decompose TransferSJVV into three categories:
*??         (1) within team (same manager, same function)
*??         (2) different team (different manager), and different function
*??         (3) different team (different manager), but same function
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. auxiliary variable: ChangeM and TransferSJSameM
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! first month for a worker
capture drop temp_first_month
sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

*!! if the worker changes his manager 
capture drop ChangeM
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

*!! lateral transfer under the same manager
capture drop TransferSJSameM
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*!! category (3): different manager + same function
capture drop TransferSJDiffMSameFunc
capture drop TransferSJDiffMSameFuncC
generate TransferSJDiffMSameFunc = TransferSJ 
replace  TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace  TransferSJDiffMSameFunc = 0 if TransferSJSameM==1
bysort IDlse: generate TransferSJDiffMSameFuncC= sum(TransferSJDiffMSameFunc)

*!! category (1): same manager + same function
capture drop TransferSJSameMSameFunc
capture drop TransferSJSameMSameFuncC
generate TransferSJSameMSameFunc = TransferSJ 
replace  TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace  TransferSJSameMSameFunc = 0 if TransferSJDiffMSameFunc==1
bysort IDlse: generate TransferSJSameMSameFuncC= sum(TransferSJSameMSameFunc)

*!! category (2): different manager + different function
*&& variable TransferFunc can accurately describe this category

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. decomposition 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

foreach var in TransferSJ TransferSJDiffMSameFunc TransferSJSameMSameFunc TransferFunc {

    if "`var'" == "TransferSJ"              local newvar TransferSJVV
    if "`var'" == "TransferSJDiffMSameFunc" local newvar DiffMSameFuncSJVV
    if "`var'" == "TransferSJSameMSameFunc" local newvar SameMSameFuncSJVV
    if "`var'" == "TransferFunc"            local newvar DiffFuncSJVV

    generate `newvar' =`var'
    replace  `newvar' = 0 if PromWL==0	

    bysort IDlse (YearMonth) : generate `newvar'C= sum(`newvar')
}

capture drop test
egen test = rowtotal(DiffMSameFuncSJVVC SameMSameFuncSJVVC DiffFuncSJVVC)
count if test != TransferSJVVC //&? 0, perfect 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Pre1 CA30_LtoH_X_Post0 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoL_X_Pre_Before24 CA30_LtoH_X_Post_After84
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. event * period dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate  CA30_Rel_Time = Rel_Time
summarize CA30_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 24 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! CA30_LtoL
generate byte CA30_LtoL_X_Pre_Before`max_pre_period' = CA30_LtoL * (CA30_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte CA30_LtoL_X_Pre`time' = CA30_LtoL * (CA30_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte CA30_LtoL_X_Post`time' = CA30_LtoL * (CA30_Rel_Time == `time')
}
generate byte CA30_LtoL_X_Post_After`Lto_max_post_period' = CA30_LtoL * (CA30_Rel_Time > `Lto_max_post_period')

*!! CA30_LtoH
generate byte CA30_LtoH_X_Pre_Before`max_pre_period' = CA30_LtoH * (CA30_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte CA30_LtoH_X_Pre`time' = CA30_LtoH * (CA30_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte CA30_LtoH_X_Post`time' = CA30_LtoH * (CA30_Rel_Time == `time')
}
generate byte CA30_LtoH_X_Post_After`Lto_max_post_period' = CA30_LtoH * (CA30_Rel_Time > `Lto_max_post_period')

*!! CA30_HtoH 
generate byte CA30_HtoH_X_Pre_Before`max_pre_period' = CA30_HtoH * (CA30_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte CA30_HtoH_X_Pre`time' = CA30_HtoH * (CA30_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte CA30_HtoH_X_Post`time' = CA30_HtoH * (CA30_Rel_Time == `time')
}
generate byte CA30_HtoH_X_Post_After`Hto_max_post_period' = CA30_HtoH * (CA30_Rel_Time > `Hto_max_post_period')

*!! CA30_HtoL 
generate byte CA30_HtoL_X_Pre_Before`max_pre_period' = CA30_HtoL * (CA30_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte CA30_HtoL_X_Pre`time' = CA30_HtoL * (CA30_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte CA30_HtoL_X_Post`time' = CA30_HtoL * (CA30_Rel_Time == `time')
}
generate byte CA30_HtoL_X_Post_After`Hto_max_post_period' = CA30_HtoL * (CA30_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 24 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop CA30_LtoL_X_Pre CA30_LtoL_X_Post CA30_LtoH_X_Pre CA30_LtoH_X_Post CA30_HtoH_X_Pre CA30_HtoH_X_Post CA30_HtoL_X_Pre CA30_HtoL_X_Post

foreach event in CA30_LtoL CA30_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in CA30_LtoL CA30_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in CA30_HtoH CA30_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in CA30_HtoH CA30_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${CA30_LtoL_X_Pre} ${CA30_LtoL_X_Post} ${CA30_LtoH_X_Pre} ${CA30_LtoH_X_Post} ${CA30_HtoH_X_Pre} ${CA30_HtoH_X_Post} ${CA30_HtoL_X_Pre} ${CA30_HtoL_X_Post}

display "${four_events_dummies}"

    // CA30_LtoL_X_Pre_Before24 CA30_LtoL_X_Pre24 ... CA30_LtoL_X_Pre4 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post84 CA30_LtoL_X_Pre_After84 
    // CA30_LtoH_X_Pre_Before24 CA30_LtoH_X_Pre24 ... CA30_LtoH_X_Pre4 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post84 CA30_LtoH_X_Pre_After84 
    // CA30_HtoH_X_Pre_Before24 CA30_HtoH_X_Pre24 ... CA30_HtoH_X_Pre4 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post60 CA30_HtoH_X_Pre_After60 
    // CA30_HtoL_X_Pre_Before24 CA30_HtoL_X_Pre24 ... CA30_HtoL_X_Pre4 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post60 CA30_HtoL_X_Pre_After60 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. run regressions and create the coefplot
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

//impt: TransferSJVVC SameMSameFuncSJVVC DiffMSameFuncSJVVC DiffFuncSJVVC

rename (SameMSameFuncSJVVC DiffMSameFuncSJVVC) (SameMVVC DiffMVVC)

foreach var in TransferSJVVC SameMVVC DiffMVVC DiffFuncSJVVC {

    if "`var'" == "TransferSJVVC" global title "Lateral move (*)"
    if "`var'" == "TransferSJVVC" global number "20"
    if "`var'" == "SameMVVC"      global title "Lateral move (*): Within team"
    if "`var'" == "SameMVVC"      global number "21"
    if "`var'" == "DiffMVVC"      global title "Lateral move (*): Different team, same function"
    if "`var'" == "DiffMVVC"      global number "22"
    if "`var'" == "DiffFuncSJVVC" global title "Lateral move (*): Different function"
    if "`var'" == "DiffFuncSJVVC" global number "23"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(CA30) pre_window_len(24)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    LH_minus_LL, event_prefix(CA30) pre_window_len(24) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
    graph save "${Results}/005EventStudiesWithCA30/CA30_Outcome${number}_`var'_Coef1_Gains.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(CA30) pre_window_len(24)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    HL_minus_HH, event_prefix(CA30) pre_window_len(24) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
    graph save "${Results}/005EventStudiesWithCA30/CA30_Outcome${number}_`var'_Coef2_Loss.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(CA30) pre_window_len(24)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(CA30) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    Double_Diff, event_prefix(CA30) pre_window_len(24) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_ddiff ub_`var'_ddiff quarter_`var'_ddiff, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
    graph save "${Results}/005EventStudiesWithCA30/CA30_Outcome${number}_`var'_Coef3_GainsMinusLoss.gph", replace

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 5. Storing particular coefficients
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    
    *&& Quarter 8th estimate = the average of Month 22, Month 23, and Month 24 estimates
    *&& Quarter 28th estimate = the average of Month 82, Month 83, and Month 84 estimates
    xlincom ///
        (lc_1 = ((CA30_LtoH_X_Post22 - CA30_LtoL_X_Post22) + (CA30_LtoH_X_Post23 - CA30_LtoL_X_Post23) + (CA30_LtoH_X_Post24 - CA30_LtoL_X_Post24))/3) ///
        (lc_2 = ((CA30_LtoH_X_Post82 - CA30_LtoL_X_Post82) + (CA30_LtoH_X_Post83 - CA30_LtoL_X_Post83) + (CA30_LtoH_X_Post84 - CA30_LtoL_X_Post84))/3) ///
        , level(95) post

    eststo `var'
}

coefplot ///
    (TransferSJVVC,              keep(lc_1) rename(lc_1 = "All lateral moves")                noci recast(bar)) ///
    (SameMVVC,                   keep(lc_1) rename(lc_1 = "Within team")                      noci recast(bar)) ///
    (DiffMVVC,                   keep(lc_1) rename(lc_1 = "Different team, same function")    noci recast(bar)) ///
    (DiffFuncSJVVC,              keep(lc_1) rename(lc_1 = "Different team, cross-functional") noci recast(bar)) ///
    , legend(off) xline(0, lpattern(dash)) ///
    xscale(range(0 0.2)) xlabel(0(0.01)0.2, grid gstyle(dot) labsize(medlarge)) ///
    ylabel(, labsize(large)) ///
    xsize(5) ysize(2) ///
    scheme(tab2) ///
    graphregion(margin(medium)) plotregion(margin(medium)) ///
    title("Effects of gaining a high-flyer manager", size(large))

graph save "${Results}/005EventStudiesWithCA30/CA30_Gains_DecompTransferSJVVC_DuringMngrRotation_Q8.gph", replace

coefplot ///
    (TransferSJVVC,              keep(lc_2) rename(lc_2 = "All lateral moves")                noci recast(bar)) ///
    (SameMVVC,                   keep(lc_2) rename(lc_2 = "Within team")                      noci recast(bar)) ///
    (DiffMVVC,                   keep(lc_2) rename(lc_2 = "Different team, same function")    noci recast(bar)) ///
    (DiffFuncSJVVC,              keep(lc_2) rename(lc_2 = "Different team, cross-functional") noci recast(bar)) ///
    , legend(off) xline(0, lpattern(dash)) ///
    xscale(range(0 0.2)) xlabel(0(0.01)0.2, grid gstyle(dot) labsize(medlarge)) ///
    ylabel(, labsize(large)) ///
    xsize(5) ysize(2) ///
    scheme(tab2) ///
    graphregion(margin(medium)) plotregion(margin(medium)) ///
    title("Effects of gaining a high-flyer manager", size(large))

graph save "${Results}/005EventStudiesWithCA30/CA30_Gains_DecompTransferSJVVC_AfterMngrRotation_Q28.gph", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. store the event studies results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep ///
    PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* ///
    LtoL_* LtoH_* HtoH_* HtoL_* ///
    coef1_* coefp1_* coef2_* coefp2_* coef3_* coefp3_* coef4_* coefp4_* coef5_* coefp5_* coef6_* coefp6_* ///
    RI1_* rip1_* RI2_* rip2_* RI3_* rip3_*

keep if inrange(_n, 1, 41)

save "${Results}/005EventStudiesWithCA30/CA30_DecompTransferSJVVC.dta", replace 

log close