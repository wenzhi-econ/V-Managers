****** Cultural Distance Preparation *********
* Virginia Minni
* December 2019
* Edited by Misha 27/12/2019
*
* This do file prepares the data for the cultural distance analysis
********************************************************************************
  * 0. Setting path to directory
********************************************************************************
  
clear all
set more off

cd "$data"

set scheme s1color

* set Matsize
//set matsize 11000
//set maxvar 32767

********************************************************************************
  * 1. Data: (PRSnapshotWC) Snapshot combined with PR dataset, White Collar
********************************************************************************
  
use "$data/dta/PRSnapshotWCM.dta", clear
xtset IDlse YearMonth // set panel data

********************************************************************************
  * Merging
********************************************************************************
  
drop EmployeeNum SpanControl LeaveType FTE ISOCountryCode CountryYM ///
ManagerNumYM dup_location

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
  
  label drop Cluster
label define Clusterlab 1 "Africa" 2 "Europe" 3 "Latin America" 4 "Middle East & East Europe" ///
  5 "North America" 6 "North Asia" 7 "South East Asia" 8 "South Asia" 9 "Unknown"
label val Cluster Clusterlab

*MERGES WITH CULTURAL DISTANCE

gen HomeCountrySl=lower(HomeCountryS)
gen HomeCountrySManagerl=lower(HomeCountrySManager)
replace HomeCountrySl = "macedonia" if HomeCountrySl == "macedonia, fmr yugoslav"
replace HomeCountrySManagerl = "macedonia" if HomeCountrySManagerl == "macedonia, fmr yugoslav"
replace HomeCountrySl = "palestine" if HomeCountrySl == "palestinian territory occupied"
replace HomeCountrySManagerl = "palestine" if HomeCountrySManagerl == "palestinian territory occupied"

merge m:1 HomeCountrySl HomeCountrySManagerl using "$temp/WVSDistance.dta" // WVS data
drop if _merge ==2
drop _merge

/*
  egen CulturalDistancestd = std(CulturalDistance)
order CulturalDistancestd, a(CulturalDistance)
sort IDlse YearMonth 
by IDlse: gen DeltaCD= d.CulturalDistancestd
order DeltaCD, a(CulturalDistance)
*/
  
  merge m:1 HomeCountryS HomeCountrySManager using "$temp/GeneDistance.dta" // newgendist
drop if _merge ==2
drop _merge
replace GeneticDistance  = 0 if HomeCountryS== HomeCountrySManager

merge m:1 HomeCountryS HomeCountrySManager using "$temp/CultDistance.dta" // cultdist
drop if _merge ==2
drop _merge

replace ReligionDistance = 0 if HomeCountryS== HomeCountrySManager
replace LinguisticDistance = 0 if HomeCountryS== HomeCountrySManager

merge m:1 ISOHomeCountry using "$temp/kinship.dta" // Enke data
drop if _merge ==2
drop _merge
order KinshipScoreHomeCountry ISOHomeCountry, a(HomeCountry)

compress

merge m:1 ISOHomeCountryM using "$temp/kinshipM.dta" // Enke data
drop if _merge ==2
drop _merge

order KinshipScoreHomeCountryM ISOHomeCountryM, a(HomeCountry)

********************************************************************************
  * Generating CONTROL vars
********************************************************************************
  
* Kinship score differences 
gen KinshipDistance = abs(KinshipScoreHomeCountry - KinshipScoreHomeCountryM) // Euclidean distance

* Diff nationality
gen OutGroup = 0
replace OutGroup = 1 if HomeCountry != HomeCountryManager
replace OutGroup = . if (HomeCountry == . | HomeCountryManager==.)
  label var OutGroup "=1 if employee has different homecountry of manager"

* Same gender
gen SameGender = 0
replace SameGender = 1 if Gender == GenderManager
replace SameGender = . if (Gender== . | GenderManager == .)
  label var SameGender "=1 if employee has same gender of manager"

*Same age
gen SameAge=0
replace SameAge = 1 if AgeBand == AgeBandManager 
replace SameAge= . if (AgeBand ==. | AgeBandManager ==.)
  label var SameAge "=1 if employee has same ageband of manager"

* Team divesity/ethnic fractionalization
bysort ManagerNum YearMonth: gen TeamSizeT = _N
order TeamSize, a(ManagerNum)

bysort ManagerNum YearMonth HomeCountry: gen TeamEthNo = _N
bysort ManagerNum YearMonth HomeCountry: gen FirstEthNo = 1 if  _n == 1
bysort ManagerNum YearMonth: gen TeamEthSq = (TeamEthNo/TeamSize)^2 if FirstEthNo==1
bysort ManagerNum YearMonth: egen HHI = sum(TeamEthSq)
bysort ManagerNum YearMonth: gen TeamEthFrac = (1 - HHI)
order TeamEthNo FirstEthNo TeamEthSq HHI TeamEthFrac, a(TeamSize)
label var TeamSize "Size of the team"
label var HHI "Herfindall index with homecountry of team members"
label var TeamEthFrac "Frac Index: equals 0 when all members have same homecountry - 1 is max diversity"

