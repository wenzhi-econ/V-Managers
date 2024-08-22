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

* Table

eststo clear 
eststo: reghdfe  LogPayBonus JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 & YearMonth>=tm(2016m1), a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonus JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 & YearMonth>=tm(2016m1), a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  TransferPTitleC JobMatchPayMZ   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 & YearMonth>=tm(2016m1), a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 & YearMonth>=tm(2016m1), a( i.IDlse i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LeaverPerm  JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 & YearMonth>=tm(2016m1), a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/4.2.JobMatchingReg/JobMatchPayMZWC.tex",  keep(JobMatchPayMZ) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


* Table diff 

eststo clear 
eststo: reghdfe  TransferSubFunc JobMatchPayDMZ   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogPayBonus JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonus JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeC JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  VPA  JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/4.2.JobMatchingReg/JobMatchPayDMZWC.tex",  keep(JobMatchPayDMZ) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


* Change in outcomes after 1 year 

gen   LogBonusPostS1y = log(  BonusPostS1y)

eststo clear 
eststo: reghdfe  TransferSubFuncCPostS1y JobMatchPayDMZ   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogPayBonusPostS1y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonusPostS1y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeCPostS1y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  VPAPostS1y  JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/4.2.JobMatchingReg/JobMatchPayDMZWCPostS1y.tex",  keep(JobMatchPayDMZ) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


* Change in outcomes after 2 year 

gen   LogBonusPostS2y = log(  BonusPostS2y)

eststo clear 
eststo: reghdfe  TransferSubFuncCPostS2y JobMatchPayDMZ   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogPayBonusPostS2y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  LogBonusPostS2y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  PromSalaryGradeCPostS2y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.IDlse i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estadd ysumm
eststo: reghdfe  VPAPostS2y  JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0 , a( i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estadd ysumm
esttab using "$Results/4.2.JobMatchingReg/JobMatchPayDMZWCPostS2y.tex",  keep(JobMatchPayDMZ) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* Event study LogPayBonus
eststo clear
eststo: reghdfe  LogPayBonus f24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store A
eststo: reghdfe  LogPayBonusPreS1y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR) // not working 
estimates store B
eststo: reghdfe  LogPayBonus JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store C
eststo: reghdfe  LogPayBonus l12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store D
eststo: reghdfe  LogPayBonus l24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store E
coefplot   A || B || C  || D  || E , keep(*JobMatchPayDMZ*) rename( F24.JobMatchPayDMZ = JobMatchPayDMZ F12.JobMatchPayDMZ = JobMatchPayDMZ L12.JobMatchPayDMZ = JobMatchPayDMZ L24.JobMatchPayDMZ = JobMatchPayDMZ ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(   "- 2"  "- 1" "0" "1" "2" )  legend(off) ytitle("Tot. Pay (logs)")
graph export "$Results/4.2.JobMatchingReg/LogPayBonusEvent.png", replace 

* Event study transfer 
eststo: reghdfe  TransferSubFunc f24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR) // not working
estimates store TRB
eststo: reghdfe  TransferSubFunc f12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store TRC
eststo: reghdfe  TransferSubFunc JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store TRD
eststo: reghdfe  TransferSubFunc l12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store TRE
eststo: reghdfe  TransferSubFunc l24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store TRF

coefplot  CSGC || TRC  || TRD  || TRE || TRF , keep(*JobMatchPayDMZ*) rename( F24.JobMatchPayDMZ = JobMatchPayDMZ F12.JobMatchPayDMZ = JobMatchPayDMZ L12.JobMatchPayDMZ = JobMatchPayDMZ L24.JobMatchPayDMZ = JobMatchPayDMZ ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(   "- 2"  "- 1" "0" "1" "2" )  legend(off) ytitle("Job Change")
graph export "$Results/4.2.JobMatchingReg/JobChangeEvent.png", replace 


* Event study promotion

eststo: reghdfe PromSalaryGrade f24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR) // not working 
estimates store CSGB
eststo: reghdfe PromSalaryGrade f12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store CSGC
eststo: reghdfe  PromSalaryGrade JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store CSGD
eststo: reghdfe  PromSalaryGradeC l12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store CSGE
eststo: reghdfe  PromSalaryGradeC l24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store CSGF

coefplot  TRC  || CSGC  || CSGD  || CSGE || CSGF  , keep(*JobMatchPayDMZ*) rename( F24.JobMatchPayDMZ = JobMatchPayDMZ F12.JobMatchPayDMZ = JobMatchPayDMZ L12.JobMatchPayDMZ = JobMatchPayDMZ L24.JobMatchPayDMZ = JobMatchPayDMZ ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(   "- 2"  "- 1" "0" "1" "2" )  legend(off) ytitle("Promotion")
graph export "$Results/4.2.JobMatchingReg/PromEvent.png", replace 



*  Event study Exit 
eststo clear
eststo: reghdfe  LeaverPerm JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a(   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store DE
eststo: reghdfe  LeaverPerm l12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a(  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store EE
eststo: reghdfe  LeaverPerm l24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a(   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store FE
coefplot  DE  || EE  || FE , keep(*JobMatchPayDMZ*) rename( L12.JobMatchPayDMZ = JobMatchPayDMZ L24.JobMatchPayDMZ = JobMatchPayDMZ ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(   "0" "1" "2" )  legend(off) ytitle("Exit")
graph export "$Results/4.2.JobMatchingReg/ExitEvent.png", replace 


* BC 

* Event study LogPayBonus

eststo: reghdfe  LogPayBonus f24.JobMatchSGDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BCA
eststo: reghdfe  LogPayBonus f12.JobMatchSGDMZ   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BCB
eststo: reghdfe  LogPayBonus JobMatchSGDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BCC
eststo: reghdfe  LogPayBonus l12.JobMatchSGDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BCD
eststo: reghdfe  LogPayBonus l24.JobMatchSGDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BCE
coefplot   BCA || BCB || BCC  || BCD  || BCE , keep(*JobMatchPayDMZ*) rename( F24.JobMatchPayDMZ = JobMatchPayDMZ F12.JobMatchPayDMZ = JobMatchPayDMZ L12.JobMatchPayDMZ = JobMatchPayDMZ L24.JobMatchPayDMZ = JobMatchPayDMZ ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(   "- 2"  "- 1" "0" "1" "2" )  legend(off) ytitle("Tot. Pay (logs)")
graph export "$Results/4.2.JobMatchingReg/BCLogPayBonusEvent.png", replace 


* Event study transfer 
eststo: reghdfe  TransferSubFunc f24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR) 
estimates store BCTRB
eststo: reghdfe  TransferSubFunc f12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BCTRC
eststo: reghdfe  TransferSubFunc JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BCTRD
eststo: reghdfe  TransferSubFunc l12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store BCTRE
eststo: reghdfe  TransferSubFunc l24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==1, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store BCTRF

coefplot  BCTRB || BCTRC  || BCTRD  || BCTRE || BCTRF , keep(*JobMatchPayDMZ*) rename( F24.JobMatchPayDMZ = JobMatchPayDMZ F12.JobMatchPayDMZ = JobMatchPayDMZ L12.JobMatchPayDMZ = JobMatchPayDMZ L24.JobMatchPayDMZ = JobMatchPayDMZ ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(   "- 2"  "- 1" "0" "1" "2" )  legend(off) ytitle("Job Change")
graph export "$Results/4.2.JobMatchingReg/BCJobChangeEvent.png", replace 

/* Event study LogPayBonus: 
eststo clear
eststo: reghdfe  LogPayBonusPreS3y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store A
eststo: reghdfe  LogPayBonusPreS2y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store B
eststo: reghdfe  LogPayBonusPreS1y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store C
eststo: reghdfe  LogPayBonus JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store D
eststo: reghdfe  LogPayBonus l12.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store E
eststo: reghdfe  LogPayBonus L24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store F
eststo: reghdfe  LogPayBonus L36.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store G
coefplot   B || C  || D  || E  || G , keep(JobMatchPayDMZ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(   "Spell - 2"  "Spell - 1" "Spell" "Spell + 1" "Spell + 2" )  legend(off) ytitle("Tot. Pay (logs)")
graph export "$Results/4.2.JobMatchingReg/LogPayBonusEvent.png", replace 


*  Event study Promotion 
eststo clear
eststo: reghdfe  PromSalaryGradeCPreS3y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store AP
eststo: reghdfe  PromSalaryGradeCPreS2y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BP
eststo: reghdfe  PromSalaryGradeCPreS1y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store CP
eststo: reghdfe  PromSalaryGradeC JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store DP
eststo: reghdfe  PromSalaryGradeCPostS2y JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store EP
eststo: reghdfe  PromSalaryGradeC l24.JobMatchPayDMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store FP
eststo: reghdfe  PromSalaryGradeC l36.JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store GP
coefplot  BP || CP  || DP  || EP  || FP , keep(*JobMatchPayMZ*  ) rename( L12.JobMatchPayMZ = JobMatchPayMZ L24.JobMatchPayMZ = JobMatchPayMZ )  levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(  "Spell - 2"  "Spell - 1" "Spell" "Spell + 1" "Spell + 2")  legend(off) ytitle("No. Promotions")
graph export "$Results/4.2.JobMatchingReg/PromEvent.png", replace 


*  Event study Transfers  
eststo clear
eststo: reghdfe  TransferPTitleCPreS3y JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store AT
eststo: reghdfe  TransferPTitleCPreS2y JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store BT
eststo: reghdfe  TransferPTitleCPreS1y JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store CT
eststo: reghdfe  TransferPTitleC JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR)
estimates store DT
eststo: reghdfe  TransferPTitleC l12.JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store ET
eststo: reghdfe  TransferPTitleC l24.JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store FT
eststo: reghdfe  TransferPTitleC l36.JobMatchPayMZ  c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC ==0, a( i.IDlse  i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM) vce(cluster IDlseMHR)
estimates store GT
coefplot  BT || CT  || DT  || ET  || FT , keep(*JobMatchPayMZ) rename( L12.JobMatchPayMZ = JobMatchPayMZ L24.JobMatchPayMZ = JobMatchPayMZ ) levels(90 ) vertical xtitle(Leads and lags) yline(0)  bycoefs bylabels(  "Spell - 2"  "Spell - 1" "Spell" "Spell + 1" "Spell + 2")  legend(off) ytitle("No. Job Changes")
graph export "$Results/4.2.JobMatchingReg/TransfersEvent.png", replace 


