/* 
This do file tries to replicate Figure A7 in the paper (CDF of the duration of managers' previous job before a new transition), but with a different implementation and using my own constructed datasets.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0104 do file.

Output:
    "${TempData}/temp_EventMngrs_EventDates.dta"

Results:
    "${Results}/DistofTenureOfBeforeEventsSubFunc_2019Events.png"
    "${Results}/DistofTenureOfBeforeEventsSubFunc.png"

RA: WWZ 
Time: 2024-10-29
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a temp dataset to store event managers and evet dates 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. calendar time of the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. keep only event managers and the earliest date 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time==0 
    //&? This keeps only those post-event managers.

keep if FT_Mngr_both_WL2==1 
    //&? This keeps only those post-event managers who are actually used in event studies.


keep IDlseMHR FT_Event_Time
duplicates drop 

sort IDlseMHR FT_Event_Time 
bysort IDlseMHR: generate occurrence = _n 
keep if occurrence==1
    //&? A manager could engage in multiple events.
    //&? This keeps only the first event

rename IDlseMHR IDlse

save "${TempData}/temp_EventMngrs_EventDates.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. before the event, how long does the event manager stays in his subfunction 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. get the event date info for managers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

merge m:1 IDlse using "${TempData}/temp_EventMngrs_EventDates.dta", keep(match) nogenerate 
    //&? keep only those event managers in the main dataset

keep  IDlse YearMonth FT_Event_Time StandardJob SubFunc
order IDlse YearMonth FT_Event_Time StandardJob SubFunc
sort  IDlse YearMonth

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. subfunction at different relative times 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! relative time to the event date 
generate Window = YearMonth - FT_Event_Time
sort     IDlse YearMonth
bysort   IDlse: egen min_Window = min(Window)

*!! subfunction right before the event and right at the event date
sort IDlse YearMonth
bysort IDlse: egen SubFunc_BeforeE = mean(cond(Window==-1, SubFunc, .))
bysort IDlse: egen SubFunc_AfterE  = mean(cond(Window==0, SubFunc, .))

*!! subfunction at the first appearance in the dataset 
sort IDlse YearMonth
bysort IDlse: egen SubFunc_First = mean(cond(Window==min_Window, SubFunc, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. the subset of managers that we care about
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate q_SubFunc_tenure_info = (SubFunc_BeforeE!=SubFunc_AfterE & SubFunc_First!=SubFunc_BeforeE & min_Window<0)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. tenure at the subfunction defined by SubFunc_BeforeE
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate At_Same_SubFunc_BeforeE = (SubFunc==SubFunc_BeforeE & Window<0) if q_SubFunc_tenure_info==1

sort IDlse YearMonth
bysort IDlse: egen Tenure_SubFunc_BeforeE = sum(At_Same_SubFunc_BeforeE) if q_SubFunc_tenure_info==1

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. draw the tenure distribution  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep if Window==-1
    //&? a cross-section of managers: 9,890 managers
keep if q_SubFunc_tenure_info==1
    //&? 497 managers 
    //&? only for these managers, we can identify their subfunction tenure at the subfunction before the event 

summarize Tenure_SubFunc_BeforeE, detail 

count if FT_Event_Time>=tm(2019m1) & FT_Event_Time<=tm(2019m12)
    //&? only 52 managers in the graph 

cdfplot Tenure_SubFunc_BeforeE if FT_Event_Time>=tm(2019m1) & FT_Event_Time<=tm(2019m12) ///
    , xlabel(0(5)115)  ylabel(0(0.1)1, grid gstyle(dot)) xtitle("Months in previous subfunction (manager)") xline(14) xline(31)

graph export "${Results}/DistofTenureOfBeforeEventsSubFunc_2019Events.png", replace as(png)

cdfplot Tenure_SubFunc_BeforeE ///
    , xlabel(0(5)115)  ylabel(0(0.1)1, grid gstyle(dot)) xtitle("Months in previous subfunction (manager)") xline(14) xline(31)

graph export "${Results}/DistofTenureOfBeforeEventsSubFunc.png", replace as(png)
