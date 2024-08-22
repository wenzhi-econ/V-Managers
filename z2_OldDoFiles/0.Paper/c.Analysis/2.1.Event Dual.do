********************************************************************************
* Dynamic TWFE model - Asymmetric
********************************************************************************

* Set globals 
********************************************************************************

* global analysis "${user}/Managers" // globals already defined in 0.0.Managers Master
do "$analysis/DoFiles/0.Paper/_CoeffProgram.do"

* choose the manager type !MANUAL INPUT!
global Label  FT  // PromWL75 PromSG75 PromWL50 PromSG50  FT odd  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 pay75F60
global typeM  EarlyAgeM  // EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 MFEBayesLogPayF6075 MFEBayesLogPayF7275 

global cont   c.TenureM##c.TenureM
* global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse   // alternative, to try WLM AgeBandM YearMonth AgeBand Tenure

* global analysis  "/Users/virginiaminni/Desktop/Managers Temp" // globals already defined in 0.0.Managers Master 

********************************************************************************
* EVENT INDICATORS 
********************************************************************************

* use "$managersdta/SwitchersAllSameTeam2.dta", clear 
use "$managersdta/AllSameTeam2.dta", clear

* Months in function
bys IDlse TransferFuncC: egen MonthsFunc =  count(YearMonth)
label var MonthsFunc "Tot. Months in Function"

* New hires only
gen TenureMin1 = TenureMin<1 
ta TenureMin
ta TenureMin1 if Ei!=. // retain how many workers? 53%

* Looking at the middle cohorts 
bys IDlse: egen MinAge = min(AgeBand)
label val MinAge AgeBand
format Ei %tm 
gen cohort30 = 1 if Ei >=tm(2014m1) & Ei <=tm(2018m12) // cohorts that have at least 36 months pre and after manager rotation 
gen cohort60 = 1 if Ei >=tm(2012m1) & Ei <=tm(2015m3) // if I cut the window, I can do 12 months pre and then 60 after 
gen cohortMiddle = 1 if Ei >=tm(2014m1) & Ei <=tm(2016m12) // cohorts that have at least 36 months pre and 60 after manager rotation 
gen cohortSingle = 1 if Ei <=tm(2014m12) // cohorts that have at least 36 months pre and 84 after manager rotation 
su cohortSingle cohortMiddle  Ei if WL2==1 // retain how many events? 
di 1198682/ 1756342 // .68248781

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

gen KEi  = YearMonth - Ei 

merge m:1 IDlse using  "$managersdta/Temp/Random50vw.dta" // "$managersdta/Temp/Random10v.dta" for exit, "$managersdta/Temp/Random50vw.dta" for all the rest
drop _merge 
rename random50 random
keep if Ei!=. | random==1 

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
local end = 36 // to be plugged in, window lenght 
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii
*keep if ii==1 | random10==1

egen CountryYear = group(Country Year)


* BASELINE MEAN 
********************************************************************************

* LL + LH - preferred and use 1 quarter 
foreach y in ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC TransferSJC {
	di "`y'"
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (FTLL!=.   | FTLH!=.  )  // 1 quarter 
*su `y' if (KEi == -1 ) &  (FTLL!=.   | FTLH!=.  )  // 1 month
*su `y' if (KEi <= -1 ) &  (FTLL!=.   | FTLH!=.  )  // all pre-periods 

}

* for exit average in month 0 (left out month) 
su LeaverPerm if (FTLL!=.   | FTLH!=.  ) & KEi ==0  

* ALL
foreach y in ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC TransferSJC{
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (FTLL!=.   | FTLH!=. | FTHH!=. | FTHL!=. )   // 1 quarter 
su `y' if (KEi == -1 ) &  (FTLL!=.   | FTLH!=. | FTHH!=. | FTHL!=.    )  // 1 month 
su `y' if (KEi <= -1 ) &  (FTLL!=.   | FTLH!=. | FTHH!=. | FTHL!=. )  // all pre-periods 

}

* HL + HH 
foreach y in ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC TransferSJC{
	di "`y'"
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (FTHL!=.   | FTHH!=.  )  // 1 quarter 
su `y' if (KEi == -1 ) &  (FTHL!=.   | FTHH!=.  )  // 1 month
su `y' if (KEi <= -1 ) &  (FTHL!=.   | FTHH!=.  )  // all pre-periods 

}

