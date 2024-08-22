* This do file looks at salary data 
* Gender: gender wage inequality, computes gender wage gap etc

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

********************************************************************************
* 1. Salary Data
********************************************************************************


do "$analysis/DoFiles/GenderClean.do" // clean data and gen variables


********************************************************************************
* 1. Organization Descriptives
********************************************************************************

*histogram WL if Year ==2017 & BC==0, by(Cluster, legend(off)) discrete percent fcolor(navy) lcolor(navy) horizontal addlabel ylabel(1(1)6)  xlabel(0(20)100)  legend(off)
tabplot WL if Year ==2017 & BC==0, by(Cluster)   fcolor(navy) lcolor(navy) horizontal showval percent(Cluster)
graph save  "$analysis/Figures/AdaptAdopt/Org/HistWL", replace
graph export  "$analysis/Figures/AdaptAdopt/Org/HistWL.png", replace


reg LogPayEX    i.Year i.Func i.WL i.EmployeeType i.BC i.Female 
*CONTROL FOR TENURE! i.Tenure not in dataset 
predict LogPayEXRes, res

collapse LogPayEXRes, by(Country ISOCode)


merge 1:1 ISOCode using "$analysis/Figures/CountriesMap/CountriesMap.dta", keepusing(CountryId)
*keep if _merge==3 // all merged but Hong Kong which is not in the map
drop _merge
format LogPayEXRes  %4.2f

*  colorpalette: hcl, blues / hcl, greens / hcl, oranges / hcl, purples / hcl, heat / hcl, plasma
spmap LogPayEXRes using "$analysis/Figures/CountriesMap/Coord.dta" , id(CountryId) fcolor(YlGnBu) clnumber(9) ///
title( "Annual Pay (US $)", size(huge) margin(medium))
*title( "Annual Pay (PPP adjusted)", size(huge) margin(medium))

graph save  "$analysis/Figures/AdaptAdopt/CountriesMap/EXPay", replace
graph export  "$analysis/Figures/AdaptAdopt/CountriesMap/EXPay.png", replace

*BY WL
do "$analysis/DoFiles/GenderClean.do" // clean data and gen variables

reg LogPayEX    i.Year i.Func i.EmployeeType i.BC i.Female 
*CONTROL FOR TENURE! i.Tenure not in dataset 
capture drop LogPayEXRes
predict LogPayEXRes, res

collapse LogPayEXRes, by(Country ISOCode WL)


*keep if _merge==3 // all merged but Hong Kong which is not in the map

levelsof WL
foreach i in `r(levels)'{
preserve 
keep  if WL==`i'
merge m:1 ISOCode using "$analysis/Figures/CountriesMap/CountriesMap.dta", keepusing(CountryId)
format LogPayEXRes %4.2f
*  colorpalette: hcl, blues / hcl, greens / hcl, oranges / hcl, purples / hcl, heat / hcl, plasma
spmap LogPayEXRes using "$analysis/Figures/CountriesMap/Coord.dta", id(CountryId) fcolor(YlGnBu) clnumber(9) ///
title( "Annual Pay (US $) WL `i'", size(huge) margin(medium))
*title( "Annual Pay (PPP adjusted) WL `i'", size(huge) margin(medium))
graph save  "$analysis/Figures/AdaptAdopt/CountriesMap/EXPayWL`i'", replace
graph export  "$analysis/Figures/AdaptAdopt/CountriesMap/EXPayWL`i'.png", replace
restore
}



********************************************************************************
* Inequality - CV
********************************************************************************

reg LogPay  i.Year i.Func i.WL i.EmployeeType i.BC i.Female
predict LogPayR, res

by Country, sort: egen LogPayRSD = sd(LogPayR) 
by Country, sort: egen LogPayRMean = mean(LogPayR) 
gen LogPayRMeanAbs = abs(LogPayRMean)
gen LogPayRCV = LogPayRSD/LogPayRMeanAbs


collapse LogPayRCV, by(Country ISOCode)


merge 1:1 ISOCode using "$analysis/Figures/CountriesMap/CountriesMap.dta", keepusing(CountryId)
*keep if _merge==3 // all merged but Hong Kong which is not in the map
drop _merge
format LogPayRCV %4.2f

*  colorpalette: hcl, blues / hcl, greens / hcl, oranges / hcl, purples / hcl, heat / hcl, plasma
spmap LogPayRCV using Coord , id(CountryId) fcolor(YlGnBu) clnumber(9) ///
title("Coefficient of Variation in Annual Pay", size(huge) margin(medium))
graph save  "$analysis/Figures/AdaptAdopt/CountriesMap/CVPay", replace
graph export  "$analysis/Figures/AdaptAdopt/CountriesMap/CVPay.png", replace

********************************************************************************
* Inequality  measures within the firm - GINI, P90P10, P75P25
********************************************************************************

