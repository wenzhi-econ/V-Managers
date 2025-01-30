/* 
This do file investigates post event managers' exit rates, separately for different event groups.

RA: WWZ 
Time: 2025-01-06
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of post-event managers 
*??         and their earliest involved event dates 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers 

keep if FT_Rel_Time==0
    //&? a cross-sectional of event workers (at the time of event)

keep IDlseMHR YearMonth
duplicates drop 
    //&? all relevant (post-event manager, event time) pairs

sort IDlseMHR YearMonth
bysort IDlseMHR: egen min_EventTime = min(YearMonth)
format min_EventTime %tm
keep if YearMonth == min_EventTime
    //&? a cross-sectional of post-event managers

keep IDlseMHR min_EventTime
    //&? a list of post-event managers, and their earliest involved event dates 
    //&? 10,423 different managers

save "${TempData}/temp_PostEventMngrs.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. collect post-event managers' exit outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 
drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrs.dta", keep(match) nogenerate
    //&? a full panel of relevant post-event managers 

keep if YearMonth >= min_EventTime
    //&? count the duration from the event time onwards

keep IDlseMHR YearMonth min_EventTime LeaverPerm Office Func Female AgeBand

sort IDlseMHR YearMonth
bysort IDlseMHR: egen Leaver   = max(LeaverPerm)
bysort IDlseMHR: egen Leave_YM = min(cond(LeaverPerm==1, YearMonth, .))
format Leave_YM %tm

generate Rel_Leave_YM = Leave_YM - min_EventTime

generate LV_1yr   = inrange(Rel_Leave_YM, 0, 12)
generate LV_2yrs  = inrange(Rel_Leave_YM, 0, 24)
generate LV_3yrs  = inrange(Rel_Leave_YM, 0, 36)
generate LV_4yrs  = inrange(Rel_Leave_YM, 0, 48)
generate LV_5yrs  = inrange(Rel_Leave_YM, 0, 60)

keep IDlseMHR YearMonth min_EventTime Leaver Leave_YM Rel_Leave_YM LV_1yr LV_2yrs LV_3yrs LV_4yrs LV_5yrs Office Func Female AgeBand

keep if YearMonth == min_EventTime
    //&? a cross-section of post-event managers and their exit outcomes

save "${TempData}/temp_PostEventMngrsExitOutcomes.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. find out managers' event groups  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers 

keep if FT_Rel_Time==0
    //&? a cross-sectional of event workers (at the time of event)

keep IDlseMHR FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time

merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrsExitOutcomes.dta", keep(match) nogenerate

save "${TempData}/temp_PostEventMngrsExitOutcomesEventGroups.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. average exit rates by event groups  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize Leaver if FT_LtoL==1, detail // mean: .5058745

summarize Leaver if FT_LtoH==1, detail // mean: .6036644

summarize Leaver if FT_HtoH==1, detail // mean: .5367941

summarize Leaver if FT_HtoL==1, detail // mean: .4376751

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. regress exit outcomes on event group identifiers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_PostEventMngrsExitOutcomesEventGroups.dta", clear 

global LastMonth = 743 
global exit_outcomes LV_1yr LV_2yrs LV_3yrs LV_4yrs LV_5yrs 

label variable FT_LtoL "LtoL"
label variable FT_LtoH "LtoH"
label variable FT_HtoH "HtoH"
label variable FT_HtoL "HtoL"

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if FT_Event_Time<=${LastPossibleEventTime}, vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female FT_Event_Time)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'
        summarize `var' if e(sample)==1 & FT_LtoL==1, detail
            estadd scalar cmean = r(mean)

    local i  = `i' + 1
}

esttab $exit_outcomes using "${Results}/PostEventMngrExitOutcomes.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 N cmean, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Obs" "Mean, LtoL") fmt(%9.0g %9.3f %9.3f %9.0g %9.3f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample consists of post-event managers who are in the event study. Only those managers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the manager left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 6. regress exit outcomes on manager high-flyer status
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_PostEventMngrsExitOutcomesEventGroups.dta", clear

generate EarlyAgeM = 0
replace  EarlyAgeM = 1 if FT_HtoH==1 | FT_LtoH==1

keep IDlseMHR EarlyAgeM Leaver Leave_YM Rel_Leave_YM LV_1yr LV_2yrs LV_3yrs LV_4yrs LV_5yrs Office Func Female AgeBand FT_Event_Time
duplicates drop 

global LastMonth = 743 
global exit_outcomes LV_1yr LV_2yrs LV_3yrs LV_4yrs LV_5yrs 

label variable EarlyAgeM "High-flyer"

reghdfe Leaver EarlyAgeM, vce(robust) absorb(Office##Func AgeBand##Female FT_Event_Time)
    eststo Leaver
    summarize Leaver if e(sample)==1 & EarlyAgeM==0, detail
        estadd scalar cmean = r(mean)

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' EarlyAgeM if FT_Event_Time<=${LastPossibleEventTime}, vce(robust) absorb(Office##Func AgeBand##Female FT_Event_Time)
        eststo `var'
        summarize `var' if e(sample)==1 & EarlyAgeM==0, detail
            estadd scalar cmean = r(mean)

    local i  = `i' + 1
}

esttab Leaver $exit_outcomes using "${Results}/PostEventMngrExitOutcomes_CrossSection.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(EarlyAgeM) ///
    order(EarlyAgeM) ///
    b(3) se(2) ///
    stats(r2 N cmean, labels("\hline R-squared" "Obs" "Mean, LtoL") fmt(%9.3f %9.0g %9.3f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leaver} & \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample consists of a cross-section of post-event managers. Only those managers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the manager left the firm within a given period after the manager change event. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender. For the four treatment groups, these controls are at the time of event. Robust standard errors are reported." "\end{tablenotes}")


