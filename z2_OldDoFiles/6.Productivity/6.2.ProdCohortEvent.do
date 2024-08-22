********************************************************************************
* SUN & ABRAHAM ESTIMATION 
********************************************************************************

/*

For step 1, we are just doing

reghdfe  Productivity L*ELH*cohort  L*ELL*cohort L*EHL*cohort  L*EHH*cohort F*ELH*cohort  F*ELL*cohort F*EHL*cohort  F*EHH*cohort c.Tenure##c.Tenure,  absorb(id month ) 

where xxx*cohort are the interactions between relative time indicators and cohort indicators.  So compared to the original dynamic two-way fixed effects regression you were already running, you just need to 1) interact the rel_time by event type indicators you included there with cohort indicators 2) re-estimate the two-way fixed effects regression with the interaction terms

for step 2, you can estimate the cohort shares by the “summarize” command. For example, to know the cohort shares among cohorts that appear in relative time 1, you can try

summarize cohort1-cohort3 if rel_time_1 == 1 & event_type = ELH

and the mean would be the cohort shares.   

for step 3, you would take the weighted average of the regression coefficient estimates from step 1 for a given relative time and a given type of event, with the weights being the cohort shares you estimate in step 2. This step can actually be achieved by Stata’s “lincom” command.  In the paper we have an additional term in the variance estimator that account for the variance from the cohort share estimates, but in my experience, the cohort shares are usually estimated quite precisely.  If you use different weights, e.g. a simple average, then that would also work as ‘lincom (1/3 * Lag1ELH_cohort1 + 1/3 * Lag1ELH_cohort2 + 1/3 * Lag1ELH_cohort3) - (1/3 * Lag1ELL_cohort1 + 1/3 * Lag1ELL_cohort2 + 1/3 * Lag1ELL_cohort3)"

*/

use "$managersdta/AllSnapshotMCultureMType.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

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

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

* 1) EVENT STUDY DUMMIES 

* never-treated  
replace Ei = . if ELL==. & ELH==. & EHL==. & EHH==. 
gen lastcohort = Ei==. // never-treated cohort

* Window around event time and event post indicator 
*  Ei EH EL
foreach var in  Ei EHL ELL EHH ELH {
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

* OPTION 1: BINNING distant leads and lags 
local end=10 // !PLUG IN! choose window suitably
foreach var in ELH ELL EHL EHH{
	gen Fend`var' = 0 
	replace Fend`var' = 1 if K`var'<-`end'
	gen Lend`var' = 0 
	replace Lend`var' = 1 if K`var'>`end'
	
	local edummies `edummies' Fend`var'
	forval i = `end'(-1)2{
	local edummies `edummies' F`i'`var'
	}

	forval i= 0/`end' {
			local edummies `edummies' L`i'`var'
	}
	
local edummies `edummies' Lend`var'
}
global edummies `edummies'
des $edummies

* OPTION 2: full leads and lags  
foreach var in ELH ELL EHL EHH{
	su K`var'
	local mmm = -(`r(min)' +1)
	forval i = `mmm'(-1)2{ // normalize -1 and r(min) for balanced sample 
	local edummiesFull `edummiesFull' F`i'`var'
	}

	forval i= 0/`r(max)' {
			local edummiesFull `edummiesFull' L`i'`var'
	}
	}
global edummiesFull `edummiesFull'
des $edummiesFull

* drop always treated individuals  (there are none)
bys IDlse: egen vv = var(EiPost) // if there is a cohort that is always treated, then we need to exclude this cohort from estimation.
drop if vv ==0 & EiPost==1 

gen YEi = year(dofm(Ei))

* 2) COHORT INTERACTION TERMS 

