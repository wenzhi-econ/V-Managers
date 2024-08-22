********************************************************************************
* This dofile looks at managers of BC & WC workers 
********************************************************************************

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

use "$Managersdta/Managers.dta", clear
merge 1:1 IDlse YearMonth using "$Managersdta/ChangeSalaryGradeR.dta"

replace WL = 4 if WL >=4
replace  WLM = 4 if WLM >=4

gen PromSpeed = 1/(TimetoProm )
foreach i in M StartS  PostS1y  PostS2y PostS3y PreS1y  PreS2y PreS3y StartSM  PostS1yM  PostS2yM PostS3yM PreS1yM  PreS2yM PreS3yM StartT  PostT1y PreT1y {
    gen PromSpeed`i' = 1/(TimetoProm`i' )
}
 

gen ChangeSalaryGradePreS1yD = ChangeSalaryGradeCPreS1y - ChangeSalaryGradeCPreS2y

gen LogBonusPreS1y = log(BonusPreS1y)
gen LogPayPreS1y = log(PayPreS1y)
gen LogBonusPreS2y = log(BonusPreS2y)

egen t = tag(IDlse IDlseMHR)
bys IDlseMHR: egen MSize = total(t)
*bys IDlseMHR: egen MSize = count(IDlse)
bys IDlseMHR: egen MSGTot= total(ChangeSalaryGrade)
bys IDlseMHR IDlse: egen MSGTotW = total(ChangeSalaryGrade)
*bys IDlseMHR IDlse: egen ESize = count(IDlse)
*gen MSGLMean = (MSGTot - MSGTotW)/(MSize-ESize)
gen MSGLMean = (MSGTot - MSGTotW)/(MSize-1)
replace MSGLMean = . if IDlseMHR==.
egen MSGLMeanZ = std(MSGLMean)

bys IDlseMHR: egen MSGTotR= total(ChangeSalaryGradeR)
bys IDlseMHR IDlse: egen MSGTotWR = total(ChangeSalaryGradeR)
gen MSGLMeanR = (MSGTotR - MSGTotWR)/(MSize-1)
replace MSGLMeanR = . if IDlseMHR==.
egen MSGLMeanRZ = std(MSGLMeanR)


label var  MSGLMeanZ "M Prom Rate of Reportees"
label var  MSGLMeanRZ "M Prom Rate of Reportees"
label var LogBonusPreS1y "log(Bonus)pre1year"
label var LogBonusPreS2y "log(Bonus)pre2year"
label var PRIPreS1y "Perf. Score pre1year"
label var PRIPreS2y "Perf. Score pre2year"
label var VPAPreS1y "V. Perf. Score pre1year"
label var VPAPreS2y "V. Perf. Score pre2year"
label var LogPayBonusPreS1y "log(Tot. Pay)pre1year"
label var LogPayBonusPreS2y "log(Tot. Pay)pre2year"
label var PromSalaryGradeCPreS1y "Promotionpre1year"
label var TransferPTitleCPreS1y "Job Changepre1year"

* MANAGER SEQUENCE 
********************************************************************************
* create previous manager quality 
gsort IDlse YearMonth
gen MSGLMeanRZPreS1 = MSGLMeanRZ[_n-1] if (IDlse == IDlse[_n-1] & IDlseMHR != IDlseMHR[_n-1] & IDlseMHR!=.  )
bys IDlse Spell: egen z = min(MSGLMeanRZPreS1)
replace MSGLMeanRZPreS1 = z 
drop z 

eststo:  reghdfe MSGLMeanRZ MSGLMeanRZPreS1   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )

* Rankings 
xtile  MSGLMeanRZPreS1Q= MSGLMeanRZPreS1, n(4)
xtile  MSGLMeanRZQ= MSGLMeanRZ, n(4)

gen Group = 1 if MSGLMeanRZPreS1Q == 1 &  MSGLMeanRZQ == 1
replace Group = 12 if MSGLMeanRZPreS1Q == 1 &  MSGLMeanRZQ == 2
replace  Group = 13 if MSGLMeanRZPreS1Q == 1 &  MSGLMeanRZQ == 3
replace  Group = 14 if MSGLMeanRZPreS1Q == 1 &  MSGLMeanRZQ == 4
replace  Group = 4 if MSGLMeanRZPreS1Q == 4 &  MSGLMeanRZQ == 4
replace  Group = 41 if MSGLMeanRZPreS1Q == 4 &  MSGLMeanRZQ == 1
replace  Group = 42 if MSGLMeanRZPreS1Q == 4 &  MSGLMeanRZQ == 2
replace  Group = 43 if MSGLMeanRZPreS1Q == 4 &  MSGLMeanRZQ == 3
replace  Group = 44 if MSGLMeanRZPreS1Q == 4 &  MSGLMeanRZQ == 4

reghdfe  LogPayBonusPreS1y c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear ) vce(cluster IDlseMHR) residuals(LogPayBonusPreS1yR)

reghdfe  LogPayBonusPreS2y c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear ) vce(cluster IDlseMHR) residuals(LogPayBonusPreS2yR)

reghdfe  LogPayBonus c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear ) vce(cluster IDlseMHR) residuals(LogPayBonusR)

reghdfe  LogPayBonusPostS1y c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear ) vce(cluster IDlseMHR) residuals(LogPayBonusPostS1yR)

reghdfe  LogPayBonusPostS2y c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC ==0, a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CountryYear ) vce(cluster IDlseMHR) residuals(LogPayBonusPostS2yR)

gen LogPayResiduals = 

tw graph dot LogPayBonusPreS2yR LogPayBonusPreS1yR LogPayBonusR LogPayBonusPostS1yR LogPayBonusPostS2yR if Group== 1 || 

* Balance checks
********************************************************************************

* WC
eststo clear 

eststo:  reghdfe LogBonusPreS1y   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe PromSalaryGradeCPreS1y   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe TransferPTitleCPreS1y    MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm

eststo:  reghdfe PRIPreS1y   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm


eststo:  reghdfe VPAPreS1y   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm


esttab using "$Results/3.0.RandomChecks/MSGLMeanRZWC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) keep(MSGLMeanRZ ) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


* BC

eststo clear 

eststo:  reghdfe LogBonusPreS1y   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==1 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe PromSalaryGradeCPreS2y   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==1 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe TransferPTitleCPreS2y    MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==1 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm

eststo:  reghdfe PRIPreS1y   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==1 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm


eststo:  reghdfe VPAPreS1y   MSGLMeanRZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==1 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
estadd ysumm


esttab using "$Results/3.0.RandomChecks/MSGLMeanRZBC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) keep(MSGLMeanRZ ) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace




