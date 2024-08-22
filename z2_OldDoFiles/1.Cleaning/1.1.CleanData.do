********************************************************************************
**                     Cleaning Manager with IDlseMHR                         **
**                              June, 2022                                 **
/*******************************************************************************

This do-file:

1. Identifies managers in AllSnapshot.dta using the list of managers' IDlse
in ManagerIDReports.dta and tag them as 1 using "Manager" dummy.

2. Extracts relevant manager characteristics and adds new variables, saving them
in a dta file MListChar.dta.

3. Merges MListChar.dta with the original dataset and generates new variables.

Input: ManagerIDReports.dta,AllSnapshotWC.dta, AllSnapshotBC.dta
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

save "$managersdta/Temp/Mlist.dta", replace


********************************************************************************
* GENERATE TRANSFERS VARIABLES FOR EVERYONE 
********************************************************************************

use "$fulldta/AllSnapshotWC.dta", clear 
xtset IDlse YearMonth 
* replacing the instances where only 1 month is missing 
foreach var in IDlseMHR   {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. // time of hire 
}

order IDlse YearMonth Female AgeBand HomeCountry Country EmployeeNum ///
ManagerNum Tenure BC WL SalaryGrade FTE EmpType LeaveType PLeave EmpStatus ///
PositionTitle SubFunc Func Office Cluster Market  Year CountryS MCO MasterType

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

* continuous age band 
decode AgeBand, gen(AgeBandS)
replace AgeBandS = "Age 30 - 39" if AgeBandS == "Age Under 18" & IDlse == 474759
replace AgeBandS = "Age 30 - 39" if AgeBandS == "Age Under 18" & IDlse == 647330
replace AgeBand = 2 if AgeBandS == "Age 30 - 39"

gen AgeContinuous = .
replace AgeContinuous = 24 if AgeBandS == "Age 18 - 29"
replace AgeContinuous = 35 if AgeBandS == "Age 30 - 39"
replace AgeContinuous = 45 if AgeBandS == "Age 40 - 49"
replace AgeContinuous = 55 if AgeBandS == "Age 50 - 59"
replace AgeContinuous = 65 if AgeBandS == "Age 60 - 69"

* 1 if VPA <=50 
* 2 VPA >50 & VPA <= 80
* 3 80- 100
* 4 100-115

********************************************************************************
* M TYPE: CHAMPIONS, FASTEST STARTEST 
********************************************************************************

/* tenure thresholds 
A. entry level WL1: 
WL2: 3-4 YEARS - 1 PERIOD [20-30 age 1]
WL3: 9-11 YEARS - 2 PERIOD  [30-40 age 2]
WL4: 19-21 YEARS - 3 PERIOD [40-50 age 3]
WL5: 30 YEARS [50-60 age 4]

B. entry level WL2: 
WL3: 5 YEARS - 2 PERIOD 
WL4: 15 YEARS - 3 PERIOD 
WL5: 25 YEARS

C. entry level WL3: 
WL4: 10 YEARS - 3 PERIOD 
WL5: 20 YEARS

D. entry level WL4:  
WL5: 10 YEARS

* In practice in my sample, 9 years, I only experience managers moving from to the next level 
gcollapse o Tenure , by(IDlse WL )
bys IDlse: egen mm = min(WL)
bys IDlse: egen mmA = max(WL)
distinct IDlse if  mm ==1 & mmA>2 // 240 employees 

*/

* tenure- WL type of manager
gen WLAgg = WL
replace  WLAgg = 5 if WL > 4 & WL!=.

egen twl = tag(IDlse WLAgg)
egen tt = tag(IDlse)
bys IDlse: egen DistinctWL = total(twl)
ta DistinctWL // only 13% has 2 and 0.5% has 3 diff. WL 
label var DistinctWL "Number of WL per employee"
bys IDlse WLAgg: egen TenureMinByWL = min(Tenure) // min tenure by WL 
bys IDlse WLAgg: egen AgeMinByWL = min(AgeBand) // min tenure by WL 
label value AgeMinByWL AgeBand 
bys IDlse: egen MinWL = min(WLAgg) // starting WL 
bys IDlse: egen MaxWL = max(WLAgg) // last observed WL 
bys IDlse: egen AgeMinMaxWL = min( cond(WL == MaxWL, AgeBand, .) ) // starting WL 
bys IDlse: egen TenureMinMaxWL = min( cond(WL == MaxWL, Tenure, .) ) // starting WL
bys IDlse: egen TenureMinMinWL = min( cond(WL == MinWL, Tenure, .) ) // starting WL
bys IDlse: egen TenureMaxWLMonths = count(cond(WL==MaxWL, YearMonth, .) ) // number of months on max WL 
gen TenureMaxWL = TenureMaxWLMonths/12 
gen diffTenureMaxMinWL = TenureMinMaxWL- TenureMinMinWL

