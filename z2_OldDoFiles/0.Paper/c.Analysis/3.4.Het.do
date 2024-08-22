********************************************************************************
* This dofile does heterogeneity analysis using at 60 months window 
********************************************************************************

global Label FT
use "$managersdta/AllSameTeam2.dta", clear 

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

*merge m:1 IDlse using  "$managersdta/Temp/Random25v.dta" // "$managersdta/Temp/Random10v.dta",
*drop _merge 
*rename random25 random
*keep if Ei!=. | random==1

* LABEL VARS
label var ChangeSalaryGradeC "Salary grade increase"
label var ChangeSalaryGradeSameMC "Salary grade increase, same manager"
label var ChangeSalaryGradeDiffMC "Salary grade increase, diff. manager"
label var PromWLC "Vertical move"
label var PromWLSameMC "Vertical move, same manager"
label var PromWLDiffMC "Vertical move, diff. manager"
label var PromWLVC "Vertical move"
label var TransferInternalC "Lateral move"
label var TransferInternalSameMC "Lateral move, same manager"
label var TransferInternalDiffMC "Lateral move, diff. manager"
label var TransferInternalLLC "Lateral move, lateral"
label var TransferInternalVC "Lateral move, vertical"
label var TransferSJC "Lateral move"
label var TransferSJSameMC "Lateral move, same manager"
label var TransferSJDiffMC "Lateral move, diff. manager"
label var TransferSJLLC "Lateral move, lateral"
label var TransferSJVC "Lateral move"
label var TransferFuncC "Lateral move, function"
label var TransferSubFuncC "Lateral move"
label var ONETDistanceBC "Task-distant move, ONET"
label var ONETDistanceC "Task-distant move, ONET"
label var ONETSkillsDistanceC "Task-distant move, ONET"
label var DiffField "Education-distant move, field"

label var LogPayBonus "Pay (logs)"

* tag manager and worker 
egen mm = tag(IDlseMHR)
egen iio = tag(IDlse)

*HET: BASELINE CHARS FOR HETEROGENEITY 
********************************************************************************

*HET: UFLP status flag for managers 
rename IDlse IDlse2
gen IDlse = IDlseMHR
merge m:1 IDlse YearMonth using "$managersdta/AllSnapshotMCultureMType.dta", keepusing(FlagUFLP )
drop if _merge ==2
ta _merge // 99% are matched 
drop _merge 
rename FlagUFLP FlagUFLPM
drop IDlse
rename IDlse2 IDlse 

* HET: ACROSS SUBFUNCTION AND FUNCTION 
bys IDlse: egen SubFuncPost = mean(cond(KEi ==36, SubFunc,.)) 
bys IDlse: egen SubFuncPre = mean(cond(KEi ==-1, SubFunc,.)) 
gen DiffSF = SubFuncPost!= SubFuncPre if SubFuncPost!=. & SubFuncPre!=. // 27% change SF

* HET: ACROSS HAVING DONE AT LEAST 1 LATERAL JOB TRANSFERS 
bys IDlse: egen TrPost1y = mean(cond(KEi ==12, TransferSJLLC,.)) 
bys IDlse: egen TrPost2y = mean(cond(KEi ==24, TransferSJLLC,.)) 
bys IDlse: egen TrPost3y = mean(cond(KEi ==36, TransferSJLLC,.)) 
bys IDlse: egen TrPre = mean(cond(KEi ==-1, TransferSJLLC,.)) 
gen DiffSJ1y = TrPost1y!= TrPre if TrPost1y!=. & TrPre!=. // 20% change JOB
gen DiffSJ2y = TrPost2y!= TrPre if TrPost2y!=. & TrPre!=. // 35% change JOB
gen DiffSJ3y = TrPost3y!= TrPre if TrPost3y!=. & TrPre!=. // 45% change JOB

* HET: ACROSS HAVING DONE AT LEAST 1 LATERAL JOB TRANSFERS 
bys IDlse: egen TrMPost1y = mean(cond(KEi ==12, TransferSJDiffMC,.)) 
bys IDlse: egen TrMPost2y = mean(cond(KEi ==24,  TransferSJDiffMC,.)) 
bys IDlse: egen TrMPost3y = mean(cond(KEi ==36,  TransferSJDiffMC,.)) 
bys IDlse: egen TrMPre = mean(cond(KEi ==-1,  TransferSJDiffMC,.)) 
gen DiffSJM1y = TrMPost1y!= TrMPre if TrMPost1y!=. & TrMPre!=. // 20% change JOB
gen DiffSJM2y = TrMPost2y!= TrMPre if TrMPost2y!=. & TrMPre!=. // 35% change JOB
gen DiffSJM3y = TrMPost3y!= TrMPre if TrMPost3y!=. & TrMPre!=. // 45% change JOB

