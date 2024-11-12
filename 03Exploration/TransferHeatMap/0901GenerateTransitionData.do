/* 
This do file calcualtes different transfer numbers across jobs (event date versus 5 years after the event) for different groups.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0102 do file.
    "${FinalData}/AllSnapshotMCulture.dta" <== ONET info is stored in the original dataset 

Output:

RA: WWZ 
Time: 2024-10-30
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of event workers: work info
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

merge 1:1 IDlse YearMonth using "${FinalData}/AllSnapshotMCulture.dta", keepusing(ONETName)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. calendar time of the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

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

keep if (Func!=. & Func_5yrsLater!=.) ///
    | (SubFunc!=. & SubFunc_5yrsLater!=.) ///
    | (StandardJob!="" & StandardJob_5yrsLater!="") ///
    | (ONETName!="" & ONETName_5yrsLater!="")
        //&? keep only those workers with work information at 5 years after the event date
        //&? 8,866 workers 

keep IDlse FT_LtoL FT_LtoH ///
    Func Func_5yrsLater ///
    SubFunc SubFunc_5yrsLater ///
    StandardJob StandardJob_5yrsLater ///
    ONETName ONETName_5yrsLater

save "${TempData}/temp_TransitionJobs_5yrsAfterEvents.dta", replace 

