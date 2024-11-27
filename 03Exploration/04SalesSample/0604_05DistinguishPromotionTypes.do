/* 
This do file distinguishes between different lateral move types when investigating pay outcomes conditional on vertical promotions.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== created in 0104 do file 
    "${TempData}/08SalesProdOutcomes.dta" <== created in 0108 do file 

Results:
    "${Results}/DistinguishPromotionAndTransferTypes.tex"

RA: WWZ 
Time: 2024-11-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. conditional on lateral moves
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. new variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

*!! Post variables 
generate FT_Post = (FT_Rel_Time>=0) if FT_Rel_Time!=.
generate FT_LtoL_X_Post = FT_LtoL * FT_Post
generate FT_LtoH_X_Post = FT_LtoH * FT_Post
generate FT_HtoH_X_Post = FT_HtoH * FT_Post
generate FT_HtoL_X_Post = FT_HtoL * FT_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. promotion time and (sub)func info at promotion
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen YM_PromWL1 = min(cond(WL==2, YearMonth, .))

sort IDlse YearMonth 
bysort IDlse: egen StartingWL = mean(cond(FT_Rel_Time==0, WL, .))
    //&? for the decomposition practice, only consider the event workers with StartingWL==1

sort IDlse YearMonth
bysort IDlse: egen Func_PromWL1    = mean(cond(YearMonth==YM_PromWL1, Func, .))
bysort IDlse: egen SubFunc_PromWL1 = mean(cond(YearMonth==YM_PromWL1, SubFunc, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. function and subfunction info at event time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Func_Event    = mean(cond(FT_Rel_Time==0, Func, .))
bysort IDlse: egen SubFunc_Event = mean(cond(FT_Rel_Time==0, SubFunc, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. decomposition 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate PromWLSameSubFunc = PromWL
replace  PromWLSameSubFunc = 0 if PromWLSameSubFunc==1 & YearMonth==YM_PromWL1 & SubFunc_Event!=SubFunc_PromWL1

generate PromWLDiffSubFunc = PromWL
replace  PromWLDiffSubFunc = 0 if PromWLDiffSubFunc==1 & YearMonth==YM_PromWL1 & (SubFunc_Event==SubFunc_PromWL1 | Func_Event!=Func_PromWL1)

generate PromWLDiffFunc = PromWL
replace  PromWLDiffFunc = 0 if PromWLDiffFunc==1 & YearMonth==YM_PromWL1 & Func_Event==Func_PromWL1

sort IDlse YearMonth
bysort IDlse: egen SameSubFunc = max(cond((YearMonth<=YM_PromWL1 & StartingWL==1), PromWLSameSubFunc, .))
bysort IDlse: egen DiffSubFunc = max(cond((YearMonth<=YM_PromWL1 & StartingWL==1), PromWLDiffSubFunc, .))
bysort IDlse: egen DiffFunc    = max(cond((YearMonth<=YM_PromWL1 & StartingWL==1), PromWLDiffFunc, .))

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. regressions on pay 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. conditional on vertical promotions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global control_vars Female##i.AgeBand 
global absorb_vars  Country YearMonth

*!! all promotions
reghdfe LogPayBonus FT_LtoH ${control_vars} if WL==2 & FT_Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1) & FT_Post==1 & StartingWL==1, cluster(IDlseMHR) absorb(${absorb_vars})
    eststo Prom
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*!! same subfunction promotions
reghdfe LogPayBonus FT_LtoH ${control_vars} if WL==2 & FT_Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1) & FT_Post==1 & SameSubFunc==1, cluster(IDlseMHR) absorb(${absorb_vars})
    eststo Prom_SSF
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*!! diff subfunction, same function promotions 
reghdfe LogPayBonus FT_LtoH ${control_vars} if WL==2 & FT_Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1) & FT_Post==1 & DiffSubFunc==1, cluster(IDlseMHR) absorb(${absorb_vars})
    eststo Prom_DSF
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*!! diff function promotions 
reghdfe LogPayBonus FT_LtoH ${control_vars} if WL==2 & FT_Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1) & FT_Post==1 & DiffFunc==1, cluster(IDlseMHR) absorb(${absorb_vars})
    eststo Prom_DF
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable FT_LtoH "LtoH"

esttab Prom Prom_SSF Prom_DSF Prom_DF using "${Results}/DistinguishPromotionTypes.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH) ///
    order(FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 cmean N, labels("R-squared" "Mean, LtoL group" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{4}{c}{Conditional on vertical move} \\" "\addlinespace[10pt] \cmidrule(lr){2-5} \\" " & \multicolumn{1}{c}{All vertical moves}  & \multicolumn{1}{c}{Same subfunction}  & \multicolumn{1}{c}{Diff subfunction, same function} & \multicolumn{1}{c}{Diff function} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item Notes. An observation is a employee-month. Standard errors clustered at the manager level. Regressions are conditional on vertical promotion based on different types of vertical moves on the \emph{Pay + bonus (in logs)} outcome." "\end{tablenotes}")
