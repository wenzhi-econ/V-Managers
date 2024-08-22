********************************************************************************
* This do files conducts team level analysis at the month level - ASYMMETRIC
* NOTE: Team composition constant: same team that underwent the manager transition, 
* keep following the same team members even if they change team 
********************************************************************************

use "$managersdta/Temp/TeamSwitchers.dta" , clear 
 xtset  IDteam YearMonth

cap drop EarlyAgeM 
gen IDlseMHR = IDlseMHRPrePost 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MType.dta" , keepusing(EarlyAgeM)
*keep if Year>2013 // post sample only if using PromSG75
drop if _merge ==2 
drop _merge 

bys IDteam: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys IDteam: egen minK = min(KEi)
bys IDteam: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

foreach var in FT { // Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015
	
xtset IDteam YearMonth 
gen diff`var' = d.EarlyAgeM // can be replace with d.EarlyAgeM
gen Delta`var'tag = diff`var' if KEi==0
bys IDteam: egen Delta`var' = mean(Delta`var'tag)

drop  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
gen `var'LHPost = KEi >=0 & `var'LH!=.
gen `var'LLPost = KEi >=0 & `var'LL!=.
gen `var'HHPost = KEi >=0 & `var'HH!=.
gen `var'HLPost = KEi >=0 & `var'HL!=.

egen `var'Post = rowmax( `var'LHPost `var'LLPost `var'HLPost `var'HHPost ) 

gen `var'PostDelta = `var'Post*Delta`var'
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
label var `var'Post "Event"
label var `var'PostDelta "Event*Delta M. Talent"
label var Delta`var' "Delta M. Talent"
} 

foreach Label in FT { //  Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
	replace `var'Pre = . if `Label'LH==. & `Label'LL ==. & `Label'HH ==. & `Label'HL ==. // missing for non-switchers
	
}
	label var  `Label'LHPre "Low to High"
	label  var `Label'LLPre "Low to Low"
	label  var `Label'HLPre "High to Low"
	label var  `Label'HHPre "High to High"
}

* Table: Prom. (salary) / Pay Growth / Pay (CV) /   Perf. Appraisals (CV)
* Table: exit firm / change team / join team /  job change same m 
* Table: ShareSameG ShareSameAge ShareSameNationality ShareSameOffice

foreach var in FT Effective PromSG75 PromWL75  PromSG50 PromWL50{
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
} 

gen lAvPay = log(AvPay)
label var lAvPay "Av. Pay (logs)"

* Define variable globals 
label var ShareTransferSJ  "Lateral job change"
label var  ShareSameNationality "Same Nationality"

global perf  ShareChangeSalaryGrade SharePromWL lAvPay  CVPay  CVVPA  // AvPayGrowth
global move   ShareTransferSJ  
global homo  ShareSameG  ShareSameAge  ShareSameOffice  ShareSameNationality 
*ShareSameCountry  
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracNat TeamFracCountry    
global job NewJob OldJob NewJobManager OldJobManager
global out  SpanM SharePromWL AvPay AvProductivityStd SDProductivityStd  ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat

* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 
* TeamEthFrac

foreach var in FuncM WLM AgeBandM CountryM  FemaleM{
bys IDteam YearMonth: egen m`var' = mode(`var'), max
replace m`var'  = round(m`var' ,1)
replace `var' = m`var'
}

global controls  FuncM WLM AgeBandM CountryM Year
global cont SpanM c.TenureM##c.TenureM##i.FemaleM

* WL2 managers
bys IDteam: egen prewl = max(cond(KEi==-1,WLM,.))
bys IDteam: egen postwl = max(cond(KEi==0,WLM,.))
ge WL2 = prewl >1 & postwl>1

* generate categories for coefficient of variation 
local var FT // FT PromSG75
gen trans = 1 if `var'LHPost==1 
replace trans = 2 if `var'LLPost==1
replace trans = 3 if `var'HLPost==1
replace trans = 4 if `var'HHPost==1
label def trans 1 "Low to High" 2 "Low to Low" 3 "High to Low" 4 "High to High" 
label value trans trans 

* independent variable - regressor 
gen HighF1 = trans==1
gen HighF2 = trans ==3

gen HighF1p = FTLH!=. & KEi<0
gen HighF2p = FTHL!=. & KEi<0

********************************************************************************
* TEAM INEQUALITY - CV
********************************************************************************

