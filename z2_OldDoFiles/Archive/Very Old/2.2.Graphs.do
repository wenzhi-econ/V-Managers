********************************************************************************
* plot the event study graphs 
********************************************************************************

frame create graphs 
frame change graphs 
use "$analysis/Results/2.Analysis/OutGroupIASameMEventPay.dta", clear 



use "$analysis/Results/2.Analysis/OutGroupIASameMEventPay.dta", clear 
gen t1 = _n + 1
replace t1 = -t1
replace t1 = _n -24 if t1<=-25
replace t1 = . if t1 >36
gen t2 = _n  - 59
replace t2 = . if t2 <2
replace t2 = -t2
replace t2 = _n - 84 if t2<=-25

twoway (scatter coef t2, color(orange) ) (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (months)") ///
ytitle("Pay + bonus (logs)") xlabel(-24(3)36) yline(0) xline(-1,lpattern(-)) legend(order(1 "IA M" )) title("IA M Effect")
graph export "$analysis/Results/2.Analysis/OutGroupIASameMEventPay.png", replace
