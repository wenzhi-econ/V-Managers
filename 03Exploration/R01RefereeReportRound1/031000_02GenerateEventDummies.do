/* 
This do file 
    (1) identifies the first eligible manager change a worker experiences; and
    (2) constructs a set of dummies for the four treatment groups based on EarlyAgeM measure.

Input:
    "${TempData}/01WorkersOutcomes.dta" <== created in 0101 do file
    "${TempData}/02Mngr_LTM.dta"        <== created in 031000_01 do file 

Output:
    "${TempData}/temp_Mngr_WL.dta           <== auxiliary dataset 
    "${TempData}/EventStudyDummies_LTM.dta" <== output dataset

Description of the Output Dataset:
    It creates a set of dummies used for event studies.
    In particular, a set of event-related variables:
        HFT_Mngr_both_WL2 HFT_Never_ChangeM ///
        HFT_Rel_Time HFT_LtoL HFT_LtoH HFT_HtoH HFT_HtoL HFT_Event_Time HFT_Calend_Time_*

RA: WWZ 
Time: 2024-12-20
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. impute missing manager ids 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/01WorkersOutcomes.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. manager id imputations 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in IDlseMHR {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. 
}

label variable IDlseMHR "Manager ID"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. get managers' H-type information - EarlyAgeM
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_LTM.dta", keep(match master) nogenerate 

label variable LTM "=1, if the manager is a high-flyer (determined by tenure at promotion)"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. manager change event 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. create ChangeM: all manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

drop temp_first_month 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. modify ChangeMR: pure manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate ChangeMR = 0 
replace  ChangeMR = 1 if ChangeM==1 
replace  ChangeMR = 0 if TransferInternal==1 | TransferSJ==1 
    // impt: we only consider those manager changes without simultaneous internal or lateral transfers
replace  ChangeMR = . if ChangeM==.
replace  ChangeMR = . if IDlseMHR==. 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. modify ChangeMR: first pure manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

bysort IDlse: egen temp_Date_FirstMngrChange = min(cond(ChangeM==1, YearMonth ,.))
bysort IDlse: egen Date_FirstMngrChange      = mean(cond(ChangeMR==1 & YearMonth==temp_Date_FirstMngrChange, temp_Date_FirstMngrChange, .))
replace ChangeMR = 0 if YearMonth>Date_FirstMngrChange & ChangeMR==1
    // impt: we only consider first manager change
replace ChangeMR = 0 if ChangeMR==. 
format  Date_FirstMngrChange %tm 

label variable ChangeMR "=1, at the month when the worker experiences his first pure manager change event"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. four set of treatment groups
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. indicator of four types of manager change 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! LtoL 
sort IDlse YearMonth
generate HFTLowLow = 0 if LTM!=.
replace  HFTLowLow = 1 if (IDlse[_n]==IDlse[_n-1] & LTM[_n]==0 & LTM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1] )
replace  HFTLowLow = 0 if ChangeMR==0 & HFTLowLow!=.

*!! LtoH
sort IDlse YearMonth 
generate HFTLowHigh = 0 if LTM!=.
replace  HFTLowHigh = 1 if (IDlse[_n]==IDlse[_n-1] & LTM[_n]==1 & LTM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HFTLowHigh = 0 if ChangeMR==0 & HFTLowHigh!=.

*!! HtoH 
sort IDlse YearMonth
generate HFTHighHigh = 0 if LTM!=.
replace  HFTHighHigh = 1 if (IDlse[_n]==IDlse[_n-1] & LTM[_n]==1 & LTM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HFTHighHigh = 0 if ChangeMR==0 & HFTHighHigh!=.

*!! HtoL
sort IDlse YearMonth
generate HFTHighLow = 0 if LTM!=.
replace  HFTHighLow = 1 if (IDlse[_n]==IDlse[_n-1] & LTM[_n]==0 & LTM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HFTHighLow = 0 if ChangeMR==0 & HFTHighLow!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. event dates of the four types of manager change 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! event time of the four events 
bys IDlse: egen HFT_Calend_Time_LtoL = mean(cond(HFTLowLow   == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HFT_Calend_Time_LtoH = mean(cond(HFTLowHigh  == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HFT_Calend_Time_HtoH = mean(cond(HFTHighHigh == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HFT_Calend_Time_HtoL = mean(cond(HFTHighLow  == 1, Date_FirstMngrChange, .)) 
format HFT_Calend_Time_LtoL %tm
format HFT_Calend_Time_LtoH %tm
format HFT_Calend_Time_HtoH %tm
format HFT_Calend_Time_HtoL %tm

*!! calendar time of the event 
generate HFT_Event_Time = . 
replace  HFT_Event_Time = HFT_Calend_Time_LtoL if HFT_Calend_Time_LtoL!=. & HFT_Event_Time==.
replace  HFT_Event_Time = HFT_Calend_Time_LtoH if HFT_Calend_Time_LtoH!=. & HFT_Event_Time==.
replace  HFT_Event_Time = HFT_Calend_Time_HtoL if HFT_Calend_Time_HtoL!=. & HFT_Event_Time==.
replace  HFT_Event_Time = HFT_Calend_Time_HtoH if HFT_Calend_Time_HtoH!=. & HFT_Event_Time==.
format   HFT_Event_Time %tm

label variable HFT_Calend_Time_LtoL "year-month when the LtoL event takes place, non-missing only for LtoL workers"
label variable HFT_Calend_Time_LtoH "year-month when the LtoH event takes place, non-missing only for LtoH workers"
label variable HFT_Calend_Time_HtoH "year-month when the HtoH event takes place, non-missing only for HtoH workers"
label variable HFT_Calend_Time_HtoL "year-month when the HtoL event takes place, non-missing only for HtoL workers"
label variable HFT_Event_Time       "year-month when the event take place, non-missing only when HFT_Never_ChangeM==0"

drop HFTLowLow HFTLowHigh HFTHighHigh HFTHighLow
    //&? Drop these auxiliary variables, which are only defined at the event time.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. five event dummies: 4 types of treatment + 1 never-treated
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate HFT_LtoL = 0 
replace  HFT_LtoL = 1 if HFT_Calend_Time_LtoL != .

generate HFT_LtoH = 0 
replace  HFT_LtoH = 1 if HFT_Calend_Time_LtoH != .

generate HFT_HtoH = 0 
replace  HFT_HtoH = 1 if HFT_Calend_Time_HtoH != .

generate HFT_HtoL = 0 
replace  HFT_HtoL = 1 if HFT_Calend_Time_HtoL != .

generate HFT_Never_ChangeM = . 
replace  HFT_Never_ChangeM = 1 if HFT_LtoH==0 & HFT_HtoL==0 & HFT_HtoH==0 & HFT_LtoL==0
replace  HFT_Never_ChangeM = 0 if HFT_LtoH==1 | HFT_HtoL==1 | HFT_HtoH==1 | HFT_LtoL==1
    //&? HFT_Never_ChangeM is also equal to one in the case where the event is involved with the un-identified manager(s).

label variable HFT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable HFT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable HFT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable HFT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable HFT_Never_ChangeM "=0, if the worker experiences an identifiable manager change"
    //&? By identifiable, I mean both pre- and post-event managers can be identified using the LTM measure.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-4. relative date to the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate HFT_Rel_Time = . 
replace  HFT_Rel_Time = YearMonth - HFT_Calend_Time_LtoL if HFT_Calend_Time_LtoL !=. 
replace  HFT_Rel_Time = YearMonth - HFT_Calend_Time_LtoH if HFT_Calend_Time_LtoH !=. 
replace  HFT_Rel_Time = YearMonth - HFT_Calend_Time_HtoH if HFT_Calend_Time_HtoH !=. 
replace  HFT_Rel_Time = YearMonth - HFT_Calend_Time_HtoL if HFT_Calend_Time_HtoL !=. 

label variable HFT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. check if the involving managers are both at work level 2 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-? get managers' work level information for each month 
preserve 

    keep   IDlse YearMonth WL 
    rename IDlse IDlseMHR 
    rename WL    WLM 

    save "${TempData}/temp_Mngr_WL.dta", replace 

restore 

*-? merge mangers' work level to the main dataset 
merge m:1 IDlseMHR YearMonth using "${TempData}/temp_Mngr_WL.dta", keep(master match) nogenerate keepusing(WLM)

*-? if the involving managers are both of work level 2
sort IDlse YearMonth
bysort IDlse: egen FirstWL2M = max(cond(WLM==2 & HFT_Rel_Time==-1, 1, 0))
bysort IDlse: egen LastWL2M  = max(cond(WLM==2 & HFT_Rel_Time==0, 1, 0))
generate HFT_Mngr_both_WL2 = (FirstWL2M ==1 & LastWL2M ==1)
replace  HFT_Mngr_both_WL2 = . if HFT_Rel_Time==.
label variable HFT_Mngr_both_WL2 "=1, if involving managers in the event are both at work level 2"
    //&? This variable is only defined for four event groups.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 6. save the dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth ///
    HFT_Mngr_both_WL2 HFT_Never_ChangeM ///
    HFT_Rel_Time HFT_LtoL HFT_LtoH HFT_HtoH HFT_HtoL HFT_Event_Time HFT_Calend_Time_*

compress
save "${TempData}/EventStudyDummies_LTM.dta", replace

