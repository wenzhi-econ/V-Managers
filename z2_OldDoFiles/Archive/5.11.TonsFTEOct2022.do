* COUNTERFACTUAL: WHAT WOULD HAPPEN IF THE SHARE OF GOOD MANAGERS GOES TO 100? 
* Gain: worker productivity
* Cost: managers' wages
* What are the productivity losses of bad managers? - is the share of good managers optimal conditional
* on the firm production function? 
* Consider a counterfactual scenario where the firm only has good managers 
***************** ***************** ***************** ***************** 

* GET THE CORRELATION OF SHARE OF GOOD MANAGERS WITH TONS PER FTE (SC productivity) 
********************************************************************************

use "$Managersdta/AllSameTeam2.dta", clear 
merge m:1 OfficeCode YearMonth using "$Managersdta/OfficeSize.dta", keepusing(TotWorkers TotWorkersBC TotWorkersWC) // get BC size
keep if _merge ==3 
drop _merge 
*"${user}/Data/Productivity/SC Data/TonsperFTEregular.dta"
gen MShare = WL>=2 if WL!=.

*gen Month = month(dofm(YearMonth))
*keep if Month == 12

/* create stock of experience with high fliers  + share of high flyers by years 
forval year=2011(1)2021{
*bys OfficeCode: egen shareHF`year' = mean(cond(Year==`year', EarlyAgeM, .))
bys IDlse: egen stockHF`year' = mean(cond(Year<=`year', EarlyAgeM, .)) 
bys IDlse: egen stockTHF`year' = mean(cond(Year<=`year', TransferSJ, .) )
bys IDlse: egen stockLHF`year' = mean(cond(Year<=`year', TransferSJLL, .) )
bys IDlse: egen stockVHF`year' = mean(cond(Year<=`year', TransferSJV, .) )

bys IDlse: egen stockTCHF`year' = max(cond(Year<=`year', TransferSJC, .) )
bys IDlse: egen stockLCHF`year' = max(cond(Year<=`year', TransferSJLLC, .) )
bys IDlse: egen stockVCHF`year' = max(cond(Year<=`year', TransferSJVC, .) )
}
*/
* cumulative exposure
bys IDlse (YearMonth), sort: gen stockHF = sum(EarlyAgeM)
gen o =1
bys IDlse (YearMonth), sort: gen stockM = sum(o)
gen shareHF = stockHF/stockM

* merge with productivity data: tons/FTE
merge m:1 OfficeCode Year using "$Managersdta/TonsperFTEconservative.dta", keepusing(PC HC FR TotBigC  TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)
rename _merge mOutput
*keep if _merge==3

* merge with productivity data: cost/tons
merge m:1 OfficeCode Year using "$Managersdta/CPTwide.dta", keepusing(CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC)

gen lcfr = log(CPTFR)
gen lchc = log(CPTHC)
gen lcpc = log(CPTPC)

gen lp=log( TonsperFTEMean)
gen lt=log( TransferSJVC+1) 
gen ltt=log( TransferSJC+1)  
gen llt=log( TransferSJLLC+1)  

egen OfficeYear= group(OfficeCode Year)

* regressions
xtset IDlse YearMonth
* 1) first managers on productivity 
reghdfe lp EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear) 
* 2) second stock of managers on productivity 
reghdfe lp shareHF EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear)
* 3) third reallocation 
reghdfe lp TransferSJC EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear) 
* 4) fourth: IV
*eststo reg0: ivreghdfe lp  (lt = shareHF) OfficeSize MShare, a(Year  ISOCode ) cluster(OfficeYear) first
eststo reg0: ivreghdfe lp  (lt = shareHF) OfficeSize, a(Year  ISOCode ) cluster(OfficeYear) first // much stronger first stage
ivreghdfe lp  (lt = shareHF) EarlyAgeM OfficeSize, a(Year  ISOCode ) cluster(OfficeYear)
ivreghdfe lp  (lt = shareHF) EarlyAgeM OfficeSize MShare, a(Year  ISOCode ) cluster(OfficeYear)

* rocco graphs 
* RM first managers on productivity 
reghdfe lp EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear) 
* RM second: stock of good managers on productivity, controlling for current quality
reghdfe lp l12.shareHF EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear) 
reghdfe lp l12.shareHF EarlyAgeM   OfficeSize  , a(Year  ISOCode ) cluster(OfficeYear) 
* RM third: stock of jobs, managers, 
reghdfe lp l12.TransferSJVC l12.shareHF EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear) 

