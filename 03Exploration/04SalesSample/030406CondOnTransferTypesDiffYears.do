/* 
This do file distinguishes between different lateral move types when investigating pay outcomes conditional on lateral moves.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== created in 0104 do file 
    "${TempData}/08SalesProdOutcomes.dta" <== created in 0108 do file 

Results:
    "${Results}/ResultsConditionalOnDiffTypesOfLateralMoves.tex"

RA: WWZ 
Time: 2024-11-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. conditional on lateral moves
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. new variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! Productivity outcomes 
use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/08SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

*!! Post variables 
generate FT_Post = (FT_Rel_Time>=0) if FT_Rel_Time!=.
generate FT_LtoL_X_Post = FT_LtoL * FT_Post
generate FT_LtoH_X_Post = FT_LtoH * FT_Post
generate FT_HtoH_X_Post = FT_HtoH * FT_Post
generate FT_HtoL_X_Post = FT_HtoL * FT_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. decompose TransferSJ into three categories:
*-?         (1) within team (same manager, same function)
*-?         (2) different team (different manager), and different function
*-?         (3) different team (different manager), but same function
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! first month for a worker
sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

*!! if the worker changes his manager 
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

*!! ignore pre-event lateral moves 
replace TransferSJ = 0 if TransferSJ==1 & FT_Rel_Time<0

*!! lateral transfer under the same manager
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*!! lateral transfer under different managers
generate TransferSJDiffM = TransferSJ
replace  TransferSJDiffM = 0 if TransferSJSameM==1

*!! category (3): differnt manager + same function
generate TransferSJDiffMSameFunc = TransferSJ 
replace  TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace  TransferSJDiffMSameFunc = 0 if TransferSJSameM==1

*!! category (1): same manager + same function
generate TransferSJSameMSameFunc = TransferSJ 
replace  TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace  TransferSJSameMSameFunc = 0 if TransferSJDiffMSameFunc==1

*!! category (2): different manager + different function
*&& variable TransferFunc can accurately describe this category
replace TransferFunc = 0 if TransferSJ==0
    //&? consider the case with IDlse==606619

*!! First, make sure we are caring about the first transfer after the events (cumsum_TransferSJ==1) 
sort IDlse YearMonth 
bysort IDlse: generate cumsum_TransferSJ = sum(TransferSJ)

*!! Ignore any other transfer
generate AE_TransferSJ              = TransferSJ
generate AE_TransferSJSameMSameFunc = TransferSJSameMSameFunc
generate AE_TransferFunc            = TransferFunc
generate AE_TransferSJDiffMSameFunc = TransferSJDiffMSameFunc
replace  AE_TransferSJ              = 0 if cumsum_TransferSJ!=1 & AE_TransferSJ==1
replace  AE_TransferSJSameMSameFunc = 0 if cumsum_TransferSJ!=1 & AE_TransferSJSameMSameFunc==1
replace  AE_TransferFunc            = 0 if cumsum_TransferSJ!=1 & AE_TransferFunc==1
replace  AE_TransferSJDiffMSameFunc = 0 if cumsum_TransferSJ!=1 & AE_TransferSJDiffMSameFunc==1

*!! Movers within 2 years after the event 
sort IDlse YearMonth
bysort IDlse: egen Movers_2yrs                 = max(cond(inrange(FT_Rel_Time, 0, 24),  AE_TransferSJ, .))
bysort IDlse: egen WithinTeamMovers_2yrs       = max(cond(inrange(FT_Rel_Time, 0, 24),  AE_TransferSJSameMSameFunc, .))
bysort IDlse: egen DiffFuncMovers_2yrs         = max(cond(inrange(FT_Rel_Time, 0, 24),  AE_TransferFunc, .))
bysort IDlse: egen DiffTeamSameFuncMovers_2yrs = max(cond(inrange(FT_Rel_Time, 0, 24),  AE_TransferSJDiffMSameFunc, .))

*!! Movers within 5 years after the event 
sort IDlse YearMonth
bysort IDlse: egen Movers_5yrs                 = max(cond(inrange(FT_Rel_Time, 0, 60),  AE_TransferSJ, .))
bysort IDlse: egen WithinTeamMovers_5yrs       = max(cond(inrange(FT_Rel_Time, 0, 60),  AE_TransferSJSameMSameFunc, .))
bysort IDlse: egen DiffFuncMovers_5yrs         = max(cond(inrange(FT_Rel_Time, 0, 60),  AE_TransferFunc, .))
bysort IDlse: egen DiffTeamSameFuncMovers_5yrs = max(cond(inrange(FT_Rel_Time, 0, 60),  AE_TransferSJDiffMSameFunc, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. 2 yrs
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & Movers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_Movers_2
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & WithinTeamMovers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_WTM_2
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & DiffFuncMovers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_DFM_2
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & DiffTeamSameFuncMovers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_DTM_2
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. 5 yrs
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & Movers_5yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_Movers_5
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & WithinTeamMovers_5yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_WTM_5
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & DiffFuncMovers_5yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_DFM_5
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & DiffTeamSameFuncMovers_5yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_DTM_5
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. produce the table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable FT_LtoH_X_Post "LtoH $\times$ Post"

esttab LogPayBonus_Movers_2 LogPayBonus_WTM_2 LogPayBonus_DTM_2 LogPayBonus_DFM_2 LogPayBonus_Movers_5 LogPayBonus_WTM_5 LogPayBonus_DTM_5 LogPayBonus_DFM_5 using "${Results}/PayOutcomesConditionalOnDiffTypesOfLateralMoves_2And5YrsLater.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH_X_Post) ///
    order(FT_LtoH_X_Post) ///
    b(3) se(2) ///
    stats(r2 cmean N, labels("R-squared" "Mean, LtoL group" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccccc}" "\toprule" "\toprule" "& \multicolumn{4}{c}{Conditional on lateral move within 2 years after the event} & \multicolumn{4}{c}{Conditional on lateral move within 5 years after the event} \\" "\addlinespace[10pt] \cmidrule(lr){2-5} \cmidrule(lr){6-9} \\" " & \multicolumn{1}{c}{All moves} & \multicolumn{1}{c}{Same team} & \multicolumn{1}{c}{Diff. team, same function} & \multicolumn{1}{c}{Diff. function} & \multicolumn{1}{c}{All moves} & \multicolumn{1}{c}{Same team} & \multicolumn{1}{c}{Diff team, same function} & \multicolumn{1}{c}{Diff. function} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item Notes. An observation is a employee-month. Standard errors clustered at the manager level. Regressions are DiD specifications but conditional on the worker making at least one lateral moves within 2 and 5 years after the event. The outcome variable is \emph{Pay + bonus (in logs)}" "\end{tablenotes}")