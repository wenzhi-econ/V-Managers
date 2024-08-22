* This dofile does regressions at the team level 
* to delve deeper into some mechanisms 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

/*
- Number of workers who drop off (wherever they go): change manager 
- Number of workers who quit 
- Team diversity (gender and any other measure): female 
- Any measure of task change within team: job change 
- Average performance : salary 
Dispersion of performance: VPA, salary 
 
And estimate
 
Y_{it}= aNF_t +bFN_t 
 
(Omitted NN)
*/

********************************************************************************
* DESCRIPTIVES
********************************************************************************


* Understand how many individuals in a different unit: For employees 
use "$Managersdta/AllSnapshotMCultureMType.dta", clear 

xtset IDlse YearMonth 
bys  YearMonth SubFunc ISOCode : egen tSubFunc = count(IDlse)
bys  YearMonth SubFunc Office : egen tSubFuncO = count(IDlse)
bys  YearMonth SubFunc Office Org4: egen tSubFuncOO = count(IDlse)

egen tt = tag(YearMonth SubFunc ISOCode)
egen ttO = tag(YearMonth SubFunc Office)
egen ttOO = tag(YearMonth SubFunc Office Org4)

ta tSubFunc if tt==1 // 23% only 1 employee 
ta tSubFuncO if ttO==1 // 32% only 1 employee 
ta tSubFuncOO if ttOO==1 // 40% only 1 employee

bys IDlseMHR YearMonth: egen s = sd(SubFunc) // each manager can have reportees across different subfunctions 
count if s==0 //  4,858,728, would it be half sample! 

* Understand how many individuals in a different unit: For managers 
use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
keep if Manager ==1 

xtset IDlse YearMonth 
bys  YearMonth SubFunc ISOCode : egen tSubFunc = count(IDlse)
bys  YearMonth SubFunc Office : egen tSubFuncO = count(IDlse)
bys  YearMonth SubFunc Office Org4: egen tSubFuncOO = count(IDlse)

egen tt = tag(YearMonth SubFunc ISOCode)
egen ttO = tag(YearMonth SubFunc Office)
egen ttOO = tag(YearMonth SubFunc Office Org4)

ta tSubFunc if tt==1 // 38% only 1 manager 
ta tSubFuncO if ttO==1 // 50% only 1 manager 
ta tSubFuncOO if ttOO==1 // 58% only 1 manager 

********************************************************************************
* NOW CAN CREATE TEAM LEVEL DATASET
********************************************************************************

use  "$Managersdta/SwitchersSameTeam.dta", clear 
use  "$Managersdta/SwitchersAllSameTeam.dta", clear 

* understanding why managers inherit the teams 
gen ManagerTransfer =0
replace ManagerTransfer = 1 if TransferSJM ==1 | TransferSJL1M ==1 | TransferSJL2M ==1 | TransferSJL3M ==1 | TransferSJF1M ==1 | TransferSJF2M ==1 | TransferSJF3M ==1
ta ChangeMR TransferSJM 
ta ChangeMR ManagerTransfer
ta ChangeMR PromWLM
ta ChangeMR ChangeSalaryGradeM
ta LeaverPermM if IDlseMHRPre!=.
ta ManagerTransfer if IDlseMHRPre!=.

* Contstruct team indicators 
xtset IDlse YearMonth
gen eventT = Ei if YearMonth == Ei
format eventT %tm
format Ei %tm 

replace IDlseMHRPre = . if eventT == .
bys IDlse: egen teamPre = mean(cond(eventT!=., IDlseMHRPre, .))  // team of the manager the employee was reporting before 
bys IDlse: egen teamPost = mean(cond(eventT!=., IDlseMHR, .)) // team of the manager the employee was reporting after

egen team = group(teamPre teamPost Ei) // team ID - need to incorporate event time as there are manager pairs that have more than one event 
drop if team ==. 
distinct team
 
bys team KEi: egen s = count(IDlse) // how many workers in the team 

* OUTCOME VARIABLES 
gen ExitTeam = IDlseMHR != teamPost & KEi>=1
gen o =1 

* CONTROL VARIABLES AT THE MANAGER LEVEL 
foreach var in FemaleM WLM  EarlyAgeM AgeBandM FuncM SubFuncM {
bys IDlse: egen `var'Pre = mean(	cond(KEi == -1, `var' , .)) 
bys IDlse: egen `var'Post = mean(	cond(KEi == 0, `var' , .)) 
} 

