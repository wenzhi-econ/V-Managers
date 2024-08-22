* This dofile looks at lateral moves 
* This dofile looks at ONET measures of skill distance 
********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* TABLEs Transfers and changes in skill distance 
********************************************************************************

use "$Managersdta/AllSnapshotMCultureMType2015.dta", clear 
xtset IDlse YearMonth
gen ONETActivitiesDistanceCB = ONETActivitiesDistanceC>0 if ONETActivitiesDistanceC!=. 
gen ONETActivitiesDistanceCB1 = ONETActivitiesDistanceC>0 if ONETActivitiesDistanceC!=. 
replace ONETActivitiesDistanceCB1 = 0 if ONETActivitiesDistanceC==. 

* L transfers 
label var EarlyAge2015M "Fast track M."
eststo clear 
foreach v in TransferInternalC  TransferInternalSameMC  TransferInternalDiffMC TransferFuncC ONETActivitiesDistanceCB1 {
local lbl : variable label `v'
mean `v' if IDlseMHR!=. &  EarlyAge2015M!=. 
mat coef=e(b)
local cmean = coef[1,1]
count if  `v' !=. & IDlseMHR!=. &  EarlyAge2015M!=. 
local N1 = r(N)
eststo: reghdfe `v' EarlyAge2015M c.Tenure##c.Tenure c.TenureM##c.TenureM TeamSize , a( AgeBand CountryYM AgeBandM FemaleM IDlse) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
}
* more transfers but entirely under different manager (under same manager there is no difference)
esttab using "$analysis/Results/5.Transfers/TransfersLDist.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2, labels("Controls" "Employee FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")  nobaselevels  drop(_cons TeamSize Tenure c.Tenure#c.Tenure TenureM c.TenureM#c.TenureM ) ///
 nomtitles mgroups("Transfers all (lateral)" "Same M." "Diff. M."  "Transfer Function" "Task distance > 0" , pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, function FE, team size, age group FE , gender, tenure and tenure squared of manager and employee. ///
"\end{tablenotes}") replace

* LL transfers & transfers all 
eststo clear 
foreach v in TransferInternalSJLLC  TransferInternalSJSameMLLC  TransferInternalSJDiffMLLC TransferInternalSJC  TransferInternalSJSameMC  TransferInternalSJDiffMC  {
local lbl : variable label `v'
mean `v' if IDlseMHR!=. &  EarlyAge2015M!=. &  ONETActivitiesDistanceCB !=.
mat coef=e(b)
local cmean = coef[1,1]
count if  `v' !=. & IDlseMHR!=. &  EarlyAge2015M!=. &  ONETActivitiesDistanceCB !=.
local N1 = r(N)
eststo: reghdfe `v' EarlyAge2015M c.Tenure##c.Tenure c.TenureM##c.TenureM TeamSize , a( AgeBand CountryYM AgeBandM FemaleM IDlse) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
}

esttab using "$analysis/Results/5.Transfers/TransfersLDist2.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2, labels("Controls" "Employee FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")  nobaselevels  drop(_cons TeamSize Tenure c.Tenure#c.Tenure TenureM c.TenureM#c.TenureM ) ///
 nomtitles mgroups("Transfers all (lateral)" "Same M." "Diff. M." "Transfers all (lateral)" "Same M." "Diff. M.", pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, function FE, team size, age group FE , gender, tenure and tenure squared of manager and employee. ///
"\end{tablenotes}") replace

collapse LogPayBonus  Tenure  ONETActivitiesDistanceC ONETActivitiesDistanceCB ONETActivitiesDistanceCB1 AgeContinuous  TransferInternalSJDiffM TeamSize (max) TransferInternalSJSameMC TransferInternalSJDiffMC TransferInternalSJSameMLC TransferInternalSJSameML TransferInternalSJDiffML TransferInternalSJDiffMLC  TransferInternalSJSameM EarlyAge2015M EarlyAgeM WLM AgeBandM FemaleM TenureM WL Func SubFunc Female AgeBand  Country LeaverVol LeaverPerm PromWL ChangeSalaryGrade VPA (count) SJTenure = YearMonth, by(IDlse   TransferInternalSJC)

