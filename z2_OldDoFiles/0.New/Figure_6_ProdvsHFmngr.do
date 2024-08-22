/* 
Major changes of the file:
    This do file makes a modified version of Figure VI (titled as "Factory productivity and workers' past lateral moves").
    Instead of investigating how workers' lateral move affect factory productivity, I explore how the share of high-flyer managers affect factory productivity.
    Some codes are copied from "3.1.Productivity.do" file.

TODO Notes: To run on the whole sample, uncomment Line 28, while commenting out Line 27.

Input files:
    "${managersdta}/AllSnapshotMCulture.dta"
    "${managersdta}/OfficeSize.dta"
    "${managersdta}/TonsperFTEconservative.dta"
    "${managersdta}/CPTwideOld.dta"

Output: None.

RA: WWZ 
Time: 20/3/2024
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1: obtain the final dataset used for analysis 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-- main dataset 

*use "${managersdta}/AllSnapshotMCultureMF.dta", clear
 use "${managersdta}/AllSnapshotMCulture.dta", clear 

*-- for each office-year cell, obtain the total number of workers 
merge m:1 OfficeCode YearMonth using "${managersdta}/OfficeSize.dta", keepusing(TotWorkers TotWorkersBC TotWorkersWC)
keep if _merge ==3 
drop _merge 

*-- for each office-year cell, obtain the productivity information 
merge m:1 OfficeCode Year using "${managersdta}/TonsperFTEconservative.dta", keepusing(PC HC FR TotBigC TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)
*keep if _merge ==3 
drop _merge 

*-- for each office-year cell, obtain the cost information 
merge m:1 OfficeCode Year using "${managersdta}/CPTwideOld.dta", keepusing(CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC)
*keep if _merge ==3 
drop _merge 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2: generate relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-1: share of high-flyer managers in each office-year cell
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

sort OfficeCode Year 
* identify managers and high-flyer managers 
generate managers = (WL>=2) if WL!=.
generate hf_managers = (WL>=2 & EarlyAgeM==1)

* the number of manager-month and high-flyer manager-month observations in each office-year cell
bysort OfficeCode Year: egen no_managers = total(managers)
bysort OfficeCode Year: egen no_hf_managers = total(hf_managers)

order OfficeCode Year IDlse WL managers EarlyAgeM hf_managers no_managers no_hf_managers

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-2: collapse at office-year level 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

collapse (mean) TotWorkers TotWorkersBC TotWorkersWC PC HC FR TotBigC TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC managers no_managers no_hf_managers, by(OfficeCode Year ISOCode)

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-3: productivity-related variables  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

generate lp = log(TonsperFTEMean) 
egen CPT = rowmean(CPTFR CPTHC CPTPC)
generate lc = log(CPT)
label variable lp "Output per worker in logs"
label variable lc "Costs per output in logs"

sort OfficeCode Year 
bysort OfficeCode: generate lp_l1 = lp[_n-1]
bysort OfficeCode: generate lp_l2 = lp[_n-2]
bysort OfficeCode: generate lc_l1 = lc[_n-1]
bysort OfficeCode: generate lc_l2 = lc[_n-2]

order lp_l1 lp_l2, after(lp)
order lc_l1 lc_l2, after(lc)
label variable lp_l1 "Lagged (-1 year) output per worker in logs"
label variable lp_l2 "Lagged (-2 years) output per worker in logs"
label variable lc_l1 "Lagged (-1 year) costs per output in logs"
label variable lc_l2 "Lagged (-2 years) costs per output in logs"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-4: manager-related variables 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

generate share_hf_managers = no_hf_managers/no_managers

rename managers Mshare 
label variable Mshare "Share of managers"
label variable TotWorkersWC "Number of white collar workers"
label variable TotWorkersBC "Number of blue collar workers"
label variable share_hf_managers "Share of high-fliers among all managers"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* 
The following two regressions are about one minor typo in the original codes. 
As the variables are all at office-year level, if you cluster at office-year level, then essentially it is heteroskedasticity-robust standard errors.
Note that in the original codes, the number of clusters equals to the number of observations. 
*/

