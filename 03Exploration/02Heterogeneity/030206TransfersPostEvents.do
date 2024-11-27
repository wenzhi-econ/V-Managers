/* 
This do file compares Within and Across Team Transfers.
In particular, I need to calculate the following statistics: 
    separately for each event group,
    conditional on the worker have a transfer (defined as changing his standard job),
    distinguish between three types of transfers: within team and function, outside team but within function, outside function,
    calculate the average number of transfers post event.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta"

RA: WWZ 
Time: 2024-10-15
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
    //&? consider the case with IDlse==606619

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
*-? s-2-2. keep only those workers who have made transfers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen Transfer_Post = max(TransferSJ)
keep if Transfer_Post==1
    //&? conditional on making at least a job transfer after the manager change 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. calculate number of transfers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen Num_TransferSJ              = total(TransferSJ) 
bysort IDlse: egen Num_TransferSJSameMSameFunc = total(TransferSJSameMSameFunc) 
bysort IDlse: egen Num_TransferFunc            = total(TransferFunc)
bysort IDlse: egen Num_TransferSJDiffMSameFunc = total(TransferSJDiffMSameFunc) 

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

order IDlse YearMonth Num_TransferSJ Num_TransferSJSameMSameFunc Num_TransferFunc Num_TransferSJDiffMSameFunc

egen test = rowtotal(Num_TransferSJSameMSameFunc Num_TransferFunc Num_TransferSJDiffMSameFunc)
count if test!=Num_TransferSJ //&? 0

summarize Num_TransferSJ              if group==1, detail 
summarize Num_TransferSJSameMSameFunc if group==1, detail 
summarize Num_TransferFunc            if group==1, detail 
summarize Num_TransferSJDiffMSameFunc if group==1, detail 


collapse (mean) Num_TransferSJ Num_TransferSJSameMSameFunc Num_TransferFunc Num_TransferSJDiffMSameFunc, by(group)

/* 
group    Num_TransferSJ    Num_TransferSJSameMSameFunc    Num_TransferFunc    Num_TransferSJDiffMSameFunc
1        2.248641          1.377038                       .2155127	          .6560912
2        2.236111          1.298835                       .2271505	          .7101254
3        2.170706          1.228662                       .2592202	          .682824
4        2.29797           1.292731	                      .2580223	          .7472168
*/
