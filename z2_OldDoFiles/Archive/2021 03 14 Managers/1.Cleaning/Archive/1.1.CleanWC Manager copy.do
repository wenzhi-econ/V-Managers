********************************************************************************
**                     Cleaning Manager with IDlseMHR                         **
**                              7 Nov, 2020                                  **
/*******************************************************************************

This do-file:

1. Identifies managers in AllSnapshotWC.dta using the list of managers' IDlse
in ManagerIDReports.dta and tag them as 1 using "Manager" dummy.

2. Adds ISOCodeHome variable to the dataset.

3. Extracts relevant manager characteristics and adds new variables, saving them
in a dta file MListChar.dta.

4. Merges MListChar.dta with the original dataset and generates new variables.

Input: ManagerIDReports.dta, AllSnapshotWC.dta
Output: AllSnapshotWCM.dta

*/
* directory
cd "$Managersdta"

*********************************************************************************
* 1. Identifying managers in the Original Dataset & adding manager IDlse
*********************************************************************************

* 1.a. creating Mlist

* using ManagerIDReports to create tempfile Mlist, which has IDlse of all
* employees who also happen to be a manager in given month.

use "$dta/ManagerIDReports.dta", clear

keep IDlseMHR YearMonth
rename IDlseMHR IDlse

duplicates drop IDlse YearMonth, force

* 1.b. I identify managers in AllSnapshotWC.dta using the tempfile.

drop if IDlse == . // 60 missing values, which is due to the missing values in IDlseMHR

save "$Managersdta/Temp/Mlist.dta", replace


********************************************************************************
* ADD TRANSFERS VARIABLES for MANAGERS
********************************************************************************

use "$dta/AllSnapshotWC.dta", clear

* Imputed performance 
gen PRI = PR
label var PRI "Imputed PR score using VPA buckets"
replace PRI = 1 if VPA <=25 & (Year >2018 | PR==.)
replace PRI = 2 if VPA >25 & VPA<=75 & (Year >2018 | PR==.)
replace PRI = 3 if VPA >75 & VPA<=100 & (Year >2018 | PR==.)
replace PRI = 4 if VPA >100 & VPA<=115 & (Year >2018 | PR==.)
replace PRI = 5 if VPA >115 & Year >2018 & VPA!=.

*Pay Increase 
gsort IDlse YearMonth
gen PayIn = 1 if (IDlse == IDlse[_n-1] & Pay > Pay[_n-1] ) & Pay!=.
replace PayIn= 0 if PayIn==.  & Pay!=.
label var PayIn " Dummy, equals 1 in the month when Pay is greater than in the preceding"

* Country transfers 
gsort IDlse YearMonth
gen TransferCountry = 0 if Country!=. 
replace  TransferCountry = 1 if (IDlse == IDlse[_n-1] & Country != Country[_n-1] & Country!=.  )
label var  TransferCountry "Dummy, equals 1 in the month when Country is diff. than in the preceding"

gen z = TransferCountry
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Country!=.
gen TransferCountryC = z 
drop z 
label var TransferCountryC "CUMSUM from dummy=1 in the month when Country is diff. than in the preceding"


* Promotion variables: PromWL OVERALL
gen z = PromWL
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 & PromWL!=.
replace z = 0 if z ==. & PromWL!=.
gen PromWLC = z 
drop z 

label var PromWLC "CUMSUM from dummy=1 in the month when WL is greater than in the preceding month"

* Promotion variables: PromSalaryGrade OVERALL
gen z = PromSalaryGrade
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1  & PromSalaryGrade!=.
replace z = 0 if z ==. & PromSalaryGrade!=.
gen PromSalaryGradeC = z 
drop z

label var PromSalaryGradeC "CUMSUM from dummy=1 in the month when SalaryGrade is higher in ranking than in the preceding month"

* "Promotion" variables: Change in Salary grade OVERALL 
gsort IDlse YearMonth
gen ChangeSalaryGrade = 0 & SalaryGrade !=.
replace  ChangeSalaryGrade = 1 if IDlse == IDlse[_n-1] & SalaryGrade != SalaryGrade[_n-1] & SalaryGrade !=.
label var ChangeSalaryGrade "Equals 1 when SalaryGrade is different than in the preceding month"

gen z = ChangeSalaryGrade
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc !=.
gen ChangeSalaryGradeC = z 
drop z  

