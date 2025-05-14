/* 
This do file presents the event study coefficients using three measures: CA30, TB04, and TB05.

Input:
    "${TempData}/FinalAnalysisSample_Simplified_WithTenureBasedMeasures.dta" <== created in 0103_02 do file 

Output:
    "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_Pre24Post84.dta"
    "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_Pre24Post84.dta"
    "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84.dta"
    "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_Pre24Post84_ForMerge.dta"
    "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_Pre24Post84_ForMerge.dta"
    "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84_ForMerge.dta

RA: WWZ 
Time: 2025-05-12
*/


capture log close
log using "${Results}/006EventStudiesWithTenureBasedMeasures/20250512log_TwoMainOutcomes_ThreeHFMeasures_CA30TB04TB05.txt", replace text

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. run event studies with measure TB04
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample_Simplified_WithTenureBasedMeasures.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. construct variables and macros used in reghdfe command
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. TB04_LtoL_X_Pre1 TB04_LtoH_X_Post0 TB04_HtoH_X_Post12
For binned dummies, e.g. TB04_LtoL_X_Pre_Before36 TB04_LtoH_X_Post_After84
*/

generate  TB04_Rel_Time = Rel_Time
summarize TB04_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 24 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! TB04_LtoL
generate byte TB04_LtoL_X_Pre_Before`max_pre_period' = TB04_LtoL * (TB04_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB04_LtoL_X_Pre`time' = TB04_LtoL * (TB04_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte TB04_LtoL_X_Post`time' = TB04_LtoL * (TB04_Rel_Time == `time')
}
generate byte TB04_LtoL_X_Post_After`Lto_max_post_period' = TB04_LtoL * (TB04_Rel_Time > `Lto_max_post_period')

*!! TB04_LtoH
generate byte TB04_LtoH_X_Pre_Before`max_pre_period' = TB04_LtoH * (TB04_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB04_LtoH_X_Pre`time' = TB04_LtoH * (TB04_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte TB04_LtoH_X_Post`time' = TB04_LtoH * (TB04_Rel_Time == `time')
}
generate byte TB04_LtoH_X_Post_After`Lto_max_post_period' = TB04_LtoH * (TB04_Rel_Time > `Lto_max_post_period')

*!! TB04_HtoH 
generate byte TB04_HtoH_X_Pre_Before`max_pre_period' = TB04_HtoH * (TB04_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB04_HtoH_X_Pre`time' = TB04_HtoH * (TB04_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte TB04_HtoH_X_Post`time' = TB04_HtoH * (TB04_Rel_Time == `time')
}
generate byte TB04_HtoH_X_Post_After`Hto_max_post_period' = TB04_HtoH * (TB04_Rel_Time > `Hto_max_post_period')

