
/* RESIDUALIZED MEASURE 
reghdfe  ChangeSalaryGrade c.Tenure##c.Tenure##i.Female, a( i.Office i.WL i.Func i.AgeBand $controlMacro  ) residuals(ChangeSalaryGradeR)

reghdfe  ChangeSalaryGrade c.Tenure##c.Tenure##i.Female, a( i.IDlse i.AgeBand i.CountryYear  ) residuals(ChangeSalaryGradeR1) // individual FE

preserve 
keep ChangeSalaryGradeR1 IDlse YearMonth
save "$Managersdta/Temp/ChangeSalaryGradeR1.dta", replace 

*/
*ChangeSalaryGradeCPreS1y c.Tenure##c.Tenure##i.Female, a( i.Office i.WL i.Func i.AgeBand $controlMacro  )

* CUM MEAN 
********************************************************************************

use "$Managersdta/Managers.dta", clear 

merge 1:1 IDlse YearMonth using "$Managersdta/Temp/ChangeSalaryGradeR.dta"
*merge 1:1 IDlse YearMonth using "$Managersdta/Temp/ChangeSalaryGradeR1.dta"

xtset IDlse YearMonth
gen SpellMatch =  l6.Spell
gen IDlseMHRMatch = l6.IDlseMHR

bys IDlse IDlseMHRMatch: egen ChangeSalaryGradeRIDlseMHR = mean(ChangeSalaryGradeR) if IDlseMHRMatch !=.
bys IDlse Spell: gen t = 1 if YearMonth==SpellStart

preserve 
collapse ChangeSalaryGradeRIDlseMHR  (sum) t, by(IDlseMHR YearMonth)
drop if IDlseMHR ==.
bys IDlseMHR (YearMonth), sort: gen CumReporteesM = sum(t)
gen o = 1
bys IDlseMHR (YearMonth), sort: gen NN = sum(o)
bys IDlseMHR (YearMonth), sort: gen ChangeSalaryGradeRM = sum(ChangeSalaryGradeRIDlseMHR)
replace ChangeSalaryGradeRM = ChangeSalaryGradeRM / NN
xtset IDlseMHR YearMonth
gen lChangeSalaryGradeRM = l.ChangeSalaryGradeRM
gen lCumReporteesM  = l.CumReporteesM 
replace CumReporteesM = lCumReporteesM 
replace ChangeSalaryGradeRM = lChangeSalaryGradeRM
drop lChangeSalaryGradeRM NN lCumReporteesM  o 
*JobMatchPayIDlseMHR JobMatchSGIDlseMHR

save "$Managersdta/Temp/ChangeSalaryGradeRM.dta", replace 

* LOAD DATA
********************************************************************************

use "$Managersdta/Managers.dta", clear 

merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/ChangeSalaryGradeRM.dta", keepusing( ChangeSalaryGradeRM CumReporteesM )
drop _merge


bys IDlse Spell : egen z = max(cond(YearMonth == SpellStart, ChangeSalaryGradeRM,.))

replace ChangeSalaryGradeRM = z
drop z
egen ChangeSalaryGradeRMZ= std(ChangeSalaryGradeRM)

egen z = cut(CumReporteesM), group(6)
replace CumReporteesM = z
drop z

* Other variables 
bys IDlse Spell: egen LeaverPermS = max(LeaverPerm)

gen LogPayBonusPostT1yD = LogPayBonusPostT1y - LogPayBonusStartT
gen LogBonusPostT1y = log(BonusPostT1y)
gen LogBonusStartT = log(BonusStartT)
gen LogBonusPostT1yD = LogBonusPostT1y - LogBonusStartT
gen VPAPostT1yD = VPAPostT1y - VPAStartT
gen PRIPostT1yD = PRIPostT1y - PRIStartT
gen LogBonusStartS = log(BonusStartS)

replace WL =4 if WL >=4
replace WLM =4 if WLM >=4

*Controls 
global controlMacro CountryYear 


*labelling
label var ChangeSalaryGradeRMZ "M Prom."
label var LogBonus "Bonus (logs)"
label var LogPayBonus "Tot. Pay (logs)"
label var TransferPTitleC "Job Change"
label var LeaverPerm "Exit"
label var  PromSalaryGradeC "Promotion"
label var TransferPTitleDuringSpellC  "Job Change"
label var LogPayBonusPostT1yD "Change Tot. Pay"

********************************************************************************


* TEMP HIST 
********************************************************************************

use "$Managersdta/Temp/ChangeSalaryGradeRM.dta", clear 

hist ChangeSalaryGradeRM , color(green%80) frac xtitle("Manager Promotion Rate of Employees")
graph save "$Results/3.MProm/ChangeSalaryGradeRMhist.gph", replace
graph export "$Results/3.MProm/ChangeSalaryGradeRMhist.png", replace 
 
* TEMP HIST BY WL / Tenure 
********************************************************************************

