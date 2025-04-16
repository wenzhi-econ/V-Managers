/* 
This do file creates a corrected version of AgeBand.

Input:
    "${RawMNEData}/AllSnapshotWC.dta"        <== raw data

Output:
    "${TempData}/0102_01AgeBandUpdated.dta"  <== output dataset

Description of the output dataset:
    It stores three variables (IDlse YearMonth AgeBandUpdated), where the original AgeBand variable is updated based on two features:
        (1) There should not be any decrease in AgeBand values for an employee as time goes by.
        (2) An employee cannot have two increases in AgeBand values since we only have 10 years of data.

RA: WWZ 
Time: 2025-04-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. load the raw dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${RawMNEData}/AllSnapshotWC.dta", clear

keep  IDlse YearMonth AgeBand Tenure WL Year
order Tenure WL Year IDlse YearMonth AgeBand
label list AgeBand 
/* 
    1 Age 18 - 29
    2 Age 30 - 39
    3 Age 40 - 49
    4 Age 50 - 59
    5 Age 60 - 69
    6 Age 70 and over
    7 Age Under 18
    8 Age Unknown 
*/
sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
order occurrence, after(YearMonth)
summarize occurrence, detail  
    //&? max: 132
    //&? impossible to go through two age band changes  

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. update AgeBand variable: deal with <18 and unknown values 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* 
general idea:
    (1) if we can observe a worker whose AgeBand has changed in our dataset, then we can exactly identify his year(month) of birth.
    (2) however, in the dataset, there are some AgeBand changes that do not make sense.
    (3) this step is used to remove these unreasonable changes, and create a correct version of AgeBand variable.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. check the cases with <18 and unknown age bands
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
description of this step:
    it is annoying to deal with non-monotonic AgeBand values: 7 (<18) and 8 (unknown ages).
    reclassification of these two marginal values does not hurt, but can generate an increasing AgeBand values (1-6). 
*/

*!! s-1-1-1. maximum AgeBand
sort IDlse YearMonth
bysort IDlse: egen MaxAgeBand = max(AgeBand)
tab MaxAgeBand if occurrence==1, missing

*!! s-1-1-2. count of observations at the maximum AgeBand
sort IDlse YearMonth
bysort IDlse: egen count_MaxAgeBand = sum(cond(AgeBand==MaxAgeBand, 1, 0))

*!! s-1-1-3. count of all observations
sort IDlse YearMonth
bysort IDlse: egen count = max(occurrence)

*!! s-1-1-4. mark all employees who have the same AgeBand value throughout
generate same_age_throughout = (count_MaxAgeBand==count)

*!! s-1-1-5. multiple possible cases with regard to MaxAgeBand==7 (<18) and MaxAgeBand==8 (unknown)
tabulate MaxAgeBand same_age_throughout if occurrence==1, missing
/* 
           |  same_age_throughout
MaxAgeBand |         0          1 |     Total
-----------+----------------------+----------
         1 |         0     70,650 |    70,650 
         2 |    34,743     47,493 |    82,236 
         3 |    23,147     18,243 |    41,390 
         4 |    12,907      9,717 |    22,624 
         5 |     3,858      1,803 |     5,661 
         6 |       112         83 |       195 
         7 |       638        353 |       991 
         8 |       361          9 |       370 
-----------+----------------------+----------
     Total |    75,766    148,351 |   224,117 
*/

