
********************************************************************************
* IMPORT DATASET - only consider first event 
********************************************************************************

use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

* 1) Sample restriction 1: I drop all employees with any instance of missing managers
bys IDlse: egen cM = count(cond(IDlseMHR==., YearMonth,.)) // count how many IDlse have missing manager info 
drop if cM > 0 // only keep IDlse for which manager id is never missing 
count if IDlseMHR==.

* Event Change manager
gsort IDlse YearMonth 
gen ChangeSJM = 0 
replace ChangeSJM = 1 if (IDlse[_n] == IDlse[_n-1] & StandardJobM[_n] != StandardJobM[_n-1]   )

* MONTHS -2 & +1: Changing manager where employee does not transfer 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & MaxWLM>1 & ChangeSJM==0  

gen    Ei = YearMonth if ChangeMR==1 // time of event 
format Ei %tm 
 
sort IDlse YearMonth
gen IDlseMHRPre = IDlseMHR[_n-1] if Ei !=. // get the previous manager

sort IDlse YearMonth
gen EiPre = YearMonth[_n-1] if Ei !=. 
format EiPre %tm

* Want to isolate transitions where the new manager inherits the whole team 
drop tt
bys IDlseMHR Ei: egen tt = count(IDlse) // team unit at manager-transition event level 
replace tt = . if Ei==. | IDlseMHR==.

count if tt==TeamSize // 14k events where team size is the same as the people that change that month
 
bys IDlseMHR EiPre: egen ttPre = count(IDlse) // team unit at manager-transition event level 
replace ttPre = . if EiPre==. | IDlseMHR==.

bys IDlseMHR Ei: egen rnkteam = rank(IDlseMHRPre) // compute the number of ties and compare number of ties with number in team 
bys IDlseMHR Ei: egen rnkmode = mode(rnkteam),  maxmode
count if rnkmode==. & Ei!=. // 0, all good!
bys IDlseMHR Ei: egen PropSameTeam  = mean(cond(rnkteam == rnkmode, 1,0))  if rnkteam!=.

gen PropSameTeamAll =PropSameTeam==1
ta ChangeMR PropSameTeamAll, row // 80% of the changes are instances where manager inherits whole team! 

replace ChangeMR = 0 if PropSameTeam <1 // only consider manager changes where entire team changes manager 

drop Ei tt IDlseMHRPre EiPre // recreate Ei using update manager transition definition 
gen    Ei = YearMonth if ChangeMR==1 // time of event 
format Ei %tm 
 
sort IDlse YearMonth
gen IDlseMHRPre = IDlseMHR[_n-1] if Ei !=. // get the previous manager

sort IDlse YearMonth
gen EiPre = YearMonth[_n-1] if Ei !=. 
format EiPre %tm


bys IDlse (YearMonth), sort: gen NoChangeM= sum(ChangeMR)
bys IDlse NoChangeM: egen noMonthsChange = count(YearMonth) // number of months for a given change 
replace noMonthsChange  = . if Ei==.
bys IDlseMHR IDlseMHRPre: egen modenoMonthsChange= mode(noMonthsChange), minmode
count if modenoMonthsChange==. & Ei!=. // 0, all good!

bys IDlseMHR Ei: egen PropSameTeamDuration  = mean(cond(noMonthsChange == modenoMonthsChange, 1,0))  if modenoMonthsChange!=.
replace ChangeMR  = 0 if PropSameTeamDuration==1 & noMonthsChange <3 // require new manager to stay in team at least 3 months 

drop Ei IDlseMHRPre EiPre // recreate Ei using update manager transition definition 
gen    Ei = YearMonth if ChangeMR==1 // time of event 
format Ei %tm 
 
sort IDlse YearMonth
gen IDlseMHRPre = IDlseMHR[_n-1] if Ei !=. // get the previous manager

sort IDlse YearMonth
gen EiPre = YearMonth[_n-1] if Ei !=. 
format EiPre %tm

* 2) Sample restriction 2: switchers where manager inherits the whole team and no whole team experiences the new manager for less than 3 months 
bys IDlse: egen totEvent = sum(ChangeMR)
distinct IDlse 
distinct IDlse if totEvent>0 
di    45781/ 139095 // 33%

* For Sun & Abraham only consider first event 
rename Ei EiAll
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1

