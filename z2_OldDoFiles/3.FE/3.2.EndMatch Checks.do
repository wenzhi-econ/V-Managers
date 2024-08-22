* ENDOGENOUS MATCHING 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth

merge m:1 IDlse using  "$analysis/Results/3.FE/EFE.dta"
drop _merge

merge m:1 IDlseMHR using "$analysis/Results/3.FE/MFE.dta"
drop _merge

********************************************************************************
* VALIDATION OF FE 
********************************************************************************

*reghdfe VPAM MFEPayWCZT  , a(Country Year WLM FuncM) cluster(IDlseMHR)

*reghdfe VPAM MFEPayWCZT  , a(Country Year WLM FuncM) cluster(IDlseMHR)

********************************************************************************
* CARD 2013
********************************************************************************

* RESIDUALIZE PAY
reghdfe LogPayBonus c.Tenure##c.Tenure , a(CountryYM Female AgeBand WL Func)  residuals
predict LogPayBonusR, res 

* LEAVE OUT MEAN FOR TEAM WAGES
bys IDlseMHR YearMonth: egen  LogPayBonusRSum = total(LogPayBonusR)
replace LogPayBonusRSum = . if IDlseMHR==.
replace LogPayBonusRSum = . if YearMonth <=tm(2015m11) // pay data not available before then 
gen LogPayBonusRTeam = (LogPayBonusRSum - LogPayBonusR) / TeamSize 

* Window around first move
bys IDlse: egen f = min(cond(ChangeM==1,YearMonth, .))
format f %tm
gen ChangeMFirst = .
replace  ChangeMFirst = 1 if YearMonth ==f
replace ChangeMFirst = 0 if f!=. & ChangeMFirst !=1
replace ChangeMFirst = . if YearMonth <=tm(2015m11) 
gen o =1
bys IDlse (YearMonth), sort: gen tot = sum(o)
bys IDlse: egen a = min(cond(YearMonth==f,tot,.))
gen Window = tot -a 
bys IDlse: egen minmin = min(Window)
bys IDlse: egen maxmax = max(Window)
drop f o 
keep if YearMonth >tm(2015m11) &  (minmin <=-12 &  maxmax >=12 )  // balanced sample 

* quartile 
gen t = 1 if Window <=-1
replace t =2 if Window >=0
bys IDlse t: egen LogPayBonusRTeamMean = mean(LogPayBonusRTeam)
egen LogPayBonusRTeamQ = xtile(LogPayBonusRTeamMean), by(Country) nq(4)

* event type
bys IDlse: egen preQ = min(cond(t==1), LogPayBonusRTeamQ,.)
bys IDlse: egen postQ = min(cond(t==2), LogPayBonusRTeamQ,.)
tostring preQ, gen(preQS) 
tostring postQ, gen(postQS) 
gen eventQ =  preQS + postQS
keep if eventQ == "11" |eventQ ==   "12" | eventQ ==  "13"  | eventQ == "14" | eventQ == "41" | eventQ == "42" | eventQ == "43" | eventQ == "44"
destring eventQ, force replace 
compress 
save "$analysis/Results/3.FE/EndMatchData.dta", replace 

********************************************************************************
* PLOT
********************************************************************************

use "$analysis/Results/3.FE/EndMatchData.dta", clear 
xtset IDlse Window
xtbalance , range(-12 12)
xtset IDlse Window
cd "$analysis/Results/3.FE"
count
esplot LogPayBonusR , window(-12 12) by(eventQ) event(ChangeMFirst) period_length(3) vce(cluster IDlseMHR)  estimate_reference savedata( Card13.dta, replace  ) legend(off)

use "$analysis/Results/3.FE/Card13.dta", clear 
set scheme burd8
grstyle init
grstyle set plain, horizontal grid
twoway connected b_111 t ||   connected b_121 t  ||   connected b_131 t  ||   connected b_141 t  ||   connected b_411 t  ||   connected b_421 t ||   connected b_431 t ||   connected b_441 t , legend(rows(2) order(1 "1 to 1" 2 "1 to 2" 3 "1 to 3" 4 "1 to 4" 5 "4 to 1"  6 "4 to 2"  7 "4 to 3"  8 "4 to 4" )) xtitle("Event Time (quarters since manager switch)") xlabel(-4(1)4)
graph export "$analysis/Results/3.FE/Card13.png", replace 


********************************************************************************
* RSQUARED CHECK
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth

egen TenureBand = cut(Tenure), group(10)
egen TenureBandM = cut(TenureM), group(10)

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYM

egen group = group(IDlse IDlseMHR )