* HET: remaining with same manager 
bys IDlse: egen MPost1y = mean(cond(KEi ==12, IDlseMHR,.)) 
bys IDlse: egen MPost2y = mean(cond(KEi ==24, IDlseMHR,.)) 
bys IDlse: egen MPost2hy = mean(cond(KEi ==30, IDlseMHR,.)) 
bys IDlse: egen MPost3y = mean(cond(KEi ==36, IDlseMHR,.)) 
bys IDlse: egen MPost5y = mean(cond(KEi ==60, IDlseMHR,.)) 
bys IDlse: egen MPre = mean(cond(KEi ==0, IDlseMHR,.)) 
gen DiffM1y = MPost1y!= MPre if MPost1y!=. & MPre!=. // 42%
gen DiffM2y = MPost2y!= MPre if MPost2y!=. & MPre!=. // 67%
gen DiffM3y = MPost3y!= MPre if MPost3y!=. & MPre!=. // 81%
gen DiffM5y = MPost5y!= MPre if MPost5y!=. & MPre!=. // 91%

* HET: indicator for 15-35 window of manager transition 
bys IDlse: egen m2y= max(cond(KEi ==-1 & MonthsSJM>=15 & MonthsSJM<=35,1,0))

* HET: average team performance before transition
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MType.dta", keepusing(AvPayGrowth  )
keep if _merge!=2
drop _merge 

bys IDlse: egen TeamPerf0 = mean(cond(KEi >=-24 & KEi<0,AvPayGrowth, .))
su TeamPerf0 if iio==1,d
gen TeamPerf0B = TeamPerf0 > `r(p50)' if TeamPerf0!=.

su TeamPerf0 if mm==1,d
gen TeamPerfM0B = TeamPerf0 > `r(p50)' if TeamPerf0!=.

* HET: worker performance 
xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus 
foreach var in PayGrowth { //  LogPayBonus VPA PayGrowth
	bys IDlse: egen `var'0 = mean(cond(KEi<=-1 & KEi >=-24, `var' , .))
	su `var'0 if iio==1,d
	gen WPerf0B = `var'0 > `r(p50)' if `var'0!=.
	gen WPerf0p10B = `var'0 <= `r(p10)' if `var'0!=.
	gen WPerf0p90B = `var'0 >= `r(p90)' if `var'0!=.
}

* p90 vs p10 worker baseline performance 
gen WPerf0p10p90B = 0 if WPerf0p10B==1
replace WPerf0p10p90B = 1 if WPerf0p90B ==1

* HET: heterogeneity by office size + tenure of manager + same gender + same nationality + same office + task distant func

* construct indicator for task distant function 
egen ff = tag(Func)
bys Func: egen avONET = mean( ONETDistance)
su avONET if ff==1 , d 
gen dFunc = avONET  >= r(p75) if avONET !=. // using the 75th percentile 
ta Func dFunc if ff==1 

* get baseline values 
foreach v in FlagUFLPM OfficeSize TenureM  SameGender SameNationality SameOffice SameCountry dFunc {
bys IDlse: egen `v'0= mean(cond( KEi ==0,`v',.))
}

* created binary indicators if needed 
su OfficeSize0 if iio==1, d 
gen OfficeSizeHigh0 = OfficeSize0> 300 if OfficeSize0!=.
bys EarlyAgeM: su TenureM0 if mm==1, d 
gen TenureMHigh0 = TenureM0>= 7 // median value for FT manager 

* HET: heterogeneity by age 
bys IDlse: egen Age0 = mean(cond(KEi==0,AgeBand,.))
gen Young0 = Age0==1 if Age0!=.

* HET: heterogeneity by tenure 
bys IDlse: egen Tenure0 = mean(cond(KEi==0,Tenure,.))
su Tenure0 if iio==1, d 
gen TenureLow0 = Tenure0 <=2 if Tenure0!=. 

* HET: labor law 
merge m:1 ISOCode Year using "$cleveldta/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF LaborRegWEFB) // /2.WB EmployingWorkers.dta ; 2.ILO EPLex.dta (EPLex )
keep if _merge!=2
drop _merge 

