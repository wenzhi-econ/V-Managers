********************************************************************************
**                     Cleaning Manager with IDlseMHR                         **
**                     BC workers & append all WC workers                     **
**                             27 Oct, 2020                                   **
/*******************************************************************************

This do-file:

1. Identifies managers in AllSnapshotBC.dta using the list of managers' IDlse
in ManagerIDReports.dta and tag them as 1 using "Manager" dummy.

2. Adds ISOCodeHome variable to the dataset.

3. Extracts relevant manager characteristics and adds new variables, saving them
in a dta file MListChar.dta.

4. Merges MListChar.dta with the original dataset and generates new variables.

Input: ManagerIDReports.dta, AllSnapshotWC.dta
Output: AllSnapshotBCM.dta

*/
* directory
cd "$dta"
*********************************************************************************
* 1. Identifying managers in the Original Dataset & adding manager IDlse
*********************************************************************************

* 1.a. creating Mlist

* using ManagerIDReports to create tempfile Mlist, which has IDlse of all
* employees who also happen to be a manager in given month.

use "ManagerIDReports.dta", clear

keep IDlseMHR YearMonth
rename IDlseMHR IDlse

duplicates drop IDlse YearMonth, force

* 1.b. I identify managers in AllSnapshot.dta using the tempfile.

drop if IDlse == . // 60 missing values, which is due to the missing values in IDlseMHR

save "$Managersdta/Temp/Mlist.dta", replace


********************************************************************************
* ADD TRANSFERS VARIABLES for MANAGERS
********************************************************************************

use "AllSnapshotWC.dta", clear
append using "AllSnapshotBC.dta"

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

* Country transfers 
gsort IDlse YearMonth
gen TransferCountry = 0 if Country!=. 
replace  TransferCountry = 1 if (IDlse == IDlse[_n-1] & Country != Country[_n-1] & Country!=.  )

gen z = TransferCountry
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Country!=.
gen TransferCountryC = z 
drop z 

* Promotion variables: PromWL OVERALL
gen z = PromWL
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 & PromWL!=.
replace z = 0 if z ==. & PromWL!=.
gen PromWLC = z 
drop z 

* Promotion variables: PromSalaryGrade OVERALL
gen z = PromSalaryGrade
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1  & PromSalaryGrade!=.
replace z = 0 if z ==. & PromSalaryGrade!=.
gen PromSalaryGradeC = z 
drop z 

* Demotion variables: DemotionSalaryGrade OVERALL
gen z = DemotionSalaryGrade
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1  & DemotionSalaryGrade!=.
replace z = 0 if z ==. & DemotionSalaryGrade!=.
gen DemotionSalaryGradeC= z 
drop z 

* Job transfer variables: Job title | position change OVERALL
gsort IDlse YearMonth
gen TransferPTitle = 0 if PositionTitle!="" & EmployeeNum!=.
replace  TransferPTitle = 1 if (IDlse == IDlse[_n-1] & PositionTitle != PositionTitle[_n-1] & PositionTitle!=""  ) | (IDlse == IDlse[_n-1] & EmployeeNum != EmployeeNum[_n-1] & EmployeeNum!=.)

gen z = TransferPTitle
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PositionTitle!="" & EmployeeNum!=.
gen TransferPTitleC = z 
drop z 

* Job transfer variables: Subfunction OVERALL
gsort IDlse YearMonth
gen TransferSubFunc = 0 & SubFunc !=.
replace  TransferSubFunc = 1 if IDlse == IDlse[_n-1] & SubFunc != SubFunc[_n-1] & SubFunc !=.

gen z = TransferSubFunc
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc !=.
gen TransferSubFuncC = z 
drop z 

*Job transfer variables: Function OVERALL
gsort IDlse YearMonth
gen TransferFunc = 0 if Func !=.
replace  TransferFunc = 1 if IDlse == IDlse[_n-1] & Func != Func[_n-1]  & Func !=.

gen z = TransferFunc
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Func !=.
gen  TransferFuncC = z 
drop z 

* Lateral sub func transfer (without promotion): Sub Function
gen TransferSubFuncLateral = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace TransferSubFuncLateral  = 1 if TransferSubFunc  == 1 & PromSalaryGrade==0

