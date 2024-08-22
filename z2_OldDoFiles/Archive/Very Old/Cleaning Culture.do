****** Cultural Distance Preparation *********
* Virginia Minni
* December 2019
*
* This do file prepares the data for the cultural distance analysis
********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

* windows
global dropbox "C:/Users/minni/Dropbox/ManagerTalent/Data/FullSample/RawData"
global analysis "C:/Users/minni/Dropbox/ManagerTalent/Data/FullSample/Analysis"
global dropboxC "C:/Users/minni/Dropbox/ManagerTalent/Data/FullSample/RawData/dta/CountryLevel/dta/Similarity"
*mac
global dropbox "/Users/virginiaminni/Dropbox/ManagerTalent/Data/FullSample/RawData"
global analysis "/Users/virginiaminni/Dropbox/ManagerTalent/Data/FullSample/Analysis"
global dropboxC "/Users/virginiaminni/Dropbox/ManagerTalent/Data/FullSample/RawData/dta/CountryLevel/dta/Similarity"
cd "$dropbox"

set scheme s1color

* set Matsize
set matsize 11000
set maxvar 32767

********************************************************************************
* Data: Employees_cleaned_ALL_final
********************************************************************************

use "$dropbox/dta/HRSnapshotWCM.dta", clear
xtset id_lse time // set panel data
 
********************************************************************************
* Merging
********************************************************************************
 
drop employee_num span_control master_type leave_type fte_actual ///
 revgenfunct scope_function scope_support iso_country_code country_grp_desc ///
region_desc uflp_from_date uflp_to_date uflp_status working_country_time ///
manager_num_time dup_location

* Working_cluster - relabeling

/*
Europe (including Central and Eastern Europe)
North Asia (Greater China and North East Asia)
South East Asia and Australasia
South Asia
Middle East (North Africa, Middle East, Turkey and Russia, Ukraine, Belarus )
Africa (Central Africa and South Africa)
North America
Latin America
*/

label drop working_cluster
label define working_cluster 1 "Africa" 2 "Europe" 3 "Latin America" 4 "Middle East & East Europe" ///
 5 "North America" 6 "North Asia" 7 "South East Asia" 8 "South Asia" 9 "Unknown"
label val  working_cluster working_cluster

*MERGES WITH CULTURAL DISTANCE

gen homecountry_sl=lower(homecountry_s)
gen homecountry_manager_sl=lower(homecountry_manager_s)
replace homecountry_sl = "macedonia" if homecountry_sl == "macedonia, fmr yugoslav"
replace homecountry_manager_sl = "macedonia" if homecountry_manager_sl == "macedonia, fmr yugoslav"
replace homecountry_sl = "palestine" if homecountry_sl == "palestinian territory occupied"
replace homecountry_manager_sl = "palestine" if homecountry_manager_sl == "palestinian territory occupied"

merge m:1 homecountry_sl homecountry_manager_sl using "$dropboxC/WVSDistance.dta" // WVS data
drop if _merge ==2
drop _merge
rename cultural_distance CulturalDistance

/*
egen  CulturalDistancestd = std(CulturalDistance)
order CulturalDistancestd, a(CulturalDistance)
sort id_lse time 
by id_lse: gen DeltaCD= d.CulturalDistancestd
order DeltaCD, a(CulturalDistance)
*/

merge m:1 homecountry_s homecountry_manager_s using "$dropboxC/GeneDistance.dta" // newgendist
drop if _merge ==2
drop _merge
rename new_gendist_weighted GeneticDistance
replace GeneticDistance = 0 if homecountry_s== homecountry_manager_s

merge m:1 homecountry_s homecountry_manager_s using "$dropboxC/CultDistance.dta" // cultdist
drop if _merge ==2
drop _merge
rename reldist_weighted_formula ReligionDistance
replace ReligionDistance = 0 if homecountry_s== homecountry_manager_s
rename lingdist_weighted_formula   LinguisticDistance 
replace LinguisticDistance = 0 if homecountry_s== homecountry_manager_s
rename cognate_weighted LinguisticDistance2 

merge m:1 isocode_homecountry using "$dropboxC/kinship.dta" // Enke data
drop if _merge ==2
drop _merge

order kinship_score_homecountry isocode_homecountry, a(homecountry)

