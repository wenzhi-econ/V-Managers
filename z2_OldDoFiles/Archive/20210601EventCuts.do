********************************************************************************
* Event study Analysis
********************************************************************************

* CHANGING MANAGER FIRST TIME ONLY - so can look at split by pre-event chars 
bys IDlse: egen FirstYMChangeM = min(cond(ChangeM==1, YearMonth , .))
gen FirstChangeM = ChangeM
replace FirstChangeM =0 if YearMonth> FirstYMChangeM
format FirstYMChangeM %tm

* pre-determined characteristics 
bys IDlse: egen PreVPA = mean(cond(YearMonth< FirstYMChangeM , VPA, .))
bys IDlse: egen PreExtraMile = mean(cond(YearMonth< FirstYMChangeM , ExtraMile, .))
bys IDlse: egen PrePayBonusG = mean(cond(YearMonth< FirstYMChangeM , PayBonusG, .))

su PreExtraMile, d
gen PreExtraMileB = PreExtraMile >r(p50) & PreExtraMile!=.
replace PreExtraMileB = . if PreExtraMile ==.

su PrePayBonusG, d
gen PrePayBonusGB = PrePayBonusG >r(p50) & PrePayBonusG!=.
replace PrePayBonusGB = . if PrePayBonusG ==.

su PreVPA, d
gen PreVPAB = PreVPA >r(p50) & PreVPA!=.
replace PreVPAB = . if PreVPA ==.

* Effective LM 
gen ChangeLMLowHigh = 0 
replace ChangeLMLowHigh = 1 if (IDlse[_n] == IDlse[_n-1] & LineManagerMeanB[_n]==1 & LineManagerMeanB[_n-1]==0    )
replace ChangeLMLowHigh = . if IDlseMHR ==. 
replace ChangeLMLowHigh = 0 if ChangeM ==0

gen ChangeLMLowHighF = ChangeLMLowHigh // first manager change only
replace ChangeLMLowHighF = 0 if FirstChangeM ==0 

gen ChangeLMHighHigh = 0 
replace ChangeLMHighHigh = 1 if (IDlse[_n] == IDlse[_n-1] & LineManagerMeanB[_n]==1 & LineManagerMeanB[_n-1]==1    )
replace ChangeLMHighHigh = . if IDlseMHR ==. 
replace ChangeLMHighHigh = 0 if ChangeM ==0

gen ChangeLMHighHighF = ChangeLMHighHigh
replace ChangeLMHighHighF = 0 if FirstChangeM ==0 

gen ChangeLMHighLow = 0 
replace ChangeLMHighLow = 1 if (IDlse[_n] == IDlse[_n-1] & LineManagerMeanB[_n]==0 & LineManagerMeanB[_n-1]==1   )
replace ChangeLMHighLow = . if IDlseMHR ==. 
replace ChangeLMHighLow = 0 if ChangeM ==0

gen ChangeLMHighLowF = ChangeLMHighLow
replace ChangeLMHighLowF = 0 if FirstChangeM ==0 

gen ChangeLMLowLow = 0 
replace ChangeLMLowLow = 1 if (IDlse[_n] == IDlse[_n-1] & LineManagerMeanB[_n]==0 & LineManagerMeanB[_n-1]==0   )
replace ChangeLMLowLow = . if IDlseMHR ==. 
replace ChangeLMLowLow = 0 if ChangeM ==0

gen ChangeLMLowLowF = ChangeLMLowLow
replace ChangeLMLowLowF = 0 if FirstChangeM ==0 

* Gender 
gen ChangeMF = 0 
replace ChangeMF = 1 if (IDlse[_n] == IDlse[_n-1] & FemaleM[_n] == 1 & FemaleM[_n-1] ==0 )
replace ChangeMF = . if IDlseMHR ==. 
replace ChangeMF = 0 if ChangeM ==0

gen ChangeFM = 0 
replace ChangeFM = 1 if (IDlse[_n] == IDlse[_n-1] & FemaleM[_n] == 0 & FemaleM[_n-1] ==1 )
replace ChangeFM = . if IDlseMHR ==. 
replace ChangeFM = 0 if ChangeM ==0

* PW 
gen ChangePW = 0 
replace ChangePW = 1 if (IDlse[_n] == IDlse[_n-1] & DidPWPostM[_n] == 1 & DidPWPostM[_n-1] ==0 )
replace ChangePW = . if IDlseMHR ==. 
replace ChangePW = 0 if ChangeM ==0

