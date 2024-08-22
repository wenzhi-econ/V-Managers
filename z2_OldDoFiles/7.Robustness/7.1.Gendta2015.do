********************************************************************************
* IMPORT DATASET
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

********************************************************************************
* Define fast track manager based on data 2011-2015 only - first event based on half sample only
********************************************************************************

keep if Year<=2015

* tenure- WL type of manager
egen twl = tag(IDlse WLAgg)
bys IDlse WLAgg: egen AgeMinByWL2015 = min(AgeBand) // min tenure by WL 
label value AgeMinByWL2015 AgeBand 
bys IDlse: egen MaxWL2015 = max(WLAgg) // last observed WL 
bys IDlse: egen AgeMinMaxWL2015 = min( cond(WL == MaxWL2015, AgeBand, .) ) // starting WL 
bys IDlse: egen TenureMinMaxWL2015 = min( cond(WL == MaxWL2015, Tenure, .) ) // starting WL 
bys IDlse: egen oo = count(cond(WL==MaxWL2015, YearMonth, .) ) // number of months on max WL 
gen yy = oo/12 
drop twl oo

* EarlyAge based on minimum age only 
* all WL 1 are 0 as by def. I do not know if they become WL 2 
gen EarlyAge2015 = 0 
replace EarlyAge2015 = 1 if MaxWL2015 ==2 &  AgeMinMaxWL2015 ==1 & yy<8 // take away managers that stay in WL for a long time  
replace EarlyAge2015 = 1 if MaxWL2015 ==3 &  AgeMinMaxWL2015 <=2 & TenureMinMaxWL2015 <11
replace EarlyAge2015 = 1 if MaxWL2015 ==4 &  AgeMinMaxWL2015 <=2 & TenureMinMaxWL2015 <21
replace EarlyAge2015 = 1 if MaxWL2015 >4 &   AgeMinMaxWL2015 <=3 & TenureMinMaxWL2015 <31
label var EarlyAge2015 "Fast track  manager based on age when promoted (WL)"
drop yy 

preserve 
keep IDlse YearMonth EarlyAge2015

rename IDlse IDlseMHR
rename EarlyAge2015  EarlyAge2015M
collapse  EarlyAge2015M, by(IDlseMHR)
compress 
save "$managersdta/Temp/MListChar2015.dta", replace

restore 

////////////////////////////////////////////////////////////////////////////////
* SAVE HALF SAMPLE &  Generate SAME event dummies as full sample (first event in full sample) - ELH1 EHH1 ELL1 EHL1 DUMMIES
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth

merge m:1 IDlseMHR using "$temp/MListChar2015.dta"
drop if _merge ==2 
drop _merge


* Changing manager that transfers 
gen  ChangeMR1 = 0 
replace ChangeMR1 = 1 if ChangeM==1 & (TransferInternalL1M==1 | TransferInternalL2M==1 | TransferInternalL3M==1 | TransferInternalF1M==1  | TransferInternalF2M==1  | TransferInternalF3M==1) 
replace  ChangeMR1  = . if ChangeM==.
replace  ChangeMR1  = . if IDlseMHR ==. 
 
* For Sun & Abraham only consider first event 
bys IDlse: egen    Ei1 = min(cond(ChangeMR1==1, YearMonth ,.)) // for single differences 
replace ChangeMR1 = 0 if YearMonth > Ei1 & ChangeMR1==1

* Early age 
gsort IDlse YearMonth 
* low high
gen ChangeAgeMLowHigh1 = 0 
replace ChangeAgeMLowHigh1 = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAge2015M[_n]==1 & EarlyAge2015M[_n-1]==0    )
replace ChangeAgeMLowHigh1 = . if IDlseMHR ==. 
replace ChangeAgeMLowHigh1 = 0 if ChangeMR1 ==0
* high low
gsort IDlse YearMonth 
gen ChangeAgeMHighLow1 = 0 
replace ChangeAgeMHighLow1 = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAge2015M[_n]==0 & EarlyAge2015M[_n-1]==1    )
replace ChangeAgeMHighLow1 = . if IDlseMHR ==. 
replace ChangeAgeMHighLow1 = 0 if ChangeMR1 ==0
* high high 
gsort IDlse YearMonth 
gen ChangeAgeMHighHigh1 = 0 
replace ChangeAgeMHighHigh1 = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAge2015M[_n]==1 & EarlyAge2015M[_n-1]==1    )
replace ChangeAgeMHighHigh1 = . if IDlseMHR ==. 
replace ChangeAgeMHighHigh1 = 0 if ChangeMR1 ==0
* low low 
gsort IDlse YearMonth 
gen ChangeAgeMLowLow1 = 0 
replace ChangeAgeMLowLow1 = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAge2015M[_n]==0 & EarlyAge2015M[_n-1]==0   )
replace ChangeAgeMLowLow1 = . if IDlseMHR ==. 
replace ChangeAgeMLowLow1 = 0 if ChangeMR1 ==0

