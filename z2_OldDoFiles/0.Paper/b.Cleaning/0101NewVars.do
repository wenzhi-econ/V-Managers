
/* 
Description of this do file:
    This do file generates about 20 new employee-level variables using the raw dataset "${managersMNEdata}/AllSnapshotWC.dta".
    The variables include:
        manager id imputation
        pay
        performance
        age
        pay increase
        moving to a new country 
        promotion (work level increases)
        promotion (salary grade increases)
        job transfer -- position title changes
        job transfer -- either one of the three (office, sub-function or org4) changes
        job transfer -- org4 changes 
        job transfer -- org5 changes 
        job transfer -- office changes 
        job transfer -- subfunction changes 
        job transfer -- function changes
        job transfer -- stamdard job changes 
        tenure in current job 
        promotion time 
        time of WL promotion (to idenfity high-flyer managers)
        entry time and a new hire dummy for an employee-year-month


This is copied from "1.Cleaning/1.1.CleanData.do" and "1.Cleaning/1.3.CleanCulture".
Major changes of this file:
    I changed paths which contain raw datasets.
    To facilitate understanding of this do file, I added several comments.
    I slightly changed the order of several code blocks to make it easier to understand.
    I deleted some unnecessary that were originally commented out.
    I commented out the PW block, as it seems more relevant to another project. 

Input files:
    "${managersMNEdata}/AllSnapshotWC.dta" (considered as raw data)

Output files:
    "${managersdta}/AllSnapshotWC_NewVars.dta"

RA: WWZ 
Time: 18/3/2024
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? generate individual variables (for both employees and managers)
*??   in particular, variables indicating job transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${managersMNEdata}/AllSnapshotWC.dta", clear

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s1: manager id imputation
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s2: pay 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

* SALARY: LogPay, bonus, benefit, package   
gen LogPay = log(Pay)
gen LogBonus = log(Bonus+1)
gen LogBenefit = log(Benefit+1)
gen LogPackage = log(Package)
gen PayBonus = Pay + Bonus
gen LogPayBonus = log(PayBonus)
gen BonusPayRatio = Bonus/Pay

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s3: performance 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

* Imputed performance 
gen PRI = PR
label var PRI "Imputed PR score using VPA buckets"
replace PRI = 1 if VPA <=25 & (Year >2018 | PR==.)
replace PRI = 2 if VPA >25 & VPA<=80 & (Year >2018 | PR==.)
replace PRI = 3 if VPA >80 & VPA<=105 & (Year >2018 | PR==.)
replace PRI = 4 if VPA >105 & VPA<=125 & (Year >2018 | PR==.)
replace PRI = 5 if VPA >125 & Year >2018 & VPA!=.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s4: age  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s5: pay increase   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

* Pay Increase 
gsort IDlse YearMonth
gen PayIn = 1 if (IDlse == IDlse[_n-1] & Pay > Pay[_n-1] ) & Pay!=.
replace PayIn= 0 if PayIn==.  & Pay!=.
label var PayIn "Dummy, equals 1 in the month when Pay is greater than in the preceding"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s6: move to a new country  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s7: promotion (work level increases)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

* Promotion variables: PromWL 
gen z = PromWL
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 & PromWL!=.
replace z = 0 if z ==. & PromWL!=.
gen PromWLC = z 
drop z 

label var PromWLC "CUMSUM from dummy=1 in the month when WL is greater than in the preceding month"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s8: promotion (salary grade increases)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s9: job transfer -- position title changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s10: job transfer -- either one of the three (office, sub-function or org4) changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s11: job transfer -- org4 changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s12: job transfer -- org5 changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s13: job transfer -- office changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s14: job transfer -- subfunction changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s15: job transfer -- function changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s16: job transfer -- stamdard job changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

* Job transfer: Standard Job Desc 
gsort IDlse YearMonth
gen TransferSJ = 0 if StandardJob!="" 
replace  TransferSJ = 1 if (IDlse == IDlse[_n-1] & StandardJob != StandardJob[_n-1] & StandardJob!=""  )

gen z = TransferSJ
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & StandardJob!=""
gen TransferSJC = z 
drop z

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s17: tenure in current job 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s18: promotion time 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s19: time of WL promotion
*??      this is to identify high-flyer managers 
*??      3 variables are generated: EarlyAge EarlyAgeTenure EarlyTenure
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s19-1: necessary variables related to age, tenure, and work level (WL)
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

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

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s19-2: variable EarlyAge: based on minimum age & tenure - strict 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

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
label var EarlyAge "Fast track manager based on age when promoted (WL)"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s19-3: variable EarlyAgeTenure: based on minimum age & tenure - laxer  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

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

label var EarlyAgeTenure "Fast track manager based on age-tenure when promoted (WL)"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s19-4: variable EarlyTenure: based on minimum tenure  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s20: entry time and whether the employee is a new hire 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

* Cohort - year of hire
bys IDlse: egen YearHire = min(Year)
bys IDlse: egen TenureMin = min(Tenure)
replace YearHire = 9999 if YearHire == 2011 & TenureMin >=1 
    // censoring, as we cannot knwo their entry year using current dataset 

* New hire dummy 
gen NewHire =  YearHire==Year 
gen TenureBelow1 = Tenure<1 
gen TenureBelowEq1 = Tenure<=1 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s21: save the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

compress
save "${managersdta}/AllSnapshotWC_NewVars.dta", replace 