eststo lh: reg CVPay HighF1 if KEi >=12  & KEi <=60 & trans <3  & WL2 ==1, vce( cluster IDlseMHR)
eststo hl: reg CVPay HighF2 if KEi >=12 & KEi <=60 & trans >=3 & trans!=.  & WL2 ==1, vce( cluster IDlseMHR)
label var HighF1 "Pay inequality, gain good manager" 
 label var HighF2 "Pay inequality, lose good manager" 

* option for all coefficient plots
global coefopts keep(HighF*)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
 aseq ///
scale(1)  legend(off) ///
aspect(0.4) coeflabels(, ) ysize(6) xsize(8)  ytick(,grid glcolor(black)) 

coefplot lh hl,   $coefopts xline(0, lpattern(dash)) xscale(range(-.1 .1)) xlabel(-.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlot.png", replace 
graph save "$analysis/Results/8.Team/CVPlot.gph", replace 

* separately by time horizon 
********************************************************************************

forval i = 1/12{
foreach v in lhp`i' hlp`i' {
gen `v' = 1 
label var `v' "-`i'"
}
}

* AVOID OVERCROWDED LABELS ON GRAPH 
forval i = 1(2)11{
foreach v in lhp`i' hlp`i' {
label var `v' " "
}
}


forval j = 1/29{
foreach v in lh`j' hl`j'  {
gen `v' = 1 
local c = `j'-1
label var `v' "`c'"
}
}

* AVOID OVERCROWDED LABELS ON GRAPH 
forval j = 2(2)28{
foreach v in lh`j' hl`j'  {
local c = `j'-1
label var `v' " "
}
}

eststo clear
eststo lhp1: reg CVPay HighF1p if KEi >=-3  & KEi <0 & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp1: reg CVPay HighF2p if KEi >=-3 & KEi <0 & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = -3
forval i = 2/12{
local m = `i'*3

eststo lhp`i': reg CVPay HighF1p if KEi >=-`m'  & KEi <-`m1' & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp`i': reg CVPay HighF2p if KEi >=-`m' & KEi <-`m1' & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = `m'
} 

eststo lh1: reg CVPay HighF1 if KEi >=0  & KEi <3 & trans <3  & WL2 ==1, vce( cluster IDlseMHR)
eststo hl1: reg CVPay HighF2 if KEi >=0 & KEi <3 & trans >=3 & trans!=.  & WL2 ==1, vce( cluster IDlseMHR)
local m1 = 3
forval i = 2/29{
local m = `i'*3 -1 

eststo lh`i': reg CVPay HighF1 if KEi >=`m1'  & KEi <=`m' & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hl`i': reg CVPay HighF2 if KEi >=`m1' & KEi <=`m' & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = `m'
} 

* SIMPLE GRAPH LH
********************************************************************************

