********************************************************************************
* Defining social connections 
* Does manager sends you more often to socially connected colleagues? 
********************************************************************************

* 1) Create list of manager to create the wide dataset manager-month level with list of previous colleagues in wide format 
********************************************************************************

* list of colleagues * 
use "$managersdta/AllSnapshotMCultureMType.dta", clear 
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
save "$managersdta/Temp/MConnectionsPeople.dta" , replace // the list includes all managers' reportees

* 2) Create list of previous managers/offices/org4/subfunctions to create the dataset manager-month level with list of places 
********************************************************************************

* previous offices etc. + manager * 
use "$managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 
drop if IDlseMHR==.
keep IDlse YearMonth  Office Org4 SubFunc IDlseMHR

rename (Office Org4 SubFunc IDlseMHR) (=YM)
gen IDlseMHR = IDlse // for easy merging 
drop IDlse 
compress 
save "$managersdta/Temp/MConnectionsPlaces.dta" , replace // to merge to manager 

*reshape wide OfficeYM Org4YM SubFuncYM IDlseMHRYM, i(IDlseMHR) j(YearMonth)
*compress 
*save "$managersdta/Temp/MConnectionsPlacesWide.dta" , replace // to merge to manager 

* MERGE ALL DATA & CREATE SOCIALLY CONNECTED TRANSITION DUMMY FOR EACH MANAGER AFTER THE FIRST MANAGER
********************************************************************************

*use "$managersdta/SwitchersAllSameTeam.dta", clear 
use "$managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

* 1) look at places: is the worker new place is the old manager's previous place?  
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MConnectionsPlaces.dta"
drop if _merge ==2 
drop _merge 

* 2) look at people: is the worker new manager the old manager's manager or colleague? 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MConnectionsPeople.dta"
drop if _merge ==2 
drop _merge 

* STEP 1: Generate manager changes variables 
bys IDlse (YearMonth), sort: gen ChangeMCum = sum(ChangeM)
bys IDlse ChangeMCum: egen FirstMonth = min(cond(ChangeM==1,YearMonth,.))
xtset IDlse YearMonth 
gen f = f.ChangeM // to get at the last month 
bys IDlse ChangeMCum: egen LastMonth = min(cond(f==1,YearMonth,.))
format (FirstMonth  LastMonth) %tm

* STEP 2: for each manager change, take the manager identity, first and last month, as well as the subfunc/office/org4 in the first month of the manager change 
su  ChangeMCum // 28 managers 
forval i = 1/28{
	bys IDlse: egen Manager`i' = mean(cond(ChangeMCum == `i', IDlseMHR ,.))
	bys IDlse: egen FirstMonth`i' = mean(cond(ChangeMCum == `i', FirstMonth ,.))
	bys IDlse: egen LastMonth`i' = mean(cond(ChangeMCum == `i', LastMonth ,.))
	bys IDlse: egen SubFunc`i' = mean(cond(ChangeMCum == `i' & YearMonth== FirstMonth`i', SubFunc ,.))
	bys IDlse: egen Office`i' = mean(cond(ChangeMCum == `i' & YearMonth== FirstMonth`i', Office ,.))
	bys IDlse: egen Org4`i' = mean(cond(ChangeMCum == `i' & YearMonth== FirstMonth`i',  Org4 ,.))
	format (FirstMonth`i'  LastMonth`i') %tm
}

* STEP 3: people: manager's manager (any of the previous manager's managers) or manager's colleagues
* do first one outside of the loop because it is the first manager change 

findregex, re("^Coll")

global Coll Coll1 Coll2 Coll3 Coll4 Coll5 Coll6 Coll7 Coll8 Coll9 Coll10 Coll11 Coll12 Coll13 Coll14 Coll15 Coll16 Coll17 Coll18 Coll19 Coll20 Coll21 Coll22 Coll23 Coll24 Coll25 Coll26 Coll27 Coll28 Coll29 Coll30 Coll31 Coll32 Coll33 Coll34 Coll35 Coll36 Coll37 Coll38 Coll39 Coll40 Coll41 Coll42 Coll43 Coll44 Coll45 Coll46

