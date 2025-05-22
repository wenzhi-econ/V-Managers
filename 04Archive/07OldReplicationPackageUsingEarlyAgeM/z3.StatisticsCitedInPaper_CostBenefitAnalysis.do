/* 
This do file conducts cost-benefit analysis in Section 7.2 of the paper.

RA: WWZ 
Time: 2025-02-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. get low-flyer managers' average wage 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

drop IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 FT_Never_ChangeM FT_Rel_Time ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL ///
    ChangeMR
        //&? To avoid confusion, this dataset consists of managers in the event studies. 
        //&? They are not analysis units in event studies, so these variables are useless.

rename IDlse IDlseMHR
merge 1:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", nogenerate
rename (IDlseMHR EarlyAgeM) (IDlse EarlyAge)

capture drop Year
generate Year = year(dofm(YearMonth))

summarize PayBonus if WL==2 & EarlyAge==0 & Year==2019, detail
/* 
                          PayBonus
-------------------------------------------------------------
      Percentiles      Smallest
 1%     28176.63       6230.225
 5%     34447.11       6230.225
10%     41763.78       6230.225       Obs              98,839
25%     56691.68       6230.225       Sum of wgt.      98,839

50%      75868.2                      Mean           82404.93
                        Largest       Std. dev.      36575.86
75%        99360       310419.7
90%     134824.3       363606.7       Variance       1.34e+09
95%     159889.5       642293.6       Skewness       1.076625
99%     188702.1       642293.6       Kurtosis       5.066663
*/

global Mean_LFM_Wage = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. get WL2 managers' average team size  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

sort IDlseMHR YearMonth IDlse
bysort IDlseMHR YearMonth: generate TeamSize = _N 
summarize TeamSize, detail 
/*                           TeamSize
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            2              1
10%            2              1       Obs          10,083,638
25%            4              1       Sum of wgt.    10083638

50%            7                      Mean           40.23993
                        Largest       Std. dev.      423.5934
75%           13           9190
90%           29           9190       Variance       179431.4
95%           49           9190       Skewness       17.79643
99%          186           9190       Kurtosis       335.0836
*/

egen tag_mngr = tag(IDlseMHR YearMonth)
capture drop Year
generate Year = year(dofm(YearMonth))
summarize TeamSize if WLM==2 & tag_mngr==1 & Year==2019, detail
/* 
                          TeamSize
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs              92,024
25%            2              1       Sum of wgt.      92,024

50%            3                      Mean           4.192048
                        Largest       Std. dev.      4.200664
75%            5             79
90%            8            218       Variance       17.64558
95%           11            226       Skewness       8.052336
99%           19            231       Kurtosis       276.1481
*/

global Median_TeamSize = r(p50)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. other pieces of information   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global Operating_Profits = 10213147 
    //&? from Orbis data, in 1,000 millions 
global n = 150000 
    //&? from Orbis data, number of total employees 
global exchange_rate = 1.1194
    //&? pay-related variables in main data are measured in Euros 
    //&? pay-related variables in Orbis data data are measured in USD
    //&? 1 euro = 1.1194 dollars in 2019 (average)
    //&? The exchange rate is taken from https://fred.stlouisfed.org/series/DEXUSEU
global Increase_Prod = 0.18 
    //&? from column (1) in the productivity table 
global Increase_Wage = 0.144 
    //&? from panel (c) in the summary statistics table 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. final calculation
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global benefit = ${Median_TeamSize} * ((${Operating_Profits} * ${Increase_Prod})/ ${n}) * 1000 
global cost    = ${Mean_LFM_Wage} * ${Increase_Wage} * ${exchange_rate}

display "Benefit increase per manager: " ${benefit} 
    // Benefit increase per manager: 36767.329

display "Extra Costs per high flyer manager: " ${cost}
    // Extra Costs per high flyer manager: 13283.148

display "Ratio cost/benefit: " ${cost}/${benefit}
    // Ratio cost/benefit: .36127584