/* 
classification of different cases:
    (1) for employees (9) whose MaxAgeBand values are always unknown for all their observations, they will be excluded from the dataset 
    (2) for employees (361) whose MaxAgeBand values are unknown for only some observations, I will impute them with the mode of their AgeBand. 
    (3) for employees (353 + 636) whose MaxAgeBand values are <18, I will classify them into 18-29.

notes for (3):
    (a) the goal of re-construct the AgeBand value is to create an intuitive version of age-based high-flyer measures.
    (b) therefore, this marginal case where employees are at some point <18 will not affect managers' identification.
    (c) but this re-classification of underaged employees can greatly simplify the age construction process.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. deal with cases with <18 and unknown age bands
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-1-2-1. case (1)
drop if MaxAgeBand==8 & same_age_throughout==1

*!! s-1-2-2. case (2)
sort MaxAgeBand IDlse YearMonth
replace AgeBand = . if AgeBand==8
bysort IDlse: egen ModeAgeBand = mode(AgeBand), minmode
    //&? the reason I sue minmode is that after exploring the data, 
    //&? the missing AgeBand values are more likely to happen in the first occurrence of one employee
replace ModeAgeBand=. if MaxAgeBand!=8
replace AgeBand = ModeAgeBand if MaxAgeBand==8

*!! s-1-2-3. case (3)
replace AgeBand = 1 if AgeBand==7

*!! s-1-2-4. re-create the MaxAgeBand variable based on the updated AgeBand variable
capture drop MaxAgeBand
sort IDlse YearMonth
bysort IDlse: egen MaxAgeBand = max(AgeBand)

keep  Tenure WL Year IDlse YearMonth occurrence count AgeBand
order Tenure WL Year IDlse YearMonth occurrence count AgeBand

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. update AgeBand variable: deal with decreasing AgeBand 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* 
description of this step:
    (1) it is impossible to experience an age decrease as time goes by.
    (2) an investigation of the data suggests that some employees experience false age increase during 2014m1-m4.
    (3) for one employee who experiences an AgeBand value decrease, I will update his previous AgeBand values using the last post-decrease AgeBand value.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. investigate those age decreases 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate age_decrease = . 
replace  age_decrease = 1 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]<AgeBand[_n-1]
replace  age_decrease = 0 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]>=AgeBand[_n-1]
replace  age_decrease = 0 if IDlse[_n]!=IDlse[_n-1]

sort IDlse YearMonth
bysort IDlse: egen ind_age_decrease = max(age_decrease)
bysort IDlse: egen total_age_decrease = total(age_decrease)
bysort IDlse: generate id_age_decrease = sum(age_decrease)

summarize ind_age_decrease if occurrence==1
    //&? 2.18243% employees experience decreases in AgeBand values.
    //&? given that we have re-classified <18 and unknown AgeBand values, this is impossible.
summarize total_age_decrease if occurrence==1, detail
    //&? mean=.0218555, max=2
    //&? this suggests some minor measurement errors.
tabulate YearMonth if age_decrease==1, missing
    //&? 95.77% happens in 2014m5
    //&? after some exploration of the data, it seems that the AgeBand values experience incorrectly increase during 2014m1-2014m4

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. update AgeBand: using age when the last decrease occurs
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-2-2-1. for those who experiences AgeBand decreases, the year-month when the last decrease occurs
sort IDlse YearMonth
bysort IDlse: egen YM_last_age_decrease = min(cond(total_age_decrease==id_age_decrease & total_age_decrease>=1, YearMonth, .))

*!! s-2-2-2. for those who experiences AgeBand decreases, the AgeBand value when the last decrease occurs
sort IDlse YearMonth
bysort IDlse: egen AgeBand_last_age_decrease = mean(cond(YearMonth==YM_last_age_decrease, AgeBand, .))

*!! s-2-2-3. update AgeBand values for all previous months 
replace AgeBand = AgeBand_last_age_decrease if YearMonth<YM_last_age_decrease & YM_last_age_decrease!=.

*!! s-2-2-4. no AgeBand decreases: pass the test successfully
/* capture drop age_decrease
generate age_decrease = . 
replace  age_decrease = 1 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]<AgeBand[_n-1]
replace  age_decrease = 0 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]>=AgeBand[_n-1]
replace  age_decrease = 0 if IDlse[_n]!=IDlse[_n-1]
codebook age_decrease */

