* COUNTRY-LEVEL DATASETS*
* Virginia Minni
* 25/10/2018
* Modified: 27/12/2018
* Edited by Misha 27/12/2018

********************************************************************************
  * 0. Setting path to directory
********************************************************************************
  
clear all
set more off


cd $country

set scheme s1color

* set Matsize
//set matsize 11000
//set maxvar 32767


************* Cultural Similarity index **********************
  
********************************************************************************
* 1. Index on Cultural Similarity
* http://userpage.fu-berlin.de/~jroose/index_en/main_indexvalues.html
* The index is based on questions about values, which have been constructed according 
*to the value dimensions suggested by Shalom Schwartz and implemented in the European Social Survey (ESS). 
********************************************************************************

import delimited "$country/Similarity/ess_index.csv", delimiter(";", collapse)  varnames(1) clear
rename index_ess ESSIndex
rename homecountry_s HomeCountryS
rename homecountry_manager_s HomeCountrySM
label var ESSIndex "Index of similarity, EU, 1= max similarity"

replace HomeCountryS= "Russian Federation" if HomeCountryS== "Russia"
replace HomeCountryS= "United States of America" if HomeCountryS== "USA"
replace HomeCountryS= "United Kingdom" if HomeCountryS== "UK"
replace HomeCountryS= "Australia" if HomeCountryS== "australia"
replace HomeCountryS= "Algeria" if HomeCountryS== "algeria"
replace HomeCountryS= "Austria" if HomeCountryS== "austria"
replace HomeCountryS = "Korea, Republic of" if HomeCountryS == "Korea"
replace HomeCountryS = "Korea, Republic of" if HomeCountryS == "Korea"
replace HomeCountryS = "Cote d Ivoire" if HomeCountryS == "Ivory Coast"

replace HomeCountrySM= "Russian Federation" if HomeCountrySM== "Russia"
replace HomeCountrySM= "United States of America" if HomeCountrySM== "USA"
replace HomeCountrySM= "United Kingdom" if HomeCountrySM== "UK"
replace HomeCountrySM= "Australia" if HomeCountrySM== "australia"
replace HomeCountrySM= "Algeria" if HomeCountrySM== "algeria"
replace HomeCountrySM= "Austria" if HomeCountrySM== "austria"
replace HomeCountrySM = "Korea, Republic of" if HomeCountrySM == "Korea"
replace HomeCountrySM = "Korea, Republic of" if HomeCountrySM == "Korea"
replace HomeCountrySM = "Cote d Ivoire" if HomeCountrySM == "Ivory Coast"

save "$country/Similarity/similarity_EU.dta", replace 

********************************************************************************
  * 2. Cultural distance 
*http://culturaldistance.muth.io
********************************************************************************

import delimited "$country/Similarity/cultural_distance.csv", delimiter(";", collapse) varnames(1) encoding(ISO-8859-1)clear
rename v1 HomeCountryS
reshape long y19812014, i(HomeCountryS) j(HomeCountrySM) string
rename y19812014 CulturalDistance
destring CulturalDistance, replace force
label var CulturalDistance "Index of cultural distance"

replace HomeCountryS= "Russian Federation" if HomeCountryS== "Russia"
replace HomeCountryS= "United States of America" if HomeCountryS== "United States"
replace HomeCountryS= "United Kingdom" if HomeCountryS== "Great Britain"
replace HomeCountryS = "Korea, Republic of" if HomeCountryS == "South Korea"
replace HomeCountryS = "Vietnam" if HomeCountryS == "Viet Nam"
replace HomeCountryS = "Czech Republic" if HomeCountryS == "Czech Rep."
replace HomeCountryS = "Dominican Republic" if HomeCountryS == "Dominican Rep."

replace HomeCountrySM= "russian federation" if HomeCountrySM== "russia"
replace HomeCountrySM= "united states of america" if HomeCountrySM== "unitedstates"
replace HomeCountrySM= "united kingdom" if HomeCountrySM== "greatbritain"
replace HomeCountrySM = "korea, republic of" if HomeCountrySM == "southkorea"
replace HomeCountrySM = "burkina faso" if HomeCountrySM == "burkinafaso" 
replace HomeCountrySM = "czech republic" if HomeCountrySM == "czechrep"
replace HomeCountrySM = "dominican republic" if HomeCountrySM == "dominicanrep"
replace HomeCountrySM = "el salvador" if HomeCountrySM == "elsalvador"
replace HomeCountrySM = "hong kong" if HomeCountrySM == "hongkong"
replace HomeCountrySM = "new zealand" if HomeCountrySM == "newzealand"
replace HomeCountrySM = "puerto rico" if HomeCountrySM == "puertorico"
replace HomeCountrySM = "saudi arabia" if HomeCountrySM == "saudiarabia"
replace HomeCountrySM = "south africa" if HomeCountrySM == "southafrica"
replace HomeCountrySM = "trinidad and tobago" if HomeCountrySM == "trinidadandtobago"