* ONLY LL
foreach y in ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC TransferSJC{
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (FTLL!=.    )  // 1 quarter 
su `y' if (KEi == -1 ) &  (FTLL!=.     ) // 1 month 
su `y' if (KEi <= -1 ) &  (FTLL!=.     )  // all pre-periods 
}

*HET: BASELINE CHARS FOR HETEROGENEITY 
********************************************************************************

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

* HET: remaining with same manager 
bys IDlse: egen MPost1y = mean(cond(KEi ==12, IDlseMHR,.)) 
bys IDlse: egen MPost2y = mean(cond(KEi ==24, IDlseMHR,.)) 
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
egen iio = tag(IDlse)
su TeamPerf0 if iio==1,d
gen TeamPerf0B = TeamPerf0 > `r(p50)' if TeamPerf0!=.

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
foreach v in OfficeSize TenureM  SameGender SameNationality SameOffice SameCountry dFunc {
bys IDlse: egen `v'0= mean(cond( KEi ==0,`v',.))
}

* created binary indicators if needed 
su OfficeSize0 , d 
gen OfficeSizeHigh0 = OfficeSize0>= r(p50)
bys EarlyAgeM: su TenureM0 , d 
gen TenureMHigh0 = TenureM0>= 7 // median value for FT manager 

* HET: heterogeneity by age 
bys IDlse: egen Age0 = mean(cond(KEi==0,AgeBand,.))
gen Young0 = Age0==1 if Age0!=.

* HET: labor law 
merge m:1 ISOCode Year using "$cleveldta/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF) // /2.WB EmployingWorkers.dta ; 2.ILO EPLex.dta (EPLex )
keep if _merge!=2
drop _merge 

bys ISOCode: egen LaborRegWEFC = mean(LaborRegWEF)
egen cc = tag(LaborRegWEF)
bys IDlse: egen LaborRegWEFC0= mean(cond( KEi ==0,LaborRegWEFC,.))
su LaborRegWEFC0 if cc==1, d 
gen LaborRegHigh0 =  LaborRegWEFC0 > `r(p50)' if LaborRegWEFC0!=.

* subfunction at baseline 
bys IDlse: egen SF0 = mean(cond(KEi==0, SubFunc, .))
bys IDlse: egen SJM0 = mean(cond(KEi==0, StandardJobCodeM, .))
* FLAG for workers take the place of the manager
gen TakeSJM = StandardJobCode==SJM0 if KEi>0 & WL2==1
bys IDlse: egen TakeSJMFraction = max(TakeSJM) // tagging all workers who take the place of the manager

* Variables for heterogeneity: DiffSJ; dFunc0; SameOffice0; SameCountry0; SameGender0; SameNationality0; WPerf0p10p90B;  DiffSF; TeamPerf0B; WPerf0B; TenureMHigh0; Young0; LaborRegWEFB; OfficeSizeHigh0
********************************************************************************

********************************************************************************
* EVENT DUMMIES
********************************************************************************

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}
* create leads and lags 
foreach var in EHL ELL EHH ELH {

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

* selecting only needed variables 
*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* if binning 
local endD = 84
foreach var in LL LH HL HH {
forval i=12(12)`endD'{
	gen endL`var'`i' = KE`var'>`i' & KE`var'!=.
	gen endF`var'`i' = KE`var'< -`i' & KE`var'!=.
}
}

local end = 60 // 36 60 
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

********************************* REGRESSIONS **********************************

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
label var ONETAbilitiesDistanceC "Task-distant move, ONET"
label var ONETSkillsDistanceC "Task-distant move, ONET"
label var DiffField "Education-distant move, field"

label var LogPayBonus "Pay (logs)"

* Same versus diff manager 
global diffM ChangeSalaryGradeDiffMC PromWLDiffMC  TransferInternalDiffMC TransferSJDiffMC // TransferInternalSJDiffMC
global sameM ChangeSalaryGradeSameMC PromWLSameMC  TransferInternalSameMC TransferSJSameMC // TransferInternalSJSameMC

********************************************************************************
* ASYMMETRIC WINDOW: 3 / 5 / 7 years 
********************************************************************************

* LOCALS
local end = 84 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local window = 169 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in 
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL36'/3 // 36 60 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

global cont  Country YearMonth TenureM##i.FemaleM  i.Tenure##Female
global Keyoutcome  ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC
global other ONETAbilitiesDistanceC // ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

* 1) separate values for salary
* 2) all other outcomes 
*log using "$analysis/Results/4.Event/Keyoutcome", replace 
*log using "$analysis/Results/4.Event/other", replace 
log using "$analysis/Results/4.Event/cohortSingle", replace 

