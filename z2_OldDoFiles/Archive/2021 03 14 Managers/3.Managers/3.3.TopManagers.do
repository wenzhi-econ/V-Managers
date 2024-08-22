* This do file identifies the characteristics of top managers 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"


use "$dta/AllSnapshotWCCultureC.dta" , clear 
by IDlse: egen TopManager = max(cond(Year==2020 & WL>3, 1, 0))
by IDlse: egen Others = max(cond(Year==2020 & WL<=3, 1, 0))


*distinct IDlse if TopManager==1
keep if TopManager ==1 | Others ==1
keep if AgeBand<=6 

gen AgeContinuous = .
replace AgeContinuous = 24 if AgeBand == 1
replace AgeContinuous = 35 if AgeBand == 2
replace AgeContinuous = 45 if AgeBand == 3
replace AgeContinuous = 55 if AgeBand == 4
replace AgeContinuous = 65 if AgeBand == 5
replace AgeContinuous = 70 if AgeBand == 6

*tab AgeBand if TopManager ==1 & Year ==2020 // what is the age of top managers 
*save "$temp/TopManager.dta", replace 

*use "$temp/TopManager.dta", clear
*replace VPA  = 150 if VPA >150 & VPA!=.
*replace LogBonus = 11 if LogBonus>11 & LogBonus!=.
*replace LogPay = 13 if LogPay>13 & LogPay!=.

egen IDlseT = tag(IDlse)
bys IDlse SalaryGrade: egen MonthsSalaryGrade = count(YearMonth)

foreach var in MonthsSalaryGrade LogBenefit LogPackage Female Tenure AgeContinuous  PR VPA LogBonus LogPay  MonthsPTitle TransferSubFuncC TransferCountryC PromSalaryGradeC MonthsPromSalaryGrade {
*winsor2 `var',  cuts( 0 99) by(Country Year) trim
*replace `var' = `var'_tr
bys IDlse: egen `var'Mean = mean(`var')
tw hist `var'Mean if IDlseT==1 & TopManager==1 , frac name(`var'Mean, replace) bcolor(blue%80) || hist `var'Mean if IDlseT==1 & Others==1, frac bcolor(red%80) title(`var') legend(label( 1 "Top Manager, WL >3") label(2 "WL<=3"))
graph export "$Results/3.3.TopManagers/`var'Mean.png", replace 

} 

 
su Female if IDlseT==1

foreach var in LogBenefit LogPackage Female Tenure AgeBand  PR VPA LogBonus LogPay  MonthsPTitle TransferSubFuncC TransferCountryC PromSalaryGradeC MonthsPromSalaryGrade {
bys IDlse: egen `var'Min = min(`var')
bys IDlse: egen `var'Max = max(`var' )
tw hist `var'Min if IDlseT==1 & TopManager==1 , frac name(`var'Min, replace) bcolor(blue%80) || hist `var'Min if IDlseT==1 & Others==1, frac bcolor(red%80) title(`var') legend(label( 1 "Top Manager, WL >3") label(2 "WL<=3"))
graph export "$Results/3.3.TopManagers/`var'Min.png", replace 

tw hist `var'Max if IDlseT==1 & TopManager==1 , frac name(`var'Max, replace) bcolor(blue%80) || hist `var'Max if IDlseT==1 & Others==1, frac bcolor(red%80) title(`var') legend(label( 1 "Top Manager, WL >3") label(2 "WL<=3"))
graph export "$Results/3.3.TopManagers/`var'Max.png", replace 
} 

