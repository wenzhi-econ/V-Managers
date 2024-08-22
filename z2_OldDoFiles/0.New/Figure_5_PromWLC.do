/* 
Major changes of this file:

This do file creates a figure like Figure 5V panel (b), where I need to present coefficients for 12, 20, 28 quarters.
The codes are copied from "2.4.Event Study NoLoops.do".
I only deleted some irrelevant codes that were originally commented out to increase readbility.

Input files:
    "$managersdta/AllSameTeam2MF.dta" 
        ==> (it is a random sample, the whole sample is "${managersdta}/AllSameTeam2.dta")
        TODO You need to uncomment line 40, while commenting out line 41.
    "$managersdta/Temp/Random50vw.dta"
        ==> I have no idea its function in estimation, but it brings a necessary variable used in reghdfe command.

Output:
    "$analysis/Results/0.New/PromWLCPlotLHA.pdf"

Additional notes:
    You need to run the master do file (which I copied to the current folder as well) first.

RA: WWZ 
Time: 18/3/2024

*/

********************************************************************************
* Dynamic TWFE model - Asymmetric 
********************************************************************************

* Set globals 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label  FT  
global typeM  EarlyAgeM  

global cont   c.TenureM##c.TenureM
global abs    YearMonth IDlse   

use "${managersdta}/AllSameTeam2.dta", clear 
*use "$managersdta/Not Used/Marco/AllSameTeam2MF.dta", clear
/* use "${managersdta}/AllSameTeam2MF.dta", clear  */

********************************************************************************
* EVENT INDICATORS 
********************************************************************************

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

merge m:1 IDlse using  "$managersdta/Temp/Random50vw.dta" // "$managersdta/Temp/Random20vw.dta" for the dual graphs to limited computation power and "$managersdta/Temp/Random50vw.dta" for all outcomes
drop _merge 
rename random50 random // random50 random20
keep if Ei!=. | random==1 

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
local end = 36 // to be plugged in, window lenght 
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-`end' &  maxEi >=`end'
ta ii
*keep if ii==1 | random10==1

egen CountryYear = group(Country Year)

********************************************************************************
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


* LABEL VARS
********************************************************************************

label var PromWLC "Vertical move"

********************************************************************************
* LH vs LL: BONUS AND PAY
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
local endL24 = 24 // 36 60 to be plugged in  
local endL36 = 36 // 36 60 to be plugged in 
local endL60 = 60 // 36 60 to be plugged in 
local endL84 = 84 // 36 60 to be plugged in 

local endFQ36 = `endF36'/3 // 36 60 to be plugged in 
local endLQ36 = `endL24'/3 // 36 8 to be plugged in 
local endLQ36 = `endL36'/3 // 36 12 to be plugged in 
local endLQ60 = `endL60'/3 // 36 60 to be plugged in 
local endLQ84 = `endL84'/3 // 36 60 to be plugged in 
local endQ= `end'/3
local Label $Label

label var LogPayBonus "Pay + bonus (logs)"
label var LogPay "Pay (logs)"
label var LogBonus "Bonus (logs)"

* MAIN 
**# ON PAPER FIGURE: PromWLCPlotLHA.pdf
* regression
********************************************************************************

eststo: reghdfe PromWLC  $LLH $LLL $FLH  $FLL if ( WL2==1 & ( FTLHB==1 | FTLLB==1) | ( random==1  & FTHLB==0 & FTHHB==0)  )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 & Ei!=.)  ) 

local lab: variable label PromWLC

* single differences 
********************************************************************************

* monthly: 36 / 84
coeffLH1, c(`window') y(PromWLC) type(`Label') // program 
su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

pretrendLH , end(12) y(PromWLC)
su jointL
local jointL = round(r(mean), 0.001)

* quarterly
coeffQLH1, c(`window') y(PromWLC) type(`Label') // program 

xlincom (L36ELH - L36ELL) (L60ELH - L60ELL) (L84ELH - L84ELL) (L24ELH - L24ELL) , level(95) post
est store PromWLC


coefplot  ///
    (PromWLC , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (PromWLC, keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    (PromWLC , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
    , ciopts(lwidth(2 ..)) levels(95) msymbol(d) mcolor(white) legend(off)  ///
    title("Work-level promotions", size(vlarge)) ///
    xline(0, lpattern(dash)) xscale(range(0 0.1)) xlabel(0(0.02)0.1, labsize(vlarge)) ylabel(, labsize(vlarge)) /// 
    graphregion(margin(medium)) plotregion(margin(medium)) xsize(5) ysize(2)

graph save "$analysis/Results/0.New/PromWLCPlotLHA.gph", replace 
graph export "$analysis/Results/0.New/PromWLCPlotLHA.pdf", replace as(pdf)

