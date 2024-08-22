* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

use "$managersdta/SwitchersAllSameTeam2.dta", clear 
*use "$managersdta/AllSameTeam2.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity) // add productivity with mediation 

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

*keep if Ei!=. 
gen KEi  = YearMonth - Ei 

keep if Ei!=. 

* MEDIATION
*  medeff (regress M T x) (regress Y T M x) , treat(T) mediate(M) sims(1000) seed(1)

foreach v in LogPayBonus PromWLC ChangeSalaryGradeC TransferSJC TransferSJVC TransferSJLLC TransferFuncC{
	reghdfe `v', a(IDlse YearMonth) res(`v'R)
}

xtset IDlse YearMonth 
foreach v in  TransferSJC TransferSJVC TransferSJLLC TransferSJCR TransferSJVCR TransferSJLLCR TransferFuncCR{
gen l`v' = l1.`v'	
}

bys IDlse: egen IDlseMHRPost = mean(cond(KEi ==0, IDlseMHR, .))
bys IDlse: egen PayBase = mean(cond(KEi ==-1, LogPayBonus, .))
bys IDlse: egen SGBase = mean(cond(KEi ==-1, ChangeSalaryGradeC, .))
bys IDlse: egen TenBase = mean(cond(KEi ==-1, Tenure, .))
bys IDlse: egen YearBase = mean(cond(KEi ==-1, Year, .))
bys IDlse: egen FuncBase = mean(cond(KEi ==-1, Func, .))

bys IDlse: egen maxKEi = max(KEi)

