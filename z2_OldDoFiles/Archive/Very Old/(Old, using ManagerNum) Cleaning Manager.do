****** Cleaning *********
* Virginia Minni
* December 2019
* Edited by Misha 28/12/2019
* This datasets adds manager variables 

********************************************************************************
*
* 0. Setting path to directory & Setting
*
********************************************************************************
  
clear all
set more off

cd "$data"
log using stuff, replace

********************************************************************************
*
* 1. Preparation (Temporary datasets)
*
********************************************************************************

********************************************************************************
* 1.1 Creating MList using AllSnapshotWC.dta
********************************************************************************

use "$data/dta/AllSnapshotWC.dta", clear

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
* 1.2 Adding characteristics to the Manager List - MListChar, MListCharMerge (for full data)
********************************************************************************

* Matching the extracted Managernum (MList with EmployeeNum (renamed to ManagerNum) in the original data
* to identify managers
* Generate Manager dummy=1 if employee also appears as a manager in the same monthly snapshot

use "$data/dta/AllSnapshotWC.dta", clear


* 2) Adding Round IA info
gen IA = 1 if EmpType >=3 & EmpType <=7
replace IA =0 if IA==.
by IDlse (YearMonth), sort: gen RoundIA1 = (Country != Country[_n-1] & _n > 1 & IA==1)
by IDlse (YearMonth), sort: gen RoundIA2 = (IA[_n] & _n==1)
gen RoundIA = RoundIA1 + RoundIA2
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIA)
drop RoundIA
rename RoundIAcum RoundIA


* 3) Selecting manager characteristics variables 

keep IDlse YearMonth Year EmployeeNum HomeCountry CountryS Cluster Market Func Female WL AgeBand Tenure EmpType RoundIA ///
TotalPay TotalBenefit TotalBonus TotalPackage ///
PR PRSnapshot VPA LeaverType

foreach var in TotalPay TotalBenefit TotalBonus TotalPackage PR PRSnapshot VPA {
bys IDlse Year: egen `var'Mean = mean(`var')
gen `var'YearLag = .
by IDlse (YearMonth), sort: replace `var'YearLag= `var'Mean[_n-1] if  Year != Year[_n-1]
bys IDlse Year: egen `var'YearLagMin = min(`var'YearLag)
bys IDlse Year: replace  `var'YearLag =  `var'YearLagMin
drop  `var'YearLagMin

}
 
sort YearMonth IDlse EmployeeNum
egen EmployeeNumYM = group(EmployeeNum YearMonth)
quietly bys EmployeeNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if EmployeeNumYM==.
keep  if  dup==0 // we want to be fully sure of who are the managers 
* in case of duplicates we cannot be sure of which EmployeeNum's characteristics are the manager's characteristics

drop dup

local variables IDlse HomeCountry CountryS Cluster Market Func Female WL AgeBand Tenure EmpType RoundIA ///
TotalPay TotalBenefit TotalBonus TotalPackage ///
PR VPA LeaverType PRSnapshot ///
TotalPayMean TotalBenefitMean TotalBonusMean TotalPackageMean PRMean PRSnapshotMean VPAMean ///
TotalPayYearLag TotalBenefitYearLag TotalBonusYearLag TotalPackageYearLag PRYearLag PRSnapshotYearLag VPAYearLag

rename EmployeeNum ManagerNum // to merge with Manager list

foreach var in `variables' {
rename `var' `var'Manager
}

merge 1:1 YearMonth ManagerNum using "$analysis/Temp/MList.dta" // finding managers among employees

* 4) Generating Manager variable that equals 1 if there is a match (Employee Number happens to be ManagerNum)

gen Manager = 0
replace Manager=1 if _merge==3
keep if _merge == 3 // dropping unmatched values
drop _merge 

save "$analysis/Temp/MListChar.dta" , replace // Manager's characteristics: HomeCountryManager, GenderManager

* 5) Creating MListCharMerge for merging

use "$analysis/Temp/MListChar.dta" , clear
keep ManagerNum YearMonth Manager

rename ManagerNum EmployeeNum 
save "$analysis/Temp/MListCharMerge.dta" , replace

********************************************************************************
*
* 2. Cleaning AllSnapshotWC -> AllSnapshotWCM
*
********************************************************************************

********************************************************************************
* 2.1 Identifying Managers in AllSnapshotWC
********************************************************************************

* Matching manager dummy from above
* with the original data (so that we have 'original data + Manager variable')

* 1) Eliminate duplicates in the snapshot data  

use "$data/dta/AllSnapshotWC.dta", clear 
sort YearMonth EmployeeNum
egen EmployeeNumYM = group(EmployeeNum YearMonth)
quietly bys EmployeeNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if EmployeeNumYM==.
keep  if  dup==0 // eliminating all duplicates of (EmployeeNum YearMonth) combination
* there is no systematic pattern of where we find these duplicates, they span across time periods,
* countries and WLs. 
drop dup

* 2) Finding the managers among the employees

merge 1:1 YearMonth EmployeeNum using "$analysis/Temp/MListCharMerge.dta"

drop if _merge == 2
drop _merge
order IDlse YearMonth, first

label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"

********************************************************************************
* 2.2 Adding manager characteristics from above to all observations in AllSnapshotWC
********************************************************************************

