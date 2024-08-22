* COUNTERFACTUAL: WHAT WOULD HAPPEN IF THE SHARE OF GOOD MANAGERS GOES TO 100? 
* Gain: worker productivity
* Cost: managers' wages
* What are the productivity losses of bad managers? - is the share of good managers optimal conditional
* on the firm production function? 
* Consider a counterfactual scenario where the firm only has good managers 
***************** ***************** ***************** ***************** 

* FIRST GET THE VARIATION IN SHARE OF GOOD MANAGERS 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

bys OfficeCode YearMonth: egen OfficeSize = count(IDlse)

* managers only
keep if WL ==2 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/mList.dta" // making sure they are mostly managers 
keep if _merge ==3 

collapse EarlyAge  , by(OfficeCode OfficeSize  YearMonth   Country ISOCode)
drop if OfficeCode==.
isid OfficeCode  YearMonth

hist EarlyAge if YearMonth ==tm(2019m12), frac xtitle(Share of high-flyer managers)  
hist EarlyAge if YearMonth ==tm(2020m12), frac xtitle(Share of high-flyer managers)  
hist EarlyAge if YearMonth ==tm(2021m12) & OfficeSize>40,  frac xtitle(Office share of high-flyer managers, size(medium)) ytitle(Fraction,size(medium) ) xlabel(0(0.1)1) width(0.05)   // width(0.01)   
graph export "$analysis/Results/5.Mechanisms/HFShareOffice.png", replace


* SC productivity 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 
merge m:1 OfficeCode Year using "${user}/Data/Productivity/SC Data/TonsperFTE.dta", keepusing(PC HC FR TotBigC  TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)
keep if _merge==3

gen MShare = WL>=2 if WL!=.
gen o =1 
collapse EarlyAge EarlyAgeM MShare TotBigC PC HC FR TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC (sum) OfficeSizeWC=o , by(OfficeCode Year ISOCode)

reghdfe TonsperFTEMean  EarlyAgeM, a(Year ISOCode)
reghdfe TonsperFTETotal  EarlyAgeM OfficeSizeWC, a(Year  ISOCode )

binscatter TonsperFTETotal  EarlyAgeM, absorb(ISOCode) controls(i.Year OfficeSizeWC)
binscatter TonsperFTETotal  EarlyAgeM,  controls(i.Year OfficeSizeWC)

* firm profits: revenue - cost 
********************************************************************************

* FAST TRACK MANAGERS WAGE GAP 
* wages per year 

use "$managersdta/Temp/MType.dta", clear 

gen PayBonusM  = exp(LogPayBonusM )
bys IDlseMHR: egen MaxW = max(PayBonusM )
egen oo = tag(IDlseMHR)
bys EarlyAgeM: su MaxW if oo==1, d  

* Wage gap of fast track manager over manager time span at the firm 
reghdfe LogPayBonusM EarlyAgeM if WLM>1 & WLM!=. , a(CountryM Year FuncM  AgeBandM TenureM##FemaleM) cluster(IDlseMHR) // 26% 

reghdfe PayBonusM EarlyAgeM if WLM>1 & WLM!=. , a(CountryM Year FuncM  AgeBandM TenureM##FemaleM) cluster(IDlseMHR) // 55,644.48

* costs of managers 
di 7658* 55644.48
di 21432

bys EarlyAgeM: su PayBonusM if Year==2019, d  

* WORKERS PRODUCTIVITY GAP UNDER GOOD MANAGERS

* compare workers earnings and managers earnings? 
use "$managersdta/SwitchersAllSameTeam2.dta", clear 

keep 
