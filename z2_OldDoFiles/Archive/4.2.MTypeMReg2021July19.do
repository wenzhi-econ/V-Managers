* This dofile looks at managers types 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

use "$Managersdta/Temp/MType.dta", clear 
xtset IDlseMHR YearMonth 

* to do: only look at post fast track 
*bys IDlse: egen MaxWL = max(WLAgg) // last observed WL 
*keep if WL== MaxWL of keep if WL< MaxWL

********************************************************************************
* REGRESSIONS AT THE MANAGER LEVEL - TEAM LEVEL
********************************************************************************

use "$Managersdta/Temp/MType.dta", clear 

label var VPAHighM "Perf. appr. M >=125"
label var LineManager "Effective Leader"
label var LineManagerB "Effective Leader"
label var PayBonusGrowthM "Salary Growth M"
label var PayBonusGrowthMB "Salary Growth M"
label var SGSpeedM "Prom. Speed (salary)"
label var SGSpeedMB "Prom. Speed (salary)"
label var ChangeSalaryGradeRMMean "Team mean prom. (salary)"
label var ChangeSalaryGradeRMMeanB "Team mean prom. (salary)"
label var LeaverVolRMMean "Team mean vol. exit"
label var LeaverVolRMMeanB "Team mean vol. exit"
label var EarlyAgeM "Fast track M."
label var EarlyTenureM  "Fast track M. (tenure)"
label var TeamChangeSalaryGrade "Promotion (salary)"
label var LargeSpanM "Large span of control"

* correlations of the manager types
********************************************************************************
pwcorr EarlyAgeM EarlyTenureM DirectorM VPAHighM LineManagerB PayBonusGrowthMB SGSpeedMB ChangeSalaryGradeRMMeanB LeaverVolRMMeanB
su EarlyAgeM EarlyTenureM DirectorM VPAHighM LineManagerB PayBonusGrowthMB SGSpeedMB ChangeSalaryGradeRMMeanB LeaverVolRMMeanB  

eststo clear 
foreach var in VPAHighM LineManagerB PayBonusGrowthMB SGSpeedMB ChangeSalaryGradeRMMeanB LeaverVolRMMeanB LargeSpanM{
	bys IDlseMHR: egen m`var' = max(`var')
	replace `var' = m`var'
eststo: reghdfe  `var'   EarlyAgeM , a(i.CountryM FuncM) cluster(IDlseMHR)
} 
esttab,   se r2 star(* 0.10 ** 0.05 *** 0.01) 
esttab  using "$Results/4.MType/MTypeFastTrack.tex", label se r2 star(* 0.10 ** 0.05 *** 0.01)   ///
drop(_cons)   nobase    ///
 s(    r2 N, labels( "\hline R-squared" "N" ) )   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. Controls for: function and CountryxYear FE. Robust standard errors. "\end{tablenotes}") replace

/*
gen IDlse = IDlseMHR 
merge m:1 IDlse Year using "$produc/dta/ProductivityYear.dta", keepusing(ProductivityStd)
keep if _merge !=2
drop _merge 
corr  EarlyAgeM   ProductivityStd // slightly negative corr. but only 3% are early age M
*/

use "$Managersdta/Temp/MType.dta", clear 

ge SameSample =1 if LineManagerB!=. & DirectorM !=. & VPAHighM!=. & PayBonusGrowthMB!=. &  ChangeSalaryGradeRMMeanB!=.  &   LeaverVolRMMeanB!=. & SGSpeedMB!=.

label var TeamSize "Team Size"
label var PayBonusCV "CV (salary)"
label var VPACV "CV (perf. appraisals)"
label var TeamTransferSJ "Job change (all)"
label var TeamTransferInternalSJ "Job change (all)"
label var TeamTransferInternalSJDiffM  "Job change (outside team)"
label var TeamTransferInternalSJSameM  "Job change (within team)"
label var TeamLeaverVol "Exit"
label var ShareInternalSJMoves "Share job moves within team"
label var WLM "Work Level"
label var DirectorM "LM Director +"
label var VPAHighM "Perf. appr. M >=125"
label var LineManager "Effective Leader"
label var LineManagerB "Effective Leader"
label var PayBonusGrowthM "Salary Growth M"
label var PayBonusGrowthMB "Salary Growth M"
label var SGSpeedM "Prom. Speed (salary)"
label var SGSpeedMB "Prom. Speed (salary)"
label var ChangeSalaryGradeRMMean "Team mean prom. (salary)"
label var ChangeSalaryGradeRMMeanB "Team mean prom. (salary)"
label var LeaverVolRMMean "Team mean vol. exit"
label var LeaverVolRMMeanB "Team mean vol. exit"
label var EarlyAgeM "Fast track M."
label var EarlyTenureM  "Fast track M. (tenure)"
label var TeamChangeSalaryGrade "Promotion (salary)"
egen TeamSizeC = cut(TeamSize), group(5)

* REGRESSIONS  
foreach x  in EarlyAgeM{
	
	eststo  clear 
	foreach var in   PayBonusCV TeamChangeSalaryGrade TeamTransferInternalSJ TeamTransferInternalSJDiffM TeamTransferInternalSJSameM     TeamLeaverVol{
 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
eststo :reghdfe `var'   `x' i.TeamSizeC c.TenureM##c.TenureM , absorb(CountryMYear  FuncM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'

} 

