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

cd "$data

set scheme s1color

* set Matsize
//set matsize 11000
//set maxvar 32767

********************************************************************************
  * 1. Data: AllSnapshotWCM
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

decode HomeCountry, gen(HomeCountryS)
decode HomeCountryManager, gen(HomeCountrySManager)

gen HomeCountrySl=lower(HomeCountryS)
gen HomeCountrySManagerl=lower(HomeCountrySManager)
replace HomeCountrySl = "macedonia" if HomeCountrySl == "macedonia, fmr yugoslav"
replace HomeCountrySManagerl = "macedonia" if HomeCountrySManagerl == "macedonia, fmr yugoslav"
replace HomeCountrySl = "palestine" if HomeCountrySl == "palestinian territory occupied"
replace HomeCountrySManagerl = "palestine" if HomeCountrySManagerl == "palestinian territory occupied"

merge m:1 HomeCountrySl HomeCountrySManagerl using "$similarity/WVSDistance.dta" // WVS data
drop if _merge ==2
drop _merge
replace CulturalDistance  = 0 if HomeCountryS== HomeCountrySManager


/*
  egen CulturalDistancestd = std(CulturalDistance)
order CulturalDistancestd, a(CulturalDistance)
sort IDlse YearMonth 
by IDlse: gen DeltaCD= d.CulturalDistancestd
order DeltaCD, a(CulturalDistance)
*/
  
merge m:1 HomeCountryS HomeCountrySManager using "$similarity/GeneDistance.dta" // newgendist
drop if _merge ==2
drop _merge
replace GeneticDistance = 0 if HomeCountryS== HomeCountrySManager
replace GeneticDistance1500 = 0 if HomeCountryS== HomeCountrySManager
replace GeneticDistancePlural = 0 if HomeCountryS== HomeCountrySManager

merge m:1 HomeCountryS HomeCountrySManager using "$similarity/CultDistance.dta" // cultdist
drop if _merge ==2
drop _merge

replace ReligionDistance = 0 if HomeCountryS== HomeCountrySManager
replace LinguisticDistance = 0 if HomeCountryS== HomeCountrySManager

merge m:1 ISOHomeCountry using "$similarity/kinship.dta" // Enke data
drop if _merge ==2
drop _merge
order KinshipScoreHomeCountry ISOHomeCountry, a(HomeCountry)

compress

merge m:1 ISOHomeCountryM using "$similarity/kinshipM.dta" // Enke data
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
  label var OutGroup "=1 if employee has different HomeCountry of manager"

* Same gender
gen SameGender = 0
replace SameGender = 1 if Female == FemaleManager
replace SameGender = . if (Female== . | FemaleManager == .)
  label var SameGender "=1 if employee has same gender as manager"

* Same age
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
label var HHI "Herfindall index with HomeCountry of team members"
label var TeamEthFrac "Frac Index: equals 0 when all members have same HomeCountry - 1 is max diversity"

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
* Diff Language Indicator
********************************************************************************
*decode HomeCountry, gen(HomeCountryS) 
*decode HomeCountryManager, gen(HomeCountrySManager) 
 
gen SpeakEngl = 0
replace SpeakEngl = 1 if HomeCountryS=="United Kingdom" |  HomeCountryS=="South Africa" ///
 | HomeCountryS=="United States of America" | HomeCountryS=="India" | HomeCountryS=="India" ///
 | HomeCountryS=="Australia"  | HomeCountryS=="Canada" |  HomeCountryS=="New Zealand" ///
|  HomeCountryS=="Ireland" |  HomeCountryS=="Singapore" | HomeCountryS=="Hong Kong" // as classified by UK gov https://www.sheffield.ac.uk/international/english-speaking-countries
replace SpeakEngl = . if  HomeCountry==.
label var SpeakEngl "From English speaking country"

