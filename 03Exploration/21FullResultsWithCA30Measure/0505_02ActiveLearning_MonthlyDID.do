/* 
This do file compares H- and L-type managers in active learning activities.

Input:
    "${TempData}/FinalAnalysisSample.dta" <== created in 0103_03 do file 
    "${RawMNEData}/ActiveLearn.dta"       <== raw data 

Results:
    "${Results}/FTActiveLearn.tex"

RA: WWZ 
Time: 2025-04-16
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain variables about workers' active learning in the firm
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
    //impt: use the analysis sample, i.e., keep only those workers who are in the event studies

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. obtain variables about active learning 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${RawMNEData}/ActiveLearn.dta"
    keep if _merge==3
    drop _merge  

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. keep only relevant variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
keep Year YearMonth IDlse Event_Time Rel_Time Post_Event CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL IDMngr_Post Num*

keep if CA30_LtoL==1 | CA30_LtoH==1
    //impt: keep only LtoL and LtoH workers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. who should we focus on 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen temp = min(Post_Event)
generate q_PrePeriods = 1 - temp 
drop temp 

label variable q_PrePeriods "=1 if the employee has pre-event periods on the active learning variables"

keep if q_PrePeriods==1
    //impt: keep event workers with both pre- and post-event active learning variables 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. "event group * post" dummy variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CA30_LtoL_X_Post = CA30_LtoL * Post_Event
generate CA30_LtoH_X_Post = CA30_LtoH * Post_Event

label variable CA30_LtoL_X_Post "LtoL $\times$ post"
label variable CA30_LtoH_X_Post "LtoH $\times$ post"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. re-define outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

replace  NumRecommend  = 0 if NumRecommend==.
replace  NumCompleted  = 0 if NumCompleted==.
replace  NumSkills     = 0 if NumSkills   ==.
generate ActiveLearner = (NumRecommend>=1 & NumCompleted>=5 & NumSkills>=3)

reghdfe NumRecommend  Post_Event CA30_LtoH_X_Post, absorb(IDlse YearMonth) cluster(IDMngr_Post)                               // 1.790978
reghdfe NumRecommend  Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -36, 60), absorb(IDlse YearMonth) cluster(IDMngr_Post) // 1.789361

reghdfe NumCompleted  Post_Event CA30_LtoH_X_Post, absorb(IDlse YearMonth) cluster(IDMngr_Post)                               // -.3912765*
reghdfe NumCompleted  Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -36, 60), absorb(IDlse YearMonth) cluster(IDMngr_Post) // -.391998*

reghdfe NumSkills     Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -36, 60), absorb(IDlse YearMonth) cluster(IDMngr_Post) // .3218364
reghdfe NumSkills     Post_Event CA30_LtoH_X_Post, absorb(IDlse YearMonth) cluster(IDMngr_Post)                               // .3303031

reghdfe ActiveLearner Post_Event CA30_LtoH_X_Post, absorb(IDlse YearMonth) cluster(IDMngr_Post) // -.0012854
reghdfe ActiveLearner Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -36, 60), absorb(IDlse YearMonth) cluster(IDMngr_Post) // -.001268

/* 
Conclusion:
    (1) DID using raw outcome variables (which vary by individual-month) does not work.
    (2) Compared with yearly DID, it seems quite robust that the effect of LtoH transition to NumCompleted is significantly negatively.
*/