label var ChangeSalaryGradeC "CUMSUM from dummy=1 in the month when SalaryGrade is different than in the preceding month"

* Demotion variables: DemotionSalaryGrade OVERALL
gen z = DemotionSalaryGrade
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1  & DemotionSalaryGrade!=.
replace z = 0 if z ==. & DemotionSalaryGrade!=.
gen DemotionSalaryGradeC= z 
drop z 
label var DemotionSalaryGradeC "CUMSUM from dummy=1 in the month when SalaryGrade is lower in ranking than in the preceding month"

* Job transfer variables: Job title | position change OVERALL
gsort IDlse YearMonth
gen TransferPTitle = 0 if PositionTitle!="" & EmployeeNum!=.
replace  TransferPTitle = 1 if (IDlse == IDlse[_n-1] & PositionTitle != PositionTitle[_n-1] & PositionTitle!=""  ) | (IDlse == IDlse[_n-1] & EmployeeNum != EmployeeNum[_n-1] & EmployeeNum!=.)
label var  TransferPTitle "Dummy, equals 1 in the month when either PositionTitle or EmployeeNum is diff. than in the preceding"

gen z = TransferPTitle
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PositionTitle!="" & EmployeeNum!=.
gen TransferPTitleC = z 
drop z 

label var  TransferPTitleC "CUMSUM from dummy=1 in the month when either PositionTitle or EmployeeNum is diff. than in the preceding"

* Job transfer variables: Subfunction OVERALL
gsort IDlse YearMonth
gen TransferSubFunc = 0 & SubFunc !=.
replace  TransferSubFunc = 1 if IDlse == IDlse[_n-1] & SubFunc != SubFunc[_n-1] & SubFunc !=.
label var  TransferSubFunc "Dummy, equals 1 in the month when SubFunc is diff. than in the preceding"

gen z = TransferSubFunc
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc !=.
gen TransferSubFuncC = z 
drop z 

label var  TransferSubFuncC "CUMSUM from dummy=1 in the month when SubFunc is diff. than in the preceding"

*Job transfer variables: Function OVERALL
gsort IDlse YearMonth
gen TransferFunc = 0 if Func !=.
replace  TransferFunc = 1 if IDlse == IDlse[_n-1] & Func != Func[_n-1]  & Func !=.
label var  TransferFunc "Dummy, equals 1 in the month when Func is diff. than in the preceding"

gen z = TransferFunc
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Func !=.
gen  TransferFuncC = z 
drop z 
label var  TransferFuncC "CUMSUM from dummy=1 in the month when Func is diff. than in the preceding"

* Lateral sub func transfer (without promotion): Sub Function
gen TransferSubFuncLateral = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace TransferSubFuncLateral  = 1 if TransferSubFunc  == 1 & PromSalaryGrade==0
label var  TransferSubFuncLateral "Dummy, equals 1 in the month when TransferSubFunc=1 but PromSalaryGrade=0"

gen z = TransferSubFuncLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc !=.
gen TransferSubFuncLateralC = z 
drop z 

label var  TransferSubFuncLateralC "CUMSUM from dummy=1 in the month when TransferSubFunc=1 but PromSalaryGrade=0"

* Lateral func transfer (without promotion): Function
gen TransferFuncLateral = 0 if PromSalaryGrade!=. & TransferFunc!=.
replace TransferFuncLateral  = 1 if TransferFunc  == 1 & PromSalaryGrade==0
label var  TransferFuncLateral "Dummy, equals 1 in the month when TransferFunc=1 but PromSalaryGrade=0"

gen z = TransferFuncLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Func !=.
gen TransferFuncLateralC = z 
drop z 

label var  TransferFuncLateralC "CUMSUM from dummy=1 in the month when TransferFunc=1 but PromSalaryGrade=0"

* Lateral Job Position Move (without promotion): Job title | position change 
gen TransferPTitleLateral = 0 if PromSalaryGrade!=. & TransferPTitle!=.
replace TransferPTitleLateral = 1 if TransferPTitle  == 1 & PromSalaryGrade==0
label var  TransferPTitleLateral "Dummy, equals 1 in the month when TransferPTitle=1 but PromSalaryGrade=0"

gen z = TransferPTitleLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & TransferPTitle !=.
gen TransferPTitleLateralC = z 
drop z 
label var  TransferPTitleLateralC "CUMSUM from dummy=1 in the month when TransferPTitle=1 but PromSalaryGrade=0"

