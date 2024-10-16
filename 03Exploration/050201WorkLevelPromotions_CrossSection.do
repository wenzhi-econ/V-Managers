/* 
This do file compares employees' promotion results between LtoL group and LtoH group, and between HtoL group and HtoH group.

RA: WWZ 
Time: 2024-10-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a simplified dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/03MainOutcomesInEventStudies_EarlyAgeM_HF2M_HF2SM.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    PromWL PromWLC ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL ///
    Office Func AgeBand Female

order ///
    PromWL PromWLC ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    Office Func AgeBand Female

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. construct (individual level) event dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! calendar time of the event 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. time when getting a promotion 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen total_PromWL = total(PromWL)
order total_PromWL, after(PromWLC)

*!! total number of work level promotions (workers of interest)
summarize total_PromWL if inrange(FT_Rel_Time, -1, 0) & FT_Mngr_both_WL2==1 
    //&& max: 2
    //&& Therefore, I only need two variables to store promotion dates. 

*!! promotion date 
sort IDlse YearMonth
bysort IDlse: egen PromWL_Date1 = min(cond(PromWL==1, YearMonth, .))
bysort IDlse: egen PromWL_Date2 = max(cond(PromWL==1, YearMonth, .))
order PromWL_Date1 PromWL_Date2, after(PromWLC)
format PromWL_Date1 %tm
format PromWL_Date2 %tm

*!! relative promotion date 
sort IDlse YearMonth
generate FT_Rel_PromWL_Date1 = PromWL_Date1 - FT_Event_Time
generate FT_Rel_PromWL_Date2 = PromWL_Date2 - FT_Event_Time
order FT_Rel_PromWL_Date1 FT_Rel_PromWL_Date2, after(PromWL_Date2)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. outcome variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Prom_1yr   = (inrange(FT_Rel_PromWL_Date1, 0, 12) | inrange(FT_Rel_PromWL_Date2, 0, 12))
generate Prom_2yrs  = (inrange(FT_Rel_PromWL_Date1, 0, 24) | inrange(FT_Rel_PromWL_Date2, 0, 24))
generate Prom_3yrs  = (inrange(FT_Rel_PromWL_Date1, 0, 36) | inrange(FT_Rel_PromWL_Date2, 0, 36))
generate Prom_4yrs  = (inrange(FT_Rel_PromWL_Date1, 0, 48) | inrange(FT_Rel_PromWL_Date2, 0, 48))
generate Prom_5yrs  = (inrange(FT_Rel_PromWL_Date1, 0, 60) | inrange(FT_Rel_PromWL_Date2, 0, 60))
generate Prom_6yrs  = (inrange(FT_Rel_PromWL_Date1, 0, 72) | inrange(FT_Rel_PromWL_Date2, 0, 72))
generate Prom_7yrs  = (inrange(FT_Rel_PromWL_Date1, 0, 84) | inrange(FT_Rel_PromWL_Date2, 0, 84))
generate Prom_8yrs  = (inrange(FT_Rel_PromWL_Date1, 0, 96) | inrange(FT_Rel_PromWL_Date2, 0, 96))
generate Prom_9yrs  = (inrange(FT_Rel_PromWL_Date1, 0, 108) | inrange(FT_Rel_PromWL_Date2, 0, 108))
generate Prom_10yrs = (inrange(FT_Rel_PromWL_Date1, 0, 120) | inrange(FT_Rel_PromWL_Date2, 0, 120))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_5. keep only a cross-sectional of dataset for four treatment groups
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: generate occurrence = _n 

keep if (YearMonth==FT_Event_Time & FT_Never_ChangeM==0)
    //&& keep one observation for one worker,
    //&& keep only treatment workers  
    //&& we are using control variables at the time of treatment for four treatment groups
keep if (FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0)
    //&& use the same sample as the event studies

save "${TempData}/temp_PromotionOutcomes.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions (cross-sectional)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close

log using "${Results}/logfile_20241014_PromotionOutcomes", replace text

use "${TempData}/temp_PromotionOutcomes.dta", clear 

*&& Note that we need to consider the time constraint due to the right-censoring nature of the dataset
summarize FT_Event_Time, detail // max: 743
global LastMonth = r(max)

global exit_outcomes Prom_1yr Prom_2yrs Prom_3yrs Prom_4yrs Prom_5yrs Prom_6yrs Prom_7yrs Prom_8yrs Prom_9yrs Prom_10yrs

label variable FT_LtoL "LtoL"
label variable FT_LtoH "LtoH"
label variable FT_HtoH "HtoH"
label variable FT_HtoL "HtoL"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. produce two figures   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

matrix Lto_coeff_mat  = J(10, 1, .)
matrix Lto_lb_mat     = J(10, 1, .)
matrix Lto_ub_mat     = J(10, 1, .)

matrix Hto_coeff_mat  = J(10, 1, .)
matrix Hto_lb_mat     = J(10, 1, .)
matrix Hto_ub_mat     = J(10, 1, .)

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime}, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female)

        lincom FT_LtoH
        matrix Lto_coeff_mat[`i',1] = r(estimate)
        matrix Lto_lb_mat[`i',1]    = r(lb)
        matrix Lto_ub_mat[`i',1]    = r(ub)

        lincom (FT_HtoL - FT_HtoH)
        matrix Hto_coeff_mat[`i',1] = r(estimate)
        matrix Hto_lb_mat[`i',1]    = r(lb)
        matrix Hto_ub_mat[`i',1]    = r(ub)

    local i  = `i' + 1
}

generate year = _n if inrange(_n, 1, 10)

matrix Lto_final_res = Lto_coeff_mat, Lto_lb_mat, Lto_ub_mat
matrix colnames Lto_final_res = coeff_gains lb_gains ub_gains
svmat  Lto_final_res, names(col)

matrix Hto_final_res = Hto_coeff_mat, Hto_lb_mat, Hto_ub_mat
matrix colnames Hto_final_res = coeff_loss lb_loss ub_loss
svmat  Hto_final_res, names(col)

twoway ///
    (scatter coeff_gains year, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_gains ub_gains year, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) ///
    xlabel(1(1)10) ///
    xtitle(Years since manager change) title("Work level promotions within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/FT_Gains_PromWL.png", as(png) replace 

twoway ///
    (scatter coeff_loss year, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_loss ub_loss year, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) ///
    xlabel(1(1)10) ///
    xtitle(Years since manager change) title("Work level promotions within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/FT_Loss_PromWL.png", as(png) replace 

log close