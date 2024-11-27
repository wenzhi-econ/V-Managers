/* 
This do file investigates a wide variety of heterogeneities on the main outcomes. 

For ChangeSalaryGradeC TransferSJVC outcomes, a simplified event study is done (months -1, -2, -3 are taken as the reference group).
For PromWLC outcome, a simplified and modified event study is done (month 0 is taken as the omitted group).
For LeaverPerm outcome, a cross-sectional regression is done. 

Input:
    "${TempData}/06MainOutcomesInEventStudies_Heterogeneity.dta" <== constructed in 0106 do file 

Results:
    "${Results}/MainOutcomes_Hetero_SelfConstructedData_SelfConstructedData.tex"

RA: WWZ 
Time: 2024-10-21
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. load the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/06MainOutcomesInEventStudies_Heterogeneity.dta", clear 

global Hetero_Vars TenureMHigh SameOffice Young TenureLow SameGender OfficeSizeHigh JobNum LaborRegHigh LowFLFP WPerf WPerf0p10p90 TeamPerfMBase DiffM2y

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. event * post dummies
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! "event * post" (ind-month level) for four treatment groups
generate FT_Post1 = (FT_Rel_Time > 0) if FT_Rel_Time != .
generate FT_LtoLXPost1 = FT_LtoL * FT_Post1
generate FT_LtoHXPost1 = FT_LtoH * FT_Post1
generate FT_HtoHXPost1 = FT_HtoH * FT_Post1
generate FT_HtoLXPost1 = FT_HtoL * FT_Post1

foreach var in $Hetero_Vars {
    generate FT_LtoLXPost1X`var' = FT_LtoLXPost1 * `var'0
    generate FT_LtoHXPost1X`var' = FT_LtoHXPost1 * `var'0
    generate FT_HtoHXPost1X`var' = FT_HtoHXPost1 * `var'0
    generate FT_HtoLXPost1X`var' = FT_HtoLXPost1 * `var'0
}
/* 
Notice that the definition of "Post" in the above procedures is a different from the convention: 
    FT_Rel_Time==0 is not included in FT_Post1. 
This is because in the "PromWLC" regression, 
    we need to use month 0 as the reference month 
    (since we only focus on WL1 workers, mechanically leading to no work level promotions before manager change).
This won't affect regressions for other outcome variables, 
    since we never include month 0 in the regressions for these outcomes (ChangeSalaryGradeC TransferSJVC).
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run event-study regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach hetero_var in $Hetero_Vars {
    global hetero_regressors ///
        FT_LtoLXPost1 FT_LtoLXPost1X`hetero_var' ///
        FT_LtoHXPost1 FT_LtoHXPost1X`hetero_var' ///
        FT_HtoHXPost1 FT_HtoHXPost1X`hetero_var' ///
        FT_HtoLXPost1 FT_HtoLXPost1X`hetero_var'
    
    if "`hetero_var'" == "LowFLFP" {

        foreach outcome in ChangeSalaryGradeC TransferSJVC PromWLC {

            *&? For salary change and later move variables, the reference month is -1, -2, -3.
            if "`outcome'" != "PromWLC" {
                reghdfe `outcome' $hetero_regressors  ///
                    if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & (Female==1) ///
                    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            }

            *&? For work levle promotion, due to the nature of the sample restrictions, the reference month is 0.
            if "`outcome'" == "PromWLC" {
                reghdfe `outcome' $hetero_regressors  ///
                    if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==0 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & (Female==1) ///
                    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            }
        
            xlincom (FT_LtoHXPost1X`hetero_var' - FT_LtoLXPost1X`hetero_var'), level(95) post

            if "`outcome'" == "ChangeSalaryGradeC" {
                local outcome_name CSGC
            }
            if "`outcome'" == "TransferSJVC" {
                local outcome_name TSJVC
            }
            if "`outcome'" == "PromWLC" {
                local outcome_name PWLC
            }

            est store `hetero_var'_`outcome_name'
        }
    }
    
    if "`hetero_var'" != "LowFLFP" {

        foreach outcome in ChangeSalaryGradeC TransferSJVC PromWLC {

            *&? For salary change and later move variables, the reference month is -1, -2, -3.
            if "`outcome'" != "PromWLC" {
                reghdfe `outcome' $hetero_regressors  ///
                    if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) ///
                    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            }

            *&? For work levle promotion, due to the nature of the sample restrictions, the reference month is 0.
            if "`outcome'" == "PromWLC" {
                reghdfe `outcome' $hetero_regressors  ///
                    if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==0 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) ///
                    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            }
        
            xlincom (FT_LtoHXPost1X`hetero_var' - FT_LtoLXPost1X`hetero_var'), level(95) post

            if "`outcome'" == "ChangeSalaryGradeC" {
                local outcome_name CSGC
            }
            if "`outcome'" == "TransferSJVC" {
                local outcome_name TSJVC
            }
            if "`outcome'" == "PromWLC" {
                local outcome_name PWLC
            }

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

*!! s-3-1-1. calendar time of the event 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

*!! s-3-1-2. relative exit time
capture drop Leaver
sort IDlse YearMonth
bysort IDlse: egen Leaver = max(LeaverPerm)

bysort IDlse: egen temp = max(YearMonth)
generate Leave_Time = . 
replace  Leave_Time = temp if Leaver == 1
format Leave_Time %tm
drop temp

generate FT_Rel_Leave_Time = Leave_Time - FT_Event_Time

label variable Leaver            "=1, if the worker left the firm during the dataset period"
label variable Leave_Time        "Time when the worker left the firm, missing if he stays during the sample period"
label variable FT_Rel_Leave_Time "Leave_Time - FT_Event_Time"

*!! s-3-1-3. outcome variable: if the worker left the firm within 5 years after the event
generate LV_5yrs  = inrange(FT_Rel_Leave_Time, 0, 60)

*!! s-3-1-4. event * heterogeneity indicators
foreach var in $Hetero_Vars {
    generate FT_LtoLX`var' = FT_LtoL * `var'0
    generate FT_LtoHX`var' = FT_LtoH * `var'0
    generate FT_HtoHX`var' = FT_HtoH * `var'0
    generate FT_HtoLX`var' = FT_HtoL * `var'0
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. keep only a cross-sectional of treated workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if (YearMonth==FT_Event_Time & FT_Never_ChangeM==0)
    //&& keep one observation for one worker,
    //&& keep only treatment workers  
    //&& we are using control variables at the time of treatment for four treatment groups
keep if (FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0)
    //&& use the same sample as the event studies

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. run cross-sectional regressions on exit outcomes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

summarize FT_Event_Time, detail // max: 743
    global LastMonth = r(max)
    global LastPossibleEventTime = ${LastMonth} - 12 * 5 
        //&& only exit outcomes of these workers (whose event dates are before this time) can be correctly identified 

foreach hetero_var in $Hetero_Vars {
    
    global hetero_regressors ///
        FT_LtoLX`hetero_var' ///
        FT_LtoH FT_LtoHX`hetero_var' ///
        FT_HtoH FT_HtoHX`hetero_var' ///
        FT_HtoL FT_HtoLX`hetero_var'

    reghdfe LV_5yrs ${hetero_regressors} if FT_Event_Time<=${LastPossibleEventTime}, ///
        vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)

    xlincom (FT_LtoHX`hetero_var'), level(95) post

    est store `hetero_var'_Exit
    
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

esttab TenureMHigh_CSGC TenureMHigh_TSJVC TenureMHigh_PWLC TenureMHigh_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager tenure, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{Pay increase} & \multicolumn{1}{c}{Lateral moves} & \multicolumn{1}{c}{Vertical moves} & \multicolumn{1}{c}{Exit from firm} \\") ///
    posthead("\hline \multicolumn{3}{c}{\textit{Panel (a): worker and manager characteristics}} \\ \hline")
esttab SameOffice_CSGC SameOffice_TSJVC SameOffice_PWLC SameOffice_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same office as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab Young_CSGC Young_TSJVC Young_PWLC Young_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker age, young") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab TenureLow_CSGC TenureLow_TSJVC TenureLow_PWLC TenureLow_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker tenure, low") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab SameGender_CSGC SameGender_TSJVC SameGender_PWLC SameGender_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same gender as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab OfficeSizeHigh_CSGC OfficeSizeHigh_TSJVC OfficeSizeHigh_PWLC OfficeSizeHigh_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office size, large") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\hline \multicolumn{3}{c}{\textit{Panel (b): environment characteristics}} \\ \hline") posthead("") prefoot("") postfoot("")
esttab JobNum_CSGC JobNum_TSJVC JobNum_PWLC JobNum_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office job diversity, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LaborRegHigh_CSGC LaborRegHigh_TSJVC LaborRegHigh_PWLC LaborRegHigh_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Labor laws, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LowFLFP_CSGC LowFLFP_TSJVC LowFLFP_PWLC LowFLFP_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Female labor force participation, low [Female]") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab WPerf_CSGC WPerf_TSJVC WPerf_PWLC WPerf_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\hline \multicolumn{3}{c}{\textit{Panel (c): worker performance and moves}} \\ \hline") posthead("") prefoot("") postfoot("")
esttab WPerf0p10p90_CSGC WPerf0p10p90_TSJVC WPerf0p10p90_PWLC WPerf0p10p90_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p90)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab TeamPerfMBase_CSGC TeamPerfMBase_TSJVC TeamPerfMBase_PWLC TeamPerfMBase_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Team performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab DiffM2y_CSGC DiffM2y_TSJVC DiffM2y_PWLC DiffM2y_Exit using "${Results}/MainOutcomes_Hetero_SelfConstructedData.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager change, post transition") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. 95\% confidence intervals used and standard errors are clustered by manager. Coefficients in columns (1), (2), and (3) are estimated from a regression as in equation \ref{eq:het} and the table reports the coefficient at the 20th quarter since the manager transition. Controls include worker FE and year months FE. Coefficients in column (4) are estimated from a cross-sectional regression, where the outcome variable is whether the worker left the firm within 5 years after the treatment, and where controls include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. Each row displays the differential heterogeneous impact of each respective variable. Panel (a): the first row looks at the differential impact between having the manager with over and under 7 years of tenure (the median tenure years for high-flyers managers); the second row looks at the differential impact between sharing and not sharing the office with the manager; the third row looks at the differential impact between being under and over 30 years old; the fourth row looks at the differential impact between being under and over 2 years of tenure; the fifth row looks at the differential impact between sharing and not sharing the same gender with the manager. Panel (b): the first row looks at the differential impact between large and small offices (above and below the median number of workers); the second row looks at the differential impact between offices with high and low number of different jobs (above and below median); the third row looks at the differential impact between countries having stricter and laxer labor laws (above and below median); the fourth row looks at the differential impact between the gender gap (women - men) in countries with the female over male labor force participation ratio above and below median. Panel (c): the first row looks at the differential impact between better and worse performing workers at baseline in terms of salary growth; the second row looks at the differential impact between the top 10\% and the bottom 10\% workers in terms of salary growth; the third row looks at the differential impact between better and worse performing teams at baseline in terms of salary growth; the fourth row looks at the differential impact between workers changing and not changing the manager 2 years after the transition." "\end{tablenotes}")
