********************************************************************************
* Dynamic TWFE model - Asymmetric - PLACEBO
********************************************************************************

* Set globals 
********************************************************************************

* global analysis "${user}/Managers" // globals already defined in 0.0.Managers Master
do "$analysis/DoFiles/0.Paper/_CoeffProgram.do"

* choose the manager type !MANUAL INPUT!
global Label  odd // PromWL75 PromSG75 PromWL50 PromSG50  FT odd  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 pay75F60
global typeM  oddManager  // EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 MFEBayesLogPayF6075 MFEBayesLogPayF7275 

global cont   c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse   // alternative, to try WLM AgeBandM YearMonth AgeBand Tenure

* global analysis  "/Users/virginiaminni/Desktop/Managers Temp" // globals already defined in 0.0.Managers Master
********************************************************************************
* EVENT INDICATORS 
********************************************************************************

*use "$managersdta/SwitchersAllSameTeam2.dta", clear 
use "$managersdta/AllSameTeam2.dta", clear 

* Looking at the middle cohorts 
bys IDlse: egen MinAge = min(AgeBand)
label val MinAge AgeBand
format Ei %tm 
gen cohort30 = 1 if Ei >=tm(2014m1) & Ei <=tm(2018m12) // cohorts that have at least 36 months pre and after manager rotation 
gen cohort60 = 1 if Ei >=tm(2012m1) & Ei <=tm(2015m3) // if I cut the window, I can do 12 months pre and then 60 after 

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

*keep if Ei!=. 
gen KEi  = YearMonth - Ei 

merge m:1 IDlse using  "$managersdta/Temp/Random50vw.dta" // "$managersdta/Temp/Random10v.dta",  "$managersdta/Temp/Random20vw.dta"
drop _merge 
rename random50 random
keep if Ei!=. | random==1 

egen CountryYear = group(Country Year)

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
local end = 36 // to be plugged in, window lenght 
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii

* Variables for heterogeneity: SameGender0; SameNationality0; WPerf0p10p90B;  DiffSF; TeamPerf0B; WPerf0B; TenureMHigh0; Young0; LaborRegWEFB; OfficeSizeHigh0
********************************************************************************

********************************************************************************
* EVENT DUMMIES
********************************************************************************

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}
* create leads and lags 
foreach var in EHL ELL EHH ELH {

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

* selecting only needed variables 
*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* if binning 
local endD = 84
foreach var in LL LH HL HH {
forval i=12(12)`endD'{
	gen endL`var'`i' = KE`var'>`i' & KE`var'!=.
	gen endF`var'`i' = KE`var'< -`i' & KE`var'!=.
}
}

local end = 60 // 36 60 
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

********************************* REGRESSIONS **********************************

* LABEL VARS
label var ChangeSalaryGradeC "Salary grade increase"
label var ChangeSalaryGradeSameMC "Salary grade increase, same manager"
label var ChangeSalaryGradeDiffMC "Salary grade increase, diff. manager"
label var PromWLC "Vertical move"
label var PromWLSameMC "Vertical move, same manager"
label var PromWLDiffMC "Vertical move, diff. manager"
label var PromWLVC "Vertical move"
label var TransferInternalC "Lateral move"
label var TransferInternalSameMC "Lateral move, same manager"
label var TransferInternalDiffMC "Lateral move, diff. manager"
label var TransferInternalLLC "Lateral move, lateral"
label var TransferInternalVC "Lateral move, vertical"
label var TransferSJC "Lateral move"
label var TransferSJSameMC "Lateral move, same manager"
label var TransferSJDiffMC "Lateral move, diff. manager"
label var TransferSJLLC "Lateral move, lateral"
label var TransferSJVC "Lateral move"
label var TransferFuncC "Lateral move, function"
label var TransferSubFuncC "Lateral move"
label var ONETDistanceBC "Task-distant move, ONET"
label var ONETDistanceC "Task-distant move, ONET"
label var ONETSkillsDistanceC "Task-distant move, ONET"
label var DiffField "Education-distant move, field"

label var LogPayBonus "Pay (logs)"

* Same versus diff manager 
global diffM ChangeSalaryGradeDiffMC PromWLDiffMC  TransferInternalDiffMC TransferSJDiffMC // TransferInternalSJDiffMC
global sameM ChangeSalaryGradeSameMC PromWLSameMC  TransferInternalSameMC TransferSJSameMC // TransferInternalSJSameMC

********************************************************************************
* ASYMMETRIC WINDOW: 3 / 5 / 7 years  LH
********************************************************************************
{
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
global Keyoutcome  ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC
global other ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

*keep if (WL2==1 | (Ei==. & random==1) )

* 1) separate values for salary
* 2) all other outcomes 

**# ON PAPER FIGURE: oddChangeSalaryGradeCELHQ5.pdf
* regression
********************************************************************************

eststo: reghdfe ChangeSalaryGradeC  $LLH $LLL $FLH  $FLL if   ( (WL2==1& (`Label'LHB==1 | `Label'LLB==1)) | random==1 ) , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )
*  `Label'LHB==1 | (`Label'LLB==1 & WL2==1) | `Label'HHB==1 | `Label'HLB==1 | (random==1 & Ei==.)
* ( (WL2==1 & (`Label'LHB==1 | `Label'LLB==1)) | ( random==1) ) 

local lab: variable label ChangeSalaryGradeC

* single differences 
********************************************************************************

coeffLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(ChangeSalaryGradeC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 

* 36 / 60
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.4(0.1)0.4) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'ChangeSalaryGradeCELHQ5.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'ChangeSalaryGradeCELHQ5.pdf", replace

**# ON PAPER FIGURE: oddPromWLCELHQ5.pdf
* regression
********************************************************************************