*Change name to merge with UL data
gen HomeCountrySl = lower(HomeCountryS)
rename HomeCountrySM HomeCountrySMl

replace CulturalDistance=0 if  CulturalDistance==. // max similarity for same country

save "$country/Similarity/WVSDistance.dta", replace 

********************************************************************************
* Newgendist - cultural distance based on genetic relatedness 
* Microsatellites variation (DNA)
* by Spolaore and Wacziarg ( Journal of Applied Metrics, 2017)
* Pemberton et al. (2013)
/*
  The dataset from Pemberton et al. differs from
Cavalli-Sforza et al. not only with respect to the genetic information on which it is based (microsatellites vs. classic
                                                                                             genetic markers), but also in the number and specificity of populations that are covered. An important advantage of the
new dataset is that it provides more detailed information on populations outside Europe—especially within Asia and
Africa.
*/
  ********************************************************************************

use "$country/Similarity/newgendist.dta", clear
keep country_1 country_2 new_gendist_weighted new_gendist_plurality new_gendist_1500
rename country_1 HomeCountryS
rename country_2 HomeCountrySM

rename new_gendist_weighted GeneticDistance
rename new_gendist_plurality GeneticDistancePlural
rename new_gendist_1500 GeneticDistance1500

foreach x in HomeCountryS HomeCountrySM{
  replace `x'= "Russian Federation" if `x'== "Russia"
  replace `x'= "United States of America" if `x'== "U.S.A"
  replace `x'= "United Kingdom" if `x'== "Great Britain"
  replace `x' = "Korea, Republic of" if `x' == "Korea"
  replace `x' = "Vietnam" if `x' == "Viet Nam"
  replace `x' = "Czech Republic" if `x' == "Czech Rep."
  replace `x' = "Dominican Republic" if `x' == "Dominican Rep."
  replace `x' = "Myanmar" if `x' == "Myanmar(Burma)"
  replace `x' = "Yemen" if `x' == "Yemen, People's Democratic Republic of"
  replace `x' = "Cote d Ivoire" if `x' == "Cote d'Ivoire"
  *replace HomeCountryS = "Yemen" if HomeCountryS == "Yemen, Arab Republic of"
  *replace HomeCountryS = "Russian Federation" if HomeCountryS == "U.S.S.R."
  *replace HomeCountryS = "Germany" if HomeCountryS == "German Democratic Republic"
  *replace HomeCountryS = "Germany" if HomeCountryS == "Germany, Federal Republic of"
  *replace HomeCountryS = "Czech Republic" if HomeCountryS == "Czechoslovakia"
  
}

sort HomeCountryS HomeCountrySM
save "$country/Similarity/newgendistHR.dta", replace 

use "$country/Similarity/newgendistHR.dta", clear
rename HomeCountryS HomeCountrySM1
rename HomeCountrySM HomeCountryS
rename HomeCountrySM1 HomeCountrySM
save "$country/Similarity/newgendistHRM.dta", replace

use "$country/Similarity/newgendistHR.dta", replace
append using "$country/Similarity/newgendistHRM.dta"
save "$country/Similarity/GeneDistance.dta", replace

********************************************************************************
* Cultdist - cultural distance based on genetic relatedness, WVS, religion, language

* Data for 'Ancestry, Language and Culture' by Spolaore and Wacziarg, May 2015
* Cavalli and Sforza genetic data 1994
********************************************************************************

use "$country/Similarity/cultdist.dta", clear
drop wacziarg_1 wacziarg_2
rename country_1 HomeCountryS
rename country_2 HomeCountrySM

rename fst_distance_dominant FstDistDominant
rename fst_distance_weighted FstDistWeighted
rename cognate_dominant LinguisticDistance2Dominant
rename cognate_weighted LinguisticDistance2
rename lingdist_dom_formula LinguisticDistanceDominant
rename lingdist_weighted_formula LinguisticDistance
rename reldist_dominant_formula ReligionDistanceDominant
rename reldist_weighted_formula ReligionDistance
rename reldist_dominant_WCD_form ReligionDistanceDominantWCD
rename reldist_weighted_WCD_form ReligionDistanceWCD

rename total CultDistIndex
rename total_a CulDistIndexA
rename total_c CulDistIndexC
rename total_d CulDistIndexD
rename total_e CulDistIndexE
rename total_f CulDistIndexF
rename total_binary CulDistIndexBinary
rename total_non_binary CulDistIndexNonBinary

