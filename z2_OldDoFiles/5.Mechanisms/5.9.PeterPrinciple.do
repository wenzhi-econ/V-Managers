********************************************************************************
* PETER PRINCIPLE TABLE 
********************************************************************************

use "$managersdta/AllSameTeam.dta", clear 

* Event 
********************************************************************************

gen Post = KEi >=0 if KEi!=.

* Delta of managerial talent 
foreach var in MFEBayesPromSG50 EarlyAgeM MFEBayesPromSG75 MFEBayesPromSG {
cap drop diffM Deltatag  DeltaM
xtset IDlse YearMonth 
gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag) 
gen Post`var' = Post*DeltaM
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
label var PostEarlyAgeM "Gaining a good manager"
label var PostEarlyAgeM1 "Losing a good manager"

* FINAL TABLE:  Performance, conditional on being promoted to manager
********************************************************************************

eststo clear 
eststo: reghdfe LogPayBonus  PostEarlyAgeM  Female##c.Tenure##c.Tenure   if   WL==2 & (FTLH!=. | FTLL !=.) & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs  )
eststo: reghdfe LogPayBonus  PostEarlyAgeM1  Female##c.Tenure##c.Tenure  if   WL==2 & (FTHL!=. | FTHH !=.)  & WL2==1 & Post==1, cluster(IDlseMHR) a( $abs )

esttab , star(* 0.10 ** 0.05 *** 0.01) keep(   PostEarlyAgeM PostEarlyAgeM1 ) se label

esttab using "$analysis/Results/5.Mechanisms/PeterPrinciple.tex", label star(* 0.10 ** 0.05 *** 0.01) keep( PostEarlyAgeM PostEarlyAgeM1) se r2 ///
s(  N r2, labels( "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Pay (in logs) | Promoted to Manager", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: country and year FE, worker tenure squared interacted with gender.  ///
"\end{tablenotes}") replace


