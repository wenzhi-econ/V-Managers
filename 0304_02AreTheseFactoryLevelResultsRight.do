


use "${TempData}/temp_FactoryLevelAnalysis.dta", clear 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. robustness for Figure VII
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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
    ylabel(5.9(0.1)6.5) xlabel(0(0.1)0.35) ///
    title("Dont control for EarlyAgeM")

graph export "${Results}/FactoryCost_CumExposuretoHF_NoEarlyAgeM.png", replace as(png)


reghdfe lp shareHF TotWorkersWC TotWorkersBC MShare EarlyAgeM, absorb(Year ISOCode TotBigC) cluster(OfficeCode)
    global b_prod_HF = _b["shareHF"]
    global b_prod_HF = string(${b_prod_HF}, "%4.3f")
    global se_prod_HF = _se["shareHF"]
    global se_prod_HF = string(${se_prod_HF}, "%3.2f")
    global N_prod_HF = e(N)
    global N_prod_HF = string(${N_prod_HF}, "%3.0f")

binscatter lp shareHF, ///
    absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC EarlyAgeM) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.35 0.3 "beta = ${b_prod_HF}", size(medium)) ///
    text(5.3 0.3 "s.e. = ${se_prod_HF}", size(medium)) ///
    text(5.25 0.3 "N = ${N_prod_HF}", size(medium)) ///
    xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ///
    ytitle("Output per worker (in logs)", size(medium)) ///
    ylabel(5.2(0.1)6) xlabel(0(0.1)0.35) ///
    title("Control EarlyAgeM")

graph export "${Results}/FactoryOutput_CumExposuretoHF_WithEarlyAgeM.png", replace as(png)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. robustness for Figure VIII
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. get a new regressor (adjusted for pre-event lateral moves)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${FinalData}/AllSameTeam2.dta", clear 

keep ///
    IDlse YearMonth Year OfficeCode ISOCode WL ///
    EarlyAgeM TransferSJC ///
    FTLL FTLH FTHL FTHH

order ///
    IDlse YearMonth Year OfficeCode ISOCode WL ///
    EarlyAgeM TransferSJC ///
    FTLL FTLH FTHL FTHH

merge m:1 OfficeCode YearMonth using "${FinalData}/OfficeSize.dta", keepusing(TotWorkersBC TotWorkersWC)
keep if _merge ==3 
drop _merge 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-1. event-related variables
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

*!! calendar time of the event
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHL FT_Calend_Time_HtoL
rename FTHH FT_Calend_Time_HtoH

*!! five event dummies: 4 types of treatment + 1 never-treated
generate FT_LtoL = 0 
replace  FT_LtoL = 1 if FT_Calend_Time_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if FT_Calend_Time_LtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if FT_Calend_Time_HtoL != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if FT_Calend_Time_HtoH != .

generate FT_Never_ChangeM = . 
replace  FT_Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  FT_Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 

label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-2. cumulative lateral moves (separate by destination manager type)
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate sum_TransferSJC_toH =.
replace  sum_TransferSJC_toH = TransferSJC if inrange(FT_Rel_Time, 0, 60) & (FT_LtoH==1 | FT_HtoH==1)
generate sum_TransferSJC_toL = .
replace  sum_TransferSJC_toL = TransferSJC if inrange(FT_Rel_Time, 0, 60) & (FT_HtoL==1 | FT_LtoL==1)

generate temp_num_transfers_pre_event = .
replace  temp_num_transfers_pre_event = TransferSJC if YearMonth == FT_Calend_Time_LtoL & FT_Calend_Time_LtoL!=.
replace  temp_num_transfers_pre_event = TransferSJC if YearMonth == FT_Calend_Time_LtoH & FT_Calend_Time_LtoH!=.
replace  temp_num_transfers_pre_event = TransferSJC if YearMonth == FT_Calend_Time_HtoL & FT_Calend_Time_HtoL!=.
replace  temp_num_transfers_pre_event = TransferSJC if YearMonth == FT_Calend_Time_HtoH & FT_Calend_Time_HtoH!=.

sort IDlse YearMonth 
bysort IDlse: egen num_transfers_pre_event = mean(temp_num_transfers_pre_event)

