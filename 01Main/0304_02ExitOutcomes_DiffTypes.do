/* 
This do file compares employees' retention results (voluntary vs involuntary exits) between LtoL group and LtoH group, and between HtoL group and HtoH group.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== constructed in 0104 do file 

Results:
    "${Results}/FT_Gains_ExitInv.pdf"
    "${Results}/FT_Loss_ExitInv.pdf"
    "${Results}/FT_Gains_ExitVol.pdf"
    "${Results}/FT_Loss_ExitVol.pdf"

RA: WWZ 
Time: 2024-10-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a simplified dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    LeaverInv LeaverVol ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL ///
    Office Func AgeBand Female

order ///
    LeaverInv LeaverVol ///
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
*-? s-1-3. time when involuntarily leaving the firm
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

rename LeaverInv raw_LeaverInv

sort IDlse YearMonth
bysort IDlse: egen LeaverInv = max(raw_LeaverInv)

sort IDlse YearMonth
bysort IDlse: egen temp = max(YearMonth)
generate LeaveInv_Time = . 
replace  LeaveInv_Time = temp if LeaverInv == 1
format LeaveInv_Time %tm
drop temp

generate FT_Rel_LeaveInv_Time = LeaveInv_Time - FT_Event_Time

label variable LeaverInv            "=1, if the worker involuntarily left the firm during the dataset period"
label variable LeaveInv_Time        "Time when the worker involuntarily left the firm"
label variable FT_Rel_LeaveInv_Time "LeaveInv_Time - FT_Event_Time"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. time when voluntarily leaving the firm
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

rename LeaverVol raw_LeaverVol

sort IDlse YearMonth
bysort IDlse: egen LeaverVol = max(raw_LeaverVol)

sort IDlse YearMonth
bysort IDlse: egen temp = max(YearMonth)
generate LeaveVol_Time = . 
replace  LeaveVol_Time = temp if LeaverVol == 1
format LeaveVol_Time %tm
drop temp

generate FT_Rel_LeaveVol_Time = LeaveVol_Time - FT_Event_Time

order IDlse YearMonth LeaverInv LeaveInv_Time FT_Rel_LeaveInv_Time LeaverVol LeaveVol_Time  FT_Rel_LeaveVol_Time

label variable LeaverVol            "=1, if the worker involuntarily left the firm during the dataset period"
label variable LeaveVol_Time        "Time when the worker involuntarily left the firm"
label variable FT_Rel_LeaveVol_Time "LeaveVol_Time - FT_Event_Time"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. outcome variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate LVInv_1yr   = inrange(FT_Rel_LeaveInv_Time, 0, 12)
generate LVInv_2yrs  = inrange(FT_Rel_LeaveInv_Time, 0, 24)
generate LVInv_3yrs  = inrange(FT_Rel_LeaveInv_Time, 0, 36)
generate LVInv_4yrs  = inrange(FT_Rel_LeaveInv_Time, 0, 48)
generate LVInv_5yrs  = inrange(FT_Rel_LeaveInv_Time, 0, 60)

generate LVVol_1yr   = inrange(FT_Rel_LeaveVol_Time, 0, 12)
generate LVVol_2yrs  = inrange(FT_Rel_LeaveVol_Time, 0, 24)
generate LVVol_3yrs  = inrange(FT_Rel_LeaveVol_Time, 0, 36)
generate LVVol_4yrs  = inrange(FT_Rel_LeaveVol_Time, 0, 48)
generate LVVol_5yrs  = inrange(FT_Rel_LeaveVol_Time, 0, 60)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_5. keep only a cross-sectional of dataset for four treatment groups
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if (YearMonth==FT_Event_Time & FT_Never_ChangeM==0)
    //&& keep one observation for one worker,
    //&& keep only treatment workers  
    //&& we are using control variables at the time of treatment for four treatment groups
keep if (FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0)
    //&& use the same sample as the event studies

save "${TempData}/temp_ExitOutcomes_DiffTypes.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions (cross-sectional)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close

log using "${Results}/logfile_20241127_ExitOutcomes_DiffTypes", replace text

use "${TempData}/temp_ExitOutcomes_DiffTypes.dta", clear 

generate year = _n if inrange(_n, 1, 10)

label variable FT_LtoL "LtoL"
label variable FT_LtoH "LtoH"
label variable FT_HtoH "HtoH"
label variable FT_HtoL "HtoL"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. Inv 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global exit_outcomes LVInv_1yr LVInv_2yrs LVInv_3yrs LVInv_4yrs LVInv_5yrs 

*&& Note that we need to consider the time constraint due to the right-censoring nature of the dataset
summarize FT_Event_Time, detail // max: 743
global LastMonth = r(max)

matrix Lto_coeff_mat  = J(10, 1, .)
matrix Lto_lb_mat     = J(10, 1, .)
matrix Lto_ub_mat     = J(10, 1, .)

matrix Hto_coeff_mat  = J(10, 1, .)
matrix Hto_lb_mat     = J(10, 1, .)
matrix Hto_ub_mat     = J(10, 1, .)

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime}, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)

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

matrix Lto_final_res = Lto_coeff_mat, Lto_lb_mat, Lto_ub_mat
matrix colnames Lto_final_res = coeff_gains_Inv lb_gains_Inv ub_gains_Inv
svmat  Lto_final_res, names(col)

matrix Hto_final_res = Hto_coeff_mat, Hto_lb_mat, Hto_ub_mat
matrix colnames Hto_final_res = coeff_loss_Inv lb_loss_Inv ub_loss_Inv
svmat  Hto_final_res, names(col)

twoway ///
    (scatter coeff_gains_Inv year if inrange(year, 1, 5), lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_gains_Inv ub_gains_Inv year if inrange(year, 1, 5), lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) yscale(range(-0.06 0.06)) ylabel(-0.06(0.02)0.06) ///
    xlabel(1(1)5) ///
    xtitle(Years since manager change) title("Exit within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/FT_Gains_ExitInv.pdf", as(pdf) replace 

twoway ///
    (scatter coeff_loss_Inv year if inrange(year, 1, 5), lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_loss_Inv ub_loss_Inv year if inrange(year, 1, 5), lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) yscale(range(-0.06 0.06)) ylabel(-0.06(0.02)0.06) ///
    xlabel(1(1)5) ///
    xtitle(Years since manager change) title("Exit within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/FT_Loss_ExitInv.pdf", as(pdf) replace 



local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & FT_Never_ChangeM==0, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'

    local i  = `i' + 1
}

esttab $exit_outcomes using "${Results}/ExitOutcomes_Inv_CrossSectionRegressions.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 N, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Obs") fmt(%9.0g %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Layoff 1yr} & \multicolumn{1}{c}{Layoff 2yrs}  & \multicolumn{1}{c}{Layoff 3yrs}  & \multicolumn{1}{c}{Layoff 4yrs}  & \multicolumn{1}{c}{Layoff 5yrs}  \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample is a cross-sectional of treatment workers who are in the event study. Only those workers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. Vol 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global exit_outcomes LVVol_1yr LVVol_2yrs LVVol_3yrs LVVol_4yrs LVVol_5yrs 

*&& Note that we need to consider the time constraint due to the right-censoring nature of the dataset
summarize FT_Event_Time, detail // max: 743
global LastMonth = r(max)

matrix Lto_coeff_mat  = J(10, 1, .)
matrix Lto_lb_mat     = J(10, 1, .)
matrix Lto_ub_mat     = J(10, 1, .)

matrix Hto_coeff_mat  = J(10, 1, .)
matrix Hto_lb_mat     = J(10, 1, .)
matrix Hto_ub_mat     = J(10, 1, .)

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime}, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)

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

matrix Lto_final_res = Lto_coeff_mat, Lto_lb_mat, Lto_ub_mat
matrix colnames Lto_final_res = coeff_gains_Vol lb_gains_Vol ub_gains_Vol
svmat  Lto_final_res, names(col)

matrix Hto_final_res = Hto_coeff_mat, Hto_lb_mat, Hto_ub_mat
matrix colnames Hto_final_res = coeff_loss_Vol lb_loss_Vol ub_loss_Vol
svmat  Hto_final_res, names(col)

twoway ///
    (scatter coeff_gains_Vol year if inrange(year, 1, 5), lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_gains_Vol ub_gains_Vol year if inrange(year, 1, 5), lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) yscale(range(-0.06 0.06)) ylabel(-0.06(0.02)0.06) ///
    xlabel(1(1)5) ///
    xtitle(Years since manager change) title("Exit within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/FT_Gains_ExitVol.pdf", as(pdf) replace 

twoway ///
    (scatter coeff_loss_Vol year if inrange(year, 1, 5), lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_loss_Vol ub_loss_Vol year if inrange(year, 1, 5), lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) yscale(range(-0.06 0.06)) ylabel(-0.06(0.02)0.06) ///
    xlabel(1(1)5) ///
    xtitle(Years since manager change) title("Exit within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/FT_Loss_ExitVol.pdf", as(pdf) replace 


local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & FT_Never_ChangeM==0, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'

    local i  = `i' + 1
}

esttab $exit_outcomes using "${Results}/ExitOutcomes_Vol_CrossSectionRegressions.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 N, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Obs") fmt(%9.0g %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Quit 1yr} & \multicolumn{1}{c}{Quit 2yrs}  & \multicolumn{1}{c}{Quit 3yrs}  & \multicolumn{1}{c}{Quit 4yrs}  & \multicolumn{1}{c}{Quit 5yrs}  \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample is a cross-sectional of treatment workers who are in the event study. Only those workers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

log close