reghdfe LogPayBonus if KEi<0, a(IDlse YearMonth) res(LogPayBonusR1)
bys IDlse: egen PayBaseR1 = mean(cond(KEi ==-1, LogPayBonusR1, .))
reghdfe LogPayBonus if KEi<0, a(Func Tenure AgeBand##Female YearMonth) res(LogPayBonusR2)
bys IDlse: egen PayBaseR2 = mean(cond(KEi ==-1, LogPayBonusR2, .))

reghdfe ChangeSalaryGradeC if KEi<0, a(IDlse YearMonth) res(ChangeSalaryGradeCR1)
bys IDlse: egen SGBaseR1 = mean(cond(KEi ==-1,ChangeSalaryGradeCR1, .))
reghdfe ChangeSalaryGradeC if KEi<0, a(Func Tenure AgeBand##Female YearMonth) res(ChangeSalaryGradeCR2)
bys IDlse: egen SGBaseR2 = mean(cond(KEi ==-1, ChangeSalaryGradeCR2, .))

bys IDlse: egen everT = max(cond(KEi>=0, TransferSJ,.))
bys IDlse: egen everTLL = max(cond(KEi>=0, TransferSJLL,.))

foreach v in TransferSJLLC TransferSJC  {
	
	bys IDlse: egen `v'6 = mean(cond(KEi ==6, `v', .))
	bys IDlse: egen `v'12 = mean(cond(KEi ==12, `v', .))
	bys IDlse: egen `v'24 = mean(cond(KEi ==24, `v', .))
	bys IDlse: egen `v'36 = mean(cond(KEi ==36, `v', .))
	bys IDlse: egen `v'60 = mean(cond(KEi ==60, `v', .))
}


bys IDlse: egen TransferSJCR36 = mean(cond(KEi ==36, TransferSJCR, .))
bys IDlse: egen TransferSJCR60 = mean(cond(KEi ==60, TransferSJCR, .))

bys IDlse: egen TransferFuncC60 = mean(cond(KEi ==60, TransferFuncC, .))

*Conduct mediation analysis for PRODUCTIVITY 
********************************************************************************
gen lp = log(Productivity + 1)

preserve 
keep if KEi ==36   & (FTLL !=. | FTLH!=.) & ISOCode =="IND" // keep max window | at least (another option is 36/60/84)

local T EarlyAgeM
local M  TransferSJC12  // TransferFuncC60 lTransferSJC TransferSJCR TransferSJLLCR lTransferSJCR lTransferSJLLCR
local Y  lp //  ChangeSalaryGradeC ChangeSalaryGradeCR  PromWLCR   LogPayBonusR
local I linter // interLL inter linter linterLL
local x  " " // "YearBase maxKEi TenBase PayBase" " SGBaseR1 maxKEi"

medeff (regress `M' `T' `x' ) (regress `Y' `T' `M'  `x' ), treat(`T') mediate(`M') sims(1000) seed(7) vce(cluster IDlseMHRPost)

*>>> Result for productivity: 7%

*Conduct mediation analysis - TAKING THE LATEST VALUE PER PERSON
********************************************************************************

preserve 
keep if KEi == maxKEi & KEi >=84 & (FTLL !=. | FTLH!=.) & WL2==1 // keep max window | at least (another option is 36/60/84)
*gen linter =  FTLHB*lTransferSJC // does not change much adding an interaction 

local T FTLHB
local M  TransferSJC60  // TransferFuncC60 lTransferSJC TransferSJCR TransferSJLLCR lTransferSJCR lTransferSJLLCR
local Y  ChangeSalaryGradeC //  ChangeSalaryGradeC ChangeSalaryGradeCR  PromWLCR   LogPayBonusR
local I linter // interLL inter linter linterLL
local x  " " // "YearBase maxKEi TenBase PayBase" " SGBaseR1 maxKEi"

medeff (regress `M' `T' `x' ) (regress `Y' `T' `M'  `x' ), treat(`T') mediate(`M') sims(1000) seed(7) vce(cluster IDlseMHRPost)

* >>> with controls 56% and without controls is 62% 
* >>> transferFunc is 12% (so they explain 20% of the overall lateral moves mediation effect)

sort IDlse 
gen t = r(tau)
gen coeff = r(tau) in 3
replace coeff = r(zeta0) in 1
replace coeff = r(delta0) in 2
gen lo = r(taulo) in 3
replace lo = r(zeta0lo) in 1
replace lo = r(delta0lo) in 2
gen hi = r(tauhi) in 3
replace hi = r(zeta0hi) in 1
replace hi = r(delta0hi) in 2
gen ttt = 1 in 1
replace ttt = 2 in 2
replace ttt = 3 in 3
*replace ttt = 0 in 3
gen bb = t in 4
gen bbb= d in 4

*tw rspike lo hi  ttt, legend(off) xlabel() lcolor(ebblue) lwidth(2 ..) horizontal xscale(range(0 0.25)) || dot coeff ttt,  horizontal  ndots(0)  msymbol(d) mcolor(white)  xtitle("Impact of good manager on long term career progression") xtick(0) ylabel(none)  ytitle("") ylabel( 1 "Unexplained" 2 "Lateral moves" 3 "Total effect" , add custom  ) xline(0, lpattern(dash)) dotextend(no) aspect(0.3) text(2.3 0.05 "40% of total effect") graphregion(margin(0 0 0 0)) 
*graph save  "$analysis/Results/5.Mechanisms/medCoeff.gph", replace
*graph export "$analysis/Results/5.Mechanisms/medCoeff.png", replace

/* with bar of percentage 
cap drop t coeff lo hi ttt bb bbb
sort IDlse 
gen t = r(tau)
gen coeff = r(tau) in 1
replace coeff = r(zeta0) in 2
replace coeff = r(delta0) in 3
gen lo = r(taulo) in 1
replace lo = r(zeta0lo) in 2
replace lo = r(delta0lo) in 3
gen hi = r(tauhi) in 1
replace hi = r(zeta0hi) in 2
replace hi = r(delta0hi) in 3
gen ttt = 1 in 1
replace ttt = 2 in 2
replace ttt = 3 in 3
replace ttt = 0 in 4
gen bb = t in 4
gen bbb= d in 4

tw rspike lo hi  ttt, legend(off) xlabel() lcolor(ebblue) lwidth(2 ..) horizontal || bar bb ttt , horizontal fcolor(white) lcolor(ebblue) || bar bbb ttt , bcolor(ebblue) horizontal   || dot coeff ttt,  horizontal  ndots(0)  msymbol(d) mcolor(white)  xtitle("Impact of good manager on long term career progression") xtick(0) ylabel(none) ytitle("") ylabel(0 "Percent decomposition" 1 "Total effect" 2 "Direct effect" 3 "Indirect effect (via lateral moves)", add custom  ) dotextend(no) aspect(0.3) text(0.1 0.04 "40%") graphregion(margin(0 0 0 0))
graph save  "$analysis/Results/5.Mechanisms/med.gph", replace
graph export "$analysis/Results/5.Mechanisms/med.png", replace
*/

*SENSITIVITY ANALYSIS
********************************************************************************

*medeff (regress `M' `T'  `x') (regress `Y' `T' `M' `I'  `x'), treat(`T') mediate(`M') interact(`I') sims(1000) seed(7) vce(cluster IDlseMHRPost)
medsens (regress  `M' `T' `x' ) (regress `Y' `T' `M' `x' ), treat(`T') mediate(`M') sims(1000)

gen rho = r(errcr)
su rho
local rho =round(r(mean), 0.001) 
su _med_delta0 if _med_rho==0
local ACME = round(r(mean), 0.001)

twoway rarea _med_updelta0 _med_lodelta0 _med_rho, bcolor(ltblue) || line _med_delta0 _med_rho, lcolor(ebblue) ytitle("Average Causal Mediation Effect (ACME)") title("Average Causal Mediation Effect (ACME) and {&rho}") xtitle("Sensitivity parameter: {&rho}") legend(off)  yline(0, lpattern(solid)) xline(0, lpattern(solid))  ///
 xline( `rho', lcolor(maroon)) xlabel(`rho' "{bf: {&rho} = `rho'}", add custom labcolor(maroon) angle(45))  
 *xlabel(-1(0.2)1)  ylabel(-0.3(0.1)0.3) yline(`ACME', lcolor(ebblue))  ylabel(`ACME' "{bf:ACME=`ACME'}", add custom labcolor(ebblue) angle(45))
graph save  "$analysis/Results/5.Mechanisms/rho.gph", replace
graph export "$analysis/Results/5.Mechanisms/rho.png", replace

restore 


*GELBACH Conduct mediation analysis - TAKING THE LATEST VALUE PER PERSON
********************************************************************************

preserve 
keep if KEi == maxKEi & KEi >=36 & (FTLL !=. | FTLH!=.) & WL2==1 // keep max window | at leas 
gen linter =  FTLHB*lTransferSJC // does not change much adding an interaction 

local T FTLHB
local M lTransferSJC // TransferSJCR TransferSJLLCR lTransferSJCR lTransferSJLLCR
local Y  ChangeSalaryGradeC //  ChangeSalaryGradeCR  PromWLCR   LogPayBonusR
local I linter // interLL inter linter linterLL
local x " SGBaseR1 maxKEi" // "YearBase maxKEi TenBase PayBase"

reg  `Y' `T'  `x' , vce(cluster IDlseMHRPost)
local tot = _b[`T']

reg  `Y' `T' `M'  `x' , vce(cluster IDlseMHRPost)
local i = _b[`M']

reg  `M' `T'   `x' , vce(cluster IDlseMHRPost)
local d = _b[`T']

di `i'*`d'/`tot' // 41% 

restore 

/* using OVERALL AVERAGE instead of last observation
********************************************************************************
gcollapse TransferSJC TransferSJCR SGBase  TenBase PayBase LogPayBonus LogPayBonusR  PromWLC* ChangeSalaryGradeC* TransferSJVC* TransferSJLLC* lTransferSJ*C*  FTLHB IDlseMHRPost everT everTLL, by(IDlse) // cross-section 

gen inter =  FTLHB*TransferSJCR 
gen interLL =  FTLHB*TransferSJLLCR 
gen linterLL =  FTLHB*lTransferSJLLCR 
gen linter =  FTLHB*lTransferSJCR 

gen interEver =  FTLHB*everT
gen interEverLL =  FTLHB*everTLL


*Conduct mediation analysis
********************************************************************************
local T FTLHB
local M lTransferSJC // TransferSJCR TransferSJLLCR lTransferSJCR lTransferSJLLCR
local Y  ChangeSalaryGradeC  //  ChangeSalaryGradeCR  PromWLCR   LogPayBonusR
local I linter // interLL inter linter linterLL


medeff (regress `M' `T' ) (regress `Y' `T' `M' ), treat(`T') mediate(`M') sims(1000) seed(7) vce(cluster IDlseMHRPost)
*medeff (regress `M' `T' ) (regress `Y' `T' `M' `I' ), treat(`T') mediate(`M') interact(`I') sims(1000) seed(7) vce(cluster IDlseMHRPost)

**Run Sensitivity Analysis
********************************************************************************

local T  FTLHB
local M lTransferSJC
local Y ChangeSalaryGradeC //  PromWLCR  
medsens (regress  `M' `T' ) (regress `Y' `T' `M'), treat(`T') mediate(`M') sims(1000) 

gen rho = r(errcr)
su rho
local rho =round(r(mean), 0.001) 
su _med_delta0 if _med_rho==0
local ACME = round(r(mean), 0.001)


twoway rarea _med_updelta0 _med_lodelta0 _med_rho, bcolor(ltblue) || line _med_delta0 _med_rho, lcolor(ebblue) ytitle("ACME") title("Average Causal Mediation Effect (ACME) and {&rho}") xtitle("Sensitivity parameter: {&rho}") legend(off)  yline(0, lpattern(solid)) xline(0, lpattern(solid)) xlabel(-1(0.2)1)  ylabel(-0.3(0.05)0.3) ///
 xline( `rho', lcolor(maroon)) xlabel(`rho' "{&rho} = `rho'", add custom labcolor(maroon) angle(45)) yline(`ACME', lcolor(ebblue))  ylabel(`ACME' "ACME=`ACME'", add custom labcolor(ebblue) angle(45)) 
graph save  "$analysis/Results/5.Mechanisms/rho.gph", replace
graph export "$analysis/Results/5.Mechanisms/rho.png", replace