keep  Tenure WL Year IDlse YearMonth occurrence count AgeBand
order Tenure WL Year IDlse YearMonth occurrence count AgeBand

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. update AgeBand variable: deal with multiple AgeBand increases 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. investigate those age increases 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate age_increase = . 
replace  age_increase = 1 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]>AgeBand[_n-1]
replace  age_increase = 0 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]==AgeBand[_n-1]
replace  age_increase = 0 if IDlse[_n]!=IDlse[_n-1]

sort IDlse YearMonth
bysort IDlse: egen ind_age_increase = max(age_increase)
bysort IDlse: egen total_age_increase = total(age_increase)
bysort IDlse: generate id_age_increase = sum(age_increase)

summarize ind_age_increase if occurrence==1
    //&? 33.17909% employees experience increases in AgeBand values.
summarize total_age_increase if occurrence==1, detail
    //&? mean=.3320408, max=2
    //&? some limited cases experience two age increases, which is impossible

tabulate YearMonth if ind_age_increase==1, missing
    //&? quite uniform distribution, a very good sign!

tabulate total_age_increase if occurrence==1, missing
/* 
total_age_i |
    ncrease |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    149,751       66.82       66.82
          1 |     74,301       33.15       99.98
          2 |         56        0.02      100.00
------------+-----------------------------------
      Total |    224,108      100.00
*/
    //&? only 56 employees with 2 AgeBand increases

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. investigate those age increases 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-3-2-1. when did the second AgeBand increase happen in an employee's panel?
capture drop rate 
generate rate=occurrence/count if age_increase==1 & total_age_increase==2 & id_age_increase==2
sort IDlse YearMonth
bysort IDlse: egen ind_rate = mean(rate)
tabulate rate if age_increase==1 & total_age_increase==2 & id_age_increase==2
/* 
two observations:
    (1) among those 56 employees, 21 employees have their second AgeBand increase in their last occurrence in the data. for these 21 employees, it is obvious I should not use their second AgeBand increase to determine their age.
    (2) among these 56 employees, 6 employees have their second AgeBand increase in their first half of the data. for these 6 employees, it is obvious that I should use their second AgeBand increase to determien their age.

    finally, I decide to use the 50% cutoff: depending on which half the second AgeBand increase happens, I will use different times of AgeBand increase to determine their AgeBand.
*/

*!! s-3-2-2. use first or second AgeBand increase to infer age 
generate first_increase  = (ind_rate>0.5) if ind_rate!=.
generate second_increase = (ind_rate<0.5) if ind_rate!=.

*!! s-3-2-3. AgeBand at first and second increase 
sort IDlse YearMonth
bysort IDlse: egen AgeBand_first_increase  = min(cond(id_age_increase==1 & total_age_increase==2, AgeBand, .))
bysort IDlse: egen AgeBand_second_increase = min(cond(id_age_increase==2 & total_age_increase==2, AgeBand, .))
label values AgeBand_first_increase  AgeBand
label values AgeBand_second_increase AgeBand

*!! s-3-2-4. update AgeBand
replace AgeBand = AgeBand_second_increase-1 if id_age_increase<2  & total_age_increase==2
replace AgeBand = AgeBand_first_increase    if id_age_increase==2 & total_age_increase==2

*!! s-3-2-5. test: only one AgeBand increase 
/* capture drop age_increase
generate age_increase = . 
replace  age_increase = 1 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]>AgeBand[_n-1]
replace  age_increase = 0 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]==AgeBand[_n-1]
replace  age_increase = 0 if IDlse[_n]!=IDlse[_n-1]
codebook age_increase //&? max=1, pass the test 
codebook AgeBand      //&? range: [1,6], pass the test */

keep  Tenure WL Year IDlse YearMonth occurrence count AgeBand
order Tenure WL Year IDlse YearMonth occurrence count AgeBand

rename AgeBand AgeBandUpdated

keep  IDlse YearMonth AgeBandUpdated
order IDlse YearMonth AgeBandUpdated

label variable AgeBandUpdated "Updated age band"

save "${TempData}/0102_01AgeBandUpdated.dta", replace 