* Early age 
gsort IDlse YearMonth 
* low high
gen ChangeAgeMLowHigh = 0 
replace ChangeAgeMLowHigh = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==0    )
replace ChangeAgeMLowHigh = . if IDlseMHR ==. 
replace ChangeAgeMLowHigh = 0 if ChangeMR ==0
* high low
gsort IDlse YearMonth 
gen ChangeAgeMHighLow = 0 
replace ChangeAgeMHighLow = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==1    )
replace ChangeAgeMHighLow = . if IDlseMHR ==. 
replace ChangeAgeMHighLow = 0 if ChangeMR ==0
* high high 
gsort IDlse YearMonth 
gen ChangeAgeMHighHigh = 0 
replace ChangeAgeMHighHigh = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==1    )
replace ChangeAgeMHighHigh = . if IDlseMHR ==. 
replace ChangeAgeMHighHigh = 0 if ChangeMR ==0
* low low 
gsort IDlse YearMonth 
gen ChangeAgeMLowLow = 0 
replace ChangeAgeMLowLow = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==0   )
replace ChangeAgeMLowLow = . if IDlseMHR ==. 
replace ChangeAgeMLowLow = 0 if ChangeMR ==0

* for single differences 
egen ChangeAgeMLow = rowmax(ChangeAgeMLowHigh ChangeAgeMLowLow) // for single differences 
egen ChangeAgeMHigh = rowmax(ChangeAgeMHighHigh ChangeAgeMHighLow) // for single differences 

egen ChangeAgeMtoLow = rowmax(ChangeAgeMHighLow ChangeAgeMLowLow) // for single differences 
egen ChangeAgeMtoHigh = rowmax(ChangeAgeMHighHigh ChangeAgeMLowHigh) // for single differences 

* only consider first event  
foreach v in toLow toHigh High Low LowHigh LowLow HighHigh HighLow{
bys IDlse: egen   ChangeAgeM`v'Month = min(cond(ChangeAgeM`v'==1, YearMonth ,.)) // for single	
replace ChangeAgeM`v'= 0 if YearMonth > ChangeAgeM`v'Month  & ChangeAgeM`v'==1
}

* Add categorical variables for imputation estimator 
*bys IDlse: egen m = max(YearMonth) // time of event
* Single differences 
gen EL = ChangeAgeMLowMonth
format EL %tm 
gen EH = ChangeAgeMHighMonth
format EH %tm 
gen EtoL = ChangeAgeMtoLowMonth
format EtoL %tm 
gen EtoH = ChangeAgeMtoHighMonth
format EtoH %tm 
* Single coefficients 
gen ELH = ChangeAgeMLowHighMonth 
*replace ELH = m + 1 if ELH==.
format ELH %tm 
gen EHH = ChangeAgeMHighHighMonth 
*replace EHH = m + 1 if EHH==.
format EHH %tm 
gen ELL = ChangeAgeMLowLowMonth 
*replace ELL = m + 1 if ELL==.
format ELL %tm 
gen EHL = ChangeAgeMHighLowMonth 
*replace EHL = m + 1 if EHL==.
format EHL %tm 

////////////////////////////////////////////////////

/* select ONLY relevant variables 
keep IDlse YearMonth IDlseMHR Ei EL EH ELH EHH ELL EHL CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow LogPayBonus  LeaverPerm  TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC ChangeSalaryGradeC VPA  PromWLC insample insample1
*/

* FE and control vars 
gen Tenure2 = Tenure*Tenure 
gen  Tenure2M = TenureM*TenureM

* other outcome variables of interest
xtset IDlse YearMonth 
gen PayBonusD= d.LogPayBonus 
gen PayBonusIncrease= PayBonusD>0 if PayBonusD!=.
gen VPA125 = VPA>=125 if VPA!=.
merge 1:1 IDlse YearMonth using "$Managersdta/Temp/Span.dta", keepusing(Span)
drop if _merge ==2 
drop _merge 
replace Span = 0 if Span==. // it means you are not a manager 

foreach var in Ei EH EL EHL ELL EHH ELH {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.


}

format Ei %tm 

drop cM ttPre PropSameTeamAll totEvent noMonthsChange modenoMonthsChange
compress
save "$Managersdta/EventSJ.dta", replace  // full sample 

* only saving the switchers 

distinct IDlse //  139095
keep if Ei!=. //     2515500 / 4,450,992 = 57% of obs 
distinct IDlse //  52164. So 45781/    139095 = 33% experience this event 

compress 
save "$Managersdta/SwitchersEventSJ.dta", replace 
