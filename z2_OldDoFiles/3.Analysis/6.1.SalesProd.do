********************************************************************************
* SALES PRODUCTIVITY
********************************************************************************

********************************************************************************
* Gaining vs losing manager with employee ID fe
********************************************************************************

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
eststo r3: reghdfe lt  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=. & Year>2017, cluster(IDlseMHR) a( IDlse YearMonth ) // first stage 

* robustness 
reghdfe lp  FTLHPost  FTLLPost FTHLPost FTHHPost   if   ISOCode =="IND"  & (KEi<=-1 | KEi>=24),  a( IDlse YearMonth  )
lincom    FTLHPost  -    FTLLPost

* baseline mean 
su TransferSJC Productivity PayBonus if ISOCode =="IND" & lp!=. & FTLL!=.
di 9800.484*0.42 // magnitudes reported in paper 

**# ON PAPER
coefplot (r1,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) (r3,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1= "Sales bonus (in logs, INR)"  r2= "Pay (in logs, EUR)"  r3= "Lateral moves (in logs)" ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xtitle("% change")   xscale(range(0 50)) xlabel(0(10)50) title("Gaining a high-flyer manager", size(medium))
 *title("Past exposure to high-flyer")  
graph export "$analysis/Results/6.Productivity/ProdPlotLH.png", replace 
graph save "$analysis/Results/6.Productivity/ProdPlotLH.gph", replace

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

**# ON PAPER
coefplot (r1,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2b,  rescale(100) keep(HFpre) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM HFpre )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1= "Movers, post manager transition"  r2b= "Non-movers, pre manager transition"  ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xtitle("% change")   xscale(range(0 100)) xlabel(0(10)100) title("Gaining a high-flyer manager, sales bonus", size(medium)) 
 *title("Past exposure to high-flyer")  
graph export "$analysis/Results/6.Productivity/ProdMovers.png", replace 
graph save "$analysis/Results/6.Productivity/ProdMovers.gph", replace
*note("First row is the impact of gaining a high-flyer manager on sales bonus  conditional on making a lateral move." "Second row is the differential sales bonus before gaining a high-flyer manager conditional on not making a lateral move after the manager transition.")
/* FIG2: OLS losing a high flyer manager 
coefplot (r1b,   keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue )))  (r2b,   keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) (r3b,   keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1b= "Productivity (sales in logs, INR)"  r2b= "Pay (in logs, EUR)"  r3b= "Lateral moves (in logs)" ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) title("Losing a high-flyer manager", size(medium))
 *title("RHS: low to high-flyer manager transition", size(medium))
 *title("Past exposure to high-flyer")  xtitle("% change")   xscale(range(-20 20)) xlabel(-20(10)20) 
graph export "$analysis/Results/6.Productivity/ProdPlotHL.png", replace 
graph save "$analysis/Results/6.Productivity/ProdPlotHL.gph", replace

* FIG3: IV
eststo r4: ivreghdfe lp  (lt = PostEarlyAgeM)    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=., cluster(IDlseMHR) a( IDlse YearMonth  ) first
eststo r4ols: reghdfe lp  lt  if  ISOCode =="IND" & lp!=. , cluster(IDlseMHR) a(  YearMonth  )
eststo r5: ivreghdfe LogPayBonus  (lt = PostEarlyAgeM)    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND" & lp!=., cluster(IDlseMHR) a( IDlse YearMonth  ) first
eststo r5ols: reghdfe LogPayBonus  lt  if  ISOCode =="IND" & lp!=. , cluster(IDlseMHR) a(  YearMonth  )

coefplot (r4ols,  keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue)))   (r4,  keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))) (r5ols,   keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))) (r5,   keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r4ols= "Lateral move on productivity (OLS)"  r4= "Lateral move on productivity (IV, gain high-flyer)" r5ols= "Lateral move on pay (OLS)"  r5= "Lateral move on pay (IV, gain high-flyer)"  ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-1 12)) xlabel(-1(1)12) xtitle("% change")
 *title("Productivity (sales in logs, INR)", size(medium))
graph export "$analysis/Results/6.Productivity/ProdPlotIV.png", replace 
graph save "$analysis/Results/6.Productivity/ProdPlotIV.gph", replace

coefplot (r4ols,  keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue)))  (r5ols,   keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r4ols= "Lateral move on productivity (OLS)"  r5ols= "Lateral move on pay (OLS)"   ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(0 1)) xlabel(0(0.1)1) xtitle("% change") title("OLS")
graph save "$analysis/Results/6.Productivity/ProdPlotIVols.gph", replace
graph export "$analysis/Results/6.Productivity/ProdPlotIVols.png", replace 

coefplot    (r4,  keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue)))  (r5,   keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))) , ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(  r4= "Lateral move on productivity (IV, gain high-flyer)" r5= "Lateral move on pay (IV, gain high-flyer)"  ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-1 12)) xlabel(-1(1)12) xtitle("% change") title("IV")
 *title("Productivity (sales in logs, INR)", size(medium))
graph save "$analysis/Results/6.Productivity/ProdPlotIV1.gph", replace
graph export "$analysis/Results/6.Productivity/ProdPlotIV1.png", replace

gr combine "$analysis/Results/6.Productivity/ProdPlotIVols.gph" "$analysis/Results/6.Productivity/ProdPlotIV1.gph", cols(1)
graph export "$analysis/Results/6.Productivity/ProdPlotIV1.png", replace 



coefplot (r1,  rescale(100) keep(PostEarlyAgeM) ciopts(lwidth(2 ..) lcolor(ebblue ))) (r4b,  keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue)))   (r4,   keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))), ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r1="Gain high-flyer" r4b = "Lateral move" r4= "Lateral move (IV, gain high-flyer)" ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash))   xscale(range(0 50)) xlabel(0(5)50) xtitle("% change")
*title("RHS: Lateral move instrumented with high-flyer manager transition", size(medium)) 
graph export "$analysis/Results/6.Productivity/ProdPlotIV2.png", replace 
graph save "$analysis/Results/6.Productivity/ProdPlotIV2.gph", replace

/* other regressions 

coefplot  (r4,  keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))) (r4ols,  keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue)))   (r5,   keep(lt) ciopts(lwidth(2 ..) lcolor(ebblue))), ///
title("", pos(12) span si(large))  keep(PostEarlyAgeM lt )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r4= "Productivity (sales in logs, INR)"  r5= "Pay (in logs, EUR)"  ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash))   title("RHS: Lateral move instrumented with high-flyer manager transition", size(medium)) xscale(range(0 12)) xlabel(0(2)12) xtitle("% change")
graph export "$analysis/Results/6.Productivity/ProdPlotIV.png", replace 
graph save "$analysis/Results/6.Productivity/ProdPlotIV.gph", replace

gen  PostEarlyAgeM1= PostEarlyAgeM
gen TenureM2 = TenureM*TenureM

global lcontrol AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM Female##AgeBand
global control AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM

* OLS no fe
eststo clear 
eststo: reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND", cluster(IDlseMHR) a( $control  )
eststo: reghdfe lp  PostEarlyAgeM1    if   (FTHL!=. | FTHH !=.)   & ISOCode =="IND", cluster(IDlseMHR) a($control  )
eststo: reghdfe LogPayBonus  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=., cluster(IDlseMHR) a( $control  )
eststo: reghdfe  LogPayBonus  PostEarlyAgeM1    if   (FTHL!=. | FTHH !=.) & ISOCode =="IND" & lp!=., cluster(IDlseMHR) a($control  )
esttab , star(* 0.10 ** 0.05 *** 0.01) keep(   PostEarlyAgeM PostEarlyAgeM1 ) se label

esttab using "$analysis/Results/6.Productivity/TalentMProdGain.tex", label star(* 0.10 ** 0.05 *** 0.01) keep( PostEarlyAgeM PostEarlyAgeM1) se r2 ///
s(  N r2, labels( "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales in logs)" "Pay (in logs)", pattern(1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: country and year FE, worker tenure squared interacted with gender.  ///
"\end{tablenotes}") replace

eststo: reghdfe lp  PostEarlyAgeM1    if   (FTHL!=. | FTHH !=.)   & ISOCode =="IND", cluster(IDlseMHR) a(IDlse YearMonth  )
eststo: reghdfe  LogPayBonus  PostEarlyAgeM1    if   (FTHL!=. | FTHH !=.) & ISOCode =="IND" & lp!=., cluster(IDlseMHR) a(IDlse YearMonth  )
esttab , star(* 0.10 ** 0.05 *** 0.01) keep(   PostEarlyAgeM PostEarlyAgeM1 ) se label

* IV + fe
reghdfe lp  lt  if  (FTLH!=. | FTLL !=.) & ISOCode =="IND", cluster(IDlseMHR) a(  IDlse YearMonth  ) // OLS
eststo clear 
eststo: ivreghdfe lp  (lt = PostEarlyAgeM)    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND", cluster(IDlseMHR) a( $control  ) first
eststo: ivreghdfe LogPayBonus  (lt = PostEarlyAgeM)    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=., cluster(IDlseMHR) a( $control  ) first
esttab , star(* 0.10 ** 0.05 *** 0.01) keep(   lt ) se label
*/
*/

* Check sample selection - other outcomes on indian population 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 

gen Post = KEi >=0 if KEi!=.

gen TenureM2 = TenureM*TenureM

eststo:reghdfe LogPayBonus  EarlyAgeM  if ISOCode =="IND" & WLM>1 & Func==3 & WL==1, cluster(IDlseMHR) a( $lcontrol )
eststo:reghdfe LogPayBonus  EarlyAgeM  if ISOCode =="IND" & WLM>1 & Func==3 & WL==1 & Post!=., cluster(IDlseMHR) a( $lcontrol )
eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND"& Post!=. , cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "\multicolumn{1}{c}{Yes}"

********************************************************************************
* All sample 
********************************************************************************

* SET UP
use "$managersdta/AllSnapshotMCulture.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
*drop if _merge ==2 
keep if _merge ==3 
drop _merge 

xtset IDlse YearMonth  

* merge with the events 
merge m:1 IDlseMHR YearMonth using  "$managersdta/Temp/ListEventsTeam"
drop if _merge ==2
drop _merge 

* merge with manager type 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50   MFEBayesLogPayF6075   MFEBayesLogPayF6050   MFEBayesLogPayF7275   MFEBayesLogPayF7250)
drop if _merge ==2
drop _merge 

