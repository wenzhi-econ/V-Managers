********************************************************************************
* Performance of new hires 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 

gen Post = KEi >=0 if KEi!=.

* Delta 
xtset IDlse YearMonth 
foreach var in EarlyAgeM{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
	gen Post`var'= Post* DeltaM`var'
}

keep if TenureMin<1 // select new hires 
bys IDlse: egen my = min(YearMonth)
format my %tm
gen year1 = my + 12 
gen year2 = my + 24 
gen year3 = my + 36
gen year4 = my + 48
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

* first year
****************************************************************************

eststo clear 
foreach var in PayGrowth LogPayBonus LogPay LogBonus VPA VPA100 VPA125 ChangeSalaryGradeC  TransferSJLLC{
	*eststo: reg `var' HF0 if YearMonth ==year1, cluster(IDlseMHR)
	eststo `var': reghdfe `var' HF0 if YearMonth ==year1 & WLM0==2, vce(cluster IDlseMHR) a(YearMonth Country )
	su `var' if HF0==0 & YearMonth ==year1 & WLM0==2
}


* PLOT: hiring manager is high flyer 
coefplot LogPay ChangeSalaryGradeC VPA100 VPA125, ///
title("New hires", pos(12) span si(large))  keep(HF0)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) 
 *xscale(range(-.04 .1)) xlabel(-.04(0.02)0.1)
graph export "$analysis/Results/8.Team/NewHire.png", replace 
graph save "$analysis/Results/8.Team/NewHire.gph", replace

gen regLH =1 
gen regHL = 1 
*label var regLH "HH vs. LH transition"
*label var regHL "HL vs. LL transition"
label var regLH "Next manager: high-flyer"
label var regHL "Next manager: low-flyer"

* NEW HIRES: By manager transition
****************************************************************************

foreach var in  LogPayBonus { // PayGrowth LogPay LogBonus VPA VPA100 VPA125 ChangeSalaryGradeC  TransferSJLLC
eststo reg1: reghdfe `var' HF0   if  WLM0==2 &  YearMonth ==year4 , cluster(IDlseMHR) a( YearMonth Country  )
*eststo reg1: reghdfe `var' HF0   if  WLM0==2 & (FTHH!=. | FTLH !=. | FTHL!=. | FTLL !=.)  & Post==1 & YearMonth ==year4  , cluster(IDlseMHR) a( YearMonth Country  )
eststo regLH: reghdfe `var' HF0   if  WLM0==2  & (FTHH!=. | FTLH !=.) & Post==1 & YearMonth ==year4 , cluster(IDlseMHR) a( YearMonth Country  )
eststo regHL: reghdfe `var' HF0   if  WLM0==2  & (FTHL!=. | FTLL !=.) & Post==1& YearMonth ==year4 , cluster(IDlseMHR) a( YearMonth Country  )
}

**# PLOT: salary (ON PAPER)
cap drop reg1
gen reg1 =1 
label var reg1 "Hiring manager: high-flyer"
coefplot reg1 regLH regHL, ///
title("Pay + bonus in logs, new hires", pos(12) span si(medsmall))  keep(HF0)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) xscale(range(0 .15)) xlabel(0(0.03)0.15)
graph export "$analysis/Results/8.Team/NewHireLH.png", replace 
graph save "$analysis/Results/8.Team/NewHireLH.gph", replace

* UFLP: By manager transition
****************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 
gen Post = KEi >=0 if KEi!=.

* UFLP 
bys IDlse: egen UFLPEnd = max(cond(UFLPStatus ==1, YearMonth, .))
gen WindowUFLP = YearMonth - UFLPEnd
bys IDlse: egen HFUFLP = max(cond(YearMonth ==  UFLPEnd , EarlyAgeM, .))
bys IDlse: egen MUFLP = max(cond(YearMonth ==  UFLPEnd , IDlseMHR, .))
bys IDlse: egen HFnextUFLP = max(cond(YearMonth ==  UFLPEnd +1 & IDlseMHR!= MUFLP, EarlyAgeM, .))
bys IDlse: egen mHFUFLP= max(cond(UFLPStatus==1 , EarlyAgeM, .))

eststo clear 
foreach var in  LogPayBonus { // PayGrowth LogPay LogBonus VPA VPA100 VPA125 ChangeSalaryGradeC  TransferSJLLC
eststo regUFLP: reghdfe `var'  mHFUFLP   if   WindowUFLP>=0 & WindowUFLP<=24 &  HFnextUFLP!=., cluster(IDlseMHR) a(YearMonth Country )
eststo regUFLPL: reghdfe `var'  mHFUFLP   if   HFnextUFLP==0  & WindowUFLP>=0 & WindowUFLP<=24, cluster(IDlseMHR) a( YearMonth Country  )
eststo regUFLPH: reghdfe `var'  mHFUFLP   if  HFnextUFLP==1 & WindowUFLP>=0 & WindowUFLP<=24, cluster(IDlseMHR) a( YearMonth Country )
}


* PLOT: salary
cap drop regUFLP regUFLPH regUFLPL
gen regUFLP =1 
gen regUFLPH =1 
gen regUFLPL = 1 
label var regUFLPH "Next manager: high-flyer"
label var regUFLPL "Next manager: low-flyer"
label var regUFLP "At least one high-flyer during programme"
coefplot regUFLP regUFLPL regUFLPH, ///
title("Pay + bonus in logs (two years after)", pos(12) span si(medsmall))  keep(mHFUFLP)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
scale(1) legend(off) swapnames aseq ///
 coeflabels(, ) ysize(6) xsize(8) aspect(0.4) ytick(,grid glcolor(black))  xline(0, lpattern(dash)) 
 *xscale(range(-.04 .1)) xlabel(-.04(0.02)0.1)
graph export "$analysis/Results/8.Team/UFLPLH.png", replace 
graph save "$analysis/Results/8.Team/UFLPLH.gph", replace

* other variables
eststo clear 
foreach var in  LeaverPerm  PromWLC  TransferSJLLC{ // PayGrowth LogPay LogBonus VPA VPA100 VPA125 ChangeSalaryGradeC  TransferSJLLC
eststo `var': reghdfe `var'  mHFUFLP   if   WindowUFLP>0 & WindowUFLP<=24 &  HFnextUFLP!=., cluster(IDlseMHR) a(YearMonth Country )
eststo `var'H: reghdfe `var'  mHFUFLP   if  HFnextUFLP==1 & WindowUFLP>0 & WindowUFLP<=24, cluster(IDlseMHR) a( YearMonth Country )
eststo `var'L: reghdfe `var'  mHFUFLP   if   HFnextUFLP==0  & WindowUFLP>0 & WindowUFLP<=24, cluster(IDlseMHR) a( YearMonth Country  )
}