************** ************** ************** ************** **************  
* EarlyAge based on minimum age & tenure - strict 
************** ************** ************** ************** **************  

ta AgeMinByWL  if WLAgg ==3
* all WL 1 are 0 as by def. I do not know if they become WL 2 
gen EarlyAge = 0 
* from WL1 to WL2
su TenureMaxWL if MaxWL ==2 & tt==1,d
replace EarlyAge = 1 if MaxWL ==2 &  AgeMinMaxWL ==1 & TenureMaxWL<=6 // take away managers that stay in WL for a long time  
replace EarlyAge = 1 if MaxWL ==2 & TenureMinMaxWL <=4 & MinWL==1 & TenureMaxWL<=6 // managers that start a little bit later, but get promoted within 3 years (median)
* from WL2 to WL3
replace EarlyAge = 1 if MaxWL ==3 &  AgeMinMaxWL <=2  & TenureMinMaxWL <=10 
*replace EarlyAge = 1 if MaxWL ==3 &  diffTenureMaxMinWL <8 & MinWL==2 // managers that start a little bit later promoted within 7 years from WL2
*replace EarlyAge = 1 if MaxWL ==3 &  TenureMinMaxWL <11 & MinWL==1 // managers that start a little bit later promoted within 10 years from WL1  
* from WL3 to WL4 
replace EarlyAge = 1 if MaxWL ==4 &  AgeMinMaxWL <=2 // & TenureMinMaxWL <21
*replace EarlyAge = 1 if MaxWL ==4 &  TenureMinMaxWL <21 & MinWL==2 // managers that start a little bit later promoted within 9 years from WL1 
*replace EarlyAge = 1 if MaxWL ==4 &  diffTenureMaxMinWL <11 & MinWL==3 // managers that start a little bit later promoted within 6 years from WL2 
* from WL4 to WL5+ 
replace EarlyAge = 1 if MaxWL >4 &   AgeMinMaxWL <=3 // & TenureMinMaxWL <31
*replace EarlyAge = 1 if MaxWL >4 &  TenureMinMaxWL <31 & MinWL==3 // managers that start a little bit later promoted within 9 years from WL1 
*replace EarlyAge = 1 if MaxWL >4 &  diffTenureMaxMinWL <6 & MinWL==4 // managers that start a little bit later promoted within 6 years from WL2 
label var EarlyAge "Fast track  manager based on age when promoted (WL)"

************** ************** ************** ************** **************  
* EarlyAge based on minimum age & tenure - laxer  
************** ************** ************** ************** **************  

ta AgeMinByWL  if WLAgg ==3

* all WL 1 are 0 as by def. I do not know if they become WL 2 
gen EarlyAgeTenure = 0 

* from WL1 to WL2
replace EarlyAgeTenure = 1 if MaxWL ==2 &  AgeMinMaxWL ==1 & TenureMaxWL<=6 // take away managers that stay in WL for a long time
replace EarlyAge = 1 if MaxWL ==2 & TenureMinMaxWL <=4 & MinWL==1 & TenureMaxWL<=6 // managers that start a little bit later, but get promoted within 3 years (median)

* from WL2 to WL3
replace EarlyAgeTenure = 1 if MaxWL ==3 &  AgeMinMaxWL <=2 & TenureMinMaxWL <=10 // & TenureMinMaxWL <11
su diffTenureMaxMinWL if MaxWL==3  & MinWL==1 & tt==1, d
replace EarlyAgeTenure = 1 if MaxWL ==3 &   diffTenureMaxMinWL <=9 & MinWL==1 // managers that start a little bit later promoted within 9 years from WL1  

* from WL3 to WL4 
replace EarlyAgeTenure = 1 if MaxWL ==4 &  AgeMinMaxWL <=2 // & TenureMinMaxWL <21

* from WL4 to WL5+ 
replace EarlyAgeTenure = 1 if MaxWL >4 &   AgeMinMaxWL <=3 // & TenureMinMaxWL <31

