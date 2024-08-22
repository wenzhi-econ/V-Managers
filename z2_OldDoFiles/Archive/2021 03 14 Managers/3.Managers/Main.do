use "$Managersdta/Managers.dta", clear 

merge 1:1 IDlse YearMonth using "$Managersdta/Temp/ChangeSalaryGradeR.dta"

/* LEAVE OUT MEAN 
reghdfe  ChangeSalaryGrade c.Tenure##c.Tenure##i.Female, a( i.Office i.WL i.Func i.AgeBand $controlMacro  ) residuals(ChangeSalaryGradeR)

preserve 
keep ChangeSalaryGradeR IDlse YearMonth
save "$Managersdta/Temp/ChangeSalaryGradeR.dta", replace 
*PropChangeSG 
*/
*ChangeSalaryGradeCPreS1y c.Tenure##c.Tenure##i.Female, a( i.Office i.WL i.Func i.AgeBand $controlMacro  )

* LEAVE OUT MEAN  Raw
egen t = tag(IDlse IDlseMHR)
bys IDlseMHR: egen MSize = total(t)
*bys IDlseMHR: egen MSize = count(IDlse)
bys IDlseMHR: egen MSGTot= total(ChangeSalaryGradeR)
bys IDlseMHR IDlse: egen MSGTotW = total(ChangeSalaryGradeR)
*bys IDlseMHR IDlse: egen ESize = count(IDlse)
gen MSGLMean = (MSGTot - MSGTotW)/(MSize-1)
replace MSGLMean = . if IDlseMHR ==.
egen MSGLMeanZ = std(MSGLMean)

* LEAVE OUT MEAN  Residualized 
bys IDlseMHR: egen MSGTotR= total(ChangeSalaryGradeR)
bys IDlseMHR IDlse: egen MSGTotWR = total(ChangeSalaryGradeR)
gen MSGLMeanR = (MSGTotR - MSGTotWR)/(MSize-1)
replace MSGLMeanR = . if IDlseMHR ==.
egen MSGLMeanRZ = std(MSGLMeanR)

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

/* HIST 
keep MSGLMeanZ MSGLMeanRZ IDlseMHR
collapse MSGLMeanZ MSGLMeanRZ , by(IDlseMHR)
save "$Managersdta/Temp/MSGLMeanRZ.dta", replace 

hist MSGLMeanRZ , color(green%80) frac xtitle("Manager Promotion Rate of Employees")
graph save "$Results/3.2.ManagerReg/MSGLMeanRZhist.gph", replace
graph export "$Results/3.2.ManagerReg/MSGLMeanRZhist.png", replace 
 
* HIST BY WL / Tenure 
keep MSGLMeanZ MSGLMeanRZ IDlseMHR WLM AgeBandM TenureM
save "$Managersdta/Temp/MSGLMeanRZMChar.dta" , replace 
collapse MSGLMeanRZ (max) WLM  , by(IDlseMHR )
label def WLM  1 "WL 1" 2 "WL 2" 3 "WL 3" 4 "WL 4+"
label value WLM WLM
hist  MSGLMeanRZ,by(WLM, note("")) color(green%80) frac xtitle("Manager Promotion Rate of Employees")
graph export "$Results/3.2.ManagerReg/MSGLMeanRZhistWL.png", replace 
use "$Managersdta/Temp/MSGLMeanRZMChar.dta" , clear 
egen TenureBand = cut(TenureM), group(6)
collapse MSGLMeanRZ (max) TenureBand   , by(IDlseMHR )
label def TenureBand 0 "Tenure 0-2" 1 "Tenure 3-5" 2 "Tenure 6-9" 3 "Tenure 10-15" 4 "Tenure 16-21" 5 "Tenure 22+" 
label value  TenureBand  TenureBand 
hist  MSGLMeanRZ,by(TenureBand, note("")) color(green%80) frac xtitle("Manager Promotion Rate of Employees") 
graph export "$Results/3.2.ManagerReg/MSGLMeanRZhistTenure.png", replace 
*/
*gen ChangeSalaryGradePostS1yD = ChangeSalaryGradeCPostS1y - ChangeSalaryGradeC