* COLLAPSE AT FACTORY YEAR LEVEL 
collapse TotWorkers TotWorkersBC TotWorkersWC CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC  lcfr lcpc lchc shareHF* EarlyAge EarlyAgeM MShare TotBigC PC HC FR TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC TransferSJV TransferSJVC TransferSJC TransferSJLL TransferSJLLC PromWL PromWLC (sum) OfficeSizeWC=o OfficeSizeWL2 = MShare  ChangeSalaryGrade , by(OfficeCode Year ISOCode ) // stock*
egen OfficeYear= group(OfficeCode Year)

su EarlyAgeM,d 

* LOGS
egen CPT = rowmean(CPTFR CPTHC CPTPC )
gen lc = log(CPT)
gen lp=log( TonsperFTEMean) 
gen lpfr=log( TonsperFTEFR) 
gen lt = log(TransferSJC +1)
gen lv = log(TransferSJVC +1)
gen pp = log(PromWLC +1)
xtset OfficeCode Year
gen l1shareHF = l1.shareHF
/*
foreach var in stockTCHF stockLCHF stockVCHF stockHF  stockTHF stockLHF stockVHF shareHF{
forval i=0(1)7{
local y2021 = 2021 - `i'
local y2020 = 2020 - `i'
local y2019 = 2019 - `i'

gen `var'`i' = `var'`y2021' if Year==2021
replace `var'`i'  = `var'`y2020' if Year==2020
replace `var'`i'  = `var'`y2019' if Year==2019
}
}
*/

* PLOT: current managers 
eststo reg1: reghdfe lp  EarlyAgeM  TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear) // results unchanged by taking logs
local b = round(_b[EarlyAgeM ] , .01)
local se = round(_se[EarlyAgeM ] , .01)
local n = e(N)
di `n'
binscatter lp  EarlyAgeM, absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.4 "beta = `b'") text(5.3 0.4 "s.e.= `se'") text(5.25 0.4 "N= `n'") ///
xtitle("Share of high-flyers managers", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5.2(0.1)6) xlabel(0(0.1)0.5)
graph export "$analysis/Results/5.Mechanisms/HFTonsLogs.png", replace
graph save "$analysis/Results/5.Mechanisms/HFTonsLogs.gph", replace

* PLOT: CUMULATIVE EXPOSURE (t-1)
eststo reg2: reghdfe lp   shareHF   TotWorkersWC TotWorkersBC MShare, a(Year  ISOCode i.TotBigC) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ shareHF ] , .01)
local se = round(_se[ shareHF ] , .01)
local n = e(N)
di `n'
binscatter lp shareHF , absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.3 "beta = `b'") text(5.3 0.3 "s.e.= `se'") text(5.25 0.3 "N= `n'") ///
xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5.2(0.1)6) xlabel(0(0.1)0.35)
graph export "$analysis/Results/5.Mechanisms/HFTonsLogsCUM.png", replace
graph save "$analysis/Results/5.Mechanisms/HFTonsLogsCUM.gph", replace

* PLOT: CUMULATIVE EXPOSURE (t-1)
eststo reg2: reghdfe lcfr   shareHF   TotWorkersWC TotWorkersBC MShare EarlyAgeM, a(Year  ISOCode ) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ shareHF ] , .01)
local se = round(_se[ shareHF ] , .01)
local n = e(N)
di `n'
binscatter lcfr shareHF , absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare EarlyAgeM ) mcolor(ebblue) ///
lcolor(orange) text(6.3 0.25 "beta = `b'") text(6.25 0.25 "s.e.= `se'") text(6.20 0.25 "N= `n'") ///
xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ytitle("Cost per ton in logs (EUR)", size(medium))   ylabel(5.9(0.1)6.5) xlabel(0(0.1)0.35)
graph export "$analysis/Results/5.Mechanisms/HFCostLogsCUM.png", replace
graph save "$analysis/Results/5.Mechanisms/HFCostLogsCUM.gph", replace

* PLOT: transfers (t-1)
eststo reg3: reghdfe lp   lt   OfficeSizeWC MShare, a(Year  ISOCode ) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ lt ] , .01)
local se = round(_se[ lt ] , .01)
local n = e(N)
di `n'
binscatter lp lt , absorb(ISOCode) controls(i.Year OfficeSizeWC MShare ) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.4 "beta = `b'") text(5.3 0.4 "s.e.= `se'") text(5.25 0.4 "N= `n'") ///
xtitle("Num. lateral transfers in logs (cumulative up to t-1)", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5.2(0.1)6) xlabel(0(0.1)0.5)
graph export "$analysis/Results/5.Mechanisms/TonsLogsTr.png", replace
graph save "$analysis/Results/5.Mechanisms/TonsLogsTr.gph", replace

