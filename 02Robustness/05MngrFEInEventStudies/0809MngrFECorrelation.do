/* 
This do file generates manager FE with different procedures and restrictions, and calculate correlation with the original measure.

RA: WWZ 
Time: 2024-11-11
*/

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

xtset IDlse YearMonth, monthly
generate LogPayBonus_5yrsLater = f60.LogPayBonus

keep if FT_Rel_Time!=. 
keep if FT_Mngr_both_WL2==1
    //&? keep a worker panel that contains only the event workers 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate manager FE (without restrictions)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. manager FE and se 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! First, residualize by individual FE and time FE 
areg LogPayBonus_5yrsLater i.YearMonth, absorb(IDlse)
    predict resLogPayBonus, res

*!! Then, compute manager FE and se of manager FE 
areg resLogPayBonus, absorb(IDlseMHR)
    *&? manager FE 
    predict LogPayBonusMFEb, d
    replace LogPayBonusMFEb = LogPayBonusMFEb + _b[_cons]

    *&? se of manager FE 
    predict residLogPayBonus, r
    generate sqresLogPayBonus=residLogPayBonus^2
    egen NLogPayBonus=count(sqresLogPayBonus), by(IDlseMHR)
    summarize sqresLogPayBonus, meanonly
    generate LogPayBonusMFEse=sqrt(r(mean)*e(N)/e(df_r)/NLogPayBonus)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. Bayes shrinkage 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

do "${DoFiles}/02Robustness/05MngrFEInEventStudies/ebayes.ado" 

ebayes LogPayBonusMFEb LogPayBonusMFEse, ///
    gen(LogPayBonusBayes) var(LogPayBonusBayesvar) rawvar(LogPayBonusBayesrawvar) ///
    uvar(LogPayBonusBayesuvar) theta(LogPayBonusBayestheta) bee(LogPayBonusBayesbee) 

rename LogPayBonusBayes MFEBayesLogPay

drop resLogPayBonus residLogPayBonus sqresLogPayBonus NLogPayBonus LogPayBonusMFEse ///
    LogPayBonusBayesbee LogPayBonusBayestheta LogPayBonusBayesvar LogPayBonusBayesuvar LogPayBonusBayesrawvar

rename LogPayBonusMFEb MFE 
rename MFEBayesLogPay  MFE_Bayes

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. generate manager FE (with restrictions)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-0. restrictions on the estimation sample  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

egen ttI = tag(IDlse IDlseMHR)
bysort IDlseMHR: egen TotWorkers = sum(ttI)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. manager FE and se 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! First, residualize by individual FE and time FE 
areg LogPayBonus_5yrsLater i.YearMonth if TotWorkers>4, absorb(IDlse)
    predict resLogPayBonus, res

*!! Then, compute manager FE and se of manager FE 
areg resLogPayBonus if TotWorkers>4, absorb(IDlseMHR)
    *&? manager FE 
    predict LogPayBonusMFEb, d
    replace LogPayBonusMFEb = LogPayBonusMFEb + _b[_cons]

    *&? se of manager FE 
    predict residLogPayBonus, r
    generate sqresLogPayBonus=residLogPayBonus^2
    egen NLogPayBonus=count(sqresLogPayBonus), by(IDlseMHR)
    summarize sqresLogPayBonus, meanonly
    generate LogPayBonusMFEse=sqrt(r(mean)*e(N)/e(df_r)/NLogPayBonus)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. Bayes shrinkage 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* do "${DoFiles}/02Robustness/05MngrFEInEventStudies/ebayes.ado"  */

ebayes LogPayBonusMFEb LogPayBonusMFEse if TotWorkers>4, ///
    gen(LogPayBonusBayes) var(LogPayBonusBayesvar) rawvar(LogPayBonusBayesrawvar) ///
    uvar(LogPayBonusBayesuvar) theta(LogPayBonusBayestheta) bee(LogPayBonusBayesbee) 

rename LogPayBonusBayes MFEBayesLogPay

drop resLogPayBonus residLogPayBonus sqresLogPayBonus NLogPayBonus ///
    LogPayBonusBayesbee LogPayBonusBayestheta LogPayBonusBayesvar LogPayBonusBayesuvar LogPayBonusBayesrawvar

rename LogPayBonusMFEb MFE_NoW 
rename MFEBayesLogPay  MFE_NoW_Bayes

foreach var in MFE MFE_Bayes MFE_NoW MFE_NoW_Bayes {
    summarize `var', detail 
    global median = r(p50)
    global p75    = r(p75)

    generate `var'_Med = (`var' >= ${median})
    generate `var'_p75 = (`var' >= ${p75})
}

keep IDlse FT_Rel_Time EarlyAgeM MFE*

keep if FT_Rel_Time==0
    //&? a cross-section of event workers

correlate EarlyAgeM MFE MFE_Bayes MFE_NoW MFE_NoW_Bayes 

*&& MFE:           No number of worker (NoW) restriction,   No Bayes procedure 
*&& MFE_Bayes:     No number of worker (NoW) restriction,   With Bayes procedure 
*&& MFE_NoW:       With number of worker (NoW) restriction, No Bayes procedure 
*&& MFE_NoW_Bayes: With number of worker (NoW) restriction, With Bayes procedure 
correlate EarlyAgeM MFE MFE_Med MFE_p75 MFE_Bayes MFE_Bayes_Med MFE_Bayes_p75 MFE_NoW MFE_NoW_Med MFE_NoW_p75 MFE_NoW_Bayes MFE_NoW_Bayes_Med MFE_NoW_Bayes_p75

/* 
             | EarlyA~M      MFE  MFE_Med  MFE_p75 MFE_Ba~s MFE_Ba~d MFE_B~75  MFE_NoW MF~W_Med MF~W_p75 MFE_No~s MFE_No.. MFE_No..
-------------+---------------------------------------------------------------------------------------------------------------------
   EarlyAgeM |   1.0000
         MFE |   0.0086   1.0000
     MFE_Med |   0.0083   0.6839   1.0000
     MFE_p75 |   0.0626   0.6436   0.5796   1.0000
   MFE_Bayes |   0.0090   0.9952   0.6879   0.6443   1.0000
MFE_Bayes_~d |   0.0083   0.6839   1.0000   0.5796   0.6879   1.0000
MFE_Bayes~75 |   0.0608   0.6440   0.5851   0.9728   0.6458   0.5851   1.0000
     MFE_NoW |   0.0077   0.9333   0.6579   0.6130   0.9311   0.6579   0.6156   1.0000
 MFE_NoW_Med |   0.0220   0.6393   0.8417   0.5426   0.6446   0.8417   0.5512   0.6819   1.0000
 MFE_NoW_p75 |   0.0736   0.6055   0.5755   0.8099   0.6079   0.5755   0.8191   0.6497   0.5960   1.0000
MFE_NoW_Ba~s |   0.0089   0.9278   0.6634   0.6145   0.9372   0.6634   0.6183   0.9914   0.6869   0.6512   1.0000
MFE_NoW_Ba~d |   0.0216   0.6394   0.8426   0.5421   0.6446   0.8426   0.5507   0.6820   0.9991   0.5955   0.6870   1.0000
MFE_NoW_B~75 |   0.0773   0.6005   0.5651   0.8004   0.6048   0.5651   0.8134   0.6460   0.5851   0.9729   0.6497   0.5846   1.0000
*/

