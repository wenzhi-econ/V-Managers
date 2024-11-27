/* 
This do file compares Within and Across Team Transfers.
In particular, I need to calculate the following statistics: 
    separately for each event group,
    conditional on the worker have a transfer (defined as changing his standard job),
    distinguish between three types of transfers: within team and function, outside team but within function, outside function,
    calculate the average time from the event to the three types of transfers.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta"

RA: WWZ 
Time: 2024-10-14
*/

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. relevant variables: TransferSJSameM TransferSJDiffM
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. auxiliary variable: temp_first_month and ChangeM
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! first month for a worker
sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

*!! if the worker changes his manager 
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. decompose TransferSJ into three categories:
*-?         (1) within team (same manager, same function)
*-?         (2) different team (different manager), and different function
*-?         (3) different team (different manager), but same function
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! lateral transfer under the same manager
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*!! lateral transfer under different managers
generate TransferSJDiffM = TransferSJ
replace  TransferSJDiffM = 0 if TransferSJSameM==1

*!! category (3): differnt manager + same function
generate TransferSJDiffMSameFunc = TransferSJ 
replace  TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace  TransferSJDiffMSameFunc = 0 if TransferSJSameM==1

*!! category (1): same manager + same function
generate TransferSJSameMSameFunc = TransferSJ 
replace  TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace  TransferSJSameMSameFunc = 0 if TransferSJDiffMSameFunc==1

*!! category (2): different manager + different function
*&& variable TransferFunc can accurately describe this category
replace TransferFunc = 0 if TransferSJ==0
    //IDlse==606619

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. keep only relevant workers (same sample as in the event studies)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if ((FT_Never_ChangeM==0) & (FT_Mngr_both_WL2==1))
    //&? LtoL LtoH HtoH HtoL workers used in the event studies 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. compute the relevant statistics  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. ignore pre-event job transfers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

replace TransferSJ              = 0 if FT_Rel_Time<=0 
replace TransferSJSameMSameFunc = 0 if FT_Rel_Time<=0 
replace TransferFunc            = 0 if FT_Rel_Time<=0 
replace TransferSJDiffMSameFunc = 0 if FT_Rel_Time<=0 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. keep only the first transfer  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen first_TransferSJ_date = min(cond(TransferSJ==1, YearMonth, .))

replace TransferSJ              = 0 if YearMonth > first_TransferSJ_date 
replace TransferSJSameMSameFunc = 0 if YearMonth > first_TransferSJ_date 
replace TransferFunc            = 0 if YearMonth > first_TransferSJ_date 
replace TransferSJDiffMSameFunc = 0 if YearMonth > first_TransferSJ_date 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. keep only those workers who have made transfers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen Transfer_Post = max(TransferSJ)
keep if Transfer_Post==1
    //&? conditional on making at least a job transfer after the manager change 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. document the first transfer time (relative to the event)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen Months_TransferSJ              = min(cond(TransferSJ==1,              FT_Rel_Time, .)) 
bysort IDlse: egen Months_TransferSJSameMSameFunc = min(cond(TransferSJSameMSameFunc==1, FT_Rel_Time, .)) 
bysort IDlse: egen Months_TransferFunc            = min(cond(TransferFunc==1,            FT_Rel_Time, .))
bysort IDlse: egen Months_TransferSJDiffMSameFunc = min(cond(TransferSJDiffMSameFunc==1, FT_Rel_Time, .)) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. auxiliary variable for collaspe 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate group = . 
replace  group = 1 if FT_LtoL==1
replace  group = 2 if FT_LtoH==1
replace  group = 3 if FT_HtoH==1
replace  group = 4 if FT_HtoL==1

label define group ///
    1 "LtoL" 2 "LtoH" 3 "HtoH" 4 "HtoL"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. collapse
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time==0 
    //&? keep a cross-section of workers 

order IDlse YearMonth Months_TransferSJ Months_TransferSJSameMSameFunc Months_TransferFunc Months_TransferSJDiffMSameFunc

collapse (mean) Months_TransferSJ Months_TransferSJSameMSameFunc Months_TransferFunc Months_TransferSJDiffMSameFunc, by(group)

/* 
group    Months_TransferSJ    Months_TransferSJSameMSameFunc    Months_TransferFunc    Months_TransferSJDiffMSameFunc
1	     24.40719             25.31339                          23.72281               22.61299
2	     21.64023             22.60369                          17.25455               21.12177
3	     25.89463             31.49718                          15.28226               20.2517
4	     21.25606             23.32383                          16.15385               19.27859
*/