esttab using "$analysis/Results/4.MType/Team`x'.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls  cmean N r2, labels("Controls" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons *TeamSize* TenureM c.TenureM#c.TenureM  ) ///
 nomtitles mgroups( "`:variable label PayBonusCV'" "`:variable label TeamChangeSalaryGrade'" "`:variable label TeamTransferInternalSJ'" "`:variable label TeamTransferInternalSJDiffM'" "`:variable label TeamTransferInternalSJSameM'"   "`:variable label TeamLeaverVol'", pattern(1 1 1 1 1 1 1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}

* REGRESSIONS  
foreach x  in EarlyAgeM EarlyTenureM {
	
	eststo  clear 
	foreach var in   PayBonusCV TeamChangeSalaryGrade TeamTransferInternalSJ TeamTransferInternalSJDiffM TeamTransferInternalSJSameM  ShareInternalSJMoves   TeamLeaverVol{
 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
eststo :reghdfe `var'   `x' TeamSize c.TenureM##c.TenureM , absorb(CountryMYear  FuncM FemaleM WLM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'

} 

esttab using "$analysis/Results/4.MType/Team`x'WL.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls  cmean N r2, labels("Controls" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize TenureM c.TenureM#c.TenureM  ) ///
 nomtitles mgroups( "`:variable label PayBonusCV'" "`:variable label TeamChangeSalaryGrade'" "`:variable label TeamTransferInternalSJ'" "`:variable label TeamTransferInternalSJDiffM'" "`:variable label TeamTransferInternalSJSameM'" "`:variable label ShareInternalSJMoves'"   "`:variable label TeamLeaverVol'", pattern(1 1 1 1 1 1 1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}

* REGRESSIONS with other manager types  
foreach var in  TeamTransferInternalSJDiffM TeamTransferInternalSJSameM  ShareInternalSJMoves PayBonusCV  TeamTransferSJ TeamTransferInternalSJ TeamLeaverVol{
   local lbl : variable label `var'
eststo  clear 
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
eststo :reghdfe `var'  DirectorM TeamSize c.TenureM##c.TenureM , absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var' VPAHighM    TeamSize c.TenureM##c.TenureM,   absorb(CountryMYear FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var' LineManagerB  TeamSize c.TenureM##c.TenureM, absorb(CountryMYear FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  PayBonusGrowthMB TeamSize c.TenureM##c.TenureM, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  SGSpeedMB TeamSize c.TenureM##c.TenureM, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  ChangeSalaryGradeRMMeanB TeamSize c.TenureM##c.TenureM, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  LeaverVolRMMeanB TeamSize c.TenureM##c.TenureM, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
esttab , se star(* 0.10 ** 0.05 *** 0.01)   drop(_cons TeamSize *TenureM*)

esttab using "$analysis/Results/4.MType/TeamMType`var'.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls cmean N r2, labels("Controls"  "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")   drop(_cons TeamSize *TenureM* ) ///
 nomtitles mgroups(" `lbl'", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

* KEEPING SAMPLE CONSTANT 
eststo  clear 
mean `var' if  SameSample ==1
mat coef=e(b)
local cmean = coef[1,1]
eststo :reghdfe `var'  DirectorM TeamSize c.TenureM##c.TenureM if SameSample ==1, absorb(CountryMYear FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var' VPAHighM    TeamSize c.TenureM##c.TenureM if  SameSample ==1,   absorb(CountryMYear FuncM AgeBandM FemaleM WLM) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var' LineManagerB  TeamSize c.TenureM##c.TenureM if  SameSample ==1, absorb(CountryMYear FuncM AgeBandM FemaleM WLM) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  PayBonusGrowthMB TeamSize c.TenureM##c.TenureM if  SameSample ==1, absorb(CountryMYear FuncM AgeBandM FemaleM WLM) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  SGSpeedMB TeamSize c.TenureM##c.TenureM if  SameSample ==1, absorb(CountryMYear FuncM AgeBandM FemaleM WLM) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  ChangeSalaryGradeRMMeanB TeamSize c.TenureM##c.TenureM if  SameSample ==1, absorb(CountryMYear FuncM AgeBandM FemaleM WLM) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  LeaverVolRMMeanB TeamSize c.TenureM##c.TenureM if  SameSample ==1, absorb(CountryMYear FuncM AgeBandM FemaleM WLM) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
esttab , se star(* 0.10 ** 0.05 *** 0.01)   drop(_cons TeamSize *TenureM*)

esttab using "$analysis/Results/4.MType/TeamMType`var'S.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls cmean N r2, labels("Controls"  "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")   drop(_cons TeamSize *TenureM* ) ///
 nomtitles mgroups(" `lbl'", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}

********************************************************************************
* Share internal versus external 
********************************************************************************

use "$Managersdta/Temp/MType.dta", clear 

egen TenureMCut = cut( TenureM) , group(10)
egen TeamSizeCut = cut( TeamSize  ) , group(5)
su TenureM, d 
gen TenureMB = TenureM > r(p50) if TenureM!=.

gen TeamSize30 = TeamSize
replace TeamSize30 = 31 if TeamSize > 30 & TeamSize !=.
gen TenureM30 = TenureM
replace TenureM30 = 31 if TenureM >30 & TenureM!=. // also tried cutoff at 40 but does not work 

label var TenureM "Tenure"
* Manager type and share of internal moves 
* Table 
eststo  clear 
mean TeamTransferInternalSJSameM
mat coef=e(b)
local cmean = coef[1,1]
eststo :reghdfe TeamTransferInternalSJSameM   c.TenureM##c.TenureM TeamSize, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd local CountryYearFE "Yes" , replace
estadd local ManagerFE "No" , replace
estadd scalar cmean = `cmean'
eststo : reghdfe  TeamTransferInternalSJSameM  c.TenureM##c.TenureM TeamSize, absorb(CountryMYear  IDlseMHR ) vce(cluster IDlseMHR)
estadd local Controls "No" , replace
estadd local CountryYearFE "Yes" , replace
estadd local ManagerFE "Yes" , replace
estadd scalar cmean = `cmean'
eststo : reghdfe  TeamTransferInternalSJSameM EarlyAgeM##c.TeamSize  c.TenureM##c.TenureM , absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd local CountryYearFE "Yes" , replace
estadd local ManagerFE "No" , replace
estadd scalar cmean = `cmean'


esttab , se star(* 0.10 ** 0.05 *** 0.01)   drop(_cons  ) nobase
esttab using "$analysis/Results/4.MType/ShareInternalSJMovesTenure.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls CountryYearFE ManagerFE cmean N r2, labels("Controls" "CountryYearFE" "ManagerFE"  "\hline Mean" " N" "R-squared" ) ) interaction("$\times$ ")   drop(_cons  ) nobase ///
 nomtitles mgroups("Job moves over tenure (within the same team)", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: function FE, age group FE,  gender, team size.  ///
"\end{tablenotes}") replace

* ORTHOGONAL TENURE AND RANK: Key to distinguish talent hoarding is manager tenure not seniority as an entry director also wants to establish good reputation 
gen DirectorHigh = DirectorM*TenureMB 
gen DirectorLow = DirectorM*(1-TenureMB ) 
gen NoDirectorHigh = (1-DirectorM)*TenureMB 
eststo  clear 
mean ShareInternalSJMoves 
mat coef=e(b)
local cmean = coef[1,1]
eststo :reghdfe TeamChangeSalaryGrade DirectorLow DirectorHigh  NoDirectorHigh TeamSize, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
eststo :reghdfe ShareInternalSJMoves  DirectorLow DirectorHigh  NoDirectorHigh TeamSize, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
eststo :reghdfe TeamTransferInternalSJDiffM  DirectorLow DirectorHigh  NoDirectorHigh TeamSize, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
eststo :reghdfe TeamTransferInternalSJSameM  DirectorLow DirectorHigh  NoDirectorHigh TeamSize, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)

*gen ShareInternalSJMoves = TeamTransferInternalSJSameM / TeamTransferInternalSJ
replace ShareInternalSJMoves = . if TeamTransferInternalSJ==0 

* graph - coefplot over tenure 
reghdfe  ShareInternalSJMoves  i.TenureM30 , absorb(CountryMYear  TeamSizeCut ) vce(cluster IDlseMHR)
coefplot, levels(99 95 90)  drop(_cons  TenureMAbove30 31.* 32.* 33.* 34.* 35.* 36.* 37.* 38.* 39.* 4*.* )   ciopts(lwidth(1 ..) lcolor(lavender*.2 lavender*.6 lavender*1) ) legend(order(1 "99" 2 "95" 3 "90") rows(1)) msymbol(d) mcolor(white)    title("Share moves within team, over tenure" , si(vlarge) span) note("Notes. Cluster SE at manager level. 99, 95, 90% Confidence Intervals." "Controlling for manager FE, team size FE and country x year FE." , span size(small)) graphregion(margin(11 11 2 2)) coeflabels(1.TenureM* = "1" 2.TenureM* = "2" 3.TenureM* = "3" 4.TenureM* = "4" 5.TenureM* = "5" 6.TenureM* = "6" 7.TenureM* = "7" 8.TenureM* = "8" 9.TenureM* = "9" 10.TenureM* = "10" 11.TenureM* = "11" 12.TenureM* = "12" 13.TenureM* = "13" 14.TenureM* = "14" 15.TenureM* = "15" 16.TenureM* = "16" 17.TenureM* = "17" 18.TenureM* = "18" 19.TenureM* = "19" 20.TenureM* = "20" 21.TenureM* = "21" 22.TenureM* = "22" 23.TenureM* = "23" 24.TenureM* = "24" 25.TenureM* = "25" 26.TenureM* = "26" 27.TenureM* = "27" 28.TenureM* = "28" 29.TenureM* = "29" 30.TenureM* = "30", angle(30) labsize(small)) scale(0.9) vertical ysize(6) xsize(8) scheme(aurora) ytick(,grid glcolor(black)) yline(0,lpattern(solid) lcolor(midblue)) xtitle(Manager Tenure)
graph export "$analysis/Results/4.MType/ShareMovesTenure.png", replace 

* fast track
reghdfe  ShareInternalSJMoves  i.TenureM30 if EarlyAgeM==1, absorb(CountryMYear TeamSizeCut ) vce(cluster IDlseMHR)
coefplot, levels(99 95 90)  drop(_cons  TenureMAbove30 31.* 32.* 33.* 34.* 35.* 36.* 37.* 38.* 39.* 4*.* )   ciopts(lwidth(1 ..) lcolor(green*.2 green*.6 green*1) ) legend(order(1 "99" 2 "95" 3 "90") rows(1)) msymbol(d) mcolor(white)    title("Share of job moves within team, over tenure" "(fast track manager)" , si(vlarge) span) note("Notes. Cluster SE at manager level. 99, 95, 90% Confidence Intervals." "Controlling for manager FE, team size FE and country x year FE." , span size(small)) graphregion(margin(11 11 2 2)) coeflabels(1.TenureM* = "1" 2.TenureM* = "2" 3.TenureM* = "3" 4.TenureM* = "4" 5.TenureM* = "5" 6.TenureM* = "6" 7.TenureM* = "7" 8.TenureM* = "8" 9.TenureM* = "9" 10.TenureM* = "10" 11.TenureM* = "11" 12.TenureM* = "12" 13.TenureM* = "13" 14.TenureM* = "14" 15.TenureM* = "15" 16.TenureM* = "16" 17.TenureM* = "17" 18.TenureM* = "18" 19.TenureM* = "19" 20.TenureM* = "20" 21.TenureM* = "21" 22.TenureM* = "22" 23.TenureM* = "23" 24.TenureM* = "24" 25.TenureM* = "25" 26.TenureM* = "26" 27.TenureM* = "27" 28.TenureM* = "28" 29.TenureM* = "29" 30.TenureM* = "30", angle(30) labsize(small)) scale(0.9) vertical ysize(6) xsize(8) scheme(aurora) ytick(,grid glcolor(black)) yline(0,lpattern(solid) lcolor(midblue)) xtitle(Manager Tenure)
graph export "$analysis/Results/4.MType/ShareMovesTenureFastTrack.png", replace 
graph save "$analysis/Results/4.MType/ShareMovesTenureFastTrack.gph", replace 

* non fast track
reghdfe  ShareInternalSJMoves  i.TenureM30 if EarlyAgeM==0, absorb(CountryMYear  TeamSizeCut ) vce(cluster IDlseMHR)
coefplot, levels(99 95 90)  drop(_cons  TenureMAbove30 31.* 32.* 33.* 34.* 35.* 36.* 37.* 38.* 39.* 4*.* )   ciopts(lwidth(1 ..) lcolor(lavender*.2 lavender*.6 lavender*1) ) legend(order(1 "99" 2 "95" 3 "90") rows(1)) msymbol(d) mcolor(white)    title("Share of job moves within team, over tenure" "(non fast track manager)" , si(vlarge) span) note("Notes. Cluster SE at manager level. 99, 95, 90% Confidence Intervals." "Controlling for manager FE, team size FE and country x year FE." , span size(small)) graphregion(margin(11 11 2 2)) coeflabels(1.TenureM* = "1" 2.TenureM* = "2" 3.TenureM* = "3" 4.TenureM* = "4" 5.TenureM* = "5" 6.TenureM* = "6" 7.TenureM* = "7" 8.TenureM* = "8" 9.TenureM* = "9" 10.TenureM* = "10" 11.TenureM* = "11" 12.TenureM* = "12" 13.TenureM* = "13" 14.TenureM* = "14" 15.TenureM* = "15" 16.TenureM* = "16" 17.TenureM* = "17" 18.TenureM* = "18" 19.TenureM* = "19" 20.TenureM* = "20" 21.TenureM* = "21" 22.TenureM* = "22" 23.TenureM* = "23" 24.TenureM* = "24" 25.TenureM* = "25" 26.TenureM* = "26" 27.TenureM* = "27" 28.TenureM* = "28" 29.TenureM* = "29" 30.TenureM* = "30", angle(30) labsize(small)) scale(0.9) vertical ysize(6) xsize(8) scheme(aurora) ytick(,grid glcolor(black)) yline(0,lpattern(solid) lcolor(midblue)) xtitle(Manager Tenure)
graph export "$analysis/Results/4.MType/ShareMovesTenureNoFastTrack.png", replace 
graph save "$analysis/Results/4.MType/ShareMovesTenureNoFastTrack.gph", replace

gr combine "$analysis/Results/4.MType/ShareMovesTenureFastTrack.gph"  "$analysis/Results/4.MType/ShareMovesTenureNoFastTrack.gph" , ycomm  ysize(3.5)
graph export "$analysis/Results/4.MType/ShareMovesTenureFastTrackHet.png", replace 

* graph - coefplot over team size
reghdfe  ShareInternalSJMoves  i.TeamSize30 c.TenureM##c.TenureM, absorb(CountryMYear  IDlseMHR  ) vce(cluster IDlseMHR)
coefplot, levels(99 95 90)  drop(_cons 31.TeamSize30  *TenureM* )   ciopts(lwidth(1 ..) lcolor(lavender*.2 lavender*.6 lavender*1) ) legend(order(1 "99" 2 "95" 3 "90") rows(1)) msymbol(d) mcolor(white)    title("Share of job moves within team, over team size" , si(vlarge) span) note("Notes. Cluster SE at manager level. 99, 95, 90% Confidence Intervals." "Controlling for manager FE, tenure, tenure squared and country x year FE." , span size(small)) graphregion(margin(11 11 2 2))  graphregion(margin(11 11 2 2)) coeflabels( 2.TeamSize* = "2" 3.TeamSize* = "3" 4.TeamSize* = "4" 5.TeamSize* = "5" 6.TeamSize* = "6" 7.TeamSize* = "7" 8.TeamSize* = "8" 9.TeamSize* = "9" 10.TeamSize* = "10" 11.TeamSize* = "11" 12.TeamSize* = "12" 13.TeamSize* = "13" 14.TeamSize* = "14" 15.TeamSize* = "15" 16.TeamSize* = "16" 17.TeamSize* = "17" 18.TeamSize* = "18" 19.TeamSize* = "19" 20.TeamSize* = "20" 21.TeamSize* = "21" 22.TeamSize* = "22" 23.TeamSize* = "23" 24.TeamSize* = "24" 25.TeamSize* = "25" 26.TeamSize* = "26" 27.TeamSize* = "27" 28.TeamSize* = "28" 29.TeamSize* = "29" 30.TeamSize* = "30", angle(30) labsize(small)) scale(0.9) vertical ysize(6) xsize(8) scheme(aurora) ytick(,grid glcolor(black)) yline(0,lpattern(solid) lcolor(midblue)) xtitle(Team Size)
graph export "$analysis/Results/4.MType/ShareMovesTeamSize.png", replace 

* less job moves outside team for smaller teams 
reghdfe  TeamTransferInternalSJDiffM  i.TeamSize30 c.TenureM##c.TenureM, absorb(CountryMYear  IDlseMHR  ) vce(cluster IDlseMHR)
coefplot, levels(99 95 90)  drop(_cons 31.TeamSize30  *TenureM* )   ciopts(lwidth(1 ..) lcolor(lavender*.2 lavender*.6 lavender*1) ) legend(order(1 "99" 2 "95" 3 "90") rows(1)) msymbol(d) mcolor(white)    title("Job moves outside team, over team size" , si(vlarge) span) note("Notes. Cluster SE at manager level. 99, 95, 90% Confidence Intervals." "Controlling for manager FE, tenure, tenure squared and country x year FE." , span size(small)) graphregion(margin(11 11 2 2))  graphregion(margin(11 11 2 2)) coeflabels( 2.TeamSize* = "2" 3.TeamSize* = "3" 4.TeamSize* = "4" 5.TeamSize* = "5" 6.TeamSize* = "6" 7.TeamSize* = "7" 8.TeamSize* = "8" 9.TeamSize* = "9" 10.TeamSize* = "10" 11.TeamSize* = "11" 12.TeamSize* = "12" 13.TeamSize* = "13" 14.TeamSize* = "14" 15.TeamSize* = "15" 16.TeamSize* = "16" 17.TeamSize* = "17" 18.TeamSize* = "18" 19.TeamSize* = "19" 20.TeamSize* = "20" 21.TeamSize* = "21" 22.TeamSize* = "22" 23.TeamSize* = "23" 24.TeamSize* = "24" 25.TeamSize* = "25" 26.TeamSize* = "26" 27.TeamSize* = "27" 28.TeamSize* = "28" 29.TeamSize* = "29" 30.TeamSize* = "30", angle(30) labsize(small)) scale(0.9) vertical ysize(6) xsize(8) scheme(aurora) ytick(,grid glcolor(black)) yline(0,lpattern(solid) lcolor(midblue)) xtitle(Team Size)
graph export "$analysis/Results/4.MType/TeamTransferInternalSJDiffMTeamSize.png", replace 

reghdfe  TeamLeaverVol  i.TeamSize30 c.TenureM##c.TenureM, absorb(CountryMYear  IDlseMHR  ) vce(cluster IDlseMHR)
coefplot, levels(99 95 90)  drop(_cons 31.TeamSize30  *TenureM* )   ciopts(lwidth(1 ..) lcolor(lavender*.2 lavender*.6 lavender*1) ) legend(order(1 "99" 2 "95" 3 "90") rows(1)) msymbol(d) mcolor(white)    title("Voluntary exits, over team size" , si(vlarge) span) note("Notes. Cluster SE at manager level. 99, 95, 90% Confidence Intervals." "Controlling for manager FE, tenure, tenure squared and country x year FE." , span size(small)) graphregion(margin(11 11 2 2))  graphregion(margin(11 11 2 2)) coeflabels( 2.TeamSize* = "2" 3.TeamSize* = "3" 4.TeamSize* = "4" 5.TeamSize* = "5" 6.TeamSize* = "6" 7.TeamSize* = "7" 8.TeamSize* = "8" 9.TeamSize* = "9" 10.TeamSize* = "10" 11.TeamSize* = "11" 12.TeamSize* = "12" 13.TeamSize* = "13" 14.TeamSize* = "14" 15.TeamSize* = "15" 16.TeamSize* = "16" 17.TeamSize* = "17" 18.TeamSize* = "18" 19.TeamSize* = "19" 20.TeamSize* = "20" 21.TeamSize* = "21" 22.TeamSize* = "22" 23.TeamSize* = "23" 24.TeamSize* = "24" 25.TeamSize* = "25" 26.TeamSize* = "26" 27.TeamSize* = "27" 28.TeamSize* = "28" 29.TeamSize* = "29" 30.TeamSize* = "30", angle(30) labsize(small)) scale(0.9) vertical ysize(6) xsize(8) scheme(aurora) ytick(,grid glcolor(black)) yline(0,lpattern(solid) lcolor(midblue)) xtitle(Team Size)
graph export "$analysis/Results/4.MType/TeamLeaverVolTeamSize.png", replace 

********************************************************************************
* Use manager manager span of control - to test prediction from Aghion & Tirole 1997
********************************************************************************

use "$Managersdta/Temp/MTypeMM.dta", clear 
su ShareInternalSJMoves PayBonusCV  TeamTransferSJ TeamTransferInternalSJ TeamLeaverVol
su DirectorM VPAHighM LineManagerB PayBonusGrowthMB SGSpeedMB ChangeSalaryGradeRMMeanB LeaverVolRMMeanB  

su TeamSizeMM, d 
gen TeamSizeMMB = TeamSizeMM> r(p50) if TeamSizeMM!=.

label var TeamSizeMM "Span of control of superior"
label var TeamSizeMMB "Span of control of superior, binary"
label var TeamSize "Team Size"
label var PayBonusCV "CV (salary)"
label var TeamTransferSJ "Job change (all)"
label var TeamTransferInternalSJ "Job change (all)"
label var TeamLeaverVol "Exit"
label var ShareInternalSJMoves "Share of job moves within team"
label var TeamTransferInternalSJDiffM  "Job change (outside team)"
label var TeamTransferInternalSJSameM  "Job change (within team)"
label var WLM "Work Level"
label var DirectorM "LM Director +"
label var VPAHighM "Perf. appr. >=125"
label var LineManager "Effective Leader"
label var LineManagerB "Effective Leader"
label var PayBonusGrowthM "Salary Growth M"
label var PayBonusGrowthMB "Salary Growth M"
label var SGSpeedM "Prom. Speed"
label var SGSpeedMB "Prom. Speed"
label var ChangeSalaryGradeRMMean "Team mean prom."
label var ChangeSalaryGradeRMMeanB "Team mean prom."
label var LeaverVolRMMean "Team mean vol. exit"
label var LeaverVolRMMeanB "Team mean vol. exit"


eststo  clear
mean TeamTransferInternalSJSameM 
mat coef=e(b)
local cmean = coef[1,1]
eststo :reghdfe TeamTransferInternalSJSameM  TeamSizeMM c.TenureM##c.TenureM TeamSize, absorb(CountryMYear WLM FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local CYear "Yes" , replace
estadd local Controls "Yes" , replace
estadd local ManagerFE "No" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe TeamTransferInternalSJSameM  TeamSizeMMB c.TenureM##c.TenureM TeamSize, absorb(CountryMYear   WLM FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local CYear "Yes" , replace
estadd local Controls "Yes" , replace
estadd local ManagerFE "No" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe TeamTransferInternalSJSameM TeamSizeMMB c.TenureM##c.TenureM TeamSize, absorb(CountryMYear   IDlse ) vce(cluster IDlseMHR)
estadd local CYear "Yes" , replace
estadd local Controls "No" , replace
estadd local ManagerFE "Yes" , replace
estadd scalar cmean = `cmean'
esttab using "$analysis/Results/4.MType/ShareInternalMM.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(CYear Controls ManagerFE cmean N r2, labels("Country x Year FE" "Controls" "Manager FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")   drop(_cons TeamSize *TenureM* ) nobase ///
 nomtitles mgroups("Job moves within team", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

* REGRESSIONS  
foreach var in  ShareInternalSJMoves PayBonusCV  TeamTransferSJ TeamTransferInternalSJ TeamLeaverVol{
   local lbl : variable label `var'
eststo  clear 
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
eststo :reghdfe `var'  DirectorM##TeamSizeMMB TeamSize c.TenureM##c.TenureM , absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var' VPAHighM##TeamSizeMMB    TeamSize c.TenureM##c.TenureM,   absorb(CountryMYear FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var' LineManagerB##TeamSizeMMB  TeamSize c.TenureM##c.TenureM, absorb(CountryMYear FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  PayBonusGrowthMB##TeamSizeMMB TeamSize c.TenureM##c.TenureM, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  SGSpeedMB##TeamSizeMMB TeamSize c.TenureM##c.TenureM, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  ChangeSalaryGradeRMMeanB##TeamSizeMMB TeamSize c.TenureM##c.TenureM, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
eststo :reghdfe `var'  LeaverVolRMMeanB##TeamSizeMMB TeamSize c.TenureM##c.TenureM, absorb(CountryMYear  FuncM AgeBandM FemaleM ) vce(cluster IDlseMHR)
estadd local Controls "Yes" , replace
estadd scalar cmean = `cmean'
esttab , se star(* 0.10 ** 0.05 *** 0.01)   drop(_cons TeamSize *TenureM*) nobase 

esttab using "$analysis/Results/4.MType/TeamMType`var'MM.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls cmean N r2, labels("Controls"  "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")   drop(_cons TeamSize *TenureM* ) nobase ///
 nomtitles mgroups(" `lbl'", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a manager-month. Controls include: country x year FE, function FE, age group FE,  gender, WL FE, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
}



