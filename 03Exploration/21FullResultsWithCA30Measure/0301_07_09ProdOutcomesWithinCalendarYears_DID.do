/* 
This do file presents the DID results on the productivity outcomes by calendar months.

RA: WWZ 
Time: 2025-05-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain a relevant dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. new productivity variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! productivity outcomes 
use "${TempData}/FinalAnalysisSample.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

generate Prod = log(Productivity + 1)
label variable Prod "Sales bonus (logs)"

keep Year - IDMngr_Post ISOCode LogPayBonus Productivity ProductivityStd Prod TransferSJVC ChangeSalaryGradeC LogPayBonus LogPay LogBonus Female AgeBand Office Func Country

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. sample restrictions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if ((ProductivityStd!=.))
    //impt: In this exercise, I keep only those employees who have non-missing productivity outcomes.


tabulate ISOCode, sort
tabulate YearMonth if ISOCode=="IND"
/* 
 Year-Month |      Freq.     Percent        Cum.
------------+-----------------------------------
     2014m1 |        732        2.14        2.14
     2014m2 |        731        2.14        4.28
     2014m3 |        730        2.14        6.42
     2014m4 |        736        2.15        8.57
     2014m5 |        683        2.00       10.57
     2014m6 |        727        2.13       12.70
     2014m7 |        736        2.15       14.85
     2014m8 |        728        2.13       16.98
     2014m9 |        726        2.12       19.10
    2014m10 |        714        2.09       21.19
    2014m11 |        658        1.93       23.12
    2014m12 |        658        1.93       25.04
     2015m1 |        724        2.12       27.16
     2015m2 |         40        0.12       27.28
     2015m3 |         40        0.12       27.40
     2015m4 |         38        0.11       27.51
     2015m5 |         25        0.07       27.58
     2015m6 |         25        0.07       27.65
     2015m7 |         48        0.14       27.80
     2015m8 |         43        0.13       27.92
     2015m9 |         48        0.14       28.06
    2015m10 |         47        0.14       28.20
    2015m11 |         47        0.14       28.34
    2015m12 |         46        0.13       28.47
     2016m1 |         46        0.13       28.61
     2016m2 |         46        0.13       28.74
     2016m3 |         32        0.09       28.83
     2016m4 |          2        0.01       28.84
     2016m5 |          1        0.00       28.84
     2016m6 |          2        0.01       28.85
     2016m7 |         11        0.03       28.88
     2016m8 |         11        0.03       28.91
     2016m9 |         11        0.03       28.95
    2016m10 |          3        0.01       28.95
    2016m11 |          5        0.01       28.97
    2016m12 |          4        0.01       28.98
     2017m1 |         56        0.16       29.14
     2017m2 |         56        0.16       29.31
     2017m3 |         56        0.16       29.47
     2017m4 |         49        0.14       29.62
     2017m5 |         49        0.14       29.76
     2017m6 |         50        0.15       29.90
     2017m7 |         51        0.15       30.05
     2017m8 |         51        0.15       30.20
     2017m9 |         51        0.15       30.35
    2017m10 |         51        0.15       30.50
    2017m11 |         51        0.15       30.65
    2017m12 |         51        0.15       30.80
     2018m1 |        639        1.87       32.67
     2018m2 |        623        1.82       34.49
     2018m3 |        616        1.80       36.30
     2018m4 |        618        1.81       38.10
     2018m5 |        613        1.79       39.90
     2018m6 |        606        1.77       41.67
     2018m7 |        626        1.83       43.50
     2018m8 |        612        1.79       45.29
     2018m9 |        605        1.77       47.06
    2018m10 |        599        1.75       48.82
    2018m11 |        594        1.74       50.55
    2018m12 |        581        1.70       52.25
     2019m1 |        591        1.73       53.98
     2019m2 |        580        1.70       55.68
     2019m3 |        567        1.66       57.34
     2019m4 |        577        1.69       59.03
     2019m5 |        568        1.66       60.69
     2019m6 |        559        1.64       62.33
     2019m7 |        553        1.62       63.94
     2019m8 |        544        1.59       65.54
     2019m9 |        529        1.55       67.08
    2019m10 |        528        1.54       68.63
    2019m11 |        514        1.50       70.13
    2019m12 |        507        1.48       71.62
     2020m1 |        525        1.54       73.15
     2020m2 |        519        1.52       74.67
     2020m3 |        511        1.50       76.17
     2020m4 |        554        1.62       77.79
     2020m5 |        552        1.62       79.40
     2020m6 |        546        1.60       81.00
     2020m7 |        534        1.56       82.56
     2020m8 |        535        1.57       84.13
     2020m9 |        533        1.56       85.69
    2020m10 |        541        1.58       87.27
    2020m11 |        539        1.58       88.85
    2020m12 |        536        1.57       90.42
     2021m1 |        536        1.57       91.99
     2021m2 |        534        1.56       93.55
     2021m3 |        518        1.52       95.06
     2021m4 |        518        1.52       96.58
     2021m5 |        290        0.85       97.43
     2021m6 |        369        1.08       98.51
     2021m7 |        510        1.49      100.00
------------+-----------------------------------
      Total |     34,175      100.00
*/
tabulate YearMonth if ISOCode=="IDN"
/* 
 Year-Month |      Freq.     Percent        Cum.
------------+-----------------------------------
     2018m1 |        148        3.19        3.19
     2018m2 |        147        3.16        6.35
     2018m3 |        147        3.16        9.51
     2018m4 |        148        3.19       12.70
     2018m5 |        152        3.27       15.97
     2018m6 |        153        3.29       19.26
     2018m7 |        153        3.29       22.56
     2018m8 |        133        2.86       25.42
     2018m9 |        127        2.73       28.15
    2018m10 |        148        3.19       31.34
    2018m11 |        148        3.19       34.52
    2018m12 |        149        3.21       37.73
     2019m1 |         19        0.41       38.14
     2019m2 |         19        0.41       38.55
     2019m3 |         21        0.45       39.00
     2019m4 |         23        0.50       39.50
     2019m5 |         22        0.47       39.97
     2019m6 |         21        0.45       40.42
     2019m7 |        152        3.27       43.69
     2019m8 |        151        3.25       46.94
     2019m9 |        149        3.21       50.15
    2019m10 |        150        3.23       53.38
    2019m11 |        154        3.31       56.69
    2019m12 |        156        3.36       60.05
     2020m1 |        155        3.34       63.39
     2020m2 |        155        3.34       66.72
     2020m3 |        151        3.25       69.97
     2020m4 |        149        3.21       73.18
     2020m5 |        151        3.25       76.43
     2020m6 |        152        3.27       79.70
     2020m7 |        154        3.31       83.02
     2020m8 |        154        3.31       86.33
     2020m9 |        152        3.27       89.60
    2020m10 |        150        3.23       92.83
    2020m11 |        149        3.21       96.04
    2020m12 |        149        3.21       99.25
     2021m1 |          3        0.06       99.31
     2021m2 |          3        0.06       99.38
     2021m3 |          3        0.06       99.44
     2021m4 |          2        0.04       99.48
     2021m5 |          3        0.06       99.55
     2021m6 |          3        0.06       99.61
     2021m7 |          3        0.06       99.68
     2021m8 |          3        0.06       99.74
     2021m9 |          3        0.06       99.81
    2021m10 |          3        0.06       99.87
    2021m11 |          3        0.06       99.94
    2021m12 |          3        0.06      100.00
------------+-----------------------------------
      Total |      4,646      100.00
*/
tabulate YearMonth if ISOCode=="ITA"
/*  
 Year-Month |      Freq.     Percent        Cum.
------------+-----------------------------------
     2018m1 |         86        2.77        2.77
     2018m2 |         86        2.77        5.55
     2018m3 |         86        2.77        8.32
     2018m4 |         97        3.13       11.45
     2018m5 |         97        3.13       14.58
     2018m6 |         97        3.13       17.70
     2018m7 |         98        3.16       20.86
     2018m8 |         98        3.16       24.02
     2018m9 |         98        3.16       27.18
    2018m10 |         56        1.81       28.99
    2018m11 |         56        1.81       30.80
    2018m12 |         56        1.81       32.60
     2019m1 |         92        2.97       35.57
     2019m2 |         92        2.97       38.54
     2019m3 |         92        2.97       41.50
     2019m4 |         92        2.97       44.47
     2019m5 |         91        2.93       47.40
     2019m6 |         89        2.87       50.27
     2019m7 |         92        2.97       53.24
     2019m8 |         92        2.97       56.21
     2019m9 |         91        2.93       59.14
    2019m10 |         92        2.97       62.11
    2019m11 |         86        2.77       64.88
    2019m12 |         85        2.74       67.62
     2020m1 |         83        2.68       70.30
     2020m2 |         83        2.68       72.98
     2020m3 |         83        2.68       75.65
     2020m4 |         42        1.35       77.01
     2020m5 |         42        1.35       78.36
     2020m6 |         42        1.35       79.72
     2020m7 |         42        1.35       81.07
     2020m8 |         42        1.35       82.43
     2020m9 |         42        1.35       83.78
    2020m10 |         42        1.35       85.13
    2020m11 |         42        1.35       86.49
    2020m12 |         41        1.32       87.81
     2021m1 |         33        1.06       88.87
     2021m2 |         33        1.06       89.94
     2021m3 |         33        1.06       91.00
     2021m4 |         33        1.06       92.07
     2021m5 |         33        1.06       93.13
     2021m6 |         33        1.06       94.20
     2021m7 |         30        0.97       95.16
     2021m8 |         30        0.97       96.13
     2021m9 |         30        0.97       97.10
    2021m10 |         30        0.97       98.07
    2021m11 |         30        0.97       99.03
    2021m12 |         30        0.97      100.00
------------+-----------------------------------
      Total |      3,101      100.00
*/
tabulate YearMonth if ISOCode=="RUS"
/* 
 Year-Month |      Freq.     Percent        Cum.
------------+-----------------------------------
     2018m1 |         72        2.73        2.73
     2018m2 |         70        2.65        5.37
     2018m3 |         71        2.69        8.06
     2018m4 |         69        2.61       10.67
     2018m5 |         70        2.65       13.32
     2018m6 |         67        2.54       15.86
     2018m7 |         66        2.50       18.36
     2018m8 |         64        2.42       20.78
     2018m9 |         63        2.38       23.16
    2018m10 |         63        2.38       25.55
    2018m11 |         63        2.38       27.93
    2018m12 |         63        2.38       30.32
     2019m1 |         65        2.46       32.78
     2019m2 |         65        2.46       35.24
     2019m3 |         65        2.46       37.70
     2019m4 |         60        2.27       39.97
     2019m5 |         59        2.23       42.20
     2019m6 |         56        2.12       44.32
     2019m7 |         57        2.16       46.48
     2019m8 |         55        2.08       48.56
     2019m9 |         54        2.04       50.61
    2019m10 |         55        2.08       52.69
    2019m11 |         56        2.12       54.81
    2019m12 |         57        2.16       56.96
     2020m1 |         51        1.93       58.89
     2020m2 |         52        1.97       60.86
     2020m3 |         54        2.04       62.91
     2020m4 |         51        1.93       64.84
     2020m5 |         50        1.89       66.73
     2020m6 |         54        2.04       68.77
     2020m7 |         51        1.93       70.70
     2020m8 |         52        1.97       72.67
     2020m9 |         53        2.01       74.68
    2020m10 |         51        1.93       76.61
    2020m11 |         50        1.89       78.50
    2020m12 |         50        1.89       80.39
     2021m1 |         48        1.82       82.21
     2021m2 |         48        1.82       84.03
     2021m3 |         48        1.82       85.84
     2021m4 |         45        1.70       87.55
     2021m5 |         33        1.25       88.80
     2021m6 |         46        1.74       90.54
     2021m7 |         44        1.67       92.20
     2021m8 |         43        1.63       93.83
     2021m9 |         43        1.63       95.46
    2021m10 |         41        1.55       97.01
    2021m11 |         42        1.59       98.60
    2021m12 |         37        1.40      100.00
------------+-----------------------------------
      Total |      2,642      100.00
*/

