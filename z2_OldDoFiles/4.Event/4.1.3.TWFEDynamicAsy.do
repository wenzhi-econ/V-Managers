********************************************************************************
* Dynamic TWFE model - Asymmetric
********************************************************************************

* Set globals 
********************************************************************************

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

* choose the manager type !MANUAL INPUT!
global Label  FT  // PromWL75 PromSG75 PromWL50 PromSG50  FT odd  pcaFTSG50 pcaFTWL50  pcaFTSG75 pcaFTWL75

global cont   c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse   // alternative, to try WLM AgeBandM YearMonth AgeBand Tenure
global exitFE   WLM  AgeBandM AgeBand CountryYear Func Female

global analysis  "/Users/virginiaminni/Desktop/Managers Temp" // temp for the results 

////////////////////////////////////////////////////////////////////////////////
* 1) 30 months window 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 
*use  "$managersdta/AllSameTeam.dta", clear 

* only work level 2 managers 
bys IDlse: egen FirstWL2M = max(cond(WLM==2 & KEi==-1,1,0))
bys IDlse: egen LastWL2M = max(cond(WLM==2 & KEi==0,1,0))
gen WL2 = FirstWL2M ==1 & LastWL2M ==1

keep if WL2 ==1 

bys IDlse: egen FirstChange = max(cond(ChangeMC ==ChangeMR & ChangeMR ==1, 1,0))
bys IDlse: egen MinAge = min(AgeBand)
label val MinAge AgeBand
* Looking at the middle cohorts 
format Ei %tm 
gen cohort30 = 1 if Ei >=tm(2014m1) & Ei <=tm(2017m9) // cohorts that have at least 30 months pre and after manager rotation 

* if I cut the window, I can do 12 months pre and then 60 after 
gen cohort60 = 1 if Ei >=tm(2012m1) & Ei <=tm(2015m3) // cohorts that have at least 30 months pre and after manager rotation 

* Sample of new hires 
bys IDlse: egen NewHireInd = max(NewHire)
egen CountryYear = group(Country Year)

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

* take out events that involve the incoming manager getting promoted 
bys IDlse: egen EiR = mean(cond(PromWLM==0 & ChangeSalaryGradeM==0 & (TransferInternalM==1 | TransferSJM==1) & YearMonth==Ei, Ei, .))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii
*keep if ii==1

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
local endD = 60
foreach var in LL LH HL HH {
forval i=20(10)`endD'{
	gen endL`var'`i' = KE`var'>`i' & KE`var'!=.
	gen endF`var'`i' = KE`var'< -`i' & KE`var'!=.
}
}

local end = 30
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

* Time invariant indicators for type of event 
local Label $Label
bys IDlse: egen `Label'LL = max(`Label'LowLow)
bys IDlse: egen `Label'LH = max(`Label'LowHigh)
bys IDlse: egen `Label'HL = max(`Label'HighLow)
bys IDlse: egen `Label'HH = max(`Label'HighHigh)

* add social connections 
* these variables take value 1 for the entire duration of the manager-employee spell, 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/MTransferConnectedAll.dta", keepusing( ///
Connected ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4 ///
ConnectedC ConnectedManagerC ConnectedSubFuncC ConnectedOfficeC ConnectedOrg4C ///
ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
ConnectedLC ConnectedManagerLC ConnectedSubFuncLC ConnectedOfficeLC ConnectedOrg4LC ///
ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ConnectedVC ConnectedManagerVC ConnectedSubFuncVC ConnectedOfficeVC ConnectedOrg4VC ) 
drop if _merge ==2
drop _merge 

label var Connected "Move within manager's network"
label var ConnectedL "Lateral move within manager's network"
label var ConnectedV "Prom. within manager's network"

********************************* REGRESSIONS **********************************

* LABEL VARS
label var ChangeSalaryGradeC "Prom. (salary)"
label var ChangeSalaryGradeSameMC "Prom. (salary), same manager"
label var ChangeSalaryGradeDiffMC "Prom. (salary), diff. manager"
label var PromWLC "Prom. (work-level)"
label var PromWLSameMC "Prom. (work-level), same manager"
label var PromWLDiffMC "Prom. (work-level), diff. manager"
label var PromWLVC "Prom., vertical (work-level)"
label var TransferInternalC "Transfer (sub-func)"
label var TransferInternalSameMC "Transfer (sub-func), same manager"
label var TransferInternalDiffMC "Transfer (sub-func), diff. manager"
label var TransferInternalLLC "Transfer (sub-func), lateral"
label var TransferInternalVC "Transfer (sub-func), vertical"
label var TransferSJC "Job Transfer"
label var TransferSJSameMC "Job Transfer, same manager"
label var TransferSJDiffMC "Job Transfer, diff. manager"
label var TransferSJLLC "Job Transfer, lateral"
label var TransferSJVC "Job Transfer, vertical"
label var TransferFuncC "Transfer (function)"
label var TransferSubFuncC "Transfer (sub-function)"

