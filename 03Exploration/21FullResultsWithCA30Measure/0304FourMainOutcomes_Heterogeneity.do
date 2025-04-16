/* 
This do file investigates a wide variety of heterogeneities on the main outcomes. 

For ChangeSalaryGradeC TransferSJVC outcomes, a simplified event study is implemented (months -1, -2, -3 are taken as the reference group).
For PromWLC outcome, a simplified and modified event study is implemented (month 0 is taken as the omitted group).
For LeaverPerm outcome, a cross-sectional regression is implemented. 

Input:
    "${TempData}/0104AnalysisSample_WithHeteroIndicators.dta" <== created in 0104 do file 

Results:
    "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex"

RA: WWZ 
Time: 2025-04-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. load the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0104AnalysisSample_WithHeteroIndicators.dta", clear 

global Hetero_Vars TenureMHigh SameOffice Young SameGender OfficeSizeHigh JobNum LaborRegHigh LowFLFP WPerf WPerf0p10p90 TeamPerfMBase

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. "event * post" dummies
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Post1 = (Rel_Time > 0) if Rel_Time != .
generate LtoLXPost1 = CA30_LtoL * Post1
generate LtoHXPost1 = CA30_LtoH * Post1
generate HtoHXPost1 = CA30_HtoH * Post1
generate HtoLXPost1 = CA30_HtoL * Post1

/* 
Notes:
    (1) The definition of "Post" in the above procedures is a different from the convention: FT_Rel_Time==0 is not included in FT_Post1. 
    (2) This is because in the "PromWLC" regression, we need to use month 0 as the reference month. 
    (3) The uniqueness of the "PromWLC" regression comes from the fact that we only focus on WL1 workers, mechanically leading to no work level promotions before manager change.
    (4) This won't affect regressions for other outcome variables, since we never include month 0 in "ChangeSalaryGradeC" and "TransferSJVC" regressions.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. "event * post * heterogeneity indicator" dummies
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in $Hetero_Vars {
    generate LtoLXPost1X`var' = LtoLXPost1 * `var'1
    generate LtoHXPost1X`var' = LtoHXPost1 * `var'1
    generate HtoHXPost1X`var' = HtoHXPost1 * `var'1
    generate HtoLXPost1X`var' = HtoLXPost1 * `var'1
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run event-study regressions on non-exit outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach hetero_var in $Hetero_Vars {
    global hetero_regressors ///
        LtoLXPost1 LtoLXPost1X`hetero_var' ///
        LtoHXPost1 LtoHXPost1X`hetero_var' ///
        HtoHXPost1 HtoHXPost1X`hetero_var' ///
        HtoLXPost1 HtoLXPost1X`hetero_var'
    
    if ("`hetero_var'" == "LowFLFP") {
        //&? For the FLFP heterogeneity indicator, regresion sample only consists of female workers.

        foreach outcome in ChangeSalaryGradeC TransferSJVC PromWLC {

            //&? For salary change and later move variables, the reference month is -1, -2, -3.
            if "`outcome'" != "PromWLC" {
                reghdfe `outcome' $hetero_regressors  ///
                    if (Rel_Time==-1 | Rel_Time==-2 | Rel_Time==-3 | Rel_Time==58 | Rel_Time==59 | Rel_Time==60) & (Female==1) ///
                    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            }

            //&? For work level promotion, due to the nature of the sample restrictions, the reference month is 0.
            if "`outcome'" == "PromWLC" {
                reghdfe `outcome' $hetero_regressors  ///
                    if (Rel_Time==0 | Rel_Time==58 | Rel_Time==59 | Rel_Time==60) & (Female==1) ///
                    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            }
            
            //&? "LtoH * post * heterogeneity indicator" - "LtoL * post * heterogeneity indicator"
            xlincom (LtoHXPost1X`hetero_var' - LtoLXPost1X`hetero_var'), level(95) post
                if "`outcome'" == "ChangeSalaryGradeC" local outcome_name CSGC
                if "`outcome'" == "TransferSJVC" local outcome_name TSJVC
                if "`outcome'" == "PromWLC" local outcome_name PWLC
                est store `hetero_var'_`outcome_name'
        }
    }
    
    if ("`hetero_var'" != "LowFLFP") {

        foreach outcome in ChangeSalaryGradeC TransferSJVC PromWLC {

            //&? For salary change and later move variables, the reference month is -1, -2, -3.
            if "`outcome'" != "PromWLC" {
                reghdfe `outcome' $hetero_regressors  ///
                    if (Rel_Time==-1 | Rel_Time==-2 | Rel_Time==-3 | Rel_Time==58 | Rel_Time==59 | Rel_Time==60) ///
                    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            }

            //&? For work level promotion, due to the nature of the sample restrictions, the reference month is 0.
            if "`outcome'" == "PromWLC" {
                reghdfe `outcome' $hetero_regressors  ///
                    if (Rel_Time==0 | Rel_Time==58 | Rel_Time==59 | Rel_Time==60) ///
                    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            }

            //&? "LtoH * post * heterogeneity indicator" - "LtoL * post * heterogeneity indicator"
            xlincom (LtoHXPost1X`hetero_var' - LtoLXPost1X`hetero_var'), level(95) post
                if "`outcome'" == "ChangeSalaryGradeC" local outcome_name CSGC
                if "`outcome'" == "TransferSJVC" local outcome_name TSJVC
                if "`outcome'" == "PromWLC" local outcome_name PWLC
                est store `hetero_var'_`outcome_name'
        }
    }

}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run cross-sectional regressions: exit outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. new variables for event outcomes  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-3-1-1. relative exit time
capture drop Leaver
sort IDlse YearMonth
bysort IDlse: egen Leaver = max(LeaverPerm)

bysort IDlse: egen temp = max(YearMonth)
generate Leave_Time = . 
replace  Leave_Time = temp if Leaver == 1
format Leave_Time %tm
drop temp

generate Rel_Leave_Time = Leave_Time - Event_Time

label variable Leaver            "=1, if the worker left the firm during the dataset period"
label variable Leave_Time        "Time when the worker left the firm, missing if he stays during the sample period"
label variable Rel_Leave_Time    "Leave_Time - Event_Time"

*!! s-3-1-2. outcome variable: if the worker left the firm within 2 years after the event
generate LV_2yrs  = inrange(Rel_Leave_Time, 0, 24)

*!! s-3-1-3. event * heterogeneity indicators
foreach var in $Hetero_Vars {
    generate LtoLX`var' = CA30_LtoL * `var'1
    generate LtoHX`var' = CA30_LtoH * `var'1
    generate HtoHX`var' = CA30_HtoH * `var'1
    generate HtoLX`var' = CA30_HtoL * `var'1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. keep only a cross-section of treated workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if YearMonth==Event_Time
    //&? keep one observation for one worker,
    //&? we are using control variables at the time of treatment for four treatment groups

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. run cross-sectional regressions on exit outcomes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

summarize Event_Time, detail
    global LastMonth = r(max)
    global LastPossibleEventTime = ${LastMonth} - 12 * 2 
        //&? only exit outcomes of these workers (whose event dates are before this time) can be correctly identified 

foreach hetero_var in $Hetero_Vars {
    
    global hetero_regressors ///
        LtoLX`hetero_var' ///
        CA30_LtoH LtoHX`hetero_var' ///
        CA30_HtoH HtoHX`hetero_var' ///
        CA30_HtoL HtoLX`hetero_var'
            //&? CA30_LtoL group is omitted.

    reghdfe LV_2yrs ${hetero_regressors} if Event_Time<=${LastPossibleEventTime}, ///
        vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female Event_Time)

    xlincom (LtoHX`hetero_var'), level(95) post
        est store `hetero_var'_Exit
    
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

esttab TenureMHigh_CSGC TenureMHigh_TSJVC TenureMHigh_PWLC TenureMHigh_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager tenure, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{Pay increase} & \multicolumn{1}{c}{Lateral moves} & \multicolumn{1}{c}{Vertical moves} & \multicolumn{1}{c}{Exit from firm} \\") ///
    posthead("\hline \multicolumn{3}{c}{\textit{Panel (a): worker and manager characteristics}} \\ \hline")
esttab SameOffice_CSGC SameOffice_TSJVC SameOffice_PWLC SameOffice_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same office as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab SameGender_CSGC SameGender_TSJVC SameGender_PWLC SameGender_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same gender as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab Young_CSGC Young_TSJVC Young_PWLC Young_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker age, young") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab OfficeSizeHigh_CSGC OfficeSizeHigh_TSJVC OfficeSizeHigh_PWLC OfficeSizeHigh_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office size, large") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\hline \multicolumn{3}{c}{\textit{Panel (b): office and country-wide characteristics}} \\ \hline") posthead("") prefoot("") postfoot("")
esttab JobNum_CSGC JobNum_TSJVC JobNum_PWLC JobNum_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office job diversity, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LaborRegHigh_CSGC LaborRegHigh_TSJVC LaborRegHigh_PWLC LaborRegHigh_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Labor laws, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LowFLFP_CSGC LowFLFP_TSJVC LowFLFP_PWLC LowFLFP_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Female labor force participation, low [Female]") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab WPerf_CSGC WPerf_TSJVC WPerf_PWLC WPerf_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\hline \multicolumn{3}{c}{\textit{Panel (c): worker performance and moves}} \\ \hline") posthead("") prefoot("") postfoot("")
esttab WPerf0p10p90_CSGC WPerf0p10p90_TSJVC WPerf0p10p90_PWLC WPerf0p10p90_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p90)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab TeamPerfMBase_CSGC TeamPerfMBase_TSJVC TeamPerfMBase_PWLC TeamPerfMBase_Exit using "${Results}/004ResultsBasedOnCA30/CA30_HeterogeneityInFourMainOutcomes.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Team performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. 95\% confidence intervals used and standard errors are clustered by manager. Coefficients in columns (1), (2), and (3) are estimated from a regression as in equation \ref{eq:het} and the table reports the coefficient at the 20th quarter since the manager transition. Controls include worker FE and year months FE. Coefficients in column (4) are estimated from a cross-sectional regression, where the outcome variable is whether the worker left the firm within 2 years after the treatment, and where controls include the fixed effects of event time, the interaction of office and function, as well as the interaction between age band and gender. Each row displays the differential heterogeneous impact of each respective variable. Panel (a): the first row looks at the differential impact between having the manager with over and under 7 years of tenure (the median tenure years for high-flyers managers); the second row looks at the differential impact between sharing and not sharing the office with the manager; the third row looks at the differential impact between being under and over 30 years old; the fourth row looks at the differential impact between being under and over 2 years of tenure; the fifth row looks at the differential impact between sharing and not sharing the same gender with the manager. Panel (b): the first row looks at the differential impact between large and small offices (above and below the median number of workers); the second row looks at the differential impact between offices with high and low number of different jobs (above and below median); the third row looks at the differential impact between countries having stricter and laxer labor laws (above and below median); the fourth row looks at the differential impact between the gender gap (women - men) in countries with the female over male labor force participation ratio above and below median. Panel (c): the first row looks at the differential impact between better and worse performing workers at baseline in terms of salary growth; the second row looks at the differential impact between the top 10\% and the bottom 10\% workers in terms of salary growth; the third row looks at the differential impact between better and worse performing teams at baseline in terms of salary growth; the fourth row looks at the differential impact between workers changing and not changing the manager 2 years after the transition." "\end{tablenotes}")
