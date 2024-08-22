********************************************************************************
* ASYMMETRIC WINDOW: 3 / 5 / 7 years - only HL vs HH to speed up estimation 
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
global Keyoutcome PromWLC ChangeSalaryGradeC  TransferSJVC TransferFuncC
global other ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

*keep if (WL2==1 | random==1)

* 1) separate values for salary
* 2) all other outcomes 

foreach  y in $Keyoutcome    { // $Keyoutcome $other
* regression
********************************************************************************

* MAIN 
eststo: reghdfe `y' $LHL  $LHH  $FHL  $FHH     if ( (WL2==1 & (FTHLB==1 | FTHHB==1)) | ( random==1  & FTHLB==0 & FTHHB==0) )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes

* MAIN ONET 
*eststo: reghdfe `y' $LHL  $LHH  $FHL  $FHH    if  (  (FTHLB==1 | FTHHB==1) | (random==1  & FTHLB==0 & FTHHB==0))    , a( IDlse YearMonth    )  vce(cluster IDlseMHR) // this regressions is for: ONETAbilitiesDistanceC ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC  ( (WL2==1 & (FTHLB==1 | FTHHB==1))  ) a( Country YearMonth  AgeBand##Female   ) 

* POISSON ROBUSTNESS 
*eststo: ppmlhdfe `y'  $LHL  $LHH  $FHL  $FHH  if  ( WL2==1& (FTHLB==1 | FTHHB==1) | (random==1  & FTHLB==0 & FTHHB==0))  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform 

* COHORT MIDDLE ROBUSTNESS
*eststo: reghdfe `y'  $LHL  $LHH  $FHL  $FHH  if ( ( WL2==1& cohortSingle==1 & (FTHLB==1 | FTHHB==1) ) | (random==1  & FTHLB==0 & FTHHB==0) ) , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

* NEW HIRE ROBUSTNESS
*eststo: reghdfe `y'  $LHL  $LHH  $FHL  $FHH  if ( ( WL2==1& TenureMin<1  & (FTHLB==1 | FTHHB==1) ) | (random==1  & FTHLB==0 & FTHHB==0) ) , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label `y'

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffHL1, c(`window') y(`y') type(`Label') // program 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrendHL , end(`endF36') y(`y')
su jointH 
local jointH = round(r(mean), 0.001)

tw scatter bH1 etH1 if etH1>=-`endF36' & etH1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>=-`endF36' & etH1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL84.pdf", replace

* quarterly
coeffQHL1, c(`window') y(`y') type(`Label') // program 

tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace

* 36 / 60
**# ON PAPER FIGURE: FTChangeSalaryGradeCEHLQ5.pdf
* ON PAPER FIGURE: FTPromWLCEHLQ5.pdf
* ON PAPER FIGURE: FTTransferSJVCEHLQ5.pdf
* ON PAPER FIGURE: FTTransferFuncCEHLQ5.pdf
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/0.Paper/2.3.Event HL/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/0.Paper/2.3.Event HL/`Label'`y'EHLQ60.pdf", replace

* 36 / 84
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ84.pdf", replace
}

********************************************************************************
* PAY + BONUS 
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
global Keyoutcome PromWLC ChangeSalaryGradeC  TransferSJVC TransferFuncC
global other ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

*keep if (WL2==1 | random==1)

* 1) separate values for salary
* 2) all other outcomes 

label var LogPayBonus "Pay + bonus (logs)"
label var LogPay "Pay (logs)"
label var LogBonus "Bonus (logs)"

