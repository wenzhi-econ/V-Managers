********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

use "$Managersdta/AllSnapshotMCultureMType.dta", clear 

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

////////////////////////////////////////////////////////////////////////////////
* EDUCATION 
////////////////////////////////////////////////////////////////////////////////

merge m:1 FuncS SubFuncS StandardJobCode using "$fulldta/EducationMainField.dta"
drop if _merge ==2 
drop _merge 

merge 1:1 IDlse YearMonth using "$fulldta/Education.dta", keepusing(QualHigh   FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge

bys IDlse: egen minMonth = min(cond(FieldHigh1!=.,YearMonth,.))
foreach var in FieldHigh1 FieldHigh2 FieldHigh3{
	bys IDlse: egen `var'min = mean(cond(YearMonth==minMonth,`var',.))
	replace `var'= `var'min if `var'==.
}
 
gen DiffField = (FieldHigh1 != MajorField & FieldHigh2!= MajorField &  FieldHigh3!= MajorField) if (MajorField!=. & FieldHigh1!=. )

keep if DiffField!=.

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

* 1) EVENT STUDY DUMMIES 

* never-treated  
replace Ei = . if ELL==. & ELH==. & EHL==. & EHH==. 
gen lastcohort = Ei==. // never-treated cohort

* Window around event time and event post indicator 
*  Ei EH EL
foreach var in Ei EHL ELL EHH ELH {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

}

* drop always treated individuals  (there are none)
bys IDlse: egen vv = var(EiPost) // if there is a cohort that is always treated, then we need to exclude this cohort from estimation.
drop if vv ==0 & EiPost==1 

gen YEi = year(dofm(Ei))

* DUMMY FOR BALANCED SAMPLE IN CALENDAR TIME
gen i = Year>2015 
bys IDlse: egen nmonth= count(cond(i==1, IDlse, .)) 
gen BalancedSample = (nmonth ==51 & i==1) 

* 2) COHORT INTERACTION TERMS 

*qui levelsof YEi, local(cohort) 
*foreach yy of local cohort {
		forval yy = 2011(1)2020 {
			gen cohort`yy' = (YEi == `yy') 
	foreach l in ELL ELH EHL EHH {
			qui gen `l'_`yy'  = cohort`yy'* `l'Post 
			local eventinteract "`eventinteract' `l'_`yy'"
	}
	}

global eventinteract `eventinteract'
des $eventinteract 

* 3) COHORT SHARES, would be 110 maybe divide into quarters? or 6 months?  or 10 years?

foreach var in ELH ELL EHL EHH {
	forval yy = 2011/2020{
		matrix shares`var'`yy' = J(1,1,.)
	}
	}

cap drop shares* 
foreach var in ELH ELL EHL EHH {
	forval yy = 2011(1)2020 {
			
summarize cohort`yy' if `var'Post == 1 

mat b_`l' = r(mean)
matrix shares`var'`yy'[1,1] =b_`l'
	
svmat shares`var'`yy'
}
}

* 4) FINAL COEFF: WEIGHTED AVERAGES 

////////////////////////////////////////////////////////////////////////////////
* Different field indicator  
////////////////////////////////////////////////////////////////////////////////

des $eventinteract 
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR Func Female

////////////////////////////////////////////////////////////////////////////////

eststo  clear
local i = 1 
foreach var in  DiffField {

 local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)
eststo regF`i': reghdfe DiffField $eventinteract $cont , a( $abs   ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
coeffStaticCohort
su bL1
estadd scalar bL1 = r(mean)
su seL1
estadd scalar seL1 = r(mean)
su bH1
estadd scalar bH1 = r(mean)
su seH1
estadd scalar seH1 = r(mean)

local i = `i' + 1
} 

/* to be edited 
esttab using "$analysis/Results/4.Event/EducStatic.tex", label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2, labels("Controls" "Employee FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")    drop(_cons TeamSize Tenure c.Tenure#c.Tenure ) ///
 nomtitles mgroups("Pay + bonus (logs)" "Transfer: office/sub-division" "Transfer (lateral)" "Transfer (vertical)" "Prom. (salary)" "Prom. (work-level)"  "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, function FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace

