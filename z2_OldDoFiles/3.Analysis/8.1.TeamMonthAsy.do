********************************************************************************
* This do files conducts team level analysis at the month level - ASYMMETRIC
********************************************************************************
global Label FT

use "$managersdta/Teams.dta" , clear 

*keep if Year>2013 // post sample only 

bys team: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys team: egen minK = min(KEi)
bys team: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

* only select WL2+ managers 
bys team: egen WLMEi =mean(cond(KEi == 0, WLM,.))
bys team: egen WLMEiPre =mean(cond(KEi ==- 1, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1 if (WLMEi !=. & WLMEiPre !=.)

foreach var in FT {
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
label  var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label  var  `var'HHPost "High to High"
} 

foreach Label in FT {
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
	replace `var'Pre = . if `Label'LH==. & `Label'LL ==. & `Label'HH ==. & `Label'HL ==. // missing for non-switchers
	
}
	label  var  `Label'LHPre "Low to High"
	label  var `Label'LLPre "Low to Low"
	label  var `Label'HLPre "High to Low"
	label  var  `Label'HHPre "High to High"
}

* Table: Prom. (salary) / Pay Growth / Pay (CV) /   Perf. Appraisals (CV)
* Table: exit firm / change team / join team /  job change same m 
* Table: ShareSameG ShareSameAge ShareSameNationality ShareSameOffice

* Define variable globals 
global perf   AvPayGrowth CVVPA VPA101 VPAL80
global move  ShareTeamLeavers ShareTransferFunc   ShareLeaver  //ShareTransferSJ
global homo  ShareSameG  ShareSameAge  ShareSameOffice ShareSameCountry F1ShareConnected F1ShareConnectedL F1ShareConnectedV
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracCountry    
global out  ShareTeamJoiners   CVPay    ShareChangeSalaryGrade SharePromWL AvPay AvProductivityStd SDProductivityStd ShareExitTeam ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat 
* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 
global charsExitFirm  LeaverPermFemale LeaverPermAge20 LeaverPermEcon LeaverPermSci LeaverPermHum  LeaverPermNewHire LeaverPermTenure5 LeaverPermEarlyAge LeaverPermPayGrowth1yAbove1 
global charsExitTeam ExitTeamFemale ExitTeamAge20 ExitTeamEcon ExitTeamSci ExitTeamHum  ExitTeamNewHire ExitTeamTenure5 ExitTeamEarlyAge ExitTeamPayGrowth1yAbove1 
global charsJoinTeam  ChangeMFemale ChangeMAge20 ChangeMEcon ChangeMSci ChangeMHum  ChangeMNewHire ChangeMTenure5 ChangeMEarlyAge ChangeMPayGrowth1yAbove1 
global charsChangeTeam F1ChangeMFemale F1ChangeMAge20 F1ChangeMEcon F1ChangeMSci F1ChangeMHum  F1ChangeMNewHire F1ChangeMTenure5 F1ChangeMEarlyAge F1ChangeMPayGrowth1yAbove1  

* TeamEthFrac
global controls  FuncM WLM AgeBandM CountryM Year
global cont SpanM c.TenureM##c.TenureM##i.FemaleM 

********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE 
********************************************************************************
sort IDlseMHR YearMonth

eststo clear
local i = 1
	local Label FT // FT PromSG75
foreach y in  $perf $move     { // $homo $div

/*mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
*/

eststo reg`i'FE:	reghdfe `y' $`Label'   if WLM2==1 & KEi<=24 & KEi>=-24, a(   team Year) cluster(IDlseMHR)

local lbl : variable label `y'

xlincom  (`Label'LHPost  - `Label'LLPost ) (`Label'HLPost  - `Label'HHPost) , level(90) post
est store  creg`i'FE
local i = `i' +1
}
su AvPayGrowth ShareTeamLeavers ShareTransferFunc   ShareLeaver CVVPA VPA101 VPAL80  if FTLLPost ==1


* Altogether LH
**# ON PAPER
coefplot (creg5FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Job change, lateral")  ciopts(lwidth(2 ..) lcolor(ebblue) ) msymbol(d) mcolor(white) ) /// 
		 (creg6FE,  keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Job change, cross-function")  ciopts(lwidth(2 ..) lcolor(ebblue) ) msymbol(d) mcolor(white) ) /// 
		 (creg7FE,  keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Exit from firm")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) /// 
		 (creg1FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Average pay growth" )  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg3FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Share good perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg4FE,  keep(lc_1) transform(* = 100*(@))  rename(  lc_1  = "Share bottom perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg2FE,  keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Coeff. variation in perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 , aspectratio(.6) legend(off) title("Gaining a high-flyer manager", size(medsmall)) xtitle("Percentage points, monthly frequency") level(90) xline(0, lpattern(dash)) ///
		 note("Notes. An observation is a team-year-month. Reporting 90% confidence intervals." "Looking at outcomes within 24 months since the manager transition." , span) ///
		 ysize(6) xsize(8) xscale(range(-0.5 1.5) ) xlabel(-0.5(0.25)1.5, ) ylabel(,labsize(medsmall))
graph export "$analysis/Results/8.Team/TeamCoeffLH.png", replace 
graph save "$analysis/Results/8.Team/TeamCoeffLH.gph", replace 

* separate coefplots 
coefplot (creg1FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Average pay growth")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg5FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Job change, lateral")  ciopts(lwidth(2 ..) lcolor(ebblue) ) msymbol(d) mcolor(white) ) /// 
		 (creg6FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Job change, cross-function")  ciopts(lwidth(2 ..) lcolor(ebblue) ) msymbol(d) mcolor(white) ) /// 
		 (creg7FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Exit from firm")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) /// 
		 , aspectratio(.4) legend(off) title("Pay growth and reallocation") xtitle("Percentage points, monthly frequency") level(90) xline(0, lpattern(dash)) note("Notes. An observation is a team-year-month. Reporting 90% confidence intervals." "Looking at outcomes within 24 months since the manager transition." , span)   ysize(6) xsize(8)  xscale(range(0 1.4)) xlabel(0(0.2)1.4) 
graph export "$analysis/Results/8.Team/TeamCoeffLH1.png", replace 
graph save "$analysis/Results/8.Team/TeamCoeffLH1.gph", replace 

coefplot (creg2FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Coeff. variation in perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg3FE, keep(lc_1) transform(* = 100*(@)) rename(  lc_1  = "Share of top perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg4FE, keep(lc_1) transform(* = 100*(@))  rename(  lc_1  = "Share of bottom perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 , legend(off) aspectratio(.4) title("Performance differentiation") xtitle("Percentage points, monthly frequency") level(90) xline(0, lpattern(dash))  
graph export "$analysis/Results/8.Team/TeamCoeffLH2.png", replace 
graph save "$analysis/Results/8.Team/TeamCoeffLH2.gph", replace 		

* Altogether HL
coefplot (creg5FE, keep(lc_2) transform(* = 100*(@)) rename(  lc_2  = "Job change, lateral")  ciopts(lwidth(2 ..) lcolor(ebblue) ) msymbol(d) mcolor(white) ) /// 
		 (creg6FE,  keep(lc_2) transform(* = 100*(@)) rename(  lc_2  = "Job change, cross-function")  ciopts(lwidth(2 ..) lcolor(ebblue) ) msymbol(d) mcolor(white) ) /// 
		 (creg7FE,  keep(lc_2) transform(* = 100*(@)) rename(  lc_2  = "Exit from firm")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) /// 
		(creg1FE, keep(lc_2) transform(* = 100*(@)) rename(  lc_2  = "Average pay growth")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg3FE, keep(lc_2) transform(* = 100*(@)) rename(  lc_2  = "Share good perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg4FE,  keep(lc_2) transform(* = 100*(@))  rename(  lc_2  = "Share bottom perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 (creg2FE,  keep(lc_2) transform(* = 100*(@)) rename(  lc_2  = "Coeff. variation in perf. appraisals")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ) ///
		 , aspectratio(.5) legend(off) title("Losing a high-flyer manager") xtitle("Percentage points, monthly frequency") level(90) xline(0, lpattern(dash)) ///
		 note("Notes. An observation is a team-year-month. Reporting 90% confidence intervals." "Looking at outcomes within 24 months since the manager transition." , span) ///
		 ysize(6) xsize(8) ylabel(,labsize(medsmall))
graph export "$analysis/Results/8.Team/TeamCoeffHL.png", replace 
graph save "$analysis/Results/8.Team/TeamCoeffHL.gph", replace


* Table: Prom. (salary) / Pay Growth / Productivity / Pay (CV) /  Productivity (CV) / Perf. Appraisals (CV)
esttab reg1FE reg2FE reg3FE reg4FE reg5FE reg6FE ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

* Table: exit firm / change team / join team /  job change same m / job change diff m 
esttab reg7FE reg8FE reg9FE reg10FE reg11FE,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 
 
* Table: ShareSameG ShareSameNationality ShareSameAge ShareSameOffice
esttab reg12FE  reg13FE reg14FE reg15FE  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) )  

/* Left out 
esttab reg16FE  reg17FE reg18FE reg19FE  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) )  

esttab  reg20FE reg21FE reg22FE reg23FE  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) )
*/
********************************************************************************  
* coefplot 
********************************************************************************

sort IDlseMHR YearMonth
	local Label FT // FT PromSG75

gen post = 1 in 1
replace post = 2 in 2 

label define  post 1 "Low to High"  2  "High to Low" 
label value  post  post

foreach var in   $perf $move  $homo $div   {
	
ge `var'coeff = .
replace `var'coeff = `var'LHdiff in 1
replace `var'coeff =  `var'HLdiff  in 2

ge `var'lb = `var'LHlb  in 1 
replace  `var'lb= `var'HLlb  in 2 


ge `var'ub = `var'LHub  in 1 
replace `var'ub= `var'HLub  in 2 

local lab: variable label `var'
graph twoway (bar `var'coeff post if post==1 ) (bar `var'coeff post if post==2 ) (rcap `var'lb `var'ub post), xlabel(1 "Low to High"  2  "High to Low" ) xtitle("") legend(off) title("`lab'") note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.")
graph export "$analysis/Results/8.Team/`Label'`var'.png", replace 
graph save "$analysis/Results/8.Team/`Label'`var'.gph", replace 
}

********************************************************************************
* TABLES TO EXPORT 
********************************************************************************

local Label FT // FT PromSG75

* Table: Prom. (salary) / Pay Growth / Productivity / Pay (CV) /  Productivity (CV) / Perf. Appraisals (CV)
esttab reg1FE reg2FE reg3FE reg4FE  using "$analysis/Results/8.Team/`Label'Perf.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{LtoH - LtoL}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}" "HtoL - HtoH" "p-value:" ) )  interaction("$\times$ ")  nobaselevels  keep(*LLPost *LHPost *HHPost *HLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

* Table: exit firm / change team / join team /  job change same m / job change diff m 
esttab   reg5FE reg6FE reg7FE reg8FE using "$analysis/Results/8.Team/`Label'Move.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{LtoH - LtoL}}" "\textcolor{RoyalBlue} {\textbf{p-value:}}" "HtoL - HtoH" "p-value:" ) )  interaction("$\times$ ")  nobaselevels  keep(*LLPost *LHPost *HHPost *HLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

* Table: ShareSameG ShareSameNationality ShareSameAge ShareSameOffice
esttab  reg9FE reg10FE reg11FE reg12FE reg13FE  using "$analysis/Results/8.Team/`Label'Comp.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{LtoH - LtoL}}" "\textcolor{RoyalBlue} {\textbf{p-value:}}" "HtoL - HtoH" "p-value:" ) )  interaction("$\times$ ")  nobaselevels  keep(*LLPost *LHPost *HHPost *HLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

* Table: TeamFracGender  TeamFracAge  TeamFracNat TeamFracOffice  TeamFracCountry 
esttab  reg14FE reg15FE reg16FE reg17FE   using "$analysis/Results/8.Team/`Label'Div.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{LtoH - LtoL}}" "\textcolor{RoyalBlue} {\textbf{p-value:}}" "HtoL - HtoH" "p-value:" ) )  interaction("$\times$ ")  nobaselevels  keep(*LLPost *LHPost *HHPost *HLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace


********************************************************************************
* CROSS SECTION PRE
********************************************************************************
global controls  FuncM  CountryM Year // WLM AgeBandM
global cont SpanM // c.TenureM##c.TenureM##i.FemaleM 

eststo clear
local i = 1
	local Label FT // FT PromSG75

foreach y in   $perf $move $homo $div $out {
	
eststo reg`i':	reghdfe `y' `Label'LHPre `Label'HHPre `Label'HLPre $cont if SpanM>1 & KEi<=-6 & KEi >=-36,  cluster(IDlseMHR) a( $controls )
local lbl : variable label `y'
lincom  `Label'HLPre - `Label'HHPre
estadd scalar pvalue2 = r(p)
estadd scalar diff2 = r(estimate)
estadd local Controls "Yes" , replace
estadd local TeamFE "No" , replace
estadd ysumm 
local i = `i' +1

}

esttab reg1 reg2 reg3 reg4  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

esttab reg5 reg6 reg7 reg8 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

esttab  reg9 reg10 reg11 reg12  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

esttab reg13 reg14 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

********************************************************************************
* TABLES TO EXPORT 
********************************************************************************

	local Label FT // FT PromSG75

**# ON PAPER
esttab reg1 reg2 reg3 reg4  using "$analysis/Results/8.Team/Pre`Label'Perf.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2  diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) )  interaction("$\times$ ")  nobaselevels  keep( *LHPre *HHPre  *HLPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

esttab  reg5 reg6 reg7 reg8 using "$analysis/Results/8.Team/Pre`Label'Move.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2  diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) ) interaction("$\times$ ")  nobaselevels  keep( *LHPre  *HHPre  *HLPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

esttab reg9 reg10 reg11 reg12 reg13 using "$analysis/Results/8.Team/Pre`Label'Comp.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2  diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) ) interaction("$\times$ ")  nobaselevels  keep( *LHPre  *HHPre  *HLPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

**# ON PAPER
esttab reg14 reg15 reg16 reg17  using "$analysis/Results/8.Team/Pre`Label'Div.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2  diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) ) interaction("$\times$ ")  nobaselevels  keep( *LHPre  *HHPre  *HLPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

********************************************************************************
* INSTEAD OF LOOKING AT MANAGER TRANSITIONS, LOOK SIMPLY AT FUTURE MANAGER, NOT MANAGERIAL CHANGES
* this test checks: can I predict the future manager quality, irrespective of which manager I had before? this pools together teams that had a bad or a good manager as the start so this also tells me that the future manager type is unrelated to previous manager type (not more likely to get a high manager if previously I had a high manager)
* the previous test, looking at manager change, says, given a team starts with the same type of manager quality, can I predict whether it gets a good or a bad manager next? so given I start with a low manager, does it matter my performance to get a high/low manager next?  
********************************************************************************

	local Label FT // FT PromSG75
egen `Label'HPre = rowmax( `Label'LHPre `Label'HHPre )
egen `Label'LPre = rowmax( `Label'LLPre `Label'HLPre )
	
bys team: egen FTHPre = mean(cond(KEi ==0 ,EarlyAgeM, .))

eststo clear
local i = 1
local Label FT // FT PromSG75
foreach y in   $perf $move $homo $div $out {
	
eststo reg`i':	reghdfe `y'  `Label'HPre `Label'LPre $cont if SpanM>1 & KEi<=-6 & KEi >=-24 & (`Label'HPre!=0 | `Label'LPre !=0),  cluster(IDlseMHR) a( $controls )
local lbl : variable label `y'
estadd local Controls "Yes" , replace
estadd local TeamFE "No" , replace
estadd ysumm 
local i = `i' +1

}

esttab reg1 reg2 reg3 reg4  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

esttab reg5 reg6 reg7 reg8 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

esttab  reg9 reg10 reg11 reg12  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) )  keep( *HPre  )

