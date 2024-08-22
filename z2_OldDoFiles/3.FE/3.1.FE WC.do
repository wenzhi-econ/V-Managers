* This dofile estimates manager and employee FE 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

*****************************************************
* Durbin Wu Hausman test 
* Null hypothesis is rhttp://rizaudinsahlan.blogspot.com/2017/05/fixed-effects-fe-vs-random-effects-re.htmlandom effects model 
*****************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth

keep if LogPayBonus!=. 
keep LogPayBonus Tenure TenureM AgeBand AgeBandM CountryYM IDlse IDlseMHR YearMonth
gen Year = year( dofm(YearMonth))
* with both worker and manager fe 
local covariates c.Tenure##c.Tenure c.TenureM##c.TenureM  i.AgeBand i.AgeBandM
eststo re: mixed LogPayBonus `covariates' i.Year || IDlse: || IDlseMHR: // IDlse & IDlseMHR has random effects 
eststo fe: reghdfe LogPayBonus `covariates' , a(IDlse IDlseMHR i.Year)

* Only with worker fe & no clustering
eststo re: xtreg LogPayBonus  c.Tenure##c.Tenure c.TenureM##c.TenureM i.Year i.AgeBand i.AgeBandM ,  re
eststo fe: xtreg LogPayBonus  c.Tenure##c.Tenure c.TenureM##c.TenureM i.Year  i.AgeBand i.AgeBandM ,  fe
hausman fe re, sigmamore
* rejects H0 

*https://twitter.com/instrumenthull/status/1070089198798032899

/* To get random effects estimates : 
xtreg ..., re
predict ..., u
*/


*****************************************************
* Summary stats table  - number of movers 
*****************************************************
use "$managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth

su PromWLC Leaver LogPayBonus 
distinct IDlse
distinct IDlse if LogPayBonus !=.
distinct IDlseMHR
distinct IDlseMHR if LogPayBonus !=.

distinct IDlse if ChangeM ==1
distinct IDlse if ChangeM ==1 & LogPayBonus !=.

collapse (sum) ChangeM (mean) TeamSize, by(IDlseMHR)
su ChangeM

/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
     ChangeM |     42,745    11.04634    18.95975          0        548
*/
su TeamSize
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    TeamSize |     42,745    4.340195    25.81607          0   5027.882


* add one since we subtracted 2 from teamsize initially
*/

*****************************************************
* FE details 
*****************************************************


use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth
*Largest connected set 
group2hdfe IDlse IDlseMHR, group(Group) largest(LConnected)
*a2group ,  individual(IDlse) unit(IDlseMHR) groupvar(Group)
keep if LConnected==1 //  99.47% of obs (in the largest mobility group)
* There are 1431 mobility groups. (50,218 observations deleted)
distinct IDlse //  202099
distinct IDlseMHR // 41254
distinct IDlse if LogPayBonus!=. //  123867
distinct IDlseMHR if LogPayBonus!=. //   28432

save "$managersdta/FEConnected.dta", replace 

use "$analysis/Results/3.FE/FEConnected.dta", clear

*How many employees? 
distinct IDlse //  172613
* IDlse x YearMonth =   7667416
*How many managers? 
distinct IDlseMHR // 39822

use "$managersdta/AllSnapshotMCulture.dta", clear 

********************************************************************************
* FE estimation 
********************************************************************************

egen TenureBand = cut(Tenure), group(10)
egen TenureBandM = cut(TenureM), group(10)

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYM

