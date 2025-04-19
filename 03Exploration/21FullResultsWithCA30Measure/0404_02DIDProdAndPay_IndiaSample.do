/* 
This do file runs DID-style regressions using productivity (i.e., sales bonus) as the outcome variable.

Notes:
    The regressions are further run conditional on workers' lateral and vertical move status.

Input:
    "${TempData}/FinalAnalysisSample.dta"          <== created in 0103_02 do file 
    "${TempData}/0105SalesProdOutcomes.dta"        <== created in 0105 do file 
    "${TempData}/0403EffectiveLeaderScores.dta"    <== created in 0403 do file 

Description of "${TempData}/0403EffectiveLeaderScores.dta" dataset:
    (1) It has three variables: IDlse YearMonth LineManager.
    (2) The LineManager value is the score that the corresponding manager with id IDlse received in that month. 
    (3) It is not the score the employee with the id IDlse gave to his manager.

Result:
    "${Results}/004ResultsBasedOnCA30/CA30_DIDResultsCondOnMoves.tex"

RA: WWZ 
Time: 2025-04-18
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain a relevant dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. new variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! productivity outcomes 
use "${TempData}/FinalAnalysisSample.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

generate Prod = log(Productivity + 1)
label variable Prod "Sales bonus (logs)"

*!! "event group * post" dummy variables 
generate CA30_LtoL_X_Post = CA30_LtoL * Post_Event
generate CA30_LtoH_X_Post = CA30_LtoH * Post_Event

label variable CA30_LtoL_X_Post "LtoL $\times$ post"
label variable CA30_LtoH_X_Post "LtoH $\times$ post"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. keep only LtoL and LtoH groups (LtoL serves as the control group) 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if CA30_LtoL==1 | CA30_LtoH==1
    //impt: keep only LtoL and LtoH event workers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. keep only Indian workers and relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep  ISOCode Year YearMonth IDlse IDlseMHR Rel_Time Event_Time Post_Event CA30_LtoL CA30_LtoH CA30_LtoL_X_Post CA30_LtoH_X_Post LogPayBonus Productivity Prod TransferSJ WL Country
order ISOCode Year YearMonth IDlse IDlseMHR Rel_Time Event_Time Post_Event CA30_LtoL CA30_LtoH CA30_LtoL_X_Post CA30_LtoH_X_Post LogPayBonus Productivity Prod TransferSJ WL Country

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. whose pre-event measures can be observed
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen MinRelTime_Prod = min(cond(Prod!=., Rel_Time, .))
generate q_PrePeriods_Prod = (MinRelTime_Prod < 0)

sort IDlse YearMonth
bysort IDlse: egen MinRelTime_Pay = min(cond(LogPayBonus!=., Rel_Time, .))
generate q_PrePeriods_Pay = (MinRelTime_Prod < 0)

label variable q_PrePeriods_Prod "The employee's pre-event productivity measure can be observed"
label variable q_PrePeriods_Pay  "The employee's pre-event compensation measure can be observed"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. DID regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* 
The interpretation of the DID regressions comes as follows.
Notice that the following two regressions are econmetrically equivalent:
    reghdfe Y CA30_LtoL_X_Post CA30_LtoH_X_Post, absorb(IDlse YearMonth) cluster(IDlseMHR)
        lincom CA30_LtoH_X_Post - CA30_LtoL_X_Post
    reghdfe Y Post_Event CA30_LtoH_X_Post, absorb(IDlse YearMonth) cluster(IDlseMHR)
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. outcome: productivity measurement
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe Prod Post_Event CA30_LtoH_X_Post if q_PrePeriods_Prod==1 & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // -.0286352
reghdfe Prod Post_Event CA30_LtoH_X_Post if ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // .0019921

reghdfe Prod Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 60) & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // .5083175*
reghdfe Prod Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 60) & q_PrePeriods_Prod==1 & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // .6283696**

reghdfe Prod Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 84) & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // .4360924
reghdfe Prod Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 84) & q_PrePeriods_Prod==1 & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // .608472**

/* 
Conclusion for the productivity measure:
    (1) The relative time period restriction is extremely important for significant coefficients.
    (2) The magnitude of the effects is similar to the effects on bonus.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. outcome: pay outcome
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post if ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // -.0563346
reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post if q_PrePeriods_Pay==1 & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // .0024702
reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 84) & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // -.0249035

reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post, absorb(IDlse YearMonth) cluster(IDlseMHR) // .0304625**
reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post if q_PrePeriods_Pay==1, absorb(IDlse YearMonth) cluster(IDlseMHR) // -.0396724

reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 84), absorb(IDlse YearMonth) cluster(IDlseMHR) // .0227789**
reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 84) & q_PrePeriods_Pay==1, absorb(IDlse YearMonth) cluster(IDlseMHR) // -.0591607**

/* 
Conclusion for the pay outcome:
    (1) No significant coefficients using only the Indian sample.
    (2) The relative time period restriction does not matter for significant coefficients.
    (3) What is weird is that when I only use only employees whose pre-event pay outcomes can be observed, the coefficients get negatively significant.
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. do lateral movers gain more  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*!! movers within 2 years after the event 
sort IDlse YearMonth
bysort IDlse: egen Movers_2yrs = max(cond(inrange(Rel_Time, 0, 24), TransferSJ, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. split the sample 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe Prod Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 60) & ISOCode=="IND" & Movers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR) // 1.905631
reghdfe Prod Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 60) & q_PrePeriods_Prod==1 & ISOCode=="IND" & Movers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR) // 1.106459

reghdfe Prod Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 84) & ISOCode=="IND" & Movers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR) // 1.908251
reghdfe Prod Post_Event CA30_LtoH_X_Post if inrange(Rel_Time, -6, 84) & q_PrePeriods_Prod==1 & ISOCode=="IND" & Movers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR) // 1.138107

reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post if Movers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR) // .0416628**

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. interaction terms 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Post_Event_X_Movers = Post_Event * Movers_2yrs
generate CA30_LtoH_X_Movers = CA30_LtoH * Movers_2yrs
generate CA30_LtoH_X_Post_X_Movers = CA30_LtoH_X_Post * Movers_2yrs

reghdfe Prod Post_Event Post_Event_X_Movers CA30_LtoH_X_Post CA30_LtoH_X_Post_X_Movers if inrange(Rel_Time, -6, 60) & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // .6434652** 1.327054
reghdfe Prod Post_Event Post_Event_X_Movers CA30_LtoH_X_Post CA30_LtoH_X_Post_X_Movers if inrange(Rel_Time, -6, 84) & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR) // .5540389** 1.41674

reghdfe LogPayBonus Post_Event Post_Event_X_Movers CA30_LtoH_X_Post CA30_LtoH_X_Post_X_Movers, absorb(IDlse YearMonth) cluster(IDlseMHR) // .0213594* .0190878

/* 
Conclusion on heterogeneity by lateral movers:
    (1) For productivity measure, there is no significant heterogeneity by lateral movers, though the sign of the interaction terms indeed implies that lateral movers gain more from LtoH events.
    (2) For pay outcome, the coefficient is indeed slightly larger conditional on lateral mover sample, but it seems not significant from the regression with interaction terms.
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. do LtoH workers have better outcomes after promotion  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global absorb_vars Country YearMonth

reghdfe LogPayBonus CA30_LtoH if Post_Event==1 & WL==2, absorb(${absorb_vars}) cluster(IDlseMHR) // .0051513

/* 
Conclusion on post-promotion outcomes:
    (1) Nothing can be found here.
*/