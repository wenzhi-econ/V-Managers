use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

********************************************************************************
* Define top manager based on data 2011-2015 only - first event based on half sample only
********************************************************************************

keep if Year<=2015
egen CountryYear = group(Country Year)
global cont  Tenure Tenure2 TenureM TenureM2
global abs CountryYear AgeBand AgeBandM

keep  LogPayBonus ChangeSalaryGradeC Tenure TenureM Year Country CountryYear YearMonth IDlseMHR IDlse AgeBand AgeBandM BC WL

gen Tenure2 = Tenure*Tenure
gen TenureM2 = TenureM*TenureM
* Estimate managers FE  
*PAY cannot be done because of sample 2011-2015
*reghdfe LogPayBonus $cont if BC ==0 , a( MFEPayWC = IDlseMHR EFEPayWC= IDlse $abs ) vce(cluster IDlseMHR) residuals(res)  

********************************************************************************
* CHANGE IN PROM
********************************************************************************

* 1) empirical bayes for MFE
reghdfe ChangeSalaryGradeC , a(  IDlse $abs ) vce(cluster IDlseMHR) residuals(resy1)  // residualize on managers FE
*xtreg resy , fe 
*predict EFE,u
fese resy1 $cont , a(IDlseMHR) s(MFE) oonly
preserve
keep MFEse MFEhrse MFEcrse MFEb IDlseMHR IDlse YearMonth
compress 
save "$analysis/Results/3.FE/MFEBayes.dta", replace 
restore 

*fese resy1 $cont , a(IDlse) s(MFE) vce(cluster IDlseMHR) // SHOULD BE SLOWER as it is with cluster 
ebayes MFEb MFEse , gen(MFEBayes)   var(MFEBayesvar) rawvar(MFEBayesrawvar) uvar(MFEBayesuvar) theta(MFEBayestheta)  bee(MFEBayesbee)
*ebayes MFEb MFEse [vars] [if], [absorb() gen() bee() theta() var() uvar() rawvar() by()

* USEFUL STATS 
egen match = tag(IDlseMHR IDlse)
egen Mid = tag(IDlseMHR)
egen Eid = tag(IDlse)
bys IDlseMHR: nemp = sum(match) 
bys IDlseMHR: nman = sum(match) 
ta nman if Eid==1  
ta nemp if Mid==1  // Roughly XX  of managers change reportees  and almost X% of employees experience a change in management between 2011 and 2015

preserve 
keep IDlse  YearMonth  IDlseMHR MFEse MFEhrse MFEcrse MFEb   MFEBayes MFEBayesvar MFEBayesrawvar MFEBayesuvar MFEBayestheta MFEBayesbee
compress
save "$analysis/Results/3.FE/MFEBayes.dta", replace 
restore 

/* not necessary to run 
* 1) empirical bayes for EFE
reghdfe ChangeSalaryGradeC , a(  IDlseMHR $abs ) vce(cluster IDlseMHR) residuals(resy2)  // residualize on managers FE
*xtreg resy , fe 
*predict EFE,u
fese resy2 $cont , a(IDlse) s(EFE) vce(cluster IDlseMHR)
ebayes resy2 EFEse , gen(EFEBayes)  var(EFEBayesvar)
*ebayes EFEPromWC seEFE [vars] [if], [absorb() gen() bee() theta() var() uvar() rawvar() by()

preserve 
keep IDlse EFE
save "$analysis/Results/3.FE/EFEBayes.dta", replace 

collapse  EFE , by(IDlse)
hist EFE, fraction    xtitle(Employee FE (empirical bayes) in promotion)
graph export "$analysis/Results/3.FE/histEFEBayes.png", replace

restore 

*/

* USEFUL STATS 
egen match = tag(IDlseMHR IDlse)
egen Mid = tag(IDlseMHR)
egen Eid = tag(IDlse)
bys IDlseMHR: nemp = sum(match) 
bys IDlseMHR: nman = sum(match) 
ta nman if Eid==1  
ta nemp if Mid==1  // Roughly XX  of managers change reportees  and almost X% of employees experience a change in management between 2011 and 2015

preserve 
keep IDlseMHR MFE
save "$analysis/Results/3.FE/MFEBayes.dta", replace 

collapse  MFE , by(IDlseMHR)
hist MFE, fraction    xtitle(Manager FE (empirical bayes) in promotion) 
graph export "$analysis/Results/3.FE/histEFEBayes.png", replace

restore 

use "$Managersdta/MFEPromWLCBayes.dta", clear 
collapse  MFEBayes , by(IDlseMHR)
hist MFEBayes, fraction    xtitle(Manager FE (empirical bayes) in promotion) 
graph export "$analysis/Results/3.FE/histMFEPromWLCBayes.png", replace

********************************************************************************
* RSQUARED CHECK
********************************************************************************


use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

********************************************************************************
* Define top manager based on data 2011-2015 only - first event based on half sample only
********************************************************************************

keep if Year<=2015
egen CountryYear = group(Country Year)
global cont  Tenure Tenure2 TenureM TenureM2
global abs CountryYear AgeBand AgeBandM 

keep  LogPayBonus ChangeSalaryGradeC Tenure TenureM Year Country CountryYear YearMonth IDlseMHR IDlse AgeBand AgeBandM BC WL

gen Tenure2 = Tenure*Tenure
gen TenureM2 = TenureM*TenureM
* Estimate managers FE  
*PAY cannot be done because of sample 2011-2015
*reghdfe LogPayBonus $cont if BC ==0 , a( MFEPayWC = IDlseMHR EFEPayWC= IDlse $abs ) vce(cluster IDlseMHR) residuals(res)  

********************************************************************************
* CHANGE IN PROM - Rsquared table 
********************************************************************************

* 1) empirical bayes for EFE
reghdfe ChangeSalaryGradeC , a(  IDlseMHR $abs ) vce(cluster IDlseMHR) 

