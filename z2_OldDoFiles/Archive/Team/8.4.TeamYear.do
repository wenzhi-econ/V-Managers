********************************************************************************
* TEAM LEVEL REGRESSIONS - year
********************************************************************************

use "$Managersdta/Teams.dta" , clear 

keep if Year > 2013
bys team: egen mSpan= min(SpanM)
*drop if mSpan == 1 
bys team: egen minK = min(KEi)
bys team: egen maxK = max(KEi)
*keep if minK ==-12 & maxK ==12

foreach var in FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015{
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
global `var'Ev `var'LH `var'HH `var'HL `var'LL

} 

foreach Label in FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015{
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
}
}

global perf  ShareChangeSalaryGrade SharePromWL AvPayGrowth CVPayBonus CVVPA
global move ShareExitTeam ShareLeaverVol ShareLeaverInv  ShareTransferSJ ShareOrg4
global other ShareFemale ShareSameG ShareDiffOffice  ShareOutGroup 
*TeamEthFrac
global controls SpanM FuncM WLM AgeBandM CountryM Year

* 1) annual variables - take them at 12 months: TeamPayCV TeamVPACV TeamPayGrowth ShareFemale TeamEthFrac
foreach var in $other AvPayGrowth CVPayBonus CVVPA FuncM WLM AgeBandM CountryM Year TenureM FemaleM {
	bys team: egen `var'12 = mean(cond(KEi==12, `var',.)) if KEi >=0 
	bys team: egen `var'Pre12 = mean(cond(KEi==-12, `var',.)) if KEi <0 
	egen `var'Y = rowmean(`var'12 `var'Pre12)
	bys team: egen `var'24 = mean(cond(KEi==24, `var',.)) if KEi >=0 
	bys team: egen `var'Pre24 = mean(cond(KEi==-24, `var',.)) if KEi <0 
	egen `var'2Y = rowmean(`var'24 `var'Pre24)

}

* 2) annual sums - sum them up to month 12
	bys team: egen SpanM0 = mean(cond(KEi ==0, SpanM, .))  
foreach var in $move    ShareChangeSalaryGrade SharePromWL {
	gen N`var' = `var' *SpanM 
	bys team: egen `var'12 = sum(cond(KEi<=12 & KEi>=0, N`var',.)) if KEi >=0 
	bys team: egen `var'Pre12 = sum(cond(KEi<=-1 & KEi>=-12, N`var',.)) if KEi <0
	replace `var'12 = `var'12/SpanM0 // number of moves as a fraction of initial team size 
	replace `var'Pre12 = `var'Pre12/SpanM0 // number of moves as a fraction of initial team size 
	egen `var'Y = rowmean(`var'12 `var'Pre12)
	bys team: egen `var'24 = sum(cond(KEi<=24 & KEi>=0, N`var',.)) if KEi >=0 
	bys team: egen `var'Pre24 = sum(cond(KEi<=-1 & KEi>=-24, N`var',.)) if KEi <0 
	replace `var'24 = `var'24/SpanM0 // number of moves as a fraction of initial team size 
	replace `var'Pre24 = `var'Pre24/SpanM0 // number of moves as a fraction of initial team size 
	egen `var'2Y = rowmean(`var'24 `var'Pre24)

}

global perfY  ShareChangeSalaryGradeY SharePromWLY AvPayGrowthY CVPayBonusY CVVPAY
global moveY ShareExitTeamY ShareLeaverVolY ShareLeaverInvY  ShareTransferSJY ShareOrg4Y
global otherY ShareFemaleY ShareSameGY ShareDiffOfficeY  ShareOutGroupY 
*TeamEthFrac
global controlsY  FuncMY WLMY AgeBandMY CountryMY YearY

global perf2Y  ShareChangeSalaryGrade2Y SharePromWL2Y AvPayGrowth2Y CVPayBonus2Y // CVVPA2Y has too few obs 
global move2Y ShareExitTeam2Y ShareLeaverVol2Y ShareLeaverInv2Y  ShareTransferSJ2Y ShareOrg42Y
global other2Y ShareFemale2Y ShareSameG2Y ShareDiffOffice2Y  ShareOutGroup2Y 
*TeamEthFrac
global controls2Y  FuncM2Y WLM2Y AgeBandM2Y CountryM2Y Year2Y

