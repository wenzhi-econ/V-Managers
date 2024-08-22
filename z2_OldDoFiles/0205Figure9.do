
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? sub-figure 1.
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

eststo: reghdfe LogPayBonus  $LLH $LLL $FLH  $FLL if ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 )  )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 & Ei!=.)  ) 

local lab: variable label LogPayBonus

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(LogPayBonus) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(12) y(LogPayBonus)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(LogPayBonus) type(`Label') // program 

xlincom (L36ELH - L36ELL) (L60ELH - L60ELL) (L84ELH - L84ELL) (L24ELH - L24ELL) , level(95) post
est store LogPayBonus

coefplot  (LogPayBonus , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (LogPayBonus, keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (LogPayBonus , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(0(0.1)0.4) xscale(range(0 0.4))
graph export "$analysis/Results/0.Paper/2.2.Event LH/LogPayBonusPlotLHA.pdf", replace 
graph save "$analysis/Results/0.Paper/2.2.Event LH/LogPayBonusPlotLHA.gph", replace 



*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? sub-figure 2.
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

eststo: reghdfe LogPay  $LLH $LLL $FLH  $FLL if ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 )  )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 & Ei!=.)  ) 

local lab: variable label LogPay

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(LogPay) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(12) y(LogPay)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(LogPay) type(`Label') // program 

xlincom (L36ELH - L36ELL) (L60ELH - L60ELL) (L84ELH - L84ELL) (L24ELH - L24ELL) , level(95) post
est store LogPay
 
coefplot  (LogPay , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
(LogPay, keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
(LogPay , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
title("`lab'", size(medsmall))  xline(0, lpattern(dash))  xlabel(0(0.1)0.4) xscale(range(0 0.4))
graph export "$analysis/Results/0.Paper/2.2.Event LH/LogPayPlotLHA.pdf", replace 
graph save "$analysis/Results/0.Paper/2.2.Event LH/LogPayPlotLHA.gph", replace


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? sub-figure 3.
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??



eststo: reghdfe LogBonus  $LLH $LLL $FLH  $FLL if ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 )  )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 & Ei!=.)  ) 

local lab: variable label LogBonus

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(LogBonus) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(12) y(LogBonus)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(LogBonus) type(`Label') // program 

xlincom (L36ELH - L36ELL) (L60ELH - L60ELL) (L84ELH - L84ELL) (L24ELH - L24ELL) , level(95) post
est store LogBonus

coefplot  (LogBonus , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (LogBonus, keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (LogBonus , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(0(0.1)1.5) xscale(range(0 1.5))
graph export "$analysis/Results/0.Paper/2.2.Event LH/LogBonusPlotLHA.pdf", replace 
graph save "$analysis/Results/0.Paper/2.2.Event LH/LogBonusPlotLHA.gph", replace 



*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? sub-figure 4.
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??


eststo: reghdfe PromWLC  $LLH $LLL $FLH  $FLL if ( WL2==1 & ( FTLHB==1 | FTLLB==1) | ( random==1  & FTHLB==0 & FTHHB==0)  )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 & Ei!=.)  ) 

local lab: variable label PromWLC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(PromWLC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(12) y(PromWLC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(PromWLC) type(`Label') // program 

xlincom (L36ELH - L36ELL) (L60ELH - L60ELL) (L84ELH - L84ELL) (L24ELH - L24ELL) , level(95) post
est store PromWLC


coefplot  ///
    (PromWLC , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (PromWLC, keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (PromWLC , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    , ciopts(lwidth(2 ..)) levels(95) msymbol(d) mcolor(white) legend(off)  ///
    title("Work-level promotions", size(vlarge)) ///
    xline(0, lpattern(dash)) xscale(range(0 0.1)) xlabel(0(0.02)0.1, labsize(vlarge)) ylabel(, labsize(vlarge)) /// 
    graphregion(margin(medium)) plotregion(margin(medium)) xsize(5) ysize(2)

graph save "$analysis/Results/0.New/PromWLCPlotLHA.gph", replace 
graph export "$analysis/Results/0.New/PromWLCPlotLHA.pdf", replace as(pdf)