egen OfficeYear = group(OfficeCode Year)

reghdfe lp share_hf_managers TotWorkersBC TotWorkersWC, absorb(Year ISOCode) vce(robust)
reghdfe lp share_hf_managers TotWorkersBC TotWorkersWC, absorb(Year ISOCode) cluster(OfficeYear)

/* main regressions */
capture eststo clear 

/* reghdfe lp share_hf_managers, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lp_nocontrol 
reghdfe lp_l1 share_hf_managers, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lp_l1_nocontrol 
reghdfe lp_l2 share_hf_managers, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lp_l2_nocontrol  */

reghdfe lp share_hf_managers TotWorkersBC TotWorkersWC i.TotBigC, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lp_control 
    summarize lp, detail
    local mean = r(mean)
    estadd scalar mean = `mean'
reghdfe lp_l1 share_hf_managers TotWorkersBC TotWorkersWC i.TotBigC, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lp_l1_control 
    summarize lp_l1, detail
    local mean = r(mean)
    estadd scalar mean = `mean'
reghdfe lp_l2 share_hf_managers TotWorkersBC TotWorkersWC i.TotBigC, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lp_l2_control 
    summarize lp_l2, detail
    local mean = r(mean)
    estadd scalar mean = `mean'



/* reghdfe lc share_hf_managers, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lc_nocontrol 
reghdfe lc_l1 share_hf_managers, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lc_l1_nocontrol 
reghdfe lc_l2 share_hf_managers, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lc_l2_nocontrol  */

reghdfe lc share_hf_managers TotWorkersBC TotWorkersWC i.TotBigC, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lc_control 
    summarize lc, detail
    local mean = r(mean)
    estadd scalar mean = `mean'
reghdfe lc_l1 share_hf_managers TotWorkersBC TotWorkersWC i.TotBigC, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lc_l1_control 
    summarize lc_l1, detail
    local mean = r(mean)
    estadd scalar mean = `mean'
reghdfe lc_l2 share_hf_managers TotWorkersBC TotWorkersWC i.TotBigC, absorb(Year ISOCode) cluster(OfficeCode)
    eststo lc_l2_control 
    summarize lc_l2, detail
    local mean = r(mean)
    estadd scalar mean = `mean'


esttab lp_control lp_l1_control lp_l2_control lc_control lc_l1_control lc_l2_control, keep(share_hf_managers)   star(* 0.10 ** 0.05 *** 0.01)
	
esttab lp_control lp_l1_control lp_l2_control lc_control lc_l1_control lc_l2_control ///
    using "${analysis}/Results/0.New/ProdvsHFmngr.tex" ///
    , replace style(tex) fragment nocons label nofloat nobaselevels nomtitles ///
    collabels(, none) keep(share_hf_managers) ///
    stats(mean N r2, labels("Mean" "N" "R-squared") fmt(%9.3f %9.0f %9.3f)) /// 
    prehead("\begin{tabular}{lcccccc}" "\toprule" "\toprule" "& \multicolumn{3}{c}{Output per worker in logs} & \multicolumn{3}{c}{Costs per output in logs} \\" "\addlinespace[10pt] \cmidrule(lr){2-4} \cmidrule(lr){5-7} \\" "& \multicolumn{1}{c}{\shortstack{Current \\ Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -1 Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -2 Year}} & \multicolumn{1}{c}{\shortstack{Current \\ Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -1 Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -2 Year}} \\ ") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is an office-year. Standard errors clustered at the office level. FEs include: product category, country and year FE. The office size (number of white- and blue-collar workers) is also controlled. In Columns (1)-(3), the outcome variables are current-year, and lagged (-1 and -2 year) output per worker in logs. In Columns (4)-(6), the outcome variables are current-year, and lagged (-1 and -2 year) costs per output in logs." "\end{tablenotes}")






