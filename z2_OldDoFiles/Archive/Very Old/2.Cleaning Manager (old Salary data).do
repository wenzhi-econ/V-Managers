****** Cleaning *********
* Virginia Minni
* December 2019
* Edited by Misha 28/12/2019
* This datasets adds manager variables 

********************************************************************************
  * 0. Setting path to directory
********************************************************************************
  
clear all
set more off

cd "$data"

********************************************************************************
* 1. Creating Manager List using full data - MList
********************************************************************************

use "$data/dta/PRSnapshotWC.dta", clear

* Extracting a list of managers and saving in /Temp
* Each observation is a YearMonth ManagerNum

keep YearMonth ManagerNum
sort YearMonth ManagerNum
egen ManagerNumYM = group(ManagerNum YearMonth)

quietly bys ManagerNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if ManagerNumYM==.
keep  if  (dup==0 | dup==1)
keep YearMonth ManagerNum
save "$analysis/Temp/MList.dta", replace // Manager list

********************************************************************************
* 2.1 Adding characteristics to the Manager List - MListChar (for PR & UniVoice)
********************************************************************************

* Matching the extracted Manager Numbers with the Employee Number in the original data
* to identify managers (renamed to ManagerNum)
* Generate Manager dummy=1 if employee also appears as a manager in the same monthly snapshot

use "$data/dta/PRSnapshotWC.dta", clear

* 1) Adding Round IA info
gen IA = 1 if EmpType >=3 & EmpType <=7
replace IA =0 if IA==.
by IDlse (YearMonth), sort: gen RoundIA1 = (Country != Country[_n-1] & _n > 1 & IA==1)
by IDlse (YearMonth), sort: gen RoundIA2 = (IA[_n] & _n==1)
gen RoundIA = RoundIA1 + RoundIA2
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIA)
drop RoundIA
rename RoundIAcum RoundIA
* 2) Spotting issue: Homecountry variable changes over time 
by IDlse (YearMonth), sort: gen changeHC = (HomeCountry != HomeCountry[_n-1] & _n > 1)
* >> Fixing the homecountry variable
rename HomeCountry HomeCountryOriginal
decode HomeCountryOriginal, gen(HomeCountryOriginalS)
by IDlse (YearMonth), sort: gen HomeCountryS = HomeCountryOriginalS[1]
encode HomeCountryS , label(HomeCountry) gen(HomeCountry)
order HomeCountry, b(HomeCountryOriginal)

* 3) Selecting manager characteristics variables 
keep IDlse YearMonth EmployeeNum HomeCountry CountryS Cluster Market Func Gender WL AgeBand Tenure EmpType RoundIA
sort YearMonth IDlse EmployeeNum
egen EmployeeNumYM = group(EmployeeNum YearMonth)
quietly bys EmployeeNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if EmployeeNumYM==.
keep  if  dup==0 // we want to be fully sure of who are the managers 
* in case of duplicates we cannot be sure of which EmployeeNum's characteristics are the manager's characteristics 

keep YearMonth IDlse EmployeeNum HomeCountry CountryS Cluster Market Func Gender WL AgeBand Tenure EmpType RoundIA
rename EmployeeNum ManagerNum // to merge with Manager list 
rename HomeCountry HomeCountryManager
rename Gender GenderManager
rename AgeBand AgeBandManager
rename Tenure TenureManager
rename IDlse IDlseManager
rename Func FuncManager
rename WL WLManager
rename CountryS CountrySManager
rename Cluster ClusterManager
rename Market MarketManager
rename EmpType EmpTypeManager
rename RoundIA RoundIAManager

merge 1:1 YearMonth ManagerNum using "$analysis/Temp/MList.dta" // finding managers among employees

* 4) Generating Manager variable that equals 1 if there is a match (Employee Number happens to be ManagerNum)

gen Manager = 0
replace Manager=1 if _merge==3
keep if _merge!=2 // these are ManagerNum that remain unmatched among the EmployeeNum
drop _merge 

save "$analysis/Temp/MListChar.dta" , replace // Manager's characteristics: HomeCountryManager, GenderManager

********************************************************************************
* 2.2 Final datasets - PRSnapshotWCM UniVoiceSnapshotWCM
********************************************************************************

local data PRSnapshotWC UniVoiceSnapshotWC

