
********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off
cd "$analysis"

* Estimate Manager fe
use "$managersdta/IAManager.dta", clear

distinct IDlse // 2076

by IDlse: gen z = sum(IA)

keep if z ==0 
reghdfe LogPayBonus c.Tenure##c.Tenure##Female, absorb(MFEPay=IDlseMHR EFEPay=IDlse Func CountryYear AgeBand EmpType EmpStatus  ) cluster(IDlseMHR) 

preserve 
keep IDlse IDlseMHR MFEPay EFEPay 
drop if IDlse==. | IDlseMHR==.

collapse MFEPay EFEPay, by(IDlse IDlseMHR)
save "$IA/Results/1.1.ManagerFE/LogPayBonusFE.dta", replace 
restore 


reghdfe PromSalaryGrade c.Tenure##c.Tenure##Female, absorb(MFEProm=IDlseMHR EFEProm=IDlse Func CountryYear AgeBand EmpType EmpStatus  ) cluster(IDlseMHR) 

keep IDlse IDlseMHR MFEProm EFEProm 
drop if IDlse==. | IDlseMHR==.
collapse MFEProm EFEProm, by(IDlse IDlseMHR)
save "$IA/Results/1.1.ManagerFE/PromFE.dta", replace 


use "$IA/Results/1.1.ManagerFE/LogPayBonusFE.dta", clear 
collapse MFEPay , by( IDlseMHR)
hist MFEPay, ytitle(Manager FE in Tot. Comp.) xtitle("")
graph save "$IA/Results/1.1.ManagerFE/MFEPay.gph", replace 


use "$IA/Results/1.1.ManagerFE/PromFE.dta", clear 
collapse MFEProm , by( IDlseMHR)
hist MFEProm, ytitle(Manager FE in Promotion) xtitle("")
graph save "$IA/Results/1.1.ManagerFE/MFEProm.gph", replace 

gr combine "$IA/Results/1.1.ManagerFE/MFEPay.gph" "$IA/Results/1.1.ManagerFE/MFEProm.gph", ysize(3) title(Manager FE)
graph export "$IA/Results/1.1.ManagerFE/MFE.png", replace
 

use "$managersdta/IA.dta", clear
xtset IDlse YearMonth // set panel data
order Year, a(YearMonth)

merge m:1 IDlse IDlseMHR using "$IA/Results/1.1.ManagerFE/LogPayBonusFE.dta"
keep if _merge !=2
drop _merge 

merge m:1 IDlse IDlseMHR using "$IA/Results/1.1.ManagerFE/PromFE.dta"
keep if _merge !=2
drop _merge 

su MonthsIA1 , d

gen WindowIA1SixM = 1 if WindowIA1>=-24 & WindowIA1< - 18
replace WindowIA1SixM = 2 if WindowIA1>=-18 & WindowIA1< - 12
replace WindowIA1SixM = 3 if WindowIA1>=-12 & WindowIA1< - 6
replace WindowIA1SixM = 4 if WindowIA1>=-6 & WindowIA1< 0
replace WindowIA1SixM = 5 if WindowIA1>=0 & WindowIA1< 6
replace WindowIA1SixM = 6 if WindowIA1>=6 & WindowIA1< 12
replace WindowIA1SixM = 7 if WindowIA1>=12 & WindowIA1< 18
replace WindowIA1SixM = 8 if WindowIA1>=18 & WindowIA1< 24
replace WindowIA1SixM = 9 if WindowIA1>=24 & WindowIA1< 30
replace WindowIA1SixM = 10 if WindowIA1>=30 & WindowIA1< 36
replace WindowIA1SixM = 11 if WindowIA1>=36 & WindowIA1< 42
replace WindowIA1SixM = 12 if WindowIA1>=42 & WindowIA1< 48
replace WindowIA1SixM = 13 if WindowIA1>=48 & WindowIA1< 54
replace WindowIA1SixM = 13 if WindowIA1>=54 & WindowIA1<= 60



*keep if (WindowIA1 <=24 & WindowIA1 >=-24) 
egen WindowIA1E = group(WindowIA1) // to add the window FE

egen PRILagMeanM = rowmean(PRILag1M PRILag2M PRILag3M PRILag4M )
/* to think about this 
su MFEProm , d
gen MFEPromAbove = 1 if  MFEProm >=r(p50)
replace MFEPromAbove = 0 if  MFEProm <r(p50)


su MFEPay , d
gen MFEPayAbove = 1 if  MFEPay >=r(p50)
replace MFEPayAbove = 0 if  MFEPay <r(p50)

egen  MFEPromZ = std(MFEProm)
egen  MFEPayZ = std(MFEPay)
egen PRIMeanMZ = std(PRIMeanM)
*/