label var EarlyAgeTenure "Fast track  manager based on age-tenure when promoted (WL)"

* EarlyTenure based on minimum tenure 
// from WL 1 to 2 //
gen EarlyTenure = 1 if  WLAgg ==2 & TenureMinByWL<6 & MinWL ==1 // observed in data starting from WL1 

// from WL 2 to 3 //
replace EarlyTenure =1 if WLAgg ==3 & TenureMinByWL<6   & MinWL ==2 // case 1: individual is mid-career recruit WL2
replace EarlyTenure =1 if WLAgg ==3 & TenureMinByWL<11   & MinWL <=2 & AgeBand <=2 // case 2: individual started in WL1 but data censored 

// from WL 3 to 4 //
replace EarlyTenure =1 if WLAgg ==4 & TenureMinByWL<11   & MinWL ==3 // case 1: individual is mid-career recruit WL3
replace EarlyTenure =1 if WLAgg ==4 & TenureMinByWL<16   & MinWL <=3 & AgeBand <=3 // case 2: individual is grown internally from WL2 
replace EarlyTenure =1 if WLAgg ==4 & TenureMinByWL<21   & MinWL <=3 & AgeBand <=3 // case 3: individual is grown internally from WL1 

// from WL 4 to 5/6 //
replace EarlyTenure =1 if WLAgg >=5 & TenureMinByWL<11   & MinWL ==4 // case 1: individual is mid-career recruit WL4
replace EarlyTenure =1 if WLAgg >=5 & TenureMinByWL<21   & MinWL <=4 & AgeBand <=4 // case 2: individual is grown internally from WL3 
replace EarlyTenure =1 if WLAgg >=5 & TenureMinByWL<26   & MinWL <=4 & AgeBand <=4 // case 3: individual is grown internally from WL2 
replace EarlyTenure =1 if WLAgg >=5 & TenureMinByWL<31   & MinWL <=4 & AgeBand <=4 // case 4: individual is grown internally from WL1

replace EarlyTenure = 0 if EarlyTenure ==. 
bys IDlse: egen z = max(EarlyTenure)
replace EarlyTenure = z 
drop z 
label var EarlyTenure "Fast track manager based on tenure"
 
* Pay Increase 
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

* Indicator for transfer variables - Hesh definition applied to standard job (instead of subfunction): office - org id 4 - standardJob 
gsort IDlse YearMonth
gen  TransferInternalSJ = 0 & Office !=. & StandardJob!="" & Org4!=. 
replace TransferInternalSJ = 1 if IDlse == IDlse[_n-1] &  ( (OfficeCode != OfficeCode[_n-1] &  OfficeCode  !=.) | (StandardJob!= StandardJob[_n-1] &  StandardJob!="") | (Org4!= Org4[_n-1] &  Org4  !=.) )
label var  TransferInternalSJ "Dummy, equals 1 in the month when either SJ or Office or org4 is diff. than in the preceding"

gen z = TransferInternalSJ
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & StandardJob!="" & OfficeCode!=.  & Org4!=.
gen TransferInternalSJC = z 
drop z 

label var  TransferInternalSJC "CUMSUM from dummy=1 in the month when either subfunc or Office or org4 is diff. than in the preceding"

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

* Job transfer variables: Org4 
gsort IDlse YearMonth
gen TransferOrg4 = 0 if Org4 !=.
replace  TransferOrg4 = 1 if IDlse == IDlse[_n-1] & Org4 != Org4[_n-1] & Org4 !=.
label var  TransferOrg4 "Dummy, equals 1 in the month when Org4 is diff. than in the preceding"

gen z = TransferOrg4
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Org4 !=.
gen TransferOrg4C = z 
drop z 

label var TransferOrg4C "CUMSUM from dummy=1 in the month when Org4 is diff. than in the preceding"

* Job transfer variables: Org5 
gsort IDlse YearMonth
gen TransferOrg5 = 0 if Org5 !=.
replace  TransferOrg5 = 1 if IDlse == IDlse[_n-1] & Org5 != Org5[_n-1] & Org5 !=.
label var  TransferOrg5 "Dummy, equals 1 in the month when Org5 is diff. than in the preceding"

gen z = TransferOrg5
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Org5 !=.
gen TransferOrg5C = z 
drop z 

label var TransferOrg5C "CUMSUM from dummy=1 in the month when Org5 is diff. than in the preceding"