foreach  y in  $Keyoutcome $other { // $Keyoutcome $other
* regression
********************************************************************************

* MAIN 
eststo: reghdfe `y' $event  if (WL2==1 | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

* MAIN ONET 
*eststo: reghdfe `y' $event   if (WL2==1 | (random==1) )   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC

* COHORT MIDDLE ROBUSTNESS 
*eststo: reghdfe `y' $event   if ( (WL2==1& cohortSingle==1) | (random==1 & Ei==.) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 
* ta cohortSingle if Ei!=. // 53%

* NEW HIRE ROBUSTNESS
*eststo: reghdfe `y' $event   if ( (WL2==1& TenureMin<=1) | (random==1 & Ei==.) )   , a( IDlse YearMonth   )  vce(cluster IDlseMHR) 
* ta TenureMin1 if Ei!=. // 53%

* CONGESTION ROBUSTNESS: take out workers who take the exact position of the manager 
*eststo: reghdfe `y'  $event  if ( (WL2==1 &TakeSJMFraction==0) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

local lab: variable label `y'

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`endF36') y(`y')
su joint
local joint = round(r(mean), 0.001)

* Monthly: 36 / 84
 tw scatter b1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'")
graph save  "$analysis/Results/4.Event/`Label'`y'Dual84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual84.pdf", replace

* Quarterly
coeffQ, c(`window') y(`y') // program 

* 36 / 36 
postDual , end(`endL36') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ36.pdf", replace

* 36 / 60
postDual , end(`endL60') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)

**# ON PAPER FIGURE: FTChangeSalaryGradeCDualQ5.pdf
* ON PAPER FIGURE: FTPromWLCDualQ5.pdf
* ON PAPER FIGURE: FTTransferSJVCDualQ5.pdf
* ON PAPER FIGURE: FTTransferFuncCDualQ5.pdf
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'DualQ60.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'DualQ60.pdf", replace

* 36 / 84
postDual , end(`endL84') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)

tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ84.pdf", replace

/* single differences 
********************************************************************************

* monthly: 36 / 84
coeff1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrend , end(`endF36') y(`y')
su jointL
local jointL = round(r(mean), 0.001)
su jointH 
local jointH = round(r(mean), 0.001)

tw scatter bL1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH84.pdf", replace

tw scatter bH1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`endF36' & et1<=`endL84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF36'(3)`endL84') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL84.pdf", replace

* quarterly
coeffQ1, c(`window') y(`y') type(`Label') // program 

* 36 / 36 
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace

* 36 / 60
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'EHLQ60.pdf", replace

* 36 / 84
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'ELHQ84.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ84.pdf", replace
*/
}

log close 

********************************************************************************
* EXIT 
********************************************************************************

*LABEL VARS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"
global exitFE   Country YearMonth // Func  AgeBand

**************************** REGRESSIONS ***************************************

* LOCALS
local end = 84 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

global event $LExitLH  $LExitLL  $LExitHL  $LExitHH 

local window = 169 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in 
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL36'/3 // 36 60 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

foreach  y in LeaverPerm LeaverVol  LeaverInv { // LeaverVol LeaverInv LeaverPerm LeaverVol   LeaverInv 

* MAIN 
eststo: reghdfe `y' $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) //  ( (WL2==1  )) &   | (random==1 & Ei==.)

* MIDDLE COHORT ROBUSTNESS 
*eststo: reghdfe `y' $event  if   KEi>-1 & WL2==1 & cohortSingle==1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // | (random==1 & Ei==.) 

* NEW HIRES ROBUSTNESS
*eststo: reghdfe `y' $event  if   KEi>-1 & WL2==1 & TenureMin<1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // | (random==1 & Ei==.) 

local lab: variable label `y'

* double differences  &
*********************************************************************************

coeffExit, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

* Monthly: 0 / 60
 tw scatter b1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(3)`endL60')  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual60.pdf", replace

* quarterly
coeffExitQ, c(`window') y(`y') // program 

* 0 / 36
 tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ36.pdf", replace

* 0 / 60 
 tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ60.pdf", replace

* 0 / 84
**# ON PAPER FIGURE: FTLeaverPermDualQ7.pdf
 tw scatter bQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) 
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'DualQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'DualQ84.pdf", replace

