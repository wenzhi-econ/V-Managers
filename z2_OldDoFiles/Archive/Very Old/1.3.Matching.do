
use "$Culturedta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth 

*keep if Year>2015 // to run faster 

********************************************************************************
* GEN VARS 
********************************************************************************

*bys IDlse StandardJob (YearMonth), sort: 

********************************************************************************
* EVENT STUDY DUMMIES 
********************************************************************************

bys IDlse IDlseMHR: egen maxIAM = max(IAM)
gen OutGroupIASame = . 
replace OutGroupIASame  =1 if OutGroup ==1 & maxIAM==1 & DiffCountry==0
replace OutGroupIASame  =0 if (OutGroup ==0 | maxIAM==0 | DiffCountry==1)
label var OutGroupIASame  "=1 if outgroup manager on IA, same location"

gsort IDlse YearMonth 
gen ChangeM = 0 
replace ChangeM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1]   )
replace ChangeM = . if IDlseMHR ==. 
replace ChangeM = 0 if OutGroupIASame==1 

gsort IDlse YearMonth 
gen OutGroupIASameM = 0 
replace OutGroupIASameM   = 1 if (IDlse[_n] == IDlse[_n-1] & OutGroupIASame[_n] ==1 & OutGroupIASame[_n-1] ==0  )
replace OutGroupIASameM  = . if IDlseMHR ==. 

* Cultural distance 
gen OutGroupIASameMHighD = OutGroupIASameM
su CulturalDistance if CulturalDistance!=0,d 
replace OutGroupIASameMHighD = 0 if CulturalDistance <= r(p50)

gen OutGroupIASameMLowD = OutGroupIASameM
su CulturalDistance if CulturalDistance!=0, d 
replace OutGroupIASameMLowD = 0 if CulturalDistance > r(p50) &  CulturalDistance!=.

* PW
gen OutGroupIASameMPW = OutGroupIASameM
replace OutGroupIASameMPW = 0 if BothPW==0

gen OutGroupIASameMNoPW = OutGroupIASameM
replace OutGroupIASameMNoPW = 0 if BothPW==1

********************************************************************************
* event study model - quarter changes
********************************************************************************

* just get the dummies 
esplot LogPayBonus,  event(OutGroupIASameM , save) compare(ChangeM, save) window(-24 36) // just to create the dummies  

* Leaver PromWLC  TransferInternalC VPA
esplot LogPayBonus,  event(OutGroupIASameM , save) compare(ChangeM, save) window(-24 36) period_length(3) vce(cluster IDlseMHR) absorb(IDlse IDlseMHR CountryYM Func WL WLM  DiffCountry ) estimate_reference savedata( "$analysis/Results/2.Analysis/Pay" , replace) xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/Pay.gph", replace

********************************************************************************
* Matched sample  - Coarsened exact matching
********************************************************************************

bys IDlse: egen Sample = max(OutGroupIASameM)
bys IDlse (YearMonth), sort: gen OutGroupIASameMRound = sum(OutGroupIASameM)
bys IDlse (YearMonth), sort: gen ChangeMRound = sum(ChangeM)

forval i=1(1)6{
	gen OutGroupE`i' = 0
    replace  OutGroupE`i' = OutGroupIASameM if   OutGroupIASameMRound == `i'
}

forval i=1(1)24{
	gen ChangeME`i' = 0
    replace  ChangeME`i' = YearMonth if ChangeM ==1   & ChangeMRound == `i'
	bys IDlse: egen m`i'= max(ChangeME`i')
	bys IDlse: replace ChangeME`i' = YearMonth -  m`i'
}

*bys IDlse ChangeMRound 
 
global matchChar AgeBand WL Female Tenure Func Country 

foreach var in $matchChar{
	forval i=1(1)24{
	egen `var'M`i'= mean(cond( ChangeME`i' <=-2 & ChangeME`i' >=-24 | (OutGroupIASameME`i' <=-2 & OutGroupIASameME`i' >=-24) , `var', .)) 
	}
}

egen TenureBand = cut(Tenure), group(10) // 10 bins 
global matchChar AgeBand WL Female TenureBand Func Country 

replace OutGroupIASameMRound = 1 if OutGroupIASameMRound >=1
set seed 1234
   flexpaneldid_preprocessing , id(IDlse) treatment(OutGroupIASameMRound) time(YearMonth)  matchvars(AgeBand WL Female  Func Country TenureBand) matchvarsexact(AgeBand WL Female  Func Country TenureBand ) matchtimerel(-12)  
save "$Culturedta/matching.dta", replace 

use "$Culturedta/matching.dta" , clear 
egen t = tag(IDlse)
keep if t==1
keep IDlse treated 
save "$Culturedta/matchingList.dta", replace 


/* 
ssc install cem
cem age (10 20 30 40 60) age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75 interaction1, treatment(Sample) 
reg re78 treat [iweight=cem_weights], robust
imbalance age education black nodegree re74, treatment(treated)
*/

