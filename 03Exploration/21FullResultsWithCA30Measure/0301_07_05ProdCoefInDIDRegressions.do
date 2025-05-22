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

keep if ((ProductivityStd!=.) | (Prod!=.))
    //impt: In this exercise, I keep only those employees who have non-missing productivity outcomes.

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

generate  CA30_Rel_Time = Rel_Time
summarize CA30_Rel_Time if ProductivityStd!=., detail
/* 
                        CA30_Rel_Time
-------------------------------------------------------------
      Percentiles      Smallest
 1%          -14            -37
 5%           -1            -36
10%            8            -36       Obs              46,450
25%           25            -35       Sum of wgt.      46,450

50%           56                      Mean           54.80635
                        Largest       Std. dev.      35.17812
75%           84            129
90%          101            129       Variance         1237.5
95%          109            130       Skewness      -.0763767
99%          118            130       Kurtosis       1.935189
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. "event * relative period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach event in CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL {
    generate byte `event'_X_Pre_Before0 = `event' * (CA30_Rel_Time <= -4)
    generate byte `event'_X_Post1 = `event' * inrange(CA30_Rel_Time, 0, 23)
    generate byte `event'_X_Post2 = `event' * inrange(CA30_Rel_Time, 24, 47)
    generate byte `event'_X_Post3 = `event' * inrange(CA30_Rel_Time, 48, 71)
    generate byte `event'_X_Post4 = `event' * inrange(CA30_Rel_Time, 72, 96)
    generate byte `event'_X_Post_After4 = `event' * (CA30_Rel_Time > 96)
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. macros storing regressors in the reghdfe command 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global four_events_dummies ///
    CA30_LtoL_X_Pre_Before0 CA30_LtoL_X_Post1 CA30_LtoL_X_Post2 CA30_LtoL_X_Post3 CA30_LtoL_X_Post4 CA30_LtoL_X_Post_After4 /// 
    CA30_LtoH_X_Pre_Before0 CA30_LtoH_X_Post1 CA30_LtoH_X_Post2 CA30_LtoH_X_Post3 CA30_LtoH_X_Post4 CA30_LtoH_X_Post_After4 ///
    CA30_HtoH_X_Pre_Before0 CA30_HtoH_X_Post1 CA30_HtoH_X_Post2 CA30_HtoH_X_Post3 CA30_HtoH_X_Post4 CA30_HtoH_X_Post_After4 ///
    CA30_HtoL_X_Pre_Before0 CA30_HtoL_X_Post1 CA30_HtoL_X_Post2 CA30_HtoL_X_Post3 CA30_HtoL_X_Post4 CA30_HtoL_X_Post_After4

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. macros storing equations to be evaluated
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global coef_0y_to_2yr  CA30_LtoH_X_Post1 - CA30_LtoL_X_Post1
global coef_2yr_to_4yr CA30_LtoH_X_Post2 - CA30_LtoL_X_Post2
global coef_4yr_to_6yr CA30_LtoH_X_Post3 - CA30_LtoL_X_Post3
global coef_6yr_to_8yr CA30_LtoH_X_Post4 - CA30_LtoL_X_Post4

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions and store results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    local obs = e(N)
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    local cmean = r(mean)
    xlincom (coef_0y_to_2yr = ${coef_0y_to_2yr}) (coef_2yr_to_4yr = ${coef_2yr_to_4yr}) (coef_4yr_to_6yr = ${coef_4yr_to_6yr}) (coef_6yr_to_8yr = ${coef_6yr_to_8yr}), post 
        eststo Full_ProductivityStd 
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'
        estadd scalar obs = `obs'

reghdfe LogPayBonus ${four_events_dummies} if ProductivityStd!=., absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    local obs = e(N)
    summarize LogPayBonus if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    local cmean = r(mean)
    xlincom (coef_0y_to_2yr = ${coef_0y_to_2yr}) (coef_2yr_to_4yr = ${coef_2yr_to_4yr}) (coef_4yr_to_6yr = ${coef_4yr_to_6yr}) (coef_6yr_to_8yr = ${coef_6yr_to_8yr}), post 
        eststo Full_LogPayBonus 
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'
        estadd scalar obs = `obs'

reghdfe TransferSJVC ${four_events_dummies} if ProductivityStd!=., absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    local obs = e(N)
    summarize TransferSJVC if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    local cmean = r(mean)
    xlincom (coef_0y_to_2yr = ${coef_0y_to_2yr}) (coef_2yr_to_4yr = ${coef_2yr_to_4yr}) (coef_4yr_to_6yr = ${coef_4yr_to_6yr}) (coef_6yr_to_8yr = ${coef_6yr_to_8yr}), post 
        eststo Full_TransferSJVC 
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'
        estadd scalar obs = `obs'

reghdfe ChangeSalaryGradeC ${four_events_dummies} if ProductivityStd!=., absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    local obs = e(N)
    summarize ChangeSalaryGradeC if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    local cmean = r(mean)
    xlincom (coef_0y_to_2yr = ${coef_0y_to_2yr}) (coef_2yr_to_4yr = ${coef_2yr_to_4yr}) (coef_4yr_to_6yr = ${coef_4yr_to_6yr}) (coef_6yr_to_8yr = ${coef_6yr_to_8yr}), post 
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
global latex_file         "${Results}/005EventStudiesWithCA30/CA30_ProdCoefInDIDRegressions_96PostPeriods.tex"

esttab Full_ProductivityStd Full_LogPayBonus Full_TransferSJVC Full_ChangeSalaryGradeC using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) substitute("\_" "_") ///
    keep(coef_0y_to_2yr coef_2yr_to_4yr coef_4yr_to_6yr coef_6yr_to_8yr) order(coef_0y_to_2yr coef_2yr_to_4yr coef_4yr_to_6yr coef_6yr_to_8yr) ///
    varlabels(coef_0y_to_2yr "$\beta_{LtoH, [0, 23]} - \beta_{LtoL, [0, 23]}$" coef_2yr_to_4yr "$\beta_{LtoH, [24, 47]} - \beta_{LtoL, [24, 47]}$" coef_4yr_to_6yr "$\beta_{LtoH, [48, 71]} - \beta_{LtoL, [48, 71]}$" coef_6yr_to_8yr "$\beta_{LtoH, [72, 96]} - \beta_{LtoL, [72, 96]}$") ///
    stats(cmean r_squared obs, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_panel_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")