* Average cultural distance & performance in the team
bysort ManagerNum YearMonth: egen TeamCDistanceT = total(CulturalDistance)
bysort ManagerNum YearMonth: egen TeamPRT = total(PR)
//bysort ManagerNum YearMonth: egen TeamSizeT = count(IDlse) 
gen TeamSize  = TeamSizeT - 1
gen TeamPR = (TeamPRT - PR)/TeamSize
gen TeamCDistance = (TeamCDistanceT - CulturalDistance)/TeamSize
label var TeamSize "Team Size minus employee"
label var TeamPR  "Team average perf score minus employee"
label var TeamCDistance  "Team average cultural distance minus employee"

* Number of months spent with same manager 
by IDlse HomeCountrySManager, sort: gen MonthsCulture = _n if HomeCountryManager!=.
by IDlse ManagerNum, sort: gen JointTenure = _n if ManagerNum!=.

order CulturalDistance KinshipDistance OutGroup SameGender JointTenure MonthsCulture TeamSize TeamEthNo FirstEthNo TeamEthSq HHI TeamEthFrac, b(ManagerNum)


********************************************************************************
  * Saving Analysis data
********************************************************************************

compress // to save disk space 
save "$data/dta/PRSnapshotWCM.dta", replace


********************************************************************************
  * 2. Data: (UniVoiceSnapshotWC) UniVoice, White Collar
********************************************************************************
  
use "$data/dta/UniVoiceSnapshotWCM.dta", clear

xtset IDlse YearMonth // set panel data

*preparation

drop Cluster MCO CountrySize OfficeNum Cluster EmployeeNum SpanControl LeaveType ///
FTE ISOCountryCode CountryYM ManagerNumYM dup_location

gen HomeCountrySl=lower(HomeCountryS)
gen HomeCountrySManagerl=lower(HomeCountrySManager)
replace HomeCountrySl = "macedonia" if HomeCountrySl == "macedonia, fmr yugoslav"
replace HomeCountrySManagerl = "macedonia" if HomeCountrySManagerl == "macedonia, fmr yugoslav"
replace HomeCountrySl = "palestine" if HomeCountrySl == "palestinian territory occupied"
replace HomeCountrySManagerl = "palestine" if HomeCountrySManagerl == "palestinian territory occupied"

********************************************************************************
  * Merging
********************************************************************************

*MERGES WITH CULTURAL DISTANCE

merge m:1 HomeCountrySl HomeCountrySManagerl using "$temp/WVSDistance.dta" // WVS data
drop if _merge ==2
drop _merge

rename CulturalDistance CulturalDistance1
egen CulturalDistance = std(CulturalDistance1)
drop CulturalDistance1

merge m:1 HomeCountryS HomeCountrySManager using "$temp/GeneDistance.dta" // newgendist
drop if _merge ==2
drop _merge

merge m:1 HomeCountryS HomeCountrySManager using "$temp/CultDistance.dta" // cultdist
drop if _merge ==2
drop _merge

merge m:1 ISOHomeCountry using "$temp/kinship.dta" // Enke data
drop if _merge ==2
drop _merge

order KinshipScoreHomeCountry ISOHomeCountry, a(HomeCountry)

merge m:1 ISOHomeCountryManager using "$temp/kinshipM.dta" // Enke data
drop if _merge ==2
drop _merge

order KinshipScoreHomeCountryM ISOHomeCountryManager, a(HomeCountry)


********************************************************************************
  * Generating CONTROL vars
********************************************************************************
  
* Cultural distance - GROUPS
egen CulturalDistanceCut = cut(CulturalDistance) , at(0,0.01,0.1,0.3,  .6487377)  icodes

* Kinship score differences 
gen KinshipDistance = abs(KinshipScoreHomeCountry - KinshipScoreHomeCountryM) // Euclidean distance

* Diff nationality
gen OutGroup = 0
replace OutGroup = 1 if HomeCountry != HomeCountryManager
replace OutGroup = . if (HomeCountry == . | HomeCountryManager==.)
  label var OutGroup "=1 if employee has different homecountry of manager"

* Same gender
gen SameGender = 0
replace SameGender = 1 if Gender == GenderManager
replace SameGender = . if (Gender== . | GenderManager == .)
  label var SameGender "=1 if employee has same gender of manager"

*Same age
gen SameAge=0
replace SameAge = 1 if AgeBand == AgeBandManager 
replace SameAge= . if (AgeBand ==. | AgeBandManager ==.)
  label var SameAge "=1 if employee has same ageband of manager"

* Team divesity/ethnic fractionalization
bysort ManagerNum YearMonth: gen TeamSizeT = _N
order TeamSize, a(ManagerNum)

