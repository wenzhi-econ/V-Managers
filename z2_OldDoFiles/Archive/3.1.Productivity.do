********************************************************************************
* SALES PRODUCTIVITY
********************************************************************************

********************************************************************************
* Gaining vs losing manager with employee ID fe
********************************************************************************

/* SAVING FILE TEMPORARILY FOR MARCO TO RUN, BUT NOTE RESULTS ARE OFF 
use "$managersdta/AllSameTeam.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )

keep if _merge ==3 
compress 
save "$managersdta/Temp/ProductivityManagersTemp.dta", replace 
*/

use "$managersdta/AllSameTeam.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )

gen Post = KEi >=0 if KEi!=.

* Delta of managerial talent 
foreach var in  EarlyAgeM  { // MFEBayesPromSG50 MFEBayesPromSG75 MFEBayesPromSG 
cap drop diffM Deltatag  DeltaM
xtset IDlse YearMonth 
gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag) 
gen Post`var' = Post*DeltaM
}

* gen variables 
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 
gen lt = log(TransferSJC+ 1)
*gen llt = log(TransferSJLLC+ 1)
*gen vt = log(TransferSJVC+ 1)

* how many workers
distinct IDlse if lp!=. & ISOCode == "IND"  //  3330
distinct IDlse if lp!=. & ISOCode == "IND" & KEi!=.  //   2541

************************************************************************
* FIGUREs in paper 
************************************************************************

* FIG1: gaining HF
************************************************************************

eststo clear 
eststo r1: reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth  )
*eststo r1: reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017, cluster(IDlseMHR) a( IDlse StandardJob YearMonth  ) // with Job FE Gharad check
eststo r2: reghdfe LogPayBonus  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=.& Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // wages are increasingly muchs less than proportionally 
eststo r3: reghdfe lt  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // first stage (in loges to homogenize figure labels)
eststo r4: reghdfe TransferSJC  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // first stage 

* robustness 
reghdfe lp  FTLHPost  FTLLPost FTHLPost FTHHPost   if   ISOCode =="IND"  & (KEi<=-1 | KEi>=24),  a( IDlse YearMonth  )
lincom    FTLHPost  -    FTLLPost

* baseline mean 
su TransferSJC Productivity PayBonus if ISOCode =="IND" & lp!=. & FTLL!=.
di 9800.484*0.42 // magnitudes reported in paper 

/*
**# ON PAPER FIGURE: ProdPlotLHE.png
coefplot (r1,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) (r3,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(95) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1= "Sales bonus (in logs, INR)"  r2= "Pay (in logs, EUR)"  r3= "Lateral moves (in logs)" ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xtitle("% change")   xscale(range(0 50)) xlabel(0(10)50) title("Gaining a high-flyer manager", size(medium))
 *title("Past exposure to high-flyer")  
graph export "$analysis/Results/0.Paper/3.1.Productivity/ProdPlotLH.pdf", replace 
graph save "$analysis/Results/0.Paper/3.1.Productivity/ProdPlotLH.gph", replace
*/

************************************************************************
* Mediation exercise 
************************************************************************

reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth  ) // alpha1
local alpha1 = _b[ PostEarlyAgeM]
reghdfe lt  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // theta 
local theta = _b[ PostEarlyAgeM]
reghdfe lp lt  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // beta 
local beta = _b[ lt ]

di `beta'*`theta'/`alpha1' // 44%

* losing a high flyer // BUT VERY FEW OBSERVATIONS 
********************************************************************************
eststo r1b: reghdfe lp  PostEarlyAgeM    if  (FTHL!=. | FTHH !=.) & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth  )
eststo r2b: reghdfe LogPayBonus  PostEarlyAgeM    if   (FTHL!=. | FTHH !=.)  & ISOCode =="IND" & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth )
eststo r3b: reghdfe lt  PostEarlyAgeM    if   (FTHL!=. | FTHH !=.)  & ISOCode =="IND"  & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth) // first stage
* baseline mean 
su TransferSJC Productivity PayBonus if ISOCode =="IND" & lp!=. & FTHH!=.

* FIG2: Moves under a high flyer vs low flyer 
********************************************************************************

bys IDlse : egen t1to5p = max(cond(KEi>0 & KEi<=60 &lp!=.,TransferSJ ,.))
bys IDlse : egen t1to3p = max(cond(KEi>0 & KEi<=36 &lp!=.,TransferSJ ,.))
bys IDlse : egen t1to2p = max(cond(KEi>0 & KEi<=24&lp!=.,TransferSJ ,.))

ta t1to5p // 40% people move 
eststo clear 
* People who change  - post productivity 
eststo r1: reghdfe lp  PostEarlyAgeM Post    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a( IDlse YearMonth  )

eststo r1b: reghdfe lp  FTLHPost  FTLLPost    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a( IDlse YearMonth  )
lincom    FTLHPost  -    FTLLPost

eststo r1c: reghdfe lp  PostEarlyAgeM Post    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==0, cluster(IDlseMHR) a( IDlse YearMonth  )

* People who do not change  - pre productivity 
gen HFpre = 1 if FTLH !=.
replace HFpre = 0 if FTLL !=.
eststo r2: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & Year>2017 & t1to5p==0, cluster(IDlseMHR) a(  YearMonth  )
eststo r2b: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & t1to5p==0, cluster(IDlseMHR) a(  YearMonth  )

* People who change  - pre productivity 
eststo r3: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a(  YearMonth  )
eststo r3b: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & t1to5p==1, cluster(IDlseMHR) a(  YearMonth  )

/*
**# ON PAPER FIGURE: ProdMoversE.png
coefplot (r1,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2b,  rescale(100) keep(HFpre) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM HFpre )  levels(95) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1= "Movers, post manager transition"  r2b= "Non-movers, pre manager transition"  ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xtitle("% change")   xscale(range(0 100)) xlabel(0(10)100) title("Gaining a high-flyer manager, sales bonus", size(medium)) 
 *title("Past exposure to high-flyer")  
graph export "$analysis/Results/0.Paper/3.1.Productivity/ProdMovers.pdf", replace 
graph save "$analysis/Results/0.Paper/3.1.Productivity/ProdMovers.gph", replace
*note("First row is the impact of gaining a high-flyer manager on sales bonus  conditional on making a lateral move." "Second row is the differential sales bonus before gaining a high-flyer manager conditional on not making a lateral move after the manager transition.")
*/

* TABLE: difference high flyer vs low flyer 
********************************************************************************

eststo clear 

eststo r1: reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth  )
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)
eststo r2: reghdfe LogPayBonus  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=.& Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) 
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)
eststo r3: reghdfe TransferSJC  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth )
qui sum `e(depvar)' if e(sample) 
estadd scalar Mean = r(mean)
eststo r1b: reghdfe lp  PostEarlyAgeM Post    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a( IDlse YearMonth  )
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)
eststo r2b: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & t1to5p==0, cluster(IDlseMHR) a(  YearMonth  )
qui sum `e(depvar)' if e(sample)
estadd scalar Mean = r(mean)

label var PostEarlyAgeM "High-flyer manager"
**# ON PAPER: "ProdOLS.tex"
esttab r1 r2 r3 r1b r2b using "$analysis/Results/0.Paper/3.1.Productivity/ProdOLS.tex", replace ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(Mean N r2, fmt(3 0 4) labels("Mean" "Observations" "R-squared")) ///
label nonotes collabels(none) ///
mtitles("Sales bonus (in logs, INR)" "Pay (in logs, EUR)" "Lateral moves" "Movers, post" "Non-movers, pre") ///
drop(_cons Post) rename( HFpre PostEarlyAgeM ) ///
postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Estimates obtained by running the model in equation \ref{eq:sales}. The sales bonus is measured in Indian Rupees (outcome mean under a low-flyer manager = INR 9,800); pay is measured in euros (outcome mean under a low-flyer manager =EUR 10,600). Column 4 looks at the the impact of gaining a high-flyer manager on sales bonus for workers that make at least one lateral move after the manager transition (up to five years after). Column 5 looks at the impact of gaining a high-flyer manager on sales bonus before a manager ransition for the workers that do not make a job move after the manager transition. Controls in columns 1-4 include: worker FE and year-month FE. In column 5, there are only the year-month FE as controls.  ///
"\end{tablenotes}")

**#ON SLIDES: with shorter tables notes 
esttab r1 r2 r3 r1b r2b using "$analysis/Results/0.Paper/3.1.Productivity/ProdOLSShort.tex", replace ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(Mean N r2, fmt(3 0 4) labels("Mean" "Observations" "R-squared")) ///
label nonotes collabels(none) ///
mtitles("Sales bonus (in logs, INR)" "Pay (in logs, EUR)" "Lateral moves" "Movers, post" "Non-movers, pre") ///
drop(_cons Post) rename( HFpre PostEarlyAgeM ) ///
postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-year-month. Standard errors are clustered by manager. ///
"\end{tablenotes}")



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
graph export "$analysis/Results/6.Productivity/TonsLogstHF.pdf", replace
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
graph export "$analysis/Results/6.Productivity/CostLogstHF.pdf", replace
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
graph export "$analysis/Results/6.Productivity/TonsLogstLF.pdf", replace
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
graph export "$analysis/Results/6.Productivity/CostLogstLF.pdf", replace
graph save "$analysis/Results/6.Productivity/CostLogstLF.gph", replace

* robustness with asinh
reghdfe lc  atLF TotWorkersWC TotWorkersBC MShare if atHF!=., a(Year  ISOCode i.TotBigC) cluster(OfficeYear) 

**# ON PAPER FIGURE: TonsLogst.png 
gr combine "$analysis/Results/6.Productivity/TonsLogstHF.gph" "$analysis/Results/6.Productivity/TonsLogstLF.gph", ycomm xcomm ysize(2.5) 
graph export "$analysis/Results/0.Paper/3.1.Productivity/TonsLogst.pdf", replace

**# ON PAPER FIGURE: CostLogst.png
gr combine "$analysis/Results/6.Productivity/CostLogstHF.gph" "$analysis/Results/6.Productivity/CostLogstLF.gph", ycomm xcomm ysize(2.5) 
graph export "$analysis/Results/0.Paper/3.1.Productivity/CostLogst.pdf", replace

/* PLOT OUTPUT: current managers 
eststo reg1: reghdfe lp  EarlyAgeM  TotWorkersWC TotWorkersBC MShare , a(Year  ISOCode i.TotBigC) cluster(OfficeYear) // results unchanged by taking logs
local b = round(_b[EarlyAgeM ] , .01)
local se = round(_se[EarlyAgeM ] , .01)
local n = e(N)
di `n'
binscatter lp  EarlyAgeM, absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.4 "beta = `b'") text(5.3 0.4 "s.e.= `se'") text(5.25 0.4 "N= `n'") ///
xtitle("Share of high-flyers managers", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5(0.1)6) xlabel(0(0.1)0.5)
graph export "$analysis/Results/6.Productivity/HFTonsLogs.pdf", replace
graph save "$analysis/Results/6.Productivity/HFTonsLogs.gph", replace
*/

