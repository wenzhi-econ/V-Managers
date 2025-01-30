/* 
This do file conducts factory level analysis on the effects of exposure to high-flyer managers.

Input: 
    "${TempData}/04MainOutcomesInEventStudies.dta"   <== created in 0104 do file
    "${RawMNEData}/OfficeSize.dta"
    "${RawMNEData}/TonsperFTEconservative.dta"       <== raw data
    "${RawMNEData}/CPTwideOld.dta"                   <== raw data

Output:
    "${TempData}/temp_FactoryLevelAnalysis.dta"

RA: WWZ 
Time: 2024-01-13
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplified dataset containing only relevant variables
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. personnel dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

generate Year = year(dofm(YearMonth))

keep ///
    IDlse YearMonth Year OfficeCode ISOCode WL ///
    EarlyAgeM TransferSJC ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL 

order ///
    IDlse YearMonth Year OfficeCode ISOCode WL ///
    EarlyAgeM TransferSJC ///
    FT_Mngr_both_WL2 ///
    FT_Never_ChangeM FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-1. office size 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

merge m:1 OfficeCode YearMonth using "${RawMNEData}/OfficeSize.dta", keepusing(TotWorkersBC TotWorkersWC)
keep if _merge ==3 
drop _merge 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-2. cumulative exposure to H type managers
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

sort IDlse YearMonth
bysort IDlse: generate stockHF = sum(EarlyAgeM)

generate one = 1
sort IDlse YearMonth
bysort IDlse: generate stockM = sum(one)
generate shareHF = stockHF/stockM

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-3. manager or not 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate Mngr = (WL>=2) if WL!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. productivity dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 OfficeCode Year using "${RawMNEData}/TonsperFTEconservative.dta", keepusing(TotBigC TonsperFTEMean)
rename _merge merge_Output

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. cost dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 OfficeCode Year using "${RawMNEData}/CPTwideOld.dta", keepusing(CPTFR CPTHC CPTPC)
rename _merge merge_Cost

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. collapse to factory-year level
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable OfficeCode          "Office or Plant/Factory"
label variable Year                "Year"
label variable ISOCode             "Country"

label variable TotBigC             "Product indicator (1-3)"

label variable TotWorkersWC        "Number of white-collar workers"
label variable TotWorkersBC        "Number of white-collar workers"
label variable Mngr                "Ind-YM level, =1, if the worker's WL >= 2"
label variable EarlyAgeM           "Ind-YM level, =1, if the worker's manager is HF"

label variable shareHF             "Ind-YM level, share of months working for a HF manager"

xtset IDlse YearMonth, monthly
generate shareHF_1yrBefore = L12.shareHF
order IDlse YearMonth shareHF shareHF_1yrBefore

collapse ///
    (mean) shareHF shareHF_1yrBefore /// // treatment variables
    TotWorkersWC TotWorkersBC TotBigC MShare=Mngr EarlyAgeM /// // control variables
    TonsperFTEMean CPTFR CPTHC CPTPC /// // outcome variables
    , by(OfficeCode Year ISOCode) 

label variable MShare "Manager share in the factory"

generate lp   = log(TonsperFTEMean) 
generate lcfr = log(CPTFR)
egen     CPT  = rowmean(CPTFR CPTHC CPTPC)
generate lc   = log(CPT)

save "${TempData}/temp_FactoryLevelAnalysis.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. factory-level analysis
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_FactoryLevelAnalysis.dta", clear 

/* drop if lp==. & lcfr==. & lc==. */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. productivity and cost against cumulative exposure to HF managers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe lp shareHF TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode TotBigC) cluster(OfficeCode)
    global b_prod_HF = _b["shareHF"]
    global b_prod_HF = string(${b_prod_HF}, "%4.3f")
    global se_prod_HF = _se["shareHF"]
    global se_prod_HF = string(${se_prod_HF}, "%3.2f")
    global N_prod_HF = e(N)
    global N_prod_HF = string(${N_prod_HF}, "%3.0f")