* Vertical Promotion: PromSalaryGrade without subfunc change  
gen PromSalaryGradeVertical = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace PromSalaryGradeVertical  = 1 if TransferSubFunc  == 0 & PromSalaryGrade==1
label var  PromSalaryGradeVertical "Dummy, equals 1 in the month when PromSalaryGrade=1  but TransferSubFunc=0"

gen z = PromSalaryGradeVertical
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PromSalaryGrade !=.
gen PromSalaryGradeVerticalC = z 
drop z 
label var  PromSalaryGradeVerticalC "CUMSUM from dummy=1 in the month when PromSalaryGrade=1  but TransferSubFunc=0"

* Lateral Promotion: PromSalaryGrade with subfunc change  
gen PromSalaryGradeLateral = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace PromSalaryGradeLateral = 1 if PromSalaryGrade ==1 & TransferSubFunc ==1
label var  PromSalaryGradeLateral "Dummy, equals 1 in the month when PromSalaryGrade=1  but TransferSubFunc=1"

gen z = PromSalaryGradeLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PromSalaryGrade !=.
gen PromSalaryGradeLateralC = z 
drop z 
label var  PromSalaryGradeLateralC "CUMSUM from dummy=1 in the month when PromSalaryGrade=1  but TransferSubFunc=1"

* Months in position
bys IDlse TransferPTitleC: egen MonthsPTitle =  count(YearMonth)
label var MonthsPTitle "Tot. Months in Position Title"
* Months in subfunction
bys IDlse TransferSubFuncC: egen MonthsSubFunc =  count(YearMonth)
label var MonthsSubFunc "Tot. Months in Sub Function"
* Months in salary grade
bys IDlse ChangeSalaryGradeC: egen MonthsSalaryGrade =  count(YearMonth)
label var MonthsSalaryGrade "Tot. Months in Salary Grade"
* Months in salary grade by promotion 
bys IDlse PromSalaryGradeC: egen MonthsPromSalaryGrade =  count(YearMonth)
label var MonthsPromSalaryGrade "Tot. Months in Salary Grade based on promotion categories"
* Time since last promotion 
bys IDlse PromSalaryGradeC: egen MonthsPromSalaryGradeCum = rank(YearMonth)
label var MonthsPromSalaryGradeCum "Time since last change in Salary Grade based on promotion categories"
* Time since last salary grade change
bys IDlse ChangeSalaryGradeC: egen MonthsSalaryGradeCum = rank(YearMonth)
label var MonthsSalaryGradeCum "Time since last change in Salary Grade"

* Speed of promotion
sort IDlse YearMonth
bys IDlse PromSalaryGradeC (YearMonth), sort: egen PromSpeed = max(cond(PromSalaryGradeC[_n]!=PromSalaryGradeC[_n-1] & IDlse[_n] == IDlse[_n-1], MonthsPromSalaryGrade[_n-1] ,.) )
bys IDlse  (YearMonth), sort: replace PromSpeed = 0 if PromSalaryGradeC[1]==PromSalaryGradeC[_N] & IDlse[1] == IDlse[_N] 
bys IDlse  (YearMonth), sort: replace PromSpeed = 0 if PromSalaryGradeC==0
label var PromSpeed "Tot. Months in Salary Grade prior promotion"

sort IDlse YearMonth
bys IDlse ChangeSalaryGradeC (YearMonth), sort: egen ChangeSalaryGradeSpeed = max(cond(ChangeSalaryGradeC[_n]!=ChangeSalaryGradeC[_n-1] & IDlse[_n] == IDlse[_n-1], MonthsSalaryGrade[_n-1] ,.) )
bys IDlse  (YearMonth), sort: replace ChangeSalaryGradeSpeed = 0 if ChangeSalaryGradeC[1]==ChangeSalaryGradeC[_N] & IDlse[1] == IDlse[_N] 
bys IDlse  (YearMonth), sort: replace ChangeSalaryGradeSpeed = 0 if ChangeSalaryGradeSpeedC==0
label var ChangeSalaryGradeSpeed "Tot. Months in Salary Grade (SG) prior change in SG"

merge 1:1 IDlse YearMonth using "$Managersdta/Temp/Mlist.dta"

