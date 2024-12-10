/* 
This do file compares employees' retention results between LtoL group and LtoH group, and between HtoL group and HtoH group.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== constructed in 0104 do file 

Results:
    "${Results}/FT_Gains_Exit.pdf"
    "${Results}/FT_Loss_Exit.pdf"

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
    LeaverPerm ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL ///
    Office Func AgeBand Female

order ///
    LeaverPerm ///
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
*-? s-1-3. time when leaving the firm
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

bysort IDlse: egen Leaver = max(LeaverPerm)

bysort IDlse: egen temp = max(YearMonth)
generate Leave_Time = . 
replace  Leave_Time = temp if Leaver == 1
format Leave_Time %tm
drop temp

generate FT_Rel_Leave_Time = Leave_Time - FT_Event_Time

order IDlse YearMonth LeaverPerm Leaver Leave_Time FT_Event_Time FT_Rel_Leave_Time

label variable Leaver            "=1, if the worker left the firm during the dataset period"
label variable Leave_Time        "Time when the worker left the firm, missing if he stays during the sample period"
label variable FT_Rel_Leave_Time "Leave_Time - FT_Event_Time"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. outcome variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate LV_1yr   = inrange(FT_Rel_Leave_Time, 0, 12)
generate LV_2yrs  = inrange(FT_Rel_Leave_Time, 0, 24)
generate LV_3yrs  = inrange(FT_Rel_Leave_Time, 0, 36)
generate LV_4yrs  = inrange(FT_Rel_Leave_Time, 0, 48)
generate LV_5yrs  = inrange(FT_Rel_Leave_Time, 0, 60)

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

keep  IDlse FT_LtoL FT_LtoH FT_HtoL FT_HtoH FT_Never_ChangeM FT_Event_Time Leaver Leave_Time FT_Rel_Leave_Time LV_* Office Func AgeBand Female IDlseMHR
order IDlse FT_LtoL FT_LtoH FT_HtoL FT_HtoH FT_Never_ChangeM FT_Event_Time Leaver Leave_Time FT_Rel_Leave_Time LV_* Office Func AgeBand Female IDlseMHR

save "${TempData}/temp_ExitOutcomes.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions (cross-sectional)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close

log using "${Results}/logfile_20241127_ExitOutcomes", replace text

use "${TempData}/temp_ExitOutcomes.dta", clear 

*&& Note that we need to consider the time constraint due to the right-censoring nature of the dataset
summarize FT_Event_Time, detail // max: 743
global LastMonth = r(max)

global exit_outcomes LV_1yr LV_2yrs LV_3yrs LV_4yrs LV_5yrs 
label variable FT_LtoL "LtoL"
label variable FT_LtoH "LtoH"
label variable FT_HtoH "HtoH"
label variable FT_HtoL "HtoL"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. produce a table 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime} & FT_Never_ChangeM==0, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'

    local i  = `i' + 1
}

esttab $exit_outcomes using "${Results}/ExitOutcomes_CrossSectionRegressions.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 N, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Obs") fmt(%9.0g %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample is a cross-sectional of treatment workers who are in the event study. Only those workers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the worker left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. produce two figures   
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

generate year = _n if inrange(_n, 1, 10)

matrix Lto_final_res = Lto_coeff_mat, Lto_lb_mat, Lto_ub_mat
matrix colnames Lto_final_res = coeff_gains lb_gains ub_gains
svmat  Lto_final_res, names(col)

matrix Hto_final_res = Hto_coeff_mat, Hto_lb_mat, Hto_ub_mat
matrix colnames Hto_final_res = coeff_loss lb_loss ub_loss
svmat  Hto_final_res, names(col)

twoway ///
    (scatter coeff_gains year if inrange(year, 1, 5), lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_gains ub_gains year if inrange(year, 1, 5), lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) yscale(range(-0.06 0.06)) ylabel(-0.06(0.02)0.06, grid gstyle(dot) labsize(medsmall)) ///
    xlabel(1(1)5, labsize(medsmall)) ///
    xtitle(Years since manager change) title("Exit within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/FT_Gains_Exit.pdf", as(pdf) replace 

twoway ///
    (scatter coeff_loss year if inrange(year, 1, 5), lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_loss ub_loss year if inrange(year, 1, 5), lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) yscale(range(-0.06 0.06)) ylabel(-0.06(0.02)0.06, grid gstyle(dot) labsize(medsmall)) ///
    xlabel(1(1)5, labsize(medsmall)) ///
    xtitle(Years since manager change) title("Exit within given years after the event", span pos(12)) ///
    legend(off)
graph export "${Results}/FT_Loss_Exit.pdf", as(pdf) replace 

log close