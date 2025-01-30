*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. mediation analysis based on non-transformed variables  
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
bysort IDlse: egen TransferSJVC60 = mean(cond(FT_Rel_Time==60, TransferSJVC, .))

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

medeff (regress TransferSJVC60 FT_LtoH) (regress ChangeSalaryGradeC FT_LtoH TransferSJVC60) ///
    , treat(FT_LtoH) mediate(TransferSJVC60) sims(1000) seed(7) vce(cluster IDlseMHRPost)
/* 
Linear regression                               Number of obs     =      5,778
                                                F(1, 2920)        =      15.01
                                                Prob > F          =     0.0001
                                                R-squared         =     0.0047
                                                Root MSE          =     .68309

                       (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
------------------------------------------------------------------------------
             |               Robust
Transfe~VC60 | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
     FT_LtoH |   .1423428   .0367395     3.87   0.000     .0703049    .2143807
       _cons |   .4004749   .0109846    36.46   0.000     .3789366    .4220132
------------------------------------------------------------------------------

Linear regression                               Number of obs     =      5,778
                                                F(2, 2920)        =    1666.24
                                                Prob > F          =     0.0000
                                                R-squared         =     0.3935
                                                Root MSE          =     .95635

                         (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
--------------------------------------------------------------------------------
               |               Robust
ChangeSalary~C | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
---------------+----------------------------------------------------------------
       FT_LtoH |   -.018904   .0487774    -0.39   0.698    -.1145457    .0767376
TransferSJVC60 |   1.125434   .0195232    57.65   0.000     1.087153    1.163715
         _cons |   .9010926   .0198934    45.30   0.000     .8620861     .940099
--------------------------------------------------------------------------------
(4,778 missing values generated)
(4,778 missing values generated)
(4,778 missing values generated)
------------------------------------------------------------------------------------
        Effect                 |  Mean           [95% Conf. Interval]
-------------------------------+----------------------------------------------------
        ACME                   |  .1607652      .0781865      .2512062
        Direct Effect          | -.0213386     -.1142232      .0767161
        Total Effect           |  .1394266      .0177784      .2614514
        % of Tot Eff mediated  |    1.1154      .5413248      5.124097
------------------------------------------------------------------------------------
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. mediation analysis based on transformed variables  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if (FT_LtoL==1 | FT_LtoH==1) & FT_Mngr_both_WL2==1
    //&? a panel of event workers in LtoL and LtoH groups
keep IDlse YearMonth IDlseMHR FT_* TransferSJV TransferSJVC TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC StandardJob 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. create the transformed outcomes and mediators
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! ignore pre-event transfers and salary grade increases
replace TransferSJV        = 0 if FT_Rel_Time < 0 
replace TransferSJ         = 0 if FT_Rel_Time < 0
replace ChangeSalaryGrade  = 0 if FT_Rel_Time < 0

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
                                                F(2, 2920)        =     281.45
                                                Prob > F          =     0.0000
                                                R-squared         =     0.1416
                                                Root MSE          =     1.0763

                        (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
-------------------------------------------------------------------------------
              |               Robust
ChangeSalar~C | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
--------------+----------------------------------------------------------------
      FT_LtoH |   .1006404   .0555051     1.81   0.070    -.0081927    .2094736
TransferSJC60 |   .3204064   .0136045    23.55   0.000      .293731    .3470818
        _cons |   .7338252    .023079    31.80   0.000     .6885725     .779078
-------------------------------------------------------------------------------
(4,778 missing values generated)
(4,778 missing values generated)
(4,778 missing values generated)
------------------------------------------------------------------------------------
        Effect                 |  Mean           [95% Conf. Interval]
-------------------------------+----------------------------------------------------
        ACME                   |  .1051399      .0480259      .1681841
        Direct Effect          |    .09787     -.0078258      .2094492
        Total Effect           |  .2030099      .0768666      .3217499
        % of Tot Eff mediated  |  .5201578      .3267771      1.367832
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
                                                F(2, 2920)        =    1711.67
                                                Prob > F          =     0.0000
                                                R-squared         =     0.4174
                                                Root MSE          =     .88667

                         (Std. err. adjusted for 2,921 clusters in IDlseMHRPost)
--------------------------------------------------------------------------------
               |               Robust
ChangeSalary~C | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
---------------+----------------------------------------------------------------
       FT_LtoH |   .0319282   .0428883     0.74   0.457    -.0521661    .1160225
TransferSJVC60 |    1.17655   .0201787    58.31   0.000     1.136984    1.216116
         _cons |   .7444376   .0172856    43.07   0.000     .7105443    .7783308
--------------------------------------------------------------------------------
(4,778 missing values generated)
(4,778 missing values generated)
(4,778 missing values generated)
------------------------------------------------------------------------------------
        Effect                 |  Mean           [95% Conf. Interval]
-------------------------------+----------------------------------------------------
        ACME                   |  .1739855      .0940981       .261558
        Direct Effect          |  .0297875     -.0518826      .1160036
        Total Effect           |   .203773      .0936053      .3172506
        % of Tot Eff mediated  |  .8449084      .5484171      1.858786
------------------------------------------------------------------------------------
*/