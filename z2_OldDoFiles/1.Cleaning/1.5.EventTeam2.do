* This dofile constructs the dataset for the event analysis 

********************************************************************************
* IMPORT DATASET - only consider first event 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth 
*keep if YearMonth <=tm(2020m3)

*1) Sample restriction 0: I drop all employees with any instance of missing managers
bys IDlse: egen cM = count(cond(IDlseMHR==., YearMonth,.)) // count how many IDlse have missing manager info 
ta cM // 90% of obs have non-missing manager info
/* drop if cM > 0 // only keep IDlse for which manager id is never missing 
drop cM 
*/

* Restriction #1: Changing manager for employee but employee does not change team at the same time 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 
replace ChangeMR = 0 if TransferInternal==1 | TransferSJ==1 
replace  ChangeMR  = . if ChangeM==.
replace  ChangeMR  = . if IDlseMHR ==. 

* merge with manager type 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesLogPayF60 MFEBayesLogPayF72 MFEBayesLogPayF6075 MFEBayesLogPayF7275 MFEBayesLogPayF6050 MFEBayesLogPayF7250 )
drop if _merge ==2
drop _merge 

* merge with manager type 
merge m:1 IDlseMHR YearMonth using  "$managersdta/Temp/MType", keepusing( LineManagerMeanB )
drop if _merge ==2
drop _merge 

* Placebo event: odd or even Manager ID
gen oddManager = mod(IDlseMHR,2) 

* pca measures: combining the 2 measures  
pca MFEBayesLogPayF60 EarlyAgeM
predict pcaFTPay, score // first component 
pca MFEBayesPromSG EarlyAgeM
predict pcaFTSG, score // first component 

foreach v in pcaFTSG pcaFTPay{
	su 	`v',d 
	gen `v'50 = `v' >=r(p50) if `v'!=.
	gen `v'75 = `v' >=r(p75) if `v'!=.
}

* Restriction #2 for individual analysis only: For Sun & Abraham only consider first event 
* first manager change observed in the data 
bys IDlse: egen    EiChange = min(cond(ChangeM==1, YearMonth ,.)) // for single differences 
bys IDlse: egen    Ei = mean(cond(ChangeMR==1 & YearMonth == EiChange, EiChange ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1
replace ChangeMR = 0 if ChangeMR==. 
format Ei %tm 

gen KEi = YearMonth - Ei 

* Constructing manager transitions on different measures of manager quality 
* Early age 
local Labels FT Effective PromSG75 PromWL75  PromSG50 PromWL50 odd pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 pay75F60 pay75F72 pay50F60 pay50F72
local i = 1
foreach var in EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75  MFEBayesLogPayF6075 MFEBayesLogPayF7275 MFEBayesLogPayF6050 MFEBayesLogPayF7250{

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

* add parental leave - for additional identification strategy 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/mVars.dta", keepusing(PLeaveM LeaveTypeCleanM)
keep if _merge !=2
drop _merge 

* managers that leave for child leave  
bys IDlse: egen EiPLeaveM = max(cond(PLeaveM==1& KEi==-1,1,0))
bys IDlse: egen EiLeaveM = max(cond(LeaveTypeCleanM !=""& KEi==-1,1,0))

* add social connections 
* these variables take value 1 for the entire duration of the manager-employee spell, 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/MTransferConnectedAll.dta", keepusing( ///
Connected ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4 ///
ConnectedC ConnectedManagerC ConnectedSubFuncC ConnectedOfficeC ConnectedOrg4C ///
ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
ConnectedLC ConnectedManagerLC ConnectedSubFuncLC ConnectedOfficeLC ConnectedOrg4LC ///
ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ConnectedVC ConnectedManagerVC ConnectedSubFuncVC ConnectedOfficeVC ConnectedOrg4VC ) 
drop if _merge ==2
drop _merge 

label var Connected "Move within manager's network"
label var ConnectedL "Lateral move within manager's network"
label var ConnectedV "Prom. within manager's network"

* heterogeneity by office size, tenure of manager 
bys Office YearMonth: egen OfficeSize = count(IDlse)

* only work level 2 managers 
bys IDlse: egen FirstWL2M = max(cond(WLM==2 & KEi==-1,1,0))
bys IDlse: egen LastWL2M = max(cond(WLM==2 & KEi==0,1,0))
gen WL2 = FirstWL2M ==1 & LastWL2M ==1
label var WL2 "Only works with work level 2 managers"

* HOW MANY WORK LEVEL 2 MANAGERS 
distinct IDlseMHR if WLM==2 //  25761
* how many work level 1 workers & work level 2 managers 
distinct IDlse if WL==1 & WLM==2 // 27711

compress
save "$managersdta/AllSameTeam2.dta", replace  // full sample 

* SWITCHERS DATASET
distinct IDlse // 205432
distinct IDlse if WL==1 & WLM==2 //   132657 
keep if Ei!=. //   3,538,943 / 8618267 = 41% of obs 

* WORKERS 
distinct IDlse //  52164. So 52164/   205432 = 25% experience this event 
distinct IDlse if WL2==1 //  27,711. So 27,711/    132657 = 21% experience this event 

* MANAGERS
distinct IDlseMHR // 35987
distinct IDlseMHR if WLM==2 & Ei==YearMonth //  10081
 
di  13755/ 25761 // = 53% where  25761 is the total number of Work-level 2 managers 
compress 
save "$managersdta/SwitchersAllSameTeam2.dta", replace 




