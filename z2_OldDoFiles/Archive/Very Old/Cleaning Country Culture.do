* COUNTRY-LEVEL DATASETS*
* Virginia Minni
* 25/10/2018
* Modified: 27/12/2018

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

* Misha Windows
global dropbox "/Users/seong/Dropbox/ManagerTalent/Data/FullSample/RawData"
global analysis "/Users/seong/Dropbox/ManagerTalent/Data/FullSample/Analysis"

cd $dropbox

set scheme s1color

* set Matsize
set matsize 11000
set maxvar 32767



************* Cultural Similarity index **********************

********************************************************************************
* 1. Index on Cultural Similarity
* http://userpage.fu-berlin.de/~jroose/index_en/main_indexvalues.html
* The index is based on questions about values, which have been constructed according 
*to the value dimensions suggested by Shalom Schwartz and implemented in the European Social Survey (ESS). 
********************************************************************************

import delimited "$dropbox/Similarity/ess_index.csv", delimiter(";", collapse)  varnames(1) clear
label var index_ess "Index of similarity, EU, 1= max similarity"
replace homecountry_s= "Russian Federation" if homecountry_s== "Russia"
replace homecountry_s= "United States of America" if homecountry_s== "USA"
replace homecountry_s= "United Kingdom" if homecountry_s== "UK"
replace homecountry_s= "Australia" if homecountry_s== "australia"
replace homecountry_s= "Algeria" if homecountry_s== "algeria"
replace homecountry_s= "Austria" if homecountry_s== "austria"
replace homecountry_s = "Korea, Republic of" if homecountry_s == "Korea"
replace homecountry_s = "Korea, Republic of" if homecountry_s == "Korea"
replace homecountry_s = "Cote d Ivoire" if homecountry_s == "Ivory Coast"

replace homecountry_manager_s= "Russian Federation" if homecountry_manager_s== "Russia"
replace homecountry_manager_s= "United States of America" if homecountry_manager_s== "USA"
replace homecountry_manager_s= "United Kingdom" if homecountry_manager_s== "UK"
replace homecountry_manager_s= "Australia" if homecountry_manager_s== "australia"
replace homecountry_manager_s= "Algeria" if homecountry_manager_s== "algeria"
replace homecountry_manager_s= "Austria" if homecountry_manager_s== "austria"
replace homecountry_manager_s = "Korea, Republic of" if homecountry_manager_s == "Korea"
replace homecountry_manager_s = "Korea, Republic of" if homecountry_manager_s == "Korea"
replace homecountry_manager_s = "Cote d Ivoire" if homecountry_manager_s == "Ivory Coast"

save "$dropbox/similarity_EU.dta", replace 

********************************************************************************
* 2. Cultural distance 
*http://culturaldistance.muth.io
********************************************************************************

import delimited "$dropbox/Similarity/cultural_distance.csv", delimiter(";", collapse) varnames(1) encoding(ISO-8859-1)clear
rename v1 homecountry_s
reshape long y19812014, i(homecountry_s) j(homecountry_manager_s) string
rename y19812014 cultural_distance
destring cultural_distance, replace force
label var cultural_distance "Index of cultural distance"

replace homecountry_s= "Russian Federation" if homecountry_s== "Russia"
replace homecountry_s= "United States of America" if homecountry_s== "United States"
replace homecountry_s= "United Kingdom" if homecountry_s== "Great Britain"
replace homecountry_s = "Korea, Republic of" if homecountry_s == "South Korea"
replace homecountry_s = "Vietnam" if homecountry_s == "Viet Nam"
replace homecountry_s = "Czech Republic" if homecountry_s == "Czech Rep."
replace homecountry_s = "Dominican Republic" if homecountry_s == "Dominican Rep."


replace homecountry_manager_s= "russian federation" if homecountry_manager_s== "russia"
replace homecountry_manager_s= "united states of america" if homecountry_manager_s== "unitedstates"
replace homecountry_manager_s= "united kingdom" if homecountry_manager_s== "greatbritain"
replace homecountry_manager_s = "korea, republic of" if homecountry_manager_s == "southkorea"
replace homecountry_manager_s = "burkina faso" if homecountry_manager_s == "burkinafaso" 
replace homecountry_manager_s = "czech republic" if homecountry_manager_s == "czechrep"
replace homecountry_manager_s = "dominican republic" if homecountry_manager_s == "dominicanrep"
replace homecountry_manager_s = "el salvador" if homecountry_manager_s == "elsalvador"
replace homecountry_manager_s = "hong kong" if homecountry_manager_s == "hongkong"
replace homecountry_manager_s = "new zealand" if homecountry_manager_s == "newzealand"
replace homecountry_manager_s = "puerto rico" if homecountry_manager_s == "puertorico"
replace homecountry_manager_s = "saudi arabia" if homecountry_manager_s == "saudiarabia"
replace homecountry_manager_s = "south africa" if homecountry_manager_s == "southafrica"
replace homecountry_manager_s = "trinidad and tobago" if homecountry_manager_s == "trinidadandtobago"



