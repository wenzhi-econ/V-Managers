/* 
This do file presents the event study coefficients using three measures: CA30 and TB05.
Notes:
    (1) The event studies are run in 23/0301_99 do file, with the coefficients stored and processed in three datasets.
    (2) This do file simply plots the coefficients plots with the CA30 and TB05 measure.
    (3) This generates the final results reported in the responses to the referee reports.

Input:
    "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_Pre24Post84_ForMerge.dta"
    "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_Pre24Post84_ForMerge.dta"
    "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84_ForMerge.dta

RA: WWZ 
Time: 2025-05-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step z. produce the figure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Results}/006EventStudiesWithTenureBasedMeasures/CA30_TwoMainOutcomes_Pre24Post84_ForMerge.dta", clear 
merge 1:1 rowid using "${Results}/006EventStudiesWithTenureBasedMeasures/TB04_TwoMainOutcomes_Pre24Post84_ForMerge.dta", nogenerate 
merge 1:1 rowid using "${Results}/006EventStudiesWithTenureBasedMeasures/TB05_TwoMainOutcomes_Pre24Post84_ForMerge.dta", nogenerate 

replace CA30_SJVC_quarter_gains = CA30_SJVC_quarter_gains - 0.2
replace TB05_SJVC_quarter_gains = TB05_SJVC_quarter_gains + 0.2
replace CA30_SGC_quarter_gains  = CA30_SGC_quarter_gains  - 0.2
replace TB05_SGC_quarter_gains  = TB05_SGC_quarter_gains  + 0.2
replace CA30_SJVC_quarter_loss  = CA30_SJVC_quarter_loss  - 0.2
replace TB05_SJVC_quarter_loss  = TB05_SJVC_quarter_loss  + 0.2
replace CA30_SGC_quarter_loss   = CA30_SGC_quarter_loss   - 0.2
replace TB05_SGC_quarter_loss   = TB05_SGC_quarter_loss   + 0.2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-z-1. the effects of gaining a high-flyer
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

twoway ///
    (scatter CA30_SJVC_coef_gains CA30_SJVC_quarter_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap CA30_SJVC_lb_gains CA30_SJVC_ub_gains CA30_SJVC_quarter_gains, lcolor(ebblue)) ///
    (scatter TB05_SJVC_coef_gains TB05_SJVC_quarter_gains, lcolor(magenta) mcolor(magenta)) ///
    (rcap TB05_SJVC_lb_gains TB05_SJVC_ub_gains TB05_SJVC_quarter_gains, lcolor(magenta)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle(Quarters since manager change, size(medlarge)) title("Lateral move", span pos(12)) ///
    legend(label(2 "Original age-based measure (age 30 as the threshold)") label(4 "Tenure-based measure (5 years as the threshold)") order(2 4) position(6) ring(0) size(small))
graph export "${Results}/006EventStudiesWithTenureBasedMeasures/CA30TB05_Outcome1_TransferSJVC_Coef1_Gains.pdf", replace

twoway ///
    (scatter CA30_SGC_coef_gains CA30_SGC_quarter_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap CA30_SGC_lb_gains CA30_SGC_ub_gains CA30_SGC_quarter_gains, lcolor(ebblue)) ///
    (scatter TB05_SGC_coef_gains TB05_SGC_quarter_gains, lcolor(magenta) mcolor(magenta)) ///
    (rcap TB05_SGC_lb_gains TB05_SGC_ub_gains TB05_SGC_quarter_gains, lcolor(magenta)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle(Quarters since manager change, size(medlarge)) title("Salary grade increase", span pos(12)) ///
    legend(label(2 "Original age-based measure (age 30 as the threshold)") label(4 "Tenure-based measure (5 years as the threshold)") order(2 4) position(6) ring(0) size(small))
graph export "${Results}/006EventStudiesWithTenureBasedMeasures/CA30TB05_Outcome2_ChangeSalaryGradeC_Coef1_Gains.pdf", replace
