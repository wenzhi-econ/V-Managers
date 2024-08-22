********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

use "$Managersdta/HetVPA.dta", clear 

********************************************************************************
* HAZART RATE & HET BY PERFORMANCE 
********************************************************************************

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR Func Female
global hazard c.Tenure##c.Tenure c.TenureM##c.TenureM i.Country i.Year i.AgeBand i.AgeBandM i.Func Female
*  i.IDlseMHR
* get the VPA 6 months before transfer 
* split event study analysis by baseline performance 

* HAZARD EXIT 
gsort IDlse YearMonth
bys IDlse: gen eventC = sum(Leaver[_n-1]) // count for the occurence of event
egen Episode = group(IDlse eventC) // episode as a continuous period for which an individual is at risk of experiencing an event
bys Episode (YearMonth): gen tLeaver =_n // dummies from randomization onwards
drop eventC Episode

cloglog Leaver EarlyAgeM c.Tenure##c.Tenure Female   i.tLeaver i.Country i.Year , cluster(IDlseMHR) nolog eform // 1.08 and significant (1.06 in full sample)

* BY VPA 

cloglog Leaver EarlyAgeM i.tLeaver i.Country i.Year if VPA1000==0 , cluster(IDlseMHR) nolog eform 
predict hH, p
bys IDlse (tLeaver) : ge sH = exp(sum(ln(1-hH)))
gen hH0 = hH if EarlyAgeM==0
gen hH1 = hH if EarlyAgeM==1
gen sH0 = sH if EarlyAgeM==0
gen sH1 = sH if EarlyAgeM==1
preserve 
collapse hH hH0 hH1 sH sH0 sH1, by( tLeaver)
twoway connect hH0 tLeaver, sort || connect hH1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
graph export "$analysis/Results/5.Transfers/ExitVPAHighH.png" 
twoway connect sH0 tLeaver, sort || connect sH1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
graph export "$analysis/Results/5.Transfers/ExitVPAHighS.png" 
restore 

cloglog Leaver EarlyAgeM i.tLeaver i.Country i.Year if VPA1000==1 , cluster(IDlseMHR) nolog eform 
predict hL, p

bys IDlse (tLeaver) : ge sL = exp(sum(ln(1-hL)))
gen hL0 = hL if EarlyAgeM==0
gen hL1 = hL if EarlyAgeM==1
gen sL0 = sL if EarlyAgeM==0
gen sL1 = sL if EarlyAgeM==1
preserve 
collapse hL hL0 hL1 sL sL0 sL1, by( tLeaver)
twoway connect hL0 tLeaver, sort || connect hL1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
graph export "$analysis/Results/5.Transfers/ExitVPALowH.png" 

twoway connect sL0 tLeaver, sort || connect sL1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
graph export "$analysis/Results/5.Transfers/ExitVPALowS.png" 
restore 

* ALTOGETHER 
gen HH = EarlyAgeM*(1-VPA1000)
gen LH = (1-EarlyAgeM)*(1-VPA1000)
gen HL = (EarlyAgeM)*(VPA1000)
* BASELINE IS NON FAST TRACK LOW PERFORMER
cloglog Leaver HH LH HL i.tLeaver $hazard if tLeaver <90 , cluster(IDlseMHR) nolog eform 

*cloglog Leaver EarlyAgeM##VPA1000 i.tLeaver $hazard , cluster(IDlseMHR) nolog eform 
predict h, p

cap drop h s hL0 hL1 hH0 hH1 sL0 sL1 sH0 sH1
bys IDlse (tLeaver) : ge s = exp(sum(ln(1-h)))
gen hL0 = h if EarlyAgeM==0 & VPA1000==1
gen hL1 = h if EarlyAgeM==1 & VPA1000==1
gen sL0 = s if EarlyAgeM==0 & VPA1000==1
gen sL1 = s if EarlyAgeM==1 & VPA1000==1

gen hH0 = h if EarlyAgeM==0  & VPA1000==0
gen hH1 = h if EarlyAgeM==1  & VPA1000==0
gen sH0 = s if EarlyAgeM==0 & VPA1000==0
gen sH1 = s if EarlyAgeM==1 & VPA1000==0