egen group = group(IDlse IDlseMHR )

*Reported obs differ because of singletons

* 1) only controls and time FE
reghdfe ChangeSalaryGradeC $cont , a(   $abs  ) vce(cluster IDlseMHR)

/* HDFE Linear regression                            Number of obs   =  3,503,089
Absorbing 11 HDFE groups                          F(   0,  28931) =          .
Statistics robust to heteroskedasticity           Prob > F        =          .
                                                  R-squared       =     0.7839
                                                  Adj R-squared   =     0.7835
                                                  Within R-sq.    =     0.0000
Number of clusters (IDlseMHR) =     28,932        Root MSE        =     0.4178

*/


* 2) only controls and time FE + Employee FE
reghdfe ChangeSalaryGradeC $cont , a(   $abs IDlse ) vce(cluster IDlseMHR)


* 3) only controls and time FE  + Employee FE + manager FE 
reghdfe ChangeSalaryGradeC $cont , a(   $abs IDlse IDlseMHR ) vce(cluster IDlseMHR)


* 4) only controls and time FE   + manager FE 
reghdfe ChangeSalaryGradeC $cont , a(   $abs  IDlseMHR ) vce(cluster IDlseMHR)

* 5) only controls and time FE   + employee-manager FE 
reghdfe ChangeSalaryGradeC $cont , a(   $abs  group ) vce(cluster IDlseMHR)

********************************************************************************
* variance decomposition exercise 
********************************************************************************

reghdfe PromWLC, nocons absorb(  CountryYear IDlse IDlseMHR, savefe  ) residuals(res) 
	
	* Relabel and rename FEs for ease of computation.
	ds *hdfe* res
	loc FixEffs `r(varlist)'
	
	foreach var in `FixEffs' {
		
		loc old: var label `var'
		loc new: subinstr local old "[FE] 1." ""
	
		label var `var' "`new'"
		loc `var'_label: var la `var'
		rename `var'  FE``var'_label'
		
	}
	
	* Compute the Variance-Covariance Matrix for all FEs and Residuals.
		corr  FECountryYear FEIDlse FEIDlseMHR  FEResiduals, cov
		mat define CovVar = r(C)
		
	* Generate a Categorical variable which details the Type of Variance
		gen VarComp = _n
		replace VarComp = . if VarComp > 7
		label values VarComp comps
		
	* Generate a Variable which stores the values associated with each variance type.
		gen Variance = .
	
		* Variance Terms (diagonals)
		forvalues i = 1/4 {
			
				replace Variance = CovVar[`i',`i'] if VarComp == `i'
					
			}
			
	* Covariance Terms (off-diagonals)
		replace Variance = abs(2*CovVar[2,1]) if VarComp == 5
		replace Variance = abs(2*CovVar[3,1]) if VarComp == 6
		replace Variance = abs(2*CovVar[3,2]) if VarComp == 7
		
	* Convert to Percentage of Total Variance in Dep Var.	
		egen TotalVar = total(Variance)
		gen StandVarPercent = (Variance/TotalVar)*100
		gen StandVarShare = round(StandVarPercent,0.01)

* Chart creation (first for WC and second for BC)
graph hbar StandVarShare, over(VarComp, sort(StandVarShare) gap(150)) asyvars blabel(bar) ytitle("Share of Promotion Rate Total Variance (%)") bar(1, color(purple)) bar(2, color(maroon)) bar(3, color(navy)) bar(4, color(ebblue)) bar(5, color(green)) bar(6, color(orange)) bar(7, color(dkgreen)) scheme(aurora) legend(size(vsmall) rows(4) ring(0) pos(2) region(style(none))) note("Notes.")
graph export "$analysis/Results/3.FE/VarDecomp.png", replace

* Diagnostic check to ensure the total variance calculated from all sources in fixed effects and residuals equals that actually observed in the dependent variable.		
summ ChangeSalaryGradeC if e(sample), det

di "Actual variance:" %6.5f r(Var) _newline "Calculated variance:" %6.5f TotalVar[1]
