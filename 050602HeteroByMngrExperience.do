/* 
This do file extends Table VII by investigating heterogeneity based on post-event manager's pre-event experiences.

Step 1 is used to construct managers' pre-event characteristics (experience):
    num_job_                number of jobs before events / number of months before events 
    num_SubFunc_            number of subfunctions before events / number of months before events
    num_Func_               number of functions before events / number of months before events
    ONETSkillsDistance_     (sum of skill difference when a manager changes his job before events / number of jobs before events) / number of months before events

Step 2 merges managers' pre-event experience variables into the main dataset.
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. consturct pre-event manager characteristics  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    SubFunc Func StandardJob StandardJobCode ONETSkillsDistance ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    FTHL FTLL FTHH FTLH

order ///
    IDlse YearMonth ///
    SubFunc Func StandardJob StandardJobCode ONETSkillsDistance ///
    EarlyAgeM IDlseMHR ///
    FTLL FTLH FTHH FTHL
        // IDs, manager info, outcome variables, sample restriction variable, treatment info

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. construct date-related event dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! calendar time of the event
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHH FT_Calend_Time_HtoH
rename FTHL FT_Calend_Time_HtoL

*!! calendar time of the event 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm
label variable FT_Event_Time "Event date, . if no manager change or with unidentified manager"

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 
label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. an auxiliary dataset containing manager id and event dates 
*-?        Note. A manager can be involved into different event dates (max 20)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

preserve 

    keep IDlse IDlseMHR FT_Rel_Time FT_Event_Time

    keep if FT_Rel_Time==0 
        // keep a cross-sectional of four treatment groups 
    keep IDlseMHR FT_Event_Time 
        // keep manager id and event time
        // so that I can calculate manager's pre-event characteristics
    duplicates drop 

    codebook IDlseMHR
        // 24,141 unique values 

    sort IDlseMHR FT_Event_Time
    bysort IDlseMHR: generate occurrence = _n 
    summarize occurrence, detail // [1, 20]

    reshape wide FT_Event_Time, i(IDlseMHR) j(occurrence)
    
    rename IDlseMHR IDlse 

    save "${TempData}/temp_MngrIDAndEventTime_Wide.dta", replace 

restore 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. obtain managers' pre-event characteristics (experience)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlse using "${TempData}/temp_MngrIDAndEventTime_Wide.dta", nogenerate keep(match) 
    // keep only matched managers

sort IDlse YearMonth

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-4-1: calculate number of months a manager is in the dataset before events 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
generate one = 1 
forvalues i = 1/20 {
    *&& =1, at the YearMonth that is not larger that the event date FT_Event_Time`i'
    generate one_`i' = one 
    replace  one_`i' = .   if FT_Event_Time`i'==.
    replace  one_`i' = 0   if YearMonth > FT_Event_Time`i'
}
forvalues i = 1/20 {
    sort IDlse YearMonth 
    bysort IDlse: egen num_month_`i' = total(one_`i')
}

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-4-2: calculate number of jobs a manager experienced before events 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
generate change_job = . 
replace  change_job = 1 if IDlse[_n]==IDlse[_n-1] & StandardJobCode[_n]!=StandardJobCode[_n-1] & StandardJobCode[_n]!=. & StandardJobCode[_n-1]!=.
replace  change_job = 0 if IDlse[_n]==IDlse[_n-1] & StandardJobCode[_n]==StandardJobCode[_n-1]

forvalues i = 1/20 {
    *&& =1, at the YearMonth when a worker changed his job before the corresponding FT_Event_Time_`i'
    generate change_job_`i' = change_job if FT_Event_Time`i' != .
    replace  change_job_`i' = 0 if change_job==1 & YearMonth>FT_Event_Time`i'
        // this step adjusts managers' post-event job changes
}
forvalues i = 1/20 {
    bysort IDlse: egen num_job_`i' = total(change_job_`i') 
        //&& how many times a manager changed his job before event dates
    replace num_job_`i' = num_job_`i' + 1
        //&& number of jobs a manager experienced before event dates
}

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-4-3: calculate number of SubFunc a manager experienced before events 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
generate change_SubFunc = . 
replace  change_SubFunc = 1 if IDlse[_n]==IDlse[_n-1] & SubFunc[_n]!=SubFunc[_n-1] & SubFunc[_n]!=. & SubFunc[_n-1]!=.
replace  change_SubFunc = 0 if IDlse[_n]==IDlse[_n-1] & SubFunc[_n]==SubFunc[_n-1]

forvalues i = 1/20 {
    *&& =1, at the YearMonth when a worker changed his SubFunc before the corresponding FT_Event_Time_`i'
    generate change_SubFunc_`i' = change_SubFunc if FT_Event_Time`i' != .
    replace  change_SubFunc_`i' = 0 if change_SubFunc==1 & YearMonth>FT_Event_Time`i'
        // this step adjusts managers' post-event SubFunc changes
}
forvalues i = 1/20 {
    bysort IDlse: egen num_SubFunc_`i' = total(change_SubFunc_`i') 
        //&& how many times a manager changed his SubFunc before event dates
    replace num_SubFunc_`i' = num_SubFunc_`i' + 1
        //&& number of SubFunc a manager experienced before event dates
}

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-4-4: calculate number of Func a manager experienced before events 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
generate change_Func = . 
replace  change_Func = 1 if IDlse[_n]==IDlse[_n-1] & Func[_n]!=Func[_n-1] & Func[_n]!=. & Func[_n-1]!=.
replace  change_Func = 0 if IDlse[_n]==IDlse[_n-1] & Func[_n]==Func[_n-1]

forvalues i = 1/20 {
    *&& =1, at the YearMonth when a worker changed his Func before the corresponding FT_Event_Time_`i'
    generate change_Func_`i' = change_Func if FT_Event_Time`i' != .
    replace  change_Func_`i' = 0 if change_Func==1 & YearMonth>FT_Event_Time`i'
        // this step adjusts managers' post-event Func changes
}
forvalues i = 1/20 {
    bysort IDlse: egen num_Func_`i' = total(change_Func_`i') 
        //&& how many times a manager changed his Func before event dates
    replace num_Func_`i' = num_Func_`i' + 1
        //&& number of Func a manager experienced before event dates
}

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-4-5: calculate average ONET skill difference a manager experienced before events 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
forvalues i = 1/20 {
    *&& =1, at the YearMonth when a worker changed his Func before the corresponding FT_Event_Time_`i'
    generate ONETSkillsDistance_`i' = ONETSkillsDistance if FT_Event_Time`i' != .
    replace  ONETSkillsDistance_`i' = 0 if ONETSkillsDistance_`i'>0 & YearMonth>FT_Event_Time`i' 
        // this step adjusts managers' post-event skill content changes
}
forvalues i = 1/20 {
    bysort IDlse: egen num_ONETSkillsDistance_`i' = total(ONETSkillsDistance_`i') 
    replace num_ONETSkillsDistance_`i' = num_ONETSkillsDistance_`i' / num_job_`i'
}

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-4-6: divide the above four variables by number of months  
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
forvalues i = 1/20 {
    replace num_job_`i'                = num_job_`i'             / num_month_`i'
    replace num_SubFunc_`i'            = num_SubFunc_`i'         / num_month_`i'
    replace num_Func_`i'               = num_Func_`i'            / num_month_`i'
    replace num_ONETSkillsDistance_`i' = num_ONETSkillsDistance_`i'  / num_month_`i'
}

keep IDlse FT_Event_Time1-FT_Event_Time20 num_job_* num_SubFunc_* num_Func_* num_ONETSkillsDistance_* 
duplicates drop 

reshape long FT_Event_Time num_job_ num_SubFunc_ num_Func_ num_ONETSkillsDistance_, i(IDlse) j(occurrence)

drop occurrence 
rename IDlse IDlseMHR
drop if FT_Event_Time==.

save "${TempData}/temp_MngrExperienceBeforeEvents.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct a main dataset   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

keep ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    WL2 ///
    FTLL FTLH FTHH FTHL

rename WL2 FT_Mngr_both_WL2 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. construct (individual level) event dummies 
*-?       and (individual-month level) relative dates to the event
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! calendar time of the event
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHH FT_Calend_Time_HtoH
rename FTHL FT_Calend_Time_HtoL

*!! calendar time of the event 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm
label variable FT_Event_Time "Event date, . if no manager change or with unidentified manager"

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

*!! "event * post" (ind-month level) for four treatment groups
generate FT_Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .
generate FT_LtoLXPost = FT_LtoL * FT_Post
generate FT_LtoHXPost = FT_LtoH * FT_Post
generate FT_HtoHXPost = FT_HtoH * FT_Post
generate FT_HtoLXPost = FT_HtoL * FT_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. merge to obtain managers' pre-events characteristics 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR FT_Event_Time using "${TempData}/temp_MngrExperienceBeforeEvents.dta", 

sort IDlse YearMonth 
bysort IDlse: egen temp_num_job_ = mean(num_job_)
bysort IDlse: egen temp_num_SubFunc_ = mean(num_SubFunc_)
bysort IDlse: egen temp_num_Func_ = mean(num_Func_)
bysort IDlse: egen temp_num_ONETSkillsDistance_ = mean(num_ONETSkillsDistance_)

replace num_job_ = temp_num_job_ if FT_Rel_Time < 0 & temp_num_job_ != . & num_job_ == .
replace num_SubFunc_ = temp_num_SubFunc_ if FT_Rel_Time < 0 & temp_num_SubFunc_ != . & num_SubFunc_ == .
replace num_Func_ = temp_num_Func_ if FT_Rel_Time < 0 & temp_num_Func_ != . & num_Func_ == .
replace num_ONETSkillsDistance_ = temp_num_ONETSkillsDistance_ if FT_Rel_Time < 0 & temp_num_ONETSkillsDistance_ != . & num_ONETSkillsDistance_ == .

drop temp_*

sort IDlse YearMonth 
bysort IDlse: generate occurrence = _n 

summarize num_job_ if occurrence == 1, detail 
    global num_job_Median = r(p50)
summarize num_SubFunc_ if occurrence == 1, detail 
    global num_SubFunc_Median = r(p50)
summarize num_Func_ if occurrence == 1, detail 
    global num_Func_Median = r(p50)
summarize num_ONETSkillsDistance_ if occurrence == 1, detail 
    global num_ONETSkillsDistance_Median = r(p50) //&& IMPORTANT: median = min = 0

generate FT_num_job_AboveM = (num_job_ >= ${num_job_Median})
generate FT_num_SubFunc_AboveM = (num_SubFunc_ >= ${num_SubFunc_Median})
generate FT_num_Func_AboveM = (num_Func_ >= ${num_Func_Median})
generate FT_num_ONETSkillsDistance_AboveM = (num_ONETSkillsDistance_ > ${num_ONETSkillsDistance_Median})

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. interact managers' pre-events characteristics with treatment dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_LtoLXPostXnum_job_AboveM = FT_LtoLXPost * FT_num_job_AboveM
generate FT_LtoHXPostXnum_job_AboveM = FT_LtoHXPost * FT_num_job_AboveM
generate FT_HtoHXPostXnum_job_AboveM = FT_HtoHXPost * FT_num_job_AboveM
generate FT_HtoLXPostXnum_job_AboveM = FT_HtoLXPost * FT_num_job_AboveM

generate FT_LtoLXPostXnum_SubFunc_AboveM = FT_LtoLXPost * FT_num_SubFunc_AboveM
generate FT_LtoHXPostXnum_SubFunc_AboveM = FT_LtoHXPost * FT_num_SubFunc_AboveM
generate FT_HtoHXPostXnum_SubFunc_AboveM = FT_HtoHXPost * FT_num_SubFunc_AboveM
generate FT_HtoLXPostXnum_SubFunc_AboveM = FT_HtoLXPost * FT_num_SubFunc_AboveM

generate FT_LtoLXPostXnum_Func_AboveM = FT_LtoLXPost * FT_num_Func_AboveM
generate FT_LtoHXPostXnum_Func_AboveM = FT_LtoHXPost * FT_num_Func_AboveM
generate FT_HtoHXPostXnum_Func_AboveM = FT_HtoHXPost * FT_num_Func_AboveM
generate FT_HtoLXPostXnum_Func_AboveM = FT_HtoLXPost * FT_num_Func_AboveM

generate FT_LtoLXPostXnum_ONET_AboveM = FT_LtoLXPost * FT_num_ONETSkillsDistance_AboveM
generate FT_LtoHXPostXnum_ONET_AboveM = FT_LtoHXPost * FT_num_ONETSkillsDistance_AboveM
generate FT_HtoHXPostXnum_ONET_AboveM = FT_HtoHXPost * FT_num_ONETSkillsDistance_AboveM
generate FT_HtoLXPostXnum_ONET_AboveM = FT_HtoLXPost * FT_num_ONETSkillsDistance_AboveM

save "${TempData}/temp_HeteroByMngrExperience.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_HeteroByMngrExperience.dta", clear 


global Hetero_Vars num_job_AboveM num_SubFunc_AboveM num_Func_AboveM num_ONET_AboveM

foreach hetero_var in $Hetero_Vars {
    global hetero_regressors ///
        FT_LtoLXPost FT_LtoLXPostX`hetero_var' ///
        FT_LtoHXPost FT_LtoHXPostX`hetero_var' ///
        FT_HtoHXPost FT_HtoHXPostX`hetero_var' ///
        FT_HtoLXPost FT_HtoLXPostX`hetero_var'

    foreach outcome in TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC {
        reghdfe `outcome' $hetero_regressors  ///
            if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) ///
            , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
    
        xlincom (FT_LtoHXPostX`hetero_var' - FT_LtoLXPostX`hetero_var'), level(95) post

        if "`outcome'" == "TransferSJVC" {
            local outcome_name TSJVC
        }
        if "`outcome'" == "TransferFuncC" {
            local outcome_name TFC
        }
        if "`outcome'" == "PromWLC" {
            local outcome_name PWLC
        }
        if "`outcome'" == "ChangeSalaryGradeC" {
            local outcome_name CSGC
        }

        est store `hetero_var'_`outcome_name'
    }
}

esttab num_job_AboveM_TSJVC num_job_AboveM_TFC num_job_AboveM_PWLC num_job_AboveM_CSGC using "${Results}/HeterogeneityByMngrExperience_OneQuarterEstimate.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager's normalized number of jobs, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{Lateral moves} & \multicolumn{1}{c}{Cross-function moves} & \multicolumn{1}{c}{Vertical moves} & \multicolumn{1}{c}{Pay grade increase} \\") ///
    posthead("") prefoot("") postfoot("")
esttab num_SubFunc_AboveM_TSJVC num_SubFunc_AboveM_TFC num_SubFunc_AboveM_PWLC num_SubFunc_AboveM_CSGC using "${Results}/HeterogeneityByMngrExperience_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager's normalized number of subfunctions, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab num_Func_AboveM_TSJVC num_Func_AboveM_TFC num_Func_AboveM_PWLC num_Func_AboveM_CSGC using "${Results}/HeterogeneityByMngrExperience_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager's normalized number of functions, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab num_ONET_AboveM_TSJVC num_ONET_AboveM_TFC num_ONET_AboveM_PWLC num_ONET_AboveM_CSGC using "${Results}/HeterogeneityByMngrExperience_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager's normalized ONET skill difference, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes." "\end{tablenotes}")