preserve 
collapse h  s hL0 hL1 hH0 hH1 sL0 sL1 sH0 sH1, by( tLeaver)
keep if tLeaver <=85 
twoway connect hL0 tLeaver, sort xlabel(0(5)85) xscale(range(0 85)) || connect hL1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
graph export "$analysis/Results/5.Transfers/ExitVPALowH.png" , replace 

twoway connect sL0 tLeaver, sort xlabel(0(5)85) xscale(range(0 85)) || connect sL1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
graph export "$analysis/Results/5.Transfers/ExitVPALowS.png" , replace 

twoway connect hL0 tLeaver, sort xlabel(0(5)85) xscale(range(0 85)) || connect hL1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
graph export "$analysis/Results/5.Transfers/ExitVPAHighH.png" , replace 

twoway connect sL0 tLeaver, sort xlabel(0(5)85) xscale(range(0 85)) || connect sL1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
graph export "$analysis/Results/5.Transfers/ExitVPAHighS.png", replace 
restore




cloglog TransferInternal EarlyAgeM i.tLeaver i.Country i.Year , cluster(IDlseMHR) nolog eform 
cloglog TransferInternalSameM EarlyAgeM i.tLeaver i.Country i.Year , cluster(IDlseMHR) nolog eform 

* to plot hazard 
********************************************************************************

cloglog Leaver EarlyAgeM i.tLeaver i.Country i.Year , cluster(IDlseMHR) nolog eform // 1.08 and significant 
predict h, p
bys IDlse (tLeaver) : ge s = exp(sum(ln(1-h)))
gen h0 = h if EarlyAgeM==0
gen h1 = h if EarlyAgeM==1
gen s0 = s if EarlyAgeM==0
gen s1 = s if EarlyAgeM==1
preserve 
collapse h h0 h1 s s0 s1, by( tLeaver)
twoway connect h0 tLeaver, sort || connect h1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
twoway connect s0 tLeaver, sort || connect s1 tLeaver, sort xtitle(Month) legend(label(1 "Non fast track") label(2 "Fast track") )
restore 

* to get the standard errors 
********************************************************************************

predictnl h = invcloglog(xb()), se(seh) //  predicted logistic hazard rate for each person given the values of his or her covariates and the value of j in the relevant spell month

replace seh = seh*seh // variance - Average sd: You average the variances; then you can take square root to get the average standard deviation.

preserve 
collapse h seh [aweight = size ], by(EarlyAgeM t)
replace seh = seh^(1/2) // standard deviation = square root variance 
	gen hU = h + 1.645*seh // 10 % CI 
	gen hL = h - 1.645*seh
keep if t <=20
twoway (connect h t if t<=20 & EarlyAgeM==0, sort  msymbol(t) lcolor(green)) (connect h t if t<=20 & EarlyAgeM==1, sort msymbol(o) lcolor(orange) ) || rcap hU hL t if EarlyAgeM== 0  || rcap hU hL t if EarlyAgeM == 1  ///
	,  title("Exit, hazard rate") ytitle("") xtitle(Month) xtitle("", axis(1)) legend( order(1 "Non fast track" 2 "Fast track manager"))  xlabel(0(2)20) xscale(range(0 20))
	graph export "ExitHazard.png", replace
	
/*twoway (connect h t if t<=20 & EarlyAgeM==0, sort  msymbol(t) lcolor(green)) (connect h t if t<=20 & EarlyAgeM==1, sort msymbol(o) lcolor(orange) ) || rcap hU hL t if EarlyAgeM== 0  || rcap hU hL t if EarlyAgeM == 1  ///
	,  title("Exit, hazard rate") ytitle("") xtitle(Month, axis(2)) xtitle("", axis(1)) legend( order(1 "Control" 2 "Treatment")) tla(3 "10% did PW" 6 "50% did PW" 16 "90% did PW", axis(1) grid glcolor(red) labsize(small)) xaxis(1 2) xlabel(0(2)20, axis(2)) xscale(range(0 20))
	graph export "ExitHazard.png", replace
*/
restore 
