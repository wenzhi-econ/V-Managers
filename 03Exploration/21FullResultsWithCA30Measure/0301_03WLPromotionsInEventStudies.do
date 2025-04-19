/* 
This do file runs cross-sectional regressions on whether the employee has been promoted to WL2 within given years after the event.
The high-flyer measure used here is CA30.

Input: 
    "${TempData}/FinalAnalysisSample.dta" <== created in 0103_03 do file

Output:
    "${TempData}/0301_03PromToWL2_CrossSection.dta" 
    
Results:
    "${Results}/004ResultsBasedOnCA30/20250417log_CrossSectionalRegressionsWithCA30_Outcome3_WLPromotions.txt"
    "${Results}/004ResultsBasedOnCA30/CA30_PromWL2_Gains.pdf"
    "${Results}/004ResultsBasedOnCA30/CA30_PromWL2_Loss.pdf"

RA: WWZ 
Time: 2025-04-17
*/

capture log close
log using "${Results}/004ResultsBasedOnCA30/20250417log_CrossSectionalRegressionsWithCA30_Outcome3_WLPromotions", replace text

use "${TempData}/FinalAnalysisSample.dta", clear

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain a cross-sectional dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. first time the event worker is WL2 after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen YearMonth_WL2 = min(cond(Post_Event==1 & WL==2, YearMonth, .))
format YearMonth_WL2 %tm 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. relative time from the event time to the promotion time  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Rel_Time_WL2 = YearMonth_WL2 - Event_Time 
summarize Rel_Time_WL2, detail 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. is the promotion within given years after the event  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate WL2_1yr   = inrange(Rel_Time_WL2, 0, 12)
generate WL2_2yrs  = inrange(Rel_Time_WL2, 0, 24)
generate WL2_3yrs  = inrange(Rel_Time_WL2, 0, 36)
generate WL2_4yrs  = inrange(Rel_Time_WL2, 0, 48)
generate WL2_5yrs  = inrange(Rel_Time_WL2, 0, 60)
generate WL2_6yrs  = inrange(Rel_Time_WL2, 0, 72)
generate WL2_7yrs  = inrange(Rel_Time_WL2, 0, 84)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. keep a cross-section of workers   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if YearMonth==Event_Time
    //impt: keep one observation for one worker,
    //&? we are using control variables at the time of treatment for four treatment groups
keep if WL==1
    //impt: note that we keep variables in the event month 
    //&? for this exercise, we require the event worker's work level to be 1 in the event month 

keep ///
    Year YearMonth IDlse IDlseMHR Event_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL ///
    YearMonth_WL2 Rel_Time_WL2 WL2_* ///
    WL Office Func Female AgeBand
order ///
    Year YearMonth IDlse IDlseMHR Event_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL ///
    YearMonth_WL2 Rel_Time_WL2 WL2_* ///
    WL Office Func Female AgeBand
    //&? keep only relevant variables 

label variable YearMonth_WL2 "First year-month when an employee becomes WL2 after the event"
label variable Rel_Time_WL2  "YearMonth_WL2 - Event_Time"
label variable WL2_1yr       "Promoted to WL2 within 1 year after the event"
label variable WL2_2yrs      "Promoted to WL2 within 2 years after the event"
label variable WL2_3yrs      "Promoted to WL2 within 3 years after the event"
label variable WL2_4yrs      "Promoted to WL2 within 4 years after the event"
label variable WL2_5yrs      "Promoted to WL2 within 5 years after the event"
label variable WL2_6yrs      "Promoted to WL2 within 6 years after the event"
label variable WL2_7yrs      "Promoted to WL2 within 7 years after the event"

save "${TempData}/0301_03PromToWL2_CrossSection.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0301_03PromToWL2_CrossSection.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. preparation for storing the results  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

matrix Lto_coeff_mat  = J(10, 1, .)
matrix Lto_lb_mat     = J(10, 1, .)
matrix Lto_ub_mat     = J(10, 1, .)

matrix Hto_coeff_mat  = J(10, 1, .)
matrix Hto_lb_mat     = J(10, 1, .)
matrix Hto_ub_mat     = J(10, 1, .)

generate year = _n if inrange(_n, 1, 10)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. run regressions and store results in matrices  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global prom_outcomes WL2_1yr WL2_2yrs WL2_3yrs WL2_4yrs WL2_5yrs WL2_6yrs WL2_7yrs 

summarize Event_Time, detail // max: 743
global LastMonth = r(max)
    //&? Note that we need to consider the time constraint due to the right-censoring nature of the dataset

local i = 1
foreach var in $prom_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' CA30_LtoH CA30_HtoH CA30_HtoL if Event_Time<=${LastPossibleEventTime}, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female Event_Time)

        lincom CA30_LtoH
        matrix Lto_coeff_mat[`i',1] = r(estimate)
        matrix Lto_lb_mat[`i',1]    = r(lb)
        matrix Lto_ub_mat[`i',1]    = r(ub)

        lincom (CA30_HtoL - CA30_HtoH)
        matrix Hto_coeff_mat[`i',1] = r(estimate)
        matrix Hto_lb_mat[`i',1]    = r(lb)
        matrix Hto_ub_mat[`i',1]    = r(ub)

    local i  = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. transform matrices into variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

matrix Lto_final_res = Lto_coeff_mat, Lto_lb_mat, Lto_ub_mat
matrix colnames Lto_final_res = coeff_gains_Inv lb_gains_Inv ub_gains_Inv
svmat  Lto_final_res, names(col)

matrix Hto_final_res = Hto_coeff_mat, Hto_lb_mat, Hto_ub_mat
matrix colnames Hto_final_res = coeff_loss_Inv lb_loss_Inv ub_loss_Inv
svmat  Hto_final_res, names(col)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. plot the results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

twoway ///
    (scatter coeff_gains_Inv year if inrange(year, 1, 7), lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_gains_Inv ub_gains_Inv year if inrange(year, 1, 7), lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) yscale(range(-0.06 0.06)) ylabel(-0.06(0.02)0.06, grid gstyle(dot) labsize(medsmall)) ///
    xlabel(1(1)7, labsize(medsmall)) ///
    xtitle(Years since manager change) title("Promotion to work level 2 within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/004ResultsBasedOnCA30/CA30_PromWL2_Gains.pdf", as(pdf) replace 

twoway ///
    (scatter coeff_loss_Inv year if inrange(year, 1, 7), lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_loss_Inv ub_loss_Inv year if inrange(year, 1, 7), lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) yscale(range(-0.06 0.06)) ylabel(-0.06(0.02)0.06, grid gstyle(dot) labsize(medsmall)) ///
    xlabel(1(1)7, labsize(medsmall)) ///
    xtitle(Years since manager change) title("Exit within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/004ResultsBasedOnCA30/CA30_PromWL2_Loss.pdf", as(pdf) replace 


log close