gen SpeakEnglM = 0
replace SpeakEnglM = 1 if HomeCountrySManager=="United Kingdom" |  HomeCountrySManager=="South Africa" ///
 | HomeCountrySManager=="United States of America" | HomeCountrySManager=="India" | HomeCountrySManager=="India" ///
 | HomeCountrySManager=="Australia"  | HomeCountrySManager=="Canada" |  HomeCountrySManager=="New Zealand" ///
|  HomeCountrySManager=="Ireland" |  HomeCountrySManager=="Singapore" | HomeCountrySManager=="Hong Kong" // as classified by UK gov https://www.sheffield.ac.uk/international/english-speaking-countries
replace SpeakEnglM = . if  HomeCountryManager==.
label var SpeakEnglM "Manager from English speaking country"

gen SpeakFr = 0
replace SpeakFr = 1 if HomeCountryS=="France" |  HomeCountryS=="Belgium" ///
 | HomeCountryS=="Cameroon" | HomeCountryS==" Burkina Faso" | HomeCountryS=="Burundi" ///
 | HomeCountryS=="Cote d Ivoire"  | HomeCountryS=="Mali" |  HomeCountryS=="Niger" ///
|  HomeCountryS=="Togo" 
replace SpeakFr = . if  HomeCountry==.
label var SpeakFr "From French speaking country"

gen SpeakFrM = 0
replace SpeakFrM = 1 if HomeCountrySManager=="France" |  HomeCountrySManager=="Belgium" ///
 | HomeCountrySManager=="Cameroon" | HomeCountrySManager==" Burkina Faso" | HomeCountrySManager=="Burundi" ///
 | HomeCountrySManager=="Cote d Ivoire"  | HomeCountrySManager=="Mali" |  HomeCountrySManager=="Niger" ///
|  HomeCountrySManager=="Togo" 
replace SpeakFrM = . if  HomeCountryManager==.
label var SpeakFrM "Manager from French speaking country"

gen SpeakSpan = 0
replace SpeakSpan = 1 if HomeCountryS=="Argentina" | HomeCountryS=="Bolivia" | HomeCountryS=="Chile" | ///
HomeCountryS=="Colombia" |  HomeCountryS=="Costa Rica" | HomeCountryS=="Dominican Republic" | ///
HomeCountryS=="Ecuador" | HomeCountryS=="El Salvador" | HomeCountryS=="Guatemala" | ///
HomeCountryS=="Honduras" | HomeCountryS=="Mexico" |  HomeCountryS=="Nicaragua" | ///
HomeCountryS=="Panama" | HomeCountryS=="Paraguay" | HomeCountryS=="Peru" | HomeCountryS=="Puerto Rico" | ///
HomeCountryS=="Spain" | HomeCountryS=="Uruguay" | HomeCountryS=="Bolivia" | HomeCountryS=="Venezuela" 
replace SpeakSpan = . if  HomeCountry==.
label var SpeakSpan "From Spanish speaking country"


gen SpeakSpanM = 0
replace SpeakSpanM = 1 if HomeCountrySManager=="Argentina" | HomeCountrySManager=="Bolivia" | HomeCountrySManager=="Chile" | ///
HomeCountrySManager=="Colombia" |  HomeCountrySManager=="Costa Rica" | HomeCountrySManager=="Dominican Republic" | ///
HomeCountrySManager=="Ecuador" | HomeCountrySManager=="El Salvador" | HomeCountrySManager=="Guatemala" | ///
HomeCountrySManager=="Honduras" | HomeCountrySManager=="Mexico" |  HomeCountrySManager=="Nicaragua" | ///
HomeCountrySManager=="Panama" | HomeCountrySManager=="Paraguay" | ///
HomeCountrySManager=="Peru" | HomeCountrySManager=="Puerto Rico" | ///
HomeCountrySManager=="Spain" | HomeCountrySManager=="Uruguay"  | HomeCountrySManager=="Bolivia" | HomeCountrySManager=="Venezuela" 
replace SpeakSpanM = . if  HomeCountryManager==.
label var SpeakSpanM "Manager from Spanish speaking country"


