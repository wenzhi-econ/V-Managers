/* 
This do file conducts mediation analysis using variables counting the number of lateral moves and number of salary grade increases within different time horizons.

RA: WWZ 
Time: 2025-03-27
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if (FT_LtoL==1 | FT_LtoH==1) & FT_Mngr_both_WL2==1
    //&? a panel of event workers in LtoL and LtoH groups

keep IDlse YearMonth IDlseMHR FT_* TransferSJV TransferSJVC TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC StandardJob 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. create the mediator
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! number of post-event transfers 1-5 years after the event 
foreach values in 12 24 36 48 60 72 {
    sort IDlse YearMonth
    bysort IDlse: egen TransferSJC`values'  = mean(cond(FT_Rel_Time==`values', TransferSJC, .))
    bysort IDlse: egen TransferSJVC`values' = mean(cond(FT_Rel_Time==`values', TransferSJVC, .))
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. create the outcome variable
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach values in 12 24 36 48 60 72 84 {
    sort IDlse YearMonth
    bysort IDlse: egen ChangeSalaryGradeC`values'  = mean(cond(FT_Rel_Time==`values', ChangeSalaryGradeC, .))
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. post-event manager (cluster)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen long IDlseMHRPost = max(cond(FT_Rel_Time==0, IDlseMHR, .))

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. mediation analysis - using TransferSJC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. 2-year gap
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

medeff (regress TransferSJC12 FT_LtoH) (regress ChangeSalaryGradeC36 FT_LtoH TransferSJC12) if FT_Rel_Time==36, treat(FT_LtoH) mediate(TransferSJC12) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .0716877

medeff (regress TransferSJC24 FT_LtoH) (regress ChangeSalaryGradeC48 FT_LtoH TransferSJC24) if FT_Rel_Time==48, treat(FT_LtoH) mediate(TransferSJC24) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .1247849

medeff (regress TransferSJC36 FT_LtoH) (regress ChangeSalaryGradeC60 FT_LtoH TransferSJC36) if FT_Rel_Time==60, treat(FT_LtoH) mediate(TransferSJC36) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .2053615

medeff (regress TransferSJC48 FT_LtoH) (regress ChangeSalaryGradeC72 FT_LtoH TransferSJC48) if FT_Rel_Time==72, treat(FT_LtoH) mediate(TransferSJC48) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .3396381

medeff (regress TransferSJC60 FT_LtoH) (regress ChangeSalaryGradeC84 FT_LtoH TransferSJC60) if FT_Rel_Time==84 ///
    , treat(FT_LtoH) mediate(TransferSJC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .5919506

/* 
. medeff (regress TransferSJC60 FT_LtoH) (regress ChangeSalaryGradeC84 FT_LtoH TransferSJC60) if FT_Rel_Time==84 ///
>     , treat(FT_LtoH) mediate(TransferSJC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)
Using 0 and 1 as treatment values

Linear regression                               Number of obs     =      5,778
                                                F(1, 2920)        =       8.99
                                                Prob > F          =     0.0027
                                                R-squared         =     0.0042
                                                Root MSE          =     1.4692

                       (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
------------------------------------------------------------------------------
             |               Robust
Transfe~JC60 | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
     FT_LtoH |   .2876158   .0959007     3.00   0.003      .099576    .4756557
       _cons |    1.52592    .029152    52.34   0.000     1.468759    1.583081
------------------------------------------------------------------------------

Linear regression                               Number of obs     =      5,778
                                                F(2, 2920)        =     221.97
                                                Prob > F          =     0.0000
                                                R-squared         =     0.1208
                                                Root MSE          =     1.1514

                        (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
-------------------------------------------------------------------------------
              |               Robust
ChangeSala~84 | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
--------------+----------------------------------------------------------------
      FT_LtoH |   .0582589   .0609749     0.96   0.339    -.0612993    .1778172
TransferSJC60 |   .2886992   .0137397    21.01   0.000     .2617586    .3156397
        _cons |   .9112687   .0269864    33.77   0.000     .8583544     .964183
-------------------------------------------------------------------------------
(4,778 missing values generated)
(4,778 missing values generated)
(4,778 missing values generated)
------------------------------------------------------------------------------------
        Effect                 |  Mean           [95% Conf. Interval]
-------------------------------+----------------------------------------------------
        ACME                   |  .0834377       .028088      .1445519
        Direct Effect          |  .0552155     -.0608962      .1777903
        Total Effect           |  .1386532      .0023153      .2677441
        % of Tot Eff mediated  |  .5919506      .2526019      3.369386
------------------------------------------------------------------------------------
*/
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. 1-year gap
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

