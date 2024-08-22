
********************************************************************************
* IMPORT DATASET - only consider first event 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth 
*keep if YearMonth <=tm(2020m3)

/* 1) Sample restriction 0: I drop all employees with any instance of missing managers
bys IDlse: egen cM = count(cond(IDlseMHR==., YearMonth,.)) // count how many IDlse have missing manager info 
ta cM // 90% of obs have non-missing manager info
drop if cM > 0 // only keep IDlse for which manager id is never missing 
drop cM 
*/

* Changing manager for employee 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 
replace  ChangeMR  = . if ChangeM==.
replace  ChangeMR  = . if IDlseMHR ==. 

/* Changing manager for employee: restricted event 
gen ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & (TransferInternalL1M==1 | TransferInternalL2M==1 | TransferInternalL3M==1 | TransferInternalM==1 | TransferInternalF1M==1  | TransferInternalF2M==1  | TransferInternalF3M==1 | TransferSJL1M==1 | TransferSJL2M==1 | TransferSJL3M==1 | TransferSJM==1 | TransferSJF1M==1  | TransferSJF2M==1  | TransferSJF3M==1)
replace ChangeMR  = . if ChangeM==.
replace ChangeMR  = . if IDlseMHR ==. 
*/

gen    Ei = YearMonth if ChangeMR==1 // time of event 
format Ei %tm 
 
////////////////////////////////////////////////////////////////////////////////
* Want to isolate transitions where the new manager inherits the whole team 
////////////////////////////////////////////////////////////////////////////////

drop tt
bys IDlseMHR Ei: egen tt = count(IDlse) // team unit at manager-transition event level 
replace tt = . if Ei==. | IDlseMHR==.

gen propT = tt / TeamSize

* Restriction #1: only considers changes where the workers that change manager are at least 50% of new team
replace ChangeMR =0 if propT<0.5 // workers that change are less than 50% of the new team  
replace Ei = . if ChangeMR==0
 
sort IDlse YearMonth
gen IDlseMHRPre = IDlseMHR[_n-1] if Ei !=. // get the previous manager

sort IDlse YearMonth
gen EiPre = YearMonth[_n-1] if Ei !=. // month before
format EiPre %tm

* I want to isolate manager changes where at least 50% of workers come from same previous manager 
bys IDlseMHR Ei: egen rnkteam = rank(IDlseMHRPre) // compute the number of ties and compare number of ties with number in team 
bys IDlseMHR Ei: egen rnkmode = mode(rnkteam),  minmode
count if rnkmode==. & Ei!=. // 10k instances because missing previous manager, all good!
bys IDlseMHR Ei: egen PropSameTeam  = mean(cond(rnkteam == rnkmode, 1,0))  if rnkmode!=.

gen PropSameTeamAll =PropSameTeam==1
gen PropSameTeamAll5 =PropSameTeam>=0.5 if PropSameTeam!=.

ta ChangeMR PropSameTeamAll5, row // 94% of the changes are instances where manager inherits at least 50% of team! 

* Restriction #2: only manager changes where at least 50% switchers come from same manager 
replace ChangeMR = 0 if PropSameTeam <0.5 | rnkmode==. // only consider manager changes where at least 50% workers who change come from same team 
replace Ei = . if ChangeMR==0

* Note: restriction 1 and 2 together ensure that at least 50% of team members all shared same previous manager and all move to same next manager 

* Restriction #3: require the manager to stay at least 3 months 
bys IDlse (YearMonth), sort: gen NoChangeM= sum(ChangeMR)
bys IDlse NoChangeM: egen noMonthsChange = count(YearMonth) // number of months for a given change 
replace noMonthsChange  = . if Ei==.
bys IDlseMHR Ei: egen modenoMonthsChange= mode(noMonthsChange), minmode
count if modenoMonthsChange==. & Ei!=. // 0, all good!
bys IDlseMHR Ei: egen PropSameTeamDuration  = mean(cond(noMonthsChange == modenoMonthsChange, 1,0))  if modenoMonthsChange!=.

