/* 
This do file identifies the first eligible manager change a worker experiences, and constructs a set of dummies for the four treatment groups based on HF2M and HF2SM measures.
In particular, 
    if the pre- and post-event managers are both of WL2,
    relative time to the event and calendar time of the event,
    which event (LtoL LtoH HtoH HtoL) does a worker belong to.

Input:
    "${RawMNEData}/AllSnapshotWC.dta"
    "${TempData}/temp_Mngr_HF2M_HF2SM.dta" <== constructed in 0102_02 do file 

Output:
    "${TempData}/02EventStudyDummies_HF2M_HF2SM.dta"

RA: WWZ 
Time: 2024-10-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. get two FT measures: HF2 HF2S
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${RawMNEData}/AllSnapshotWC.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

bysort IDlse: generate occurrence = _n 

order IDlse YearMonth occurrence IDlseMHR

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. impute missing manager id 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in IDlseMHR   {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. 
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. who are fast-track managers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR YearMonth using "${TempData}/temp_Mngr_HF2M_HF2SM.dta", generate(_merge_HF) keep(master match)

order IDlse YearMonth occurrence IDlseMHR HF2M HF2SM q_witness_WL2PromM Age_atWL2PromM q_WL2plus_atentryM Age_WL2plus_atentryM

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. manager change event 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. variable ChangeM: all manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

drop temp_first_month 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. variable ChangeMR: pure manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferInternal = 0 & Office!=. & SubFunc!=. & Org4!=. 
replace  TransferInternal = 1 if IDlse==IDlse[_n-1] & ((OfficeCode!=OfficeCode[_n-1] & OfficeCode!=.) | (SubFunc!=SubFunc[_n-1] & SubFunc!=.) | (Org4!=Org4[_n-1] & Org4!=.))
label variable  TransferInternal "= 1 in the month when either subfunc or Office or org4 is diff. than preceding"

sort IDlse YearMonth
generate TransferSJ = 0 if StandardJob!="" 
replace  TransferSJ = 1 if (IDlse==IDlse[_n-1] & StandardJob!=StandardJob[_n-1] & StandardJob!="")

*&& Changing manager for employee but employee does not change team at the same time 
generate ChangeMR = 0 
replace  ChangeMR = 1 if ChangeM==1 
replace  ChangeMR = 0 if TransferInternal==1 | TransferSJ==1 
replace  ChangeMR = . if ChangeM==.
replace  ChangeMR = . if IDlseMHR==. 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. variable ChangeMR: first pure manager changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

bysort IDlse: egen temp_Date_FirstMngrChange = min(cond(ChangeM==1, YearMonth ,.))
bysort IDlse: egen Date_FirstMngrChange      = mean(cond(ChangeMR==1 & YearMonth==temp_Date_FirstMngrChange, temp_Date_FirstMngrChange, .))
replace ChangeMR = 0 if YearMonth>Date_FirstMngrChange & ChangeMR==1
    //&? IMPORTANT: we only consider first manager change
replace ChangeMR = 0 if ChangeMR==. 
format  Date_FirstMngrChange %tm 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. four set of treatment groups based on HF2
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. indicator of four types of manager change based on HF2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! LtoL 
sort IDlse YearMonth
generate HF2LowLow = 0 if HF2M!=.
replace  HF2LowLow = 1 if (IDlse[_n]==IDlse[_n-1] & HF2M[_n]==0 & HF2M[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1] )
replace  HF2LowLow = 0 if ChangeMR==0 & HF2LowLow!=.

*!! LtoH
sort IDlse YearMonth 
generate HF2LowHigh = 0 if HF2M!=.
replace  HF2LowHigh = 1 if (IDlse[_n]==IDlse[_n-1] & HF2M[_n]==1 & HF2M[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2LowHigh = 0 if ChangeMR==0 & HF2LowHigh!=.

*!! HtoH 
sort IDlse YearMonth
generate HF2HighHigh = 0 if HF2M!=.
replace  HF2HighHigh = 1 if (IDlse[_n]==IDlse[_n-1] & HF2M[_n]==1 & HF2M[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2HighHigh = 0 if ChangeMR==0 & HF2HighHigh!=.

*!! HtoL
sort IDlse YearMonth
generate HF2HighLow = 0 if HF2M!=.
replace  HF2HighLow = 1 if (IDlse[_n]==IDlse[_n-1] & HF2M[_n]==0 & HF2M[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2HighLow = 0 if ChangeMR==0 & HF2HighLow!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. event dates of the four types of manager change based on HF2 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! four event dates
bys IDlse: egen HF2_Calend_Time_LtoL = mean(cond(HF2LowLow   == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HF2_Calend_Time_LtoH = mean(cond(HF2LowHigh  == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HF2_Calend_Time_HtoH = mean(cond(HF2HighHigh == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HF2_Calend_Time_HtoL = mean(cond(HF2HighLow  == 1, Date_FirstMngrChange, .)) 
format HF2_Calend_Time_LtoL %tm
format HF2_Calend_Time_LtoH %tm
format HF2_Calend_Time_HtoH %tm
format HF2_Calend_Time_HtoL %tm

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. five event dummies: 4 types of treatment + 1 never-treated based on HF2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate HF2_LtoL = 0 
replace  HF2_LtoL = 1 if HF2_Calend_Time_LtoL != .

generate HF2_LtoH = 0 
replace  HF2_LtoH = 1 if HF2_Calend_Time_LtoH != .

generate HF2_HtoH = 0 
replace  HF2_HtoH = 1 if HF2_Calend_Time_HtoH != .

generate HF2_HtoL = 0 
replace  HF2_HtoL = 1 if HF2_Calend_Time_HtoL != .

generate HF2_Never_ChangeM = . 
replace  HF2_Never_ChangeM = 1 if HF2_LtoH==0 & HF2_HtoL==0 & HF2_HtoH==0 & HF2_LtoL==0
replace  HF2_Never_ChangeM = 0 if HF2_LtoH==1 | HF2_HtoL==1 | HF2_HtoH==1 | HF2_LtoL==1

label variable HF2_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable HF2_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable HF2_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable HF2_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable HF2_Never_ChangeM "=0, if the worker experiences an identifiable manager change"
    //&? By identifiable, I mean both pre- and post-event managers can be identified using the HF2 measure.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. relative date to the event based on HF2 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate HF2_Rel_Time = . 
replace  HF2_Rel_Time = YearMonth - HF2_Calend_Time_LtoL if HF2_Calend_Time_LtoL !=. 
replace  HF2_Rel_Time = YearMonth - HF2_Calend_Time_LtoH if HF2_Calend_Time_LtoH !=. 
replace  HF2_Rel_Time = YearMonth - HF2_Calend_Time_HtoH if HF2_Calend_Time_HtoH !=. 
replace  HF2_Rel_Time = YearMonth - HF2_Calend_Time_HtoL if HF2_Calend_Time_HtoL !=. 

label variable HF2_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. four set of treatment groups based on HF2S
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. indicator of four types of manager change based on HF2S 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! LtoL 
sort IDlse YearMonth
generate HF2SLowLow = 0 if HF2SM!=.
replace  HF2SLowLow = 1 if (IDlse[_n]==IDlse[_n-1] & HF2SM[_n]==0 & HF2SM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1] )
replace  HF2SLowLow = 0 if ChangeMR==0 & HF2SLowLow!=.

*!! LtoH
sort IDlse YearMonth 
generate HF2SLowHigh = 0 if HF2SM!=.
replace  HF2SLowHigh = 1 if (IDlse[_n]==IDlse[_n-1] & HF2SM[_n]==1 & HF2SM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2SLowHigh = 0 if ChangeMR==0 & HF2SLowHigh!=.

*!! HtoH 
sort IDlse YearMonth
generate HF2SHighHigh = 0 if HF2SM!=.
replace  HF2SHighHigh = 1 if (IDlse[_n]==IDlse[_n-1] & HF2SM[_n]==1 & HF2SM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2SHighHigh = 0 if ChangeMR==0 & HF2SHighHigh!=.

*!! HtoL
sort IDlse YearMonth
generate HF2SHighLow = 0 if HF2SM!=.
replace  HF2SHighLow = 1 if (IDlse[_n]==IDlse[_n-1] & HF2SM[_n]==0 & HF2SM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2SHighLow = 0 if ChangeMR==0 & HF2SHighLow!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. event dates of the four types of manager change based on HF2S 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! four event dates
bys IDlse: egen HF2S_Calend_Time_LtoL = mean(cond(HF2SLowLow   == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HF2S_Calend_Time_LtoH = mean(cond(HF2SLowHigh  == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HF2S_Calend_Time_HtoH = mean(cond(HF2SHighHigh == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen HF2S_Calend_Time_HtoL = mean(cond(HF2SHighLow  == 1, Date_FirstMngrChange, .)) 
format HF2S_Calend_Time_LtoL %tm
format HF2S_Calend_Time_LtoH %tm
format HF2S_Calend_Time_HtoH %tm
format HF2S_Calend_Time_HtoL %tm

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. five event dummies: 4 types of treatment + 1 never-treated based on HF2S
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate HF2S_LtoL = 0 
replace  HF2S_LtoL = 1 if HF2S_Calend_Time_LtoL != .

generate HF2S_LtoH = 0 
replace  HF2S_LtoH = 1 if HF2S_Calend_Time_LtoH != .

generate HF2S_HtoH = 0 
replace  HF2S_HtoH = 1 if HF2S_Calend_Time_HtoH != .

generate HF2S_HtoL = 0 
replace  HF2S_HtoL = 1 if HF2S_Calend_Time_HtoL != .

generate HF2S_Never_ChangeM = . 
replace  HF2S_Never_ChangeM = 1 if HF2S_LtoH==0 & HF2S_HtoL==0 & HF2S_HtoH==0 & HF2S_LtoL==0
replace  HF2S_Never_ChangeM = 0 if HF2S_LtoH==1 | HF2S_HtoL==1 | HF2S_HtoH==1 | HF2S_LtoL==1

label variable HF2S_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable HF2S_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable HF2S_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable HF2S_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable HF2S_Never_ChangeM "=0, if the worker experiences an identifiable manager change"
    //&? By identifiable, I mean both pre- and post-event managers can be identified using the HF2S measure.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-4. relative date to the event based on HF2S 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate HF2S_Rel_Time = . 
replace  HF2S_Rel_Time = YearMonth - HF2S_Calend_Time_LtoL if HF2S_Calend_Time_LtoL !=. 
replace  HF2S_Rel_Time = YearMonth - HF2S_Calend_Time_LtoH if HF2S_Calend_Time_LtoH !=. 
replace  HF2S_Rel_Time = YearMonth - HF2S_Calend_Time_HtoH if HF2S_Calend_Time_HtoH !=. 
replace  HF2S_Rel_Time = YearMonth - HF2S_Calend_Time_HtoL if HF2S_Calend_Time_HtoL !=. 

label variable HF2S_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. check if the involving managers are both at work level 2 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-? get managers' work level information for each month 
preserve 
    keep IDlse YearMonth WL 
    rename IDlse IDlseMHR 
    rename WL    WLM 

    save "${TempData}/temp_Mngr_WL.dta", replace 

restore 

*-? merge mangers' work level to the main dataset 
merge m:1 IDlseMHR YearMonth using "${TempData}/temp_Mngr_WL.dta", keep(master match) nogenerate keepusing(WLM)

*-? if the involving managers are both of work level 2
sort IDlse YearMonth
bysort IDlse: egen HF2_FirstWL2M = max(cond(WLM==2 & HF2_Rel_Time==-1, 1, 0))
bysort IDlse: egen HF2_LastWL2M  = max(cond(WLM==2 & HF2_Rel_Time==0, 1, 0))
generate HF2_Mngr_both_WL2 = (HF2_FirstWL2M ==1 & HF2_LastWL2M ==1)
replace  HF2_Mngr_both_WL2 = . if HF2_Rel_Time==.
label variable HF2_Mngr_both_WL2 "=1, if involving managers in the event are both at work level 2"
    //&? This variable is only defined for four event groups.

sort IDlse YearMonth
bysort IDlse: egen HF2S_FirstWL2M = max(cond(WLM==2 & HF2S_Rel_Time==-1, 1, 0))
bysort IDlse: egen HF2S_LastWL2M  = max(cond(WLM==2 & HF2S_Rel_Time==0, 1, 0))
generate HF2S_Mngr_both_WL2 = (HF2S_FirstWL2M ==1 & HF2S_LastWL2M ==1)
replace  HF2S_Mngr_both_WL2 = . if HF2_Rel_Time==.
label variable HF2S_Mngr_both_WL2 "=1, if involving managers in the event are both at work level 2"
    //&? This variable is only defined for four event groups.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 6. save the dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth ///
    IDlseMHR HF2M HF2SM HF2_Mngr_both_WL2 HF2S_Mngr_both_WL2 ///
    ChangeMR ///
    HF2_Rel_Time ///
    HF2_LtoL HF2_LtoH HF2_HtoH HF2_HtoL HF2_Never_ChangeM ///
    HF2_Calend_Time_LtoL HF2_Calend_Time_LtoH HF2_Calend_Time_HtoH HF2_Calend_Time_HtoL ///
    HF2S_Rel_Time ///
    HF2S_LtoL HF2S_LtoH HF2S_HtoH HF2S_HtoL HF2S_Never_ChangeM ///
    HF2S_Calend_Time_LtoL HF2S_Calend_Time_LtoH HF2S_Calend_Time_HtoH HF2S_Calend_Time_HtoL

label drop _all

compress
save "${TempData}/02EventStudyDummies_HF2M_HF2SM.dta", replace

