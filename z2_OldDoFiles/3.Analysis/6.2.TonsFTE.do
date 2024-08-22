********************************************************************************
* CORRELATIONS OF SHARE OF GOOD MANAGERS WITH SC productivity
* TONS PER FTE AND COST PER TON  
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

* divide lateral moves: initiated by HF or not
gen tHF  =.
replace  tHF  = TransferSJC if KEi>=0 & KEi <=60 & (FTLH!=. | FTHH!=. )
gen tLF  =.
replace tLF  = TransferSJC if KEi>=0 & KEi <=60 & (FTHL!=. | FTLL!=. )
gen tall  =TransferSJC
replace tall  = . if tHF!=.

* merge with productivity data: tons/FTE
merge m:1 OfficeCode Year using "$managersdta/TonsperFTEconservative.dta", keepusing(PC HC FR TotBigC  TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)
rename _merge mOutput
*keep if _merge==3
*merge m:1 OfficeCode Year using "$managersdta/TonsperFTEregular.dta", keepusing(PC HC FR TotBigC  TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC)

* merge with productivity data: cost/tons
*merge m:1 OfficeCode Year using "$managersdta/CPTwide.dta", keepusing(CPTMaxFR CPTMinFR CPTprevMaxFR CPTprevMinFR CPTChangeYoYMaxFR CPTChangeYoYMinFR EuroMaxFR EuroMinFR EuroprevMaxFR EuroprevMinFR VolMaxFR VolMinFR VolprevMaxFR VolprevMinFR CPTMaxHC CPTMinHC CPTprevMaxHC CPTprevMinHC CPTChangeYoYMaxHC CPTChangeYoYMinHC EuroMaxHC EuroMinHC EuroprevMaxHC EuroprevMinHC VolMaxHC VolMinHC VolprevMaxHC VolprevMinHC CPTMaxPC CPTMinPC CPTprevMaxPC CPTprevMinPC CPTChangeYoYMaxPC CPTChangeYoYMinPC EuroMaxPC EuroMinPC EuroprevMaxPC EuroprevMinPC VolMaxPC VolMinPC VolprevMaxPC VolprevMinPC )
merge m:1 OfficeCode Year using "$managersdta/CPTwideOld.dta", keepusing(CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC)

gen lcfr = log(CPTFR)
gen lchc = log(CPTHC)
gen lcpc = log(CPTPC)

gen lp=log( TonsperFTEMean)
gen lt=log( TransferSJVC+1) 
gen ltt=log( TransferSJC+1)  

gen llt=log( TransferSJLLC+1)  

egen OfficeYear= group(OfficeCode Year)

/********************************************************************************
* WORKER LEVEL regressions
********************************************************************************

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
********************************************************************************
* RM first managers on productivity 
reghdfe lp EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear) 
* RM second: stock of good managers on productivity, controlling for current quality
reghdfe lp l12.shareHF EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear) 
reghdfe lp l12.shareHF EarlyAgeM   OfficeSize  , a(Year  ISOCode ) cluster(OfficeYear) 
* RM third: stock of jobs, managers, 
reghdfe lp l12.TransferSJVC l12.shareHF EarlyAgeM   OfficeSize MShare , a(Year  ISOCode ) cluster(OfficeYear) 
*/
********************************************************************************
* COLLAPSE AT FACTORY YEAR LEVEL 
********************************************************************************

collapse tall tHF tLF TotWorkers TotWorkersBC TotWorkersWC CPTFR CPTHC CPTPC CPTChangeYoYFR CPTChangeYoYHC CPTChangeYoYPC  lcfr lcpc lchc shareHF* EarlyAge EarlyAgeM MShare TotBigC PC HC FR TonsperFTEMean TonsperFTETotal TonsperFTEFR TonsperFTEHC TonsperFTEPC TransferSJV TransferSJVC TransferSJC TransferSJLL TransferSJLLC PromWL PromWLC (sum) OfficeSizeWC=o OfficeSizeWL2 = MShare  ChangeSalaryGrade , by(OfficeCode Year ISOCode ) // stock*

