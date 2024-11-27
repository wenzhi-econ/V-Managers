/* 
This do file investigates the correlation between factory-level productivity against share of HF managers.

Input files:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== created in 0104 do file 
    "${FinalData}/OfficeSize.dta" <== not produced by me, taken as raw data
    "${FinalData}/TonsperFTEconservative.dta" <== not produced by me, taken as raw data
    "${FinalData}/CPTwideOld.dta" <== not produced by me, taken as raw data

Output: None.

RA: WWZ 
Time: 2024-11-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain the final dataset used for analysis 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

*-? s-1-1. for each office-year cell, obtain the total number of workers 
merge m:1 OfficeCode YearMonth using "${FinalData}/OfficeSize.dta", keepusing(TotWorkers TotWorkersBC TotWorkersWC)
    keep if _merge==3 
    drop _merge 

*-? s-1-2. for each office-year cell, obtain the productivity information 
merge m:1 OfficeCode Year using "${FinalData}/TonsperFTEconservative.dta", keepusing(PC HC FR TotBigC TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)
    drop if _merge==2
    drop _merge 

*-? s-1-3. for each office-year cell, obtain the cost information 
merge m:1 OfficeCode Year using "${FinalData}/CPTwideOld.dta", keepusing(CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC)
    drop if _merge==2
    drop _merge 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. generate relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 
rename (IDlseMHR EarlyAgeM) (IDlse EarlyAge)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. share of high-flyer managers in each office-year cell
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort OfficeCode Year 

generate managers = (WL>=2) if WL!=.
generate hf_managers = (WL>=2 & EarlyAge==1)

bysort OfficeCode Year: egen no_managers = total(managers)
bysort OfficeCode Year: egen no_hf_managers = total(hf_managers)

order OfficeCode Year IDlse WL managers EarlyAge hf_managers no_managers no_hf_managers

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


esttab lp_control lp_l1_control lp_l2_control lc_control lc_l1_control lc_l2_control, keep(share_hf_managers)   star(* 0.10 ** 0.05 *** 0.01)
	
esttab lp_control lp_l1_control lp_l2_control lc_control lc_l1_control lc_l2_control ///
    using "${Results}/ProdvsHFmngr.tex" ///
    , replace style(tex) fragment nocons label nofloat nobaselevels nomtitles ///
    collabels(, none) keep(share_hf_managers) ///
    stats(mean N r2, labels("Mean" "N" "R-squared") fmt(%9.3f %9.0f %9.3f)) /// 
    prehead("\begin{tabular}{lcccccc}" "\toprule" "\toprule" "& \multicolumn{3}{c}{Output per worker in logs} & \multicolumn{3}{c}{Costs per output in logs} \\" "\addlinespace[10pt] \cmidrule(lr){2-4} \cmidrule(lr){5-7} \\" "& \multicolumn{1}{c}{\shortstack{Current \\ Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -1 Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -2 Year}} & \multicolumn{1}{c}{\shortstack{Current \\ Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -1 Year}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -2 Year}} \\ ") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is an office-year. Standard errors clustered at the office level. Control variables include country FE, year FE, and office size. In Columns (1)-(3), the outcome variables are current-year, and lagged (-1 and -2 year) output per worker in logs. In Columns (4)-(6), the outcome variables are current-year, and lagged (-1 and -2 year) costs per output in logs." "\end{tablenotes}")