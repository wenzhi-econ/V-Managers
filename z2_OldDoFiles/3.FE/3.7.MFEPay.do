********************************************************************************
* Dec 2021 
* BAYES ESTIMATOR OF MANAGER FE IN PROMOTIONS
********************************************************************************

********************************************************************************
* LOAD DATA 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
*use "$managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

********************************************************************************
* Define top manager based on data 2011-2015 only - first event based on half sample only
********************************************************************************

xtset IDlse YearMonth

drop if IDlseMHR==. 

*-*- Restriction #1
bys IDlseMHR : egen minYM= min(YearMonth)
bys IDlseMHR : egen maxYM= max(YearMonth)
format (minYM maxYM) %tm
gen MDuration =  maxYM - minYM 
su MDuration, d 

keep if MDuration >=24 // only managers that are in the sample as managers for at least 2 years (circa 25 percentile)

*-*- Restriction #2
egen ttI = tag(IDlse IDlseMHR)
bys IDlseMHR: egen TotWorkers = sum(ttI)
su TotWorkers, d
su TotWorkers if ttI==1, d
 
keep if TotWorkers > 9 // (p25), minimum number of workers above 9 otw too noisy 


xtset IDlse YearMonth
foreach v in ChangeSalaryGrade PromWL{ // taking into account when promoted under different manager, creates missing values for the last period a worker is present
gen F1`v' = f.`v'
} 


* estimate FE and their SDs - to apply bayes shrinkage 
//////////////////////////////////////////////////////////

su   LogPayBonus 

foreach v in  LogPayBonus {
	xtset IDlse YearMonth
	* first de-mean the outcome to reduce computational demands
	areg `v' c.Tenure##c.Tenure##i.Female i.Func i.AgeBand i.Year, a(   ISOCode  )   // residualize on managers FE
	predict res`v', res
	* then compute the manager FE and their SD 
	areg res`v', a(IDlseMHR) // F-test significant <0.000 
	predict `v'MFEb, d
	replace `v'MFEb=`v'MFEb+_b[_cons]
	predict resid`v', r
	generate sqres`v'=resid`v'^2
	egen N`v'=count(sqres`v'), by(IDlseMHR)
	summarize sqres`v', meanonly
	generate `v'MFEse=sqrt(r(mean)*e(N)/e(df_r)/N`v')

*fese res`v' , a(IDlseMHR) s(`v'MFE) oonly // estimate sd 
}

* R squared if 55% when looking at future pay 

* compute random effects to compare 
//////////////////////////////////////////////////////////

foreach v in  LogPayBonus {
	xtset IDlse YearMonth
	reghdfe `v' i.Func i.AgeBand, res(`v'R) a( i.Year i.Country)
	mixed `v'R c.Tenure##c.Tenure##i.Female  ||  IDlseMHR: ,  vce(cluster IDlseMHR)
	 predict `v'Mixed, reffects 
}	
collapse *Mixed *MFEb *MFEse , by(IDlseMHR)
*keep IDlse YearMonth IDlseMHR  MFEse  MFEb // homoscedastic only
compress 
save "$managersdta/Temp/MFEBayesPay.dta", replace 

* Bayes shrinkage 
//////////////////////////////////////////////////////////

do "$analysis/DoFiles/3.FE/ebayes.ado" 
 
use "$managersdta/Temp/MFEBayesPay.dta", clear 

