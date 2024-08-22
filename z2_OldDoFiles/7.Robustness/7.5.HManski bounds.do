////////////////////////////////////////////////////////////////////////////////
* Horowitz-Manski bounds 
////////////////////////////////////////////////////////////////////////////////

do "$analysis/DoFiles/7.Robustness/7.3.EventImportSun.do" // only consider first event as with new did estimators 

xtset IDlse YearMonth
keep if insample==1
tsfill , full // balanced panel

bys IDlse: egen mm = min(cond(Female!=., YearMonth,.))
format mm %tm
keep if YearMonth>= mm 

bys IDlse: egen maxx = max(cond(Female!=., YearMonth,.))
format maxx %tm

* impute values for control variables 
global control PromWLC Tenure AgeBand Country AgeBandM EarlyAge2015M
foreach var in  $control {
	bys IDlse: egen a = mean(cond(YearMonth==maxx, `var',.))
	gen `var'MB = `var'
	replace `var'MB = a if `var'MB==.
	drop a
}

foreach var in ELH ELL EHH EHL{
	bys IDlse: egen a = min(`var')
replace `var' = a 
drop a 
}

////////////////////////////////////////////////////////////////////////////////
* static 
////////////////////////////////////////////////////////////////////////////////

* UB - good people exit 
gen PromWLCUB = PromWLC
sum PromWLC
replace PromWLCUB = PromWLCMB+ 1  if PromWLCUB == . & EarlyAge2015MMB==1
replace  PromWLCUB= PromWLCMB+0 if  PromWLCUB == . &  EarlyAge2015MMB==0

* LB - bad people exit 
gen PromWLCLB = PromWLC
sum PromWLC
replace PromWLCLB = PromWLCMB+0  if PromWLCLB == . &  EarlyAge2015MMB==1
replace  PromWLCLB= PromWLCMB+1 if  PromWLCLB == . & EarlyAge2015MMB==0

////////////////////////////////////////////////////////////////////////////////
* dynamic
////////////////////////////////////////////////////////////////////////////////

* UB - good people exit 
gen PromWLCUB = PromWLC
sum PromWLC
replace PromWLCUB = PromWLCMB+1  if PromWLCUB == . & ((YearMonth>= ELH  & ELH!=.) |  (YearMonth>= EHH  & EHH!=.))
replace  PromWLCUB= PromWLCMB+0 if  PromWLCUB == . & (ELH==. & EHH==.)

* LB - bad people exit 
gen PromWLCLB = PromWLC
sum PromWLC
replace PromWLCLB = PromWLCMB+0  if PromWLCLB == . & ((YearMonth>= ELH  & ELH!=.) |  (YearMonth>= EHH  & EHH!=.))
replace  PromWLCLB= PromWLCMB+1 if  PromWLCLB == . & (ELH==. & EHH==.)

* regressions 
eststo: reghdfe PromWLC  EarlyAge2015M c.TenureMB##c.TenureMB  , a( IDlse AgeBandMB CountryMB AgeBandMMB YearMonth) cluster(IDlse) // actual 0.017
eststo: reghdfe PromWLCUB  EarlyAge2015MMB c.TenureMB##c.TenureMB  , a( IDlse AgeBandMB CountryMB AgeBandMMB YearMonth) cluster(IDlse) // UB .0216009  
eststo: reghdfe PromWLCLB  EarlyAge2015MMB c.TenureMB##c.TenureMB  , a( IDlse AgeBandMB CountryMB AgeBandMMB YearMonth) cluster(IDlse) // LB .0081903 
* mean is  .0840977
