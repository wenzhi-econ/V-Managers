********************************************************************************
* Computing the cost/benefit ratio of high flyer managers 
********************************************************************************

* using income statement data from ORBIS - UNILEVER FINANCIALS 
********************************************************************************

* first compute average salaries 
use "$managersdta/SwitchersAllSameTeam2.dta", clear 
*use  "$managersdta/AllSnapshotMCulture.dta", clear

* salary 
su PayBonus if WL==1 & Year==2019,d
su PayBonus  if WL==2 &EarlyAge==0 & Year==2019,d

* team size 
egen tm = tag(IDlseMHR YearMonth)
su TeamSize if WLM==2 & tm==1 & Year==2019, d

use "$managersdta/Orbis/unilever_financial.dta", replace 

* figures are in 1,000millions 
* using 2019 data 
local op = 10213147 // operating profits 
local eb =  12045093  //   EBITDA  12045093
local n = 150000 
local exc = 1.12340 // Exchange rate: EUR/USD

* data from paper 
local prodIn = 0.27 
local wageIn = 0.079
local wageM = 0.06
local teamN = 3
local PayBonusWorker =   28991.95 * `exc' // su PayBonus if WL==1 & Year=2019 and convert to USD 
local PayBonusManager =     83003.26 * `exc' // su PayBonus  if WL==2 &EarlyAge==0 & Year=2019 and convert to USD 

*di "Benefit increase per manager: "  `teamN'*(`eb'*`prodIn' / `n') *1000 - `wageIn'*`PayBonusWorker'

di "Benefit increase per manager: "  `teamN'*(`op'*`prodIn' / `n') *1000 
local b =  `teamN'*(`op'*`prodIn' / `n') *1000 

