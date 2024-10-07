/* 
This do file does the following exercise:
    We focus on the (a) standard job code (b) sub function (c) function a worker is in exactly 5 years after the manager change.
    Compute the total number of consecutive months in that job (from the first month they are in the job).
    Take the log of the duration and run censored normal regressions where the X variables are LH, LL, HL, HH transition but then compute the gap.
    Control for country FE and time FE and function FE taken at the month of the manager transition (as the dataset is a cross section).

RA: WWZ 
Time: 2024-09-23
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. get a simplified dataset containing only relevant variables
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    SubFunc Func StandardJob StandardJobCode ISOCode /// 
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    SubFunc Func StandardJob StandardJobCode ISOCode /// 
    WL2 ///
    FTLL FTLH FTHH FTHL
        // IDs, manager info, outcome variables, sample restriction variable, treatment info

rename WL2 FT_Mngr_both_WL2 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. construct (individual level) event-related variables
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

*!! event date 
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 
format   FT_Event_Time %tm 

label variable FT_Event_Time "Event date, . if no manager change or with unidentified manager"

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 

label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

keep if FT_Never_ChangeM==0
    //&& keep only four event groups, since we can only define job after 5 years of event for them

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. job tenure variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
order IDlse, before(occurrence)

*-? First, determine the job number 5 years after the event 
    //&& a job number is determined by chaning a job (i.e., 0 is his first job, 1 is his second job, ...)
    //&& since we only care about tenure at a specific job, there is actually no need to know the exact job information

*!! =1, at the YM when a worker changed his job
generate change_job = . 
replace  change_job = 1 if IDlse[_n]==IDlse[_n-1] & StandardJobCode[_n]!=StandardJobCode[_n-1] & StandardJobCode[_n]!=. & StandardJobCode[_n-1]!=.
replace  change_job = 0 if IDlse[_n]==IDlse[_n-1] & StandardJobCode[_n]==StandardJobCode[_n-1]

*!! assign job number 
sort IDlse YearMonth 
bysort IDlse: generate job_num = sum(change_job)

*!! determine job number 5 years after the event 
generate temp_job_num_5yrsLater = job_num if YearMonth == FT_Event_Time + 60 
sort IDlse YearMonth
bysort IDlse: egen job_num_5yrsLater = mean(temp_job_num_5yrsLater)
drop temp_job_num_5yrsLater

*-? Next, calculate the job tenure for that job 

*!! =1, if he is at the same job as the job 5 years after the event
generate same_job_as_5yrsLater = (job_num==job_num_5yrsLater) if job_num_5yrsLater!=.

*!! job tenure for the exact job he is in 5 years after the event
bysort IDlse: egen job_tenure_as_5yrsLater = total(same_job_as_5yrsLater)
replace job_tenure_as_5yrsLater =. if job_tenure_as_5yrsLater==0

*-? Finally, determine if we can accurately measure job tenure 

bysort IDlse: generate last_occurrence_job_num = job_num[_N]
bysort IDlse: generate first_occurrence_job_num = job_num[1]

*!! if the job number is also the first occurrence job number, then we don't know when exactly the job starts (left censored)
*!! if the job number is also the last occurrence job number, then we don't know when exactly the job ends (right censored)
generate censor_job_tenure = .
replace  censor_job_tenure = 1  if job_num_5yrsLater==last_occurrence_job_num
replace  censor_job_tenure = -1 if job_num_5yrsLater==first_occurrence_job_num
replace  censor_job_tenure = 0  if job_num_5yrsLater<last_occurrence_job_num & job_num_5yrsLater>first_occurrence_job_num

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. Func tenure variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*-? First, determine the Func number 5 years after the event 
    //&& a Func number is determined by chaning a Func (i.e., 0 is his first Func, 1 is his second Func, ...)
    //&& since we only care about tenure at a specific Func, there is actually no need to know the exact Func information

*!! =1, at the YM when a worker changed his Func
generate change_Func = . 
replace  change_Func = 1 if IDlse[_n]==IDlse[_n-1] & Func[_n]!=Func[_n-1] & Func[_n]!=. & Func[_n-1]!=.
replace  change_Func = 0 if IDlse[_n]==IDlse[_n-1] & Func[_n]==Func[_n-1]

*!! assign Func number 
sort IDlse YearMonth 
bysort IDlse: generate Func_num = sum(change_Func)

*!! determine Func number 5 years after the event 
generate temp_Func_num_5yrsLater = Func_num if YearMonth == FT_Event_Time + 60 
sort IDlse YearMonth
bysort IDlse: egen Func_num_5yrsLater = mean(temp_Func_num_5yrsLater)
drop temp_Func_num_5yrsLater

*-? Next, calculate the Func tenure for that Func 

*!! =1, if he is at the same Func as the Func 5 years after the event
generate same_Func_as_5yrsLater = (Func_num==Func_num_5yrsLater) if Func_num_5yrsLater!=.

*!! Func tenure for the exact Func he is in 5 years after the event
bysort IDlse: egen Func_tenure_as_5yrsLater = total(same_Func_as_5yrsLater)
replace Func_tenure_as_5yrsLater =. if Func_tenure_as_5yrsLater==0

*-? Finally, determine if we can accurately measure Func tenure 

bysort IDlse: generate last_occurrence_Func_num = Func_num[_N]
bysort IDlse: generate first_occurrence_Func_num = Func_num[1]

*!! if the Func number is also the first occurrence Func number, then we don't know when exactly the Func starts (left censored)
*!! if the Func number is also the last occurrence Func number, then we don't know when exactly the Func ends (right censored)
generate censor_Func_tenure = .
replace  censor_Func_tenure = 1  if Func_num_5yrsLater==last_occurrence_Func_num
replace  censor_Func_tenure = -1 if Func_num_5yrsLater==first_occurrence_Func_num
replace  censor_Func_tenure = 0  if Func_num_5yrsLater<last_occurrence_Func_num & Func_num_5yrsLater>first_occurrence_Func_num

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. SubFunc tenure variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*-? First, determine the SubFunc number 5 years after the event 
    //&& a SubFunc number is determined by chaning a SubFunc (i.e., 0 is his first SubFunc, 1 is his second SubFunc, ...)
    //&& since we only care about tenure at a specific SubFunc, there is actually no need to know the exact SubFunc information

*!! =1, at the YM when a worker changed his SubFunc
generate change_SubFunc = . 
replace  change_SubFunc = 1 if IDlse[_n]==IDlse[_n-1] & SubFunc[_n]!=SubFunc[_n-1] & SubFunc[_n]!=. & SubFunc[_n-1]!=.
replace  change_SubFunc = 0 if IDlse[_n]==IDlse[_n-1] & SubFunc[_n]==SubFunc[_n-1]

*!! assign SubFunc number 
sort IDlse YearMonth 
bysort IDlse: generate SubFunc_num = sum(change_SubFunc)

*!! determine SubFunc number 5 years after the event 
generate temp_SubFunc_num_5yrsLater = SubFunc_num if YearMonth == FT_Event_Time + 60 
sort IDlse YearMonth
bysort IDlse: egen SubFunc_num_5yrsLater = mean(temp_SubFunc_num_5yrsLater)
drop temp_SubFunc_num_5yrsLater

*-? Next, calculate the SubFunc tenure for that SubFunc 

*!! =1, if he is at the same SubFunc as the SubFunc 5 years after the event
generate same_SubFunc_as_5yrsLater = (SubFunc_num==SubFunc_num_5yrsLater) if SubFunc_num_5yrsLater!=.

*!! SubFunc tenure for the exact SubFunc he is in 5 years after the event
bysort IDlse: egen SubFunc_tenure_as_5yrsLater = total(same_SubFunc_as_5yrsLater)
replace SubFunc_tenure_as_5yrsLater =. if SubFunc_tenure_as_5yrsLater==0

*-? Finally, determine if we can accurately measure SubFunc tenure 

bysort IDlse: generate last_occurrence_SubFunc_num = SubFunc_num[_N]
bysort IDlse: generate first_occurrence_SubFunc_num = SubFunc_num[1]

*!! if the SubFunc number is also the first occurrence SubFunc number, then we don't know when exactly the SubFunc starts (left censored)
*!! if the SubFunc number is also the last occurrence SubFunc number, then we don't know when exactly the SubFunc ends (right censored)
generate censor_SubFunc_tenure = .
replace  censor_SubFunc_tenure = 1  if SubFunc_num_5yrsLater==last_occurrence_SubFunc_num
replace  censor_SubFunc_tenure = -1 if SubFunc_num_5yrsLater==first_occurrence_SubFunc_num
replace  censor_SubFunc_tenure = 0  if SubFunc_num_5yrsLater<last_occurrence_SubFunc_num & SubFunc_num_5yrsLater>first_occurrence_SubFunc_num

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-6. turn the dataset into an individual cross-sectional dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time==0

keep IDlse IDlseMHR FT_Mngr_both_WL2 ///
    SubFunc Func StandardJobCode ISOCode ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time ///
    job_tenure_as_5yrsLater censor_job_tenure ///
    Func_tenure_as_5yrsLater censor_Func_tenure ///
    SubFunc_tenure_as_5yrsLater censor_SubFunc_tenure

order IDlse IDlseMHR FT_Mngr_both_WL2 ///
    SubFunc Func StandardJobCode ISOCode ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time ///
    job_tenure_as_5yrsLater censor_job_tenure ///
    Func_tenure_as_5yrsLater censor_Func_tenure ///
    SubFunc_tenure_as_5yrsLater censor_SubFunc_tenure

duplicates drop 

save "${TempData}/temp_JobTenureAfterEvents.dta", replace 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run censored normal regression
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close
log using "${Results}/logfile_20240925_JobTenureAfterEvents", replace text

use "${TempData}/temp_JobTenureAfterEvents.dta", clear  

generate l_job_tenure_as_5yrsLater     = log(job_tenure_as_5yrsLater)
generate l_Func_tenure_as_5yrsLater    = log(Func_tenure_as_5yrsLater)
generate l_SubFunc_tenure_as_5yrsLater = log(SubFunc_tenure_as_5yrsLater)

tabulate ISOCode, generate(ISOCode_)
tabulate FT_Event_Time, generate(FT_Event_Time_)
tabulate Func, generate(Func_)
tabulate StandardJobCode, generate(StandardJobCode_)
tabulate SubFunc, generate(SubFunc_)

label variable FT_LtoH "LtoH"
label variable FT_HtoH "HtoH"
label variable FT_HtoL "HtoL"

cnreg l_job_tenure_as_5yrsLater FT_LtoH FT_HtoH FT_HtoL ISOCode_* FT_Event_Time_* Func_* if FT_Mngr_both_WL2==1, censor(censor_job_tenure) cluster(IDlseMHR)
    eststo job
    test FT_HtoH = FT_HtoL
    local p_test = r(p)
    estadd scalar p_test = `p_test'
    summarize l_job_tenure_as_5yrsLater if e(sample)==1 & FT_LtoL==1
    local LtoLmean = r(mean)
    estadd scalar LtoLmean = `LtoLmean'

cnreg l_Func_tenure_as_5yrsLater FT_LtoH FT_HtoH FT_HtoL ISOCode_* FT_Event_Time_* Func_* if FT_Mngr_both_WL2==1, censor(censor_Func_tenure) cluster(IDlseMHR)
    eststo Func
    test FT_HtoH = FT_HtoL
    local p_test = r(p)
    estadd scalar p_test = `p_test'
    summarize l_Func_tenure_as_5yrsLater if e(sample)==1 & FT_LtoL==1
    local LtoLmean = r(mean)
    estadd scalar LtoLmean = `LtoLmean'

cnreg l_SubFunc_tenure_as_5yrsLater FT_LtoH FT_HtoH FT_HtoL ISOCode_* FT_Event_Time_* Func_* if FT_Mngr_both_WL2==1, censor(censor_SubFunc_tenure) cluster(IDlseMHR)
    eststo SubFunc
    test FT_HtoH = FT_HtoL
    local p_test = r(p)
    estadd scalar p_test = `p_test'
    summarize l_SubFunc_tenure_as_5yrsLater if e(sample)==1 & FT_LtoL==1
    local LtoLmean = r(mean)
    estadd scalar LtoLmean = `LtoLmean'

esttab job Func SubFunc using "${Results}/JobTenureAfterEvents.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_value p_test LtoLmean N, labels("\hline p-values" "HtoH = HtoL" " \hline LtoL Mean" "N") fmt(%9.0g %9.3f %9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Job tenure} & \multicolumn{1}{c}{Function tenure} & \multicolumn{1}{c}{Subfunction tenure} \\ ") ///
    posthead("") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Censored normal regression (using $\mathtt{cnreg}$ command in Stata). Sample includes those workers in the event study whose job information is available 5 years after the treatment. I regress their job tenure at the job he was in 5 years after the treatment to a set of dummies indicating his treatment group. Control variables include country, event time, and function. Standard errors are clustered at the manager level. " "\end{tablenotes}")

cnreg l_job_tenure_as_5yrsLater FT_LtoH FT_HtoH FT_HtoL ISOCode_* FT_Event_Time_* StandardJobCode_* if FT_Mngr_both_WL2==1, censor(censor_job_tenure) cluster(IDlseMHR)
    eststo job_RelFE
    test FT_HtoH = FT_HtoL
    local p_test = r(p)
    estadd scalar p_test = `p_test'
    summarize l_job_tenure_as_5yrsLater if e(sample)==1 & FT_LtoL==1
    local LtoLmean = r(mean)
    estadd scalar LtoLmean = `LtoLmean'

cnreg l_Func_tenure_as_5yrsLater FT_LtoH FT_HtoH FT_HtoL ISOCode_* FT_Event_Time_* Func_* if FT_Mngr_both_WL2==1, censor(censor_Func_tenure) cluster(IDlseMHR)
    eststo Func_RelFE
    test FT_HtoH = FT_HtoL
    local p_test = r(p)
    estadd scalar p_test = `p_test'
    summarize l_Func_tenure_as_5yrsLater if e(sample)==1 & FT_LtoL==1
    local LtoLmean = r(mean)
    estadd scalar LtoLmean = `LtoLmean'

cnreg l_SubFunc_tenure_as_5yrsLater FT_LtoH FT_HtoH FT_HtoL ISOCode_* FT_Event_Time_* SubFunc_* if FT_Mngr_both_WL2==1, censor(censor_SubFunc_tenure) cluster(IDlseMHR)
    eststo SubFunc_RelFE
    test FT_HtoH = FT_HtoL
    local p_test = r(p)
    estadd scalar p_test = `p_test'
    summarize l_SubFunc_tenure_as_5yrsLater if e(sample)==1 & FT_LtoL==1
    local LtoLmean = r(mean)
    estadd scalar LtoLmean = `LtoLmean'

esttab job_RelFE Func_RelFE SubFunc_RelFE using "${Results}/JobTenureAfterEvents_RelevantFE.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH FT_HtoH FT_HtoL) ///
    order(FT_LtoH FT_HtoH FT_HtoL) ///
    b(3) se(2) ///
    stats(p_value p_test LtoLmean N, labels("\hline p-values" "HtoH = HtoL" " \hline LtoL Mean" "N") fmt(%9.0g %9.3f %9.3f %9.0f)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Job tenure} & \multicolumn{1}{c}{Function tenure} & \multicolumn{1}{c}{Subfunction tenure} \\ ") ///
    posthead("") ///
    prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Censored normal regression (using $\mathtt{cnreg}$ command in Stata). Sample includes those workers in the event study whose job information is available 5 years after the treatment. I regress their job tenure at the job he was in 5 years after the treatment to a set of dummies indicating his treatment group. Control variables include country, event time, and the corresponding FE (job fixed effects in the first column, function fixed effects in the second column, and subfunction fixed effects in the third column). Standard errors are clustered at the manager level. " "\end{tablenotes}")

log close