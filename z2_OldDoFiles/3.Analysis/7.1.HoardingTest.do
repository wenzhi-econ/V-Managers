********************************* TEST FOR TALENT HOARDING *********************************

global analysis  "/Users/virginiaminni/Desktop/Managers Temp" // temp for the results 
global exitFE   WLM  AgeBandM AgeBand Country Year Func Female
global Label  FT // FT PromWL75 PromSG75 PromWL50 PromSG50  FT odd  pcaFTSG50 pcaFTWL50  pcaFTSG75 pcaFTWL75

use "$managersdta/SwitchersAllSameTeam.dta", clear 

* only work level 2 managers 
bys IDlse: egen FirstWL2M = max(cond(WLM==2 & KEi==-1,1,0))
bys IDlse: egen LastWL2M = max(cond(WLM==2 & KEi==0,1,0))
gen WL2 = FirstWL2M ==1 & LastWL2M ==1


*First Event
gen EiInd = YearMonth == Ei

********************************* TEST FOR TALENT HOARDING *********************************

* whether the individual changes manager 
* same results whether I have worker FE or not 
xtset IDlse YearMonth 
replace EiInd = 0 if ChangeM==0

local v ChangeM // TransferSJ
label var  TransferInternal "Exit team"
label var ChangeM "Probability of manager change"
local lab: variable label `v'
esplot `v' if    WL2 ==1, event( EiInd, nogen)  window(-12 12 , bin )  vce(cluster IDlseMHR) absorb(   YearMonth  ) controls(c.Tenure##i.Female i.FemaleM##c.TenureM  ) estimate_reference legend(off) yline(0) xline(-1)  xlabel(-12(2)12) name(Hoard`v', replace) xtitle(Months since manager change) title("`lab'", span pos(12))

graph save "$analysis/Results/7.Robustness/TestHoard.gph", replace 
graph export "$analysis/Results/7.Robustness/TestHoard.png", replace 


