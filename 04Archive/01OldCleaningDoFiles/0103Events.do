/* 
Description of this do-file:

This do file creates a set of variables related to workers' characteristics.

Input files:
    "${RawMNEData}/AllSnapshotWC.dta" (raw data)

Output files:
    "${FinalData}/Workers.dta" (a panel dataset storing workers' outcomes)

RA: WWZ 
Time: 24/06/2024
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. combine workers' variables with managers' characteristics
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/Workers.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_1. workers who have a complete manager document
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
egen ind_tag = tag(IDlse)

bysort IDlse: egen count_MissingManagers = count(cond(IDlseMHR==., YearMonth, .)) 
tabulate count_MissingManagers if ind_tag==1, missing 
    // 69.66% (156,111) workers have a complete manager history
    // 10.92% (24,484) workers don't have their corresponding manager id for one month 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_2. manager id imputations 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
* TODO issue here: for one individual, we are actually imputing a lot of manager ids 

sort IDlse YearMonth
* replacing the instances where only 1 month is missing 
foreach var in IDlseMHR   {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==.
}
bysort IDlse: egen count_MissingManagers_Imputed = count(cond(IDlseMHR==., YearMonth, .)) 
tabulate count_MissingManagers_Imputed if ind_tag==1, missing 
    // 93.80% (210,212) workers now have a complete manager history after imputations 
drop if count_MissingManagers_Imputed!=0
    //&& Important: sample restriction here! 
codebook IDlseMHR // 0 missing values for manager id 
drop count_MissingManagers count_MissingManagers_Imputed

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_3. merge with managers' panel dataset  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
merge m:1 IDlseMHR YearMonth using "${FinalData}/Managers.dta", keepusing(HighFlyer1 HighFlyer2 WLAgg_Mngr)
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                     1,606,777
        from master                    65,262  (_merge==1)
        from using                  1,541,515  (_merge==2)

    Matched                         9,147,464  (_merge==3)
    -----------------------------------------
*/
codebook IDlse if _merge==1 // 28,554
sort IDlse YearMonth
bysort IDlse: egen ind_merge_outcome = mean(_merge)
tabulate ind_merge_outcome if ind_tag==1, missing 
    // 86.42% workers have their managers' full history in the dataset (181,658 workers among 210,212 distinct workers)
drop if ind_merge_outcome!=3 
    //&& Important: sample restriction here! 
drop _merge ind_merge_outcome

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. generate event study dummies 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s2_1. document manager changes for each worker 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
capture drop ChangeM
gsort IDlse YearMonth 
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0 if TransferInternal==1 | TransferSJ==1 
    // exclude those changes that involve internal transfers or standard job changes
    // todo what does this exclusion mean? 
by IDlse (YearMonth), sort: generate temp_count_ChangeM = sum(ChangeM)
bysort IDlse: egen count_ChangeM = max(temp_count_ChangeM)
drop temp_count_ChangeM
order IDlse IDlseMHR ChangeM count_ChangeM

label variable ChangeM       "=1 in the month when an individual's manager id is diff. from last month"
label variable count_ChangeM "count of manager changes for an individual"
tabulate count_ChangeM if ind_tag==1, missing 
    // 44.22% (80,332) workers have never experienced a manager change among a total of 181,658 managers 
count if ind_tag==1 & count_ChangeM!=0 
    // 101,326 distinct workers who have ever experienced manager change are left in the dataset

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s2_2. focus on the first observed manager change in the dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
sort IDlse YearMonth 
* first manager change observed in the data 
bys IDlse: egen First_ChangeM_YearMonth = min(cond(ChangeM==1, YearMonth, .)) 
format First_ChangeM_YearMonth %tm 
* index of months reletive to the first manager change 
generate Month_to_First_ChangeM = YearMonth - First_ChangeM_YearMonth 

label variable First_ChangeM_YearMonth "YearMonth when the first manager change happens"
label variable Month_to_First_ChangeM  "index of months relative to the first manager change"

tabulate Month_to_First_ChangeM, missing 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s2_4. focus on those managers with WL2  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

* only work level 2 managers 
bys IDlse: egen FirstWL2M = max(cond(WLAgg_Mngr==2 & Month_to_First_ChangeM==-1, 1, 0))
bys IDlse: egen LastWL2M  = max(cond(WLAgg_Mngr==2 & Month_to_First_ChangeM== 0, 1, 0))
generate Mngr_both_WL2 = (FirstWL2M==1 & LastWL2M==1)
label variable Mngr_both_WL2 "=1, if the worker's pre- and post-managers are both at WL2"

count if ind_tag==1 & count_ChangeM!=0 
    // 30,959 distinct workers who have experienced a manager change are left in the dataset
codebook IDlseMHR if count_ChangeM!=0 
    // 24,763 distinct managers who involve a manager change are left in the dataset 

order IDlse YearMonth ind_tag IDlseMHR count_ChangeM Month_to_First_ChangeM HighFlyer1 HighFlyer2 
sort  IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. determine the nature of this first manager change  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s3_1. auxiliary variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
capture drop pre_mngr_high
capture drop post_mngr_high
sort IDlse YearMonth 
bysort IDlse: egen pre_mngr_high  = max(cond(Month_to_First_ChangeM==-1 & HighFlyer1==1, 1, 0))
bysort IDlse: egen post_mngr_high = max(cond(Month_to_First_ChangeM==0  & HighFlyer1==1, 1, 0))
replace pre_mngr_high  = . if Month_to_First_ChangeM==.
replace post_mngr_high = . if Month_to_First_ChangeM==.