foreach var in `data'{

* Matching manager dummy from above
* with the original data (so that we have 'original data + Manager variable')
********************************************************************************


* 1) Prepare the managers' characteristics data 

use "$analysis/Temp/MListChar.dta" , clear
drop HomeCountryManager ClusterManager CountrySManager MarketManager FuncManager ///
GenderManager IDlseManager WLManager AgeBandManager TenureManager EmpTypeManager RoundIAManager

rename ManagerNum EmployeeNum 
save "$analysis/Temp/MListCharMerge.dta" , replace

* 2) Eliminate duplicates in the snapshot data  

use "$data/dta/`var'.dta", clear 
sort YearMonth EmployeeNum
egen EmployeeNumYM = group(EmployeeNum YearMonth)
quietly bys EmployeeNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if EmployeeNumYM==.
keep  if  dup==0 // eliminating all duplicates of (EmployeeNum YearMonth) combination
* there is no systematic pattern of where we find these duplicates, they span across time periods,
* countries and WLs. 
drop dup


* 3) Finding the managers among the employees 
merge 1:1 YearMonth EmployeeNum using "$analysis/Temp/MListCharMerge.dta"

* Checking if the manager is identified:

* NOTE: warning message, labels already defined. in this case, the labeling is the 
* same as it is the same dataset, so no need to take action. Labels are correct. 

/* 
For PRSnapshotWC:
	
	Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                         7,663,615  (_merge==3)
    -----------------------------------------

	


For UniVoiceSnapshotWC:

    Result                           # of obs.
    -----------------------------------------
    not matched                     6,894,268
        from master                        35  (_merge==1)
        from using                  6,894,233  (_merge==2)

    matched                           769,382  (_merge==3)
    -----------------------------------------

*/

drop if _merge == 2
drop _merge
order IDlse YearMonth, first

label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"

* Now, adding manager characteristics from above to ALL observations 
* (each obs. is employee's data + employee's manager's data)
********************************************************************************

* 1) Merge 
merge m:1 YearMonth ManagerNum using "$analysis/Temp/MListChar.dta", keepusing(IDlseManager HomeCountryManager ClusterManager ///
CountrySManager MarketManager FuncManager GenderManager WLManager AgeBandManager TenureManager EmpTypeManager RoundIAManager)


/* 
For PRSnapshotWC:

    Result                           # of obs.
    -----------------------------------------
    not matched                     6,318,144
        from master                   231,319  (_merge==1)
        from using                  6,086,825  (_merge==2)

    matched                         7,432,296  (_merge==3)
    -----------------------------------------


For UniVoiceSnapshotWC:


    Result                           # of obs.
    -----------------------------------------
    not matched                    7,364,272
        from master                 2,385  (_merge==1)
        from using                  7,361,887  (_merge==2)

    matched                           767,032  (_merge==3)
    -----------------------------------------


*/


drop if _merge ==2 
drop _merge

order EmployeeNum ManagerNum IDlseManager Manager ///
HomeCountryManager CountrySManager ClusterManager MarketManager FuncManager ///
GenderManager WLManager AgeBandManager TenureManager EmpTypeManager RoundIAManager, a(Tenure)

* 2) Creating Variables

* Span of control
bys YearMonth ManagerNum: gen SpanControl = _N // number of direct reports
replace SpanControl =. if ManagerNum==.
order SpanControl, a(ManagerNum)

/* Expats 
decode HomeCountry, gen(HomeCountryS)
gen ManagerExpat = 0
replace ManagerExpat = 1 if  (CountryS != HomeCountryS & Manager==1)
order ManagerExpat, a(Manager)
label var ManagerExpat "=1 The manager is an expat"
*/

* Country Size
bysort YearMonth Country: egen CountrySize = count(IDlse) // no. of employees by country and month
label var CountrySize "No. of employees in each country and month"

* Office
distinct Office // number of establishments 2550 (for WC); 871 (for HRUniVoice)
distinct Country // number of countries: 117 (for WC); 113 (for HRUniVoice)
quietly bys Office: gen dup_location = cond(_N==1,0,_n)
bys Country YearMonth: egen OfficeNum = count(Office) if (dup_location ==0 & Office !=. | dup_location ==1 & Office !=.) 
label var OfficeNum "No. of offices in each Country and Month"

* Additional variables useful for the analysis
egen CountryYM = group(Country YearMonth)
egen ManagerNumYM = group(ManagerNum YearMonth)
decode HomeCountryManager, gen(HomeCountrySManager)

