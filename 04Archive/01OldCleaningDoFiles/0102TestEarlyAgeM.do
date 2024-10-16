/* 
This do file tests whether I can replicate original EarlyAgeM measure. 


RA: WWZ 
Time: 2024-10-07
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. original events 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear 
sort  IDlse YearMonth

keep IDlse YearMonth IDlseMHR EarlyAgeM
rename IDlseMHR IDlseMHR_ORI
rename EarlyAgeM EarlyAgeM_ORI

save "${TempData}/test_OriginalConstructingEarlyAgeM.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct my own EarlyAgeM
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${RawMNEData}/AllSnapshotWC.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

bysort IDlse: generate occurrence = _n 

order IDlse YearMonth occurrence IDlseMHR

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. impute missing manager id 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in IDlseMHR   {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. 
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. who are fast-track managers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-1. a set of auxiliary variables 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate WLAgg = WL
replace  WLAgg = 5 if WL>4 & WL!=.

//&? starting work level 
bysort IDlse: egen MinWL = min(WLAgg)  
//&? last observed work level 
bysort IDlse: egen MaxWL = max(WLAgg)

//&? age when the worker starts his last observed WL 
bysort IDlse: egen AgeMinMaxWL = min(cond(WL == MaxWL, AgeBand, .)) 
//&? number of months a worker is in his last observed WL
bysort IDlse: egen TenureMaxWLMonths = count(cond(WL==MaxWL, YearMonth, .) ) 
//&? number of years a worker is in his last observed WL
generate TenureMaxWL = TenureMaxWLMonths/12 
//&? tenure when the worker starts his last observed WL 
bysort IDlse: egen TenureMinMaxWL = min(cond(WL==MaxWL, Tenure, .)) 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-2. Variable EarlyAge: if the worker is a fast-track manager 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

summarize TenureMaxWL if MaxWL ==2 & occurrence==1, detail 

generate EarlyAge = 0 
replace  EarlyAge = 1 if MinWL==1 & MaxWL==2 & TenureMinMaxWL<=4 & TenureMaxWL<=6 
replace  EarlyAge = 1 if MaxWL==2 & AgeMinMaxWL==1 & TenureMaxWL<=6 
replace  EarlyAge = 1 if MaxWL==3 & AgeMinMaxWL<=2 & TenureMinMaxWL<=10 
replace  EarlyAge = 1 if MaxWL==4 & AgeMinMaxWL<=2 
replace  EarlyAge = 1 if MaxWL>4  & AgeMinMaxWL<=3 
label var EarlyAge "Fast track  manager based on age when promoted (WL)"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-3. get a dataset of id EarlyAge  
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

preserve 

    keep IDlse EarlyAge 
    duplicates drop 
    rename IDlse IDlseMHR 
    rename EarlyAge EarlyAgeM

    save "${TempData}/temp_Mngr_FT.dta", replace 

restore 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-4. merge back manager's FT measure to the main dataset  
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

merge m:1 IDlseMHR using "${TempData}/temp_Mngr_FT.dta", keep(match) nogenerate 

order IDlse YearMonth occurrence IDlseMHR EarlyAgeM

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. compare with the original measure 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??


merge 1:1 IDlse YearMonth using "${TempData}/test_OriginalConstructingEarlyAgeM.dta", keep(match)
drop if _merge==2

order IDlse YearMonth IDlseMHR IDlseMHR_ORI EarlyAgeM EarlyAgeM_ORI occurrence 

sort IDlse YearMonth
/* 
Apart from different missing values, self-constructed FT measure EarlyAgeM is exactly the same as the original measure.

The difference in missing values is caused by the following original practice:
    To obtain managers' FT measure, we need to merge the temporary dataset back to the master dataset. However, since we use both IDlseMHR and YearMonth as keys, it will effectively only keep only those managers who are also in the dataset at the same time. But since FT measure is an individual-level variable, we should drop the YearMonth key.

    The specific commands are in Lines 527-529 in "1.1.CleanData.do" file. They are copied below.
        merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MListChar.dta"
        drop if _merge ==2 
        drop _merge

My practice is in Line 101, which makes more sense. 
*/


count if IDlseMHR!=IDlseMHR_ORI // 0

count if EarlyAgeM!=EarlyAgeM_ORI & EarlyAgeM!=.  & EarlyAgeM_ORI!=.  // 0


count if IDlseMHR==. 
count if EarlyAgeM==.
count if EarlyAgeM_ORI==.

