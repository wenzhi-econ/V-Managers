* identify the lowest performer: lowest VPA or lowest pay growth/pay in the two previous years 
********************************************************************************

xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus 
foreach var in VPA PayGrowth LogPayBonus {
	bys IDlse: egen `var'0 = mean(cond(KEi<=-1 & KEi >=-24, `var' , .))
	bys IDlseMHR YearMonth: egen min`var'0 = min(cond( KEi == 0 , `var' , .) )
	bys IDlse: egen weak`var' = max(cond (`var'0 == min`var'0 & `var'0 !=. & KEi==0 , 1, 0) ) 
	bys IDlseMHR YearMonth: egen max`var'0 = max(cond( KEi == 0 , `var' , .) )
	bys IDlse: egen strong`var' = max(cond (`var'0 == max`var'0 & `var'0 !=. & KEi==0 , 1, 0) )
}

count if weakVPA ==1 | weakPayGrowth==1 | weakLogPayBonus ==1 // lowest performers at baseline 


********************************************************************************
* ASYMMETRIC WINDOW: 3 / 5 / 7 years 
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

keep if (WL2==1 | random10==1)

* 1) separate values for salary
* 2) all other outcomes 

foreach  y in  ChangeSalaryGradeC  TransferSJVC PromWLC   { // $Keyoutcome $other
* regression
********************************************************************************

*eststo: reghdfe `y' $event   if (WL2==1)   , a( IDlse YearMonth    )  vce(cluster IDlseMHR) // this regressions is for:  TransferSJ but it is not used as I decided to use TransferSJVC

*eststo: reghdfe `y' $event   if (WL2==1)   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC

eststo: reghdfe `y'  $event   if (WL2==1 & weakLogPayBonus==1) | random10==1  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) // this regression is for all other outcomes
local lab: variable label `y'

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`endF36') y(`y')
su joint
local joint = round(r(mean), 0.001)

* Monthly: 36 / 84
 tw scatter b1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'")
graph save  "$analysis/Results/4.Event/W`Label'`y'Dual84.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'Dual84.png", replace

* Quarterly
coeffQ, c(`window') y(`y') // program 

* 36 / 36 
postDual , end(`endL36') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/W`Label'`y'DualQ36.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'DualQ36.png", replace

* 36 / 60
postDual , end(`endL60') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/W`Label'`y'DualQ60.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'DualQ60.png", replace

* 36 / 84
postDual , end(`endL84') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/W`Label'`y'DualQ84.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'DualQ84.png", replace

* single differences 
********************************************************************************

* monthly: 36 / 84
coeff1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrend , end(`endF36') y(`y')
su jointL
local jointL = round(r(mean), 0.001)
su jointH 
local jointH = round(r(mean), 0.001)

tw scatter bL1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/W`Label'`y'ELH84.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'ELH84.png", replace

tw scatter bH1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/W`Label'`y'EHL84.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'EHL84.png", replace


* quarterly
coeffQ1, c(`window') y(`y') type(`Label') // program 

* 36 / 36 
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/W`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'ELHQ36.png", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/W`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'EHLQ36.png", replace

* 36 / 60
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/W`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'ELHQ60.png", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/W`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'EHLQ60.png", replace

* 36 / 84
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/W`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'ELHQ84.png", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/W`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/4.Event/W`Label'`y'EHLQ84.png", replace
}
