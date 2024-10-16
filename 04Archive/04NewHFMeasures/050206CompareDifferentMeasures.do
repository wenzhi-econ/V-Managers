/* 
This do file compares four different measure-dataset combinations used in the event studies, using the (New Data, Old Measure as the benchmark).
    New Data, Old Measure 
    Old Data, Old Measure 
    New Data, New Measure (HF2)
    New Data, New Measure (HF3)

Input:


RA: WWZ 
Time: 2024-10-09
*/
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. New Data, Old Measure 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/01WorkersOutcomes.dta", clear 

merge 1:1 IDlse YearMonth using "${TempData}/02EventStudyDummies.dta", generate(_merge_newd_oldm)

keep ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Never_ChangeM 

save "${TempData}/test_newdata_oldmeasure.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. Old Data, Old Measure 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear 

keep ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH

rename WL2 FT_Mngr_both_WL2

*!! calendar time of the event
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHL FT_Calend_Time_HtoL
rename FTHH FT_Calend_Time_HtoH

*!! five event dummies: 4 types of treatment + 1 never-treated
generate FT_LtoL = 0 
replace  FT_LtoL = 1 if FT_Calend_Time_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if FT_Calend_Time_LtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if FT_Calend_Time_HtoL != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if FT_Calend_Time_HtoH != .

generate FT_Never_ChangeM = . 
replace  FT_Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  FT_Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 

label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

keep ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Never_ChangeM 

foreach var in IDlseMHR EarlyAgeM FT_Mngr_both_WL2 FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Never_ChangeM {
    rename `var' `var'_ORI 
}

label drop _all 

save "${TempData}/test_olddata_oldmeasure.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. New Data, New Measure (HF2)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/01WorkersOutcomes.dta", clear

merge 1:1 IDlse YearMonth using "${TempData}/04EventStudyDummies_TwoNewHFMeasures.dta", generate(_merge_newd_newm) keepusing(IDlseMHR HF2M HF2_Mngr_both_WL2 HF2_Rel_Time HF2_LtoL HF2_LtoH HF2_HtoH HF2_HtoL HF2_Never_ChangeM HF3M HF3_Rel_Time HF3_Mngr_both_WL2 HF3_LtoL HF3_LtoH HF3_HtoH HF3_HtoL HF3_Never_ChangeM)

keep IDlse YearMonth ///
    IDlseMHR HF2M HF2_Mngr_both_WL2 HF2_Rel_Time HF2_LtoL HF2_LtoH HF2_HtoH HF2_HtoL HF2_Never_ChangeM HF3M HF3_Rel_Time HF3_Mngr_both_WL2 HF3_LtoL HF3_LtoH HF3_HtoH HF3_HtoL HF3_Never_ChangeM

rename IDlseMHR IDlseMHR_HF

save "${TempData}/test_newdata_newmeasure.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. comparison between different combinations 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/test_newdata_oldmeasure.dta", clear 

merge 1:1 IDlse YearMonth using "${TempData}/test_olddata_oldmeasure.dta", nogenerate 
merge 1:1 IDlse YearMonth using "${TempData}/test_newdata_newmeasure.dta", nogenerate 

order IDlse YearMonth ///
    IDlseMHR IDlseMHR_ORI IDlseMHR_HF ///
    EarlyAgeM EarlyAgeM_ORI HF2M HF3M ///
    FT_Mngr_both_WL2 FT_Mngr_both_WL2_ORI HF2_Mngr_both_WL2 HF3_Mngr_both_WL2 ///
    FT_Rel_Time FT_Rel_Time_ORI HF2_Rel_Time HF3_Rel_Time ///
    FT_Never_ChangeM FT_Never_ChangeM_ORI HF2_Never_ChangeM HF3_Never_ChangeM

save "${TempData}/test_AllFourMeasures.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. does sample restriction variable 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/test_AllFourMeasures.dta", clear 

*!! s-4-1-1. redefine this sample restriction variable only for eligible treatment groups 
replace FT_Mngr_both_WL2     = . if FT_Rel_Time==.
replace FT_Mngr_both_WL2_ORI = . if FT_Rel_Time_ORI==.
replace HF2_Mngr_both_WL2    = . if HF2_Rel_Time==.
replace HF3_Mngr_both_WL2    = . if HF3_Rel_Time==.

