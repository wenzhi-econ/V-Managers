/* 
This do file generates relevant outcome variables used in the paper.

Input:
    "${RawMNEData}/AllSnapshotWC.dta"

Output:
    "${TempData}/FinalFullSample.dta"

Description of the output dataset:
    (1) Full employee panel, with additional outcomes relevant to the event studies.
    (2) In particular, the dataset contains the following outcome variables:
        variables related to vertical promotion,
        variables related to lateral moves, and
        variables related to pay.

impt: This dataset will be used frequently if full sample dataset is required.

RA: WWZ 
Time: 2025-04-16
*/

use "${RawMNEData}/AllSnapshotWC.dta", clear
xtset IDlse YearMonth 
sort IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. outcome variables: vertical promotions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. salary grade increases
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate ChangeSalaryGrade = 0 & SalaryGrade!=.
replace  ChangeSalaryGrade = 1 if IDlse==IDlse[_n-1] & SalaryGrade!=SalaryGrade[_n-1] & SalaryGrade!=.

generate temp = ChangeSalaryGrade
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & SalaryGrade!=.
generate ChangeSalaryGradeC = temp 
drop temp  

label variable ChangeSalaryGrade  "= 1 in the month when an individual's SalaryGrade is diff. than the preceding"
label variable ChangeSalaryGradeC "cumulative count of SalaryGrade increase for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2: work level promotions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate temp = PromWL
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 & PromWL!=.
replace temp = 0 if temp==. & PromWL!=.
generate PromWLC = temp 
drop temp 

label variable PromWLC "cumulative count of work level promotions for an individual"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. outcome variables: lateral transfers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. standard job changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferSJ = 0 if StandardJob!="" 
replace  TransferSJ = 1 if (IDlse==IDlse[_n-1] & StandardJob!=StandardJob[_n-1] & StandardJob!="")

generate temp = TransferSJ
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & StandardJob!=""
generate TransferSJC = temp 
drop temp

label variable TransferSJ  "= 1 in the month when an individual's StandardJob is diff. than the preceding"
label variable TransferSJC "cumulative count of StandardJob transfers for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. standard job changes without salary grade changes
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
*-? s-2-3. function changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferFunc = 0 if Func!=.
replace  TransferFunc = 1 if IDlse==IDlse[_n-1] & Func!=Func[_n-1]  & Func!=.

generate temp = TransferFunc
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & Func!=.
generate  TransferFuncC = temp 
drop temp 

label variable TransferFunc  "= 1 in the month when an individual's Func is diff. than the preceding"
label variable TransferFuncC "cumulative count of Func transfers for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. subfunction changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferSubFunc = 0 if SubFunc!=.
replace  TransferSubFunc = 1 if IDlse==IDlse[_n-1] & SubFunc!=SubFunc[_n-1] & SubFunc!=.

generate temp = TransferSubFunc
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & SubFunc!=.
generate TransferSubFuncC = temp 
drop temp 

label var  TransferSubFunc "= 1 in the month when SubFunc is diff. than the preceding"
label var  TransferSubFuncC "cumulative count of SubFunc transfers for an individual"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. internal transfers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-5-1. measure 1: either office, subfunc, or org4
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

sort IDlse YearMonth
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
*!! s-2-5-2. measure 2: either office, StandardJob, or org4
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

sort IDlse YearMonth
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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. outcome variables: earnings
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. manager id imputations  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in IDlseMHR {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. 
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? final step. save these worker outcomes  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture drop occurrence
sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
order occurrence, after(YearMonth)

order ///
    Year YearMonth occurrence IDlse IDlseMHR ///
    Female AgeBand Tenure WL Country ISOCode ///
    Func SubFunc Org4 Office OfficeCode StandardJob SalaryGrade VPA ///
    TransferSJV TransferSJVC TransferSJ TransferSJC ///
    ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC ///
    TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC ///
    TransferInternal TransferInternalC TransferInternalSJ TransferInternalSJC ///
    LogPayBonus LogPay LogBonus Pay Bonus ///
    Leaver LeaverPerm LeaverVol LeaverInv

label variable Year             "Year"
label variable YearMonth        "Year-Month"
label variable occurrence       "Sequential occurrence number for each employee in that month"
label variable IDlse            "Employee ID"
label variable IDlseMHR         "Manager ID"

label variable Female           "Female"
label variable AgeBand          "Age band"
label variable Tenure           "Years within the firm"
label variable WL               "Work level: from lowest (1) to highest (6)"
label variable Country          "Working country"
label variable ISOCode          "ISO code of the working country"

label variable Func             "Function"
label variable SubFunc          "Subfunction"
label variable Org4             "Level 4 organization description"
label variable Office           "Work location: Office or Plant/Factory"
label variable OfficeCode       "Work location code: Office or Plant/Factory"
label variable StandardJob      "Standard job title"
label variable SalaryGrade      "Salary grade"
label variable VPA              "Performance rating"

label variable TransferSJV         "= 1 when his StandardJob is diff. than last month but SalaryGrade is the same"
label variable TransferSJVC        "Cumulative count of TransferSJV for an individual"
label variable TransferSJ          "= 1 in months when an individual's StandardJob is diff. than preceding months"
label variable TransferSJC         "Cumulative count of TransferSJ for an individual"
label variable ChangeSalaryGrade   "= 1 in months when an individual's SalaryGrade is diff. than preceding months"
label variable ChangeSalaryGradeC  "Cumulative count of ChangeSalaryGrade for an individual"
label variable PromWL              "= 1 in months when WL is greater than preceding months"
label variable PromWLC             "Cumulative count of PromWL for an individual"
label variable TransferFunc        "= 1 in months when an individual's Func is diff. than preceding months"
label variable TransferFuncC       "Cumulative count of TransferFunc for an individual"
label variable TransferSubFunc     "= 1 in months when SubFunc is diff. than preceding months"
label variable TransferSubFuncC    "Cumulative count of TransferSubFuncC for an individual"
label variable TransferInternal    "= 1 in months when either SubFunc or Office or Org4 is diff than last months"
label variable TransferInternalC   "Cumulative count of TransferInternal for an individual"
label variable TransferInternalSJ  "= 1 in months when either StandardJob or Office or Org4 is diff than last months"
label variable TransferInternalSJC "Cumulative count of TransferInternalSJ for an individual"

label variable LogPayBonus         "Pay + bonus (logs)"
label variable LogPay              "Pay (logs)"
label variable LogBonus            "Bonus (logs)"
label variable Pay                 "Pay"
label variable Bonus               "Bonus"
label variable Leaver              "= 1 in months when an individual leaves the firm"
label variable LeaverPerm          "= 1 in the month when an individual leaves the firm permanently"
label variable LeaverVol           "= 1 in the month when an individual quits (voluntarily exits)"
label variable LeaverInv           "= 1 in the month when an individual is fired (involuntarily exits)"

compress 
save "${TempData}/FinalFullSample.dta", replace 