*Change name to merge with UL data
gen homecountry_sl = lower( homecountry_s)
rename  homecountry_manager_s homecountry_manager_sl

replace cultural_distance=0 if  cultural_distance==. // max similarity for same country

save "$dropbox/WVSDistance.dta", replace 

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

use "$dropbox/Similarity/newgendist.dta", clear
keep country_1 country_2 new_gendist_weighted new_gendist_plurality new_gendist_1500
rename country_1 homecountry_s
rename country_2 homecountry_manager_s

foreach x in homecountry_s homecountry_manager_s{
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
*replace homecountry_s = "Yemen" if homecountry_s == "Yemen, Arab Republic of"
*replace homecountry_s = "Russian Federation" if homecountry_s == "U.S.S.R."
*replace homecountry_s = "Germany" if homecountry_s == "German Democratic Republic"
*replace homecountry_s = "Germany" if homecountry_s == "Germany, Federal Republic of"
*replace homecountry_s = "Czech Republic" if homecountry_s == "Czechoslovakia"

}

sort homecountry_s homecountry_manager_s
save "$dropbox/Similarity/newgendistHR.dta", replace 



use "$dropbox/Similarity/newgendistHR.dta", clear
rename homecountry_s homecountry_manager_s1
rename homecountry_manager_s homecountry_s
rename homecountry_manager_s1 homecountry_manager_s
save "$dropbox/Similarity/newgendistHRM.dta", replace

use "$dropbox/Similarity/newgendistHR.dta", replace
append using "$dropbox/Similarity/newgendistHRM.dta"
save "$dropbox/Similarity/GeneDistance.dta", replace
********************************************************************************
* Cultdist - cultural distance based on genetic relatedness, WVS, religion, language

* Data for 'Ancestry, Language and Culture' by Spolaore and Wacziarg, May 2015
* Cavalli and Sforza genetic data 1994
********************************************************************************

use "$dropbox/Similarity/cultdist.dta", clear
drop wacziarg_1 wacziarg_2
rename country_1 homecountry_s
rename country_2 homecountry_manager_s

foreach x in homecountry_s homecountry_manager_s{
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
*replace homecountry_s = "Yemen" if homecountry_s == "Yemen, Arab Republic of"
*replace homecountry_s = "Russian Federation" if homecountry_s == "U.S.S.R."
*replace homecountry_s = "Germany" if homecountry_s == "German Democratic Republic"
*replace homecountry_s = "Germany" if homecountry_s == "Germany, Federal Republic of"
*replace homecountry_s = "Czech Republic" if homecountry_s == "Czechoslovakia"

}

sort homecountry_s homecountry_manager_s
save "$dropbox/Similarity/cultdistHR.dta", replace 


use "$dropbox/Similarity/cultdistHR.dta", clear
rename homecountry_s homecountry_manager_s1
rename homecountry_manager_s homecountry_s
rename homecountry_manager_s1 homecountry_manager_s
save "$dropbox/Similarity/cultdistHRM.dta", replace

use "$dropbox/Similarity/cultdistHR.dta", replace
append using "$dropbox/Similarity/cultdistHRM.dta"
save "$dropbox/Similarity/CultDistance.dta", replace



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
use "$dropbox/Similarity/Enke_data_programs/Data/CountryData.dta", clear
keep isocode gps_negrecip_honor gps_punish_others gps_punish_revenge ///
diff_trust_out_in diff_trust_family trust_othernationality kinship_score values_uniform
rename trust_othernationality trust_othernat

foreach x of varlist _all {
	rename `x' `x'_homecountry
} 
save "$dropbox/Similarity/kinship.dta", replace 

use "$dropbox/Similarity/Enke_data_programs/Data/CountryData.dta", clear
keep isocode gps_negrecip_honor gps_punish_others gps_punish_revenge ///
diff_trust_out_in diff_trust_family trust_othernationality kinship_score values_uniform
rename trust_othernationality trust_othernat

foreach x of varlist _all {
	rename `x' `x'_homecountryM
} 
save "$dropbox/Similarity/kinshipM.dta", replace 
