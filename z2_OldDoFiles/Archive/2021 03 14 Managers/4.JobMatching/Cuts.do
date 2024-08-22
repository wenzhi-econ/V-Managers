/* TODO: with more time take mode
foreach var in $controlE $controlM $controlMacro {
	bys IDlse Spell: egen `var'Mode = mode(`var')
	replace `var' = `var'Mode
}

gsort IDlse YearMonth
collapse PRIPreS2y PRIPreS1y  TimetoPromPreS2y TimetoPromPreS1y PRIPostS2y PRIPostS1y  TimetoPromPostS2y TimetoPromPostS1y  PRIPreS2yE PRIPreS1yE  TimetoPromPreS2yE TimetoPromPreS1yE  BonusPreS2yE BonusPreS1yE (firstnm) $controlE $controlM $controlMacro , by(IDlse Spell)
*/


*******************************************************************************
* Variable preparation 
********************************************************************************



* I do not have PromSalaryGradePostS1y> create it by looking at the difference in cum promotion across time periods
gen PromSalaryGradePostS1m = PromSalaryGradeCPostS1m - PromSalaryGradeCM 
gen PromSalaryGradePostS1y = PromSalaryGradeCPostS1y - PromSalaryGradeCPostS1m 
*gen PromSalaryGradePostS6m = PromSalaryGradeCPostS6m - PromSalaryGradeCPostS1m
*gen PromSalaryGradePostS1y = PromSalaryGradeCPostS1y - PromSalaryGradeCPostS6m
*gen PromSalaryGradePostS2y = PromSalaryGradeCPostS2y - PromSalaryGradeCPostS1y
*gen PromSalaryGradePostS3y = PromSalaryGradeCPostS3y - PromSalaryGradeCPostS2y
* Employee 
gen PromSalaryGradePostS1mE = PromSalaryGradeCPostS1mE - PromSalaryGradeC
gen PromSalaryGradePostS1yE = PromSalaryGradeCPostS1yE - PromSalaryGradeCPostS1mE
*gen PromSalaryGradePostS6mE = PromSalaryGradeCPostS6mE - PromSalaryGradeCPostS1mE
*gen PromSalaryGradePostS1yE = PromSalaryGradeCPostS1yE - PromSalaryGradeCPostS6mE
*gen PromSalaryGradePostS2yE = PromSalaryGradeCPostS2yE - PromSalaryGradeCPostS1yE
*gen PromSalaryGradePostS3yE = PromSalaryGradeCPostS3yE - PromSalaryGradeCPostS2yE

gen TransferSubFuncPostS1mE = TransferSubFuncCPostS1mE - TransferSubFuncC
gen TransferSubFuncPostS1yE = TransferSubFuncCPostS1yE - TransferSubFuncCPostS1mE
*gen TransferSubFuncPostS6mE = TransferSubFuncCPostS6mE - TransferSubFuncCPostS1mE 
*gen TransferSubFuncPostS1yE = TransferSubFuncCPostS1yE - TransferSubFuncCPostS6mE
*gen TransferSubFuncPostS2yE = TransferSubFuncCPostS2yE - TransferSubFuncCPostS1yE
*gen TransferSubFuncPostS3yE = TransferSubFuncCPostS3yE - TransferSubFuncCPostS2yE




gen o = 1 
egen ID = group(IDlse Spell)
drop if ID ==.
collapse o , by(IDlse SpellStart SpellEnd ID PostSpell1year PostSpell2year PostSpell3year PostSpell4year PostSpell5year PostSpell6year PreSpell1year PreSpell2year PreSpell3year PreSpell4year PreSpell5year PreSpell6year PostSpell1month PostSpell2month PostSpell3month PostSpell4month PostSpell5month PostSpell6month PreSpell1month PreSpell2month PreSpell3month PreSpell4month PreSpell5month PreSpell6month)

isid ID
drop o
save "$temp/SpellTimeE.dta", replace // dataset at spell level 

merge m:m IDlse using  "$temp/5percent.dta"
keep if _merge ==3 
drop _merge 

local post LeaverInv LeaverVol LeaverPerm
local post PRI

