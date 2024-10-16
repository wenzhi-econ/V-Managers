/* 
This do file constructs two new measures of HF managers.

Input:
    "${RawMNEData}/AllSnapshotWC.dta"

Output:
    ${TempData}/temp_Mngr_HF2_HF3.dta" ==> used in 050202.do file 
    "${Results}/Distribution_of_Age_atWL2PromM.png"
    "${Results}/Distribution_of_Tenure_atWL2PromM.png"

RA: WWZ 
Time: 2024-10-08
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct a continuous age
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-0. construct a simplified dataset with only necessary variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawMNEData}/AllSnapshotWC.dta", clear

keep  IDlse YearMonth AgeBand Tenure WL Year
order Tenure WL Year IDlse YearMonth AgeBand

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. those whose exact age can be identified
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&? Suppose that we can observe a worker whose AgeBand has changed in our dataset, then we can exactly identify his year(month) of birth.

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
order occurrence, after(YearMonth)
/* summarize occurrence, detail  */
    // max: 132
    // It is impossible to witness two changes in AgeBand variable for a given individual.

/* label list AgeBand */
/* AgeBand:
           1 Age 18 - 29
           2 Age 30 - 39
           3 Age 40 - 49
           4 Age 50 - 59
           5 Age 60 - 69
           6 Age 70 and over
           7 Age Under 18
           8 Age Unknown */
replace AgeBand = . if AgeBand==8

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-1. some workers have more than one change in AgeBand, which is impossible
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
generate age_change = . 
replace  age_change = 1 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]!=AgeBand[_n-1]
replace  age_change = 0 if IDlse[_n]==IDlse[_n-1] & AgeBand[_n]==AgeBand[_n-1]
replace  age_change = 0 if IDlse[_n]!=IDlse[_n-1]

bysort IDlse: egen num_age_change = total(age_change)
/* tabulate num_age_change, missing  */
/* 
num_age_cha |
        nge |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |  3,676,485       36.46       36.46
          1 |  5,980,401       59.31       95.77
          2 |     35,741        0.35       96.12
          3 |    389,785        3.87       99.99
          4 |        849        0.01      100.00
          5 |        377        0.00      100.00
------------+-----------------------------------
      Total | 10,083,638      100
*/

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-2. keep only the last change and correct for AgeBand variable
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*&& For those worker with more than 1 AgeBand change, 
*&& I will keep only the last change as the genuine age change, 
*&& and use this to identify their exact age. 

sort IDlse YearMonth
generate cumsum_age_change = age_change
bysort IDlse: replace cumsum_age_change = cumsum_age_change[_n] + cumsum_age_change[_n-1] if _n > 1

sort IDlse YearMonth 
bysort IDlse: egen YM_last_age_change = min(cond(cumsum_age_change==num_age_change & num_age_change>1, YearMonth, .))
format YM_last_age_change %tm 
label variable YM_last_age_change "For those who have > 1 change in AgeBand, date at the last AgeBand change"

generate temp_AgeBand_afterchange = AgeBand if YM_last_age_change==YearMonth 
sort IDlse YearMonth 
bysort IDlse: egen AgeBand_afterchange = mean(temp_AgeBand_afterchange)

generate AgeBand_Corrected = AgeBand 
replace  AgeBand_Corrected = AgeBand_afterchange - 1 if YearMonth<YM_last_age_change & YM_last_age_change!=.

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-3. Whose age can be identified?
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
generate age_change_corrected = . 
replace  age_change_corrected = 1 if IDlse[_n]==IDlse[_n-1] & AgeBand_Corrected[_n]!=AgeBand_Corrected[_n-1]
replace  age_change_corrected = 0 if IDlse[_n]==IDlse[_n-1] & AgeBand_Corrected[_n]==AgeBand_Corrected[_n-1]
replace  age_change_corrected = 0 if IDlse[_n]!=IDlse[_n-1]

sort IDlse YearMonth
bysort IDlse: egen q_exact_age = max(age_change_corrected)
label variable q_exact_age "=1, if the worker's age is exactly identified"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-3. date of birth for these workers
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate temp_AgeBand_atchange = AgeBand_Corrected if age_change_corrected==1
sort IDlse YearMonth
bysort IDlse: egen AgeBand_atchange = mean(temp_AgeBand_atchange)
label variable AgeBand_atchange "AgeBand at the last change in AgeBand"
label value AgeBand_atchange AgeBand

