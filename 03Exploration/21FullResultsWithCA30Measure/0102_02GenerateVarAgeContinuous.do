/* 
This do file constructs a variable AgeContinuous, which is an imputed continuous version of AgeBand.

Input: 
    "${RawMNEData}/AllSnapshotWC.dta"
    "${TempData}/0102_01AgeBandUpdated.dta" <== created in 0102_01 do file 

Output:
    "${TempData}/0102_02AgeContinuous.dta"

Description of the output:
    It contains an (imputed) continuous version of AgeBand variable -- AgeContinuous.
        (1) For those employees whose AgeBandUpdated (an updated version of AgeBand variable to get rid of some relevant measurement errors) has crossed the threshold, their exact age can be identified from the increase in AgeBandUpdated. 
        (2) For those employees whose AgeBand does not experience changes in the dataset, their age is imputed based on their length of presence in the dataset. The imputation starts from the midpoint and extends at an equal speed to both ends of the band.

RA: WWZ 
Time: 2025-04-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. exact age can be identified from the change in AgeBand
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge AgeBandUpdated into the raw dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawMNEData}/AllSnapshotWC.dta", clear

keep  IDlse YearMonth AgeBand Tenure WL Year
order Tenure WL Year IDlse YearMonth AgeBand

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
order occurrence, after(YearMonth)

merge 1:1 IDlse YearMonth using "${TempData}/0102_01AgeBandUpdated.dta", keep(match master) nogenerate

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. identify those employees whose exact ages can be identified 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate age_change = . 
replace  age_change = 1 if IDlse[_n]==IDlse[_n-1] & AgeBandUpdated[_n]!=AgeBandUpdated[_n-1]
replace  age_change = 0 if IDlse[_n]==IDlse[_n-1] & AgeBandUpdated[_n]==AgeBandUpdated[_n-1]
replace  age_change = 0 if IDlse[_n]!=IDlse[_n-1]

sort IDlse YearMonth
bysort IDlse: egen q_exact_age = max(age_change)
label variable q_exact_age "=1, if the worker's age is exactly identified"

summarize q_exact_age if occurrence==1 
    //&? I can identify the exact age for 33.15367% employees 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. age for these exactly identifiable employees
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

gsort -q_exact_age IDlse YearMonth

*!! s-1-3-1. AgeBand_atchange
sort IDlse YearMonth
bysort IDlse: egen AgeBand_atchange = mean(cond(age_change==1, AgeBandUpdated, .))
label value AgeBand_atchange AgeBand

*!! s-1-3-2. date of birth: DOB
bysort IDlse: egen DOB_exact = mean(cond(age_change==1, YearMonth, .))
format DOB_exact %tm
replace DOB_exact = DOB_exact - 360 if AgeBand_atchange==2 // 360 = 30 * 12
replace DOB_exact = DOB_exact - 480 if AgeBand_atchange==3 // 480 = 40 * 12
replace DOB_exact = DOB_exact - 600 if AgeBand_atchange==4 // 600 = 50 * 12
replace DOB_exact = DOB_exact - 720 if AgeBand_atchange==5 // 720 = 60 * 12
replace DOB_exact = DOB_exact - 840 if AgeBand_atchange==6 // 840 = 70 * 12
label variable DOB_exact "date of birth, for those employees whose ages can be exactly identified"

generate AgeContinuous_exact = floor((YearMonth - DOB_exact) / 12)
label variable AgeContinuous_exact "continuous age, for those whose ages can be exactly identified"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. impute a continuous age for other employees
*??         (they have the same AgeBand value over their observation months)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. impute a continuous age for other workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate AgeBandUpdated_with18m = AgeBandUpdated
replace  AgeBandUpdated_with18m = 7 if AgeBand==7

generate minage = ///
	(AgeBandUpdated_with18m == 1) * 18 + ///
	(AgeBandUpdated_with18m == 2) * 30 + ///
	(AgeBandUpdated_with18m == 3) * 40 + ///
	(AgeBandUpdated_with18m == 4) * 50 + ///
	(AgeBandUpdated_with18m == 5) * 60 + ///
	(AgeBandUpdated_with18m == 6) * 70 + ///
	(AgeBandUpdated_with18m == 7) * 16 if q_exact_age==0
generate maxage = ///
	(AgeBandUpdated_with18m == 1) * 29 + ///
	(AgeBandUpdated_with18m == 2) * 39 + ///
	(AgeBandUpdated_with18m == 3) * 49 + ///
	(AgeBandUpdated_with18m == 4) * 59 + ///
	(AgeBandUpdated_with18m == 5) * 69 + ///
	(AgeBandUpdated_with18m == 6) * 79 + ///
	(AgeBandUpdated_with18m == 7) * 18 if q_exact_age==0

generate minyob = Year - maxage
generate maxyob = Year - minage
bysort IDlse: egen MINyob = max(minyob)
bysort IDlse: egen MAXyob = min(maxyob)
generate Yob = (MINyob + MAXyob)/2
replace Yob = Yob - 0.5 if mod(MINyob + MAXyob, 2) == 1

generate AgeContinuous_imputed = Year - Yob 
label variable AgeContinuous_imputed "imputed continuous age, for those whose ages cannot be exactly identified"

/* 
notes on the nature of the imputation procedures:
    the imputation is based on the length of presence for an individual employee in the dataset.
    suppose that for an employee whose AgeBand falls into [50, 59] throughout the dataset.
        (1) if he only has <12 months in the data, then his continuous age is imputed as 55.
        (2) if he has 36 months in the data, then obviously, then his continuous age at different points will be 54, 55, 56.
        (3) if he has 60 months in the data, then obviously, then his continuous age at different points will be 53, 54, 55, 56, 57.
    as in the example, the imputation procedure always starts with the midpoint in the AgeBand.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. final variable: AgeContinuous, combining step 1 and s-2-1
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate AgeContinuous = .
replace  AgeContinuous = AgeContinuous_exact   if q_exact_age==1
replace  AgeContinuous = AgeContinuous_imputed if q_exact_age==0
label variable AgeContinuous "Continuous age"

sort IDlse YearMonth
keep IDlse YearMonth AgeBand AgeBandUpdated AgeContinuous q_exact_age AgeContinuous_exact AgeContinuous_imputed

label variable AgeContinuous "Continuous age (with imputations)" 

save "${TempData}/0102_02AgeContinuous.dta", replace
