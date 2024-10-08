/* 
This do file constructs a HT measure for managers (EarlyAgeM), and uses this measure to define four treatment groups: LtoL LtoH HtoH HtoL. 

Next, all dummies used in event study regressions are generated.

RA: WWZ 
Time: 2024-10-07
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate a FT measure: EarlyAgeM
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

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-1. a set of auxiliary variables 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate WLAgg = WL
replace  WLAgg = 5 if WL>4 & WL!=.

//&? starting work level 
bysort IDlse: egen MinWL = min(WLAgg)  
//&? last observed work level 
bysort IDlse: egen MaxWL = max(WLAgg)

//&? age when the worker starts his last observed WL 
bysort IDlse: egen AgeMinMaxWL = min(cond(WL == MaxWL, AgeBand, .)) 
//&? number of months a worker is in his last observed WL
bysort IDlse: egen TenureMaxWLMonths = count(cond(WL==MaxWL, YearMonth, .) ) 
//&? number of years a worker is in his last observed WL
generate TenureMaxWL = TenureMaxWLMonths/12 
//&? tenure when the worker starts his last observed WL 
bysort IDlse: egen TenureMinMaxWL = min(cond(WL==MaxWL, Tenure, .)) 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-2. variable EarlyAge: if the worker is a fast-track manager 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

summarize TenureMaxWL if MaxWL ==2 & occurrence==1, detail 

generate EarlyAge = 0 
replace  EarlyAge = 1 if MinWL==1 & MaxWL==2 & TenureMinMaxWL<=4 & TenureMaxWL<=6 
replace  EarlyAge = 1 if MaxWL==2 & AgeMinMaxWL==1 & TenureMaxWL<=6 
replace  EarlyAge = 1 if MaxWL==3 & AgeMinMaxWL<=2 & TenureMinMaxWL<=10 
replace  EarlyAge = 1 if MaxWL==4 & AgeMinMaxWL<=2 
replace  EarlyAge = 1 if MaxWL>4  & AgeMinMaxWL<=3 
label variable EarlyAge "Fast track  manager based on age when promoted (WL)"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-3. get a dataset of id EarlyAge  
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

preserve 

    keep IDlse EarlyAge 
    duplicates drop 
    rename IDlse IDlseMHR 
    rename EarlyAge EarlyAgeM

    save "${TempData}/temp_Mngr_FT.dta", replace 

restore 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-4. merge back manager's FT measure to the main dataset  
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

merge m:1 IDlseMHR using "${TempData}/temp_Mngr_FT.dta", keep(match) nogenerate 
    //&? Sample restriction happens here, which does not matter since finally we need to merge this dataset back to the main datase.

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
*?? step 3. four set of treatment groups
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. indicator of four types of manager change 
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
*-? s-3-2. event dates of the four types of manager change 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! four event dates
bys IDlse: egen FT_Calend_Time_LtoL = mean(cond(FTLowLow   == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen FT_Calend_Time_LtoH = mean(cond(FTLowHigh  == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen FT_Calend_Time_HtoH = mean(cond(FTHighHigh == 1, Date_FirstMngrChange, .)) 
bys IDlse: egen FT_Calend_Time_HtoL = mean(cond(FTHighLow  == 1, Date_FirstMngrChange, .)) 
format FT_Calend_Time_LtoL %tm
format FT_Calend_Time_LtoH %tm
format FT_Calend_Time_HtoH %tm
format FT_Calend_Time_HtoL %tm

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. five event dummies: 4 types of treatment + 1 never-treated
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

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_Never_ChangeM "=1, if the worker never experiences a manager change"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. relative date to the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 

label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. event * period dummies 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize FT_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 36 
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! FT_LtoL
generate byte FT_LtoL_X_Pre_Before`max_pre_period' = FT_LtoL * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_LtoL_X_Pre`time' = FT_LtoL * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte FT_LtoL_X_Post`time' = FT_LtoL * (FT_Rel_Time == `time')
}
generate byte FT_LtoL_X_Post_After`Lto_max_post_period' = FT_LtoL * (FT_Rel_Time > `Lto_max_post_period')

*!! FT_LtoH
generate byte FT_LtoH_X_Pre_Before`max_pre_period' = FT_LtoH * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_LtoH_X_Pre`time' = FT_LtoH * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte FT_LtoH_X_Post`time' = FT_LtoH * (FT_Rel_Time == `time')
}
generate byte FT_LtoH_X_Post_After`Lto_max_post_period' = FT_LtoH * (FT_Rel_Time > `Lto_max_post_period')

*!! FT_HtoH 
generate byte FT_HtoH_X_Pre_Before`max_pre_period' = FT_HtoH * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_HtoH_X_Pre`time' = FT_HtoH * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte FT_HtoH_X_Post`time' = FT_HtoH * (FT_Rel_Time == `time')
}
generate byte FT_HtoH_X_Post_After`Hto_max_post_period' = FT_HtoH * (FT_Rel_Time > `Hto_max_post_period')

*!! FT_HtoL 
generate byte FT_HtoL_X_Pre_Before`max_pre_period' = FT_HtoL * (FT_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte FT_HtoL_X_Pre`time' = FT_HtoL * (FT_Rel_Time == -`time')
}
forvalues time = 0/`Hto_max_post_period' {
    generate byte FT_HtoL_X_Post`time' = FT_HtoL * (FT_Rel_Time == `time')
}
generate byte FT_HtoL_X_Post_After`Hto_max_post_period' = FT_HtoL * (FT_Rel_Time > `Hto_max_post_period')

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
bysort IDlse: egen FirstWL2M = max(cond(WLM==2 & FT_Rel_Time==-1, 1, 0))
bysort IDlse: egen LastWL2M  = max(cond(WLM==2 & FT_Rel_Time==0, 1, 0))
generate FT_Mngr_both_WL2 = (FirstWL2M ==1 & LastWL2M ==1)
label variable FT_Mngr_both_WL2 "Only works with work level 2 managers"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 6. save the dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth ///
    IDlseMHR EarlyAgeM WLM ///
    ChangeMR FT_Rel_Time ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Never_ChangeM ///
    FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL ///
    FT_Mngr_both_WL2 ///
    FT_LtoL_X_Pre* FT_LtoL_X_Post* ///
    FT_LtoH_X_Pre* FT_LtoH_X_Post* ///
    FT_HtoH_X_Pre* FT_HtoH_X_Post* ///
    FT_HtoL_X_Pre* FT_HtoL_X_Post* ///

label drop _all

compress
save "${TempData}/02EventStudyDummies.dta", replace

