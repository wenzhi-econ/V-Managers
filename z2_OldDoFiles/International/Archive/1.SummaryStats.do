* This do file looks at manager effect on UFLP sample

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd $data

********************************************************************************
* HOMECOUNTRY MATRIX
********************************************************************************

use "$data/dta/AllSnapshotIAFinalSample.dta", clear
*use "$data/dta/PRSnapshotWCMFinal1718", clear
keep if  EmpTypeManager<=7 // keep only the employees with IA manager
collapse (count) IDlse, by(HomeCountry HomeCountryManager)
drop if HomeCountryManager ==.
order HomeCountry HomeCountryManager  IDlse
rename IDlse No
decode HomeCountryManager, gen(HomeCountryManagerS)
replace HomeCountryManagerS = subinstr(HomeCountryManagerS," ","",.)
replace HomeCountryManagerS = subinstr(HomeCountryManagerS,",","",.)
drop HomeCountryManager
drop if (HomeCountryManagerS == "UNKNW" | HomeCountry == 106) // taking away UNKNW
reshape wide No, i(HomeCountry) j(HomeCountryManagerS) string
export excel using "$analysis/Results/1.SummaryStats/HCMatrix", firstrow(variables) replace

********************************************************************************
* Balancing checks  - Table
********************************************************************************

* Duration of international Assignments: Managers characteristics
use "$data/dta/AllSnapshotWCCultureC.dta", clear
*use "$data/dta/PRSnapshotWCMFinal1718", clear

/*sort IDlse YearMonthIA
quietly bys IDlse IA:  gen dup_IA = cond(_N==1,0,_n)
su MonthsIA if IA==1 & (dup==0 | dup==1)

sort IDlse YearMonthManager
quietly bys IDlse Manager:  gen dup_manager = cond(_N==1,0,_n)
su MonthsIA if IA==1 & (dup==0 | dup==1)
*/

sort IDlse YearMonth
by IDlse: gen TenureTot = Tenure[_N]
by IDlse: egen AgeEntry = min(AgeBand)
by IDlse: egen AgeExit = max(AgeBand)
by IDlse: egen WLEntry = min(WL)
by IDlse: egen WLExit = max(WL)
label value AgeEntry  AgeBand
label value AgeExit  AgeBand

* All employees
global DESCVARS  Female TenureTot AgeEntry AgeExit  WLExit PR 
foreach y in $DESCVARS {
reg `y' i.Cluster#i.Year
predict `y'_res, res
}
global DESCVARS_res  Female_res TenureTot_res AgeEntry_res AgeExit_res  WLExit_res PR_res 

* Managers
global DESCVARS_m Female TenureTot AgeEntry AgeExit  WLExit PR 
foreach y in $DESCVARS_m {
reg `y' i.Cluster#i.Year
predict `y'_Mres, res
}
global DESCVARS_res_m  Female_Mres TenureTot_Mres AgeEntry_Mres AgeExit_Mres  WLExit_Mres PR_Mres 


collapse FlagManager FlagIA FlagIAManager FlagUFLP EmpTypeManager $DESCVARS_res_m $DESCVARS_res , by(IDlse)

*Balancing table managers: IA and not IA
balancetable FlagIA $DESCVARS_res_m using ///
 "$analysis/Results/1.SummaryStats/balancingtableM.tex" if FlagManager==1, replace vce(robust) ctitles( "No International Ass." "International Ass." "Difference")
 

*Balancing table employees: LOCAL and IA manager 
balancetable FlagIAManager $DESCVARS_res using ///
 "$analysis/Results/1.SummaryStats/balancingtableW.tex", replace ctitles("Local Manager" "Foreign Manager (IA)" "Difference")


* Balancing table UFLP: UFLP or not 
balancetable FlagUFLP $DESCVARS_res using ///
 "$analysis/Results/1.SummaryStats/balancingtableUFLP.tex", replace ctitles("No UFLP" "UFLP" "Difference")
 


********************************************************************************
* Cultural Distance histogram
********************************************************************************

use "$data/dta/AllSnapshotIAFinalSample.dta", clear
egen  CulturalDistanceSTD = std( CulturalDistance)

su CulturalDistanceSTD
hist CulturalDistanceSTD if CulturalDistanceSTD > r(min), percent bcolor(blue) xtitle(Cultural Distance (WVS))
graph save "$analysis/Results/1.SummaryStats/CulturalDistanceHist", replace
graph export "$analysis/Results/1.SummaryStats/CulturalDistanceHist.png", replace

su CulturalDistanceSTD
hist CulturalDistanceSTD if CulturalDistanceSTD > r(min), percent bcolor(blue) by(Year)
