/* 
This do file 
    (1) identifies the first eligible manager change a worker experiences; and
    (2) constructs a set of dummies for the four treatment groups based on EarlyAgeM measure.

In particular, workers in the event studies are those employees who satisfy the following conditions.
    Condition (a): An employee's observed first manager transition event is a pure manager change event. 
    Condition (b): Both the pre- (i.e., origin) and post-event (i.e., destination) managers are of work level 2.

Input:
    "${TempData}/FinalFullSample.dta"   <== created in 0101_01 do file
    "${TempData}/0102_03HFMeasure.dta"  <== created in 0102_03 do file 

Output:
    "${TempData}/temp_Mngr_WL.dta                       <== auxiliary dataset, will be removed if $if_erase_temp_file==1
    "${TempData}/0103_01CrossSectionalEventWorkers.dta" <== main output dataset

Description of the main output dataset:
    (1) It contains the following variables: IDlse Event_Time Event_Time_1monthbefore IDMngr_Pre IDMngr_Post
    (2) It is a cross section of workers in the event studies.
    (3) It stores these event workers' origin and destination managers.

RA: WWZ 
Time: 2025-04-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. condition (b): a dataset storing managers' work levels  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${RawMNEData}/AllSnapshotWC.dta", clear 
    keep   IDlse YearMonth WL 
    rename IDlse IDlseMHR 
    rename WL    WLM 
save "${TempData}/temp_Mngr_WL.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. condition (a) -- first pure manager change event 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. create ChangeM: all manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

drop temp_first_month 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. modify ChangeMR: pure manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate ChangeMR = 0 
replace  ChangeMR = 1 if ChangeM==1 
replace  ChangeMR = 0 if TransferInternal==1 | TransferSJ==1 
    // impt: we only consider those manager changes without simultaneous internal or lateral transfers (pure manager change)
replace  ChangeMR = . if ChangeM==.
replace  ChangeMR = . if IDlseMHR==. 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. modify ChangeMR: first pure manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Date_FirstMngrChange     = min(cond(ChangeM==1,  YearMonth ,.))
bysort IDlse: egen Date_FirstPureMngrChange = min(cond(ChangeMR==1, YearMonth, .))
replace ChangeMR = 0 if Date_FirstPureMngrChange>Date_FirstMngrChange & ChangeMR==1
    // impt: we only consider pure manager change, 
    // impt: if first manager change is not pure, we will not include these employees in the event studies
replace ChangeMR = 0 if YearMonth>Date_FirstPureMngrChange
    // impt: we only consider the first pure manager change
format  Date_FirstMngrChange %tm 

label variable ChangeMR "=1, at the month when the worker experiences his first pure manager change event"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. condition (b) -- pre- and post-event managers' work levels 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

merge m:1 IDlseMHR YearMonth using "${TempData}/temp_Mngr_WL.dta", keep(master match) nogenerate keepusing(WLM)

sort IDlse YearMonth
keep IDlse YearMonth IDlseMHR ChangeM ChangeMR WLM
    //&? this is a panel of employees whose first manager change event is a pure manager change 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. two observations for each employee
*-?        the month when the pure manager change event happens 
*-?        one month before the pure manager change event happens 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate ChangeMR_1monthbefore = ChangeMR[_n+1]
label variable ChangeMR "=1, 1 month before the worker experiences his first pure manager change event"

keep if ChangeMR==1 | ChangeMR_1monthbefore==1
    //&? for each employee who satisfies condition (a), keep 2 observations (the month and one month before the manager change event)

codebook IDlse
    //&? 118,884 distinct employees 

/* sort IDlse YearMonth
bysort IDlse: generate test = _N 
summarize test, detail 
    //&? passed the test!
drop test  */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. identify event workers based on ChangeMR and WLM
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if WLM==2
    //&? recall that we have kept the event month and one month before the event 

sort IDlse YearMonth
bysort IDlse: generate ind_count = _N 
keep if ind_count==2
    //impt: if two observations are left for an employee, this means that both his pre- and post-event managers are of work level 2

keep IDlse YearMonth IDlseMHR WLM ChangeM ChangeMR ChangeMR_1monthbefore

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. reshape dataset to a wide form
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate Period = .
replace  Period = 1 if ChangeMR==1
replace  Period = 0 if ChangeMR_1monthbefore==1

keep IDlse YearMonth IDlseMHR Period 
reshape wide IDlseMHR, i(IDlse YearMonth) j(Period)

sort IDlse YearMonth
bysort IDlse: egen long IDlseMHR00 = mean(IDlseMHR0)

keep if IDlseMHR00!=. & IDlseMHR1!=.
    //impt: keep a cross-section of event workers
    //&? 29,826 distinct event workers

keep IDlse YearMonth IDlseMHR00 IDlseMHR1
rename (YearMonth IDlseMHR00 IDlseMHR1) (Event_Time IDMngr_Pre IDMngr_Post)

generate Event_Time_1monthbefore = Event_Time - 1, after(Event_Time)
format Event_Time_1monthbefore %tm

order IDlse Event_Time Event_Time_1monthbefore IDMngr_Pre IDMngr_Post

label variable IDlse                   "Employee ID"
label variable IDMngr_Pre              "Pre-event manager ID"
label variable IDMngr_Post             "Post-event manager ID"
label variable Event_Time              "Event month"
label variable Event_Time_1monthbefore "Event month - 1"

save "${TempData}/0103_01CrossSectionalEventWorkers.dta", replace 

if $if_erase_temp_file==1 {
    erase "${TempData}/temp_Mngr_WL.dta"
}