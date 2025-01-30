/* 
This do file investigates the correlation between managers' high-flyer status and their characteristics.

RA: WWZ 
Time: 2025-01-29
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain the final dataset consisting of event managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. generate a list of managers who have been WL2 in the data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

*!! get any employee who is of WL2 at any point in the data 
generate WL2 = (WL==2) if WL!=.
sort IDlse YearMonth
bysort IDlse: egen Ever_WL2 = max(WL2)

keep if Ever_WL2==1
    //&? a panel of workers who are ever WL2 in the data 

keep IDlse
duplicates drop 

save "${TempData}/temp_EverWL2WorkerList.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate a list of managers who are in the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers

keep if FT_Rel_Time==0 | FT_Rel_Time==-1
    //&? keep only pre- and post-event managers

keep IDlseMHR
duplicates drop

rename IDlseMHR IDlse

save "${TempData}/temp_EventMngrList.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. get mangers' exit outcomes separately for event and non-event managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

merge m:1 IDlse using "${TempData}/temp_EverWL2WorkerList.dta", generate(EverWL2Worker)
merge m:1 IDlse using "${TempData}/temp_EventMngrList.dta", generate(EventMngr)

keep if EverWL2Worker==3 | EventMngr==3
    //&? a panel of employees who are ever WL2 in the data or they are event managers in the event studies 

label drop _merge
replace EverWL2Worker = 0 if EverWL2Worker!=3
replace EverWL2Worker = 1 if EverWL2Worker==3
replace EventMngr = 0 if EventMngr!=3
replace EventMngr = 1 if EventMngr==3

label variable EverWL2Worker "Ever WL2 Workers"
label variable EventMngr     "Event Managers"


drop EarlyAgeM - FT_Calend_Time_HtoL WLM - DiffM2y1
drop IDlseMHR
    //&? This is a panel of employees who are ever WL2 in the data.
    //&? I can identify whether they are event managers in the event studies.
    //&? To prevent ambiguity, I will drop variables constructed only for WL1 workers.


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. get high-flyer status for managers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

rename IDlse IDlseMHR
merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 
rename IDlseMHR IDlse
rename EarlyAgeM EarlyAge

order IDlse EarlyAge YearMonth Female Func SubFunc OfficeCode HomeCountryISOCode StandardJob

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. get other variables  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. education 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlse using "${RawMNEData}/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
    drop if _merge==2 
    drop _merge 

generate Bachelor       = QualHigh>=10 if QualHigh!=.
generate MBA            = QualHigh==13 if QualHigh!=.
generate AboveSecondary = QualHigh>=6  if QualHigh!=.

generate Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
label variable Econ "Econ, Business, and Admin"

generate Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
    FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
    FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
label variable Sci "Sci, Tech, Engin, and Math"

generate Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | ///
    FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | ///
    FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label variable Hum "Social Sciences and Humanities"

generate Other = (Econ == 0 & Sci == 0 & Hum == 0)  if FieldHigh1!=.
label variable Other "Other Educ"

generate Missing = (FieldHigh1==.) 
label variable Missing "Missing Education"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. country's income group  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 ISOCode using "${RawCntyData}/6.WB IncomeGroup.dta", keep(match master)

codebook IncomeGroup

generate LowIncome = .
replace  LowIncome = 1 if IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"
replace  LowIncome = 0 if IncomeGroup=="High income" | IncomeGroup=="Upper middle income"

generate UpperMidIncome = .
replace  UpperMidIncome = 1 if IncomeGroup=="Upper middle income" 
replace  UpperMidIncome = 0 if IncomeGroup=="High income" | IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"

generate HighIncome = . 
replace  HighIncome = 1 if IncomeGroup=="High income"
replace  HighIncome = 0 if IncomeGroup=="Upper middle income" | IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"

label variable LowIncome      "Low income countries"
label variable UpperMidIncome "Middle income countries"
label variable HighIncome     "High income countries"


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. mid-career hire 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

bysort IDlse : egen FF= min(YearMonth)
bysort IDlse : egen FirstWL = mean(cond(YearMonth==FF, WL, .)) // first WL observed 
bysort IDlse : egen FirstTenure = mean(cond(YearMonth==FF, Tenure, .)) // tenure in first month observed 

generate MidCareerHire = (FirstWL>1 & FirstTenure<=1 & WL!=.)
label variable MidCareerHire "Mid career hire"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-4. one's first function  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate func_cd = (Func==3)  if !missing(Func)
generate func_m  = (Func==9)  if !missing(Func)
generate func_sc = (Func==11) if !missing(Func)
generate func_rd = (Func==10) if !missing(Func)
generate func_fi = (Func==4)  if !missing(Func)
generate func_o  = 1           if !missing(Func)
replace  func_o  = 0 if (func_cd==1 | func_m==1 | func_sc==1 | func_rd==1 | func_fi==1)

label variable func_cd "Sales function"
label variable func_m  "Marketing function"
label variable func_sc "Supply chain function"
label variable func_rd "Research/Development function"
label variable func_fi "Finance function"
label variable func_o  "Other functions"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-5. does the worker change his function before WL2 promotion   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen WL2Month   = min(cond(WL==2, YearMonth, .))
bysort IDlse: egen FirstMonth = min(YearMonth)

bysort IDlse: egen temp_TransferFuncC = max(cond(YearMonth==WL2Month, TransferFuncC, .))

generate FuncChangeBeforeWL2 = .
replace  FuncChangeBeforeWL2 = 1 if temp_TransferFuncC>0  & FirstMonth<WL2Month
replace  FuncChangeBeforeWL2 = 0 if temp_TransferFuncC==0 & FirstMonth<WL2Month
    //&? we can only define this variable for managers whose promotion can be observed

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-6. a cross section of managers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if YearMonth==FirstMonth
    //&? keep a cross section of managers 

save "${TempData}/temp_LogitCrossSectionMngrs.dta", replace

order IDlse EarlyAge Female Func ISOCode Bachelor MBA AboveSecondary Econ Sci Hum Other Missing LowIncome UpperMidIncome HighIncome func_cd func_m func_sc func_rd func_fi func_o FuncChangeBeforeWL2

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. on full managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_LogitCrossSectionMngrs.dta", clear 
label variable FuncChangeBeforeWL2 "Func. change before WL2"

regress EarlyAge Female, robust
    eststo reg1 
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female Bachelor AboveSecondary MBA, robust
    eststo reg2 
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female Bachelor AboveSecondary MBA Econ Sci Hum Other, robust
    eststo reg3
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female Bachelor AboveSecondary MBA Econ Sci Hum Other LowIncome UpperMidIncome, robust
    eststo reg4
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female MidCareerHire, robust
    eststo reg5
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female MidCareerHire func_cd func_m func_sc func_rd func_fi, robust
    eststo reg6
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female MidCareerHire func_cd func_m func_sc func_rd func_fi FuncChangeBeforeWL2, robust
    eststo reg7
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 using "${Results}/LogitOnHighFlyerStatus.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(3) se(2) ///
    stats(r2 mean N, labels("R-squared" "High-flyer, mean" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccccc}" "\toprule" "\toprule") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Linear probability model with robust standard errors. The regression sample consists of a cross section of employees in the data who have ever been work level 2. " "\end{tablenotes}")


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. on event managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

eststo clear 


regress EarlyAge Female if EventMngr==1, robust
    eststo reg1 
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female Bachelor AboveSecondary MBA if EventMngr==1, robust
    eststo reg2 
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female Bachelor AboveSecondary MBA Econ Sci Hum Other if EventMngr==1, robust
    eststo reg3
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female Bachelor AboveSecondary MBA Econ Sci Hum Other LowIncome UpperMidIncome if EventMngr==1, robust
    eststo reg4
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female MidCareerHire if EventMngr==1, robust
    eststo reg5
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female MidCareerHire func_cd func_m func_sc func_rd func_fi if EventMngr==1, robust
    eststo reg6
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)
regress EarlyAge Female MidCareerHire func_cd func_m func_sc func_rd func_fi FuncChangeBeforeWL2 if EventMngr==1, robust
    eststo reg7
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 using "${Results}/LogitOnHighFlyerStatus_EventMngr.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(3) se(2) ///
    stats(r2 mean N, labels("R-squared" "High-flyer, mean" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccccc}" "\toprule" "\toprule") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Linear probability model with robust standard errors. The regression sample consists of a cross section of managers who have shown up in the event studies." "\end{tablenotes}")