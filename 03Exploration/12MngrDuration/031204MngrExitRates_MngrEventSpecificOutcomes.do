/* 
This do file investigates post event managers' exit rates, separately for different event groups.

RA: WWZ 
Time: 2025-01-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of post-event managers 
*??         and each of their involved event dates 
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
bysort IDlseMHR: generate occurrence = _n 
reshape wide YearMonth, i(IDlseMHR) j(occurrence)
rename YearMonth* EventTime_*
    //&? a cross-section of post-event managers, and a complete list of their involved event dates 

save "${TempData}/temp_PostEventMngrsAndEventDates.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. collect post-event managers' exit outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 
drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrsAndEventDates.dta", keep(match) nogenerate
    //&? a full panel of relevant post-event managers 
    
/* 
impt: Explanation of the following codes:
For each manager-date pair, we only want to count the manager's relative leave date from the event.
However, a manager could be involved into multiple events, listed in variables EventTime_1, EventTime_2, ..., EventTime_15.
The event dates are ordered in a way such that EventTime_1 is the earliest event date, and EventTime_15 is the latest event date.
Therefore, we can successively use the sample restriction command to make sure that we only count the duration from the event dates onwards, if we know that the manager has at least `j' events.
    keep if YearMonth >= EventTime_`j' & NumOfEvents>=`j'
*/

keep IDlseMHR YearMonth EventTime_* LeaverPerm 

egen NumOfEvents = rownonmiss(EventTime_*)
    //&? count the number of events a manager could be involved in