* !TEAM LEVEL DATASET! 
collapse  WLM FemaleM s ELH ELL EHL EHH *Pre *Post ShareExitTeam = ExitTeam ShareFemale = Female ShareSameG = SameGender  ShareOutGroup = OutGroup ShareDiffOffice = DiffOffice TeamTenure=Tenure TeamPay = PayBonus  TeamVPA = VPA ShareLeaverVol = LeaverVol ShareLeaver = LeaverPerm  ///
ShareTransferSJ = TransferSJ  ShareTransferInternalSJ = TransferInternalSJ ShareTransferInternal= TransferInternal ShareTransferSubFunc= TransferSubFunc   ///
SharePromWL=  PromWL  ShareChangeSalaryGrade = ChangeSalaryGrade    ///
ShareTransferSJSameM = TransferSJSameM  ShareTransferInternalSJSameM = TransferInternalSJSameM  ShareTransferInternalSameM= TransferInternalSameM   SharePromWLSameM= PromWLSameM   ///
ShareTransferSJDiffM = TransferSJDiffM ShareTransferInternalSJDiffM = TransferInternalSJDiffM ShareTransferInternalDiffM= TransferInternalDiffM ShareChangeSalaryGradeDiffM = ChangeSalaryGradeDiffM SharePromWLDiffM=  PromWLDiffM  ///
(sd) TeamPaySD = PayBonus TeamVPASD = VPA (sum) SpanM = o , by(team KEi )

xtset team KEi 
global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

gen TeamPayCV =  TeamPaySD / TeamPay 
gen TeamVPACV =  TeamVPASD / TeamVPA 

label var ShareExitTeam "Exit Team"
label var ShareLeaver "Exit Firm"
label var ShareTransferSJ  "Job Change"
label var ShareChangeSalaryGrade  "Prom. (salary)"
label var SharePromWL  "Prom. (work level)"
label var TeamPayCV  "Pay (CV)"
label var TeamVPACV  "Perf. Appraisals (CV)"

ta SpanM if KEi ==0


keep if KEi <13 & KEi >-13
bys team: egen minSpan = min(SpanM) 
gen Post = 0 
replace Post = 1 if  KEi <13 & KEi>=0 

ds team Post, not
collapse `r(varlist)' , by(team Post)


********************************************************************************
* TEAM LEVEL REGRESSIONS 
********************************************************************************

foreach y in ShareExitTeam ShareLeaver  ShareTransferSJ   ShareChangeSalaryGrade SharePromWL TeamPayCV TeamVPACV {
eststo:	reghdfe `y' ELLPost ELHPost EHHPost EHLPost  if SpanM>0 & KEi <13 & KEi >-13 , a(team ) cluster(team)
}

********************************************************************************
* ALL TEAM DATASET  
********************************************************************************

use "$Managersdta/AllSameTeam.dta", clear 
* Goal: to fix the team at the manager pre-manager post level, look at 12 months pre and 12 months post
* event is already defined as that where all members change manager 

keep if IDlseMHRPre!=.
keep YearMonth IDlseMHR KEi // event-manager pair 

keep if KEi >=0 & KEi <=12 // post year 
save "$Managersdta/Temp/Post.dta" , replace 

xtset KEi 
tsfill 



merge 1:m IDlseMHR YearMonth, 

********************************************************************************
* FUNNEL 
********************************************************************************

use  "$Managersdta/SwitchersSameTeam.dta", clear 

* !TEAM LEVEL DATASET! 
collapse  s ELH ELL EHL EHH *Pre FemaleMPost  WLMPost  EarlyAgeMPost  AgeBandMPost  FuncMPost  SubFuncMPost ShareExitTeam = ExitTeam ShareFemale = Female ShareSameG = SameGender  ShareOutGroup = OutGroup ShareDiffOffice = DiffOffice TeamTenure=Tenure TeamPay = PayBonus  TeamVPA = VPA ShareLeaverVol = LeaverVol ShareLeaver = LeaverPerm  ///
ShareTransferSJ = TransferSJ  ShareTransferInternalSJ = TransferInternalSJ ShareTransferInternal= TransferInternal ShareTransferSubFunc= TransferSubFunc   ///
SharePromWL=  PromWL  ShareChangeSalaryGrade = ChangeSalaryGrade    ///
ShareTransferSJSameM = TransferSJSameM  ShareTransferInternalSJSameM = TransferInternalSJSameM  ShareTransferInternalSameM= TransferInternalSameM   SharePromWLSameM= PromWLSameM   ///
ShareTransferSJDiffM = TransferSJDiffM ShareTransferInternalSJDiffM = TransferInternalSJDiffM ShareTransferInternalDiffM= TransferInternalDiffM ShareChangeSalaryGradeDiffM = ChangeSalaryGradeDiffM SharePromWLDiffM=  PromWLDiffM  ///
(sd) TeamPaySD = PayBonus TeamVPASD = VPA (sum) SpanM = o , by(teamPost KEi )