* For Sun & Abraham only consider first event 
********************************************************************************

rename Ei EiAll
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1
replace ChangeMR = 0 if ChangeMR==. 
replace IDlseMHRPreMost = . if ChangeMR== 0 
format Ei %tm 

gen KEi  = YearMonth - Ei
*keep if KEi!=. 

gen Post = KEi >=0 if KEi!=.

* Delta of managerial talent 
foreach var in MFEBayesPromSG50 EarlyAgeM MFEBayesPromSG75 MFEBayesPromSG {
cap drop diffM Deltatag  DeltaM
xtset IDlse YearMonth 
gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag) 
gen Post`var' = Post*DeltaM
}

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse IDlseMHR   // alternative, to try 
global exitFE CountryYear AgeBand AgeBandM Func Female
global lcontrol AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM Female##AgeBand
global control AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM

gen Tenure2 = Tenure*Tenure
gen TenureM2 = TenureM*TenureM
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 
su Productivity if ISOCode =="IND"

label var MFEBayesPromSG75 "High Prom. Manager, p75"
label var EarlyAgeM "High Flyer Manager" 

* how many workers
distinct IDlse if lp!=. & ISOCode == "IND"  & Post==1 //  1815

* FINAL TABLE with prod. in logs & wages (in the PAPER)
*******************************

reghdfe f24.lp EarlyAgeM  if ISOCode =="IND"  & Post==1  , cluster(IDlseMHR) a( $lcontrol )
reghdfe lp l12.TransferSJC if ISOCode =="IND" & WLM>1 & EarlyAgeM==0, cluster(IDlseMHR) a( YearMonth )
ivreghdfe lp  (TransferSJC = EarlyAgeM)  if ISOCode =="IND"  & Post==1, cluster(IDlseMHR) a( $lcontrol )

gen pastM = l12.TransferSJC
gen pastLLM = l12.TransferSJLLC
binscatter lp pastLLM  if ISOCode =="IND" & WLM>1 & EarlyAgeM==0, absorb(YearMonth)

* regressions to output
eststo clear 
eststo r1:reghdfe lp  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "No"
	summ Productivity if e(sample) &  EarlyAgeM==0
		estadd scalar cmean `r(mean)', replace