compress
save "$data/dta/`var'M.dta",replace
}

********************************************************************************
* Adding the perf score (PR) of manager to ALL datasets 
********************************************************************************

* Extracting manager numbers 
use "$data/dta/PRSnapshotWCM.dta", clear
keep YearMonth ManagerNum
sort YearMonth ManagerNum

egen ManagerNumYM = group(ManagerNum YearMonth)
quietly bys ManagerNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if ManagerNumYM==.
keep if (dup==0 | dup==1)
keep YearMonth ManagerNum

save "$analysis/Temp/MListPR.dta",replace // manager list

* Matching the manager list to the employee numbers to identify managers

use "$data/dta/PRSnapshotWCM.dta", clear
keep IDlse YearMonth EmployeeNum PR
sort YearMonth IDlse EmployeeNum
egen EmployeeNumYM = group(EmployeeNum YearMonth)
quietly bys EmployeeNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if EmployeeNumYM==.
keep  if  dup==0 // there can be no duplicates among the employees
rename EmployeeNum ManagerNum
rename PR PRManager
rename IDlse IDlseManager

merge 1:1 YearMonth ManagerNum using "$analysis/Temp/MListPR.dta" // finding managers among employees

save "$analysis/Temp/MListPR2.dta" , replace // homecountry_manager, gender_manager

* Merging managers' PR data with the rest of the dataset (adding PRManager to the original)
use "$data/dta/PRSnapshotWCM.dta", clear
merge m:1 YearMonth ManagerNum using "$analysis/Temp/MListPR2.dta", keepusing(PRManager)
drop if _merge ==2
drop _merge
order EmployeeNum ManagerNum IDlseManager Manager HomeCountryManager ///
CountrySManager ClusterManager MarketManager FuncManager ///
GenderManager PRManager WLManager AgeBandManager TenureManager, a(Tenure)
save "$data/dta/PRSnapshotWCM.dta", replace

* Extend merging to UniVoiceSnapshotWCM dataset

use "$data/dta/UniVoiceSnapshotWCM.dta", clear
merge m:1 YearMonth ManagerNum using "$analysis/Temp/MListPR2.dta", keepusing(PRManager)
drop if _merge ==2
drop _merge
order EmployeeNum ManagerNum IDlseManager Manager HomeCountryManager ///
GenderManager PRManager WLManager AgeBandManager TenureManager, a(Tenure)
save "$data/dta/UniVoiceSnapshotWCM.dta", replace

********************************************************************************
* ISOCODE merging PRSnapshotWC & UniVoiceSnapshotWC 
********************************************************************************

********************* PRSnapshotWC ISOCODE merging *****************************

use "$data/dta/PRSnapshotWCM.dta", clear
keep CountryS ISOCountryCode
quietly bys CountryS:  gen dup = cond(_N==1,0,_n)
keep  if  (dup==0 | dup==1)
rename CountryS HomeCountryS
rename ISOCountryCode ISOHomeCountry
drop dup
save "$analysis/Temp/isocode.dta", replace 

use "$analysis/Temp/isocode.dta", clear
rename HomeCountry HomeCountrySManager
rename ISOHomeCountry ISOHomeCountryManager
save "$analysis/Temp/isocodeM.dta", replace 

* Merging for Employees
use "$data/dta/PRSnapshotWCM.dta", clear
decode HomeCountry, gen(HomeCountryS) // use old notation to match with isocode for merging
replace HomeCountryS = "Palestine"  if HomeCountryS== "Palestinian Territory Occupied"
replace HomeCountrySManager = "Palestine"  if HomeCountrySManager== "Palestinian Territory Occupied"
merge m:1 HomeCountryS using "$analysis/Temp/isocode.dta"
rename HomeCountryS HomeCountryS
drop if _merge==2
drop _merge
order ISOHomeCountry, a(HomeCountry)
save "$data/dta/PRSnapshotWCM.dta", replace 

* Merging for Managers
use "$data/dta/PRSnapshotWCM.dta", clear
merge m:1 HomeCountrySManager using "$analysis/Temp/isocodeM.dta"
drop if _merge==2
drop _merge
order ISOHomeCountryManager ,a(HomeCountryManager)
compress
save "$data/dta/PRSnapshotWCM.dta", replace 