drop if _merge == 2 // 12,956 unmatched obs. from ManagerIDReports.dta.

* the matched individuals are managers. I tag them generating a dummy Manager.

gen Manager = 0
replace Manager = 1 if _merge == 3
label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"

drop _merge

* 1.d. saving as AllSnapshotWCM.dta
save "$Managersdta/AllSnapshotWCM.dta",replace

*********************************************************************************
* 2. Adding ISOCodeHome, ISOCode for home countries.
*********************************************************************************

* use AllSnapshotWCM.dta if it is not loaded or loaded but changed
* Note: I add 'if' clause to avoid wasting time to load already existing data.
* But I do not delete the code as it might be necessary to run this section separately.

if "`c(filename)'" != "$Managersdta/AllSnapshotWCM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotWCM.dta", clear
}

* 2.a. Extracting "ISOCode", ISOCode for working Countries (Country),
* to generate "ISOCodeHome" variable.
keep CountryS ISOCode
duplicates drop CountryS, force

rename CountryS HomeCountryS
rename ISOCode ISOCodeHome

* Saving
save "$Managersdta/Temp/isocode.dta",replace

* 2.b. Merging with the original data.

use "$Managersdta/AllSnapshotWCM.dta", clear

replace HomeCountryS = "Palestine"  if HomeCountryS== "Palestinian Territory Occupied"

merge m:1 HomeCountryS using "$Managersdta/Temp/isocode.dta"
drop if _merge==2
drop _merge HomeCountryS

order ISOCodeHome, a(HomeCountry)

* 2.c. Updating AllSnapshotWCM.dta
save "$Managersdta/AllSnapshotWCM.dta",replace

********************************************************************************
* 3. Preparing Manager Characteristics tempfile to merge with AllSnapshotWCM.dta
********************************************************************************

* use AllSnapshotWCM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/AllSnapshotWCM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotWCM.dta", clear
}

* 3.a. Dropping non-manager employees and unnecessary variables

keep if Manager ==1

keep IDlse EmployeeNum YearMonth Year ///
HomeCountry ISOCodeHome Country CountryS ISOCode ///
Cluster Market PositionTitle StandardJob StandardJobCode Func SubFunc ///
Female WL WLSalaryGrade AgeBand Tenure EmpType ///
LeaverType LeaverInv LeaverVol LeaverPerm LeaverTemp ///
SalaryGrade SalaryGradeC SalaryGradeOrder PromWL PromWLSalaryGrade PromSalaryGrade DemotionSalaryGrade ///
Pay Benefit Bonus Package PR PRI PRSnapshot VPA ///
PayIn TransferCountry TransferCountryC PromWLC PromSalaryGradeC DemotionSalaryGradeC TransferPTitle TransferPTitleC TransferSubFunc TransferSubFuncC TransferFunc TransferFuncC TransferSubFuncLateral TransferSubFuncLateralC TransferFuncLateral TransferFuncLateralC TransferPTitleLateral TransferPTitleLateralC PromSalaryGradeVertical PromSalaryGradeVerticalC PromSalaryGradeLateral PromSalaryGradeLateralC MonthsPTitle MonthsSubFunc MonthsPromSalaryGrade MonthsSalaryGrade

* 3.b. Generating additional variables for managers only

* Generating Round IA info
gen IA = 1 if EmpType >=3 & EmpType <=7
replace IA =0 if IA==.
by IDlse (YearMonth), sort: gen RoundIA1 = (Country != Country[_n-1] & _n > 1 & IA==1)
by IDlse (YearMonth), sort: gen RoundIA2 = (IA[_n] & _n==1)
gen RoundIA = RoundIA1 + RoundIA2
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIA)
drop IA RoundIA1 RoundIA2 RoundIA
rename RoundIAcum RoundIA

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

* Generating TenureWL: the number of years a person has been in the current WL.
* if first observed WL == 1, extrapolate from Tenure at the earliest obs. for each individual.
* Missing values if WL > 1 and there is no previous obs.

gsort IDlse YearMonth

bys IDlse WL (YearMonth): egen TenureWLMax = max(Tenure)
bys IDlse (YearMonth): gen TenureWLMaxLagFirst = TenureWLMax[_n-1] if WL != WL[_n-1]

bys IDlse WL: egen TenureWLMaxLag = min(TenureWLMaxLagFirst)

