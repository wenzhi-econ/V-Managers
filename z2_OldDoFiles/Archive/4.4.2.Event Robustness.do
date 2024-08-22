///////////////////////
* IMPORT DATASET 
///////////////////////

do "$analysis/DoFiles/0.1.EventImport.do"

********************************************************************************
* DID IMPUTATION  - Borusyak et al. (2021)
********************************************************************************

bys IDlse: egen   ChangeAgeMLowHighMonth = min(cond(ChangeAgeMLowHigh==1, YearMonth ,.))
bys IDlse: egen m = max(YearMonth) // time of event
 
gen Ei = ChangeAgeMLowHighMonth 
replace Ei = m + 1 if Ei==.
format Ei %tm 

*3 hours // to run overnight 
did_imputation LogPayBonus IDlse YearMonth  Ei, allhorizons pretrend(30) autosample cluster(IDlseMHR) fe(IDlseMHR CountryYM ) 
event_plot, default_look trimlag(30) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Pay+bonus (logs), Borusyak et al. (2021) imputation estimator") xlabel(-30(3)30) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/DIDPay.gph", replace
graph export  "$analysis/Results/4.MType/DIDPay.png", replace

did_imputation LeaverPerm IDlse YearMonth  Ei, allhorizons pretrend(60) autosample cluster(IDlseMHR) fe(IDlseMHR CountryYM ) controls(AgeBand Female Func)
event_plot, default_look trimlag(60) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Exit, Borusyak et al. (2021) imputation estimator") xlabel(-60(3)60) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/DIDExit.gph", replace
graph export  "$analysis/Results/4.MType/DIDExit.png", replace

did_imputation PromWLC IDlse YearMonth  Ei, allhorizons pretrend(60) autosample cluster(IDlseMHR) fe(IDlseMHR CountryYM ) controls(AgeBand Female Func)
event_plot, default_look trimlag(60) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Promotion (WL), Borusyak et al. (2021) imputation estimator") xlabel(-60(3)60) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/DIDPromWLC.gph", replace
graph export  "$analysis/Results/4.MType/DIDPromWLC.png", replace

did_imputation ChangeSalaryGradeC IDlse YearMonth  Ei, allhorizons pretrend(60) autosample cluster(IDlseMHR) fe(IDlseMHR CountryYM ) controls(AgeBand Female Func)
event_plot, default_look trimlag(60) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Promotion (salary), Borusyak et al. (2021) imputation estimator") xlabel(-60(3)60) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/DIDChangeSalaryGradeC.gph", replace
graph export  "$analysis/Results/4.MType/DIDChangeSalaryGradeC.png", replace

did_imputation TransferInternalC IDlse YearMonth  Ei, allhorizons pretrend(60) autosample cluster(IDlseMHR) fe(IDlseMHR CountryYM ) controls(AgeBand Female Func)
event_plot, default_look trimlag(60) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Transfer: office/sub-division, Borusyak et al. (2021) imputation estimator") xlabel(-60(3)60) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/DIDTransferInternalC.gph", replace
graph export  "$analysis/Results/4.MType/DIDTransferInternalC.png", replace

********************************************************************************
* First differences 
********************************************************************************

* first estimate all the lags and leads 
esplot LogPayBonus ,  event(ChangeAgeMHighLow , save ) compare(ChangeAgeMHighHigh , save) window(-30 30)  period_length(3) estimate_reference // estimate reference 
*estimates
esplot LogPayBonus ,  event(ChangeAgeMLowHigh , save ) compare(ChangeAgeMLowLow , save) window(-30 30)  period_length(3) estimate_reference 

********************************************************************************
* with manager FE 
********************************************************************************

* LogPayBonus
esplot LogPayBonus ,  event(ChangeAgeMLowHigh , nogen ) compare(ChangeAgeMLowLow , nogen) window(-30 30)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh CountryYM AgeBand IDlse  IDlseMHR) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-10(2)10) ///
xtitle(Quarters since manager change) ytitle("Pay + Bonus (logs)") title("Pay + Bonus (logs)", span pos(12))
graph save  "$analysis/Results/4.MType/PayAgeLowHighMFE.gph", replace
graph export  "$analysis/Results/4.MType/PayAgeLowHighMFE.png", replace

* symmetric?
esplot LogPayBonus ,  event(ChangeAgeMHighLow , nogen ) compare(ChangeAgeMHighHigh , nogen) window(-30 30)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMLowLow L*ChangeAgeMLowLow F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh CountryYM AgeBand IDlse IDlseMHR) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-10(2)10) ///
xtitle(Quarters since manager change) ytitle("Pay + Bonus (logs)") title("Pay + Bonus (logs)", span pos(12))
graph save  "$analysis/Results/4.MType/PayAgeHighLowMFE.gph", replace
graph export  "$analysis/Results/4.MType/PayAgeHighLowMFE.png", replace

