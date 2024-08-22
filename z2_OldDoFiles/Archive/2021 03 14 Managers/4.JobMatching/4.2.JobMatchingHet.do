********************************************************************************
* JOB MATCHING - regressions 
********************************************************************************

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"
use "$Managersdta/Managers.dta", clear

replace WL =4 if WL >=4
replace WLM =4 if WLM >=4

merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/JobMatchM.dta", keepusing( JobMatchSGM JobMatchPayM CumReporteesM )
drop _merge

replace JobMatchPayM = . if YearMonth < = tm(2015m12)

bys IDlse Spell : egen zSG = max(cond(YearMonth == SpellStart, JobMatchSGM,.))
bys IDlse Spell : egen zPay = max(cond(YearMonth == SpellStart, JobMatchPayM,.))

replace JobMatchSGM = zSG
replace JobMatchPayM = zPay

egen JobMatchSGMZ= std(JobMatchSGM)
egen JobMatchPayMZ= std(JobMatchPayM)

egen z = cut(CumReporteesM), group(6)
replace CumReporteesM = z
drop z

xtset IDlse YearMonth
label var  JobMatchPayMZ "M Match Value"
label var  JobMatchPayDMZ "M Match Value"

gen LogBonusStartS = log(BonusStartS)
gen LogBonusPostT1y = log(BonusPostT1y)
gen LogBonusStartT = log(BonusStartT)
gen LogPayBonusPostT1yD = LogPayBonusPostT1y - LogPayBonusStartT
gen LogBonusPostT1yD = LogBonusPostT1y - LogBonusStartT
gen VPAPostT1yD = VPAPostT1y - VPAStartT
gen PRIPostT1yD = PRIPostT1y - PRIStartT

* Table

eststo clear
eststo: reghdfe  TransferPTitleDuringSpellC c.JobMatchPayMZ##c.LogPayBonusStartS c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleDuringSpellC c.JobMatchPayMZ##c.PRIStartS  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a(  i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM  ) vce(cluster IDlseMHR)
estadd ysumm
*eststo: reghdfe  TransferPTitleC c.MSGLMeanZ##c.LogBonusStartS Tenure TenureM  if BC ==0, a( i.IDlse i.WLM $controlMacro  ) vce(cluster IDlseMHR)
*estadd ysumm
eststo: reghdfe LogPayBonusPostT1yD  JobMatchPayMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a(   i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm
*reghdfe LogBonusPostT1yD   MSGLMeanZ Tenure TenureM if BC==0 , a( i.WLM $controlMacro ) vce(cluster IDlseMHR )
esttab using "$Results/4.2.JobMatchingReg/JobMatchPayMZHETWC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) keep(JobMatchPayMZ LogPayBonusStartS c.JobMatchPayMZ#c.LogPayBonusStartS c.JobMatchPayMZ#c.PRIStartS PRIStartS) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


* Table DIFF

eststo clear
eststo: reghdfe LogPayBonusPostT1yD  JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a(   i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.TeamSizeC ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe LogBonusPostT1yD  JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a(   i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.TeamSizeC ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe PRIPostT1yD  JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a(   i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.TeamSizeC ) vce(cluster IDlseMHR )
estadd ysumm


esttab using "$Results/4.2.JobMatchingReg/ChangeJobMatchPayDMZWC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) keep(JobMatchPayDMZ ) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace



