/* 
This do file runs cross-sectional regressions on a set of transfer outcomes.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0104 do file 

RA: WWZ 
Time: 2024-11-14
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. construct (individual level) event dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers 

*!! calendar time of the event 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. count workers' lateral moves after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! ignore pre-event lateral moves 
generate AE_TransferSJV = TransferSJV
replace  AE_TransferSJV = 0 if AE_TransferSJV==1 & YearMonth<FT_Event_Time

*!! count post-event lateral moves (2 years later)
sort IDlse YearMonth 
bysort IDlse: egen     total_AE_TransferSJV  = total(AE_TransferSJV) if inrange(FT_Rel_Time, 0, 24)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. outcome variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate TransferSJV_0 = (total_AE_TransferSJV==0) if FT_Rel_Time==0
generate TransferSJV_1 = (total_AE_TransferSJV==1) if FT_Rel_Time==0
generate TransferSJV_2 = (total_AE_TransferSJV==2) if FT_Rel_Time==0
generate TransferSJV_3 = (total_AE_TransferSJV==3) if FT_Rel_Time==0

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. keep only a cross-sectional of dataset for four treatment groups
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time==0
    //&? a cross-sectional of event workers: 29,288

order IDlse FT_Event_Time total_AE_TransferSJV FT_LtoL FT_LtoH FT_HtoH FT_HtoL

save "${TempData}/temp_NumberOfLateralMoves_CrossSection_2yrs.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run cross-sectional regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_NumberOfLateralMoves_CrossSection_2yrs.dta", clear 

summarize FT_Event_Time, detail 
global LastMonth = r(max)
global LastPossibleEventTime = ${LastMonth} - 24

matrix Lto_coeff_mat  = J(4, 1, .)
matrix Lto_lb_mat     = J(4, 1, .)
matrix Lto_ub_mat     = J(4, 1, .)

matrix Hto_coeff_mat  = J(4, 1, .)
matrix Hto_lb_mat     = J(4, 1, .)
matrix Hto_ub_mat     = J(4, 1, .)

local i = 1
foreach var in TransferSJV_0 TransferSJV_1 TransferSJV_2 TransferSJV_3 {

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime}, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)
        lincom FT_LtoH
        matrix Lto_coeff_mat[`i',1] = r(estimate)
        matrix Lto_lb_mat[`i',1]    = r(lb)
        matrix Lto_ub_mat[`i',1]    = r(ub)

        lincom (FT_HtoL - FT_HtoH)
        matrix Hto_coeff_mat[`i',1] = r(estimate)
        matrix Hto_lb_mat[`i',1]    = r(lb)
        matrix Hto_ub_mat[`i',1]    = r(ub)

    local i = `i' + 1
}

capture drop times
generate times = _n-1 if inrange(_n, 1, 4)

matrix Lto_final_res = Lto_coeff_mat, Lto_lb_mat, Lto_ub_mat
matrix colnames Lto_final_res = coeff_gains lb_gains ub_gains
svmat  Lto_final_res, names(col)

matrix Hto_final_res = Hto_coeff_mat, Hto_lb_mat, Hto_ub_mat
matrix colnames Hto_final_res = coeff_loss lb_loss ub_loss
svmat  Hto_final_res, names(col)

twoway ///
    (scatter coeff_gains times, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_gains ub_gains times, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) ///
    xlabel(0(1)3) ///
    xtitle("Number of lateral moves within 2 years after the event") ///
    ytitle("Coefficient on LtoH") ///
    legend(off)
graph export "${Results}/FT_Gains_NumberOfLateralMoves_2yrs.pdf", as(pdf) replace 

twoway ///
    (scatter coeff_loss times, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_loss ub_loss times, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) ///
    xlabel(0(1)3) ///
    xtitle("Number of lateral moves within 2 years after the event") ///
    ytitle("Coefficient on HtoL - HtoH") ///
    legend(off)
graph export "${Results}/FT_Loss_NumberOfLateralMoves_2yrs.pdf", as(pdf) replace 