gen z = TransferSubFuncLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc !=.
gen TransferSubFuncLateralC = z 
drop z 

* Lateral func transfer (without promotion): Function
gen TransferFuncLateral = 0 if PromSalaryGrade!=. & TransferFunc!=.
replace TransferFuncLateral  = 1 if TransferFunc  == 1 & PromSalaryGrade==0

gen z = TransferFuncLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Func !=.
gen TransferFuncLateralC = z 
drop z 

* Lateral Job Position Move (without promotion): Job title | position change 
gen TransferPTitleLateral = 0 if PromSalaryGrade!=. & TransferPTitle!=.
replace TransferPTitleLateral = 1 if TransferPTitle  == 1 & PromSalaryGrade==0

gen z = TransferPTitleLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & TransferPTitle !=.
gen TransferPTitleLateralC = z 
drop z 

* Vertical Promotion: PromSalaryGrade without subfunc change  
gen PromSalaryGradeVertical = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace PromSalaryGradeVertical  = 1 if TransferSubFunc  == 0 & PromSalaryGrade==1

gen z = PromSalaryGradeVertical
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PromSalaryGrade !=.
gen PromSalaryGradeVerticalC = z 
drop z 

* Lateral Promotion: PromSalaryGrade with subfunc change  
gen PromSalaryGradeLateral = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace PromSalaryGradeLateral = 1 if PromSalaryGrade ==1 & TransferSubFunc ==1

gen z = PromSalaryGradeLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PromSalaryGrade !=.
gen PromSalaryGradeLateralC = z 
drop z 

* Months in position
bys IDlse TransferPTitleC: egen MonthsPTitle =  count(YearMonth)
label var MonthsPTitle "Tot. Months in Position Title"
* Months in subfunction
bys IDlse TransferSubFuncC: egen MonthsSubFunc =  count(YearMonth)
label var MonthsSubFunc "Tot. Months in Sub Function"
* Months in salary grade
bys IDlse SalaryGrade: egen MonthsSalaryGrade =  count(YearMonth)
label var MonthsSalaryGrade "Tot. Months in Salary Grade"
* Time since last promotion 
bys IDlse PromSalaryGradeC: egen MonthsPromSalaryGrade = rank(YearMonth)

quietly bys IDlse YearMonth:  gen dup = cond(_N==1,0,_n)
drop if BC==1 & dup >0 // if duplicates, only keep WC 
drop dup
merge 1:1 IDlse YearMonth using "$Managersdta/Temp/Mlist.dta"

drop if _merge == 2 // 12,956 unmatched obs. from ManagerIDReports.dta.

* the matched individuals are managers. I tag them generating a dummy Manager.

gen Manager = 0
replace Manager = 1 if _merge == 3
label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"

drop _merge

* 1.d. saving as AllSnapshotM.dta
save "AllSnapshotM.dta",replace

*********************************************************************************
* 2. Adding ISOCodeHome, ISOCode for home countries.
*********************************************************************************

* use AllSnapshotM.dta if it is not loaded or loaded but changed
* Note: I add 'if' clause to avoid wasting time to load already existing data.
* But I do not delete the code as it might be necessary to run this section separately.

if "`c(filename)'" != "$dta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$dta/AllSnapshotM.dta", clear
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

use "AllSnapshotM.dta", clear

replace HomeCountryS = "Palestine"  if HomeCountryS== "Palestinian Territory Occupied"

merge m:1 HomeCountryS using "$Managersdta/Temp/isocode.dta"
drop if _merge==2
drop _merge HomeCountryS

order ISOCodeHome, a(HomeCountry)

* 2.c. Updating AllSnapshotM.dta
save "AllSnapshotM.dta",replace

********************************************************************************
* 3. Preparing Manager Characteristics tempfile to merge with AllSnapshotM.dta
********************************************************************************

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$dta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$dta/AllSnapshotM.dta", clear
}

* 3.a. Dropping non-manager employees and unnecessary variables

keep if Manager ==1