* Gen variables 
egen OfficeYear= group(OfficeCode Year)
egen CPT = rowmean(CPTFR CPTHC CPTPC )
gen lc = log(CPT)
gen lp=log( TonsperFTEMean) 
gen lpfr=log( TonsperFTEFR) 
gen lt = log(TransferSJC +1)
gen ltHF = log(tHF +1)
gen ltLF = log(tLF +1)
gen atHF= asinh(tHF)
gen atLF= asinh(tLF)
gen lv = log(TransferSJVC +1)
gen pp = log(PromWLC +1)
xtset OfficeCode Year
gen l1shareHF = l1.shareHF

* higher mean and variance for moves induced by HF
su tLF tHF if lp!=.
su tLF tHF if lc!=.

*LATERAL MOVES CHECKS
********************************************************************************
 
*** MOVES INDUCED BY HF
reghdfe lp  ltHF TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 
local b = round(_b[ltHF ] , .01)
local se = round(_se[ltHF] , .01)
local n = e(N)
di `n'
binscatter lp ltHF, absorb( ISOCode) controls(Year  i.TotBigC  TotWorkersWC TotWorkersBC MShare)  mcolor(ebblue) ///
lcolor(orange) ytitle("Output per worker (in logs)", size(medium)) xtitle("Lateral moves after exposure to high-flyer manager (in logs)", size(medium)) text(5.8 1.1 "beta = `b'") text(5.75 1.1 "s.e.= `se'") xscale(range(0 1.2)) xlabel(0(0.1)1.2) //  text(5.25 .8 "N= `n'")
graph export "$analysis/Results/6.Productivity/TonsLogstHF.png", replace
graph save "$analysis/Results/6.Productivity/TonsLogstHF.gph", replace

* robustness with asinh
reghdfe lp  atHF TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 

* costs 
reghdfe lc  ltHF TotWorkersWC TotWorkersBC MShare if ltLF!=., a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 
local b = round(_b[ltHF ] , .01)
local se = round(_se[ltHF] , .01)
*count if lcfr !=. & ltLF!=. & ltLF!=.
*local n = r(N)
local n = e(N)
di `n'
binscatter lc ltHF if ltLF!=., absorb( ISOCode) controls(Year  i.TotBigC  TotWorkersWC TotWorkersBC MShare)  mcolor(ebblue) ///
lcolor(orange) ytitle("Cost per ton (in logs)", size(medium)) xtitle("Lateral moves after exposure to high-flyer manager (in logs)", size(medium)) text(5.5 1 "beta = `b'") text(5.45 1 "s.e.= `se'")  yscale(range(5.2 5.8)) xscale(range(0 1.2)) xlabel(0(0.1)1.2) // text(5.65 .9 "N= `n'")
graph export "$analysis/Results/6.Productivity/CostLogstHF.png", replace
graph save "$analysis/Results/6.Productivity/CostLogstHF.gph", replace

* robustness with asinh
reghdfe lc  atHF TotWorkersWC TotWorkersBC MShare if atLF!=., a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 

*** MOVES INDUCED BY LF
* output/worker
reghdfe lp  ltLF TotWorkersWC TotWorkersBC if ltHF!=., a(Year  ISOCode i.TotBigC) cluster(OfficeYear)
 local b = round(_b[ltLF ] , .01)
local se = round(_se[ltLF ] , .01)
local n = e(N)
di `n'
binscatter lp ltLF if ltHF!=., absorb( ISOCode) controls(Year  i.TotBigC TotWorkersWC TotWorkersBC )  mcolor(ebblue) lcolor(orange) ytitle("Output per worker (in logs)", size(medium)) xtitle("Lateral moves after exposure to low-flyer manager (in logs)", size(medium)) text(5.7 1 "beta = `b'") text(5.65 1 "s.e.= `se'")  xscale(range(0 1.2)) xlabel(0(0.1)1.2) // text(5.8 0.4 "N= `n'")
graph export "$analysis/Results/6.Productivity/TonsLogstLF.png", replace
graph save "$analysis/Results/6.Productivity/TonsLogstLF.gph", replace

* robustness with asinh
reghdfe lp  atLF TotWorkersWC TotWorkersBC MShare if atHF!=., a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 

* costs 
reghdfe lc  ltLF TotWorkersWC TotWorkersBC MShare if ltHF!=., a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 
local b = round(_b[ltLF ] , .01)
local se = round(_se[ltLF] , .01)
*count if lcfr !=. & ltLF!=. & ltLF!=.
*local n = r(N)
local n = e(N)
di `n'
binscatter lc ltLF if ltHF!=., absorb( ISOCode) controls(Year  i.TotBigC  TotWorkersWC TotWorkersBC MShare)  mcolor(ebblue) ///
lcolor(orange) ytitle("Cost per ton (in logs)", size(medium)) xtitle("Lateral moves after exposure to low-flyer manager (in logs)", size(medium)) text(5.75 1 "beta = `b'") text(5.7 1 "s.e.= `se'")  xscale(range(0 1.2)) xlabel(0(0.1)1.2) // text(5.65 1 "N= `n'")
graph export "$analysis/Results/6.Productivity/CostLogstLF.png", replace
graph save "$analysis/Results/6.Productivity/CostLogstLF.gph", replace

