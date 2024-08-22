********************************************************************************
* Defining social connections 
* Does manager sends you more often to socially connected colleagues? 
********************************************************************************

* 1) Create list of manager to create the wide dataset manager-month level with list of previous colleagues in wide format 
********************************************************************************

* list of colleagues * 
use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 
drop if IDlseMHR==.


su TeamSize ,d
keep if TeamSize <= `r(p95)'

gen o =1 
bys IDlseMHR YearMonth: gen No = sum(o)

keep IDlse IDlseMHR YearMonth No
rename IDlse Coll 
reshape wide  Coll , i(IDlseMHR YearMonth) j(No)
isid IDlseMHR YearMonth
compress 
save "$Managersdta/Temp/MConnectionsPeople.dta" , replace // the list includes all managers' reportees

* 2) Create list of previous managers/offices/org4/subfunctions to create the dataset manager-month level with list of places 
********************************************************************************

* previous offices etc. + manager * 
use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 
drop if IDlseMHR==.
keep IDlse YearMonth  Office Org4 SubFunc IDlseMHR

rename (Office Org4 SubFunc IDlseMHR) (=YM)
gen IDlseMHR = IDlse // for easy merging 
drop IDlse 
compress 
save "$Managersdta/Temp/MConnectionsPlaces.dta" , replace // to merge to manager 

*reshape wide OfficeYM Org4YM SubFuncYM IDlseMHRYM, i(IDlseMHR) j(YearMonth)
*compress 
*save "$Managersdta/Temp/MConnectionsPlacesWide.dta" , replace // to merge to manager 

* MERGE TO SWITCHERS DATA & CREATE SOCIALLY CONNECTED TRANSITION DUMMY FOR FIRST MANAGER AFTER THE TRANSITION EVENT 
********************************************************************************

* managers connections before event (<=F1): first manager/post after the event 
use "$Managersdta/SwitchersAllSameTeam.dta", clear 

* transition manager 
bys IDlse: egen ManagerEvent = min(cond( KEi==0, IDlseMHR,. ))  // new manager from transition "event manager"
bys IDlse: egen LastMonth = max(cond(IDlseMHR == ManagerEvent, YearMonth,. ))  // latest month with the event manager

* identify the first manager change after event 
sort IDlse YearMonth 
gen o =1 
bys IDlse IDlseMHR (YearMonth), sort: egen Managercum = sum(o)
bys IDlse: egen FirstManagerMonth = min(cond(ChangeM==1 & KEi>0 & Managercum>3 , YearMonth,. ))  // minimum of 1 quarter with next manager (If I remove this condition, the share of connected barely changes and if anything it decreases)
format  FirstManagerMonth  %tm

* 1) look at places: is the worker new place is the old manager's previous place?  
 foreach var in IDlseMHR SubFunc Office Org4 {
bys IDlse: egen  First`var'  = mean(cond(YearMonth == FirstManagerMonth , `var', . )) 	
 label value First`var' `var'
 }

merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/MConnectionsPlaces.dta"
drop if _merge ==2 
drop _merge 

* 2) look at people: is the worker new manager the old manager's manager or colleague? 
merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/MConnectionsPeople.dta"
drop if _merge ==2 
drop _merge 

* only consider people & places before event 
findregex, re("^Coll")

global Coll Coll1 Coll2 Coll3 Coll4 Coll5 Coll6 Coll7 Coll8 Coll9 Coll10 Coll11 Coll12 Coll13 Coll14 Coll15 Coll16 Coll17 Coll18 Coll19 Coll20 Coll21 Coll22 Coll23 Coll24 Coll25 Coll26 Coll27 Coll28 Coll29 Coll30 Coll31 Coll32 Coll33 Coll34 Coll35 Coll36 Coll37 Coll38 Coll39 Coll40 Coll41 Coll42 Coll43 Coll44 Coll45 Coll46

