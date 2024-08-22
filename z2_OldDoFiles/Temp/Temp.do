**********************************************************************
* temp codes 
**********************************************************************

**********************************************************************
* MANAGER PDV 
**********************************************************************

use "$managersdta/Temp/MType.dta" , replace 
bys IDlseMHR: egen minWL = min(WLM)
reghdfe LogPayBonusM EarlyAgeM  if minWL==2, cluster(IDlseMHR) a( CountryM FuncM YearMonth)


use "$managersdta/AllSameTeam2.dta", clear 

gen Month = month(dofm(YearMonth))
bys IDlse: egen minWL = min(WLM)
su Tenure if minWL==2 | WL>1
di "`r(max)'"
egen TenureC = cut(Tenure),at(0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 63 )

egen TenureC2 = cut(Tenure),at(0 2 4 6 8 10 15 20 25 30 63 )

tab TenureC2, gen(t)

forval i=1/10{
	gen Ht`i'= EarlyAge*t`i'
	gen Lt`i'= (1-EarlyAge)*t`i'
}

global controls Country Func Year Month AgeBand Female 
reghdfe LogPayBonus EarlyAge##c.Tenure  if minWL==2 | WL>1, cluster(IDlse) a( $controls )
reghdfe LogPayBonus EarlyAge##c.Tenure  if minWL==2 | WL>1, cluster(IDlse) a( $controls WL )

reghdfe LogPayBonus EarlyAge##TenureC  if minWL==2 | WL>1, cluster(IDlse) a( $controls )
reghdfe LogPayBonus EarlyAge##TenureC2  if minWL==2 | WL>1, cluster(IDlse) a( $controls WL )

reghdfe LogPayBonus Ht* Lt2-Lt10 if minWL==2 | WL>1, cluster(IDlse) a( $controls )


reghdfe LogPayBonus EarlyAge##Tenure  if minWL==2 | WL>1, cluster(IDlse) a( $controls )




* Discount rate: 5% 
* CASE 1: Assume no effect after 5 years 
* CASE 2: Assume constant effect after 5 years 

* Here, restriction to WL2 
local l = 1.9 // after 5 years 
di 1.6 + 0.6/(1.05) +  1.5/(1.05)^2 + 1/(1.05)^3 + 1/(1.05)^4 +  1.9/(1.05)^5 + `l'/(1.05)^6 +  `l'/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 +   `l'/(1.05)^20
* 7% with no dynamic effects after 5 years 
* 22% with 1.9 dynamic effects after 5 years 




