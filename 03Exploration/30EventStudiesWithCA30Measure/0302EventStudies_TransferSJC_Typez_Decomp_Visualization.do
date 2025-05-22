/* 
This do file presents the decomposition results using bar plots.

RA: WWZ 
Time: 2025-05-20
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. presenting all coefficients
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome2_TransferSJC_Typez_Decomp.dta", clear 

keep ///
    quarter_TransferSJC_gains coeff_TransferSJC_gains lb_TransferSJC_gains ub_TransferSJC_gains ///
    quarter_SameMC_gains coeff_SameMC_gains lb_SameMC_gains ub_SameMC_gains ///
    quarter_DiffMC_gains coeff_DiffMC_gains lb_DiffMC_gains ub_DiffMC_gains ///
    quarter_TransferFuncC_gains coeff_TransferFuncC_gains lb_TransferFuncC_gains ub_TransferFuncC_gains

generate quarter = quarter_TransferSJC_gains

graph bar coeff_SameMC_gains coeff_DiffMC_gains coeff_TransferFuncC_gains, ///
    scheme(tab2) over(quarter) stack bargap(3) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions") position(12) ring(1)) ///
    b1title("Quarters since manager change") ytitle("Coefficients value") ///
    title("Decomposition of standard job changes") name(bar_stacked, replace)
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_Decomp_StackedBar.pdf", replace as(pdf)

graph bar coeff_SameMC_gains coeff_DiffMC_gains coeff_TransferFuncC_gains, ///
    scheme(tab2) over(quarter) stack bargap(2) blabel(bar, format(%03.2f) position(center) size(tiny) orientation(vertical)) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions") position(12) ring(1)) ///
    b1title("Quarters since manager change") ytitle("Coefficients value") title("Decomposition of standard job changes") ///
    name(bar_stacked_barheight, replace)
    

graph bar coeff_SameMC_gains coeff_DiffMC_gains coeff_TransferFuncC_gains, ///
    scheme(tab2) over(quarter) stack bargap(2) blabel(total, format(%03.2f) position(center) size(tiny) orientation(vertical)) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions") position(12) ring(1)) ///
    b1title("Quarters since manager change") ytitle("Coefficients value") title("Decomposition of standard job changes") ///
    name(bar_stacked_cumlbarheight, replace)

generate cum_SameMC = coeff_SameMC_gains
generate cum_DiffMC = cum_SameMC + coeff_DiffMC_gains
generate cum_TransferFuncC = cum_DiffMC + coeff_TransferFuncC_gains

twoway ///
    (bar cum_TransferFuncC quarter, color(red%20)) ///
    (bar cum_DiffMC quarter, color(ebblue%20)) ///
    (bar cum_SameMC quarter, color(dkgreen%20)), ///
    scheme(tab2) ///
    legend(order(3 "Within team" 2 "Across teams, within function" 1 "Across teams, across functions")) ///
    ytitle("Coefficients value") ///
    xlabel(-8(2)28, grid gstyle(dot)) xtitle("Quarters since manager change") ///
    title("Decomposition of standard job changes") name(bar_owncalculation, replace)
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_Decomp_CumulBar.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. presenting post-aggregation coefficients: 3 coefficients
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome2_TransferSJC_Typez_Decomp.dta", clear 

keep ///
    quarter_TransferSJC_gains coeff_TransferSJC_gains lb_TransferSJC_gains ub_TransferSJC_gains ///
    quarter_SameMC_gains coeff_SameMC_gains lb_SameMC_gains ub_SameMC_gains ///
    quarter_DiffMC_gains coeff_DiffMC_gains lb_DiffMC_gains ub_DiffMC_gains ///
    quarter_TransferFuncC_gains coeff_TransferFuncC_gains lb_TransferFuncC_gains ub_TransferFuncC_gains

generate Year_0_2 = inrange(quarter_TransferSJC_gains, 0, 7)
generate Year_2_5 = inrange(quarter_TransferSJC_gains, 8, 19)
generate Year_5_7 = inrange(quarter_TransferSJC_gains, 20, 28)
generate Period = _n if inrange(_n, 1, 3)

foreach var in TransferSJC SameMC DiffMC TransferFuncC {

    generate AvgCoef_`var' = _n if inrange(_n, 1, 3) 

    summarize coeff_`var'_gains if Year_0_2==1, meanonly
    replace  AvgCoef_`var' = r(mean) if _n==1
    
    summarize coeff_`var'_gains if Year_2_5==1, meanonly
    replace  AvgCoef_`var' = r(mean) if _n==2
    
    summarize coeff_`var'_gains if Year_5_7==1, meanonly
    replace  AvgCoef_`var' = r(mean) if _n==3
}

graph bar AvgCoef_SameMC AvgCoef_DiffMC AvgCoef_TransferFuncC ///
    , stack over(Period, relabel(1 "0-2 years" 2 "2-5 years" 3 "5-7 years") label(labsize(medlarge))) ///
    blabel(bar, format(%04.3f) position(center) size(small) orientation(horizontal)) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions") position(12) ring(1)) ///
    ytitle("Coefficients value") title("Decomposition of standard job changes") ///
    scheme(tab2)
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_Decomp_StackedBar_3AverageCoefficients.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. presenting post-aggregation coefficients: 7 coefficients
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome2_TransferSJC_Typez_Decomp.dta", clear 

keep ///
    quarter_TransferSJC_gains coeff_TransferSJC_gains lb_TransferSJC_gains ub_TransferSJC_gains ///
    quarter_SameMC_gains coeff_SameMC_gains lb_SameMC_gains ub_SameMC_gains ///
    quarter_DiffMC_gains coeff_DiffMC_gains lb_DiffMC_gains ub_DiffMC_gains ///
    quarter_TransferFuncC_gains coeff_TransferFuncC_gains lb_TransferFuncC_gains ub_TransferFuncC_gains

generate Year_0 = inrange(quarter_TransferSJC_gains, 0, 3)
generate Year_1 = inrange(quarter_TransferSJC_gains, 4, 7)
generate Year_2 = inrange(quarter_TransferSJC_gains, 8, 11)
generate Year_3 = inrange(quarter_TransferSJC_gains, 12, 15)
generate Year_4 = inrange(quarter_TransferSJC_gains, 16, 19)
generate Year_5 = inrange(quarter_TransferSJC_gains, 20, 23)
generate Year_6 = inrange(quarter_TransferSJC_gains, 24, 28)

generate Period = _n if inrange(_n, 1, 7)

foreach var in TransferSJC SameMC DiffMC TransferFuncC {

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

graph bar AvgCoef_SameMC AvgCoef_DiffMC AvgCoef_TransferFuncC ///
    , stack over(Period) ///
    blabel(bar, format(%04.3f) position(center) size(small) orientation(horizontal)) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions") position(6) ring(1)) ///
    b1title("Years since manager change") ytitle("Coefficients value") title("Decomposition of standard job changes") ///
    scheme(tab2) ///
    text(0.05 35 "Text example")

graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_Decomp_StackedBar_YearlyAverage.pdf", replace as(pdf)
