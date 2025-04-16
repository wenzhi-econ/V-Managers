/* 
This do file conducts factory level analysis on the effects of exposure to high-flyer managers.

Input: 
    "${TempData}/FinalFullSample.dta"                <== created in 0101_01 do file
    "${RawMNEData}/OfficeSize.dta"                   <== raw data
    "${RawMNEData}/TonsperFTEconservative.dta"       <== raw data
    "${RawMNEData}/CPTwideOld.dta"                   <== raw data

Output:
    "${TempData}/0305FactoryLevel_ProdAndCostAgainstHFShares.dta"

Results:
    "${Results}/004ResultsBasedOnCA30/CA30_FactoryOutput_CumExposuretoHF_1yrBefore.pdf"
    "${Results}/004ResultsBasedOnCA30/CA30_FactoryCost_CumExposuretoHF_1yrBefore.pdf"

RA: WWZ 
Time: 2025-04-16
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplified dataset containing only relevant variables
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. obtain an employee's manager's HF measure 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalFullSample.dta", clear 

keep  IDlse IDlseMHR YearMonth Year OfficeCode ISOCode WL 
order OfficeCode Year YearMonth IDlse IDlseMHR

merge m:1 IDlseMHR YearMonth using "${TempData}/0102_03HFMeasure.dta", keepusing(CA30)
    drop if _merge==2
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                     5,407,229
        from master                 4,347,038  (_merge==1)
        from using                  1,060,191  (_merge==2)

    Matched                         5,736,600  (_merge==3)
    -----------------------------------------
*/
rename CA30 CA30M 
    //&? rename this variable to indicate that it is the employee's manager's quality 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. obtain factory size: both white- and blue-collar workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 OfficeCode YearMonth using "${RawMNEData}/OfficeSize.dta", keepusing(TotWorkersBC TotWorkersWC)
    keep if _merge ==3 
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                         2,480
        from master                       337  (_merge==1)
        from using                      2,143  (_merge==2)

    Matched                        10,083,301  (_merge==3)
    -----------------------------------------
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. obtain factory-level productivity measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 OfficeCode Year using "${RawMNEData}/TonsperFTEconservative.dta", keepusing(TotBigC TonsperFTEMean)
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                     9,753,887
        from master                 9,753,869  (_merge==1)
        from using                         18  (_merge==2)

    Matched                           329,432  (_merge==3)
    -----------------------------------------
*/
rename _merge merge_Output
drop if merge_Output==2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. obtain factory-level cost measures 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 OfficeCode Year using "${RawMNEData}/CPTwideOld.dta", keepusing(CPTFR CPTHC CPTPC)
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                     9,763,428
        from master                 9,763,091  (_merge==1)
        from using                        337  (_merge==2)

    Matched                           320,210  (_merge==3)
    -----------------------------------------
*/
rename _merge merge_Cost
drop if merge_Cost==2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. office-year level manager share 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Mngr = (WL>=2) if WL!=.

sort OfficeCode Year 
bysort OfficeCode Year: egen MShare = mean(Mngr)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct individual-month level past exposure on HF managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. sample restriction on employee-month pairs 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

order ISOCode OfficeCode MShare Year YearMonth IDlse WL IDlseMHR CA30M

keep if CA30M!=.
    //impt: in this step, I will only keep employee-year-month with where the corresponding manager's quality can be identified with CA30 measure
    //&? in other words, here I only consider WL1 employees whose managers' have ever been WL2 in the dataset 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. an individual's exposure to HF managers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate stockHF = sum(CA30M)

generate one = 1
sort IDlse YearMonth
bysort IDlse: generate stockM = sum(one)
generate shareHF = stockHF/stockM
order stockHF stockM shareHF, after(CA30M)

xtset IDlse YearMonth, monthly
generate shareHF_1yrBefore = L12.shareHF, after(shareHF)

label variable ISOCode             "Country"
label variable OfficeCode          "Office or plant/factory"
label variable MShare              "Office-YM level share of managers (WL2+ among all employees)"
label variable Year                "Year"
label variable CA30M               "The employee's manager in that month is a high-flyer"
label variable shareHF             "Ind-YM level, share of months working for a HF manager"
label variable shareHF_1yrBefore   "Ind-YM level, 1 year ago, share of months working for a HF manager"

label variable TotBigC             "Product indicator (1-3)"
label variable TotWorkersWC        "Number of white-collar workers"
label variable TotWorkersBC        "Number of white-collar workers"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. collapse into office-year level 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

collapse (mean) MShare TotWorkersWC TotWorkersBC TotBigC TonsperFTEMean CPTFR CPTHC CPTPC shareHF shareHF_1yrBefore, by(OfficeCode Year ISOCode)

label variable shareHF_1yrBefore "Employees' average cumulative past exposure to HF managers up to last year"
label variable shareHF           "Employees' average cumulative past exposure to HF managers up to current year"

generate lp   = log(TonsperFTEMean) 
generate lcfr = log(CPTFR)
egen     CPT  = rowmean(CPTFR CPTHC CPTPC)
generate lc   = log(CPT)

save "${TempData}/0305FactoryLevel_ProdAndCostAgainstHFShares.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. factory-level regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0305FactoryLevel_ProdAndCostAgainstHFShares.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. productivity against lagged cumulative exposure to HF managers
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

graph export "${Results}/004ResultsBasedOnCA30/CA30_FactoryOutput_CumExposuretoHF_1yrBefore.pdf", replace as(pdf)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. cost against lagged cumulative exposure to HF managers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

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

graph export "${Results}/004ResultsBasedOnCA30/CA30_FactoryCost_CumExposuretoHF_1yrBefore.pdf", replace as(pdf)