* robustness with asinh
reghdfe lc  atLF TotWorkersWC TotWorkersBC MShare if atHF!=., a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 

**# combine graphs (BOTH ON PAPER)
gr combine "$analysis/Results/6.Productivity/TonsLogstHF.gph" "$analysis/Results/6.Productivity/TonsLogstLF.gph", ycomm xcomm ysize(2.5) 
graph export "$analysis/Results/6.Productivity/TonsLogst.png", replace

gr combine "$analysis/Results/6.Productivity/CostLogstHF.gph" "$analysis/Results/6.Productivity/CostLogstLF.gph", ycomm xcomm ysize(2.5) 
graph export "$analysis/Results/6.Productivity/CostLogst.png", replace

* PLOT OUTPUT: current managers 
eststo reg1: reghdfe lp  EarlyAgeM  TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear) // results unchanged by taking logs
local b = round(_b[EarlyAgeM ] , .01)
local se = round(_se[EarlyAgeM ] , .01)
local n = e(N)
di `n'
binscatter lp  EarlyAgeM, absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.4 "beta = `b'") text(5.3 0.4 "s.e.= `se'") text(5.25 0.4 "N= `n'") ///
xtitle("Share of high-flyers managers", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5(0.1)6) xlabel(0(0.1)0.5)
graph export "$analysis/Results/6.Productivity/HFTonsLogs.png", replace
graph save "$analysis/Results/6.Productivity/HFTonsLogs.gph", replace

**# PLOT OUTPUT (ON PAPER): CUMULATIVE EXPOSURE (t-1) 
eststo reg2: reghdfe lp   shareHF   TotWorkersWC TotWorkersBC MShare, a(Year  ISOCode i.TotBigC) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ shareHF ] , .01)
local se = round(_se[ shareHF ] , .01)
local n = e(N)
di `n'
binscatter lp shareHF , absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.3 "beta = `b'") text(5.3 0.3 "s.e.= `se'") text(5.25 0.3 "N= `n'") ///
xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5.2(0.1)6) xlabel(0(0.1)0.35)
graph export "$analysis/Results/6.Productivity/HFTonsLogsCUM.png", replace
graph save "$analysis/Results/6.Productivity/HFTonsLogsCUM.gph", replace

**# PLOT COSTS (ON PAPER): CUMULATIVE EXPOSURE (t-1)
eststo reg2: reghdfe lcfr   shareHF   TotWorkersWC TotWorkersBC MShare EarlyAgeM, a(Year  ISOCode ) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ shareHF ] , .01)
local se = round(_se[ shareHF ] , .01)
local n = e(N)
di `n'
binscatter lcfr shareHF , absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare EarlyAgeM ) mcolor(ebblue) ///
lcolor(orange) text(6.3 0.25 "beta = `b'") text(6.25 0.25 "s.e.= `se'") text(6.20 0.25 "N= `n'") ///
xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ytitle("Cost per ton in logs (EUR)", size(medium))   ylabel(5.9(0.1)6.5) xlabel(0(0.1)0.35)
graph export "$analysis/Results/6.Productivity/HFCostLogsCUM.png", replace
graph save "$analysis/Results/6.Productivity/HFCostLogsCUM.gph", replace

* ROBUSTNESS: output per worker on same sites of cost per worker available
reghdfe lp   shareHF   TotWorkersWC TotWorkersBC MShare if lc!=., a(Year  ISOCode i.TotBigC ) cluster(OfficeYear)

* PLOT transfers: 
eststo reg3: reghdfe lp   lt   OfficeSizeWC MShare, a(Year  ISOCode ) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ lt ] , .01)
local se = round(_se[ lt ] , .01)
local n = e(N)
di `n'
binscatter lp lt , absorb(ISOCode) controls(i.Year OfficeSizeWC MShare ) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.4 "beta = `b'") text(5.3 0.4 "s.e.= `se'") text(5.25 0.4 "N= `n'") ///
xtitle("Num. lateral transfers in logs (cumulative up to t-1)", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5.2(0.1)6) xlabel(0(0.1)0.5)
graph export "$analysis/Results/6.Productivity/TonsLogsTr.png", replace
graph save "$analysis/Results/6.Productivity/TonsLogsTr.gph", replace

