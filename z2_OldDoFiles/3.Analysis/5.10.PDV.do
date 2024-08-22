********************************************************************************
* How influential are good managers for careers? 
********************************************************************************

* IN THE PAPER I DECIDED TO USE THE SALARY ESTIMATES FROM THE EVENT STUDY 

* Discount rate: 5% 
* CASE 1: Assume no effect after 7 years 
* CASE 2: Assume constant effect after 7 years 

* Here, restriction to WL2 
local l = 30 // after 7 years 
di 0 + 2/(1.05) +  7/(1.05)^2 + 11/(1.05)^3 + 19/(1.05)^4 + 24/(1.05)^5 + 28/(1.05)^6 +  30/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 
* 94% with no dynamic effects after  7 years 
* 283% with 5% dynamic effects after 7 years 

di 0 + 2/(1.05) +  7/(1.05)^2 + 11/(1.05)^3 + 19/(1.05)^4 + 24/(1.05)^5 + 28/(1.05)^6 +  30/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 +   `l'/(1.05)^20 +   `l'/(1.05)^21 +   `l'/(1.05)^22 +   `l'/(1.05)^23 +   `l'/(1.05)^24+   `l'/(1.05)^25 ///
+   `l'/(1.05)^26 +   `l'/(1.05)^27 +   `l'/(1.05)^28 +   `l'/(1.05)^29 

* 94% with no dynamic effects after 7 years 
* 375% with 5% dynamic effects after 7 years 


/* USING THE SALARY GRADE ESTIMATES FROM THE EVENT STUDY 

* Discount rate: 5% 
* CASE 1: Assume no effect after 5 years 
* CASE 2: Assume constant effect after 5 years 

* Here, restriction to WL2 
local l = 5 // after 7 years 
di 0.6 + 2/(1.05) +  2.6/(1.05)^2 + 4.1/(1.05)^3 + 5/(1.05)^4 +  5/(1.05)^5 + 5/(1.05)^6 +  `l'/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 
* 20% with no dynamic effects after  7 years 
* 55% with 5% dynamic effects after 7 years 

di 0.6 + 2/(1.05) +  2.6/(1.05)^2 + 4.1/(1.05)^3 + 5/(1.05)^4 +  5/(1.05)^5 + 5/(1.05)^6 +  `l'/(1.05)^7 +   `l'/(1.05)^8 +  `l'/(1.05)^9 ///
+   `l'/(1.05)^10 +  `l'/(1.05)^11 +   `l'/(1.05)^12 +   `l'/(1.05)^13 +   `l'/(1.05)^14 +   `l'/(1.05)^15 +   `l'/(1.05)^16  ///
+   `l'/(1.05)^17 +   `l'/(1.05)^18 +   `l'/(1.05)^19 +   `l'/(1.05)^20 +   `l'/(1.05)^21 +   `l'/(1.05)^22 +   `l'/(1.05)^23 +   `l'/(1.05)^24+   `l'/(1.05)^25 ///
+   `l'/(1.05)^26 +   `l'/(1.05)^27 +   `l'/(1.05)^28 +   `l'/(1.05)^29 

* 20% with no dynamic effects after 7 years 
* 71% with 5% dynamic effects after 7 years 
*/

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

* results consistent with 5% higher salary 5 years after 
* say both LH and LL start with 1
* USING COEFF FROM TABLE 13 IN PAPER 
* LH:
di  1*1.016 + 1*1.016*1.006 + (1*1.016)*1.006*1.015 + (1*1.016)*1.006*1.015*1.01 + (1*1.016)*1.006*1.015*1.01*1.01 + (1*1.016)*1.006*1.015*1.01*1.01*1.02 
*LL
di 1+1+1+1+1+1

* overal increase in percent 
di 0.26/6 // 4.3% very consistent! 

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
