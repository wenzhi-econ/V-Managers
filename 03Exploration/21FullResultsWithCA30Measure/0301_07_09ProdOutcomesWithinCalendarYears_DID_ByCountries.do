/* 
This do file presents the DID results on the productivity outcomes by calendar months and by countries

RA: WWZ 
Time: 2025-05-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain a relevant dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. new productivity variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! productivity outcomes 
use "${TempData}/FinalAnalysisSample.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

generate Prod = log(Productivity + 1)
label variable Prod "Sales bonus (logs)"

keep Year - IDMngr_Post ISOCode LogPayBonus Productivity ProductivityStd Prod TransferSJVC ChangeSalaryGradeC LogPayBonus LogPay LogBonus Female AgeBand Office Func

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. sample restrictions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if ((ProductivityStd!=.))
    //impt: In this exercise, I keep only those employees who have non-missing productivity outcomes.

generate Year18to20 = inrange(YearMonth, tm(2018m1), tm(2020m12))
generate Year18to21 = inrange(YearMonth, tm(2018m1), tm(2021m12))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. who are in the balanced sample 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Min_RelTime = min(Rel_Time)
bysort IDlse: egen Max_RelTime = max(Rel_Time)

summarize Min_RelTime, detail
summarize Max_RelTime, detail

generate q_BalancedSample=1 if Min_RelTime<0 & Max_RelTime>0

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct regressors used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate  CA30_Rel_Time = Rel_Time
foreach event in CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL {
    generate byte `event'_X_Post = `event' * (CA30_Rel_Time >= 0)
}

global DID_dummies Post_Event CA30_LtoH_X_Post CA30_HtoH_X_Post CA30_HtoL_X_Post 

label variable Post_Event "Post-event"
label variable CA30_LtoH_X_Post "LtoH $\times$ post-event"
label variable CA30_HtoH_X_Post "HtoH $\times$ post-event"
label variable CA30_HtoL_X_Post "HtoL $\times$ post-event"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. IND: run regressions and produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & ISOCode=="IND", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2018m1), tm(2018m12))==1 & ISOCode=="IND", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2019m1), tm(2019m12))==1 & ISOCode=="IND", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2020m1), tm(2020m12))==1 & ISOCode=="IND", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_20
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2021m1), tm(2021m12))==1 & ISOCode=="IND", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & !inrange(YearMonth, tm(2019m1), tm(2019m12)) & ISOCode=="IND", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21_No19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{2018m1-2021m12} & \multicolumn{1}{c}{2018m1-2018m12}  & \multicolumn{1}{c}{2019m1-2019m12} & \multicolumn{1}{c}{2020m1-2020m12} & \multicolumn{1}{c}{2021m1-2021m12} & \multicolumn{1}{c}{\shortstack{2018m1-2021m12, \\ no 2019m1-2019m12}} \\"
global latex_panel        "& \multicolumn{6}{c}{Sales bonus (s.d.)} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_ProdOutcomesInDID_CalendarMonths_IND.tex"

esttab Prod_18to21 Prod_18 Prod_19 Prod_20 Prod_21 Prod_18to21_No19 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(${DID_dummies}) order(${DID_dummies}) ///
    stats(cmean r2 N, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. IDN: run regressions and produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & ISOCode=="IDN", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2018m1), tm(2018m12))==1 & ISOCode=="IDN", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2019m1), tm(2019m12))==1 & ISOCode=="IDN", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2020m1), tm(2020m12))==1 & ISOCode=="IDN", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_20
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2021m1), tm(2021m12))==1 & ISOCode=="IDN", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & !inrange(YearMonth, tm(2019m1), tm(2019m12)) & ISOCode=="IDN", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21_No19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{2018m1-2021m12} & \multicolumn{1}{c}{2018m1-2018m12}  & \multicolumn{1}{c}{2019m1-2019m12} & \multicolumn{1}{c}{2020m1-2020m12} & \multicolumn{1}{c}{2021m1-2021m12} & \multicolumn{1}{c}{\shortstack{2018m1-2021m12, \\ no 2019m1-2019m12}} \\"
global latex_panel        "& \multicolumn{6}{c}{Sales bonus (s.d.)} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_ProdOutcomesInDID_CalendarMonths_IDN.tex"

esttab Prod_18to21 Prod_18 Prod_19 Prod_20 Prod_21 Prod_18to21_No19 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(${DID_dummies}) order(${DID_dummies}) ///
    stats(cmean r2 N, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. ITA: run regressions and produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & ISOCode=="ITA", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2018m1), tm(2018m12))==1 & ISOCode=="ITA", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2019m1), tm(2019m12))==1 & ISOCode=="ITA", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2020m1), tm(2020m12))==1 & ISOCode=="ITA", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_20
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2021m1), tm(2021m12))==1 & ISOCode=="ITA", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & !inrange(YearMonth, tm(2019m1), tm(2019m12)) & ISOCode=="ITA", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21_No19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{2018m1-2021m12} & \multicolumn{1}{c}{2018m1-2018m12}  & \multicolumn{1}{c}{2019m1-2019m12} & \multicolumn{1}{c}{2020m1-2020m12} & \multicolumn{1}{c}{2021m1-2021m12} & \multicolumn{1}{c}{\shortstack{2018m1-2021m12, \\ no 2019m1-2019m12}} \\"
global latex_panel        "& \multicolumn{6}{c}{Sales bonus (s.d.)} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_ProdOutcomesInDID_CalendarMonths_ITA.tex"

esttab Prod_18to21 Prod_18 Prod_19 Prod_20 Prod_21 Prod_18to21_No19 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(${DID_dummies}) order(${DID_dummies}) ///
    stats(cmean r2 N, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 6. RUS: run regressions and produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & ISOCode=="RUS", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2018m1), tm(2018m12))==1 & ISOCode=="RUS", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2019m1), tm(2019m12))==1 & ISOCode=="RUS", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2020m1), tm(2020m12))==1 & ISOCode=="RUS", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_20
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2021m1), tm(2021m12))==1 & ISOCode=="RUS", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & !inrange(YearMonth, tm(2019m1), tm(2019m12)) & ISOCode=="RUS", absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21_No19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{2018m1-2021m12} & \multicolumn{1}{c}{2018m1-2018m12}  & \multicolumn{1}{c}{2019m1-2019m12} & \multicolumn{1}{c}{2020m1-2020m12} & \multicolumn{1}{c}{2021m1-2021m12} & \multicolumn{1}{c}{\shortstack{2018m1-2021m12, \\ no 2019m1-2019m12}} \\"
global latex_panel        "& \multicolumn{6}{c}{Sales bonus (s.d.)} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_ProdOutcomesInDID_CalendarMonths_RUS.tex"

esttab Prod_18to21 Prod_18 Prod_19 Prod_20 Prod_21 Prod_18to21_No19 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(${DID_dummies}) order(${DID_dummies}) ///
    stats(cmean r2 N, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 7. all countries: run regressions and produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2018m1), tm(2018m12))==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2019m1), tm(2019m12))==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2020m1), tm(2020m12))==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_20
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2021m1), tm(2021m12))==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & !inrange(YearMonth, tm(2019m1), tm(2019m12)), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21_No19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{2018m1-2021m12} & \multicolumn{1}{c}{2018m1-2018m12}  & \multicolumn{1}{c}{2019m1-2019m12} & \multicolumn{1}{c}{2020m1-2020m12} & \multicolumn{1}{c}{2021m1-2021m12} & \multicolumn{1}{c}{\shortstack{2018m1-2021m12, \\ no 2019m1-2019m12}} \\"
global latex_panel        "& \multicolumn{6}{c}{Sales bonus (s.d.)} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_ProdOutcomesInDID_CalendarMonths.tex"

esttab Prod_18to21 Prod_18 Prod_19 Prod_20 Prod_21 Prod_18to21_No19 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(${DID_dummies}) order(${DID_dummies}) ///
    stats(cmean r2 N, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")