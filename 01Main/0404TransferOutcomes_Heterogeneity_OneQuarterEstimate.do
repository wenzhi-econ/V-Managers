/* 
This do file investigates a wide variety of heterogeneities on workers' lateral and vertical moves. 

Input:
    "${TempData}/06MainOutcomesInEventStudies_Heterogeneity.dta" <== constructed in 0106 do file 

Results:
    "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate_SelfConstructedData.tex"

RA: WWZ 
Time: 2024-10-09
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. load the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/06MainOutcomesInEventStudies_Heterogeneity.dta", clear 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global Hetero_Vars TenureMHigh SameOffice Young TenureLow SameGender OfficeSizeHigh JobNum LaborRegHigh WPerf WPerf0p10p90 TeamPerfMBase DiffM2y

foreach hetero_var in $Hetero_Vars {
    global hetero_regressors ///
        FT_LtoLXPost FT_LtoLXPostX`hetero_var' ///
        FT_LtoHXPost FT_LtoHXPostX`hetero_var' ///
        FT_HtoHXPost FT_HtoHXPostX`hetero_var' ///
        FT_HtoLXPost FT_HtoLXPostX`hetero_var'

    foreach outcome in TransferSJVC TransferFuncC ChangeSalaryGradeC {
        reghdfe `outcome' $hetero_regressors  ///
            if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) ///
            , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
    
        xlincom (FT_LtoHXPostX`hetero_var' - FT_LtoLXPostX`hetero_var'), level(95) post

        if "`outcome'" == "TransferSJVC" {
            local outcome_name TSJVC
        }
        if "`outcome'" == "TransferFuncC" {
            local outcome_name TFC
        }
        if "`outcome'" == "ChangeSalaryGradeC" {
            local outcome_name CSGC
        }

        est store `hetero_var'_`outcome_name'
    }
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

esttab TenureMHigh_TSJVC TenureMHigh_TFC TenureMHigh_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager tenure, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\hline\hline" "& \multicolumn{1}{c}{Lateral moves} & \multicolumn{1}{c}{Cross-function moves} & \multicolumn{1}{c}{Pay grade increase} \\") ///
    posthead("\hline \multicolumn{3}{c}{\textit{Panel (a): worker and manager characteristics}} \\ \hline")
esttab SameOffice_TSJVC SameOffice_TFC SameOffice_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same office as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab Young_TSJVC Young_TFC Young_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker age, young") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab TenureLow_TSJVC TenureLow_TFC TenureLow_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker tenure, low") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab SameGender_TSJVC SameGender_TFC SameGender_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same gender as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab OfficeSizeHigh_TSJVC OfficeSizeHigh_TFC OfficeSizeHigh_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office size, large") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\hline \multicolumn{3}{c}{\textit{Panel (b): environment characteristics}} \\ \hline") posthead("") prefoot("") postfoot("")
esttab JobNum_TSJVC JobNum_TFC JobNum_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office job diversity, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LaborRegHigh_TSJVC LaborRegHigh_TFC LaborRegHigh_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Labor laws, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab WPerf_TSJVC WPerf_TFC WPerf_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\hline \multicolumn{3}{c}{\textit{Panel c: worker performance and moves}} \\ \hline") posthead("") prefoot("") postfoot("")
esttab WPerf0p10p90_TSJVC WPerf0p10p90_TFC WPerf0p10p90_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p90)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab TeamPerfMBase_TSJVC TeamPerfMBase_TFC TeamPerfMBase_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Team performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab DiffM2y_TSJVC DiffM2y_TFC DiffM2y_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager change, post transition") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. 95\% confidence intervals used and standard errors are clustered by manager. Coefficients are estimated from a regression as in equation \ref{eq:het} and the figure reports the coefficient at the 20th quarter since the manager transition. Controls include worker FE and year months FE. Each row displays the differential heterogeneous impact of each respective variable. Panel (a): the first row looks at the differential impact between having the manager with over and under 7 years of tenure (the median tenure years for high-flyers managers); the second row looks at the differential impact between sharing and not sharing the office with the manager; the third row looks at the differential impact between being under and over 30 years old; the fourth row looks at the differential impact between being under and over 2 years of tenure; the fifth row looks at the differential impact between sharing and not sharing the same gender with the manager. Panel (b): the first row looks at the differential impact between large and small offices (above and below the median number of workers); the second row looks at the differential impact between offices with high and low number of different jobs (above and below median); the third row looks at the differential impact between countries having stricter and laxer labor laws (above and below median); the fourth row looks at the differential impact between the gender gap (women - men) in countries with the female over male labor force participation ratio above and below median. Panel (c): the first row looks at the differential impact between better and worse performing workers at baseline in terms of salary growth; the second row looks at the differential impact between the top 10\% and the bottom 10\% workers in terms of salary growth; the third row looks at the differential impact between better and worse performing teams at baseline in terms of salary growth; the fourth row looks at the differential impact between workers changing and not changing the manager 2 years after the transition." "\end{tablenotes}")