bys IDlse: egen LaborRegHigh0= mean(cond( KEi ==0,LaborRegWEFB,.))
 gen ISOCode0= ISOCode if KEi==0
 gen Country0= CountryS if KEi==0

preserve 
collapse LaborRegHigh0, by( ISOCode0 Country0) // LaborRegHigh0 LaborRegWEFC
export excel "$analysis/Results/5.Mechanisms/LaborLawCountry", replace 
restore 

* GENDER OF MANAGER
bys IDlse: egen FemaleM0= mean(cond( KEi ==0,FemaleM,.))

* gender norms
gen Cohort = AgeBand
merge m:1 ISOCode Cohort using "$cleveldta/3.WB FMShares Decade.dta", keepusing(FMShareWB FMShareEducWB)
drop if _merge==2
drop _merge  

egen cc= tag(ISOCode)
bys IDlse: egen FMShareWB0= mean(cond( KEi ==0,FMShareWB,.))
bys IDlse: egen FMShareEducWB0= mean(cond( KEi ==0,FMShareEducWB,.))

merge m:1 ISOCode Year using "$cleveldta/2.WB WBL.dta", keepusing(WBL Mobility Workplace Pay Marriage Parenthood  Entrepreneurship Assets Pension)
drop if _merge==2
drop _merge 
bys IDlse: egen WBL0= mean(cond( KEi ==0,WBL,.))

* Univoice 
merge m:1 IDlseMHR Year using "$managersdta/LMScore.dta", keepusing(LMScore)
drop _merge 
bys IDlse: egen LMScore0= mean(cond( KEi ==0,LMScore,.)) // taking the score of the LM 
gen HighLM0 = LMScore0 >4 if LMScore0!=.

********************************************************************************
* REGRESSIONS
********************************************************************************

* FM share categories 
su FMShareWB0, d 
local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)
gen FMShareWB0C = 1 if FMShareWB0<=`p25'
replace FMShareWB0C = 2 if FMShareWB0>`p25' & FMShareWB0<=`p50'
replace FMShareWB0C = 3 if FMShareWB0>`p50' & FMShareWB0<=`p75'
replace FMShareWB0C = 4 if FMShareWB0> `p75' & FMShareWB0!=.
tab FMShareWB0C, gen(FMShareWB0C)

su FMShareEducWB0, d
gen LowFLFP0 = 1 if FMShareEducWB0 <=0.89 // median 
replace LowFLFP0 = 0 if LowFLFP0 ==. & FMShareEducWB0 !=.

* job diversity - task distance 
bys Office YearMonth: egen JobDivOffice = mean(ONETSkillsDistanceC) 
bys IDlse: egen JobDivOffice0= mean(cond( KEi ==0,JobDivOffice,.))
su JobDivOffice0 if iio==1, d 
gen JobDiv0 = JobDivOffice0 > 0.05 if JobDivOffice0!=. 

egen oj = group(Office StandardJobE)
bys Office YearMonth: egen JobNumOffice = total(oj) 
bys IDlse: egen JobNumOffice0= mean(cond( KEi ==0,JobNumOffice,.))
su JobNumOffice0 if iio==1, d 
gen JobNum0 = JobNumOffice0 > `r(p50)' if JobNumOffice0!=. 

* constructing interaction variables
rename WPerf0B WPerf0
rename WPerf0p10p90B WPerf0p10p900
rename TeamPerf0B TeamPerfBase0
rename TeamPerfM0B TeamPerfMBase0
rename DiffM2y DiffM2y0
rename DiffSJ2y  DiffSJ2y0
rename DiffSJM3y  DiffSJM3y0

* gender of worker 
gen Female0 = Female 

