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
Time: 2025-04-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. conditional on lateral moves
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. new variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! productivity outcomes 
use "${TempData}/FinalAnalysisSample.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

*!! "event group * post" dummy variables 
generate CA30_LtoL_X_Post = CA30_LtoL * Post_Event
generate CA30_LtoH_X_Post = CA30_LtoH * Post_Event
generate CA30_HtoH_X_Post = CA30_HtoH * Post_Event
generate CA30_HtoL_X_Post = CA30_HtoL * Post_Event

*!! Movers within 2 years after the event 
bysort IDlse: egen Movers_2yrs = max(cond(inrange(Rel_Time, 0, 24), TransferSJ, .))

*!! Descriptive: countries for which we have productivity data 
/* tab ISOCode if ProductivityStd!=. & (CA30_LtoL==1 | CA30_LtoH==1) & LogPayBonus!=. */
/* 
ISO_COUNTRY |
      _CODE |      Freq.     Percent        Cum.
------------+-----------------------------------
        BLR |        141        0.22        0.22
        COL |        234        0.37        0.59
        CRI |        620        0.97        1.56
        ECU |         21        0.03        1.59
        GRC |      2,275        3.57        5.16
        GTM |        500        0.78        5.94
        HND |        277        0.43        6.38
        IDN |      6,644       10.41       16.79
        IND |     31,723       49.72       66.51
        ITA |      4,670        7.32       73.83
        MEX |      8,312       13.03       86.86
        MYS |        636        1.00       87.86
        NIC |        392        0.61       88.47
        PAN |         39        0.06       88.53
        PHL |      1,043        1.63       90.17
        RUS |      5,253        8.23       98.40
        SGP |          3        0.00       98.41
        SLV |        600        0.94       99.35
        ZAF |        417        0.65      100.00
------------+-----------------------------------
      Total |     63,800      100.00
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. DiD regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
impt: the interpretation of the DID regressions
Notice that the following two regressions are econmetrically equivalent:
    reghdfe ProductivityStd CA30_LtoL_X_Post CA30_LtoH_X_Post if (CA30_LtoL==1 | CA30_LtoH==1) & LogPayBonus!=., absorb(IDlse YearMonth) cluster(IDlseMHR)
        lincom CA30_LtoH_X_Post - CA30_LtoL_X_Post
    reghdfe ProductivityStd Post_Event CA30_LtoH_X_Post if (CA30_LtoL==1 | CA30_LtoH==1) & LogPayBonus!=., absorb(IDlse YearMonth) cluster(IDlseMHR)
*/

reghdfe ProductivityStd Post_Event CA30_LtoH_X_Post if (CA30_LtoL==1 | CA30_LtoH==1) & LogPayBonus!=., absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo Prod
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe LogPayBonus Post_Event CA30_LtoH_X_Post if (CA30_LtoL==1 | CA30_LtoH==1) & Movers_2yrs==1, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus_Movers
    summarize LogPayBonus if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd Post_Event CA30_LtoH_X_Post if (CA30_LtoL==1 | CA30_LtoH==1) & Movers_2yrs==1 & LogPayBonus!=., absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo Prod_Movers
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. conditional on vertical promotions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. LogPayBonus
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global control_vars Female##i.AgeBand 
global absorb_vars  Country YearMonth

reghdfe LogPayBonus CA30_LtoH ${control_vars} if WL==2 & (CA30_LtoL==1 | CA30_LtoH==1) & Post_Event==1, cluster(IDlseMHR) absorb(${absorb_vars})
    eststo LogPayBonus_Gain
    summarize LogPayBonus if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. MScore (survey variables)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-2-2-1. obtain survey variables 
merge m:1 IDlse YearMonth using "${TempData}/0403EffectiveLeaderScores.dta"
keep if _merge==3
drop _merge
    //&? keep only those employees with a score on his manager survey 
    //&? notice that the manager score is only used in regressions conditional on promotion to WL2

rename LineManager MScore
generate MScoreB = (MScore>4) if MScore!=.
sort IDlse YearMonth

*!! s-2-2-2. run regressions 
global control_vars Female##i.AgeBand 
global absorb_vars  Country YearMonth

reghdfe MScore CA30_LtoH ${control_vars} if WL==2 & (CA30_LtoL==1 | CA30_LtoH==1) & Post_Event==1, cluster(IDlseMHR) a(${absorb_vars})
    eststo MScore_Gain
    summarize MScore if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)
	
reghdfe MScoreB CA30_LtoH ${control_vars} if WL==2 & (CA30_LtoL==1 | CA30_LtoH==1) & Post_Event==1, cluster(IDlseMHR) a(${absorb_vars})
    eststo MScoreB_Gain
    summarize MScoreB if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable CA30_LtoH "LtoH"
label variable CA30_LtoH_X_Post "LtoH $\times$ Post"

esttab Prod Prod_Movers LogPayBonus_Movers LogPayBonus_Gain MScore_Gain MScoreB_Gain using "${Results}/004ResultsBasedOnCA30/CA30_DIDResultsCondOnMoves.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH_X_Post CA30_LtoH) ///
    order(CA30_LtoH_X_Post CA30_LtoH) ///
    b(3) se(2) ///
    stats(cmean r2 N, labels("Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Full} & \multicolumn{2}{c}{Conditional on lateral move} & \multicolumn{3}{c}{Conditional on vertical move} \\ [-10pt]" "\addlinespace[10pt] \cmidrule(lr){2-2} \cmidrule(lr){3-4} \cmidrule(lr){5-7} \\ [-10pt]" " & \multicolumn{1}{c}{Sales bonus (s.d.)}  & \multicolumn{1}{c}{Sales bonus (s.d.)}  & \multicolumn{1}{c}{Pay + bonus (in logs)} & \multicolumn{1}{c}{Pay + bonus (in logs)} & \multicolumn{1}{c}{Effective leader} & \multicolumn{1}{c}{High Effective leader} \\ ") ///
    posthead("\hline \\ [-10pt]") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item Notes. An observation is a employee-month. Standard errors clustered at the manager level. Column (1) is a DiD specification as equation \ref{eq:sales} on the sample of LtoL and LtoH workers. Columns (2) and (3) are the same DiD specification conditional on the worker making at least one lateral moves within 2 years after the event.  Columns (4), (5), and (6) are estimated using periods after the LtoL and LtoH workers are promoted as managers. Since they can only be promoted as managers after the manager transition events, this is not a DiD design, and the estimated coefficients on whether the worker is in the LtoH event group are reported. \emph{Sales bonus (s.d.)} is normalized sales bonus as a measure of productivity. The variable is available in the following countries: BLR, COL, CRI, ECU, GRC, GTM, HND, IDN, IND, ITA, MEX, MYS, NIC, PAN, PHL, RUS, SGP, SLV, ZAF. \emph{Pay + bonus (in logs)} is the sum of regular pay and additional bonuses. \emph{Effective leader score} is the workers' anonymous rating of the manager via the survey question \emph{My line manager is an effective leader} with scale 1-5, which is asked every year in the annual survey and the overall mean is 4.1. \emph{High Effective leader score} is a binary variable indicating if the score is larger than 4." "\end{tablenotes}")
