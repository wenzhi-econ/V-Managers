/* 
This do file conducts t-test for managers' exit rates by whether they are in the event and whether they are high-flyers.

RA: WWZ
Time: 2025-01-29
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain the final dataset consisting of event managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. generate a list of managers who have been WL2 in the data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

*!! get any employee who is of WL2 at any point in the data 
generate WL2 = (WL==2) if WL!=.
sort IDlse YearMonth
bysort IDlse: egen Ever_WL2 = max(WL2)

keep if Ever_WL2==1
    //&? a panel of workers who are ever WL2 in the data 

keep IDlse
duplicates drop 

save "${TempData}/temp_EverWL2WorkerList.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate a list of managers who are in the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers

keep if FT_Rel_Time==0 | FT_Rel_Time==-1
    //&? keep only pre- and post-event managers

keep IDlseMHR
duplicates drop

rename IDlseMHR IDlse

save "${TempData}/temp_EventMngrList.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. get managers' status: in the event or not, high-flyer or not 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. in the event or not 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlse using "${TempData}/temp_EverWL2WorkerList.dta", generate(EverWL2Worker)
merge m:1 IDlse using "${TempData}/temp_EventMngrList.dta", generate(EventMngr)

keep if EverWL2Worker==3 | EventMngr==3
    //&? a panel of employees who are ever WL2 in the data or they are event managers in the event studies 

label drop _merge
replace EverWL2Worker = 0 if EverWL2Worker!=3
replace EverWL2Worker = 1 if EverWL2Worker==3
replace EventMngr = 0 if EventMngr!=3
replace EventMngr = 1 if EventMngr==3

label variable EverWL2Worker "Ever WL2 Workers"
label variable EventMngr     "Event Managers"

tab EventMngr EverWL2Worker

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. H- or L-type
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 
rename IDlseMHR IDlse

sort IDlse YearMonth
bysort IDlse: egen EarlyAge = max(EarlyAgeM)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. generate exit outcomes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sort IDlse YearMonth
bysort IDlse: egen Exit = max(LeaverPerm)

keep IDlse Exit EverWL2Worker EventMngr EarlyAge
duplicates drop 
codebook IDlse
    //&? a cross-section of 33,198 managers

tabulate EventMngr EverWL2Worker
/* 
           |  Ever WL2
     Event |  Workers
  Managers |         1 |     Total
-----------+-----------+----------
         0 |    18,534 |    18,534 
         1 |    14,664 |    14,664 
-----------+-----------+----------
     Total |    33,198 |    33,198 
*/

tabulate EventMngr Exit 
/* 
     Event |         Exit
  Managers |         0          1 |     Total
-----------+----------------------+----------
         0 |     8,139     10,395 |    18,534 
         1 |     6,777      7,887 |    14,664 
-----------+----------------------+----------
     Total |    14,916     18,282 |    33,198 
*/

ttest Exit, by(EventMngr)
/* 
Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. err.   Std. dev.   [95% conf. interval]
---------+--------------------------------------------------------------------
       0 |  18,534    .5608611    .0036455    .4962955    .5537156    .5680066
       1 |  14,664    .5378478    .0041173    .4985825    .5297774    .5459182
---------+--------------------------------------------------------------------
Combined |  33,198    .5506958    .0027301    .4974308    .5453448    .5560469
---------+--------------------------------------------------------------------
    diff |            .0230133    .0054963                .0122404    .0337863
------------------------------------------------------------------------------
    diff = mean(0) - mean(1)                                      t =   4.1871
H0: diff = 0                                     Degrees of freedom =    33196

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 1.0000         Pr(|T| > |t|) = 0.0000          Pr(T > t) = 0.0000
*/

ttest Exit if EarlyAge==1, by(EventMngr)
/* 
Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. err.   Std. dev.   [95% conf. interval]
---------+--------------------------------------------------------------------
       0 |   9,844    .4732832    .0050325    .4993111    .4634184     .483148
       1 |   9,022    .4716249    .0052558    .4992219    .4613223    .4819276
---------+--------------------------------------------------------------------
Combined |  18,866    .4724902    .0036348    .4992559    .4653656    .4796148
---------+--------------------------------------------------------------------
    diff |            .0016583    .0072767               -.0126048    .0159214
------------------------------------------------------------------------------
    diff = mean(0) - mean(1)                                      t =   0.2279
H0: diff = 0                                     Degrees of freedom =    18864

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 0.5901         Pr(|T| > |t|) = 0.8197          Pr(T > t) = 0.4099
*/

ttest Exit if EarlyAge==0, by(EventMngr)
/* 
Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. err.   Std. dev.   [95% conf. interval]
---------+--------------------------------------------------------------------
       0 |   8,621    .6573483    .0051118    .4746237    .6473281    .6673686
       1 |   5,635    .6433008    .0063819    .4790674    .6307898    .6558118
---------+--------------------------------------------------------------------
Combined |  14,256    .6517957    .0039901    .4764179    .6439745    .6596169
---------+--------------------------------------------------------------------
    diff |            .0140475    .0081608               -.0019486    .0300437
------------------------------------------------------------------------------
    diff = mean(0) - mean(1)                                      t =   1.7213
H0: diff = 0                                     Degrees of freedom =    14254

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 0.9574         Pr(|T| > |t|) = 0.0852          Pr(T > t) = 0.0426
*/