/* Country Culture Conversion.do

This do-file converts Country-level similarity datasets cleaned in
"1.Similarity Cleaning.do" in CountryLevel. It supercedes "1.Cleaning Country Culture.do",
which is now in the archive.

Author: Misha Seong
Created: 1st Jul, 2020
* ARCHIVED 7/11/2020: NOT RUNNING IT ANYMORE 
*/

use "$cleveldta/1.ESSCultDist.dta", clear
rename CountryS1 HomeCountryS
rename ISOCode1 ISOCode

rename CountryS2 HomeCountrySM
rename ISOCode2 ISOCodeM

save "$temp/similarity_EU.dta", replace 

use "$cleveldta/1.WVSCultDist.dta", clear
rename CountryS1 HomeCountryS
rename ISOCode1 ISOCode

rename CountryS2 HomeCountrySM
rename ISOCode2 ISOCodeM

*Change name to merge with UL data
gen HomeCountrySl = lower(HomeCountryS), a(HomeCountryS)
gen HomeCountrySMl = lower(HomeCountrySM),a(HomeCountrySM)

save "$temp/WVSDistance.dta", replace 

use "$cleveldta/1.GeneDist.dta", clear
rename CountryS1 HomeCountryS
rename ISOCode1 ISOCode

rename CountryS2 HomeCountrySM
rename ISOCode2 ISOCodeM

save "$temp/GeneDistance.dta", replace

use "$cleveldta/1.CultDist.dta", replace
rename CountryS1 HomeCountryS
rename ISOCode1 ISOCode

rename CountryS2 HomeCountrySM
rename ISOCode2 ISOCodeM

save "$temp/CultDistance.dta", replace

use "$cleveldta/1.Kinship.dta",clear

* Removing "Std"
rename *Std *

keep CountryS ISOCode Year ///
GPSNegRecipHonor GPSPunishOthers GPSPunishRevenge ///
TrustDiffOutIn TrustDiffFamilyOthers TrustOtherNat ///
KinshipScore ValuesUniform

* updated variable names (12th August 2020): 
* TrustOutIn  -> TrustDiffOutIn
* TrustFamily -> TrustDiffFamilyOthers

* Renaming TrustDiffFamilyOthers as the name is too long
rename TrustDiffFamilyOthers TrustDiffFamily


foreach x of varlist GPSNegRecipHonor-ValuesUniform {
rename `x' `x'HomeCountry
}

rename CountryS HomeCountryS
rename ISOCode ISOCodeHome
save "$temp/kinship.dta", replace 

use "$cleveldta/1.Kinship.dta",clear

* Removing "Std"
rename *Std *

keep CountryS ISOCode Year ///
GPSNegRecipHonor GPSPunishOthers GPSPunishRevenge ///
TrustDiffOutIn TrustDiffFamilyOthers TrustOtherNat ///
KinshipScore ValuesUniform


* updated variable names (12th August 2020): 
* TrustOutIn  -> TrustDiffOutIn
* TrustFamily -> TrustDiffFamilyOthers

* Renaming TrustDiffFamilyOthers as the name is too long
rename TrustDiffFamilyOthers TrustDiffFamily

foreach x of varlist GPSNegRecipHonor-ValuesUniform {
rename `x' `x'HomeCountryM
}

rename CountryS HomeCountrySM
rename ISOCode ISOCodeHomeM

save "$temp/kinshipM.dta", replace 
