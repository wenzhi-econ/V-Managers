/* 
This do file overlay event study results for two outcomes: PromWLC and CVPay

Input: 
    "${EventStudyResults}/Outcome7_PromWLC_Typez_YearlyAggregation.dta"   <== obtained in 0308_Typez do file 
    "${EventStudyResults}/Outcome8_CVPay_Typez_YearlyAggregation.dta"     <== obtained in 0307_Typez do file

RA: WWZ 
Time: 2025-05-21
*/

global EventStudyResults "${Results}/010EventStudiesResultsWithCA30Measure"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare datasets for future merge 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/Outcome8_CVPay_Typez_YearlyAggregation.dta", clear 
generate Year = Year_CVPay_gains
save "${EventStudyResults}/Outcome8_CVPay_Typez_YearlyAggregation_ForMerge.dta", replace 

use "${EventStudyResults}/Outcome7_PromWLC_Typez_YearlyAggregation.dta", clear 
generate Year = Year_PromWLC_gains
save "${EventStudyResults}/Outcome7_PromWLC_Typez_YearlyAggregation_ForMerge.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. merge two datasets storing event study coefficients  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/Outcome8_CVPay_Typez_YearlyAggregation_ForMerge.dta", clear 
merge 1:1 Year using "${EventStudyResults}/Outcome7_PromWLC_Typez_YearlyAggregation_ForMerge.dta", nogenerate

replace Year_PromWLC_gains = Year_PromWLC_gains - 0.1
replace Year_CVPay_gains   = Year_CVPay_gains   + 0.1

twoway ///
    (scatter coef_PromWLC_gains Year_PromWLC_gains, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_PromWLC_gains ub_PromWLC_gains Year_PromWLC_gains, lcolor(magenta)) ///
    (scatter coef_CVPay_gains Year_CVPay_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_CVPay_gains ub_CVPay_gains Year_CVPay_gains, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(1(1)7, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.1(0.02)0.1, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Years since manager change", size(medlarge)) ytitle("Coefficient values", size(medlarge)) ///
    legend(label(2 "Work level promotions") label(4 "Pay dispersion, team level") order(2 4) position(6) ring(0) size(small))

graph export "${Results}/010EventStudiesResultsWithCA30Measure/Outcome7And8_PromWLCAndCVPay_Coef1_Gains.pdf", replace