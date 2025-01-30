/* 
This do file investigates the distribution of post-event managers' duration at his work after the event, separately for different event groups.

If a manager is involved in multiple events, then we only randomly select one event for the manager.

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
*?? step 2. collect post-event managers' duration at work 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 
drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR using "${TempData}/temp_PostEventMngrsAndEventDates.dta", keep(match) nogenerate
    //&? a full panel of relevant post-event managers 

/* 
impt: Explanation of the following codes:
For each manager-date pair, we only want to count the manager's work duration from the event time onwards.
However, a manager could be involved into multiple events, listed in variables EventTime_1, EventTime_2, ..., EventTime_15.
The event dates are ordered in a way such that EventTime_1 is the earliest event date, and EventTime_15 is the latest event date.
Therefore, we can successively use the sample restriction command to make sure that we only count the duration from the event dates onwards, if we know that the manager has at least `j' events.
    keep if YearMonth >= EventTime_`j' & NumOfEvents>=`j'
*/

keep IDlseMHR YearMonth Func SubFunc Office Org4 EventTime_*

egen NumOfEvents = rownonmiss(EventTime_*)
    //&? count the number of events a manager could be involved in

forvalues j = 1/15{
    //&? iterate over all events a manager could be involved in

    keep if (YearMonth>=EventTime_`j' & NumOfEvents>=`j') | NumOfEvents<`j'
        //&? count the duration from the jth event time onwards

    sort IDlseMHR YearMonth
    egen IDMHR_Work_`j' = group(IDlseMHR Func SubFunc Office Org4)

    sort IDlseMHR YearMonth
    bysort IDlseMHR: generate Change_Work_`j' = (IDMHR_Work_`j'[_n] != IDMHR_Work_`j'[_n-1])
    bysort IDlseMHR: replace  Change_Work_`j' = 0 if _n==1
    bysort IDlseMHR: generate IDWork_`j'      = sum(Change_Work_`j') 

    generate FirstWork_`j' = (IDWork_`j'==0)
    sort IDlseMHR YearMonth
    bysort IDlseMHR: egen WorkDuration_`j' = total(FirstWork_`j')

    replace WorkDuration_`j' = . if NumOfEvents<`j'
        //&? there is no jth event for the manager

}

keep IDlseMHR WorkDuration_* EventTime_* NumOfEvents
duplicates drop 
    //&? a cross-section of post-event managers
    //&? variables with different numbering indicates event dates and the work duration for different events 

reshape long WorkDuration_ EventTime_, i(IDlseMHR) j(EventNum)
drop if EventTime_==.
    //&? manager-event level dataset, 
    //&? storing manager-event specific outcome variables: work duration from the event onwards
rename WorkDuration_ WorkDuration
rename EventTime_    EventTime

order IDlseMHR NumOfEvents EventNum EventTime WorkDuration

save "${TempData}/temp_PostEventMngrsAndEventDatesWorkDuration.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. find out managers' event groups  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers 

keep if FT_Rel_Time==0
    //&? a cross-sectional of event workers (at the time of event)

keep IDlseMHR YearMonth FT_LtoL FT_LtoH FT_HtoH FT_HtoL

rename YearMonth EventTime

merge m:1 IDlseMHR EventTime using "${TempData}/temp_PostEventMngrsAndEventDatesWorkDuration.dta", keep(match) nogenerate

save "${TempData}/temp_PostEventMngrsAndEventDatesWorkDurationEventGroups.dta", replace
    //&? exactly 29610 events in the dataset!

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. plot the distribution  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. by event groups, weighted version 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_PostEventMngrsAndEventDatesWorkDurationEventGroups.dta", clear

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-1. choose a random event 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

set seed 1234
sort IDlseMHR EventTime
bysort IDlseMHR: generate randomnumbers = runiform()
bysort IDlseMHR: egen min_randomnumber = min(randomnumbers)
generate selected_event = (randomnumbers==min_randomnumber)

count if selected_event==1
    //&? 10,423 managers, thus 10,423 events are selected

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-2. cdf
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate Treatment = .
replace  Treatment = 1 if FT_LtoL==1
replace  Treatment = 2 if FT_LtoH==1
replace  Treatment = 3 if FT_HtoH==1
replace  Treatment = 4 if FT_HtoL==1

label define treat 1 "LtoL" 2 "LtoH" 3 "HtoH" 4 "HtoL"
label values Treatment treat

cdfplot WorkDuration if selected_event==1, by(Treatment) /// 
    legend(label(1 "LtoL") label(2 "LtoH") label(3 "HtoH") label(4 "HtoL")) ///
    xtitle("Duration at work after event") xlabel(0(25)125, grid gstyle(dot)) /// 
    ytitle("Cumulative probability") ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Managers' duration at work after event, by event groups")
graph export "${Results}/PostEventMngrDuration_Random1_CDF.png", replace as(png)

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-4-1-3. density
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

histogram WorkDuration if FT_LtoL==1 & selected_event==1 ///
    , width(1) fraction ///
    xtitle("Duration at work after event") xlabel(0(25)150, grid gstyle(dot)) ///
    ytitle("Fraction") ylabel(0(0.005)0.065, grid gstyle(dot)) ///
    title("Managers' duration at work after event, LtoL") 
graph export "${Results}/PostEventMngrDuration_Random1_Histogram_LtoL.png", replace as(png)

histogram WorkDuration if FT_LtoH==1 & selected_event==1 ///
    , width(1) fraction ///
    xtitle("Duration at work after event") xlabel(0(25)150, grid gstyle(dot)) ///
    ytitle("Fraction") ylabel(0(0.005)0.065, grid gstyle(dot)) ///
    title("Managers' duration at work after event, LtoH")
graph export "${Results}/PostEventMngrDuration_Random1_Histogram_LtoH.png", replace as(png)

histogram WorkDuration if FT_HtoH==1 & selected_event==1 ///
    , width(1) fraction ///
    xtitle("Duration at work after event") xlabel(0(25)150, grid gstyle(dot)) ///
    ytitle("Fraction") ylabel(0(0.005)0.065, grid gstyle(dot)) ///
    title("Managers' duration at work after event, HtoH") 
graph export "${Results}/PostEventMngrDuration_Random1_Histogram_HtoH.png", replace as(png)

histogram WorkDuration if FT_HtoL==1 & selected_event==1 ///
    , width(1) fraction ///
    xtitle("Duration at work after event") xlabel(0(25)150, grid gstyle(dot)) ///
    ytitle("Fraction") ylabel(0(0.005)0.065, grid gstyle(dot)) ///
    title("Managers' duration at work after event, HtoL") 
graph export "${Results}/PostEventMngrDuration_Random1_Histogram_HtoL.png", replace as(png)

histogram WorkDuration if selected_event==1 ///
    , width(1) fraction ///
    xtitle("Duration at work after event") xlabel(0(25)150, grid gstyle(dot)) ///
    ytitle("Fraction") ylabel(0(0.005)0.065, grid gstyle(dot)) ///
    title("Managers' duration at work after event, all managers") 
graph export "${Results}/PostEventMngrDuration_Random1_Histogram_All.png", replace as(png)


graph twoway ///
    (kdensity WorkDuration if FT_LtoL==1 & selected_event==1) ///
    (kdensity WorkDuration if FT_LtoH==1 & selected_event==1) ///
    (kdensity WorkDuration if FT_HtoH==1 & selected_event==1) ///
    (kdensity WorkDuration if FT_HtoL==1 & selected_event==1), ///
    scheme(tab2) ///
    legend(label(1 "LtoL") label(2 "LtoH") label(3 "HtoH") label(4 "HtoL")) ///
    xtitle("Duration at work after event") xlabel(0(25)150, grid gstyle(dot)) ///
    ytitle("Frequency") ylabel(0(0.005)0.045, grid gstyle(dot)) ///
    title("Managers' duration at work after event, by event groups") 

graph export "${Results}/PostEventMngrDuration_Random1.png", replace as(png)
