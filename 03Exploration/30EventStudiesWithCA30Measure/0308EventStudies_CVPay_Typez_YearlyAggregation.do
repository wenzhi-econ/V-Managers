/* 
This do file runs event study regressions on outcome: CVPay, i.e., team-level inequality measure.
The high-flyer measure used here is CA30.

Notes on the regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60].

Input: 
    "${TempData}/0106TeamLevelEventsAndOutcomes.dta" <== created in 0106 do file

Output:
    "${EventStudyResults}/Outcome8_CVPay_Typez_YearlyAggregation.dta"
    "${EventStudyResults}/CA30_Outcome8_CVPay_Coef1_Gains_Typez_YearlyAggregation.gph"

RA: WWZ 
Time: 2025-05-21
*/

global EventStudyResults "${Results}/010EventStudiesResultsWithCA30Measure"

capture log close
log using "${EventStudyResults}/20250521log_Outcome8_CVPay_Typez_YearlyAggregation.txt", replace text

use "${TempData}/0106TeamLevelEventsAndOutcomes.dta", clear

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct variables and macros used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Pre1 CA30_LtoH_X_Post0 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoL_X_Pre_Before24 CA30_LtoH_X_Post_After84
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. "event * relative period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CA30_Rel_Time = Rel_Time
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
*-? s-0-2. global macros used in regressions 
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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-3. macros storing equations to be evaluated
*-?        they are used to calculate yearly average coefficients
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

#delimit ;
global coef_0yr_to_1yr 
    ((CA30_LtoH_X_Post1 - CA30_LtoL_X_Post1)
    + (CA30_LtoH_X_Post2 - CA30_LtoL_X_Post2)
    + (CA30_LtoH_X_Post3 - CA30_LtoL_X_Post3)
    + (CA30_LtoH_X_Post4 - CA30_LtoL_X_Post4)
    + (CA30_LtoH_X_Post5 - CA30_LtoL_X_Post5)
    + (CA30_LtoH_X_Post6 - CA30_LtoL_X_Post6)
    + (CA30_LtoH_X_Post7 - CA30_LtoL_X_Post7)
    + (CA30_LtoH_X_Post8 - CA30_LtoL_X_Post8)
    + (CA30_LtoH_X_Post9 - CA30_LtoL_X_Post9)
    + (CA30_LtoH_X_Post10 - CA30_LtoL_X_Post10)
    + (CA30_LtoH_X_Post11 - CA30_LtoL_X_Post11)
    + (CA30_LtoH_X_Post12 - CA30_LtoL_X_Post12))/12;
global coef_1yr_to_2yr 
    ((CA30_LtoH_X_Post13 - CA30_LtoL_X_Post13)
    + (CA30_LtoH_X_Post14 - CA30_LtoL_X_Post14)
    + (CA30_LtoH_X_Post15 - CA30_LtoL_X_Post15)
    + (CA30_LtoH_X_Post16 - CA30_LtoL_X_Post16)
    + (CA30_LtoH_X_Post17 - CA30_LtoL_X_Post17)
    + (CA30_LtoH_X_Post18 - CA30_LtoL_X_Post18)
    + (CA30_LtoH_X_Post19 - CA30_LtoL_X_Post19)
    + (CA30_LtoH_X_Post20 - CA30_LtoL_X_Post20)
    + (CA30_LtoH_X_Post21 - CA30_LtoL_X_Post21)
    + (CA30_LtoH_X_Post22 - CA30_LtoL_X_Post22)
    + (CA30_LtoH_X_Post23 - CA30_LtoL_X_Post23) 
    + (CA30_LtoH_X_Post24 - CA30_LtoL_X_Post24))/12;
global coef_2yr_to_3yr 
    ((CA30_LtoH_X_Post25 - CA30_LtoL_X_Post25)
    + (CA30_LtoH_X_Post26 - CA30_LtoL_X_Post26)
    + (CA30_LtoH_X_Post27 - CA30_LtoL_X_Post27)
    + (CA30_LtoH_X_Post28 - CA30_LtoL_X_Post28)
    + (CA30_LtoH_X_Post29 - CA30_LtoL_X_Post29)
    + (CA30_LtoH_X_Post30 - CA30_LtoL_X_Post30)
    + (CA30_LtoH_X_Post31 - CA30_LtoL_X_Post31)
    + (CA30_LtoH_X_Post32 - CA30_LtoL_X_Post32)
    + (CA30_LtoH_X_Post33 - CA30_LtoL_X_Post33)
    + (CA30_LtoH_X_Post34 - CA30_LtoL_X_Post34)
    + (CA30_LtoH_X_Post35 - CA30_LtoL_X_Post35) 
    + (CA30_LtoH_X_Post36 - CA30_LtoL_X_Post36))/12;
