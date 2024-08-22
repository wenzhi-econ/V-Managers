* KEEPING TRACK OF SPECIFICATIONS 

* MANAGER FE 
local Label FT
esplot `v' if   ( `Label'LL !=. |    `Label'LH!=.) & Year>2010 & WL2 ==1 , event( `Label'LowHigh, nogen) compare( `Label'LowLow, nogen) window(-36 36 , bin ) period(3) estimate_reference vce(cluster IDlseMHR) absorb(   i.YearMonth i.IDlse i.Tenure i.TenureM i.IDlseMHR ) legend(off) yline(0) xline(-1)  xlabel(-12(2)12) name(`v'LH, replace) xtitle(Quarters since manager change) title("`lab'", span pos(12))

* takes 1 day to run completely (24h) 


* NO MANAGER FE 
local Label FT
esplot `v' if   ( `Label'LL !=. |    `Label'LH!=.) & Year>2010 & WL2 ==1 , event( `Label'LowHigh, nogen) compare( `Label'LowLow, nogen) window(-36 36 , bin ) period(3) estimate_reference vce(cluster IDlseMHR) absorb(   i.YearMonth i.IDlse i.Tenure i.TenureM) legend(off) yline(0) xline(-1)  xlabel(-12(2)12) name(`v'LH, replace) xtitle(Quarters since manager change) title("`lab'", span pos(12))


local v  PromWLC // LogPayBonus TransferSJLLC
local Label FT
local lab: variable label `v'
esplot `v' if   ( `Label'LL !=. |    `Label'LH!=.)   , event( `Label'LowHigh, nogen) compare( `Label'LowLow, nogen) window(-36 36 , bin ) period(3) estimate_reference vce(cluster IDlseMHR) absorb(   i.YearMonth    )  legend(off) yline(0) xline(-1)  xlabel(-12(2)12) name(`v'LH, replace) xtitle(Quarters since manager change) title("`lab'", span pos(12))

graph save  "$analysis/Results/4.EventQ/`Label'`v'ELH.gph", replace
graph export "$analysis/Results/4.EventQ/`Label'`v'ELH.png", replace


local v LogPayBonus // LogPayBonus TransferSJLLC
local Label FT
local lab: variable label `v'
esplot `v' if   ( `Label'LL !=. |    `Label'LH!=.) &  WL2 ==1  , event( `Label'LowHigh, nogen) absorb(   i.Year i.IDlse i.Tenure   ) controls( TransferSJ ) compare( `Label'LowLow, nogen) window(-36 36 , bin ) period(3) estimate_reference vce(cluster IDlseMHR)  legend(off) yline(0) xline(-1)  xlabel(-12(2)12) name(`v'LH, replace) xtitle(Quarters since manager change) title("`lab'", span pos(12))



local v LogPayBonus // LogPayBonus TransferSJLLC
local Label FT
local lab: variable label `v'
esplot `v' if   ( `Label'LL !=. |    `Label'LH!=.) &  WL2 ==1   , event( `Label'LowHigh, nogen) absorb(   i.Year i.IDlse i.Tenure   )  compare( `Label'LowLow, nogen) window(-36 36 , bin ) period(3) estimate_reference vce(cluster IDlseMHR)  legend(off) yline(0) xline(-1)  xlabel(-12(2)12) name(`v'LH, replace) xtitle(Quarters since manager change) title("`lab'", span pos(12))



* a bit better when doing f3.Ei
* absorb(   i.YearMonth i.IDlse i.Tenure   ) controls( MonthsSubFunc  )
