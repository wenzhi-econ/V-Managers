/* 
This do file runs event study regressions on outcome: TransferSJLC.
The high-flyer measure used here is CA30.

Special notes:
    (1) This do file investigates which group of employees contribute to the weird increase for the effects of losing a high-flyer manager.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60].

Some key results (quarterly aggregated coefficients with their p-values, and other key summary statistics) are stored in the output file. 

Input: 
    "${TempData}/FinalAnalysisSample.dta" <== created in 0103_03 do file

Output:
    "${EventStudyResults}/20250521log_Outcome3_TransferSJLC_Type6_DiffTenure.txt"
    "${EventStudyResults}/Outcome3_TransferSJLC_Type6_DiffTenure.dta"

RA: WWZ 
Time: 2025-05-21
*/

global EventStudyResults "${Results}/010EventStudiesResultsWithCA30Measure"

capture log close
log using "${EventStudyResults}/20250521log_Outcome3_TransferSJLC_Type6_DiffTenure.txt", replace text

use "${TempData}/FinalAnalysisSample.dta", clear

capture drop TransferSJL 
capture drop TransferSJLC
foreach var in TransferSJ {

    generate `var'L =`var'
    replace  `var'L = 0 if PromWL==1

    sort IDlse YearMonth
    bysort IDlse (YearMonth): generate `var'LC  = sum(`var'L)
}

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. investigate the tenure distribution
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sort IDlse YearMonth
bysort IDlse: egen TenureAtEvent = mean(cond(Rel_Time==0, Tenure, .))

tabulate TenureAtEvent
/* 
TenureAtEve |
         nt |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    335,645       17.81       17.81
          1 |    346,703       18.40       36.22
          2 |    193,110       10.25       46.46
          3 |    120,194        6.38       52.84
          4 |     89,936        4.77       57.62
          5 |     70,837        3.76       61.38
          6 |     62,594        3.32       64.70
          7 |     55,200        2.93       67.63
          8 |     45,550        2.42       70.05
          9 |     34,849        1.85       71.90
         10 |     35,204        1.87       73.76
         11 |     33,672        1.79       75.55
         12 |     33,880        1.80       77.35
         13 |     31,668        1.68       79.03
         14 |     29,579        1.57       80.60
         15 |     29,371        1.56       82.16
         16 |     28,487        1.51       83.67
         17 |     27,176        1.44       85.11
         18 |     26,670        1.42       86.53
         19 |     24,310        1.29       87.82
         20 |     22,448        1.19       89.01
         21 |     21,623        1.15       90.16
         22 |     22,827        1.21       91.37
         23 |     26,161        1.39       92.76
         24 |     22,314        1.18       93.94
         25 |     15,709        0.83       94.78
         26 |     13,496        0.72       95.49
         27 |     14,563        0.77       96.27
         28 |     10,328        0.55       96.81
         29 |      9,911        0.53       97.34
         30 |      8,675        0.46       97.80
         31 |      7,552        0.40       98.20
         32 |      9,091        0.48       98.68
         33 |      5,618        0.30       98.98
         34 |      4,408        0.23       99.22
         35 |      4,156        0.22       99.44
         36 |      3,470        0.18       99.62
         37 |      1,852        0.10       99.72
         38 |      1,457        0.08       99.80
         39 |        639        0.03       99.83
         40 |        982        0.05       99.88
         41 |        863        0.05       99.93
         42 |        566        0.03       99.96
         43 |        200        0.01       99.97
         44 |        346        0.02       99.99
         45 |         41        0.00       99.99
         46 |        178        0.01      100.00
         51 |         36        0.00      100.00
------------+-----------------------------------
      Total |  1,884,145      100.00
*/
tabulate TenureAtEvent if CA30_HtoH==1 | CA30_HtoL==1
/* 
TenureAtEve |
         nt |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    108,853       31.49       31.49
          1 |     88,291       25.54       57.03
          2 |     34,838       10.08       67.10
          3 |     20,082        5.81       72.91
          4 |     10,346        2.99       75.91
          5 |      9,122        2.64       78.55
          6 |      6,539        1.89       80.44
          7 |      5,373        1.55       81.99
          8 |      4,465        1.29       83.28
          9 |      3,766        1.09       84.37
         10 |      3,629        1.05       85.42
         11 |      3,719        1.08       86.50
         12 |      2,557        0.74       87.24
         13 |      3,690        1.07       88.30
         14 |      1,720        0.50       88.80
         15 |      4,092        1.18       89.99
         16 |      3,093        0.89       90.88
         17 |      3,249        0.94       91.82
         18 |      3,142        0.91       92.73
         19 |      2,791        0.81       93.54
         20 |      1,991        0.58       94.11
         21 |      2,115        0.61       94.72
         22 |      3,163        0.91       95.64
         23 |      2,891        0.84       96.48
         24 |      2,142        0.62       97.09
         25 |      2,324        0.67       97.77
         26 |      1,256        0.36       98.13
         27 |      1,303        0.38       98.51
         28 |      1,019        0.29       98.80
         29 |        713        0.21       99.01
         30 |        999        0.29       99.30
         31 |        855        0.25       99.54
         32 |        370        0.11       99.65
         33 |        663        0.19       99.84
         34 |        144        0.04       99.89
         35 |         48        0.01       99.90
         36 |         84        0.02       99.92
         37 |         66        0.02       99.94
         38 |         66        0.02       99.96
         40 |         83        0.02       99.99
         41 |         24        0.01       99.99
         42 |         26        0.01      100.00
------------+-----------------------------------
      Total |    345,702      100.00
*/