replace sum_TransferSJC_toH = sum_TransferSJC_toH - num_transfers_pre_event
replace sum_TransferSJC_toL = sum_TransferSJC_toL - num_transfers_pre_event

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-3. other variables
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

sort IDlse YearMonth
bysort IDlse: generate stockHF = sum(EarlyAgeM)

generate one = 1
sort IDlse YearMonth
bysort IDlse: generate stockM = sum(one)
generate shareHF = stockHF/stockM

generate Mngr = (WL>=2) if WL!=.

merge m:1 OfficeCode Year using "${FinalData}/TonsperFTEconservative.dta", keepusing(TotBigC TonsperFTEMean)
rename _merge merge_Output

merge m:1 OfficeCode Year using "${FinalData}/CPTwideOld.dta", keepusing(CPTFR CPTHC CPTPC)
rename _merge merge_Cost

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-1-4. collapse to factory-year level
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. factory-year level data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

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

save "${TempData}/temp_FactoryLevelAnalysis_NewTransferMeasure.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. run regressions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_FactoryLevelAnalysis_NewTransferMeasure.dta", clear 


reghdfe lp logsum_TransferSJC_toH TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode i.TotBigC) cluster(OfficeCode)
    global b_prod_movestoH = _b["logsum_TransferSJC_toH"]
    global b_prod_movestoH = string(${b_prod_movestoH}, "%4.3f")
    global se_prod_movestoH = _se["logsum_TransferSJC_toH"]
    global se_prod_movestoH = string(${se_prod_movestoH}, "%3.2f")
    global N_prod_movestoH = e(N)
    global N_prod_movestoH = string(${N_prod_movestoH}, "%3.0f")

binscatter lp logsum_TransferSJC_toH, ///
    absorb(ISOCode) controls(Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.8 1.1 "beta = ${b_prod_movestoH}", size(medium)) ///
    text(5.75 1.1 "s.e. = ${se_prod_movestoH}", size(medium)) /// // 
    text(5.7 1.1 "N = ${N_prod_movestoH}", size(medium)) ///
    xtitle("Lateral moves after exposure to high-flyer manager (in logs)", size(medium)) ///
    ytitle("Output per worker in logs", size(medium)) ///
    xscale(range(0 1.2)) xlabel(0(0.2)1.4) ///
    title("New regressor, no sample restrictions")

graph export "${Results}/FactoryOutput_CumsumLateralMoves_toHTypeMngrs_NewTransferMeasure_NoRestriction.png", replace as(png)

reghdfe lc logsum_TransferSJC_toH TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode i.TotBigC) cluster(OfficeCode)
    global b_cost_movestoH = _b["logsum_TransferSJC_toH"]
    global b_cost_movestoH = string(${b_cost_movestoH}, "%4.3f")
    global se_cost_movestoH = _se["logsum_TransferSJC_toH"]
    global se_cost_movestoH = string(${se_cost_movestoH}, "%3.2f")
    global N_cost_movestoH = e(N)
    global N_cost_movestoH = string(${N_cost_movestoH}, "%3.0f")

binscatter lc logsum_TransferSJC_toH, ///
    absorb(ISOCode) controls(Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.5 1 "beta = ${b_cost_movestoH}", size(medium)) ///
    text(5.45 1 "s.e. = ${se_cost_movestoH}", size(medium)) /// // 
    text(5.4 1 "N = ${N_cost_movestoH}", size(medium)) ///
    xtitle("Lateral moves after exposure to high-flyer manager (in logs)", size(medium)) ///
    ytitle("Cost per ton (in logs)", size(medium)) ///
    yscale(range(5.2 5.8)) xscale(range(0 1.2)) xlabel(0(0.2)1.4) ///
    title("New regressor, no sample restrictions")

graph export "${Results}/FactoryCost_CumsumLateralMoves_toHTypeMngrs_NewTransferMeasure_NoRestriction.png", replace as(png)

reghdfe lp logsum_TransferSJC_toL TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode i.TotBigC) cluster(OfficeCode)
    global b_prod_movestoL = _b["logsum_TransferSJC_toL"]
    global b_prod_movestoL = string(${b_prod_movestoL}, "%4.3f")
    global se_prod_movestoL = _se["logsum_TransferSJC_toL"]
    global se_prod_movestoL = string(${se_prod_movestoL}, "%3.2f")
    global N_prod_movestoL = e(N)
    global N_prod_movestoL = string(${N_prod_movestoL}, "%3.0f")

