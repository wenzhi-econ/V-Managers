/* 
This do file investigates the correlation between managers' high-flyer status and their characteristics.

Notes: The regressions are based on two different samples: 
    (1) those employees who have ever been WL2 in the data, and
    (2) those whose promotion to WL2 can be observed.

The regressors of interest are as follows:
    the income group of the working country
    mid career hire indicator 
    specific function (when the worker is first observed as WL2)
    if the manager has changed his function 
    education and fields of study

RA: WWZ 
Time: 2025-01-30
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. keep a panel of employees of interest 
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
*-? s-1-2. keep only those employees who have been observed as WL2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

merge m:1 IDlse using "${TempData}/temp_EverWL2WorkerList.dta", generate(EverWL2Worker)

keep if EverWL2Worker==3
    //&? a panel of employees who are ever WL2 in the data

label drop _merge
replace EverWL2Worker = 0 if EverWL2Worker!=3
replace EverWL2Worker = 1 if EverWL2Worker==3

label variable EverWL2Worker "Ever WL2 Workers"

drop EarlyAgeM - FT_Calend_Time_HtoL WLM - DiffM2y1
drop IDlseMHR
    //&? This is a panel of employees who are ever WL2 in the data.
    //&? I can identify whether they are event managers in the event studies.
    //&? To prevent ambiguity, I will drop variables constructed only for WL1 workers.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. get employees' high-flyer status
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

rename IDlse IDlseMHR
merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 
rename IDlseMHR IDlse
rename EarlyAgeM EarlyAge

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. determine whose promotion to WL2 can be observed
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
bysort IDlse: egen WL_FirstOccurrence = mean(cond(occurrence==1, WL, .))
generate q_WL2Prom = (WL_FirstOccurrence==1) if WL_FirstOccurrence!=.
    //&? since I only keep a panel of employees who have ever been WL2 in the data
    //&? if an employee's first occurrence WL is 1
    //&? then I must be able to observe his promotion to WL2

label variable q_WL2Prom "Promotion to WL2 can be observed"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. obtain other relevant variables  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. education and fields of study
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlse using "${RawMNEData}/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
    drop if _merge==2 
    drop _merge 

generate BachelorAbove   = QualHigh>10  if QualHigh!=.
generate BachelorOrBelow = QualHigh<=10 if QualHigh!=.

label variable BachelorAbove "Above bachelor degree"
label variable BachelorOrBelow "Bachelor degree or below"

generate Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
label variable Econ "Econ, business, and admin"

generate Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
    FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
    FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
label variable Sci "Sci, tech, engin, and math"

generate Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | ///
    FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | ///
    FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label variable Hum "Social sciences and humanities"

generate Other = (Econ == 0 & Sci == 0 & Hum == 0)  if FieldHigh1!=.
label variable Other "Other educ"


generate Econ_Excl = (FieldHigh1 == 4) if FieldHigh1!=.
label variable Econ_Excl "Econ, business, and admin (mutually exclusive)"

generate Sci_Excl = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17) if FieldHigh1!=.
label variable Sci_Excl "Sci, tech, engin, and math (mutually exclusive)"

generate Hum_Excl = (FieldHigh1 == 6 | FieldHigh1 == 11 | FieldHigh1 == 12 | FieldHigh1 == 13 | FieldHigh1 == 19) if FieldHigh1!=.
label variable Hum_Excl "Social sciences and humanities (mutually exclusive)"

generate Other_Excl = (Econ_Excl == 0 & Sci_Excl == 0 & Hum_Excl == 0)  if FieldHigh1!=.
label variable Other_Excl "Other educ (mutually exclusive)"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. country's income group  
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
*-? s-2-3. mid-career hire 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort   IDlse YearMonth
bysort IDlse: egen FF          = min(YearMonth)
bysort IDlse: egen FirstWL     = mean(cond(YearMonth==FF, WL, .))
bysort IDlse: egen FirstTenure = mean(cond(YearMonth==FF, Tenure, .))

generate MidCareerHire = (FirstWL>1 & FirstTenure<=1 & WL!=.)
label variable MidCareerHire "Mid career hire"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. one's function when first observed as WL2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen YearMonth_FirstWL2 = min(cond(WL==2, YearMonth, .))
bysort IDlse: egen Func_FirstWL2      = mean(cond(YearMonth==YearMonth_FirstWL2, Func, .))

generate func_cd = (Func_FirstWL2==3)  if !missing(Func_FirstWL2)
generate func_m  = (Func_FirstWL2==9)  if !missing(Func_FirstWL2)
generate func_sc = (Func_FirstWL2==11) if !missing(Func_FirstWL2)
generate func_rd = (Func_FirstWL2==10) if !missing(Func_FirstWL2)
generate func_fi = (Func_FirstWL2==4)  if !missing(Func_FirstWL2)
generate func_o  = 1           if !missing(Func_FirstWL2)
replace  func_o  = 0 if (func_cd==1 | func_m==1 | func_sc==1 | func_rd==1 | func_fi==1)

label variable func_cd "Sales function"
label variable func_m  "Marketing function"
label variable func_sc "Supply chain function"
label variable func_rd "Research/development function"
label variable func_fi "Finance function"
label variable func_o  "Other functions"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. does the worker change his function before WL2 promotion   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

bysort IDlse: egen temp_TransferFuncC = max(cond(YearMonth==YearMonth_FirstWL2, TransferFuncC, .))

generate FuncChangeBeforeWL2 = .
replace  FuncChangeBeforeWL2 = 1 if temp_TransferFuncC>0  & q_WL2Prom==1
replace  FuncChangeBeforeWL2 = 0 if temp_TransferFuncC==0 & q_WL2Prom==1
    //&? we can only define this variable only for managers whose promotion can be observed
label variable FuncChangeBeforeWL2 "Func. change before WL2"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-6. a cross section of managers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if YearMonth==YearMonth_FirstWL2
    //&? keep a cross section of managers 
    //&? 33,198 unique managers

keep IDlse EarlyAge q_WL2Prom ///
    Female MidCareerHire ///
    LowIncome UpperMidIncome HighIncome ///
    func_cd func_m func_sc func_rd func_fi func_o FuncChangeBeforeWL2 ///
    BachelorAbove BachelorOrBelow Econ* Sci* Hum* Other* 

order IDlse EarlyAge q_WL2Prom ///
    Female MidCareerHire ///
    LowIncome UpperMidIncome HighIncome ///
    func_cd func_m func_sc func_rd func_fi func_o FuncChangeBeforeWL2 ///
    BachelorAbove BachelorOrBelow Econ* Sci* Hum* Other* 

label variable Female "Female"

save "${TempData}/temp_LogitCrossSectionMngrs.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run linear probability models
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. on full sample (all employees who have ever been WL2)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_LogitCrossSectionMngrs.dta", clear 

regress EarlyAge Female MidCareerHire LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi, robust
    eststo reg1 
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi FuncChangeBeforeWL2, robust
    eststo reg2 
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female MidCareerHire LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi BachelorAbove, robust
    eststo reg3
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female MidCareerHire LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi Econ Sci Hum Other, robust
    eststo reg4
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female MidCareerHire LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi Econ_Excl Sci_Excl Hum_Excl, robust
    eststo reg4_Excl
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. on promotion sample (whose promotion to WL2 can be observed)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

regress EarlyAge Female LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi if q_WL2Prom==1, robust
    eststo reg5 
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi FuncChangeBeforeWL2 if q_WL2Prom==1, robust
    eststo reg6 
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi BachelorAbove if q_WL2Prom==1, robust
    eststo reg7
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi Econ Sci Hum Other if q_WL2Prom==1, robust
    eststo reg8
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

regress EarlyAge Female MidCareerHire LowIncome UpperMidIncome func_cd func_m func_sc func_rd func_fi Econ_Excl Sci_Excl Hum_Excl if q_WL2Prom==1, robust
    eststo reg8_Excl
    summarize EarlyAge if e(sample)==1
    estadd scalar mean = r(mean)

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 using "${Results}/LinearProbModelOnHighFlyerStatus.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(3) se(2) ///
    stats(r2 mean N, labels("R-squared" "High-flyer, mean" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccc}" "\toprule" "\toprule" "& \multicolumn{4}{c}{Full manager sample} & \multicolumn{4}{c}{Managers whose promotion can be observed} \\" "\addlinespace[10pt] \cmidrule(lr){2-5} \cmidrule(lr){6-9} \\") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Linear probability model with robust standard errors. " "\end{tablenotes}")

esttab reg1 reg2 reg3 reg4_Excl reg5 reg6 reg7 reg8_Excl using "${Results}/LinearProbModelOnHighFlyerStatus_FieldExcl.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(3) se(2) ///
    stats(r2 mean N, labels("R-squared" "High-flyer, mean" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccc}" "\toprule" "\toprule" "& \multicolumn{4}{c}{Full manager sample} & \multicolumn{4}{c}{Managers whose promotion can be observed} \\" "\addlinespace[10pt] \cmidrule(lr){2-5} \cmidrule(lr){6-9} \\") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Linear probability model with robust standard errors. " "\end{tablenotes}")

