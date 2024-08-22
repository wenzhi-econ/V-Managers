********************************************************************************
* IMPORT DATASET 
********************************************************************************

use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
merge 1:1 IDlse YearMonth using  "$Managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

bys IDlse: egen t = max(ChangeM)
bys IDlse: egen a1 = max(IAM) // 22% 

bys IDlse: egen a = max(OutGroup)
ta a// 33% 

keep if a==1 
ta IAM DiffOffice

* For Sun & Abraham only consider first event 
bys IDlse: egen    Ei = min(cond(ChangeM==1, YearMonth ,.)) // for single differences 
replace ChangeM = 0 if YearMonth > Ei & ChangeM==1

foreach var in Ei  {
gen K`var' = YearMonth - `var'


gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}

}

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW

bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
local end= 30
local end = 20
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii

gen VPA100 = VPA>=100 if VPA!=.
gen VPA115 = VPA>=115 if VPA!=.
gen VPA125 = VPA>=125 if VPA!=.

reghdfe LogPayBonus CulturalDistance c.Tenure##c.Tenure  , a(IDlse Year AgeBand AgeBandM )
reghdfe LogPayBonus OutGroup##EarlyAgeM c.Tenure##c.Tenure  , a(IDlse Year AgeBand AgeBandM DiffOffice IDlseMHR  )
reghdfe LogPayBonus IAM##EarlyAgeM c.Tenure##c.Tenure  , a(IDlse Year AgeBand AgeBandM DiffOffice  )

reghdfe VPA125 IAM##EarlyAgeM c.Tenure##c.Tenure  , a(IDlse Year AgeBand AgeBandM DiffOffice  )

reghdfe ProductivityStd OutGroup c.Tenure##c.Tenure  , a(IDlse Year AgeBand AgeBandM DiffOffice  )