keep IDlse EmployeeNum YearMonth Year BC ///
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
HomeCountry ISOCodeHome CountryS ISOCode Cluster Market PositionTitle StandardJob StandardJobCode Func SubFunc BC ///
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
* 4. Merging AllSnapshotM with Mchar and adding new variables
*********************************************************************************

* 4.a. Adding MListchar variables by merging the file with AllSnapshotM.dta
use "AllSnapshotM.dta", clear

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
distinct Office 
distinct Country 
quietly bys Office: gen dup_location = cond(_N==1,0,_n)
bys Country YearMonth: egen OfficeNum = count(Office) if (dup_location ==0 & Office !=. | dup_location ==1 & Office !=.)
drop dup_location 
label var OfficeNum "No. of offices in each Country and Month"

* Additional variables useful for the analysis
egen CountryYM = group(Country YearMonth)
egen IDlseMHRYM = group(IDlseMHR YearMonth)
decode HomeCountryM, gen(HomeCountrySM)
order HomeCountrySM, a(HomeCountryM)


* 4.c. Compressing and saving in AllSnapshotM.dta.
compress

save "$data/dta/AllSnapshotM.dta",replace



********************************************************************************
* GEN VARS
********************************************************************************

use "$data/dta/AllSnapshotM.dta", clear 

keep if BC==1

* Independent variables / clustering
 
* FirstYear FE
bys IDlse : egen FirstYearM = min(YearMonth)
label var  FirstYearM "FirstYear = min(YearMonth)"

bys IDlse : egen FirstYear = min(Year)
label var  FirstYear "FirstYear = min(Year)"

* Entry
gen Entry = 1 if FirstYearM ==YearMonth 
replace Entry = 0 if Entry==.
label var  Entry "=1 for first year month in the dataset"

* Clustering 
egen Block = group(Office Func)
order Block, a(YearMonth)

egen CountryYear = group(Country Year)
*egen Match = group(IDlse IDlseMHR)

* Team ID
bys IDlseMHR YearMonth: egen TeamID = sum(IDlse)
order TeamID, a(IDlseMHR)
label var TeamID "bys IDlseMHR YearMonth: egen TeamID = sum(IDlse)" 

********************************************************************************
 * Outcome variables - PR / Salary / VPA / Leaver / Promotion Change / Job Change Variables
********************************************************************************

* PR:  Log perf score
gen LogPR = ln(PR + 1)
gen LogPRSnapshot = ln(PRSnapshot +1)

* SALARY: LogPay, bonus, benefit, package   
gen LogPay = log(Pay)
gen LogBonus = log(Bonus+1)
gen LogBenefit = log(Benefit+1)
gen LogPackage = log(Package)
gen PayBonus = Pay + Bonus
gen LogPayBonus = log(PayBonus)
gen BonusPayRatio = Bonus/Pay

* VPA: LogVPA
gen LogVPA = log(VPA+1)

/* This code moved to FullSample 2.3.Cleaning Merge.do
* LEAVE: Leaver
local LeaverVar Leaver LeaverVol LeaverInv LeaverPerm LeaverTemp

foreach v in `LeaverVar' {
replace `v' = 0 if `v' !=1
}
* replacing 
replace LeaverInv =. if LeaverType == 2 & Leaver == 1
replace LeaverVol =. if LeaverType == 2 & Leaver == 1

*/
bys IDlse: egen LeaverID = sum(Leaver) // equals >1 for leavers (individual level variable)

gsort IDlse YearMonth
gen WeirdLeave = 1 if IDlse == IDlse[_n-1] & YearMonth == YearMonth[_n-1]+1 & Leaver[_n-1] == 1 & LeaverID>=1
replace WeirdLeave = 1 if IDlse == IDlse[_n+1] & YearMonth == YearMonth[_n+1]-1 & Leaver[_n] == 1 & LeaverID>=1

br IDlse YearMonth Leaver LeaverType if WeirdLeave == 1

* 2 such cases, with LeaverType == 2 ("LVR"), IDlse == 701247, 701250

* recoding these

foreach v in `LeaverVar' {
replace `v' = . if WeirdLeave ==1
}

drop WeirdLeave LeaverID

