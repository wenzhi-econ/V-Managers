********************************************************************************
* BALANCE TABLES 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth 

*keep if Year>2015 // to run faster 

********************************************************************************
* GEN VARS 
********************************************************************************

*bys IDlse StandardJob (YearMonth), sort: 

********************************************************************************
* create balance table 
********************************************************************************

* Defining Characteristics to work with
global chars Female WL Tenure AgeContinuous Func VPA Pay  ChangeSalaryGradeC TransferSJC TransferSubFuncC 

gen PrePeriodData = 0 
replace PrePeriodData = 1 if  F2_OutGroupIASameM ==1 | F3_OutGroupIASameM ==1 | F4_OutGroupIASameM ==1 | F5_OutGroupIASameM ==1 | F6_OutGroupIASameM ==1 | F7_OutGroupIASameM ==1 | F8_OutGroupIASameM ==1 | F9_OutGroupIASameM ==1 | F10_OutGroupIASameM ==1 | F11_OutGroupIASameM ==1 | F12_OutGroupIASameM ==1 | F13_OutGroupIASameM ==1 | F14_OutGroupIASameM ==1 | F15_OutGroupIASameM ==1 | F16_OutGroupIASameM ==1 | F17_OutGroupIASameM ==1 | F18_OutGroupIASameM ==1 | F19_OutGroupIASameM ==1 | F20_OutGroupIASameM ==1 | F21_OutGroupIASameM ==1 | F22_OutGroupIASameM ==1 | F23_OutGroupIASameM ==1 | F24_OutGroupIASameM ==1 
*| F2_ChangeM ==1 | F3_ChangeM ==1 | F4_ChangeM ==1 | F5_ChangeM ==1 | F6_ChangeM ==1 | F7_ChangeM ==1 | F8_ChangeM ==1 | F9_ChangeM ==1 | F10_ChangeM ==1 | F11_ChangeM ==1 | F12_ChangeM ==1 | F13_ChangeM ==1 | F14_ChangeM ==1 | F15_ChangeM ==1 | F16_ChangeM ==1 | F17_ChangeM ==1 | F18_ChangeM ==1 | F19_ChangeM ==1 | F20_ChangeM ==1 | F21_ChangeM ==1 | F22_ChangeM ==1 | F23_ChangeM ==1 | F24_ChangeM ==1

bys IDlse: egen Sample = max(OutGroupIASameM)

merge m:1 IDlse using "$managersdta/matchingList.dta" 
gen MatchSample = _merge ==3
drop _merge 

balancetable  (mean if OutGroupIASameM ==0 & PrePeriodData == 1 & insample==1) (diff Sample if PrePeriodData == 1  & insample==1) (diff Sample if PrePeriodData == 1 & MatchSample==1  & insample==1)  $chars using "$Results/2.Balance/OutGroupIASameM.tex" [pweight=ipw], ///
replace  vce(cluster IDlse )   ctitles("Domestic Manager" "Diff IA Manager" "Diff IA Manager Matched" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." "Only keeping the 8 quarters prior to an event." ///
"The difference in means is computed using standard errors clustered at the individual level." "\end{tablenotes}")
* cov(i.Stratification) varla