* Change in Office
gsort IDlse YearMonth
gen ChangeOffice = 0 & OfficeCode !=.
replace  ChangeOffice = 1 if IDlse == IDlse[_n-1] & OfficeCode != OfficeCode[_n-1] & OfficeCode !=.
label var ChangeOffice "Equals 1 when OfficeCode is different than in the preceding month"

gen z = ChangeOffice
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & OfficeCode !=.
gen ChangeOfficeC = z 
drop z 

label var ChangeOfficeC "CUMSUM from dummy=1 in the month when OfficeCode is diff. than in the preceding"

* Job transfer variables: Subfunction 
gsort IDlse YearMonth
gen TransferSubFunc = 0 if SubFunc !=.
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
* Months in function
bys IDlse TransferFuncC: egen MonthsFunc =  count(YearMonth)
label var MonthsFunc "Tot. Months in Function"
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
bys IDlse: egen mT = min(Tenure)
bys IDlse ChangeSalaryGradeC: egen cT = max(Tenure)
replace cT = cT - mT
xtset IDlse YearMonth
gen dT = d.cT
bys IDlse ChangeSalaryGradeC: egen dTT = max(dT)
replace dTT = cT if ChangeSalaryGradeC ==0 
xtset IDlse YearMonth
gen ldTT = l.dTT
bys IDlse ChangeSalaryGradeC (YearMonth), sort: gen YearstoChangeSG = ldTT[1]
drop cT mT dT ldTT dTT
replace YearstoChangeSG = . if YearstoChangeSG < 0
label var YearstoChangeSG "Years in Salary Grade (SG) prior change in SG"

bys IDlse ChangeSalaryGradeC (YearMonth), sort: egen TimetoChangeSG = max(cond(ChangeSalaryGradeC[_n]!=ChangeSalaryGradeC[_n-1] & IDlse[_n] == IDlse[_n-1], MonthsSG[_n-1] ,.) )
replace TimetoChangeSG = TenureMonths if ChangeSalaryGradeC==0
replace TimetoChangeSG = . if ChangeSalaryGradeC==.
label var TimetoChangeSG "Tot. Months in Salary Grade (SG) prior change in SG"

* Managers 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/Mlist.dta"

drop if _merge == 2 // 12,956 unmatched obs. from ManagerIDReports.dta.

* the matched individuals are managers. I tag them generating a dummy Manager.

gen Manager = 0
replace Manager = 1 if _merge == 3
label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"

drop _merge

* saving as AllSnapshotM.dta
compress
save "$managersdta/AllSnapshotM.dta",replace

*********************************************************************************
* Adding PW
*********************************************************************************

merge m:1 IDlse using "$fulldta/AttendancePW.dta" // uses the earlier date in case of people doing the PW multiple times 
*merge m:1 IDlse using "$Purpose/PWCompletion.dta" // more info on who was invited but did not attend & uses the last date in case of people doing the PW multiple times  
drop if _merge ==2
drop _merge

* PW
gen DidPWPost = 0 
replace  DidPWPost = 1 if  YearMonth >= PWMonth
*replace  DidPWPost = 1 if  YearMonth >= mofd(CompletionDate)
replace DidPWPost = 0 if PWMonth==.
* saving as AllSnapshotM.dta

compress
save "$managersdta/AllSnapshotM.dta",replace

********************************************************************************
* Preparing Manager Characteristics tempfile to merge with AllSnapshotM.dta
* MANAGER-YM LEVEL CHARACTERISTICS 
********************************************************************************

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$managersdta/AllSnapshotM.dta", clear
}

*Dropping non-manager employees and unnecessary variables

keep if Manager ==1

* adding some leads and lags in manager transfers variables to account to differences in reporting times 
xtset IDlse YearMonth 
foreach var in TransferInternal TransferSubFunc TransferSJ{
forval i=1(1)3{
	gen `var'L`i' = l`i'.`var'
	gen `var'F`i' = f`i'.`var'
}
} 
gen PayBonusGrowthAnnual = LogPayBonus - l12.LogPayBonus

