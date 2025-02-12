/* 
This do file calculates several statistics about the magnitude of the pay gap between the LtoH and LtoL groups.

RA: WWZ 
Time: 2025-01-21
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. event numbers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Mngr_both_WL2==1 & FT_Rel_Time!=.
    //&? a panel of event workers 

sort IDlse YearMonth 
bysort IDlse: generate occurrence = _n 

count if occurrence==1 
    //&? number of workers: 29,610
count if occurrence==1 & FT_LtoL==1
    //&? number of LtoL events: 20,853
count if occurrence==1 & FT_LtoH==1
    //&? number of LtoH events: 4,148
count if occurrence==1 & FT_HtoH==1
    //&? number of HtoH events: 1,753
count if occurrence==1 & FT_HtoL==1
    //&? number of HtoL events: 2,856

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. economic magnitude of the pay gap between LtoH and LtoL groups 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close
log using "${Results}/logfile_20250121_PayStatistics", replace text

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. PDV effects 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-1. construct variables used in reghdfe command
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. FT_LtoL_X_Pre1 FT_LtoH_X_Post0 FT_HtoH_X_Post12
For binned dummies, e.g. FT_LtoL_X_Pre_Before36 FT_LtoH_X_Post_After84
*/

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

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-2. global macros used in regressions 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop FT_LtoL_X_Pre FT_LtoL_X_Post FT_LtoH_X_Pre FT_LtoH_X_Post FT_HtoH_X_Pre FT_HtoH_X_Post FT_HtoL_X_Pre FT_HtoL_X_Post

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

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-3. run regressions
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

foreach var in LogPayBonus {

    *&& run regressions
    reghdfe `var' ${four_events_dummies} if (FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    *&& store yearly effects  
    lincom FT_LtoH_X_Post12 - FT_LtoL_X_Post12
        global eff_1yrLater = r(estimate)
    lincom FT_LtoH_X_Post24 - FT_LtoL_X_Post24
        global eff_2yrLater = r(estimate)
    lincom FT_LtoH_X_Post36 - FT_LtoL_X_Post36
        global eff_3yrLater = r(estimate)
    lincom FT_LtoH_X_Post48 - FT_LtoL_X_Post48
        global eff_4yrLater = r(estimate)
    lincom FT_LtoH_X_Post60 - FT_LtoL_X_Post60
        global eff_5yrLater = r(estimate)
    lincom FT_LtoH_X_Post72 - FT_LtoL_X_Post72
        global eff_6yrLater = r(estimate)
    lincom FT_LtoH_X_Post84 - FT_LtoL_X_Post84
        global eff_7yrLater = r(estimate)
}

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-4. calculate PDV
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

display "=================================================================="
display "PDV Calculation==================================================="
display "=================================================================="

display ///
    0 + ///
    ${eff_1yrLater}/(1.05)^1 + ///
    ${eff_2yrLater}/(1.05)^2 + ///
    ${eff_3yrLater}/(1.05)^3 + ///
    ${eff_4yrLater}/(1.05)^4 + ///
    ${eff_5yrLater}/(1.05)^5 + ///
    ${eff_6yrLater}/(1.05)^6 + ///
    ${eff_7yrLater}/(1.05)^7 + ///
    ${eff_7yrLater}/(1.05)^8 + ///
    ${eff_7yrLater}/(1.05)^9 + ///
    ${eff_7yrLater}/(1.05)^10 + ///
    ${eff_7yrLater}/(1.05)^11 + ///
    ${eff_7yrLater}/(1.05)^12 + ///
    ${eff_7yrLater}/(1.05)^13 + ///
    ${eff_7yrLater}/(1.05)^14 + ///
    ${eff_7yrLater}/(1.05)^15 + ///
    ${eff_7yrLater}/(1.05)^16 + ///
    ${eff_7yrLater}/(1.05)^17 + ///
    ${eff_7yrLater}/(1.05)^18 + ///
    ${eff_7yrLater}/(1.05)^19 + ///
    ${eff_7yrLater}/(1.05)^20 + ///
    ${eff_7yrLater}/(1.05)^21 + ///
    ${eff_7yrLater}/(1.05)^22 + ///
    ${eff_7yrLater}/(1.05)^23 + ///
    ${eff_7yrLater}/(1.05)^24 + ///
    ${eff_7yrLater}/(1.05)^25 + ///
    ${eff_7yrLater}/(1.05)^26 + ///
    ${eff_7yrLater}/(1.05)^27 + ///
    ${eff_7yrLater}/(1.05)^28 + ///
    ${eff_7yrLater}/(1.05)^29
    //&? 1.3292901

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. a money amount in USD
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop Year
generate Year = year(dofm(YearMonth))

summarize PayBonus if ISOCode =="USA" & Year==2019 & WL==1, detail 
    //&? It is measured in Euros 
    //&? 1 euro = 1.1194 dollars in 2019 (average)
    //&? The exchange rate is taken from https://fred.stlouisfed.org/series/DEXUSEU

display "=================================================================="
display "Money Amount Calculation=========================================="
display "=================================================================="

display "Calculation based on mean: "
display ${eff_7yrLater} * r(mean) * 1.1194
    //&? 8651.1598

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. tenure lengths according to a mincerian-style regression 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen TenureMin = min(Tenure)

reghdfe LogPayBonus c.Tenure##c.Tenure if WL==1 & TenureMin<2, absorb(Country YearMonth) vce(cluster IDlseMHR)

global coef_0 = _b[_cons]
global coef_1 = _b[Tenure]
global coef_2 = _b[c.Tenure#c.Tenure]

display "=================================================================="
display "Tenure Equivalent Calculation====================================="
display "=================================================================="

display "The constant term in the equation: "
display - ${eff_7yrLater} 
    //&? - 0.1028705
display "The linear term in the equation: "
display ${coef_1} 
    //&? 0.02905944
display "The quadratic term in the equation: "
display ${coef_2} 
    //&? -0.00076159

/* 
To calculate the 7th year coefficient equivalent in the tenure regression, I solve for the following equation:
    ${coef_2} * x^2 + ${coef_1} * x = ${eff_7yrLater}, i.e.,
    -0.0007616 * x^2 + 0.0290594 * x = 0.1028705

The roots are calculated using the following Python codes:
    import numpy as np
    linear_term_tenure_regression = 0.0290594
    squared_term_tenure_regression = -0.0007616
    effect_7yrslater = 0.1028705

    coefficients = [
        squared_term_tenure_regression,
        linear_term_tenure_regression,
        -effect_7yrslater,
    ]
    roots = np.roots(coefficients)
    print(f"The roots are: {roots}")
which gives the following results:
    The roots are: [34.2070816   3.94864319]
*/

log close