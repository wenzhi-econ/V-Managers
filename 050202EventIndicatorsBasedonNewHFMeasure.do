/* 
Given a HF measure for managers, this do file constructs four oevent indicators.

This do file is adapted from "1.5.EventTeam2.do".


RA: WWZ 
Time: 2024-09-17
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. create a simplified dataset containing only relevant variables
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

keep ///
    IDlse YearMonth ChangeM TransferInternal TransferSJ IDlseMHR EarlyAgeM ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    WLM

order /// 
    IDlse YearMonth ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    WLM ///
    EarlyAgeM IDlseMHR
        // IDs, outcome variables, sample restriction variable, manager info
    
merge m:1 IDlseMHR using "${TempData}/ManagersTwoNewHFMeasures.dta", keep(master match) nogenerate

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a ChangeMR variable which equals to one for a qualified event
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. Restriction 1. 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*&& Changing manager for employee but employee does not change team at the same time 
generate ChangeMR = 0 
replace  ChangeMR = 1 if ChangeM==1 
replace  ChangeMR = 0 if TransferInternal==1 | TransferSJ==1 
replace  ChangeMR = . if ChangeM==.
replace  ChangeMR = . if IDlseMHR==. 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. Restriction 2. 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*&& Considering only first manager change observed in the data 
bys IDlse: egen EiChange = min(cond(ChangeM==1, YearMonth ,.)) // for single differences 
bys IDlse: egen Ei = mean(cond(ChangeMR==1 & YearMonth == EiChange, EiChange ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1
replace ChangeMR = 0 if ChangeMR==. 
format Ei %tm 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. manager transitions with different HF measures
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. Measure 1. EarlyAgeM (Original measure)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! LtoH
sort IDlse YearMonth
generate FT_LtoH = 0 if EarlyAgeM!=.
replace  FT_LtoH = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FT_LtoH = 0 if ChangeMR ==0

*!! HtoL
sort IDlse YearMonth
generate FT_HtoL = 0 if EarlyAgeM!=.
replace  FT_HtoL = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FT_HtoL = 0 if ChangeMR ==0

*!! HtoH 
sort IDlse YearMonth
generate FT_HtoH = 0 if EarlyAgeM!=.
replace  FT_HtoH = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FT_HtoH = 0 if ChangeMR ==0

*!! LtoL 
sort IDlse YearMonth
generate FT_LtoL = 0 if EarlyAgeM!=.
replace  FT_LtoL = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1] )
replace  FT_LtoL = 0 if ChangeMR ==0

*!! four event dates
bys IDlse: egen Calend_Time_FT_LtoH = mean(cond(FT_LtoH == 1, Ei,.)) 
bys IDlse: egen Calend_Time_FT_HtoL = mean(cond(FT_HtoL == 1, Ei,.)) 
bys IDlse: egen Calend_Time_FT_HtoH = mean(cond(FT_HtoH == 1, Ei,.)) 
bys IDlse: egen Calend_Time_FT_LtoL = mean(cond(FT_LtoL == 1, Ei,.)) 
format Calend_Time_FT_LtoH %tm
format Calend_Time_FT_LtoL %tm
format Calend_Time_FT_HtoH %tm
format Calend_Time_FT_HtoL %tm

generate FT_Never_ChangeM = . 
replace  FT_Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  FT_Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - Calend_Time_FT_LtoL if Calend_Time_FT_LtoL !=. 
replace  FT_Rel_Time = YearMonth - Calend_Time_FT_LtoH if Calend_Time_FT_LtoH !=. 
replace  FT_Rel_Time = YearMonth - Calend_Time_FT_HtoL if Calend_Time_FT_HtoL !=. 
replace  FT_Rel_Time = YearMonth - Calend_Time_FT_HtoH if Calend_Time_FT_HtoH !=. 

label variable FT_Rel_Time "relative date to event, . if event is Never_ChangeM or with unknown manager type"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. Measure 2. HF2M (based on age at WL2)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! LtoH
sort IDlse YearMonth
generate HF2_LtoH = 0 if HF2M!=.
replace  HF2_LtoH = 1 if (IDlse[_n]==IDlse[_n-1] & HF2M[_n]==1 & HF2M[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2_LtoH = 0 if ChangeMR ==0

*!! HtoL
sort IDlse YearMonth
generate HF2_HtoL = 0 if HF2M!=.
replace  HF2_HtoL = 1 if (IDlse[_n]==IDlse[_n-1] & HF2M[_n]==0 & HF2M[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2_HtoL = 0 if ChangeMR ==0

*!! HtoH 
sort IDlse YearMonth
generate HF2_HtoH = 0 if HF2M!=.
replace  HF2_HtoH = 1 if (IDlse[_n]==IDlse[_n-1] & HF2M[_n]==1 & HF2M[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF2_HtoH = 0 if ChangeMR ==0

*!! LtoL 
sort IDlse YearMonth
generate HF2_LtoL = 0 if HF2M!=.
replace  HF2_LtoL = 1 if (IDlse[_n]==IDlse[_n-1] & HF2M[_n]==0 & HF2M[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1] )
replace  HF2_LtoL = 0 if ChangeMR ==0

*!! four event dates
bys IDlse: egen HF2_Calend_Time_LtoH = mean(cond(HF2_LtoH == 1, Ei,.)) 
bys IDlse: egen HF2_Calend_Time_HtoL = mean(cond(HF2_HtoL == 1, Ei,.)) 
bys IDlse: egen HF2_Calend_Time_HtoH = mean(cond(HF2_HtoH == 1, Ei,.)) 
bys IDlse: egen HF2_Calend_Time_LtoL = mean(cond(HF2_LtoL == 1, Ei,.)) 
format HF2_Calend_Time_LtoH %tm
format HF2_Calend_Time_HtoL %tm
format HF2_Calend_Time_HtoH %tm
format HF2_Calend_Time_LtoL %tm

generate HF2_Never_ChangeM = . 
replace  HF2_Never_ChangeM = 1 if HF2_LtoH==0 & HF2_HtoL==0 & HF2_HtoH==0 & HF2_LtoL==0
replace  HF2_Never_ChangeM = 0 if HF2_LtoH==1 | HF2_HtoL==1 | HF2_HtoH==1 | HF2_LtoL==1

label variable HF2_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable HF2_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable HF2_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable HF2_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable HF2_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate HF2_Rel_Time = . 
replace  HF2_Rel_Time = YearMonth - HF2_Calend_Time_LtoL if HF2_Calend_Time_LtoL !=. 
replace  HF2_Rel_Time = YearMonth - HF2_Calend_Time_LtoH if HF2_Calend_Time_LtoH !=. 
replace  HF2_Rel_Time = YearMonth - HF2_Calend_Time_HtoL if HF2_Calend_Time_HtoL !=. 
replace  HF2_Rel_Time = YearMonth - HF2_Calend_Time_HtoH if HF2_Calend_Time_HtoH !=. 

label variable HF2_Rel_Time "relative date to event, . if event is Never_ChangeM or with unknown manager type"

*!! only work level 2 managers 
bysort IDlse: egen HF2_FirstWL2M = max(cond(WLM==2 & HF2_Rel_Time==-1, 1, 0))
bysort IDlse: egen HF2_LastWL2M  = max(cond(WLM==2 & HF2_Rel_Time==0, 1, 0))
generate HF2_Mngr_both_WL2 = (HF2_FirstWL2M ==1 & HF2_LastWL2M ==1)
label variable HF2_Mngr_both_WL2 "Only works with work level 2 managers"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. Measure 3. HF3M (based on tenure at WL2)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! LtoH
sort IDlse YearMonth
generate HF3_LtoH = 0 if HF3M!=.
replace  HF3_LtoH = 1 if (IDlse[_n]==IDlse[_n-1] & HF3M[_n]==1 & HF3M[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF3_LtoH = 0 if ChangeMR ==0

*!! HtoL
sort IDlse YearMonth
generate HF3_HtoL = 0 if HF3M!=.
replace  HF3_HtoL = 1 if (IDlse[_n]==IDlse[_n-1] & HF3M[_n]==0 & HF3M[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF3_HtoL = 0 if ChangeMR ==0

*!! HtoH 
sort IDlse YearMonth
generate HF3_HtoH = 0 if HF3M!=.
replace  HF3_HtoH = 1 if (IDlse[_n]==IDlse[_n-1] & HF3M[_n]==1 & HF3M[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  HF3_HtoH = 0 if ChangeMR ==0

*!! LtoL 
sort IDlse YearMonth
generate HF3_LtoL = 0 if HF3M!=.
replace  HF3_LtoL = 1 if (IDlse[_n]==IDlse[_n-1] & HF3M[_n]==0 & HF3M[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1] )
replace  HF3_LtoL = 0 if ChangeMR ==0

*!! four event dates
bys IDlse: egen HF3_Calend_Time_LtoH = mean(cond(HF3_LtoH == 1, Ei,.)) 
bys IDlse: egen HF3_Calend_Time_HtoL = mean(cond(HF3_HtoL == 1, Ei,.)) 
bys IDlse: egen HF3_Calend_Time_HtoH = mean(cond(HF3_HtoH == 1, Ei,.)) 
bys IDlse: egen HF3_Calend_Time_LtoL = mean(cond(HF3_LtoL == 1, Ei,.)) 
format HF3_Calend_Time_LtoH %tm
format HF3_Calend_Time_HtoL %tm
format HF3_Calend_Time_HtoH %tm
format HF3_Calend_Time_LtoL %tm

generate HF3_Never_ChangeM = . 
replace  HF3_Never_ChangeM = 1 if HF3_LtoH==0 & HF3_HtoL==0 & HF3_HtoH==0 & HF3_LtoL==0
replace  HF3_Never_ChangeM = 0 if HF3_LtoH==1 | HF3_HtoL==1 | HF3_HtoH==1 | HF3_LtoL==1

label variable HF3_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable HF3_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable HF3_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable HF3_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable HF3_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate HF3_Rel_Time = . 
replace  HF3_Rel_Time = YearMonth - HF3_Calend_Time_LtoL if HF3_Calend_Time_LtoL !=. 
replace  HF3_Rel_Time = YearMonth - HF3_Calend_Time_LtoH if HF3_Calend_Time_LtoH !=. 
replace  HF3_Rel_Time = YearMonth - HF3_Calend_Time_HtoL if HF3_Calend_Time_HtoL !=. 
replace  HF3_Rel_Time = YearMonth - HF3_Calend_Time_HtoH if HF3_Calend_Time_HtoH !=. 

label variable HF3_Rel_Time "relative date to event, . if event is Never_ChangeM or with unknown manager type"

*!! only work level 2 managers 
bysort IDlse: egen HF3_FirstWL2M = max(cond(WLM==2 & HF3_Rel_Time==-1, 1, 0))
bysort IDlse: egen HF3_LastWL2M  = max(cond(WLM==2 & HF3_Rel_Time==0, 1, 0))
generate HF3_Mngr_both_WL2 = (HF3_FirstWL2M ==1 & HF3_LastWL2M ==1)
label variable HF3_Mngr_both_WL2 "Only works with work level 2 managers"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. construct "event * relative date" dummies
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize FT_Rel_Time, detail  // range: [-131, +130]
summarize HF2_Rel_Time, detail // range: [-131, +130]
summarize HF3_Rel_Time, detail // range: [-113, +130]

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. dummies for HF2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! ordinary "event * relative date" dummies 
local max_pre_period  = 36 
local max_post_period = 84

foreach event in HF2_LtoL HF2_LtoH HF2_HtoL HF2_HtoH {
    forvalues time = 1/`max_pre_period' {
        generate byte `event'_X_Pre`time' = `event' * (HF2_Rel_Time == -`time')
    }
}
foreach event in HF2_LtoL HF2_LtoH HF2_HtoL HF2_HtoH {
    forvalues time = 0/`max_post_period' {
        generate byte `event'_X_Post`time' = `event' * (HF2_Rel_Time == `time')
    }
}

*!! binned absorbing "event * relative date" dummies for pre- and post-event periods 
foreach event in HF2_LtoL HF2_LtoH HF2_HtoL HF2_HtoH {
    generate byte `event'_X_Pre_Before36 = `event' * (HF2_Rel_Time < -36)
}

foreach event in HF2_LtoL HF2_LtoH HF2_HtoL HF2_HtoH {
    generate byte `event'_X_Post_After84 = `event' * (HF2_Rel_Time > 84)
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. dummies for HF3
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! ordinary "event * relative date" dummies 
foreach event in HF3_LtoL HF3_LtoH HF3_HtoL HF3_HtoH {
    forvalues time = 1/`max_pre_period' {
        generate byte `event'_X_Pre`time' = `event' * (HF3_Rel_Time == -`time')
    }
}
foreach event in HF3_LtoL HF3_LtoH HF3_HtoL HF3_HtoH {
    forvalues time = 0/`max_post_period' {
        generate byte `event'_X_Post`time' = `event' * (HF3_Rel_Time == `time')
    }
}

*!! binned absorbing "event * relative date" dummies for pre- and post-event periods 
foreach event in HF3_LtoL HF3_LtoH HF3_HtoL HF3_HtoH {
    generate byte `event'_X_Pre_Before36 = `event' * (HF3_Rel_Time < -36)
}

foreach event in HF3_LtoL HF3_LtoH HF3_HtoL HF3_HtoH {
    generate byte `event'_X_Post_After84 = `event' * (HF3_Rel_Time > 84)
}

save "${TempData}/temp_MainOutcomesInEventStudies_TwoNewHFMeasures.dta", replace