eststo: reghdfe PromWLC  $LLH $LLL $FLH  $FLL if   ( (WL2==1& (`Label'LHB==1 | `Label'LLB==1)) | random==1 ) , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )
*  `Label'LHB==1 | (`Label'LLB==1 & WL2==1) | `Label'HHB==1 | `Label'HLB==1 | (random==1 & Ei==.)
*( ( (`Label'LHB==1 | `Label'LLB==1)) )

local lab: variable label PromWLC

* single differences 
********************************************************************************

coeffLH1, c(`window') y(PromWLC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(PromWLC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(PromWLC) type(`Label') // program 

* 36 / 60
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.2(0.1)0.2) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'PromWLCELHQ5.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'PromWLCELHQ5.pdf", replace

**# ON PAPER FIGURE: oddTransferSJVCELHQ5.pdf
* regression
********************************************************************************

eststo: reghdfe TransferSJVC  $LLH $LLL $FLH  $FLL if   ( (WL2==1& (`Label'LHB==1 | `Label'LLB==1)) | random==1 ) , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )
*  `Label'LHB==1 | (`Label'LLB==1 & WL2==1) | `Label'HHB==1 | `Label'HLB==1 | (random==1 & Ei==.)
* ( (WL2==1 & (`Label'LHB==1 | `Label'LLB==1)) | ( random==1) ) 

local lab: variable label TransferSJVC

* single differences 
********************************************************************************

coeffLH1, c(`window') y(TransferSJVC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferSJVC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferSJVC) type(`Label') // program 

* 36 / 60
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.3(0.1)0.3) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'TransferSJVCELHQ5.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'TransferSJVCELHQ5.pdf", replace

}

********************************************************************************
* ASYMMETRIC WINDOW: 3 / 5 / 7 years - only HL vs HH to speed up estimation 
********************************************************************************
{
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

**# ON PAPER FIGURE: oddTransferSJVCEHLQ5.pdf (RE-RUN)
* regression
********************************************************************************

eststo: reghdfe TransferSJVC $LHL  $LHH  $FHL  $FHH     if ( (WL2==1& (`Label'HLB==1 | `Label'HHB==1)) | random==1 )     , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes
local lab: variable label TransferSJVC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffHL1, c(`window') y(TransferSJVC) type(`Label') // program 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrendHL , end(`endF36') y(TransferSJVC)
su jointH 
local jointH = round(r(mean), 0.001)

* quarterly
coeffQHL1, c(`window') y(TransferSJVC) type(`Label') // program 

* 36 / 60
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.3(0.1)0.3) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointH'") // ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon))
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'TransferSJVCEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'TransferSJVCEHLQ5.pdf", replace
 
**# ON PAPER FIGURE: oddChangeSalaryGradeCEHLQ5.pdf 
* regression
********************************************************************************

eststo: reghdfe ChangeSalaryGradeC $LHL  $LHH  $FHL  $FHH     if ( (WL2==1& (`Label'HLB==1 | `Label'HHB==1)) | random==1 )     , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes
local lab: variable label ChangeSalaryGradeC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffHL1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrendHL , end(`endF36') y(ChangeSalaryGradeC)
su jointH 
local jointH = round(r(mean), 0.001)

* quarterly
coeffQHL1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 

* 36 / 60
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.4(0.1)0.4) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointH'") // ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon))
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'ChangeSalaryGradeCEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'ChangeSalaryGradeCEHLQ5.pdf", replace

**# ON PAPER FIGURE: oddPromWLCEHLQ5.pdf 
* regression
********************************************************************************

eststo: reghdfe PromWLC $LHL  $LHH  $FHL  $FHH     if ( (WL2==1& (`Label'HLB==1 | `Label'HHB==1)) | random==1 )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes
local lab: variable label PromWLC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffHL1, c(`window') y(PromWLC) type(`Label') // program 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrendHL , end(`endF36') y(PromWLC)
su jointH 
local jointH = round(r(mean), 0.001)

* quarterly
coeffQHL1, c(`window') y(PromWLC) type(`Label') // program 

* 36 / 60
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.2(0.1)0.2) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'") //  ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon))
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'PromWLCEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'PromWLCEHLQ5.pdf", replace
}

********************************************************************************
* EXIT 
********************************************************************************

{
*LABEL VARS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"
global exitFE   Country YearMonth // Func  AgeBand

**************************** REGRESSIONS ***************************************

* LOCALS
local end = 60 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
*global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local window = 121 // 73 121 169  to be plugged in
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

**# ON PAPER FIGURE: oddLeaverPermELHQ5.pdf
* regression
********************************************************************************

eststo: reghdfe LeaverPerm $event  if (`Label'LHB==1 | `Label'LLB==1 | `Label'HLB==1 | `Label'HHB==1) & KEi>-1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // c.Tenure##i.Female
local lab: variable label LeaverPerm

* single differences 
*********************************************************************************
coeffExit1, c(`window') y(LeaverPerm) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* quarterly
coeffExitQ1, c(`window') y(LeaverPerm) type(`Label') // program 

* 0/60
tw scatter bQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'LeaverPermELHQ5.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'LeaverPermELHQ5.pdf", replace

**# ON PAPER FIGURE: oddLeaverPermEHLQ5.pdf
* regression
********************************************************************************

* single differences 
*********************************************************************************
coeffExit1, c(`window') y(LeaverPerm) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* quarterly
coeffExitQ1, c(`window') y(LeaverPerm) type(`Label') // program 

* 0/60
tw scatter bQH1 etQL1 if etQL1>=0 & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQL1 if etQL1>=0 & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'LeaverPermEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'LeaverPermEHLQ5.pdf", replace

}