foreach var in  `post' {
	forval i= 1(1)6{
bys ID: egen `var'PostS`i'yE  = max(cond(YearMonth == PostSpell`i'year, `var', .)) 
label var  `var'PostS`i'yE  "`var' `i' year(s) post spell" 

bys ID: egen `var'PostS`i'mE  = max(cond(YearMonth == PostSpell`i'month, `var', .)) 
label var  `var'PostS`i'mE  "`var' `i' month(s) post spell" 

}
}






*global string ISOCode CountryS PositionTitle SalaryGradeC 
* REDEFINING GLOBALS FOR THE FINAL COLLAPSE (string variables go in a separate )
global mode   Office OfficeCode Market Func SubFunc BC Female AgeBand Tenure WL SalaryGrade FTE EmpType EmpStatus LeaveType IDlseMHR PromSalaryGradeM PromSalaryGradeCM PromSalaryGradeLateralM PromSalaryGradeLateralCM PromSalaryGradeVerticalM PromSalaryGradeVerticalCM TransferCountryM TransferCountryCM TransferFuncM TransferFuncCM TransferSubFuncM TransferSubFuncCM TransferSubFuncLateralM TransferSubFuncLateralCM TransferFuncLateralM TransferFuncLateralCM TransferPTitleM TransferPTitleCM TransferPTitleLateralM TransferPTitleLateralCM PRM VPAM LeaverPermM LeaverInvM LeaverVolM FemaleM AgeBandM TenureM BCM


PostSpell1year PostSpell2year PostSpell3year PostSpell4year PostSpell5year PostSpell6year PreSpell1year PreSpell2year PreSpell3year PreSpell4year PreSpell5year PreSpell6year PostSpell1month PostSpell2month PostSpell3month PostSpell4month PostSpell5month PostSpell6month PreSpell1month PreSpell2month PreSpell3month PreSpell4month PreSpell5month PreSpell6month


* Generating lags (1-4 years) and year-level mean of variables defined below

* Creating dummy FirstYM, which equals 1 for first obs. within the Year (for each individual).
* I use this so that I can sort with only 1 obs. for each year in the loop (useful for creating lags for previous years)

bys IDlse Year (YearMonth): gen FirstYM = 1 if _n== 1
replace FirstYM = 0 if FirstYM !=1

* these are the variables
local lagminvariables Pay Benefit Bonus Package PR PRI PRSnapshot VPA

foreach var in  `lagminvariables' {

bys IDlse Year: egen `var'Mean = mean(`var')

forvalues i = 1/4 {

gen `var'Lag`i' = .
bys FirstYM IDlse (YearMonth): replace `var'Lag`i'= `var'Mean[_n-`i'] if  Year != Year[_n-1]

replace `var'Lag`i' =. if FirstYM == 0

bys IDlse Year: egen `var'LagMin`i' = min(`var'Lag`i')

bys IDlse Year: replace  `var'Lag`i' =  `var'LagMin`i'

drop  `var'LagMin`i'
}
}

drop FirstYM
* Standard variables (adding Manager)
 global MvariablesTime PayMean BenefitMean BonusMean PackageMean PRMean PRSnapshotMean PRIMean VPAMean PayLag1 BenefitLag1 BonusLag1 PackageLag1 PRLag1 PRSnapshotLag1 PRILag1 VPALag1 PayLag2 BenefitLag2 BonusLag2 PackageLag2 PRLag2 PRSnapshotLag2 PRILag2 VPALag2 PayLag3 BenefitLag3 BonusLag3 PackageLag3 PRLag3 PRSnapshotLag3 PRILag3 VPALag3 PayLag4 BenefitLag4 BonusLag4 PackageLag4 PRLag4 PRSnapshotLag4 PRILag4 VPALag4 


use "$temp/SpellTimeM.dta", clear 
keep IDlse SpellStart 
egen tag1 = tag(IDlse SpellStart )
keep if tag1 ==1
drop tag1 
save "$temp/SpellStart.dta", replace 

use "$temp/SpellTimeM.dta", clear 
keep IDlse SpellEnd
egen tag1 = tag(IDlse SpellEnd )
keep if tag1 ==1
drop tag1 
append 
save "$temp/SpellStart.dta", replace 


 local MSpell PayPostS*y PayPostS*m PayPreS*y PayPreS*m BonusPostS*y BonusPostS*m BonusPreS*y BonusPreS*m PRPostS*y PRPostS*m PRPreS*y PRPreS*m  PRIPostS*y PRIPostS*m PRIPreS*y PRIPreS*m  PRSnapshotPostS*y PRSnapshotPostS*m PRSnapshotPreS*y PRSnapshotPreS*m  VPAPostS*y VPAPostS*m VPAPreS*y VPAPreS*m PromSalaryGradeCPostS*y PromSalaryGradeCPostS*m PromSalaryGradeCPreS*y PromSalaryGradeCPreS*m   ChangeSalaryGradeCPostS*y ChangeSalaryGradeCPostS*m ChangeSalaryGradeCPreS*y ChangeSalaryGradeCPreS*m  MonthsPromSalaryGradeCumPostS*y MonthsPromSalaryGradeCumPostS*m MonthsPromSalaryGradeCumPreS*y MonthsPromSalaryGradeCumPreS*m MonthsSalaryGradeCumPostS*y MonthsSalaryGradeCumPostS*m MonthsSalaryGradeCumPreS*y MonthsSalaryGradeCumPreS*m  TransferSubFuncCPostS*y TransferSubFuncCPostS*m TransferSubFuncCPreS*y TransferSubFuncCPreS*m  TransferFuncCPostS*y TransferFuncCPostS*m TransferFuncCPreS*y TransferFuncCPreS*m  TransferPTitleCPostS*y TransferPTitleCPostS*m TransferPTitleCPreS*y TransferPTitleCPreS*m MonthsSubFuncPostS*y MonthsSubFuncPostS*m MonthsSubFuncPreS*y MonthsSubFuncPreS*m  MonthsWLPostS*y MonthsWLPostS*m MonthsWLPreS*y MonthsWLPreS*m    TransferCountryCPostS*y TransferCountryCPostS*m TransferCountryCPreS*y TransferCountryCPreS*m PromSpeedPostS*y PromSpeedPostS*m PromSpeedPreS*y PromSpeedPreS*m  ChangeSalaryGradeSpeedPostS*y ChangeSalaryGradeSpeedPostS*m ChangeSalaryGradeSpeedPreS*y ChangeSalaryGradeSpeedPreS*m  LeaverInvPostS*y LeaverInvPostS*m LeaverVolPostS*y LeaverVolPostS*m   LeaverPermPostS*y LeaverPermPostS*m