gen SpeakPor = 0
replace SpeakPor = 1 if HomeCountryS=="Portugal" | HomeCountryS=="Portugal" | ///
HomeCountryS=="Mozambique" | HomeCountryS=="Brazil" | HomeCountryS=="Angola" | ///
HomeCountryS=="Cape Verde"
replace SpeakPor = . if  HomeCountry==.
label var  SpeakPor "From Portuguese speaking country"


gen SpeakPorM = 0
replace SpeakPorM = 1 if HomeCountrySManager=="Portugal" | HomeCountrySManager=="Portugal" | ///
HomeCountrySManager=="Mozambique" | HomeCountrySManager=="Brazil" | HomeCountrySManager=="Angola" | ///
HomeCountrySManager=="Cape Verde" 
replace SpeakPorM = . if  HomeCountryManager==.

label var SpeakPorM "Manager from Portuguese speaking country"

gen SpeakArab = 0
replace SpeakArab = 1 if HomeCountryS=="Egypt" | HomeCountryS=="Algeria" | ///
HomeCountryS=="Sudan" | HomeCountryS=="Saudi Arabia" | HomeCountryS=="Tunisia" | ///
HomeCountryS=="Syria" | HomeCountryS=="Morocco" | HomeCountryS=="Mauritania" ///
| HomeCountryS=="Lybia" | HomeCountryS=="Somalia" | HomeCountryS=="Jordan" ///
| HomeCountryS=="Iraq" | HomeCountryS=="Kuwait" | HomeCountryS=="Yemen" | HomeCountryS=="Oman" ///
| HomeCountryS=="Qatar" | HomeCountryS=="Somalia"  | HomeCountryS=="Bahrain" | HomeCountryS=="United Arab Emirates" ///
  | HomeCountryS=="Lebanon" |  HomeCountryS=="Kuwait"
  replace SpeakArab = . if  HomeCountry==.

label var SpeakArab "From  Arabic speaking country"

gen SpeakArabM = 0
replace SpeakArabM = 1 if HomeCountrySManager=="Egypt" | HomeCountrySManager=="Algeria" | ///
HomeCountrySManager=="Sudan" | HomeCountrySManager=="Saudi Arabia" | HomeCountrySManager=="Tunisia" | ///
HomeCountrySManager=="Syria" | HomeCountrySManager=="Morocco" | HomeCountrySManager=="Mauritania" ///
| HomeCountrySManager=="Lybia" | HomeCountrySManager=="Somalia" | HomeCountrySManager=="Jordan" ///
| HomeCountrySManager=="Iraq" | HomeCountrySManager=="Bahrain" | HomeCountrySManager=="Kuwait" | HomeCountrySManager=="Yemen" | HomeCountrySManager=="Oman" ///
| HomeCountrySManager=="Qatar" | HomeCountrySManager=="Somalia"  | HomeCountrySManager=="United Arab Emirates" ///
  | HomeCountrySManager=="Lebanon" |  HomeCountrySManager=="Kuwait"
  replace SpeakArabM = . if  HomeCountryManager==.

label var SpeakArabM "Manager from Arabic speaking country"

gen SpeakRus=0
replace  SpeakRus=1 if HomeCountryS=="Russian Federation" | HomeCountryS=="Belarus" | HomeCountryS=="Kyrgyzstan" ///
| HomeCountryS=="Kazakhstan" | HomeCountryS=="Ukraine" | HomeCountryS=="Azerbaijan" ///
| HomeCountryS=="Estonia" | HomeCountryS=="Georgia" | HomeCountryS=="Latvia" | HomeCountryS=="Lithuania" ///
| HomeCountryS=="Moldova" | HomeCountryS=="Tajikistan"  | HomeCountryS=="Turkmenistan" | HomeCountryS=="Uzbekistan"
replace SpeakRus = . if  HomeCountry==.
label var SpeakRus "From  Russian speaking country"