* Estimate managers FE  
*PAY
reghdfe LogPayBonus if BC ==0 , a( MFEPayWC = IDlseMHR EFEPayWC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*reghdfe LogPayBonus if BC ==1 , a( MFEPayBC = IDlseMHR EFEPayBC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*CHANGE IN PROM
reghdfe PromWLC if BC ==0  , a( MFEPromWC = IDlseMHR EFEPromWC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*reghdfe PromWLC if BC ==1 , a( MFESGBC = IDlseMHR EFESGBC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*CHANGE IN TRANSFER
reghdfe TransferInternalC if BC ==0  , a( MFETrWC = IDlseMHR EFETrWC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*reghdfe TransferInternalC if BC ==1 , a( MFESGBC = IDlseMHR EFESGBC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*EXIT
reghdfe Leaver if BC ==0  , a( MFELeaverWC = IDlseMHR $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*reghdfe Leaver if BC ==1 , a( MFESGBC = IDlseMHR  $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

keep MFEPayWC MFEPromWC MFETrWC MFELeaverWC EFEPayWC EFEPromWC  EFETrWC IDlse IDlseMHR
*MFEPayBC  MFESGBC   EFEPayBC  EFESGBC 
save "$analysis/Results/3.FE/FE.dta", replace 

* Manager FE
use "$analysis/Results/3.FE/FE.dta", clear 
collapse MFEPayWC MFEPromWC MFETrWC MFELeaverWC , by(IDlseMHR)
egen MFEPayWCZ = std(MFEPayWC)
egen MFEPromWCZ = std(MFEPromWC)
egen MFETrWCZ = std(MFETrWC)
egen MFELeaverWCZ = std(MFELeaverWC)

winsor2 MFEPayWCZ , trim cuts(2.5 99) suffix(T)
winsor2 MFEPromWCZ , trim cuts(1 95) suffix(T)
winsor2 MFELeaverWCZ , trim cuts(1 99) suffix(T)
winsor2 MFETrWCZ , trim cuts(1 99) suffix(T)
drop if IDlseMHR ==.

pwcorr MFELeaverWCZT MFEPayWCZT MFEPromWCZT  MFETrWCZT 
save "$analysis/Results/3.FE/MFE.dta", replace 

hist MFEPayWCZT, fraction    xtitle(Manager VA in log pay) 
graph export "$analysis/Results/3.FE/histMFEPay.png", replace

hist MFEPromWCZT  , fraction    xtitle(Manager VA in promotions) 
graph export "$analysis/Results/3.FE/histMFEProm.png", replace

hist MFELeaverWCZT  , fraction    xtitle(Manager VA in exits) 
graph export "$analysis/Results/3.FE/histMFELeaver.png", replace

 * color(teal%60)


* look at cross-country differences
use "$analysis/Results/3.FE/FE.dta", clear 
collapse MFEPayWC MFEPromWC MFETrWC MFELeaverWC , by(IDlseMHR)
egen MFEPayWCZ = std(MFEPayWC)
egen MFEPromWCZ = std(MFEPromWC)
egen MFETrWCZ = std(MFETrWC)
egen MFELeaverWCZ = std(MFELeaverWC)
winsor2 MFEPayWC , trim cuts(2.5 99) suffix(T)
winsor2 MFEPromWC , trim cuts(1 95) suffix(T)
winsor2 MFELeaverWC , trim cuts(1 99) suffix(T)

gen IDlse = IDlseMHR
merge 1:m IDlse using "$managersdta/AllSnapshotMCulture.dta"
keep if _merge ==3 
drop _merge 
bys IDlse: egen ISOCodeMode = mode(ISOCode) , maxmode
collapse  MFEPayWC MFEPromWC MFETrWC MFELeaverWC  MFEPayWCT MFEPromWCT MFELeaverWCT   , by(IDlse ISOCodeMode )

collapse MFEPayWC MFEPromWC MFETrWC MFELeaverWC  MFEPayWCT MFEPromWCT MFELeaverWCT , by(ISOCodeMode )

*graph bar MFEPayWC  , over(ISOCodeMode,  sort(1) label(angle(forty_five)))  ysize(2)

rename ISOCodeMode ISOCode
merge 1:1 ISOCode using "$analysis/Data/CountriesMap/CountriesMap.dta", keepusing(CountryId)
cd "$analysis/Data/CountriesMap"
spmap MFEPayWCT using Coord , id(CountryId) fcolor(Blues)  clnumber(5) legend(on) legend(size(medium) title(M VA in Pay)) 
gr export "$analysis/Results/3.FE/MapMFEPayWC.png", replace

spmap MFEPromWCT using Coord , id(CountryId) fcolor(Blues)  clnumber(5) legend(on) legend(size(medium) title(M VA in Prom)) 
gr export "$analysis/Results/3.FE/MapMFEPromWC.png", replace  

spmap MFELeaverWCT using Coord , id(CountryId) fcolor(Blues)  clnumber(5) legend(on) legend(size(medium) title(M VA in Exit)) 
gr export "$analysis/Results/3.FE/MapMFELeaverWC.png", replace  


* We have NAM
use "$analysis/Results/3.FE/FE.dta", replace 
collapse MFEPayWC MFEPromWC MFETrWC MFELeaverWC EFEPayWC EFEPromWC  EFETrWC, by(IDlse IDlseMHR)

*Standardize for interpretation
egen MFEPayWCZ = std(MFEPayWC)
egen MFEPromWCZ = std(MFEPromWC)
egen MFETrWCZ = std(MFETrWC)
egen EFEPayWCZ = std(EFEPayWC)
egen EFEPromWCZ = std(EFEPromWC)
egen EFETrWCZ = std(EFETrWC)

winsor2 MFEPayWCZ , trim cuts(2.5 99) suffix(T)
winsor2 EFEPayWCZ , trim cuts(2.5 99) suffix(T)
winsor2 MFEPromWCZ , trim cuts(2.5 99) suffix(T)
winsor2 EFEPromWCZ , trim cuts(2.5 99) suffix(T)
winsor2 MFETrWCZ , trim cuts(2.5 99) suffix(T)
winsor2 EFETrWCZ , trim cuts(2.5 99) suffix(T)

reg MFEPayWCZT EFEPayWCZT
*reg MFEPayBCZ EFEPayBCZ
reg MFEPromWCZT EFEPromWCZT
 reg MFEPromWCZT EFEPromWCZT if MFEPayWCZT !=.
reg MFETrWCZT EFETrWCZT
reg MFETrWCZT EFETrWCZT if MFEPayWCZT !=.


collapse EFEPayWC* EFEPromWC*  EFETrWC*, by(IDlse )
save "$analysis/Results/3.FE/EFE.dta", replace 


********************************************************************************
* VARIANCE OF FE - SPLIT SAMPLE APPROACH 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth

egen TenureBand = cut(Tenure), group(10)
egen TenureBandM = cut(TenureM), group(10)

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYM

reghdfe LogPayBonus if BC ==0  ,  a( $controlMacro  ) vce(cluster IDlseMHR) residuals
predict LogPayBonusR, res
su LogPayBonusR // 

merge m:1 IDlse using  "$analysis/Results/3.FE/EFE.dta"
drop _merge

merge m:1 IDlseMHR using "$analysis/Results/3.FE/MFE.dta"
drop _merge

egen group = group(IDlse IDlseMHR)

keep if LogPayBonus!=.
splitsample , cluster(group)  gen(Sample)  nsplit(2)

reghdfe LogPayBonus if BC ==0 & Sample==1 , a( MFEPayWCSS1 = IDlseMHR EFEPayWCSS1= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
reghdfe LogPayBonus if BC ==0  & Sample==2, a( MFEPayWCSS2 = IDlseMHR EFEPayWCSS2= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
reghdfe LogPayBonus if BC ==0  & Sample==1,  a( $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR) residuals
predict LogPayBonusR1 , res 
reghdfe LogPayBonus if BC ==0  & Sample==2,  a( $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR) residuals
predict LogPayBonusR2 , res 

gen LogPayBonus1 = (cond(Sample==1,LogPayBonus , .))
gen LogPayBonus2 = (cond(Sample==2,LogPayBonus , .))

keep IDlse IDlseMHR MFEPayWCSS1   EFEPayWCSS1 MFEPayWCSS2   EFEPayWCSS2  LogPayBonusR1  LogPayBonusR2 LogPayBonus1 LogPayBonus2 group Sample
compress 
save "$analysis/Results/3.FE/FESplitSample.dta", replace 

use "$analysis/Results/3.FE/FESplitSample.dta", clear 
gen o =1
collapse MFEPayWCSS1   EFEPayWCSS1 MFEPayWCSS2   EFEPayWCSS2  LogPayBonusR1  LogPayBonusR2 LogPayBonus1 LogPayBonus2 (sum) o, by(IDlse   )
drop if IDlse ==.
isid IDlse
egen sdEFE = rowsd( EFEPayWCSS1 EFEPayWCSS2)

su sdEFE //     .1472181  

su sdEFE [ iweight= o] // .13937 


use "$analysis/Results/3.FE/FESplitSample.dta", clear 
gen o =1
collapse MFEPayWCSS1   EFEPayWCSS1 MFEPayWCSS2   EFEPayWCSS2  LogPayBonusR1  LogPayBonusR2 LogPayBonus1 LogPayBonus2 (sum) o, by(IDlseMHR   )
drop if IDlseMHR ==.
isid IDlseMHR
egen sdMFE = rowsd( MFEPayWCSS1* MFEPayWCSS2)

su sdMFE // .1448056
su sdMFE [ iweight= o] // .1169299

********************************************************************************
* MFE Quartile plots 
********************************************************************************

use "$analysis/Results/3.FE/MFE.dta", clear 

winsor2 MFEPayWC , trim cuts(2.5 99) suffix(T)
su  MFEPayWCT,d 
xtile  MFEPayWCTQ = MFEPayWCT, nq(10)

xtile  MFEPayWCZTQ = MFEPayWCZT, nq(10)
collapse  MFEPayWCT, by( MFEPayWCTQ) 
tw line MFEPayWCT MFEPayWCTQ, xtitle(Manager Percentile) ytitle("% Effect on Pay") lwidth( thick   ) xlabel(1(1)10)

graph export "$analysis/Results/3.FE/MFEQ.png", replace 

 





