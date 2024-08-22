****** Cleaning *********
* Virginia Minni
* December 2019
* This datasets adds manager variables 
********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

* windows
global dropbox "C:/Users/minni/Dropbox/ManagerTalent/Data/FullSample/RawData"
global analysis "C:/Users/minni/Dropbox/ManagerTalent/Data/FullSample/Analysis"
*mac
global dropbox "/Users/virginiaminni/Dropbox/ManagerTalent/Data/FullSample/RawData"
global analysis "/Users/virginiaminni/Dropbox/ManagerTalent/Data/FullSample/Analysis"
cd "$dropbox"

set scheme s1color

* set Matsize
set matsize 11000
set maxvar 32767

********************************************************************************
* 1. Cleaning and variables
********************************************************************************

* Employees 2011-2018

local data HRSnapshotWC HRUniVoice
foreach var in `data'{
use "$dropbox/dta/`var'.dta", clear

* Generate Manager dummy=1 if employee also appears as a manager in the same monthly snapshot
keep time manager_num
sort time manager_num
egen manager_num_time = group(manager_num time)

quietly bys manager_num_time:  gen dup = cond(_N==1,0,_n)
replace dup=. if manager_num_time==.
keep  if  (dup==0 | dup==1)
keep time manager_num
save "$analysis/Temp/MList.dta",replace // manager list

use "$dropbox/dta/`var'.dta", clear
keep id_lse time employee_num homecountry working_country_s working_cluster market_type function gender worklevel ageband tenure emp_type
sort time id_lse employee_num
egen employee_num_time = group(employee_num time)
quietly bys employee_num_time:  gen dup = cond(_N==1,0,_n)
replace dup=. if employee_num_time==.
keep  if  (dup==0 | dup==1)

keep time id_lse employee_num homecountry working_country_s working_cluster market_type function gender worklevel ageband tenure emp_type
rename employee_num manager_num
rename homecountry homecountry_manager
rename gender gender_manager
rename ageband ageband_manager
rename tenure tenure_manager
rename id_lse id_lse_manager
rename function function_manager
rename worklevel worklevel_manager
rename working_country_s working_country_manager_s
rename working_cluster working_cluster_manager
rename market_type market_type_manager
rename emp_type emp_type_manager
merge 1:1 time manager_num using "$analysis/Temp/MList.dta" // finding managers among employees

gen employee_is_manager = 0
replace employee_is_manager=1 if _merge==3
keep if _merge!=2
drop _merge

save "$analysis/Temp/MListCountry.dta" , replace // homecountry_manager, gender_manager

use "$analysis/Temp/MListCountry.dta" , clear
drop homecountry_manager working_cluster_manager working_country_manager_s market_type_manager function_manager gender_manager id_lse_manager worklevel_manager ageband_manager tenure_manager emp_type_manager
rename manager_num employee_num 
merge 1:m time employee_num using "$dropbox/dta/`var'.dta"
* NOTE: warning message, labels already defined. in this case, the labeling is the 
* same as it is the same dataset, so no need to take action. Labels are correct. 

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                         7,236,448  (_merge==3)
    -----------------------------------------

*/
drop _merge
order id_lse time, first

label var employee_is_manager "=1 if employee also appears as a manager in the same monthly snapshot"

merge m:1 time manager_num using "$analysis/Temp/MListCountry.dta", keepusing(id_lse_manager homecountry_manager working_cluster_manager working_country_manager_s market_type_manager function_manager gender_manager worklevel_manager ageband_manager tenure_manager emp_type_manager)
drop if _merge ==2
drop _merge
order employee_num manager_num id_lse_manager employee_is_manager ///
homecountry_manager working_country_manager_s working_cluster_manager market_type_manager function_manager ///
 gender_manager worklevel_manager ageband_manager tenure_manager emp_type_manager, a(tenure)

* Span of control
bys time manager_num: gen span_control = _N // number of direct reports
replace span_control =. if manager_num==.
order span_control, a(manager_num)

/* Expats 
decode homecountry, gen(homecountry_s)
gen manager_expat = 0
replace manager_expat = 1 if  (working_country_s != homecountry_s & employee_is_manager==1)
order manager_expat, a(employee_is_manager)
label var manager_expat "=1 The manager is an expat"
*/
* Additional var useful for the analysis

egen working_country_time = group(working_country time)
egen manager_num_time = group(manager_num time)
bysort time working_country: egen size_country = count(id_lse) // no. of employees by country and month
label var size_country "No. of employees in each country and month"

distinct work_location_code // number of establishments: 2487
distinct working_country // number of countries: 114
quietly bys work_location_code:  gen dup_location = cond(_N==1,0,_n)
destring work_location_code, replace force // unknown work location
bys working_country time: egen no_offices = count(work_location_code) if ( dup_location ==0 & work_location_code !=. | dup_location ==1 & work_location_code !=. ) 
label var no_offices "No. of offices in each country and month"

decode homecountry_manager, gen(homecountry_manager_s)
compress
save "$dropbox/dta/`var'M.dta",replace
}

********************************************************************************
* Add the perf score of manager to ALL datasets 
********************************************************************************

