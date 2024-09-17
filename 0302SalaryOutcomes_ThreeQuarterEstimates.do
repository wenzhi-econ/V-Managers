/* 
This do file replicates Figure V in the paper. 

Commands are mainly copied from "2.4 Event Study NoLoops.do" file.

RA: WWZ 
Time: 2024-09-05
*/

capture log close
log using "${Results}/logfile_20240917_SalaryOutcomes", replace text

use "${TempData}/temp_MainOutcomesInEventStudies.dta", clear 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when offically producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Months -1, -2, and -3 are omitted as the reference group, so in Lines 30 and 42, iteration ends with 4.
*&& <-36, -36, -35, ..., -5, -4, 0, 1, 2, ...,  +83, +84, and >+84

local max_pre_period  = 36 
local max_post_period = 84

foreach event in FT_LtoL FT_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_LtoL FT_LtoH {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}
foreach event in FT_HtoH FT_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before36
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in FT_HtoH FT_HtoL {
    forvalues time = 0/`max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After84
}

global four_events_dummies ${FT_LtoL_X_Pre} ${FT_LtoL_X_Post} ${FT_LtoH_X_Pre} ${FT_LtoH_X_Post} ${FT_HtoH_X_Pre} ${FT_HtoH_X_Post} ${FT_HtoL_X_Pre} ${FT_HtoL_X_Post}

display "${four_events_dummies}"

    // FT_LtoL_X_Pre_Before36 FT_LtoL_X_Pre36 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post84 FT_LtoL_X_Pre_After84 
    // FT_LtoH_X_Pre_Before36 FT_LtoH_X_Pre36 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post84 FT_LtoH_X_Pre_After84 
    // FT_HtoH_X_Pre_Before36 FT_HtoH_X_Pre36 ... FT_HtoH_X_Pre4 FT_HtoH_X_Post0 FT_HtoH_X_Post1 ... FT_HtoH_X_Post84 FT_HtoH_X_Pre_After84 
    // FT_HtoL_X_Pre_Before36 FT_HtoL_X_Pre36 ... FT_HtoL_X_Pre4 FT_HtoL_X_Post0 FT_HtoL_X_Post1 ... FT_HtoL_X_Post84 FT_HtoL_X_Pre_After84 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure A. Pay + bonus (logs)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

eststo clear 

reghdfe LogPayBonus ${four_events_dummies} ///
    if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*&& Quarter 12 estimate is the average of Month 34, Month 35, and Month 36 estimates
*&& Quarter 20 estimate is the average of Month 58, Month 59, and Month 60 estimates
*&& Quarter 28 estimate is the average of Month 82, Month 83, and Month 84 estimates

xlincom ///
    (((FT_LtoH_X_Post34 - FT_LtoL_X_Post34) + (FT_LtoH_X_Post35 - FT_LtoL_X_Post35) + (FT_LtoH_X_Post36 - FT_LtoL_X_Post36))/3) ///
    (((FT_LtoH_X_Post58 - FT_LtoL_X_Post58) + (FT_LtoH_X_Post59 - FT_LtoL_X_Post59) + (FT_LtoH_X_Post60 - FT_LtoL_X_Post60))/3) ///
    (((FT_LtoH_X_Post82 - FT_LtoL_X_Post82) + (FT_LtoH_X_Post83 - FT_LtoL_X_Post83) + (FT_LtoH_X_Post84 - FT_LtoL_X_Post84))/3) ///
    , level(95) post

eststo LogPayBonus

coefplot  ///
    (LogPayBonus, keep(lc_1) rename(lc_1 = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (LogPayBonus, keep(lc_2) rename(lc_2 = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (LogPayBonus, keep(lc_3) rename(lc_3 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    , ciopts(lwidth(2 ..)) levels(95) msymbol(d) mcolor(white) legend(off)  ///
    title("Pay + bonus (logs)", size(vlarge)) ///
    graphregion(margin(medium)) plotregion(margin(medium)) xsize(5) ysize(2) ///
    xline(0, lpattern(dash)) ylabel(, labsize(vlarge)) xlabel(, labsize(vlarge)) ///
    xlabel(0(0.05)0.15, labsize(vlarge)) xscale(range(0 0.15)) 

graph export "${Results}/FT_Gains_LogPayBonus_ThreeQuarterEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure B.  Pay (logs)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe LogPay ${four_events_dummies} ///
    if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*&& Quarter 12 estimate is the average of Month 34, Month 35, and Month 36 estimates
*&& Quarter 20 estimate is the average of Month 58, Month 59, and Month 60 estimates
*&& Quarter 28 estimate is the average of Month 82, Month 83, and Month 84 estimates

xlincom ///
    (((FT_LtoH_X_Post34 - FT_LtoL_X_Post34) + (FT_LtoH_X_Post35 - FT_LtoL_X_Post35) + (FT_LtoH_X_Post36 - FT_LtoL_X_Post36))/3) ///
    (((FT_LtoH_X_Post58 - FT_LtoL_X_Post58) + (FT_LtoH_X_Post59 - FT_LtoL_X_Post59) + (FT_LtoH_X_Post60 - FT_LtoL_X_Post60))/3) ///
    (((FT_LtoH_X_Post82 - FT_LtoL_X_Post82) + (FT_LtoH_X_Post83 - FT_LtoL_X_Post83) + (FT_LtoH_X_Post84 - FT_LtoL_X_Post84))/3) ///
    , level(95) post

eststo LogPay

coefplot  ///
    (LogPay, keep(lc_1) rename(lc_1 = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (LogPay, keep(lc_2) rename(lc_2 = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (LogPay, keep(lc_3) rename(lc_3 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    , ciopts(lwidth(2 ..)) levels(95) msymbol(d) mcolor(white) legend(off)  ///
    title("Pay (logs)", size(vlarge)) ///
    graphregion(margin(medium)) plotregion(margin(medium)) xsize(5) ysize(2) ///
    xline(0, lpattern(dash)) ylabel(, labsize(vlarge)) xlabel(, labsize(vlarge)) ///
    xlabel(0(0.05)0.15, labsize(vlarge)) xscale(range(0 0.15)) 

graph export "${Results}/FT_Gains_LogPay_ThreeQuarterEstimates.png", replace


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure C. Bonus (logs)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe LogBonus ${four_events_dummies} ///
    if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*&& Quarter 12 estimate is the average of Month 34, Month 35, and Month 36 estimates
*&& Quarter 20 estimate is the average of Month 58, Month 59, and Month 60 estimates
*&& Quarter 28 estimate is the average of Month 82, Month 83, and Month 84 estimates

xlincom ///
    (((FT_LtoH_X_Post34 - FT_LtoL_X_Post34) + (FT_LtoH_X_Post35 - FT_LtoL_X_Post35) + (FT_LtoH_X_Post36 - FT_LtoL_X_Post36))/3) ///
    (((FT_LtoH_X_Post58 - FT_LtoL_X_Post58) + (FT_LtoH_X_Post59 - FT_LtoL_X_Post59) + (FT_LtoH_X_Post60 - FT_LtoL_X_Post60))/3) ///
    (((FT_LtoH_X_Post82 - FT_LtoL_X_Post82) + (FT_LtoH_X_Post83 - FT_LtoL_X_Post83) + (FT_LtoH_X_Post84 - FT_LtoL_X_Post84))/3) ///
    , level(95) post

eststo LogBonus

coefplot  ///
    (LogBonus, keep(lc_1) rename(lc_1 = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (LogBonus, keep(lc_2) rename(lc_2 = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (LogBonus, keep(lc_3) rename(lc_3 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    , ciopts(lwidth(2 ..)) levels(95) msymbol(d) mcolor(white) legend(off)  ///
    title("Bonus (logs)", size(vlarge)) ///
    graphregion(margin(medium)) plotregion(margin(medium)) xsize(5) ysize(2) ///
    xline(0, lpattern(dash)) ylabel(, labsize(vlarge)) xlabel(, labsize(vlarge)) ///
    xlabel(0(0.5)1.5, labsize(vlarge)) xscale(range(0 1.5)) 

graph export "${Results}/FT_Gains_LogBonus_ThreeQuarterEstimates.png", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Subfigure D. Work-level promotions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe PromWLC ${four_events_dummies} ///
    if ((FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0) | (FT_Never_ChangeM==1)) ///
    , absorb(IDlse YearMonth)  vce(cluster IDlseMHR) 

*&& Quarter 12 estimate is the average of Month 34, Month 35, and Month 36 estimates
*&& Quarter 20 estimate is the average of Month 58, Month 59, and Month 60 estimates
*&& Quarter 28 estimate is the average of Month 82, Month 83, and Month 84 estimates

xlincom ///
    (((FT_LtoH_X_Post34 - FT_LtoL_X_Post34) + (FT_LtoH_X_Post35 - FT_LtoL_X_Post35) + (FT_LtoH_X_Post36 - FT_LtoL_X_Post36))/3) ///
    (((FT_LtoH_X_Post58 - FT_LtoL_X_Post58) + (FT_LtoH_X_Post59 - FT_LtoL_X_Post59) + (FT_LtoH_X_Post60 - FT_LtoL_X_Post60))/3) ///
    (((FT_LtoH_X_Post82 - FT_LtoL_X_Post82) + (FT_LtoH_X_Post83 - FT_LtoL_X_Post83) + (FT_LtoH_X_Post84 - FT_LtoL_X_Post84))/3) ///
    , level(95) post

eststo PromWLC

coefplot  ///
    (PromWLC, keep(lc_1) rename(lc_1 = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (PromWLC, keep(lc_2) rename(lc_2 = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (PromWLC, keep(lc_3) rename(lc_3 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    , ciopts(lwidth(2 ..)) levels(95) msymbol(d) mcolor(white) legend(off)  ///
    title("Work-level promotions", size(vlarge)) ///
    graphregion(margin(medium)) plotregion(margin(medium)) xsize(5) ysize(2) ///
    xline(0, lpattern(dash)) ylabel(, labsize(vlarge)) xlabel(, labsize(vlarge)) ///
    xlabel(-0.01(0.01)0.05, labsize(vlarge)) xscale(range(0 0.05)) 

graph export "${Results}/FT_Gains_PromWLC_ThreeQuarterEstimates.png", replace

log close