generate Year18to20 = inrange(YearMonth, tm(2018m1), tm(2020m12))
generate Year18to21 = inrange(YearMonth, tm(2018m1), tm(2021m12))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. who are in the balanced sample 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Min_RelTime = min(Rel_Time)
bysort IDlse: egen Max_RelTime = max(Rel_Time)

summarize Min_RelTime, detail
summarize Max_RelTime, detail

generate q_BalancedSample=1 if Min_RelTime<0 & Max_RelTime>0

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct regressors used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate  CA30_Rel_Time = Rel_Time
foreach event in CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL {
    generate byte `event'_X_Post = `event' * (CA30_Rel_Time >= 0)
}

global DID_dummies Post_Event CA30_LtoH_X_Post CA30_HtoH_X_Post CA30_HtoL_X_Post 

label variable Post_Event "Post-event"
label variable CA30_LtoH_X_Post "LtoH $\times$ post-event"
label variable CA30_HtoH_X_Post "HtoH $\times$ post-event"
label variable CA30_HtoL_X_Post "HtoL $\times$ post-event"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. TWFE: run regressions and produce the regression table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2018m1), tm(2018m12))==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2019m1), tm(2019m12))==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2020m1), tm(2020m12))==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_20
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2021m1), tm(2021m12))==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & !inrange(YearMonth, tm(2019m1), tm(2019m12)), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21_No19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{2018m1-2021m12} & \multicolumn{1}{c}{2018m1-2018m12}  & \multicolumn{1}{c}{2019m1-2019m12} & \multicolumn{1}{c}{2020m1-2020m12} & \multicolumn{1}{c}{2021m1-2021m12} & \multicolumn{1}{c}{\shortstack{2018m1-2021m12, \\ no 2019m1-2019m12}} \\"
global latex_panel        "& \multicolumn{6}{c}{Sales bonus (s.d.)} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_ProdOutcomesInDID_CalendarMonths.tex"