esttab reg13 reg14 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

********************************************************************************
* TABLES TO EXPORT 
********************************************************************************

	local Label FT // FT PromSG75

esttab reg1 reg2 reg3 reg4  using "$analysis/Results/8.Team/Pre`Label'PerfLevel.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared"  ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

esttab  reg5 reg6 reg7 reg8 using "$analysis/Results/8.Team/Pre`Label'MoveLevel.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared"  ) ) interaction("$\times$ ")  nobaselevels  keep( *HPre   ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

esttab reg9 reg10 reg11 reg12 reg13 using "$analysis/Results/8.Team/Pre`Label'CompLevel.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared"  ) ) interaction("$\times$ ")  nobaselevels  keep( *HPre   ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

esttab reg14 reg15 reg16 reg17  using "$analysis/Results/8.Team/Pre`Label'DivLevel.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared"  ) ) interaction("$\times$ ")  nobaselevels  keep( *HPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace


********************************************************************************
* PROFILES OF LEAVERS AND JOINERS 
********************************************************************************

eststo clear
local i = 1
sort IDlseMHR YearMonth 
	local Label FT // FT PromSG75

global charsCoef Female Age20 MBA Econ Sci Hum  NewHire Tenure5 EarlyAge  PayGrowth1yAbove1 // Age30 Age40 Age50  PayGrowth1yAbove0 

foreach y in $charsCoef Age30 Age40 Age50  $charsExitFirm $charsExitTeam $charsJoinTeam $charsChangeTeam {

reghdfe `y' $`Label' c.TenureM##c.TenureM##i.FemaleM if SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

local lbl : variable label `y'

xlincom  (`Label'LHPost - `Label'LLPost )  (`Label'HLPost - `Label'HHPost) , level(90) post
est store  `y'
coefplot  (`y', keep(lc_1) rename(  lc_1  = "Low to High"))  (`y', keep(lc_2) rename( lc_2 = "High to Low" )) , ciopts(recast(rcap)) legend(off) title(`lbl')   recast(bar ) vertical
graph export "$analysis/Results/8.Team/`Label'`y'.png", replace 
graph save "$analysis/Results/8.Team/`Label'`y'.gph", replace              
local i = `i' +1
}

/********************************************************************************
* CROSS SECTION POST
********************************************************************************

eststo clear
local i = 1
	local Label PromSG75
foreach y in $perf $move $other {
	
eststo reg`i':	reghdfe `y' `Label'LHPost `Label'HHPost `Label'HLPost   if SpanM>1  & Post==1,  cluster(IDlseMHR) a( $controls )
local i = `i' +1

}

esttab reg1 reg2 reg3 reg4 reg5 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2
esttab reg6 reg7 reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2
esttab reg11 reg12 reg13 reg14 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2


eststo clear
local i = 1
	local Label PromSG50
foreach y in $perf $move $other {
	
eststo reg`i':	reghdfe `y' `Label'LHPost `Label'HHPost `Label'HLPost  c.TenureM##c.TenureM if SpanM>1  & KEi>=12,  cluster(IDlseMHR) a(  $controls )
local i = `i' +1

}

esttab reg1 reg2 reg3 reg4 reg5 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2
esttab reg6 reg7 reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2
esttab reg11 reg12 reg13 reg14 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2

********************************************************************************
* TEAM LEVEL REGRESSIONS - month and WITHOUT team FE 
********************************************************************************

eststo clear
local i = 1
	local Label PromSG75
foreach y in $perf $move $other {

/*mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
*/

eststo reg`i':	reghdfe `y' $`Label'  $cont if SpanM>1 & Year>2013 , a( $controls ) cluster(IDlseMHR)
local lbl : variable label `y'
lincom  `Label'LHPost - `Label'LLPost
estadd scalar pvalue1 = r(p)
estadd scalar diff1 = r(estimate)
lincom  `Label'HLPost - `Label'HHPost
estadd scalar pvalue2 = r(p)
estadd scalar diff2 = r(estimate)
estadd local Controls "Yes" , replace
estadd local TeamFE "No" , replace
estadd ysumm 
*estadd scalar cmean = `cmean'
*estadd scalar N1 = `N1'


local i = `i' +1
}

esttab reg1 reg2 reg3 reg4 reg5 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 
esttab reg6 reg7 reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 
esttab reg11 reg12 reg13 reg14  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) )

* EXPORT TABLES 
esttab reg1 reg2 reg3 reg4 reg5 using "$analysis/Results/8.Team/`Label'PerfnoFE.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{LtoH - LtoL}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}" "HtoL - HtoH" "p-value:" ) )  interaction("$\times$ ")  nobaselevels  keep(*LLPost *LHPost *HHPost *HLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. The period is 12 months before and after manager change. Controls include: function FE, team size, work level FE, year FE, age band of manager, tenure and tenure squared of manager. ///
"\end{tablenotes}") replace



* event study specification 

global event L*ELL L*ELH L*EHH L*EHL F*ELL F*ELH F*EHH F*EHL

local end = 12 // to be plugged in 
local window = 25 // to be plugged in

eststo clear 
foreach y in TeamLeaverVol  TeamTransferSJ    TeamChangeSalaryGrade TeamPromWL TeamPayCV TeamVPACV{
eststo:	reghdfe `y' $event  if SpanM>1  ,  cluster(team) a(team WLM FuncM AgeBandM)

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/8.Team/`y'Dual.gph", replace
graph export "$analysis/Results/8.Team/`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/8.Team/`y'ELH.gph", replace
graph export "$analysis/Results/8.Team/`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/8.Team/`y'EHL.gph", replace
graph export "$analysis/Results/8.Team/`y'EHL.png", replace

}
esttab,   label star(* 0.10 ** 0.05 *** 0.01) se r2


* TRIALS WITH LINCOM AND COEFPLOT 

	local l "" 
foreach v in  Female Age20  Econ Sci Hum  NewHire Tenure5 EarlyAge PayGrowth1yAbove1  {
	gen l`v' = LeaverPerm`v'
	gen e`v' = ExitTeam`v'
	gen j`v' = ChangeM`v'
	gen c`v' = F1ChangeM`v'
	local l "`l' l`v' e`v' j`v' c`v' "
}

foreach t in l e j c {
gen  `t'PromSG75LHPost  =  PromSG75LHPost 
PromSG75LLPost 
PromSG75HLPost 
PromSG75HHPost
}  

eststo clear
local i = 1
sort IDlseMHR YearMonth 
cap drop *LHdiff *LHlb *LHub 
cap drop *HLdiff *HLlb *HLub  
	local Label PromSG75
	
foreach v in  Female Age20  Econ Sci Hum  NewHire Tenure5 EarlyAge PayGrowth1yAbove1  {
	local l "`l' l`v' e`v' j`v' c`v' "
}	
foreach y in  `l' {

eststo reg`i'FE:	reghdfe `y' $`Label'  c.TenureM##c.TenureM##i.FemaleM if SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

local lbl : variable label `y'

lincom  `Label'LHPost - `Label'LLPost, level(90)
estadd scalar pvalue1 = r(p)
estadd scalar diff1 = r(estimate)
gen `y'LHdiff = r(estimate) in 1
gen `y'LHlb = r(lb) in 1
gen `y'LHub = r(ub) in 1

lincom  `Label'HLPost - `Label'HHPost, level(90)
estadd scalar pvalue2 = r(p)
estadd scalar diff2 = r(estimate)
gen `y'HLdiff = r(estimate) in 2
gen `y'HLlb = r(lb) in 2
gen `y'HLub = r(ub) in 2

estadd local Controls "Yes" , replace
estadd local TeamFE "Yes" , replace
estadd ysumm 

local i = `i' +1
}

	local Label PromSG75
