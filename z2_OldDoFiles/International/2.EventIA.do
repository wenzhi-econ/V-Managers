use  "$managersdta/AllSnapshotMCulture.dta", clear 

* random sample to make estimation faster 
egen t = tag(IDlse)
generate random = runiform() if t ==1 
bys IDlse: egen r = min(random)
sort r 
generate insample = _n <= 1000000
generate insample2 = _n <= 200000

* sample of employees with at least one IA manager 
bys IDlse : egen Sample = max(OutGroupIASameM )

* matched sample 
*merge m:1 IDlse using "$managersdta/matchingList.dta" 
*keep if _merge ==3
*drop _merge 

* how many WL4+ have done IA
ta WL 
bys IDlse: egen xx = max(IA)
count if WL>3
count if WL>3 & xx==1

********************************************************************************
* propensity score
********************************************************************************

gen Tenuresq = Tenure*Tenure
logit OutGroupIASameM i.AgeBand i.Func Tenure Tenuresq Female i.EmpType  i.Country  i.WL if insample==1
predict pscore
su pscore if OutGroupIASameM==1, detail
su pscore if OutGroupIASameM==0, detail
histogram pscore, by(OutGroupIASameM) binrescale

bys IDlse: egen pscoremean = mean(pscore)

gen pscoremean2 = pscoremean 
replace pscoremean2 = . if pscoremean <= 0.0001 

gen double ipw =cond(Sample==1,1/pscoremean2,1/(1-pscoremean2))

* overall effect 
drop F*_*  L*_* 
esplot LogPayBonus if insample ==1 [pw=ipw],  event(OutGroupIASameM , save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry IDlse  ) estimate_reference
graph save  "$analysis/Results/2.Analysis/PSCORE/PayFE.gph", replace


esplot TransferInternalC if insample ==1 [pw=ipw],  event(OutGroupIASameM , nogen ) compare(ChangeM, nogen) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry IDlse  ) estimate_reference
graph save  "$analysis/Results/2.Analysis/PSCORE/TransferInternalCFE.gph", replace

drop F*_*  L*_* 
esplot Leaver if insample ==1 [pw=ipw],  event(OutGroupIASameM , save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry   ) estimate_reference
graph save  "$analysis/Results/2.Analysis/PSCORE/Leaver.gph", replace

drop F*_*  L*_* 
gen STA = 1 if MasterType  == 1 | MasterType  == 4
replace STA = 0 if  STA ==.& MasterType!=.
esplot STA if insample ==1 [pw=ipw],  event(OutGroupIASameM , save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry   ) estimate_reference
graph save  "$analysis/Results/2.Analysis/PSCORE/STA.gph", replace

* cultural distance on IA managers sample 
cd "$analysis/Results/2.Analysis/PSCORE"
drop F*_*  L*_* 
esplot LogPayBonus if insample ==1 [pw=ipw] , by(CultureDEvent)  event(OutGroupIASameM, save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry IDlse  ) savedata( "PayCultureFE.dta" , replace) estimate_reference
graph save  "$analysis/Results/2.Analysis/PSCORE/PayCultureFE.gph", replace


* cultural distance on IA managers sample 
cd "$analysis/Results/2.Analysis/PSCORE"
drop F*_*  L*_* 
esplot LogPayBonus if insample ==1 [pw=ipw] ,   event(OutGroupIASameMHighD, save ) compare(OutGroupIASameMLowD, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry IDlse  ) savedata( "PayCultureFE2.dta" , replace) estimate_reference
graph save  "$analysis/Results/2.Analysis/PSCORE/PayCultureFE2.gph", replace

* TO BE RUN 
* high distance 
cd "$analysis/Results/2.Analysis/PSCORE"
drop F*_*  L*_* 
esplot LogPayBonus if insample ==1 [pw=ipw] ,   event(OutGroupIASameMHighD, save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry IDlse  ) savedata( "PayHighCultureFE.dta" , replace) estimate_reference
graph save  "$analysis/Results/2.Analysis/PSCORE/PayHighCultureFE.gph", replace

* low distance 
cd "$analysis/Results/2.Analysis/PSCORE"
drop F*_*  L*_* 
esplot LogPayBonus if insample ==1 [pw=ipw] ,   event(OutGroupIASameMLowD, save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry IDlse  ) savedata( "PayLowCultureFE.dta" , replace) estimate_reference
graph save  "$analysis/Results/2.Analysis/PSCORE/PayLowCultureFE.gph", replace

* graph the 2 distance measures together 

use "PayLowCultureFE.dta", clear 
drop if t==.
append using "PayHighCultureFE.dta"
drop if t==.
gen highd = 1 if _n>=22
replace highd = 0 if highd==.
set scheme aurora
tw connected b_01 t if highd ==0,  lcolor(ebblue) mcolor(ebblue) || connected b_01 t if highd ==1, lcolor(cranberry) mcolor(cranberry) || rcap lo_0 hi_0 t if highd==1, lcolor(cranberry)  || rcap lo_0 hi_0 t if highd==0 , lcolor(ebblue)  legend(order(1 "Low Distance" 2 "High Distance" )) xlabel(-8(2)12) title("Pay + bonus (logs)")
graph save  "$analysis/Results/2.Analysis/PSCORE/PayLowHighCultureFE.gph", replace


