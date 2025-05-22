/* 
This do file plots the event study coefficients for two outcomes of interest.


RA: WWZ 
Time: 2025-05-20
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. keep only necessary variables in the resulting dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome1_ChangeSalaryGradeC_Type1_Pre24Post84.dta", replace 
    keep quarter_ChangeSalaryGradeC_gains coeff_ChangeSalaryGradeC_gains lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains
    generate quarter = quarter_ChangeSalaryGradeC_gains
    drop if quarter==.
    save "${Results}/010EventStudiesResultsWithCA30Measure/Outcome1_ChangeSalaryGradeC_Type1_Pre24Post84_ForMerge.dta", replace

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome2_TransferSJC_Type1_Pre24Post84.dta", replace 
    keep quarter_TransferSJC_gains coeff_TransferSJC_gains lb_TransferSJC_gains ub_TransferSJC_gains
    generate quarter = quarter_TransferSJC_gains
    drop if quarter==.
    save "${Results}/010EventStudiesResultsWithCA30Measure/Outcome2_TransferSJC_Type1_Pre24Post84_ForMerge.dta", replace

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome3_TransferSJLC_Type1_Pre24Post84.dta", replace 
    keep quarter_TransferSJLC_gains coeff_TransferSJLC_gains lb_TransferSJLC_gains ub_TransferSJLC_gains
    generate quarter = quarter_TransferSJLC_gains
    drop if quarter==.
    save "${Results}/010EventStudiesResultsWithCA30Measure/Outcome3_TransferSJLC_Type1_Pre24Post84_ForMerge.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. merge the datasets  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/010EventStudiesResultsWithCA30Measure/Outcome1_ChangeSalaryGradeC_Type1_Pre24Post84_ForMerge.dta", clear 
merge 1:1 quarter using "${Results}/010EventStudiesResultsWithCA30Measure/Outcome2_TransferSJC_Type1_Pre24Post84_ForMerge.dta", nogenerate
merge 1:1 quarter using "${Results}/010EventStudiesResultsWithCA30Measure/Outcome3_TransferSJLC_Type1_Pre24Post84_ForMerge.dta", nogenerate

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. plot the coefficients in one figure  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

replace quarter_ChangeSalaryGradeC_gains = quarter_ChangeSalaryGradeC_gains - 0.2
replace quarter_TransferSJC_gains        = quarter_TransferSJC_gains + 0.2
replace quarter_TransferSJLC_gains       = quarter_TransferSJLC_gains + 0.2

twoway ///
    (scatter coeff_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue)) ///
    (scatter coeff_TransferSJC_gains quarter_TransferSJC_gains, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_TransferSJC_gains ub_TransferSJC_gains quarter_TransferSJC_gains, lcolor(magenta)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ytitle("Coefficient values", size(medlarge)) ///
    legend(label(2 "Salary grade increase") label(4 "Standard job change") order(2 4) position(6) ring(0) size(small))
graph export "${Results}/010EventStudiesResultsWithCA30Measure/Outcome1And2_ChangeSalaryGradeCAndTransferSJC_Coef1_Gains.pdf", replace


twoway ///
    (scatter coeff_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ChangeSalaryGradeC_gains ub_ChangeSalaryGradeC_gains quarter_ChangeSalaryGradeC_gains, lcolor(ebblue)) ///
    (scatter coeff_TransferSJLC_gains quarter_TransferSJLC_gains, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_TransferSJLC_gains ub_TransferSJLC_gains quarter_TransferSJLC_gains, lcolor(magenta)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ytitle("Coefficient values", size(medlarge)) ///
    legend(label(2 "Salary grade increase") label(4 "Lateral move") order(2 4) position(6) ring(0) size(small))
graph export "${Results}/010EventStudiesResultsWithCA30Measure/Outcome1And3_ChangeSalaryGradeCAndTransferSJLC_Coef1_Gains.pdf", replace
