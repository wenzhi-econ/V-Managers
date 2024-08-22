********************************************************************************
* Paper checks 
********************************************************************************

* Set globals 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label  FT  // PromWL75 PromSG75 PromWL50 PromSG50  FT odd  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 pay75F60
global typeM  EarlyAgeM  // EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 MFEBayesLogPayF6075 MFEBayesLogPayF7275 

global cont   c.TenureM##c.TenureM
* global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse   // alternative, to try WLM AgeBandM YearMonth AgeBand Tenure

********************************************************************************
* When are events occurring?  
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 

collapse Ei, by(IDlse)

ta Ei,sort

drop if Ei==. 
gen year = year(dofm(Ei))

**# ON PAPER STATISTICS: section 4.2 pag. 17
ta year, sort // 57% events occur in first 3 years 

********************************************************************************
* Probability you are with same manager after 18 months 
********************************************************************************

*use "$managersdta/SwitchersAllSameTeam2.dta", clear 
use "$managersdta/AllSameTeam2.dta", clear 

bys IDlse: egen IDlseMHREi = mean(cond(KEi==0, IDlseMHR , .))
gen SameM = IDlseMHR == IDlseMHREi if IDlseMHR!=. & IDlseMHREi!=.
bys IDlseMHR YearMonth: egen totSameM = sum(SameM)
gen shareSameM =    totSameM /TeamSize


foreach y in   FTLHPost   FTLLPost   FTHLPost   FTHHPost{
su shareSameM  if KEi==6 & `y'==1 , d
su shareSameM  if KEi==12 & `y'==1 , d 
su shareSameM  if KEi==18 & `y'==1, d
su shareSameM  if KEi==24 & `y'==1, d
}

*use results collapsed at the team level
preserve
collapse shareSameM (max) KEi FTLHPost   FTLLPost   FTHLPost   FTHHPost , by(IDlseMHR YearMonth)


foreach y in   FTLHPost   FTLLPost   FTHLPost   FTHHPost{
su shareSameM  if KEi==12 & `y'==1 , d
su shareSameM  if KEi==18 & `y'==1, d // key indicator, and look at p25 - it is 0 for all groups  
}
restore 


********************************************************************************
* Job mapping hypothesis 
********************************************************************************


/* DOES NOT HAVE TO BE RERUN EACH TIME 
use "$managersdta/SwitchersAllSameTeam2.dta", clear 
*use "$managersdta/AllSameTeam2.dta", clear
keep if WL2==1 // ONLY wl2
global Label  FT  

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

* First: change job and change manager 
bys IDlse: egen FirstJobManYM = min(cond(KEi>0 & TransferSJ ==1 & ChangeM==1 & KEi!=., YearMonth,.))
bys IDlse: egen FirstJobManM = mean(cond(YearMonth==  FirstJobManYM,  IDlseMHR,.))


drop if  FirstJobManYM ==. | FirstJobManM==.
keep  FirstJobManYM FirstJobManM FT*B

collapse  FT*B , by(FirstJobManYM FirstJobManM)
count
rename FirstJobManM IDlseMHR
rename FirstJobManYM YearMonth
keep if (FTLHB ==1 |  FTLHB==0) & (FTHLB ==1 |  FTHLB==0) & (FTHHB ==1 |  FTHHB==0) & (FTLLB ==1 |  FTLLB==0)

di "(73 observations deleted): 73/ 7568 = <0.1% obs" 


foreach var in FTLHB FTHLB FTHHB FTLLB {
    rename `var' `var'I
}

merge 1:m IDlseMHR YearMonth using "$managersdta/AllSameTeam2.dta",  // merging with full data to get team members in that month
keep if _merge ==3 

drop if ChangeM==1 & TransferSJ ==1 // drop own employee 


keep IDlseMHR YearMonth FT*BI
gen MapSample =1
collapse MapSample FT*BI, by(IDlseMHR YearMonth)
isid IDlseMHR YearMonth
save "$managersdta/Temp/MapSample.dta", replace 
*/

use "$managersdta/Temp/MapSample.dta"
merge 1:m IDlseMHR YearMonth using "$managersdta/AllSameTeam2.dta"
keep if _merge ==3

collapse PayBonus VPA TransferSJC PromWLC ChangeSalaryGradeC EarlyAgeM FuncM TeamSize (max) FT*BI, by(IDlseMHR YearMonth CountryM) // average performace at team level 


gen HF = (FTLHBI==1 | FTHHBI==1 )
label var HF "Previous manager is high-flyer manager"
gen LogPayBonus = log(PayBonus)
label var LogPayBonus "Av. Pay (logs)" 
label var PromWLC "Av. prom. (work level)"
label var VPA "Av. perf. Appraisals"