gen SpeakRusM=0
replace  SpeakRusM=1 if HomeCountrySManager=="Russian Federation" | HomeCountrySManager=="Belarus" | HomeCountrySManager=="Kyrgyzstan" ///
| HomeCountrySManager=="Kazakhstan" | HomeCountrySManager=="Ukraine" | HomeCountrySManager=="Azerbaijan" ///
| HomeCountrySManager=="Estonia" | HomeCountrySManager=="Georgia" | HomeCountrySManager=="Latvia" | HomeCountrySManager=="Lithuania" ///
| HomeCountrySManager=="Moldova" | HomeCountrySManager=="Tajikistan"  | HomeCountrySManager=="Turkmenistan" | HomeCountrySManager=="Uzbekistan"
replace SpeakRusM = . if  HomeCountryManager==.
label var SpeakRusM "Manager from  Russian speaking country"

gen DiffLanguage = 1
replace DiffLanguage = 0 if (SpeakEngl ==1 &  SpeakEnglM ==1) | (SpeakFr ==1 &  SpeakFrM ==1) | ///
(SpeakPor ==1 &  SpeakPorM ==1) | (SpeakSpan ==1 &  SpeakSpanM ==1) | (SpeakRus ==1 &  SpeakRusM ==1) | ///
(SpeakArab ==1 &  SpeakArabM ==1)
replace DiffLanguage = 0 if  HomeCountryS== HomeCountrySManager
replace DiffLanguage = . if HomeCountry==. | HomeCountryManager==.
label var DiffLanguage "Employee and manager speak different language"

********************************************************************************
  * Saving Analysis data
********************************************************************************

label var CulDistIndexC "WVS Cultural Distance, category C: work"
label var CulDistIndexC "WVS Cultural Distance, all categories"

compress // to save disk space 
save "$data/dta/AllSnapshotWCCulture.dta", replace

********************************************************************************
  * 2. Data: (UniVoiceSnapshotWC) UniVoice, White Collar
********************************************************************************
  
use "$data/dta/UniVoiceSnapshotWCM.dta", clear

xtset IDlse YearMonth // set panel data

*preparation

drop Cluster MCO CountrySize OfficeNum Cluster EmployeeNum SpanControl LeaveType ///
FTE ISOCountryCode CountryYM ManagerNumYM dup_location

decode HomeCountry, gen(HomeCountryS)
decode HomeCountryManager, gen(HomeCountrySManager)

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

merge m:1 HomeCountrySl HomeCountrySManagerl using "$similarity/WVSDistance.dta" // WVS data
drop if _merge ==2
drop _merge

rename CulturalDistance CulturalDistance1
egen CulturalDistance = std(CulturalDistance1)
drop CulturalDistance1

merge m:1 HomeCountryS HomeCountrySManager using "$similarity/GeneDistance.dta" // newgendist
drop if _merge ==2
drop _merge

merge m:1 HomeCountryS HomeCountrySManager using "$similarity/CultDistance.dta" // cultdist
drop if _merge ==2
drop _merge

merge m:1 ISOHomeCountry using "$similarity/kinship.dta" // Enke data
drop if _merge ==2
drop _merge

order KinshipScoreHomeCountry ISOHomeCountry, a(HomeCountry)

merge m:1 ISOHomeCountryManager using "$similarity/kinshipM.dta" // Enke data
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
  label var OutGroup "=1 if employee has different HomeCountry of manager"

* Same gender
gen SameGender = 0
replace SameGender = 1 if Female == FemaleManager
replace SameGender = . if (Female== . | FemaleManager == .)
  label var SameGender "=1 if employee has same gender as manager"

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
label var HHI "Herfindall index with HomeCountry of team members"
label var TeamEthFrac "Frac Index: equals 0 when all members have same HomeCountry - 1 is max diversity"

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


