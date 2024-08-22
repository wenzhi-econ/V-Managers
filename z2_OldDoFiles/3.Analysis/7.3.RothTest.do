********************************************************************************
* This dofile computes the diagnostic checks for pre-tre tests as in Jonathan Roth 
* https://www.youtube.com/watch?v=F8C1xaPoRvM
* 2 papers: "pre-test with caution" in AER insights and then the follow up paper "a more credible approach to   pre-tests" 
* both packages just rely on coeff estimates and var-cov matrix, not on running regressions again
* there is also shiny app where you input the above 
* pre trends package: evaluate the likely distortions from pre testing under context relevant violations of parallel trends
 
********************************************************************************
* Set globals 
********************************************************************************

global analysis "${user}/Managers"
do "$user/Managers/DoFiles/4.Event/_CoeffProgram.do"

* choose the manager type !MANUAL INPUT!
global Label  FT  // PromWL75 PromSG75 PromWL50 PromSG50  FT odd  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 pay75F60
global typeM  EarlyAgeM  // EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 MFEBayesLogPayF6075 MFEBayesLogPayF7275 

global cont   c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse   // alternative, to try WLM AgeBandM YearMonth AgeBand Tenure

global analysis  "/Users/virginiaminni/Desktop/Managers Temp" // temp for the results 

********************************************************************************
* EVENT INDICATORS 
********************************************************************************

*use "$managersdta/SwitchersAllSameTeam2.dta", clear 
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

gen KEi  = YearMonth - Ei 

merge m:1 IDlse using  "$managersdta/Temp/Random50vw.dta" // "$managersdta/Temp/Random10v.dta" for exit, "$managersdta/Temp/Random50vw.dta" for all the rest
drop _merge 
rename random50 random
keep if Ei!=. | random==1 

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

********************************************************************************
* REGRESSIONS 
********************************************************************************

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
global Keyoutcome  ChangeSalaryGradeC PromWLC TransferSJVC TransferFuncC ProbJobV
global other ONETSkillsDistanceC   
global nogood  TransferSJC MonthsFunc  LogPayBonus 

* same as paper 
foreach  y in ChangeSalaryGradeC  { // $Keyoutcome $other

eststo: reghdfe `y'  $FLH  $LLH   $FLL $LLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a(  IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes (WL2==1 | ( Ei==. & random==1) )

}

* faster, no random + window: [-60 and +60] 
eststo: reghdfe  ChangeSalaryGradeC   $FLH  $LLH   $FLL $LLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) )  , a(  IDlse YearMonth  )  vce(cluster IDlseMHR)

********************************************************************************
* SENSITIVITIES 
********************************************************************************
* Command requires to insert: indices of pre and post coefficients, choice of bound, vector of coefficients 
* it uses the latest regression output 

* this is for 84 window 
/*matrix l_vec = 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ /// 
			   0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ ///
			   0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ ///
			   1 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ ///
			   0 \ 0 \ 0 \ 0 \ 0 \ 0
			   */
* only use coefficient at 60 months 			   
matrix l_vec = 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ /// 
			   0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ ///
			   0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ 0 \ ///
			   1 \ 0 
			   
* Sensitivity 1: magnitudes bound 
*local plotopts xtitle(Mbar) ytitle(95% Robust CI)
*honestdid, pre(1/84) post(1/86) mvec(0.5(0.5)2) coefplot `plotopts' // use option "cached" to use the last results from honestdid (which are cached in memory)

* Sensitivity 2: smoothness bounds for the coeff. at time 60
local plotopts xtitle(M) ytitle(95% Robust CI)
honestdid, pre(60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 ) post(61/122) l_vec(l_vec) delta(sd) coefplot `plotopts' // let it choose the bounds from pre-coefficients instead of specifying mvec(0(0.01)0.05)
*pre(1/84) post(85/170)

*smoothness bounds
matrix x = e(V)
matrix y = e(b)  
local plotopts xtitle(M) ytitle(95% Robust CI) 
honestdid,  l_vec(l_vec) pre(1/84) post(85/170)   delta(sd) coefplot `plotopts' vcov(x) b(y) // mvec(0(0.01)0.05)

* magnitudes bound 
local plotopts xtitle(Mbar) ytitle(95% Robust CI)
honestdid, l_vec(l_vec) pre(1/84) post(85/170) mvec(0.5(0.5)2) coefplot `plotopts'	

