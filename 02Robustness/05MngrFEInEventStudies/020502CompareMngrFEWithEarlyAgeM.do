/* 
This do file compares manager FE with the EarlyAgeM measure.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0102 do file.
    "${TempData}/temp_Mngr_MngrFE.dta" <== constructed in 0801 do file

RA: WWZ 
Time: 2024-10-30
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge MngrFE measure 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

keep if FT_Rel_Time!=. 
keep if FT_Mngr_both_WL2==1
    //&? keep a worker panel that contains only the event workers 

merge m:1 IDlseMHR using "${TempData}/temp_Mngr_MngrFE.dta", keep(match) nogenerate
    //&? keep only those managers whose manager FE can be identified

keep if FT_Rel_Time==0
    //&? a cross-section of event workers whose manager (event or non-event) FE can be identified 

keep IDlseMHR EarlyAgeM MngrFE MngrFE_Med MngrFE_p75
duplicates drop 
    //&? 871 different managers 

save "${TempData}/temp_Mngr_MngrFE_EarlyAgeM.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. correlation 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_Mngr_MngrFE_EarlyAgeM.dta", clear 

correlate EarlyAgeM MngrFE_Med MngrFE_p75
/* 
. correlate EarlyAgeM MngrFE_Med MngrFE_p75
(obs=871)

             | EarlyA~M MngrFE~d MngrF~75
-------------+---------------------------
   EarlyAgeM |   1.0000
  MngrFE_Med |  -0.0415   1.0000
  MngrFE_p75 |  -0.0384   0.5767   1.0000
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. distribution for L- and H-type (based EarlyAgeM measure) managers  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable MngrFE "Manager FE"

histogram MngrFE, fraction by(EarlyAgeM)

graph export "${Results}/DistOfMngrFEByEarlyAgeM.png", replace as(png)