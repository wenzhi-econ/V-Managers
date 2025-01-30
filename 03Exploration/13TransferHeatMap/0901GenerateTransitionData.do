/* 
This do file calculates different transfer numbers across jobs (event date versus 5 years after the event) for different groups.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== constructed in 0104 do file

Output:

RA: WWZ 
Time: 2025-01-29
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of event workers: work info
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. 5 years after the event date 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_Event_Time_5yrsLater = FT_Event_Time + 60 
format   FT_Event_Time_5yrsLater %tm 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. job info 5 years after the event date  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen Func_5yrsLater = mean(cond(YearMonth==FT_Event_Time_5yrsLater, Func, .))

sort IDlse YearMonth 
bysort IDlse: egen SubFunc_5yrsLater = mean(cond(YearMonth==FT_Event_Time_5yrsLater, SubFunc, .))

generate temp_StandardJob_5yrsLater = StandardJob if YearMonth==FT_Event_Time_5yrsLater
sort IDlse YearMonth 
bysort IDlse: egen StandardJob_5yrsLater = mode(temp_StandardJob_5yrsLater)
drop temp_StandardJob_5yrsLater

generate temp_ONETName_5yrsLater = ONETName if YearMonth==FT_Event_Time_5yrsLater
sort IDlse YearMonth 
bysort IDlse: egen ONETName_5yrsLater = mode(temp_ONETName_5yrsLater)
drop temp_ONETName_5yrsLater

keep IDlse YearMonth ///
    FT_Rel_Time FT_Mngr_both_WL2 FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    Func Func_5yrsLater ///
    SubFunc SubFunc_5yrsLater ///
    StandardJob StandardJob_5yrsLater ///
    ONETName ONETName_5yrsLater 

order IDlse YearMonth ///
    FT_Rel_Time FT_Mngr_both_WL2 FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    Func Func_5yrsLater ///
    SubFunc SubFunc_5yrsLater ///
    StandardJob StandardJob_5yrsLater ///
    ONETName ONETName_5yrsLater 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. keep a cross-section of event workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time==0 & FT_Mngr_both_WL2==1
    //&? same groups of workers in event studies 
    //&? 29,288 unique workers 

keep if FT_LtoL==1 | FT_LtoH==1  
    //&? keep only tow treatment groups 
    //&? 24,726 unique workers 

keep if ///
    (Func!=. & Func_5yrsLater!=.) ///
    | (SubFunc!=. & SubFunc_5yrsLater!=.) ///
    | (StandardJob!="" & StandardJob_5yrsLater!="") ///
    | (ONETName!="" & ONETName_5yrsLater!="")
        //&? keep only those workers with work information at 5 years after the event date
        //&? 9,007 workers 

tab FT_LtoL FT_LtoH

/* =1, if the |
    worker |
experience |
  s a low- |   =1, if the worker
        to | experiences a low- to
  low-type |   high-type manager
   manager |        change
    change |         0          1 |     Total
-----------+----------------------+----------
         0 |         0      1,208 |     1,208 
         1 |     7,799          0 |     7,799 
-----------+----------------------+----------
     Total |     7,799      1,208 |     9,007  */

keep IDlse FT_LtoL FT_LtoH ///
    Func Func_5yrsLater ///
    SubFunc SubFunc_5yrsLater ///
    StandardJob StandardJob_5yrsLater ///
    ONETName ONETName_5yrsLater

save "${TempData}/temp_TransitionJobs_5yrsAfterEvents.dta", replace 

