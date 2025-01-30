/* 
This do file explores the possibility of using Tenure as thresholds to define high-flyer status.


RA: WWZ 
Time: 2024-12-06
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. load the raw dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${RawMNEData}/AllSnapshotWC.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

bysort IDlse: generate occurrence = _n 
order IDlse YearMonth occurrence IDlseMHR

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. manager id imputations 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in IDlseMHR {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. 
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. who are fast-track managers - EarlyAgeM
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. a set of auxiliary variables 
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
*-? s-2-2. variable EarlyAge: if the worker is a fast-track manager 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

summarize TenureMaxWL if MaxWL ==2 & occurrence==1, detail 

generate EarlyAge = 0 
replace  EarlyAge = 1 if MinWL==1 & MaxWL==2 & TenureMinMaxWL<=4 & TenureMaxWL<=6 
replace  EarlyAge = 1 if MaxWL==2 & AgeMinMaxWL==1 & TenureMaxWL<=6 
replace  EarlyAge = 1 if MaxWL==3 & AgeMinMaxWL<=2 & TenureMinMaxWL<=10 
replace  EarlyAge = 1 if MaxWL==4 & AgeMinMaxWL<=2 
replace  EarlyAge = 1 if MaxWL>4  & AgeMinMaxWL<=3 
label variable EarlyAge "Fast track manager based on age when promoted (WL)"


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. Tenure distribution under different conditions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize TenureMinMaxWL if MaxWL==2 & AgeMinMaxWL==1 & TenureMaxWL<=6, detail 
/* 
                       TenureMinMaxWL
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs             316,979
25%            2              0       Sum of wgt.     316,979

50%            3                      Mean           3.000492
                        Largest       Std. dev.      1.849378
75%            4             10
90%            5             10       Variance       3.420199
95%            6             10       Skewness       .2584099
99%            8             10       Kurtosis       2.849755
*/

summarize TenureMinMaxWL if MaxWL==3 & AgeMinMaxWL<=2 & TenureMinMaxWL<=10, detail
/*                        TenureMinMaxWL
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs             139,436
25%            3              0       Sum of wgt.     139,436

50%            7                      Mean           6.142675
                        Largest       Std. dev.        3.4539
75%            9             10
90%           10             10       Variance       11.92943
95%           10             10       Skewness      -.6194276
99%           10             10       Kurtosis        1.99877
*/

summarize TenureMinMaxWL if MaxWL==4 & AgeMinMaxWL<=2, detail 
/* 
                       TenureMinMaxWL
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            1              0
10%            2              0       Obs              19,886
25%            8              0       Sum of wgt.      19,886

50%           13                      Mean           11.23524
                        Largest       Std. dev.      4.970213
75%           15             19
90%           16             19       Variance       24.70302
95%           16             19       Skewness       -.943773
99%           17             19       Kurtosis       2.720868

*/

summarize TenureMinMaxWL if MaxWL>4  & AgeMinMaxWL<=3, detail 
/* 
                       TenureMinMaxWL
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            1              0
10%            2              0       Obs              12,692
25%           14              0       Sum of wgt.      12,692

50%           20                      Mean           17.24882
                        Largest       Std. dev.      7.963574
75%           23             28
90%           25             28       Variance        63.4185
95%           26             28       Skewness      -.9946039
99%           27             28       Kurtosis       2.712313
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. LT (abbreviation for Low Tenure)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??


capture drop LT 
quietly {
    generate LT = 0 
    replace  LT = 1 if MinWL==1 & MaxWL==2 & TenureMinMaxWL<=4 & TenureMaxWL<=6 
    replace  LT = 1 if MaxWL==2 & TenureMinMaxWL<=2
    replace  LT = 1 if MaxWL==3 & TenureMinMaxWL<=10 
    replace  LT = 1 if MaxWL==4 & TenureMinMaxWL<=15
    replace  LT = 1 if MaxWL>4  & TenureMinMaxWL<=20
    label variable LT "Fast track manager based on tenure when promoted"
}
/* display "----------------------------`j'" */
/* tabulate LT EarlyAge if occurrence==1, missing  */
correlate LT EarlyAge if occurrence==1

/* 
             |       LT EarlyAge
-------------+------------------
          LT |   1.0000
    EarlyAge |   0.6496   1.0000

 */

correlate LT EarlyAge if occurrence==1
/* 

             |       LT EarlyAge
-------------+------------------
          LT |   1.0000
    EarlyAge |   0.5786   1.0000


*/
correlate LT EarlyAge if occurrence==1 & MaxWL==2 & MinWL==1
/* 
             |       LT EarlyAge
-------------+------------------
          LT |   1.0000
    EarlyAge |   0.7693   1.0000
*/

correlate LT EarlyAge if occurrence==1 & MaxWL==2
/* 
             |       LT EarlyAge
-------------+------------------
          LT |   1.0000
    EarlyAge |   0.4514   1.0000
*/
correlate LT EarlyAge if occurrence==1 & MaxWL==3
/* 
             |       LT EarlyAge
-------------+------------------
          LT |   1.0000
    EarlyAge |   0.3485   1.0000
*/
correlate LT EarlyAge if occurrence==1 & MaxWL==4
/* 

             |       LT EarlyAge
-------------+------------------
          LT |   1.0000
    EarlyAge |   0.1382   1.0000
*/


keep IDlse YearMonth LT 
rename IDlse IDlseMHR 
rename LT LTM

save "${TempData}/02Mngr_LTM.dta", replace 