* MANAGERS CHARS 
 global Mvariables EarlyAge EarlyAgeTenure EarlyTenure MaxWL MinWL AgeMinMaxWL HomeCountry HomeCountryISOCode Country CountryS Office OfficeCode ISOCode Cluster Market PositionTitle StandardJob StandardJobCode Func SubFunc Female WL AgeBand Tenure EmpType MasterType LeaverType LeaverInv LeaverVol LeaverPerm LeaverTemp SalaryGrade LogPayBonus Pay Benefit Bonus PR PRI PRSnapshot VPA PayIn  TransferCountry TransferCountryC PromWL PromWLC  TransferPTitle TransferPTitleC TransferSubFunc TransferSubFuncL1 TransferSubFuncL2 TransferSubFuncL3 TransferSubFuncF1 TransferSubFuncF2 TransferSubFuncF3  TransferSubFuncC TransferFunc TransferFuncC TransferInternal TransferInternalL1 TransferInternalL2 TransferInternalL3 TransferInternalF1 TransferInternalF2 TransferInternalF3  TransferInternalC MonthsSJ MonthsSubFunc MonthsWL MonthsSG MonthsSGCum   ChangeSalaryGrade ChangeSalaryGradeC YearstoChangeSG TransferSJ TransferSJL1 TransferSJL2 TransferSJL3 TransferSJF1 TransferSJF2 TransferSJF3 TransferSJC DidPWPost PayBonusGrowthAnnual TransferOrg5 TransferOrg5C ChangeOffice ChangeOfficeC PLeave LeaveType

keep IDlse YearMonth Year $Mvariables

*Renaming variables

* Specific cases
rename IDlse IDlseMHR

foreach var in $Mvariables  {
rename `var' `var'M
}

* Compressing and saving MListChar
compress
save "$managersdta/Temp/MListChar.dta", replace

********************************************************************************
* Merging AllSnapshotM with Mchar 
********************************************************************************

* Adding MListchar variables by merging the file with AllSnapshotM.dta

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$managersdta/AllSnapshotM.dta", clear
}
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MListChar.dta"
drop if _merge ==2 
drop _merge
compress
save "$managersdta/AllSnapshotM.dta", replace 

*********************************************************************************
* Generating additional variables & modifying some variables
*********************************************************************************

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
  * Flags
********************************************************************************

* first ym
bys IDlse (YearMonth), sort: gen FirstYM = YearMonth == YearMonth[1]
label var FirstYM "=1 if first YM for employee"

* IAManager
gen IAM = 1 if MasterTypeM ==1 | MasterTypeM ==4
replace IAM =0 if IAM ==. & IDlseMHR!=.
label var IAM "=1 if IDlse's manager is on IA"

* FlagManager
bys IDlse: egen FlagManager= max(Manager)
label var FlagManager "=1 if IDlse ever was a manager"

* FlagIA
gen IA = 1 if MasterType ==1 | MasterType ==4
replace IA =0 if IA==.
by IDlse: egen FlagIA= max(IA)
label var FlagIA "=1 if IDlse ever did an IA"

* FlagIAManager
bys IDlse: egen FlagIAM= max(  IAM )
label var FlagIAM "=1 if IDlse ever had an IA manager"

* FlagUFLP 
by IDlse: egen FlagUFLP= max(UFLPStatus)
label var FlagUFLP "=1 if IDlse ever was UFLP"

* Manager round  
by IDlse (YearMonth), sort: gen ManagerRound = (IDlseMHR != IDlseMHR[_n-1] & _n > 1)
by IDlse (YearMonth), sort: gen ManagerRoundcum = sum(ManagerRound)
replace ManagerRound =  ManagerRoundcum +1
drop ManagerRoundcum
label var ManagerRound "How many managers employee changes"

* RoundIA for Employee
by IDlse (YearMonth), sort: gen Count = _n
by IDlse (YearMonth), sort: gen RoundIAM = (IDlseMHR != IDlseMHR[_n-1] & _n > 1  &  IAM   ==1)
replace RoundIAM = 1 if IAM==1 & FirstYM==1
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIAM)
replace RoundIAM =  RoundIAcum 
drop RoundIAcum Count

by IDlse: egen RoundIAMMax = max(RoundIAM)
label var RoundIAM "Number of time the employee has had a manager on IA"

* Compressing and saving in AllSnapshotM.dta.
compress
*keep if YearMonth <=tm(2020m3) // covid 
save "$managersdta/AllSnapshotM.dta",replace

* Manager on IA dataset
keep if FlagIA ==1 
* Save dataset
compress
*keep if YearMonth <=tm(2020m3) // covid 
save "$managersdta/IAManager.dta", replace


use "$managersdta/AllSnapshotM.dta" 
keep if FlagUFLP==1 
compress 
save "$managersdta/GraduatesRaw.dta", replace 