*!! s-4-1-2. all 0: this sample restriction variable is legit 
count if FT_Mngr_both_WL2 != FT_Mngr_both_WL2_ORI & FT_Mngr_both_WL2!=. & FT_Mngr_both_WL2_ORI!=.
count if FT_Mngr_both_WL2 != HF2_Mngr_both_WL2 & FT_Mngr_both_WL2!=. & HF2_Mngr_both_WL2!=.
count if FT_Mngr_both_WL2 != HF3_Mngr_both_WL2 & FT_Mngr_both_WL2!=. & HF3_Mngr_both_WL2!=.

*!! s-4-1-3. all 0: New Data, Old Measure defines the largest number of treatment groups
count if FT_Mngr_both_WL2_ORI!=. & FT_Mngr_both_WL2==.
count if HF2_Mngr_both_WL2!=. & FT_Mngr_both_WL2==.
count if HF3_Mngr_both_WL2!=. & FT_Mngr_both_WL2==.

*!! s-4-1-4. sample restriction: keep only those workers used in the event studies 
*&? This is essentially the sample restriciton condition used in all regressions. The s-4-1-1 step does not matter in this case because for X_Rel_Time==. observations, the X_Mngr_both_WL2 is always set as 0.
keep if FT_Mngr_both_WL2 == 1
    //&? the largest sample corresponds to the New Data, Old Measure case 
    //&? But again, remember, in all the following comparison, we also need to impose X_Never_ChangeM==0 since in the event studies, we didn't include control sample.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. how many events each combination identifies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
order occurrence, after(YearMonth)

*&? The occurrence==1 condition makes sure for each worker, we only count once. 
count if occurrence==1 & FT_LtoL==1 // 20,622
count if occurrence==1 & FT_LtoH==1 // 4,104 
count if occurrence==1 & FT_HtoH==1 // 1,745
count if occurrence==1 & FT_HtoL==1 // 2,817

count if occurrence==1 & HF2_LtoL==1 // 12,747
count if occurrence==1 & HF2_LtoH==1 // 6,079 
count if occurrence==1 & HF2_HtoH==1 // 6,006
count if occurrence==1 & HF2_HtoL==1 // 4,456

count if occurrence==1 & FT_LtoL_ORI==1 // 19,494
count if occurrence==1 & FT_LtoH_ORI==1 // 3,913 
count if occurrence==1 & FT_HtoH_ORI==1 // 1,646
count if occurrence==1 & FT_HtoL_ORI==1 // 2,658

count if occurrence==1 & HF3_LtoL==1 // 1,579
count if occurrence==1 & HF3_LtoH==1 // 677 
count if occurrence==1 & HF3_HtoH==1 // 850
count if occurrence==1 & HF3_HtoL==1 // 759

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. verify that FT and FT_ORI measures are the same except for the missing treatments
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! all zeros
*&? Recall that X_Never_ChangeM==0 is used to restrict the regression sample. 
*&? Therefore, it means that the (New Data, Old Measure) sample is a super-set of the (Old Data, Old Measure) sample. 
count if FT_LtoL!=FT_LtoL_ORI & FT_Never_ChangeM==0 & FT_Never_ChangeM_ORI==0
count if FT_LtoH!=FT_LtoH_ORI & FT_Never_ChangeM==0 & FT_Never_ChangeM_ORI==0
count if FT_HtoH!=FT_HtoH_ORI & FT_Never_ChangeM==0 & FT_Never_ChangeM_ORI==0
count if FT_HtoL!=FT_HtoL_ORI & FT_Never_ChangeM==0 & FT_Never_ChangeM_ORI==0

list IDlse YearMonth IDlseMHR_HF IDlseMHR_ORI EarlyAgeM EarlyAgeM_ORI if IDlse==541437
    //&? Again, why is the (New Data, Old Measure) combination different from the (Old Data, Old Measure)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-4. correlation calculation sample 1: worker-based 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

preserve

keep if inrange(FT_Rel_Time, -1, 0)
    //&?  for each individual worker in the dataset, we keep only his pre- and post-managers (so each worker has two managers' information in this correlation sample)

