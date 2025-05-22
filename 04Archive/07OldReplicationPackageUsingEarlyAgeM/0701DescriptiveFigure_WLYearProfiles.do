/* 
This do file plots share of different WL across years, mean age of different WL across years, and mean tenure of different WL across years.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 

Results:
    "${Results}/Profile_ShareWL_Year.pdf"
    "${Results}/Profile_AgeWL_Year.pdf"
    "${Results}/Profile_TenureWL_Year.pdf"

RA: WWZ 
Time: 2024-12-06
*/

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep IDlse YearMonth WL Tenure AgeBand 

generate Year = year(dofm(YearMonth))

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct a continuous age
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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
*?? step 2. construct other variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate WLAgg = WL
replace  WLAgg = 5 if WL>4 & WL!=.

generate one = 1

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. collapse into WL-year level  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

collapse (mean) Tenure AgeContinuous (sum) counts=one, by(Year WLAgg)

sort Year WLAgg
bysort Year: egen total_counts = sum(counts)

forval i = 1/5{
	bys Year: egen ShareWL`i'  = mean(cond(WLAgg==`i', counts/total_counts, .))
	bys Year: egen TenureWL`i' = mean(cond(WLAgg==`i', Tenure, .))
	bys Year: egen AgeWL`i'    = mean(cond(WLAgg==`i', AgeContinuous, .))
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. ShareWL - year profile
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

twoway ///
    (connected ShareWL1 Year) ///
    (connected ShareWL2 Year) ///
    (connected ShareWL3 Year) ///
    (connected ShareWL4 Year) ///
    (connected ShareWL5 Year) ///
    , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1) position(3)) ///
    xscale(range(2011(1)2021)) xlabel(2011(1)2021,labsize(medsmall)) xtitle("Year", size(medlarge)) ///
    ytitle("Share", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) scheme(tab2)

graph export "${Results}/Profile_ShareWL_Year.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. AgeWL - year profile
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

twoway ///
    (connected AgeWL1 Year) ///
    (connected AgeWL2 Year) ///
    (connected AgeWL3 Year) ///
    (connected AgeWL4 Year) ///
    (connected AgeWL5 Year) ///
    , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1) position(3)) ///
    xscale(range(2011(1)2021)) xlabel(2011(1)2021,labsize(medsmall)) xtitle("Year", size(medlarge)) ///
    ytitle("Age", size(medlarge)) ylabel(30(5)60, grid gstyle(dot)) scheme(tab2)

graph export "${Results}/Profile_AgeWL_Year.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 6. TenureWL - year profile
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

twoway ///
    (connected TenureWL1 Year) ///
    (connected TenureWL2 Year) ///
    (connected TenureWL3 Year) ///
    (connected TenureWL4 Year) ///
    (connected TenureWL5 Year) ///
    , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1) position(3)) ///
    xscale(range(2011(1)2021)) xlabel(2011(1)2021,labsize(medsmall)) xtitle("Year", size(medlarge)) ///
    ytitle("Tenure", size(medlarge)) ylabel(0(5)30, grid gstyle(dot)) scheme(tab2)

graph export "${Results}/Profile_TenureWL_Year.pdf", replace as(pdf)