* Same versus diff manager 
global diffM ChangeSalaryGradeDiffMC PromWLDiffMC  TransferInternalDiffMC TransferSJDiffMC // TransferInternalSJDiffMC
global sameM ChangeSalaryGradeSameMC PromWLSameMC  TransferInternalSameMC TransferSJSameMC // TransferInternalSJSameMC

* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in
local Label $Label
foreach  y in    TransferSJLLC TransferSJC PromWLC   TransferSJLLC TransferInternalLLC  TransferFuncC TransferInternalC  ChangeSalaryGradeC  ONETDistanceBC  $diffM $sameM TransferInternalVC  PromWLVC { // DiffField 
eststo: reghdfe `y' $event  , a( IDlse YearMonth Tenure   ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.png", replace
}

////////////////////////////////////////////////////////////////////////////////
* 2) 12 months window - PAY
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

local end = 24 // to be plugged in 
local window = 49 // to be plugged in 


* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii
*keep if ii==1

keep if LogPayBonus!=.
*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

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

*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen endL`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen endF`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

********************************* REGRESSIONS **********************************

*LABEL VARS
label var LogPayBonus "Pay + bonus (logs)"

egen CountryYear = group(Country Year)

local Label $Label 
foreach  y in   LogPayBonus {
eststo: reghdfe `y' $event $cont if WLM2==1 , a( $abs  ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.png", replace
}

////////////////////////////////////////////////////////////////////////////////
* 3) 12 months window - VPA
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

local end = 12 // to be plugged in 
local window = 25 // to be plugged in 

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

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
* Other outcomes 
gen VPA100 = VPA>=100 if VPA!=.
gen VPA115 = VPA>=115 if VPA!=.

*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen endL`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen endF`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

********************************* REGRESSIONS **********************************

*LABEL VARS
label var VPA "Perf. Appraisals"
label var VPA100 "Perf. Appraisals>=100"
label var VPA115 "Perf. Appraisals>=115"
label var VPA125 "Perf. Appraisals>=125"

egen CountryYear = group(Country Year)
local Label $Label
foreach  y in VPA VPA100 VPA115 VPA125 {
eststo: reghdfe `y' $event $cont if WLM2==1 , a( $abs   ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.png", replace
}

////////////////////////////////////////////////////////////////////////////////
* 4) 12 months window - PRODUCTIVITY
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

local end = 12 // to be plugged in 
local window = 25 // to be plugged in 

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

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

*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen endL`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen endF`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

********************************* REGRESSIONS **********************************

*LABEL VARS
label var ProductivityStd "Productivity (standardized)"

egen CountryYear = group(Country Year)
local Label $Label
foreach  y in   ProductivityStd {
eststo: reghdfe `y' $event $cont, a( $abs   ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.png", replace
}

///////////////////////////////////////////////////////////////////////////////
* 5) EXIT
///////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

local end = 30 // to be plugged in 
local window = 61 // to be plugged in

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

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

* if binning 
foreach var in LL LH HL HH {
forval i=20(10)`end'{
	gen endL`var'`i' = KE`var'>`i' & KE`var'!=.
	gen endF`var'`i' = KE`var'< -`i' & KE`var'!=.
}
}

* create list of event indicators if binning  
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LExitLH $LExitLL $LExitHL  $LExitHH  // binning 

**************************** REGRESSIONS ***************************************

*LABEL VARS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"

egen CountryYear = group(Country Year)

local window = 61 // to be plugged in
local end = 30 // to be plugged in 
local Label $Label
foreach  y in   LeaverPerm LeaverVol LeaverInv {
eststo: reghdfe `y' $event $cont if WLM2==1 , a( $exitFE   ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeffExit, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.01)

 tw connected b1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(3)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.png", replace

* single differences 
coeffExit1, c(`window') y(`y') // program 

 tw connected bL1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.png", replace

 tw connected bH1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=0 & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.png", replace
} 

