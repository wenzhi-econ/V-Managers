********************************************************************************
**                     Cleaning Manager with IDlseMHR                         **
**                              7 April, 2021                                 **
/*******************************************************************************

This do-file:

1. Identifies managers in AllSnapshot.dta using the list of managers' IDlse
in ManagerIDReports.dta and tag them as 1 using "Manager" dummy.

2. Extracts relevant manager characteristics and adds new variables, saving them
in a dta file MListChar.dta.

3. Merges MListChar.dta with the original dataset and generates new variables.

Input: ManagerIDReports.dta, AllSnapshotBC.dta
Output: $managersdta/AllSnapshotM.dta
*/

* directory
cd "$managersdta"

*********************************************************************************
* 1. Identifying managers in the Original Dataset & adding manager IDlse
*********************************************************************************

* 1.a. creating Mlist

* using ManagerIDReports to create tempfile Mlist, which has IDlse of all
* employees who also happen to be a manager in given month.

use "$fulldta/ManagerIDReports.dta", clear

keep IDlseMHR YearMonth
rename IDlseMHR IDlse

duplicates drop IDlse YearMonth, force

* 1.b. I identify managers in AllSnapshot.dta using the tempfile.

drop if IDlse == . // 60 missing values, which is due to the missing values in IDlseMHR

save "$managersdta/Temp/MlistBC.dta", replace


********************************************************************************
* GENERATE TRANSFERS VARIABLES FOR EVERYONE 
********************************************************************************

use "$fulldta/AllSnapshotBC.dta", clear 

order IDlse YearMonth Female AgeBand HomeCountry Country EmployeeNum ///
ManagerNum Tenure BC WL SalaryGrade FTE EmpType LeaveType PLeave EmpStatus ///
PositionTitle SubFunc Func Office Cluster Market Year CountryS MCO MasterType

isid IDlse YearMonth

********************************************************************************

* SALARY: LogPay, bonus, benefit, package   
gen LogPay = log(Pay)
gen LogBonus = log(Bonus+1)
gen LogBenefit = log(Benefit+1)
gen LogPackage = log(Package)
gen PayBonus = Pay + Bonus
gen LogPayBonus = log(PayBonus)
gen BonusPayRatio = Bonus/Pay

* Imputed performance 
gen PRI = PR
label var PRI "Imputed PR score using VPA buckets"
replace PRI = 1 if VPA <=25 & (Year >2018 | PR==.)
replace PRI = 2 if VPA >25 & VPA<=80 & (Year >2018 | PR==.)
replace PRI = 3 if VPA >80 & VPA<=105 & (Year >2018 | PR==.)
replace PRI = 4 if VPA >105 & VPA<=125 & (Year >2018 | PR==.)
replace PRI = 5 if VPA >125 & Year >2018 & VPA!=.

* 1 if VPA <=50 
* 2 VPA >50 & VPA <= 80
* 3 80- 100
* 4 100-115

*Pay Increase 
gsort IDlse YearMonth
gen PayIn = 1 if (IDlse == IDlse[_n-1] & Pay > Pay[_n-1] ) & Pay!=.
replace PayIn= 0 if PayIn==.  & Pay!=.
label var PayIn "Dummy, equals 1 in the month when Pay is greater than in the preceding"

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

* Promotion variables: PromWL 
gen z = PromWL
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 & PromWL!=.
replace z = 0 if z ==. & PromWL!=.
gen PromWLC = z 
drop z 

label var PromWLC "CUMSUM from dummy=1 in the month when WL is greater than in the preceding month"

* Change in Salary grade 
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

* Job transfer variables: Job title | position change
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

* Indicator for transfer variables - Hesh definition: office - org id 4 - subfunc 
gsort IDlse YearMonth
gen  TransferInternal = 0 & Office !=. & SubFunc!=. & Org4!=. 
replace TransferInternal = 1 if IDlse == IDlse[_n-1] &  ( (OfficeCode != OfficeCode[_n-1] &  OfficeCode  !=.) | (SubFunc != SubFunc[_n-1] &  SubFunc  !=.) | (Org4!= Org4[_n-1] &  Org4  !=.) )
label var  TransferInternal "Dummy, equals 1 in the month when either subfunc or Office or org4 is diff. than in the preceding"