bysort ManagerNum YearMonth HomeCountry: gen TeamEthNo = _N
bysort ManagerNum YearMonth HomeCountry: gen FirstEthNo = 1 if  _n == 1
bysort ManagerNum YearMonth: gen TeamEthSq = (TeamEthNo/TeamSize)^2 if FirstEthNo==1
bysort ManagerNum YearMonth: egen HHI = sum(TeamEthSq)
bysort ManagerNum YearMonth: gen TeamEthFrac = (1 - HHI)
order TeamEthNo FirstEthNo TeamEthSq HHI TeamEthFrac, a(TeamSize)
label var TeamSize "Size of the team"
label var HHI "Herfindall index with homecountry of team members"
label var TeamEthFrac "Frac Index: equals 0 when all members have same homecountry - 1 is max diversity"

* Average cultural distance & performance in the team
bysort ManagerNum YearMonth: egen TeamCDistanceT = total(CulturalDistance)
bysort ManagerNum YearMonth: egen TeamPRT = total(PR)
//bysort ManagerNum YearMonth: egen TeamSizeT = count(IDlse) 
gen TeamSize  = TeamSizeT - 1
gen TeamPR = (TeamPRT - PR)/TeamSize
gen TeamCDistance = (TeamCDistanceT - CulturalDistance)/TeamSize
label var TeamSize "Team Size minus employee"
label var TeamPR  "Team average perf score minus employee"
label var TeamCDistance  "Team average cultural distance minus employee"

/*
* Number of months spent with same manager 
Merge with PRSnapshot data to get full joint tenure 
*/

* rerun
merge 1:1 IDlse YearMonth using "$data/dta/PRSnapshotWCM.dta", keepusing(JointTenure MonthsCulture) // all matched
drop if _merge == 2
drop _merge

order CulturalDistance KinshipDistance OutGroup SameGender JointTenure MonthsCulture TeamSize TeamEthNo FirstEthNo TeamEthSq HHI TeamEthFrac, b(ManagerNum)
order Balanced, after(YearMonth)

********************************************************************************
  * Saving Analysis data
********************************************************************************
compress
save "$data/dta/UniVoiceSnapshotWCM.dta", replace
********************************************************************************


********************************************************************************
  * 3. Data: AllSnapshotWCM
********************************************************************************
  
use "$data/dta/AllSnapshotWCM.dta", clear
xtset IDlse YearMonth // set panel data

********************************************************************************
  * Merging
********************************************************************************
  
drop EmployeeNum SpanControl LeaveType FTE ISOCountryCode CountryYM ///
ManagerNumYM dup_location

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
  
label drop Cluster
label define Clusterlab 1 "Africa" 2 "Europe" 3 "Latin America" 4 "Middle East & East Europe" ///
  5 "North America" 6 "North Asia" 7 "South East Asia" 8 "South Asia" 9 "Unknown"
label val Cluster Clusterlab

*MERGES WITH CULTURAL DISTANCE

gen HomeCountrySl=lower(HomeCountryS)
gen HomeCountrySManagerl=lower(HomeCountrySManager)
replace HomeCountrySl = "macedonia" if HomeCountrySl == "macedonia, fmr yugoslav"
replace HomeCountrySManagerl = "macedonia" if HomeCountrySManagerl == "macedonia, fmr yugoslav"
replace HomeCountrySl = "palestine" if HomeCountrySl == "palestinian territory occupied"
replace HomeCountrySManagerl = "palestine" if HomeCountrySManagerl == "palestinian territory occupied"

merge m:1 HomeCountrySl HomeCountrySManagerl using "$temp/WVSDistance.dta" // WVS data
drop if _merge ==2
drop _merge

/*
  egen CulturalDistancestd = std(CulturalDistance)
order CulturalDistancestd, a(CulturalDistance)
sort IDlse YearMonth 
by IDlse: gen DeltaCD= d.CulturalDistancestd
order DeltaCD, a(CulturalDistance)
*/
  
merge m:1 HomeCountryS HomeCountrySManager using "$temp/GeneDistance.dta" // newgendist
drop if _merge ==2
drop _merge
replace GeneticDistance  = 0 if HomeCountryS== HomeCountrySManager

merge m:1 HomeCountryS HomeCountrySManager using "$temp/CultDistance.dta" // cultdist
drop if _merge ==2
drop _merge

replace ReligionDistance = 0 if HomeCountryS== HomeCountrySManager
replace LinguisticDistance = 0 if HomeCountryS== HomeCountrySManager

merge m:1 ISOHomeCountry using "$temp/kinship.dta" // Enke data
drop if _merge ==2
drop _merge
order KinshipScoreHomeCountry ISOHomeCountry, a(HomeCountry)

compress

merge m:1 ISOHomeCountryM using "$temp/kinshipM.dta" // Enke data
drop if _merge ==2
drop _merge

order KinshipScoreHomeCountryM ISOHomeCountryM, a(HomeCountry)

********************************************************************************
  * Generating CONTROL vars
********************************************************************************
  
* Kinship score differences 
gen KinshipDistance = abs(KinshipScoreHomeCountry - KinshipScoreHomeCountryM) // Euclidean distance

* Diff nationality
gen OutGroup = 0
replace OutGroup = 1 if HomeCountry != HomeCountryManager
replace OutGroup = . if (HomeCountry == . | HomeCountryManager==.)
  label var OutGroup "=1 if employee has different homecountry of manager"
q