********************************************************************************
* Lee Bounds 
********************************************************************************
* assumes Monotonicity which means that the treatment status affects selection in just one direction
* Either from below or from above, the group (treatment, control) that suffers less from sample attrition is trimmed at the quantile of the outcome variable that corresponds to the share of excess observations in this group.
* treatment group is trimmed as there is more exit there 
* lower bound above zero
leebounds LogPayBonus OutGroupIASameM if insample ==1 [pw=ipw] , select(Leaver)  cieffect

heckman  LogPayBonus OutGroupIASameM , select(Leaver = OutGroupIASameM )

********************************************************************************
* psmatch
********************************************************************************

set seed 777 
gen sortid = uniform()
sort sortid
psmatch2  OutGroupIASameM i.AgeBand i.Func Tenure Tenuresq Female i.EmpType  i.Country  i.WL 
pstest i.AgeBand i.Func Tenure Tenuresq Female i.EmpType  i.Country  i.WL  , both graph 

drop F*_*  L*_* 
esplot LogPayBonus if insample ==1 & _weight!=. [iw=_weight],  event(OutGroupIASameM , save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry IDlse  )   estimate_reference

********************************************************************************
* event study model - quarter changes
********************************************************************************

drop F*_*  L*_* 
esplot LogPayBonus if insample ==1 ,  event(OutGroupIASameM , save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry IDlse IDlseMHR ) estimate_reference

drop F*_*  L*_* 
esplot LogPayBonus if insample ==1 & (Func ==3 | Func == 4 | Func ==10 | Func == 14),  event(OutGroupIASameM , save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM  DiffCountry IDlse  ) estimate_reference

********************************************************************************
* by cluster 
********************************************************************************

cd "$analysis/Results/2.Analysis"
*keep if CountryS =="India"
forval i = 17(1)18{
	drop F*_*  L*_* 
	esplot LogPayBonus if Cluster ==`i' ,  event(OutGroupIASameM , save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry IDlse ) estimate_reference
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/PayFE`i'.gph", replace
 
}

* Leaver PromWLC  TransferInternalC VPA
esplot LogPayBonus ,  event(OutGroupIASameM , save ) compare(ChangeM, save) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry IDlse ) estimate_reference savedata( "Pay.dta" , replace) 
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/PayFE.gph", replace

esplot LogPayBonus ,  event(OutGroupIASameM , nogen )  window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry  ) estimate_reference savedata( "PayNoCompareAll.dta" , replace) 
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/PayNoFENoCompareAll.gph", replace

esplot PromWLC ,  event(OutGroupIASameM , nogen )  window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry IDlse ) estimate_reference  
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/PromWLCFENoCompare.gph", replace

esplot  TransferInternalC ,  event(OutGroupIASameM , nogen )  window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry IDlse ) estimate_reference  
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/TransferInternalCFENoCompare.gph", replace

esplot PromWLC,  event(OutGroupIASameM , nogen ) compare(ChangeM, nogen) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry IDlse ) estimate_reference savedata( "Prom.dta" , replace) 
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/PromWLC.gph", replace

esplot TransferInternalC,  event(OutGroupIASameM , nogen ) compare(ChangeM, nogen) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry IDlse ) estimate_reference savedata( "TransferInternalC.dta" , replace) 
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/TransferInternalC.gph", replace


esplot LogPayBonus if WL>1 ,  event(OutGroupIASameM , nogen ) compare(ChangeM, nogen) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM Func WL WLM  DiffCountry IDlse ) estimate_reference savedata( "Pay.dta" , replace) 
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/PayFEWL2.gph", replace


esplot LogPayBonus,  event(OutGroupIASameM , nogen) compare(ChangeM, nogen) window(-24 36) period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM Func WL WLM  DiffCountry ) estimate_reference savedata( "$analysis/Results/2.Analysis/Pay" , replace) 
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/Pay.gph", replace

esplot LogPayBonus,  event(OutGroupIASameM , nogen) compare(ChangeM, nogen) window(-24 36) period_length(3) vce(cluster IDlseMHR) absorb(  CountryYM Func WL WLM  DiffCountry ) estimate_reference savedata( "$analysis/Results/2.Analysis/Pay" , replace) 
*xtitle("Event Time (Quarters)") title("Pay+bonus (logs)") xlabel(-8(2)12) yline(0) xline(-1,lpattern(-)) 
graph save  "$analysis/Results/2.Analysis/PaynoFE.gph", replace


********************************************************************************
* Placebo
********************************************************************************
gen Odd = mod(IDlseMHR,2)
