********************************************************************************
* OLD CODE - FIGURES/TABLES REPLACED OR TAKEN OUT
********************************************************************************


********************************************************************************
* Performance of new hires 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 

gen Post = KEi >=0 if KEi!=.

keep if TenureMin<1 // select new hires 
bys IDlse: egen my = min(YearMonth)
format my %tm
gen year1 = my + 12 
gen year2 = my + 24 
gen year3 = my + 36
gen year4 = my + 48
gen year5 = my + 60
gen year7 = my + 84

gen yearmid = my + 6
format year1 %tm // first year of new hire 

* New Hires 
bys IDlse: egen Pay1 = mean(cond(YearMonth ==year1 , LogPayBonus, .) )
bys IDlse: egen Pay0 = mean(cond(YearMonth ==my , LogPayBonus, .) )
gen PayGrowth = Pay1 - Pay0 

bys IDlse: egen HF0 = mean(cond(YearMonth ==my , EarlyAgeM, .) )
bys IDlse: egen WLM0 = mean(cond(YearMonth ==my , WLM, .) )
bys IDlse: egen IDlseMHR0 = mean(cond(YearMonth ==my , IDlseMHR, .) )

gen VPA125 = VPA >=125 if VPA!=. 
gen VPA100 = VPA >100 if VPA!=. 

label var PayGrowth "Pay growth, 1 year"
label var LogPayBonus "Pay + bonus, logs" 
label var LogPay "Pay + bonus, logs" 
label var LogBonus  "Bonus, logs" 
label var VPA "Perf. appraisals"  
label var VPA100 "Perf. appraisals > 100"  
label var VPA125 "Perf. appraisals > 125"  
label var ChangeSalaryGradeC "Prob. salary increase"
label var TransferSJC "Prob. job transfer"
label var TransferSJC "Prob. lateral move"


gen regLH =1 
gen regHL = 1 
*label var regLH "HH vs. LH transition"
*label var regHL "HL vs. LL transition"
label var regLH "Next manager: high-flyer"
label var regHL "Next manager: low-flyer"

* NEW HIRES: By manager transition
****************************************************************************

foreach var in  LogPayBonus { // PayGrowth LogPay LogBonus VPA VPA100 VPA125 ChangeSalaryGradeC  TransferSJLLC
eststo reg1: reghdfe `var' HF0   if  WLM0==2 &  YearMonth ==year5 , cluster(IDlseMHR) a( YearMonth Country  )
*eststo reg1: reghdfe `var' HF0   if  WLM0==2 & (FTHH!=. | FTLH !=. | FTHL!=. | FTLL !=.)  & Post==1 & YearMonth ==year4  , cluster(IDlseMHR) a( YearMonth Country  )
eststo regLH: reghdfe `var' HF0   if  WLM0==2  & (FTHH!=. | FTLH !=.) & Post==1 & YearMonth ==year5 , cluster(IDlseMHR) a( YearMonth Country  )
eststo regHL: reghdfe `var' HF0   if  WLM0==2  & (FTHL!=. | FTLL !=.) & Post==1& YearMonth ==year5 , cluster(IDlseMHR) a( YearMonth Country  )
}

**# ON PAPER FIGURE: NewHireLHE.png
cap drop reg1
gen reg1 =1 
label var reg1 "Hiring manager: high-flyer"
coefplot reg1 regLH regHL, ///
title("Pay + bonus in logs, new hires", pos(12) span si(medsmall))  keep(HF0)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(0 .15)) xlabel(0(0.03)0.15)
graph export "$analysis/Results/0.Paper/3.3.Other Analysis/NewHireLH.png", replace 
graph save "$analysis/Results/0.Paper/3.3.Other Analysis/NewHireLH.gph", replace