global coef_3yr_to_4yr
    ((CA30_LtoH_X_Post37 - CA30_LtoL_X_Post37)
    + (CA30_LtoH_X_Post38 - CA30_LtoL_X_Post38)
    + (CA30_LtoH_X_Post39 - CA30_LtoL_X_Post39)
    + (CA30_LtoH_X_Post40 - CA30_LtoL_X_Post40)
    + (CA30_LtoH_X_Post41 - CA30_LtoL_X_Post41)
    + (CA30_LtoH_X_Post42 - CA30_LtoL_X_Post42)
    + (CA30_LtoH_X_Post43 - CA30_LtoL_X_Post43)
    + (CA30_LtoH_X_Post44 - CA30_LtoL_X_Post44)
    + (CA30_LtoH_X_Post45 - CA30_LtoL_X_Post45)
    + (CA30_LtoH_X_Post46 - CA30_LtoL_X_Post46)
    + (CA30_LtoH_X_Post47 - CA30_LtoL_X_Post47) 
    + (CA30_LtoH_X_Post48 - CA30_LtoL_X_Post48))/12;
global coef_4yr_to_5yr 
    ((CA30_LtoH_X_Post49 - CA30_LtoL_X_Post49)
    + (CA30_LtoH_X_Post50 - CA30_LtoL_X_Post50)
    + (CA30_LtoH_X_Post51 - CA30_LtoL_X_Post51)
    + (CA30_LtoH_X_Post52 - CA30_LtoL_X_Post52)
    + (CA30_LtoH_X_Post53 - CA30_LtoL_X_Post53)
    + (CA30_LtoH_X_Post54 - CA30_LtoL_X_Post54)
    + (CA30_LtoH_X_Post55 - CA30_LtoL_X_Post55)
    + (CA30_LtoH_X_Post56 - CA30_LtoL_X_Post56)
    + (CA30_LtoH_X_Post57 - CA30_LtoL_X_Post57)
    + (CA30_LtoH_X_Post58 - CA30_LtoL_X_Post58)
    + (CA30_LtoH_X_Post59 - CA30_LtoL_X_Post59)
    + (CA30_LtoH_X_Post60 - CA30_LtoL_X_Post60))/12;
global coef_5yr_to_6yr 
    ((CA30_LtoH_X_Post61 - CA30_LtoL_X_Post61)
    + (CA30_LtoH_X_Post62 - CA30_LtoL_X_Post62)
    + (CA30_LtoH_X_Post63 - CA30_LtoL_X_Post63)
    + (CA30_LtoH_X_Post64 - CA30_LtoL_X_Post64)
    + (CA30_LtoH_X_Post65 - CA30_LtoL_X_Post65)
    + (CA30_LtoH_X_Post66 - CA30_LtoL_X_Post66)
    + (CA30_LtoH_X_Post67 - CA30_LtoL_X_Post67)
    + (CA30_LtoH_X_Post68 - CA30_LtoL_X_Post68)
    + (CA30_LtoH_X_Post69 - CA30_LtoL_X_Post69)
    + (CA30_LtoH_X_Post70 - CA30_LtoL_X_Post70)
    + (CA30_LtoH_X_Post71 - CA30_LtoL_X_Post71)
    + (CA30_LtoH_X_Post72 - CA30_LtoL_X_Post72))/12;
global coef_6yr_to_7yr 
    ((CA30_LtoH_X_Post73 - CA30_LtoL_X_Post73)
    + (CA30_LtoH_X_Post74 - CA30_LtoL_X_Post74)
    + (CA30_LtoH_X_Post75 - CA30_LtoL_X_Post75)
    + (CA30_LtoH_X_Post76 - CA30_LtoL_X_Post76)
    + (CA30_LtoH_X_Post77 - CA30_LtoL_X_Post77)
    + (CA30_LtoH_X_Post78 - CA30_LtoL_X_Post78)
    + (CA30_LtoH_X_Post79 - CA30_LtoL_X_Post79)
    + (CA30_LtoH_X_Post80 - CA30_LtoL_X_Post80)
    + (CA30_LtoH_X_Post81 - CA30_LtoL_X_Post81)
    + (CA30_LtoH_X_Post82 - CA30_LtoL_X_Post82)
    + (CA30_LtoH_X_Post83 - CA30_LtoL_X_Post83)
    + (CA30_LtoH_X_Post84 - CA30_LtoL_X_Post84))/12;
