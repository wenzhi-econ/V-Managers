/* 
This do file conducts factory level analysis on the effects of high-flyer managers.

Input: 
    "${FinalData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0104 do file
    "${FinalData}/OfficeSize.dta"
    "${FinalData}/TonsperFTEconservative.dta"
    "${FinalData}/CPTwideOld.dta"

Output:
    "${TempData}/temp_FactoryLevelAnalysis.dta"

RA: WWZ 
Time: 2024-10-14
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplified dataset containing only relevant variables
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. personnal dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

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

merge m:1 OfficeCode YearMonth using "${FinalData}/OfficeSize.dta", keepusing(TotWorkersBC TotWorkersWC)
keep if _merge ==3 
drop _merge 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-2. cumulative lateral moves (separate by destination manager type)
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate sum_TransferSJC_toH =.
replace  sum_TransferSJC_toH = TransferSJC if inrange(FT_Rel_Time, 0, 60) & (FT_LtoH==1 | FT_HtoH==1)
generate sum_TransferSJC_toL = .
replace  sum_TransferSJC_toL = TransferSJC if inrange(FT_Rel_Time, 0, 60) & (FT_HtoL==1 | FT_LtoL==1)

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-3. cumulative exposure to H type managers
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

sort IDlse YearMonth
bysort IDlse: generate stockHF = sum(EarlyAgeM)

generate one = 1
sort IDlse YearMonth
bysort IDlse: generate stockM = sum(one)
generate shareHF = stockHF/stockM

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-4. manager or not 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate Mngr = (WL>=2) if WL!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. productivity dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 OfficeCode Year using "${FinalData}/TonsperFTEconservative.dta", keepusing(TotBigC TonsperFTEMean)
rename _merge merge_Output


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. cost dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 OfficeCode Year using "${FinalData}/CPTwideOld.dta", keepusing(CPTFR CPTHC CPTPC)
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

label variable shareHF             "Ind-YM level, share of months working for a HF manager (before current month)"
label variable sum_TransferSJC_toH "Ind-YM level cumsum of lateral moves 60 months after first exposure to HF Mngr"
label variable sum_TransferSJC_toL "Ind-YM level cumsum of lateral moves 60 months after first exposure to LF Mngr"

collapse ///
    (mean) shareHF sum_TransferSJC_toH sum_TransferSJC_toL /// // treatment variables
    TotWorkersWC TotWorkersBC TotBigC MShare=Mngr EarlyAgeM /// // control variables
    TonsperFTEMean CPTFR CPTHC CPTPC /// // outcome variables
    , by(OfficeCode Year ISOCode) 

label variable MShare "Manager share in the factory"

generate lp   = log(TonsperFTEMean) 
generate lcfr = log(CPTFR)
egen     CPT  = rowmean(CPTFR CPTHC CPTPC)
generate lc   = log(CPT)

generate logsum_TransferSJC_toH = log(sum_TransferSJC_toH + 1)
generate logsum_TransferSJC_toL = log(sum_TransferSJC_toL + 1)

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
    mcolor(ebblue) lcolor(orange) ///
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
    mcolor(ebblue) lcolor(orange) ///
    text(6.3 0.3 "beta = ${b_cost_HF}", size(medium)) ///
    text(6.25 0.3 "s.e. = ${se_cost_HF}", size(medium)) ///
    text(6.20 0.3 "N = ${N_cost_HF}", size(medium)) ///
    xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ///
    ytitle("Cost per ton in logs (EUR)", size(medium)) ///
    ylabel(5.9(0.1)6.5) xlabel(0(0.1)0.35)

graph export "${Results}/FactoryCost_CumExposuretoHF.pdf", replace as(pdf)