foreach hh in Female FemaleM HighLM FlagUFLPM JobNum JobDiv LowFLFP DiffSJ2y DiffSJM3y  DiffM2y TeamPerfMBase   TeamPerfBase WPerf0p10p90 WPerf OfficeSizeHigh  LaborRegHigh  TenureMHigh TenureLow Young SameGender SameOffice{
foreach v in FTLHPost  FTHHPost   FTLLPost   FTHLPost{
gen `v'`hh'0= `v'*(1-`hh'0)
gen `v'`hh'1 = `v'*`hh'0
} 
} 

********************************************************************************
* Binary heterogeneity 
********************************************************************************

* (KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60)
* (KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==22 | KEi ==23 | KEi ==24)
* (KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==10 | KEi ==11 | KEi ==12) 

********************************************************************************
* LINE MANAGER SCORE (UNIVOICE)
********************************************************************************
/*
* Note that the data is at the manager and year level and it is only available since 2017, so maximum time window avaiable is 4 years 
* so consider window up at 3 years after 

local hh HighLM // JobDiv JobNum
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1
*su $hetCoeff if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==46 | KEi ==47 | KEi ==48 )
*su $hetCoeff if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==34 | KEi ==35 | KEi ==36)
*su $hetCoeff if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==22 | KEi ==23 | KEi ==24)

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==34 | KEi ==35 | KEi ==36), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==34 | KEi ==35 | KEi ==36 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta HighLM0 if iio==1 

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Worker assessment of manager (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 36 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between workers whose manager has an average score above or below 4." "The share of workers with a manager with an average score above 4 is 56%.", span)
graph export "$analysis/Results/5.Mechanisms/HFLMScore.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HFLMScore.gph", replace 

********************************************************************************
* MANAGER DID THE GRADUATE PROGRAMME 
********************************************************************************

local hh FlagUFLPM // JobDiv JobNum
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta FlagUFLPM0 if iio==1 

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Manager did graduate program (yes - no)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between workers whose manager did or did not do the graduate program." "The share of workers with a manager that did the graduate program is 4%.", span)
graph export "$analysis/Results/5.Mechanisms/HFlagUFLPM.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HJFlagUFLPM.gph", replace 
  
*xscale(range(-0.05 0.15)) xlabel(-0.05(0.01)0.05)
*/
********************************************************************************
* Manager above 7 years of tenure   
********************************************************************************

local hh TenureMHigh
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

local hh TenureMHigh
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Office##YearMonth##Func  AgeBand##Female  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta TenureMHigh0 if mm==1 

/*
**# ON PAPER FIGURE: HTenureME.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.1 0.4)) xlabel(-0.1(0.1)0.4) ///
 title("Manager tenure (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between having the manager with over and under 7 years of tenure." "The share of managers above 7 years of tenure is 77%.", span)
*COMMON SCALE option: *xscale(range(-0.1 0.5)) xlabel(-0.1(0.1)0.5)
graph export "$analysis/Results/0.Paper/3.4.Het/HTenureM.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HTenureM.gph", replace 
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 1)
estadd local label lc_1 "Manager tenure, high"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", replace ///
prehead("\begin{tabular}{l*{4}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{5}{c}{\textit{Panel (a): worker and manager characteristics}} \\\\[-1ex]") ///
fragment ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
nofloat nonotes collabels(none) noobs ///
keep(lc_1) label ///
mlabels("Pay increase" "Lateral moves" "Vertical moves" "Exit from firm")

********************************************************************************
* same office 
********************************************************************************

local hh SameOffice
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameOffice0 if iio==1

/*
**# ON PAPER FIGURE: HOfficeE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC, keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm , keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same office - different office", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the office with the manager." "The share of workers in the same office of manager is 71%.", span) 
*COMMON SCALE option: *xscale(range(-0.1 0.5)) xlabel(-0.1(0.1)0.5) 
graph export "$analysis/Results/0.Paper/3.4.Het/HOffice.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HOffice.gph", replace
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 2)
estadd local label lc_1 "Same office as manager"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1) 

********************************************************************************
* Young worker  
********************************************************************************

local hh Young
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta Young0 if iio==1 

/*
**# ON PAPER FIGURE: HYoungE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)  ///
 title("Worker age (below 30 - above 30)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between being under and over 30 years old." "The share of workers under 30 years old is 42%.", span)
*COMMON SCALE option: *xscale(range(-0.1 0.5)) xlabel(-0.1(0.1)0.5)
graph export "$analysis/Results/0.Paper/3.4.Het/HYoung.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HYoung.gph", replace 
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 3)
estadd local label lc_1 "Worker age, young"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
* Worker below 2 years of tenure   
********************************************************************************

local hh TenureLow
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta TenureLow0 if iio==1 

/*
**# ON PAPER FIGURE: HTenureE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.1 0.2)) xlabel(-0.1(0.05)0.2) ///
 title("Worker tenure (low - high)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between being under and over 2 years of tenure." "The share of workers under 2 years of tenure is 66%.", span)
*COMMON SCALE option: *xscale(range(-0.1 0.5)) xlabel(-0.1(0.1)0.5)
graph export "$analysis/Results/0.Paper/3.4.Het/HTenure.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HTenure.gph", replace 
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 4)
estadd local label lc_1 "Worker tenure, low"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
* same gender as manager 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC   { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==10 | KEi ==11 | KEi ==12), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

eststo PromWLC: reghdfe PromWLC $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==4 | KEi ==5 | KEi ==6), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  PromWLC

ta SameGender0 if iio==1 

/*
**# ON PAPER FIGURE: HGenderE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender", size(medsmall))  level(95) xline(0, lpattern(dash)) xscale(range(-0.05 0.15)) xlabel(-0.05(0.01)0.05) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager." "The share of workers sharing same gender with manager is 62%.", span)
*COMMON SCALE option: *xscale(range(-0.1 0.5)) xlabel(-0.1(0.1)0.5)
graph export "$analysis/Results/0.Paper/3.4.Het/HGender.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HGender.gph", replace 
*/ 

**# ON PAPER TABLE: HTableAll.tex (ROW 5)
estadd local label lc_1 "Same gender as manager"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
*office size   
********************************************************************************

local hh  OfficeSizeHigh
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta OfficeSizeHigh0 if iio==1

/*
**# ON PAPER FIGURE: HLargeOfficeE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.1 0.4)) xlabel(-0.1(0.1)0.4) ///
 title("Office size, number of workers (large - small)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between large and small offices (above and below median number of workers)." "The share of workers in offices with more than 300 workers (above median) is 55%.", span)
*COMMON SCALE option: xscale(range(-0.1 1)) xlabel(-0.1(0.1)1)
graph export "$analysis/Results/0.Paper/3.4.Het/HLargeOffice.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HLargeOffice.gph", replace 
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 6)
estadd local label lc_1 "Office size, large"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
posthead("\hline \\ \multicolumn{5}{c}{\textit{Panel (b): environment characteristics}} \\\\[-1ex]") ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
* JOB DIVERSITY AT THE OFFICE LEVEL  - number of jobs 
********************************************************************************

local hh JobNum // JobDiv JobNum
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta JobNum0 if iio==1 

/*
**# ON PAPER FIGURE: HJobNumE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Job diversity in the office (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between offices with high and low number of different jobs (above and below median)." "The share of workers in offices with above median number of different jobs is 50%.", span)
*COMMON SCALE option: xscale(range(-0.1 1)) xlabel(-0.1(0.1)1)
graph export "$analysis/Results/0.Paper/3.4.Het/HJobNum.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HJobNum.gph", replace 
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 7)
estadd local label lc_1 "Office job diversity, high"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
* JOB DIVERSITY AT THE OFFICE LEVEL  - job diversity (ONET)
********************************************************************************
/*
local hh JobDiv // JobDiv JobNum
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta JobDiv0 if iio==1 

coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Job diversity measured by tasks in the office (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between offices with high and low job diversity (above and below median)." "The share of workers in offices with above median job diversity is 44%." "Job diversity is measured as average task distance across jobs in each office using O*NET data.", span)
graph export "$analysis/Results/5.Mechanisms/HJobDiv.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HJobDiv.gph", replace 

********************************************************************************
* careers of women in countries with low FLFP 
********************************************************************************

local hh LowFLFP
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  TransferFuncC PromWLC  { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if Female==1 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if Female==1 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm


ta LowFLFP0 if iio==1 & Female ==1

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Female over male labor force participation (low - high), women only", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between women in countries with the female over male labor force participation ratio" "below and above median." "The share of women in countries with the female over male labor force participation ratio below median is 38%.", span)
graph export "$analysis/Results/5.Mechanisms/HFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HFLFP.gph", replace 

*xscale(range(-0.05 0.15)) xlabel(-0.05(0.01)0.05)
 
********************************************************************************
* careers of men in countries with low FLFP 
********************************************************************************

local hh  LowFLFP
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC  { // $Keyoutcome $other  TransferFuncC
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if Female==0 &   (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if  Female==0 &  (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta LowFLFP0 if iio==1 & Female ==0

* Female==1 & SameGender==1 >> positive (worse for equal countries)
* Female==0 & SameGender==1  >> negative (better for equal countries )
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Female over male labor force participation (low - high), men only", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between men in countries with the female over male labor force participation ratio" "below and above median." "The share of men in countries with the female over male labor force participation ratio below median is 46%.", span)
graph export "$analysis/Results/5.Mechanisms/HFLFPMen.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HFLFPMen.gph", replace 
*/

********************************************************************************
* Labor regulations     
********************************************************************************
 
local hh  LaborRegHigh
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta LaborRegHigh0 if iio==1
 
/*
**# ON PAPER FIGURE: HLawE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.1 0.4)) xlabel(-0.1(0.1)0.4) ///
 title("Stringency of country labor laws (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between countries having stricter and laxer labor laws (above and below median)." "The share of workers in countries with more stringent labor laws is 43%.", span)
*COMMON SCALE option: xscale(range(-0.1 1)) xlabel(-0.1(0.1)1)
graph export "$analysis/Results/0.Paper/3.4.Het/HLaw.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HLaw.gph", replace 
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 8)
estadd local label lc_1 "Labor laws, high"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
* gender gap and low FLFP
********************************************************************************

local hh   LowFLFP
global hetCoeff FTLHPost`hh'0##Female FTHLPost`hh'0##Female  FTLLPost`hh'0##Female  FTHHPost`hh'0##Female   ///
FTLHPost`hh'1##Female  FTHLPost`hh'1##Female  FTLLPost`hh'1##Female  FTHHPost`hh'1##Female 

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC  { // $Keyoutcome $other  TransferFuncC
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if  (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (1.FTLHPost`hh'1#1.Female - 1.FTLLPost`hh'1#1.Female - 1.FTLHPost`hh'0#1.Female + 1.FTLLPost`hh'0#1.Female) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (1.FTLHPost`hh'1#1.Female - 1.FTLLPost`hh'1#1.Female - 1.FTLHPost`hh'0#1.Female + 1.FTLLPost`hh'0#1.Female) , level(95) post
est store  LeaverPerm

ta LowFLFP0 if iio==1 

/*
**# ON PAPER FIGURE: HFLFPFemaleGapE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Female over male labor force participation (low - high), gender gap", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between the gender gap (women - men) in countries with the" "female over male labor force participation ratio below and above median." "The share of workers in countries with the female over male labor force participation ratio below median is 48%.", span)
*COMMON SCALE option: xscale(range(-0.1 1)) xlabel(-0.1(0.1)1)
graph export "$analysis/Results/0.Paper/3.4.Het/HFLFPFemaleGap.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HFLFPFemaleGap.gph", replace 
*/

/*
**# ON PAPER TABLE: HTableAll.tex (ROW 9)
estadd local label lc_1 "Low FLFP country, gender gap (F-M)"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)
*/

********************************************************************************
* WOMAN in low FLFP country: does it matter to have manager of same gender? 
********************************************************************************
/*
local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in  ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if LowFLFP0==1 & Female==1 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if LowFLFP0==1 & Female==1 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameGender0 if iio==1 & LowFLFP0==1 & Female==1

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender (women, low FLFP countries)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager for women in low FLFP." "The share of women in low FLFP countries sharing same gender with manager is 45%.", span)
graph export "$analysis/Results/5.Mechanisms/HGenderFemaleLowFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HGenderFemaleLowFLFP.gph", replace 

********************************************************************************
* WOMAN in high FLFP country: does it matter to have manager of same gender? 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in  ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if LowFLFP0==0 & Female==1 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if LowFLFP0==0 & Female==1 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameGender0 if iio==1 & LowFLFP0==0 & Female==1

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender (women, high FLFP countries)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager for women in high FLFP." "The share of women in high FLFP countries sharing same gender with manager is 47%.", span)
graph export "$analysis/Results/5.Mechanisms/HGenderFemaleHighFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HGenderFemaleHighFLFP.gph", replace 

********************************************************************************
* MEN in low FLFP country: does it matter to have manager of same gender? 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in  ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if LowFLFP0==1 & Female==0 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if LowFLFP0==1 & Female==0 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameGender0 if iio==1 & LowFLFP0==1 & Female==0

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender (men, low FLFP countries)", size(medsmall))  level(95) xline(0, lpattern(dash)) ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager for men in low FLFP." "The share of men in low FLFP countries sharing same gender with manager is 76%.", span)
graph export "$analysis/Results/5.Mechanisms/HGenderMaleLowFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HGenderMaleLowFLFP.gph", replace 
*xscale(range(-0.05 0.05)) xlabel(-0.05(0.01)0.05)

********************************************************************************
* MEN in high FLFP country: does it matter to have manager of same gender? 
********************************************************************************

local hh SameGender
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in  ChangeSalaryGradeC   TransferSJVC  TransferFuncC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'
eststo `y': reghdfe `y' $hetCoeff  if LowFLFP0==0 & Female==0 & (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y'
} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if LowFLFP0==0 & Female==0 & (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta SameGender0 if iio==1 & LowFLFP0==0 & Female==0

* PLOT 
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
  (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) ///
 title("Same gender - different gender (men, high FLFP countries)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between sharing and not sharing the gender with the manager for men in high FLFP." "The share of men in high FLFP countries sharing same gender with manager is 72%.", span)
graph export "$analysis/Results/5.Mechanisms/HGenderMaleHighFLFP.pdf", replace 
graph save "$analysis/Results/5.Mechanisms/HGenderMaleHighFLFP.gph", replace 

********************************************************************************
* Changed Job      
********************************************************************************

local hh DiffSJ2y
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta DiffSJ2y0 if iio==1
 
* No longer on paper figure: HDiffSJE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.2 0.2)) xlabel(-0.2(0.1)0.2) ///
 title("Job change within 2 years (yes - no)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
  "Showing the differential impact between workers changing and not changing job within 2 years of the manager transition." "The share of workers that change job within 2 years of the manager transition is 41%.", span)
*COMMON SCALE option: xscale(range(-1 0.5)) xlabel(-1(0.25)0.5)  
graph export "$analysis/Results/0.Paper/3.4.Het/HDiffSJ.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HDiffSJ.gph", replace 
*/

********************************************************************************
* worker performance   
********************************************************************************

local hh WPerf
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta WPerf0 if iio==1

/*
**# ON FIGURE FIGURE: HWPerfE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-1 0.5)) xlabel(-1(0.25)0.5) ///
 title("Worker past pay growth (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
"Showing the differential impact between better and worse performing workers at baseline." "The share of workers with above median pay growth in the 2 years preceding the manager change is 41%.", span)
*COMMON SCALE option: xscale(range(-1 0.5)) xlabel(-1(0.25)0.5)
graph export "$analysis/Results/0.Paper/3.4.Het/HWPerf.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HWPerf.gph", replace
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 9*)
estadd local label lc_1 "Worker performance, high (p50)"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
posthead("\hline \\ \multicolumn{5}{c}{\textit{Panel c: worker performance and moves}} \\\\[-1ex]") ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
* worker performance   
********************************************************************************

local hh  WPerf0p10p90
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta  WPerf0p10B  if iio==1
ta  WPerf0p90B  if iio==1

/*
**# ON PAPER FIGURE: HWPerfpE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off)  xscale(range(-1 0.5)) xlabel(-1(0.25)0.5) ///
 title("Worker past pay growth (p90- p10)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
"Showing the differential impact between the top 10% and the bottom 10% workers in terms performance at baseline." "Top 10% versus the bottom 10% of workers in terms of average pay growth in the 2 years before the manager transition.", span)
*COMMON SCALE option: xscale(range(-1 0.5)) xlabel(-1(0.25)0.5)
graph export "$analysis/Results/0.Paper/3.4.Het/HWPerfp.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HWPerfp.gph", replace
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 10*)
estadd local label lc_1 "Worker performance, high (p90)"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
* team performance   
********************************************************************************

local hh TeamPerfMBase
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1

eststo clear 
foreach  y in ChangeSalaryGradeC   TransferSJVC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( IDlse YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta TeamPerfMBase0 if iio==1

/*
**# ON PAPER FIGURE: HTeamE.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
 (TransferSJVC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) xscale(range(-0.4 0.4)) xlabel(-0.4(0.1)0.4) ///
 title("Team past pay growth (high - low)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
"Showing the differential impact between better and worse performing teams at baseline." "The share of workers in teams with above median pay growth in the 2 years preceding the manager change is 48%.", span)
*COMMON SCALE option: xscale(range(-1 0.5)) xlabel(-1(0.25)0.5)
graph export "$analysis/Results/0.Paper/3.4.Het/HTeam.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HTeam.gph", replace
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 11*)
estadd local label lc_1 "Team performance, high (p50)"

esttab ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat nonotes collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1)

********************************************************************************
* Changed Manager     
********************************************************************************

local hh DiffM2y
global hetCoeff FTLHPost`hh'0 FTHLPost`hh'0 FTLLPost`hh'0 FTHHPost`hh'0  ///
FTLHPost`hh'1 FTHLPost`hh'1 FTLLPost`hh'1 FTHHPost`hh'1
su $hetCoeff
eststo clear 
foreach  y in   ChangeSalaryGradeC  TransferSJLLC  PromWLC { // $Keyoutcome $other 
local lab: variable label `y'

eststo `y': reghdfe `y' $hetCoeff  if (WL2==1 ) & ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60), a( Country YearMonth  )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
lincom FTLHPost`hh'1 - FTLLPost`hh'1
lincom FTLHPost`hh'0 - FTLLPost`hh'0
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  `y' 

} 

* ( KEi ==-1 | KEi ==-2 | KEi ==-3 | KEi ==58 | KEi ==59 | KEi ==60)
eststo LeaverPerm: reghdfe LeaverPerm $hetCoeff  if (WL2==1 ) & (  KEi==0 | KEi ==58 | KEi ==59 | KEi ==60 ), a( Country YearMonth )  vce(cluster IDlseMHR) // if (WL2==1 & FMShareWB0C!=.) | ( Ei==. & random==1 ) 
xlincom  (FTLHPost`hh'1 - FTLLPost`hh'1 - FTLHPost`hh'0 + FTLLPost`hh'0) , level(95) post
est store  LeaverPerm

ta DiffM2y0 if iio==1
 
/*
**# ON PAPER FIGURE: HDiffME.png
coefplot  (ChangeSalaryGradeC , keep(lc_1) rename(  lc_1  = "Pay increase"))  ///
(TransferSJLLC, keep(lc_1) rename(  lc_1  = "Lateral moves"))  ///
  (PromWLC , keep(lc_1) rename(  lc_1  = "Vertical moves") ciopts(lwidth(2 ..) lcolor(cranberry)) )  ///
 (LeaverPerm, keep(lc_1) rename(  lc_1  = "Exit from firm") ciopts(lwidth(2 ..) lcolor(emerald)) )  ///
, ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) scale(0.96) legend(off) xscale(range(-0.25 0.25)) xlabel(-0.25(0.1)0.25) ///
 title("Manager change within 2 years (yes - no)", size(medsmall))  level(95) xline(0, lpattern(dash))  ///
 note("Notes. Looking at outcomes at 60 months after manager transition. Reporting 95% confidence intervals." ///
 "Showing the differential impact between workers changing and not changing the manager within 2 years of the transition." "The share of workers that change manager within 2 years is 71%.", span)
*COMMON SCALE option: xscale(range(-1 0.5)) xlabel(-1(0.25)0.5)
graph export "$analysis/Results/0.Paper/3.4.Het/HDiffM.pdf", replace 
graph save "$analysis/Results/0.Paper/3.4.Het/HDiffM.gph", replace
*/

**# ON PAPER TABLE: HTableAll.tex (ROW 12*)
estadd local label lc_1 "Manager change, post transition"

esttab ChangeSalaryGradeC TransferSJLLC PromWLC LeaverPerm using "$analysis/Results/0.Paper/3.4.Het/HTableAll.tex", ///
fragment ///
append ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
label nofloat collabels(none) noobs nolines nomtitles nonum ///
keep(lc_1) ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. An observation is a worker-year-month. 95\% confidence intervals used and standard errors are clustered by manager. Coefficients are estimated from a regression as in equation \ref{eq:het} and the figure reports the coefficient at the 20th quarter since the manager transition. Controls include worker FE and year months FE. Each row displays the differential heterogeneous impact of each respective variable. Panel (a): the first row looks at the differential impact between having the manager with over and under 7 years of tenure (the median tenure years for high-flyers managers); the second row looks at the differential impact between sharing and not sharing the office with the manager; the third row looks at the differential impact between being under and over 30 years old; the fourth row looks at the differential impact between being under and over 2 years of tenure; the fifth row looks at the differential impact between sharing and not sharing the same gender with the manager. Panel (b): the first row looks at the differential impact between large and small offices (above and below the median number of workers); the second row looks at the differential impact between offices with high and low number of different jobs (above and below median); the third row looks at the differential impact between countries having stricter and laxer labor laws (above and below median); the fourth row looks at the differential impact between the gender gap (women - men) in countries with the female over male labor force participation ratio above and below median. Panel (c): the first row looks at the differential impact between better and worse performing workers at baseline in terms of salary growth; the second row looks at the differential impact between the top 10\% and the bottom 10\% workers in terms of salary growth; the third row looks at the differential impact between better and worse performing teams at baseline in terms of salary growth; the fourth row looks at the differential impact between workers changing and not changing the manager 2 years after the transition." ///
"\end{tablenotes}")