* Separately by WL Function
reg AnnualPayProRated  i.Year
predict AnnualPayProRatedR, res 
egen CountryWLF = group(Country WL Func)
*ineqdeco LogPay, by(CountryWL)

gen GINIWLF = .     
gen p90p10WLF = .
gen p75p25WLF = .
gen p25p50WLF = .
gen p10p50WLF= . 
gen p90p50WLF = .
gen p75p50WLF = .
                          
levels CountryWLF, local(levels) 
foreach i of local levels { 
	ineqdec0 AnnualPayProRatedR   if CountryWLF == `i'
      replace GINIWLF = $S_gini if CountryWLF == `i' 
	   replace p90p10WLF = $S_9010  if CountryWLF == `i' 
	  replace p75p25WLF = $S_7525  if CountryWLF == `i' 
} 

graph hbar (mean) GINIWLF , over(Cluster,sort(1) ) over(WL)  scale(*.5) 
graph hbar (mean) GINIWLF if CountryInd==1, over(Country,sort(1) ) over(WL)  scale(*.3) 
graph hbar (mean)  p90p10WLF if CountryInd==1, over(Country,sort(1) ) over(WL)  scale(*.3) 

* By Country 
reg AnnualPayProRated  i.WL i.Func i.Year
capture drop AnnualPayProRatedR
predict AnnualPayProRatedR, res 
*ineqdeco LogPay, by(CountryWL)

gen GINI = .     
gen p90p10 = .
gen p75p25 = .
gen p25p50 = .
gen p10p50= . 
gen p90p50 = .
gen p75p50 = .
                          
levels Country, local(levels) 
foreach i of local levels { 
	ineqdec0 AnnualPayProRatedR   if Country == `i'
      replace GINI = $S_gini if Country== `i' 
	   replace p90p10 = $S_9010  if Country == `i' 
	  replace p75p25 = $S_7525  if Country == `i' 
} 

graph hbar (mean) GINI , over(Cluster,sort(1) ) over(WL)  scale(*.5) 
graph hbar (mean) GINI if CountryInd==1, over(Country,sort(1) ) over(WL)  scale(*.3) 
graph hbar (mean)  p90p10 if CountryInd==1, over(Country,sort(1) ) over(WL)  scale(*.3) 


kdensity AnnualPayProRatedR, nograph generate(x fx) 
kdensity AnnualPayProRatedR  if CountryS=="United Kingdom", nograph generate(fx0) at(x) 
kdensity AnnualPayProRatedR  if CountryS=="United States of America", nograph generate(fx1) at(x) 
kdensity AnnualPayProRatedR  if CountryS=="India", nograph generate(fx2) at(x) 
kdensity AnnualPayProRatedR  if CountryS=="Brazil", nograph generate(fx3) at(x) 
label var fx0 "Domestic cars" . label var fx1 "Foreign cars" 
line fx0 fx1 fx2 fx3 x, sort ytitle(Density)



* 1) Country Map 

merge 1:1 ISOCode using "$analysis/Figures/AdaptAdopt/CountriesMap/CountriesMap.dta", keepusing(CountryId)
*keep if _merge==3 // all merged but Hong Kong which is not in the map
drop _merge
*format female %4.2f
cd "$analysis/Figures/AdaptAdopt/CountriesMap"

*  colorpalette: hcl, blues / hcl, greens / hcl, oranges / hcl, purples / hcl, heat / hcl, plasma
spmap GINI using Coord , id(CountryId) fcolor(YlGnBu) clnumber(9) ///
title("GINI Index", size(huge) margin(medium))
graph save  "$analysis/Figures/AdaptAdopt/CountriesMap/GINI", replace
graph export  "$analysis/Figures/AdaptAdopt/CountriesMap/GINI.png", replace


do "$analysis/DoFiles/GenderClean.do" // clean data and gen variables


* 2) Gini index against power distance
* label(labsize(small))) ylabel(,labsize(small))

by Country WL Func: egen AnnualPayProRated = mean(AnnualPayProRated)
gen AnnualPayProRatedCV=r(sd)/r(mean) 

********************************************************************************
* GLOBE data ( power distance, collectivism)
********************************************************************************

/*
Power distance: The extent to which the community accepts and endorses authority, power differences, and status privileges
Performance orientation: The degree to which a collective encourages and rewards group members for performance improvement and excellence
Collectivism: The degree to which organizational and societal institutional practices encourage and reward collective distribution of resources and collective action
*/
merge m:1 CountryS using "$dropbox/dta/CountryLevel/GLOBE/GLOBE_societal.dta"

drop if _merge==2
drop _merge

* Relationship btw AnnualPayPPPsd and collectivism/power distance 



