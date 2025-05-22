/* 
This do file visualizes event study results on outcome: TransferSJLC, by different tenure restrictions.
The high-flyer measure used here is CA30.

Input:
    "${EventStudyResults}/Outcome3_TransferSJLC_Type6_DiffTenure.dta"

RA: WWZ 
Time: 2025-05-21
*/

global EventStudyResults "${Results}/010EventStudiesResultsWithCA30Measure"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. produce event study plots separately 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach type in TenureRestriction1 TenureRestriction2 TenureRestriction3 {
    foreach result in Coef1_Gains Coef2_Loss Coef3_GainsMinusLoss {
        graph use "${EventStudyResults}/CA30_Outcome3_TransferSJLC_`result'_Type6_`type'.gph"
        graph export "${EventStudyResults}/CA30_Outcome3_TransferSJLC_`result'_Type6_`type'.pdf", replace as(pdf)
    }
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. produce event study results in one single plot 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/Outcome3_TransferSJLC_Type6_DiffTenure.dta", clear

foreach type in gains loss ddiff {
    replace quarter_TransferSJLC_`type'1 = quarter_TransferSJLC_`type'1 - 0.25
    replace quarter_TransferSJLC_`type'2 = quarter_TransferSJLC_`type'2 + 0.001
    replace quarter_TransferSJLC_`type'3 = quarter_TransferSJLC_`type'3 + 0.25
}

twoway ///
    (scatter coeff_TransferSJLC_gains1 quarter_TransferSJLC_gains1, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJLC_gains1 ub_TransferSJLC_gains1 quarter_TransferSJLC_gains1, lcolor(ebblue)) ///
    (scatter coeff_TransferSJLC_gains2 quarter_TransferSJLC_gains2, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_TransferSJLC_gains2 ub_TransferSJLC_gains2 quarter_TransferSJLC_gains2, lcolor(magenta)) ///
    (scatter coeff_TransferSJLC_gains3 quarter_TransferSJLC_gains3, lcolor(dkgreen) mcolor(dkgreen)) ///
    (rcap lb_TransferSJLC_gains3 ub_TransferSJLC_gains3 quarter_TransferSJLC_gains3, lcolor(dkgreen)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ytitle("Coefficient values", size(medlarge)) ///
    legend(label(2 "Tenure at event: [0, 2]") label(4 "Tenure at event: [3, 10]") label(6 "Tenure at event: >10") order(2 4 6) position(6) ring(0) size(small))
graph export "${EventStudyResults}/CA30_Outcome3_TransferSJLC_Coef1_Gains_Type6_DiffTenureInOnePlot.pdf", replace

twoway ///
    (scatter coeff_TransferSJLC_loss1 quarter_TransferSJLC_loss1, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_TransferSJLC_loss1 ub_TransferSJLC_loss1 quarter_TransferSJLC_loss1, lcolor(ebblue)) ///
    (scatter coeff_TransferSJLC_loss2 quarter_TransferSJLC_loss2, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_TransferSJLC_loss2 ub_TransferSJLC_loss2 quarter_TransferSJLC_loss2, lcolor(magenta)) ///
    (scatter coeff_TransferSJLC_loss3 quarter_TransferSJLC_loss3, lcolor(dkgreen) mcolor(dkgreen)) ///
    (rcap lb_TransferSJLC_loss3 ub_TransferSJLC_loss3 quarter_TransferSJLC_loss3, lcolor(dkgreen)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.5(0.05)0.5, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ytitle("Coefficient values", size(medlarge)) ///
    legend(label(2 "Tenure at event: [0, 2]") label(4 "Tenure at event: [3, 10]") label(6 "Tenure at event: >10") order(2 4 6) position(6) ring(0) size(small))
graph export "${EventStudyResults}/CA30_Outcome3_TransferSJLC_Coef2_Loss_Type6_DiffTenureInOnePlot.pdf", replace