foreach v in $Coll  OfficeYM Org4YM SubFuncYM IDlseMHRYM  {
	replace `v'= . if YearMonth>=Ei 
}

* 1) people: manager's manager (any of the previous manager's managers) or manager's colleagues 
bys IDlse: egen ConnectedIDlseMHR  = max(cond( FirstIDlseMHR!=. & (FirstIDlseMHR ==   IDlseMHRYM | FirstIDlseMHR ==  Coll1 | FirstIDlseMHR ==  Coll2 | FirstIDlseMHR ==  Coll3 | FirstIDlseMHR ==  Coll4 | FirstIDlseMHR ==  Coll5 | FirstIDlseMHR ==  Coll6 | FirstIDlseMHR ==  Coll7 | FirstIDlseMHR ==  Coll8 | FirstIDlseMHR ==  Coll9 | FirstIDlseMHR ==  Coll10 | FirstIDlseMHR ==  Coll11 | FirstIDlseMHR ==  Coll12 | FirstIDlseMHR ==  Coll13 | FirstIDlseMHR ==  Coll14 | FirstIDlseMHR ==  Coll15 | FirstIDlseMHR ==  Coll16 | FirstIDlseMHR ==  Coll17 | FirstIDlseMHR ==  Coll18 | FirstIDlseMHR ==  Coll19 | FirstIDlseMHR ==  Coll20 | FirstIDlseMHR ==  Coll21 | FirstIDlseMHR ==  Coll22 | FirstIDlseMHR ==  Coll23 | FirstIDlseMHR ==  Coll24 | FirstIDlseMHR ==  Coll25 | FirstIDlseMHR ==  Coll26 | FirstIDlseMHR ==  Coll27 | FirstIDlseMHR ==  Coll28 | FirstIDlseMHR ==  Coll29 | FirstIDlseMHR ==  Coll30 | FirstIDlseMHR ==  Coll31 | FirstIDlseMHR ==  Coll32 | FirstIDlseMHR ==  Coll33 | FirstIDlseMHR ==  Coll34 | FirstIDlseMHR ==  Coll35 | FirstIDlseMHR ==  Coll36 | FirstIDlseMHR ==  Coll37 | FirstIDlseMHR ==  Coll38 | FirstIDlseMHR ==  Coll39 | FirstIDlseMHR ==  Coll40 | FirstIDlseMHR ==  Coll41 | FirstIDlseMHR ==  Coll42 | FirstIDlseMHR ==  Coll43 | FirstIDlseMHR ==  Coll44 | FirstIDlseMHR ==  Coll45 | FirstIDlseMHR ==  Coll46) ,1,0)) 
ta ConnectedIDlseMHR  if  YearMonth == FirstManagerMonth // only 1 individual to a socially connected manager but 10% with colleagues  

* to inspect manually as a check, all good 
bys IDlse: egen ConnectedColl1  = max(cond( FirstIDlseMHR!=. & (FirstIDlseMHR ==  Coll1) ,1,0)) 
sort IDlse YearMonth
br  IDlse IDlseMHR KEi FirstIDlseMHR ConnectedColl1 Coll1 Managercum if ConnectedColl1==1 

* 2) places:  SubFunc Office Org4 
foreach v in SubFunc Office Org4 {
	bys IDlse: egen `v'TempBefore = mean(cond(KEi==-1, `v', .)) // what employee was doing before switch
	bys IDlse: egen `v'Temp = mean(cond(KEi==0, `v', .)) // what employee does at time of switch
	bys IDlse: egen `v'TempLast = mean(cond(YearMonth ==LastMonth, `v', .)) // what employee does at the last month of switch 

	label value (`v'Temp `v'TempBefore `v'TempLast) `v' 
	bys IDlse: egen Connected`v'  = max(cond( (First`v' ==   `v'YM & First`v' != `v'Temp & First`v' != `v'TempLast & First`v' != `v'TempBefore & First`v' !=. ) ,1,0)) 
}

* <<<<<<<<<<<<<<<<< overall connected dummy - SOCIALLY CONNECTED MANAGER TRANSITION >>>>>>>
egen Connected = rowmax(ConnectedIDlseMHR ConnectedSubFunc ConnectedOffice ConnectedOrg4)
ta  Connected if YearMonth == FirstManagerMonth // 14% (3 % of cases without people, only places) conditional on a manager change 

ta MFEBayesPromSG75 Connected, row   // seems as likely to have socially connected transition with a better manager 

keep IDlse FirstManagerMonth FirstIDlseMHR Connected ConnectedIDlseMHR ConnectedSubFunc ConnectedOffice ConnectedOrg4
keep if Connected ==1 
label var Connected "Socially Connected M trans."
label var ConnectedIDlseMHR "M trans. to colleague" 
label var ConnectedSubFunc "M trans. to sub-func" 
label var ConnectedOffice "M trans. to office" 
label var ConnectedOrg4 "M trans. to org4"
duplicates drop

gen   YearMonth = FirstManagerMonth
gen   IDlseMHR = FirstIDlseMHR
label var YearMonth  "for easy merging, = FirstManagerMonth"
compress 
save "$Managersdta/Temp/MTransferConnected.dta" , replace 

* command to merge to master data 
merge 1:1 IDlse YearMonth using "$Managersdta/Temp/MTransferConnected.dta", keepusing(FirstIDlseMHR FirstManagerMonth Connected ConnectedIDlseMHR ConnectedOffice ConnectedOrg4 ConnectedSubFunc) 


* here I need to do table: transfer with or without social connections 

/* create window around event 
gen Window = YearMonth -  Ei
su Window
local mmm = -(`r(min)' )
forvalues l = 1/ `mmm' { // normalize -1 and r(min)
	gen F`l'Window = Window==-`l'
}
su Window
forvalues l = 0/`r(max)' { // normalize 0 and r(max)
	gen L`l'Window = Window`i'==`l'
}