label var SJTenure "Past occ. tenure"
label var ONETActivitiesDistanceC "Task Distance"
label var ONETActivitiesDistanceCB "Task Distance > 0"
label var LogPayBonus "Past Wages (logs)"
label var EarlyAgeM "Fast track M."

su  SJTenure 
replace SJTenure = SJTenure/12 // years 
su  SJTenure 

xtset IDlse TransferInternalSJC

* PAY & DISTANCE by fast track - binscatter 
********************************************************************************
gen LogVPA = log(VPA + 1 )
gen changePay = d.LogPayBonus
gen changeVPA = d.LogVPA
gen changeEarlyAgeM = d.EarlyAgeM
gen L1EarlyAgeM= L.EarlyAgeM
gen L1EarlyAge2015M= L.EarlyAge2015M
gen L1VPA= L.VPA

gen VPA125 = VPA>124 if VPA!=.
gen VPA115 = VPA>115 if VPA!=.

gen DChangeSalaryGrade  = d.ChangeSalaryGrade 

label define fast 0 "Non fast track" 1 "Fast track"
label value L1EarlyAgeM fast 
label var L1EarlyAge2015M "Fast track"

label value EarlyAgeM fast

eststo clear 
mean LogPayBonus if  L1EarlyAge2015M!=. 
mat coef=e(b)
local cmean = coef[1,1]
count if  LogPayBonus !=. & L1EarlyAge2015M!=. 
local N1 = r(N)
eststo all: reghdfe LogPayBonus L1EarlyAge2015M c.Tenure##c.Tenure  c.TenureM##c.TenureM , a(AgeBand AgeBandM FemaleM IDlse) cluster(IDlse)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
eststo same: reghdfe LogPayBonus L1EarlyAge2015M c.Tenure##c.Tenure c.TenureM##c.TenureM if  TransferInternalSJSameM==1 , a(AgeBand AgeBandM FemaleM IDlse) cluster(IDlse)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
eststo diff: reghdfe LogPayBonus L1EarlyAge2015M c.Tenure##c.Tenure c.TenureM##c.TenureM if  TransferInternalSJSameM==0 , a(AgeBand AgeBandM FemaleM IDlse) cluster(IDlse)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

esttab using "$analysis/Results/5.Transfers/CompAdv.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2, labels("Controls" "Employee FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")  nobaselevels  drop(_cons Tenure c.Tenure#c.Tenure TenureM c.TenureM#c.TenureM ) ///
 nomtitles mgroups("Pay + bonus (logs) - all transfers" "Same M." "Diff. M."  "Transfer Function" "Task distance > 0" , pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-job. Controls include: country x year FE, age group FE , gender, tenure and tenure squared of manager and employee. ///
"\end{tablenotes}") replace


