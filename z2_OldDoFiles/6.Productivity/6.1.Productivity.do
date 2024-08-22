
* this dofile looks event study on productivity 

********************************************************************************
* SET UP 
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

* First RUN EventImportSun!!
////////////////////////////////////////////////////////////////////////////////

xtset IDlse YearMonth 

********************************************************************************
* Event study dummies on full sample 
********************************************************************************

* Changing manager that transfers 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & (TransferInternalL1M==1 | TransferInternalL2M==1 | TransferInternalL3M==1 | TransferInternalF1M==1  | TransferInternalF2M==1  | TransferInternalF3M==1) 
replace  ChangeMR  = . if ChangeM==.
replace  ChangeMR  = . if IDlseMHR ==. 
 
* For Sun & Abraham only consider first event 
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1

* Early age 
gsort IDlse YearMonth 
* low high
gen ChangeAgeMLowHigh = 0 
replace ChangeAgeMLowHigh = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==0    )
replace ChangeAgeMLowHigh = . if IDlseMHR ==. 
replace ChangeAgeMLowHigh = 0 if ChangeMR ==0
* high low
gsort IDlse YearMonth 
gen ChangeAgeMHighLow = 0 
replace ChangeAgeMHighLow = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==1    )
replace ChangeAgeMHighLow = . if IDlseMHR ==. 
replace ChangeAgeMHighLow = 0 if ChangeMR ==0
* high high 
gsort IDlse YearMonth 
gen ChangeAgeMHighHigh = 0 
replace ChangeAgeMHighHigh = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==1    )
replace ChangeAgeMHighHigh = . if IDlseMHR ==. 
replace ChangeAgeMHighHigh = 0 if ChangeMR ==0
* low low 
gsort IDlse YearMonth 
gen ChangeAgeMLowLow = 0 
replace ChangeAgeMLowLow = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==0   )
replace ChangeAgeMLowLow = . if IDlseMHR ==. 
replace ChangeAgeMLowLow = 0 if ChangeMR ==0

* for single differences 
egen ChangeAgeMLow = rowmax(ChangeAgeMLowHigh ChangeAgeMLowLow) // for single differences 
egen ChangeAgeMHigh = rowmax(ChangeAgeMHighHigh ChangeAgeMHighLow) // for single differences 

egen ChangeAgeMtoLow = rowmax(ChangeAgeMHighLow ChangeAgeMLowLow) // for single differences 
egen ChangeAgeMtoHigh = rowmax(ChangeAgeMHighHigh ChangeAgeMLowHigh) // for single differences 

* only consider first event 
foreach v in toLow toHigh High Low LowHigh LowLow HighHigh HighLow{
bys IDlse: egen   ChangeAgeM`v'Month = min(cond(ChangeAgeM`v'==1, YearMonth ,.)) // for single	
replace ChangeAgeM`v'= 0 if YearMonth > ChangeAgeM`v'Month  & ChangeAgeM`v'==1
}

* Add categorical variables for imputation estimator 
*bys IDlse: egen m = max(YearMonth) // time of event
* Single differences 
gen EL = ChangeAgeMLowMonth
format EL %tm 
gen EH = ChangeAgeMHighMonth
format EH %tm 
gen EtoL = ChangeAgeMtoLowMonth
format EtoL %tm 
gen EtoH = ChangeAgeMtoHighMonth
format EtoH %tm 
* Single coefficients 
gen ELH = ChangeAgeMLowHighMonth 
*replace ELH = m + 1 if ELH==.
format ELH %tm 
gen EHH = ChangeAgeMHighHighMonth 
*replace EHH = m + 1 if EHH==.
format EHH %tm 
gen ELL = ChangeAgeMLowLowMonth 
*replace ELL = m + 1 if ELL==.
format ELL %tm 
gen EHL = ChangeAgeMHighLowMonth 
*replace EHL = m + 1 if EHL==.
format EHL %tm 
////////////////////////////////////////////////////////////////////////////////

keep if ProductivityStd!=.

winsor2 ProductivityStd, cuts(1 99) suffix(T) trim by(Country)
 
su ProductivityStd if CountryS=="India",d 
gen ProductivityStdB = ProductivityStd>r(p50) if CountryS=="India" & ProductivityStd!=.
gen ProductivityDiff = d.ProductivityStd

gen ProductivityB = ProductivityDiff > 0 if ProductivityDiff!=.

* EVENT STUDY DUMMIES 

* never-treated  
replace Ei = . if ELL==. & ELH==. & EHL==. & EHH==. 
gen lastcohort = Ei==. // never-treated cohort

* Window around event time and event post indicator 
*  Ei EH EL
foreach var in  EHL ELL EHH ELH {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min) (needed when using balanced sample)
	gen F`l'`var' = K`var'==-`l'
}
}

* DEFINE VARIABLES 
global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH
global eventPost ELLPost ELHPost EHHPost EHLPost
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM TeamSize
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR 
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR Func Female

* DUMMY FOR BALANCED SAMPLE IN CALENDAR TIME
gen i = (Year==2018 | Year==2019)
bys IDlse: egen nmonth= count(cond(i==1, IDlse, .)) 
gen BalancedSample = (nmonth ==24 & i==1) 

********************************************************************************
* STATIC
********************************************************************************

eststo clear 
mean ProductivityStd 
mat coef=e(b)
local cmean = coef[1,1]
eststo: reghdfe ProductivityStd $eventPost $cont , a(  $abs ) cluster(IDlseMHR)
estadd scalar cmean = `cmean'
eststo: reghdfe ProductivityStd $eventPost $cont if Year>2017, a(  $abs ) cluster(IDlseMHR)
estadd scalar cmean = `cmean'
eststo: reghdfe ProductivityStd $eventPost $cont if BalancedSample==1, a(  $abs ) cluster(IDlseMHR)
estadd scalar cmean = `cmean'
esttab, label star(* 0.10 ** 0.05 *** 0.01) se r2 keep($eventPost)

