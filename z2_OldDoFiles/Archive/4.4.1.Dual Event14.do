///////////////////////
* IMPORT DATASET 
///////////////////////

do "$analysis/DoFiles/0.1.EventImport.do"

********************************************************************************
* * DUAL DOUBLE DIFFERENCES 
********************************************************************************

* program to store coeff estimates 
cap program drop coeff
program def coeff
matrix b = J(121,1,.)
matrix se = J(121,1,.)
matrix p = J(121,1,.)
matrix lo = J(121,1,.)
matrix hi = J(121,1,.)
matrix et = J(121,1,.)

local j = 1
forval i=60(-1)2{
	lincom ( (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) - (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) )
	
	mat b_F`i' = (r(estimate))
	mat se_F`i' = (r(se))
	mat p_F`i' = (r(p))
	mat lo_F`i' = (r(lb))
	mat hi_F`i' = (r(ub))
	
	matrix b[`j',1] =b_F`i'
	matrix se[`j',1] =se_F`i'
	matrix p[`j',1] =p_F`i'
	matrix lo[`j',1] =lo_F`i'
	matrix hi[`j',1] =hi_F`i'
	mat et[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix b[60,1] =0
matrix se[60,1] =0
matrix p[60,1] =0
matrix lo[60,1] =0
matrix hi[60,1] =0
matrix et[60,1] =-1

local j = 61
forval i=0(1)60{
	lincom ( (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) - (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh) )
	
	mat b_L`i' = (r(estimate))
	mat se_L`i' = (r(se))
	mat p_L`i' = (r(p))
	mat lo_L`i' = (r(lb))
	mat hi_L`i' = (r(ub))
	
	matrix b[`j',1] =b_L`i'
	matrix se[`j',1] =se_L`i'
	matrix p[`j',1] =p_L`i'
	matrix lo[`j',1] =lo_L`i'
	matrix hi[`j',1] =hi_L`i'
	mat et[`j',1] = `i'
	local j = `j' + 1

}

cap drop b1 et1 lo1 hi1 p1	se1
svmat b 
svmat se
svmat p
svmat et 
svmat lo 
svmat hi 
end 

////////////////////////////////////////////////////////////////////////////////
* first estimate all the lags and leads 
////////////////////////////////////////////////////////////////////////////////

esplot LogPayBonus ,  event(ChangeAgeMHighLow , save ) compare(ChangeAgeMHighHigh , save) window(-12 12)   estimate_reference // estimate reference 
esplot LogPayBonus ,  event(ChangeAgeMLowHigh , save ) compare(ChangeAgeMLowLow , save) window(-12 12)   estimate_reference // estimate reference 

drop F1_ChangeAgeMLowHigh F1_ChangeAgeMLowLow F1_ChangeAgeMHighHigh F1_ChangeAgeMHighLow

////////////////////////////////////////////////////////////////////////////////
* Define variables for full model 
////////////////////////////////////////////////////////////////////////////////

global event F*ChangeAgeMLowHigh L*ChangeAgeMLowHigh F*ChangeAgeMHighLow L*ChangeAgeMHighLow F*ChangeAgeMHighHigh L*ChangeAgeMHighHigh F*ChangeAgeMLowLow L*ChangeAgeMLowLow
global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
global abs CountryYM AgeBand AgeBandM IDlse  IDlseMHR

* PAY
eststo: reghdfe LogPayBonus $event $cont , a( $abs   ) vce(cluster IDlseMHR)

coeff // program 

 tw connected b et if et>-21 & et<21, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et if et>-21 & et<21, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-20(2)20) ///
xtitle(Months since manager change) title("Pay + Bonus (logs)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.MType/PayDual.gph", replace
graph export "$analysis/Results/4.MType/PayDual.png", replace

* EXIT 
eststo: reghdfe LeaverPerm $event $cont , a( CountryYM AgeBand AgeBandM  IDlseMHR   ) vce(cluster IDlseMHR)

coeff // program 
cap drop hi lo 
gen hi = b1 +  se1*1.96
gen lo = b1 -  se1*1.96
*coeffQ
*gen hiQ= bQ +  seQ*1.96
*gen loQ = bQ -  seQ*1.96
 tw connected b1 et1 if et1>-31 & et1<31, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et1 if et1>-31 & et1<31, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-30(3)30) ///
xtitle(Months since manager change) title("Exit", span pos(12)) legend(off)
graph save  "$analysis/Results/4.MType/ExitDual.gph", replace
graph export "$analysis/Results/4.MType/ExitDual.png", replace

* PROMWLC
eststo: reghdfe PromWLC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

coeff // program 

 tw connected b et if et>-61 & et<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et if et>-61 & et<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Promotion (work level)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.MType/PromWLCDual.gph", replace
graph export "$analysis/Results/4.MType/PromWLCDual.png", replace

* ChangeSalaryGradeC
eststo: reghdfe ChangeSalaryGradeC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

coeff // program 

 tw connected b et if et>-61 & et<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et if et>-61 & et<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Promotion (salary)", span pos(12)) legend(off)
graph save  "$analysis/Results/4.MType/ChangeSalaryGradeCDual.gph", replace
graph export "$analysis/Results/4.MType/ChangeSalaryGradeCDual.png", replace

* TransferInternalSJC
eststo: reghdfe TransferInternalSJC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

coeff // program 

 tw connected b et if et>-61 & et<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et if et>-61 & et<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/4.MType/TransferInternalSJCDual.gph", replace
graph export "$analysis/Results/4.MType/TransferInternalSJCDual.png", replace


* TransferInternalSJDiffMC
eststo: reghdfe TransferInternalSJDiffMC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

coeff // program 

 tw connected b et if et>-61 & et<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et if et>-61 & et<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division, diff. manager", span pos(12)) legend(off)
graph save  "$analysis/Results/4.MType/TransferInternalSJDiffMCDual.gph", replace
graph export "$analysis/Results/4.MType/TransferInternalSJDiffMCDual.png", replace

* TransferInternalSJSameMC
eststo: reghdfe TransferInternalSJSameMC $event $cont, a( $abs   ) vce(cluster IDlseMHR)

coeff // program 

 tw connected b et if et>-61 & et<61, lcolor(ebblue) mcolor(ebblue) || rcap lo hi et if et>-61 & et<61, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-60(6)60) ///
xtitle(Months since manager change) title("Transfer: job/office/sub-division, same manager", span pos(12)) legend(off)
graph save  "$analysis/Results/4.MType/TransferInternalSJSameMCDual.gph", replace
graph export "$analysis/Results/4.MType/TransferInternalSJSameMCDual.png", replace