foreach  y in LogPayBonus LogPay  LogBonus    { // $Keyoutcome $other
* regression
********************************************************************************

* MAIN 
eststo: reghdfe `y' $LHL  $LHH  $FHL  $FHH     if ( (WL2==1 & (FTHLB==1 | FTHHB==1)) | ( random==1  & FTHLB==0 & FTHHB==0) )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes

* MAIN ONET 
*eststo: reghdfe `y' $LHL  $LHH  $FHL  $FHH    if  (  (FTHLB==1 | FTHHB==1) | (random==1  & FTHLB==0 & FTHHB==0))    , a( IDlse YearMonth    )  vce(cluster IDlseMHR) // this regressions is for: ONETAbilitiesDistanceC ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC  ( (WL2==1 & (FTHLB==1 | FTHHB==1))  ) a( Country YearMonth  AgeBand##Female   ) 

* POISSON ROBUSTNESS 
*eststo: ppmlhdfe `y'  $LHL  $LHH  $FHL  $FHH  if  ( WL2==1& (FTHLB==1 | FTHHB==1) | (random==1  & FTHLB==0 & FTHHB==0))  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform 

* COHORT MIDDLE ROBUSTNESS
*eststo: reghdfe `y'  $LHL  $LHH  $FHL  $FHH  if ( ( WL2==1& cohortSingle==1 & (FTHLB==1 | FTHHB==1) ) | (random==1  & FTHLB==0 & FTHHB==0) ) , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

* NEW HIRE ROBUSTNESS
*eststo: reghdfe `y'  $LHL  $LHH  $FHL  $FHH  if ( ( WL2==1& TenureMin<1  & (FTHLB==1 | FTHHB==1) ) | (random==1  & FTHLB==0 & FTHHB==0) ) , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label `y'

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffHL1, c(`window') y(`y') type(`Label') // program 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrendHL , end(12) y(`y')
su jointH 
local jointH = round(r(mean), 0.001)

tw scatter bH1 etH1 if etH1>=-`endF36' & etH1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>=-`endF36' & etH1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL84.pdf", replace

* quarterly
coeffQHL1, c(`window') y(`y') type(`Label') // program 

tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace

* 36 / 60
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ60.pdf", replace

* 36 / 84
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ84.pdf", replace

* 12 / 60
tw scatter bQH1 etQH1 if etQH1>=-4 & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-4 & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-4(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ60PostPre.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ60PostPre.pdf", replace

* 12 / 84
tw scatter bQH1 etQH1 if etQH1>=-4 & etQH1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-4 & etQH1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-4(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ84PostPre.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ84PostPre.pdf", replace

* 0 / 60
tw scatter bQH1 etQH1 if etQH1>=-1 & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-1 & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xscale(range(-1 `endLQ60')) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ60Post.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ60Post.pdf", replace

* 0 / 84
tw scatter bQH1 etQH1 if etQH1>=-1 & etQH1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-1 & etQH1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xscale(range(-1 `endLQ84')) xlabel(0(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ84Post.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ84Post.pdf", replace

xlincom (L36EHL - L36EHH) (L60EHL - L60EHH) (L84EHL - L84EHH) , level(95) post
est store `y'

**# FIGURE previously on paper, but eliminated for now: LogPayBonusPlotHLE.png - xlabel(-0.4(0.1)0.4) xscale(range(-0.4 0.4))
coefplot  (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(-0.4(0.1)0.4) xscale(range(-0.4 0.4)) note("Notes. Plotting estimates at 12, 20 and 28 quarters after manager transition. Reporting 95% confidence intervals.", span)
graph export "$analysis/Results/0.Paper/2.3.Event HL/`y'PlotHL.pdf", replace 
graph save "$analysis/Results/0.Paper/2.3.Event HL/`y'PlotHL.gph", replace

coefplot  (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(-0.4(0.1)0.4) xscale(range(-0.4 0.4)
graph export "$analysis/Results/4.Event/`y'PlotHLA.pdf", replace 
graph save "$analysis/Results/4.Event/`y'PlotHLA.gph", replace 
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

* MIDDLE COHORT ROBUSTNESS 
*eststo: reghdfe `y' $event  if   KEi>-1 & WL2==1 & cohortSingle==1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // | (random==1 & Ei==.) 

* NEW HIRES ROBUSTNESS
*eststo: reghdfe `y' $event  if   KEi>-1 & WL2==1 & TenureMin<1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // | (random==1 & Ei==.) 

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
/*
 tw scatter bL1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endL60') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELH60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH60.pdf", replace
*/

 tw scatter bH1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endL60') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHL60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL60.pdf", replace

* quarterly
coeffExitQ1, c(`window') y(`y') type(`Label') // program 

* 0/84
/*
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'ELHQ84.pdf", replace
*/

**# ON PAPER FIGURE: FTLeaverPermEHLQ7.pdf 
* ON PAPER FIGURE: FTLeaverVolEHLQ7.pdf
* ON PAPER FIGURE: FTLeaverInvEHLQ7.pdf
tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) 
yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ///
xtitle("Quarters since manager change") title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon))
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'EHLQ84.pdf", replace

* 0/60
/*
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60.pdf", replace
*/

tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ60.pdf", replace

* 0/36
/*
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace
*/

tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace
} 
