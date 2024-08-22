********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

///////////////////////
* IMPORT DATASET 
///////////////////////

do "$analysis/DoFiles/4.Event/4.0.EventImportSun.do"
xtset IDlse YearMonth  

global event F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh F*ChangeAgeMLowLow L*ChangeAgeMLowLow
global cont  Tenure TenureM Tenure2 Tenure2M
global abs AgeBand AgeBandM  IDlseMHR IDlse  CountryYM 
global exitFE  CountryYM AgeBand AgeBandM  IDlseMHR Female Func

********************************************************************************
* Event study Analysis - Borusyak et al. (2021) imputation
********************************************************************************

* to log estimation time  

////////////////////////////////////////////////////////////////////////////////
* Single differences 
////////////////////////////////////////////////////////////////////////////////

global abs    IDlse  YearMonth
bys IDlse: egen c = count(YearMonth)
drop if c<12

count if ELH!=.
gen wtr1 = (ELH!=.)/r(N)
count if ELL!=.
gen wtr2 = (ELL!=.)/r(N)
gen wtr_diff = wtr1-wtr2

////////////////////////////////////////////////////////////////////////////////
* PAY
////////////////////////////////////////////////////////////////////////////////

* First determine cannot impute (as autosample NA for sum option ) 
did_imputation LogPayBonus IDlse YearMonth  EL ,  autosample  cluster(IDlseMHR) fe( $abs ) controls(  $cont ) tol(5) nose horizons(0/30) pretrend(30)
gen CILogPayBonus =  cannot_impute
* then run command  - specify horizons & pretrend 
did_imputation LogPayBonus IDlse YearMonth  EL if  CILogPayBonus!=1, wtr(wtr_diff ) sum  cluster(IDlseMHR) fe( $abs ) controls(  $cont )  nose horizons(0/30) pretrend(30)

event_plot, default_look trimlag(30) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Pay+bonus (logs), Borusyak et al. (2021) imputation estimator") xlabel(-30(3)30) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/Imputation/DIDPay.gph", replace
graph export  "$analysis/Results/4.MType/Imputation/DIDPay.png", replace

////////////////////////////////////////////////////////////////////////////////
* EXIT
////////////////////////////////////////////////////////////////////////////////

* First determine cannot impute (as autosample NA for sum option ) 
did_imputation LeaverPerm IDlse YearMonth  EL ,  autosample  cluster(IDlseMHR) fe( $exitFE ) controls(  $cont ) tol(5) nose horizons(0/60) pretrend(60)
gen CILeaverPerm =  cannot_impute
did_imputation LeaverPerm IDlse YearMonth  EL if  CILeaverPerm!=1, wtr(wtr_diff ) sum  cluster(IDlseMHR) fe( $exitFE ) controls( $cont   ) tol(.1) nose horizons(0/60) pretrend(60)
event_plot, default_look trimlag(60) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Exit, Borusyak et al. (2021) imputation estimator") xlabel(-60(3)60) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/Imputation/DIDExit.gph", replace
graph export  "$analysis/Results/4.MType/Imputation/DIDExit.png", replace

////////////////////////////////////////////////////////////////////////////////
* PROM WLC 
////////////////////////////////////////////////////////////////////////////////

* First determine cannot impute (as autosample NA for sum option ) 
did_imputation PromWLC IDlse YearMonth  EL ,  autosample  cluster(IDlseMHR) fe( $abs ) controls(   $cont  ) tol(5) nose horizons(0/60) pretrend(60)
gen CIPromWLC  =  cannot_impute
did_imputation PromWLC IDlse YearMonth  EL if  CIPromWLC !=1, wtr(wtr_diff ) sum  cluster(IDlseMHR) fe(  $abs ) controls( $cont   ) tol(.1) nose horizons(0/60) pretrend(60)
event_plot, default_look trimlag(60) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Promotion (WL), Borusyak et al. (2021) imputation estimator") xlabel(-60(3)60) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/Imputation/DIDPromWLC.gph", replace
graph export  "$analysis/Results/4.MType/Imputation/DIDPromWLC.png", replace

////////////////////////////////////////////////////////////////////////////////
* ChangeSalaryGradeC
////////////////////////////////////////////////////////////////////////////////

* First determine cannot impute (as autosample NA for sum option ) 
did_imputation ChangeSalaryGradeC IDlse YearMonth  EL ,  autosample  cluster(IDlseMHR) fe( $abs ) controls(   $cont  ) tol(5) nose horizons(0/60) pretrend(60)
gen CIChangeSalaryGradeC  =  cannot_impute
did_imputation ChangeSalaryGradeC IDlse YearMonth  EL if  CIChangeSalaryGradeC !=1, wtr(wtr_diff ) sum  cluster(IDlseMHR) fe(  $abs ) controls( $cont   ) tol(.1) nose horizons(0/60) pretrend(60)
event_plot, default_look trimlag(60) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Promotion (salary), Borusyak et al. (2021) imputation estimator") xlabel(-60(3)60) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/Imputation/DIDChangeSalaryGradeC.gph", replace
graph export  "$analysis/Results/4.MType/Imputation/DIDChangeSalaryGradeC.png", replace

////////////////////////////////////////////////////////////////////////////////
* TransferInternalC
////////////////////////////////////////////////////////////////////////////////

* First determine cannot impute (as autosample NA for sum option ) 
did_imputation TransferInternalC IDlse YearMonth  EL ,  autosample  cluster(IDlseMHR) fe( $abs ) controls(   $cont  ) tol(5) nose horizons(0/60) pretrend(60)
gen CITransferInternalC  =  cannot_impute
did_imputation TransferInternalC IDlse YearMonth  EL if  CITransferInternalC !=1, wtr(wtr_diff ) sum  cluster(IDlseMHR) fe(  $abs ) controls( $cont   ) tol(.1) nose horizons(0/60) pretrend(60)
event_plot, default_look trimlag(60) graph_opt( xtitle("Months since the event") ytitle("Average causal effect") ///
	title("Transfer: office/sub-division, Borusyak et al. (2021) imputation estimator") xlabel(-60(3)60) scheme(aurora) )   ciplottype(rcap) savecoef
graph save  "$analysis/Results/4.MType/Imputation/DIDTransferInternalC.gph", replace
graph export  "$analysis/Results/4.MType/Imputation/DIDTransferInternalC.png", replace
