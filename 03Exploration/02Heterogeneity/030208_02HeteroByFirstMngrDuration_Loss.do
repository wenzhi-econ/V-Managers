/* 
This do file investigates heterogeneity by pre-event manager exposure.

Note:
    (1) This do file focuses on the effect of lossing a high-flyer manager, unlike other results in the heterogeneity table.
    (2) The regression sample only consists of new hires in the sample.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file.

Results:
    "${Results}/HeteroByFirstMngrDuration_Loss.tex"

RA: WWZ 
Time: 2024-11-20
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create the heterogeneity indicator 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. NewHire
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen TenureMin = min(Tenure)

generate NewHire = (TenureMin<=1) if TenureMin!=. 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. ExpoPreMngr
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen long PreMngrID = mean(cond(FT_Rel_Time==-1, IDlseMHR, .))

generate Same_PreMngr = (IDlseMHR==PreMngrID & FT_Rel_Time<0) if IDlseMHR!=.

sort IDlse YearMonth 
bysort IDlse: egen ExpoPreMngr = total(Same_PreMngr) if NewHire==1

order IDlse YearMonth IDlseMHR TenureMin NewHire ExpoPreMngr FT_Rel_Time

keep if NewHire==1
    //&? keep a panel of new hires 
    //&? We can define pre-event manager exposure only 

summarize ExpoPreMngr, detail 
generate HighExpoPreMngr1 = (ExpoPreMngr >= r(p50)) if ExpoPreMngr!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. event-relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! "event * post" (ind-month level) for four treatment groups
generate FT_Post1 = (FT_Rel_Time > 0) if FT_Rel_Time != .
generate FT_LtoLXPost1 = FT_LtoL * FT_Post1
generate FT_LtoHXPost1 = FT_LtoH * FT_Post1
generate FT_HtoHXPost1 = FT_HtoH * FT_Post1
generate FT_HtoLXPost1 = FT_HtoL * FT_Post1

global Hetero_Vars HighExpoPreMngr

foreach var in $Hetero_Vars {
    generate FT_LtoLXPost1X`var' = FT_LtoLXPost1 * `var'1
    generate FT_LtoHXPost1X`var' = FT_LtoHXPost1 * `var'1
    generate FT_HtoHXPost1X`var' = FT_HtoHXPost1 * `var'1
    generate FT_HtoLXPost1X`var' = FT_HtoLXPost1 * `var'1
}

/* 
Notice that the definition of "Post" in the above procedures is a different from the convention: 
    FT_Rel_Time==0 is not included in FT_Post1. 
This is because in the "PromWLC" regression, 
    we need to use month 0 as the reference month 
    (since we only focus on WL1 workers, mechanically leading to no work level promotions before manager change).
This won't affect regressions for other outcome variables, 
    since we never include month 0 in the regressions for these outcomes (ChangeSalaryGradeC TransferSJVC).
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run event-study regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. event-study outcomes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach hetero_var in $Hetero_Vars {
    global hetero_regressors ///
        FT_LtoLXPost1 FT_LtoLXPost1X`hetero_var' ///
        FT_LtoHXPost1 FT_LtoHXPost1X`hetero_var' ///
        FT_HtoHXPost1 FT_HtoHXPost1X`hetero_var' ///
        FT_HtoLXPost1 FT_HtoLXPost1X`hetero_var'


    foreach outcome in ChangeSalaryGradeC TransferSJVC PromWLC {

        *&? For salary change and later move variables, the reference month is -1, -2, -3.
        if "`outcome'" != "PromWLC" {
            reghdfe `outcome' $hetero_regressors  ///
                if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & (NewHire==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
        }

        *&? For work level promotion, due to the nature of the sample restrictions, the reference month is 0.
        if "`outcome'" == "PromWLC" {
            reghdfe `outcome' $hetero_regressors  ///
                if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==0 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & (NewHire==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
        }
    
        xlincom (FT_HtoLXPost1X`hetero_var' - FT_HtoHXPost1X`hetero_var'), level(95) post

        if "`outcome'" == "ChangeSalaryGradeC" {
            local outcome_name CSGC
        }
        if "`outcome'" == "TransferSJVC" {
            local outcome_name TSJVC
        }
        if "`outcome'" == "PromWLC" {
            local outcome_name PWLC
        }

        est store `hetero_var'_`outcome_name'
    }

}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run cross-sectional regressions: exit outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. new variables for event outcomes  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-3-1-1. relative exit time
capture drop Leaver
sort IDlse YearMonth
bysort IDlse: egen Leaver = max(LeaverPerm)

bysort IDlse: egen temp = max(YearMonth)
generate Leave_Time = . 
replace  Leave_Time = temp if Leaver == 1
format Leave_Time %tm
drop temp

generate FT_Rel_Leave_Time = Leave_Time - FT_Event_Time

label variable Leaver            "=1, if the worker left the firm during the dataset period"
label variable Leave_Time        "Time when the worker left the firm, missing if he stays during the sample period"
label variable FT_Rel_Leave_Time "Leave_Time - FT_Event_Time"

*!! s-3-1-2. outcome variable: if the worker left the firm within 2 years after the event
generate LV_2yrs  = inrange(FT_Rel_Leave_Time, 0, 24)

*!! s-3-1-3. event * heterogeneity indicators
foreach var in $Hetero_Vars {
    generate FT_LtoLX`var' = FT_LtoL * `var'1
    generate FT_LtoHX`var' = FT_LtoH * `var'1
    generate FT_HtoHX`var' = FT_HtoH * `var'1
    generate FT_HtoLX`var' = FT_HtoL * `var'1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. keep only a cross-sectional of treated workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if (YearMonth==FT_Event_Time & FT_Never_ChangeM==0)
    //&& keep one observation for one worker,
    //&& keep only treatment workers  
    //&& we are using control variables at the time of treatment for four treatment groups
keep if (FT_Mngr_both_WL2==1 & FT_Never_ChangeM==0)
    //&& use the same sample as the event studies

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. run cross-sectional regressions on exit outcomes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

summarize FT_Event_Time, detail // max: 743
    global LastMonth = r(max)
    global LastPossibleEventTime = ${LastMonth} - 12 * 2 
        //&& only exit outcomes of these workers (whose event dates are before this time) can be correctly identified 

foreach hetero_var in $Hetero_Vars {
    
    global hetero_regressors ///
        FT_LtoLX`hetero_var' ///
        FT_LtoH FT_LtoHX`hetero_var' ///
        FT_HtoH FT_HtoHX`hetero_var' ///
        FT_HtoL FT_HtoLX`hetero_var'

    reghdfe LV_2yrs ${hetero_regressors} if FT_Event_Time<=${LastPossibleEventTime}, ///
        vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)

    xlincom (FT_HtoLX`hetero_var' - FT_HtoHX`hetero_var'), level(95) post

    est store `hetero_var'_Exit
    
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

esttab HighExpoPreMngr_CSGC HighExpoPreMngr_TSJVC HighExpoPreMngr_PWLC HighExpoPreMngr_Exit using "${Results}/HeteroByFirstMngrDuration_Loss.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Exposure with pre-event manager, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    stats(N, labels("Obs") fmt(%9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{Pay increase} & \multicolumn{1}{c}{Lateral moves} & \multicolumn{1}{c}{Vertical moves} & \multicolumn{1}{c}{Exit from firm} \\") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes." "\end{tablenotes}")
    