********************************************************************************
* FIGURE: COEFPLOT
********************************************************************************

coefplot    (reg2, keep(shareHF) ciopts(lwidth(2 ..) lcolor(ebblue)))  (reg3, keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))) (reg0, keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))), ///
title("", pos(12) span si(large))    levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(  reg2= "Share of high-flyers (cum. exposure)"  reg3 = "Num. lateral moves in logs"  reg0 = "Num. lateral moves in logs (IV, high-flyers)") ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-1 10)) xlabel(-1(2)10)   // reg1= "Share of high-flyers" (reg1,  keep(EarlyAgeM ) ciopts(lwidth(2 ..) lcolor(ebblue )))
graph export "$analysis/Results/6.Productivity/ProdCoefPlot.png", replace 
graph save "$analysis/Results/6.Productivity/ProdCoefPlot.gph", replace

* additional plots
* transfers rate 
reghdfe tt  EarlyAgeM  OfficeSizeWC MShare , a(Year  ISOCode ) cluster(OfficeYear) // results unchanged by taking logs
local b = round(_b[EarlyAgeM ] , .01)
local se = round(_se[EarlyAgeM ] , .01)
local n = e(N)
di `n'
binscatter tt  EarlyAgeM, absorb(ISOCode) controls(i.Year OfficeSizeWC MShare) mcolor(ebblue) ///
lcolor(orange) text(0.26 0.1 "beta = `b'") text(0.25 0.1 "s.e.= `se'") text(0.24 0.1 "N= `n'") ///
xtitle("Share of high-flyers managers", size(medium)) ytitle("Num. lateral moves in logs", size(medium))   ylabel(.22(0.02)0.32) xlabel(0(0.1)0.5)
graph export "$analysis/Results/5.Mechanisms/HFTTLogs.png", replace
graph save "$analysis/Results/5.Mechanisms/HFTTLogs.gph", replace

* promotions rate 
reghdfe pp  EarlyAgeM  OfficeSizeWC MShare , a(Year  ISOCode ) cluster(OfficeYear) // results unchanged by taking logs
local b = round(_b[EarlyAgeM ] , .01)
local se = round(_se[EarlyAgeM ] , .01)
local n = e(N)
di `n'
binscatter pp  EarlyAgeM, absorb(ISOCode) controls(i.Year OfficeSizeWC MShare) mcolor(ebblue) ///
lcolor(orange) text(0.05 0.4 "beta = `b'") text(0.047 0.4 "s.e.= `se'") text(0.044 0.4 "N= `n'") ///
xtitle("Share of high-flyers managers", size(medium)) ytitle("Num. vertical moves in logs", size(medium))   ylabel(.04(0.01)0.08) xlabel(0(0.1)0.5)
graph export "$analysis/Results/5.Mechanisms/HFPPLogs.png", replace
graph save "$analysis/Results/5.Mechanisms/HFPPLogs.gph", replace

* ROBUSTNESS: trimmed for outliers  
winsor2 TonsperFTEMean, cuts(0 99) trim suffix(T)
reghdfe TonsperFTEMeanT  EarlyAgeM  OfficeSizeWC MShare , a(Year  ISOCode ) cluster(OfficeYear) // results unchanged by taking the trimmed top 1% version

* indian dummy 
gen IND = 1 if ISOCode =="IND"
replace IND = 0 if IND==. & ISOCode!=""
reghdfe TonsperFTEMean  c.EarlyAgeM##IND  OfficeSizeWC MShare , a(Year  ISOCode ) cluster(OfficeYear) // no difference, interaction is small and not significant 