*!! TB04_HtoL 
generate byte TB04_HtoL_X_Pre_Before`max_pre_period' = TB04_HtoL * (TB04_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB04_HtoL_X_Pre`time' = TB04_HtoL * (TB04_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte TB04_HtoL_X_Post`time' = TB04_HtoL * (TB04_Rel_Time == `time')
}
generate byte TB04_HtoL_X_Post_After`Hto_max_post_period' = TB04_HtoL * (TB04_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 24 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop TB04_LtoL_X_Pre TB04_LtoL_X_Post TB04_LtoH_X_Pre TB04_LtoH_X_Post TB04_HtoH_X_Pre TB04_HtoH_X_Post TB04_HtoL_X_Pre TB04_HtoL_X_Post

foreach event in TB04_LtoL TB04_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in TB04_LtoL TB04_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in TB04_HtoH TB04_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in TB04_HtoH TB04_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${TB04_LtoL_X_Pre} ${TB04_LtoL_X_Post} ${TB04_LtoH_X_Pre} ${TB04_LtoH_X_Post} ${TB04_HtoH_X_Pre} ${TB04_HtoH_X_Post} ${TB04_HtoL_X_Pre} ${TB04_HtoL_X_Post}

display "${four_events_dummies}"

    // TB04_LtoL_X_Pre_Before24 TB04_LtoL_X_Pre24 ... TB04_LtoL_X_Pre4 TB04_LtoL_X_Post0 TB04_LtoL_X_Post1 ... TB04_LtoL_X_Post84 TB04_LtoL_X_Pre_After84 
    // TB04_LtoH_X_Pre_Before24 TB04_LtoH_X_Pre24 ... TB04_LtoH_X_Pre4 TB04_LtoH_X_Post0 TB04_LtoH_X_Post1 ... TB04_LtoH_X_Post84 TB04_LtoH_X_Pre_After84 
    // TB04_HtoH_X_Pre_Before24 TB04_HtoH_X_Pre24 ... TB04_HtoH_X_Pre4 TB04_HtoH_X_Post0 TB04_HtoH_X_Post1 ... TB04_HtoH_X_Post60 TB04_HtoH_X_Pre_After60 
    // TB04_HtoL_X_Pre_Before24 TB04_HtoL_X_Pre24 ... TB04_HtoL_X_Pre4 TB04_HtoL_X_Post0 TB04_HtoL_X_Post1 ... TB04_HtoL_X_Post60 TB04_HtoL_X_Pre_After60 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. run event studies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in TransferSJVC ChangeSalaryGradeC {

    *!! s-1-3-1. Main Regression
    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *!! s-1-3-2. LtoH versus LtoL
    LH_minus_LL, event_prefix(TB04) pre_window_len(24) post_window_len(84) outcome(`var')
    
    *!! s-1-3-3. HtoL versus HtoH
    HL_minus_HH, event_prefix(TB04) pre_window_len(24) post_window_len(60) outcome(`var')
    
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. save event studies results in a dta file 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep coeff_* quarter_* lb_* ub_* 
keep if inrange(_n, 1, 41)
save "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_Pre24Post84.dta", replace 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run event studies with measure TB05
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample_Simplified_WithTenureBasedMeasures.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. construct variables and macros used in reghdfe command
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. TB05_LtoL_X_Pre1 TB05_LtoH_X_Post0 TB05_HtoH_X_Post12
For binned dummies, e.g. TB05_LtoL_X_Pre_Before36 TB05_LtoH_X_Post_After84
*/

generate  TB05_Rel_Time = Rel_Time
summarize TB05_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 24 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! TB05_LtoL
generate byte TB05_LtoL_X_Pre_Before`max_pre_period' = TB05_LtoL * (TB05_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB05_LtoL_X_Pre`time' = TB05_LtoL * (TB05_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte TB05_LtoL_X_Post`time' = TB05_LtoL * (TB05_Rel_Time == `time')
}
generate byte TB05_LtoL_X_Post_After`Lto_max_post_period' = TB05_LtoL * (TB05_Rel_Time > `Lto_max_post_period')

*!! TB05_LtoH
generate byte TB05_LtoH_X_Pre_Before`max_pre_period' = TB05_LtoH * (TB05_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB05_LtoH_X_Pre`time' = TB05_LtoH * (TB05_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte TB05_LtoH_X_Post`time' = TB05_LtoH * (TB05_Rel_Time == `time')
}
generate byte TB05_LtoH_X_Post_After`Lto_max_post_period' = TB05_LtoH * (TB05_Rel_Time > `Lto_max_post_period')

*!! TB05_HtoH 
generate byte TB05_HtoH_X_Pre_Before`max_pre_period' = TB05_HtoH * (TB05_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB05_HtoH_X_Pre`time' = TB05_HtoH * (TB05_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte TB05_HtoH_X_Post`time' = TB05_HtoH * (TB05_Rel_Time == `time')
}
generate byte TB05_HtoH_X_Post_After`Hto_max_post_period' = TB05_HtoH * (TB05_Rel_Time > `Hto_max_post_period')

*!! TB05_HtoL 
generate byte TB05_HtoL_X_Pre_Before`max_pre_period' = TB05_HtoL * (TB05_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte TB05_HtoL_X_Pre`time' = TB05_HtoL * (TB05_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte TB05_HtoL_X_Post`time' = TB05_HtoL * (TB05_Rel_Time == `time')
}
generate byte TB05_HtoL_X_Post_After`Hto_max_post_period' = TB05_HtoL * (TB05_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 24 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop TB05_LtoL_X_Pre TB05_LtoL_X_Post TB05_LtoH_X_Pre TB05_LtoH_X_Post TB05_HtoH_X_Pre TB05_HtoH_X_Post TB05_HtoL_X_Pre TB05_HtoL_X_Post

foreach event in TB05_LtoL TB05_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in TB05_LtoL TB05_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in TB05_HtoH TB05_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in TB05_HtoH TB05_HtoL {
    forvalues time = 0/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${TB05_LtoL_X_Pre} ${TB05_LtoL_X_Post} ${TB05_LtoH_X_Pre} ${TB05_LtoH_X_Post} ${TB05_HtoH_X_Pre} ${TB05_HtoH_X_Post} ${TB05_HtoL_X_Pre} ${TB05_HtoL_X_Post}

display "${four_events_dummies}"

    // TB05_LtoL_X_Pre_Before24 TB05_LtoL_X_Pre24 ... TB05_LtoL_X_Pre4 TB05_LtoL_X_Post0 TB05_LtoL_X_Post1 ... TB05_LtoL_X_Post84 TB05_LtoL_X_Pre_After84 
    // TB05_LtoH_X_Pre_Before24 TB05_LtoH_X_Pre24 ... TB05_LtoH_X_Pre4 TB05_LtoH_X_Post0 TB05_LtoH_X_Post1 ... TB05_LtoH_X_Post84 TB05_LtoH_X_Pre_After84 
    // TB05_HtoH_X_Pre_Before24 TB05_HtoH_X_Pre24 ... TB05_HtoH_X_Pre4 TB05_HtoH_X_Post0 TB05_HtoH_X_Post1 ... TB05_HtoH_X_Post60 TB05_HtoH_X_Pre_After60 
    // TB05_HtoL_X_Pre_Before24 TB05_HtoL_X_Pre24 ... TB05_HtoL_X_Pre4 TB05_HtoL_X_Post0 TB05_HtoL_X_Post1 ... TB05_HtoL_X_Post60 TB05_HtoL_X_Pre_After60 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. run event studies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in TransferSJVC ChangeSalaryGradeC {

    *!! s-2-3-1. Main Regression
    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *!! s-2-3-2. LtoH versus LtoL
    LH_minus_LL, event_prefix(TB05) pre_window_len(24) post_window_len(84) outcome(`var')
    
    *!! s-2-3-3. HtoL versus HtoH
    HL_minus_HH, event_prefix(TB05) pre_window_len(24) post_window_len(60) outcome(`var')
    
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. save event studies results in a dta file 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep coeff_* quarter_* lb_* ub_* 
keep if inrange(_n, 1, 41)
save "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_Pre24Post84.dta", replace 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run event studies with measure CA30
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample_Simplified_WithTenureBasedMeasures.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. construct variables and macros used in reghdfe command
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Pre1 CA30_LtoH_X_Post0 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoL_X_Pre_Before36 CA30_LtoH_X_Post_After84
*/

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
*-? s-3-2. global macros used in regressions 
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
*-? s-3-3. run event studies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in TransferSJVC ChangeSalaryGradeC {

    *!! s-3-3-1. Main Regression
    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *!! s-3-3-2. LtoH versus LtoL
    LH_minus_LL, event_prefix(CA30) pre_window_len(24) post_window_len(84) outcome(`var')
    
    *!! s-3-3-3. HtoL versus HtoH
    HL_minus_HH, event_prefix(CA30) pre_window_len(24) post_window_len(60) outcome(`var')
    
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. save event studies results in a dta file 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep coeff_* quarter_* lb_* ub_* 
keep if inrange(_n, 1, 41)
save "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84.dta", replace 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step y. merge coefficients under different measures into one dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-y-1. measure TB04
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_Pre24Post84.dta", clear 

keep ///
    quarter_TransferSJVC_gains coeff_TransferSJVC_gains lb_TransferSJVC_gains ub_TransferSJVC_gains ///
    quarter_TransferSJVC_loss coeff_TransferSJVC_loss lb_TransferSJVC_loss ub_TransferSJVC_loss ///
    quarter_ChangeSalaryGradeC_gains coeff_ChangeSalaryGradeC_gains lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains ///
    quarter_ChangeSalaryGradeC_loss coeff_ChangeSalaryGradeC_loss lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss

rename (quarter_TransferSJVC_gains coeff_TransferSJVC_gains lb_TransferSJVC_gains ub_TransferSJVC_gains) (TB04_SJVC_quarter_gains TB04_SJVC_coef_gains TB04_SJVC_lb_gains TB04_SJVC_ub_gains)
rename (quarter_TransferSJVC_loss coeff_TransferSJVC_loss lb_TransferSJVC_loss ub_TransferSJVC_loss) (TB04_SJVC_quarter_loss TB04_SJVC_coef_loss TB04_SJVC_lb_loss TB04_SJVC_ub_loss)
rename (quarter_ChangeSalaryGradeC_gains coeff_ChangeSalaryGradeC_gains lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains) (TB04_SGC_quarter_gains TB04_SGC_coef_gains TB04_SGC_lb_gains TB04_SGC_ub_gains)
rename (quarter_ChangeSalaryGradeC_loss coeff_ChangeSalaryGradeC_loss lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss) (TB04_SGC_quarter_loss TB04_SGC_coef_loss TB04_SGC_lb_loss TB04_SGC_ub_loss)

generate rowid = _n

save "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_Pre24Post84_ForMerge.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-y-2. measure TB05
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_Pre24Post84.dta", clear

keep ///
    quarter_TransferSJVC_gains coeff_TransferSJVC_gains lb_TransferSJVC_gains ub_TransferSJVC_gains ///
    quarter_TransferSJVC_loss coeff_TransferSJVC_loss lb_TransferSJVC_loss ub_TransferSJVC_loss ///
    quarter_ChangeSalaryGradeC_gains coeff_ChangeSalaryGradeC_gains lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains ///
    quarter_ChangeSalaryGradeC_loss coeff_ChangeSalaryGradeC_loss lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss

rename (quarter_TransferSJVC_gains coeff_TransferSJVC_gains lb_TransferSJVC_gains ub_TransferSJVC_gains) (TB05_SJVC_quarter_gains TB05_SJVC_coef_gains TB05_SJVC_lb_gains TB05_SJVC_ub_gains)
rename (quarter_TransferSJVC_loss coeff_TransferSJVC_loss lb_TransferSJVC_loss ub_TransferSJVC_loss) (TB05_SJVC_quarter_loss TB05_SJVC_coef_loss TB05_SJVC_lb_loss TB05_SJVC_ub_loss)
rename (quarter_ChangeSalaryGradeC_gains coeff_ChangeSalaryGradeC_gains lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains) (TB05_SGC_quarter_gains TB05_SGC_coef_gains TB05_SGC_lb_gains TB05_SGC_ub_gains)
rename (quarter_ChangeSalaryGradeC_loss coeff_ChangeSalaryGradeC_loss lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss) (TB05_SGC_quarter_loss TB05_SGC_coef_loss TB05_SGC_lb_loss TB05_SGC_ub_loss)

generate rowid = _n

save "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_Pre24Post84_ForMerge.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-y-3. measure CA30
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84.dta", clear

keep ///
    quarter_TransferSJVC_gains coeff_TransferSJVC_gains lb_TransferSJVC_gains ub_TransferSJVC_gains ///
    quarter_TransferSJVC_loss coeff_TransferSJVC_loss lb_TransferSJVC_loss ub_TransferSJVC_loss ///
    quarter_ChangeSalaryGradeC_gains coeff_ChangeSalaryGradeC_gains lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains ///
    quarter_ChangeSalaryGradeC_loss coeff_ChangeSalaryGradeC_loss lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss

rename (quarter_TransferSJVC_gains coeff_TransferSJVC_gains lb_TransferSJVC_gains ub_TransferSJVC_gains) (CA30_SJVC_quarter_gains CA30_SJVC_coef_gains CA30_SJVC_lb_gains CA30_SJVC_ub_gains)
rename (quarter_TransferSJVC_loss coeff_TransferSJVC_loss lb_TransferSJVC_loss ub_TransferSJVC_loss) (CA30_SJVC_quarter_loss CA30_SJVC_coef_loss CA30_SJVC_lb_loss CA30_SJVC_ub_loss)
rename (quarter_ChangeSalaryGradeC_gains coeff_ChangeSalaryGradeC_gains lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains) (CA30_SGC_quarter_gains CA30_SGC_coef_gains CA30_SGC_lb_gains CA30_SGC_ub_gains)
rename (quarter_ChangeSalaryGradeC_loss coeff_ChangeSalaryGradeC_loss lb_ChangeSalaryGradeC_loss ub_ChangeSalaryGradeC_loss) (CA30_SGC_quarter_loss CA30_SGC_coef_loss CA30_SGC_lb_loss CA30_SGC_ub_loss)

generate rowid = _n

save "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84_ForMerge.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step z. produce the figure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84_ForMerge.dta", clear 
merge 1:1 rowid using "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_Pre24Post84_ForMerge.dta", nogenerate 
merge 1:1 rowid using "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_Pre24Post84_ForMerge.dta", nogenerate 

/* use "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84_ForMerge.dta", clear 
merge 1:1 rowid using "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_MeasureTB04_ForMerge.dta", nogenerate 
merge 1:1 rowid using "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_MeasureTB05_ForMerge.dta", nogenerate  */

replace TB04_SJVC_quarter_gains = TB04_SJVC_quarter_gains - 0.2
replace TB05_SJVC_quarter_gains = TB05_SJVC_quarter_gains + 0.2
replace TB04_SGC_quarter_gains = TB04_SGC_quarter_gains - 0.2
replace TB05_SGC_quarter_gains = TB05_SGC_quarter_gains + 0.2

replace TB04_SJVC_quarter_loss = TB04_SJVC_quarter_loss - 0.2
replace TB05_SJVC_quarter_loss = TB05_SJVC_quarter_loss + 0.2
replace TB04_SGC_quarter_loss = TB04_SGC_quarter_loss - 0.2
replace TB05_SGC_quarter_loss = TB05_SGC_quarter_loss + 0.2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-z-1. the effects of gaining a high-flyer
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

twoway ///
    (scatter CA30_SJVC_coef_gains CA30_SJVC_quarter_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap CA30_SJVC_lb_gains CA30_SJVC_ub_gains CA30_SJVC_quarter_gains, lcolor(ebblue)) ///
    (scatter TB04_SJVC_coef_gains TB04_SJVC_quarter_gains, lcolor(magenta) mcolor(magenta)) ///
    (rcap TB04_SJVC_lb_gains TB04_SJVC_ub_gains TB04_SJVC_quarter_gains, lcolor(magenta)) ///
    (scatter TB05_SJVC_coef_gains TB05_SJVC_quarter_gains, lcolor(dkgreen) mcolor(dkgreen)) ///
    (rcap TB05_SJVC_lb_gains TB05_SJVC_ub_gains TB05_SJVC_quarter_gains, lcolor(dkgreen)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle(Quarters since manager change, size(medlarge)) title("Lateral move", span pos(12)) ///
    legend(label(2 "Original age-based measure (age 30 as the threshold)") label(4 "Tenure-based measure (4 years as the threshold)") label(6 "Tenure-based measure (5 years as the threshold)") order(2 4 6) position(6) ring(0) size(small))
graph save "${Results}/006EventStudiesWithTenureBasedMeasures/CA30TB04TB05_Outcome1_TransferSJVC_Coef1_Gains.gph", replace

twoway ///
    (scatter CA30_SGC_coef_gains CA30_SGC_quarter_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap CA30_SGC_lb_gains CA30_SGC_ub_gains CA30_SGC_quarter_gains, lcolor(ebblue)) ///
    (scatter TB04_SGC_coef_gains TB04_SGC_quarter_gains, lcolor(magenta) mcolor(magenta)) ///
    (rcap TB04_SGC_lb_gains TB04_SGC_ub_gains TB04_SGC_quarter_gains, lcolor(magenta)) ///
    (scatter TB05_SGC_coef_gains TB05_SGC_quarter_gains, lcolor(dkgreen) mcolor(dkgreen)) ///
    (rcap TB05_SGC_lb_gains TB05_SGC_ub_gains TB05_SGC_quarter_gains, lcolor(dkgreen)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle(Quarters since manager change, size(medlarge)) title("Salary grade increase", span pos(12)) ///
    legend(label(2 "Original age-based measure (age 30 as the threshold)") label(4 "Tenure-based measure (4 years as the threshold)") label(6 "Tenure-based measure (5 years as the threshold)") order(2 4 6) position(6) ring(0) size(small))
graph save "${Results}/006EventStudiesWithTenureBasedMeasures/CA30TB04TB05_Outcome2_ChangeSalaryGradeC_Coef1_Gains.gph", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-z-2. the effects of losing a high-flyer
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

twoway ///
    (scatter CA30_SJVC_coef_loss CA30_SJVC_quarter_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap CA30_SJVC_lb_loss CA30_SJVC_ub_loss CA30_SJVC_quarter_loss, lcolor(ebblue)) ///
    (scatter TB04_SJVC_coef_loss TB04_SJVC_quarter_loss, lcolor(magenta) mcolor(magenta)) ///
    (rcap TB04_SJVC_lb_loss TB04_SJVC_ub_loss TB04_SJVC_quarter_loss, lcolor(magenta)) ///
    (scatter TB05_SJVC_coef_loss TB05_SJVC_quarter_loss, lcolor(dkgreen) mcolor(dkgreen)) ///
    (rcap TB05_SJVC_lb_loss TB05_SJVC_ub_loss TB05_SJVC_quarter_loss, lcolor(dkgreen)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle(Quarters since manager change, size(medlarge)) title("Lateral move", span pos(12)) ///
    legend(label(2 "Original age-based measure (age 30 as the threshold)") label(4 "Tenure-based measure (4 years as the threshold)") label(6 "Tenure-based measure (5 years as the threshold)") order(2 4 6) position(6) ring(0) size(small))
graph save "${Results}/006EventStudiesWithTenureBasedMeasures/CA30TB04TB05_Outcome1_TransferSJVC_Coef2_Loss.gph", replace

twoway ///
    (scatter CA30_SGC_coef_loss CA30_SGC_quarter_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap CA30_SGC_lb_loss CA30_SGC_ub_loss CA30_SGC_quarter_loss, lcolor(ebblue)) ///
    (scatter TB04_SGC_coef_loss TB04_SGC_quarter_loss, lcolor(magenta) mcolor(magenta)) ///
    (rcap TB04_SGC_lb_loss TB04_SGC_ub_loss TB04_SGC_quarter_loss, lcolor(magenta)) ///
    (scatter TB05_SGC_coef_loss TB05_SGC_quarter_loss, lcolor(dkgreen) mcolor(dkgreen)) ///
    (rcap TB05_SGC_lb_loss TB05_SGC_ub_loss TB05_SGC_quarter_loss, lcolor(dkgreen)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle(Quarters since manager change, size(medlarge)) title("Salary grade increase", span pos(12)) ///
    legend(label(2 "Original age-based measure (age 30 as the threshold)") label(4 "Tenure-based measure (4 years as the threshold)") label(6 "Tenure-based measure (5 years as the threshold)") order(2 4 6) position(6) ring(0) size(small))
graph save "${Results}/006EventStudiesWithTenureBasedMeasures/CA30TB04TB05_Outcome2_ChangeSalaryGradeC_Coef2_Loss.gph", replace

log close 