forvalues j = 1/15{
    //&? iterate over all events a manager could be involved in

    keep if (YearMonth>=EventTime_`j' & NumOfEvents>=`j') | NumOfEvents<`j'
        //&? count the duration from the jth event time onwards

    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen Leaver_`j'   = max(LeaverPerm)
    bysort IDlseMHR: egen Leave_YM_`j' = min(cond(LeaverPerm==1, YearMonth, .))
    format Leave_YM_`j' %tm

    generate Rel_Leave_YM_`j' = Leave_YM_`j' - EventTime_`j'

    replace Leaver_`j'       = -99 if NumOfEvents<`j'
    replace Rel_Leave_YM_`j' = -99 if NumOfEvents<`j'
        //&? there is no jth event for the manager
        //&? use -99 because . (missing) means that the manager didn't leave the firm

}

keep IDlseMHR Leaver_* Rel_Leave_YM_* EventTime_*
duplicates drop 
    //&? a cross-section of post-event managers
    //&? variables with different numbering indicates event dates and the work duration for different events 

reshape long Leaver_ Rel_Leave_YM_ EventTime_, i(IDlseMHR) j(EventNum)
drop if EventTime_==.
    //&? manager-event level dataset, 
    //&? storing manager-event specific outcome variables: work duration from the event onwards
rename Leaver_ Leaver
rename Rel_Leave_YM_ Rel_Leave_YM
rename EventTime_ EventTime

save "${TempData}/temp_PostEventMngrsAndEventDatesExitOutcomes.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. find out managers' event groups  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers 

keep if FT_Rel_Time==0
    //&? a cross-sectional of event workers (at the time of event)

keep IDlseMHR YearMonth FT_LtoL FT_LtoH FT_HtoH FT_HtoL FuncM OfficeCodeM ISOCodeM FemaleM AgeBandM

rename YearMonth EventTime

merge m:1 IDlseMHR EventTime using "${TempData}/temp_PostEventMngrsAndEventDatesExitOutcomes.dta", keep(match) nogenerate

save "${TempData}/temp_PostEventMngrsAndEventDatesExitOutcomesEventGroups.dta", replace
    //&? exactly 29610 events in the dataset!

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. average exit rates by event groups  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize Leaver, detail
/* 
. summarize Leaver, detail

                           Leaver
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs              29,610
25%            0              0       Sum of wgt.      29,610

50%            1                      Mean           .5148261
                        Largest       Std. dev.      .4997886
75%            1              1
90%            1              1       Variance       .2497886
95%            1              1       Skewness      -.0593304
99%            1              1       Kurtosis        1.00352
 */

summarize Leaver if FT_LtoL==1, detail
/* . summarize Leaver if FT_LtoL==1, detail

                           Leaver
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs              20,853
25%            0              0       Sum of wgt.      20,853

50%            1                      Mean           .5058745
                        Largest       Std. dev.      .4999775
75%            1              1
90%            1              1       Variance       .2499775
95%            1              1       Skewness      -.0234994
99%            1              1       Kurtosis       1.000552

 */

summarize Leaver if FT_LtoH==1, detail
/* . summarize Leaver if FT_LtoH==1, detail

                           Leaver
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs               4,148
25%            0              0       Sum of wgt.       4,148

50%            1                      Mean           .6036644
                        Largest       Std. dev.      .4891946
75%            1              1
90%            1              1       Variance       .2393114
95%            1              1       Skewness      -.4238678
99%            1              1       Kurtosis       1.179664
 */

summarize Leaver if FT_HtoH==1, detail
/* . summarize Leaver if FT_HtoH==1, detail

                           Leaver
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs               1,753
25%            0              0       Sum of wgt.       1,753

50%            1                      Mean           .5367941
                        Largest       Std. dev.      .4987866
75%            1              1
90%            1              1       Variance       .2487881
95%            1              1       Skewness      -.1475764
99%            1              1       Kurtosis       1.021779
 */

summarize Leaver if FT_HtoL==1, detail
/* . summarize Leaver if FT_HtoL==1, detail

                           Leaver
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs               2,856
25%            0              0       Sum of wgt.       2,856

50%            0                      Mean           .4376751
                        Largest       Std. dev.      .4961873
75%            1              1
90%            1              1       Variance       .2462018
95%            1              1       Skewness       .2512593
99%            1              1       Kurtosis       1.063131
 */

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. regress exit outcomes on event group identifiers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_PostEventMngrsAndEventDatesExitOutcomesEventGroups.dta", clear 

global LastMonth = 743 //&? 2021m12

generate LV_1yr   = inrange(Rel_Leave_YM, 0, 12)
generate LV_2yrs  = inrange(Rel_Leave_YM, 0, 24)
generate LV_3yrs  = inrange(Rel_Leave_YM, 0, 36)
generate LV_4yrs  = inrange(Rel_Leave_YM, 0, 48)
generate LV_5yrs  = inrange(Rel_Leave_YM, 0, 60)

global exit_outcomes LV_1yr LV_2yrs LV_3yrs LV_4yrs LV_5yrs 

label variable FT_LtoL "LtoL"
label variable FT_LtoH "LtoH"
label variable FT_HtoH "HtoH"
label variable FT_HtoL "HtoL"

reghdfe Leaver FT_LtoH FT_HtoH FT_HtoL, vce(cluster IDlseMHR) absorb(EventTime ISOCodeM)
    eststo Leaver
    summarize Leaver if e(sample)==1 & FT_LtoL==0, detail
        estadd scalar cmean = r(mean)
    test FT_HtoH = FT_HtoL
        local p_Hto = r(p)
        estadd scalar p_Hto = `p_Hto'

local i = 1
foreach var in $exit_outcomes {

    global LastPossibleEventTime = ${LastMonth} - 12 * `i'

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL if EventTime<=${LastPossibleEventTime}, vce(cluster IDlseMHR) absorb(EventTime ISOCodeM)
        eststo `var'
        test FT_HtoH = FT_HtoL
            local p_Hto = r(p)
            estadd scalar p_Hto = `p_Hto'
        summarize `var' if e(sample)==1 & FT_LtoL==1, detail
            estadd scalar cmean = r(mean)

    local i  = `i' + 1
}

esttab Leaver $exit_outcomes using "${Results}/PostEventMngrExitOutcomes_EventLevel.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_values p_Hto r2 N cmean, labels("\hline p-values" "HtoH = HtoL" "\hline R-squared" "Obs" "Mean, LtoL") fmt(%9.0g %9.3f %9.3f %9.0g %9.3f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Leaver} & \multicolumn{1}{c}{Leave 1yr} & \multicolumn{1}{c}{Leave 2yrs}  & \multicolumn{1}{c}{Leave 3yrs}  & \multicolumn{1}{c}{Leave 4yrs}  & \multicolumn{1}{c}{Leave 5yrs}  \\ " "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\ ") ///
    posthead("\hline") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The regression sample consists of post-event managers who are in the event study. Only those managers whose outcome variable can be measured given the dataset period are kept. The LtoL group is the omitted group. The outcome variable indicates whether the manager left the firm within a given period after the manager change event. Control variables include country and event time fixed effects. For the four treatment groups, these controls are at the time of event. Standard errors are clustered at manager level (manager at the event date)." "\end{tablenotes}")