* LEVELS
reghdfe TonsperFTEMean  EarlyAgeM  OfficeSizeWC MShare , a(Year  ISOCode ) cluster(OfficeYear)
local b = round(_b[EarlyAgeM ] , 1)
local se = round(_se[EarlyAgeM ] , 1)
di `b' `se'
su  TonsperFTEMean if e(sample)==1
local mean = round(r(mean),1)
di 0.15*`b'/`mean' // 11 
di 0.2*`b'/`mean' // 15 
binscatter TonsperFTEMean  EarlyAgeM, absorb(ISOCode) controls(i.Year OfficeSizeWC MShare) mcolor(ebblue) ///
lcolor(orange) text(400 0.4 "beta = `b'") text(390 0.4 "s.e.= `se'") text(375 0.4 "y mean= `mean'") ///
xtitle("Share of high-flyers managers", size(medium)) ytitle("Output per worker", size(medium))  nquantiles(10) ylabel(280(50)480) xlabel(0(0.1)0.5)
*binscatter TonsperFTETotal  EarlyAgeM, absorb(ISOCode) controls(i.Year OfficeSizeWC MShare ) xtitle("Share of high-fliers managers") ytitle("Tons per FTE")
graph export "$analysis/Results/5.Mechanisms/HFTons.png", replace
graph save "$analysis/Results/5.Mechanisms/HFTons.gph", replace

hist EarlyAgeM ,  frac xtitle(Office share of high-flyer managers, size(medium)) ytitle(Fraction,size(medium) ) xlabel(0(0.1)1) width(0.02) ylabel(0(0.05)0.1)  // width(0.01)   
graph export "$analysis/Results/5.Mechanisms/HFShareOffice.png", replace

hist shareHF ,  frac xtitle(Cumulative exposure to high-flyer managers (site level), size(medium)) ytitle(Fraction,size(medium) )   // width(0.01)   
graph export "$analysis/Results/5.Mechanisms/HFShareOfficeCUM.png", replace

* LONG DIFFERENCE & plant FE
********************************************************************************

preserve 

*bys OfficeCode : egen minY = min(Year)
*bys OfficeCode: egen maxY = max(Year)

keep if Year == minY | Year == maxY
xtset OfficeCode Year 
gen delta = d.TonsperFTEMean
gen deltaHF = d.EarlyAgeM

*reghdfe delta    deltaHF  OfficeSizeWC MShare , a(Year  ISOCode ) cluster(OfficeYear)

reghdfe TonsperFTEMean    EarlyAgeM  OfficeSizeWC MShare , a(  Year OfficeCode ) cluster(OfficeYear)

restore 

* WORKERS and managers WAGE GAP (good vs bad managers): do High flyers earn more? 
********************************************************************************

* compare workers earnings and managers earnings

* Get dataset of managers and workers who are part of natural experiment
use "$Managersdta/SwitchersAllSameTeam2.dta", clear 
global Label FT
* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))
gen KEi = YearMonth - Ei 
keep if WL2==1
local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

bys IDlse: egen IDlseMHRTr = mean(cond(KEi==0,IDlseMHR,.))

keep if KEi == 12 | KEi==24 | KEi == 36 | KEi == 48 | KEi ==60  

compress 
save "$Managersdta/Temp/Outcomes5y.dta", replace

* save dataset of managers in the experiment 
use "$Managersdta/Temp/Outcomes5y.dta", clear 
keep IDlseMHRTr 
rename IDlseMHRTr IDlseMHR
duplicates drop IDlseMHR, force 
gen indMTr = 1
save "$Managersdta/Temp/TrMList.dta", replace 

* get manager wages 
use "$Managersdta/Temp/MType.dta", clear 
merge m:1 IDlseMHR using  "$Managersdta/Temp/TrMList.dta", keepusing(indMTr)
keep if _merge ==3 
drop _merge 

gen PayBonusM= exp(LogPayBonusM )-1

bys EarlyAgeM: su LogPayBonusM PayBonusM

* Do managers earn more? 
reghdfe LogPayBonusM EarlyAgeM , a(CountryM YearMonth) vce( cluster IDlseMHR)  // -4 
reghdfe PayBonusM EarlyAgeM , a(CountryM YearMonth) vce( cluster IDlseMHR)  //  1084.095  

reghdfe LogPayBonusM EarlyAgeM  c.TenureM##c.TenureM , a(CountryM YearMonth) vce( cluster IDlseMHR)  // 4.7
reghdfe PayBonusM EarlyAgeM  c.TenureM##c.TenureM , a(CountryM YearMonth) vce( cluster IDlseMHR)  // 4.7

* Additional work 
********************************************************************************

* Estimation 
use "$Managersdta/Temp/MType.dta", clear 
gen IDlseMHRTr = IDlseMHR
gen Ei = YearMonth 
gen PayBonusM  = exp(LogPayBonusM ) -1 
keep IDlseMHRTr Ei YearMonth PayBonusM MaxWLM MinWLM WLM TenureM CountryM FuncM AgeBandM FemaleM EarlyAgeM
save "$Managersdta/Temp/MTypeTr.dta", replace 