generate temp_DOB = YearMonth if age_change_corrected==1
sort IDlse YearMonth
bysort IDlse: egen DOB = mean(temp_DOB)
format DOB %tm
label variable DOB "date of birth in %tm"

replace DOB = DOB - 216 if AgeBand_atchange==1 // 216 = 18 * 12 
replace DOB = DOB - 360 if AgeBand_atchange==2 // 360 = 30 * 12
replace DOB = DOB - 480 if AgeBand_atchange==3 // 480 = 40 * 12
replace DOB = DOB - 600 if AgeBand_atchange==4 // 600 = 50 * 12
replace DOB = DOB - 720 if AgeBand_atchange==5 // 720 = 60 * 12
replace DOB = DOB - 840 if AgeBand_atchange==6 // 840 = 70 * 12

generate AgeContinuous = floor((YearMonth - DOB) / 12)

label variable AgeContinuous "Age (continuous, with imputed values)"

drop age_change num_age_change cumsum_age_change temp_AgeBand_afterchange AgeBand_afterchange AgeBand_Corrected age_change_corrected temp_AgeBand_atchange temp_DOB

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. impute a continuous age for other workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate minage = ///
	(AgeBand == 1) * 18 + ///
	(AgeBand == 2) * 30 + ///
	(AgeBand == 3) * 40 + ///
	(AgeBand == 4) * 50 + ///
	(AgeBand == 5) * 60 + ///
	(AgeBand == 6) * 70 + ///
	(AgeBand == 7) * 16
generate maxage = ///
	(AgeBand == 1) * 29 + ///
	(AgeBand == 2) * 39 + ///
	(AgeBand == 3) * 49 + ///
	(AgeBand == 4) * 59 + ///
	(AgeBand == 5) * 69 + ///
	(AgeBand == 6) * 79 + ///
	(AgeBand == 7) * 18
replace minage = . if AgeBand == 8
replace maxage = . if AgeBand == 8
generate minyob = Year - maxage
generate maxyob = Year - minage
bysort IDlse: egen MINyob = max(minyob)
bysort IDlse: egen MAXyob = min(maxyob)
generate Yob = (MINyob + MAXyob)/2
replace Yob = Yob - 0.5 if mod(MINyob + MAXyob, 2) == 1

generate AgeImputed = Year - Yob 
label variable AgeImputed "imputed age based on age band"

replace AgeContinuous = AgeImputed if AgeContinuous==. & AgeImputed!=.

drop minage maxage minyob maxyob MINyob MAXyob Yob

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. Construct a HF measure based on age at promotion to WL2
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. whose promotion to WL2 can be observed
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth 

generate temp_q_witness_WL2Prom = . 
replace  temp_q_witness_WL2Prom = 1 if IDlse[_n]==IDlse[_n-1] & WL[_n]==2 & WL[_n-1]==1
bysort IDlse: egen q_witness_WL2Prom = max(temp_q_witness_WL2Prom)

order q_witness_WL2Prom, after(WL)

tabulate q_witness_WL2Prom if occurrence==1, missing 
/* 
q_witness_W |
     L2Prom |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     13,246        5.91        5.91
          . |    210,871       94.09      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/

generate temp_Age_atWL2Prom = AgeContinuous if temp_q_witness_WL2Prom == 1 
sort IDlse YearMonth 
bysort IDlse: egen Age_atWL2Prom = max(temp_Age_atWL2Prom)

tabulate Age_atWL2Prom q_witness_WL2Prom if occurrence==1, missing 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. whose work level is >= 2 at entry 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate temp_q_WL2plus_atentry = (WL >= 2) if occurrence==1

sort IDlse YearMonth 
bysort IDlse: egen q_WL2plus_atentry = max(temp_q_WL2plus_atentry)
replace q_WL2plus_atentry = . if q_WL2plus_atentry == 0

tabulate q_WL2plus_atentry if occurrence==1, missing 
/* 
q_WL2plus_a |
     tentry |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    199,900       89.19       89.19
          1 |     24,217       10.81      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/
/* tabulate AgeContinuous Tenure if occurrence==1 & q_WL2plus_atentry==1, missing  */

