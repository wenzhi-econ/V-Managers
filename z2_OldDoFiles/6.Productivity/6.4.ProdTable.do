********************************************************************************

* PRODUCTIVITY TABLE WITH TALENTED MANAGER  

********************************************************************************
* SET UP 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
*drop if _merge ==2 
keep if _merge ==3 
drop _merge 

xtset IDlse YearMonth  

* merge with the events 
merge m:1 IDlseMHR YearMonth using  "$managersdta/Temp/ListEventsTeam"
drop if _merge ==2
drop _merge 

* merge with manager type 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50   MFEBayesLogPayF6075   MFEBayesLogPayF6050   MFEBayesLogPayF7275   MFEBayesLogPayF7250)
drop if _merge ==2
drop _merge 

* For Sun & Abraham only consider first event 
********************************************************************************

rename Ei EiAll
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1
replace ChangeMR = 0 if ChangeMR==. 
replace IDlseMHRPreMost = . if ChangeMR== 0 
format Ei %tm 

gen KEi  = YearMonth - Ei
*keep if KEi!=. 

gen Post = KEi >=0 if KEi!=.

* Delta of managerial talent 
foreach var in MFEBayesPromSG50 EarlyAgeM MFEBayesPromSG75 MFEBayesPromSG {
cap drop diffM Deltatag  DeltaM
xtset IDlse YearMonth 
gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB
gen Deltatag = diffM if YearMonth == Ei
bys IDlse: egen DeltaM = mean(Deltatag) 
gen Post`var' = Post*DeltaM
}


global cont  c.Tenure##c.Tenure c.TenureM##c.TenureM
*global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse IDlseMHR   // alternative, to try 
global exitFE CountryYear AgeBand AgeBandM Func Female
global lcontrol AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM Female##AgeBand
global control AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM

gen Tenure2 = Tenure*Tenure
gen TenureM2 = TenureM*TenureM
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 
su Productivity if ISOCode =="IND"

label var MFEBayesPromSG75 "High Prom. Manager, p75"
label var EarlyAgeM "High Flyer Manager" 

* FINAL TABLE with prod. in logs & wages 
*******************************

reghdfe f24.lp EarlyAgeM  if ISOCode =="IND"  & Post==1  , cluster(IDlseMHR) a( $lcontrol )

eststo clear 

eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND"& Post==1 & WLM>1, cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "\multicolumn{1}{c}{Yes}"

eststo:reghdfe LogPayBonus  EarlyAgeM  if ISOCode =="IND" , cluster(IDlseMHR) a( $lcontrol )
estadd local SW "\multicolumn{1}{c}{No}"
estadd local N "51063", replace
eststo:reghdfe  LogPayBonus  EarlyAgeM  if ISOCode =="IND"& Post==1 , cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "\multicolumn{1}{c}{Yes}"
estadd local N "23253", replace

esttab , star(* 0.10 ** 0.05 *** 0.01) keep(  EarlyAgeM )

esttab using "$analysis/Results/6.Productivity/TalentMProdlogWages.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EarlyAgeM  ) se r2 ///
s( SW N r2, labels( "Switchers sample, post transition" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales in logs)" "Pay (in logs)", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: worker age group FE interacted with gender, managers' age group FE, tenure and tenure squared interacted with managers' gender.  ///
"\end{tablenotes}") replace

* FINAL TABLE with prod. in logs & wages 
*******************************


eststo clear 

eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND"& Post==1 & WLM>1, cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "\multicolumn{1}{c}{Yes}"

eststo:reghdfe lp MFEBayesPromSG75  if ISOCode =="IND", cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe lp MFEBayesPromSG75  if ISOCode =="IND" & Post==1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "\multicolumn{1}{c}{Yes}"

esttab , star(* 0.10 ** 0.05 *** 0.01) keep(  EarlyAgeM  MFEBayesPromSG75 )

esttab using "$analysis/Results/6.Productivity/TalentMProdlog.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EarlyAgeM  MFEBayesPromSG75) se r2 ///
s( SW N r2, labels( "Switchers sample, post transition" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales in logs)", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: worker age group FE interacted with gender, managers' age group FE, tenure and tenure squared interacted with managers' gender.  ///
"\end{tablenotes}") replace


* FINAL TABLE: India  (in standard deviation)
********************************************

eststo clear 

eststo:reghdfe ProductivityStd  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $control )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe ProductivityStd  EarlyAgeM  if ISOCode =="IND"& Post==1 & WLM>1, cluster(IDlseMHR) a(  $control )
estadd local SW "\multicolumn{1}{c}{Yes}"
eststo:reghdfe ProductivityStd MFEBayesPromSG75  if ISOCode =="IND", cluster(IDlseMHR) a(  $control )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe ProductivityStd MFEBayesPromSG75  if ISOCode =="IND" & Post==1, cluster(IDlseMHR) a( $control )
estadd local SW "\multicolumn{1}{c}{Yes}"

esttab , star(* 0.10 ** 0.05 *** 0.01) keep(  EarlyAgeM  MFEBayesPromSG75 )

esttab using "$analysis/Results/6.Productivity/TalentMProd.tex", label star(* 0.10 ** 0.05 *** 0.01) keep(EarlyAgeM  MFEBayesPromSG75) se r2 ///
s( SW N r2, labels( "Switchers sample, post transition" "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales)", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: managers' age group FE, tenure and tenure squared interacted with managers' gender.  ///
"\end{tablenotes}") replace

* How many months for each IDlse? 
********************************************
gen o = 1 
bys IDlse: egen tto = sum(o)
egen i = tag(IDlse)

bys IDlse: egen ttChangeM = sum(ChangeM)

su tto if i==1 & ISOCode =="IND",d // median duration in position is 22 months 
su ttChangeM if i==1 & ISOCode =="IND" & Ei!=. & MFEBayesPromSG75!=.,d // median is 2 manager change, but drop to 600 people in the sample, 20% of the original 3300
count if ttChangeM >0 & i==1 & ISOCode =="IND" & Ei!=. & MFEBayesPromSG75!=. // drop to 600 people in the sample, 20% of the original 3300 workers in India

* Check sample selection - other outcomes on indian population 
********************************************

use "$managersdta/AllSameTeam2.dta", clear 
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 

gen Post = KEi >=0 if KEi!=.

gen TenureM2 = TenureM*TenureM

eststo:reghdfe LogPayBonus  EarlyAgeM  if ISOCode =="IND" & WLM>1 & Func==3 & WL==1, cluster(IDlseMHR) a( $lcontrol )
eststo:reghdfe LogPayBonus  EarlyAgeM  if ISOCode =="IND" & WLM>1 & Func==3 & WL==1 & Post!=., cluster(IDlseMHR) a( $lcontrol )
eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND" & WLM>1, cluster(IDlseMHR) a( $lcontrol )
estadd local SW "\multicolumn{1}{c}{No}"
eststo:reghdfe lp  EarlyAgeM  if ISOCode =="IND"& Post!=. , cluster(IDlseMHR) a(  $lcontrol )
estadd local SW "\multicolumn{1}{c}{Yes}"


* Gaining vs losing manager with employee ID fe
********************************************************************************

use "$managersdta/AllSameTeam.dta", clear 

gen TenureM2 = TenureM*TenureM
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 

global lcontrol AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM Female##AgeBand
global control AgeBandM##FemaleM c.TenureM2##FemaleM c.TenureM##FemaleM

eststo clear 
eststo: reghdfe lp  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.) & ISOCode =="IND", cluster(IDlseMHR) a( $control  )
eststo: reghdfe lp  PostEarlyAgeM1    if   (FTHL!=. | FTHH !=.)   & ISOCode =="IND", cluster(IDlseMHR) a($control  )
eststo: reghdfe LogPayBonus  PostEarlyAgeM    if  (FTLH!=. | FTLL !=.)  & ISOCode =="IND" & lp!=., cluster(IDlseMHR) a( $control  )
eststo: reghdfe  LogPayBonus  PostEarlyAgeM1    if   (FTHL!=. | FTHH !=.) & ISOCode =="IND" & lp!=., cluster(IDlseMHR) a($control  )
esttab , star(* 0.10 ** 0.05 *** 0.01) keep(   PostEarlyAgeM PostEarlyAgeM1 ) se label

esttab using "$analysis/Results/6.Productivity/TalentMProdGain.tex", label star(* 0.10 ** 0.05 *** 0.01) keep( PostEarlyAgeM PostEarlyAgeM1) se r2 ///
s(  N r2, labels( "N" "R-squared" ) ) interaction("$\times$ ")    ///
nomtitles mgroups( "Productivity (sales in logs)" "Pay (in logs)", pattern(1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))   ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a employee-month. Standard errors clustered at the manager level. ///
 Controls include: country and year FE, worker tenure squared interacted with gender.  ///
"\end{tablenotes}") replace