foreach v in LogPayBonus PromWLC  VPA { // TransferSJC ChangeSalaryGradeC
eststo `v': reghdfe `v' HF if FTLHBI==1 | FTLLBI==1, a(YearMonth CountryM) cluster(IDlseMHR)
estadd ysumm 
*reghdfe `v' HF if FTHHBI==1 | FTHLBI==1, a(YearMonth CountryM) cluster(IDlseMHR)
}

**# ON PAPER STATISTICS: Discussion section, pag. 36-37
esttab  LogPayBonus PromWLC  VPA, label star(* 0.10 ** 0.05 *** 0.01) se r2
/* If I want to esport 
esttab  LogPayBonus PromWLC  VPA  using "$analysis/Results/0.Paper/3.3.Other Analysis/MapTable.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s( ymean N r2 , labels( "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( HF ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to teammates at the time of the worker job switch. Controls include: country and year- month FE. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

*/ 


*******************************************************************************
* Code to check if high flyer leads to higher job tenure in the end - NOT IN PAPER 
*******************************************************************************

use "$managersdta/SwitchersAllSameTeam2.dta", clear 
*use "$managersdta/AllSameTeam2.dta", clear
keep if WL2==1 // ONLY wl2
global Label  FT  

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

bys IDlse: egen wMax = max(WL) // NO PROMOTIONS 

* First: change job 
bys IDlse: egen FirstJobYM = min(cond(KEi>0 & TransferSJ ==1 & KEi!=., YearMonth,.))
bys IDlse: egen FirstSFYM = min(cond(KEi>0 & TransferSubFunc ==1 & KEi!=., YearMonth,.))
bys IDlse: egen FirstJobM = mean(cond(YearMonth==  FirstJobYM,  IDlseMHR,.))
bys IDlse: egen FirstJobSJ = mean(cond( FirstJobYM==YearMonth, StandardJobCode,.))
bys IDlse: egen FirstJobSF = mean(cond(FirstSFYM==YearMonth, SubFunc,.))
bys IDlse: egen jobtenure1 = sum(cond(FirstJobSJ==StandardJobCode &   FirstJobSJ!=. , 1 ,.))
bys IDlse: egen jobtenureSF1 = sum(cond(FirstJobSF==SubFunc &   FirstJobSF!=. , 1 ,.))

* AT 5 YEARS WINDOW
bys IDlse: egen FirstJobCode5 = mean(cond(KEi==60 &FirstJobYM!=., StandardJobCode,.)) // movers only
bys IDlse: egen FirstSF5 = mean(cond(KEi==60 &FirstJobYM!=., SubFunc,.))
bys IDlse: egen jobtenureSF5 = sum(cond(FirstSF5==SubFunc &  FirstSF5!=. & KEi>=60 , 1 ,.))
bys IDlse: egen jobtenure5 = sum(cond(FirstJobCode5==StandardJobCode  & FirstJobCode5!=. & KEi>=60, 1 ,.))

bys IDlse StandardJob: egen jobtenure = count(YearMonth)
bys IDlse SubFunc: egen SFtenure = count(YearMonth)

bys IDlse: egen lastM= max(YearMonth)
egen ii = tag(IDlse)
gen HF = (FTLHB==1 | FTHHB==1 )


* job tenure regressions - job in the last month in the data  
 su MonthsSJ if  (FTLHB==1 | FTLLB==1) & lastM==YearMonth &  wMax==1 &FirstJobYM!=.  ,d
 
cap drop res1 res2
reghdfe MonthsSJ HF  c.Tenure##c.Tenure if  (FTLHB==1 | FTLLB==1) & lastM==YearMonth &  wMax==1 &FirstJobYM!=.  &     MonthsSJ<101,  vce(robust) a(KEi Country Female YearMonth)  residuals(res1)

reghdfe MonthsSJ HF  c.Tenure##c.Tenure if  (FTHHB==1 | FTHLB==1) & lastM==YearMonth &  wMax==1 &FirstJobYM!=.  &     MonthsSJ<101,  vce(robust) a(KEi Country Female YearMonth)  residuals(res2)

ppmlhdfe  MonthsSJ HF  c.Tenure##c.Tenure if  (FTLHB==1 | FTLLB==1) & lastM==YearMonth &  wMax==1 &FirstJobYM!=.  &     MonthsSJ<101,  vce(robust) a(KEi Country Female YearMonth)

tw  kdensity res1 if  (FTLHB==1 | FTLLB==1)  & HF ==1  , lcolor(cranberry) || kdensity res1 if (FTLHB==1 | FTLLB==1) & HF ==0 , lcolor(navy)