********************* UnivoiceWCM ISOCODE merging ******************************

use "$data/dta/UniVoiceSnapshotWCM.dta", clear
keep CountryS ISOCountryCode
quietly bys CountryS:  gen dup = cond(_N==1,0,_n)
keep  if  (dup==0 | dup==1)
rename CountryS HomeCountryS
rename ISOCountryCode ISOHomeCountry
drop dup
save "$analysis/Temp/isocode.dta", replace 

use "$analysis/Temp/isocode.dta", clear
rename HomeCountryS HomeCountrySManager
rename ISOHomeCountry ISOHomeCountryManager
save "$analysis/Temp/isocodeM.dta", replace 

* Merging for Employees
use "$data/dta/UniVoiceSnapshotWCM.dta", clear
decode HomeCountry, gen(HomeCountryS) // use old notation to match with isocode for merging
replace HomeCountryS = "Palestine"  if HomeCountryS== "Palestinian Territory Occupied"
replace HomeCountrySManager = "Palestine"  if HomeCountrySManager== "Palestinian Territory Occupied"
merge m:1 HomeCountryS using "$analysis/Temp/isocode.dta"
drop HomeCountryS
drop if _merge==2
drop _merge
order ISOHomeCountry, a(HomeCountry)
save "$data/dta/UniVoiceSnapshotWCM.dta", replace

*Merging for Managers
use "$data/dta/UniVoiceSnapshotWCM.dta", clear
merge m:1 HomeCountrySManager using "$analysis/Temp/isocodeM.dta"
drop if _merge==2
drop _merge
order ISOHomeCountryManager ,a(HomeCountryManager)
compress
save "$data/dta/UniVoiceSnapshotWCM.dta", replace


********************************************************************************
*
* 3. Running the Same Code for AllSnapshotWC.dta
*
********************************************************************************

********************************************************************************
* 3.1 Adding characteristics to the Manager List - MListChar (for AllSnapshotWC)
********************************************************************************

* Matching the extracted Managernum (MList with EmployeeNum (renamed to ManagerNum) in the original data
* to identify managers
* Generate Manager dummy=1 if employee also appears as a manager in the same monthly snapshot

use "$data/dta/AllSnapshotWC.dta", clear
keep IDlse YearMonth EmployeeNum HomeCountry CountryS Cluster Market Func Female WL  ///
AgeBand Tenure EmpType PR VPA AnnualPayProRated LeaverType

sort YearMonth IDlse EmployeeNum
egen EmployeeNumYM = group(EmployeeNum YearMonth)
quietly bys EmployeeNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if EmployeeNumYM==.
keep  if  dup==0 // we want to be fully sure of who are the managers 
* in case of duplicates we cannot be sure of which EmployeeNum's characteristics are the manager's characteristics 
drop dup

local variables IDlse HomeCountry CountryS Cluster Market Func Female WL AgeBand Tenure EmpType PR LeaverType VPA AnnualPayProRated

rename EmployeeNum ManagerNum // to merge with Manager list

foreach var in `variables' {
rename `var' `var'Manager
}

merge 1:1 YearMonth ManagerNum using "$analysis/Temp/MList.dta" // finding managers among employees

* Generating Manager variable that equals 1 if there is a match (Employee Number happens to be ManagerNum)

gen Manager = 0
replace Manager=1 if _merge==3
keep if _merge!=2 // these are ManagerNum that remain unmatched among the EmployeeNum
drop _merge 

save "$analysis/Temp/MListChar.dta" , replace // Manager's characteristics: HomeCountryManager, GenderManager

********************************************************************************
* Matching manager dummy from above
* with the original data (so that we have 'original data + Manager variable')

* 1) Prepare the managers' characteristics data 

use "$analysis/Temp/MListChar.dta" , clear
drop HomeCountryManager ClusterManager CountrySManager MarketManager FuncManager ///
Female IDlseManager WLManager AgeBandManager TenureManager EmpTypeManager PRManager VPAManager LeaverTypeManager AnnualPayProRatedManager

rename ManagerNum EmployeeNum 
save "$analysis/Temp/MListCharMerge.dta" , replace

* 2) Eliminate duplicates in the snapshot data  

