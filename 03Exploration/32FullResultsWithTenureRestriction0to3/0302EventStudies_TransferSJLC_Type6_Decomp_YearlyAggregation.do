/* 
This do file decomposes the variable TransferSJLC into three categories.
The high-flyer measure used here is CA30.

Special notes:
    (1) Unlike most other event study plots, where quarterly aggregation is conducted, for this outcome variable, yearly aggregation is conducted.
    (2) Only those employees whose tenure at the event time is in the range of [0,3] are included.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month 0 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60].

Input: 
    "${TempData}/FinalAnalysisSample.dta" <== created in 0103_03 do file

Output:
    "${Results}/005EventStudiesWithCA30/20250522log_Outcome2_TransferSJLC_Type6_Decomp_YearlyAggregation.txt"
    "${EventStudyResults}/Outcome2_TransferSJLC_Type6_Decomp_YearlyAggregation.dta"

RA: WWZ 
Time: 2025-05-22
*/

global EventStudyResults "${Results}/022FullResultsWithTenureRestriction0to3"

capture log close
log using "${EventStudyResults}/20250522log_Outcome2_TransferSJLC_Type6_Decomp_YearlyAggregation.txt", replace text

use "${TempData}/FinalAnalysisSample.dta", clear 

keep if inrange(TenureAtEvent, 0, 3)
    //impt: keep only those employees whose tenure at the event time is in the range of [0,3]

/* keep if inrange(_n, 1, 1000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Pre1 CA30_LtoH_X_Post0 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoL_X_Pre_Before24 CA30_LtoH_X_Post_After84
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. event * period dummies 
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
*?? step 1. run regressions on total and decomposed outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in TransferSJLC SameMLC DiffMLC DiffFuncSJLC {

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

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

}

keep Year_* coef_* lb_* ub_* 
keep if inrange(_n, 1, 7)
save "${EventStudyResults}/Outcome2_TransferSJLC_Type6_Decomp_YearlyAggregation.dta", replace 

log close

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. produce the stacked bar plot
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* 
use "${EventStudyResults}/Outcome2_TransferSJLC_Type6_Decomp_YearlyAggregation.dta", clear 

generate Year = Year_TransferSJLC_gains

foreach var in SameMLC DiffMLC DiffFuncSJLC {
    generate frac_`var'_gains = coef_`var'_gains / coef_TransferSJLC_gains
    generate frac_`var'_gains_int = round(frac_`var'_gains * 100)
    tostring frac_`var'_gains_int, generate(frac_`var'_gains_str)
}

egen test = rowtotal(frac_SameMLC_gains frac_DiffMLC_gains frac_DiffFuncSJLC_gains)
tabulate test, sort
    //&? roughly 1, as expected

foreach var in SameMLC DiffMLC DiffFuncSJLC {
    forvalues i = 1/7 {
        global frac_`var'_`i' = frac_`var'_gains_str[`i']
    }
}

graph bar coef_SameMLC_gains coef_DiffMLC_gains coef_DiffFuncSJLC_gains, ///
    over(Year, gap(5)) stack ///
    scheme(tab2) name(bar_stacked, replace) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions")) ///
    b1title("Years since manager change") ytitle("Coefficients value") title("Decomposition of lateral moves") ///
    ylabel(0(0.01)0.2, grid gstyle(dot)) ///
    text(0.150 1.00 "reporting % of total lateral moves", size(medium) placement(e)) ///
    text(0.006 9.50 "${frac_DiffMLC_1}"     , size(vsmall)  placement(c)) ///
    text(0.015 9.50 "${frac_DiffFuncSJLC_1}", size(vsmall)  placement(c)) ///
    text(0.03  23.0 "${frac_DiffMLC_2}"     , size(medium)  placement(c)) ///
    text(0.05  23.0 "${frac_DiffFuncSJLC_2}", size(medium)  placement(c)) ///
    text(0.05  36.5 "${frac_DiffMLC_3}"     , size(medium)  placement(c)) ///
    text(0.08  36.5 "${frac_DiffFuncSJLC_3}", size(medium)  placement(c)) ///
    text(0.05  50.5 "${frac_DiffMLC_4}"     , size(medium)  placement(c)) ///
    text(0.09  50.5 "${frac_DiffFuncSJLC_4}", size(medium)  placement(c)) ///
    text(0.05  64.0 "${frac_DiffMLC_5}"     , size(medium)  placement(c)) ///
    text(0.10  64.0 "${frac_DiffFuncSJLC_5}", size(medium)  placement(c)) ///
    text(0.05  77.5 "${frac_DiffMLC_6}"     , size(medium)  placement(c)) ///
    text(0.12  77.5 "${frac_DiffFuncSJLC_6}", size(medium)  placement(c)) ///
    text(0.05  91.0 "${frac_DiffMLC_7}"     , size(medium)  placement(c)) ///
    text(0.12  91.0 "${frac_DiffFuncSJLC_7}", size(medium)  placement(c))
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJLC_Decomp_YearlyAggregation.pdf", replace as(pdf)
 */