********************************************************************************
* MEDIATION EXERCISE - transfers explain btw 20% (output) - 30% (costs) of the variation 
********************************************************************************

reghdfe lp  shareHF  TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 
reghdfe lp  shareHF ltHF TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 
di 0.4/2 // 20% 
reghdfe lc  shareHF  TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 
reghdfe lc  shareHF ltHF TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear)
di  0.42/1.5 // 30% 

********************************************************************************
* FIGURE: COEFPLOT (IV)
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
graph export "$analysis/Results/6.Productivity/HFTTLogs.png", replace
graph save "$analysis/Results/6.Productivity/HFTTLogs.gph", replace

* promotions rate 
reghdfe pp  EarlyAgeM  OfficeSizeWC MShare , a(Year  ISOCode ) cluster(OfficeYear) // results unchanged by taking logs
local b = round(_b[EarlyAgeM ] , .01)
local se = round(_se[EarlyAgeM ] , .01)
local n = e(N)
di `n'
binscatter pp  EarlyAgeM, absorb(ISOCode) controls(i.Year OfficeSizeWC MShare) mcolor(ebblue) ///
lcolor(orange) text(0.05 0.4 "beta = `b'") text(0.047 0.4 "s.e.= `se'") text(0.044 0.4 "N= `n'") ///
xtitle("Share of high-flyers managers", size(medium)) ytitle("Num. vertical moves in logs", size(medium))   ylabel(.04(0.01)0.08) xlabel(0(0.1)0.5)
graph export "$analysis/Results/6.Productivity/HFPPLogs.png", replace
graph save "$analysis/Results/6.Productivity/HFPPLogs.gph", replace

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
graph export "$analysis/Results/6.Productivity/HFTons.png", replace
graph save "$analysis/Results/6.Productivity/HFTons.gph", replace

hist EarlyAgeM ,  frac xtitle(Office share of high-flyer managers, size(medium)) ytitle(Fraction,size(medium) ) xlabel(0(0.1)1) width(0.02) ylabel(0(0.05)0.1)  // width(0.01)   
graph export "$analysis/Results/6.Productivity/HFShareOffice.png", replace

hist shareHF ,  frac xtitle(Cumulative exposure to high-flyer managers (site level), size(medium)) ytitle(Fraction,size(medium) )   // width(0.01)   
graph export "$analysis/Results/6.Productivity/HFShareOfficeCUM.png", replace

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
use "$managersdta/SwitchersAllSameTeam2.dta", clear 
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
save "$managersdta/Temp/Outcomes5y.dta", replace

* save dataset of managers in the experiment 
use "$managersdta/Temp/Outcomes5y.dta", clear 
keep IDlseMHRTr 
rename IDlseMHRTr IDlseMHR
duplicates drop IDlseMHR, force 
gen indMTr = 1
save "$managersdta/Temp/TrMList.dta", replace 

* get manager wages 
use "$managersdta/Temp/MType.dta", clear 
merge m:1 IDlseMHR using  "$managersdta/Temp/TrMList.dta", keepusing(indMTr)
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
use "$managersdta/Temp/MType.dta", clear 
gen IDlseMHRTr = IDlseMHR
gen Ei = YearMonth 
gen PayBonusM  = exp(LogPayBonusM ) -1 
keep IDlseMHRTr Ei YearMonth PayBonusM MaxWLM MinWLM WLM TenureM CountryM FuncM AgeBandM FemaleM EarlyAgeM
save "$managersdta/Temp/MTypeTr.dta", replace 

use "$managersdta/Temp/Outcomes5y.dta", clear 

* merge managers at the time of transition 
drop MaxWLM MinWLM WLM TenureM CountryM FuncM AgeBandM FemaleM EarlyAgeM
merge m:1 IDlseMHRTr YearMonth using "$managersdta/Temp/MTypeTr.dta" // IDlseMHRTr  Ei
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




