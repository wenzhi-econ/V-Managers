/* 
This do file generates other outcomes for event workers that are used in event studies.

Notes:
    (1) The dataset contains only the analysis sample, i.e., the full panel of employees who are in event studies.
    (2) The dataset contains only relevant variables, including 
        (i) event-relevant variables, 
        (ii) outcome variables used in the main event studies, and 
        (iii) other variables that may be used as control variables in cross-sectional regressions. 

Input:
    "${TempData}/0103_02EventWorkersPanel_WithEventDummies.dta" <== created in 0103_02 do file 

Output:
    "${TempData}/FinalAnalysisSample.dta" <== main output

Description of the output dataset:
    (1) It is the main dataset used in the event study, i.e., the analysis sample.
    (2) In particular, the dataset contains the following variables:
        outcome variables constructed in 0101_01, 0101_03 do files, and 
        the event group identifiers, and event-relevant variables. 

impt: This dataset will be used frequently if analysis sample dataset is required.

RA: WWZ 
Time: 2025-04-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. keep only relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0103_02EventWorkersPanel_WithEventDummies.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. event-related variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop occurrence
sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
order occurrence, after(YearMonth)

generate Post_Event = (Rel_Time>=0) if Rel_Time!=., after(Event_Time)
label variable Post_Event "Months from the event month onwards (event month included)"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-2. obtain updated age variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${TempData}/0102_01AgeBandUpdated.dta", keep(match) nogenerate
merge 1:1 IDlse YearMonth using "${TempData}/0102_02AgeContinuous.dta"  ///
    , keepusing(AgeContinuous q_exact_age AgeContinuous_exact AgeContinuous_imputed) keep(match) nogenerate

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-2. order the outcomes that are already generated before
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop Year
generate Year = year(dofm(YearMonth))

keep ///
    Year YearMonth occurrence IDlse IDlseMHR ///
    Rel_Time Event_Time Post_Event ///
    CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL IDMngr_Pre IDMngr_Post CA30_Pre CA30_Post ///
    TransferSJV TransferSJVC TransferSJ TransferSJC ///
    ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC ///
    TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC ///
    TransferInternal TransferInternalC TransferInternalSJ TransferInternalSJC ///
    LogPayBonus LogPay LogBonus Pay Bonus ///
    Leaver LeaverPerm LeaverVol LeaverInv /// 
    Func SubFunc Org4 Office OfficeCode StandardJob SalaryGrade ///
    Female Tenure WL Country ISOCode ///
    AgeBand AgeBandUpdated AgeContinuous q_exact_age AgeContinuous_exact AgeContinuous_imputed

order ///
    Year YearMonth occurrence IDlse IDlseMHR ///
    Rel_Time Event_Time Post_Event ///
    CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL IDMngr_Pre IDMngr_Post CA30_Pre CA30_Post ///
    TransferSJV TransferSJVC TransferSJ TransferSJC ///
    ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC ///
    TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC ///
    TransferInternal TransferInternalC TransferInternalSJ TransferInternalSJC ///
    LogPayBonus LogPay LogBonus Pay Bonus ///
    Leaver LeaverPerm LeaverVol LeaverInv /// 
    Func SubFunc Org4 Office OfficeCode StandardJob SalaryGrade ///
    Female Tenure WL Country ISOCode ///
    AgeBand AgeBandUpdated AgeContinuous q_exact_age AgeContinuous_exact AgeContinuous_imputed

label variable YearMonth        "Year-Month"
label variable Year             "Year"
label variable occurrence       "Sequential occurrence number for each employee in that month"
label variable IDlseMHR         "Manager ID"

rename (CA30_Pre CA30_Post) (CA30Mngr_Pre CA30Mngr_Post)

label variable TransferSJV         "= 1 when his StandardJob is diff. than last month but SalaryGrade is the same"
label variable TransferSJVC        "Cumulative count of TransferSJV for an individual"
label variable TransferSJ          "= 1 in months when an individual's StandardJob is diff. than preceding months"
label variable TransferSJC         "Cumulative count of TransferSJ for an individual"
label variable ChangeSalaryGrade   "= 1 in months when an individual's SalaryGrade is diff. than preceding months"
label variable ChangeSalaryGradeC  "Cumulative count of ChangeSalaryGrade for an individual"
label variable PromWL              "= 1 in months when WL is greater than preceding months"
label variable PromWLC             "Cumulative count of PromWL for an individual"
label variable TransferFunc        "= 1 in months when an individual's Func is diff. than preceding months"
label variable TransferFuncC       "Cumulative count of TransferFunc for an individual"
label variable TransferSubFunc     "= 1 in months when SubFunc is diff. than preceding months"
label variable TransferSubFuncC    "Cumulative count of TransferSubFuncC for an individual"
label variable TransferInternal    "= 1 in months when either SubFunc or Office or Org4 is diff than last months"
label variable TransferInternalC   "Cumulative count of TransferInternal for an individual"
label variable TransferInternalSJ  "= 1 in months when either StandardJob or Office or Org4 is diff than last months"
label variable TransferInternalSJC "Cumulative count of TransferInternalSJ for an individual"

label variable LogPayBonus        "Pay + bonus (logs)"
label variable LogPay             "Pay (logs)"
label variable LogBonus           "Bonus (logs)"
label variable Pay                "Pay"
label variable Bonus              "Bonus"
label variable Leaver             "= 1 in months when an individual leaves the firm"
label variable LeaverPerm         "= 1 in the month when an individual leaves the firm permanently"
label variable LeaverVol          "= 1 in the month when an individual quits (voluntarily exits)"
label variable LeaverInv          "= 1 in the month when an individual is fired (involuntarily exits)"

label variable Func               "Function"
label variable SubFunc            "Subfunction"
label variable Org4               "Level 4 organization description"
label variable Office             "Work location: Office or Plant/Factory"
label variable OfficeCode         "Work location code: Office or Plant/Factory"
label variable StandardJob        "Standard job title"
label variable SalaryGrade        "Salary grade"
label variable Female             "Female"
label variable Tenure             "Years within the firm"
label variable WL                 "Work level: from lowest (1) to highest (6)"
label variable Country            "Working country"
label variable ISOCode            "ISO code of the working country"
label variable AgeBand            "Age band"
label variable AgeBandUpdated     "Updated age band"
label variable AgeContinuous      "Continuous age (with imputations)"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain ONET-relevant outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

merge m:1 StandardJob using "${TempData}/0101_03FinalJobLevelPrank.dta"
    drop if _merge==2
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                       160,939
        from master                   160,211  (_merge==1)
        from using                        728  (_merge==2)

    Matched                         1,751,448  (_merge==3)
    -----------------------------------------
*/
sort IDlse YearMonth
bysort IDlse: generate ONETDist = ///
    ((prank_cognitive[_n] * prank_cognitive[_n-1]) + (prank_routine[_n] * prank_routine[_n-1]) + (prank_social[_n] * prank_social[_n-1])) ///
    / sqrt((prank_cognitive[_n]^2 + prank_routine[_n]^2 + prank_social[_n]^2) * (prank_cognitive[_n-1]^2 + prank_routine[_n-1]^2 + prank_social[_n-1]^2)) ///
    if YearMonth[_n]==YearMonth[_n-1]+1