gen z = TransferInternal
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc!=. & OfficeCode!=.  & Org4!=.
gen TransferInternalC = z 
drop z 

label var  TransferInternalC "CUMSUM from dummy=1 in the month when either subfunc or Office or org4 is diff. than in the preceding"

* Job transfer variables: Subfunction 
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

*Job transfer variables: Function 
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

* Job transfer: Standard Job Desc 
gsort IDlse YearMonth
gen TransferSJ = 0 if StandardJob!="" 
replace  TransferSJ = 1 if (IDlse == IDlse[_n-1] & StandardJob != StandardJob[_n-1] & StandardJob!=""  )

gen z = TransferSJ
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & StandardJob!=""
gen TransferSJC = z 
drop z

* Months in position
bys IDlse TransferSJC: egen MonthsSJ =  count(YearMonth)
label var MonthsSJ "Tot. Months in Standard Job Description"
* Months in subfunction
bys IDlse TransferSubFuncC: egen MonthsSubFunc =  count(YearMonth)
label var MonthsSubFunc "Tot. Months in Sub Function"
* Months in WL
bys IDlse PromWLC: egen MonthsWL =  count(YearMonth)
label var MonthsWL "Tot. Months in WL"
* Months in salary grade
bys IDlse ChangeSalaryGradeC: egen MonthsSG =  count(YearMonth)
label var MonthsSG "Tot. Months in Salary Grade"
* Time since last salary grade change
bys IDlse ChangeSalaryGradeC: egen MonthsSGCum = rank(YearMonth)
label var MonthsSGCum "Time since last change in Salary Grade"
* Months in firm
gen o = 1
bys IDlse (YearMonth), sort: gen TenureMonths = sum(o)
label var TenureMonths "Tot number of months in the firm up to current month"
drop o

* Time to promotion
sort IDlse YearMonth
bys IDlse ChangeSalaryGradeC (YearMonth), sort: egen TimetoChangeSG = max(cond(ChangeSalaryGradeC[_n]!=ChangeSalaryGradeC[_n-1] & IDlse[_n] == IDlse[_n-1], MonthsSG[_n-1] ,.) )
replace TimetoChangeSG = TenureMonths if ChangeSalaryGradeC==0
replace TimetoChangeSG = . if ChangeSalaryGradeC==.
label var TimetoChangeSG "Tot. Months in Salary Grade (SG) prior change in SG"

* Managers 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/MlistBC.dta"

drop if _merge == 2 // 12,956 unmatched obs. from ManagerIDReports.dta.

* the matched individuals are managers. I tag them generating a dummy Manager.

gen Manager = 0
replace Manager = 1 if _merge == 3
label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"

drop _merge

* saving as AllSnapshotM.dta
compress
save "$managersdta/AllSnapshotBCM.dta",replace

*********************************************************************************
* Adding PW
*********************************************************************************

merge m:1 IDlse using "$fulldta/AttendancePW.dta" 
drop if _merge ==2
drop _merge

* PW
gen DidPWPost = 0 
replace  DidPWPost = 1 if  Year >= PWYear 

* saving as AllSnapshotM.dta
compress
save "$managersdta/AllSnapshotBCM.dta",replace

********************************************************************************
* Preparing Manager Characteristics tempfile to merge with AllSnapshotM.dta
* MANAGER-YM LEVEL CHARACTERISTICS 
********************************************************************************

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$managersdta/AllSnapshotBCM.dta" | `c(changed)' == 1 {
use "$managersdta/AllSnapshotBCM.dta", clear
}

*Dropping non-manager employees and unnecessary variables

keep if Manager ==1