use "$data/dta/AllSnapshotWC.dta", clear 
sort YearMonth EmployeeNum
egen EmployeeNumYM = group(EmployeeNum YearMonth)
quietly bys EmployeeNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if EmployeeNumYM==.
keep  if  dup==0 // eliminating all duplicates of (EmployeeNum YearMonth) combination
* there is no systematic pattern of where we find these duplicates, they span across time periods,
* countries and WLs. 
drop dup


* 3) Finding the managers among the employees

merge 1:1 YearMonth EmployeeNum using "$analysis/Temp/MListCharMerge.dta"

drop if _merge == 2
drop _merge
order IDlse YearMonth, first

label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"

* Now, adding manager characteristics from above to ALL observations 
* (each obs. is employee's data + employee's manager's data)
********************************************************************************

* 1) Merge 
merge m:1 YearMonth ManagerNum using "$analysis/Temp/MListChar.dta", keepusing(HomeCountryManager ClusterManager CountrySManager MarketManager FuncManager ///
Female IDlseManager WLManager AgeBandManager TenureManager EmpTypeManager PRManager VPAManager LeaverTypeManager AnnualPayProRatedManager)


drop if _merge ==2 
drop _merge

order EmployeeNum ManagerNum IDlseManager Manager ///
HomeCountryManager CountrySManager ClusterManager MarketManager FuncManager ///
FemaleManager WLManager AgeBandManager TenureManager EmpTypeManager ///
PRManager VPAManager LeaverTypeManager AnnualPayProRatedManager, a(Tenure)

* 2) Creating Variables

* Span of control
bys YearMonth ManagerNum: gen SpanControl = _N // number of direct reports
replace SpanControl =. if ManagerNum==.
order SpanControl, a(ManagerNum)


* Country Size
bysort YearMonth Country: egen CountrySize = count(IDlse) // no. of employees by country and month
label var CountrySize "No. of employees in each country and month"

* Office
distinct Office // number of establishments 2550 (for WC); 871 (for HRUniVoice)
distinct Country // number of countries: 117 (for WC); 113 (for HRUniVoice)
quietly bys Office: gen dup_location = cond(_N==1,0,_n)
bys Country YearMonth: egen OfficeNum = count(Office) if (dup_location ==0 & Office !=. | dup_location ==1 & Office !=.) 
label var OfficeNum "No. of offices in each Country and Month"

* Additional variables useful for the analysis
egen CountryYM = group(Country YearMonth)
egen ManagerNumYM = group(ManagerNum YearMonth)
decode HomeCountryManager, gen(HomeCountrySManager)

compress
save "$data/dta/AllSnapshotWCM.dta",replace

********************************************************************************
* ISOCODE merging AllSnapshotWCM
********************************************************************************

********************* PRSnapshotWC ISOCODE merging *****************************

use "$data/dta/AllSnapshotWCM.dta", clear
keep CountryS ISOCountryCode
quietly bys CountryS:  gen dup = cond(_N==1,0,_n)
keep  if  (dup==0 | dup==1)
rename CountryS HomeCountryS
rename ISOCountryCode ISOHomeCountry
drop dup
save "$analysis/Temp/isocode.dta", replace 

use "$analysis/Temp/isocode.dta", clear
rename HomeCountry HomeCountrySManager
rename ISOHomeCountry ISOHomeCountryManager
save "$analysis/Temp/isocodeM.dta", replace 

* Merging for Employees
use "$data/dta/AllSnapshotWCM.dta", clear
decode HomeCountry, gen(HomeCountryS) // use old notation to match with isocode for merging
replace HomeCountryS = "Palestine"  if HomeCountryS== "Palestinian Territory Occupied"
replace HomeCountrySManager = "Palestine"  if HomeCountrySManager== "Palestinian Territory Occupied"

merge m:1 HomeCountryS using "$analysis/Temp/isocode.dta" // 3,089 obs. from the original dataset not matched;
// 2 obs. from the ISOcode dataset not matched.

rename HomeCountryS HomeCountryS
drop if _merge==2
drop _merge
order ISOHomeCountry, a(HomeCountry)
save "$data/dta/AllSnapshotWCM.dta", replace 

* Merging for Managers
use "$data/dta/AllSnapshotWCM.dta", clear
merge m:1 HomeCountrySManager using "$analysis/Temp/isocodeM.dta"
drop if _merge==2
drop _merge
order ISOHomeCountryManager ,a(HomeCountryManager)

compress

save "$data/dta/AllSnapshotWCM.dta", replace 
