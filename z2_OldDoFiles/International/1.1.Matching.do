
use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth 

*keep if Year>2015 // to run faster 

********************************************************************************
* Matched sample  - Coarsened exact matching
********************************************************************************

bys IDlse: egen Sample = max(OutGroupIASameM)
bys IDlse (YearMonth), sort: gen OutGroupIASameMRound = sum(OutGroupIASameM)

* only consider first manager 
gen OutGroupE1 = 0
replace  OutGroupE1 = OutGroupIASameM if   OutGroupIASameMRound == 1

forvalues i = 1(1)24 {
	gen F`i'_OutGroupE1 = F`i'.OutGroupE1 == 1
	local F_absorb " `F_absorb' F`i'_OutGroupE1"
}

egen PrePeriod = rowmax(`F_absorb')
 
global matchChar AgeBand WL Female Tenure Func Country Pay YearMonth 
sort IDlse YearMonth 
keep if Year>2015
keep if _n <=1000000
set seed 1234
cem AgeBand (#0) WL (#0) Female (#0) Func (#0) Country  (#0) YearMonth (#0) Pay (#100)  Tenure (#10) , treatment(PrePeriod)
save "$managersdta/matchingcem.dta", replace 

*   flexpaneldid_preprocessing , id(IDlse) treatment(OutGroupIASameMRound) time(YearMonth)  matchvars(AgeBand WL Female  Func Country TenureBand) matchvarsexact(AgeBand WL Female  Func Country TenureBand ) matchtimerel(-12)  

use "$managersdta/matching.dta" , clear 
egen t = tag(IDlse)
keep if t==1
keep IDlse treated 
save "$managersdta/matchingList.dta", replace 


/* 
ssc install cem
cem age (10 20 30 40 60) age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75 interaction1, treatment(Sample) 
reg re78 treat [iweight=cem_weights], robust
imbalance age education black nodegree re74, treatment(treated)
*/

