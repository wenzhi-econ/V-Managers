* Densitites distributions of earnings by different events  

*use "$managersdta/AllSnapshotMCultureMType2015.dta", clear 
*use "/Users/virginiaminni/Desktop/Switchers.dta", clear 
use "$managersdta/SwitchersAllSameTeam2.dta", clear 

* BALANCED SAMPLE 
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-24 &  maxEi >=24
ta ii

gen ii2 = minEi <=-12 &  maxEi >=12
ta ii2

********************************************************************************
* Densities at different event windows 
********************************************************************************

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM IDlse  
global exitFE CountryYear AgeBand AgeBandM  Func Female

egen CountryFuncYear = group(Country Func Year)
egen CountryYear = group(Country Year)

* Delta 
xtset IDlse YearMonth 
foreach var in EarlyAgeM MFEBayesPromSG75{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
}

reghdfe  LogPayBonus c.Tenure##c.Tenure , a( Female AgeBand Country YearMonth Func  ) res(LogPayBonusR) // balanced sample -24 and +24
* FT Effective PromSG75 Female AgeBand CountryYear Func
local Label FT
forval i =-12(12)24{

tw kdensity LogPayBonusR if KEi==`i'  & `Label'LH!=. & WL2==1 || kdensity LogPayBonusR  if KEi==`i' & `Label'LL!=. & WL2==1, legend(label(1 "low to high") label(2 "low to low")) ///
ytitle("`i' months") xtitle("")
graph export "$Results/4.Event/PayDensity`i'`Label'LH.png", replace 
graph save "$Results/4.Event/PayDensity`i'`Label'LH.gph", replace 

tw kdensity LogPayBonusR if KEi==`i'  & `Label'HL!=. & WL2==1 || kdensity LogPayBonusR  if KEi==`i'  & `Label'HH!=. & WL2==1, legend(label(1 "high to low") label(2 "high to high")) ///
 ytitle("`i' months") xtitle("")
graph export "$Results/4.Event/PayDensity`i'`Label'HL.png", replace 
graph save "$Results/4.Event/PayDensity`i'`Label'HL.gph", replace 

graph combine "$Results/4.Event/PayDensity`i'`Label'LH.gph" "$Results/4.Event/PayDensity`i'`Label'HL.gph", ycomm xcomm title("Pay + bonus (logs), `i' months since manager change")
graph export "$Results/4.Event/PayDensity`i'`Label'.png", replace 
}

local Label FT

graph combine "$Results/4.Event/PayDensity-12`Label'LH.gph" "$Results/4.Event/PayDensity24`Label'LH.gph", note("Notes. Pay+Bonus (logs), residualized on female, tenure, function country-year and age group") ycomm xcomm title("Pay + bonus (logs), months since manager change")
graph export "$Results/4.Event/PayDensity`Label'LH.png", replace 

graph combine "$Results/4.Event/PayDensity-12`Label'HL.gph" "$Results/4.Event/PayDensity24`Label'HL.gph",note("Notes. Pay+Bonus (logs), residualized on female, tenure, function country-year and age group") ycomm xcomm title("Pay + bonus (logs), months since manager change")
graph export "$Results/4.Event/PayDensity`Label'HL.png", replace 

********************************************************************************
* Shares  
********************************************************************************

use "/Users/virginiaminni/Desktop/Switchers.dta", clear 
*use "/Users/virginiaminni/Desktop/AllSample.dta", clear 

* BALANCED SAMPLE 
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-24 &  maxEi >=24
ta ii
gen ii2 = minEi <=-36 &  maxEi >=36
keep if ii==1

foreach v in ELH EHH ELL EHL {
bys IDlse: egen WLM2`v'0 = max(cond(K`v'==0 & WLM==2, 1 ,0)) // only those with manager wl 2
egen pool`v' = count(cond(K`v'==0 &WLM2`v'0==1 , IDlse,. ))

gen i`v'= (`v'!=. & WLM2`v'0==1)

gen  WL2`v' = (WL ==2 & i`v'==1)
gen  WL3`v' = (WL ==3 & i`v'==1)
gen WL4Agg`v' = (WL>=4 & i`v'==1)
}

ta WL if WLM2ELH0==1

collapse pool*  (sum) WL2* WL3* WL4Agg*, by(KEi )

foreach v in ELH EHH ELL EHL {
gen ShareWL2`v' = WL2`v'/pool`v'
gen ShareWL3`v' = WL3`v'/pool`v'
gen ShareWL4Agg`v' = WL4Agg`v'/pool`v'
}

tw connected ShareWL2ELH KEi if KEi <=20 & KEi>=-20, xlabel(-20(5)20) ||  connected ShareWL2ELL KEi if KEi <=20 & KEi>=-20

tw connected ShareWL3ELH KEi if KEi <=60 & KEi>=-60, xlabel(-60(5)60) ||  connected ShareWL3ELL KEi if KEi <=60 & KEi>=-60

tw connected ShareWL4AggELH KEi if KEi <=60 & KEi>=-60, xlabel(-60(5)60) ||  connected ShareWL4AggELL KEi if KEi <=60 & KEi>=-60
