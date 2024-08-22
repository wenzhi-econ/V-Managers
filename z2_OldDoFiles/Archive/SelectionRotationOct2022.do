use "$Managersdta/SwitchersAllSameTeam2.dta", clear

egen p = tag(IDlseMHR)


preserve 
keep if WL2==1 & KEi==0 // exactly 32%
ta EarlyAgeM if p==1 
restore 


preserve 
keep if  KEi==0
ta EarlyAgeM if p==1 
restore 


use "$Managersdta/Temp/MType.dta", clear 

bys IDlseMHR: egen tt = min(TenureM)

egen m = tag(IDlseMHR)

ta tt if m==1

* is there differential exit? 
ta EarlyAgeM LeaverPermM , row

********************************************************************************
* Timing of manager rotation  + how many managers experience this rotation 
********************************************************************************

* How many managers in total? 
use "$Managersdta/AllSnapshotMCulture.dta", clear 
distinct IDlseMHR if WLM>1 //  33295

* how many managers rotating: worker does not change sub function or job 
use "$Managersdta/SwitchersAllSameTeam2.dta", clear 
distinct IDlseMHR if KEi==0 &  WLM>1  //  17892

* how many managers rotating: inherit all team 
use "$Managersdta/SwitchersAllSameTeam.dta", clear 
distinct IDlseMHR if KEi==0 &  WLM>1  //   16088

ta FTHighHigh
ta FTHighHigh
ta FTHighHigh
ta FTHighHigh
di  28109 +  5587 + 4095 + 2412
di  28109 / 40203
di  5587 / 40203
di  4095 / 40203
di  2412 / 40203


//////////
* MANAGERS
//////////

* Incoming and outgoing manager 
foreach var in HL LL LH HH {
gen  u`var'InM = 1 if (YearMonth == FT`var' & WL2==1 ) 
gen u`var'OutM = 1 if (YearMonth == FT`var'-1 	& WL2==1 ) 
}

preserve
collapse uLHInM uLHOutM uLLInM uLLOutM uHHInM uHHOutM uHLInM uHLOutM, by(IDlseMHR YearMonth)
rename IDlseMHR  IDlse  
save "$Managersdta/Temp/MEvent.dta" , replace 
restore 

drop uLHInM uLHOutM uLLInM uLLOutM uHHInM uHHOutM uHLInM uHLOutM
merge 1:1 IDlse YearMonth using "$Managersdta/Temp/MEvent.dta", keepusing(uLHInM uLHOutM uLLInM uLLOutM uHHInM uHHOutM uHLInM uHLOutM)
drop if _merge ==2
rename _merge ManagerMatch

egen i = rowmean( uLHInM uLLInM  uHHInM uHLInM ) // incoming manager 
egen o = rowmean( uLHOutM uLLOutM  uHHOutM uHLOutM ) // outgoing manager 
bys IDlse : egen IEvent = sum(i)
bys IDlse : egen OEvent = sum(o)

replace IEvent = . if IEvent == 0 & Manager==0
replace OEvent = . if OEvent == 0 & Manager==0

* OUTGOING
distinct IDlse if OEvent==0  &YearMonth <=tm(2020m3) & WL==2
local c1 =  r(ndistinct)
distinct IDlse if o==1 &YearMonth <=tm(2020m3)
local c2 =  r(ndistinct)
distinct IDlse if uLLOutM!=. &YearMonth <=tm(2020m3)
local c3 =  r(ndistinct)
distinct IDlse if uLHOutM!=. &YearMonth <=tm(2020m3)
local c4 =  r(ndistinct)
distinct IDlse if uHLOutM!=. &YearMonth <=tm(2020m3)
local c5 =  r(ndistinct)
distinct IDlse if uHHOutM!=. &YearMonth <=tm(2020m3)
local c6 =  r(ndistinct)

balancetable (mean if OEvent==0  & WL==2) (mean if OEvent==1 ) (mean if  uLLOutM!=. ) (mean if  uLHOutM!=. )  (mean if  uHLOutM!=. ) (mean if uHHOutM!=. )  $CHARS $PRE      using "$analysis/Results/2.Descriptives/TransitionOM.tex", ///
replace    varla noobservations  vce(cluster IDlseMHR)  ctitles("No event" "Had event" "Low to Low" "Low to High" "High to Low" "High to High") ///
postfoot("\hline" "\multicolumn{1}{l}{Unique Individuals} &  `c1' & `c2' & `c3' & `c4' & `c5' & `c6' \\ " "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. This table shows summary statics across event types, and between the groups who do and do not experience events. Outgoing managers are defined as the manager of the team in the month before a transition event; incoming managers are those who are assigned to a team in the month of the event. For event columns, I show the average of managers in the month they experience the event; for those who never experience an event I show the average across their tenure at the firm." "\end{tablenotes}")
*cov(i.CountryY i.FuncM)

* pvalues 
cap drop lowM highM
gen lowM=  (uLLOutM==1 |  uLHOutM==1)
gen highM =  (uHLOutM==1 |  uHHOutM==1)

gen OEvent1 = 1 if OEvent ==1 
replace OEvent1 = 0 if OEvent ==0

balancetable (diff OEvent1 if WL==2) (diff uLHOutM if lowM==1 &WL2==1) (diff  uHLOutM  if highM==1&WL2==1 )  $CHARS $PRE  using "$analysis/Results/2.Descriptives/TransitionOMDiff.tex", ///
replace  noobservations varla vce(cluster IDlseMHR)  ctitles("Event" "Low to High versus to Low" "High to Low versus to High") ///
postfoot("\hline" "\multicolumn{1}{l}{Unique Individuals} &  `c1' & `c2' & `c3' \\ " "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. This table shows p-values for the difference in means to show balance of covariates across event types, and between the groups who do and do not experience events. Outgoing managers are defined as the manager of unit in the month before a transition event; incoming managers are those who are assigned to a unit in the month of the event. For event columns, I show the average of employees in the month they experience the event; for those who never experience an event I show the average of all such individuals across their tenure at the firm." "\end{tablenotes}")