* for single differences 
egen ChangeAgeMLow1 = rowmax(ChangeAgeMLowHigh1 ChangeAgeMLowLow1) // for single differences 
egen ChangeAgeMHigh1 = rowmax(ChangeAgeMHighHigh1 ChangeAgeMHighLow1) // for single differences 

* only consider first event 
foreach v in High1 Low1 LowHigh1 LowLow1 HighHigh1 HighLow1{
bys IDlse: egen   ChangeAgeM`v'Month = min(cond(ChangeAgeM`v'==1, YearMonth ,.)) // for single	
replace ChangeAgeM`v'= 0 if YearMonth > ChangeAgeM`v'Month  & ChangeAgeM`v'==1
}

* Add categorical variables for imputation estimator 
*bys IDlse: egen m = max(YearMonth) // time of event
* Single differences 
gen EL1 = ChangeAgeMLow1Month
format EL1 %tm 
gen EH1 = ChangeAgeMHigh1Month
format EH1 %tm 
* Single coefficients 
gen ELH1 = ChangeAgeMLowHigh1Month 
*replace ELH = m + 1 if ELH==.
format ELH1 %tm 
gen EHH1 = ChangeAgeMHighHigh1Month 
*replace EHH = m + 1 if EHH==.
format EHH1 %tm 
gen ELL1 = ChangeAgeMLowLow1Month 
*replace ELL = m + 1 if ELL==.
format ELL1 %tm 
gen EHL1 = ChangeAgeMHighLow1Month 
*replace EHL = m + 1 if EHL==.
format EHL1 %tm 
 
keep if Year>2015 // only keep data after 2015 

compress
save "$managersdta/AllSnapshotMCultureMType2015.dta", replace

********************************************************************************
* ADD Event study dummies with first event based on half sample (so different from full sample dummies above)
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType2015.dta", clear 

xtset IDlse YearMonth 

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
replace ChangeAgeMLowHigh = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAge2015M[_n]==1 & EarlyAge2015M[_n-1]==0    )
replace ChangeAgeMLowHigh = . if IDlseMHR ==. 
replace ChangeAgeMLowHigh = 0 if ChangeMR ==0
* high low
gsort IDlse YearMonth 
gen ChangeAgeMHighLow = 0 
replace ChangeAgeMHighLow = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAge2015M[_n]==0 & EarlyAge2015M[_n-1]==1    )
replace ChangeAgeMHighLow = . if IDlseMHR ==. 
replace ChangeAgeMHighLow = 0 if ChangeMR ==0
* high high 
gsort IDlse YearMonth 
gen ChangeAgeMHighHigh = 0 
replace ChangeAgeMHighHigh = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAge2015M[_n]==1 & EarlyAge2015M[_n-1]==1    )
replace ChangeAgeMHighHigh = . if IDlseMHR ==. 
replace ChangeAgeMHighHigh = 0 if ChangeMR ==0
* low low 
gsort IDlse YearMonth 
gen ChangeAgeMLowLow = 0 
replace ChangeAgeMLowLow = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAge2015M[_n]==0 & EarlyAge2015M[_n-1]==0   )
replace ChangeAgeMLowLow = . if IDlseMHR ==. 
replace ChangeAgeMLowLow = 0 if ChangeMR ==0

* for single differences 
egen ChangeAgeMLow = rowmax(ChangeAgeMLowHigh ChangeAgeMLowLow) // for single differences 
egen ChangeAgeMHigh = rowmax(ChangeAgeMHighHigh ChangeAgeMHighLow) // for single differences 

* only consider first event 
foreach v in High Low LowHigh LowLow HighHigh HighLow{
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

* FE and control vars 
gen Tenure2 = Tenure*Tenure 
gen  Tenure2M = TenureM*TenureM

* other outcome variables of interest
xtset IDlse YearMonth 
gen PayBonusD= d.LogPayBonus 
gen PayBonusIncrease= PayBonusD>0 if PayBonusD!=.

merge 1:1 IDlse YearMonth using "$managersdta/Temp/Span.dta", keepusing(Span)
drop if _merge ==2 
drop _merge 
replace Span = 0 if Span==. // it means you are not a manager 

compress
save "$managersdta/AllSnapshotMCultureMType2015.dta", replace 



