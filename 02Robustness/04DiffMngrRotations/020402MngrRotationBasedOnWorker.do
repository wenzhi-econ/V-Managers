/* 
This do file computes manager-level average duration with workers inside a team for post-event workers.
    First, for each event worker, I first calculate his time with the post-event manager. 
    Then, for each post-event manager, I calculate the average exposure time across event workers with him as the manager.
    I then plot the cdf for the post-event workers.

Note:
    To avoid right-censoring, we focus only on workers with event time <= year 2019.

Two extensions:
    (1) only using those event workers who didn't change job after the event to calculate average exposure time for each manager.
    (2) re-run event studies using those events with post-event manager's average exposure time falling in the range [15, 30].

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0104 do file.

Output:
    "${TempData}/temp_EventWorkers_ExposureWithMngrs.dta"
    "${TempData}/temp_PostEventMngrID_EventWorkerID.dta"
    "${TempData}/temp_Mngr_Exposure.dta"

RA: WWZ 
Time: 2024-11-01
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. event workers' exposure with the post-event manager 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

sort IDlse YearMonth

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep a panel of event workers 

*!! event time 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

keep if FT_Event_Time <= tm(2019m1) 
    //&? keep only those workers whose event time is before 2019

*!! post-event manager id 
generate long temp_Post_Mngr_ID = . //&& type notation is necessary
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_LtoL & FT_Calend_Time_LtoL != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_LtoH & FT_Calend_Time_LtoH != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_HtoH & FT_Calend_Time_HtoH != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_HtoL & FT_Calend_Time_HtoL != .

bysort IDlse: egen long Post_Mngr_ID = mean(temp_Post_Mngr_ID) //&& type notation is necessary
label variable Post_Mngr_ID "Post-event manager ID"

drop temp_Post_Mngr_ID

*!! FT_Post 
generate FT_Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .

*!! number of months working with the post-event manager
generate Post_Mngr = ((IDlseMHR == Post_Mngr_ID) & (FT_Post==1)) if Post_Mngr_ID!=.
label variable Post_Mngr "=1, if the worker is under the post-event manager"

sort IDlse YearMonth
bysort IDlse: egen FT_Exposure = total(Post_Mngr)
replace FT_Exposure = . if Post_Mngr==.
label variable FT_Exposure "Number of months a worker spends time with the post-event manager"

order IDlse YearMonth FT_Exposure

*!! keep a cross-section of event workers
keep IDlse FT_Exposure
duplicates drop 

save "${TempData}/temp_EventWorkers_ExposureWithMngrs.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. post-event manager - event worker correspondence  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

sort IDlse YearMonth

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep a panel of event workers 

*!! event time 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

keep if FT_Event_Time <= tm(2019m1) 
    //&? keep only those workers whose event time is before 2019

*!! post-event manager id 
generate long temp_Post_Mngr_ID = . //&& type notation is necessary
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_LtoL & FT_Calend_Time_LtoL != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_LtoH & FT_Calend_Time_LtoH != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_HtoH & FT_Calend_Time_HtoH != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_HtoL & FT_Calend_Time_HtoL != .

bysort IDlse: egen long Post_Mngr_ID = mean(temp_Post_Mngr_ID) //&& type notation is necessary
label variable Post_Mngr_ID "Post-event manager ID"

drop temp_Post_Mngr_ID

*!! keep only event workers' ID and post-event managers' ID 
keep IDlse Post_Mngr_ID
duplicates drop 
rename Post_Mngr_ID IDlseMHR 
order  IDlseMHR IDlse
sort   IDlseMHR

save "${TempData}/temp_PostEventMngrID_EventWorkerID.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. aggregate worker-level exposure time to manager level 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_PostEventMngrID_EventWorkerID.dta", clear 
merge 1:1 IDlse using "${TempData}/temp_EventWorkers_ExposureWithMngrs.dta", nogenerate 

sort IDlseMHR IDlse
bysort IDlseMHR: egen FT_Mngr_Exposure = mean(FT_Exposure)

keep IDlseMHR FT_Mngr_Exposure
duplicates drop 

generate q_exposure = (inrange(FT_Mngr_Exposure, 15, 30))

rename IDlseMHR Post_Mngr_ID

save "${TempData}/temp_Mngr_Exposure.dta", replace 

summarize FT_Mngr_Exposure, detail // [1, 130]

cdfplot FT_Mngr_Exposure ///
    , xlabel(0(5)130)  ylabel(0(0.1)1, grid gstyle(dot)) xtitle("Manager's average exporsure months with workers") ///
    xline(14) xline(31)

graph export "${Results}/DistOfMngrExposureWithWorkers.png", replace as(png)