* MANAGERS CHARS 
 global Mvariables HomeCountry HomeCountryISOCode Country CountryS Office OfficeCode ISOCode Cluster Market PositionTitle StandardJob StandardJobCode Func SubFunc Female WL AgeBand Tenure EmpType MasterType LeaverType LeaverInv LeaverVol LeaverPerm LeaverTemp SalaryGrade LogPayBonus Pay Benefit Bonus Package PR PRI PRSnapshot VPA PayIn  TransferCountry TransferCountryC PromWL PromWLC  TransferPTitle TransferPTitleC TransferSubFunc  TransferSubFuncC TransferFunc TransferFuncC TransferInternal  TransferInternalC MonthsSJ MonthsSubFunc MonthsWL MonthsSG MonthsSGCum   ChangeSalaryGrade ChangeSalaryGradeC TimetoChangeSG TransferSJ TransferSJC DidPWPost

keep IDlse YearMonth Year $Mvariables

*Renaming variables

* Specific cases
rename IDlse IDlseMHR

foreach var in $Mvariables  {
rename `var' `var'M
}

* Compressing and saving MListChar
compress
save "$managersdta/Temp/MListCharBC.dta", replace

********************************************************************************
* Merging AllSnapshotM with Mchar 
********************************************************************************

* Adding MListchar variables by merging the file with AllSnapshotM.dta

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$managersdta/AllSnapshotBCM.dta" | `c(changed)' == 1 {
use "$managersdta/AllSnapshotBCM.dta", clear
}
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MListCharBC.dta"
drop if _merge ==2 
drop _merge
compress
save "managersdta/AllSnapshotBCM.dta", replace 

*********************************************************************************
* Generating additional variables & modifying some variables
*********************************************************************************

* number of direct reports
bys YearMonth IDlseMHR: gen NoReportees = _N // number of direct reports
replace NoReportees =. if IDlseMHR==.
order NoReportees, a(IDlseMHR)
label var NoReportees "No. of employees reporting to same manager in current month"

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

********************************************************************************
  * Flags & controls 
********************************************************************************

* first ym
bys IDlse (YearMonth), sort: gen FirstYM = YearMonth == YearMonth[1]
label var FirstYM "=1 if first YM for employee"

* FlagUFLP 
by IDlse: egen FlagUFLP= max(UFLPStatus)
label var FlagUFLP "=1 if IDlse ever was UFLP"

* Manager round  
by IDlse (YearMonth), sort: gen ManagerRound = (IDlseMHR != IDlseMHR[_n-1] & _n > 1)
by IDlse (YearMonth), sort: gen ManagerRoundcum = sum(ManagerRound)
replace ManagerRound =  ManagerRoundcum +1
drop ManagerRoundcum
label var ManagerRound "How many managers employee changes"

* Diff nationality
gen OutGroup = 0
replace OutGroup = 1 if HomeCountryISOCode !=  HomeCountryISOCodeM
replace OutGroup = . if ( HomeCountryISOCode == "" |  HomeCountryISOCodeM=="")
label var OutGroup "=1 if employee has different HomeCountry of manager"

* Same gender
gen SameGender = 0
replace SameGender = 1 if Female == FemaleM
replace SameGender = . if (Female== . | FemaleM == .)
label var SameGender "=1 if employee has same gender as manager"

* Same age
gen SameAge=0
replace SameAge = 1 if AgeBand == AgeBandM 
replace SameAge= . if (AgeBand ==. | AgeBandM ==.)
label var SameAge "=1 if employee has same ageband of manager"

* Same PW
gen BothPW=0
replace BothPW = 1 if (DidPWPost ==1 &  DidPWPostM ==1)
replace BothPW= . if (DidPWPost ==. | DidPWPostM ==.)
label var BothPW "=1 if employee & manager have done PW"

********************************************************************************
* EVENT STUDY DUMMIES 
********************************************************************************

gsort IDlse YearMonth 
gen ChangeM = 0 
replace ChangeM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1]   )
replace ChangeM = . if IDlseMHR ==. 
bys IDlse: egen mm = min(YearMonth)
replace ChangeM = 0  if YearMonth ==mm & ChangeM==1
drop mm 


* Compressing and saving in AllSnapshotBCM.dta.
compress
save "$managersdta/AllSnapshotBCM.dta",replace