* OUTGROUP 
gen ChangeC = 0 
replace ChangeC = 1 if (IDlse[_n] == IDlse[_n-1] & OutGroup[_n] == 1 & OutGroup[_n-1] ==0 )
replace ChangeC = . if IDlseMHR ==. 
replace ChangeC = 0 if ChangeM ==0


* also to run overnight on full sample 

* Line Manager 
esplot LogPayBonus if  LineManagerMeanB!=.,  event(ChangeLMLowHigh , replace ) compare(ChangeM, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayLMHigh.gph", replace

esplot LogPayBonus if  LineManagerMeanB!=.,  event(ChangeLMHighLow , replace ) compare(ChangeM, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayLMLow.gph", replace


* first stage: duration of event of changing to effective LM
* low to high 
esplot LineManagerMeanB if  LineManagerMeanB!=. & insample==1,  event(ChangeLMLowHigh , replace ) compare(ChangeLMLowLow, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/DurationLMLowHigh.gph", replace
* high to low 
esplot LineManagerMeanB if  LineManagerMeanB!=.,  event(ChangeLMHighLow , replace ) compare(ChangeLMHighHigh, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/DurationLMLowLow.gph", replace

* other variables 
esplot Leaver if  LineManagerMeanB!=.,  event(ChangeLMLowHigh , replace ) compare(ChangeLMLow, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/ExitLMHighLow.gph", replace

esplot TransferInternalC if  LineManagerMeanB!=.,  event(ChangeLMLowHigh , replace ) compare(ChangeLMLowLow, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse) estimate_reference
graph save  "$analysis/Results/4.MType/TransferCLMLowHigh.gph", replace

* First manager 
esplot LogPayBonus if  LineManagerMeanB!=., event(ChangeLMLowHighF , replace ) compare(ChangeLMLowLowF, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayLMLowHighF.gph", replace

esplot TransferInternalC if  LineManagerMeanB!=. ,  event(ChangeLMLowHighF , replace ) compare(ChangeLMLowLowF, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayLMLowHighF.gph", replace

esplot LeaverPerm if  LineManagerMeanB!=. ,  event(ChangeLMLowHighF , replace ) compare(ChangeLMLowLowF, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM   ) estimate_reference
graph save  "$analysis/Results/4.MType/LeaverLMLowHighF.gph", replace

* Heterogeneity - first manager 
esplot TransferInternalC if  LineManagerMeanB!=. & PreExtraMileB!=., by(PreExtraMileB) event(ChangeLMLowHighF , replace ) compare(ChangeLMLowLowF, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/TransferLMLowHighFMile.gph", replace

esplot LogPayBonus if  LineManagerMeanB!=. & PreExtraMileB!=., by(PreExtraMileB) event(ChangeLMLowHighF , replace ) compare(ChangeLMLowLowF, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayLMLowHighFMile.gph", replace

esplot LogPayBonus if  LineManagerMeanB!=. , by(PreVPAB) event(ChangeLMLowHighF , replace ) compare(ChangeLMLowLowF, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayLMLowHighFVPA.gph", replace

esplot LeaverPerm if  LineManagerMeanB!=. & PreExtraMileB!=., by(PreExtraMileB) event(ChangeLMLowHighF , replace ) compare(ChangeLMLowLowF, replace) window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM   ) estimate_reference
graph save  "$analysis/Results/4.MType/LeaverPermLMLowHighFMile.gph", replace

* GENDER 
esplot LogPayBonus if insample==1,  by(Female) event(ChangeFM , replace ) compare(ChangeM, replace) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse WLM  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayChangefm.gph", replace

esplot LogPayBonus if insample==1,  by(Female) event(ChangeMF , replace ) compare(ChangeM, replace) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse WLM  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayChangeMF.gph", replace

* purpose workshop 
esplot LogPayBonus ,   event(ChangePW , replace ) compare(ChangeM, replace) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse WLM  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayChangePW.gph", replace

* outgroup
esplot LogPayBonus ,   event(ChangeC , replace ) compare(ChangeM, replace) window(-24 36)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse WLM  ) estimate_reference
graph save  "$analysis/Results/4.MType/PayChangeC.gph", replace

