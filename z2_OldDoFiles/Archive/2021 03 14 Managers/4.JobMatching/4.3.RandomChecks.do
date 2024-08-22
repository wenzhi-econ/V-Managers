********************************************************************************
* JOB MATCHING - balance checks 
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

gen LogBonusPreS1y = log(BonusPreS1y)


label var  JobMatchPayMZ "M Match Value"
label var LogPayBonusPreS1y "log(Pay + Bonus)pre1year"
label var LogBonusPreS1y "log(Bonus)pre1year"
label var PRIPreS1y "Perf. Score pre1year"
label var PRIPreS2y "Perf. Score pre2year"
label var VPAPreS1y "V. Perf. Score pre1year"
label var VPAPreS2y "V. Perf. Score pre2year"
label var LogPayBonusPreS1y "log(Tot. Pay)pre1year"
label var PromSalaryGradeCPreS1y "Promotionspre1year"
label var TransferPTitleCPreS1y "Job Changespre1year"

* Balance checks
********************************************************************************

* WC
eststo clear 

eststo:  reghdfe LogPayBonusPreS1y   JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0  , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm

eststo:  reghdfe LogBonusPreS1y   JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0  , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe PromSalaryGradeCPreS1y  JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm

eststo: reghdfe TransferPTitleCPreS1y    JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm

eststo:  reghdfe PRIPreS1y   JobMatchPayDMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
estadd ysumm


*eststo:  reghdfe VPAPreS1y  JobMatchPayMZ c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 , a( i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM ) vce(cluster IDlseMHR )
*estadd ysumm


esttab using "$Results/4.3.RandomChecks/JobMatchPayMZWC.tex",  stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) keep(JobMatchPayMZ ) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace

* BALANCE TABLE 
permute JobMatchSGDMZ , strata(WL WLM AgeBand AgeBandM)

* MANAGER SEQUENCE 
********************************************************************************
* create previous manager quality 

gsort IDlse YearMonth
gen JobMatchPayMZPreS1 = JobMatchPayMZ[_n-1] if (IDlse == IDlse[_n-1] & IDlseMHR != IDlseMHR[_n-1] & IDlseMHR!=.  )
bys IDlse Spell: egen z = min(JobMatchPayMZPreS1)
replace JobMatchPayMZPreS1 = z 
drop z 

* Diff
gsort IDlse YearMonth
gen JobMatchPayDMZPreS1 = JobMatchPayDMZ[_n-1] if (IDlse == IDlse[_n-1] & IDlseMHR != IDlseMHR[_n-1] & IDlseMHR!=.  )
bys IDlse Spell: egen z = min(JobMatchPayDMZPreS1)
replace JobMatchPayDMZPreS1 = z 
drop z 

gsort IDlse YearMonth
gen JobMatchSGDMZPreS1 = JobMatchSGDMZ[_n-1] if (IDlse == IDlse[_n-1] & IDlseMHR != IDlseMHR[_n-1] & IDlseMHR!=.  )
bys IDlse Spell: egen z = min(JobMatchSGDMZPreS1)
replace JobMatchSGDMZPreS1 = z 
drop z 

*gsort IDlse YearMonth
*gen JobMatchSGMZPreS1 = JobMatchSGMZ[_n-1] if (IDlse == IDlse[_n-1] & IDlseMHR != IDlseMHR[_n-1] & IDlseMHR!=.  )
*bys IDlse Spell: egen z = min(JobMatchSGMZPreS1)
*replace JobMatchSGMZPreS1 = z 
*drop z 

* does previous MQ predict the next manager quality 
eststo clear 
eststo:  reghdfe  JobMatchPayDMZ  JobMatchPayDMZPreS1   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 & YearMonth == SpellStart   , a(  i.IDlse    i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.CountryYear ) vce(cluster IDlseMHR )
estadd ysumm
esttab using "$Results/4.3.RandomChecks/Path.tex",  keep(JobMatchPayDMZPreS1) stats(ymean r2 N, fmt(%9.3f %9.3f %9.0g)  labels( "Mean" "R-squared" "Number of obs.")) label  se r2 nonotes star(* 0.10 ** 0.05 *** 0.01)   replace


eststo:  reghdfe  JobMatchPayDMZ  JobMatchPayDMZPreS1   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 & YearMonth == SpellStart   , a(  i.IDlse   i.WL  i.IDlseMHR i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.CountryYear ) vce(cluster IDlseMHR )
estadd ysumm


eststo:  reghdfe  JobMatchSGDMZ  JobMatchSGDMZPreS1   c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0 & YearMonth == SpellStart   , a(  i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM i.CumReporteesM i.TeamSizeC) vce(cluster IDlseMHR )
estadd ysumm

*eststo:  reghdfe JobMatchSGMZ   JobMatchSGMZPreS1 c.Tenure##c.Tenure##i.Female c.TenureM##i.FemaleM  if BC==0    , a(  i.IDlse   i.WL  i.AgeBand i.WLM i.AgeBandM ) vce(cluster IDlseMHR )
*estadd ysumm

* Rankings - follow the steps of [Adhvaryu et al. (2020)]
forval q = 0(1)9{ 
xtile  JobMatchPayDMZQ`q'= JobMatchPayDMZ if TenureBandM==`q', n(4)
xtile  JobMatchPayDMZPreS1Q`q'= JobMatchPayDMZPreS1 if TenureBandM==`q', n(4)
}

egen JobMatchPayDMZQ = rowmean(JobMatchPayDMZQ*) 
egen JobMatchPayDMZPreS1Q = rowmean(JobMatchPayDMZPreS1Q*) 

gen Group = 11     if  JobMatchPayDMZPreS1Q == 1 &   JobMatchPayDMZQ == 1
replace  Group = 12 if JobMatchPayDMZPreS1Q == 1 &   JobMatchPayDMZQ == 2
replace  Group = 13 if JobMatchPayDMZPreS1Q == 1 &  JobMatchPayDMZQ == 3
replace  Group = 14 if JobMatchPayDMZPreS1Q == 1 &  JobMatchPayDMZQ == 4
replace  Group = 41 if JobMatchPayDMZPreS1Q == 4 &  JobMatchPayDMZQ == 1
replace  Group = 42 if JobMatchPayDMZPreS1Q == 4 &  JobMatchPayDMZQ == 2
replace  Group = 43 if JobMatchPayDMZPreS1Q == 4 &  JobMatchPayDMZQ == 3
replace  Group = 44 if JobMatchPayDMZPreS1Q == 4 &  JobMatchPayDMZQ == 4

reghdfe  LogPayBonus c.Tenure##c.Tenure##i.Female c.TenureM##c.TenureM##i.FemaleM , a( i.AgeBand i.CountryYear i.AgeBandM     )  residuals( LogPayBonusR)

gsort IDlse YearMonth
gen LogPayBonusRPreS1 = LogPayBonusR[_n-1] if (IDlse == IDlse[_n-1] & IDlseMHR != IDlseMHR[_n-1] & IDlseMHR!=.  )
bys IDlse Spell: egen z = min(LogPayBonusRPreS1)
replace LogPayBonusRPreS1 = z 
drop z 

graph bar  LogPayBonusRPreS1  LogPayBonusR , over(Group)