medeff (regress TransferSJC12 FT_LtoH) (regress ChangeSalaryGradeC24 FT_LtoH TransferSJC12) if FT_Rel_Time==24, treat(FT_LtoH) mediate(TransferSJC12) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .1145747

medeff (regress TransferSJC24 FT_LtoH) (regress ChangeSalaryGradeC36 FT_LtoH TransferSJC24) if FT_Rel_Time==36, treat(FT_LtoH) mediate(TransferSJC24) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .2467697

medeff (regress TransferSJC36 FT_LtoH) (regress ChangeSalaryGradeC48 FT_LtoH TransferSJC36) if FT_Rel_Time==48, treat(FT_LtoH) mediate(TransferSJC36) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .2129056

medeff (regress TransferSJC48 FT_LtoH) (regress ChangeSalaryGradeC60 FT_LtoH TransferSJC48) if FT_Rel_Time==60, treat(FT_LtoH) mediate(TransferSJC48) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .2582297

medeff (regress TransferSJC60 FT_LtoH) (regress ChangeSalaryGradeC72 FT_LtoH TransferSJC60) if FT_Rel_Time==72, treat(FT_LtoH) mediate(TransferSJC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .3973744

medeff (regress TransferSJC72 FT_LtoH) (regress ChangeSalaryGradeC84 FT_LtoH TransferSJC72) if FT_Rel_Time==84, treat(FT_LtoH) mediate(TransferSJC72) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .5833194

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. mediation analysis - using TransferSJVC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. 2-year gap
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

medeff (regress TransferSJVC12 FT_LtoH) (regress ChangeSalaryGradeC36 FT_LtoH TransferSJVC12) if FT_Rel_Time==36, treat(FT_LtoH) mediate(TransferSJVC12) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .1086643 

medeff (regress TransferSJVC24 FT_LtoH) (regress ChangeSalaryGradeC48 FT_LtoH TransferSJVC24) if FT_Rel_Time==48, treat(FT_LtoH) mediate(TransferSJVC24) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .4144359

medeff (regress TransferSJVC36 FT_LtoH) (regress ChangeSalaryGradeC60 FT_LtoH TransferSJVC36) if FT_Rel_Time==60, treat(FT_LtoH) mediate(TransferSJVC36) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .5123509

medeff (regress TransferSJVC48 FT_LtoH) (regress ChangeSalaryGradeC72 FT_LtoH TransferSJVC48) if FT_Rel_Time==72, treat(FT_LtoH) mediate(TransferSJVC48) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .8175614

medeff (regress TransferSJVC60 FT_LtoH) (regress ChangeSalaryGradeC84 FT_LtoH TransferSJVC60) if FT_Rel_Time==84, treat(FT_LtoH) mediate(TransferSJVC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? 1.1154

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. 1-year gap
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

medeff (regress TransferSJVC12 FT_LtoH) (regress ChangeSalaryGradeC24 FT_LtoH TransferSJVC12) if FT_Rel_Time==24, treat(FT_LtoH) mediate(TransferSJVC12) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .1283109

medeff (regress TransferSJVC24 FT_LtoH) (regress ChangeSalaryGradeC36 FT_LtoH TransferSJVC24) if FT_Rel_Time==36, treat(FT_LtoH) mediate(TransferSJVC24) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .3958363

medeff (regress TransferSJVC36 FT_LtoH) (regress ChangeSalaryGradeC48 FT_LtoH TransferSJVC36) if FT_Rel_Time==48, treat(FT_LtoH) mediate(TransferSJVC36) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .5489885

medeff (regress TransferSJVC48 FT_LtoH) (regress ChangeSalaryGradeC60 FT_LtoH TransferSJVC48) if FT_Rel_Time==60, treat(FT_LtoH) mediate(TransferSJVC48) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .6999397

medeff (regress TransferSJVC60 FT_LtoH) (regress ChangeSalaryGradeC72 FT_LtoH TransferSJVC60) if FT_Rel_Time==72, treat(FT_LtoH) mediate(TransferSJVC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .961549

medeff (regress TransferSJVC72 FT_LtoH) (regress ChangeSalaryGradeC84 FT_LtoH TransferSJVC72) if FT_Rel_Time==84, treat(FT_LtoH) mediate(TransferSJVC72) sims(1000) seed(7) vce(cluster IDlseMHRPost)
    //&? .9981662

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. visualization of the results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture drop SJC_2yr_1 - SJVC_1yr_6

generate SJC_2yr_1 = .0716877 if _n==1
generate SJC_2yr_2 = .1247849 if _n==1
generate SJC_2yr_3 = .2053615 if _n==1
generate SJC_2yr_4 = .3396381 if _n==1
generate SJC_2yr_5 = .5919506 if _n==1
global barlabels ///
    1 "Salary grade increases (t+3)" ///
    2 "Salary grade increases (t+4)" ///
    3 "Salary grade increases (t+5)" ///
    4 "Salary grade increases (t+6)" ///
    5 "Salary grade increases (t+7)"
graph hbar SJC_2yr_1 SJC_2yr_2 SJC_2yr_3 SJC_2yr_4 SJC_2yr_5, ascategory ///
    yvaroptions(relabel(${barlabels})) legend(off) scheme(tab2) ///
    ytitle("% of total effect mediated by lateral moves, 2-year gap", size(medlarge)) ylabel(0(.1)1, grid gstyle(dot))
graph export "${Results}/Mediation_TransferSJC_2year.png", replace as(png)

generate SJC_1yr_1 = .1145747 if _n==1
generate SJC_1yr_2 = .2467697 if _n==1
generate SJC_1yr_3 = .2129056 if _n==1
generate SJC_1yr_4 = .2582297 if _n==1
generate SJC_1yr_5 = .3973744 if _n==1
generate SJC_1yr_6 = .5833194 if _n==1
global barlabels ///
    1 "Salary grade increases (t+2)" ///
    2 "Salary grade increases (t+3)" ///
    3 "Salary grade increases (t+4)" ///
    4 "Salary grade increases (t+5)" ///
    5 "Salary grade increases (t+6)" ///
    6 "Salary grade increases (t+7)"
graph hbar SJC_1yr_1 SJC_1yr_2 SJC_1yr_3 SJC_1yr_4 SJC_1yr_5 SJC_1yr_6, ascategory ///
    yvaroptions(relabel(${barlabels})) legend(off) scheme(tab2) ///
    ytitle("% of total effect mediated by lateral moves, 2-year gap", size(medlarge)) ylabel(0(.1)1, grid gstyle(dot))
graph export "${Results}/Mediation_TransferSJC_1year.png", replace as(png)

generate SJVC_2yr_1 = .1086643 if _n==1
generate SJVC_2yr_2 = .4144359 if _n==1
generate SJVC_2yr_3 = .5123509 if _n==1
generate SJVC_2yr_4 = .8175614 if _n==1
generate SJVC_2yr_5 = 1.1154 if _n==1
global barlabels ///
    1 "Salary grade increases (t+3)" ///
    2 "Salary grade increases (t+4)" ///
    3 "Salary grade increases (t+5)" ///
    4 "Salary grade increases (t+6)" ///
    5 "Salary grade increases (t+7)"
graph hbar SJVC_2yr_1 SJVC_2yr_2 SJVC_2yr_3 SJVC_2yr_4 SJVC_2yr_5, ascategory ///
    yvaroptions(relabel(${barlabels})) legend(off) scheme(tab2) ///
    ytitle("% of total effect mediated by lateral moves, 2-year gap", size(medlarge)) ylabel(0(.1)1, grid gstyle(dot)) 
graph export "${Results}/Mediation_TransferSJVC_2year.png", replace as(png)

generate SJVC_1yr_1 = .1283109 if _n==1
generate SJVC_1yr_2 = .3958363 if _n==1
generate SJVC_1yr_3 = .5489885 if _n==1
generate SJVC_1yr_4 = .6999397 if _n==1
generate SJVC_1yr_5 = .961549 if _n==1
generate SJVC_1yr_6 = .9981662 if _n==1
global barlabels ///
    1 "Salary grade increases (t+2)" ///
    2 "Salary grade increases (t+3)" ///
    3 "Salary grade increases (t+4)" ///
    4 "Salary grade increases (t+5)" ///
    5 "Salary grade increases (t+6)" ///
    6 "Salary grade increases (t+7)"
graph hbar SJVC_1yr_1 SJVC_1yr_2 SJVC_1yr_3 SJVC_1yr_4 SJVC_1yr_5 SJVC_1yr_6, ascategory ///
    yvaroptions(relabel(${barlabels})) legend(off) scheme(tab2) ///
    ytitle("% of total effect mediated by lateral moves, 1-year gap", size(medlarge)) ylabel(0(.1)1, grid gstyle(dot))
graph export "${Results}/Mediation_TransferSJVC_1year.png", replace as(png)