foreach v in  LogPayBonus {
ebayes `v'MFEb `v'MFEse , gen(`v'Bayes)   var(`v'Bayesvar) rawvar(`v'Bayesrawvar) uvar(`v'Bayesuvar) theta(`v'Bayestheta)  bee(`v'Bayesbee)

*-*- Restriction #3: trim top 1% because of long tails 
winsor2 `v'Bayes , trim cuts(0 99) suffix(T) //  
*ebayes MFEb MFEse [vars] [if], [absorb() gen() bee() theta() var() uvar() rawvar() by()
}

rename LogPayBonusBayesT MFEBayesLogPay

su MFEBayesLogPay, d
local pS = r(p75)
kdensity MFEBayesLogPay if MFEBayesLogPay>-2, bcolor(red%50)   xline(`pS' , lcolor(red) ) xaxis(1 2) xlabel(`pS' "p75", axis(2)) title( "Empirical Bayes Shrunk Manager Fixed Effect on Pay") xtitle("") xtitle("", axis(2)) note("Looking at a 5 years horizon.")
graph save "$analysis/Results/3.FE/MFEBayesPay2.gph", replace 
graph export "$analysis/Results/3.FE/MFEBayesPay2.png", replace  

foreach var in MFEBayesLogPay {
	su `var', d
	gen `var'75 = `var' >=r(p75) if `var'!=.
	gen `var'50 = `var' >r(p50) if `var'!=.

} 

compress
save "$managersdta/Temp/MFEBayesPay.dta", replace // NOTE: input the date! !MANUAL INPUT! 

/* Does shrinkage change the order of the ranking? what about the random effects? 
* Comparing pure FE with shrinkage FE and shrinkage FE with random effects 
********************************************************************************

use  "$managersdta/Temp/MFEBayesPay.dta", clear 

cap drop  MFEBayesLogPay  {
	su `var', d
	gen `var'75 = `var' >=r(p75) if `var'!=.
	gen `var'50 = `var' >r(p50) if `var'!=.
	egen R`var' = rank(`var'), unique
} 

* 1) FE - compare pure FE with shrinkage FE 
********************************************************************************
gen ind75 = F1ChangeSalaryGradeMFEb75 == MFEBayesPromSG75 if MFEBayesPromSG75!= . & F1ChangeSalaryGradeMFEb75!=. 
gen ind50 = F1ChangeSalaryGradeMFEb50 == MFEBayesPromSG50 if MFEBayesPromSG50!= . & F1ChangeSalaryGradeMFEb50!=. 
gen ind75Pay = F60LogPayBonusMFEb75 ==MFEBayesLogPayF6075 if MFEBayesLogPayF6075!= . &  F60LogPayBonusMFEb75!=. 

ta F1ChangeSalaryGradeMFEb75 MFEBayesPromSG75
ta F1ChangeSalaryGradeMFEb50 MFEBayesPromSG50

su ind75  ind75Pay
* >>> yes but for very fews obs (97% have same ranking), confirms what expected in theory, although in practice very few obs change ranking 

* scatter of the rank 
tw scatter RMFEBayesPromSG  RF1ChangeSalaryGradeMFEb || (function y=x, range(0 6000)), legend(off) ytitle("Shrunk Fixed Effects Rank") xtitle("Fixed Effects Rank") title("Shrunk FE versus FE, Rank")
graph save "$analysis/Results/3.FE/RankShrunkFEvsFE.gph", replace 
graph export "$analysis/Results/3.FE/RankShrunkFEvsFE.png", replace 

winsor2 F1ChangeSalaryGradeMFEb, trim cuts(0 99) suffix(T) // removing extreme outliers in the pure FE 
tw scatter  MFEBayesPromSG F1ChangeSalaryGradeMFEbT || (function y=x, range(-0.04 0.04)), legend(off)  ytitle("Shrunk Fixed Effects") xtitle("Fixed Effects") title("Shrunk FE versus FE, Estimates")
graph save "$analysis/Results/3.FE/EstimateShrunkFEvsFE.gph", replace 
graph export "$analysis/Results/3.FE/EstimatehrunkFEvsFE.png", replace 

* PAY
tw scatter RMFEBayesLogPayF60  RF60LogPayBonusMFEb || (function y=x, range(0 6000)), legend(off) ytitle("Shrunk Fixed Effects Rank") xtitle("Fixed Effects Rank") title("Shrunk FE versus FE, Rank")
graph save "$analysis/Results/3.FE/RankShrunkFEvsFEPay.gph", replace 
graph export "$analysis/Results/3.FE/RankShrunkFEvsFEPay.png", replace 