preserve
keep ChangeSalaryGradeRM IDlseMHR WLM AgeBandM TenureM
save "$Managersdta/Temp/ChangeSalaryGradeRMChar.dta" , replace 
collapse ChangeSalaryGradeRM (max) WLM  , by(IDlseMHR )
label def WLM  1 "WL 1" 2 "WL 2" 3 "WL 3" 4 "WL 4+"
label value WLM WLM
hist  ChangeSalaryGradeRM,by(WLM, note("")) color(green%80) frac xtitle("Manager Promotion Rate of Employees")
graph export "$Results/3.Prom/ChangeSalaryGradeRMhistWL.png", replace 
use "$Managersdta/Temp/ChangeSalaryGradeRMChar.dta" , clear 
egen TenureBand = cut(TenureM), group(6)
collapse ChangeSalaryGradeRM (max) TenureBand   , by(IDlseMHR )
label def TenureBand 0 "Tenure 0-2" 1 "Tenure 3-5" 2 "Tenure 6-9" 3 "Tenure 10-15" 4 "Tenure 16-21" 5 "Tenure 22+" 
label value  TenureBand  TenureBand 
hist  ChangeSalaryGradeRM,by(TenureBand, note("")) color(green%80) frac xtitle("Manager Promotion Rate of Employees") 
graph export "$Results/3.Prom/ChangeSalaryGradeRMhistTenure.png", replace 


******************************************************************************** 


* Balance checks - MANAGER SEQUENCE 
********************************************************************************

* create previous manager quality 
gsort IDlse YearMonth
gen ChangeSalaryGradeRMZPreS1 = ChangeSalaryGradeRMZ[_n-1] if (IDlse == IDlse[_n-1] & IDlseMHR != IDlseMHR[_n-1] & IDlseMHR!=.  )
bys IDlse Spell: egen z = min(ChangeSalaryGradeRMZPreS1)
replace ChangeSalaryGradeRMZPreS1 = z 
drop z 

* does previous MQ predict the next manager quality 
eststo:  reghdfe  ChangeSalaryGradeRMZ  ChangeSalaryGradeRMZPreS1  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 & YearMonth == SpellStart   , a(  i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.CountryYear ) vce(cluster IDlseMHR )
estadd ysumm


* Balance checks - PRE-TRENDS 
********************************************************************************

* WC
eststo clear 

eststo:  reghdfe LogPayBonusPreS1y   ChangeSalaryGradeRMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0  , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm

eststo:  reghdfe LogBonusPreS1y   ChangeSalaryGradeRMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0  , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe PromSalaryGradeCPreS1y  ChangeSalaryGradeRMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe TransferPTitleCPreS1y    ChangeSalaryGradeRMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm

eststo:  reghdfe PRIPreS1y   ChangeSalaryGradeRMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm


*eststo:  reghdfe VPAPreS1y  JobMatchPayMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
*estadd ysumm


esttab using "$Results/3.Prom/BChangeSalaryGradeRMZWC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) keep(JobMatchPayMZ ) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


******************************************************************************** 


* RESULTS - Event study
******************************************************************************** 

* LogPayBonus
eststo clear
eststo: reghdfe  LogPayBonusPreS3y ChangeSalaryGradeRMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store A
eststo: reghdfe  LogPayBonusPreS2y ChangeSalaryGradeRMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store B
eststo: reghdfe  LogPayBonusPreS1y ChangeSalaryGradeRMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store C
eststo: reghdfe  LogPayBonus ChangeSalaryGradeRMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store D
eststo: reghdfe  LogPayBonus l12.ChangeSalaryGradeRMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store E
eststo: reghdfe  LogPayBonusPostS2y ChangeSalaryGradeRMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store F
eststo: reghdfe  LogPayBonusPostS3y ChangeSalaryGradeRMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store G
coefplot   B || C  || D  || E  || G , keep(*ChangeSalaryGradeRMZ*  ) rename( L12.ChangeSalaryGradeRMZ  = ChangeSalaryGradeRMZ  L24.ChangeSalaryGradeRMZ  = ChangeSalaryGradeRMZ  ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(   "Spell - 2"  "Spell - 1" "Spell" "Spell + 1" "Spell + 2" )  legend(off) ytitle("Tot. Pay (logs)")
graph export "$Results/3.Prom/LogPayBonusEvent.png", replace 

******************************************************************************** 


* HET
******************************************************************************** 

eststo clear
eststo: reghdfe  TransferPTitleDuringSpellC c.ChangeSalaryGradeRMZ##c.LogPayBonusStartS c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleDuringSpellC c.ChangeSalaryGradeRMZ##c.PRIStartS  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a(  i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  ) vce(cluster IDlseMHR)
estadd ysumm
*eststo: reghdfe  TransferPTitleC c.MSGLMeanZ##c.LogBonusStartS Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
*estadd ysumm
eststo: reghdfe LogPayBonusPostT1yD  ChangeSalaryGradeRMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a(   i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm
*reghdfe LogBonusPostT1yD   MSGLMeanZ Tenure TenureM if BC==0 , a( i.WLM $controlMacro ) vce(cluster IDlseMHR )
esttab using "$Results/3.Prom/JobMatchPayMZHETWC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) keep(ChangeSalaryGradeRMZ LogPayBonusStartS c.ChangeSalaryGradeRMZ#c.LogPayBonusStartS c.ChangeSalaryGradeRMZ#c.PRIStartS PRIStartS) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

*TEMP Results 
******************************************************************************** 
eststo clear 
eststo: reghdfe  LogPayBonus ChangeSalaryGradeRM  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM   if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonus ChangeSalaryGradeRM   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM   if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleC ChangeSalaryGradeRM   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM   if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC ChangeSalaryGradeRM   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LeaverPerm ChangeSalaryGradeRM  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM   if BC ==0, a(  i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  ) vce(cluster IDlseMHR)
estadd ysumm

esttab,  label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)

esttab using "$Results/3.Prom/ChangeSalaryGradeRMWC.tex",  stats( ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels("Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


