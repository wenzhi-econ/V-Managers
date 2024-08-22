********************************************************************************
* Another measure of manager type based on promotion rates 2011-2013
********************************************************************************

use "$Managersdta/AllSnapshotMCulture.dta", clear
xtset IDlse YearMonth
drop if IDlseMHR==. 

xtset IDlse YearMonth
foreach v in ChangeSalaryGrade PromWL{ // taking into account when promoted under different manager 
gen F1`v' = f.`v'
} 

keep if Year<2015 // first 3 (<2014) or 4 (<2015) years !MANUAL INPUT! 

* creates missing values for the last period a worker is present

 su  ChangeSalaryGrade PromWL  F1ChangeSalaryGrade F1PromWL
foreach v in F1ChangeSalaryGrade F1PromWL LeaverPerm LeaverInv LeaverVol {
	xtset IDlse YearMonth
	reghdfe  `v' c.Tenure##c.Tenure##i.Female, a( MFE`v' = IDlseMHR i.Func i.AgeBand ISOCode Year   )  // tenure, gender, func, agem country and year 
}

 *- Restriction #1
bys IDlseMHR : egen minYM= min(YearMonth)
bys IDlseMHR : egen maxYM= max(YearMonth)
format (minYM maxYM) %tm
gen MDuration =  maxYM - minYM 
su MDuration, d 

keep if MDuration >=24 // only managers that are in the sample as managers for at least 2 years (circa 25 percentile)

 *- Restriction #2
egen ttI = tag(IDlse IDlseMHR)
bys IDlseMHR: egen TotWorkers = sum(ttI)
su TotWorkers, d
su TotWorkers if ttI==1, d
 
keep if TotWorkers > 9 // (p25), minimum number of workers above 9 otw too noisy 

gen o =1

collapse  minYM maxYM MFEF1ChangeSalaryGrade MFEF1PromWL  MFELeaverPerm MFELeaverVol MFELeaverInv , by(IDlseMHR) // manager type based on yearly prom rate, averaged over 3 years

rename MFEF1ChangeSalaryGrade MTypePromSG
rename MFEF1PromWL MTypePromWL
rename MFELeaverPerm MTypeLeaver
rename MFELeaverVol MTypeLeaverVol
rename MFELeaverInv MTypeLeaverInv

su MTypePromSG, d
local pSG = r(p75)
su  MTypePromWL, d
local pWL = r(p75)
tw kdensity  MTypePromSG , bcolor(%80)||  kdensity MTypePromWL, bcolor(red%50) xline(`pSG', lcolor(blue))  xline(`pWL', lcolor(red)) legend(label(1 "Salary Prom.") label(2 "WL Prom."))

foreach var in MTypePromSG MTypePromWL MTypeLeaver  MTypeLeaverVol MTypeLeaverInv{
	su `var', d
	gen `var'75 = `var' >=r(p75) if `var'!=.
	gen `var'50 = `var' >r(p50) if `var'!=.

} 

pwcorr MTypePromSG MTypePromWL MTypeLeaver MTypeLeaverVol MTypeLeaverInv // there is a negative correlation and this may be due because good managers improve retention 
pwcorr MTypePromSG75 MTypePromWL75 MTypeLeaver75 MTypeLeaverVol75 MTypeLeaverInv75 // there is a negative correlation and this may be due because good managers improve retention 

compress
save "$Managersdta/Temp/MTypePromExit2015.dta", replace // change year at the end depending on time period chosen 


use "$Managersdta/Temp/MTypePromExit2015.dta", clear 

merge 1:m IDlseMHR using "$Managersdta/Temp/MType.dta" 

keep if _merge ==3 


egen tt = tag(IDlseMHR)

pwcorr MTypePromWL75 MTypePromSG75 MTypePromWL50 MTypePromSG50  MaxWLM LineManagerMeanB if tt==1

reghdfe  MTypePromWL50 LineManagerMeanB if tt==1, a(CountryM FuncM)
reghdfe  MTypePromSG50 LineManagerMeanB if tt==1, a(CountryM FuncM)

/*
collapse minYM maxYM F1ChangeSalaryGradeR F1PromWLR LeaverPermR LeaverVolR LeaverInvR (sum) TeamSize = o , by(IDlseMHR YearMonth Year) // monthly prom rate 

collapse minYM maxYM   TeamSize (sum) F1ChangeSalaryGradeR F1PromWLR LeaverPermR LeaverVolR LeaverInvR , by(IDlseMHR  Year) // yearly prom rate 
count if minYM == tm(2011m1) & maxYM == tm(2013m12)

collapse  minYM maxYM F1ChangeSalaryGradeR F1PromWLR  LeaverPermR LeaverVolR LeaverInvR , by(IDlseMHR) // manager type based on yearly prom rate, averaged over 3 years

rename F1ChangeSalaryGradeR MTypePromSG
rename F1PromWLR MTypePromWL
rename LeaverPermR MTypeLeaver
rename LeaverVolR MTypeLeaverVol
rename LeaverInvR MTypeLeaverInv

su MTypePromSG, d
local pSG = r(p75)
su  MTypePromWL, d
local pWL = r(p75)
tw kdensity  MTypePromSG , bcolor(%80)||  kdensity MTypePromWL, bcolor(red%50) xline(`pSG', lcolor(blue))  xline(`pWL', lcolor(red)) legend(label(1 "Salary Prom.") label(2 "WL Prom."))

foreach var in MTypePromSG MTypePromWL MTypeLeaver  MTypeLeaverVol MTypeLeaverInv{
	su `var', d
	gen `var'75 = `var' >=r(p75) if `var'!=.
	gen `var'50 = `var' >r(p50) if `var'!=.

} 

pwcorr MTypePromSG MTypePromWL MTypeLeaver MTypeLeaverVol MTypeLeaverInv // there is a negative correlation and this may be due because good managers improve retention 
pwcorr MTypePromSG75 MTypePromWL75 MTypeLeaver75 MTypeLeaverVol75 MTypeLeaverInv75 // there is a negative correlation and this may be due because good managers improve retention 

compress
save "$Managersdta/Temp/MTypePromExit.dta", replace 


use "$Managersdta/Temp/MTypePromExit.dta", clear 

merge 1:m IDlseMHR using "$Managersdta/Temp/MType.dta" 

keep if _merge ==3 


egen tt = tag(IDlseMHR)

pwcorr MTypePromWL75 MaxWLM LineManagerMeanB if tt==1