winsor2 F60LogPayBonusMFEb, trim cuts(0 99) suffix(T) // removing extreme outliers in the pure FE 
tw scatter  MFEBayesLogPayF60 F60LogPayBonusMFEbT || (function y=x, range(-3 1.5)), legend(off)  ytitle("Shrunk Fixed Effects") xtitle("Fixed Effects") title("Shrunk FE versus FE, Estimates")
graph save "$analysis/Results/3.FE/EstimateShrunkFEvsFEPay.gph", replace 
graph export "$analysis/Results/3.FE/EstimatehrunkFEvsFEPay.png", replace 

* 2) RE - compare RE with shrinkage FE 
********************************************************************************
gen Rind75 = F1ChangeSalaryGradeMixed75 == MFEBayesPromSG75 if MFEBayesPromSG75!= . & F1ChangeSalaryGradeMixed75!=. 
gen Rind50 = F1ChangeSalaryGradeMixed50 == MFEBayesPromSG50 if MFEBayesPromSG50!= . & F1ChangeSalaryGradeMixed50!=. 
gen RindPay75 = F60LogPayBonusMixed75 == MFEBayesLogPayF6075 if MFEBayesLogPayF6075!= . & F60LogPayBonusMixed75!=. 

ta Rind75
ta F1ChangeSalaryGradeMixed75 MFEBayesPromSG75
ta F1ChangeSalaryGradeMixed50 MFEBayesPromSG50


su ind50 ind75 Rind50 Rind75 RindPay75 
* >>> yes but for very fews obs (97% have same ranking!), confirms what expected in theory, they should be very similar 

* scatter of the rank 
tw scatter RMFEBayesPromSG  RF1ChangeSalaryGradeMixed || (function y=x, range(0 6000)), legend(off) ytitle("Shrunk Fixed Effects Rank") xtitle("Random Effects Rank") title("Shrunk FE versus RE, Rank")
graph save "$analysis/Results/3.FE/RankShrunkFEvsRE.gph", replace 
graph export "$analysis/Results/3.FE/RankShrunkFEvsRE.png", replace 

winsor2 F1ChangeSalaryGradeMixed, trim cuts(0 99) suffix(T) // removing extreme outliers in the pure FE 
tw scatter  MFEBayesPromSG F1ChangeSalaryGradeMixedT || (function y=x, range(-0.02 0.02)), legend(off)  ytitle("Shrunk Fixed Effects") xtitle("Random Effects") title("Shrunk FE versus RE, Estimates") xscale(range(-0.02 0.02)  ) xlabel(-0.02(0.01)0.02)
graph save "$analysis/Results/3.FE/EstimateShrunkFEvsRE.gph", replace 
graph export "$analysis/Results/3.FE/EstimatehrunkFEvsRE.png", replace 

* pay 
tw scatter RMFEBayesLogPayF60  RF60LogPayBonusMixed || (function y=x, range(0 6000)), legend(off) ytitle("Shrunk Fixed Effects Rank") xtitle("Random Effects Rank") title("Shrunk FE versus RE, Rank")
graph save "$analysis/Results/3.FE/RankShrunkFEvsREPay.gph", replace 
graph export "$analysis/Results/3.FE/RankShrunkFEvsREPay.png", replace 

winsor2 F60LogPayBonusMixed, trim cuts(0 99) suffix(T) // removing extreme outliers in the pure FE 
tw scatter  MFEBayesLogPayF60 F60LogPayBonusMixedT || (function y=x, range(-3 1.5)), legend(off)  ytitle("Shrunk Fixed Effects") xtitle("Random Effects") title("Shrunk FE versus RE, Estimates") xscale(range(-3 1.5)  ) xlabel(-3(0.5)1.5)
graph save "$analysis/Results/3.FE/EstimateShrunkFEvsREPay.gph", replace 
graph export "$analysis/Results/3.FE/EstimatehrunkFEvsREPay.png", replace 