eststo r2:reghdfe lp  EarlyAgeM  if ISOCode =="IND"& Post==1 & WLM>1, cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "Yes"
	summ Productivity if e(sample) &  EarlyAgeM==0
		estadd scalar cmean `r(mean)', replace

eststo r3:reghdfe LogPayBonus  EarlyAgeM  if ISOCode =="IND" , cluster(IDlseMHR) a( $lcontrol )
estadd local SW "No"
estadd local N "51063", replace
	summ PayBonus if e(sample) &  EarlyAgeM==0
		estadd scalar cmean `r(mean)', replace
eststo r4:reghdfe  LogPayBonus  EarlyAgeM  if ISOCode =="IND"& Post==1 , cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "Yes"
estadd local N "23253", replace
	summ PayBonus if e(sample) &  EarlyAgeM==0
		estadd scalar cmean `r(mean)', replace

eststo r5:reghdfe TransferSJLLC  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "No"
	summ TransferSJLLC if e(sample) &  EarlyAgeM==0
	estadd scalar cmean `r(mean)', replace
eststo r6:reghdfe TransferSJLLC  EarlyAgeM  if ISOCode =="IND"& Post==1 & WLM>1, cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "Yes"
	summ TransferSJLLC if e(sample) &  EarlyAgeM==0
		estadd scalar cmean `r(mean)', replace

esttab , star(* 0.10 ** 0.05 *** 0.01) keep(  EarlyAgeM )

* PLOT - only natural experiment 
coefplot  (r2,  ciopts(lwidth(2 ..) lcolor(ebblue )))  (r4,  ciopts(lwidth(2 ..) lcolor(ebblue)))   (r6, ciopts(lwidth(2 ..) lcolor(ebblue))), ///
title("", pos(12) span si(large))  keep(EarlyAgeM )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(off) ///
 coeflabels(r2= "Productivity (sales in logs, INR)"  r4= "Pay (in logs, EUR)"  r6 = "Lateral Moves") ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(-0.1 .6)) xlabel(-0.1(0.1)0.6)   
graph export "$analysis/Results/6.Productivity/ProdPlot2.png", replace 
graph save "$analysis/Results/6.Productivity/ProdPlot2.gph", replace

* PLOT - both full sample and natural experiment 
coefplot (r1, label(Full sample) ciopts(lwidth(2 ..) lcolor(orange))) (r2, label(Natural experiment) ciopts(lwidth(2 ..) lcolor(ebblue ))) (r3, label(Full sample) ciopts(lwidth(2 ..) lcolor(orange))) (r4, label(Natural experiment) ciopts(lwidth(2 ..) lcolor(ebblue))) (r5, label(Full sample) ciopts(lwidth(2 ..) lcolor(orange))) (r6, label(Natural experiment) ciopts(lwidth(2 ..) lcolor(ebblue))), ///
title("", pos(12) span si(large))  keep(EarlyAgeM )  levels(90) ///
scale(1) swapnames aseq ciopts(lwidth(2 ..)) msymbol(d) mcolor(white)  legend(order(1 "Full sample" 3 "Natural experiment" ) position(6) rows(1)) ///
 coeflabels(r1= "Productivity (sales in logs, INR)" r2 = " " r3= "Pay (in logs, EUR)" r4 = " " r5 = "Lateral Moves" r6 = " ") ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(0 .6)) xlabel(0(0.1)0.6)   
graph export "$analysis/Results/6.Productivity/ProdPlot.png", replace 
graph save "$analysis/Results/6.Productivity/ProdPlot.gph", replace

* TABLE PAPER:
esttab using "$analysis/Results/6.Productivity/TalentMProdlogWages.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EarlyAgeM  ) se r2 ///
s( SW N r2 cmean, labels( "Switchers sample, post transition" "N" "R-squared" "Mean, low-flyer manager" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales in logs, INR)" "Pay (in logs, EUR)" "Lateral Moves", pattern(1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: worker age group FE interacted with gender, managers' age group FE, tenure and tenure squared interacted with managers' gender.  ///
"\end{tablenotes}") replace

* TABLE SLIDES: separate version for the slides where you need to add manually: \begin{tabular}{lcc>{\onslide<2->}cccc<{\onslide<1->}} instead of \begin{tabular}{l*{6}{c}}
esttab using "$analysis/Results/6.Productivity/TalentMProdlogWagesSlides.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EarlyAgeM  ) se r2 ///
s( SW N r2 cmean, labels( "Switchers sample, post transition" "N" "R-squared" "Mean, low-flyer manager" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales in logs, INR)" "Pay (in logs, EUR)" "Lateral Moves", pattern(1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: worker age group FE interacted with gender, managers' age group FE, tenure and tenure squared interacted with managers' gender.  ///
"\end{tablenotes}") replace


* Do the high fliers managers earn higher wages while supervising the workers in the natural experiment? No! 
* NOTE: HF have same WL (WLM==2) and usually lower tenure and age 
eststo:reghdfe  LogPayBonusM  EarlyAgeM  if ISOCode =="IND"& Post==1 & WLM==2 , cluster(IDlseMHR) a(  $lcontrol )

* TABLE with prod. in logs & wages 
*******************************

eststo clear 

eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND"& Post==1 & WLM>1, cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "\multicolumn{1}{c}{Yes}"

eststo:reghdfe lp MFEBayesPromSG75  if ISOCode =="IND", cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe lp MFEBayesPromSG75  if ISOCode =="IND" & Post==1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "\multicolumn{1}{c}{Yes}"

esttab , star(* 0.10 ** 0.05 *** 0.01) keep(  EarlyAgeM  MFEBayesPromSG75 )

esttab using "$analysis/Results/6.Productivity/TalentMProdlog.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EarlyAgeM  MFEBayesPromSG75) se r2 ///
s( SW N r2, labels( "Switchers sample, post transition" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales in logs)", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: worker age group FE interacted with gender, managers' age group FE, tenure and tenure squared interacted with managers' gender.  ///
"\end{tablenotes}") replace


* FINAL TABLE: India  (in standard deviation)
********************************************

eststo clear 

eststo:reghdfe ProductivityStd  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $control )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe ProductivityStd  EarlyAgeM  if ISOCode =="IND"& Post==1 & WLM>1, cluster(IDlseMHR) a(  $control )
estadd local SW "\multicolumn{1}{c}{Yes}"
eststo:reghdfe ProductivityStd MFEBayesPromSG75  if ISOCode =="IND", cluster(IDlseMHR) a(  $control )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe ProductivityStd MFEBayesPromSG75  if ISOCode =="IND" & Post==1, cluster(IDlseMHR) a( $control )
estadd local SW "\multicolumn{1}{c}{Yes}"

esttab , star(* 0.10 ** 0.05 *** 0.01) keep(  EarlyAgeM  MFEBayesPromSG75 )

esttab using "$analysis/Results/6.Productivity/TalentMProd.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EarlyAgeM  MFEBayesPromSG75) se r2 ///
s( SW N r2, labels( "Switchers sample, post transition" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales)", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: managers' age group FE, tenure and tenure squared interacted with managers' gender.  ///
"\end{tablenotes}") replace

* How many months for each IDlse? 
********************************************
gen o = 1 
bys IDlse: egen tto = sum(o)
egen i = tag(IDlse)

bys IDlse: egen ttChangeM = sum(ChangeM)

su tto if i==1 & ISOCode =="IND",d // median duration in position is 22 months 
su ttChangeM if i==1 & ISOCode =="IND" & Ei!=. & MFEBayesPromSG75!=.,d // median is 2 manager change, but drop to 600 people in the sample, 20% of the original 3300
count if ttChangeM >0 & i==1 & ISOCode =="IND" & Ei!=. & MFEBayesPromSG75!=. // drop to 600 people in the sample, 20% of the original 3300 workers in India