*Controls 
global controlMacro CountryYear 


*labelling
label var MSGLMeanZ "M Prom."
label var MSGLMeanRZ "M Prom."
label var LogBonus "Bonus (logs)"
label var LogPayBonus "Tot. Pay (logs)"
label var TransferPTitleC "Job Change"
label var LeaverPerm "Exit"
label var  PromSalaryGradeC "Promotion"
label var TransferPTitleDuringSpellC  "Job Change"
label var LogPayBonusPostT1yD "Change Tot. Pay"


/* Residualize outcomes 
reghdfe  LogPayBonus c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM $controlMacro  ) vce(cluster IDlseMHR) residuals(LogPayBonusR)
reghdfe  LogBonus c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL i.AgeBand i.WLM i.AgeBandM $controlMacro  ) vce(cluster IDlseMHR) residuals(LogBonusR)
reghdfe  TransferPTitleC c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL i.AgeBand i.WLM i.AgeBandM $controlMacro  ) vce(cluster IDlseMHR) residuals(TransferPTitleCR)
reghdfe  TransferPTitleLateralC c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL i.AgeBand i.WLM i.AgeBandM $controlMacro  ) vce(cluster IDlseMHR) residuals(TransferPTitleLateralCR)
reghdfe  PromSalaryGradeC c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM $controlMacro  ) vce(cluster IDlseMHR) residuals(PromSalaryGradeCR)
reghdfe  LeaverPerm c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM $controlMacro  ) vce(cluster IDlseMHR) residuals(LeaverPermR)
reghdfe  TransferPTitleDuringSpellC c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM $controlMacro ) vce(cluster IDlseMHR) residuals(TransferPTitleDuringSpellCR)
reghdfe  LogPayBonusPostT1yD c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM $controlMacro  ) vce(cluster IDlseMHR) residuals(LogPayBonusPostT1yDR)
*/

*TABLE 1: WC
******************************************************************************** 
eststo clear 
eststo: reghdfe  LogPayBonus MSGLMeanZ  Tenure TenureM   if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonus MSGLMeanZ  Tenure TenureM   if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleC MSGLMeanZ  Tenure TenureM   if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC MSGLMeanZ  Tenure TenureM   if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LeaverPerm  MSGLMeanZ Tenure TenureM   if BC ==0, a(  i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm

esttab,  label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)

