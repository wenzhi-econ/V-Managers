********************************************************************************
* Profitability calculation 
* Profits: p*Y - C 
* So profits change (if price constant) = p*(y1 - y0) - (c1 - c0)
* Issue: do not have prices
* alternative strategy: compare coefficients 
* use coefficient on output per worker: 2.03 (no workers are constant as I control for it in regression)
* use coefficient on cost per worker: -1.2 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 
merge m:1 OfficeCode YearMonth using "$managersdta/OfficeSize.dta", keepusing(TotWorkers TotWorkersBC TotWorkersWC) // get BC size
keep if _merge ==3 
drop _merge 
*"${user}/Data/Productivity/SC Data/TonsperFTEregular.dta"
gen MShare = WL>=2 if WL!=.

* cumulative exposure
bys IDlse (YearMonth), sort: gen stockHF = sum(EarlyAgeM)
gen o =1
bys IDlse (YearMonth), sort: gen stockM = sum(o)
gen shareHF = stockHF/stockM

* merge with productivity data: tons/FTE
merge m:1 OfficeCode Year using "$managersdta/TPFTEwide.dta", keepusing(TonsperFTEMaxFR TonsperFTEMinFR TonsperFTEMaxHC TonsperFTEMinHC TonsperFTEMaxPC TonsperFTEMinPC  BigCType)
*merge m:1 OfficeCode Year using "$managersdta/TonsperFTEconservative.dta", keepusing(PC HC FR TotBigC  TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)
rename _merge mOutput
*keep if _merge==3
*merge m:1 OfficeCode Year using "$managersdta/TonsperFTEregular.dta", keepusing(PC HC FR TotBigC  TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)

* merge with productivity data: cost/tons
merge m:1 OfficeCode Year using "$managersdta/CPTwide.dta", keepusing( BigCType CPTMaxFR CPTMinFR CPTprevMaxFR CPTprevMinFR CPTChangeYoYMaxFR CPTChangeYoYMinFR EuroMaxFR EuroMinFR EuroprevMaxFR EuroprevMinFR VolMaxFR VolMinFR VolprevMaxFR VolprevMinFR CPTMaxHC CPTMinHC CPTprevMaxHC CPTprevMinHC CPTChangeYoYMaxHC CPTChangeYoYMinHC EuroMaxHC EuroMinHC EuroprevMaxHC EuroprevMinHC VolMaxHC VolMinHC VolprevMaxHC VolprevMinHC CPTMaxPC CPTMinPC CPTprevMaxPC CPTprevMinPC CPTChangeYoYMaxPC CPTChangeYoYMinPC EuroMaxPC EuroMinPC EuroprevMaxPC EuroprevMinPC VolMaxPC VolMinPC VolprevMaxPC VolprevMinPC )

* collapse 
collapse Euro*  TotWorkers TotWorkersBC TotWorkersWC shareHF* EarlyAge EarlyAgeM MShare BigCType TransferSJV TransferSJVC TransferSJC TransferSJLL TransferSJLLC PromWL PromWLC (sum) OfficeSizeWC=o OfficeSizeWL2 = MShare  ChangeSalaryGrade , by(OfficeCode Year ISOCode ) // stock*

egen OfficeYear= group(OfficeCode Year)

* average costs 
egen EuroMax = rowmean( EuroMaxFR EuroMaxPC EuroMaxHC) 
egen EuroMin = rowmean( EuroMinFR EuroMinPC EuroMinHC)
egen Euro = rowmean(EuroMin EuroMax) 

* cost per worker 
foreach v in Euro EuroMin EuroMax EuroMaxFR EuroMinFR EuroMaxPC EuroMinPC EuroMaxHC EuroMinHC{
	ge `v'W = `v'/TotWorkers
}

* take logs 
foreach v in EuroW EuroMinW EuroMaxW EuroMaxFRW EuroMinFRW EuroMaxPCW EuroMinPCW EuroMaxHCW EuroMinHCW EuroMaxFR EuroMaxPC EuroMaxHC EuroMinFR EuroMinPC EuroMinHC{ 
gen l`v' = log(`v')
} 


reghdfe lEuroMaxW shareHF  TotWorkersBC TotWorkersWC MShare , a(Year ISOCode BigCType) cluster(OfficeYear)
reghdfe lEuroMinW shareHF  TotWorkersBC TotWorkersWC MShare , a(Year ISOCode BigCType) cluster(OfficeYear)

