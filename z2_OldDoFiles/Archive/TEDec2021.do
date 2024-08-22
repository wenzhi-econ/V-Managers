use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
* Changing manager that transfers 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & (TransferInternalL1M==1 | TransferInternalL2M==1 | TransferInternalL3M==1 | TransferInternalF1M==1  | TransferInternalF2M==1  | TransferInternalF3M==1) 
replace  ChangeMR  = . if ChangeM==.
replace  ChangeMR  = . if IDlseMHR ==. 
 
* For Sun & Abraham only consider first event 
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1

egen CountryYear = group(Country Year)

********************************************************************************
* Event study dummies 
********************************************************************************

xtset IDlse YearMonth 
gen diffM = d.EarlyAgeM // d.EarlyAge2015M / can be replace with d.MFEBayes
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag)
*gen DeltaM = d.EarlyAgeM // option 2 
keep if DeltaM!=. 

foreach var in Ei {
gen K`var' = YearMonth - `var'

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

gen `var'PostDeltaM = `var'Post*DeltaM
replace `var'PostDeltaM  = 0 if  `var'PostDeltaM  ==.


}

* VPA/Pay G HETEROGENEITY 
xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus
egen tt = tag(IDlse)

foreach v in PayGrowth VPA{
	bys IDlse: egen `v'0 = mean(cond( YearMonth == Ei,`v', .))
	bys IDlse : egen `v'Mean = mean(`v')
	replace `v'0 = `v'Mean if Ei==. // replace with overall mean if worker never experiences a manager change
	su `v'0 if tt==1 , d 
	gen Above`v'0 = `v'0 > r(p50) if `v'0 !=.
}
drop tt

foreach var in EiPostDeltaM EiPost{
	gen `var'H = `var'*AbovePayGrowth0
	gen `var'L = `var'*(1-AbovePayGrowth0)
}

label var EiPostDeltaML "$\Delta$ M, Low" 
label var EiPostDeltaMH "$\Delta$ M, High"  
label var EiPostL "Event, Low"
label var  EiPostH "Event, High"

********************************************************************************
* Regressions  
********************************************************************************

global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYear AgeBand AgeBandM IDlse  
global exitFE CountryYear AgeBand AgeBandM  Func Female

global yperf LogPayBonus  PromWLVC ChangeSalaryGradeVC  VPA VPA125
global ytransfer TransferInternalLLC TransferInternalVC TransferInternalSameMC  TransferInternalDiffMC   TransferFuncC ONETDistanceCB TimeInternalC TimeFuncC  DiffField 
global yexit LeaverPerm LeaverVol  LeaverInv

foreach var in LogPayBonus ChangeSalaryGradeC PromWLC VPA  {
local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)

eststo: reghdfe `var' EiPostDeltaML EiPostDeltaMH EiPostL EiPostH  $cont , a( $abs ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
}

foreach var in LeaverPerm  {
local lbl : variable label `var'
mean `var' 
mat coef=e(b)
local cmean = coef[1,1]
count if `var' !=.& IDlseMHR!=. 
local N1 = r(N)

eststo: reghdfe `var' EiPostDeltaML EiPostDeltaMH EiPostL EiPostH  $cont , a( $exitFE ) vce(cluster IDlseMHR)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
}


esttab using "$analysis/Results/5.Mechanisms/FastTrack/PerfTWFEStaticHetPayG.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(Ei* ) se r2 ///
s(cmean N1 r2, labels("Mean" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups("Pay + bonus (logs)" "Prom. (salary)" "Prom. (work-level)"  "Perf. Appraisals" "Exit", pattern(1   1 1  1  1  1  1  1  1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Controls include: country x year FE, age group FE,  gender, team size, tenure and tenure squared.  ///
"\end{tablenotes}") replace
