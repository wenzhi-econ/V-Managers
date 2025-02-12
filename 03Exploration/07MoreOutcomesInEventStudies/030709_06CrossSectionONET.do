/* 
This do file runs a cross-sectional regression on employees' task content change following the manager change event.

RA: WWZ
Time: 2025-02-11
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. obtain the final dataset for the event studies
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. merge the task intensity measures into the main dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep a panel of event workers 

keep IDlse YearMonth IDlseMHR EarlyAgeM ChangeM ChangeMR FT_* StandardJob Office Func AgeBand Female Country 

merge m:1 StandardJob using "${TempData}/temp_ONET_FinalJobLevelPrank.dta"
    keep if _merge==3
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                       589,258
        from master                   589,114  
        from using                        144  

    Matched                         1,313,301  
    -----------------------------------------
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-2. distance measure (naive difference for all three tasks) 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 

sort IDlse YearMonth
bysort IDlse: generate dist_cognitive = prank_cognitive[_n] - prank_cognitive[_n-1]
replace dist_cognitive = 0 if occurrence==1

sort IDlse YearMonth
bysort IDlse: generate dist_routine = prank_routine[_n] - prank_routine[_n-1]
replace dist_routine = 0 if occurrence==1

sort IDlse YearMonth
bysort IDlse: generate dist_social = prank_social[_n] - prank_social[_n-1]
replace dist_social = 0 if occurrence==1

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-3. whether the worker experiences a task intensity change
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

foreach var in cognitive routine social {

    bysort IDlse: egen min_`var'_1yr = min(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+12, dist_`var', .))
    bysort IDlse: egen max_`var'_1yr = max(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+12, dist_`var', .))

    bysort IDlse: egen min_`var'_2yr = min(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+24, dist_`var', .))
    bysort IDlse: egen max_`var'_2yr = max(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+24, dist_`var', .))

    bysort IDlse: egen min_`var'_3yr = min(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+36, dist_`var', .))
    bysort IDlse: egen max_`var'_3yr = max(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+36, dist_`var', .))

    bysort IDlse: egen min_`var'_4yr = min(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+48, dist_`var', .))
    bysort IDlse: egen max_`var'_4yr = max(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+48, dist_`var', .))

    bysort IDlse: egen min_`var'_5yr = min(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+60, dist_`var', .))
    bysort IDlse: egen max_`var'_5yr = max(cond(FT_Rel_Time>=0 & YearMonth<=FT_Event_Time+60, dist_`var', .))
}

foreach var in cognitive routine social {
    generate increase_`var'_1yr = (max_`var'_1yr>0) if max_`var'_1yr!=.
    generate decrease_`var'_1yr = (min_`var'_1yr<0) if min_`var'_1yr!=.

    generate increase_`var'_2yr = (max_`var'_2yr>0) if max_`var'_2yr!=.
    generate decrease_`var'_2yr = (min_`var'_2yr<0) if min_`var'_2yr!=.
    
    generate increase_`var'_3yr = (max_`var'_3yr>0) if max_`var'_3yr!=.
    generate decrease_`var'_3yr = (min_`var'_3yr<0) if min_`var'_3yr!=.
    
    generate increase_`var'_4yr = (max_`var'_4yr>0) if max_`var'_4yr!=.
    generate decrease_`var'_4yr = (min_`var'_4yr<0) if min_`var'_4yr!=.
    
    generate increase_`var'_5yr = (max_`var'_5yr>0) if max_`var'_5yr!=.
    generate decrease_`var'_5yr = (min_`var'_5yr<0) if min_`var'_5yr!=.
}

    //&? Notice that the increase and decrease variables are not mutually exclusive.
    //&? If a worker changes multiple ONET occupations within a time period, 
    //&? he can have both increase and decrease variables equal to 1.

sort IDlse YearMonth
bysort IDlse: egen max_YearMonth = max(YearMonth)

generate q_unidentified_1yr = (max_YearMonth<FT_Event_Time+12)
generate q_unidentified_2yr = (max_YearMonth<FT_Event_Time+24)
generate q_unidentified_3yr = (max_YearMonth<FT_Event_Time+36)
generate q_unidentified_4yr = (max_YearMonth<FT_Event_Time+48)
generate q_unidentified_5yr = (max_YearMonth<FT_Event_Time+60)

foreach var in cognitive routine social {
    replace increase_`var'_1yr = . if q_unidentified_1yr==1
    replace decrease_`var'_1yr = . if q_unidentified_1yr==1

    replace increase_`var'_2yr = . if q_unidentified_2yr==1
    replace decrease_`var'_2yr = . if q_unidentified_2yr==1

    replace increase_`var'_3yr = . if q_unidentified_3yr==1
    replace decrease_`var'_3yr = . if q_unidentified_3yr==1

    replace increase_`var'_4yr = . if q_unidentified_4yr==1
    replace decrease_`var'_4yr = . if q_unidentified_4yr==1

    replace increase_`var'_5yr = . if q_unidentified_5yr==1
    replace decrease_`var'_5yr = . if q_unidentified_5yr==1
}
    //&? For some late events, we cannot identify the workers' task intensity changes in the future, 
    //&? as the dataset is right censored by nature.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-4. a simplified dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    IDlse YearMonth IDlseMHR EarlyAgeM ChangeM ChangeMR ///
    FT_* Office Func AgeBand Female Country ///
    increase_* decrease_*

keep if FT_Rel_Time==0
    //&? keep only a cross-sectional of workers 
    //&? 22,694 unique event workers 

save "${TempData}/temp_ONET_CrossSectionRegressions.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. cross sectional regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_ONET_CrossSectionRegressions.dta", clear 
label variable FT_LtoL "LtoL"
label variable FT_LtoH "LtoH"
label variable FT_HtoL "HtoL"
label variable FT_HtoH "HtoH"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. cognitive task 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global cognitive_vars ///
    increase_cognitive_1yr increase_cognitive_2yr increase_cognitive_3yr increase_cognitive_4yr increase_cognitive_5yr ///
    decrease_cognitive_1yr decrease_cognitive_2yr decrease_cognitive_3yr decrease_cognitive_4yr decrease_cognitive_5yr

foreach var in $cognitive_vars {
    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'
        summarize `var' if e(sample)==1 & FT_LtoL==1
            local mean_LtoL = r(mean)
            estadd scalar mean_LtoL = `mean_LtoL'
}

esttab $cognitive_vars using "${Results}/ONETCrossSection_cognitive.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 mean_LtoL N, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Mean, LtoL" "Obs") fmt(%9.0g %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{5}{c}{Increase in cognitive task intensity} & \multicolumn{5}{c}{Decrease in cognitive task intensity} \\" "\addlinespace[10pt] \cmidrule(lr){2-6} \cmidrule(lr){7-11} \\" "& \multicolumn{1}{c}{Within 1yr} & \multicolumn{1}{c}{Within 2yrs}  & \multicolumn{1}{c}{Within 3yrs}  & \multicolumn{1}{c}{Within 4yrs}  & \multicolumn{1}{c}{Within 5yrs} & \multicolumn{1}{c}{Within 1yr} & \multicolumn{1}{c}{Within 2yrs}  & \multicolumn{1}{c}{Within 3yrs}  & \multicolumn{1}{c}{Within 4yrs}  & \multicolumn{1}{c}{Within 5yrs} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample is a cross-sectional of treatment workers who are in the event study. Only those workers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the worker has increased or decreased the cognitive task intensity within given years after the event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. routine task 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global routine_vars ///
    increase_routine_1yr increase_routine_2yr increase_routine_3yr increase_routine_4yr increase_routine_5yr ///
    decrease_routine_1yr decrease_routine_2yr decrease_routine_3yr decrease_routine_4yr decrease_routine_5yr

foreach var in $routine_vars {
    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'
        summarize `var' if e(sample)==1 & FT_LtoL==1
            local mean_LtoL = r(mean)
            estadd scalar mean_LtoL = `mean_LtoL'
}

esttab $routine_vars using "${Results}/ONETCrossSection_routine.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 mean_LtoL N, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Mean, LtoL" "Obs") fmt(%9.0g %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{5}{c}{Increase in routine task intensity} & \multicolumn{5}{c}{Decrease in routine task intensity} \\" "\addlinespace[10pt] \cmidrule(lr){2-6} \cmidrule(lr){7-11} \\" "& \multicolumn{1}{c}{Within 1yr} & \multicolumn{1}{c}{Within 2yrs}  & \multicolumn{1}{c}{Within 3yrs}  & \multicolumn{1}{c}{Within 4yrs}  & \multicolumn{1}{c}{Within 5yrs} & \multicolumn{1}{c}{Within 1yr} & \multicolumn{1}{c}{Within 2yrs}  & \multicolumn{1}{c}{Within 3yrs}  & \multicolumn{1}{c}{Within 4yrs}  & \multicolumn{1}{c}{Within 5yrs} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample is a cross-sectional of treatment workers who are in the event study. Only those workers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the worker has increased or decreased the routine task intensity within given years after the event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. social task 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global social_vars ///
    increase_social_1yr increase_social_2yr increase_social_3yr increase_social_4yr increase_social_5yr ///
    decrease_social_1yr decrease_social_2yr decrease_social_3yr decrease_social_4yr decrease_social_5yr

foreach var in $social_vars {
    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'
        summarize `var' if e(sample)==1 & FT_LtoL==1
            local mean_LtoL = r(mean)
            estadd scalar mean_LtoL = `mean_LtoL'
}

esttab $social_vars using "${Results}/ONETCrossSection_social.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 mean_LtoL N, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Mean, LtoL" "Obs") fmt(%9.0g %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccccc}" "\toprule" "\toprule" "& \multicolumn{5}{c}{Increase in social task intensity} & \multicolumn{5}{c}{Decrease in social task intensity} \\" "\addlinespace[10pt] \cmidrule(lr){2-6} \cmidrule(lr){7-11} \\" "& \multicolumn{1}{c}{Within 1yr} & \multicolumn{1}{c}{Within 2yrs}  & \multicolumn{1}{c}{Within 3yrs}  & \multicolumn{1}{c}{Within 4yrs}  & \multicolumn{1}{c}{Within 5yrs} & \multicolumn{1}{c}{Within 1yr} & \multicolumn{1}{c}{Within 2yrs}  & \multicolumn{1}{c}{Within 3yrs}  & \multicolumn{1}{c}{Within 4yrs}  & \multicolumn{1}{c}{Within 5yrs} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample is a cross-sectional of treatment workers who are in the event study. Only those workers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the worker has increased or decreased the social task intensity within given years after the event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