global contY SpanM c.TenureMY##c.TenureMY 
global cont2Y SpanM c.TenureM2Y##c.TenureM2Y 

collapse SpanM $perfY $moveY $otherY $controlsY $perf2Y $move2Y $other2Y $controls2Y TenureM*Y FemaleM*Y $FT $Effective $FTEv $EffectiveEv $PromWL75Ev $PromWL75 $PromSG75 $PromSG75Ev  $PromWL50Ev $PromWL50 $PromSG50 $PromSG50Ev   , by(team Post IDlseMHR)

isid team Post

* OUTCOME VARIABLES 
label var ShareExitTeamY "Exit Team"
label var ShareLeaverVolY "Exit Firm (Vol.)"
label var ShareLeaverInvY "Exit Firm (Inv.)"
label var ShareTransferSJY  "Job Change"
label var ShareOrg4Y  "Org Change"
label var ShareChangeSalaryGradeY  "Prom. (salary)"
label var SharePromWLY  "Prom. (work level)"
label var CVPayBonusY  "Pay (CV)"
label var CVVPAY  "Perf. Appraisals (CV)"
label var AvPayGrowthY "Pay Growth"

* Diversity 
label var ShareFemaleY "Female Share"
label var ShareDiffOfficeY "Share in Diff. Office"
label var ShareSameGY "Share Same Gender"
label var ShareOutGroupY "Share Diff. Hiring Office"

* pre 
foreach Label in  Effective FT PromWL75 PromSG75 PromSG50 PromWL50{
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
}
}

eststo clear
local i = 1
	local Label PromSG75
foreach y in  $perfY $moveY $otherY  {
eststo reg`i':	reghdfe `y' $`Label' $contY if SpanM>1 , a(team  ) cluster(IDlseMHR)
local lbl : variable label `y'
test `Label'LLPost = `Label'LHPost
estadd scalar pvalue1 = r(p)
test `Label'HHPost = `Label'HLPost
estadd scalar pvalue2= r(p)

mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
estadd local Controls "No" , replace
estadd local TeamFE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'

local i = `i' +1

}

esttab reg1 reg2 reg3 reg4 reg5 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 
esttab reg6 reg7 reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 
esttab reg11 reg12 reg13 reg14  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 


* export table
esttab reg1 reg2 reg3 reg4 reg5 using "$analysis/Results/8.Team/SharePrePostPerf.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) interaction("$\times$ ")  nobaselevels  keep(ELLPost ELHPost EHHPost EHLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team 12 months before and 12 months after manager change. Standard errors clustered at the team level. ///
"\end{tablenotes}") replace


esttab reg6 reg7 reg8 reg9 reg10 using "$analysis/Results/8.Team/SharePrePostMove.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) interaction("$\times$ ")  nobaselevels  keep(ELLPost ELHPost EHHPost EHLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team 12 months before and 12 months after manager change. Standard errors clustered at the team level. ///
"\end{tablenotes}") replace

* CROSS SECTION POST
eststo clear
local i = 1
	local Label PromSG75
foreach y in $perf $move $other {
	
eststo reg`i':	reghdfe `y' `Label'LHPost `Label'HHPost `Label'HLPost c.TenureMY##c.TenureMY   if SpanM>1  & Post==1 ,  cluster(IDlseMHR) a( FuncMY AgeBandMY CountryMY YearY )
local i = `i' +1

}

esttab reg1 reg2 reg3 reg4 reg5 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 
esttab reg6 reg7 reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 
esttab reg11 reg12 reg13 reg14  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 


* CROSS SECTION PRE

eststo clear
local i = 1
		local Label PromSG75 
foreach y in $perfY $moveY $otherY {
	
eststo reg`i':	reghdfe `y' `Label'LHPre `Label'HHPre `Label'HLPre $contY  if SpanM>1  & Post==0,  cluster(IDlseMHR) a( $controlsY )
local i = `i' +1

}

esttab reg1 reg2 reg3 reg4 reg5 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 
esttab reg6 reg7 reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 
esttab reg11 reg12 reg13 reg14  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE cmean N1 r2 pvalue1 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH = LtoL" "HtoL = HtoH" ) ) 