generate temp_age_WL2plus_atentry = AgeContinuous if q_WL2plus_atentry==1 & occurrence==1
sort IDlse YearMonth 
bysort IDlse: egen age_WL2plus_atentry = min(temp_age_WL2plus_atentry)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. construct the HF measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate HF2 = . 
replace  HF2 = 1 if q_witness_WL2Prom==1 & Age_atWL2Prom<=30 
replace  HF2 = 0 if q_witness_WL2Prom==1 & Age_atWL2Prom>30 
replace  HF2 = 1 if q_WL2plus_atentry==1 & age_WL2plus_atentry<=33 
replace  HF2 = 0 if q_WL2plus_atentry==1 & age_WL2plus_atentry>33 

order IDlse YearMonth q_witness_WL2Prom Age_atWL2Prom q_WL2plus_atentry age_WL2plus_atentry HF2

tabulate HF2 if occurrence==1, missing
/* 
        HF2 |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     25,233       11.26       11.26
          1 |     12,072        5.39       16.65
          . |    186,812       83.35      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. Construct a HF measure based on tenure at promotion to WL2
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

order IDlse YearMonth Tenure q_witness_WL2Prom Age_atWL2Prom q_WL2plus_atentry age_WL2plus_atentry HF2

sort IDlse YearMonth 

bysort IDlse: egen YM_atpromotion = min(cond((q_witness_WL2Prom==1) & (WL==2), YearMonth, .))
format YM_atpromotion %tm 
order YM_atpromotion, after(YearMonth)

sort IDlse YearMonth 
bysort IDlse: egen Tenure_atWL2Prom = mean(cond(YearMonth==YM_atpromotion, Tenure, .))
order Tenure_atWL2Prom, after(YM_atpromotion)

summarize Tenure_atWL2Prom if occurrence==1 & q_witness_WL2Prom==1, d 
/* 
                      Tenure_atWL2Prom
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            1              0
10%            1              0       Obs              13,246
25%            2              0       Sum of wgt.      13,246

50%            4                      Mean           5.286275
                        Largest       Std. dev.      4.684008
75%            7             37
90%           11             38       Variance       21.93994
95%           15             38       Skewness       2.242781
99%           24             48       Kurtosis       10.13333

*/

egen Tenure_cutoff = xtile(Tenure_atWL2Prom) if occurrence==1 & q_witness_WL2Prom==1, n(3) 
tabulate Tenure_cutoff Tenure_atWL2Prom, m 
    //&? Managers with tenure at WL2 promotion is 0, 1, 2, 3 are defined as HF3 managers

generate temp_HF3 = (Tenure_cutoff==1) if occurrence==1 & q_witness_WL2Prom==1
sort IDlse YearMonth 
bysort IDlse: egen HF3 = mean(temp_HF3)


keep  IDlse q_witness_WL2Prom q_WL2plus_atentry Age_atWL2Prom age_WL2plus_atentry HF2 HF3 Tenure_atWL2Prom
order IDlse HF2 HF3 q_witness_WL2Prom Age_atWL2Prom Tenure_atWL2Prom q_WL2plus_atentry age_WL2plus_atentry

label variable q_witness_WL2Prom "=1, if we can observe the worker's promotion from WL1 to WL2"
label variable Age_atWL2Prom "age when the worker is promoted from WL1 to WL2"
label variable q_WL2plus_atentry "=1, if the worker's first observable WL in data is >= 2"
label variable age_WL2plus_atentry "age when worker is first observed in data"
label variable Tenure_atWL2Prom  "Tenure when the worker is promoted from WL1 to WL2"

label variable HF2 "HF managers based on Age_atWL2Prom and age_WL2plus_atentry"
label variable HF3 "HF managers based on tenure for workers with q_witness_WL2Prom==1"

duplicates drop 

rename IDlse IDlseMHR 

foreach var in q_witness_WL2Prom q_WL2plus_atentry Age_atWL2Prom age_WL2plus_atentry Tenure_atWL2Prom HF2 HF3 {
    rename `var' `var'M 
}

save "${TempData}/temp_Mngr_HF2_HF3.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. summary on the two measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

histogram Age_atWL2PromM if q_witness_WL2PromM==1, width(1) xlabel(20(10)60) fraction 
    graph export "${Results}/Distribution_of_Age_atWL2PromM.png", replace as(png)

histogram Tenure_atWL2PromM if q_witness_WL2PromM==1, width(1) xlabel(0(10)50) fraction 
    graph export "${Results}/Distribution_of_Tenure_atWL2PromM.png", replace as(png)