*LeaverPerm
esplot LeaverPerm  ,  event(ChangeAgeMLowHigh , nogen ) compare(ChangeAgeMLowLow , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh CountryYM AgeBand Female Func IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Exit) title(Exit, span pos(12))
graph save  "$analysis/Results/4.MType/LeaverAgeLowHighMFE.gph", replace
graph export  "$analysis/Results/4.MType/LeaverAgeLowHighMFE.png", replace

* symmetric?
esplot LeaverPerm  ,  event(ChangeAgeMHighLow , nogen ) compare(ChangeAgeMHighHigh , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMLowLow L*ChangeAgeMLowLow F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh  CountryYM AgeBand Female Func IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Exit) title(Exit, span pos(12))
graph save  "$analysis/Results/4.MType/LeaverAgeHighLowMFE.gph", replace
graph export  "$analysis/Results/4.MType/LeaverAgeHighLowMFE.png", replace

*TransferInternalSJC
esplot TransferInternalSJC,  event(ChangeAgeMLowHigh , nogen ) compare(ChangeAgeMLowLow , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Transfer: job/office/sub-division) title(Transfer: job/office/sub-division, span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalSJCAgeLowHighMFE.gph", replace
graph export "$analysis/Results/4.MType/TransferInternalSJCAgeLowHighMFE.png", replace

* symmetric? 
esplot TransferInternalSJC,  event(ChangeAgeMHighLow , nogen ) compare(ChangeAgeMHighHigh , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMLowLow L*ChangeAgeMLowLow F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Transfer: office/sub-division) title(Transfer: office/sub-division, span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalSJCAgeHighLowMFE.gph", replace
graph export  "$analysis/Results/4.MType/TransferInternalSJCAgeHighLowMFE.png", replace

*TransferInternalSJSameMC
esplot TransferInternalSJSameMC,  event(ChangeAgeMLowHigh , nogen ) compare(ChangeAgeMLowLow , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Transfer: job/office/sub-division, same manager") title("Transfer: job/office/sub-division, same manager", span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalSJSameMCAgeLowHighMFE.gph", replace
graph export "$analysis/Results/4.MType/TransferInternalSJSameMCAgeLowHighMFE.png", replace

* symmetric? 
esplot TransferInternalSJSameMC,  event(ChangeAgeMHighLow , nogen ) compare(ChangeAgeMHighHigh , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMLowLow L*ChangeAgeMLowLow F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Transfer: job/office/sub-division, same manager") title("Transfer: job/office/sub-division, same manager", span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalSJSameMCAgeHighLowMFE.gph", replace
graph export  "$analysis/Results/4.MType/TransferInternalSJSameMCAgeHighLowMFE.png", replace

*TransferInternalSJDiffMC
esplot TransferInternalSJDiffMC,  event(ChangeAgeMLowHigh , nogen ) compare(ChangeAgeMLowLow , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Transfer: job/office/sub-division, diff. manager") title("Transfer: job/office/sub-division, diff. manager", span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalSJDiffMCAgeLowHighMFE.gph", replace
graph export "$analysis/Results/4.MType/TransferInternalSJDiffMCAgeLowHighMFE.png", replace

* symmetric? 
esplot TransferInternalSJDiffMC,  event(ChangeAgeMHighLow , nogen ) compare(ChangeAgeMHighHigh , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMLowLow L*ChangeAgeMLowLow F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Transfer: job/office/sub-division, diff. manager") title("Transfer: job/office/sub-division, diff. manager", span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalSJDiffMCAgeHighLowMFE.gph", replace
graph export  "$analysis/Results/4.MType/TransferInternalSJDiffMCAgeHighLowMFE.png", replace

*TransferInternalC
esplot TransferInternalC,  event(ChangeAgeMLowHigh , nogen ) compare(ChangeAgeMLowLow , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Transfer: office/sub-division) title(Transfer: office/sub-division, span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalCAgeLowHighMFE.gph", replace
graph export  "$analysis/Results/4.MType/TransferInternalCAgeLowHighMFE.png", replace

* symmetric? 
esplot TransferInternalC,  event(ChangeAgeMHighLow , nogen ) compare(ChangeAgeMHighHigh , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMLowLow L*ChangeAgeMLowLow F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Transfer: office/sub-division) title(Transfer: office/sub-division, span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalCAgeHighLowMFE.gph", replace
graph export  "$analysis/Results/4.MType/TransferInternalCAgeHighLowMFE.png", replace

*ChangeSalaryGradeC
esplot ChangeSalaryGradeC  ,  event(ChangeAgeMLowHigh , nogen ) compare(ChangeAgeMLowLow , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb(F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Promotion (salary)) title(Promotion (salary), span pos(12))
graph save  "$analysis/Results/4.MType/ChangeSalaryGradeCAgeLowHighMFE.gph", replace
graph export  "$analysis/Results/4.MType/ChangeSalaryGradeCAgeLowHighMFE.png", replace

* symmetric? 
esplot ChangeSalaryGradeC  ,  event(ChangeAgeMHighLow , nogen ) compare(ChangeAgeMHighHigh , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMLowLow L*ChangeAgeMLowLow F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Promotion (salary)) title(Promotion (salary), span pos(12))
graph save  "$analysis/Results/4.MType/ChangeSalaryGradeCAgeHighLowMFE.gph", replace
graph export  "$analysis/Results/4.MType/ChangeSalaryGradeCAgeHighLowMFE.png", replace

*PromWLC
esplot PromWLC  ,  event(ChangeAgeMLowHigh , nogen ) compare(ChangeAgeMLowLow , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Promotion (work level)) title(Promotion (work level), span pos(12))
graph save  "$analysis/Results/4.MType/PromWLCAgeLowHighMFE.gph", replace
graph export  "$analysis/Results/4.MType/PromWLCAgeLowHighMFE.png", replace

* symmetric? 
esplot PromWLC  ,  event(ChangeAgeMHighLow , nogen ) compare(ChangeAgeMHighHigh , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) control(c.Tenure##c.Tenure) absorb( F*ChangeAgeMLowLow L*ChangeAgeMLowLow F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh CountryYM AgeBand IDlse IDlseMHR ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle(Promotion (work level)) title(Promotion (work level), span pos(12))
graph save  "$analysis/Results/4.MType/PromWLCAgeHighLowMFE.gph", replace
graph export "$analysis/Results/4.MType/PromWLCAgeHighLowMFE.png", replace

********************************************************************************
* dual double differences 
********************************************************************************

gen  ChangeAgeMDiff = ChangeAgeMLowHigh
replace ChangeAgeMDiff = -1  if ChangeAgeMHighLow ==1 

gen ChangeAgeMSame = ChangeAgeMHighHigh
replace ChangeAgeMSame = -1 if ChangeAgeMHighHigh==1

* first estimate all the lags and leads 
esplot LogPayBonus ,  event(ChangeAgeMDiff , save ) compare(ChangeAgeMSame , save) window(-30 30)  period_length(3) estimate_reference // 30 Window
* 5h30 ON 3MILL 
esplot LogPayBonus ,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-30 30)  period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM IDlse ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-10(2)10) ///
xtitle(Quarters since manager change) ytitle("Pay + Bonus (logs)") title("Pay + Bonus (logs)", span pos(12))
graph save  "$analysis/Results/4.MType/DualPay.gph", replace
graph export  "$analysis/Results/4.MType/DualPay.png", replace

esplot LeaverPerm  ,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM AgeBand Female Func ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Exit") title("Exit", span pos(12))
graph save  "$analysis/Results/4.MType/DualExit.gph", replace
graph export  "$analysis/Results/4.MType/DualExit.png", replace
esplot LeaverPerm,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-60 60)  period_length(3) estimate_reference// 60 Window

esplot TransferInternalC ,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM IDlse ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Transfer: office/sub-division") title("Transfer: office/sub-division", span pos(12))
graph save  "$analysis/Results/4.MType/DualTransferInternalC.gph", replace
graph export  "$analysis/Results/4.MType/DualTransferInternalC.png", replace

esplot TransferInternalSJC ,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM IDlse ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Transfer: job/office/sub-division") title("Transfer: job/office/sub-division", span pos(12))
graph save  "$analysis/Results/4.MType/DualTransferInternalSJC.gph", replace
graph export  "$analysis/Results/4.MType/DualTransferInternalSJC.png", replace

esplot TransferInternalSJSameMC,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM IDlse ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Transfer: job/office/sub-division, same manager") title("Transfer: job/office/sub-division, same manager", span pos(12))
graph save  "$analysis/Results/4.MType/DualTransferInternalSJSameMC.gph", replace
graph export  "$analysis/Results/4.MType/DualTransferInternalSJSameMC.png", replace

esplot TransferInternalSJDiffMC ,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM IDlse ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Transfer: job/office/sub-division, diff. manager") title("Transfer: job/office/sub-division, diff. manager", span pos(12))
graph save  "$analysis/Results/4.MType/TransferInternalSJDiffMC.gph", replace
graph export  "$analysis/Results/4.MType/TransferInternalSJDiffMC.png", replace

esplot ChangeSalaryGradeC ,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM IDlse ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Promotion (salary)") title("Promotion (salary)", span pos(12))
graph save  "$analysis/Results/4.MType/DualChangeSalaryGradeC.gph", replace
graph export  "$analysis/Results/4.MType/DualChangeSalaryGradeC.png", replace

esplot PromWLC ,  event(ChangeAgeMDiff , nogen ) compare(ChangeAgeMSame , nogen) window(-60 60)  period_length(3) vce(cluster IDlseMHR) absorb( IDlseMHR CountryYM IDlse ) estimate_reference yline(0, lc(maroon) lp(dash)) xline(-1, lc(maroon) lp(solid)) xlabel(-20(2)20) ///
xtitle(Quarters since manager change) ytitle("Promotion (work level)") title("Promotion (work level)", span pos(12))
graph save  "$analysis/Results/4.MType/DualPromWLC.gph", replace
graph export  "$analysis/Results/4.MType/DualPromWLC.png", replace