replace ONETDist = 1 if occurrence==1
replace ONETDist = 1 - ONETDist

sort IDlse YearMonth
bysort IDlse: generate ONETDistC = sum(ONETDist)

order ONETDist ONETDistC, after(TransferSJC)
rename Title ONETOccTitle
order ONETOccTitle, after(StandardJob)
drop ONETSOCCode intensity_cognitive_a intensity_cognitive_b intensity_cognitive_d intensity_cognitive_e intensity_cognitive_f intensity_routine_g intensity_routine_h intensity_social_i intensity_social_j intensity_social_k intensity_social_l intensity_cognitive_c intensity_cognitive intensity_routine intensity_social prank_cognitive prank_routine prank_social
label variable ONETDist  "Task distance between current standard job and job in the previous month"
label variable ONETDistC "Cumulate sum of task distance"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. making at least one lateral transfers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*!! a variable that marks post-event lateral transfers
generate Post_TransferSJV = TransferSJV
replace  Post_TransferSJV = 0 if Rel_Time<0

*!! a cumulative count of post-event lateral transfers 
generate temp = Post_TransferSJV
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & StandardJob!=""
generate Post_TransferSJVC = temp 
drop temp

*!! making at least one post-event lateral transfer 
generate JobV_AtLeast1 = .
replace  JobV_AtLeast1 = 0 if Rel_Time>=0 & Post_TransferSJVC==0
replace  JobV_AtLeast1 = 1 if Rel_Time>=0 & Post_TransferSJVC>=1

*!! drop and order 
drop Post_TransferSJV Post_TransferSJVC
order JobV_AtLeast1, after(TransferSJVC)
label variable JobV_AtLeast1 "=1 from the month onwards when a first post-event TransferSJV occurs"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. decompose TransferSJ into three categories:
*??         (1) within team (same manager, same function)
*??         (2) different team (different manager), and different function
*??         (3) different team (different manager), but same function
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. auxiliary variable: ChangeM and TransferSJSameM
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! first month for a worker
sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

*!! if the worker changes his manager 
capture drop ChangeM
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

*!! lateral transfer under the same manager
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. decomposition 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

*!! category (3): different manager + same function
generate TransferSJDiffMSameFunc = TransferSJ 
replace  TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace  TransferSJDiffMSameFunc = 0 if TransferSJSameM==1
bysort IDlse: generate TransferSJDiffMSameFuncC= sum(TransferSJDiffMSameFunc)

*!! category (1): same manager + same function
generate TransferSJSameMSameFunc = TransferSJ 
replace  TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace  TransferSJSameMSameFunc = 0 if TransferSJDiffMSameFunc==1
bysort IDlse: generate TransferSJSameMSameFuncC= sum(TransferSJSameMSameFunc)

*!! category (2): different manager + different function
*&& variable TransferFunc can accurately describe this category

*!! drop and order 
drop temp_first_month TransferSJSameM TransferSJDiffMSameFunc TransferSJSameMSameFunc

order TransferSJSameMSameFuncC TransferSJDiffMSameFuncC TransferFuncC, after(TransferSJC)
order ChangeM, after(IDlseMHR)

label variable TransferSJC               "Cumulative count of all lateral moves"
label variable TransferSJSameMSameFuncC  "Cumulative count of within team lateral moves"
label variable TransferSJDiffMSameFuncC  "Cumulative count of diff. team, same function lateral moves"
label variable TransferFuncC             "Cumulative count of diff. team, different function lateral moves"
label variable ChangeM                   "= 1 in months when an individual's manager is diff. than last months"


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. save the final dataset for event studies 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

save "${TempData}/FinalAnalysisSample.dta", replace 
