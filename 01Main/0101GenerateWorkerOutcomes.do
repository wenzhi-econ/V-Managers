/* 
This do file generates relevant outcome variables used in the paper.

Input:
    "${RawMNEData}/AllSnapshotWC.dta"

Output:
    "${TempData}/01WorkersOutcomes.dta"

Description of the Output Dataset:
    Full employee panel, with additional outcomes relevant to the event studies.
    In particular, the dataset contains the following outcome variables:
        variables related to vertical promotion  
        variables related to lateral moves 
        variables related to pay 
        variables related to ONET task-distance    

RA: WWZ 
Time: 2024-11-19
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
*?? step 4. outcome variables: task-distance changes (ONET)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. match firm's job names to ONET job names
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

decode SubFunc, gen(SubFuncS)
decode Func, gen(FuncS)

xtset IDlse YearMonth 
encode StandardJob, gen(StandardJobE)
generate StandardJobEBefore = l.StandardJobE
label value StandardJobEBefore StandardJobE
decode StandardJobEBefore, gen(StandardJobBefore)

generate StandardJobCodeBefore = l.StandardJobCode

generate SubFuncBefore = l.SubFunc
label value SubFuncBefore SubFunc
decode SubFuncBefore, gen(SubFuncSBefore)

generate FuncBefore = l.Func
label value FuncBefore Func
decode FuncBefore, gen(FuncSBefore)

merge m:1 FuncS SubFuncS StandardJob StandardJobCode ///
    using  "${RawONETData}/SJ Crosswalk.dta", keepusing(ONETCode ONETName)
        drop if _merge==2
        drop _merge 

merge m:1 FuncSBefore SubFuncSBefore StandardJobBefore StandardJobCodeBefore ///
    using  "${RawONETData}/SJ Crosswalk.dta", keepusing(ONETCodeBefore ONETNameBefore)
        drop if _merge==2
        drop _merge 

merge m:1 ONETCode ONETCodeBefore using  "${RawONETData}/Distance.dta", ///
    keepusing(ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance)
        drop if _merge==2
        drop _merge  

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. generate cumulative sum of task measures difference
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance{
    replace `var' = 0 if (ONETCode==ONETCodeBefore & ONETCodeBefore!="" & ONETCode!="")
    replace `var' = 0 if TransferSJC==0 
    generate z =  `var'
    by IDlse (YearMonth), sort: replace z = z[_n-1] if _n>1 & StandardJob[_n]==StandardJob[_n-1]
    replace z = 0 if z ==. & ONETCode==ONETCodeBefore & ONETCodeBefore!="" & ONETCode!=""
    generate `var'C = z 
    replace `var'C = 0 if TransferSJC==0
    drop z 
}

egen ONETDistance = rowmean(ONETContextDistance ONETActivitiesDistance ONETAbilitiesDistance ONETSkillsDistance) 
egen ONETDistanceC = rowmean(ONETContextDistanceC ONETActivitiesDistanceC ONETAbilitiesDistanceC ONETSkillsDistanceC) 

label variable ONETDistance "ONET task-distance measure between current StandardJob and previous month's"
label variable ONETDistanceC "cumulative sum of ONET task-distance moves"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. generate cumulative count of task-distance change
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate ONETB = (ONETDistance>0) if ONETDistance!=.

capture drop ONETBC
generate temp = ONETB
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & ONETDistance!=.
generate ONETBC = temp 
drop temp 

label variable ONETB "=1, if current StandardJob's ONET task measure is different from last month's"
label variable ONETBC "cumulative count of lateral moves involved with ONET task-distance moves"

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

order IDlse YearMonth IDlseMHR ///
    TransferSJV TransferSJVC TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC ///
    ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC ///
    Func SubFunc Office ISOCode ///
    LogPayBonus LogPay LogBonus ///
    StandardJob ONETName ONETDistance ONETDistanceC ONET* ///
    SalaryGrade Org4 OfficeCode Pay Bonus Benefit Package

compress 
save "${TempData}/01WorkersOutcomes.dta", replace 