* PLOT OUTPUT: TOTAL COSTS PER WORKER (t-1)
reghdfe lEuroW shareHF  TotWorkersBC TotWorkersWC MShare , a(Year ISOCode BigCType) cluster(OfficeYear) // cost per worker decrease by 1.2
* so profits: 2.03 + 1.2 = 3.23
local b = round(_b[ shareHF ] , .01)
local se = round(_se[ shareHF ] , .01)
local n = e(N)
di `n'

binscatter lEuroW shareHF , absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.BigCType) mcolor(ebblue) lcolor(orange) text(10.95 0.3 "beta = `b'") text(10.9 0.3 "s.e.= `se'") text(10.85 0.3 "N= `n'") ///
xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ytitle("Costs per worker in logs", size(medium))   ylabel(10.4(0.2)11) xlabel(0(0.1)0.35)
graph export "$analysis/Results/6.Productivity/HFEurosLogsCUM.png", replace
graph save "$analysis/Results/6.Productivity/HFEurosLogsCUM.gph", replace


/*merge m:1 OfficeCode Year using "$managersdta/CPTwide.dta", keepusing(CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC)

PI = VolMaxFR - EuroMaxFR // but do not have prices! 
* change YoYFR
********************************************************************************

* gen variables 
egen OfficeYear= group(OfficeCode Year)

egen CPTChangeYoYMax = rowmean(CPTChangeYoYMaxFR CPTChangeYoYMaxHC CPTChangeYoYMaxPC)
egen CPTMax = rowmean(CPTMaxFR CPTMaxHC CPTMaxPC)
gen TonsFR =  TonsperFTEFR*TotWorkersBC
gen Tons = TonsperFTETotal*TotWorkersBC

xtset IDlse YearMonth 
gen TonsperFTEChangeYoYFR = d.lpfr
gen TonsperFTEChangeYoY = d.lp

* profits 
gen PI = Tons - CPT*Tons 
su PI // all negative, cannot take logs 
gen PIFR = TonsFR - CPTFR*TonsFR
gen ChangepiFR =  TonsperFTEChangeYoYFR - CPTChangeYoYFR
gen Changepi =  TonsperFTEChangeYoY - CPTChangeYoY

* costs 
gen CostFR = CPTFR*TonsFR 
gen Cost = CPT*Tons

* logs 
ge pi = log(PI)
ge pifr = log(PIFR)
gen lcfr = log(CPTFR)
gen lchc = log(CPTHC)
gen lcpc = log(CPTPC)
gen lp=log( TonsperFTEMean)
gen lpfr=log( TonsperFTEFR)
gen lcc = log(Cost + 1 )
gen lccfr = log(CostFR +1 )

reghdfe Changepi shareHF EarlyAgeM   TotWorkersBC TotWorkersWC MShare , a(Year  ISOCode ) cluster(OfficeYear)

reghdfe PI shareHF  TotWorkersBC TotWorkersWC MShare , a(Year  ISOCode TotBigC) cluster(OfficeYear)
reghdfe pi shareHF  TotWorkersBC TotWorkersWC MShare , a(Year  ISOCode TotBigC) cluster(OfficeYear)
reghdfe lcc shareHF  TotWorkersBC TotWorkersWC MShare EarlyAgeM, a(Year  ISOCode TotBigC) cluster(OfficeYear)

* collapse 
********************************************************************************

collapse Euro* lcc lccfr Cost CostFR PI PIFR TotWorkers TotWorkersBC TotWorkersWC CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC  lcfr lcpc lchc shareHF* EarlyAge EarlyAgeM MShare TotBigC PC HC FR TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC TransferSJV TransferSJVC TransferSJC TransferSJLL TransferSJLLC PromWL PromWLC (sum) OfficeSizeWC=o OfficeSizeWL2 = MShare  ChangeSalaryGrade , by(OfficeCode Year ISOCode ) // stock*

* Gen variables 
egen OfficeYear= group(OfficeCode Year)
egen CPT = rowmean(CPTFR CPTHC CPTPC )
gen lc = log(CPT)
gen lp=log( TonsperFTEMean) 
gen lpfr=log( TonsperFTEFR) 
gen lt = log(TransferSJC +1)
gen lv = log(TransferSJVC +1)
gen pp = log(PromWLC +1)
xtset OfficeCode Year 
gen TonsperFTEChangeYoYFR = d.lpfr
gen TonsperFTEChangeYoY = d.lp

gen ChangepiFR =  TonsperFTEChangeYoYFR - CPTChangeYoYFR
gen Changepi =  TonsperFTEChangeYoY - CPTChangeYoY

* compute output - but cannot do it as I do not have the price level 
********************************************************************************

reghdfe PI shareHF  TotWorkersBC TotWorkersWC MShare , a(Year  ISOCode TotBigC) cluster(OfficeYear)
reghdfe pi shareHF  TotWorkersBC TotWorkersWC MShare , a(Year  ISOCode TotBigC) cluster(OfficeYear)
reghdfe lccfr shareHF  TotWorkersBC TotWorkersWC MShare , a(Year  ISOCode) cluster(OfficeYear)