esttab using "$Results/3.2.ManagerReg/MSGLMeanZMainWC.tex",  stats( ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels("Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* residualized 
eststo clear 
eststo: reghdfe  LogPayBonus MSGLMeanRZ  Tenure TenureM   if BC ==0, a( i.IDlse i.WLM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonus MSGLMeanRZ  Tenure TenureM   if BC ==0, a( i.IDlse i.WLM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleC MSGLMeanRZ  Tenure TenureM   if BC ==0, a( i.IDlse i.WLM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC MSGLMeanRZ  Tenure TenureM   if BC ==0, a( i.IDlse i.WLM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LeaverPerm  MSGLMeanRZ Tenure TenureM   if BC ==0, a(  i.WLM  ) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/3.2.ManagerReg/MSGLMeanRZMainWC.tex",  keep(MSGLMeanRZ) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* full controls 

eststo clear 
eststo: reghdfe  LogPayBonus MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonus MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleC MSGLMeanRZ   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LeaverPerm  MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/3.2.ManagerReg/MSGLMeanRZMainWC.tex",  keep(MSGLMeanRZ) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* BC 

eststo clear 
eststo: reghdfe  LogPayBonus MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse    i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonus MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse     i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleC MSGLMeanRZ   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse   i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse   i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LeaverPerm  MSGLMeanRZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a(  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/3.2.ManagerReg/MSGLMeanRZMainBC.tex",  keep(MSGLMeanRZ) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

*HET 
********************************************************************************
eststo clear
eststo: reghdfe  TransferPTitleDuringSpellC c.MSGLMeanZ##c.LogPayBonusStartS c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL i.AgeBand i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleDuringSpellC c.MSGLMeanZ##c.PRIStartS  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL i.AgeBand  i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
*eststo: reghdfe  TransferPTitleC c.MSGLMeanZ##c.LogBonusStartS Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
*estadd ysumm
eststo: reghdfe LogPayBonusPostT1yD   MSGLMeanZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a(  i.IDlse  i.WL i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm
*reghdfe LogBonusPostT1yD   MSGLMeanZ Tenure TenureM if BC==0 , a( i.WLM $controlMacro ) vce(cluster IDlseMHR )
esttab using "$Results/3.2.ManagerReg/MSGLMeanZHETWC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) keep(MSGLMeanRZ LogPayBonusStartS c.MSGLMeanRZ#c.LogPayBonusStartS c.MSGLMeanRZ#c.PRIStartS PRIStartS) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

*residualized 
eststo clear
eststo: reghdfe  TransferPTitleDuringSpellC c.MSGLMeanRZ##c.LogPayBonusStartS c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL i.AgeBand i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleDuringSpellC c.MSGLMeanRZ##c.PRIStartS  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL i.AgeBand  i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
*eststo: reghdfe  TransferPTitleC c.MSGLMeanZ##c.LogBonusStartS Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
*estadd ysumm
eststo: reghdfe  LeaverPerm c.MSGLMeanRZ##c.LogPayBonusStartS c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL i.AgeBand i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LeaverPerm c.MSGLMeanRZ##c.PRIStartS  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL i.AgeBand  i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe LogPayBonusPostT1yD   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a(  i.IDlse  i.WL i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm
*reghdfe LogBonusPostT1yD   MSGLMeanZ Tenure TenureM if BC==0 , a( i.WLM $controlMacro ) vce(cluster IDlseMHR )
esttab using "$Results/3.2.ManagerReg/MSGLMeanZHETWC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


*residualized BC
eststo clear
eststo: reghdfe  TransferPTitleDuringSpellC c.MSGLMeanRZ##c.LogPayBonusStartS c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse   i.AgeBand i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleDuringSpellC c.MSGLMeanRZ##c.PRIStartS  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse   i.AgeBand  i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleDuringSpellC c.MSGLMeanRZ##c.LogBonusStartS  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse   i.AgeBand  i.WLM i.AgeBandM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe LogPayBonusPostT1yD   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==1 , a(  i.IDlse  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm
*reghdfe LogBonusPostT1yD   MSGLMeanZ Tenure TenureM if BC==0 , a( i.WLM $controlMacro ) vce(cluster IDlseMHR )
esttab using "$Results/3.2.ManagerReg/MSGLMeanZHETBC.tex",  keep(MSGLMeanRZ LogPayBonusStartS c.MSGLMeanRZ#c.LogPayBonusStartS c.MSGLMeanRZ#c.PRIStartS PRIStartS) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


* DYNAMICS 
********************************************************************************
eststo clear
eststo: reghdfe  LogPayBonus MSGLMeanZ  l24.MSGLMeanZ Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC MSGLMeanZ  l24.MSGLMeanZ Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe LeaverPerm MSGLMeanZ  l24.MSGLMeanZ Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/3.2.ManagerReg/MSGLMeanZDynWC.tex",  stats( ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* residualized 
eststo clear
eststo: reghdfe  LogPayBonus MSGLMeanRZ  l24.MSGLMeanRZ Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC MSGLMeanRZ  l24.MSGLMeanRZ Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe LeaverPerm MSGLMeanRZ  l24.MSGLMeanRZ Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/3.2.ManagerReg/MSGLMeanRZDynWC.tex",  stats( ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

********************************************************************************
/* ARCHIVE

* no results 
reghdfe  LeaverPermS  MFESGWCZ   if BC ==0, a(  i.WLM $controlMacro  ) vce(cluster IDlseMHR)

*Results
reghdfe  TransferPTitleDuringSpellC c.MFESGWCZ##c.LogPayBonusStartS  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)

reghdfe  TransferPTitleDuringSpellC c.MFESGWCZ##c.PRIStartS  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
 
 