binscatter lp shareHF, ///
    absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolors(ebblue) lcolors(red) ///
    text(5.35 0.3 "beta = ${b_prod_HF}", size(medium)) ///
    text(5.3 0.3 "s.e. = ${se_prod_HF}", size(medium)) ///
    text(5.25 0.3 "N = ${N_prod_HF}", size(medium)) ///
    xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ///
    ytitle("Output per worker (in logs)", size(medium)) ///
    ylabel(5.2(0.1)6) xlabel(0(0.1)0.35)

graph export "${Results}/FactoryOutput_CumExposuretoHF.pdf", replace as(pdf)

reghdfe lcfr shareHF TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode) cluster(OfficeCode)
    global b_cost_HF = _b["shareHF"]
    global b_cost_HF = string(${b_cost_HF}, "%4.3f")
    global se_cost_HF = _se["shareHF"]
    global se_cost_HF = string(${se_cost_HF}, "%3.2f")
    global N_cost_HF = e(N)

binscatter lcfr shareHF, ///
    absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare) ///
    mcolor(ebblue) lcolor(red) ///
    text(6.3 0.3 "beta = ${b_cost_HF}", size(medium)) ///
    text(6.25 0.3 "s.e. = ${se_cost_HF}", size(medium)) ///
    text(6.20 0.3 "N = ${N_cost_HF}", size(medium)) ///
    xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ///
    ytitle("Cost per ton in logs (EUR)", size(medium)) ///
    ylabel(5.9(0.1)6.5) xlabel(0(0.1)0.35)

graph export "${Results}/FactoryCost_CumExposuretoHF.pdf", replace as(pdf)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. productivity and cost against lagged cumulative exposure to HF managers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe lp shareHF_1yrBefore TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode TotBigC) cluster(OfficeCode)
    global b_prod_HF = _b["shareHF_1yrBefore"]
    global b_prod_HF = string(${b_prod_HF}, "%4.3f")
    global se_prod_HF = _se["shareHF_1yrBefore"]
    global se_prod_HF = string(${se_prod_HF}, "%3.2f")
    global N_prod_HF = e(N)
    global N_prod_HF = string(${N_prod_HF}, "%3.0f")

binscatter lp shareHF_1yrBefore, ///
    absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolors(ebblue) lcolors(red) ///
    text(5.35 0.3 "beta = ${b_prod_HF}", size(medium)) ///
    text(5.3 0.3 "s.e. = ${se_prod_HF}", size(medium)) ///
    text(5.25 0.3 "N = ${N_prod_HF}", size(medium)) ///
    xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ///
    ytitle("Output per worker (in logs)", size(medium)) ///
    ylabel(5.2(0.1)6, grid gstyle(dot)) xlabel(0(0.1)0.35)

graph export "${Results}/FactoryOutput_CumExposuretoHF_1yrBefore.pdf", replace as(pdf)

reghdfe lcfr shareHF_1yrBefore TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode) cluster(OfficeCode)
    global b_cost_HF = _b["shareHF_1yrBefore"]
    global b_cost_HF = string(${b_cost_HF}, "%4.3f")
    global se_cost_HF = _se["shareHF_1yrBefore"]
    global se_cost_HF = string(${se_cost_HF}, "%3.2f")
    global N_cost_HF = e(N)

binscatter lcfr shareHF_1yrBefore, ///
    absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare) ///
    mcolor(ebblue) lcolor(red) ///
    text(6.3 0.3 "beta = ${b_cost_HF}", size(medium)) ///
    text(6.25 0.3 "s.e. = ${se_cost_HF}", size(medium)) ///
    text(6.20 0.3 "N = ${N_cost_HF}", size(medium)) ///
    xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ///
    ytitle("Cost per ton in logs (EUR)", size(medium)) ///
    ylabel(5.9(0.1)6.5, grid gstyle(dot)) xlabel(0(0.1)0.35)

graph export "${Results}/FactoryCost_CumExposuretoHF_1yrBefore.pdf", replace as(pdf)