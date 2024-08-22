********************************************************************************
* Dynamic TWFE model - Asymmetric 
********************************************************************************

* Set globals 
********************************************************************************

* global analysis "${user}/Managers" // globals already defined in 0.0.Managers Master
do "$analysis/DoFiles/0.Paper/_CoeffProgram.do"

* choose the manager type !MANUAL INPUT!
global Label  FT  // PromWL75 PromSG75 PromWL50 PromSG50  FT odd  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 pay75F60
global typeM  EarlyAgeM  // EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 MFEBayesLogPayF6075 MFEBayesLogPayF7275 

global cont   c.TenureM##c.TenureM
* global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse   // alternative, to try WLM AgeBandM YearMonth AgeBand Tenure

* global analysis  "/Users/virginiaminni/Desktop/Managers Temp" // globals already defined in 0.0.Managers Master 

* use "$managersdta/SwitchersAllSameTeam2.dta", clear 
use "$managersdta/AllSameTeam2.dta", clear


********************************************************************************
* EVENT INDICATORS 
********************************************************************************

{
* Months in function
bys IDlse TransferFuncC: egen MonthsFunc =  count(YearMonth)
label var MonthsFunc "Tot. Months in Function"

* New hires only
gen TenureMin1 = TenureMin<1 
ta TenureMin
ta TenureMin1 if Ei!=. // retain how many workers? 53%

* Looking at the middle cohorts 
bys IDlse: egen MinAge = min(AgeBand)
label val MinAge AgeBand
format Ei %tm 
gen cohort30 = 1 if Ei >=tm(2014m1) & Ei <=tm(2018m12) // cohorts that have at least 36 months pre and after manager rotation 
gen cohort60 = 1 if Ei >=tm(2012m1) & Ei <=tm(2015m3) // if I cut the window, I can do 12 months pre and then 60 after 
gen cohortMiddle = 1 if Ei >=tm(2014m1) & Ei <=tm(2016m12) // cohorts that have at least 36 months pre and 60 after manager rotation 
gen cohortSingle = 1 if Ei <=tm(2014m12) // cohorts that have at least 36 months pre and 84 after manager rotation 
su cohortSingle cohortMiddle  Ei if WL2==1 // retain how many events? 
di 1198682/ 1756342 // .68248781

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

gen KEi  = YearMonth - Ei 

merge m:1 IDlse using  "$managersdta/Temp/Random50vw.dta" // "$managersdta/Temp/Random20vw.dta" for the dual graphs to limited computation power and "$managersdta/Temp/Random50vw.dta" for all outcomes
drop _merge 
rename random50 random // random50 random20
keep if Ei!=. | random==1 

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
local end = 36 // to be plugged in, window lenght 
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii
*keep if ii==1 | random10==1

egen CountryYear = group(Country Year)


* BASELINE MEAN 
********************************************************************************

* LL + LH - preferred and use 1 quarter 
foreach y in ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC TransferSJC {
	di "`y'"
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (FTLL!=.   | FTLH!=.  )  // 1 quarter 
*su `y' if (KEi == -1 ) &  (FTLL!=.   | FTLH!=.  )  // 1 month
*su `y' if (KEi <= -1 ) &  (FTLL!=.   | FTLH!=.  )  // all pre-periods 

}

* for exit average in month 0 (left out month) 
su LeaverPerm if (FTLL!=.   | FTLH!=.  ) & KEi ==0  

* ALL
foreach y in ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC TransferSJC{
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (FTLL!=.   | FTLH!=. | FTHH!=. | FTHL!=. )   // 1 quarter 
su `y' if (KEi == -1 ) &  (FTLL!=.   | FTLH!=. | FTHH!=. | FTHL!=.    )  // 1 month 
su `y' if (KEi <= -1 ) &  (FTLL!=.   | FTLH!=. | FTHH!=. | FTHL!=. )  // all pre-periods 

}

* HL + HH 
foreach y in ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC TransferSJC{
	di "`y'"
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (FTHL!=.   | FTHH!=.  )  // 1 quarter 
su `y' if (KEi == -1 ) &  (FTHL!=.   | FTHH!=.  )  // 1 month
su `y' if (KEi <= -1 ) &  (FTHL!=.   | FTHH!=.  )  // all pre-periods 

}

* ONLY LL
foreach y in ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC TransferSJC{
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (FTLL!=.    )  // 1 quarter 
su `y' if (KEi == -1 ) &  (FTLL!=.     ) // 1 month 
su `y' if (KEi <= -1 ) &  (FTLL!=.     )  // all pre-periods 
}

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


* LABEL VARS
********************************************************************************

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
label var ONETAbilitiesDistanceC "Task-distant move, ONET"
label var ONETSkillsDistanceC "Task-distant move, ONET"
label var DiffField "Education-distant move, field"

label var LogPayBonus "Pay (logs)"


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
}