*Reported obs differ because of singletons
reghdfe LogPayBonus if BC ==0 , a(   $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

/* HDFE Linear regression                            Number of obs   =  3,503,089
Absorbing 11 HDFE groups                          F(   0,  28931) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.7839
                                                  Adj R-squared   =     0.7835
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     28,932        Root MSE        =     0.4178

*/

reghdfe LogPayBonus if BC ==0 , a(  IDlseMHR $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)

/*

HDFE Linear regression                            Number of obs   =  3,502,605
Absorbing 12 HDFE groups                          F(   0,  28447) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.8642
                                                  Adj R-squared   =     0.8628
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     28,448        Root MSE        =     0.3325

*/
reghdfe LogPayBonus if BC ==0 , a(  IDlse  $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
/*

HDFE Linear regression                            Number of obs   =  3,499,651
Absorbing 12 HDFE groups                          F(   0,  28833) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.9437
                                                  Adj R-squared   =     0.9416
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     28,834        Root MSE        =     0.2170


*/

reghdfe LogPayBonus if BC ==0 , a(  IDlseMHR IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
/*
HDFE Linear regression                            Number of obs   =  3,499,231
Absorbing 13 HDFE groups                          F(   0,  28425) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.9536
                                                  Adj R-squared   =     0.9514
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     28,426        Root MSE        =     0.1979

*/
reghdfe LogPayBonus if BC ==0 , a(  group $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)
/*

HDFE Linear regression                            Number of obs   =  3,461,637
Absorbing 12 HDFE groups                          F(   0,  27995) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.9638
                                                  Adj R-squared   =     0.9605
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     27,996        Root MSE        =     0.1785

*/

********************************************************************************
* RSQUARED CHECK - promotions 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth

egen TenureBand = cut(Tenure), group(10)
egen TenureBandM = cut(TenureM), group(10)

global controlE i.WL i.Female i.AgeBand i.TenureBand i.Func
global controlM i.WLM i.FemaleM i.AgeBandM i.TenureBandM i.FuncM
global controlMacro i.CountryYM

egen group = group(IDlse IDlseMHR )
egen CountryYear = group(Country Year )

*Reported obs differ because of singletons
reghdfe PromWLC if BC ==0 , a(  CountryYear  ) vce(cluster IDlseMHR)

/* 
HDFE Linear regression                            Number of obs   =  8,382,553
Absorbing 1 HDFE group                            F(   0,  42743) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.0363
                                                  Adj R-squared   =     0.0362
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     42,744        Root MSE        =     0.2318


*/

reghdfe PromWLC if BC ==0 , a( IDlse CountryYear  ) vce(cluster IDlseMHR)

/*

HDFE Linear regression                            Number of obs   =  8,375,301
Absorbing 2 HDFE groups                           F(   0,  42575) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.6767
                                                  Adj R-squared   =     0.6689
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     42,576        Root MSE        =     0.1359


*/
reghdfe PromWLC if BC ==0 , a( IDlse CountryYear IDlseMHR   ) vce(cluster IDlseMHR)

/*

HDFE Linear regression                            Number of obs   =  8,374,781
Absorbing 3 HDFE groups                           F(   0,  42069) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.7466
                                                  Adj R-squared   =     0.7391
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     42,070        Root MSE        =     0.1207


*/

reghdfe PromWLC if BC ==0 , a( CountryYear IDlseMHR   ) vce(cluster IDlseMHR) 

/*
HDFE Linear regression                            Number of obs   =  8,381,938
Absorbing 2 HDFE groups                           F(   0,  42128) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.2303
                                                  Adj R-squared   =     0.2264
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     42,129        Root MSE        =     0.2077


*/
reghdfe PromWLC if BC ==0 , a( CountryYear group   ) vce(cluster IDlseMHR)
/*


HDFE Linear regression                            Number of obs   =  8,320,962
Absorbing 2 HDFE groups                           F(   0,  41722) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.9430
                                                  Adj R-squared   =     0.9389
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     41,723        Root MSE        =     0.0584


*/

********************************************************************************
* RESIDUALS CHECK - BASSI NAM FIG. A3 (2020)
********************************************************************************

reghdfe LogPayBonus if BC ==0 , a( MFE= IDlseMHR EFE=IDlse $controlM   $controlE $controlMacro  ) vce(cluster IDlseMHR)  residuals
predict Res , res 

egen MFEPayZ = std(MFE)
winsor2 MFEPayZ , trim cuts(2.5 99) suffix(T)

egen EFEPayZ = std(EFE)
winsor2 EFEPayZ , trim cuts(2.5 99) suffix(T)

egen EFEPayZTQ = xtile(EFEPayZT),  nq(4)
egen MFEPayZTQ = xtile(MFEPayZT),  nq(4)

collapse Res, by(EFEPayZTQ MFEPayZTQ  )

drop if EFEPayZTQ==. | MFEPayZTQ==.

twoway contour Res EFEPayZTQ MFEPayZTQ   , heatmap   ccolors(ebblue eltblue emidblue ) xtitle("Manager FE (Quartile)") ytitle("Worker FE (Quartile)") ztitle("Mean Residuals")

graph export "$analysis/Results/3.FE/3d.png", replace 