use "$Managersdta/Temp/Outcomes5y.dta", clear 

* merge managers at the time of transition 
drop MaxWLM MinWLM WLM TenureM CountryM FuncM AgeBandM FemaleM EarlyAgeM
merge m:1 IDlseMHRTr YearMonth using "$Managersdta/Temp/MTypeTr.dta" // IDlseMHRTr  Ei
drop if _merge==2 
bys IDlseMHRTr: egen YMMax = max(Ei)
egen mm = tag(IDlseMHRTr) if YMMax==Ei

*WORKERS until 5 years after the transition 
eststo clear 
forval i=12(12)60{
eststo W`i': reghdfe LogPayBonus FTLHB FTHLB FTHHB if KEi==`i' , a(YearMonth ISOCode Func  AgeBand##Female  ) cluster(IDlseMHRTr)
local b`i' = _b[ FTLHB]
count  if KEi ==`i' & FTLHB==1
local nb`i' = round(r(N),1)
su LogPayBonus if FTLLB==1 & KEi ==`i'
local y`i' = `b`i'' * `nb`i''*r(mean)
di as err "Year `i' total wage gap: " `y`i''

eststo lW`i': reghdfe LogPayBonus FTLHB FTHLB FTHHB if KEi==`i' , a(YearMonth ISOCode Func  AgeBand##Female  ) cluster(IDlseMHRTr)

} 
local s = round(`y12' + `y24' +  `y36' +  `y48' +  `y60' ,1)
di as err "Total WORKER wage gap: " `s' 
esttab W12 W24 W36 W48 W60,  star(* 0.10 ** 0.05 *** 0.01) keep(   FT* ) se label

* in Month 60 total wage gap:  619,272 

*MANAGERS until 5 years after the transition 
forval i=12(12)60{
eststo M`i': reghdfe LogPayBonusM FTLHB FTHLB FTHHB if KEi==`i' , a(YearMonth CountryM FuncM  AgeBandM##FemaleM  ) cluster(IDlseMHRTr)
local b`i' = _b[ FTLHB] // 
distinct IDlseMHRTr if  FTLHB ==1 & KEi==`i' // 2665 
local nb`i' = round( r(ndistinct),1)

su  PayBonusM if FTLLB==1 & KEi==`i'
local y`i' = `b`i'' * `nb`i''* `r(mean)'
di as err "Year `i' total wage gap: " `y`i''
eststo lM`i': reghdfe LogPayBonusM FTLHB FTHLB FTHHB if KEi==`i' , a(YearMonth CountryM FuncM  AgeBandM##FemaleM  ) cluster(IDlseMHRTr)

} 
local s = round(`y12' + `y24' +  `y36' +  `y48' +  `y60' ,1)
di as err "Total MANAGER wage gap: " `s' 
esttab M12 M24 M36 M48 M60,  star(* 0.10 ** 0.05 *** 0.01) keep(   FT* ) se label
esttab W12 W24 W36 W48 W60,  star(* 0.10 ** 0.05 *** 0.01) keep(   FT* ) se label

esttab lM12 lM24 lM36 lM48 lM60,  star(* 0.10 ** 0.05 *** 0.01) keep(   FT* ) se label
esttab lW12 lW24 lW36 lW48 lW60,  star(* 0.10 ** 0.05 *** 0.01) keep(   FT* ) se label

* CUTS
reghdfe PayBonusM EarlyAgeM if mm==1, a(Ei CountryM FuncM  AgeBandM##FemaleM   ) cluster(IDlseMHRTr)
local b = _b[EarlyAgeM]
distinct IDlseMHRTr if  FTLHB ==1 // 2665 
di "Total wage gap (high flyers managers): " r(ndistinct)* `b' // 151,300,000,000 [1.513e8]
 
reghdfe PayBonusM FTLHB FTHLB FTHHB if KEi==60, a(Ei CountryM FuncM  AgeBandM##FemaleM   ) cluster(IDlseMHRTr)
reghdfe MaxWLM EarlyAgeM if mm==1, a(Ei CountryM FuncM  AgeBandM##FemaleM ) cluster(IDlseMHRTr)
reghdfe WLM EarlyAgeM if mm==1, a(Ei CountryM FuncM  AgeBandM##FemaleM ) cluster(IDlseMHRTr)




