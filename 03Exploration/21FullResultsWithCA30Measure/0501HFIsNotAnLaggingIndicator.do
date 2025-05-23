/* 
This do file investigates the correlation between factory-level productivity against share of HF managers.

Input:
    "${TempData}/FinalFullSample.dta"               <== created in 0101_01 do file 
    "${RawMNEData}/OfficeSize.dta"                  <== raw data
    "${RawMNEData}/TonsperFTEconservative.dta"      <== raw data
    "${RawMNEData}/CPTwideOld.dta"                  <== raw data

Result:
    "${Results}/004ResultsBasedOnCA30/CA30_FactoryLevelProdAgainstLaggedHFShares.tex"

RA: WWZ 
Time: 2025-04-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain the final dataset used for analysis 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

*-? s-1-1. for each office-year cell, obtain the total number of workers 
merge m:1 OfficeCode YearMonth using "${RawMNEData}/OfficeSize.dta", keepusing(TotWorkers TotWorkersBC TotWorkersWC)
    keep if _merge==3 
    drop _merge 

*-? s-1-2. for each office-year cell, obtain the productivity information 
merge m:1 OfficeCode Year using "${RawMNEData}/TonsperFTEconservative.dta", keepusing(PC HC FR TotBigC TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)
    drop if _merge==2
    drop _merge 

*-? s-1-3. for each office-year cell, obtain the cost information 
merge m:1 OfficeCode Year using "${RawMNEData}/CPTwideOld.dta", keepusing(CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC)
    drop if _merge==2
    drop _merge 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. generate relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

drop IDlseMHR
rename IDlse IDlseMHR
merge 1:1 IDlseMHR YearMonth using "${TempData}/0102_03HFMeasure.dta", keep(match master) nogenerate 
drop IDMngr_Pre IDMngr_Post
rename IDlseMHR IDlse 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. share of high-flyers among WL2 workers in each office-year cell
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate managers    = (WL==2) if WL!=.
generate hf_managers = (WL==2 & CA30==1) if WL!=.

sort   OfficeCode Year 
bysort OfficeCode Year: egen no_managers    = total(managers)
bysort OfficeCode Year: egen no_hf_managers = total(hf_managers)

order OfficeCode Year IDlse WL managers CA30 hf_managers no_managers no_hf_managers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. collapse at office-year level 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

collapse (mean) TotWorkers TotWorkersBC TotWorkersWC PC HC FR TotBigC TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC managers no_managers no_hf_managers, by(OfficeCode Year ISOCode)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. productivity-related variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate lp = log(TonsperFTEMean) 
egen CPT = rowmean(CPTFR CPTHC CPTPC)
generate lc = log(CPT)
label variable lp "Output per worker in logs"
label variable lc "Costs per output in logs"

sort OfficeCode Year 
bysort OfficeCode: generate lp_l1 = lp[_n-1] if Year[_n-1]==Year-1
bysort OfficeCode: generate lp_l2 = lp[_n-2] if Year[_n-2]==Year-2
bysort OfficeCode: generate lc_l1 = lc[_n-1] if Year[_n-1]==Year-1
bysort OfficeCode: generate lc_l2 = lc[_n-2] if Year[_n-2]==Year-2

order lp_l1 lp_l2, after(lp)
order lc_l1 lc_l2, after(lc)
label variable lp_l1 "Lagged (-1 year) output per worker in logs"
label variable lp_l2 "Lagged (-2 years) output per worker in logs"
label variable lc_l1 "Lagged (-1 year) costs per output in logs"
label variable lc_l2 "Lagged (-2 years) costs per output in logs"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. manager-related variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate share_hf_managers = no_hf_managers/no_managers

rename managers Mshare 
label variable Mshare "Share of managers"
label variable TotWorkersWC "Number of white collar workers"
label variable TotWorkersBC "Number of blue collar workers"
label variable share_hf_managers "Share of high-flyers among all managers"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. productivity outcomes  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. cost outcomes  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. produce the output table
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

esttab lp_control lp_l1_control lp_l2_control lc_control lc_l1_control lc_l2_control ///
    using "${Results}/004ResultsBasedOnCA30/CA30_FactoryLevelProdAgainstLaggedHFShares.tex" ///
    , replace style(tex) fragment nocons label nofloat nobaselevels nomtitles ///
    collabels(, none) keep(share_hf_managers) ///
    stats(mean r2 N, labels("Mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0f)) /// 
    prehead("\begin{tabular}{lcccccc}" "\toprule" "\toprule" "& \multicolumn{3}{c}{Output per worker in logs} & \multicolumn{3}{c}{Costs per output in logs} \\" "\addlinespace[10pt] \cmidrule(lr){2-4} \cmidrule(lr){5-7} \\" "& \multicolumn{1}{c}{\shortstack{Current \\ Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -1 Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -2 Year}} & \multicolumn{1}{c}{\shortstack{Current \\ Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -1 Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -2 Year}} \\ ") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is an office-year. Standard errors clustered at the office level. Control variables include country FE, year FE, and office size. In Columns (1)-(3), the outcome variables are current-year, and lagged (-1 and -2 year) output per worker in logs. In Columns (4)-(6), the outcome variables are current-year, and lagged (-1 and -2 year) costs per output in logs." "\end{tablenotes}")