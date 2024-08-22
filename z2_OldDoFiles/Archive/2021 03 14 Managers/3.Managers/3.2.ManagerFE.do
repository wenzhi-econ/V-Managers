* This dofile estimates FE 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"


use "$Managersdta/Managers.dta", clear 

xtset IDlse YearMonth

*****************************************************
* FE details 
*****************************************************

*Largest connected set 
group2hdfe IDlse IDlseMHR, group(Group) largest(LConnected)
*a2group ,  individual(IDlse) unit(IDlseMHR) groupvar(Group)
keep if LConnected==1 // 97.35% of obs
* There are 1125 mobility groups. (50,218 observations deleted)
save "$Managers/dta/Temp/FEConnected.dta", replace 

use "$Managers/dta/Temp/FEConnected.dta", clear

*How many employees? 
distinct IDlse //  172613
* IDlse x YearMonth =   7667416
*How many managers? 
distinct IDlseMHR // 39822

use "$Managersdta/Managers.dta", clear 

********************************************************************************
* FE estimation 
********************************************************************************

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYear

* Estimate managers FE  
*PAY
reghdfe LogPayBonus if BC ==0 , a( MFEPayWC = IDlseMHR EFEPayWC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
reghdfe LogPayBonus if BC ==1 , a( MFEPayBC = IDlseMHR EFEPayBC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
*CHANGE IN SALARY GRADE 
reghdfe ChangeSalaryGradeC if BC ==0 & , a( MFESGWC = IDlseMHR EFESGWC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
reghdfe ChangeSalaryGradeC if BC ==1 , a( MFESGBC = IDlseMHR EFESGBC= IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

keep MFEPayWC MFEPayBC MFESGWC MFESGBC  EFEPayWC  EFEPayBC EFESGWC EFESGBC IDlse IDlseMHR
save "$Managersdta/Temp/FE.dta", replace 

* Manager FE
use "$Managersdta/Temp/FE.dta", clear 
collapse MFEPayWC MFEPayBC MFESGWC MFESGBC  , by(IDlseMHR)
egen MFEPayWCZ = std(MFEPayWC)
egen MFEPayBCZ = std(MFEPayBC)
egen MFESGWCZ = std(MFESGWC)
egen MFESGBCZ = std(MFESGBC)
tw hist MFEPayWCZ if MFEPayWCZ<5 & MFEPayWCZ>-5 , fraction color(teal%60)   xtitle(Manager VA in log pay) || hist MFEPayBCZ if MFEPayBCZ<5 & MFEPayBCZ>-5 , fraction color(ebblue%60)  xtitle(Manager VA in log pay) legend(label(1 "WC") label(2 "BC") )
graph export "$Results/3.2.ManagerReg/histMFEPay.png", replace

tw hist MFESGWCZ if MFESGWCZ<5 & MFESGWCZ>-5, fraction color(teal%60)   xtitle(Manager VA in salary grade) || hist MFESGBCZ if MFESGBCZ<5 & MFESGBCZ>-5, fraction color(ebblue%60)  xtitle(Manager VA in salary grade) legend(label(1 "WC") label(2 "BC") )
graph export "$Results/3.2.ManagerReg/histMFESG.png", replace
save "$Managersdta/MFE.dta", replace 

* Employee FE 
use "$Managersdta/Temp/FE.dta", clear 
preserve 
collapse EFEPayWC  EFEPayBC  EFESGWC EFESGBC, by(IDlse)
save "$Managersdta/EFEPay.dta", replace 
restore 

* We have NAM
use "$Managersdta/Temp/FE.dta", replace 
collapse MFEPayWC MFEPayBC EFEPayWC  EFEPayBC, by(IDlse IDlseMHR)

*Standardize for interpretation
egen MFEPayWCZ = std(MFEPayWC)
egen MFEPayBCZ = std(MFEPayBC)
egen EFEPayWCZ = std(EFEPayWC)
egen EFEPayBCZ = std(EFEPayBC)
egen MFESGWCZ = std(MFESGWC)
egen MFESGBCZ = std(MFESGBC)
egen EFESGWCZ = std(EFESGWC)
egen EFESGBCZ = std(EFESGBC)

reg MFEPayWCZ EFEPayWCZ
reg MFEPayBCZ EFEPayBCZ

reg MFESGWCZ EFESGWCZ
reg MFESGBCZ EFESGBCZ


