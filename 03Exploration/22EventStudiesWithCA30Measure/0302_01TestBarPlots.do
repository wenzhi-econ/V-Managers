/* 
This do file presents the decomposition results using bar plots.

RA: WWZ 
Time: 2025-05-16
*/



use "${Results}/005EventStudiesWithCA30/CA30_DecompTransferSJC.dta", clear 

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