generate TenureRestriction1 = (inrange(TenureAtEvent, 0, 2))  if TenureAtEvent!=.
generate TenureRestriction2 = (inrange(TenureAtEvent, 3, 10)) if TenureAtEvent!=.
generate TenureRestriction3 = (TenureAtEvent > 10)            if TenureAtEvent!=.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct variables and macros used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Pre1 CA30_LtoH_X_Post0 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoL_X_Pre_Before24 CA30_LtoH_X_Post_After84
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. "event * relative period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate  CA30_Rel_Time = Rel_Time
summarize CA30_Rel_Time, detail

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
*?? step 3. event studies on the two main outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSJLC {

    if "`var'" == "TransferSJLC" global title "Lateral move"
    if "`var'" == "TransferSJLC" global number "3"

    forvalues num_restriction = 1/3 {

        //impt: loop over three different tenure restrictions

        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
        *-? step 1. Main Regression
        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

        reghdfe `var' ${four_events_dummies} if TenureRestriction`num_restriction'==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
        
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
            ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) yscale(range(-0.3 0.3)) ///
            xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
            legend(off) note(Pre-trends joint p-value = ${PTGain_`var'})
        graph save "${EventStudyResults}/CA30_Outcome${number}_`var'_Coef1_Gains_Type6_TenureRestriction`num_restriction'.gph", replace
        
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
            ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) yscale(range(-0.3 0.3)) ///
            xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
            legend(off) note(Pre-trends joint p-value = ${PTLoss_`var'})
        graph save "${EventStudyResults}/CA30_Outcome${number}_`var'_Coef2_Loss_Type6_TenureRestriction`num_restriction'.gph", replace   

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
            ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) yscale(range(-0.3 0.3)) ///
            xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
            legend(off) note("Pre-trends joint p-value = ${PTDiff_`var'}" "Post coeffs. joint p-value = ${postevent_`var'}")
        graph save "${EventStudyResults}/CA30_Outcome${number}_`var'_Coef3_GainsMinusLoss_Type6_TenureRestriction`num_restriction'.gph", replace

        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
        *-? step 4. Renaming the Coefficients
        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

        capture drop PTGain_* PTLoss_* PTDiff_* postevent_* 
        capture drop LtoL_* LtoH_* HtoH_* HtoL_*
        capture drop coef1_* coefp1_* coef2_* coefp2_* coef3_* coefp3_* coef4_* coefp4_* coef5_* coefp5_* coef6_* coefp6_*
        capture drop RI1_* rip1_* RI2_* rip2_* RI3_* rip3_*
            
        rename (coeff_`var'_gains coeff_`var'_loss coeff_`var'_ddiff)       (coeff_`var'_gains`num_restriction' coeff_`var'_loss`num_restriction' coeff_`var'_ddiff`num_restriction')
        rename (quarter_`var'_gains quarter_`var'_loss quarter_`var'_ddiff) (quarter_`var'_gains`num_restriction' quarter_`var'_loss`num_restriction' quarter_`var'_ddiff`num_restriction') 
        rename (lb_`var'_gains lb_`var'_loss lb_`var'_ddiff)                (lb_`var'_gains`num_restriction' lb_`var'_loss`num_restriction' lb_`var'_ddiff`num_restriction')
        rename (ub_`var'_gains ub_`var'_loss ub_`var'_ddiff)                (ub_`var'_gains`num_restriction' ub_`var'_loss`num_restriction' ub_`var'_ddiff`num_restriction')
    }

}

keep coeff_* quarter_* lb_* ub_*
keep if inrange(_n, 1, 41)
save "${EventStudyResults}/Outcome3_TransferSJLC_Type6_DiffTenure.dta", replace 

log close