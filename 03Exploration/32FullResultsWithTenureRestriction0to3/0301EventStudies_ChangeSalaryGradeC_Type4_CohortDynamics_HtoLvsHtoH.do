/* 
Description of the do file:
    (1) This do file computes a variant version of cohort-average treatment effects based on Liyang Sun and Sarah Abraham, "Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects," Journal of Econometrics 225, no. 2 (2021): 175–99, https://doi.org/10.1016/j.jeconom.2020.09.006.
    (2) The high-flyer measure used here is CA30.

Special notes:
    (1) Only those employees whose tenure at the event time is in the range of [0,3] are included.
    
Notes on the event study regressions.
    (1) To reduce the computational burden, only HtoH and HtoL event workers are included in the regressions. Never-treated workers are always not included.
    (2) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (3) For HtoH and HtoL groups, the relative time period is [-24, +60].

Notes on the implementation of cohort dynamics:
    (1) For each "event * relative month" indicator dummy appeared in the normal TWFE regression, I interact it with 10 other dummies (from 2011 to 2020) indicating the year in which the manager change event happens.
    (2) The coefficients of these dummies are estimated using reghdfe, controlling for time and individual fixed effects.
    (3) For each event group, and for each relative month, I calculate the share of regression sample that belongs to each cohort (so there are 10 numbers that sum to one indicating the weights associated with each cohort).
    (4) The coefficients on "event * relative month indicator * cohort indicator" are first aggregated to coefficients on "event * relative month indicator" using the weights calculated in step 3.
    (5) Furthermore, coefficients are aggregated to "event * relative quarter" level based on the same quarter aggregation procedure in the TWFE regression.
    (6) The above procedures are implemented by the Stata programs defined in 0207 do file.

Some key results (quarterly aggregated coefficients with their p-values, and other key summary statistics) are stored in the output file. 

Input: 
    "${TempData}/FinalAnalysisSample.dta" <== created in 0103_03 do file

Output:
    "${EventStudyResults}/20250522log_Outcome1_ChangeSalaryGradeC_Type4_CohortDynamics_HtoLvsHtoH.txt"
    "${EventStudyResults}/Outcome1_ChangeSalaryGradeC_Type4_CohortDynamics_HtoLvsHtoH.dta"

RA: WWZ 
Time: 2025-05-22
*/

global EventStudyResults "${Results}/022FullResultsWithTenureRestriction0to3"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare the interaction terms
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close
log using "${EventStudyResults}/20250522log_Outcome1_ChangeSalaryGradeC_Type4_CohortDynamics_HtoLvsHtoH.txt", replace text

use "${TempData}/FinalAnalysisSample.dta", clear

keep if CA30_HtoH==1 | CA30_HtoL==1
    //&? keep only HtoH and HtoL event workers

keep if inrange(TenureAtEvent, 0, 3)
    //impt: keep only those employees whose tenure at the event time is in the range of [0,3]

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. the ordinary event * relative periods indicators
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Pre1 CA30_HtoH_X_Post0 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoL_X_Pre_Before24 CA30_HtoH_X_Post_After84
*/

generate  CA30_Rel_Time = Rel_Time
summarize CA30_Rel_Time, detail

*!! time window of interest
local max_pre_period  = 24 
local Hto_max_post_period = 60

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
*-? s-1-2. global macros for the ordinary event * relative periods indicators
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 24 
local Hto_max_post_period = 60

macro drop CA30_HtoH_X_Pre CA30_HtoH_X_Post CA30_HtoL_X_Pre CA30_HtoL_X_Post

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

global two_events_dummies ${CA30_HtoH_X_Pre} ${CA30_HtoH_X_Post} ${CA30_HtoL_X_Pre} ${CA30_HtoL_X_Post}

display "${two_events_dummies}"

    // CA30_HtoH_X_Pre_Before24 CA30_HtoH_X_Pre24 ... CA30_HtoH_X_Pre4 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post60 CA30_HtoH_X_Pre_After60 
    // CA30_HtoL_X_Pre_Before24 CA30_HtoL_X_Pre24 ... CA30_HtoL_X_Pre4 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post60 CA30_HtoL_X_Pre_After60 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. interaction with cohort indicators (which year the event takes place)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate YEi = year(dofm(Event_Time))

forval yy = 2011(1)2020 {
    generate byte cohort`yy' = (YEi == `yy') 
    foreach l in $two_events_dummies {
        generate byte `l'_`yy'  = cohort`yy'* `l' 
        local eventinteract "`eventinteract' `l'_`yy'"
    }
}
global eventinteract `eventinteract'
display "${eventinteract}"

    // CA30_HtoH_X_Pre_Before24_2011 CA30_HtoH_X_Pre24_2011 ... CA30_HtoH_X_Pre4_2011 CA30_HtoH_X_Post0_2011 CA30_HtoH_X_Post1_2011 ... CA30_HtoH_X_Post84_2011 CA30_HtoH_X_Pre_After84_2011
    // ...
    // CA30_HtoH_X_Pre_Before24_2020 CA30_HtoH_X_Pre24_2020 ... CA30_HtoH_X_Pre4_2020 CA30_HtoH_X_Post0_2020 CA30_HtoH_X_Post1_2020 ... CA30_HtoH_X_Post84_2020 CA30_HtoH_X_Pre_After84_2020
    // CA30_HtoL_X_Pre_Before24_2011 CA30_HtoL_X_Pre24_2011 ... CA30_HtoL_X_Pre4_2011 CA30_HtoL_X_Post0_2011 CA30_HtoL_X_Post1_2011 ... CA30_HtoL_X_Post60_2011 CA30_HtoL_X_Pre_After60_2011 
    // ...
    // CA30_HtoL_X_Pre_Before24_2020 CA30_HtoL_X_Pre24_2020 ... CA30_HtoL_X_Pre4_2020 CA30_HtoL_X_Post0_2020 CA30_HtoL_X_Post1_2020 ... CA30_HtoL_X_Post60_2020 CA30_HtoL_X_Pre_After60_2020

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in ChangeSalaryGradeC {

    if "`var'" == "ChangeSalaryGradeC" global title "Salary grade increase"
    if "`var'" == "ChangeSalaryGradeC" global number "1"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${eventinteract} if (CA30_HtoL==1 | CA30_HtoH==1), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! quarterly estimates
    HL_minus_HH_CohortDynamics, event_prefix(CA30) pre_window_len(24) post_window_len(60) outcome(`var')
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
        xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        ylabel(, grid gstyle(dot) labsize(medsmall)) ///
        xtitle(Quarters since manager change, size(medlarge)) title("${title}", span pos(12)) ///
        legend(off)
    graph save "${EventStudyResults}/CA30_Outcome${number}_`var'_Coef2_Loss_Type4_CohortDynamics.gph", replace   
    
}

keep coeff_* quarter_* lb_* ub_* 

keep if inrange(_n, 1, 41)

save "${EventStudyResults}/Outcome1_ChangeSalaryGradeC_Type4_CohortDynamics_HtoLvsHtoH.dta", replace 

log close