binscatter lp logsum_TransferSJC_toL, ///
    absorb(ISOCode) controls(Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.7 1.1 "beta = ${b_prod_movestoL}", size(medium)) ///
    text(5.6 1.1 "s.e. = ${se_prod_movestoL}", size(medium)) /// // 
    text(5.5 1.1 "N = ${N_prod_movestoL}", size(medium)) ///
    xtitle("Lateral moves after exposure to low-flyer manager (in logs)", size(medium)) ///
    ytitle("Output per worker (in logs)", size(medium)) ///
    xscale(range(0 1.2)) xlabel(0(0.2)1.4) ///
    title("New regressor, no sample restrictions")

graph export "${Results}/FactoryOutput_CumsumLateralMoves_toLTypeMngrs_NewTransferMeasure_NoRestriction.png", replace as(png)

reghdfe lc logsum_TransferSJC_toL TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode i.TotBigC) cluster(OfficeCode)
    global b_cost_movestoL = _b["logsum_TransferSJC_toL"]
    global b_cost_movestoL = string(${b_cost_movestoL}, "%4.3f")
    global se_cost_movestoL = _se["logsum_TransferSJC_toL"]
    global se_cost_movestoL = string(${se_cost_movestoL}, "%3.2f")
    global N_cost_movestoL = e(N)
    global N_cost_movestoL = string(${N_cost_movestoL}, "%3.0f")

binscatter lc logsum_TransferSJC_toL, ///
    absorb(ISOCode) controls(Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.75 1 "beta = ${b_cost_movestoL}", size(medium)) ///
    text(5.7 1 "s.e. = ${se_cost_movestoL}", size(medium)) /// // 
    text(5.65 1 "N = ${N_cost_movestoL}", size(medium)) ///
    xtitle("Lateral moves after exposure to low-flyer manager (in logs)", size(medium)) ///
    ytitle("Cost per ton (in logs)", size(medium)) ///
    xscale(range(0 1.2)) xlabel(0(0.2)1.4) ///
    title("New regressor, no sample restrictions")

graph export "${Results}/FactoryCost_CumsumLateralMoves_toLTypeMngrs_NewTransferMeasure_NoRestriction.png", replace as(png)








reghdfe lp logsum_TransferSJC_toH TotWorkersWC TotWorkersBC MShare, absorb(Year ISOCode i.TotBigC) cluster(OfficeCode)
    global b_prod_movestoH = _b["logsum_TransferSJC_toH"]
    global b_prod_movestoH = string(${b_prod_movestoH}, "%4.3f")
    global se_prod_movestoH = _se["logsum_TransferSJC_toH"]
    global se_prod_movestoH = string(${se_prod_movestoH}, "%3.2f")
    global N_prod_movestoH = e(N)
    global N_prod_movestoH = string(${N_prod_movestoH}, "%3.0f")

binscatter lp logsum_TransferSJC_toH, ///
    absorb(ISOCode) controls(Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.8 1.1 "beta = ${b_prod_movestoH}", size(medium)) ///
    text(5.75 1.1 "s.e. = ${se_prod_movestoH}", size(medium)) /// // 
    text(5.7 1.1 "N = ${N_prod_movestoH}", size(medium)) ///
    xtitle("Lateral moves after exposure to high-flyer manager (in logs)", size(medium)) ///
    ytitle("Output per worker in logs", size(medium)) ///
    xscale(range(0 1.2)) xlabel(0(0.2)1.4) ///
    title("New regressor, same sample restrictions")

graph export "${Results}/FactoryOutput_CumsumLateralMoves_toHTypeMngrs_NewTransferMeasure_SameRestriction.png", replace as(png)

reghdfe lc logsum_TransferSJC_toH TotWorkersWC TotWorkersBC MShare if logsum_TransferSJC_toL!=., absorb(Year ISOCode i.TotBigC) cluster(OfficeCode)
    global b_cost_movestoH = _b["logsum_TransferSJC_toH"]
    global b_cost_movestoH = string(${b_cost_movestoH}, "%4.3f")
    global se_cost_movestoH = _se["logsum_TransferSJC_toH"]
    global se_cost_movestoH = string(${se_cost_movestoH}, "%3.2f")
    global N_cost_movestoH = e(N)
    global N_cost_movestoH = string(${N_cost_movestoH}, "%3.0f")