* I drop the promotion variable that was here as they are generated in FullSample 2.2.GenVar.do
/* PROMOTION !TO UPDATE - NO LONGER NEEDED?!
sort IDlse YearMonth
bys IDlse: gen PromChange = (SalaryGrade != SalaryGrade[_n-1]) if _n!=1
replace PromChange = 0 if PromChange == . // if there is no preceding Obs. for an individual, these variables are coded as MV.
* exception: data error, IDlse changes from WL1 to Wl2 and then back to WL1 after  2 months 
replace  PromChange =0 if IDlse == 439568 (*/

compress
save "$data/dta/AllSnapshotMBC", replace 

********************************************************************************
* APPEND BC AND WC>> !FINAL GLOBAL DATASET!
********************************************************************************

use "$data/dta/AllSnapshotMBC", clear 
append using "$data/dta/AllSnapshotWCCultureC"
save "$data/dta/ManagersBCWC", replace 

********************************************************************************
* CREATING !FINAL YEAR LEVEL DATASET! BC & WC 
********************************************************************************

use "$data/dta/AllSnapshotMBC", clear // BC
*use "$dta/AllSnapshotWCCultureC.dta", clear // WC

global mode  ISOCode CountryS Office OfficeCode Market Func SubFunc PositionTitle BC Female AgeBand Tenure WL SalaryGrade SalaryGradeC FTE EmpType EmpStatus LeaveType IDlseMHR PromSalaryGradeM PromSalaryGradeCM PromSalaryGradeLateralM PromSalaryGradeLateralCM PromSalaryGradeVerticalM PromSalaryGradeVerticalCM TransferCountryM TransferCountryCM TransferFuncM TransferFuncCM TransferSubFuncM TransferSubFuncCM TransferSubFuncLateralM TransferSubFuncLateralCM TransferFuncLateralM TransferFuncLateralCM TransferPTitleM TransferPTitleCM TransferPTitleLateralM TransferPTitleLateralCM PRM VPAM LeaverPermM LeaverInvM LeaverVolM FemaleM AgeBandM TenureM BCM
foreach var in $mode{
bys IDlse Year: egen `var'Mode = mode(`var')
replace `var' = `var'Mode
}

* leaving out the Months* variables as they require thinking about how to collapse 

global mode   Office OfficeCode Market Func SubFunc BC Female AgeBand Tenure WL SalaryGrade FTE EmpType EmpStatus LeaveType IDlseMHR PromSalaryGradeM PromSalaryGradeCM PromSalaryGradeLateralM PromSalaryGradeLateralCM PromSalaryGradeVerticalM PromSalaryGradeVerticalCM TransferCountryM TransferCountryCM TransferFuncM TransferFuncCM TransferSubFuncM TransferSubFuncCM TransferSubFuncLateralM TransferSubFuncLateralCM TransferFuncLateralM TransferFuncLateralCM TransferPTitleM TransferPTitleCM TransferPTitleLateralM TransferPTitleLateralCM PRM VPAM LeaverPermM LeaverInvM LeaverVolM FemaleM AgeBandM TenureM BCM

global mean FirstYear VPA  PR PRI Pay Bonus Benefit Package PayBonus LogPayBonus LogPay LogBonus PRSnapshot

global string ISOCode CountryS PositionTitle SalaryGradeC 

 global sum TransferCountry TransferCountryC TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC TransferSubFuncLateral TransferSubFuncLateralC TransferFuncLateral TransferFuncLateralC TransferPTitle TransferPTitleC TransferPTitleLateral TransferPTitleLateralC   PromSalaryGrade PromSalaryGradeC PromSalaryGradeLateral PromSalaryGradeLateralC PromSalaryGradeVertical PromSalaryGradeVerticalC LeaverPerm LeaverInv LeaverVol
 
collapse $mean  (max) $sum $mode (firstnm) $string, by(IDlse Year)

save "$data/dta/AllSnapshotMBCY", replace // BC
*save "$data/dta/AllSnapshotWCCultureCY", replace // WC

* APPEND BC AND WC>> FINAL YEAR DATASET
use "$data/dta/AllSnapshotMBCY", clear
append using "$data/dta/AllSnapshotWCCultureCY"
save "$data/dta/AllSnapshotY", replace 