tempfile temp
save `temp'
use "$data/dta/AllSnapshotWCCulture.dta", clear
keep IDlse YearMonth JointTenure MonthsCulture
merge 1:1 IDlse YearMonth using `temp' // all matched


/*

39 unmatched
    Result                           # of obs.
    -----------------------------------------
    not matched                     7,013,183
        from master                 7,013,144  (_merge==1)
        from using                         39  (_merge==2)

    matched                           858,010  (_merge==3)
    -----------------------------------------

*/

drop if _merge == 1
drop _merge

order CulturalDistance KinshipDistance OutGroup SameGender JointTenure MonthsCulture TeamSize TeamEthNo FirstEthNo TeamEthSq HHI TeamEthFrac, b(ManagerNum)
order Balanced, after(YearMonth)


********************************************************************************
* Diff Language Indicator
********************************************************************************

*decode HomeCountry, gen(HomeCountryS) 
*decode HomeCountryManager, gen(HomeCountrySManager) 
 
gen SpeakEngl = 0
replace SpeakEngl = 1 if HomeCountryS=="United Kingdom" |  HomeCountryS=="South Africa" ///
 | HomeCountryS=="United States of America" | HomeCountryS=="India" | HomeCountryS=="India" ///
 | HomeCountryS=="Australia"  | HomeCountryS=="Canada" |  HomeCountryS=="New Zealand" ///
|  HomeCountryS=="Ireland" |  HomeCountryS=="Singapore" | HomeCountryS=="Hong Kong" // as classified by UK gov https://www.sheffield.ac.uk/international/english-speaking-countries
replace SpeakEngl = . if  HomeCountry==.
label var SpeakEngl "From English speaking country"

gen SpeakEnglM = 0
replace SpeakEnglM = 1 if HomeCountrySManager=="United Kingdom" |  HomeCountrySManager=="South Africa" ///
 | HomeCountrySManager=="United States of America" | HomeCountrySManager=="India" | HomeCountrySManager=="India" ///
 | HomeCountrySManager=="Australia"  | HomeCountrySManager=="Canada" |  HomeCountrySManager=="New Zealand" ///
|  HomeCountrySManager=="Ireland" |  HomeCountrySManager=="Singapore" | HomeCountrySManager=="Hong Kong" // as classified by UK gov https://www.sheffield.ac.uk/international/english-speaking-countries
replace SpeakEnglM = . if  HomeCountryManager==.
label var SpeakEnglM "Manager from English speaking country"

gen SpeakFr = 0
replace SpeakFr = 1 if HomeCountryS=="France" |  HomeCountryS=="Belgium" ///
 | HomeCountryS=="Cameroon" | HomeCountryS==" Burkina Faso" | HomeCountryS=="Burundi" ///
 | HomeCountryS=="Cote d Ivoire"  | HomeCountryS=="Mali" |  HomeCountryS=="Niger" ///
|  HomeCountryS=="Togo" 
replace SpeakFr = . if  HomeCountry==.
label var SpeakFr "From French speaking country"

gen SpeakFrM = 0
replace SpeakFrM = 1 if HomeCountrySManager=="France" |  HomeCountrySManager=="Belgium" ///
 | HomeCountrySManager=="Cameroon" | HomeCountrySManager==" Burkina Faso" | HomeCountrySManager=="Burundi" ///
 | HomeCountrySManager=="Cote d Ivoire"  | HomeCountrySManager=="Mali" |  HomeCountrySManager=="Niger" ///
|  HomeCountrySManager=="Togo" 
replace SpeakFrM = . if  HomeCountryManager==.
label var SpeakFrM "Manager from French speaking country"

