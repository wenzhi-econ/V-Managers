///////////////////////
* IMPORT DATASET 
///////////////////////

do  "$analysis/DoFiles/4.Event/4.0.TWFEPrep.do"
********************************************************************************
* * DUAL DOUBLE DIFFERENCES 
********************************************************************************

global event F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh F*ChangeAgeMLowLow L*ChangeAgeMLowLow
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR
global exitFE CountryYM AgeBand AgeBandM   IDlseMHR Func Female

* IDEALLY TO REDO ARE TRANSFER & EXIT ON FULL ROBUSTNESS SAMPLE 

////////////////////////////////////////////////////////////////////////////////
* EXIT 
////////////////////////////////////////////////////////////////////////////////

global event F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh F*ChangeAgeMLowLow L*ChangeAgeMLowLow
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR
global exitFE CountryYM AgeBand AgeBandM Female Func  IDlseMHR
global eventE L*ChangeAgeMLowHigh L*ChangeAgeMHighLow L*ChangeAgeMHighHigh L*ChangeAgeMLowLow

rename L0_ChangeAgeMLowHigh DL0_ChangeAgeMLowHigh 
rename L0_ChangeAgeMLowLow DL0_ChangeAgeMLowLow
rename L0_ChangeAgeMHighHigh DL0_ChangeAgeMHighHigh 
rename L0_ChangeAgeMHighLow DL0_ChangeAgeMHighLow 

eststo: reghdfe LeaverPerm $eventE $cont if YearMonth >= Ei | Ei ==.  , a( $exitFE   ) vce(cluster IDlseMHR)

* double differences 
coeffExit // program 
drop hi1 lo1
gen hi1 = b1 +  se1*1.96
gen lo1 = b1 -  se1*1.96
 tw connected b1 et1 if et1>=0 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=0 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon))  xline(0, lcolor(maroon)) xlabel(0(3)30) ///
xtitle(Months since manager change) title("Exit", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ExitDual.gph", replace
graph export "$analysis/Results/7.Robustness/ExitDual.png", replace
 

* single differences 
coeffExit1 // program 
drop hiL1 loL1  hiH1 loH1
gen hiL1 = bL1 +  seL1*1.96
gen loL1 = bL1 -  seL1*1.96
gen hiH1 = bH1 +  seH1*1.96
gen loH1 = bH1 -  seH1*1.96
 tw connected bL et1 if et1>=0 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL et1 if et1>=0 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon))  xlabel(0(3)30) ///
xtitle(Months since manager change) title("Exit", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ExitSingleLow.gph", replace
graph export "$analysis/Results/7.Robustness/ExitSingleLow.png", replace

 tw connected bH1 et1 if et1>=0 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=0 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon))  xlabel(0(3)30) ///
xtitle(Months since manager change) title("Exit", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/ExitSingleHigh.gph", replace
graph export "$analysis/Results/7.Robustness/ExitSingleHigh.png", replace

////////////////////////////////////////////////////////////////////////////////
* TransferInternalSJC
////////////////////////////////////////////////////////////////////////////////

rename DL0_ChangeAgeMLowHigh L0_ChangeAgeMLowHigh 
rename DL0_ChangeAgeMLowLow L0_ChangeAgeMLowLow
rename DL0_ChangeAgeMHighHigh L0_ChangeAgeMHighHigh 
rename DL0_ChangeAgeMHighLow L0_ChangeAgeMHighLow 

eststo: reghdfe TransferInternalC $event $cont, a( CountryYM AgeBand AgeBandM IDlse  ) vce(cluster IDlseMHR)

* double differences 
coeff // program 
drop hi1 lo1
gen hi1 = b1 +  se1*1.96
gen lo1 = b1 -  se1*1.96
 tw connected b1 et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferInternalCDual.gph", replace
graph export "$analysis/Results/7.Robustness/TransferInternalCDual.png", replace

* single differences 
coeff1 // program 

drop hiL1 loL1  hiH1 loH1
gen hiL1 = bL1 +  seL1*1.96
gen loL1 = bL1 -  seL1*1.96
gen hiH1 = bH1 +  seH1*1.96
gen loH1 = bH1 -  seH1*1.96

 tw connected bL et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferInternalCSingleLow.gph", replace
graph export "$analysis/Results/7.Robustness/TransferInternalCSingleLow.png", replace

 tw connected bH1 et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferInternalCSingleHigh.gph", replace
graph export "$analysis/Results/7.Robustness/TransferInternalCSingleHigh.png", replace

* other transfers 

merge 1:1 IDlse YearMonth using "$Managersdta/AllSnapshotMCultureMType2015.dta", keepusing(TransferSubFuncC TransferSJ TransferSJC TransferSJSameMC TransferSJSameM TransferSJDiffMC ///
 TransferSJDiffM TransferSJL TransferSJLC TransferSJSameMLC TransferSJSameML TransferSJDiffMLC TransferSJDiffML ///
 TransferInternalL TransferInternalLC TransferInternalSameMLC TransferInternalSameML  TransferInternalDiffMLC TransferInternalDiffML TransferInternalLL TransferInternalLLC TransferInternalSameMLLC TransferInternalSameMLL TransferInternalDiffMLLC TransferInternalDiffMLL )
keep if _merge ==3 
drop _merge 


eststo: reghdfe TransferSJC $event $cont, a( $abs ) vce(cluster IDlseMHR)

* double differences 
coeff // program 
drop hi1 lo1
gen hi1 = b1 +  se1*1.96
gen lo1 = b1 -  se1*1.96
 tw connected b1 et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferSJCDual.gph", replace
graph export "$analysis/Results/7.Robustness/TransferSJCDual.png", replace

* single differences 
coeff1 // program 

drop hiL1 loL1  hiH1 loH1
gen hiL1 = bL1 +  seL1*1.96
gen loL1 = bL1 -  seL1*1.96
gen hiH1 = bH1 +  seH1*1.96
gen loH1 = bH1 -  seH1*1.96

 tw connected bL et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferSJCSingleLow.gph", replace
graph export "$analysis/Results/7.Robustness/TransferSJCSingleLow.png", replace

 tw connected bH1 et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferSJCSingleHigh.gph", replace
graph export "$analysis/Results/7.Robustness/TransferSJCSingleHigh.png", replace

* dummy - to run
eststo: reghdfe TransferSJ $event $cont, a( $abs ) vce(cluster IDlseMHR)

* double differences 
coeff // program 
drop hi1 lo1
gen hi1 = b1 +  se1*1.96
gen lo1 = b1 -  se1*1.96
 tw connected b1 et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferSJDual.gph", replace
graph export "$analysis/Results/7.Robustness/TransferSJDual.png", replace

* single differences 
coeff1 // program 

drop hiL1 loL1  hiH1 loH1
gen hiL1 = bL1 +  seL1*1.96
gen loL1 = bL1 -  seL1*1.96
gen hiH1 = bH1 +  seH1*1.96
gen loH1 = bH1 -  seH1*1.96

 tw connected bL et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferSJSingleLow.gph", replace
graph export "$analysis/Results/7.Robustness/TransferSJSingleLow.png", replace

 tw connected bH1 et1 if et1>-40 & et1<40, lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>-40 & et1<40, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-40(6)40) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/7.Robustness/TransferSJSingleHigh.gph", replace
graph export "$analysis/Results/7.Robustness/TransferSJSingleHigh.png", replace
