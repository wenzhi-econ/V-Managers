********************************************************************************
* ASYMMETRIC WINDOW: 3 / 5 / 7 years 
********************************************************************************

* Probability of at least one transfer - only defined for those in the experiment 
********************************************************************************

gen ProbJobV = 0 if KEi <=0 
replace ProbJobV = TransferSJVC>0 if KEi>0  & KEi!=.
label var ProbJobV "Probability of at least one lateral move"
gen ProbJob = 0 if KEi <=0 
replace ProbJob = TransferSJC>0 if KEi>0  & KEi!=.
label var ProbJob "Probability of at least one lateral move"

reghdfe ProbJobV  FTLLPost  FTLHPost FTHLPost FTHHPost if WL2==1   , a( IDlse YearMonth  )  vce(cluster IDlseMHR)

* Baseline mean 
su ProbJobV if KEi>0 & FTLLPost ==1 // 0.19

* LOCALS
********************************************************************************

local end = 84 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local window = 169 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in 
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL36'/3 // 36 60 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

global cont  Country YearMonth TenureM##i.FemaleM  i.Tenure##Female
global Keyoutcome  ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC ProbJobV
global other ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

* 1) separate values for salary
* 2) all other outcomes 

foreach  y in $Keyoutcome $other { // $Keyoutcome $other
* regression
********************************************************************************

* MAIN 
eststo: reghdfe `y'  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

* MAIN: ONET
eststo: reghdfe `y'  $LLH $LLL $FLH  $FLL    if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1 & (FTLHB==0 & FTLLB==0)) )   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC

**# POISSON ROBUSTNESS
* ON PAPER FIGURE: FTTransferSJVCELHQ7PO.pdf
* ON PAPER FIGURE: FTPromWLCELHQ7PO.pdf
* ON PAPER FIGURE: FTChangeSalaryGradeCELHQ7PO.pdf
eststo: ppmlhdfe `y'  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform 

**# COHORT MIDDLE ROBUSTNES
* ON PAPER FIGURE: FTTransferSJVCELHQ7Single.pdf
* ON PAPER FIGURE: FTTransferFuncCELHQ7Single.pdf
* ON PAPER FIGURE: FTPromWLCELHQ7Single.pdf
* ON PAPER FIGURE: FTChangeSalaryGradeCELHQ7Single.pdf
eststo: reghdfe `y' $LLH $LLL $FLH  $FLL   if ( (WL2==1& cohortSingle==1 & (FTLHB==1 | FTLLB==1) ) | (random==1) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

**# NEW HIRE ROBUSTNESS
* ON PAPER FIGURE: FTTransferSJVCELHQ7New.pdf
* ON PAPER FIGURE: FTTransferFuncCELHQ7New.pdf
* ON PAPER FIGURE: FTPromWLCELHQ7New.pdf
* ON PAPER FIGURE: FTChangeSalaryGradeCELHQ7New.pdf
eststo: reghdfe `y' $LLH $LLL $FLH  $FLL   if ( (WL2==1& TenureMin<1 & (FTLHB==1 | FTLLB==1) ) | (random==1 ) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

* CONGESTION ROBUSTNESS: take out workers who take the exact position of the manager 
*eststo: reghdfe `y'  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1) & TakeSJMFraction==0) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

local lab: variable label `y'

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(`y')
su jointL
local jointL = round(r(mean), 0.001)

tw scatter bL1 etL1 if etL1>=-`endF36' & etL1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>=-`endF36' & etL1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH84.pdf", replace

* quarterly
coeffQLH1, c(`window') y(`y') type(`Label') // program 

* 36 / 36
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace

* 36 / 60
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60.pdf", replace

* 36 / 84
**# ON PAPER FIGURE: FTChangeSalaryGradeCELHQ7.pdf
* ON PAPER FIGURE: FTPromWLCELHQ7.pdf
* ON PAPER FIGURE: FTTransferSJVCELHQ7.pdf
* ON PAPER FIGURE: FTTransferFuncCELHQ7.pdf
* ON PAPER FIGURE: FTProbJobVELHQ7.pdf
* ON PAPER FIGURE: FTONETSkillsDistanceCELHQ7.pdf
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'`y'ELHQ84.pdf", replace
}

