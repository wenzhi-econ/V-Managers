/* 
This do file produces all statistics that are cited in the paper.

*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. numbers 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. number of events in each group
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Mngr_both_WL2==1 & FT_Rel_Time!=.
    //&? a panel of event workers 

sort IDlse YearMonth 
bysort IDlse: generate occurrence = _n 

count if occurrence==1 
    //&? number of workers: 29,610
count if occurrence==1 & FT_LtoL==1
    //&? number of LtoL events: 20,853
count if occurrence==1 & FT_LtoH==1
    //&? number of LtoH events: 4,148
count if occurrence==1 & FT_HtoH==1
    //&? number of HtoH events: 1,753
count if occurrence==1 & FT_HtoL==1
    //&? number of HtoL events: 2,856

display 1753 / 29610
    //&? .05920297 of events are HtoH

codebook IDlseMHR if inrange(FT_Rel_Time, -1, 0) & FT_Mngr_both_WL2==1
    //&? number of managers: 14,664

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. event-year tabulation 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Mngr_both_WL2==1 & FT_Rel_Time!=.
    //&? a panel of event workers 

generate Year = year(dofm(YearMonth))
tab Year if FT_Rel_Time==0
/* 
       Year |      Freq.     Percent        Cum.
------------+-----------------------------------
       2011 |      3,706       12.52       12.52
       2012 |      6,891       23.27       35.79
       2013 |      4,317       14.58       50.37
       2014 |      2,733        9.23       59.60
       2015 |      2,241        7.57       67.17
       2016 |      1,951        6.59       73.76
       2017 |      1,594        5.38       79.14
       2018 |      1,813        6.12       85.26
       2019 |      1,496        5.05       90.31
       2020 |      1,080        3.65       93.96
       2021 |      1,788        6.04      100.00
------------+-----------------------------------
      Total |     29,610      100.00

*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. share of events in robustness checks
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Mngr_both_WL2==1 & FT_Rel_Time!=.
    //&? a panel of event workers 

*!! single-cohort 
generate Year = year(dofm(YearMonth))
tab Year if FT_Rel_Time==0

*!! new hires 
sort IDlse YearMonth
bysort IDlse: egen TenureMin = min(Tenure)
tab TenureMin if FT_Rel_Time==0

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. mediation analysis  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if (FT_LtoL==1 | FT_LtoH==1) & FT_Mngr_both_WL2==1
    //&? a panel of event workers in LtoL and LtoH groups
keep IDlse YearMonth IDlseMHR FT_* TransferSJV TransferSJVC TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC StandardJob 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. create the mediator
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! ignore pre-event transfers 
replace TransferSJV = 0 if FT_Rel_Time < 0 
replace TransferSJ  = 0 if FT_Rel_Time < 0
replace ChangeSalaryGrade = 0 if FT_Rel_Time < 0

*!! recreate count variables (counting only post-event transfers)
capture drop TransferSJC
generate temp = TransferSJ
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & StandardJob!=""
generate TransferSJC = temp 
drop temp

capture drop TransferSJVC
generate temp = TransferSJV
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & StandardJob!=""
generate TransferSJVC = temp 
drop temp

capture drop ChangeSalaryGradeC
generate temp = ChangeSalaryGrade
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & StandardJob!=""
generate ChangeSalaryGradeC = temp 
drop temp

*!! number of post-event transfers at 60 months after the event 
sort IDlse YearMonth
bysort IDlse: egen TransferSJC60  = mean(cond(FT_Rel_Time==60, TransferSJC, .))
bysort IDlse: egen TransferSJVC60 = mean(cond(FT_Rel_Time==60, TransferSJVC, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. post-event manager (cluster)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen long IDlseMHRPost = max(cond(FT_Rel_Time==0, IDlseMHR, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. keep a cross section of event workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
keep if FT_Rel_Time==84 
    //&? a cross section of LtoL and LtoH workers (relative month +84)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. mediation analysis
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

medeff (regress TransferSJC60 FT_LtoH) (regress ChangeSalaryGradeC FT_LtoH TransferSJC60) ///
    , treat(FT_LtoH) mediate(TransferSJC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)

/* 
Linear regression                               Number of obs     =      5,778
                                                F(1, 2920)        =      13.47
                                                Prob > F          =     0.0002
                                                R-squared         =     0.0064
                                                Root MSE          =     1.3475

                       (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
------------------------------------------------------------------------------
             |               Robust
Transfe~JC60 | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
     FT_LtoH |    .326837   .0890685     3.67   0.000     .1521936    .5014804
       _cons |   1.327859   .0262163    50.65   0.000     1.276455    1.379263
------------------------------------------------------------------------------

Linear regression                               Number of obs     =      5,778
                                                F(2, 2920)        =     250.14
                                                Prob > F          =     0.0000
                                                R-squared         =     0.1267
                                                Root MSE          =     1.1475

                        (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
-------------------------------------------------------------------------------
              |               Robust
ChangeSalar~C | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
--------------+----------------------------------------------------------------
      FT_LtoH |   .0358838   .0606784     0.59   0.554     -.083093    .1548605
TransferSJC60 |   .3225143   .0144341    22.34   0.000     .2942122    .3508164
        _cons |    .923547   .0260024    35.52   0.000     .8725621    .9745319
-------------------------------------------------------------------------------
(4,778 missing values generated)
(4,778 missing values generated)
(4,778 missing values generated)
------------------------------------------------------------------------------------
        Effect                 |  Mean           [95% Conf. Interval]
-------------------------------+----------------------------------------------------
        ACME                   |  .1058269      .0482278       .169306
        Direct Effect          |  .0328552     -.0826918      .1548338
        Total Effect           |  .1386821       .001488      .2673386
        % of Tot Eff mediated  |  .7527106      .3151921      4.139946
------------------------------------------------------------------------------------
*/