use "$dropbox/dta/HRSnapshotWCM.dta", clear
keep time manager_num
sort time manager_num
egen manager_num_time = group(manager_num time)

quietly bys manager_num_time:  gen dup = cond(_N==1,0,_n)
replace dup=. if manager_num_time==.
keep  if  (dup==0 | dup==1)
keep time manager_num
save "$analysis/Temp/MListPR.dta",replace // manager list


use "$dropbox/dta/HRSnapshotWCM.dta", clear
keep id_lse time employee_num perf_score
sort time id_lse employee_num
egen employee_num_time = group(employee_num time)
quietly bys employee_num_time:  gen dup = cond(_N==1,0,_n)
replace dup=. if employee_num_time==.
keep  if  (dup==0 | dup==1)
rename employee_num manager_num
rename perf_score perf_score_manager
rename id_lse id_lse_manager

merge 1:1 time manager_num using "$analysis/Temp/MListPR.dta" // finding managers among employees


save "$analysis/Temp/MListPR2.dta" , replace // homecountry_manager, gender_manager


use "$dropbox/dta/HRSnapshotWCM.dta", clear
merge m:1 time manager_num using "$analysis/Temp/MListPR2.dta" , keepusing( perf_score_manager)
drop if _merge ==2
drop _merge
order employee_num manager_num id_lse_manager employee_is_manager homecountry_manager working_country_manager_s working_cluster_manager  market_type_manager function_manager gender_manager perf_score_manager worklevel_manager ageband_manager tenure_manager, a(tenure)
save "$dropbox/dta/HRSnapshotWCM.dta", replace


*Extend to all datasets 


use "$dropbox/dta/HRUniVoiceM.dta", clear
merge m:1 time manager_num using "$analysis/Temp/MListPR.dta", keepusing( perf_score_manager)
drop if _merge ==2
drop _merge
order employee_num manager_num id_lse_manager employee_is_manager homecountry_manager gender_manager perf_score_manager worklevel_manager ageband_manager tenure_manager, a(tenure)
save "$dropbox/dta/HRUniVoiceM.dta", replace



* ISO_CODE merging Employees_cleaned_ALL

use "$dropbox/dta/HRSnapshotWCM.dta", clear
keep working_country_s iso_country_code
quietly bys working_country_s:  gen dup = cond(_N==1,0,_n)
keep  if  (dup==0 | dup==1)
rename working_country_s homecountry_s
rename iso_country_code isocode_homecountry
drop dup
save "$analysis/Temp/isocode.dta", replace 

use "$analysis/Temp/isocode.dta", clear
rename homecountry_s homecountry_manager_s
rename isocode_homecountry isocode_homecountryM
save "$analysis/Temp/isocodeM.dta", replace 

use "$dropbox/dta/HRSnapshotWCM.dta", clear
decode homecountry, gen(homecountry_s)
replace homecountry_s= "Palestine"  if homecountry_s== "Palestinian Territory Occupied"
replace homecountry_manager_s= "Palestine"  if homecountry_manager_s== "Palestinian Territory Occupied"
merge m:1 homecountry_s using "Datasets/Cleaning/isocode.dta"
drop if _merge==2
drop _merge
order isocode_homecountry ,a(homecountry)
save "$dropbox/dta/HRSnapshotWCM.dta", replace 

use "$dropbox/dta/HRSnapshotWCM.dta", clear
merge m:1 homecountry_manager_s using "$analysis/Temp/isocodeM.dta"
drop if _merge==2
drop _merge
order isocode_homecountryM ,a(homecountry_manager)
compress
save "$dropbox/dta/HRSnapshotWCM.dta", replace 



*************** Univoice ISOCODE merging ***************************************

use "$dropbox/dta/HRUniVoiceM.dta", clear
keep working_country_s iso_country_code
quietly bys working_country_s:  gen dup = cond(_N==1,0,_n)
keep  if  (dup==0 | dup==1)
rename working_country_s homecountry_s
rename iso_country_code isocode_homecountry
drop dup
save "$analysis/Temp/isocode.dta", replace 

use "$analysis/Temp/isocode.dta", clear
rename homecountry_s homecountry_manager_s
rename isocode_homecountry isocode_homecountryM
save "$analysis/Temp/isocodeM.dta", replace 

use "$dropbox/dta/HRUniVoiceM.dta", clear
decode homecountry, gen(homecountry_s)
replace homecountry_s= "Palestine"  if homecountry_s== "Palestinian Territory Occupied"
replace homecountry_manager_s= "Palestine"  if homecountry_manager_s== "Palestinian Territory Occupied"
merge m:1 homecountry_s using "$analysis/Temp/isocode.dta"
drop if _merge==2
drop _merge
order isocode_homecountry ,a(homecountry)
save "$dropbox/dta/HRUniVoiceM.dta", replace 

use "$dropbox/dta/HRUniVoiceM.dta", clear
merge m:1 homecountry_manager_s using "$analysis/Temp/isocodeM.dta"
drop if _merge==2
drop _merge
order isocode_homecountryM ,a(homecountry_manager)
compress
save "$dropbox/dta/HRUniVoiceM.dta", replace 
