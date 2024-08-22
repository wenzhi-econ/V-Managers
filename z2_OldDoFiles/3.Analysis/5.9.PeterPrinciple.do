********************************************************************************
* PETER PRINCIPLE TABLE 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 
gen Post = KEi >=0 if KEi!=.

* Delta 
xtset IDlse YearMonth 
foreach var in EarlyAgeM{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
	gen Post`var'= Post* DeltaM`var'
}
* globals and other controls 
********************************************************************************

*gen Tenure2 = Tenure*Tenure
gen TenureM2 = TenureM*TenureM
egen CountryYear = group(Country Year)

global cont   AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM Female##AgeBand // c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs  Country YearMonth   // alternative, to try  YearMonth  IDlse   
global exitFE CountryYear AgeBand AgeBandM Func Female

gen PostEarlyAgeM1 = PostEarlyAgeM
label var PostEarlyAgeM "Gaining a high-flyer manager"
label var PostEarlyAgeM1 "Losing a high-flyer manager"

eststo clear 
eststo reg1: reghdfe LogPayBonus  PostEarlyAgeM  Female##c.Tenure##c.Tenure   if   WL==2 & (FTLH!=. | FTLL !=.) & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs  )
eststo reg2: reghdfe LogPayBonus  PostEarlyAgeM1  Female##c.Tenure##c.Tenure  if   WL==2 & (FTHL!=. | FTHH !=.)  & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs )

* Adding survey variables
********************************************************************************
/* only run if want to update dataset
preserve 
* list of workers that become managers 
keep if   WL==2 & (FTLH!=. | FTLL !=.) & WL2==1 & Post==1
keep  IDlse YearMonth 
rename IDlse IDlseMHR
save "$managersdta/Temp/ListWbecM.dta", replace
restore 
*/

* how manager is scored by workers 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/ListWbecM.dta" , // list of workers
keep if _merge==3
drop _merge
gen month = month(dofm(YearMonth))
merge m:1 IDlse Year using "$fulldta/Univoice.dta"
bys IDlseMHR Year: egen MScore = mean(LineManager)
gen  EarlyAgeM1=  EarlyAgeM  
label var EarlyAgeM "Gaining a good manager"
label var EarlyAgeM1 "Losing a good manager"

* FINAL TABLE:  Performance, conditional on being promoted to manager
********************************************************************************

eststo reg3: reghdfe MScore  EarlyAgeM  Female##c.Tenure##c.Tenure   if   WL==2 & (FTLH!=. | FTLL !=.) & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs  )
eststo reg4: reghdfe MScore  EarlyAgeM1  Female##c.Tenure##c.Tenure  	  if   WL==2 & (FTHL!=. | FTHH !=.)  & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs )

esttab reg1 reg2 reg3 reg4, star(* 0.10 ** 0.05 *** 0.01) keep(   EarlyAgeM EarlyAgeM1 ) se label

* outcome mean
su MScore

esttab reg1 reg2 reg3 reg4 using "$analysis/Results/5.Mechanisms/PeterPrinciple.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(*EarlyAgeM *EarlyAgeM1) se r2 ///
s(  N r2, labels( "N" "R-squared" ) ) rename(PostEarlyAgeM EarlyAgeM PostEarlyAgeM1 EarlyAgeM1) interaction("$\times$ ")    ///
nomtitles mgroups( "Pay (in logs) | Promoted to Manager" "Effective Leader scored by reportees", pattern(1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: country and year FE, worker tenure squared interacted with gender.  ///
\textit{Effective Leader} is the workers' anonymous rating of the manager via the survey question \textit{My line manager is an effective leader}. \textit{Effective Leader} is measured on a Likert scale 1 - 5 and the mean is 4.1. ///
"\end{tablenotes}") replace

label var LogPayBonus "Pay (in logs) | Promoted to Manager"
label var  MScore "Effective Leader scored by reportees"

**# ON PAPER
coefplot (reg1, rename(PostEarlyAgeM ="Pay (in logs) | Promoted to Manager" )) (reg3,rename(EarlyAgeM ="Effective Leader scored by reportees" )) ,  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
 aseq  aspect(0.4)  coeflabels(, ) ysize(6) xsize(8) xscale(range(0 .6)) xlabel(0(0.1)0.6) ///
title("Gaining a high flyer manager", pos(12) span si(medium)) ///
 xline(0, lpattern(dash)) keep(EarlyAgeM PostEarlyAgeM ) legend(off)
graph export "$analysis/Results/5.Mechanisms/PeterPrincipleLH.png", replace 
graph save "$analysis/Results/5.Mechanisms/PeterPrincipleLH.gph", replace 

**# ON PAPER
coefplot (reg2, rename(PostEarlyAgeM1 ="Pay (in logs) | Promoted to Manager" )) (reg4,rename(EarlyAgeM1 ="Effective Leader scored by reportees" )) ,  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
 aseq  aspect(0.4)  coeflabels(, ) ysize(6) xsize(8) xscale(range(-0.5 .5)) xlabel(-0.5(0.1)0.5) ///
title("Losing a high flyer manager", pos(12) span si(medium)) ///
 xline(0, lpattern(dash)) keep(EarlyAgeM1 PostEarlyAgeM1 ) legend(off)
graph export "$analysis/Results/5.Mechanisms/PeterPrincipleHL.png", replace 
graph save "$analysis/Results/5.Mechanisms/PeterPrincipleHL.gph", replace 