********************************************************************************
* BONUS AND PAY
********************************************************************************

* LOCALS
local end = 84 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local window = 169 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in
local endL24 = 24 // 36 60 to be plugged in  
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL24'/3 // 36 8 to be plugged in 
local endLQ36 = `endL36'/3 // 36 12 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

label var LogPayBonus "Pay + bonus (logs)"
label var LogPay "Pay (logs)"
label var LogBonus "Bonus (logs)"

* special graph for salary 
foreach  y in LogPay LogPayBonus LogBonus { //   $Keyoutcome $other
* regression
********************************************************************************

* MAIN 
eststo `y': reghdfe `y'  $LLH $LLL $FLH  $FLL if ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 )  )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 & Ei!=.)  )

* MAIN: ONET
*eststo: reghdfe `y'  $LLH $LLL $FLH  $FLL    if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1 & (FTLHB==0 & FTLLB==0)) )   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC

* POISSON ROBUSTNESS 
*eststo: ppmlhdfe `y'  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform 

* COHORT MIDDLE ROBUSTNESS
*eststo: reghdfe `y' $LLH $LLL $FLH  $FLL   if ( (WL2==1& cohortSingle==1 & (FTLHB==1 | FTLLB==1) ) | (random==1) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

* NEW HIRE ROBUSTNESS
*eststo: reghdfe `y' $LLH $LLL $FLH  $FLL   if ( (WL2==1& TenureMin<1 & (FTLHB==1 | FTLLB==1) ) | (random==1 ) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label `y'

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(12) y(`y')
su jointL
local jointL = round(r(mean), 0.001)

tw scatter bL1 etL1 if etL1>=-`endF36' & etL1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>=-`endF36' & etL1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH84.pdf", replace

* quarterly
coeffQLH1, c(`window') y(`y') type(`Label') // program 

/* 36 / 24 
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ24', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ24', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ24') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ24.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ24.pdf", replace

* 36 / 36 
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace

* 36 / 60
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60.pdf", replace

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ84.pdf", replace

* 12 / 60
tw scatter bQL1 etQL1 if etQL1>=-4 & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-4 & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-4(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60PostPre.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60PostPre.pdf", replace

* 12 / 84
tw scatter bQL1 etQL1 if etQL1>=-4 & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-4 & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-4(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ84PostPre.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ84PostPre.pdf", replace

* 0 / 60
tw scatter bQL1 etQL1 if etQL1>=-1 & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-1 & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xscale(range(-1 `endLQ60')) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60Post.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60Post.pdf", replace

* 0 / 84
tw scatter bQL1 etQL1 if etQL1>=-1 & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-1 & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xscale(range(-1 `endLQ84')) xlabel(0(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ84Post.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ84Post.pdf", replace
*/

xlincom (L36ELH - L36ELL) (L60ELH - L60ELL) (L84ELH - L84ELL) (L24ELH - L24ELL) , level(95) post
est store `y'

coefplot  (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(0(0.1)1.5) note("Notes. Plotting estimates at 12, 20 and 28 quarters after manager transition. Reporting 95% confidence intervals.", span)
graph export "$analysis/Results/4.Event/`y'PlotLH.pdf", replace 
graph save "$analysis/Results/4.Event/`y'PlotLH.gph", replace 

**# ON PAPER FIGURE: LogPayPlotLHAE.png - xlabel(0(0.1)0.4) xscale(range(0 0.4))
* ON PAPER FIGURE: LogPayBonusPlotLHAE.png - xlabel(0(0.1)0.4) xscale(range(0 0.4))
* ON PAPER FIGURE: LogBonusPlotLHAE.png - xlabel(0(0.1)1.5) xscale(range(0 1.5))
coefplot  (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(0(0.1)1.5)
graph export "$analysis/Results/0.Paper/2.2.Event LH/`y'PlotLHA.pdf", replace 
graph save "$analysis/Results/0.Paper/2.2.Event LH/`y'PlotLHA.gph", replace 

/* COMMON SCALE Option: 
forvalues i=1/3 {
    local y "y`i'"

    coefplot  (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
     (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
      (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
     , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
     title("`lab'", size(medsmall))   xline(0, lpattern(dash))  ///
     if `i'<3 {
        xlabel(0(0.1)0.4) xscale(range(0 0.4))
     }
     else {
        xlabel(0(0.1)1.5) xscale(range(0 1.5))
     }
    graph export "$analysis/Results/0.Paper/2.2.Event LH/`y'PlotLHA.pdf", replace 
    graph save "$analysis/Results/0.Paper/2.2.Event LH/`y'PlotLHA.gph", replace
}*/

coefplot (`y' , keep(lc_4) rename(  lc_4  = "8 quarters") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
 (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(0(0.1)1.5)
graph export "$analysis/Results/4.Event/`y'PlotLHA2y.pdf", replace 
graph save "$analysis/Results/4.Event/`y'PlotLHA2y.gph", replace 
}

********************************************************************************
* EXIT 
********************************************************************************

*LABEL VARS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"
global exitFE   Country YearMonth // Func  AgeBand

**************************** REGRESSIONS ***************************************

* LOCALS
local end = 84 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

global event $LExitLH  $LExitLL  $LExitHL  $LExitHH 

local window = 169 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in 
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL36'/3 // 36 60 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

foreach  y in LeaverPerm LeaverVol  LeaverInv { // LeaverVol LeaverInv LeaverPerm LeaverVol   LeaverInv 

* MAIN 
eststo: reghdfe `y' $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

**# MIDDLE COHORT ROBUSTNESS 
* ON PAPER FIGURE: FTLeaverPermELHQ7Single.pdf 
eststo: reghdfe `y' $event  if   KEi>-1 & WL2==1 & cohortSingle==1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // | (random==1 & Ei==.) 

**# NEW HIRES ROBUSTNESS
* ON PAPER FIGURE: FTLeaverPermELHQ7New.pdf
eststo: reghdfe `y' $event  if   KEi>-1 & WL2==1 & TenureMin<1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // | (random==1 & Ei==.) 

local lab: variable label `y'

/* double differences  &
*********************************************************************************

coeffExit, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

* Monthly: 0 / 60
 tw scatter b1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(3)`endL60')  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual60.pdf", replace

* quarterly
coeffExitQ, c(`window') y(`y') // program 

* 0 / 36
 tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ36.pdf", replace

* 0 / 60 
 tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ60.pdf", replace

* 0 / 84
**# ON PAPER FIGURE: FTLeaverPermDualQ7.pdf (RUN THE CODE TO CHANGE TO 20 QUARTERS)
 tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'DualQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'DualQ84.pdf", replace
*/

* single differences 
*********************************************************************************
coeffExit1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* 0/60
 tw scatter bL1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endL60') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELH60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH60.pdf", replace

/*
 tw scatter bH1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endL60') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHL60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL60.pdf", replace
*/

* quarterly
coeffExitQ1, c(`window') y(`y') type(`Label') // program 

* 0/84
**# ON PAPER FIGURE: FTLeaverPermELHQ7.pdf
* ON PAPER FIGURE: FTLeaverVolELHQ7.pdf
* ON PAPER FIGURE: FTLeaverInvELHQ7.pdf
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'ELHQ84.pdf", replace

/*
tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) 
yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ///
xtitle("Quarters since manager change") title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon))
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'EHLQ84.pdf", replace
*/

* 0/60
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60.pdf", replace

/*
tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ60.pdf", replace
*/

* 0/36
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace

/*
tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace
*/
} 