global dependent AnnualPayProRatedsd
global independent PowerDistanceSocietalValues PowerDistanceSocietalPractice CollectivismISocietalValues CollectivismISocietalPractice  PerformanceOrientationSocietal
global control  i.Gender Age Age2 i.Year i.WL i.PartTime i.BC i.EmployeeType i.Func CountrySize
foreach indep in $independent{
binscatter $dependent  `indep',  med control($control)
graph export "$analysis/Figures/bin_`indep'.png", replace
}

* BIN= COUNTRY 
reg $dependent $control , robust 
predict y, res 

preserve 
collapse y $independent CountrySize  , by(ISOCode Gender)

*bys iso_country_code : su span_control no_offices size_country PowerDistanceSocietalValues CollectivismISocietalValues
*texsave using "tab.tex", title(Summary Stats)


foreach indep in $independent {

reg y `indep'  [aw=CountrySize ]
local beta `=round(_b[`indep'], .001)'
local stder `=round(_se[`indep'], .001)'
local tstat = _b[`indep']/_se[`indep']
local pval = `=round(2*(ttail(e(df_r),abs(`tstat'))), .001)'


graph twoway (lfit y `indep' [aw=CountrySize]) ///
(scatter y `indep' [aw=CountrySize], msymbol(circle_hollow) ) ///
|| (scatter  y `indep' [aw=CountrySize], msymbol(i) mlabel(ISOCode)) ||, ///
legend(off) xtitle("`indep'") ///
note("Beta of fitted line = `beta' (SE = `stder'; p = `pval')", size(vsmall))
graph export "$analysis/Figures/scatter_`indep'.png", replace
}
}

restore 




********************************************************************************
* GINI ( power distance, collectivism)
********************************************************************************
do "$analysis/DoFiles/GenderClean.do" // clean data and gen variables

bys Country WL Func Year: egen AnnualPayProRatedM = mean(AnnualPayProRated)
capture drop AnnualPayProRatedsd
bys Country WL Func Year: egen AnnualPayProRatedsd = sd(AnnualPayProRated)

gen AnnualPayProRatedCV=AnnualPayProRatedsd/AnnualPayProRatedM

collapse AnnualPayProRatedCV, by(CountryS ISOCode Year )
merge 1:1 CountryS Year using "$dropbox/dta/CountryLevel/dta/WB/Gini/Gini.dta"
keep if _merge ==3 
drop _merge 
drop if CountryS=="Germany"
drop if AnnualPayProRatedCV>3
binscatter AnnualPayProRatedCV Gini
twoway scatter AnnualPayProRatedCV Gini, mlabel(ISOCode) msymbol(Oh) mcolor(blue) mlabcolor(blue) || lfit AnnualPayProRatedCV Gini, ///
yscale(range(0 2)) lcolor(red) ytitle(Annual Pay CV) legend(off) title(Firm Pay Inequality and Country Gini Index )
graph save "$analysis/Figures/AdaptAdopt/Inequality/Gini", replace
graph export "$analysis/Figures/AdaptAdopt/Inequality/Gini.png", replace

* P90/P10
do "$analysis/DoFiles/GenderClean.do" // clean data and gen variables

gen p90p10=0
levels Country, local(levels) 
levels Func, local(Flevels) 
foreach i of local levels { 
foreach j of local Flevels { 
centile AnnualPayProRated if Country==`i' & Func ==`j' , centile(10 50 90)
replace p90p10 = `r(c_3)'/`r(c_1)' if Country==`i' & Func ==`j'
}
}

collapse p90p10, by(Country CountryS ISOCode Func)
save "$analysis/Temp/p90p10.dta", replace

use "$dropbox/dta/CountryLevel/dta/WB/Gini/Gini.dta", clear 
keep if Year >=2015
bys CountryS: egen GiniAv=mean(Gini)
keep if Year == 2017
drop Year Gini
save "$analysis/Temp/GiniAv.dta", replace

use "$analysis/Temp/p90p10.dta", clear
bys CountryS: egen p90p10Av=mean(p90p10)
bysort CountryS: keep if _n==1
merge 1:1 CountryS using "$analysis/Temp/GiniAv.dta" 
keep if _merge ==3
drop _merge 
drop if CountryS=="Germany"
drop if CountryS=="Colombia"
drop if CountryS=="Vietnam"
drop if CountryS =="Dominican Republic"
drop if CountryS =="Ethiopia"

keep if p90p10<=200
binscatter p90p10 GiniAv, by(Func)

twoway scatter p90p10 GiniAv, mlabel(ISOCode) msymbol(Oh) mcolor(blue) mlabcolor(blue) || lfit p90p10 GiniAv, lcolor(red) ytitle(p90p10 ratio in pay) legend(off) title(Firm P90P10 ratio and Country Gini Index )
graph save "$analysis/Figures/AdaptAdopt/Inequality/p90p10", replace
graph export "$analysis/Figures/AdaptAdopt/Inequality/p90p10.png", replace

collapse p90p10, by(CountryS ISOCode Function )


