* This do file creates productivity dta 

********************************************************************************
* Prepare dataset 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear

* Monthly *
merge 1:1 IDlse YearMonth using "$produc/dta/CDProductivityMonth" , keepusing(Productivity* ProdGroup File FreqMonth)
rename _merge _mergeMonth

* Quarterly (Italy IH only as of 9 June 2021) *
preserve
use "$produc/dta/CDProductivityQuarter", clear
keep if FreqQuarter==1
tempfile quarterly
save `quarterly'
restore

gen YearQuarter = qofd(dofm(YearMonth))
merge m:1 IDlse  YearQuarter using `quarterly', keepusing(Productivity* ProdGroup File FreqQuarter) update
drop if _merge==2
rename _merge =Quarter

* Yearly *
preserve
use "$produc/dta/CDProductivityYear", clear
keep if FreqYear==1
tempfile yearly
save `yearly'
restore

merge m:1 IDlse Year using `yearly', keepusing(Productivity* ProdGroup File FreqYear) update

keep if _mergeMonth == 3 | (_mergeQuarter >= 3 & _mergeQuarter<.) | (_merge >= 3 & _merge<.) // 5. merged with monthly/quarterly/yearly data
keep if Productivity!=. // 6. non-missing productivity data

/* Only monthly 

*merge m:1 IDlse Year using "$produc/dta/ProductivityYear.dta", keepusing(Productivity ProductivityStd)
merge 1:1 IDlse YearMonth using "$produc/dta/ProductivityMonth.dta", keepusing(Productivity ProductivityStd)
keep if _merge ==3 
drop _merge 
*/

* Channel FE
encode ProdGroup, gen(ChannelFE)
replace ChannelFE = 0 if ChannelFE==. // not specified when there is no variation within country
la de ChannelFE 0 "Not specified", modify
bys CountryS: egen x = sd(ChannelFE)
assert x == 0 if ChannelFE==0 // check that ChannelFE does not vary within country for "Not specified"
drop x

drop _merge 

compress
save "$managersdta/Temp/ProductivityManagers.dta", replace 