esttab Prod_18to21 Prod_18 Prod_19 Prod_20 Prod_21 Prod_18to21_No19 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(${DID_dummies}) order(${DID_dummies}) ///
    stats(cmean r2 N, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4.1. exit controls: run regressions and produce the regression table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global controls Female#AgeBand Office#Func

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2018m1), tm(2018m12))==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2019m1), tm(2019m12))==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2020m1), tm(2020m12))==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_20
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2021m1), tm(2021m12))==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & !inrange(YearMonth, tm(2019m1), tm(2019m12)), absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21_No19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{2018m1-2021m12} & \multicolumn{1}{c}{2018m1-2018m12}  & \multicolumn{1}{c}{2019m1-2019m12} & \multicolumn{1}{c}{2020m1-2020m12} & \multicolumn{1}{c}{2021m1-2021m12} & \multicolumn{1}{c}{\shortstack{2018m1-2021m12, \\ no 2019m1-2019m12}} \\"
global latex_panel        "& \multicolumn{6}{c}{Sales bonus (s.d.)} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_ProdOutcomesInDID_CalendarMonths_ExitControls.tex"

esttab Prod_18to21 Prod_18 Prod_19 Prod_20 Prod_21 Prod_18to21_No19 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(${DID_dummies}) order(${DID_dummies}) ///
    stats(cmean r2 N, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4.2. country controls: run regressions and produce the regression table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global controls Country

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2018m1), tm(2018m12))==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2019m1), tm(2019m12))==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2020m1), tm(2020m12))==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_20
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if inrange(YearMonth, tm(2021m1), tm(2021m12))==1, absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_21
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ProductivityStd ${DID_dummies} if Year18to21==1 & !inrange(YearMonth, tm(2019m1), tm(2019m12)), absorb(${controls} YearMonth) vce(cluster IDlseMHR) 
    eststo Prod_18to21_No19
    summarize ProductivityStd if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_titles       "& \multicolumn{1}{c}{2018m1-2021m12} & \multicolumn{1}{c}{2018m1-2018m12}  & \multicolumn{1}{c}{2019m1-2019m12} & \multicolumn{1}{c}{2020m1-2020m12} & \multicolumn{1}{c}{2021m1-2021m12} & \multicolumn{1}{c}{\shortstack{2018m1-2021m12, \\ no 2019m1-2019m12}} \\"