**# ON PAPER FIGURE: HFTonsLogsCUM.png 
* CUMULATIVE EXPOSURE (t-1) 
eststo reg2: reghdfe lp   shareHF   TotWorkersWC TotWorkersBC MShare, a(Year  ISOCode i.TotBigC) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ shareHF ] , .01)
local se = round(_se[ shareHF ] , .01)
local n = e(N)
di `n'
binscatter lp shareHF , absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare i.TotBigC) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.3 "beta = `b'") text(5.3 0.3 "s.e.= `se'") text(5.25 0.3 "N= `n'") ///
xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5.2(0.1)6) xlabel(0(0.1)0.35)
graph export "$analysis/Results/0.Paper/3.1.Productivity/HFTonsLogsCUM.pdf", replace
graph save "$analysis/Results/0.Paper/3.1.Productivity/HFTonsLogsCUM.gph", replace

**# ON PAPER FIGURE: HFCostLogsCUM.png
* CUMULATIVE EXPOSURE (t-1)
eststo reg2: reghdfe lcfr   shareHF   TotWorkersWC TotWorkersBC MShare EarlyAgeM, a(Year  ISOCode ) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ shareHF ] , .01)
local se = round(_se[ shareHF ] , .01)
local n = e(N)
di `n'
binscatter lcfr shareHF , absorb(ISOCode) controls(i.Year TotWorkersWC TotWorkersBC MShare EarlyAgeM ) mcolor(ebblue) ///
lcolor(orange) text(6.3 0.25 "beta = `b'") text(6.25 0.25 "s.e.= `se'") text(6.20 0.25 "N= `n'") ///
xtitle("Exposure to high-flyers managers (cumulative up to t-1)", size(medium)) ytitle("Cost per ton in logs (EUR)", size(medium))   ylabel(5.9(0.1)6.5) xlabel(0(0.1)0.35)
graph export "$analysis/Results/0.Paper/3.1.Productivity/HFCostLogsCUM.pdf", replace
graph save "$analysis/Results/0.Paper/3.1.Productivity/HFCostLogsCUM.gph", replace

* ROBUSTNESS: output per worker on same sites of cost per worker available
reghdfe lp   shareHF   TotWorkersWC TotWorkersBC MShare if lc!=., a(Year  ISOCode i.TotBigC ) cluster(OfficeYear)

/* PLOT transfers: 
eststo reg3: reghdfe lp   lt   OfficeSizeWC MShare, a(Year  ISOCode ) cluster(OfficeYear) // stockHF1 results unchanged by taking logs
local b = round(_b[ lt ] , .01)
local se = round(_se[ lt ] , .01)
local n = e(N)
di `n'
binscatter lp lt , absorb(ISOCode) controls(i.Year OfficeSizeWC MShare ) mcolor(ebblue) ///
lcolor(orange) text(5.35 0.4 "beta = `b'") text(5.3 0.4 "s.e.= `se'") text(5.25 0.4 "N= `n'") ///
xtitle("Num. lateral transfers in logs (cumulative up to t-1)", size(medium)) ytitle("Output per worker in logs", size(medium))   ylabel(5.2(0.1)6) xlabel(0(0.1)0.5)
graph export "$analysis/Results/6.Productivity/TonsLogsTr.pdf", replace
graph save "$analysis/Results/6.Productivity/TonsLogsTr.gph", replace
*/
