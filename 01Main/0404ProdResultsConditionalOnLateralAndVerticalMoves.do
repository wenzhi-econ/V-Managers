/* 
This do file replicates Table B4 in the paper.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 
    "${TempData}/05SalesProdOutcomes.dta"          <== created in 0105 do file 
    "${RawMNEData}/ListWbecM.dta"                  <== raw data 
    "${RawMNEData}/Univoice.dta"                   <== raw data 

Results:
    "${Results}/ResultsConditionalOnLateralAndVerticalMoves.tex"

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
use "${TempData}/04MainOutcomesInEventStudies.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/05SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

*!! Post variables 
generate FT_Post = (FT_Rel_Time>=0) if FT_Rel_Time!=.
generate FT_LtoL_X_Post = FT_LtoL * FT_Post
generate FT_LtoH_X_Post = FT_LtoH * FT_Post
generate FT_HtoH_X_Post = FT_HtoH * FT_Post
generate FT_HtoL_X_Post = FT_HtoL * FT_Post

*!! Movers within 2 years after the event 
bysort IDlse: egen Movers_2yrs = max(cond(inrange(FT_Rel_Time, 0, 24), TransferSJ, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. DiD regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
impt: 
Notice that the following two regressions are econmetrically equivalent:
    reghdfe ProductivityStd FT_LtoL_X_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & LogPayBonus!=., absorb(IDlse YearMonth) cluster(IDlseMHR)
        lincom FT_LtoH_X_Post - FT_LtoL_X_Post
    reghdfe ProductivityStd FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & LogPayBonus!=., absorb(IDlse YearMonth) cluster(IDlseMHR)
*/

reghdfe ProductivityStd FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & LogPayBonus!=., absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo Prod
    summarize ProductivityStd if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & Movers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_Movers
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & Movers_2yrs==1 & LogPayBonus!=., absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo Prod_Movers
    summarize ProductivityStd if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. conditional on vertical promotions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. LogPayBonus
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global control_vars Female##i.AgeBand 
global absorb_vars  Country YearMonth

reghdfe LogPayBonus FT_LtoH ${control_vars} if WL==2 & FT_Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1) & FT_Post==1, cluster(IDlseMHR) absorb(${absorb_vars})
    eststo LogPayBonus_Gain
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. MScore (survey variables)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-2-2-1. obtain survey variables 
merge m:1 IDlseMHR YearMonth using "${RawMNEData}/ListWbecM.dta"
    keep if _merge==3
    drop _merge

generate Year = year(dofm(YearMonth))

merge m:1 IDlse Year using "${RawMNEData}/Univoice.dta", keep(match master) nogenerate keepusing(LineManager)

sort IDlseMHR YearMonth IDlse
bysort IDlseMHR Year: egen MScore = mean(LineManager)
generate MScoreB = (MScore>4) if MScore!=.
sort IDlse YearMonth

*!! s-2-2-2. run regressions 
global control_vars Female##i.AgeBand 
global absorb_vars  Country YearMonth

reghdfe MScore FT_LtoH ${control_vars} if WL==2 & FT_Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1) & FT_Post==1, cluster(IDlseMHR) a(${absorb_vars})
    eststo MScore_Gain
    summarize MScore if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)
	
reghdfe MScoreB FT_LtoH ${control_vars} if WL==2 & FT_Mngr_both_WL2==1 & (FT_LtoL==1 | FT_LtoH==1) & FT_Post==1, cluster(IDlseMHR) a(${absorb_vars})
    eststo MScoreB_Gain
    summarize MScoreB if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable FT_LtoH "LtoH"
label variable FT_LtoH_X_Post "LtoH $\times$ Post"

esttab Prod Prod_Movers LogPayBonus_Movers LogPayBonus_Gain MScore_Gain MScoreB_Gain, keep(FT_LtoH_X_Post FT_LtoH)

esttab Prod Prod_Movers LogPayBonus_Movers LogPayBonus_Gain MScore_Gain MScoreB_Gain using "${Results}/ResultsConditionalOnLateralAndVerticalMoves.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(FT_LtoH_X_Post FT_LtoH) ///
    order(FT_LtoH_X_Post FT_LtoH) ///
    b(3) se(2) ///
    stats(r2 cmean N, labels("R-squared" "Mean, LtoL group" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccc}" "\toprule" "\toprule" "& & \multicolumn{2}{c}{Conditional on lateral move} & \multicolumn{3}{c}{Conditional on vertical move} \\" "\addlinespace[10pt] \cmidrule(lr){3-4} \cmidrule(lr){5-7} \\" " & \multicolumn{1}{c}{Sales bonus (s.d.)}  & \multicolumn{1}{c}{Sales bonus (s.d.)}  & \multicolumn{1}{c}{Pay + bonus (in logs)} & \multicolumn{1}{c}{Pay + bonus (in logs)} & \multicolumn{1}{c}{Effective leader} & \multicolumn{1}{c}{High Effective leader} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item Notes. An observation is a employee-month. Standard errors clustered at the manager level. Column (1) is a DiD specification as equation \ref{eq:sales} on the sample of LtoL and LtoH workers. Columns (2) and (3) are the same DiD specification conditional on the worker making at least one lateral moves within 2 years after the event.  Columns (4), (5), and (6) are estimated using periods after the LtoL and LtoH workers are promoted as managers. Since they can only be promoted as managers after the manager transition events, this is not a DiD design, and the estimated coefficients on whether the worker is in the LtoH event group are reported. \emph{Sales bonus (s.d.)} is normalized sales bonus as a measure of productivity. \emph{Pay + bonus (in logs)} is the sum of regular pay and additional bonuses. \emph{Effective leader score} is the workers' anonymous rating of the manager via the survey question \emph{My line manager is an effective leader} with scale 1-5, which is asked every year in the annual survey and the overall mean is 4.1. \emph{High Effective leader score} is a binary variable indicating if the score is larger than 4." "\end{tablenotes}")
