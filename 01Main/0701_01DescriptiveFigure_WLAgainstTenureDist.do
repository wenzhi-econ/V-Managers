/* 
This do file constructs the distribution of work level by different tenures.

RA: WWZ 
Time: 2024-12-09
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. the WL-Tenure profile
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

generate WLAgg = WL
replace  WLAgg = 5 if WL>4 & WL!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. calculate the profile
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& In 2019m12, for all workers having the same tenure, the share of them in different work levels

forval i=1(1)5{
    bysort Tenure : egen noT`i' = count(cond(YearMonth == tm(2019m12) & WLAgg==`i', IDlse, .))  	 
}
bysort Tenure: egen noTT = count(cond(YearMonth == tm(2019m12), IDlse, .)) 

generate Share1 = noT1/noTT
generate Share2 = (noT1 + noT2)/noTT
generate Share3 = (noT1 + noT2 + noT3)/noTT
generate Share4 = (noT1 + noT2 + noT3 + noT4+ noT5)/noTT

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. plotting
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! auxiliary variables 
egen tw = tag(Tenure)
replace tw = 0 if Tenure>30
generate Share0 = 0
generate upper = 1 
generate lower = 0

twoway ///
    (rarea Share0 Share1 Tenure if tw==1, sort) ///
    (rarea Share1 Share2 Tenure if tw==1, sort) ///
    (rarea Share2 Share3 Tenure if tw==1, sort) ///
    (rarea Share3 Share4 Tenure if  tw==1, sort) ///
    , legend(off) scheme(tab2) ///
    xlabel(0(1)30, axis(1)) xtitle("Tenure", size(medlarge) axis(1)) ///
    ylabel(0(.1)1) ytitle("Percent of population", size(medlarge)) ///
    text(0.4 5 "Work-level 1" 0.8 15 "Work-level 2" 0.94 20 "Work-level 3" 0.99 25 "Work-level 4+", size(medlarge))  

graph export "${Results}/WLTenure.pdf", replace as(pdf)