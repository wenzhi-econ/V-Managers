* This do file estimates managers FE
* Commands: twfe felsdvreg (grouponly ) a2reg reg2hdfe reghdfe

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set maxvar 32767

use "$dta/AllSnapshotWCCultureC.dta", clear 

********************************************************************************
*  Select sample 
********************************************************************************

drop if FlagUFLP == 1 // not UFLP employees 
*keep if  EmpStatus == 7 & (EmpType==9 | EmpType== 12 | EmpType== 13 ) // regular employees 
* FTE == 1 

*Largest connected set 
group2hdfe IDlse IDlseMHR, group(Group) largest(LConnected)
*a2group ,  individual(IDlse) unit(IDlseMHR) groupvar(Group)
keep if LConnected==1 // 97.35% of obs
* There are 1125 mobility groups. (50,218 observations deleted)

* Macro-trends 
egen CountryYear = group(Country Year)

save "$Managers/dta/Temp/FEConnected.dta", replace 

use "$Managers/dta/Temp/FEConnected.dta", clear

*How many employees? 
distinct IDlse //  172613
* IDlse x YearMonth =   7667416
*How many managers? 
distinct IDlseMHR // 39822

*How many movers? 
sort IDlse YearMonth 
by IDlse: gen mover = IDlseMHR[1]!=IDlseMHR[_N] 
tab mover
distinct IDlse if mover ==1 //  120848 IDlse are movers out of 172613 (120848/ 172613= 70%)


********************************************************************************
*  FE Estimation 
********************************************************************************

* Leaver
use "$Managersdta/Temp/FEConnected.dta", clear
reghdfe LeaverPerm c.Tenure##c.Tenure##Female, absorb(MFELeaver=IDlseMHR  Func CountryYear AgeBand  EmpType EmpStatus ) cluster(IDlseMHR) 
keep IDlse IDlseMHR MFELeaver 
drop if IDlse==. | IDlseMHR==. | MFELeaver ==.

collapse MFELeaver, by(IDlseMHR)
save "$Full/Results/3.1.ManagerFE/LeaverMFE.dta", replace 

* LogPay
*drop if LogPayBonus ==. 
use "$Managersdta/Temp/FEConnected.dta", clear
reghdfe LogPayBonus c.Tenure##c.Tenure##Female, absorb(MFEPay=IDlseMHR EFEPay=IDlse Func CountryYear AgeBand EmpType EmpStatus  ) cluster(IDlseMHR) 

keep IDlse IDlseMHR MFEPay EFEPay 
drop if IDlse==. | IDlseMHR==.
collapse MFEPay EFEPay, by(IDlse IDlseMHR)
save "$Full/Results/3.1.ManagerFE/LogPayBonusFE.dta", replace 


* Promotion
use "$Managersdta/Temp/FEConnected.dta", clear
reghdfe PromSalaryGrade c.Tenure##c.Tenure##Female, absorb(MFEProm=IDlseMHR EFEProm=IDlse Func CountryYear AgeBand EmpType EmpStatus  ) cluster(IDlseMHR) 

keep IDlse IDlseMHR MFEProm EFEProm 
drop if IDlse==. | IDlseMHR==.
collapse MFEProm EFEProm, by(IDlse IDlseMHR)

* How many promotions? 
by IDlse (YearMonth), sort: gen PromCount = sum(PromSalaryGrade)
preserve 
collapse (max) PromCount, by(IDlse)
hist PromCount
su PromCount,d
save "$Full/Results/3.1.ManagerFE/PromFE.dta", replace

* VPA
use "$Managersdta/Temp/FEConnected.dta", clear
reghdfe LogVPA c.Tenure##c.Tenure##Female, absorb(MFEVPA=IDlseMHR EFEVPA=IDlse Func CountryYear AgeBand EmpType EmpStatus  ) cluster(IDlseMHR) 