* In the outcome, each obs. is employee's data + employee's manager's data
* ALL VARS
global variables IDlseManager HomeCountryManager CountrySManager ClusterManager MarketManager FuncManager FemaleManager WLManager AgeBandManager TenureManager EmpTypeManager RoundIAManager ///
TotalPayManager TotalBenefitManager TotalBonusManager TotalPackageManager ///
PRManager VPAManager LeaverTypeManager PRSnapshotManager ///
TotalPayMeanManager TotalBenefitMeanManager TotalBonusMeanManager TotalPackageMeanManager PRMeanManager PRSnapshotMeanManager VPAMeanManager ///
TotalPayYearLagManager TotalBenefitYearLagManager TotalBonusYearLagManager TotalPackageYearLagManager PRYearLagManager PRSnapshotYearLagManager VPAYearLagManager

* 1) Merge 
merge m:1 YearMonth ManagerNum using "$analysis/Temp/MListChar.dta", keepusing( $variables )

/*
tempfile temp
save `temp'
keep if _merge == 1
drop _merge
save "$data/NewDatasetUnmatched.dta",replace
use `temp'
*/

drop if _merge ==2 
drop _merge

order EmployeeNum ManagerNum  Manager $variables , a(Tenure)

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
order HomeCountrySManager, a(HomeCountryManager)

compress

save "$data/dta/AllSnapshotWCM.dta",replace

********************************************************************************
* 2.3 ISOCODE merging AllSnapshotWCM
********************************************************************************

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
*decode HomeCountry, gen(HomeCountryS) // use old notation to match with isocode for merging
replace HomeCountryS = "Palestine"  if HomeCountryS== "Palestinian Territory Occupied"
replace HomeCountrySManager = "Palestine"  if HomeCountrySManager== "Palestinian Territory Occupied"

merge m:1 HomeCountryS using "$analysis/Temp/isocode.dta" // 3,089 obs. from the original dataset not matched;
// 2 obs. from the ISOcode dataset not matched.

drop HomeCountryS
drop if _merge==2
drop _merge
order ISOHomeCountry, a(HomeCountry)
save "$data/dta/AllSnapshotWCM.dta", replace 

* Merging for Managers
use "$data/dta/AllSnapshotWCM.dta", clear
merge m:1 HomeCountrySManager using "$analysis/Temp/isocodeM.dta"
drop if _merge==2
drop _merge HomeCountrySManager
order ISOHomeCountryManager ,a(HomeCountryManager)

compress

save "$data/dta/AllSnapshotWCM.dta", replace 

********************************************************************************
*
* 3. Cleaning UniVoiceSnapshotWC -> UniVoiceSnapshotWCM
*
********************************************************************************

********************************************************************************
* 3.1 Identifying Managers in UniVoiceSnapshotWC
********************************************************************************

* 1) Eliminate duplicates in the UniVoiceSnapshotWC

use "$data/dta/UniVoiceSnapshotWC.dta", clear

sort YearMonth EmployeeNum
egen EmployeeNumYM = group(EmployeeNum YearMonth)
quietly bys EmployeeNumYM:  gen dup = cond(_N==1,0,_n)
replace dup=. if EmployeeNumYM==.
keep  if  dup==0 // eliminating all duplicates of (EmployeeNum YearMonth) combination
* there is no systematic pattern of where we find these duplicates, they span across time periods,
* countries and WLs. 
drop dup

* 2) Finding the managers among the employees 
merge 1:1 YearMonth EmployeeNum using "$analysis/Temp/MListCharMerge.dta"

* Checking if the manager is identified:

* NOTE: warning message, labels already defined. in this case, the labeling is the 
* same as it is the same dataset, so no need to take action. Labels are correct. 

/* 
(This seems to be the because we drop different groups of variables when we drop dups.)

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

********************************************************************************
* 3.2 Adding manager characteristics from above to all observations in UniVoiceSnapshotWC
********************************************************************************

* In the outcome, each obs. is employee's data + employee's manager's data

* ALL VARS
global variables IDlseManager HomeCountryManager CountrySManager ClusterManager ///
MarketManager FuncManager FemaleManager WLManager AgeBandManager ///
TenureManager EmpTypeManager RoundIAManager

* 1) Merge 
merge m:1 YearMonth ManagerNum using "$analysis/Temp/MListChar.dta", keepusing( $variables )


/* 

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

order EmployeeNum ManagerNum  Manager $variables , a(Tenure)

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
save "$data/dta/UniVoiceSnapshotWCM.dta",replace

use "$data/dta/UniVoiceSnapshotWCM.dta",replace
* Adding other variables from Snapshot to Univoice data
merge 1:1 IDlse YearMonth using "$data/dta/AllSnapshotWCM.dta", keepusing(TotalPay TotalBenefit TotalBonus TotalPackage VPA PRSnapshot PR)
drop if _merge ==2
drop _merge

compress
save "$data/dta/UniVoiceSnapshotWCM.dta",replace
********************************************************************************
* 3.3 ISOCODE merging UniVoiceSnapshotWCM
********************************************************************************

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
*decode HomeCountry, gen(HomeCountryS) // use old notation to match with isocode for merging
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
drop _merge HomeCountrySManager
order ISOHomeCountryManager ,a(HomeCountryManager)

compress
save "$data/dta/UniVoiceSnapshotWCM.dta", replace
log close _all