********************************************************************************
* LH vs LL: MAIN + ONET 
********************************************************************************

{


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

* MAIN 
**# ON PAPER FIGURE: FTChangeSalaryGradeCELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe ChangeSalaryGradeC  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) 

local lab: variable label ChangeSalaryGradeC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(ChangeSalaryGradeC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.1(0.1)0.3) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'ChangeSalaryGradeCELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'ChangeSalaryGradeCELHQ7.pdf", replace

**# ON PAPER FIGURE: FTPromWLCELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe PromWLC  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) 

local lab: variable label PromWLC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(PromWLC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(PromWLC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(PromWLC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.02(0.02)0.08) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'PromWLCELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'PromWLCELHQ7.pdf", replace

**# ON PAPER FIGURE: FTTransferSJVCELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe TransferSJVC  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) 

local lab: variable label TransferSJVC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(TransferSJVC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferSJVC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferSJVC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.05(0.05)0.2) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7.pdf", replace

**# ON PAPER FIGURE: FTTransferFuncCELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe TransferFuncC  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) 

local lab: variable label TransferFuncC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(TransferFuncC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferFuncC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferFuncC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.05(0.05)0.1) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferFuncCELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferFuncCELHQ7.pdf", replace

**# ON PAPER FIGURE: FTProbJobVELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe ProbJobV  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) 

local lab: variable label ProbJobV

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(ProbJobV) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(ProbJobV)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(ProbJobV) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.05(0.05)0.15) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'ProbJobVELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'ProbJobVELHQ7.pdf", replace

* MAIN: ONET
**# ON PAPER FIGURE: FTONETSkillsDistanceCELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe ONETSkillsDistanceC  $LLH $LLL $FLH  $FLL    if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1 & (FTLHB==0 & FTLLB==0)) )   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC

local lab: variable label ONETSkillsDistanceC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(ONETSkillsDistanceC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(ONETSkillsDistanceC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(ONETSkillsDistanceC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.06(0.02)0.06) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'ONETSkillsDistanceCELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'ONETSkillsDistanceCELHQ7.pdf", replace

}

********************************************************************************
* LH vs LL: ROBUSTNESS CHECKS
********************************************************************************

{
	
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


* COHORT MIDDLE ROBUSTNES
**# ON PAPER FIGURE: FTTransferSJVCELHQ7Single.pdf
* regression
********************************************************************************

eststo: reghdfe TransferSJVC $LLH $LLL $FLH  $FLL   if ( (WL2==1& cohortSingle==1 & (FTLHB==1 | FTLLB==1) ) | (random==1) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label TransferSJVC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(TransferSJVC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferSJVC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferSJVC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.05(0.05)0.2) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7Single.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7Single.pdf", replace

**# ON PAPER FIGURE: FTTransferFuncCELHQ7Single.pdf
* regression
********************************************************************************

eststo: reghdfe TransferFuncC $LLH $LLL $FLH  $FLL   if ( (WL2==1& cohortSingle==1 & (FTLHB==1 | FTLLB==1) ) | (random==1) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label TransferFuncC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(TransferFuncC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferFuncC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferFuncC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.05(0.05)0.1) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferFuncCELHQ7Single.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferFuncCELHQ7Single.pdf", replace

**# ON PAPER FIGURE: FTPromWLCELHQ7Single.pdf
* regression
********************************************************************************

eststo: reghdfe PromWLC $LLH $LLL $FLH  $FLL   if ( (WL2==1& cohortSingle==1 & (FTLHB==1 | FTLLB==1) ) | (random==1) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label PromWLC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(PromWLC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(PromWLC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(PromWLC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.02(0.02)0.08) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'PromWLCELHQ7Single.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'PromWLCELHQ7Single.pdf", replace

**# ON PAPER FIGURE: FTChangeSalaryGradeCELHQ7Single.pdf
* regression
********************************************************************************

eststo: reghdfe ChangeSalaryGradeC $LLH $LLL $FLH  $FLL   if ( (WL2==1& cohortSingle==1 & (FTLHB==1 | FTLLB==1) ) | (random==1) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label ChangeSalaryGradeC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(ChangeSalaryGradeC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.1(0.1)0.3) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'ChangeSalaryGradeCELHQ7Single.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'ChangeSalaryGradeCELHQ7Single.pdf", replace

* NEW HIRE ROBUSTNESS
**# ON PAPER FIGURE: FTTransferSJVCELHQ7New.pdf
* regression
********************************************************************************

eststo: reghdfe TransferSJVC $LLH $LLL $FLH  $FLL   if ( (WL2==1& TenureMin<1 & (FTLHB==1 | FTLLB==1) ) | (random==1 ) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label TransferSJVC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(TransferSJVC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferSJVC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferSJVC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.05(0.05)0.25) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7New.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7New.pdf", replace

**# ON PAPER FIGURE: FTTransferFuncCELHQ7New.pdf
* regression
********************************************************************************

eststo: reghdfe TransferFuncC $LLH $LLL $FLH  $FLL   if ( (WL2==1& TenureMin<1 & (FTLHB==1 | FTLLB==1) ) | (random==1 ) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR)

local lab: variable label TransferFuncC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(TransferFuncC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferFuncC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferFuncC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.05(0.05)0.15) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferFuncCELHQ7New.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferFuncCELHQ7New.pdf", replace

**# ON PAPER FIGURE: FTPromWLCELHQ7New.pdf
* regression
********************************************************************************

eststo: reghdfe PromWLC $LLH $LLL $FLH  $FLL   if ( (WL2==1& TenureMin<1 & (FTLHB==1 | FTLLB==1) ) | (random==1 ) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label PromWLC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(PromWLC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(PromWLC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(PromWLC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(0(0.02)0.1) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'PromWLCELHQ7New.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'PromWLCELHQ7New.pdf", replace

**# ON PAPER FIGURE: FTChangeSalaryGradeCELHQ7New.pdf
* regression
********************************************************************************

eststo: reghdfe ChangeSalaryGradeC $LLH $LLL $FLH  $FLL   if ( (WL2==1& TenureMin<1 & (FTLHB==1 | FTLLB==1) ) | (random==1 ) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 

local lab: variable label ChangeSalaryGradeC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(ChangeSalaryGradeC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.1(0.1)0.4) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'ChangeSalaryGradeCELHQ7New.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'ChangeSalaryGradeCELHQ7New.pdf", replace


* POISSON ROBUSTNESS
**# ON PAPER FIGURE: FTTransferSJVCELHQ7PO.pdf
********************************************************************************

eststo: ppmlhdfe TransferSJVC $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform

local lab: variable label TransferSJVC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(TransferSJVC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(TransferSJVC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(TransferSJVC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.5(0.1)0.5) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7PO.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'TransferSJVCELHQ7PO.pdf", replace

**# ON PAPER FIGURE: FTChangeSalaryGradeCELHQ7PO.pdf
* regression
********************************************************************************

eststo: ppmlhdfe ChangeSalaryGradeC $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform 

local lab: variable label ChangeSalaryGradeC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(ChangeSalaryGradeC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(ChangeSalaryGradeC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-0.4(0.1)0.4) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'ChangeSalaryGradeCELHQ7PO.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'ChangeSalaryGradeCELHQ7PO.pdf", replace

/**# ON PAPER FIGURE: FTPromWLCELHQ7PO.pdf
* regression
********************************************************************************

eststo: ppmlhdfe PromWLC $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) eform 

local lab: variable label PromWLC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(PromWLC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(`endF36') y(PromWLC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(PromWLC) type(`Label') // program 

* 36 / 84
tw scatter bQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=-`endFQ36' & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(-1.2(0.2)1.2) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'PromWLCELHQ7PO.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'PromWLCELHQ7PO.pdf", replace
*/

}

********************************************************************************
* LH vs LL: BONUS AND PAY
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

* MAIN 
**# ON PAPER FIGURE: LogPayPlotLHAE.png
* regression
********************************************************************************

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

**# ON PAPER FIGURE: LogPayBonusPlotLHAE.png
* regression
********************************************************************************

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

**# ON PAPER FIGURE: LogBonusPlotLHAE.png
* regression
********************************************************************************

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

} 


********************************************************************************
* LH vs LL: EXIT 
********************************************************************************

{
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

*MAIN
**# ON PAPER FIGURE: FTLeaverPermELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe LeaverPerm $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

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

* 0/84
tw scatter bQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84')  ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverPermELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverPermELHQ7.pdf", replace

**# ON PAPER FIGURE: FTLeaverVolELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe LeaverVol $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

local lab: variable label LeaverVol

* single differences 
*********************************************************************************
coeffExit1, c(`window') y(LeaverVol) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* quarterly
coeffExitQ1, c(`window') y(LeaverVol) type(`Label') // program 

* 0/84
tw scatter bQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverVolELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverVolELHQ7.pdf", replace

**# ON PAPER FIGURE: FTLeaverInvELHQ7.pdf
* regression
********************************************************************************

eststo: reghdfe LeaverInv $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

local lab: variable label LeaverInv

* single differences 
*********************************************************************************
coeffExit1, c(`window') y(LeaverInv) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* quarterly
coeffExitQ1, c(`window') y(LeaverInv) type(`Label') // program 

* 0/84
tw scatter bQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverInvELHQ7.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverInvELHQ7.pdf", replace


* MIDDLE COHORT ROBUSTNESS 
**# ON PAPER FIGURE: FTLeaverPermELHQ7Single.pdf
* regression
********************************************************************************

eststo: reghdfe LeaverPerm $event  if   KEi>-1 & WL2==1 & cohortSingle==1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // | (random==1 & Ei==.) 
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

* 0/84
tw scatter bQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84')  ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverPermELHQ7Single.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverPermELHQ7Single.pdf", replace

* NEW HIRES ROBUSTNESS
**# ON PAPER FIGURE: FTLeaverPermELHQ7New.pdf
* regression
********************************************************************************

eststo: reghdfe LeaverPerm $event  if   KEi>-1 & WL2==1 & TenureMin<1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // | (random==1 & Ei==.) 
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

* 0/84
tw scatter bQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQL1 if etQL1>=0 & etQL1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84')  ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverPermELHQ7New.gph", replace
graph export "$analysis/Results/0.Paper/2.2.Event LH/`Label'LeaverPermELHQ7New.pdf", replace
 
} 


********************************************************************************
* HL vs HH: MAIN 
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

* MAIN 
**# ON PAPER FIGURE: FTChangeSalaryGradeCEHLQ5.pdf
* regression
********************************************************************************

eststo: reghdfe ChangeSalaryGradeC $LHL  $LHH  $FHL  $FHH     if ( (WL2==1 & (FTHLB==1 | FTHHB==1)) | ( random==1  & FTHLB==0 & FTHHB==0) )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes

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
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/0.Paper/2.3.Event HL/`Label'ChangeSalaryGradeCEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.3.Event HL/`Label'ChangeSalaryGradeCEHLQ5.pdf", replace

**# ON PAPER FIGURE: FTPromWLCEHLQ5.pdf
* regression
********************************************************************************

eststo: reghdfe PromWLC $LHL  $LHH  $FHL  $FHH     if ( (WL2==1 & (FTHLB==1 | FTHHB==1)) | ( random==1  & FTHLB==0 & FTHHB==0) )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes

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
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/0.Paper/2.3.Event HL/`Label'PromWLCEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.3.Event HL/`Label'PromWLCEHLQ5.pdf", replace

**# ON PAPER FIGURE: FTTransferSJVCEHLQ5.pdf
* regression
********************************************************************************

eststo: reghdfe TransferSJVC $LHL  $LHH  $FHL  $FHH     if ( (WL2==1 & (FTHLB==1 | FTHHB==1)) | ( random==1  & FTHLB==0 & FTHHB==0) )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes

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
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/0.Paper/2.3.Event HL/`Label'TransferSJVCEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.3.Event HL/`Label'TransferSJVCEHLQ5.pdf", replace

**# ON PAPER FIGURE: FTTransferFuncCEHLQ5.pdf
* regression
********************************************************************************

eststo: reghdfe TransferFuncC $LHL  $LHH  $FHL  $FHH     if ( (WL2==1 & (FTHLB==1 | FTHHB==1)) | ( random==1  & FTHLB==0 & FTHHB==0) )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes

local lab: variable label TransferFuncC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffHL1, c(`window') y(TransferFuncC) type(`Label') // program 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrendHL , end(`endF36') y(TransferFuncC)
su jointH 
local jointH = round(r(mean), 0.001)

* quarterly
coeffQHL1, c(`window') y(TransferFuncC) type(`Label') // program 

* 36 / 60
tw scatter bQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=-`endFQ36' & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.2(0.1)0.2) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/0.Paper/2.3.Event HL/`Label'TransferFuncCEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.3.Event HL/`Label'TransferFuncCEHLQ5.pdf", replace


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

* MAIN
**# FIGURE previously on paper, but eliminated for now: LogPayBonusPlotHLE.png 
* regression
********************************************************************************

eststo: reghdfe LogPayBonus $LHL  $LHH  $FHL  $FHH     if ( (WL2==1 & (FTHLB==1 | FTHHB==1)) | ( random==1  & FTHLB==0 & FTHHB==0) )   , a( IDlse YearMonth )  vce(cluster IDlseMHR) // this regression is for all other outcomes

local lab: variable label LogPayBonus

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffHL1, c(`window') y(LogPayBonus) type(`Label') // program 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrendHL , end(12) y(LogPayBonus)
su jointH 
local jointH = round(r(mean), 0.001)

* quarterly
coeffQHL1, c(`window') y(LogPayBonus) type(`Label') // program 

xlincom (L36EHL - L36EHH) (L60EHL - L60EHH) (L84EHL - L84EHH) , level(95) post
est store LogPayBonus

coefplot  (LogPayBonus , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (LogPayBonus, keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (LogPayBonus , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(95)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(-0.4(0.1)0.4) note("Notes. Plotting estimates at 12, 20 and 28 quarters after manager transition. Reporting 95% confidence intervals.", span)
graph export "$analysis/Results/0.Paper/2.3.Event HL/LogPayBonusPlotHL.pdf", replace 
graph save "$analysis/Results/0.Paper/2.3.Event HL/LogPayBonusPlotHL.gph", replace

}

********************************************************************************
* HL vs HH: EXIT
********************************************************************************

{
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

* MAIN
**# ON PAPER FIGURE: FTLeaverPermEHLQ5.pdf 
* regression
********************************************************************************

eststo: reghdfe LeaverPerm $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

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
tw scatter bQH1 etQH1 if etQH1>=0 & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=0 & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  
graph save  "$analysis/Results/0.Paper/2.3.Event HL/`Label'LeaverPermEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.3.Event HL/`Label'LeaverPermEHLQ5.pdf", replace

**# ON PAPER FIGURE: FTLeaverVolEHLQ5.pdf 
* regression
********************************************************************************

eststo: reghdfe LeaverVol $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

local lab: variable label LeaverVol

* single differences 
*********************************************************************************
coeffExit1, c(`window') y(LeaverVol) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* quarterly
coeffExitQ1, c(`window') y(LeaverVol) type(`Label') // program 

* 0/60
tw scatter bQH1 etQH1 if etQH1>=0 & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=0 & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  
graph save  "$analysis/Results/0.Paper/2.3.Event HL/`Label'LeaverVolEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.3.Event HL/`Label'LeaverVolEHLQ5.pdf", replace

**# ON PAPER FIGURE: FTLeaverInvEHLQ5.pdf 
* regression
********************************************************************************

eststo: reghdfe LeaverInv $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

local lab: variable label LeaverInv

* single differences 
*********************************************************************************
coeffExit1, c(`window') y(LeaverInv) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* quarterly
coeffExitQ1, c(`window') y(LeaverInv) type(`Label') // program 

* 0/60
tw scatter bQH1 etQH1 if etQH1>=0 & etQH1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQH1 if etQH1>=0 & etQH1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  
graph save  "$analysis/Results/0.Paper/2.3.Event HL/`Label'LeaverInvEHLQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.3.Event HL/`Label'LeaverInvEHLQ5.pdf", replace

} 


********************************************************************************
* DUAL: MAIN
********************************************************************************
* uses "$managersdta/Temp/Random20vw.dta" instead of "$managersdta/Temp/Random50vw.dta" due to limited computation power 
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
global other ONETAbilitiesDistanceC // ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

* 1) separate values for salary
* 2) all other outcomes 
log using "$analysis/Results/4.Event/Keyoutcome", replace 
*log using "$analysis/Results/4.Event/other", replace 
*log using "$analysis/Results/4.Event/cohortSingle", replace 

* MAIN 
**# ON PAPER FIGURE: FTChangeSalaryGradeCDualQ5.pdf
* regression
********************************************************************************

eststo: reghdfe ChangeSalaryGradeC $event  if (WL2==1 | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

local lab: variable label ChangeSalaryGradeC

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(ChangeSalaryGradeC) // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`endF36') y(ChangeSalaryGradeC)
su joint
local joint = round(r(mean), 0.001)

* Quarterly
coeffQ, c(`window') y(ChangeSalaryGradeC) // program 

* 36 / 60
postDual , end(`endL60') y(ChangeSalaryGradeC)
su jointPost
local jointPost = round(r(mean), 0.001)

tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.4(0.2)0.4) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'ChangeSalaryGradeCDualQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'ChangeSalaryGradeCDualQ5.pdf", replace

**# ON PAPER FIGURE: FTPromWLCDualQ5.pdf
* regression
********************************************************************************

eststo: reghdfe PromWLC $event  if (WL2==1 | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

local lab: variable label PromWLC

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(PromWLC) // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`endF36') y(PromWLC)
su joint
local joint = round(r(mean), 0.001)

* Quarterly
coeffQ, c(`window') y(PromWLC) // program 

* 36 / 60
postDual , end(`endL60') y(PromWLC)
su jointPost
local jointPost = round(r(mean), 0.001)

tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.05(0.05)0.15) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'PromWLCDualQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'PromWLCDualQ5.pdf", replace

**# ON PAPER FIGURE: FTTransferSJVCDualQ5.pdf
* regression
********************************************************************************

eststo: reghdfe TransferSJVC $event  if (WL2==1 | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

local lab: variable label TransferSJVC

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(TransferSJVC) // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`endF36') y(TransferSJVC)
su joint
local joint = round(r(mean), 0.001)

* Quarterly
coeffQ, c(`window') y(TransferSJVC) // program 

* 36 / 60
postDual , end(`endL60') y(TransferSJVC)
su jointPost
local jointPost = round(r(mean), 0.001)

tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.2(0.1)0.2) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'TransferSJVCDualQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'TransferSJVCDualQ5.pdf", replace

**# ON PAPER FIGURE: FTTransferSJVCDualQ5.pdf
* regression
********************************************************************************

eststo: reghdfe TransferFuncC $event  if (WL2==1 | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

local lab: variable label TransferFuncC

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(TransferFuncC) // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`endF36') y(TransferFuncC)
su joint
local joint = round(r(mean), 0.001)

* Quarterly
coeffQ, c(`window') y(TransferFuncC) // program 

* 36 / 60
postDual , end(`endL60') y(TransferFuncC)
su jointPost
local jointPost = round(r(mean), 0.001)

tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(-0.15(0.05)0.1) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'TransferFuncCDualQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'TransferFuncCDualQ5.pdf", replace

log close 

}

********************************************************************************
* DUAL: EXIT
********************************************************************************

{
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

* MAIN 
**# ON PAPER FIGURE: FTLeaverPermDualQ5.pdf
* regression
********************************************************************************

eststo: reghdfe LeaverPerm $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

local lab: variable label LeaverPerm

* double differences  
*********************************************************************************

coeffExit, c(`window') y(LeaverPerm) // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

* quarterly
coeffExitQ, c(`window') y(LeaverPerm) // program 

* 0 / 84
tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ylabel(-0.04(0.01)0.04) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'LeaverPermDualQ5.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'LeaverPermDualQ5.pdf", replace

}
 