bys IDlse: egen ConnectedManager1  = max(cond(  Manager1!=. & (YearMonth <FirstMonth1) &  (Manager1 ==   IDlseMHRYM | Manager1 ==  Coll1 | Manager1 ==  Coll2 | Manager1 ==  Coll3 | Manager1 ==  Coll4 | Manager1 ==  Coll5 | Manager1 ==  Coll6 | Manager1 ==  Coll7 | Manager1 ==  Coll8 | Manager1 ==  Coll9 | Manager1 ==  Coll10 | Manager1 ==  Coll11 | Manager1 ==  Coll12 | Manager1 ==  Coll13 | Manager1 ==  Coll14 | Manager1 ==  Coll15 | Manager1 ==  Coll16 | Manager1 ==  Coll17 | Manager1 ==  Coll18 | Manager1 ==  Coll19 | Manager1 ==  Coll20 | Manager1 ==  Coll21 | Manager1 ==  Coll22 | Manager1 ==  Coll23 | Manager1 ==  Coll24 | Manager1 ==  Coll25 | Manager1 ==  Coll26 | Manager1 ==  Coll27 | Manager1 ==  Coll28 | Manager1 ==  Coll29 | Manager1 ==  Coll30 | Manager1 ==  Coll31 | Manager1 ==  Coll32 | Manager1 ==  Coll33 | Manager1 ==  Coll34 | Manager1 ==  Coll35 | Manager1 ==  Coll36 | Manager1 ==  Coll37 | Manager1 ==  Coll38 | Manager1 ==  Coll39 | Manager1 ==  Coll40 | Manager1 ==  Coll41 | Manager1 ==  Coll42 | Manager1 ==  Coll43 | Manager1 ==  Coll44 | Manager1 ==  Coll45 | Manager1 ==  Coll46) ,1,0)) 

