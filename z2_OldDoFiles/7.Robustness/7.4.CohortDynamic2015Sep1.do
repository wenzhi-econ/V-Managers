* COHORT INDICATOR USING 2015 DATA 

use "$managersdta/AllSnapshotMCultureMType2015.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 


////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

* 1) COHORT INTERACTION TERMS 

* never-treated  
replace Ei = . if ELL==. & ELH==. & EHL==. & EHH==. 
gen lastcohort = Ei==. // never-treated cohort

* Window around event time and event post indicator 
foreach var in Ei EH EL EHL ELL EHH ELH {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

* drop always treated individuals  (there are none)
bys IDlse: egen vv = var(EiPost) // if there is a cohort that is always treated, then we need to exclude this cohort from estimation.
drop if vv ==0 & EiPost==1 

gen YEi = year(dofm(Ei))

* Prepare interaction terms for the interacted regression
* set the window -10 - 10 for productivity 
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

*generate cohort - event dummies interactions 
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

* 2) COHORT SHARES, would be 110 maybe divide into quarters? or 6 months?  or 10 years?

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

* 3) FINAL COEFF: WEIGHTED AVERAGES 

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
graph save  "$analysis/Results/7.Robustness/ProdELH.gph", replace
graph export "$analysis/Results/7.Robustness/ProdELH.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ProdEHL.gph", replace
graph export "$analysis/Results/7.Robustness/ProdEHL.png", replace

////////////////////////////////////////////////////////////////////////////////
* ONLY CONSIDER AFTER 2017 
eststo: reghdfe ProductivityStd $eventinteract $cont if Year>2017 , a( $abs   ) vce(cluster IDlseMHR)
local c = 21 // !PLUG! specify window 
coeffCohort1, c(`c') 

* final plots 
 tw connected bL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ProdELH2019.gph", replace
graph export "$analysis/Results/7.Robustness/ProdELH2019.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ProdEHL2019.gph", replace
graph export "$analysis/Results/7.Robustness/ProdEHL2019.png", replace


////////////////////////////////////////////////////////////////////////////////
* DUMMY FOR BALANCED SAMPLE IN CALENDAR TIME
gen i = (Year==2018 | Year==2019)
bys IDlse: egen nmonth= count(cond(i==1, IDlse, .)) 
gen BalancedSample = (nmonth ==24 & i==1) 

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
graph save  "$analysis/Results/7.Robustness/ProdELHB.gph", replace
graph export "$analysis/Results/7.Robustness/ProdELHB.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ProdEHLB.gph", replace
graph export "$analysis/Results/7.Robustness/ProdEHLB.png", replace

////////////////////////////////////////////////////////////////////////////////
* COHORT INDICATOR USING 2015 DATA BUT SAME EVENT TIME AS FULL SAMPLE 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/AllSnapshotMCultureMType2015.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

drop Ei ELL ELH EHL EHH
foreach var in Ei ELL ELH EHL EHH{
rename `var'1 `var'	
}

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

* 1) COHORT INTERACTION TERMS 

* never-treated  
replace Ei = . if ELL==. & ELH==. & EHL==. & EHH==. 
gen lastcohort = Ei==. // never-treated cohort

* Window around event time and event post indicator 
foreach var in Ei EHL ELL EHH ELH {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

* drop always treated individuals  (there are none)
bys IDlse: egen vv = var(EiPost) // if there is a cohort that is always treated, then we need to exclude this cohort from estimation.
drop if vv ==0 & EiPost==1 

gen YEi = year(dofm(Ei))

* Prepare interaction terms for the interacted regression
* set the window -10 - 10 for productivity 
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

*generate cohort - event dummies interactions 
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

* 2) COHORT SHARES, would be 110 maybe divide into quarters? or 6 months?  or 10 years?

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

* 3) FINAL COEFF: WEIGHTED AVERAGES 

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
graph save  "$analysis/Results/7.Robustness/ProdELH1.gph", replace
graph export "$analysis/Results/7.Robustness/ProdELH1.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ProdEHL1.gph", replace
graph export "$analysis/Results/7.Robustness/ProdEHL1.png", replace

////////////////////////////////////////////////////////////////////////////////
* ONLY CONSIDER AFTER 2017 
eststo: reghdfe ProductivityStd $eventinteract $cont if Year>2017 , a( $abs   ) vce(cluster IDlseMHR)
local c = 21 // !PLUG! specify window 
coeffCohort1, c(`c') 

* final plots 
 tw connected bL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 etL1 if etL1>-21 & etL1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ProdELH12019.gph", replace
graph export "$analysis/Results/7.Robustness/ProdELH12019.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ProdEHL12019.gph", replace
graph export "$analysis/Results/7.Robustness/ProdEHL12019.png", replace


////////////////////////////////////////////////////////////////////////////////
* DUMMY FOR BALANCED SAMPLE IN CALENDAR TIME
gen i = (Year==2018 | Year==2019)
bys IDlse: egen nmonth= count(cond(i==1, IDlse, .)) 
gen BalancedSample = (nmonth ==24 & i==1) 

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
graph save  "$analysis/Results/7.Robustness/ProdELH1B.gph", replace
graph export "$analysis/Results/7.Robustness/ProdELH1B.png", replace

 tw connected bH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 etH1 if etH1>-21 & etH1<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-10(2)10) ///
xtitle(Months since manager change) title("Productivity", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ProdEHL1B.gph", replace
graph export "$analysis/Results/7.Robustness/ProdEHL1B.png", replace