gen SpeakSpan = 0
replace SpeakSpan = 1 if HomeCountryS=="Argentina" | HomeCountryS=="Bolivia" | HomeCountryS=="Chile" | ///
HomeCountryS=="Colombia" |  HomeCountryS=="Costa Rica" | HomeCountryS=="Dominican Republic" | ///
HomeCountryS=="Ecuador" | HomeCountryS=="El Salvador" | HomeCountryS=="Guatemala" | ///
HomeCountryS=="Honduras" | HomeCountryS=="Mexico" |  HomeCountryS=="Nicaragua" | ///
HomeCountryS=="Panama" | HomeCountryS=="Paraguay" | HomeCountryS=="Peru" | HomeCountryS=="Puerto Rico" | ///
HomeCountryS=="Spain" | HomeCountryS=="Uruguay" | HomeCountryS=="Bolivia" | HomeCountryS=="Venezuela" 
replace SpeakSpan = . if  HomeCountry==.
label var SpeakSpan "From Spanish speaking country"


gen SpeakSpanM = 0
replace SpeakSpanM = 1 if HomeCountrySManager=="Argentina" | HomeCountrySManager=="Bolivia" | HomeCountrySManager=="Chile" | ///
HomeCountrySManager=="Colombia" |  HomeCountrySManager=="Costa Rica" | HomeCountrySManager=="Dominican Republic" | ///
HomeCountrySManager=="Ecuador" | HomeCountrySManager=="El Salvador" | HomeCountrySManager=="Guatemala" | ///
HomeCountrySManager=="Honduras" | HomeCountrySManager=="Mexico" |  HomeCountrySManager=="Nicaragua" | ///
HomeCountrySManager=="Panama" | HomeCountrySManager=="Paraguay" | ///
HomeCountrySManager=="Peru" | HomeCountrySManager=="Puerto Rico" | ///
HomeCountrySManager=="Spain" | HomeCountrySManager=="Uruguay"  | HomeCountrySManager=="Bolivia" | HomeCountrySManager=="Venezuela" 
replace SpeakSpanM = . if  HomeCountryManager==.
label var SpeakSpanM "Manager from Spanish speaking country"


gen SpeakPor = 0
replace SpeakPor = 1 if HomeCountryS=="Portugal" | HomeCountryS=="Portugal" | ///
HomeCountryS=="Mozambique" | HomeCountryS=="Brazil" | HomeCountryS=="Angola" | ///
HomeCountryS=="Cape Verde"
replace SpeakPor = . if  HomeCountry==.
label var  SpeakPor "From Portuguese speaking country"


gen SpeakPorM = 0
replace SpeakPorM = 1 if HomeCountrySManager=="Portugal" | HomeCountrySManager=="Portugal" | ///
HomeCountrySManager=="Mozambique" | HomeCountrySManager=="Brazil" | HomeCountrySManager=="Angola" | ///
HomeCountrySManager=="Cape Verde" 
replace SpeakPorM = . if  HomeCountryManager==.

label var SpeakPorM "Manager from Portuguese speaking country"

gen SpeakArab = 0
replace SpeakArab = 1 if HomeCountryS=="Egypt" | HomeCountryS=="Algeria" | ///
HomeCountryS=="Sudan" | HomeCountryS=="Saudi Arabia" | HomeCountryS=="Tunisia" | ///
HomeCountryS=="Syria" | HomeCountryS=="Morocco" | HomeCountryS=="Mauritania" ///
| HomeCountryS=="Lybia" | HomeCountryS=="Somalia" | HomeCountryS=="Jordan" ///
| HomeCountryS=="Iraq" | HomeCountryS=="Kuwait" | HomeCountryS=="Yemen" | HomeCountryS=="Oman" ///
| HomeCountryS=="Qatar" | HomeCountryS=="Somalia"  | HomeCountryS=="Bahrain" | HomeCountryS=="United Arab Emirates" ///
  | HomeCountryS=="Lebanon" |  HomeCountryS=="Kuwait"
  replace SpeakArab = . if  HomeCountry==.