/* single differences 
*********************************************************************************
coeffExit1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* 0/60
 tw scatter bL1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endL60') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELH60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH60.pdf", replace

 tw scatter bH1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=0 & et1<=`endL60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endL60') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHL60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL60.pdf", replace

* quarterly
coeffExitQ1, c(`window') y(`y') type(`Label') // program 

* 0/84
**# ON PAPER FIGURE: FTLeaverPermELHQ7.pdf
* ON PAPER FIGURE: FTLeaverVolELHQ7.pdf
* ON PAPER FIGURE: FTLeaverInvELHQ7.pdf
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'ELHQ84.pdf", replace

**# ON PAPER FIGURE: FTLeaverPermEHLQ7.pdf (RUN THE CODE TO CHANGE TO 20 QUARTERS)
* ON PAPER FIGURE: FTLeaverVolEHLQ7.pdf
* ON PAPER FIGURE: FTLeaverInvEHLQ7.pdf
tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ84', lcolor(ebblue) 
yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ84') ///
xtitle("Quarters since manager change") title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon))
graph save  "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/0.Paper/2.1.Event Dual/`Label'`y'EHLQ84.pdf", replace

* 0/60
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ60.pdf", replace

* 0/36
tw scatter bQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=0 & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace
*/
} 


/********************************************************************************
* HETEROGENEITY 
********************************************************************************

* LOCALS
local end = 84 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local window = 169 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in 
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL36'/3 // 36 60 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

global cont  Country YearMonth TenureM##i.FemaleM  i.Tenure##Female
global Keyoutcome PromWLC ChangeSalaryGradeC  TransferSJVC TransferFuncC
global other ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

keep if (WL2==1 | random10==1)

* left out: SameNationality0 DiffM5y SameCountry0  dFunc0
global HET   DiffSJ2y // DiffSJ3y Young0 WPerf0p10p90B WPerf0B TeamPerf0B TenureMHigh0 SameGender0  SameOffice0 DiffM3y  OfficeSizeHigh0  LaborRegHigh0 DiffSF   

local h ""
foreach het in  $HET {
foreach  y in ChangeSalaryGradeC  TransferSJVC PromWLC   { // $Keyoutcome $other
* regression
********************************************************************************

*eststo: reghdfe `y' $event   if (WL2==1)   , a( IDlse YearMonth    )  vce(cluster IDlseMHR) // this regressions is for:  TransferSJ but it is not used as I decided to use TransferSJVC

*eststo: reghdfe `y' $event   if (WL2==1)   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC

eststo: reghdfe `y'  $event   if (WL2==1 & `het'==0) | (random10==1  ) , a( IDlse YearMonth  )  vce(cluster IDlseMHR) // this regression is for all other outcomes

* quarterly
coeffQH1, c(`window') y(`y') type(`Label') het(`het') b(0) // program 

eststo: reghdfe `y'  $event   if (WL2==1 & `het'==1) | (random10==1) , a( IDlse YearMonth  )  vce(cluster IDlseMHR) // this regression is for all other outcomes
* quarterly
coeffQH1, c(`window') y(`y') type(`Label') het(`het') b(1) // program 

* single differences 
********************************************************************************
local lab: variable label `y'

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* quarterly

* 36 / 36 
tw scatter bQL`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || scatter bQL`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ36', lcolor(orange) mcolor(orange) ///
|| rcap loQL`het'01 hiQL`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ36', lcolor(ebblue) || rcap loQL`het'11 hiQL`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ36', lcolor(orange) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High"))  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'ELHQ36.pdf", replace

tw scatter bQH`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ36', lcolor(ebblue) mcolor(ebblue) ///
|| scatter bQH`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ36', lcolor(orange) mcolor(orange) ///
 || rcap loQH`het'01 hiQH`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ36', lcolor(ebblue) ///
  || rcap loQH`het'11 hiQH`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ36', lcolor(orange) ///
yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High")) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'EHLQ36.pdf", replace

* 36 / 60
tw scatter bQL`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || scatter bQL`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ60', lcolor(orange) mcolor(orange) ///
|| rcap loQL`het'01 hiQL`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ60', lcolor(ebblue) || rcap loQL`het'11 hiQL`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ60', lcolor(orange) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High"))  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'ELHQ60.pdf", replace

tw scatter bQH`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ60', lcolor(ebblue) mcolor(ebblue) ///
|| scatter bQH`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ60', lcolor(orange) mcolor(orange) ///
 || rcap loQH`het'01 hiQH`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ60', lcolor(ebblue) ///
  || rcap loQH`het'11 hiQH`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ60', lcolor(orange) ///
yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High")) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'EHLQ60.pdf", replace

* 36 / 84
tw scatter bQL`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ84', lcolor(ebblue) mcolor(ebblue) || scatter bQL`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ84', lcolor(orange) mcolor(orange) ///
|| rcap loQL`het'01 hiQL`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ84', lcolor(ebblue) || rcap loQL`het'11 hiQL`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ84', lcolor(orange) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High"))  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'ELHQ84.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'ELHQ84.pdf", replace

tw scatter bQH`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ84', lcolor(ebblue) mcolor(ebblue) ///
|| scatter bQH`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ84', lcolor(orange) mcolor(orange) ///
 || rcap loQH`het'01 hiQH`het'01 etQL`het'01 if etQL`het'01>=-`endFQ36' & etQL`het'01<=`endLQ84', lcolor(ebblue) ///
  || rcap loQH`het'11 hiQH`het'11 etQL`het'11 if etQL`het'11>=-`endFQ36' & etQL`het'11<=`endLQ84', lcolor(orange) ///
yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ84') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High")) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon))  
graph save  "$analysis/Results/4.Event/`het'`Label'`y'EHLQ84.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'EHLQ84.pdf", replace
}
}

********************************************************************************
* HET EXIT 
********************************************************************************

*LABEL VARS
label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"
global exitFE   Country YearMonth // Func  AgeBand

**************************** REGRESSIONS ***************************************

* LOCALS
local end = 60 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
*global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local window = 121 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in 
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL36'/3 // 36 60 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

local h ""
foreach het in   DiffSJ3y SameOffice0 DiffM3y  { // $HET
foreach  y in LeaverPerm  { // LeaverVol LeaverInv eaverPerm

eststo: reghdfe `y' $event  if ( (WL2==1 & cohort30==1 & `het'==0 ) |random10==1) & KEi>-1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // c.Tenure##i.Female
local lab: variable label `y'
coeffExitQH1, c(`window') y(`y') type(`Label')  het(`het') b(0) // program 

eststo: reghdfe `y' $event  if ( (WL2==1 & cohort30==1 & `het'==1 ) |random10==1) & KEi>-1 , a( Office##YearMonth##Func  AgeBand##Female    ) vce(cluster IDlseMHR) // c.Tenure##i.Female
coeffExitQH1, c(`window') y(`y') type(`Label')  het(`het') b(1) // program 


* single differences 
********************************************************************************

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

* quarterly

* 0/60
tw scatter bQL`het'01 etQL`het'01 if etQL`het'01>=0 & etQL`het'01<=`endLQ60', lcolor(ebblue) mcolor(ebblue) ///
|| scatter bQL`het'11 etQL`het'11 if etQL`het'11>=0 & etQL`het'11<=`endLQ60', lcolor(orange) mcolor(orange) ///
|| rcap loQL`het'01 hiQL`het'01 etQL`het'01 if etQL`het'01>=0 & etQL`het'01<=`endLQ60', lcolor(ebblue) ///
|| rcap loQL`het'11 hiQL`het'11 etQL`het'11 if etQL`het'11>=0 & etQL`het'11<=`endLQ60', lcolor(orange) ///
 yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High"))  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'ELHQ60.pdf", replace

tw scatter bQH`het'01 etQL`het'01 if etQL`het'01>=0 & etQL`het'01<=`endLQ60', lcolor(ebblue) mcolor(ebblue) ///
|| scatter bQH`het'11 etQL`het'11 if etQL`het'11>=0 & etQL`het'11<=`endLQ60', lcolor(orange) mcolor(orange) ///
|| rcap loQH`het'01 hiQH`het'01 etQL`het'01 if etQL`het'01>=0 & etQL`het'01<=`endLQ60', lcolor(ebblue) ///
|| rcap loQH`het'11 hiQH`het'11 etQL`het'11 if etQL`het'11>=0 & etQL`het'11<=`endLQ60', lcolor(orange) ///
yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High"))  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'EHLQ60.pdf", replace

* 0/36
tw scatter bQL`het'01 etQL`het'01 if etQL`het'01>=0 & etQL`het'01<=`endLQ36', lcolor(ebblue) mcolor(ebblue) ///
|| scatter bQL`het'11 etQL`het'11 if etQL`het'11>=0 & etQL`het'11<=`endLQ36', lcolor(orange) mcolor(orange) ///
|| rcap loQL`het'01 hiQL`het'01 etQL`het'01 if etQL`het'01>=0 & etQL`het'01<=`endLQ36', lcolor(ebblue) ///
|| rcap loQL`het'11 hiQL`het'11 etQL`het'11 if etQL`het'11>=0 & etQL`het'11<=`endLQ36', lcolor(orange) ///
 yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High"))  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'ELHQ36.pdf", replace

tw scatter bQH`het'01 etQL`het'01 if etQL`het'01>=0 & etQL`het'01<=`endLQ36', lcolor(ebblue) mcolor(ebblue) ///
|| scatter bQH`het'11 etQL`het'11 if etQL`het'11>=0 & etQL`het'11<=`endLQ36', lcolor(orange) mcolor(orange) ///
|| rcap loQH`het'01 hiQH`het'01 etQL`het'01 if etQL`het'01>=0 & etQL`het'01<=`endLQ36', lcolor(ebblue) ///
|| rcap loQH`het'11 hiQH`het'11 etQL`het'11 if etQL`het'11>=0 & etQL`het'11<=`endLQ36', lcolor(orange) ///
yline(0, lcolor(maroon)) xline(0, lcolor(maroon)) xlabel(0(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(order(1 "Low" 2 "High"))  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) 
graph save  "$analysis/Results/4.Event/`het'`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`het'`Label'`y'EHLQ36.pdf", replace
} 
}

************************************************************************
* BALANCED SAMPLE
************************************************************************

* LOCALS
local end = 60 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local window = 121 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF12 = 12 // 12 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in 
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL36'/3 // 36 60 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

global cont  Country YearMonth TenureM##i.FemaleM  i.Tenure##Female
global Keyoutcome PromWLC ChangeSalaryGradeC  TransferSJC TransferSJVC TransferFuncC
global other ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

keep if (WL2==1 | random10==1)

* 1) separate values for salary
* 2) all other outcomes 

foreach  y in $Keyoutcome { // $Keyoutcome $other Ei >=tm(2014m1) & Ei <=tm(2018m12)
* regression
********************************************************************************

*eststo: reghdfe `y' $event   if (WL2==1)   , a( IDlse YearMonth    )  vce(cluster IDlseMHR) // this regressions is for:  TransferSJ but it is not used as I decided to use TransferSJVC

*eststo: reghdfe `y' $event   if (WL2==1)   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC

eststo: reghdfe `y'  $event   if ( (WL2==1 &  Ei >=tm(2014m1) & Ei <=tm(2016m12)) | random10==1 )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) // this regression is for all other outcomes
local lab: variable label `y'

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`endF36') y(`y')
su joint
local joint = round(r(mean), 0.001)

* Quarterly
coeffQ, c(`window') y(`y') // program 

* 36 / 36 
postDual , end(`endL36') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQB.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQB.pdf", replace


* single differences 
********************************************************************************

* monthly: 36 / 84
coeff1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrend , end(`endF36') y(`y')
su jointL
local jointL = round(r(mean), 0.001)
su jointH 
local jointH = round(r(mean), 0.001)



* quarterly
coeffQ1, c(`window') y(`y') type(`Label') // program 

* 36 / 36 
tw scatter bQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQB.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQB.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ36' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ36'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQB.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQB.pdf", replace

}

************************************************************************
* SALARY 
************************************************************************

* LOCALS
local end = 60 // 36 60 84
* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

local window = 121 // 73 121 169  to be plugged in
local end = 36 // 36 60 to be plugged in 
local endF12 = 12 // 12 36 60 to be plugged in 
local endF36 = 36 // 12 36 60 to be plugged in 
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 

local endFQ12 = `endF12'/3 // 36 60 to be plugged in 
local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL36'/3 // 36 60 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 

local endQ= `end'/3
local Label $Label

global cont  Country YearMonth TenureM##i.FemaleM  i.Tenure##Female
global Keyoutcome PromWLC ChangeSalaryGradeC  TransferSJC TransferSJVC TransferFuncC
global other ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus

keep if (WL2==1 | random10==1)

* 1) separate values for salary
* 2) all other outcomes 

foreach  y in LogPayBonus { // $Keyoutcome $other Ei >=tm(2014m1) & Ei <=tm(2018m12)
* regression
********************************************************************************

*eststo: reghdfe `y' $event   if (WL2==1)   , a( IDlse YearMonth    )  vce(cluster IDlseMHR) // this regressions is for:  TransferSJ but it is not used as I decided to use TransferSJVC

*eststo: reghdfe `y' $event   if (WL2==1)   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  ONETDistanceBC ONETSkillsDistanceBC ONETAbilitiesDistanceBC ONETDistanceC ONETSkillsDistanceC ONETAbilitiesDistanceC
eststo: reghdfe `y'  $event  if (WL2==1 | random10==1)   , a( IDlse YearMonth  )  vce(cluster IDlseMHR) // this regression is for all other outcomes
local lab: variable label `y'

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`endF12') y(`y')
su joint
local joint = round(r(mean), 0.001)

* Quarterly
coeffQ, c(`window') y(`y') // program 

* 12 / 36 
postDual , end(`endL36') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ12'(2)`endLQ36') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ36.pdf", replace

* 12 / 60
postDual , end(`endL60') y(`y')
su jointPost
local jointPost = round(r(mean), 0.001)
 tw scatter bQ1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ12'(2)`endLQ60') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'" "Post coeffs. joint p-value = `jointPost'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ60.pdf", replace


* single differences 
********************************************************************************

* monthly: 36 / 36
coeff1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrend , end(`endF12') y(`y')
su jointL
local jointL = round(r(mean), 0.001)
su jointH 
local jointH = round(r(mean), 0.001)


* quarterly
coeffQ1, c(`window') y(`y') type(`Label') // program 

* 12 / 36 
tw scatter bQL1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ12'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ36.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ36', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ36', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ12'(2)`endLQ36') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ36.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ36.pdf", replace


* 12 / 60 
tw scatter bQL1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ12'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ60.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ60', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ12' & etQ1<=`endLQ60', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ12'(2)`endLQ60') ///
xtitle(Quarters since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ60.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ60.pdf", replace

}

/********************************************************************************
* 5 YEARS 
********************************************************************************

* LOCALS
xtset IDlse YearMonth 

local end = 36 // 36 60 to be plugged in 
local endF = 12 // 36 60 to be plugged in 
local endL = 60 // 36 60 to be plugged in 
local endFQ = `endF'/3 // 36 60 to be plugged in 
local endLQ = `endL'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local window = 73 // 73 121 to be plugged in
local Label $Label

global cont  Country YearMonth TenureM##i.FemaleM  i.Tenure##Female
global Keyoutcome PromWLC ChangeSalaryGradeC ONETDistanceBC ONETDistanceC TransferSJC TransferFuncC MonthsFunc 

keep if (WL2==1 | random10==1)

foreach  y in     PromWLC ChangeSalaryGradeC ONETDistanceBC ONETDistanceC TransferFuncC MonthsFunc  { 
* regression
********************************************************************************

*eststo: reghdfe `y' $event   if (WL2==1 )   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR) // this regressions is for:  TransfersSJ 

eststo: reghdfe `y'  $event   if (WL2==1 | random10==1 )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) // this regression is for all other outcomes: TransferSJC MonthsSubFunc MonthsFunc  TransferSJLLC TransferInternalLLC  TransferFuncC TransferInternalC ONETDistanceC TransferInternalVC TransferInternalDiffMC TransferSJDiffMC TransferInternalSameMC TransferSJSameMC

local lab: variable label `y'

* double differences 
********************************************************************************

* monthly
coeff, c(`window') y(`y') // program 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)

pretrendDual , end(`end') y(`y')
su joint
local joint = round(r(mean), 0.001)

 tw scatter b1 et1 if et1>=-`endF' & et1<=`endL', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`endF' & et1<=`endL', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF'(3)`endL') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'")
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.pdf", replace

* quarterly
coeffQ, c(`window') y(`y') // program 

 tw scatter bQ1 etQ1 if etQ1>=-`endFQ' & etQ1<=`endLQ', lcolor(ebblue) mcolor(ebblue) || rcap loQ1 hiQ1 etQ1 if etQ1>=-`endFQ' & etQ1<=`endLQ', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ'(2)`endLQ') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`joint'")
graph save  "$analysis/Results/4.Event/`Label'`y'DualQ.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'DualQ.pdf", replace

* single differences 
********************************************************************************

* monthly
coeff1, c(`window') y(`y') type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

pretrend , end(`end') y(`y')
su jointL
local jointL = round(r(mean), 0.001)
su jointH 
local jointH = round(r(mean), 0.001)

tw scatter bL1 et1 if et1>=-`endF' & et1<=`endL', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`endF' & et1<=`endL', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF'(3)`endL') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.pdf", replace

tw scatter bH1 et1 if et1>=-`endF' & et1<=`endL', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`endF' & et1<=`endL', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endF'(3)`endL') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.pdf", replace


* quarterly
coeffQ1, c(`window') y(`y') type(`Label') // program 

tw scatter bQL1 etQ1 if etQ1>=-`endFQ' & etQ1<=`endLQ', lcolor(ebblue) mcolor(ebblue) || rcap loQL1 hiQL1 etQ1 if etQ1>=-`endFQ' & etQ1<=`endLQ', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ'(2)`endLQ') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  ylabel(0 "0(`ymeanF1L')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELHQ.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELHQ.pdf", replace

tw scatter bQH1 etQ1 if etQ1>=-`endFQ' & etQ1<=`endLQ', lcolor(ebblue) mcolor(ebblue) || rcap loQH1 hiQH1 etQ1 if etQ1>=-`endFQ' & etQ1<=`endLQ', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`endFQ'(2)`endLQ') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) ylabel(0 "0(`ymeanF1H')", add custom labcolor(maroon)) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHLQ.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHLQ.pdf", replace
}

/*
////////////////////////////////////////////////////////////////////////////////
* 2) 12 months window - PAY
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

local end = 24 // to be plugged in 
local window = 49 // to be plugged in 


* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii
*keep if ii==1

keep if LogPayBonus!=.
*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

foreach var in EHL ELL EHH ELH {

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen endL`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen endF`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

********************************* REGRESSIONS **********************************

*LABEL VARS
label var LogPayBonus "Pay + bonus (logs)"

egen CountryYear = group(Country Year)

local Label $Label 
foreach  y in   LogPayBonus {
eststo: reghdfe `y' $event $cont if WLM2==1 , a( $abs  ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.pdf", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.pdf", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.pdf", replace
}

////////////////////////////////////////////////////////////////////////////////
* 3) 12 months window - VPA
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

local end = 12 // to be plugged in 
local window = 25 // to be plugged in 

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

foreach var in EHL ELL EHH ELH {

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}

}
* Other outcomes 
gen VPA100 = VPA>=100 if VPA!=.
gen VPA115 = VPA>=115 if VPA!=.

*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen endL`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen endF`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

********************************* REGRESSIONS **********************************

*LABEL VARS
label var VPA "Perf. Appraisals"
label var VPA100 "Perf. Appraisals>=100"
label var VPA115 "Perf. Appraisals>=115"
label var VPA125 "Perf. Appraisals>=125"

egen CountryYear = group(Country Year)
local Label $Label
foreach  y in VPA VPA100 VPA115 VPA125 {
eststo: reghdfe `y' $event $cont if WLM2==1 , a( $abs   ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.pdf", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.pdf", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.pdf", replace
}

////////////////////////////////////////////////////////////////////////////////
* 4) 12 months window - PRODUCTIVITY
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

local end = 12 // to be plugged in 
local window = 25 // to be plugged in 

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}

foreach var in EHL ELL EHH ELH {

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}
}

*keep IDlse YearMonth IDlseMHR L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH Ei  ELH EHH ELL EHL KEi KELL KELH KEHH KEHL Country Year CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow PromWLC   PromWLVC  ChangeSalaryGradeC TransferInternalLLC TransferInternalVC TransferFuncC TransferSubFunc TransferSubFuncC TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC TransferFuncC  LeaverPerm LeaverVol LeaverInv  VPA  LogPayBonus 

* Bin the event window 
foreach var in LL LH HL HH {
	gen endL`var'`end' = KE`var'>`end'  & KE`var'!=.
	gen endF`var'`end'  = KE`var'< -`end'  & KE`var'!=.
}

* create list of event indicators if binning 
eventd, end(`end')

*global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

********************************* REGRESSIONS **********************************

*LABEL VARS
label var ProductivityStd "Productivity (standardized)"

egen CountryYear = group(Country Year)
local Label $Label
foreach  y in   ProductivityStd {
eststo: reghdfe `y' $event $cont, a( $abs   ) vce(cluster IDlseMHR)
local lab: variable label `y'

* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/`Label'`y'Dual.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'Dual.pdf", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pre-trends joint p-value=`jointL'")
graph save  "$analysis/Results/4.Event/`Label'`y'ELH.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'ELH.pdf", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(2)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon)) ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pre-trends joint p-value=`jointH'")
graph save  "$analysis/Results/4.Event/`Label'`y'EHL.gph", replace
graph export "$analysis/Results/4.Event/`Label'`y'EHL.pdf", replace
}
*/
