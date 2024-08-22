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

gen F60LogPayBonus = f60.LogPayBonus // 5 years after 
gen F72LogPayBonus = f72.LogPayBonus // 5 years after 

keep if Year<2014 // first 3 (<2014) or 4 (<2015) years !MANUAL INPUT! 

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

su   F60LogPayBonus F72LogPayBonus ChangeSalaryGrade PromWL  F1ChangeSalaryGrade F1PromWL

foreach v in  F60LogPayBonus F72LogPayBonus F1ChangeSalaryGrade F1PromWL LeaverPerm LeaverInv LeaverVol {
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

foreach v in  F60LogPayBonus F72LogPayBonus F1ChangeSalaryGrade F1PromWL LeaverPerm LeaverInv LeaverVol {
	xtset IDlse YearMonth
	reghdfe `v' i.Func i.AgeBand, res(`v'R) a( i.Year i.Country)
	mixed `v'R c.Tenure##c.Tenure##i.Female  ||  IDlseMHR: ,  vce(cluster IDlseMHR)
	 predict `v'Mixed, reffects 
}	
collapse *Mixed *MFEb *MFEse , by(IDlseMHR)
*keep IDlse YearMonth IDlseMHR  MFEse  MFEb // homoscedastic only
compress 
save "$managersdta/Temp/MFEBayes.dta", replace 

* Bayes shrinkage 
//////////////////////////////////////////////////////////

use "$managersdta/Temp/MFEBayes.dta", clear 

foreach v in  F60LogPayBonus F72LogPayBonus F1ChangeSalaryGrade F1PromWL LeaverPerm LeaverInv LeaverVol {
ebayes `v'MFEb `v'MFEse , gen(`v'Bayes)   var(`v'Bayesvar) rawvar(`v'Bayesrawvar) uvar(`v'Bayesuvar) theta(`v'Bayestheta)  bee(`v'Bayesbee)

*-*- Restriction #3: trim top 1% because of long tails 
winsor2 `v'Bayes , trim cuts(0 99) suffix(T) //  
*ebayes MFEb MFEse [vars] [if], [absorb() gen() bee() theta() var() uvar() rawvar() by()
}

rename F1ChangeSalaryGradeBayesT MFEBayesPromSG
rename F1PromWLBayesT MFEBayesPromWL
rename LeaverPermBayesT MFEBayesLeaver
rename LeaverVolBayesT MFEBayesLeaverVol
rename LeaverInvBayesT MFEBayesLeaverInv
rename F60LogPayBonusBayesT MFEBayesLogPayF60
rename F72LogPayBonusBayesT MFEBayesLogPayF72

su MFEBayesPromSG, d
local pSG = r(p75)
su  MFEBayesPromWL, d
local pWL = r(p75)
su MFEBayesLogPayF60, d
local pS = r(p75)

kdensity MFEBayesPromSG , bcolor(red%50)   xline(`pSG' , lcolor(red) ) xaxis(1 2) xlabel(`pSG' "p75", axis(2)) title( "Empirical Bayes Shrunk Manager Fixed Effect on Salary Prom.") xtitle("") xtitle("", axis(2))
graph save "$analysis/Results/3.FE/MFEBayesPromSG.gph", replace 
graph export "$analysis/Results/3.FE/MFEBayesPromSG.png", replace 

**# ON PAPER (with no notes)
kdensity MFEBayesLogPayF60 if MFEBayesLogPayF60>-2, bcolor(red%50)   xline(`pS' , lcolor(red) ) xaxis(1 2) xlabel(`pS' "p75", axis(2)) title( "Empirical Bayes Shrunk Manager Fixed Effect on Pay") xtitle("") xtitle("", axis(2)) note("Looking at a 5 years horizon.")
graph save "$analysis/Results/3.FE/MFEBayesPay.gph", replace 
graph export "$analysis/Results/3.FE/MFEBayesPay.png", replace 

su MFEBayesLogPayF60, d
local pS = r(p75)
hist MFEBayesLogPayF60 if MFEBayesLogPayF60>-2, bcolor(red%50)   xline(`pS' , lcolor(navy) ) xaxis(1 2) xlabel(`pS' "p75", axis(2)) title( "Empirical Bayes Shrunk Manager Fixed Effect on Pay") xtitle("") xtitle("", axis(2))  note("Looking at a 5 years horizon.")
graph save "$analysis/Results/3.FE/MFEBayesPayHist.gph", replace 
graph export "$analysis/Results/3.FE/MFEBayesPayHist.png", replace 

kdensity  MFEBayesPromWL, bcolor(%80) xline(`pWL', lcolor(red))  xaxis(1 2) xlabel(`pWL' "p75", axis(2))  title( "Empirical Bayes Shrunk Manager Fixed Effect on WL Prom.") xtitle("") xtitle("", axis(2))
graph save "$analysis/Results/3.FE/MFEBayesPromWL.gph", replace 
graph export "$analysis/Results/3.FE/MFEBayesPromWL.png", replace 

foreach var in MFEBayesLogPayF60 MFEBayesLogPayF72 MFEBayesPromSG MFEBayesPromWL  MFEBayesLeaver MFEBayesLeaverVol MFEBayesLeaverInv {
	su `var', d
	gen `var'75 = `var' >=r(p75) if `var'!=.
	gen `var'50 = `var' >r(p50) if `var'!=.

} 

pwcorr MFEBayesPromSG MFEBayesPromWL MFEBayesLeaver MFEBayesLeaverVol MFEBayesLeaverInv // there is a negative correlation and this may be due because good managers improve retention 
pwcorr MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesLeaver75 MFEBayesLeaverVol75 MFEBayesLeaverInv75 // there is a negative correlation and this may be due because good managers improve retention 

compress
*save "$managersdta/Temp/MFEBayes2015.dta", replace 
save "$managersdta/Temp/MFEBayes2014.dta", replace // NOTE: input the date! !MANUAL INPUT! 

* Does shrinkage change the order of the ranking? what about the random effects? 
* Comparing pure FE with shrinkage FE and shrinkage FE with random effects 
********************************************************************************

use  "$managersdta/Temp/MFEBayes2014.dta", clear 

cap drop  MFEBayesPromSG75  MFEBayesPromSG50  MFEBayesPromWL75 MFEBayesPromWL50 MFEBayesLogPayF6075 MFEBayesLogPayF7275 MFEBayesLogPayF6050 MFEBayesLogPayF7250
foreach var in  F60LogPayBonusMFEb F72LogPayBonusMFEb F60LogPayBonusMixed F72LogPayBonusMixed F1ChangeSalaryGradeMFEb F1ChangeSalaryGradeMixed F1PromWLMixed LeaverPermMixed LeaverInvMixed LeaverVolMixed MFEBayesPromSG MFEBayesPromWL MFEBayesLogPayF60 MFEBayesLogPayF72  {
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