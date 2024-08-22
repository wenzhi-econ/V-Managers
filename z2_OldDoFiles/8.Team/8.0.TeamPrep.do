////////////////////////////////////////////////////////////////////////////////
* TEAM LEVEL EVENT ANALYSIS - create dataset 
////////////////////////////////////////////////////////////////////////////////

* First create the post event - up to 12 months after switch 
////////////////////////////////////////////////////////////////////////////////

*gen IDlseMHRPost = IDlseMHR 
*gen YearMonth = Ei 
use "$managersdta/Temp/ListEventsTeam", clear 
drop YearMonth 

gen Ei0 = Ei
rename Ei Event
forval i = 1/48{
gen Ei`i' = Ei0 + `i'
format 	 Ei`i' %tm
}

reshape long Ei , i(IDlseMHR IDlseMHRPreMost Event team) j(KEi)
br if Event!=Ei & KEi==0 // 0, all good 

isid IDlseMHR IDlseMHRPreMost KEi Event

rename Ei YearMonth

merge m:1 IDlseMHR YearMonth  using "$managersdta/Temp/MType.dta"
keep if _merge ==3 
drop _merge 

merge m:1 IDlseMHR YearMonth  using "$managersdta/Temp/TeamChurn.dta" 
keep if _merge ==3 
drop _merge 

compress 
save "$managersdta/Temp/EventTeamPost.dta" ,replace 

* Then create the pre event -  12 months before switch 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/Temp/ListEventsTeam", clear 

drop YearMonth

gen Ei0 = Ei
rename Ei Event
forval i = 1/48{
gen Ei`i' = Ei0 - `i'
format 	 Ei`i' %tm
}

reshape long Ei , i(IDlseMHR IDlseMHRPreMost Event) j(KEi)
br if Event!=Ei & KEi==0 // 0, all good 

replace KEi = - KEi 
drop if KEi == 0 

rename IDlseMHR IDlseMHRPost 
rename IDlseMHRPreMost  IDlseMHR

rename Ei YearMonth

isid IDlseMHR IDlseMHRPost  KEi Event

sort IDlseMHR YearMonth 

merge m:1 IDlseMHR YearMonth  using "$managersdta/Temp/MType.dta"
keep if _merge ==3 
drop _merge 

merge m:1 IDlseMHR YearMonth  using "$managersdta/Temp/TeamChurn.dta" 
keep if _merge ==3 
drop _merge 

compress 
save "$managersdta/Temp/EventTeamPre.dta" ,replace 

////////////////////////////////////////////////////////////////////////////////
* Append & create manager quality switches 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/Temp/EventTeamPre.dta", clear 
append using "$managersdta/Temp/EventTeamPost.dta"
isid team KEi

merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2015.dta", keepusing(MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50)
drop if _merge ==2
drop _merge

rename (MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50) =v2015

merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50)
drop if _merge ==2
drop _merge 

* Constructing manager transitions on different measures of manager quality 
* Early age 
local Labels FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015
local i = 1
foreach var in EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015 {

local Label: word `i' of `Labels'

xtset team YearMonth 
gen diff`Label' = d.`var' // can be replace with d.EarlyAgeM
gen Delta`Label'tag = diff`Label' if YearMonth == Event
bys team: egen Delta`Label' = mean(Delta`Label'tag)

gsort team KEi
* low high
gen `Label'LowHigh = 0 if `var'!=.
replace `Label'LowHigh = 1 if (team[_n] == team[_n-1] & `var'[_n]==1 & `var'[_n-1]==0  & IDlseMHR[_n]!= IDlseMHR[_n-1] )

* high low
gsort team KEi
gen `Label'HighLow = 0 if `var'!=.
replace `Label'HighLow = 1 if (team[_n] == team[_n-1] & `var'[_n]==0 & `var'[_n-1]==1     & IDlseMHR[_n]!= IDlseMHR[_n-1] )

* high high 
gsort team KEi
gen `Label'HighHigh = 0 if `var'!=.
replace `Label'HighHigh = 1 if (team[_n] == team[_n-1] & `var'[_n]==1 & `var'[_n-1]==1    & IDlseMHR[_n]!= IDlseMHR[_n-1]  )