*qui levelsof YEi, local(cohort) 
*foreach yy of local cohort {
		forval yy = 2011(1)2020 {
			gen cohort`yy' = (YEi == `yy') 
	foreach l in $edummies {
			qui gen `l'_`yy'  = cohort`yy'* `l' 
			local eventinteract "`eventinteract' `l'_`yy'"
	}
	}

global eventinteract `eventinteract'
des $eventinteract 

* 3) COHORT SHARES, would be 110 maybe divide into quarters? or 6 months?  or 10 years?

local end =10  // !PLUG IN! specify half window 
local c = `end'*2 // specify window 

foreach var in ELH ELL EHL EHH {
	forval yy = 2011/2020{
		matrix shares`var'`yy' = J(`c',1,.)
	}
	}

cap drop shares* 
foreach var in ELH ELL EHL EHH {
	forval yy = 2011(1)2020 {
		local j = 1
			forval l = `end'(-1)2{
summarize cohort`yy' if K`var' == -`l' 

mat b_`l' = r(mean)
matrix shares`var'`yy'[`j',1] =b_`l'

	local j = `j' + 1

			} 
	local j = `end'
			forval l = 0/`end'{
summarize cohort`yy' if K`var' == `l' 
mat b_`l' = r(mean)
matrix shares`var'`yy'[`j',1] =b_`l'
	local j = `j' + 1

		} 
svmat shares`var'`yy'
}
}

* 4) FINAL COEFF: WEIGHTED AVERAGES 

////////////////////////////////////////////////////////////////////////////////
* Productivity 
////////////////////////////////////////////////////////////////////////////////

des $eventinteract 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR Func Female

eststo: reghdfe ProductivityStd $eventinteract $cont , a( $abs   ) vce(cluster IDlseMHR)

////////////////////////////////////////////////////////////////////////////////
* Set the window:
* c = 21 // -10 + 10 for productivity 
* c = 41 // -20 + 20 for pay 
* c = 121 // -60 + 60 for the rest 

local c = 21 // !PLUG! specify window 
coeffCohort1, c(`c') 
////////////////////////////////////////////////////////////////////////////////

* final plots 
 tw connected bL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdELH.gph", replace
graph export "$analysis/Results/6.Productivity/ProdELH.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdEHL.gph", replace
graph export "$analysis/Results/6.Productivity/ProdEHL.png", replace

////////////////////////////////////////////////////////////////////////////////
* ONLY CONSIDER AFTER 2017 
eststo: reghdfe ProductivityStd $eventinteract $cont if Year>2017 , a( $abs   ) vce(cluster IDlseMHR)
local c = 21 // !PLUG! specify window 
coeffCohort1, c(`c') 

* final plots 
 tw connected bL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdELH2019.gph", replace
graph export "$analysis/Results/6.Productivity/ProdELH2019.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdEHL2019.gph", replace
graph export "$analysis/Results/6.Productivity/ProdEHL2019.png", replace


////////////////////////////////////////////////////////////////////////////////
* DUMMY FOR BALANCED SAMPLE IN CALENDAR TIME
gen i = (Year==2018 | Year==2019)
bys IDlse: egen nmonth= count(cond(i==1, IDlse, .)) 
gen BalancedSample = (nmonth ==24 & i==1) 

foreach var in KELL KELH KEHH KEHL { // check balanced sample has same max and min window (especially min window is needed to be same so that we exclude the last lead in each case)
bys BalancedSample: su `var'
}

* Prepare interaction terms for the interacted regression: EXCLUDE Fend indicator when using balanced sample 
* set the window -10 - 10 for productivity 
local end=10 // !PLUG IN! choose window suitably
foreach var in ELH ELL EHL EHH{
	forval i = `end'(-1)2{
	local edummies `edummies' F`i'`var'
	}

	forval i= 0/`end' {
			local edummies `edummies' L`i'`var'
	}
	
local edummies `edummies' Lend`var'
}
global edummiesB `edummies'
des $edummiesB

*foreach yy of local cohort {
		forval yy = 2011(1)2020 {
	foreach l in $edummiesB {
			local eventinteract "`eventinteract' `l'_`yy'"
	}
	}

global eventinteractB `eventinteract'
des $eventinteractB
	
eststo: reghdfe ProductivityStd $eventinteractB $cont if BalancedSample==1, a( $abs   ) vce(cluster IDlseMHR)

local c = 21 // !PLUG! specify window 
coeffCohort1, c(`c') 

* final plots 
 tw connected bL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdELHB.gph", replace
graph export "$analysis/Results/6.Productivity/ProdELHB.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/6.Productivity/ProdEHLB.gph", replace
graph export "$analysis/Results/6.Productivity/ProdEHLB.png", replace