coefplot all same diff, rescale(100) ///
keep(*EarlyAgeM) levels(99 95 90) ///
ciopts(lwidth(2 ..) lcolor(ebblue*.2 ebblue*.6 ebblue*1)) legend(order(1 "99" 2 "95" 3 "90") rows(1)) msymbol(d) mcolor(white) eqrename(all = "Any lateral job move" same = "Under same manager" diff = "Under diff manager")  ///
swapnames aseq ///
note("Standard errors clustered at the employee level. 99, 95, 90% Confidence Intervals." "Specifications include employee FE, tenure, tenure squared, age and gender of manager controls.", span size(small)) ///
title("total compensation after a job transfer" " % difference between fast track and other managers", pos(12) span si(vlarge)) ///
graphregion(margin(15 10 2 2)) coeflabels(, angle(30)) vertical ysize(6) xsize(8) scheme(aurora) ytick(#6,grid glcolor(black)) scale(0.9) 
graph export "$analysis/Results/5.Transfers/TransfersPay.png", replace 


headings(low = "{bf:Job change, same M.}" high = "{bf:Job change, diff. M.}" ) ///


eststo clear 
eststo low: reghdfe changePay c.Tenure##c.Tenure if  TransferInternalSJSameM==1 &  changeEarlyAgeM==0 & EarlyAgeM==0, a(Country AgeContinuous Female Func ) vce(cluster IDlse) // random sorting 
eststo high: reghdfe changePay c.Tenure##c.Tenure if  TransferInternalSJSameM==1 &  changeEarlyAgeM==0 & EarlyAgeM==1, a(Country AgeContinuous Female Func ) vce(cluster IDlse) // random sorting 
eststo low1: reghdfe changePay c.Tenure##c.Tenure if   changeEarlyAgeM==0 & EarlyAgeM==0, a(Country AgeContinuous Female Func ) vce(cluster IDlse) // random sorting 
eststo high1: reghdfe changePay c.Tenure##c.Tenure if   changeEarlyAgeM==0 & EarlyAgeM==1, a(Country AgeContinuous Female Func ) vce(cluster IDlse) // random sorting

coefplot (low high ) (low1 high1), ///
keep(_cons) levels(99 95 90) ///
ciopts(lwidth(2 ..) lcolor(ebblue*.2 ebblue*.6 ebblue*1)) legend(order(1 "99" 2 "95" 3 "90") rows(1)) msymbol(d) mcolor(white) eqrename(low = "No, same M." high = "Fast track, same M." low1 = "No, diff. M." high1 = "Fast track, diff. M.")  ///
headings(low = "{bf:Job change, same M.}" high = "{bf:Job change, diff. M.}" ) ///
swapnames aseq ///
note("Standard errors clustered at the employee level. Specifications include Country FE, tenure, tenure squared," "age and gender controls." "99, 95, 90% Confidence Intervals. Change in pay after job transfer.", span size(small)) ///
title("Change in Pay" " ", pos(12) span si(vlarge)) ///
graphregion(margin(15 10 2 2)) coeflabels(, angle(30)) vertical ysize(6) xsize(8) scheme(aurora) ytick(#6,grid glcolor(black)) scale(0.9) yline(0,lpattern(solid))
graph export "$analysis/Results/5.Transfers/CompAdv.png", replace 

reghdfe changeVPA c.Tenure##c.Tenure if   ChangeSalaryGrade==0& changeEarlyAgeM==0 & EarlyAgeM==0, a(CountryYM AgeContinuous Female  ) vce(cluster IDlse) // random sorting 
reghdfe changeVPA c.Tenure##c.Tenure if   ChangeSalaryGrade==0& changeEarlyAgeM==0 & EarlyAgeM==1, a(CountryYM AgeContinuous Female ) vce(cluster IDlse) // comparative advantage 
reghdfe changePay c.Tenure##c.Tenure if   ChangeSalaryGrade==0& changeEarlyAgeM==0 & EarlyAgeM==0, a(CountryYM AgeContinuous Female ) vce(cluster IDlse) // random sorting 
reghdfe changePay c.Tenure##c.Tenure if   ChangeSalaryGrade==0& changeEarlyAgeM==0 & EarlyAgeM==1, a(CountryYM AgeContinuous Female ) vce(cluster IDlse) // comparative advantage 

reghdfe changeVPA c.Tenure##c.Tenure if  TransferInternalSJSameM==1 & changeEarlyAgeM==0 & EarlyAgeM==0, a(CountryYM AgeContinuous Female  ) vce(cluster IDlse) // random sorting 
reghdfe changeVPA c.Tenure##c.Tenure if  TransferInternalSJSameM==1 &  changeEarlyAgeM==0 & EarlyAgeM==1, a(CountryYM AgeContinuous Female  ) vce(cluster IDlse) // random sorting 
reghdfe changePay c.Tenure##c.Tenure if  TransferInternalSJSameM==1 &  changeEarlyAgeM==0 & EarlyAgeM==0, a(CountryYM AgeContinuous Female  ) vce(cluster IDlse) // random sorting 
reghdfe changePay c.Tenure##c.Tenure if  TransferInternalSJSameM==1 &  changeEarlyAgeM==0 & EarlyAgeM==1, a(CountryYM AgeContinuous Female  ) vce(cluster IDlse) // random sorting 


reghdfe ChangeSalaryGrade c.Tenure##c.Tenure if  TransferInternalSJSameM==1 & changeEarlyAgeM==0 & EarlyAgeM==0, a(CountryYM AgeContinuous Female   ) vce(cluster IDlse) // random sorting 
reghdfe ChangeSalaryGrade c.Tenure##c.Tenure if  TransferInternalSJSameM==1 &  changeEarlyAgeM==0 & EarlyAgeM==1, a(CountryYM AgeContinuous Female IDlse ) vce(cluster IDlse) // random sorting 
reghdfe PromWL c.Tenure##c.Tenure if  TransferInternalSJSameM==1 &  changeEarlyAgeM==0 & EarlyAgeM==0, a(CountryYM AgeContinuous Female  ) vce(cluster IDlse) // random sorting 
reghdfe  PromWL c.Tenure##c.Tenure if  TransferInternalSJSameM==1 &  changeEarlyAgeM==0 & EarlyAgeM==1, a(CountryYM AgeContinuous Female IDlse ) vce(cluster IDlse) // random sorting 

* FIGUREs
* works well
cibar  changeVPA if   DChangeSalaryGrade==0& changeEarlyAgeM==0, over(  L1EarlyAgeM )
cibar  changePay if   DChangeSalaryGrade==0& changeEarlyAgeM==0, over(  L1EarlyAgeM )

set scheme burd5
grstyle init
grstyle set plain, horizontal grid
cibar  changePay if   DChangeSalaryGrade==0&   TransferInternalSJSameM>0 & changeEarlyAgeM==0, over(  L1EarlyAgeM ) graphopts(ytitle("% change in pay following" "job transfer under same manager", size(medlarge)) ) barc(navy maroon)
graph export  "$analysis/Results/5.Transfers/ChangePayTransfer.png", replace

cibar  changeVPA if   DChangeSalaryGrade==0&   TransferInternalSJSameM>0 & changeEarlyAgeM==0, over(  L1EarlyAgeM )
binscatter changePay  L1EarlyAgeM, by(ONETActivitiesDistanceCB)   absorb(CountryYM  )  controls(Tenure Female)
binscatter changeVPA  L1EarlyAgeM, by(ONETActivitiesDistanceCB)   absorb(CountryYM  )  controls(Tenure Female)
binscatter changeVPA  L1EarlyAgeM,  absorb(CountryYM  )  controls(Tenure Female) ytitle(Change in performance appraisal) xtitle(Fast track manager)
binscatter changePay  L1EarlyAgeM,  absorb(CountryYM  )  controls(Tenure Female) ytitle(Change in salary (%)) xtitle(Fast track manager)

* Talent Hoarding 
********************************************************************************

gen VPAHigh = VPA >115 if VPA!=.
reghdfe ChangeSalaryGrade c.l.VPA##i.EarlyAgeM c.Tenure##c.Tenure   , a(CountryYM AgeBand Female ) vce(cluster IDlse)

reghdfe ChangeSalaryGrade c.VPA##i.EarlyAgeM c.Tenure##c.Tenure   , a(CountryYM AgeBand Female ) vce(cluster IDlse)
reghdfe ChangeSalaryGrade VPAHigh##i.EarlyAgeM c.Tenure##c.Tenure   , a(CountryYM AgeBand Female ) vce(cluster IDlse)
reghdfe ChangeSalaryGrade l.VPAHigh##l.i.EarlyAgeM c.Tenure##c.Tenure   , a(CountryYM AgeBand Female ) vce(cluster IDlse)

********************************************************************************
* PAY & DISTANCE by fast track 
********************************************************************************

eststo clear
eststo: reghdfe LogPayBonus i.ONETActivitiesDistanceCB##i.l.EarlyAgeM c.Tenure##c.Tenure   , a(CountryYM AgeBand Female ) vce(cluster IDlse)
estadd local EFE "No" , replace
eststo: reghdfe LogPayBonus ONETActivitiesDistanceCB##l.EarlyAgeM c.Tenure##c.Tenure   , a(CountryYM IDlse ) vce(cluster IDlse)
estadd local EFE "Yes" , replace
eststo: reghdfe PromWL ONETActivitiesDistanceCB##l.EarlyAgeM c.Tenure##c.Tenure   , a(CountryYM  AgeBand Female  ) vce(cluster IDlse)
estadd local EFE "No" , replace
eststo: reghdfe PromWL ONETActivitiesDistanceCB##l.EarlyAgeM c.Tenure##c.Tenure   , a(CountryYM  IDlse ) vce(cluster IDlse)
estadd local EFE "Yes" , replace
eststo: reghdfe LeaverVol ONETActivitiesDistanceCB##l.EarlyAgeM  c.Tenure##c.Tenure   , a(CountryYM  AgeBand Female   ) vce(cluster IDlse)
estadd local EFE "No" , replace
esttab,   se r2 star(* 0.10 ** 0.05 *** 0.01) nobaselevels drop(     _cons Tenure  c.Tenure#c.Tenure )
esttab  using "$Results/5.Transfers/WageMovesFastTrack.tex", label  se r2 star(* 0.10 ** 0.05 *** 0.01)   ///
nomtitles   nobase    ///
mgroups(  "Pay + bonus (logs)" "Prom (WL)" "Vol. Exit", pattern(1 0 1 0 1   )  prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) s( EFE   r2 N, labels("Employee FE" "\hline R-squared" "N" ) )  nobase drop(     _cons Tenure  c.Tenure#c.Tenure ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-occ. Sample restricted to individuals that change job at least once. Controls for: tenure, tenure squared, gender FE, age group FE, CountryxYear FE. Standard errors clustered at the individual level. "\end{tablenotes}") replace

eststo clear
eststo: reghdfe LogPayBonus ONETActivitiesDistanceCB##c.l.SJTenure c.Tenure##c.Tenure   , a(CountryYM AgeBand Female ) vce(cluster IDlse)
estadd local FuncFE "No" , replace
estadd local SubFuncFE "No" , replace
eststo: reghdfe LogPayBonus ONETActivitiesDistanceCB##c.l.SJTenure c.Tenure##c.Tenure   , a(CountryYM Func AgeBand Female ) vce(cluster IDlse)
estadd local FuncFE "Yes" , replace
estadd local SubFuncFE "No" , replace
eststo: reghdfe LogPayBonus ONETActivitiesDistanceCB##c.l.SJTenure c.Tenure##c.Tenure   , a(CountryYM  AgeBand Female SubFunc ) vce(cluster IDlse)
estadd local FuncFE "No" , replace
estadd local SubFuncFE "Yes" , replace
esttab,   se r2 star(* 0.10 ** 0.05 *** 0.01) nobase
esttab  using "$Results/5.Transfers/WageMovesT.tex", label  se r2 star(* 0.10 ** 0.05 *** 0.01)   ///
nomtitles   nobase    ///
mgroups(  "Pay + bonus (logs)", pattern(1 0   )  prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) s( FuncFE SubFuncFE  r2 N, labels("Func FE" "Sub-function FE" "\hline R-squared" "N" ) )  nobase drop(     _cons Tenure  c.Tenure#c.Tenure  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-occ. Sample restricted to individuals that change job at least once. Controls for: tenure, tenure squared, gender FE, age group FE, CountryxYear FE. Standard errors clustered at the individual level. "\end{tablenotes}") replace

* CAREER TRAJ - occupation/worker level 
eststo clear
eststo:reghdfe LeaverVol ONETActivitiesDistanceCB c.Tenure##c.Tenure if l.LogPayBonus!=.  , a(CountryYM Func AgeBand Female ) 
estadd local FuncFE "Yes" , replace
estadd local SubFuncFE "No" , replace
eststo:reghdfe LeaverVol ONETActivitiesDistanceCB##c.l.LogPayBonus c.Tenure##c.Tenure  , a(CountryYM Func AgeBand Female ) // positive coeff
estadd local FuncFE "Yes" , replace
estadd local SubFuncFE "No" , replace
eststo:reghdfe PromWL ONETActivitiesDistanceCB if l.LogPayBonus!=., a(CountryYM Func AgeBand Female )
estadd local FuncFE "Yes" , replace
estadd local SubFuncFE "No" , replace
eststo:reghdfe PromWL ONETActivitiesDistanceCB##c.l.LogPayBonus  , a(CountryYM Func AgeBand Female )
estadd local FuncFE "Yes" , replace
estadd local SubFuncFE "No" , replace
eststo:reghdfe ChangeSalaryGrade ONETActivitiesDistanceCB if l.LogPayBonus!=. , a(CountryYM Func AgeBand Female )
estadd local FuncFE "Yes" , replace
estadd local SubFuncFE "No" , replace
eststo:reghdfe ChangeSalaryGrade ONETActivitiesDistanceCB##c.l.LogPayBonus  , a(CountryYM Func AgeBand Female )
estadd local FuncFE "Yes" , replace
estadd local SubFuncFE "No" , replace
*eststo: reghdfe f.LogPayBonus ONETActivitiesDistanceCB c.Tenure##c.Tenure  if l.LogPayBonus!=. , a(CountryYM AgeBand Female ) vce(cluster IDlse)
*estadd local FuncFE "Yes" , replace
*estadd local SubFuncFE "No" , replace
*eststo: reghdfe f.LogPayBonus ONETActivitiesDistanceCB##c.l.LogPayBonus c.Tenure##c.Tenure   , a(CountryYM AgeBand Female ) vce(cluster IDlse)
*estadd local FuncFE "Yes" , replace
*estadd local SubFuncFE "No" , replace
*eststo:reghdfe f.ChangeSalaryGrade c.ONETActivitiesDistanceC##c.l.LogPayBonus  , a(CountryYM Func##WL AgeBand Female ) // does not work 
*eststo:reghdfe PromWL c.ONETActivitiesDistanceC##c.l.LogPayBonus  , a(CountryYM Func##WL AgeBand Female ) // does not work 
*eststo:reghdfe f.PromWL c.ONETActivitiesDistanceC##c.l.LogPayBonus  , a(CountryYM Func##WL AgeBand Female ) // does not work 

esttab,   se r2 star(* 0.10 ** 0.05 *** 0.01) nobase
esttab  using "$Results/5.Transfers/CareerMoves.tex", label  se r2 star(* 0.10 ** 0.05 *** 0.01)   ///
nomtitles   nobase    ///
mgroups(  "Exit Vol." "Prom WL" "Prom. SG."  "Pay + bonus (logs) (t+1)" , pattern(1 0 1 0 1 0 1 0 1 0   )  prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) s( FuncFE SubFuncFE  r2 N, labels("Func FE" "Sub-function FE" "\hline R-squared" "N" ) )  nobase drop(     _cons Tenure  c.Tenure#c.Tenure   ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-occ. Sample restricted to individuals that change job at least once. Controls for: tenure, tenure squared, gender FE, function FE, age group FE, CountryxYear FE. Standard errors clustered at the individual level. "\end{tablenotes}") replace

restore 

* IN PROGRESS 
reghdfe f12.LogPayBonus ONETActivitiesDistanceC if TR==1  , a(CountryYM Func AgeBand Female WL  )
reghdfe d.LogPayBonus d.ONETActivitiesDistanceC  , a(CountryYM Func AgeBand Female WL  )
 
reghdfe f12.LogPayBonus c.ONETActivitiesDistanceC##c.TransferInternalC if insample==1  , a(CountryYM Func AgeBand Female  )
reghdfe f12.LogPayBonus c.ONETActivitiesDistanceC##TransferInternal c.Tenure##c.Tenure if insample==1  , a(CountryYM Func AgeBand Female  )
. eststo:reghdfe LeaverVol c.ONETActivitiesDistanceC c.Tenure##c.Tenure  if TransferInternalC==1 , a(CountryYM Func AgeBand Female )  // higher distance decreases exit but coeff is very small
 
* Table:  Exit & Transfers 
********************************************************************************
eststo clear
eststo: reghdfe  LeaverVol TransferInternalC c.Tenure##c.Tenure  TeamSize, a(CountryYM Func   AgeBand Female  )
eststo: reghdfe  LeaverInv TransferInternalC c.Tenure##c.Tenure  TeamSize, a(CountryYM Func  AgeBand Female  )
eststo: reghdfe  LeaverVol c.TransferInternalC##c.VPAHigh c.Tenure##c.Tenure  TeamSize, a(CountryYM Func   AgeBand Female  )
eststo: reghdfe  LeaverInv c.TransferInternalC##c.VPAHigh c.Tenure##c.Tenure  TeamSize, a(CountryYM Func   AgeBand Female  )
eststo: reghdfe  LeaverVol c.TransferInternalC##LineManagerB c.Tenure##c.Tenure  TeamSize, a(CountryYM Func   AgeBand Female )
eststo: reghdfe  LeaverInv c.TransferInternalC##LineManagerB c.Tenure##c.Tenure  TeamSize, a(CountryYM Func  AgeBand Female )

esttab,   se r2 star(* 0.10 ** 0.05 *** 0.01) nobase
esttab  using "$Results/5.Transfers/ExitMoves.tex", label  se r2 star(* 0.10 ** 0.05 *** 0.01)   ///
nomtitles   nobase    ///
mgroups(  "Vol" "Inv" "Vol" "Inv" "Vol" "Inv" , pattern(1 0   )  prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) s( FuncFE SubFuncFE  r2 N, labels("Func FE" "Sub-function FE" "\hline R-squared" "N" ) )  nobase drop(     _cons Tenure  c.Tenure#c.Tenure TeamSize  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-month. Controls for: tenure, tenure squared, team size, function FE, gender FE, age group FE, CountryxYear FE. Standard errors clustered at the individual level. "\end{tablenotes}") replace

* lasso prediction
*lasso linear LeaverVol   i.Country i.Year i.Func i.WL i.AgeBand Tenure if insample==1, nolog rseed(12345)
*lassoknots
*lassocoef, display(coef, postselection)

* transfers under same manager 
********************************************************************************
reghdfe f12.LogPayBonus c.TransferInternalSJSameMC##i.LineManagerB Tenure if  LineManagerB!=.  , a(CountryYM WL  AgeBand Female WLM FemaleM AgeBandM  )
reghdfe f12.LogPayBonus c.TransferInternalSJSameMC##i.LineManagerB if  LineManagerB!=.  , a(CountryYM IDlse  )
reghdfe f12.LogPayBonus c.TransferInternalSameMC##i.LineManagerB if  LineManagerB!=.  , a(CountryYM IDlse  )
reghdfe f12.ChangeSalaryGradeC c.TransferInternalSJSameMC##i.LineManagerB Tenure if  LineManagerB!=.  , a(CountryYM WL  AgeBand Female WLM FemaleM AgeBandM  )

reghdfe TransferInternalC L12.LineManagerB if  LineManagerB!=., a(CountryYM )
reghdfe TransferInternalC L12.LineManagerB if  LineManagerB!=., a(CountryYM IDlse ) // negative correlated 
reghdfe LogPayBonus TransferInternalC  if  insample==1, a(CountryYM IDlse )

reghdfe PromWLC L12.LineManagerB if  LineManagerB!=., a(CountryYM IDlse )
reghdfe ChangeSalaryGradeC L12.LineManagerB if  LineManagerB!=., a(CountryYM IDlse )

*Event

esplot LogPayBonus if  insample==1,  event(TransferInternal , replace ) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse ) estimate_reference

esplot LogPayBonus if  insample==1,  event(TransferInternal , replace ) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse ) estimate_reference
graph save  "$analysis/Results/5.Transfers/PayTransfer.gph", replace

reghdfe TransferInternalC L12.DevOpportunity if  insample==1, a(CountryYM )
reghdfe TransferInternalC L12.VPA if  insample==1, a(CountryYM IDlse ) // low performers change function
reghdfe VPA   L12.TransferInternalC if  insample==1, a(CountryYM IDlse ) // those who change improve performance
reghdfe VPA   C.L12.TransferInternalC##c.L12.VPA if  insample==1, a(CountryYM IDlse ) // who improves performance the most are low performers   
 
reghdfe LogPayBonus TransferInternal  if  insample==1, a(CountryYM IDlse Tenure )

reghdfe TransferInternalC L12.ExtraMile if  insample==1, a(CountryYM )
reghdfe TransferInternalC L12.Leaving if  insample==1, a(CountryYM )
reghdfe TransferInternalC L12.Learning if  insample==1, a(CountryYM )
reghdfe TransferInternalC L12.LivePurpose if  insample==1, a(CountryYM )

