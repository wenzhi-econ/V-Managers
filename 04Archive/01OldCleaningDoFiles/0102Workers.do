/* 
Description of this do-file:

This do file creates a set of variables related to workers' characteristics.

Input files:
    "${RawMNEData}/AllSnapshotWC.dta" (raw data)

Output files:
    "${FinalData}/Workers.dta" (a panel dataset storing workers' outcomes)

RA: WWZ 
Time: 24/06/2024
*/

use "${RawMNEData}/AllSnapshotWC.dta", clear

xtset IDlse YearMonth 

keep IDlse YearMonth ///
    StandardJob Func SalaryGrade ///
    Office SubFunc Org4 OfficeCode ///
    Pay Bonus Benefit Package ///
    WL PromWL ///
    IDlseMHR ///
    Tenure AgeBand 

order IDlse YearMonth ///
    IDlseMHR ///
    Tenure AgeBand WL ///
    StandardJob Func SalaryGrade ///
    Office SubFunc Org4 OfficeCode ///  
    Pay Bonus Benefit Package ///
    PromWL 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate outcome variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_1. promotion (salary grade increases)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

* Change in Salary grade 
gsort IDlse YearMonth
generate ChangeSalaryGrade = 0 & SalaryGrade !=.
replace  ChangeSalaryGrade = 1 if IDlse == IDlse[_n-1] & SalaryGrade != SalaryGrade[_n-1] & SalaryGrade!=.

generate temp = ChangeSalaryGrade
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & SalaryGrade!=.
generate ChangeSalaryGradeC = temp 
drop temp  

label variable ChangeSalaryGrade  "= 1 in the month when an individual's SalaryGrade is diff. than in the preceding"
label variable ChangeSalaryGradeC "cumulative count of SalaryGrade increase for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_2. job transfer -- stamdard job changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

* Job transfer: Standard Job Desc 
gsort IDlse YearMonth
generate TransferSJ = 0 if StandardJob!="" 
replace  TransferSJ = 1 if (IDlse == IDlse[_n-1] & StandardJob != StandardJob[_n-1] & StandardJob!=""  )

generate temp = TransferSJ
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & StandardJob!=""
generate TransferSJC = temp 
drop temp

label variable TransferSJ  "= 1 in the month when an individual's StandardJob is diff. than in the preceding"
label variable TransferSJC "cumulative count of StandardJob transfers for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_3. job transfer -- stamdard job changes without salary grade changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate TransferSJV = TransferSJ
replace  TransferSJV = 0 if ChangeSalaryGrade==0	

generate temp = TransferSJV
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & StandardJob!=""
generate TransferSJVC = temp 
drop temp

label variable TransferSJV  "= 1 when his StandardJob is diff. than last month but SalaryGrade is the same"
label variable TransferSJVC "cumulative count of TransferSJ for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_4. job transfer -- function changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*Job transfer variables: Function 
gsort IDlse YearMonth
generate TransferFunc = 0 if Func !=.
replace  TransferFunc = 1 if IDlse == IDlse[_n-1] & Func != Func[_n-1]  & Func!=.

generate temp = TransferFunc
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & Func!=.
generate  TransferFuncC = temp 
drop temp 

label variable TransferFunc  "= 1 in the month when an individual's Func is diff. than in the preceding"
label variable TransferFuncC "cumulative count of Func transfers for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_5. internal transfer 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s1_5_1. measure 1. either office, subfunc, or org4
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

gsort IDlse YearMonth
generate TransferInternal = 0 & Office!=. & SubFunc!=. & Org4!=. 
replace  TransferInternal = 1 if IDlse==IDlse[_n-1] & ///
    ((OfficeCode!=OfficeCode[_n-1] & OfficeCode!=.) | (SubFunc!=SubFunc[_n-1] & SubFunc!=.) | (Org4!=Org4[_n-1] & Org4!=.))

generate temp = TransferInternal
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & SubFunc!=. & OfficeCode!=. & Org4!=.
generate TransferInternalC = temp 
drop temp 

label variable TransferInternal  "= 1 in the month when either SubFunc or Office or Org4 is diff than last month"
label variable TransferInternalC "cumulative count of internal transfer for an individual"


*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s1_5_2. measure 2. either office, standardJob, or org4
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
gsort IDlse YearMonth
generate TransferInternalSJ = 0 if Office!=. & StandardJob!="" & Org4!=. 
replace  TransferInternalSJ = 1 if IDlse==IDlse[_n-1] & ///
    ((OfficeCode!=OfficeCode[_n-1] & OfficeCode!=.) | (StandardJob!=StandardJob[_n-1] & StandardJob!="") | (Org4!=Org4[_n-1] & Org4!=.))

generate temp = TransferInternalSJ
by IDlse (YearMonth), sort: replace temp = temp[_n] +  temp[_n-1] if _n>1 
replace temp = 0 if temp ==. & StandardJob!="" & OfficeCode!=.  & Org4!=.
generate TransferInternalSJC = temp 
drop temp 

label variable TransferInternalSJ  "= 1 in the month when either either SJ or Office or Org4 is diff than last month"
label variable TransferInternalSJC "cumulative count of internal (job) transfer for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_6: pay 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

* Salary: LogPay, bonus, benefit, package   
generate LogPay        = log(Pay)
generate LogBonus      = log(Bonus+1)
generate LogBenefit    = log(Benefit+1)
generate LogPackage    = log(Package)
generate PayBonus      = Pay + Bonus
generate LogPayBonus   = log(PayBonus)
generate BonusPayRatio = Bonus/Pay

label variable LogPayBonus "Pay + bonus (logs)"
label variable LogPay      "Pay (logs)"
label variable LogBonus    "Bonus (logs)"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s1_7: promotion (work level increases) 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

* Promotion variables: PromWL 
generate temp = PromWL
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 & PromWL!=.
replace temp = 0 if temp==. & PromWL!=.
generate PromWLC = temp 
drop temp 

label variable PromWLC "cumulative count of work level promotions for an individual"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step X. store worker outcomes 
*??         panel data  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

compress 
save "${FinalData}/Workers.dta", replace 
