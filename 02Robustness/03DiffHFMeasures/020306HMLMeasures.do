/* 
This do file constructs two new measures of HF managers.

Input:
    "${TempData}/test_newdata_oldmeasure.dta"

Output:
    "${TempData}/temp_Mngr_HML.dta"
    "${TempData}/RELEVANT_Mngr_ID.dta"
    "${TempData}/test_HML_measures.dta"

RA: WWZ 
Time: 2024-10-11
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
*?? step 2. two critical ages: Age_atWL2Prom Age_WL2plus_atentry
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

generate temp_Age_WL2plus_atentry = AgeContinuous if q_WL2plus_atentry==1 & occurrence==1
sort IDlse YearMonth 
bysort IDlse: egen Age_WL2plus_atentry = min(temp_Age_WL2plus_atentry)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. 3-Type Measure 1: H1, M1, L1 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate H1 = . 
replace  H1 = 1 if q_witness_WL2Prom==1 & Age_atWL2Prom<=30 
replace  H1 = 0 if q_witness_WL2Prom==1 & Age_atWL2Prom>30
replace  H1 = 1 if q_WL2plus_atentry==1 & Age_WL2plus_atentry<=30 
replace  H1 = 0 if q_WL2plus_atentry==1 & Age_WL2plus_atentry>30

generate M1 = . 
replace  M1 = 1 if q_witness_WL2Prom==1 & (Age_atWL2Prom>30 & Age_atWL2Prom<=35)
replace  M1 = 0 if q_witness_WL2Prom==1 & (Age_atWL2Prom<=30 | Age_atWL2Prom>35)
replace  M1 = 1 if q_WL2plus_atentry==1 & (Age_WL2plus_atentry>30 & Age_WL2plus_atentry<=35)
replace  M1 = 0 if q_WL2plus_atentry==1 & (Age_WL2plus_atentry<=30 | Age_WL2plus_atentry>35)

generate L1 = . 
replace  L1 = 1 if q_witness_WL2Prom==1 & Age_atWL2Prom>35
replace  L1 = 0 if q_witness_WL2Prom==1 & Age_atWL2Prom<=35
replace  L1 = 1 if q_WL2plus_atentry==1 & Age_WL2plus_atentry>35
replace  L1 = 0 if q_WL2plus_atentry==1 & Age_WL2plus_atentry<=35

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. 3-Type Measure 2: H2, M2, L2 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate H2 = . 
replace  H2 = 1 if q_witness_WL2Prom==1 & Age_atWL2Prom<=30 
replace  H2 = 0 if q_witness_WL2Prom==1 & Age_atWL2Prom>30
replace  H2 = 1 if q_WL2plus_atentry==1 & Age_WL2plus_atentry<=30 
replace  H2 = 0 if q_WL2plus_atentry==1 & Age_WL2plus_atentry>30

generate M2 = . 
replace  M2 = 1 if q_witness_WL2Prom==1 & (Age_atWL2Prom>30 & Age_atWL2Prom<=36)
replace  M2 = 0 if q_witness_WL2Prom==1 & (Age_atWL2Prom<=30 | Age_atWL2Prom>36)
replace  M2 = 1 if q_WL2plus_atentry==1 & (Age_WL2plus_atentry>30 & Age_WL2plus_atentry<=36)
replace  M2 = 0 if q_WL2plus_atentry==1 & (Age_WL2plus_atentry<=30 | Age_WL2plus_atentry>36)

generate L2 = . 
replace  L2 = 1 if q_witness_WL2Prom==1 & Age_atWL2Prom>36
replace  L2 = 0 if q_witness_WL2Prom==1 & Age_atWL2Prom<=36
replace  L2 = 1 if q_WL2plus_atentry==1 & Age_WL2plus_atentry>36
replace  L2 = 0 if q_WL2plus_atentry==1 & Age_WL2plus_atentry<=36

rename IDlse IDlseMHR 
foreach var in q_witness_WL2Prom Age_atWL2Prom q_WL2plus_atentry Age_WL2plus_atentry H1 M1 L1 H2 M2 L2 {
    rename `var' `var'M
}

keep IDlseMHR YearMonth H1M M1M L1M H2M M2M L2M q_witness_WL2PromM Age_atWL2PromM q_WL2plus_atentryM Age_WL2plus_atentryM

order IDlseMHR YearMonth H1M M1M L1M H2M M2M L2M q_witness_WL2PromM Age_atWL2PromM q_WL2plus_atentryM Age_WL2plus_atentryM

save "${TempData}/temp_Mngr_HML.dta", replace 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. compare these two measures only in the sample of relevant managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-1. get a list of relevant managers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/test_newdata_oldmeasure.dta", clear 

keep if FT_Mngr_both_WL2 == 1
keep if inrange(FT_Rel_Time, -1, 0)

keep IDlseMHR

duplicates drop 

save "${TempData}/RELEVANT_Mngr_ID.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-2. compare results only for those managers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_Mngr_HML.dta", clear 

merge m:1 IDlseMHR using "${TempData}/RELEVANT_Mngr_ID.dta", keep(match) nogenerate 
    //&? keep only matched observations -- that is, keep only event-relevant managers


drop YearMonth 
duplicates drop 
    //&? a cross-section of relevant mangers 

save "${TempData}/test_HML_measures.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-3. are the measures legit?
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/test_HML_measures.dta", clear 

egen test1 = rowtotal(H1M M1M L1M)
egen test2 = rowtotal(H2M M2M L2M)

codebook test1 test2 // all 1
    //&? This means that all relevant managers can be assinged as a type under both measures.

sort IDlseMHR

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-4. share 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

graph bar (mean) H1M M1M L1M H2M M2M L2M, ///
    bar(1, color(navy)) bar(2, color(navy)) bar(3, color(navy)) bar(4, color(purple)) bar(5, color(purple)) bar(6, color(purple)) ///
    blabel(bar) ///
    legend(order(1 "30/35 Threshold: H-type" 2 "30/35 Threshold: M-type" 3 "30/35 Threshold: L-type" 4 "30/36 Threshold: H-type" 5 "30/36 Threshold: M-type" 6 "30/36 Threshold: L-type")) ///
    ytitle("Share among all relevant managers")