/********************************************************************************
* Need to define relevant team unit
* Approach is: get the employees with previous manager for pre and then new manager for post  
********************************************************************************

use  "$Managersdta/Switchers.dta", clear 

xtset IDlse YearMonth
gen eventT = Ei if YearMonth == Ei
format eventT %tm
format Ei %tm 
gen eventTF1 = f.eventT

bys IDlse: egen teamPre = mean(cond(eventTF1!=., IDlseMHR, .)) // team of the manager the employee was reporting before 
bys IDlse: egen teamPost = mean(cond(eventT!=., IDlseMHR, .)) // team of the manager the employee was reporting after

********************************************************************************
* need to add other team member info that potentially left before the switch 
********************************************************************************

forval i = 1/12{
bys teamPre teamPost: egen MonthPre`i' = mean(cond(KEi ==-`i', YearMonth, .))
format MonthPre`i' %tm
}
preserve 
gen o = 1
collapse o, by(teamPre teamPost MonthPre12 MonthPre11 MonthPre10 MonthPre9 ///
MonthPre8 MonthPre7 MonthPre6 MonthPre5 MonthPre4 MonthPre3 MonthPre2 MonthPre1)
drop if teamPre==. 
isid teamPre teamPost
drop o 
egen group = group(teamPre teamPost)
rename MonthPre* YearMonth*
reshape long  YearMonth, i(teamPre teamPost ) j(MonthPre)
rename teamPre IDlseMHR 
drop if YearMonth ==.
quietly bys IDlseMHR YearMonth :  gen dup = cond(_N==1,0,_n) // 74% with not duplicates, the rest is due to people who change to a different manager 
collapse MonthPre, by(IDlseMHR YearMonth)
replace MonthPre = -MonthPre
rename MonthPre KEi 
gen teamPre = IDlseMHR 
save "$Managersdta/Temp/TeamPre.dta", replace 
restore

use  "$Managersdta/AllSnapshotMCulture.dta", clear
merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/TeamPre.dta" // identify team members & their chars who may have left before 
keep if _merge ==3
drop _merge 
merge 1:1 IDlse YearMonth using "$Managersdta/Switchers.dta"
keep if _merge ==1 // list of team members not already present in the switchers dataset
compress
save "$Managersdta/Temp/TeamPretoAppend.dta", replace 

use  "$Managersdta/SwitchersSameTeam.dta", clear 

gen ManagerTransfer =0
replace ManagerTransfer = 1 if TransferSJM ==1 | TransferSJL1M ==1 | TransferSJL2M ==1 | TransferSJL3M ==1 | TransferSJF1M ==1 | TransferSJF2M ==1 | TransferSJF3M ==1
ta ChangeMR TransferSJM 
ta ChangeMR ManagerTransfer
ta ChangeMR PromWLM
ta ChangeMR ChangeSalaryGradeM
ta LeaverPermM if IDlseMHRPre!=.
ta ManagerTransfer if IDlseMHRPre!=.

global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

xtset IDlse YearMonth
gen eventT = Ei if YearMonth == Ei
format eventT %tm
format Ei %tm 
*gen eventTF1 = f.eventT

replace IDlseMHRPre = . if eventT == .
bys IDlse: egen teamPre = mean(cond(eventT!=., IDlseMHRPre, .))  // team of the manager the employee was reporting before 
bys IDlse: egen teamPost = mean(cond(eventT!=., IDlseMHR, .)) // team of the manager the employee was reporting after

gen Switcher = 1
append using "$Managersdta/Temp/TeamPretoAppend.dta" // append team members that did not experience the same manager switch 
