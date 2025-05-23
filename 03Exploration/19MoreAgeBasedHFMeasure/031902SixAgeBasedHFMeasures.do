/* 
This do file constructs five new measures and the original measures for manager quality.

Description of the measure:
    (1) DA30; using the original AgeBand variable; 
        if an employee's minimum AgeBand observed in WL2 is in range [<18, 30], then he is a high-flyer; otherwise, he is a low'flyer.
    (2) CA30; using the (imputed) AgeContinuous variable (<== constructed in 031900_02 do file);
        if an employee's minimum AgeContinuous observed in WL2 is <=30, then he is a high-flyer; otherwise, he is a low'flyer.
    (3) CA31; using the (imputed) AgeContinuous variable (<== constructed in 031900_02 do file);
        for an employee whose promotion to WL2 can be observed, 
            if AgeContinuous at promotion is <=30, then he is a high-flyer; 
            otherwise (still conditional on observable WL2 promotion), he is a low'flyer. 
        for an employee whose promotion to WL2 cannot be observed,
            if AgeContinuous at promotion is <=31, then he is a high-flyer; 
            otherwise (still conditional on unobservable WL2 promotion), he is a low'flyer.  
    (4) CA32; using the (imputed) AgeContinuous variable (<== constructed in 031900_02 do file);
        for an employee whose promotion to WL2 can be observed, 
            if AgeContinuous at promotion is <=30, then he is a high-flyer; 
            otherwise (still conditional on observable WL2 promotion), he is a low'flyer. 
        for an employee whose promotion to WL2 cannot be observed,
            if AgeContinuous at promotion is <=32, then he is a high-flyer; 
            otherwise (still conditional on unobservable WL2 promotion), he is a low'flyer.  
    (5) CA33; using the (imputed) AgeContinuous variable (<== constructed in 031900_02 do file);
        for an employee whose promotion to WL2 can be observed, 
            if AgeContinuous at promotion is <=30, then he is a high-flyer; 
            otherwise (still conditional on observable WL2 promotion), he is a low'flyer. 
        for an employee whose promotion to WL2 cannot be observed,
            if AgeContinuous at promotion is <=33, then he is a high-flyer; 
            otherwise (still conditional on unobservable WL2 promotion), he is a low'flyer.  
    (6) OM; the original HF measure (<== constructed in 0102 do file).

Input:
    "${RawMNEData}/AllSnapshotWC.dta"            <== raw data 
    "${TempData}/031900_02AgeContinuous.dta"     <== created in 031900_02 do file 
    "${TempData}/031902AListOfEventManagers.dta" <== created in 031901 do file 

RA: WWZ 
Time: 2025-04-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. merge the AgeContinuous variable to the raw data 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${RawMNEData}/AllSnapshotWC.dta", clear 

keep  IDlse YearMonth AgeBand Tenure WL Year
order IDlse Year YearMonth AgeBand Tenure WL

sort   IDlse YearMonth
bysort IDlse: generate occurrence = _n 
bysort IDlse: generate ind_count = _N

merge 1:1 IDlse YearMonth using "${TempData}/031900_02AgeContinuous.dta", keepusing(AgeContinuous) nogenerate

rename IDlse IDlseMHR
merge m:1 IDlseMHR using "${TempData}/031902AListOfEventManagers.dta", keep(match) nogenerate
    //impt: I only keep managers that are involved in the event study.
rename IDlseMHR IDlse

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. for employees whose promotion to WL2 can be observed
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. identify employees whose promotion to WL2 can be observed
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-2-1-1. month at which the work level increases from 1 to 2
sort IDlse YearMonth 
generate WL2Prom = . 
replace  WL2Prom = 1 if IDlse[_n]==IDlse[_n-1] & WL[_n]==2 & WL[_n-1]==1

*!! s-2-1-2. investigate those employees with multiple times of promotion
bysort IDlse: egen total_WL2Prom = total(WL2Prom)
tabulate total_WL2Prom if occurrence==1, missing
    //&? some margin cases with multiple times of promotion to WL2
/* 
total_WL2Pr |
         om |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |      9,378       63.61       63.61
          1 |      5,225       35.44       99.05
          2 |        134        0.91       99.96
          3 |          5        0.03       99.99
          4 |          1        0.01      100.00
------------+-----------------------------------
      Total |     14,743      100.00
*/
/* gsort -total_WL2Prom IDlse YearMonth */
    //&? after some exploration of the data, it is better to take the last promotion as the true one

