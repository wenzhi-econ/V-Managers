/* 
Given a HF measure for managers, this do file constructs four oevent indicators.

This do file is adapted from "1.5.EventTeam2.do".


RA: WWZ 
Time: 2024-09-17
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. create a simplified dataset containing only relevant variables
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

keep IDlse YearMonth ChangeM TransferInternal TransferSJ IDlseMHR EarlyAgeM

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a ChangeMR variable which equals to one for a qualified event
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. Restriction 1. 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*&& Changing manager for employee but employee does not change team at the same time 
generate ChangeMR = 0 
replace  ChangeMR = 1 if ChangeM==1 
replace  ChangeMR = 0 if TransferInternal==1 | TransferSJ==1 
replace  ChangeMR = . if ChangeM==.
replace  ChangeMR = . if IDlseMHR==. 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. Restriction 2. 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*&& Considering only first manager change observed in the data 
bys IDlse: egen EiChange = min(cond(ChangeM==1, YearMonth ,.)) // for single differences 
bys IDlse: egen Ei = mean(cond(ChangeMR==1 & YearMonth == EiChange, EiChange ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1
replace ChangeMR = 0 if ChangeMR==. 
format Ei %tm 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. manager transitions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*!! LtoH
sort IDlse YearMonth
generate FTLowHigh = 0 if EarlyAgeM!=.
replace  FTLowHigh = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FTLowHigh = 0 if ChangeMR ==0

*!! HtoL
sort IDlse YearMonth
generate FTHighLow = 0 if EarlyAgeM!=.
replace  FTHighLow = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FTHighLow = 0 if ChangeMR ==0

*!! HtoH 
sort IDlse YearMonth
generate FTHighHigh = 0 if EarlyAgeM!=.
replace  FTHighHigh = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==1 & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  FTHighHigh = 0 if ChangeMR ==0

*!! LtoL 
sort IDlse YearMonth
generate FTLowLow = 0 if EarlyAgeM!=.
replace  FTLowLow = 1 if (IDlse[_n]==IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==0 & IDlseMHR[_n]!=IDlseMHR[_n-1] )
replace  FTLowLow = 0 if ChangeMR ==0

*!! four event dates
bys IDlse: egen FTLH = mean(cond(FTLowHigh  == 1, Ei,.)) 
bys IDlse: egen FTHL = mean(cond(FTHighLow  == 1, Ei,.)) 
bys IDlse: egen FTHH = mean(cond(FTHighHigh == 1, Ei,.)) 
bys IDlse: egen FTLL = mean(cond(FTLowLow   == 1, Ei,.)) 
format FTLH %tm
format FTLL %tm
format FTHH %tm
format FTHL %tm

save "${TempData}/test_ConstructingEventVariables.dta", replace  // full sample 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. compare with the existing variables
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. existing dataset and existing variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    IDlse YearMonth ///
    FTHL FTLL FTHH FTLH ///
    FTLowHigh FTHighLow FTHighHigh FTLowLow

order ///
    IDlse YearMonth ///
    FTHL FTLL FTHH FTLH ///
    FTLowHigh FTHighLow FTHighHigh FTLowLow

*!! calendar time of the event
rename FTLL Calend_Time_FT_LtoL
rename FTLH Calend_Time_FT_LtoH
rename FTHL Calend_Time_FT_HtoL
rename FTHH Calend_Time_FT_HtoH

rename FTLowLow   FT_LtoL
rename FTLowHigh  FT_LtoH
rename FTHighLow  FT_HtoL
rename FTHighHigh FT_HtoH 

merge 1:1 IDlse YearMonth using "${TempData}/test_ConstructingEventVariables.dta", keepusing(FTHL FTLL FTHH FTLH FTLowHigh FTHighLow FTHighHigh FTLowLow)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. compare variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

count if FT_LtoH != FTLowHigh
count if FT_HtoL != FTHighLow
count if FT_HtoH != FTHighHigh
count if FT_LtoL != FTLowLow

count if Calend_Time_FT_LtoH != FTLH
count if Calend_Time_FT_HtoL != FTHL
count if Calend_Time_FT_HtoH != FTHH
count if Calend_Time_FT_LtoL != FTLL

tabulate FT_LtoH, m 
tabulate FT_HtoL, m 
tabulate FT_HtoH, m 
tabulate FT_LtoL, m // all these four variables have 8526 missing values

generate Never_ChangeM = . 
replace  Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1
tabulate Never_ChangeM, m 

save "${TempData}/test_ComparisonEventVariables_Success.dta", replace 