#delimit cr

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate outcome variable: CVPay
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate CVPay = SDPay / AvPay

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run event studies on CVPay
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in CVPay {

    if "`var'" == "CVPay" global title "Coefficient of variation in pay plus bonus, team level"
    if "`var'" == "CVPay" global number "8"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDteam YearMonth) vce(cluster IDMngr_Post) 

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. Calculate and Store Yearly Average Coefficients
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    xlincom ///
        (coef_0yr_to_1yr = ${coef_0yr_to_1yr}) ///
        (coef_1yr_to_2yr = ${coef_1yr_to_2yr}) ///
        (coef_2yr_to_3yr = ${coef_2yr_to_3yr}) ///
        (coef_3yr_to_4yr = ${coef_3yr_to_4yr}) ///
        (coef_4yr_to_5yr = ${coef_4yr_to_5yr}) ///
        (coef_5yr_to_6yr = ${coef_5yr_to_6yr}) ///
        (coef_6yr_to_7yr = ${coef_6yr_to_7yr}), post

    generate Year_`var'_gains = _n if inrange(_n, 1, 7)

    generate coef_`var'_gains = _n if inrange(_n, 1, 7)
    replace  coef_`var'_gains = r(table)["b", "coef_0yr_to_1yr"] if _n==1 
    replace  coef_`var'_gains = r(table)["b", "coef_1yr_to_2yr"] if _n==2
    replace  coef_`var'_gains = r(table)["b", "coef_2yr_to_3yr"] if _n==3
    replace  coef_`var'_gains = r(table)["b", "coef_3yr_to_4yr"] if _n==4
    replace  coef_`var'_gains = r(table)["b", "coef_4yr_to_5yr"] if _n==5
    replace  coef_`var'_gains = r(table)["b", "coef_5yr_to_6yr"] if _n==6
    replace  coef_`var'_gains = r(table)["b", "coef_6yr_to_7yr"] if _n==7

    generate lb_`var'_gains = _n if inrange(_n, 1, 7)
    replace  lb_`var'_gains = r(table)["ll", "coef_0yr_to_1yr"] if _n==1
    replace  lb_`var'_gains = r(table)["ll", "coef_1yr_to_2yr"] if _n==2
    replace  lb_`var'_gains = r(table)["ll", "coef_2yr_to_3yr"] if _n==3
    replace  lb_`var'_gains = r(table)["ll", "coef_3yr_to_4yr"] if _n==4
    replace  lb_`var'_gains = r(table)["ll", "coef_4yr_to_5yr"] if _n==5
    replace  lb_`var'_gains = r(table)["ll", "coef_5yr_to_6yr"] if _n==6
    replace  lb_`var'_gains = r(table)["ll", "coef_6yr_to_7yr"] if _n==7

    generate ub_`var'_gains = _n if inrange(_n, 1, 7)
    replace  ub_`var'_gains = r(table)["ul", "coef_0yr_to_1yr"] if _n==1
    replace  ub_`var'_gains = r(table)["ul", "coef_1yr_to_2yr"] if _n==2
    replace  ub_`var'_gains = r(table)["ul", "coef_2yr_to_3yr"] if _n==3
    replace  ub_`var'_gains = r(table)["ul", "coef_3yr_to_4yr"] if _n==4
    replace  ub_`var'_gains = r(table)["ul", "coef_4yr_to_5yr"] if _n==5
    replace  ub_`var'_gains = r(table)["ul", "coef_5yr_to_6yr"] if _n==6
    replace  ub_`var'_gains = r(table)["ul", "coef_6yr_to_7yr"] if _n==7

    keep Year_* coef_* lb_* ub_* 
    keep if inrange(_n, 1, 7)
    save "${EventStudyResults}/Outcome${number}_`var'_Typez_YearlyAggregation.dta", replace 

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. Plot the Yearly Average Coefficients
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    twoway ///
        (scatter coef_`var'_gains Year_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains Year_`var'_gains, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(1(1)7, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) yscale(range(-0.3 0.3)) ///
        xtitle("Years since manager change", size(medlarge)) title("${title}", span pos(12)) ///
        legend(off)
    graph save "${EventStudyResults}/CA30_Outcome${number}_`var'_Coef1_Gains_Typez_YearlyAggregation.gph", replace
}

log close 