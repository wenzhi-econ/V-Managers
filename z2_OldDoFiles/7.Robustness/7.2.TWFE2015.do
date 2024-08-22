********************************************************************************
* STATIC REGRESSIONS 
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType2015.dta", clear 

merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

********************************************************************************
* !REQUIRES MANUAL INPUT TO CONSTRUCT THE EVENT DUMMIES!
* do  "$analysis/DoFiles/4.Event/4.0.TWFEPrep.do"
********************************************************************************


label var TeamSize "Team Size"
label var TransferInternalSJC  "Transfer: job/office/sub-division"
label var ChangeSalaryGradeC  "Prom. (salary)"
label var PromWLC  "Prom. (work-level)"
label var LogPayBonus "Pay + bonus (logs)"

label var WLM "Work Level"
label var DirectorM "LM Director +"
label var VPAHighM "VPA M >=125"
label var LineManagerMean "Effective LM"
label var LineManagerMeanB "Effective LM"
label var PayBonusGrowthM "Salary Growth M"
label var PayBonusGrowthMB "Salary Growth M"
label var SGSpeedM "Prom. Speed"
label var SGSpeedMB "Prom. Speed"
label var ChangeSalaryGradeRMMean "Team mean prom."
label var ChangeSalaryGradeRMMeanB "Team mean prom."
label var LeaverVolRMMean "Team mean vol. exit"
label var LeaverVolRMMeanB "Team mean vol. exit"

label var LeaverVol "Exit (Vol.)"
label var Leaver "Exit"
label var LeaverPerm "Exit"
label var EarlyAge2015M "Fast track M."

eststo: reghdfe ProductivityStd $event $cont if CountryS == "India", a( $abs    ) vce(cluster IDlseMHR)

* single differences 
coeffProd1 // program 
cap drop loL1 hiL1 loH1 hiH1 
gen loL1 = bL1 -1.96*seL1
gen hiL1  = bL1 +1.96*seL1
gen loH1 = bH1 -1.96*seH1
gen hiH1  = bH1 +1.96*seH1
 tw connected bL1 etL1 if etL1>-11 & etL1<11, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>-11 & etL1<11, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdSingleLow.gph", replace
graph export  "$analysis/Results/6.Productivity/ProdSingleLow.png", replace

 tw connected bH1 etL1 if etL1>-11 & etL1<11, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etL1 if etL1>-11 & etL1<11, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdSingleHigh.gph", replace
graph export  "$analysis/Results/6.Productivity/ProdSingleHigh.png", replace

event_plot,  stub_lag(L#ELH) stub_lead(F#ELH) together ///
 graph_opt(xtitle("Months since the event") ytitle("OLS coefficients") xlabel(-10(2)10) ///
 yline(0, lcolor(maroon)) xline(-1, lcolor(maroon))  title("OLS")) ///
 	  trimlag(10) trimlead(10) ciplottype(rcap) 

event_plot,  stub_lag(L#ELL) stub_lead(F#ELL) together ///
 graph_opt(xtitle("Months since the event") ytitle("OLS coefficients") xlabel(-10(2)10) ///
 yline(0, lcolor(maroon)) xline(-1, lcolor(maroon))  title("OLS")) ///
 	  trimlag(10) trimlead(10) ciplottype(rcap) 

	  event_plot,  stub_lag(L#EHL) stub_lead(F#EHL) together ///
 graph_opt(xtitle("Months since the event") ytitle("OLS coefficients") xlabel(-10(2)10) ///
 yline(0, lcolor(maroon)) xline(-1, lcolor(maroon))  title("OLS")) ///
 	  trimlag(10) trimlead(10) ciplottype(rcap) 
	  
	  event_plot,  stub_lag(L#EHH) stub_lead(F#EHH) together ///
 graph_opt(xtitle("Months since the event") ytitle("OLS coefficients") xlabel(-10(2)10) ///
 yline(0, lcolor(maroon)) xline(-1, lcolor(maroon))  title("OLS")) ///
 	  trimlag(10) trimlead(10) ciplottype(rcap) 
	  
* DEFINE VARIABLES 
global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH
global eventPost ELLPost ELHPost EHHPost EHLPost
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM TeamSize
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR 
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR Func Female
global outcomes LogPayBonus  TransferInternalC TransferInternalLLC TransferInternalVC  ChangeSalaryGradeC PromWLC Span PayBonusIncrease 

winsor2 Span, trim suffix(T) cuts(0 99)
gen SpanTB = SpanT>0 if SpanT!=. // regression works well 

local i = 1 
eststo  clear 
	foreach var in LogPayBonus  TransferInternalC TransferInternalLLC TransferInternalVC  ChangeSalaryGradeC PromWLC {
 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=.
local N1 = r(N)

eststo regF`i': reghdfe `var'   $eventPost $cont , a( $abs ) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
local i = `i' + 1

} 

 local lbl : variable label Leaver
mean Leaver 
mat coef=e(b)
local cmean = coef[1,1]
count if  Leaver !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regE: reghdfe Leaver    $eventPost  $cont , a( $exitFE ) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "No" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

esttab using "$analysis/Results/7.Robustness/EEStatic.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2, labels("Controls" "Employee FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize Tenure c.Tenure#c.Tenure ) ///
 nomtitles mgroups("`:variable label LogPayBonus'" "`:variable label TransferInternalSJLC'" "`:variable label ChangeSalaryGradeC'" "`: variable label  PromWLC'"  "`:variable label Leaver'", pattern(1 0  1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, function FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace


////////////////////////////////////////////////////////////////////////////////
* Static table on random sample using full sample EarlyAgeM 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 
keep if insample==1 

label var EarlyAgeM  "Fast Track M."

	eststo  clear
	local i = 1 
	foreach var in  LogPayBonus  TransferInternalC TransferInternalLLC TransferInternalVC ChangeSalaryGradeC PromWLC {


 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe `var'      $eventPost  $cont c.Tenure##c.Tenure TeamSize , a( $abs ) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
local i = `i' + 1
} 

 local lbl : variable label Leaver
mean Leaver 
mat coef=e(b)
local cmean = coef[1,1]
count if  Leaver !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regE: reghdfe Leaver      $eventPost  $cont , a( $exitFE ) cluster(IDlseMHR)
estadd local Controls "Yes" , replace
estadd local FE "No" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

esttab using "$analysis/Results/7.Robustness/EEStatic3mill.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2, labels("Controls" "Employee FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize Tenure c.Tenure#c.Tenure ) ///
 nomtitles mgroups("Pay + bonus (logs)" "Transfer: office/sub-division" "Transfer (lateral)" "Transfer (vertical)" "Prom. (salary)" "Prom. (work-level)"  "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, function FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace


