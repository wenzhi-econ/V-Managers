/* 
This do file produces all statistics that are cited in the paper.

*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. numbers related to the event study design 
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


/* 
JMP_Managers/Paper Managers/DoFiles/z2_OldDoFiles/0.Paper/c.Analysis/0.2.PaperChecks.do
JMP_Managers/Paper Managers/DoFiles/z2_OldDoFiles/2.Descriptives/2.5.MiscStats.do
JMP_Managers/Paper Managers/DoFiles/z2_OldDoFiles/2.Descriptives/2.1.ManagerDes.do
JMP_Managers/Paper Managers/DoFiles/z2_OldDoFiles/2.Descriptives/2.2.JobsDes.do
JMP_Managers/Paper Managers/DoFiles/z2_OldDoFiles/2.Descriptives/2.3.SummaryStats.do
COST BENEFIT MANAGERS: JMP_Managers/Paper Managers/DoFiles/z2_OldDoFiles/0.Paper/c.Analysis/4.2.Misc.do 
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. how many functions and the size of subfunctions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n

tab Func if occurrence==1
/* 

                 Function |      Freq.     Percent        Cum.
--------------------------+-----------------------------------
                    Audit |        112        0.05        0.05
           Communications |      1,042        0.46        0.51
     Customer Development |     86,575       38.63       39.14
                  Finance |     18,467        8.24       47.38
       General Management |      4,651        2.08       49.46
          Human Resources |      8,654        3.86       53.32
   Information Technology |      4,395        1.96       55.28
                    Legal |      1,264        0.56       55.85
                Marketing |     21,329        9.52       65.36
     Research/Development |     13,457        6.00       71.37
             Supply Chain |     61,132       27.28       98.64
       Workplace Services |      2,671        1.19       99.84
                    UNKNW |          4        0.00       99.84
Information and Analytics |        167        0.07       99.91
       Project Management |         18        0.01       99.92
               Operations |         80        0.04       99.96
       Data and Analytics |         28        0.01       99.97
         Data & Analytics |         71        0.03      100.00
--------------------------+-----------------------------------
                    Total |    224,117      100.00
*/
/* 
The biggest six functions are:
    Customer Development: 38.63%
    Supply Chain: 27.28%
    Marketing: 9.52%
    Finance: 8.24%
    Research/Development: 6.00%
    Human Resources: 3.86%
*/

label list SubFunc

capture drop Size_SubFunc
sort SubFunc YearMonth IDlse
bysort SubFunc YearMonth: egen Size_SubFunc = count(IDlse)

egen tag_SubFunc_YM = tag(SubFunc YearMonth)

summarize Size_SubFunc if tag_SubFunc_YM==1, detail
/* 
                        Size_SubFunc
-------------------------------------------------------------
      Percentiles      Smallest
 1%            2              1
 5%            7              1
10%           16              1       Obs              10,974
25%           67              1       Sum of wgt.      10,974

50%          240                      Mean           918.8662
                        Largest       Std. dev.      2595.251
75%          788          24291
90%         2103          24330       Variance        6735328
95%         3080          24355       Skewness       7.124653
99%        21235          24523       Kurtosis       58.83218
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. how many standard job titles for WL1 workers  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

codebook StandardJob if WL==1 
    //&? 992 unique values 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. how many standard job titles inside a team and team size  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

sort IDlseMHR YearMonth IDlse
bysort IDlseMHR YearMonth: egen Size_StandardJob = nvals(StandardJob)

egen tag_Mngr_YM = tag(IDlseMHR YearMonth)

summarize Size_StandardJob if tag_Mngr_YM==1, detail
/* 
                      Size_StandardJob
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs           2,018,062
25%            1              1       Sum of wgt.   2,018,062

50%            2                      Mean           1.980874
                        Largest       Std. dev.       1.43945
75%            2             39
90%            4             40       Variance       2.072016
95%            5             42       Skewness       2.726785
99%            7             55       Kurtosis       18.12362
*/

sort IDlseMHR YearMonth IDlse
bysort IDlseMHR YearMonth: egen Size_Team = count(IDlse)
summarize Size_Team if tag_Mngr_YM==1, detail
/* 
                          Size_Team
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs           2,018,062
25%            2              1       Sum of wgt.   2,018,062

50%            3                      Mean           4.971967
                        Largest       Std. dev.      6.965016
75%            6            583
90%           10            595       Variance       48.51145
95%           13            610       Skewness       13.78036
99%           28            758       Kurtosis       495.7559
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. sd within a given office-job-month pair   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

bysort Office StandardJob YearMonth: egen PayBonusSD = sd(PayBonus)
egen OfficeJobYM_tag = tag(Office StandardJob YearMonth)

winsor2 PayBonusSD, suffix(T) cuts(5 95) trim
summarize PayBonusSDT, detail
/* 
                         PayBonusSD
-------------------------------------------------------------
      Percentiles      Smallest
 1%     238.2554       160.0375
 5%     660.0438       160.0375
10%     1518.931       160.0879       Obs           3,970,505
25%     3254.161       160.0879       Sum of wgt.   3,970,505

50%     5968.248                      Mean            7435.98
                        Largest       Std. dev.      5597.724
75%     10204.44       25570.41
90%     15924.35       25570.41       Variance       3.13e+07
95%     19121.04       25570.41       Skewness       1.047949
99%     23854.23       25570.41       Kurtosis       3.514185
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. bonus versus pay    
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

keep if WL==1
    //&? use only WL1 workers 

summarize Pay, detail 
    global mean_Pay = r(mean)
summarize Bonus, detail
    global mean_Bonus = r(mean)

display ${mean_Bonus} / ${mean_Pay}
    //&? .09525724


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 6. factory level numbers (how many factories with non-missing productivity data)   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_FactoryLevelAnalysis.dta", clear 
    //&? This dataset is constructed in 0304 do file

codebook OfficeCode if lp!=.
/* 
                  Type: Numeric (int)

                 Range: [1,20394]                     Units: 1
         Unique values: 158                       Missing .: 0/400

                  Mean: 3670.34
             Std. dev.: 4013.28

           Percentiles:     10%       25%       50%       75%       90%
                         1046.5      1410      2142      3255      9638
*/

