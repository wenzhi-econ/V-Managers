/* 
Major changes of the file:
    This do file makes a modified version of Figure I(b).
    It creates a continuous version of the age variable. 
    Then it plots the distribution of (continuous) age and tenure at promotion (to WL2)
    
    The codes are copied from "0.New/0.NewVars.do".

Additional notes:
    I use the random sample of the whole dataset "${managersdta}/AllSnapshotMCulture.dta".
    todo To run on the whole sample, you need to uncomment Line 29, while comment out Line 28.

Input files:
    "${managersdta}/AllSnapshotMCultureMF.dta"

Output files:
    "$analysis/Results/0.New/ContAgeatWLPromo.png"
    "$analysis/Results/0.New/TenureatWLPromo.png"

RA: WWZ 
Time: 19/3/2024
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? variable: continuous age 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${managersdta}/Not Used/Marco/AllSnapshotMCultureMF.dta", clear
/* use "${managersdta}/AllSnapshotMCulture.dta", clear */

cap drop minage-YobB
gen minage = ///
	(AgeBand == 1) * 18 + ///
	(AgeBand == 2) * 30 + ///
	(AgeBand == 3) * 40 + ///
	(AgeBand == 4) * 50 + ///
	(AgeBand == 5) * 60 + ///
	(AgeBand == 6) * 70 + ///
	(AgeBand == 7) * 16
gen maxage = ///
	(AgeBand == 1) * 29 + ///
	(AgeBand == 2) * 39 + ///
	(AgeBand == 3) * 49 + ///
	(AgeBand == 4) * 59 + ///
	(AgeBand == 5) * 69 + ///
	(AgeBand == 6) * 79 + ///
	(AgeBand == 7) * 18
replace minage = . if AgeBand == 8
replace maxage = . if AgeBand == 8
gen minyob = Year - maxage
gen maxyob = Year - minage
bysort IDlse: egen MINyob = max(minyob)
bysort IDlse: egen MAXyob = min(maxyob)
gen Yob = (MINyob + MAXyob)/2
replace Yob = Yob - 0.5 if mod(MINyob + MAXyob, 2) == 1

generate age = Year - Yob 
label variable age "imputed age based on age band"
tabulate age 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? plot the distribution 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

preserve
    keep if WL == 2                          // keep employees at work level 2
    bysort IDlse: generate occurrence = _n   // for each employee, keep only the first observation (promotion to WL2)
    keep if occurrence == 1 
    tabulate age 
    twoway histogram age, width(1) title("Age at promotion to work-level 2") xtitle("Age")
    graph export "$analysis/Results/0.New/ContAgeatWLPromo.png", replace as(png)
    graph save "$analysis/Results/0.New/ContAgeatWLPromo.gph", replace
    twoway histogram Tenure, width(1) title("Tenure at promotion to work-level 2") xtitle("Tenure")
    graph export "$analysis/Results/0.New/TenureatWLPromo.png", replace as(png)
    graph save "$analysis/Results/0.New/TenureatWLPromo.gph", replace
restore 