merge m:1 isocode_homecountryM using "$dropboxC/kinshipM.dta" // Enke data
drop if _merge ==2
drop _merge
order kinship_score_homecountryM isocode_homecountryM, a(homecountry)


********************************************************************************
* Generating CONTROL vars
********************************************************************************

* Kinship score differences 
gen kinshipDistance = abs(kinship_score_homecountry - kinship_score_homecountryM) // Euclidean distance

* Diff nationality
gen outgroup = 0
replace outgroup = 1 if homecountry != homecountry_manager
replace outgroup = . if (homecountry == . | homecountry_manager==.)
label var outgroup "=1 if employee has different homecountry of manager"

* Same gender
gen sameGender = 0
replace sameGender = 1 if gender == gender_manager
replace sameGender = . if (gender== . | gender_manager == .)
label var sameGender "=1 if employee has same gender of manager"

*Same age
gen sameAge=0
replace sameAge = 1 if ageband == ageband_manager 
replace sameAge= . if ( ageband ==. | ageband_manager ==.)
label var sameAge "=1 if employee has same ageband of manager"

* Team divesity/ethnic fractionalization
bysort manager_num time: gen teamsize = _N
order teamsize, a(manager_num)

bysort manager_num time homecountry: gen teamEthNo = _N
bysort manager_num time homecountry: gen firstEthNo = 1 if  _n == 1
bysort manager_num time: gen teamEthsq = (teamEthNo/teamsize)^2 if firstEthNo==1
bysort manager_num time: egen HHI = sum(teamEthsq)
bysort manager_num time: gen teamEthFrac = (1 - HHI)
order teamEthNo firstEthNo teamEthsq HHI teamEthFrac, a(teamsize)
label var teamsize "Size of the team"
label var HHI "Herfindall index with homecountry of team members"
label var teamEthFrac "Frac Index: equals 0 when all members have same homecountry - 1 is max diversity"

* Average cultural distance & performance in the team
bysort manager_num time: egen teamCDistanceT = total(CulturalDistance)
bysort manager_num time: egen teamPerfScoreT = total(perf_score)
bysort manager_num time: egen teamSizeT = count(id_lse) 
gen teamSize  = teamSizeT  -1
gen teamPerfScore = (teamPerfScore - perf_score)/teamSize
gen teamCDistance = (teamCDistanceT - CulturalDistance)/teamSize
label var teamSize "Team Size minus employee"
label var  teamPerfScore  "Team average perf score minus employee"
label var  teamCDistance  "Team average cultural distance minus employee"

* Number of months spent with same manager 
by id_lse homecountry_manager_s, sort: gen monthsCulture = _n if homecountry_manager!=.
by id_lse manager_num, sort: gen jointTenure = _n if manager_num!=.

order CulturalDistance kinshipDistance outgroup sameGender jointTenure monthsCulture teamsize teamEthNo firstEthNo teamEthsq HHI teamEthFrac, b(manager_num)


********************************************************************************
* Saving Analysis data
********************************************************************************
compress // to save disk space 
save "$dropbox/dta/HRSnapshotWCM.dta", replace

********************************************************************************

********************************************************************************
* Data: Univoice
********************************************************************************

use "$dropbox/dta/HRUnivoiceM.dta", clear

xtset id_lse time // set panel data
 
********************************************************************************
* Merging
********************************************************************************
 
drop working_cluster employee_num span_control master_type leave_type fte_actual ///
revgenfunct scope_function scope_support iso_country_code country_grp_desc ///
mco_desc region_desc uflp_from_date uflp_to_date uflp_status working_country_time ///
manager_num_time size_country  dup_location no_offices


*MERGES WITH CULTURAL DISTANCE

gen homecountry_sl=lower(homecountry_s)
gen homecountry_manager_sl=lower(homecountry_manager_s)
replace homecountry_sl = "macedonia" if homecountry_sl == "macedonia, fmr yugoslav"
replace homecountry_manager_sl = "macedonia" if homecountry_manager_sl == "macedonia, fmr yugoslav"
replace homecountry_sl = "palestine" if homecountry_sl == "palestinian territory occupied"
replace homecountry_manager_sl = "palestine" if homecountry_manager_sl == "palestinian territory occupied"

