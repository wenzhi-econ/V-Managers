********************************************************************************
* LATERAL MOVES: ARE THEY INCREASING PRODUCTIVITY 
********************************************************************************

* Compare moves under a good manager and all the rest 
* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

use "$managersdta/AllSameTeam2.dta", clear 
*use "$managersdta/AllSameTeam2.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity) // add productivity with mediation 

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

* Delta of managerial talent
gen Post = KEi >=0 if KEi!=.
 
foreach var in  EarlyAgeM  { // MFEBayesPromSG50 MFEBayesPromSG75 MFEBayesPromSG 
cap drop diffM Deltatag  DeltaM
xtset IDlse YearMonth 
gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag) 
gen Post`var' = Post*DeltaM
}

*keep if Ei!=. 
gen KEi  = YearMonth - Ei 

keep if Ei!=. 

* gen variables 
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 
gen lt = log(TransferSJC+ 1)

* FIG1: OLS gaining 
eststo clear 
eststo r1: reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth  )
eststo r2: reghdfe LogPayBonus  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=.& Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // wages are increasingly muchs less than proportionally 
eststo r3: reghdfe lt  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // first stage 

* baseline mean 
su TransferSJC Productivity PayBonus if ISOCode =="IND" & lp!=. & FTLL!=.
di 9800.484*0.42 // magnitudes reported in paper 

coefplot (r1, keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2,   keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) (r3,  keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1= "Productivity (sales in logs, INR)"  r2= "Pay (in logs, EUR)"  r3= "Lateral moves (in logs)" ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xtitle("% change")   xscale(range(0 1)) xlabel(0(.1)1) title("Gaining a high-flyer manager", size(medium))
 *title("Past exposure to high-flyer")  
graph export "$analysis/Results/6.Productivity/ProdPlotLH2.png", replace 
graph save "$analysis/Results/6.Productivity/ProdPlotLH2.gph", replace

* FIG2: separate individuals who transfer / and do not transfer 
bys IDlse : egen tall = max(cond(KEi>0,TransferSJ ,.))
bys IDlse : egen t1to5 = max(cond(KEi>0 & KEi<=60,TransferSJ ,.))
bys IDlse : egen t1to3 = max(cond(KEi>0 & KEi<=36,TransferSJ ,.))
bys IDlse : egen t1to2 = max(cond(KEi>0 & KEi<=24,TransferSJ ,.))

bys IDlse : egen t1to5p = max(cond(KEi>0 & KEi<=60 &lp!=.,TransferSJ ,.))
bys IDlse : egen t1to3p = max(cond(KEi>0 & KEi<=36 &lp!=.,TransferSJ ,.))
bys IDlse : egen t1to2p = max(cond(KEi>0 & KEi<=24&lp!=.,TransferSJ ,.))

eststo clear 
* People who change  - post productivity 
eststo r1: reghdfe lp  PostEarlyAgeM Post    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a( IDlse YearMonth  )
eststo r1b: reghdfe lp  FTLHPost  FTLLPost    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=.  & Year>2017 & t1to5p==1, cluster(IDlseMHR) a( IDlse YearMonth  )
lincom    FTLHPost  -    FTLLPost
* People who do not change  - pre productivity 
gen HFpre = 1 if FTLH !=.
replace HFpre = 0 if FTLL !=.
eststo r2: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & Year>2017 & t1to5p==0, cluster(IDlseMHR) a(  YearMonth  )
eststo r2b: reghdfe lp   HFpre  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & KEi<0 & lp!=.  & t1to5p==0, cluster(IDlseMHR) a(  YearMonth  )

**# ON PAPER
coefplot (r1,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2b,  rescale(100) keep(HFpre) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM HFpre )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1= "Movers, post-productivity"  r2b= "Non-movers, pre-productivity"  ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xtitle("% change")   xscale(range(0 100)) xlabel(0(10)100) title("Gaining a high-flyer manager", size(medium))
 *title("Past exposure to high-flyer")  
graph export "$analysis/Results/6.Productivity/ProdMovers.png", replace 
graph save "$analysis/Results/6.Productivity/ProdMovers.gph", replace