egen PRIMeanMZ = std(PRIMeanM)
egen PRILagMeanMZ = std(PRILagMeanM )

gen LogPRI = log(PRI)

foreach y in  PromSalaryGrade TransferSubFunc LogPRI  LogPayBonus LogPay LogBonus LeaverPerm{
	
reghdfe `y' c.PRILagMeanMZ##b4.WindowIA1SixM c.Tenure##c.Tenure JointTenure , cluster(IDlseMHR) a( CountryYear AgeBandM AgeBand Female##FemaleM  )
* TeamEthFrac   CulturalDistanceAbove#TeamCDistance
preserve
regsave using "$IA/Results/2.RegIA/`y'.dta", ci replace level(90) 
restore

}


use "$IA/Results/2.RegIA/PromSalaryGrade", clear
drop in 28/31
drop in 1

gen t1 = [_n]-4
replace t1 = . if t1 >9
gen t2 = [_n]-17
replace t2 = . if t2 <-3

*replace t1 = . if t1>6 // formula: [_n]-(#of lags +1)

twoway  (scatter coef t1, color(green) ) (line  coef t1, color(green) )  (rcap ci_lower ci_upper t1, color(green))  , xtitle("Event Time (6 months)") ///
ytitle("Promotion") xlabel(-3(1)9) yline(0) xline(0,lpattern(-)) legend(off) title("Level Effect of IA manager") 
graph save "$IA/Results/2.RegIA/PromSalaryGradeL.gph", replace