keep IDlse IDlseMHR MFEVPA EFEVPA 
drop if IDlse==. | IDlseMHR==.
collapse MFEVPA EFEVPA, by(IDlse IDlseMHR)
save "$Full/Results/3.1.ManagerFE/VPAFE.dta", replace  

*PR
use "$Managersdta/Temp/FEConnected.dta", clear
reghdfe PR c.Tenure##c.Tenure##Female, absorb(MFEPR=IDlseMHR EFEPR=IDlse Func CountryYear AgeBand EmpType EmpStatus  ) cluster(IDlseMHR) 

keep IDlse IDlseMHR MFEPR EFE 
drop if IDlse==. | IDlseMHR==.
collapse MFEPR EFEPR, by(IDlse IDlseMHR)
save "$Full/Results/3.1.ManagerFE/PRFE.dta", replace  

* FE dataset - merging all together

use "$Full/Results/3.1.ManagerFE/LeaverMFE.dta", clear 

merge 1:m  IDlseMHR using "$Full/Results/3.1.ManagerFE/LogPayBonusFE.dta"
drop _merge 

merge 1:1 IDlse IDlseMHR using "$Full/Results/3.1.ManagerFE/PromFE.dta"
drop _merge 

merge 1:1 IDlse IDlseMHR using "$Full/Results/3.1.ManagerFE/VPAFE.dta"
drop _merge 

merge 1:1 IDlse IDlseMHR using "$Full/Results/3.1.ManagerFE/PRFE.dta"
drop _merge 

save "$Full/Results/3.1.ManagerFE/AllFE.dta", replace

********************************************************************************
* HISTOGRAMS OF FE
********************************************************************************

use "$Full/Results/3.1.ManagerFE/AllFE.dta", clear 
collapse MFE*, by(IDlseMHR)
egen MFELeaverZ = std(MFELeaver)
egen MFEPromZ = std(MFEProm)
egen MFEPayZ = std(MFEPay)
save "$Full/Results/3.1.ManagerFE/AllFEM.dta", replace 

* Histogram
use  "$Full/Results/3.1.ManagerFE/AllFEM.dta", clear
hist MFELeaverZ if MFELeaverZ<=2, fraction color(navy) xtitle(Manager VA in Exit)
graph export "$Full/Results/3.1.ManagerFE/histMFELeaver.png", replace

hist MFEPromZ if  MFEPromZ<=2 & MFEPromZ>=-2 , fraction color(navy)  xtitle(Manager VA in Promotion)
graph export "$Full/Results/3.1.ManagerFE/histMFEProm.png", replace

hist MFEPayZ if  MFEPayZ<=2 & MFEPayZ>=-2, fraction color(navy)  xtitle(Manager VA in Pay)
graph export "$Full/Results/3.1.ManagerFE/histMFEPay.png", replace

hist MFEVPA, fraction color(blue) normal xtitle(Manager VA in Bonus Allocation)
graph export "$Full/Results/3.1.ManagerFE/histMFEVPA.png", replace

hist MFEPR, fraction color(blue) normal xtitle(Manager VA in Perf. Score)
graph export "$Full/Results/3.1.ManagerFE/histMFEPR.png", replace

use "$Full/Results/3.1.ManagerFE/AllFEM.dta", clear
bidensity MFEPromZ MFEPayZ
heatplot MFEPromZ MFEPayZ

*HEATMAP
use "$Full/Results/3.1.ManagerFE/AllFEM.dta", clear 
merge 1:m IDlseMHR using "$dta/AllSnapshotWCCultureC.dta"

collapse  MFEPayZ  MFEPromZ WLM, by(IDlseMHR)
keep if  MFEPayZ>=-2 &  MFEPayZ<=2 & MFEPromZ>=-2 &  MFEPromZ<=2

heatplot MFEPromZ MFEPayZ , level(5) xtitle(Manager VA in log(Pay)) ytitle(Manager VA in Promotion)

heatplot WLM MFEPayZ
heatplot WLM MFEPromZ