forval i = 2/28{ 
	local j = `i' - 1 
bys IDlse: egen ConnectedManager`i'  = max(cond(  Manager`i'!=. & (YearMonth <FirstMonth`i') & (YearMonth >= FirstMonth`j') & (Manager`i' ==   IDlseMHRYM | Manager`i' ==  Coll1 | Manager`i' ==  Coll2 | Manager`i' ==  Coll3 | Manager`i' ==  Coll4 | Manager`i' ==  Coll5 | Manager`i' ==  Coll6 | Manager`i' ==  Coll7 | Manager`i' ==  Coll8 | Manager`i' ==  Coll9 | Manager`i' ==  Coll10 | Manager`i' ==  Coll11 | Manager`i' ==  Coll12 | Manager`i' ==  Coll13 | Manager`i' ==  Coll14 | Manager`i' ==  Coll15 | Manager`i' ==  Coll16 | Manager`i' ==  Coll17 | Manager`i' ==  Coll18 | Manager`i' ==  Coll19 | Manager`i' ==  Coll20 | Manager`i' ==  Coll21 | Manager`i' ==  Coll22 | Manager`i' ==  Coll23 | Manager`i' ==  Coll24 | Manager`i' ==  Coll25 | Manager`i' ==  Coll26 | Manager`i' ==  Coll27 | Manager`i' ==  Coll28 | Manager`i' ==  Coll29 | Manager`i' ==  Coll30 | Manager`i' ==  Coll31 | Manager`i' ==  Coll32 | Manager`i' ==  Coll33 | Manager`i' ==  Coll34 | Manager`i' ==  Coll35 | Manager`i' ==  Coll36 | Manager`i' ==  Coll37 | Manager`i' ==  Coll38 | Manager`i' ==  Coll39 | Manager`i' ==  Coll40 | Manager`i' ==  Coll41 | Manager`i' ==  Coll42 | Manager`i' ==  Coll43 | Manager`i' ==  Coll44 | Manager`i' ==  Coll45 | Manager`i' ==  Coll46) ,1,0)) 
}
 
* STEP 4: places: SubFunc Office Org4 
foreach v in SubFunc Office Org4 {
	bys IDlse ChangeMCum: egen `v'TempBeforeFirst = mean(cond(YearMonth == FirstMonth, `v', .)) // what employee was doing first
	bys IDlse ChangeMCum: egen `v'TempBeforeLast = mean(cond(YearMonth ==LastMonth, `v', .)) // what employee does at the last month of switch 
	label value (`v'TempBeforeFirst `v'TempBeforeLast) `v' 
	bys IDlse: egen Connected`v'1 = max(cond( (`v'1 ==   `v'YM  & (YearMonth <FirstMonth1)  & `v'1 != `v'TempBeforeLast &  `v'1 != `v'TempBeforeFirst & `v'1 !=. ) ,1,0)) 
	
	forval i = 2/28{
			local j = `i' - 1 
bys IDlse: egen Connected`v'`i' = max(cond( (`v'`i' ==   `v'YM  & (YearMonth <FirstMonth`i') & (YearMonth  >= FirstMonth`j') &  `v'`i' != `v'TempBeforeLast &  `v'`i'  != `v'TempBeforeFirst &  `v'`i'   !=. ) ,1,0)) 
	}
}

* FINAL STEP: overall variables
* Is the current manager a colleague or manager of employee's previous manager? 
foreach var in Manager SubFunc Org4 Office{
	gen Connected`var' = Connected`var'1 if ChangeMCum ==1 
	forval i=2/28{
	replace Connected`var' = Connected`var'`i' if ChangeMCum ==`i'	
}
replace  Connected`var' = 0 if ChangeMCum ==0 // or leave as missing given that, by definition, one cannot move within manager's network unless he had a manager first 
}

* overall connected dummy - SOCIALLY CONNECTED MANAGER TRANSITION >>>>>>>
egen Connected = rowmax(ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4)
ta  Connected if ChangeM==1 // 18% 
ta  ConnectedManager if ChangeM==1 // 14% people, rest is places 

* Distinguish between lateral and vertical moves 
foreach v in Connected ConnectedManager ConnectedOffice ConnectedOrg4 ConnectedSubFunc{ 
	gen `v'ChangeM = `v' if ChangeM==1 // to make it easier for below, make indicator for the transition month only

	* connected lateral transfer
	gen `v'LChangeM = `v'ChangeM
	replace  `v'LChangeM = 0 if ChangeSalaryGrade ==1 & ChangeM==1

	* connected promotion
	gen `v'VChangeM= `v'ChangeM
	replace  `v'VChangeM = 0 if ChangeSalaryGrade ==0 & ChangeM==1

	bys IDlse ChangeMCum: egen `v'L = max(`v'LChangeM)
	bys IDlse ChangeMCum: egen `v'V = max(`v'VChangeM)
	bys IDlse (YearMonth), sort: gen `v'C = sum(`v'ChangeM)
	bys IDlse (YearMonth), sort: gen `v'LC = sum(`v'LChangeM)
	bys IDlse (YearMonth), sort: gen `v'VC = sum(`v'VChangeM)
} 

preserve 
* FINAL DATASET
keep IDlse YearMonth Connected ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4 ///
ConnectedC ConnectedManagerC ConnectedSubFuncC ConnectedOfficeC ConnectedOrg4C ///
ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
ConnectedLC ConnectedManagerLC ConnectedSubFuncLC ConnectedOfficeLC ConnectedOrg4LC ///
ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ConnectedVC ConnectedManagerVC ConnectedSubFuncVC ConnectedOfficeVC ConnectedOrg4VC 

label var Connected "Socially Connected M trans."
label var ConnectedManager "M trans. to colleague" 
label var ConnectedSubFunc "M trans. to sub-func" 
label var ConnectedOffice "M trans. to office" 
label var ConnectedOrg4 "M trans. to org4"

compress 
save "$managersdta/Temp/MTransferConnectedAll.dta" , replace 

* command to merge to master data 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/MTransferConnectedAll.dta", keepusing(Connected ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4 ///
ConnectedC ConnectedManagerC ConnectedSubFuncC ConnectedOfficeC ConnectedOrg4C ///
ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
ConnectedLC ConnectedManagerLC ConnectedSubFuncLC ConnectedOfficeLC ConnectedOrg4LC ///
ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ConnectedVC ConnectedManagerVC ConnectedSubFuncVC ConnectedOfficeVC ConnectedOrg4VC )