plotbeta `Label'LHPost - `Label'LLPost | `Label'HLPost - `Label'HHPost, level(90)  addplot((scatteri 2.5 2.5, ms(S) msize(*2)))
  labels ylab(none, axis(2)) ytitle("", axis(2))

********************************************************************************  
* coefplot 
********************************************************************************

sort IDlseMHR YearMonth
global Label PromSG75

gen post = 1 in 1
replace post = 1.2 in 2
forval i = 3(2)50{
	local j = `i'-1
	replace post = `i'+0.2 in `j'
	replace post = `i' in `i'
}

* l e j c 
local i =1 
foreach var in eFemale eAge20  eEcon eSci eHum  eNewHire eTenure5 eEarlyAge ePayGrowth1yAbove1 jFemale jAge20 jEcon jSci jHum  jNewHire jTenure5 jEarlyAge jPayGrowth1yAbove1    {

local j = `i' + 1
ge `var'coeff = .
replace `var'coeff = `var'LHdiff in `i'
replace `var'coeff =  `var'HLdiff  in `j'

ge `var'lb = `var'LHlb  in `i' 
replace  `var'lb= `var'HLlb  in `j'


ge `var'ub = `var'LHub  in `i' 
replace `var'ub= `var'HLub  in `j' 

local lab: variable label `var'
graph twoway (scatter  post `var'coeff )  (rcap `var'lb `var'ub post, hor ),  xtitle("") legend(off) title("`lab'") note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.")
graph export "$analysis/Results/8.Team/`var'$LabelAsy.png", replace 
graph save "$analysis/Results/8.Team/`var'$LabelAsy.gph", replace 

local i = `i'+1
}



