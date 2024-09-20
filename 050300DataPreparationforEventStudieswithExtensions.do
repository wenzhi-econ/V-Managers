/* 
This do file extends the dataset "${TempData}/temp_MainOutcomesInEventStudies.dta" (obtained in do file 0300*) with the original random sample indicator (in June 14, 2022 version).

Input:
    "${FinalData}/AllSameTeam2.dta"
    "${TempData}/Random50vw.dta"

Output:
    "${TempData}/temp_MainOutcomesInEventStudies_Extensions.dta"
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create the main event study dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    TransferSJ TransferSJC TransferFunc TransferFuncC TransferSJSameM /// 
    IDlse YearMonth IDlseMHR EarlyAgeM WLM ChangeMR ///
    WL2 ///
    FTHL FTLL FTHH FTLH 

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ChangeMR WLM ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    TransferSJ TransferSJC TransferFunc TransferFuncC TransferSJSameM /// 
    WL2 ///
    FTLL FTLH FTHH FTHL
        // IDs, manager info, outcome variables, sample restriction variable, treatment info

rename WL2 FT_Mngr_both_WL2 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. construct (individual level) event dummies 
*-?       and (individual-month level) relative dates to the event
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! calendar time of the event
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHH FT_Calend_Time_HtoH
rename FTHL FT_Calend_Time_HtoL

*!! five event dummies: 4 types of treatment + 1 never-treated
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

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 

label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. construct "event * relative date" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

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

compress

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. get the same random sample of control workers as the original paper
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sort IDlse YearMonth 
bysort IDlse: generate occurrence = _n

merge m:1 IDlse using  "${TempData}/Random50vw.dta"
drop _merge 
rename random50 random

tabulate random FT_Never_ChangeM if occurrence==1, missing 
    //&& workers in all five event groups can be drawn randomly, 
    //&& but in the regression, we only use a random sample of control workers
/* 
           |   =1, if the worker
           |  never experiences a
           |    manager change
    random |         0          1 |     Total
-----------+----------------------+----------
         1 |    41,017     59,374 |   100,391 
         . |    50,431     73,295 |   123,726 
-----------+----------------------+----------
     Total |    91,448    132,669 |   224,117 
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. a disparity between different treatment groups
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

tabulate FT_Never_ChangeM if occurrence==1, missing 
/* 
 =1, if the |
     worker |
      never |
experiences |
  a manager |
     change |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     91,448       40.80       40.80
          1 |    132,669       59.20      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/
tabulate FT_LtoL if occurrence==1, missing 
/* 
 =1, if the |
     worker |
experiences |
  a low- to |
   low-type |
    manager |
     change |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    156,192       69.69       69.69
          1 |     67,925       30.31      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/
tabulate FT_LtoH if occurrence==1, missing 
/* 
 =1, if the |
     worker |
experiences |
  a low- to |
  high-type |
    manager |
     change |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    213,203       95.13       95.13
          1 |     10,914        4.87      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/
tabulate FT_HtoH if occurrence==1, missing 
/* 
 =1, if the |
     worker |
experiences |
 a high- to |
  high-type |
    manager |
     change |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    219,991       98.16       98.16
          1 |      4,126        1.84      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/
tabulate FT_HtoL if occurrence==1, missing 
/* 
 =1, if the |
     worker |
experiences |
 a high- to |
   low-type |
    manager |
     change |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    215,634       96.21       96.21
          1 |      8,483        3.79      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. more restrictions on control workers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

order IDlse YearMonth IDlseMHR EarlyAgeM ChangeMR WLM FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Mngr_both_WL2 FT_Never_ChangeM FT_Rel_Time

generate temp_FT_Mngr_First_WL2 = (WLM==2) if occurrence==1 & FT_Never_ChangeM==1
sort IDlse YearMonth 
bysort IDlse: egen FT_Mngr_First_WL2 = mean(temp_FT_Mngr_First_WL2)
drop temp_FT_Mngr_First_WL2

order FT_Mngr_First_WL2, after(FT_Never_ChangeM)


save "${TempData}/temp_MainOutcomesInEventStudies_Extensions.dta", replace 