gen TenureWL = Tenure
replace TenureWL = Tenure - TenureWLMaxLag if WL !=1 

br IDlse YearMonth WL Tenure TenureWL
drop TenureWLMax TenureWLMaxLagFirst TenureWLMaxLag
order TenureWL, a(Tenure)

* 3.c. Renaming variables

* Specific cases
rename EmployeeNum ManagerNum
rename IDlse IDlseMHR

* Standard variables (adding Manager)
local Mvariables ///
HomeCountry ISOCodeHome CountryS ISOCode Cluster Market PositionTitle StandardJob StandardJobCode Func SubFunc ///
Female WL WLSalaryGrade AgeBand Tenure TenureWL EmpType RoundIA ///
LeaverType LeaverInv LeaverVol LeaverPerm LeaverTemp ///
SalaryGrade SalaryGradeC SalaryGradeOrder PromWL PromWLSalaryGrade PromSalaryGrade DemotionSalaryGrade ///
Pay Benefit Bonus Package PR PRI PRSnapshot VPA ///
PayMean BenefitMean BonusMean PackageMean PRMean PRSnapshotMean PRIMean VPAMean ///
PayLag1 BenefitLag1 BonusLag1 PackageLag1 PRLag1 PRSnapshotLag1 PRILag1 VPALag1 ///
PayLag2 BenefitLag2 BonusLag2 PackageLag2 PRLag2 PRSnapshotLag2 PRILag2 VPALag2 ///
PayLag3 BenefitLag3 BonusLag3 PackageLag3 PRLag3 PRSnapshotLag3 PRILag3 VPALag3 ///
PayLag4 BenefitLag4 BonusLag4 PackageLag4 PRLag4 PRSnapshotLag4 PRILag4 VPALag4 ///
PayIn TransferCountry TransferCountryC PromWLC PromSalaryGradeC DemotionSalaryGradeC TransferPTitle TransferPTitleC TransferSubFunc TransferSubFuncC TransferFunc TransferFuncC TransferSubFuncLateral TransferSubFuncLateralC TransferFuncLateral TransferFuncLateralC TransferPTitleLateral TransferPTitleLateralC PromSalaryGradeVertical PromSalaryGradeVerticalC PromSalaryGradeLateral PromSalaryGradeLateralC MonthsPTitle MonthsSubFunc MonthsPromSalaryGrade MonthsSalaryGrade

foreach var in `Mvariables' {
rename `var' `var'M
}

* 3.d. Compressing and saving MListChar

compress

save "$Managersdta/Temp/MListChar.dta", replace

*********************************************************************************
* 4. Merging AllSnapshotWCM with Mchar and adding new variables
*********************************************************************************

* 4.a. Adding MListchar variables by merging the file with AllSnapshotWCM.dta
use "$Managersdta/AllSnapshotWCM.dta", clear

merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/MListChar.dta"

/*
tempfile temp
save `temp'
keep if _merge == 1
drop _merge
save "$data/OldDatasetUnmatched.dta",replace
use `temp'
*/

drop if _merge ==2 
drop _merge

* 4.b. Generating additional variables & modifying some variables

* Span of control
bys YearMonth IDlseMHR: gen SpanControl = _N // number of direct reports
replace SpanControl =. if IDlseMHR==.
order SpanControl, a(IDlseMHR)
label var SpanControl "No. of employees reporting to same manager in current month"
* Country Size
bysort YearMonth Country: egen CountrySize = count(IDlse) // no. of employees by country and month
label var CountrySize "No. of employees in each country and month"

* Office
distinct Office // number of establishments 2550 (for WC)
distinct Country // number of countries: 117 (for WC)
quietly bys Office: gen dup_location = cond(_N==1,0,_n)
bys Country YearMonth: egen OfficeNum = count(Office) if (dup_location ==0 & Office !=. | dup_location ==1 & Office !=.) 
drop dup_location 
label var OfficeNum "No. of offices in each Country and Month"

* Additional variables useful for the analysis
egen CountryYM = group(Country YearMonth)
egen IDlseMHRYM = group(IDlseMHR YearMonth)
decode HomeCountryM, gen(HomeCountrySM)
order HomeCountrySM, a(HomeCountryM)


* 4.c. Compressing and saving in AllSnapshotWCM.dta.
compress

save "$Managersdta/AllSnapshotWCM.dta",replace