twoway ( scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (6 months)") ///
ytitle("Promotion") xlabel(-3(1)9) yline(0) xline(0,lpattern(-)) legend(off) title(" Effect of IA manager") 
graph save "$IA/Results/2.RegIA/PromSalaryGradeM.gph", replace
graph export "$IA/Results/2.RegIA/PromSalaryGrade.png", replace


use "$IA/Results/2.RegIA/LogPayBonus", clear
drop in 28/31
drop in 1

gen t1 = [_n]-4
replace t1 = . if t1 >9
gen t2 = [_n]-17
replace t2 = . if t2 <-3
*replace t1 = . if t1>6 // formula: [_n]-(#of lags +1)

twoway  (scatter coef t1, color(green) ) (line  coef t1, color(green) )  (rcap ci_lower ci_upper t1, color(green))  , xtitle("Event Time (6 months)") ///
ytitle("Pay + Bonus (log)") xlabel(-3(1)9) yline(0) xline(0,lpattern(-)) legend(off) title("Level Effect of IA manager") 
graph save "$IA/Results/2.RegIA/LogPayBonusL.gph", replace
graph export "$IA/Results/2.RegIA/LogPayBonus.png", replace


twoway ( scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (6 months)") ///
ytitle("Pay + Bonus (log)") xlabel(-3(1)9) yline(0) xline(0,lpattern(-)) legend(off) title(" Effect of IA manager") 
graph save "$IA/Results/2.RegIA/LogPayBonusM.gph", replace
graph export "$IA/Results/2.RegIA/LogPayBonus.png", replace


use "$IA/Results/2.RegIA/TransferSubFunc", clear
drop in 28/31
drop in 1

gen t1 = [_n]-4
replace t1 = . if t1 >9
gen t2 = [_n]-17
replace t2 = . if t2 <-3
*replace t1 = . if t1>6 // formula: [_n]-(#of lags +1)

twoway  (scatter coef t1, color(green) ) (line  coef t1, color(green) )  (rcap ci_lower ci_upper t1, color(green))  , xtitle("Event Time (6 months)") ///
ytitle("Pay + Bonus (log)") xlabel(-3(1)9) yline(0) xline(0,lpattern(-)) legend(off) title("Level Effect of IA manager") 
graph save "$IA/Results/2.RegIA/TransferSubFuncL.gph", replace
graph export "$IA/Results/2.RegIA/TransferSubFunc.png", replace


twoway ( scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (6 months)") ///
ytitle("Pay + Bonus (log)") xlabel(-3(1)9) yline(0) xline(0,lpattern(-)) legend(off) title(" Effect of IA manager") 
graph save "$IA/Results/2.RegIA/TransferSubFuncM.gph", replace
graph export "$IA/Results/2.RegIA/TransferSubFunc.png", replace


use "$IA/Results/2.RegIA/TransferSubFunc", clear
drop in 14/17

gen t1 = [_n]-4
*replace t1 = . if t1>6 // formula: [_n]-(#of lags +1)

twoway  (scatter coef t1, color(green) ) (line  coef t1, color(green) )  (rcap ci_lower ci_upper t1, color(green))  , xtitle("Event Time (6 months)") ///
ytitle("TransferSubFunc") xlabel(-3(1)9) yline(0) xline(0,lpattern(-)) legend(off) title("Level Effect of IA manager") 
graph save "$IA/Results/2.RegIA/TransferSubFunc.gph", replace
graph export "$IA/Results/2.RegIA/TransferSubFunc.png", replace








* OLS Regression
foreach y in PromSalaryGrade TransferSubFunc LogPR  LogPayBonus LogVPA LogPay LogBonus{

*reghdfe `y' b24.WindowIA1E Tenure JointTenure TeamEthFrac   , cluster(Block) a(  CountryYear )
*preserve
*regsave using "$IA/Results/2.RegIA/`y'Level.dta", ci replace level(90) 
*restore

reghdfe `y' MFEPayAbove##b24.WindowIA1E Tenure JointTenure TeamEthFrac , cluster(IDlseMHR) a( CountryYear  )
* TeamEthFrac   CulturalDistanceAbove#TeamCDistance
preserve
regsave using "$IA/Results/2.RegIA/`y'.dta", ci replace level(90) 
restore


}



use "$IA/Results/2.RegIA/PromSalaryGrade", clear

drop in 150/153
drop in 52/100
drop in 1/2

gen t1 = [_n]-24
replace t1 = . if t1>25 // formula: [_n]-(#of lags +1)


gen t2 = [_n]-73
replace t2 = . if t2<-23 // formula: [_n]-(#of lags +1)


twoway  (scatter coef t1, color(green) ) (line  coef t1, color(green) )  (rcap ci_lower ci_upper t1, color(green)) (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (months)") ///
ytitle("Promotion") xlabel(-24(3)24) yline(0) xline(0,lpattern(-)) legend(off) title("Level Effect (Green) vs High M Type (Orange) ") 
graph save "$IA/Results/2.RegIA/PromSalaryGrade.gph", replace
graph export "$IA/Results/2.RegIA/PromSalaryGrade.png", replace

use "$IA/Results/2.RegIA/LogBonus", clear

drop in 150/153
drop in 52/100
drop in 1/2

gen t1 = [_n]-24
replace t1 = . if t1>25 // formula: [_n]-(#of lags +1)


gen t2 = [_n]-73
replace t2 = . if t2<-23 // formula: [_n]-(#of lags +1)

twoway (scatter coef t1, color(green) ) (line  coef t1, color(green) )  (rcap ci_lower ci_upper t1, color(green)) (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (months)") ///
ytitle("Annual bonus (logs)") xlabel(-24(3)24) yline(0) xline(0,lpattern(-)) legend(off) title("Level Effect (Green) vs High M Type (Orange) ") 
graph save "$IA/Results/2.RegIA/LogBonus.gph", replace
graph export "$IA/Results/2.RegIA/LogBonus.png", replace


use "$IA/Results/2.RegIA/LogPayBonus", clear

drop in 150/153
drop in 52/100
drop in 1/2

gen t1 = [_n]-24
replace t1 = . if t1>25 // formula: [_n]-(#of lags +1)


gen t2 = [_n]-73
replace t2 = . if t2<-23 // formula: [_n]-(#of lags +1)

twoway (scatter coef t1, color(green) ) (line  coef t1, color(green) )  (rcap ci_lower ci_upper t1, color(green)) (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (months)") ///
ytitle("Annual pay + bonus (logs)") xlabel(-24(3)24) yline(0) xline(0,lpattern(-)) legend(off) title("Level Effect (Green) vs High M Type (Orange) ") 
graph save "$IA/Results/2.RegIA/LogPayBonus.gph", replace
graph export "$IA/Results/2.RegIA/LogPayBonus.png", replace


use "$IA/Results/2.RegIA/TransferSubFunc", clear

drop in 150/153
drop in 52/100
drop in 1/2

gen t1 = [_n]-24
replace t1 = . if t1>25 // formula: [_n]-(#of lags +1)


gen t2 = [_n]-73
replace t2 = . if t2<-23 // formula: [_n]-(#of lags +1)

twoway (scatter coef t1, color(green) ) (line  coef t1, color(green) )  (rcap ci_lower ci_upper t1, color(green)),  xtitle("Event Time (months)") ///
ytitle("Transfer (subfunction)") xlabel(-24(3)24) yline(0) xline(0,lpattern(-)) legend(off) title("Level Effect (Green)")
graph save "$IA/Results/2.RegIA/TransferSubFuncL.gph", replace
twoway (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (months)") ///
ytitle("Transfer (subfunction)") xlabel(-24(3)24) yline(0) xline(0,lpattern(-)) legend(off) title("High M Type (Orange) ") 
graph save "$IA/Results/2.RegIA/TransferSubFuncM.gph", replace

gr combine "$IA/Results/2.RegIA/TransferSubFuncL.gph" "$IA/Results/2.RegIA/TransferSubFuncM.gph", cols(1)
graph export "$IA/Results/2.RegIA/TransferSubFunc.png", replace




********************************************************************************
* 3. Prepare data for Regressions - year level
********************************************************************************

* Choosing the maxmode of RoundIA for each IDlse and year combination
bys IDlse Year: egen RoundIAMode =mode(RoundIA), maxmode
bys IDlse Year: egen OutGroupMode =mode(OutGroup), maxmode
bys IDlse Year: egen CulturalDistanceSTDMode =mode(CulturalDistanceSTD), maxmode

* Taking the mode for all variables
global YearVars  IDlseMHR  MonthsIA1 HomeCountryManager JointTenure TeamEthFrac TeamCDistance CountryYear Block TeamID
foreach var in $YearVars {
bys IDlse Year: gen `var'Mode = `var' if CulturalDistanceSTD == CulturalDistanceSTDMode
}

global ModeVars RoundIAMode  OutGroupMode CulturalDistanceSTDMode IDlseManagerMode  HomeCountryManagerMode JointTenureMode TeamEthFracMode TeamCDistanceMode CountryYearMode BlockMode TeamIDMode

* Collapse at the year level 
collapse $outcomes  Tenure (max)   $ModeVars $outcomesChange , by(IDlse Year)
	
* Renaming 
foreach var in  $YearVars OutGroup CulturalDistanceSTD RoundIA RoundIAManager {
rename `var'Mode `var'
}

* Create window around manager switch
by IDlse: egen RoundIAMax= max(RoundIA)
drop if RoundIAMax ==0 // these are employees that have IA manager for less than 3 months
by IDlse (Year), sort: gen Count = _n
by IDlse (Year), sort: gen YearsIA1 = Count if (RoundIA[_n]==1 & RoundIA[_n-1]==0  )
by IDlse: egen YearsIA1Max = max(YearsIA1)
replace YearsIA1 = YearsIA1Max
label var YearsIA1 "Number of year  on IA1 for the employee"
drop YearsIA1Max
gen WindowIA1 = Count - YearsIA1
replace WindowIA1 = 999 if WindowIA1==.

* Save dataset
save "$analysis/Temp/IAFinalSampleYearly", replace 

********************************************************************************
* 4. Regressions - year level
********************************************************************************

* Run regression on full sample 

* 5 years window [-3, +4]
use "$analysis/Temp/IAFinalSampleYearly" , clear

su CulturalDistanceSTD, detail
gen CulturalDistanceAbove = 1 if CulturalDistanceSTD > r(p50)
replace CulturalDistanceAbove = 0 if CulturalDistanceAbove == .
replace CulturalDistanceAbove = . if CulturalDistanceSTD==.

* Discrete survival model using duration  - logit or xtcloglog
sort IDlse Year
by IDlse : generate t = _n
gen Duration = log(t) // or t + t^2

keep if (WindowIA1 <=24 & WindowIA1 >=-24) 
*| WindowIA1 == 999
egen WindowIA1E = group(WindowIA1) // to add the window FE

* OLS Regression
foreach y in PromChange JobChange LogPR LogPRSnapshot LogVPA LogPay LogBonus{

reghdfe `y' b3.WindowIA1E Tenure JointTenure TeamEthFrac   , cluster(Block) a(IDlse  CountryYear  RoundIAManager)
preserve
regsave using "$analysis/Results/2.RegIA/`y'Level.dta", ci replace level(90) 
restore

reghdfe `y' CulturalDistanceAbove##b3.WindowIA1E Tenure JointTenure TeamEthFrac   CulturalDistanceAbove#c.TeamCDistance, cluster(Block) a(IDlse  CountryYear  RoundIAManager)
* TeamEthFrac   CulturalDistanceAbove#TeamCDistance
preserve
regsave using "$analysis/Results/2.RegIA/`y'.dta", ci replace level(90) 
restore


}

