********************************************************************************
* does the gender of manager matter? for women or men? 
********************************************************************************

* female manager
********************************************************************************
 
local hh FemaleM
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if   (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  LeaverPerm


ta FemaleM0 if iio==1 

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Female - male manager", size(medsmall))  level(90) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 90% confidence intervals." ///
 "Showing the differential impact between having a woman and a man as a manager." "The share of workers with a female manager is 34%.", span)
graph export "$analysis/Results/5.Mechanisms/HFemaleM.png", replace 
graph save "$analysis/Results/5.Mechanisms/HFemaleM.png.gph", replace 

* female manager - women vs men 
********************************************************************************
 
local hh Female
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if FemaleM0==1 &(WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if  FemaleM0==1& (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  LeaverPerm


ta FemaleM0 if iio==1 

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Woman - men, female manager", size(medsmall))  level(90) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 90% confidence intervals." ///
 "Showing the differential impact between women and men, given the manager is a woman." "The share of workers with a female manager is 34%.", span)
graph export "$analysis/Results/5.Mechanisms/HGGapFemaleM.png", replace 
graph save "$analysis/Results/5.Mechanisms/HGGapFemaleM.gph", replace 

* male manager - women vs men 
********************************************************************************

local hh Female
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if FemaleM0==0 &(WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if  FemaleM0==0& (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  LeaverPerm


ta FemaleM0 if iio==1 

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Woman - men, male manager", size(medsmall))  level(90) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 90% confidence intervals." ///
 "Showing the differential impact between women and men, given the manager is a man." "The share of workers with a male manager is 66%.", span)
graph export "$analysis/Results/5.Mechanisms/HGGapMaleM.png", replace 
graph save "$analysis/Results/5.Mechanisms/HGGapMaleM.gph", replace 

* male manager - women vs men in low FLFP
********************************************************************************

local hh Female
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if FemaleM0==1 & LowFLFP0 == 0 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if  FemaleM0==1 & LowFLFP0 == 0 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  LeaverPerm


ta FemaleM0 if iio==1 

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Woman - men, male manager", size(medsmall))  level(90) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 90% confidence intervals." ///
 "Showing the differential impact between women and men, given the manager is a man." "The share of workers with a male manager is 66%.", span)
graph export "$analysis/Results/5.Mechanisms/HGGapMaleM.png", replace 
graph save "$analysis/Results/5.Mechanisms/HGGapMaleM.gph", replace 

* women vs men 
********************************************************************************

local hh Female
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  LeaverPerm


ta FemaleM0 if iio==1 

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Woman - men", size(medsmall))  level(90) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 90% confidence intervals." ///
 "Showing the differential impact between women and men, given the manager is a man." "The share of workers with a male manager is 66%.", span)
graph export "$analysis/Results/5.Mechanisms/HGGap.png", replace 
graph save "$analysis/Results/5.Mechanisms/HGGap.gph", replace 

* men, low FLFP  
********************************************************************************

local hh Female
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(90) post
est store  LeaverPerm


ta FemaleM0 if iio==1 

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Woman - men", size(medsmall))  level(90) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 90% confidence intervals." ///
 "Showing the differential impact between women and men, given the manager is a man." "The share of workers with a male manager is 66%.", span)
graph export "$analysis/Results/5.Mechanisms/HGGap.png", replace 
graph save "$analysis/Results/5.Mechanisms/HGGap.gph", replace 




