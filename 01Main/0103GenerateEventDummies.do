/* 
This do file 
    (1) identifies the first eligible manager change a worker experiences; and
    (2) constructs a set of dummies for the four treatment groups based on EarlyAgeM measure.

Input:
    "${TempData}/01WorkersOutcomes.dta" <== created in 0101 do file
    "${TempData}/02Mngr_EarlyAgeM.dta"  <== created in 0102 do file 

Output:
    "${TempData}/temp_Mngr_WL.dta         <== auxiliary dataset 
    "${TempData}/03EventStudyDummies.dta" <== output dataset

Description of the Output Dataset:
    It adds more variables to the "${TempData}/01WorkersOutcomes.dta" dataset.
    In particular, a set of event-related variables:
        EarlyAgeM ChangeMR ///
        FT_Mngr_both_WL2 FT_Never_ChangeM ///
        FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time FT_Calend_Time_*

RA: WWZ 
Time: 2024-11-19
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

merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 

label variable EarlyAgeM "=1, if the manager is a high-flyer (determined by age at promotion)"

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
generate FTLowLow = 0 if EarlyAgeM!=.
replace  FTLowLow = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1] )
replace  FTLowLow = 0 if ChangeMR==0 & FTLowLow!=.

*!! LtoH
sort IDlse YearMonth 
generate FTLowHigh = 0 if EarlyAgeM!=.
replace  FTLowHigh = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FTLowHigh = 0 if ChangeMR==0 & FTLowHigh!=.

*!! HtoH 
sort IDlse YearMonth
generate FTHighHigh = 0 if EarlyAgeM!=.
replace  FTHighHigh = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FTHighHigh = 0 if ChangeMR==0 & FTHighHigh!=.

*!! HtoL
sort IDlse YearMonth
generate FTHighLow = 0 if EarlyAgeM!=.
replace  FTHighLow = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FTHighLow = 0 if ChangeMR==0 & FTHighLow!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. event dates of the four types of manager change 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! event time of the four events 
bys IDlse: egen FT_Calend_Time_LtoL = mean(cond(FTLowLow   == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen FT_Calend_Time_LtoH = mean(cond(FTLowHigh  == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen FT_Calend_Time_HtoH = mean(cond(FTHighHigh == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen FT_Calend_Time_HtoL = mean(cond(FTHighLow  == 1, Date_FirstMngrChange, .)) 
format FT_Calend_Time_LtoL %tm
format FT_Calend_Time_LtoH %tm
format FT_Calend_Time_HtoH %tm
format FT_Calend_Time_HtoL %tm

*!! calendar time of the event 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

label variable FT_Calend_Time_LtoL "year-month when the LtoL event takes place, non-missing only for LtoL workers"
label variable FT_Calend_Time_LtoH "year-month when the LtoH event takes place, non-missing only for LtoH workers"
label variable FT_Calend_Time_HtoH "year-month when the HtoH event takes place, non-missing only for HtoH workers"
label variable FT_Calend_Time_HtoL "year-month when the HtoL event takes place, non-missing only for HtoL workers"
label variable FT_Event_Time       "year-month when the event take place, non-missing only when FT_Never_ChangeM==0"

drop FTLowLow FTLowHigh FTHighHigh FTHighLow
    //&? Drop these auxiliary variables, which are only defined at the event time.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. five event dummies: 4 types of treatment + 1 never-treated
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_LtoL = 0 
replace  FT_LtoL = 1 if FT_Calend_Time_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if FT_Calend_Time_LtoH != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if FT_Calend_Time_HtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if FT_Calend_Time_HtoL != .

generate FT_Never_ChangeM = . 
replace  FT_Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  FT_Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1
    //&? FT_Never_ChangeM is also equal to one in the case where the event is involved with the un-identified manager(s).

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_Never_ChangeM "=0, if the worker experiences an identifiable manager change"
    //&? By identifiable, I mean both pre- and post-event managers can be identified using the EarlyAgeM measure.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-4. relative date to the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 

label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

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
bysort IDlse: egen FirstWL2M = max(cond(WLM==2 & FT_Rel_Time==-1, 1, 0))
bysort IDlse: egen LastWL2M  = max(cond(WLM==2 & FT_Rel_Time==0, 1, 0))
generate FT_Mngr_both_WL2 = (FirstWL2M ==1 & LastWL2M ==1)
replace  FT_Mngr_both_WL2 = . if FT_Rel_Time==.
label variable FT_Mngr_both_WL2 "=1, if involving managers in the event are both at work level 2"
    //&? This variable is only defined for four event groups.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 6. save the dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

order IDlse YearMonth ///
    IDlseMHR EarlyAgeM ChangeMR ///
    FT_Mngr_both_WL2 FT_Never_ChangeM ///
    FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time FT_Calend_Time_*

compress
save "${TempData}/03EventStudyDummies.dta", replace