merge m:1 homecountry_sl homecountry_manager_sl using "$dropboxC/WVSDistance.dta" // WVS data
drop if _merge ==2
drop _merge

egen  CulturalDistance = std(cultural_distance)

merge m:1 homecountry_s homecountry_manager_s using "$dropboxC/GeneDistance.dta" // newgendist
drop if _merge ==2
drop _merge
rename new_gendist_weighted GeneticDistance

merge m:1 homecountry_s homecountry_manager_s using "$dropboxC/CultDistance.dta" // cultdist
drop if _merge ==2
drop _merge
rename reldist_weighted_formula ReligionDistance
rename lingdist_weighted_formula   LinguisticDistance 
rename cognate_weighted LinguisticDistance2 

merge m:1 isocode_homecountry using "$dropboxC/kinship.dta" // Enke data
drop if _merge ==2
drop _merge

order kinship_score_homecountry isocode_homecountry, a(homecountry)

merge m:1 isocode_homecountryM using "$dropboxC/kinshipM.dta" // Enke data
drop if _merge ==2
drop _merge

order kinship_score_homecountryM isocode_homecountryM, a(homecountry)

********************************************************************************
* Generating CONTROL vars
********************************************************************************

* Cultural distance - GROUPS
egen cultural_distanceCUT = cut(CulturalDistance) , at(0,0.01,0.1,0.3,  .6487377 )  icodes


* Kinship score differences 
gen kinshipDistance = abs(kinship_score_homecountry - kinship_score_homecountryM) // Euclidean distance

* Diff nationality
gen outgroup = 0
replace outgroup = 1 if homecountry != homecountry_manager
replace outgroup = . if (homecountry == . | homecountry_manager==.)
label var outgroup "=1 if employee has different homecountry of manager"

* Same gender
gen sameGender = 0
replace sameGender = 1 if gender == gender_manager
replace sameGender = . if (gender== . | gender_manager == .)
label var sameGender "=1 if employee has same gender of manager"

*Same age
gen sameAge=0
replace sameAge = 1 if ageband == ageband_manager 
replace sameAge= . if ( ageband ==. | ageband_manager ==.)
label var sameAge "=1 if employee has same ageband of manager"

* Team divesity/ethnic fractionalization
bysort manager_num time: gen teamsize = _N
order teamsize, a(manager_num)

bysort manager_num time homecountry: gen teamEthNo = _N
bysort manager_num time homecountry: gen firstEthNo = 1 if  _n == 1
bysort manager_num time: gen teamEthsq = (teamEthNo/teamsize)^2 if firstEthNo==1
bysort manager_num time: egen HHI = sum(teamEthsq)
bysort manager_num time: gen teamEthFrac = (1 - HHI)
order teamEthNo firstEthNo teamEthsq HHI teamEthFrac, a(teamsize)
label var teamsize "Size of the team"
label var HHI "Herfindall index with homecountry of team members"
label var teamEthFrac "Frac Index: equals 0 when all members have same homecountry - 1 is max diversity"

* Average cultural distance & performance in the team
bysort manager_num time: egen teamCDistanceT = total(CulturalDistance)
bysort manager_num time: egen teamPerfScoreT = total(perf_score)
bysort manager_num time: egen teamSizeT = count(id_lse) 
gen teamSize  = teamSizeT  -1
gen teamPerfScore = (teamPerfScore - perf_score)/teamSize
gen teamCDistance = (teamCDistanceT - CulturalDistance)/teamSize
label var teamSize "Team Size minus employee"
label var  teamPerfScore  "Team average perf score minus employee"
label var  teamCDistance  "Team average cultural distance minus employee"

* Number of months spent with same manager 
by id_lse homecountry_manager_s, sort: gen monthsCulture = _n if homecountry_manager!=.
by id_lse manager_num, sort: gen jointTenure = _n if manager_num!=.

order CulturalDistance kinshipDistance outgroup sameGender jointTenure monthsCulture teamsize teamEthNo firstEthNo teamEthsq HHI teamEthFrac, b(manager_num)
order balanced, after(time)

********************************************************************************
* Saving Analysis data
********************************************************************************
compress
save "$dropbox/dta/HRUnivoiceM.dta", replace

********************************************************************************