binscatter lc logsum_TransferSJC_toH if logsum_TransferSJC_toL!=., ///
    absorb(ISOCode) controls(Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.5 1 "beta = ${b_cost_movestoH}", size(medium)) ///
    text(5.45 1 "s.e. = ${se_cost_movestoH}", size(medium)) /// // 
    text(5.4 1 "N = ${N_cost_movestoH}", size(medium)) ///
    xtitle("Lateral moves after exposure to high-flyer manager (in logs)", size(medium)) ///
    ytitle("Cost per ton (in logs)", size(medium)) ///
    yscale(range(5.2 5.8)) xscale(range(0 1.2)) xlabel(0(0.2)1.4) ///
    title("New regressor, same sample restrictions")

graph export "${Results}/FactoryCost_CumsumLateralMoves_toHTypeMngrs_NewTransferMeasure_SameRestriction.png", replace as(png)

reghdfe lp logsum_TransferSJC_toL TotWorkersWC TotWorkersBC MShare if logsum_TransferSJC_toH!=., absorb(Year ISOCode i.TotBigC) cluster(OfficeCode)
    global b_prod_movestoL = _b["logsum_TransferSJC_toL"]
    global b_prod_movestoL = string(${b_prod_movestoL}, "%4.3f")
    global se_prod_movestoL = _se["logsum_TransferSJC_toL"]
    global se_prod_movestoL = string(${se_prod_movestoL}, "%3.2f")
    global N_prod_movestoL = e(N)
    global N_prod_movestoL = string(${N_prod_movestoL}, "%3.0f")

binscatter lp logsum_TransferSJC_toL if logsum_TransferSJC_toH!=., ///
    absorb(ISOCode) controls(Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.7 1.1 "beta = ${b_prod_movestoL}", size(medium)) ///
    text(5.6 1.1 "s.e. = ${se_prod_movestoL}", size(medium)) /// // 
    text(5.5 1.1 "N = ${N_prod_movestoL}", size(medium)) ///
    xtitle("Lateral moves after exposure to low-flyer manager (in logs)", size(medium)) ///
    ytitle("Output per worker (in logs)", size(medium)) ///
    xscale(range(0 1.2)) xlabel(0(0.2)1.4) ///
    title("New regressor, same sample restrictions")

graph export "${Results}/FactoryOutput_CumsumLateralMoves_toLTypeMngrs_NewTransferMeasure_SameRestriction.png", replace as(png)

reghdfe lc logsum_TransferSJC_toL TotWorkersWC TotWorkersBC MShare if logsum_TransferSJC_toH!=., absorb(Year ISOCode i.TotBigC) cluster(OfficeCode)
    global b_cost_movestoL = _b["logsum_TransferSJC_toL"]
    global b_cost_movestoL = string(${b_cost_movestoL}, "%4.3f")
    global se_cost_movestoL = _se["logsum_TransferSJC_toL"]
    global se_cost_movestoL = string(${se_cost_movestoL}, "%3.2f")
    global N_cost_movestoL = e(N)
    global N_cost_movestoL = string(${N_cost_movestoL}, "%3.0f")

binscatter lc logsum_TransferSJC_toL if logsum_TransferSJC_toH!=., ///
    absorb(ISOCode) controls(Year TotWorkersWC TotWorkersBC MShare i.TotBigC) ///
    mcolor(ebblue) lcolor(orange) ///
    text(5.75 1 "beta = ${b_cost_movestoL}", size(medium)) ///
    text(5.7 1 "s.e. = ${se_cost_movestoL}", size(medium)) /// // 
    text(5.65 1 "N = ${N_cost_movestoL}", size(medium)) ///
    xtitle("Lateral moves after exposure to low-flyer manager (in logs)", size(medium)) ///
    ytitle("Cost per ton (in logs)", size(medium)) ///
    xscale(range(0 1.2)) xlabel(0(0.2)1.4) ///
    title("New regressor, same sample restrictions")

graph export "${Results}/FactoryCost_CumsumLateralMoves_toLTypeMngrs_NewTransferMeasure_SameRestriction.png", replace as(png)