label variable pre_mngr_high  "=1, if the pre-manager is a high-flyer based on HighFlyer1"
label variable post_mngr_high "=1, if the post-manager is a high-flyer based on HighFlyer1"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s3_2. four event indicators and one control indicator 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
capture drop Never_ChangeM HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH
generate Never_ChangeM   = (count_ChangeM == 0)
generate HighFlyer1_LtoL = 0 
replace  HighFlyer1_LtoL = 1 if pre_mngr_high==0 & post_mngr_high==0
generate HighFlyer1_LtoH = 0 
replace  HighFlyer1_LtoH = 1 if pre_mngr_high==0 & post_mngr_high==1
generate HighFlyer1_HtoL = 0 
replace  HighFlyer1_HtoL = 1 if pre_mngr_high==1 & post_mngr_high==0
generate HighFlyer1_HtoH = 0 
replace  HighFlyer1_HtoH = 1 if pre_mngr_high==1 & post_mngr_high==1 

order pre_mngr_high post_mngr_high Never_ChangeM HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH, after(HighFlyer1)
label variable Never_ChangeM   "=1, if the worker has neve experienced a manager change in the dataset"
label variable HighFlyer1_LtoL "=1, if the manager change is from a Low-flyer to a Low-flyer"
label variable HighFlyer1_LtoH "=1, if the manager change is from a Low-flyer to a High-flyer"
label variable HighFlyer1_HtoL "=1, if the manager change is from a High-flyer to a Low-flyer"
label variable HighFlyer1_HtoH "=1, if the manager change is from a High-flyer to a High-flyer"

capture drop test_group 
egen test_group = rowtotal(Never_ChangeM HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH)
codebook test_group
drop test_group
    // all workers in the dataset must belong to one and only one of the five groups:
    //   control group (consisting of workers who have never changed  managers)
    //   four treatment groups (HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH)
tabulate Never_ChangeM   if ind_tag==1 // 80,332, 44.22% 
tabulate HighFlyer1_LtoL if ind_tag==1 // 73,845, 40.65%
tabulate HighFlyer1_LtoH if ind_tag==1 // 12,473, 6.87%
tabulate HighFlyer1_HtoL if ind_tag==1 // 9,998, 5.5%
tabulate HighFlyer1_HtoH if ind_tag==1 // 5,010, 2.76% 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. interact event indicators with (relative) time indicators   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s4_1. event times period dummies for all periods 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
summarize Month_to_First_ChangeM, detail 
local max_pre_period  = -r(min) // -131
local max_post_period =  r(max) // +130

foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    forvalues time = 1/`max_pre_period' {
        generate byte `event'_X_Pre`time' = `event' * (Month_to_First_ChangeM==-`time')
    }
}
foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    forvalues time = 0/`max_post_period' {
        generate byte `event'_X_Post`time' = `event' * (Month_to_First_ChangeM==`time')
    }
}
/* order ///
    HighFlyer1_LtoL_X_Pre* HighFlyer1_LtoL_X_Post* ///
    HighFlyer1_LtoH_X_Pre* HighFlyer1_LtoH_X_Post* /// 
    HighFlyer1_HtoL_X_Pre* HighFlyer1_HtoL_X_Post* ///
    HighFlyer1_HtoH_X_Pre* HighFlyer1_HtoH_X_Post*, last  */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s4_2. same event times period dummies as the original do file 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*!! We need to aggregate those periods outside [-86, +86] into one period indicator 

foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    egen `event'_X_Pre_End87  = rowmax(`event'_X_Pre87  - `event'_X_Pre`max_pre_period')
    egen `event'_X_Post_End87 = rowmax(`event'_X_Post87 - `event'_X_Post`max_post_period') 
}

*!! We need to aggregate those periods outside [-84, +84] into one period indicator 

foreach event in HighFlyer1_LtoL HighFlyer1_LtoH HighFlyer1_HtoL HighFlyer1_HtoH {
    egen `event'_X_Pre_End85  = rowmax(`event'_X_Pre85  - `event'_X_Pre`max_pre_period')
    egen `event'_X_Post_End85 = rowmax(`event'_X_Post85 - `event'_X_Post`max_post_period') 
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. generate workers' outcome variables related to manager change    
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s5_1: does job changes (lateral or verticle) coincide with manager changes?
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

* this is to account for the lags in reporting manager/position changes 
foreach var in ChangeSalaryGrade PromWL TransferInternalSJ TransferInternal TransferSJ {
    generate `var'SameM = `var'
    replace  `var'SameM = 0 if ChangeM==1   // only count job changes without manager changes 
    generate `var'DiffM = `var'
    replace  `var'DiffM = 0 if `var'SameM==1 // only count job changes with manager changes
}

label variable ChangeSalaryGradeSameM  "ChangeSalaryGrade without manager change"
label variable PromWLSameM             "PromWL without manager change"
label variable TransferInternalSJSameM "TransferInternalSJ without manager change"
label variable TransferSJSameM         "TransferSJ without manager change"
label variable TransferInternalSameM   "TransferInternal without manager change"

label variable ChangeSalaryGradeDiffM  "ChangeSalaryGrade with manager change"
label variable PromWLDiffM             "PromWL with manager change"
label variable TransferInternalSJDiffM "TransferInternalSJ with manager change"
label variable TransferSJDiffM         "TransferSJ with manager change"
label variable TransferInternalDiffM   "TransferInternal with manager change"





compress 
save "${FinalData}/EventStudySample.dta", replace

