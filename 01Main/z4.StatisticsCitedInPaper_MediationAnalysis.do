/* 
This do file conducts mediation analysis in the paper.

RA: WWZ 
Time: 2025-02-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. mediation analysis  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if (FT_LtoL==1 | FT_LtoH==1) & FT_Mngr_both_WL2==1
    //&? a panel of event workers in LtoL and LtoH groups
keep IDlse YearMonth IDlseMHR FT_* TransferSJV TransferSJVC TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC StandardJob 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. create the mediator
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! number of post-event transfers at 60 months after the event 
sort IDlse YearMonth
bysort IDlse: egen TransferSJC60  = mean(cond(FT_Rel_Time==60, TransferSJC, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. post-event manager (cluster)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen long IDlseMHRPost = max(cond(FT_Rel_Time==0, IDlseMHR, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. keep a cross section of event workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
keep if FT_Rel_Time==84 
    //&? a cross section of LtoL and LtoH workers (relative month +84)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. mediation analysis
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

medeff (regress TransferSJC60 FT_LtoH) (regress ChangeSalaryGradeC FT_LtoH TransferSJC60) ///
    , treat(FT_LtoH) mediate(TransferSJC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)

/* 
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
ChangeSalar~C | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
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