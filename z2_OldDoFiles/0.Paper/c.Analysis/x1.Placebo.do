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

merge m:1 IDlse using  "$managersdta/Temp/Random20vw.dta" // "$managersdta/Temp/Random10v.dta",
drop _merge 
rename random20 random
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

foreach  y in  ChangeSalaryGradeC PromWLC TransferSJVC  { // $Keyoutcome $other
* regression
********************************************************************************

eststo: reghdfe `y'  $LLH $LLL $FLH  $FLL if  ( ( (`Label'LHB==1 | `Label'LLB==1)) ) , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )
*  `Label'LHB==1 | (`Label'LLB==1 & WL2==1) | `Label'HHB==1 | `Label'HLB==1 | (random==1 & Ei==.)
*( (WL2==1 & (`Label'LHB==1 | `Label'LLB==1)) | ( random==1) ) 

*eststo: ppmlhdfe `y'  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (`Label'LHB==1 | `Label'LLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform 
*
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
**# ON PAPER FIGURE: oddChangeSalaryGradeCELHQ5.pdf
* ON PAPER FIGURE: oddPromWLCELHQ5.pdf
* ON PAPER FIGURE: oddTransferSJVCELHQ5.pdf
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'`y'ELHQ60.pdf", replace

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ84.pdf", replace

}

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

foreach  y in PromWLC ChangeSalaryGradeC  TransferSJVC    { // $Keyoutcome $other
* regression
********************************************************************************

*eststo: reghdfe `y' $LHL  $LHH  $FHL  $FHH    if  (  (`Label'HLB==1 | `Label'HHB==1) | (random==1  & `Label'HLB==0 & `Label'HHB==0))    , a( IDlse YearMonth    )  vce(cluster IDlseMHR) // this regressions is for: ONETAbilitiesDistanceC ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC  ( (WL2==1 & (`Label'HLB==1 | `Label'HHB==1))  ) a( Country YearMonth  AgeBand##Female   ) 

*eststo: ppmlhdfe `y'  $LHL  $LHH  $FHL  $FHH  if  (  (`Label'HLB==1 | `Label'HHB==1) | (random==1  & `Label'HLB==0 & `Label'HHB==0))  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform 

eststo: reghdfe `y' $LHL  $LHH  $FHL  $FHH     if ( ((`Label'HLB==1 | `Label'HHB==1))  )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes
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
**# ON PAPER FIGURE: oddTransferSJVCEHLQ5.pdf
* ON PAPER FIGURE: oddChangeSalaryGradeCEHLQ5.pdf
* ON PAPER FIGURE: oddPromWLCEHLQ5.pdf
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'`y'EHLQ60.pdf", replace

* 36 / 84
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ84.pdf", replace
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

foreach  y in LeaverPerm { // LeaverVol LeaverInv eaverPerm
eststo: reghdfe `y' $event  if ( (WL2==1 & cohort30==1 ) |random==1) & KEi>-1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // c.Tenure##i.Female
local lab: variable label `y'

* double differences 
*********************************************************************************

coeffExit, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

* Monthly: 0 / 60
 tw scatter b1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(3)`endL60')  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual60.pdf", replace

* quarterly
coeffExitQ, c(`window') y(`y') // program 

* 0 / 36
postDual , end(`endL36') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ36.pdf", replace

* 0 / 60
postDual , end(`endL60') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)

 tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ60.pdf", replace

* single differences 
*********************************************************************************
coeffExit1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* 0/60
 tw scatter bL1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endL60') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  
graph save  "$analysis/Results/4.Event/`Label'`y'ELH60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH60.pdf", replace

 tw scatter bH1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endL60') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHL60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL60.pdf", replace

* quarterly
coeffExitQ1, c(`window') y(`y') type(`Label') // program 

* 0/60
**# ON PAPER FIGURE: oddLeaverPermELHQ5.pdf
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'`y'ELHQ60.pdf", replace

**# ON PAPER FIGURE: oddLeaverPermEHLQ5.pdf
tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  
graph save  "$analysis/Results/0.Paper/x1.Placebo/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/0.Paper/x1.Placebo/`Label'`y'EHLQ60.pdf", replace

* 0/36
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace
} 

/********************************************************************************
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

* 1) separate values for salary
* 2) all other outcomes 

foreach  y in   $Keyoutcome  { // $Keyoutcome $other
* regression
********************************************************************************

*eststo: reghdfe `y' $event   if (WL2==1)   , a( IDlse YearMonth    )  vce(cluster IDlseMHR) // this regressions is for:  TransferSJ but it is not used as I decided to use TransferSJVC

*eststo: reghdfe `y' $event   if (WL2==1)   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC

eststo: reghdfe `y'  $event   if (WL2==1 | random==1)  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) // this regression is for all other outcomes
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
 tw scatter b1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84')  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'")
graph save  "$analysis/Results/4.Event/`Label'`y'Dual84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual84.pdf", replace

* Quarterly
coeffQ, c(`window') y(`y') // program 

* 36 / 36 
postDual , end(`endL36') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36')  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ36.pdf", replace

* 36 / 60
postDual , end(`endL60') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60')  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ60.pdf", replace

* 36 / 84
postDual , end(`endL84') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84')  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ84.pdf", replace

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
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH84.pdf", replace

tw scatter bH1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL84.pdf", replace


* quarterly
coeffQ1, c(`window') y(`y') type(`Label') // program 

* 36 / 36 
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace

* 36 / 60
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)   note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ60.pdf", replace

* 36 / 84
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ84.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ84.pdf", replace
}