di "Extra Costs per high flyer manager: " ( `wageM'*`PayBonusManager')  
local c = ( `wageM'*`PayBonusManager') 

di "Ratio cost/benefit: " `c'/`b'
local r = `c'/`b' 

********************************************************************************
* The returns of being a high flyer manager  
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 

gen PayBonusM = exp(LogPayBonusM)

gen o =1 
bys IDlseMHR (YearMonth), sort : gen cum = sum(o)
 
eststo reg1:reghdfe LogPayBonusM EarlyAgeM  if  (MinWLM==1 | MinWLM==2) & WLM>1, cluster(IDlseMHR) a(  YearMonth )
reghdfe LogPayBonusM EarlyAgeM TenureM  if  (MinWLM==1 | MinWLM==2) & WLM>1, cluster(IDlseMHR) a(  CountryM Year)
reghdfe PromWLCM EarlyAgeM TenureM  if  (MinWLM==1 | MinWLM==2) & WLM>1, cluster(IDlseMHR) a(  CountryM Year)


gen PromWLCM1 =  PromWLCM
replace  PromWLCM1 = 1 if PromWLCM>1 & PromWLCM!=. 
reghdfe PromWLCM1 EarlyAgeM TenureM  if  (MinWLM==1 | MinWLM==2) & WLM>1, cluster(IDlseMHR) a(  CountryM Year) // very similar results

tw lpoly LogPayBonusM TenureM if EarlyAgeM==1 & (MinWLM==1 | MinWLM==2) & WLM>1 & TenureM <=20, bw(0.8) || lpoly LogPayBonusM TenureM if EarlyAgeM==0 &(MinWLM==1 | MinWLM==2) & WLM>1 & TenureM <=20, name(tl,replace ) bw(0.8)


* collapse year level 
preserve 
collapse  EarlyAgeM MinWLM (max) TenureM PromWLCM WLM CountryM PayBonusM, by(IDlseMHR Year)
gen LogPayBonusM = log(PayBonusM)

reghdfe LogPayBonusM EarlyAgeM   if  (MinWLM==1 | MinWLM==2) & WLM>1, cluster(IDlseMHR) a(  CountryM Year)
reghdfe LogPayBonusM EarlyAgeM TenureM  if  (MinWLM==1 | MinWLM==2) & WLM>1, cluster(IDlseMHR) a(  CountryM Year)
reghdfe PromWLCM EarlyAgeM TenureM  if  (MinWLM==1 | MinWLM==2) & WLM>1, cluster(IDlseMHR) a(  CountryM Year)

restore

preserve 
keep if  (MinWLM==1 | MinWLM==2) & WLM>1 & TenureM <=20
collapse PayBonusM, by(EarlyAgeM TenureM)

gen LogPayBonusM = log(PayBonusM)

tw line LogPayBonusM TenureM if EarlyAgeM==1 || line LogPayBonusM TenureM if EarlyAgeM==0, name(t,replace )
tw lpoly LogPayBonusM TenureM if EarlyAgeM==1, bw(0.8) || lpoly LogPayBonusM TenureM if EarlyAgeM==0, name(tl,replace ) bw(0.8)

restore 



preserve 
keep if  (MinWLM==1 | MinWLM==2) & WLM>1 // & TenureM <=20
collapse PayBonusM, by(EarlyAgeM cum)

gen LogPayBonusM = log(PayBonusM)

gen cum1 = cum/12
tw line LogPayBonusM cum1 if EarlyAgeM==1 || line LogPayBonusM cum1 if EarlyAgeM==0, name(t1,replace )

tw line LogPayBonusM cum if EarlyAgeM==1 || line LogPayBonusM cum if EarlyAgeM==0, name(t12,replace )
tw lpoly LogPayBonusM cum if EarlyAgeM==1, bw(0.8) || lpoly LogPayBonusM cum if EarlyAgeM==0, name(tl,replace ) bw(0.8)

restore


********************************************************************************
* How influential are good managers for careers? 
********************************************************************************

global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

use "$managersdta/SwitchersAllSameTeam2.dta", clear 
gen Month = month(dofm(YearMonth))

keep if Month ==12

xtset IDlse Year 

forval u = 1(1)5{
gen EarlyAgeM`u' = l`u'.EarlyAgeM
}
label var EarlyAgeM "Fast Track Manager"
label var EarlyAgeM1 "Fast Track Manager, lag 1"
label var EarlyAgeM2 "Fast Track Manager, lag 2"
label var EarlyAgeM3 "Fast Track Manager, lag 3"
label var EarlyAgeM4 "Fast Track Manager, lag 4"
label var EarlyAgeM5 "Fast Track Manager, lag 5"

* TABLE ON PAPER: 
********************************************************************************
eststo clear 
cap drop lagSample 
* no job fe 
eststo reg1:reghdfe LogPayBonus EarlyAgeM  if (FTLL!=. | FTLH!=.) & KEi>=-1 & WL2==1, cluster(IDlseMHR) a( IDlse YearMonth )
estadd local JobFE "\multicolumn{1}{c}{No}"
eststo reg3: reghdfe LogPayBonus EarlyAgeM* if (FTLL!=. | FTLH!=.) & KEi>=-1 & WL2==1, cluster(IDlseMHR) a( IDlse YearMonth)
estadd local JobFE "\multicolumn{1}{c}{No}"
*estadd local N "87413", replace 
gen lagSample = e(sample)
eststo reg2:reghdfe LogPayBonus EarlyAgeM  if lagSample==1, cluster(IDlseMHR) a( IDlse YearMonth )
estadd local JobFE "\multicolumn{1}{c}{No}"

esttab reg1 reg2 reg3 , star(* 0.10 ** 0.05 *** 0.01) keep(  *EarlyAgeM*  ) se label

esttab reg1 reg2 reg3  using "$analysis/Results/5.Mechanisms/PDV.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(  *EarlyAgeM*) se r2 ///
s( N r2, labels(  "\hline N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Annual Pay (in logs) ", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-year. Standard errors clustered at the manager level. ///
 Controls include: employee and year FE.  ///
"\end{tablenotes}") replace

* Discount rate: 5% 
* CASE 1: Assume no effect after 5 years 
* CASE 2: Assume constant effect after 5 years 

* Here, restriction to WL2 
local l = 1.9 // after 5 years 
di 1.6 + 0.6/(1.05) +  1.5/(1.05)^2 + 1/(1.05)^3 + 1/(1.05)^4 +  1.9/(1.05)^5 + `l'/(1.05)^6 +  `l'/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 +   `l'/(1.05)^20
* 7% with no dynamic effects after 5 years 
* 22% with 1.9 dynamic effects after 5 years 

* OTW, no restriction on WL2 
********************************************************************************

eststo clear 
cap drop lagSample 
* no job fe 
eststo reg1:reghdfe LogPayBonus EarlyAgeM  if (FTLL!=. | FTLH!=.) & KEi>=-1 , cluster(IDlseMHR) a( IDlse YearMonth )
estadd local JobFE "\multicolumn{1}{c}{No}"
eststo reg3: reghdfe LogPayBonus EarlyAgeM* if (FTLL!=. | FTLH!=.) & KEi>=-1 , cluster(IDlseMHR) a( IDlse YearMonth)
estadd local JobFE "\multicolumn{1}{c}{No}"
*estadd local N "87413", replace 
gen lagSample = e(sample)
eststo reg2:reghdfe LogPayBonus EarlyAgeM  if lagSample==1, cluster(IDlseMHR) a( IDlse YearMonth )
estadd local JobFE "\multicolumn{1}{c}{No}"

esttab reg1 reg2 reg3 , star(* 0.10 ** 0.05 *** 0.01) keep(  *EarlyAgeM*  ) se label

* COMPUTE pdv: 
local l = 4 // after 5 years 
di 2.6 + 2.2/(1.05) +  2.3/(1.05)^2 + 1.9/(1.05)^3 + 2.4/(1.05)^4 +  4.6/(1.05)^5 + `l'/(1.05)^6 +  `l'/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 +   `l'/(1.05)^20

* 14% with no dynamic effects after 5 years 
* 30% with 2 dynamic effects after 5 years 
* 47% with 4 dynamic effects after 5 years

* Table with and without job FE 
********************************************************************************
eststo clear 
cap drop lagSample lagSamplenoJ
* no job fe 
eststo reg1:reghdfe LogPayBonus EarlyAgeM  if (FTLL!=. | FTLH!=.) & KEi>=-1 & WL2==1, cluster(IDlseMHR) a( IDlse YearMonth )
estadd local JobFE "\multicolumn{1}{c}{No}"
eststo reg3: reghdfe LogPayBonus EarlyAgeM* if (FTLL!=. | FTLH!=.) & KEi>=-1 & WL2==1, cluster(IDlseMHR) a( IDlse YearMonth)
estadd local JobFE "\multicolumn{1}{c}{No}"
estadd local N "87413", replace 
gen lagSample = e(sample)
eststo reg2:reghdfe LogPayBonus EarlyAgeM  if lagSample==1 & WL2==1, cluster(IDlseMHR) a( IDlse YearMonth )
estadd local JobFE "\multicolumn{1}{c}{No}"
* with job FE 
eststo reg4:reghdfe LogPayBonus EarlyAgeM  if (FTLL!=. | FTLH!=.) & KEi>=-1 & WL2==1, cluster(IDlseMHR) a( IDlse YearMonth StandardJob)
estadd local JobFE "\multicolumn{1}{c}{Yes}"
eststo reg6: reghdfe LogPayBonus EarlyAgeM* if (FTLL!=. | FTLH!=.) & KEi>=-1 & WL2==1, cluster(IDlseMHR) a( IDlse YearMonth StandardJob)
estadd local JobFE "\multicolumn{1}{c}{Yes}"
gen lagSamplenoJ = e(sample)
eststo reg5:reghdfe LogPayBonus EarlyAgeM  if lagSamplenoJ==1 & WL2==1, cluster(IDlseMHR) a( IDlse YearMonth StandardJob)
estadd local JobFE "\multicolumn{1}{c}{Yes}"


esttab reg3 reg6, star(* 0.10 ** 0.05 *** 0.01) keep(  *EarlyAgeM*  ) se label

esttab reg3 reg6 using "$analysis/Results/5.Mechanisms/PDVJobFE.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(  *EarlyAgeM*) se r2 ///
s( JobFE N r2, labels( "Job fixed effects" "\hline N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Annual Pay (in logs) ", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-year. Standard errors clustered at the manager level. ///
 Controls include: employee and year FE.  ///
"\end{tablenotes}") replace

* Discount rate: 5% 
* Assume no effect after 5 years 
* Assumer constant effect after 5 years 

* COMPUTE pdv: 
local l = 4 // after 5 years 
di 2.6 + 2.2/(1.05) +  2.3/(1.05)^2 + 1.9/(1.05)^3 + 2.4/(1.05)^4 +  4.6/(1.05)^5 + `l'/(1.05)^6 +  `l'/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 +   `l'/(1.05)^20

* 14% with no dynamic effects after 5 years 
* 30% with 2 dynamic effects after 5 years 
* 47% with 4 dynamic effects after 5 years 

* with job fixed effects 
local l = 0 // after 5 years 
di 1 + 1/(1.05) +  1/(1.05)^2 + 1/(1.05)^3 + 1/(1.05)^4 +  1.5/(1.05)^5 +  `l'/(1.05)^6 +  `l'/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 +   `l'/(1.05)^20

* 6% with no dynamic effects after 5 years 
* 14% with 1 dynamic effects after 5 years 