label var SpeakArab "From  Arabic speaking country"

gen SpeakArabM = 0
replace SpeakArabM = 1 if HomeCountrySManager=="Egypt" | HomeCountrySManager=="Algeria" | ///
HomeCountrySManager=="Sudan" | HomeCountrySManager=="Saudi Arabia" | HomeCountrySManager=="Tunisia" | ///
HomeCountrySManager=="Syria" | HomeCountrySManager=="Morocco" | HomeCountrySManager=="Mauritania" ///
| HomeCountrySManager=="Lybia" | HomeCountrySManager=="Somalia" | HomeCountrySManager=="Jordan" ///
| HomeCountrySManager=="Iraq" | HomeCountrySManager=="Bahrain" | HomeCountrySManager=="Kuwait" | HomeCountrySManager=="Yemen" | HomeCountrySManager=="Oman" ///
| HomeCountrySManager=="Qatar" | HomeCountrySManager=="Somalia"  | HomeCountrySManager=="United Arab Emirates" ///
  | HomeCountrySManager=="Lebanon" |  HomeCountrySManager=="Kuwait"
  replace SpeakArabM = . if  HomeCountryManager==.

label var SpeakArabM "Manager from Arabic speaking country"

gen SpeakRus=0
replace  SpeakRus=1 if HomeCountryS=="Russian Federation" | HomeCountryS=="Belarus" | HomeCountryS=="Kyrgyzstan" ///
| HomeCountryS=="Kazakhstan" | HomeCountryS=="Ukraine" | HomeCountryS=="Azerbaijan" ///
| HomeCountryS=="Estonia" | HomeCountryS=="Georgia" | HomeCountryS=="Latvia" | HomeCountryS=="Lithuania" ///
| HomeCountryS=="Moldova" | HomeCountryS=="Tajikistan"  | HomeCountryS=="Turkmenistan" | HomeCountryS=="Uzbekistan"
replace SpeakRus = . if  HomeCountry==.
label var SpeakRus "From  Russian speaking country"

gen SpeakRusM=0
replace  SpeakRusM=1 if HomeCountrySManager=="Russian Federation" | HomeCountrySManager=="Belarus" | HomeCountrySManager=="Kyrgyzstan" ///
| HomeCountrySManager=="Kazakhstan" | HomeCountrySManager=="Ukraine" | HomeCountrySManager=="Azerbaijan" ///
| HomeCountrySManager=="Estonia" | HomeCountrySManager=="Georgia" | HomeCountrySManager=="Latvia" | HomeCountrySManager=="Lithuania" ///
| HomeCountrySManager=="Moldova" | HomeCountrySManager=="Tajikistan"  | HomeCountrySManager=="Turkmenistan" | HomeCountrySManager=="Uzbekistan"
replace SpeakRusM = . if  HomeCountryManager==.
label var SpeakRusM "Manager from  Russian speaking country"

gen DiffLanguage = 1
replace DiffLanguage = 0 if (SpeakEngl ==1 &  SpeakEnglM ==1) | (SpeakFr ==1 &  SpeakFrM ==1) | ///
(SpeakPor ==1 &  SpeakPorM ==1) | (SpeakSpan ==1 &  SpeakSpanM ==1) | (SpeakRus ==1 &  SpeakRusM ==1) | ///
(SpeakArab ==1 &  SpeakArabM ==1)
replace DiffLanguage = 0 if  HomeCountryS== HomeCountrySManager
replace DiffLanguage = . if HomeCountry==. | HomeCountryManager==.
label var DiffLanguage "Employee and manager speak different language"

********************************************************************************
  * Saving Analysis data
********************************************************************************

label var CulDistIndexC "WVS Cultural Distance, category C: work"
label var CulDistIndexC "WVS Cultural Distance, all categories"

compress
save "$data/dta/UniVoiceSnapshotWCCulture.dta", replace
********************************************************************************