medeff (regress TransferSJVC60 FT_LtoH) (regress ChangeSalaryGradeC FT_LtoH TransferSJVC60) ///
    , treat(FT_LtoH) mediate(TransferSJVC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)
/* 
Linear regression                               Number of obs     =      5,778
                                                F(1, 2920)        =      18.83
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0059
                                                Root MSE          =     .63523

                       (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
------------------------------------------------------------------------------
             |               Robust
Transfe~VC60 | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
     FT_LtoH |    .147408   .0339696     4.34   0.000     .0808012    .2140148
       _cons |    .352592    .010063    35.04   0.000     .3328606    .3723234
------------------------------------------------------------------------------

Linear regression                               Number of obs     =      5,778
                                                F(2, 2920)        =    1452.20
                                                Prob > F          =     0.0000
                                                R-squared         =     0.3737
                                                Root MSE          =     .97181

                         (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
--------------------------------------------------------------------------------
               |               Robust
ChangeSalary~C | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
---------------+----------------------------------------------------------------
       FT_LtoH |  -.0325461   .0493391    -0.66   0.510    -.1292891    .0641969
TransferSJVC60 |   1.179308    .021899    53.85   0.000     1.136369    1.222247
         _cons |   .9359859   .0200128    46.77   0.000     .8967453    .9752265
--------------------------------------------------------------------------------
(4,778 missing values generated)
(4,778 missing values generated)
(4,778 missing values generated)
------------------------------------------------------------------------------------
        Effect                 |  Mean           [95% Conf. Interval]
-------------------------------+----------------------------------------------------
        ACME                   |  .1743925      .0943956      .2623143
        Direct Effect          | -.0350087     -.1289629      .0641752
        Total Effect           |  .1393838      .0174554      .2594781
        % of Tot Eff mediated  |  1.213286      .5899078      5.639765
------------------------------------------------------------------------------------
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. testing for negative weights 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. generate event indicators for DID style TWFE
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? a panel of event workers

generate FT_Post = (FT_Rel_Time>=0)
generate FT_LtoL_X_Post = FT_LtoL * FT_Post
generate FT_LtoH_X_Post = FT_LtoH * FT_Post
generate FT_HtoH_X_Post = FT_HtoH * FT_Post
generate FT_HtoL_X_Post = FT_HtoL * FT_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. testing negative weights for the two main outcomes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

twowayfeweights TransferSJVC IDlse YearMonth FT_LtoH_X_Post, type(feTR) other_treatments(FT_LtoL_X_Post FT_HtoH_X_Post FT_HtoL_X_Post)

twowayfeweights ChangeSalaryGradeC IDlse YearMonth FT_LtoH_X_Post, type(feTR) other_treatments(FT_LtoL_X_Post FT_HtoH_X_Post FT_HtoL_X_Post)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. economic magnitude of the pay gap between LtoH and LtoL groups 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

local l = 30 // after 7 years 

di 0 + 2/(1.05) +  7/(1.05)^2 + 11/(1.05)^3 + 19/(1.05)^4 + 24/(1.05)^5 + 28/(1.05)^6 +  30/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 +   `l'/(1.05)^20 +   `l'/(1.05)^21 +   `l'/(1.05)^22 +   `l'/(1.05)^23 +   `l'/(1.05)^24+   `l'/(1.05)^25+   `l'/(1.05)^26 +   `l'/(1.05)^27 +   `l'/(1.05)^28 +   `l'/(1.05)^29 

* 94% with no dynamic effects after 7 years 
* 375% with 5% dynamic effects after 7 years 