*!! s-2-1-3. employees with observable promotion to WL2
bysort IDlse: egen q_witness_WL2Prom = max(WL2Prom)
tabulate q_witness_WL2Prom if occurrence==1, missing 
/* 
q_witness_W |
     L2Prom |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      5,365       36.39       36.39
          . |      9,378       63.61      100.00
------------+-----------------------------------
      Total |     14,743      100.00
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. at the month of promotion, values of AgeBand and AgeContinuous 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 
bysort IDlse: egen AgeContinuous_atWL2Prom = max(cond(WL2Prom==1, AgeContinuous, .))
bysort IDlse: egen AgeBand_atWL2Prom       = max(cond(WL2Prom==1, AgeBand,       .))
    //&? if an employee has multiple times promotion from WL1 to WL2 (which is very likely to be a measurement error),
    //&? by using max, I consider their last promotion as the true promotion to calculate age at promotion


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. for employees whose promotion to WL2 cannot be observed
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sort IDlse YearMonth
bysort IDlse: egen Min_AgeContinuous_atWL2 = min(cond(WL==2, AgeContinuous, .))
bysort IDlse: egen Min_AgeBand_atWL2       = min(cond(WL==2, AgeBand,       .))

order IDlse YearMonth WL q_witness_WL2Prom ///
    AgeBand AgeContinuous AgeBand_atWL2Prom AgeContinuous_atWL2Prom Min_AgeBand_atWL2 Min_AgeContinuous_atWL2

label values Min_AgeBand_atWL2 AgeBand
label values AgeBand_atWL2Prom AgeBand

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. create five new age-based high-flyer measure  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. DA30: AgeBand
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

label list AgeBand

generate DA30 = .
replace  DA30 = 1 if q_witness_WL2Prom==1 & AgeBand_atWL2Prom==1
replace  DA30 = 0 if q_witness_WL2Prom==1 & AgeBand_atWL2Prom>1
replace  DA30 = 1 if q_witness_WL2Prom==. & Min_AgeBand_atWL2==1
replace  DA30 = 0 if q_witness_WL2Prom==. & Min_AgeBand_atWL2>1

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. CA30: AgeContinuous; 30 as the uniform threshold
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CA30 = . 
replace  CA30 = 1 if q_witness_WL2Prom==1 & AgeContinuous_atWL2Prom<=30 
replace  CA30 = 0 if q_witness_WL2Prom==1 & AgeContinuous_atWL2Prom>30 
replace  CA30 = 1 if q_witness_WL2Prom==. & Min_AgeContinuous_atWL2<=30 
replace  CA30 = 0 if q_witness_WL2Prom==. & Min_AgeContinuous_atWL2>30 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. CA31: AgeContinuous; 31 as the threshold for unobservable case
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CA31 = . 
replace  CA31 = 1 if q_witness_WL2Prom==1 & AgeContinuous_atWL2Prom<=30 
replace  CA31 = 0 if q_witness_WL2Prom==1 & AgeContinuous_atWL2Prom>30 
replace  CA31 = 1 if q_witness_WL2Prom==. & Min_AgeContinuous_atWL2<=31 
replace  CA31 = 0 if q_witness_WL2Prom==. & Min_AgeContinuous_atWL2>31 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. CA32: AgeContinuous; 32 as the threshold for unobservable case
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CA32 = . 
replace  CA32 = 1 if q_witness_WL2Prom==1 & AgeContinuous_atWL2Prom<=30 
replace  CA32 = 0 if q_witness_WL2Prom==1 & AgeContinuous_atWL2Prom>30 
replace  CA32 = 1 if q_witness_WL2Prom==. & Min_AgeContinuous_atWL2<=32 
replace  CA32 = 0 if q_witness_WL2Prom==. & Min_AgeContinuous_atWL2>32 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-5. CA33: AgeContinuous; 33 as the threshold for unobservable case
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CA33 = . 
replace  CA33 = 1 if q_witness_WL2Prom==1 & AgeContinuous_atWL2Prom<=30 
replace  CA33 = 0 if q_witness_WL2Prom==1 & AgeContinuous_atWL2Prom>30 
replace  CA33 = 1 if q_witness_WL2Prom==. & Min_AgeContinuous_atWL2<=33 
replace  CA33 = 0 if q_witness_WL2Prom==. & Min_AgeContinuous_atWL2>33 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. original measure: OM
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. a set of auxiliary variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate WLAgg = WL
replace  WLAgg = 5 if WL>4 & WL!=.

//&? starting work level 
bysort IDlse: egen MinWL = min(WLAgg)  
//&? last observed work level 
bysort IDlse: egen MaxWL = max(WLAgg)

//&? age when the worker starts his last observed WL 
bysort IDlse: egen AgeMinMaxWL = min(cond(WL == MaxWL, AgeBand, .)) 
//&? number of months a worker is in his last observed WL
bysort IDlse: egen TenureMaxWLMonths = count(cond(WL==MaxWL, YearMonth, .) ) 
//&? number of years a worker is in his last observed WL
generate TenureMaxWL = TenureMaxWLMonths/12 
//&? tenure when the worker starts his last observed WL 
bysort IDlse: egen TenureMinMaxWL = min(cond(WL==MaxWL, Tenure, .)) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. variable EarlyAge: if the worker is a fast-track manager 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

summarize TenureMaxWL if MaxWL ==2 & occurrence==1, detail 

generate OM = 0 
replace  OM = 1 if MinWL==1 & MaxWL==2 & TenureMinMaxWL<=4 & TenureMaxWL<=6 
replace  OM = 1 if MaxWL==2 & AgeMinMaxWL==1 & TenureMaxWL<=6 
replace  OM = 1 if MaxWL==3 & AgeMinMaxWL<=2 & TenureMinMaxWL<=10 
replace  OM = 1 if MaxWL==4 & AgeMinMaxWL<=2 
replace  OM = 1 if MaxWL>4  & AgeMinMaxWL<=3 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. check correlation, and save the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

correlate OM DA30 CA30 CA31 CA32 CA33 if occurrence==1
/* 
(obs=14,743)

             |       OM     DA30     CA30     CA31     CA32     CA33
-------------+------------------------------------------------------
          OM |   1.0000
        DA30 |   0.5502   1.0000
        CA30 |   0.5420   0.8653   1.0000
        CA31 |   0.5217   0.8140   0.9409   1.0000
        CA32 |   0.4837   0.7407   0.8559   0.9097   1.0000
        CA33 |   0.4214   0.6498   0.7505   0.7977   0.8769   1.0000
 */