coefplot  ( lh12 , keep(HighF1) rename(  HighF1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 ( lh20, keep(HighF1) rename(  HighF1  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  ( lh28 , keep(HighF1) rename(  HighF1 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)   ///
 title("Coefficient of variation in pay, team level", size(medsmall))  levels(90) xline(0, lpattern(dash))  xlabel(0(0.02)0.1) ///
note("Notes. Plotting estimates at 12, 20 and 28 quarters after manager transition. Reporting 90% confidence intervals.", span)
graph export "$analysis/Results/8.Team/CVPlotLH.png", replace 
graph save "$analysis/Results/8.Team/CVPlotLH.gph", replace 

**# ON PAPER
coefplot  ( lh12 , keep(HighF1) rename(  HighF1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 ( lh20, keep(HighF1) rename(  HighF1  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  ( lh28 , keep(HighF1) rename(  HighF1 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)   ///
 title("Coefficient of variation in pay, team level", size(medsmall))  levels(90) xline(0, lpattern(dash))  xlabel(0(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotLHA.png", replace 
graph save "$analysis/Results/8.Team/CVPlotLHA.gph", replace 

* SIMPLE GRAPH HL
********************************************************************************

coefplot  ( hl12 , keep(HighF2) rename(  HighF2  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 ( hl20, keep(HighF2) rename(  HighF2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  ( hl28 , keep(HighF2) rename(  HighF2 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)   ///
 title("Coefficient of variation in pay, team level", size(medsmall))  levels(90) xline(0, lpattern(dash))  xlabel(-0.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotHLA.png", replace 
graph save "$analysis/Results/8.Team/CVPlotHLA.gph", replace 

coefplot  ( hl12 , keep(HighF2) rename(  HighF2  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 ( hl20, keep(HighF2) rename(  HighF2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  ( hl28 , keep(HighF2) rename(  HighF2 = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)   ///
 title("Coefficient of variation in pay, team level", size(medsmall))  levels(90) xline(0, lpattern(dash))  xlabel(-0.1(0.02)0.1) ///
 note("Notes. Plotting estimates at 12, 20 and 28 quarters after manager transition. Reporting 90% confidence intervals.", span)
graph export "$analysis/Results/8.Team/CVPlotHL.png", replace 
graph save "$analysis/Results/8.Team/CVPlotHL.gph", replace 

********************************************************************************
* FULL GRAPH 
********************************************************************************

* option for all coefficient plots
* lwidth(0.8 ..)  msymbol() aspect(0.4) ysize(8) xsize(8)
global coefopts keep(HighF*)  levels(95) ///
ciopts(recast(rcap) lcolor(ebblue))  mcolor(ebblue) /// 
 aseq swapnames xline(12, lcolor(maroon) lpattern(dash))  yline(0, lcolor(maroon) lpattern(dash)) ///
scale(1)  vertical legend(off) ///
 coeflabels(, )   ytick(,grid glcolor(black))  xtitle(Quarters since manager change) omitted
 
su CVPay  if KEi>=58 & KEi<=60 & FTLL!=.
di  0.05/  .2803382 // 18%

eststo lhp1: reg CVPay HighF1p if KEi >=1  & KEi <=1 & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp1: reg CVPay HighF2p if KEi >=1 & KEi <=1 & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)

coefplot lhp12 lhp11 lhp10 lhp9 lhp8 lhp7 lhp6 lhp5 lhp4 lhp3 lhp2 lhp1 lh1 lh2 lh3 lh4 lh5 lh6 lh7 lh8 lh9 lh10 lh11 lh12 lh13 lh14 lh15 lh16 lh17 lh18 lh19 lh20 lh21  ,   ///
 title("Coefficient of variation in pay, team-level") $coefopts  yscale(range(-.06 .06)) ylabel(-.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotYearLHQ5.png", replace 
graph save "$analysis/Results/8.Team/CVPlotYearLHQ5.gph", replace 

coefplot hlp12 hlp11 hlp10 hlp9 hlp8 hlp7 hlp6 hlp5 hlp4 hlp3 hlp2 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10 hl11 hl12 hl13 hl14 hl15 hl16 hl17 hl18 hl19 hl20 hl21 ,   ///
 title("Coefficient of variation in pay, team-level")  $coefopts  yscale(range(-.25 .25)) ylabel(-.25(0.05)0.25)
graph export "$analysis/Results/8.Team/CVPlotYearHLQ5.png", replace 
graph save "$analysis/Results/8.Team/CVPlotYearHLQ5.gph", replace 

coefplot lhp12 lhp11 lhp10 lhp9 lhp8 lhp7 lhp6 lhp5 lhp4 lhp3 lhp2 lhp1 lh1 lh2 lh3 lh4 lh5 lh6 lh7 lh8 lh9 lh10 lh11 lh12 lh13 lh14 lh15 lh16 lh17 lh18 lh19 lh20 lh21  lh22 lh23 lh24 lh25 lh26 lh27 lh28 lh29 ,   ///
 title("Coefficient of variation in pay, team-level") $coefopts  yscale(range(-.06 .06)) ylabel(-.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotYearLHQ7.png", replace 
graph save "$analysis/Results/8.Team/CVPlotYearLHQ7.gph", replace 

coefplot hlp12 hlp11 hlp10 hlp9 hlp8 hlp7 hlp6 hlp5 hlp4 hlp3 hlp2 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10 hl11 hl12 hl13 hl14 hl15 hl16 hl17 hl18 hl19 hl20 hl21 hl22 hl23 hl24 hl25 hl26 hl27 hl28 hl29 ,   ///
 title("Coefficient of variation in pay, team-level")  $coefopts  yscale(range(-.25 .25)) ylabel(-.25(0.05)0.25)
graph export "$analysis/Results/8.Team/CVPlotYearHLQ7.png", replace 
graph save "$analysis/Results/8.Team/CVPlotYearHLQ7.gph", replace 

* Event study
********************************************************************************

drop   FTLowHigh  FTLowLow
gen FTLowHigh = KEi==0 & trans==1
gen FTLowLow = KEi==0 & trans==2

esplot CVPay if     (FTLH!=. | FTLL!=. ) & WL2 ==1, event( FTLowHigh, save) compare( FTLowLow, save) window(-12 60 , ) period(3) estimate_reference  legend(off) yline(0) xline(-1)  xlabel(-12(2)20) xtitle(Quarters since manager change)  vce(cluster IDlseMHR)
graph export "$analysis/Results/8.Team/FTEventCVLH.png", replace 
graph save "$analysis/Results/8.Team/FTEventCVLH.gph", replace

esplot CVPay if     (FTHL!=. | FTHH!=. ) & WL2 ==1, event( FTHighLow, save) compare( FTHighHigh, save) window(-12 60 , ) period(3) estimate_reference  legend(off) yline(0) xline(-1)  xlabel(-12(2)20) xtitle(Quarters since manager change)  vce(cluster IDlseMHR) 
graph export "$analysis/Results/8.Team/FTEventCVHL.png", replace 
graph save "$analysis/Results/8.Team/FTEventCVHL.gph", replace

********************************************************************************
* LOW TO HIGH 
********************************************************************************

* Baseline mean 
bys IDteam: egen tranInv = mean(trans)
su CVPay if KEi <0 & KEi >=-36& WL2==1
su CVPay if KEi <0 & KEi >=-36& tranInv <3 & WL2==1
su CVPay if KEi <0 & KEi >=-36& tranInv >=3 & tranInv<=4 & WL2==1


local Label FT // FT PromSG75
distinct IDteam if KEi >=12 & KEi <=36 & trans ==1 & WL2==1
local n1 =     r(ndistinct) 
distinct IDteam if KEi >=12 & KEi <=36 & trans ==2  & WL2==1
local n2 =     r(ndistinct)
cibar CVPay if KEi >=12 & KEi <=36 & trans <3  & WL2 ==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay") note("Notes. Average monthly coeff. var in pay, 1-3 years of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the low to high group and `n2' teams in the low to low group.", size(medsmall)) ytitle("Percentage points") scheme(white_ptol) legend(rows(1) position(1)) yscale(range(0.28 0.36)) ylabel(0.28(0.01)0.36)) 
graph export "$analysis/Results/8.Team/`Label'FunnelCVLH.png", replace 
graph save "$analysis/Results/8.Team/`Label'FunnelCVLH.gph", replace

********************************************************************************
* HIGH to LOW
********************************************************************************

local Label FT // FT PromSG75
distinct IDteam if KEi >=12 & KEi <=36 & trans ==3  & WL2==1
local n1 =     r(ndistinct) 
distinct IDteam if KEi >=12 & KEi <=36 & trans ==4 & WL2==1
local n2 =     r(ndistinct) 
cibar CVPay if KEi >=12 & KEi <=36 & trans >=3 & trans<=4 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay") note("Notes. Average monthly coeff. var in pay, 1-3 years of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue)  legend(rows(1) position(1)) yscale(range(0.28 0.36)) ylabel(0.28(0.01)0.36) ) 
graph export "$analysis/Results/8.Team/`Label'FunnelCVHL.png", replace 
graph save "$analysis/Results/8.Team/`Label'FunnelCVHL.gph", replace

********************************************************************************
* ENDOGENOUS MOBILITY CHECKS 
********************************************************************************

********************************************************************************
* 1) INSTEAD OF LOOKING AT MANAGER TRANSITIONS, LOOK SIMPLY AT FUTURE MANAGER, NOT MANAGERIAL CHANGES
* this test checks: can I predict the future manager quality, irrespective of which manager I had before? this pools together teams that had a bad or a good manager as the start so this also tells me that the future manager type is unrelated to previous manager type (not more likely to get a high manager if previously I had a high manager)
* the previous test, looking at manager change, says, given a team starts with the same type of manager quality, can I predict whether it gets a good or a bad manager next? so given I start with a low manager, does it matter my performance to get a high/low manager next?  
********************************************************************************

	local Label FT // FT PromSG75
egen `Label'HPre = rowmax( `Label'LHPre `Label'HHPre )
egen `Label'LPre = rowmax( `Label'LLPre `Label'HLPre )

global controls  FuncM CountryM Year // WLM AgeBandM 
global cont SpanM // c.TenureM##c.TenureM##i.FemaleM

eststo clear
local i = 1
local Label FT // FT PromSG75
label var  `Label'HPre  "High-flyer manager"

foreach y in  $perf $move $homo $div {
	
eststo reg`i':	reghdfe `y'  `Label'HPre `Label'LPre $cont if SpanM>1 & KEi<=-6 & KEi >=-36 & WLM==2,  cluster(IDlseMHR) a( $controls )
local lbl : variable label `y'
estadd local Controls "Yes" , replace
estadd local TeamFE "No" , replace
estadd ysumm 
local i = `i' +1

}

esttab  reg1 reg2 reg3  reg5 reg6  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

esttab  reg7  reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) ) keep( *HPre  )

esttab reg11 reg12 reg13 reg14  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared"  ) )  keep( *HPre  )


********************************************************************************
* TABLES TO EXPORT 
********************************************************************************

	local Label FT // FT PromSG75

**# ON PAPER
esttab  reg1 reg2 reg3  reg5 reg6  using "$analysis/Results/8.Team/_TeamConstant/Pre`Label'Perf.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 , labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Controls include: function, country and year FE, and team size. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

**# ON PAPER
esttab  reg7  reg8 reg9 reg10 using "$analysis/Results/8.Team/_TeamConstant/Pre`Label'Homo.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 , labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, and team size. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

**# ON PAPER
esttab reg11 reg12 reg13 reg14 using "$analysis/Results/8.Team/_TeamConstant/Pre`Label'Div.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 , labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( *HPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, and team size. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

********************************************************************************
* 2) LOOK AT THE MANAGER TRANSITIONS - CROSS SECTION PRE
********************************************************************************

global controls  FuncM CountryM Year // WLM AgeBandM 
global cont SpanM // c.TenureM##c.TenureM##i.FemaleM

eststo clear
local i = 1
	local Label FT // FT PromSG75

foreach y in  $perf $move $homo $div  {
	
eststo reg`i':	reghdfe `y' `Label'LHPre `Label'HHPre `Label'HLPre $cont if SpanM>1  & KEi<=-6 & KEi >=-36  & WLM==2 ,  cluster(IDlseMHR) a( $controls )
local lbl : variable label `y'
lincom  `Label'HLPre - `Label'HHPre
estadd scalar pvalue2 = r(p)
estadd scalar diff2 = r(estimate)
estadd local Controls "Yes" , replace
estadd local TeamFE "No" , replace
estadd ysumm 
local i = `i' +1

}

esttab reg1 reg2 reg3  reg5 reg6 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) keep( *LHPre *HHPre  *HLPre ) 

esttab  reg7  reg8 reg9 reg10 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) keep( *LHPre *HHPre  *HLPre ) 

esttab reg11 reg12 reg13 reg14,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) keep( *LHPre *HHPre  *HLPre ) 


********************************************************************************
* TABLES TO EXPORT 
********************************************************************************

	local Label FT // FT PromSG75

**# ON PAPER
esttab reg1 reg2 reg3  reg5 reg6 using "$analysis/Results/8.Team/_TeamConstant/Pre`Label'PerfTR.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2  diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) )  interaction("$\times$ ")  nobaselevels  keep( *LHPre *HHPre  *HLPre ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Controls include: function, country and year FE, and team size. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

**# ON PAPER
esttab reg7  reg8 reg9 reg10  using "$analysis/Results/8.Team/_TeamConstant/Pre`Label'HomoTR.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2  diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) ) interaction("$\times$ ")  nobaselevels  keep( *LHPre  *HHPre  *HLPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, and team size. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

**# ON PAPER
esttab reg11 reg12 reg13 reg14 using "$analysis/Results/8.Team/_TeamConstant/Pre`Label'DivTR.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2  diff2 pvalue2, labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" "\hline \textcolor{RoyalBlue} {\textbf{HtoL - HtoH}}" " \textcolor{RoyalBlue} {\textbf{p-value:}}"  ) ) interaction("$\times$ ")  nobaselevels  keep( *LHPre  *HHPre  *HLPre  ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, and team size. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

/********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE 
********************************************************************************
sort IDlseMHR YearMonth

eststo clear
local i = 1
	local Label FT // FT PromSG75
foreach y in  CVPay $perf  $move  $homo $div  {

/*mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
*/

eststo reg`i'FE:	reghdfe `y' $`Label'  c.TenureM##c.TenureM if SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36 & WL2==1, a(  IDteam ) cluster(IDlseMHR)

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

gen post = 1 in 1
replace post = 2 in 2 

label define  post 1 "Low to High"  2  "High to Low" 
label value  post  post

sort IDlseMHR YearMonth
	local Label FT // FT PromSG75

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
graph export "$analysis/Results/8.Team/_TeamConstant/`Label'`var'.png", replace 
graph save "$analysis/Results/8.Team/_TeamConstant/`Label'`var'.gph", replace 
}
 
