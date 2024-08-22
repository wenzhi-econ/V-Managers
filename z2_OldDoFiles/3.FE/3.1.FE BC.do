* This dofile estimates manager and employee FE 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

use "$managersdta/AllSnapshotBCM.dta", clear 

xtset IDlse YearMonth

*****************************************************
* Summary stats table  - number of movers 
*****************************************************

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


use "$managersdta/AllSnapshotBCM.dta", clear 

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

save "$managersdta/FEConnectedBC.dta", replace 

use "$analysis/Results/3.FE/FEConnectedBC.dta", clear

*How many employees? 
distinct IDlse //  172613
* IDlse x YearMonth =   7667416
*How many managers? 
distinct IDlseMHR // 39822

use "$managersdta/AllSnapshotBCM.dta", clear 

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
reghdfe LogPayBonus if BC ==1 , a( MFEPayBC = IDlseMHR EFEPayBC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*CHANGE IN PROM
reghdfe PromWLC if BC ==1  , a( MFEPromBC = IDlseMHR EFEPromBC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*CHANGE IN TRANSFER
reghdfe TransferInternalC if BC ==1 , a( MFETrBC = IDlseMHR EFETrBC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

*EXIT
reghdfe Leaver if BC ==1  , a( MFELeaverBC = IDlseMHR $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

keep MFEPayBC MFEPromBC MFETrBC MFELeaverBC EFEPayBC EFEPromBC  EFETrBC IDlse IDlseMHR
*MFEPayBC  MFESGBC   EFEPayBC  EFESGBC 
save "$analysis/Results/3.FE/FEBC.dta", replace 

* Manager FE
use "$analysis/Results/3.FE/FEBC.dta", clear 
collapse MFEPayBC MFEPromBC MFETrBC MFELeaverBC , by(IDlseMHR)
egen MFEPayBCZ = std(MFEPayBC)
egen MFEPromBCZ = std(MFEPromBC)
egen MFETrBCZ = std(MFETrBC)
egen MFELeaverBCZ = std(MFELeaverBC)

winsor2 MFEPayBCZ , trim cuts(2.5 99) suffix(T)
winsor2 MFEPromBCZ , trim cuts(1 95) suffix(T)
winsor2 MFELeaverBCZ , trim cuts(1 99) suffix(T)
winsor2 MFETrBCZ , trim cuts(1 99) suffix(T)
drop if IDlseMHR ==. 
save "$analysis/Results/3.FE/MFEBC.dta", replace 

hist MFEPayBCZT, fraction    xtitle(Manager VA in log pay) 
graph export "$analysis/Results/3.FE/histMFEPayBC.png", replace

hist MFETrBCZT  , fraction    xtitle(Manager VA in transfers) 
graph export "$analysis/Results/3.FE/histMFETrBC.png", replace

hist MFELeaverBCZT  , fraction    xtitle(Manager VA in exits) 
graph export "$analysis/Results/3.FE/histMFELeaverBC.png", replace

* color(teal%60)

* look at cross-country differences
use "$analysis/Results/3.FE/FEBC.dta", clear 
collapse MFEPayBC MFEPromBC MFETrBC MFELeaverBC , by(IDlseMHR)
egen MFEPayBCZ = std(MFEPayBC)
egen MFEPromBCZ = std(MFEPromBC)
egen MFETrBCZ = std(MFETrBC)
egen MFELeaverBCZ = std(MFELeaverBC)
winsor2 MFEPayBCZ , trim cuts(2.5 99) suffix(T)
winsor2 MFEPromBCZ , trim cuts(1 95) suffix(T)
winsor2 MFELeaverBCZ , trim cuts(1 99) suffix(T)
winsor2 MFETrBCZ , trim cuts(1 99) suffix(T)

pwcorr  MFEPayBCZT  MFELeaverBCZT MFETrBCZT

gen IDlse = IDlseMHR
merge 1:m IDlse using "$managersdta/AllSnapshotBCM.dta"
keep if _merge ==3 
drop _merge 
bys IDlse: egen ISOCodeMode = mode(ISOCode) , maxmode
collapse  MFEPayBC MFEPromBC MFETrBC MFELeaverBC  MFEPayBCZT MFEPromBCZT MFELeaverBCZT MFETrBCZT  , by(IDlse ISOCodeMode )

collapse MFEPayBC MFEPromBC MFETrBC MFELeaverBC  MFEPayBCZT MFEPromBCZT MFELeaverBCZT MFETrBCZT  , by(ISOCodeMode )

*graph bar MFEPayBC  , over(ISOCodeMode,  sort(1) label(angle(forty_five)))  ysize(2)

rename ISOCodeMode ISOCode
merge 1:1 ISOCode using "$analysis/Data/CountriesMap/CountriesMap.dta", keepusing(CountryId)
cd "$analysis/Data/CountriesMap"
spmap MFEPayBCZT using Coord , id(CountryId) fcolor(Blues)  clnumber(5) legend(on) legend(size(medium) title(M VA in Pay)) 
gr export "$analysis/Results/3.FE/MapMFEPayBC.png", replace

spmap MFETrBCZT using Coord , id(CountryId) fcolor(Blues)  clnumber(5) legend(on) legend(size(medium) title(M VA in Transfers)) 
gr export "$analysis/Results/3.FE/MapMFETrBC.png", replace  

spmap MFELeaverBCZT using Coord , id(CountryId) fcolor(Blues)  clnumber(5) legend(on) legend(size(medium) title(M VA in Exit)) 
gr export "$analysis/Results/3.FE/MapMFELeaverBC.png", replace  


* We have NAM?
use "$analysis/Results/3.FE/FEBC.dta", replace 
collapse MFEPayBC MFEPromBC MFETrBC MFELeaverBC EFEPayBC EFEPromBC  EFETrBC, by(IDlse IDlseMHR)

*Standardize for interpretation
egen MFEPayBCZ = std(MFEPayBC)
egen MFETrBCZ = std(MFETrBC)
egen EFEPayBCZ = std(EFEPayBC)
egen EFETrBCZ = std(EFETrBC)

winsor2 MFEPayBCZ , trim cuts(2.5 99) suffix(T)
winsor2 EFEPayBCZ , trim cuts(2.5 99) suffix(T)
winsor2 MFETrBCZ , trim cuts(2.5 99) suffix(T)
winsor2 EFETrBCZ , trim cuts(2.5 99) suffix(T)

reg MFEPayBCZT EFEPayBCZT
reg MFETrBCZT EFETrBCZT
reg MFETrBCZT EFETrBCZT if EFEPayBCZT!=.

*reg MFEPayBCZ EFEPayBCZ

collapse EFEPayBC* EFEPromBC*  EFETrBC*, by(IDlse )
save "$analysis/Results/3.FE/EFEBC.dta", replace 


********************************************************************************
* VARIANCE OF FE - SPLIT SAMPLE APPROACH 
********************************************************************************

use "$managersdta/AllSnapshotBCM.dta", clear 

xtset IDlse YearMonth

egen TenureBand = cut(Tenure), group(10)
egen TenureBandM = cut(TenureM), group(10)

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYM

reghdfe LogPayBonus if BC ==1  ,  a( $controlMacro  ) vce(cluster IDlseMHR) residuals
predict LogPayBonusR, res
su LogPayBonusR // SD= .4752964 
su LogPayBonus

merge m:1 IDlse using  "$analysis/Results/3.FE/EFEBC.dta"
drop _merge

merge m:1 IDlseMHR using "$analysis/Results/3.FE/MFEBC.dta"
drop _merge

egen group = group(IDlse IDlseMHR)

keep if LogPayBonus!=.
splitsample , cluster(group)  gen(Sample)  nsplit(2)

reghdfe LogPayBonus if BC ==1 & Sample==1 , a( MFEPayBCSS1 = IDlseMHR EFEPayBCSS1= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
reghdfe LogPayBonus if BC ==1  & Sample==2, a( MFEPayBCSS2 = IDlseMHR EFEPayBCSS2= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
reghdfe LogPayBonus if BC ==1  & Sample==1,  a( $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR) residuals
predict LogPayBonusR1 , res 
reghdfe LogPayBonus if BC ==1  & Sample==2,  a( $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR) residuals
predict LogPayBonusR2 , res 

gen LogPayBonus1 = (cond(Sample==1,LogPayBonus , .))
gen LogPayBonus2 = (cond(Sample==2,LogPayBonus , .))

keep IDlse IDlseMHR MFEPayBCSS1   EFEPayBCSS1 MFEPayBCSS2   EFEPayBCSS2  LogPayBonusR1  LogPayBonusR2 LogPayBonus1 LogPayBonus2 group Sample
compress 
save "$analysis/Results/3.FE/FESplitSampleBC.dta", replace 

use "$analysis/Results/3.FE/FESplitSampleBC.dta", clear 
gen o =1
collapse MFEPayBCSS1   EFEPayBCSS1 MFEPayBCSS2   EFEPayBCSS2  LogPayBonusR1  LogPayBonusR2 LogPayBonus1 LogPayBonus2 (sum) o, by(IDlse   )
drop if IDlse ==.
isid IDlse
egen sdEFE = rowsd(EFEPayBCSS1 EFEPayBCSS2)

su sdEFE //  .0946186 

su sdEFE  [ iweight= o]
* sdEFE  .090371 


use "$analysis/Results/3.FE/FESplitSampleBC.dta", clear 
gen o =1
collapse MFEPayBCSS1   EFEPayBCSS1 MFEPayBCSS2   EFEPayBCSS2  LogPayBonusR1  LogPayBonusR2 LogPayBonus1 LogPayBonus2 (sum) o, by(IDlseMHR   )
drop if IDlseMHR ==.
isid IDlseMHR
egen sdMFE = rowsd(MFEPayBCSS1 MFEPayBCSS2)


su sdMFE //    .1076041  
su sdMFE [ iweight= o] //   .0712031 

********************************************************************************
* MFE Quartile plots 
********************************************************************************

use "$analysis/Results/3.FE/MFEBC.dta", clear 

winsor2 MFEPayBC , trim cuts(2.5 99) suffix(T)
su  MFEPayBCT,d 
xtile  MFEPayBCTQ = MFEPayBCT, nq(10)

xtile  MFEPayBCZTQ = MFEPayBCZT, nq(10)
collapse  MFEPayBCT, by( MFEPayBCTQ) 
tw line MFEPayBCT MFEPayBCTQ, xtitle(Manager Percentile) ytitle("% Effect on Pay") lwidth( thick   ) xlabel(1(1)10)

graph export "$analysis/Results/3.FE/MFEBCQ.png", replace 

 





