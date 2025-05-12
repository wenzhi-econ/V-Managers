/* 
This do file runs DID-style regressions using productivity (i.e., sales bonus) as the outcome variable.

Notes:
    The regressions are further run conditional on workers' lateral and vertical move status.

Input:
    "${TempData}/FinalAnalysisSample.dta"          <== created in 0103_02 do file 
    "${TempData}/0105SalesProdOutcomes.dta"        <== created in 0105 do file 
    "${TempData}/0403EffectiveLeaderScores.dta"    <== created in 0403 do file 

Description of "${TempData}/0403EffectiveLeaderScores.dta" dataset:
    (1) It has three variables: IDlse YearMonth LineManager.
    (2) The LineManager value is the score that the corresponding manager with id IDlse received in that month. 
    (3) It is not the score the employee with the id IDlse gave to his manager.

Result:
    "${Results}/004ResultsBasedOnCA30/CA30_DIDResultsCondOnMoves.tex"

RA: WWZ 
Time: 2025-04-18
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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. keep only LtoL and LtoH groups (LtoL serves as the control group) 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if CA30_LtoL==1 | CA30_LtoH==1
    //impt: keep only LtoL and LtoH event workers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. new productivity variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Periods_0_2 = inrange(Rel_Time, 0, 23)
generate Periods_2_5 = inrange(Rel_Time, 24, 59)
generate Periods_5_7 = inrange(Rel_Time, 60, 84)

generate CA30_LtoL_X_Periods_0_2 = CA30_LtoL * Periods_0_2
generate CA30_LtoH_X_Periods_0_2 = CA30_LtoH * Periods_0_2

generate CA30_LtoL_X_Periods_2_5 = CA30_LtoL * Periods_2_5
generate CA30_LtoH_X_Periods_2_5 = CA30_LtoH * Periods_2_5

generate CA30_LtoL_X_Periods_5_7 = CA30_LtoL * Periods_5_7
generate CA30_LtoH_X_Periods_5_7 = CA30_LtoH * Periods_5_7

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. keep only Indian workers and relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep  ISOCode Year YearMonth IDlse IDlseMHR Rel_Time Event_Time Post_Event CA30_* Periods_* LogPayBonus PromWLC Productivity Prod TransferSJ WL Country Office Func Female AgeBand
order ISOCode Year YearMonth IDlse IDlseMHR Rel_Time Event_Time Post_Event CA30_* Periods_* LogPayBonus PromWLC Productivity Prod TransferSJ WL Country Office Func Female AgeBand

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. DID regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe Prod CA30_LtoH_X_Periods_0_2 CA30_LtoH_X_Periods_2_5 CA30_LtoH_X_Periods_5_7 Periods_0_2 Periods_2_5 Periods_5_7 if ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR)
    //&? negative and insignificant

reghdfe Prod CA30_LtoH_X_Periods_0_2 CA30_LtoH_X_Periods_2_5 CA30_LtoH_X_Periods_5_7 Periods_0_2 Periods_2_5 Periods_5_7 if inrange(Rel_Time, -6, 84) & ISOCode=="IND", absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo Prod 
    summarize Prod if e(sample)==1 & CA30_LtoL==1 & inrange(Rel_Time, -3, -1)
    estadd scalar cmean = r(mean)

reghdfe PromWLC CA30_LtoH_X_Periods_0_2 CA30_LtoH_X_Periods_2_5 CA30_LtoH_X_Periods_5_7 Periods_0_2 Periods_2_5 Periods_5_7 if inrange(Rel_Time, -6, 84), absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo PromWLC 
    summarize PromWLC if e(sample)==1 & CA30_LtoL==1 & Rel_Time==0
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. do lateral movers gain more  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*!! movers within 2 years after the event 
sort IDlse YearMonth
bysort IDlse: egen Movers_2yrs = max(cond(inrange(Rel_Time, 0, 24), TransferSJ, .))

reghdfe LogPayBonus CA30_LtoH if Movers_2yrs==1 & Post_Event==1, absorb(YearMonth Office#Func Female#AgeBand) cluster(IDlseMHR)
    eststo LateralMovers 
    summarize LogPayBonus if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. do LtoH workers have better outcomes after promotion  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe LogPayBonus CA30_LtoH if Post_Event==1 & WL==2, absorb(YearMonth Office#Func Female#AgeBand) cluster(IDlseMHR)
    eststo VerticalMovers 
    summarize LogPayBonus if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

merge m:1 IDlse YearMonth using "${TempData}/0403EffectiveLeaderScores.dta"
keep if _merge==3
drop _merge
    //&? keep only those employees with a score on his manager survey 
    //&? notice that the manager score is only used in regressions conditional on promotion to WL2

rename LineManager MScore
generate MScoreB = (MScore>4) if MScore!=.
sort IDlse YearMonth

reghdfe MScore CA30_LtoH if WL==2 & Post_Event==1, absorb(YearMonth Office#Func Female#AgeBand) cluster(IDlseMHR)
    eststo MScore_Gain
    summarize MScore if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)
	
reghdfe MScoreB CA30_LtoH if WL==2 & Post_Event==1, absorb(YearMonth Office#Func Female#AgeBand) cluster(IDlseMHR)
    eststo MScoreB_Gain
    summarize MScoreB if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. produce the regression table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable CA30_LtoH_X_Periods_0_2 "LtoH $\times$ [0, 2] years later"
label variable CA30_LtoH_X_Periods_2_5 "LtoH $\times$ [2, 5] years later" 
label variable CA30_LtoH_X_Periods_5_7 "LtoH $\times$ [5, 7] years later" 
label variable CA30_LtoH "LtoH"

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_panel        "& \multicolumn{1}{c}{India} & \multicolumn{1}{c}{Full} & \multicolumn{1}{c}{Lateral movers} & \multicolumn{3}{c}{Vertical movers} \\"
global latex_panel_line   "\cmidrule(lr){2-2} \cmidrule(lr){3-3} \cmidrule(lr){4-4} \cmidrule(lr){5-7}"
global latex_titles       "& \multicolumn{1}{c}{Sales bonus (in logs)} & \multicolumn{1}{c}{Number of work level promotions}  & \multicolumn{1}{c}{Pay + bonus (in logs)} & \multicolumn{1}{c}{Pay + bonus (in logs)}  & \multicolumn{1}{c}{Effective leader} & \multicolumn{1}{c}{High effective leader} \\"
global latex_file         "${Results}/004ResultsBasedOnCA30/DIDProdAndPromotions.tex"

esttab Prod PromWLC LateralMovers VerticalMovers MScore_Gain MScoreB_Gain using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(3) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH_X_Periods_0_2 CA30_LtoH_X_Periods_2_5 CA30_LtoH_X_Periods_5_7 CA30_LtoH) order(CA30_LtoH_X_Periods_0_2 CA30_LtoH_X_Periods_2_5 CA30_LtoH_X_Periods_5_7 CA30_LtoH) ///
    stats(cmean r2 N, labels("Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_panel_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")