global latex_panel        "& \multicolumn{6}{c}{Sales bonus (s.d.)} \\"
global latex_line         "\cmidrule(lr){2-7}"
global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_ProdOutcomesInDID_CalendarMonths_CountryControl.tex"

esttab Prod_18to21 Prod_18 Prod_19 Prod_20 Prod_21 Prod_18to21_No19 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(${DID_dummies}) order(${DID_dummies}) ///
    stats(cmean r2 N, labels("Control mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_panel}" "${latex_line}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. what is in year 2019 data
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

keep Year - IDMngr_Post ISOCode Female AgeBand Office Func ///
    LogPayBonus Productivity ProductivityStd ///
    TransferSJVC ChangeSalaryGradeC LogPayBonus LogPay LogBonus 

keep if ((ProductivityStd!=.))
    //impt: In this exercise, I keep only those employees who have non-missing productivity outcomes.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-1. tabulation of the countries
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

tabulate ISOCode if inrange(YearMonth, tm(2019m1), tm(2019m12)), sort 
/* 
ISO code of |
the working |
    country |      Freq.     Percent        Cum.
------------+-----------------------------------
        IND |      6,617       66.29       66.29
        ITA |      1,086       10.88       77.17
        IDN |      1,037       10.39       87.56
        RUS |        704        7.05       94.61
        MEX |        212        2.12       96.73
        PHL |        162        1.62       98.36
        ZAF |         48        0.48       98.84
        GTM |         34        0.34       99.18
        MYS |         24        0.24       99.42
        NIC |         17        0.17       99.59
        CRI |         12        0.12       99.71
        HND |         12        0.12       99.83
        SLV |         12        0.12       99.95
        COL |          5        0.05      100.00
------------+-----------------------------------
      Total |      9,982      100.00
*/

tabulate ISOCode if inrange(YearMonth, tm(2018m1), tm(2021m12)) & (!inrange(YearMonth, tm(2019m1), tm(2019m12))), sort 
/* 
ISO code of |
the working |
    country |      Freq.     Percent        Cum.
------------+-----------------------------------
        IND |     17,032       65.65       65.65
        IDN |      3,609       13.91       79.57
        ITA |      2,015        7.77       87.33
        RUS |      1,938        7.47       94.80
        MEX |        649        2.50       97.31
        PHL |        270        1.04       98.35
        GTM |        127        0.49       98.84
        MYS |         72        0.28       99.11
        ZAF |         45        0.17       99.29
        NIC |         42        0.16       99.45
        SLV |         39        0.15       99.60
        COL |         36        0.14       99.74
        CRI |         36        0.14       99.88
        HND |         24        0.09       99.97
        GRC |          8        0.03      100.00
------------+-----------------------------------
      Total |     25,942      100.00
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-2. distribution of the productivity outcome 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

graph twoway ///
    (histogram ProductivityStd if inrange(YearMonth, tm(2019m1), tm(2019m12)), width(0.1) bcolor(dkgreen%50)) ///
    (kdensity  ProductivityStd if inrange(YearMonth, tm(2019m1), tm(2019m12)), lcolor(dkgreen%50)) ///
    , xtitle("Sales bonus (s.d.)", size(medlarge)) xlabel(-7(0.5)7, grid gstyle(dot) labsize(small)) ///
    legend(label(1 "2019m1-2019m12") order(1) position(1) ring(1)) name(Dist_2019, replace)

graph twoway ///
    (histogram ProductivityStd if inrange(YearMonth, tm(2018m1), tm(2021m12)) & (!inrange(YearMonth, tm(2019m1), tm(2019m12))), width(0.1) bcolor(red%50)) ///
    (kdensity  ProductivityStd if inrange(YearMonth, tm(2018m1), tm(2021m12)) & (!inrange(YearMonth, tm(2019m1), tm(2019m12))), lcolor(red%50)) ///
    , xtitle("Sales bonus (s.d.)", size(medlarge)) xlabel(-7(0.5)7, grid gstyle(dot) labsize(small)) ///
    legend(label(1 "2018m1-2021m12, excluding 2019m1-2019m12") order(1) position(1) ring(1)) name(Dist_No2019, replace)

graph combine Dist_No2019 Dist_2019, cols(1)
graph export "${Results}/005EventStudiesWithCA30/DistributionOfProd_ByCalenderYears.pdf", replace as(pdf)
