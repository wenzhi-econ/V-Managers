/* 
This do file presents the decomposition results using bar plots.

RA: WWZ 
Time: 2025-05-20
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. presenting all coefficients
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome3_TransferSJLC_Typez_Decomp.dta", clear 

keep ///
    quarter_TransferSJLC_gains coeff_TransferSJLC_gains lb_TransferSJLC_gains ub_TransferSJLC_gains ///
    quarter_SameMLC_gains coeff_SameMLC_gains lb_SameMLC_gains ub_SameMLC_gains ///
    quarter_DiffMLC_gains coeff_DiffMLC_gains lb_DiffMLC_gains ub_DiffMLC_gains ///
    quarter_DiffFuncSJLC_gains coeff_DiffFuncSJLC_gains lb_DiffFuncSJLC_gains ub_DiffFuncSJLC_gains

generate quarter = quarter_TransferSJLC_gains

graph bar coeff_SameMLC_gains coeff_DiffMLC_gains coeff_DiffFuncSJLC_gains, ///
    scheme(tab2) over(quarter) stack bargap(3) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions") position(12) ring(1)) ///
    b1title("Quarters since manager change") ytitle("Coefficients value") ///
    title("Decomposition of standard job changes") name(bar_stacked, replace)
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_Decomp_StackedBar.pdf", replace as(pdf)


generate cum_SameMLC = coeff_SameMLC_gains
generate cum_DiffMLC = cum_SameMLC + coeff_DiffMLC_gains
generate cum_TransferFuncC = cum_DiffMLC + coeff_DiffFuncSJLC_gains

twoway ///
    (bar cum_TransferFuncC quarter, color(red%20)) ///
    (bar cum_DiffMC quarter, color(ebblue%20)) ///
    (bar cum_SameMC quarter, color(dkgreen%20)), ///
    scheme(tab2) ///
    legend(order(3 "Within team" 2 "Across teams, within function" 1 "Across teams, across functions")) ///
    ytitle("Coefficients value") ///
    xlabel(-8(2)28, grid gstyle(dot)) xtitle("Quarters since manager change") ///
    title("Decomposition of standard job changes") name(bar_owncalculation, replace)
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_Decomp_CumulBar.pdf", replace as(pdf)


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. presenting post-aggregation coefficients: 3 coefficients
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome3_TransferSJLC_Typez_Decomp.dta", clear 

keep ///
    quarter_TransferSJLC_gains coeff_TransferSJLC_gains lb_TransferSJLC_gains ub_TransferSJLC_gains ///
    quarter_SameMLC_gains coeff_SameMLC_gains lb_SameMLC_gains ub_SameMLC_gains ///
    quarter_DiffMLC_gains coeff_DiffMLC_gains lb_DiffMLC_gains ub_DiffMLC_gains ///
    quarter_DiffFuncSJLC_gains coeff_DiffFuncSJLC_gains lb_DiffFuncSJLC_gains ub_DiffFuncSJLC_gains

generate Year_0_2 = inrange(quarter_TransferSJLC_gains, 0, 7)
generate Year_2_5 = inrange(quarter_TransferSJLC_gains, 8, 19)
generate Year_5_7 = inrange(quarter_TransferSJLC_gains, 20, 28)
generate Period = _n if inrange(_n, 1, 3)

foreach var in TransferSJLC SameMLC DiffMLC DiffFuncSJLC {

    generate AvgCoef_`var' = _n if inrange(_n, 1, 3) 

    summarize coeff_`var'_gains if Year_0_2==1, meanonly
    replace  AvgCoef_`var' = r(mean) if _n==1
    
    summarize coeff_`var'_gains if Year_2_5==1, meanonly
    replace  AvgCoef_`var' = r(mean) if _n==2
    
    summarize coeff_`var'_gains if Year_5_7==1, meanonly
    replace  AvgCoef_`var' = r(mean) if _n==3
}

graph bar AvgCoef_SameMLC AvgCoef_DiffMLC AvgCoef_DiffFuncSJLC ///
    , stack over(Period, relabel(1 "0-2 years" 2 "2-5 years" 3 "5-7 years") label(labsize(medlarge))) ///
    blabel(bar, format(%04.3f) position(center) size(small) orientation(horizontal)) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions") position(12) ring(1)) ///
    ytitle("Coefficients value") title("Decomposition of lateral moves") ///
    scheme(tab2)
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_Decomp_StackedBar_3AverageCoefficients.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. presenting post-aggregation coefficients: 7 coefficients
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome3_TransferSJLC_Typez_Decomp.dta", clear 

keep ///
    quarter_TransferSJLC_gains coeff_TransferSJLC_gains lb_TransferSJLC_gains ub_TransferSJLC_gains ///
    quarter_SameMLC_gains coeff_SameMLC_gains lb_SameMLC_gains ub_SameMLC_gains ///
    quarter_DiffMLC_gains coeff_DiffMLC_gains lb_DiffMLC_gains ub_DiffMLC_gains ///
    quarter_DiffFuncSJLC_gains coeff_DiffFuncSJLC_gains lb_DiffFuncSJLC_gains ub_DiffFuncSJLC_gains

generate Year_0 = inrange(quarter_TransferSJLC_gains, 0, 3)
generate Year_1 = inrange(quarter_TransferSJLC_gains, 4, 7)
generate Year_2 = inrange(quarter_TransferSJLC_gains, 8, 11)
generate Year_3 = inrange(quarter_TransferSJLC_gains, 12, 15)
generate Year_4 = inrange(quarter_TransferSJLC_gains, 16, 19)
generate Year_5 = inrange(quarter_TransferSJLC_gains, 20, 23)
generate Year_6 = inrange(quarter_TransferSJLC_gains, 24, 28)

generate Period = _n if inrange(_n, 1, 7)

foreach var in TransferSJLC SameMLC DiffMLC DiffFuncSJLC {

    generate AvgCoef_`var' = _n if inrange(_n, 1, 7) 

    summarize coeff_`var'_gains if Year_0==1, meanonly
    replace  AvgCoef_`var' = r(mean) if Period==1
    
    summarize coeff_`var'_gains if Year_1==1, meanonly
    replace  AvgCoef_`var' = r(mean) if Period==2
    
    summarize coeff_`var'_gains if Year_2==1, meanonly
    replace  AvgCoef_`var' = r(mean) if Period==3

    summarize coeff_`var'_gains if Year_3==1, meanonly
    replace  AvgCoef_`var' = r(mean) if Period==4

    summarize coeff_`var'_gains if Year_4==1, meanonly
    replace  AvgCoef_`var' = r(mean) if Period==5

    summarize coeff_`var'_gains if Year_5==1, meanonly
    replace  AvgCoef_`var' = r(mean) if Period==6

    summarize coeff_`var'_gains if Year_6==1, meanonly
    replace  AvgCoef_`var' = r(mean) if Period==7
}

graph bar AvgCoef_SameMLC AvgCoef_DiffMLC AvgCoef_DiffFuncSJLC ///
    , stack over(Period) ///
    blabel(bar, format(%04.3f) position(center) size(small) orientation(horizontal)) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions") position(6) ring(1)) ///
    b1title("Years since manager change") ytitle("Coefficients value") title("Decomposition of lateral moves") ///
    scheme(tab2)

graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_Decomp_StackedBar_YearlyAverage.pdf", replace as(pdf)
