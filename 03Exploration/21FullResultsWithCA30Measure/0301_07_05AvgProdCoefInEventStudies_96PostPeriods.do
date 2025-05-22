/* 
This do file reports the average coefficients for 0-2, 2-4, 4-6, and 6-8 years after the event on the sales sample.
The high-flyer measure used here is CA30.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [-6, +86], while for HtoH and HtoL groups, the relative time period is [-6, +60].

Notes on the outcomes:
    (1) In the full sample with non-missing ProductivityStd values, the outcome variables are ProductivityStd.

RA: WWZ 
Time: 2025-05-12
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain a relevant dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. new productivity variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! productivity outcomes 
use "${TempData}/FinalAnalysisSample.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

generate Prod = log(Productivity + 1)
label variable Prod "Sales bonus (logs)"

keep Year - IDMngr_Post ISOCode LogPayBonus Productivity ProductivityStd Prod TransferSJVC ChangeSalaryGradeC LogPayBonus LogPay LogBonus 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. sample restriction 1: non-missing productivity outcomes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if ((ProductivityStd!=.))
    //impt: In this exercise, I keep only those employees who have non-missing productivity outcomes.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. sample restriction 2: "balanced" panel sample  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Min_RelTime = min(Rel_Time)
bysort IDlse: egen Max_RelTime = max(Rel_Time)

summarize Min_RelTime, detail
summarize Max_RelTime, detail

keep if Min_RelTime<0 & Max_RelTime>0

summarize Rel_Time, detail 
/* 
                 Relative time to the event
-------------------------------------------------------------
      Percentiles      Smallest
 1%          -22            -36
 5%          -11            -35
10%           -7            -35       Obs               7,496
25%            0            -35       Sum of wgt.       7,496

50%           13                      Mean           22.64234
                        Largest       Std. dev.      27.93257
75%           47             88
90%           66             88       Variance       780.2287
95%           73             88       Skewness       .5418349
99%           82             89       Kurtosis       2.073686
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct variables and macros used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Pre1 CA30_LtoH_X_Post0 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoL_X_Pre_Before6 CA30_LtoH_X_Post_After84
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. "event * relative period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
generate  CA30_Rel_Time = Rel_Time

*!! time window of interest
local max_pre_period  = 6 
local Lto_max_post_period = 60
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

local max_pre_period  = 6 
local Lto_max_post_period = 60
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

    // CA30_LtoL_X_Pre_Before6 CA30_LtoL_X_Pre6 CA30_LtoL_X_Pre5 ... CA30_LtoL_X_Pre4 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post60 CA30_LtoL_X_Pre_After60 
    // CA30_LtoH_X_Pre_Before6 CA30_LtoH_X_Pre6 CA30_LtoH_X_Pre5 ... CA30_LtoH_X_Pre4 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post60 CA30_LtoH_X_Pre_After60 
    // CA30_HtoH_X_Pre_Before6 CA30_HtoH_X_Pre6 CA30_HtoH_X_Pre5 ... CA30_HtoH_X_Pre4 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post60 CA30_HtoH_X_Pre_After60 
    // CA30_HtoL_X_Pre_Before6 CA30_HtoL_X_Pre6 CA30_HtoL_X_Pre5 ... CA30_HtoL_X_Pre4 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post60 CA30_HtoL_X_Pre_After60 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. macros storing equations to be evaluated
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

#delimit ;
global coef_0yr_to_1yr 
    ((CA30_LtoH_X_Post0 - CA30_LtoL_X_Post0)
    + (CA30_LtoH_X_Post1 - CA30_LtoL_X_Post1)
    + (CA30_LtoH_X_Post2 - CA30_LtoL_X_Post2)
    + (CA30_LtoH_X_Post3 - CA30_LtoL_X_Post3)
    + (CA30_LtoH_X_Post4 - CA30_LtoL_X_Post4)
    + (CA30_LtoH_X_Post5 - CA30_LtoL_X_Post5)
    + (CA30_LtoH_X_Post6 - CA30_LtoL_X_Post6)
    + (CA30_LtoH_X_Post7 - CA30_LtoL_X_Post7)
    + (CA30_LtoH_X_Post8 - CA30_LtoL_X_Post8)
    + (CA30_LtoH_X_Post9 - CA30_LtoL_X_Post9)
    + (CA30_LtoH_X_Post10 - CA30_LtoL_X_Post10)
    + (CA30_LtoH_X_Post11 - CA30_LtoL_X_Post11))/12;

global coef_1yr_to_2yr 
    ((CA30_LtoH_X_Post12 - CA30_LtoL_X_Post12)
    + (CA30_LtoH_X_Post13 - CA30_LtoL_X_Post13)
    + (CA30_LtoH_X_Post14 - CA30_LtoL_X_Post14)
    + (CA30_LtoH_X_Post15 - CA30_LtoL_X_Post15)
    + (CA30_LtoH_X_Post16 - CA30_LtoL_X_Post16)
    + (CA30_LtoH_X_Post17 - CA30_LtoL_X_Post17)
    + (CA30_LtoH_X_Post18 - CA30_LtoL_X_Post18)
    + (CA30_LtoH_X_Post19 - CA30_LtoL_X_Post19)
    + (CA30_LtoH_X_Post20 - CA30_LtoL_X_Post20)
    + (CA30_LtoH_X_Post21 - CA30_LtoL_X_Post21)
    + (CA30_LtoH_X_Post22 - CA30_LtoL_X_Post22)
    + (CA30_LtoH_X_Post23 - CA30_LtoL_X_Post23))/12;

global coef_2yr_to_3yr 
    ((CA30_LtoH_X_Post24 - CA30_LtoL_X_Post24)
    + (CA30_LtoH_X_Post25 - CA30_LtoL_X_Post25)
    + (CA30_LtoH_X_Post26 - CA30_LtoL_X_Post26)
    + (CA30_LtoH_X_Post27 - CA30_LtoL_X_Post27)
    + (CA30_LtoH_X_Post28 - CA30_LtoL_X_Post28)
    + (CA30_LtoH_X_Post29 - CA30_LtoL_X_Post29)
    + (CA30_LtoH_X_Post30 - CA30_LtoL_X_Post30)
    + (CA30_LtoH_X_Post31 - CA30_LtoL_X_Post31)
    + (CA30_LtoH_X_Post32 - CA30_LtoL_X_Post32)
    + (CA30_LtoH_X_Post33 - CA30_LtoL_X_Post33)
    + (CA30_LtoH_X_Post34 - CA30_LtoL_X_Post34)
    + (CA30_LtoH_X_Post35 - CA30_LtoL_X_Post35))/12;

global coef_3yr_to_4yr
    ((CA30_LtoH_X_Post36 - CA30_LtoL_X_Post36)
    + (CA30_LtoH_X_Post37 - CA30_LtoL_X_Post37)
    + (CA30_LtoH_X_Post38 - CA30_LtoL_X_Post38)
    + (CA30_LtoH_X_Post39 - CA30_LtoL_X_Post39)
    + (CA30_LtoH_X_Post40 - CA30_LtoL_X_Post40)
    + (CA30_LtoH_X_Post41 - CA30_LtoL_X_Post41)
    + (CA30_LtoH_X_Post42 - CA30_LtoL_X_Post42)
    + (CA30_LtoH_X_Post43 - CA30_LtoL_X_Post43)
    + (CA30_LtoH_X_Post44 - CA30_LtoL_X_Post44)
    + (CA30_LtoH_X_Post45 - CA30_LtoL_X_Post45)
    + (CA30_LtoH_X_Post46 - CA30_LtoL_X_Post46)
    + (CA30_LtoH_X_Post47 - CA30_LtoL_X_Post47))/12;

global coef_4yr_to_5yr 
    ((CA30_LtoH_X_Post48 - CA30_LtoL_X_Post48)
    + (CA30_LtoH_X_Post49 - CA30_LtoL_X_Post49)
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
    + (CA30_LtoH_X_Post60 - CA30_LtoL_X_Post60))/13;

#delimit cr

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. run regressions and store results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    local obs = e(N)
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    local cmean = r(mean)
    xlincom (coef_0yr_to_1yr = ${coef_0yr_to_1yr}) (coef_1yr_to_2yr = ${coef_1yr_to_2yr}) (coef_2yr_to_3yr = ${coef_2yr_to_3yr}) (coef_3yr_to_4yr = ${coef_3yr_to_4yr}) (coef_4yr_to_5yr = ${coef_4yr_to_5yr}), post 
        eststo Full_ProductivityStd 
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'
        estadd scalar obs = `obs'

reghdfe LogPayBonus ${four_events_dummies} if ProductivityStd!=., absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    local obs = e(N)
    summarize LogPayBonus if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    local cmean = r(mean)
    xlincom (coef_0yr_to_1yr = ${coef_0yr_to_1yr}) (coef_1yr_to_2yr = ${coef_1yr_to_2yr}) (coef_2yr_to_3yr = ${coef_2yr_to_3yr}) (coef_3yr_to_4yr = ${coef_3yr_to_4yr}) (coef_4yr_to_5yr = ${coef_4yr_to_5yr}), post 
        eststo Full_LogPayBonus 
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'
        estadd scalar obs = `obs'

reghdfe TransferSJVC ${four_events_dummies} if ProductivityStd!=., absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    local obs = e(N)
    summarize TransferSJVC if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    local cmean = r(mean)
    xlincom (coef_0yr_to_1yr = ${coef_0yr_to_1yr}) (coef_1yr_to_2yr = ${coef_1yr_to_2yr}) (coef_2yr_to_3yr = ${coef_2yr_to_3yr}) (coef_3yr_to_4yr = ${coef_3yr_to_4yr}) (coef_4yr_to_5yr = ${coef_4yr_to_5yr}), post 
        eststo Full_TransferSJVC 
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'
        estadd scalar obs = `obs'

reghdfe ChangeSalaryGradeC ${four_events_dummies} if ProductivityStd!=., absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    local obs = e(N)
    summarize ChangeSalaryGradeC if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    local cmean = r(mean)
    xlincom (coef_0yr_to_1yr = ${coef_0yr_to_1yr}) (coef_1yr_to_2yr = ${coef_1yr_to_2yr}) (coef_2yr_to_3yr = ${coef_2yr_to_3yr}) (coef_3yr_to_4yr = ${coef_3yr_to_4yr}) (coef_4yr_to_5yr = ${coef_4yr_to_5yr}), post 
        eststo Full_ChangeSalaryGradeC 
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'
        estadd scalar obs = `obs'

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. produce the regression table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} \\"
global latex_titles       "& \multicolumn{1}{c}{\shortstack{Sales bonus \\ (s.d.)}} & \multicolumn{1}{c}{\shortstack{Pay+Bonus \\ (in logs, Euros)}}  & \multicolumn{1}{c}{\shortstack{Number of \\ lateral moves}} & \multicolumn{1}{c}{\shortstack{Number of \\ salary grade increases}} \\"
global latex_file         "${Results}/005EventStudiesWithCA30/CA30_AvgProdCoefInEventStudies_BalancedSample.tex"

esttab Full_ProductivityStd Full_LogPayBonus Full_TransferSJVC Full_ChangeSalaryGradeC using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(coef_0yr_to_1yr coef_1yr_to_2yr coef_2yr_to_3yr coef_3yr_to_4yr coef_4yr_to_5yr) order(coef_0yr_to_1yr coef_1yr_to_2yr coef_2yr_to_3yr coef_3yr_to_4yr coef_4yr_to_5yr) ///
    stats(cmean r_squared obs, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_panel_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")