keep IDlse IDlseMHR EarlyAgeM EarlyAgeM_ORI HF2M HF3M

tabulate EarlyAgeM HF2M, missing 
/* 
Fast track |
   manager |
  based on | HF managers based on
  age when |   Age_atWL2Prom and
  promoted |  age_WL2plus_atentry
      (WL) |         0          1 |     Total
-----------+----------------------+----------
         0 |    34,093     14,072 |    48,165 
         1 |     1,936      8,475 |    10,411 
-----------+----------------------+----------
     Total |    36,029     22,547 |    58,576
*/

tabulate EarlyAgeM HF3M, missing 
/* 
Fast track |
   manager |
  based on | HF managers based on tenure for
  age when |           workers with
  promoted |       q_witness_WL2Prom==1
      (WL) |         0          1          . |     Total
-----------+---------------------------------+----------
         0 |     7,746      2,499     37,920 |    48,165 
         1 |     2,180      4,342      3,889 |    10,411 
-----------+---------------------------------+----------
     Total |     9,926      6,841     41,809 |    58,576
*/

correlate EarlyAgeM HF2M
/* 
. correlate EarlyAgeM HF2M
(obs=58,576)

             | EarlyA~M     HF2M
-------------+------------------
   EarlyAgeM |   1.0000
        HF2M |   0.4100   1.0000
*/

correlate EarlyAgeM HF3M
/* 
. correlate EarlyAgeM HF3M
(obs=16,767)

             | EarlyA~M     HF3M
-------------+------------------
   EarlyAgeM |   1.0000
        HF3M |   0.4184   1.0000
*/

correlate EarlyAgeM HF2M HF3M
/* 
. correlate EarlyAgeM HF2M HF3M
(obs=16,767)

             | EarlyA~M     HF2M     HF3M
-------------+---------------------------
   EarlyAgeM |   1.0000
        HF2M |   0.3725   1.0000
        HF3M |   0.4184   0.3802   1.0000
*/

restore 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-5. correlation calculation sample 2: manager-based 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
      
preserve 

keep if inrange(FT_Rel_Time, -1, 0)
    //&? Again, we first need to care about two managers for one single worker. 

keep IDlseMHR EarlyAgeM EarlyAgeM_ORI HF2M HF3M
duplicates drop 

tabulate EarlyAgeM HF2M, missing 
/* 
Fast track |
   manager |
  based on | HF managers based on
  age when |   Age_atWL2Prom and
  promoted |  age_WL2plus_atentry
      (WL) |         0          1 |     Total
-----------+----------------------+----------
         0 |     8,232      3,323 |    11,555 
         1 |       783      2,709 |     3,492 
-----------+----------------------+----------
     Total |     9,015      6,032 |    15,047 
*/

tabulate EarlyAgeM HF3M, missing 
/* 
Fast track |
   manager |
  based on | HF managers based on tenure for
  age when |           workers with
  promoted |       q_witness_WL2Prom==1
      (WL) |         0          1          . |     Total
-----------+---------------------------------+----------
         0 |     2,273        624      8,658 |    11,555 
         1 |       886      1,602      1,004 |     3,492 
-----------+---------------------------------+----------
     Total |     3,159      2,226      9,662 |    15,047 
*/

correlate EarlyAgeM HF2M
/* 
. correlate EarlyAgeM HF2M
(obs=15,047)

             | EarlyA~M     HF2M
-------------+------------------
   EarlyAgeM |   1.0000
        HF2M |   0.4205   1.0000
*/

correlate EarlyAgeM HF3M
/* 
. correlate EarlyAgeM HF3M
(obs=5,385)

             | EarlyA~M     HF3M
-------------+------------------
   EarlyAgeM |   1.0000
        HF3M |   0.4338   1.0000

*/

correlate EarlyAgeM HF2M HF3M
/* 
. correlate EarlyAgeM HF2M HF3M
(obs=5,385)

             | EarlyA~M     HF2M     HF3M
-------------+---------------------------
   EarlyAgeM |   1.0000
        HF2M |   0.3885   1.0000
        HF3M |   0.4338   0.3185   1.0000
*/





restore 