keep IDlse YearMonth OM DA30 CA30 CA31 CA32 CA33

generate long IDMngr_Pre  = IDlse
generate long IDMngr_Post = IDlse

drop IDlse

save "${TempData}/031902SixHighFlyerMeasures.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. other statistics about the HF measures
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??


use "${TempData}/031902SixHighFlyerMeasures.dta", clear 

rename IDMngr_Pre IDlse
order IDlse YearMonth
sort  IDlse YearMonth
bysort IDlse YearMonth: generate occurrence = _n
keep if occurrence==1

summarize OM DA30 CA30 CA31 CA32 CA33
/* 

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
          OM |  1,246,903    .2100388     .407336          0          1
        DA30 |  1,246,903    .2248282    .4174693          0          1
        CA30 |  1,246,903    .2934519    .4553439          0          1
        CA31 |  1,246,903     .325488    .4685571          0          1
        CA32 |  1,246,903    .3671954    .4820406          0          1
-------------+---------------------------------------------------------
        CA33 |  1,246,903    .4133128    .4924282          0          1
*/

correlate OM DA30 CA30 CA31 CA32 CA33
/* 
(obs=1,246,903)

             |       OM     DA30     CA30     CA31     CA32     CA33
-------------+------------------------------------------------------
          OM |   1.0000
        DA30 |   0.4691   1.0000
        CA30 |   0.4620   0.8342   1.0000
        CA31 |   0.4447   0.7738   0.9277   1.0000
        CA32 |   0.4182   0.7059   0.8460   0.9119   1.0000
        CA33 |   0.3844   0.6407   0.7678   0.8276   0.9076   1.0000

*/

tab2 OM DA30, missing row
/* 

           |         DA30
        OM |         0          1 |     Total
-----------+----------------------+----------
         0 |   863,009    121,996 |   985,005 
           |     87.61      12.39 |    100.00 
-----------+----------------------+----------
         1 |   103,555    158,343 |   261,898 
           |     39.54      60.46 |    100.00 
-----------+----------------------+----------
     Total |   966,564    280,339 | 1,246,903 
           |     77.52      22.48 |    100.00 
*/

tab2 OM CA30, missing row
/* 
           |         CA30
        OM |         0          1 |     Total
-----------+----------------------+----------
         0 |   802,804    182,201 |   985,005 
           |     81.50      18.50 |    100.00 
-----------+----------------------+----------
         1 |    78,193    183,705 |   261,898 
           |     29.86      70.14 |    100.00 
-----------+----------------------+----------
     Total |   880,997    365,906 | 1,246,903 
           |     70.65      29.35 |    100.00 
*/

tab2 OM CA31, missing row
/* 
           |         CA31
        OM |         0          1 |     Total
-----------+----------------------+----------
         0 |   770,234    214,771 |   985,005 
           |     78.20      21.80 |    100.00 
-----------+----------------------+----------
         1 |    70,817    191,081 |   261,898 
           |     27.04      72.96 |    100.00 
-----------+----------------------+----------
     Total |   841,051    405,852 | 1,246,903 
           |     67.45      32.55 |    100.00
*/

tab2 OM CA32, missing row 
/* 
           |         CA32
        OM |         0          1 |     Total
-----------+----------------------+----------
         0 |   725,714    259,291 |   985,005 
           |     73.68      26.32 |    100.00 
-----------+----------------------+----------
         1 |    63,332    198,566 |   261,898 
           |     24.18      75.82 |    100.00 
-----------+----------------------+----------
     Total |   789,046    457,857 | 1,246,903 
           |     63.28      36.72 |    100.00 
*/

tab2 OM CA33, missing row 
/* 
           |         CA33
        OM |         0          1 |     Total
-----------+----------------------+----------
         0 |   674,032    310,973 |   985,005 
           |     68.43      31.57 |    100.00 
-----------+----------------------+----------
         1 |    57,510    204,388 |   261,898 
           |     21.96      78.04 |    100.00 
-----------+----------------------+----------
     Total |   731,542    515,361 | 1,246,903 
           |     58.67      41.33 |    100.00 
*/