* low low 
gsort team KEi  
gen `Label'LowLow = 0 if `var'!=.
replace `Label'LowLow = 1 if (team[_n] == team[_n-1] & `var'[_n]==0 & `var'[_n-1]==0    & IDlseMHR[_n]!= IDlseMHR[_n-1] )

bys team: egen `Label'LH = mean(cond( `Label'LowHigh == 1, Event,.)) 
bys team: egen `Label'HL = mean(cond( `Label'HighLow == 1, Event,.)) 
bys team: egen `Label'HH = mean(cond(  `Label'HighHigh == 1, Event,.)) 
bys team: egen `Label'LL = mean(cond(  `Label'LowLow == 1, Event,.)) 
format `Label'LH %tm
format `Label'LL %tm
format `Label'HH %tm
format `Label'HL %tm

su `Label'LH `Label'HH `Label'LL `Label'HL
local i = `i' + 1
} 

foreach Label in `Labels' {
foreach var in `Label'HL `Label'LL `Label'HH `Label'LH {
gen K`var' = KEi if `var' !=.

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.  & Delta`Label'!=.

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

* OUTCOME VARIABLES 
label var ShareExitTeam "Exit Team"
label var ShareLeaver "Exit Firm"
label var ShareLeaverVol "Exit Firm (Vol.)"
label var ShareLeaverInv "Exit Firm (Inv.)"
label var ShareTransferInternal  "Sub-func Change"
label var ShareOrg4  "Org. Unit Change"
label var ShareChangeSalaryGrade  "Prom. (salary)"
label var SharePromWL  "Prom. (work level)"
label var ShareTeamJoiners "Join Team"
label var ShareTeamLeavers "Change Team"
label var ShareTenureBelow1 "New Hire"
label var ShareTenureBelowEq1 "New Hire"
label var ShareNewHire "New Hire"
label var ShareTransferSJ  "Job Change, same team"
label var ShareTransferSJSameM  "Job Change, same team"
label var F1ShareTransferSJDiffM  "Job Change, diff. team"
label var F1ShareTransferSJDiffM  "Job Change, diff. team"
label var F1ShareTransferInternalDiffM  "Sub-func Change, diff. team"
label var F1ShareChangeSalaryGradeDiffM  "Prom. (salary), diff. team"
label var F1SharePromWLDiffM  "Prom. (work level), diff. team"
label var F3mShareTransferSJDiffM  "Job Change, diff. team"
label var F3mShareTransferSJDiffM  "Job Change, diff. team"
label var F3mShareTransferInternalDiffM  "Sub-func Change, diff. team"
label var F3mShareChangeSalaryGradeDiffM  "Prom. (salary), diff. team"
label var F3mSharePromWLDiffM  "Prom. (work level), diff. team"
label var F6mShareTransferSJDiffM  "Job Change, diff. team"
label var F6mShareTransferSJDiffM  "Job Change, diff. team"
label var F6mShareTransferInternalDiffM  "Sub-func Change, diff. team"
label var F6mShareChangeSalaryGradeDiffM  "Prom. (salary), diff. team"
label var F6mSharePromWLDiffM  "Prom. (work level), diff. team"
label var CVPay  "Pay (CV)"
label var CVVPA  "Perf. Appraisals (CV)"
label var SDProductivityStd "Productivity (SD)"
label var AvPayGrowth "Pay Growth"
label var AvPay "Av. Pay+Bonus"
label var AvProductivityStd "Productivity"

* Diversity / homophily
label var ShareFemale "Female Share"
label var ShareSameOffice "Same Office"
label var ShareSameG "Same Gender"
label var ShareOutGroup "Diff. Hiring Office"
label var ShareSameNationality "Same First Country"
label var ShareSameCountry "Same Country"
label var ShareSameAge "Same Age Band"
label var F1ShareConnected "Move within Manager's network"
label var F1ShareConnectedL "Lateral Move within Manager's network"
label var F1ShareConnectedV "Prom. within Manager's network"
label var TeamFracGender "Diversity, gender"
label var TeamFracOffice "Diversity, office"
label var TeamFracAge "Diversity, age"
label var TeamFracCountry "Diversity, country"
label var TeamFracNat "Diversity, nationality"

* OVERALL TEAM COMPOSITION SHARES 
label var Female "Share Female"
label var Age20  "Share Age < 20"
label var MBA "Share MBA"
label var Econ "Share Econ"
label var Sci "Share STEM"
label var Hum  "Share Humanities"
label var NewHire "Share New Hire"
label var Tenure5 "Share Tenure <5"
label var EarlyAge "Share Fast Track"
label var PayGrowth1yAbove0 "Share PayGrowth>0"
label var PayGrowth1yAbove1 "Share PayGrowth>0.01"

* team joiners and leavers profiles 
label var F1ChangeMFemale "Female" 
label var ChangeMFemale "Female" 
label var LeaverPermFemale "Female" 
label var ExitTeamFemale "Female" 

label var F1ChangeMAge20 "Age<30" 
label var ChangeMAge20 "Age<30" 
label var LeaverPermAge20 "Age<30"
label var ExitTeamAge20 "Age<30"

label var F1ChangeMMBA "MBA" 
label var ChangeMMBA "MBA" 
label var LeaverPermMBA "MBA"
label var ExitTeamMBA "MBA"

label var F1ChangeMEcon "Econ Major" 
label var ChangeMEcon "Econ Major" 
label var LeaverPermEcon "Econ Major"
label var ExitTeamEcon "Econ Major"

label var F1ChangeMSci "STEM Major" 
label var ChangeMSci "STEM Major" 
label var LeaverPermSci "STEM Major"
label var ExitTeamSci "STEM Major"

label var F1ChangeMHum "Humanities Major" 
label var ChangeMHum "Humanities Major" 
label var LeaverPermHum "Humanities Major"
label var ExitTeamHum "Humanities Major"

label var F1ChangeMNewHire "New Hire" 
label var ChangeMNewHire "New Hire" 
label var LeaverPermNewHire "New Hire"
label var ExitTeamNewHire "New Hire"

label var F1ChangeMTenure5 "Tenure<5" 
label var ChangeMTenure5 "Tenure<5" 
label var LeaverPermTenure5 "Tenure<5"
label var ExitTeamTenure5 "Tenure<5"

label var F1ChangeMEarlyAge "Fast Track" 
label var ChangeMEarlyAge "Fast Track" 
label var LeaverPermEarlyAge "Fast Track"
label var ExitTeamEarlyAge "Fast Track"

label var F1ChangeMPayGrowth1yAbove0 "Pay Growth>0" 
label var ChangeMPayGrowth1yAbove0 "Pay Growth>0" 
label var LeaverPermPayGrowth1yAbove0 "Pay Growth>0"
label var ExitTeamPayGrowth1yAbove0 "Pay Growth>0"

label var F1ChangeMPayGrowth1yAbove1 "Pay Growth>0.01" 
label var ChangeMPayGrowth1yAbove1 "Pay Growth>0.01" 
label var LeaverPermPayGrowth1yAbove1 "Pay Growth>0.01"
label var ExitTeamPayGrowth1yAbove1 "Pay Growth>0.01"

* Post indicator 
gen Post = 0 
replace Post = 1 if   KEi>=0 

compress
save "$managersdta/Teams.dta", replace



/* first create a list of employees that experience the events 
use "$managersdta/AllSnapshotMCultureMType.dta", clear 

merge m:1 IDlseMHR YearMonth using  "$managersdta/Temp/ListEventsTeam"
keep if _merge ==3
drop _merge 

bys IDlseMHR Ei: egen SizeEvent = sum(ChangeMR)
drop if SizeEvent==1 // for teams analysis ensure teams are > 1!
*keep IDlse IDlseMHR Ei IDlseMHRPreMost team ChangeMR
collapse SizeEvent, by(IDlse)
isid IDlse 
save "$managersdta/Temp/EmployeeList.dta" ,replace 

* then extract the full time series for this list of employees 
use "$managersdta/Temp/EmployeeList.dta", clear 
merge 1:m IDlse using "$managersdta/AllSnapshotMCultureMType.dta"
keep if _merge ==3 
drop _merge 
save "$managersdta/Temp/TeamSample.dta" ,replace 
*/