eststo: reghdfe ProductivityStd $eventPost $cont , a(  $abs ) cluster(IDlseMHR)
eststo: reghdfe ProductivityStd $eventPost $cont , a(  $abs ) cluster(IDlseMHR)


bys Country: egen size = count(IDlse)
levelsof Country if size>3000, local(lc)
foreach l of  local lc {
 reghdfe ProductivityStd  $eventPost $cont if Country==`l', a( $abs  ) cluster(IDlseMHR)
		ta CountryS if Country==`l'
} 

********************************************************************************
* Event study 
********************************************************************************

eststo: reghdfe ProductivityStd $event $cont if CountryS == "India", a( $abs    ) vce(cluster IDlseMHR)

event_plot,  stub_lag(L#ELH) stub_lead(F#ELH) together ///
 graph_opt(xtitle("Months since the event") ytitle("OLS coefficients") xlabel(-20(2)20) ///
 yline(0, lcolor(maroon)) xline(-1, lcolor(maroon))  title("OLS")) ///
 	  trimlag(20) trimlead(20) ciplottype(rcap) 

* double differences 
coeffProd // program 
cap drop lo1 hi1 
gen lo1 = b1 -1.96*se1
gen hi1  = b1 +1.96*se1

 tw connected b1 et1 if et1>-21 & et1<21, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-21 & et1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(2)20) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdDualB.gph", replace
graph export  "$analysis/Results/6.Productivity/ProdDualB.png", replace

* single differences 
coeffProd1 // program 
cap drop loL1 hiL1 loH1 hiH1 
gen loL1 = bL1 -1.96*seL1
gen hiL1  = bL1 +1.96*seL1
gen loH1 = bH1 -1.96*seH1
gen hiH1  = bH1 +1.96*seH1
 tw connected bL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(2)20) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdSingleLowB.gph", replace
graph export  "$analysis/Results/6.Productivity/ProdSingleLowB.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(2)20) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdSingleHighB.gph", replace
graph export  "$analysis/Results/6.Productivity/ProdSingleHighB.png", replace

********************************************************************************
* Sun and Abraham (2020)
********************************************************************************

gen lastcohortLow = EL==. // dummy for the never-treated cohort
gen lastcohortLowHigh = ELH==. // dummy for the never-treated cohort
gen lastcohortLowLow = ELL==. // dummy for the never-treated cohort

eventstudyinteract ProductivityStd F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh if  Year<2020, absorb(CountryYM AgeBand AgeBandM  IDlse IDlseMHR ) cohort(EL) control_cohort(lastcohortLow) covariates( c.Tenure##c.Tenure)

eventstudyinteract LogPayBonus F*ChangeAgeMLowLow L*ChangeAgeMLowLow , absorb(CountryYM AgeBand AgeBandM IDlse IDlseMHR ) cohort(ELL) control_cohort(lastcohortLowLow) covariates( c.Tenure##c.Tenure)

event_plot e(b_iw)#e(V_iw),  graph_opt(xtitle("Periods since the event")  ytitle("Average causal effect") xlabel(-21(3)21) ///
	title("Sun and Abraham (2020)") yline(0, lcolor(maroon)) xline(-1, lcolor(maroon))  ) stub_lag(L#_ChangeAgeMLowLow) stub_lead(F#_ChangeAgeMLowLow) together ciplottype(rcap) ///
	  trimlag(20) trimlead(20)
	  
graph save  "$analysis/Results/6.Productivity/ProdSunB.gph", replace
graph export  "$analysis/Results/6.Productivity/ProdSunB.png", replace

********************************************************************************
* Borusyak et al. (2021) imputation estimator
********************************************************************************

reghdfe ProductivityStd  if ELHPost==0 , a(  $abs ) cluster(IDlseMHR)
predict x, xb
replace x = 0 if ELHPost!=0
drop if  cannot_impute==1
bys IDlse : egen x = sd(ELHPost) if ProductivityStd!=.
did_imputation ProductivityStd IDlse YearMonth  ELH , allhorizons pretrend(6) autosample cluster(IDlseMHR) fe( $abs ) 
event_plot, default_look trimlag(12) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Productivity (sales), Borusyak et al. (2021) imputation estimator") xlabel(-6(1)12) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/6.Productivity/DIDProd.gph", replace
graph export  "$analysis/Results/6.Productivity/DIDProd.png", replace

/* cuts 
* IV
bys IDlse: egen mm = min(YearMonth)
bys IDlse: egen ProductivityStd0 = mean(cond(YearMonth ==mm | YearMonth ==mm+1 | YearMonth ==mm+2, ProductivityStd,. ))
ivreghdfe ProductivityStd  (TransferInternalSJC = EarlyAgeM) c.Tenure##c.Tenure , a(Year  AgeBand WLM FemaleM ) cluster(IDlseMHR)
ivreghdfe ProductivityStd  (TransferInternalSJC = EarlyAgeM) c.Tenure##c.Tenure , a(Year  AgeBand WLM FemaleM IDlse) cluster(IDlseMHR)

reghdfe ProductivityStd  EarlyAgeM c.Tenure##c.Tenure , a(Year  AgeBand WLM FemaleM ) cluster(IDlseMHR)