replace ChangeMR  = 0 if PropSameTeamDuration==1 & noMonthsChange <3 // require new manager to stay in team at least 3 months 
replace Ei = . if ChangeMR==0

* Re-create the relevant variables 
drop IDlseMHRPre EiPre
sort IDlse YearMonth
gen IDlseMHRPre = IDlseMHR[_n-1] if Ei !=. // get the previous manager

sort IDlse YearMonth
gen EiPre = YearMonth[_n-1] if Ei !=. // month before
format EiPre %tm

* need to get the previous team: considered the one where at least 50% of workers are from 
bys IDlseMHR Ei: egen IDlseMHRPreMost = mode(IDlseMHRPre) ,  minmode //  if IDlseMHRPre!=.

* FINAL COUNT
bys IDlse: egen totEvent = sum(ChangeMR)
distinct IDlse 
distinct IDlse if totEvent>0 
di  112357/ 205432 // 54%

******************************************************************************
* Export list for team level analysis 
******************************************************************************

keep if  Ei!=. 
keep IDlseMHR Ei IDlseMHRPreMost
gen o = 1 
collapse (sum) o, by(IDlseMHR Ei IDlseMHRPreMost)
egen team = group(IDlseMHR Ei IDlseMHRPreMost)
drop o

quietly bys IDlseMHR IDlseMHRPreMost :  gen dup = cond(_N==1,0,_n) // same manager pair can have multiple events 93% of obs do not!
* drop duplicates for now 
drop if dup> 0
drop dup 
gen YearMonth = Ei 
gen ChangeMR = 1 
save "$managersdta/Temp/ListEventsTeam", replace 

******************************************************************************
* Dataset for individual level analysis 
******************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth 

/* 1) Sample restriction #0: I drop all employees with any instance of missing managers
bys IDlse: egen cM = count(cond(IDlseMHR==., YearMonth,.)) // count how many IDlse have missing manager info 
drop if cM > 0 // only keep IDlse for which manager id is never missing 
count if IDlseMHR==.
*/
* 2) Sample restriction #1: only consider time after manager type is defined 
*keep if Year>2013 // as this is only relevant for PromSG75 as a measure, then better to restrict sample afterwards 

* merge with the events 
merge m:1 IDlseMHR YearMonth using  "$managersdta/Temp/ListEventsTeam"
drop if _merge ==2
drop _merge 

* merge with manager type 
merge m:1 IDlseMHR YearMonth using  "$managersdta/Temp/MType", keepusing( LineManagerMeanB )
drop if _merge ==2
drop _merge 

* merge with manager type 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50  MFEBayesLogPayF60 MFEBayesLogPayF72 MFEBayesLogPayF6075 MFEBayesLogPayF7275 MFEBayesLogPayF6050 MFEBayesLogPayF7250)
drop if _merge ==2
drop _merge 

* 3) Restriction #2 for individual analysis only: For Sun & Abraham only consider first event 
rename Ei EiAll
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1
replace ChangeMR = 0 if ChangeMR==. 
replace IDlseMHRPreMost = . if ChangeMR== 0 
format Ei %tm 

gen KEi  = YearMonth - Ei

* Placebo event: odd or even Manager ID
gen oddManager = mod(IDlseMHR,2) 

* pca measures: combining the 2 measures  
pca MFEBayesPromSG EarlyAgeM
predict pcaFTSG, score // first component 
pca MFEBayesLogPayF60 EarlyAgeM
predict pcaFTPay, score // first component 

