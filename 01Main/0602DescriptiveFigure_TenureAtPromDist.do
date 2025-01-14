/* 
This do file constructs the distribution of age at promotion (to WL2).

RA: WWZ 
Time: 2024-12-09
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. dataset for the age-at-promotion profile
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. two lists of managers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! a complete list of managers
use "${TempData}/04MainOutcomesInEventStudies.dta", clear
keep IDlseMHR
duplicates drop 
save "${TempData}/temp_FullMngrList.dta", replace

*!! a list of pre- and post-event managers
use "${TempData}/04MainOutcomesInEventStudies.dta", clear
keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep a panel of event workers 
keep if inrange(FT_Rel_Time, -1, 0)
    //&? keep periods -1 and 0 
keep IDlseMHR
duplicates drop 
save "${TempData}/temp_EventMngrList.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. keep only those WL2 managers in the list 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

*!! WL2 restriction
generate WL2 = (WL==2) if WL!=.
sort IDlse YearMonth
bysort IDlse: egen Ever_WL2 = max(WL2)
keep if Ever_WL2==1
    //&? First, keep a panel of employees who have ever been WL2 (full history).

*!! manager identity restriction
drop IDlseMHR
generate long IDlseMHR=IDlse
merge m:1 IDlseMHR using "${TempData}/temp_FullMngrList.dta"
keep if _merge==3 
    //&? Second, keep only those WL2 employees who have ever been managers.
drop _merge

*!! event manager identity 
merge m:1 IDlseMHR using "${TempData}/temp_EventMngrList.dta"
generate q_eventmngr = (_merge==3)
    //&? Third, get a variable indicating whether the manager also appears in the event study.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. whose promotion can be observed 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate temp_q_witness_WL2Prom = . 
replace  temp_q_witness_WL2Prom = 1 if IDlse[_n]==IDlse[_n-1] & WL[_n]==2 & WL[_n-1]==1
bysort IDlse: egen q_witness_WL2Prom = max(temp_q_witness_WL2Prom)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. minimum age at WL2 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen minAge = min(cond(WL==2, AgeBand, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. keep a cross section of workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
bysort IDlse: egen min_occurrence = min(cond(WL==2, occurrence, .))
keep if occurrence==min_occurrence
    //&? keep a cross section of workers (at the month when they are first observed as WL2)
codebook IDlse
    //&? 26,417 different managers 
codebook IDlse if q_eventmngr==1
    //&? 14,664 different managers 

keep  IDlse q_eventmngr q_witness_WL2Prom AgeBand minAge WL Tenure
order IDlse q_eventmngr q_witness_WL2Prom AgeBand minAge WL Tenure

save "${TempData}/temp_AgeAtPromProfile.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. generate age-at-promotion profile
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. tenure restriction
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_AgeAtPromProfile.dta", clear 

keep if Tenure<10
    //impt: tenure restriction
    //&? 19,865 managers 

generate one = 1 
egen total_counts = total(one)
bysort minAge: egen size = total(one)
replace size = size/total_counts
separate size, by(minAge==1)

graph ///
    bar size0 size1 if minAge<5 ///
    , over(minAge) ///
    bar(1, bfcolor("237 68 74")) ///
    bar(2, bfcolor("145 179 215")) ///
    nofill legend(off) ylabel(0(0.1)0.6) ///
    title("Age at promotion to work-level 2")    

graph export "${Results}/AgeWL2FT_TenureRestriction.pdf", replace as(pdf)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. WL2 promotion restriction
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_AgeAtPromProfile.dta", clear 

keep if q_witness_WL2Prom==1
    //impt: Only keep managers whose promotion to WL2 can be observed.
    //&? 10,910 managers 

generate one = 1 
egen total_counts = total(one)
bysort minAge: egen size = total(one)
replace size = size/total_counts
separate size, by(minAge==1)

graph ///
    bar size0 size1 if minAge<5 ///
    , over(minAge) ///
    bar(1, bfcolor("237 68 74")) ///
    bar(2, bfcolor("145 179 215")) ///
    nofill legend(off) ylabel(0(0.1)0.6) ///
    title("Age at promotion to work-level 2")    

graph export "${Results}/AgeWL2FT_WitnessRestriction.pdf", replace as(pdf)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. tenure restriction among event managers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_AgeAtPromProfile.dta", clear 

keep if Tenure<10
    //impt: tenure restriction
keep if q_eventmngr==1
    //impt: event manager restriction
    //&? 10,609 managers

generate one = 1 
egen total_counts = total(one)
bysort minAge: egen size = total(one)
replace size = size/total_counts
separate size, by(minAge==1)

graph ///
    bar size0 size1 if minAge<5 ///
    , over(minAge) ///
    bar(1, bfcolor("237 68 74")) ///
    bar(2, bfcolor("145 179 215")) ///
    nofill legend(off) ylabel(0(0.1)0.6) ///
    title("Age at promotion to work-level 2")    

graph export "${Results}/AgeWL2FT_TenureRestriction_EventMngrs.pdf", replace as(pdf)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. WL2 promotion restriction among event managers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_AgeAtPromProfile.dta", clear 

keep if q_witness_WL2Prom==1
    //impt: Only keep managers whose promotion to WL2 can be observed.
keep if q_eventmngr==1
    //impt: event manager restriction
    //&? 5,329 managers

generate one = 1 
egen total_counts = total(one)
bysort minAge: egen size = total(one)
replace size = size/total_counts
separate size, by(minAge==1)

graph ///
    bar size0 size1 if minAge<5 ///
    , over(minAge) ///
    bar(1, bfcolor("237 68 74")) ///
    bar(2, bfcolor("145 179 215")) ///
    nofill legend(off) ylabel(0(0.1)0.6) ///
    title("Age at promotion to work-level 2")    

graph export "${Results}/AgeWL2FT_WitnessRestriction_EventMngrs.pdf", replace as(pdf)