foreach x in HomeCountryS HomeCountrySM{
replace `x'= "Russian Federation" if `x'== "Russia"
replace `x'= "United States of America" if `x'== "U.S.A"
replace `x'= "United Kingdom" if `x'== "Great Britain"
replace `x' = "Korea, Republic of" if `x' == "Korea"
replace `x' = "Vietnam" if `x' == "Viet Nam"
replace `x' = "Czech Republic" if `x' == "Czech Rep."
replace `x' = "Dominican Republic" if `x' == "Dominican Rep."
replace `x' = "Myanmar" if `x' == "Myanmar(Burma)"
replace `x' = "Yemen" if `x' == "Yemen, People's Democratic Republic of"
replace `x' = "Cote d Ivoire" if `x' == "Cote d'Ivoire"
*replace HomeCountryS = "Yemen" if HomeCountryS == "Yemen, Arab Republic of"
*replace HomeCountryS = "Russian Federation" if HomeCountryS == "U.S.S.R."
*replace HomeCountryS = "Germany" if HomeCountryS == "German Democratic Republic"
*replace HomeCountryS = "Germany" if HomeCountryS == "Germany, Federal Republic of"
*replace HomeCountryS = "Czech Republic" if HomeCountryS == "Czechoslovakia"

}

sort HomeCountryS HomeCountrySM
save "$country/Similarity/cultdistHR.dta", replace 


use "$country/Similarity/cultdistHR.dta", clear
rename HomeCountryS HomeCountrySM1
rename HomeCountrySM HomeCountryS
rename HomeCountrySM1 HomeCountrySM
save "$country/Similarity/cultdistHRM.dta", replace

use "$country/Similarity/cultdistHR.dta", replace
append using "$country/Similarity/cultdistHRM.dta"
save "$country/Similarity/CultDistance.dta", replace



********************************************************************************
* Bilateral.dta - cultural distance based on genetic relatedness 
* Microsatellites variation (DNA)
* Genetic distance, a measure associated with the time elapsed
* since two populations’ last common ancestors
* The diffusion of development, by Spolaore and Wacziarg ( QJE, 2009)
* Our source for genetic distances between human populations is Cavalli-Sforza, Menozzi, and Piazza (1994).
* Genetic distance measures the difference in gene distributions between two populations
/*
Therefore, genetic distance measures
the time since two populations have shared common ancestors—
that is, the time since they have been the same population

An intuitive analogue is the familiar concept of relatedness between individuals: two siblings
are more closely related than two cousins because they share
more recent common ancestors—their parents rather than their
grandparents.

What traits are captured by genetic distance? We argue that,
by its very definition, genetic distance is an excellent summary
statistic capturing divergence in the whole set of implicit beliefs,
customs, habits, biases, conventions, etc. that are transmitted
across generations—biologically and/or culturally—with high persistence. In a nutshell, human genetic distance can be viewed as
a summary measure of very long-term divergence in intergenerationally transmitted traits across populations. 
Desmet et al. (2007) show a strong and robust correlation between answers to the
World Values Survey (WVS) and genetic distance, finding that
European populations that are genetically closer give more similar answers to a set of 430 questions about norms, values, and
cultural characteristics included in the 2005 WVS sections on perceptions of life, family, religion, and morals
*/
********************************************************************************


* Benjamin Enke 
use "$country/Similarity/Enke_data_programs/Data/CountryData.dta", clear
keep isocode gps_negrecip_honor gps_punish_others gps_punish_revenge ///
diff_trust_out_in diff_trust_family trust_othernationality kinship_score values_uniform

rename isocode ISO
rename gps_negrecip_honor GPSNegRecipHonor
rename gps_punish_others GPSPunishOthers
rename gps_punish_revenge GPSPunishRevenge
rename diff_trust_out_in TrustOutIn
rename diff_trust_family TrustFamily
rename trust_othernationality TrustOtherNat
rename kinship_score KinshipScore
rename values_uniform ValuesUniform

foreach x of varlist _all {
rename `x' `x'HomeCountry
} 

rename ISOHomeCountry ISOCodeHome

save "$country/Similarity/kinship.dta", replace 

use "$country/Similarity/Enke_data_programs/Data/CountryData.dta", clear
keep isocode gps_negrecip_honor gps_punish_others gps_punish_revenge ///
diff_trust_out_in diff_trust_family trust_othernationality kinship_score values_uniform

rename isocode ISO
rename gps_negrecip_honor GPSNegRecipHonor
rename gps_punish_others GPSPunishOthers
rename gps_punish_revenge GPSPunishRevenge
rename diff_trust_out_in TrustOutIn
rename diff_trust_family TrustFamily
rename trust_othernationality TrustOtherNat
rename kinship_score KinshipScore
rename values_uniform ValuesUniform

foreach x of varlist _all {
rename `x' `x'HomeCountryM
}
// Preparing ISOHomeCountryM so that it matches with other datasets

rename ISOHomeCountryM ISOCodeHomeM

save "$country/Similarity/kinshipM.dta", replace 