foreach v in pcaFTSG pcaFTPay{
	su 	`v',d 
	gen `v'50 = `v' >=r(p50) if `v'!=.
	gen `v'75 = `v' >=r(p75) if `v'!=.

}

* Constructing manager transitions on different measures of manager quality 
* Early age 
local Labels FT Effective PromSG75 PromWL75  PromSG50 PromWL50 odd pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75  pay75F60 pay75F72 pay50F60 pay50F72
local i = 1
foreach var in EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 MFEBayesLogPayF6075 MFEBayesLogPayF7275 MFEBayesLogPayF6050 MFEBayesLogPayF7250 {

local Label: word `i' of `Labels'

gsort 	IDlse YearMonth
* low high
gen `Label'LowHigh = 0 if `var'!=.
replace `Label'LowHigh = 1 if (IDlse[_n] == IDlse[_n-1] & `var'[_n]==1 & `var'[_n-1]==0  & IDlseMHR[_n]!= IDlseMHR[_n-1] )
replace `Label'LowHigh = 0 if ChangeMR ==0

* high low
gsort 	IDlse YearMonth
gen `Label'HighLow = 0 if `var'!=.
replace `Label'HighLow = 1 if (IDlse[_n] == IDlse[_n-1] & `var'[_n]==0 & `var'[_n-1]==1     & IDlseMHR[_n]!= IDlseMHR[_n-1] )
replace `Label'HighLow = 0 if ChangeMR ==0

* high high 
gsort 	IDlse YearMonth
gen `Label'HighHigh = 0 if `var'!=.
replace `Label'HighHigh = 1 if (IDlse[_n] == IDlse[_n-1] & `var'[_n]==1 & `var'[_n-1]==1    & IDlseMHR[_n]!= IDlseMHR[_n-1]  )
replace `Label'HighHigh = 0 if ChangeMR ==0

* low low 
gsort 	IDlse YearMonth
gen `Label'LowLow = 0 if `var'!=.
replace `Label'LowLow = 1 if (IDlse[_n] == IDlse[_n-1] & `var'[_n]==0 & `var'[_n-1]==0    & IDlseMHR[_n]!= IDlseMHR[_n-1] )
replace `Label'LowLow = 0 if ChangeMR ==0

bys IDlse: egen `Label'LH = mean(cond( `Label'LowHigh == 1, Ei,.)) 
bys IDlse: egen `Label'HL = mean(cond( `Label'HighLow == 1, Ei,.)) 
bys IDlse: egen `Label'HH = mean(cond(  `Label'HighHigh == 1,Ei,.)) 
bys IDlse: egen `Label'LL = mean(cond(  `Label'LowLow == 1, Ei,.)) 
format `Label'LH %tm
format `Label'LL %tm
format `Label'HH %tm
format `Label'HL %tm

su `Label'LH `Label'HH `Label'LL `Label'HL
local i = `i' + 1
} 

foreach Label in `Labels' {
foreach var in `Label'HL `Label'LL `Label'HH `Label'LH {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

*su K`var'
*forvalues l = 0/`r(max)' {
*	gen L`l'`var' = K`var'==`l'
*}
*local mmm = -(`r(min)' )
*forvalues l = 2/`mmm' { // normalize -1 
*	gen F`l'`var' = K`var'==-`l'
*}
}
}

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
merge 1:1 IDlse YearMonth using "$managersdta/Temp/Span.dta", keepusing(Span)
drop if _merge ==2 
drop _merge 
replace Span = 0 if Span==. // it means you are not a manager 


* heterogeneity by office size, tenure of manager 
bys Office YearMonth: egen OfficeSize = count(IDlse)

* only work level 2 managers 
bys IDlse: egen FirstWL2M = max(cond(WLM==2 & KEi==-1,1,0))
bys IDlse: egen LastWL2M = max(cond(WLM==2 & KEi==0,1,0))
gen WL2 = FirstWL2M ==1 & LastWL2M ==1
label var WL2 "Only works with work level 2 managers"

* add parental leave - for additional identification strategy 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/mVars.dta", keepusing(PLeaveM LeaveTypeCleanM)
keep if _merge !=2
drop _merge 

* managers that leave for child leave  
bys IDlse: egen EiPLeaveM = max(cond(PLeaveM==1& KEi==-1,1,0))
bys IDlse: egen EiLeaveM = max(cond(LeaveTypeCleanM !=""& KEi==-1,1,0))

compress
save "$managersdta/AllSameTeam.dta", replace  // full sample 

* only saving the switchers 

distinct IDlse // 205432
keep if Ei!=. //   3,538,943 / 8618267 = 41% of obs 
distinct IDlse //  52164. So 52164/   205432 = 25% experience this event 
distinct IDlseMHR // 35987

compress 
save "$managersdta/SwitchersAllSameTeam.dta", replace 
