********************************************************************************
* Managers in experiment: overall share + is there differential selection by manager type? 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 
merge m:1 IDlseMHR using "$managersdta/Temp/mSample.dta", keepus(  minAge) // sample of WL2 managers - constructed in 2.1.ManagerDes line 151, minAge is the minimum age observed at WL2
keep if _merge==3 

bys IDlseMHR: egen mT = max(cond(ChangeMR==1, 1,0)) // managers in the rotation policy
 
* collapse at manager level 
collapse mT EarlyAgeM WLM minAge, by(IDlseMHR)

gen HF = minAge ==1 // high fliers  
ttest HF , by(mT)

ta mT // 74% of managers make at least one of this transition 

keep mT HF IDlseMHR
compress 
save "$managersdta/Temp/m2.dta", replace 

* for balance tables on manager selecting into rotations look 2.0.MTypeBalance 
* some quick checks on why some people do not rotate 
use "$managersdta/Temp/MType.dta", clear 
merge m:1 IDlseMHR using "$managersdta/Temp/m2.dta", keepusing( mT HF)
keep if _merge==3

 *the managers not in the experiment have lower tenure and higher exit and this trend is the same for HF and not HF
bys mT: su TenureM LeaverPerm if HF==1
bys mT: su TenureM LeaverPerm if HF==0

* exactly same patterns: btw in and out rotation policy conditional on manager quality and btw high and low flyers conditional on being or not in the rotation policy 
ttest LeaverPerm if HF==0, by(mT) 
ttest LeaverPerm if HF==1, by(mT)
ttest TenureM if HF==0, by(mT) 
ttest TenureM if HF==1, by(mT)

ttest LeaverPerm if mT==0, by(HF) 
ttest LeaverPerm if mT==1, by(HF) 
ttest TenureM if mT==0, by(HF) 
ttest TenureM if mT==1, by(HF)

********************************************************************************
* Balance table by transition event 
********************************************************************************

*use "$managersdta/AllSnapshotMCultureMType.dta", clear 
use "$managersdta/AllSameTeam2.dta", clear 

merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

* education variable 
merge m:1 IDlse  using "$fulldta/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge 

* Constructing relevant variables for the table 
* EDUCATION Groups 
gen Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
label var Econ "Econ, Business, and Admin"
gen Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
label var Sci "Sci, Engin, Math, and Stat"
gen Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label var Hum "Social Sciences and Humanities"
gen Other = (Econ ==0 & Sci ==0 & Hum ==0  )  if FieldHigh1!=.
label var Other "Other Educ"
gen Missing = FieldHigh1 ==. 
label var Missing "Missing Education"

gen Bachelor =    QualHigh >=10 if QualHigh!=.
gen MBA =    QualHigh ==13 if QualHigh!=.
gen AboveSecondary = QualHigh >=6 if QualHigh!=.

* Mid-career recruit 
bys IDlse : egen FF= min(YearMonth)
bys  IDlse: egen FirstWL = mean(cond(YearMonth==FF, WL, .)) // first WL observed 
bys  IDlse: egen FirstTenure = mean(cond(YearMonth==FF, Tenure, .)) // tenure in first month observed 

gen MidCareerHire = FirstWL>1 & FirstTenure<=1 & WL!=. // they are only 10% of all managers!

* generating relevant vars 
* here are the actual median ages within group computed in MType.do: 26 35 44 53 62 
replace AgeContinuous = .
replace AgeContinuous = 26 if AgeBand == 1
replace AgeContinuous = 35 if AgeBand == 2
replace AgeContinuous = 44 if AgeBand == 3
replace AgeContinuous = 53 if AgeBand == 4
replace AgeContinuous = 62 if AgeBand == 5

winsor2 TeamSize, suffix(W) cuts(0 95)
egen CountryY = group(Country Year) 
bys YearMonth Office SubFunc Org4: egen SizeUnit = count(IDlse)

bys IDlseMHR YearMonth: egen ShareFemale = mean(Female)
bys IDlseMHR YearMonth: egen ShareSameG = mean(SameGender)
bys IDlseMHR YearMonth: egen ShareOutGroup = mean(OutGroup)
bys IDlseMHR YearMonth: egen ShareDiffOffice = mean(DiffOffice)

xtset IDlse YearMonth

gen PayBonusGrowth= d.LogPayBonus 
gen PayBonusGrowth12= S12.LogPayBonus // 12 period difference 
gen PayBonusGrowth6= S6.LogPayBonus // 6 period difference 

label var PayBonusGrowth12 "Pay growth (12 months)"
label var PayBonusGrowth6 "Pay growth (6 months)"

* globals for the variables in the table 
global CHARS  Female AgeContinuous MBA Econ Sci Hum Other Tenure   
label var Female "Female"
label var AgeContinuous "Age"
label var MidCareerHire "Mid-career recruit"
label var FlagUFLP "Hired through graduate programme"
label var Tenure "Tenure (years)" 
label var WL   "Work Level"

global PRE   TransferSJC ChangeSalaryGradeC PayBonusGrowth6  VPA 
label var ProductivityStd  "Sales achievement/target"
label var LogPayBonus "Pay + Bonus (logs)"
label var VPA   "Perf. appraisal (1-150)"
label var TransferSJC "No. of job moves"
label var ChangeSalaryGradeC "No. of salary increases"
label var PRI "Perf. appraisal (1-5)"
label var PayBonusGrowth  "Salary growth" 

global TEAM TeamSizeW  ShareFemale   ShareOutGroup ShareDiffOffice  SizeUnit 
label var TeamSize "Team Size"
label var TeamSizeW "Team Size"
label var ShareSameG "Team share, diff. gender"
label var ShareFemale "Team share, female"
label var ShareOutGroup  "Team share, diff. homecountry" 
label var ShareDiffOffice  "Team share, diff. office"
label var SizeUnit "Unit Size"

//////////
*EMPLOYEES 
//////////

* Event indicators that select on the right month of comparison  
gen Event = YearMonth == Ei 
gen e = 1 if (FTLH !=. | FTLL!=. | FTHL!=. | FTHH!=.) 
replace Event=0 if e!=1 // because of incongruences when manager is missing  
gen ell = YearMonth ==FTLL
gen elh = YearMonth ==FTLH
gen ehh = YearMonth ==FTHH
gen ehl = YearMonth ==FTHL

* locals 
distinct IDlse if Event==0 & WL==1 // &YearMonth <=tm(2020m3)  
local c1 =  r(ndistinct)
distinct IDlse if Event==1 & WL==1  // &YearMonth <=tm(2020m3)  
local c2 =  r(ndistinct)
distinct IDlse if ell==1 & WL==1 //  &YearMonth <=tm(2020m3)  
local c3 =  r(ndistinct)
distinct IDlse if elh==1 & WL==1 //  &YearMonth <=tm(2020m3)   
local c4 =  r(ndistinct)
distinct IDlse if ehl==1 & WL==1 // &YearMonth <=tm(2020m3)   
local c5 =  r(ndistinct)
distinct IDlse if ehh==1 & WL==1 //  &YearMonth <=tm(2020m3)  
local c6 =  r(ndistinct)

balancetable (mean if Event==0 ) (mean if Event==1 &WL2==1 ) (mean if ell==1 &WL2==1 ) (mean if elh==1 &WL2==1)  (mean if ehl==1 &WL2==1) (mean if ehh==1 &WL2==1)  $CHARS $PRE    using "$analysis/Results/2.Descriptives/Transition.tex" , ///
replace   noobservations  varla vce(cluster IDlseMHR)  ctitles("No event" "Had event" "Low to Low" "Low to High" "High to Low" "High to High") ///
postfoot("\hline" "\multicolumn{1}{l}{Unique num. workers, work level 1} &  `c1' & `c2' & `c3' & `c4' & `c5' & `c6' \\ " "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. This table shows summary statics across event types, and between the groups who do and do not experience events. For event columns, I show the average of employees in the month they experience the event; for those who never experience an event I show the average of all such individuals across their tenure at the firm." "\end{tablenotes}")
*cov(i.CountryY i.Func)

* pvalues 
gen low = .
replace low =1 if (YearMonth ==FTLL | YearMonth ==FTLH) 
gen high = .
replace high =1 if (YearMonth ==FTHL | YearMonth ==FTHH) 
gen ll = FTLL!=.
gen lh = FTLH!=.
gen hh = FTHH!=.
gen hl = FTHL!=.

* locals 
distinct IDlse if Event!=. & WL==1  //& WL==1 &YearMonth <=tm(2020m3)
local c1 =  r(ndistinct)
distinct IDlse if low==1 & WL==1  // & WL==1 &YearMonth <=tm(2020m3)
local c2 =  r(ndistinct)
distinct IDlse if high==1 & WL==1  // & WL==1 &YearMonth <=tm(2020m3)
local c3 =  r(ndistinct)

balancetable (diff Event ) (diff lh if low==1 &WL2==1) (diff hl if high==1&WL2==1 )  $CHARS $PRE  using "$analysis/Results/2.Descriptives/TransitionDiff.tex", ///
replace  noobservations varla vce(cluster IDlseMHR)  ctitles("Event" "Low to High versus to Low" "High to Low versus to High") ///
postfoot("\hline" "\multicolumn{1}{l}{Unique Individuals} &  `c1' & `c2' & `c3' \\ " "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. This table shows p-values for the difference in means to show balance of covariates across event types, and between the groups who do and do not experience events. Outgoing managers are defined as the manager of unit in the month before a transition event; incoming managers are those who are assigned to a unit in the month of the event. For event columns, I show the average of employees in the month they experience the event; for those who never experience an event I show the average of all such individuals across their tenure at the firm." "\end{tablenotes}")
*cov(i.CountryY i.Func)

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
save "$managersdta/Temp/MEvent.dta" , replace 
restore 

drop uLHInM uLHOutM uLLInM uLLOutM uHHInM uHHOutM uHLInM uHLOutM
merge 1:1 IDlse YearMonth using "$managersdta/Temp/MEvent.dta", keepusing(uLHInM uLHOutM uLLInM uLLOutM uHHInM uHHOutM uHLInM uHLOutM)
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
*cov(i.CountryY i.Func)

*"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." "The difference in means is computed using standard errors clustered at the manager level and controlling for CountryXYear fixed effects." "\end{tablenotes}")

*"Notes. This table presents summary statistics for managers and demonstrates balance of covariates across event types, and between the groups who do and do not experience events. Outgoing managers are defined as the manager of unit in the month before a transition event; incoming managers are those who are assigned to a unit in the month of the event. For event columns, I show the average of managers in the month they experience the event; for those who never experience an event I show the average of all such individuals across their tenure at the firm." "\end{tablenotes}"

* INCOMING // Although this does not make logical sense because obv the incoming manager will differ btw LH and LL (by definition)
distinct IDlse if IEvent==0 &YearMonth <=tm(2020m3)   & WL==2
local c1 =  r(ndistinct)
distinct IDlse if i==1 &YearMonth <=tm(2020m3)   
local c2 =  r(ndistinct)
distinct IDlse if uLLInM!=. &YearMonth <=tm(2020m3)   
local c3 =  r(ndistinct)
distinct IDlse if uLHInM!=. &YearMonth <=tm(2020m3)   
local c4 =  r(ndistinct)
distinct IDlse if uHLInM!=. &YearMonth <=tm(2020m3)   
local c5 =  r(ndistinct)
distinct IDlse if uHHInM!=. &YearMonth <=tm(2020m3)   
local c6 =  r(ndistinct)
* select the whole period for managers that never rotate but only the transition month for those who do
balancetable (mean if IEvent==0 & WL==2) (mean if i==1 ) (mean if  uLLInM!=. ) (mean if  uLHInM!=. )  (mean if  uHLInM!=. ) (mean if uHHInM!=. )  $CHARS $TEAM $PRE   using "$analysis/Results/2.Descriptives/TransitionIM.tex" , ///
replace    varla noobservations  vce(cluster IDlseMHR) ctitles("No event" "Had event" "Low to Low" "Low to High" "High to Low" "High to High") ///
postfoot("\hline" "\multicolumn{1}{l}{Unique Individuals} & `c1' & `c2' & `c3' & `c4' & `c5' & `c6' \\ " "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. This table shows summary statics across event types, and between the groups who do and do not experience events. Outgoing managers are defined as the manager of the team in the month before a transition event; incoming managers are those who are assigned to a team in the month of the event. For event columns, I show the average of managers in the month they experience the event; for those who never experience an event I show the average across their tenure at the firm." "\end{tablenotes}")
*cov(i.CountryY i.Func) 

********************************************************************************
* TIMING OF MANAGER ROTATION: INCOMING MANAGER 
********************************************************************************

use "$managersdta/SwitchersAllSameTeam2.dta", clear 

* panel of the rotating managers, USEFUL TO LOOK AT MANAGER CHARACTERISTICS (LATER IN CODE) 
preserve 
keep  if KEi == 0 
keep IDlseMHR YearMonth 
duplicates  drop IDlseMHR YearMonth, force 
gen o = 1 
bys IDlseMHR (YearMonth), sort : gen TransitionNum = sum(o)
rename YearMonth TransitionMonth
reshape wide TransitionMonth, i(IDlseMHR) j(TransitionNum)
isid IDlseMHR
rename IDlseMHR IDlse  
save "$managersdta/Temp/MRotating.dta" , replace 
restore 

format Ei %tm
ta Ei, sort 
gen EiYear = year(dofm(Ei))
ta EiYear, sort // 75% of events before 2016
* note that 2016 is the middle year: there are 5 years before it and 5 years after it 

bys IDlse: egen MT = mean(cond(KEi==0 & WL2==1, IDlseMHR,.)) // take the manager that transitions

keep MT Ei 
duplicates drop 
rename MT IDlseMHR // manager ID
save "$managersdta/Temp/TimingInM2.dta", replace // list of incoming managers, one month before transitions

use "$managersdta/Temp/TimingInM2.dta", clear
sort IDlseMHR  Ei 
duplicates drop IDlseMHR, force // drops all but the first occurrence of each group of duplicated observations.
merge 1:m  IDlseMHR using "$managersdta/Temp/MType.dta"
keep if _merge==3
drop _merge
* get cumulative
gen IDlse = IDlseMHR
merge 1:1  IDlse YearMonth using "$managersdta/AllSnapshotMCulture.dta", keepusing(TransferSJC TransferSubFuncC)
keep if _merge==3
drop _merge 

sort IDlseMHR YearMonth

gen Window = YearMonth- Ei

* new hires - so to have non censored time in previous job 
* but might not be accurate because you could have been a worker before (this is min month of manager)
bys IDlseMHR: egen yearm = min(YearMonth)
format yearm %tm

* job before transition
encode  StandardJobM, gen( StandardJobME)
ge mmSJ  = StandardJobME if Window==-1 // job before
bys IDlseMHR: egen JobBefore= min( mmSJ) 
ge mmSJC  = TransferSJC if Window==-1 // job before C
bys IDlseMHR: egen JobBeforeC= min( mmSJC) 

ge mmASJ  = StandardJobME if Window==0 // job after
bys IDlseMHR: egen JobAfter= min( mmASJ) 
la val JobBefore mmSJ

* subfunc
ge mmSF  = SubFuncM if Window==-1
bys IDlseMHR: egen SFBefore= min( mmSF)
ge mmASF  = SubFuncM if Window==0
bys IDlseMHR: egen SFAfter= min( mmASF)
ge mmSFC  = TransferSubFuncC if Window==-1 // job before C
bys IDlseMHR: egen SFBeforeC= min( mmSFC) 

* min window
bys IDlseMHR: egen mW= min(Window) // min window
gen minWSJ= StandardJobME if mW == Window // first ever job 
bys  IDlseMHR: egen mminWSJ= min(minWSJ)
gen minWSF= SubFuncM if mW == Window // first ever SF
bys IDlseMHR: egen mminWSF= min(minWSF)

*indicator for same job as job before
gen i =  (StandardJobME == JobBefore   & Window<0 ) if  mminWSJ != JobBefore &  mW <0 &JobBefore!= JobAfter
gen iSF =  ( SubFuncM == SFBefore  & Window<0 ) if  mminWSF != SFBefore &  mW <0 & SFBefore!= SFAfter 

* total months in previous position
bys IDlseMHR : egen tot = sum(i) if  mminWSJ != JobBefore &  mW <0 & JobBefore!= JobAfter
bys IDlseMHR : egen totSF = sum(iSF) if  mminWSF != SFBefore &  mW <0 & SFBefore!= SFAfter 

**# FINAL GRAPH ON PAPER
cdfplot totSF if Window==-1 & Ei>=tm(2019m1) &   Ei<=tm(2019m12), xlabel(0(5)85)  ylabel(0(0.1)1) xtitle("Months in previous position (manager)") xline(14) xline(31)

graph save "$analysis/Results/2.Descriptives/MTimingInSFcdf.gph", replace 
graph export "$analysis/Results/2.Descriptives/MTimingInSFcdf.png", replace 

hist totSF if Window==-1 & Ei>=tm(2019m1) &   Ei<=tm(2019m12), xlabel(0(5)85) bin(8) frac xtitle("Months in previous position (manager)") 
graph save "$analysis/Results/2.Descriptives/MTimingInSF.gph", replace 
graph export "$analysis/Results/2.Descriptives/MTimingInSF.png", replace 

/* TIMING OF MANAGER ROTATION: INCOMING MANAGER 
use "$managersdta/SwitchersAllSameTeam.dta", clear 

bys IDlse: egen MT = mean(cond(KEi==0 & WL2==1, IDlseMHR,.)) // take the manager that transitions

keep MT Ei 
duplicates drop 
gen YearMonth = Ei -1 // one month before transitioning 
rename MT IDlse // manager ID
merge 1:1 IDlse YearMonth using "$managersdta/AllSnapshotMCulture.dta"
keep if _merge ==3 
 
hist MonthsSJ  , xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash)) xline(35, lpattern(dash))

hist MonthsSJ if YearHire<9999  & YearMonth>=tm(2013m1), xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash)) xline(35, lpattern(dash))

kdensity MonthsSJ , lcolor(navy) xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash) lcolor(maroon)) xline(35, lpattern(dash) lcolor(maroon)) title("") ysize(4) legend(off) note("")
graph  save "$analysis/Results/2.Descriptives/MTiming.gph", replace 
graph export "$analysis/Results/2.Descriptives/MTiming.png", replace 

cdfplot MonthsSJ, xlabel(0(5)150) xtitle("Months in previous position (manager)") title("") ysize(3.8) legend(off) note("")
graph save "$analysis/Results/2.Descriptives/MTimingcdf.gph", replace 
graph export "$analysis/Results/2.Descriptives/MTimingcdf.png", replace 
* tw  hist MonthsSJM if tm==1, color(*.5) || kdensity MonthsSJM if tm==1, lcolor(navy) xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash) lcolor(maroon)) xline(30, lpattern(dash) lcolor(maroon)) title("") ysize(4) legend(off)
*hist MonthsSubFuncM, xtitle("Months in previous position (manager)") xlabel(0(5)130)

* TIMING OF MANAGER ROTATION: OUTGOING MANAGER 
use "$managersdta/SwitchersAllSameTeam.dta", clear 

bys IDlse: egen MT = mean(cond(KEi==-1 & WL2==1, IDlseMHR,.)) // take the manager that transitions

keep MT Ei 
duplicates drop 
gen YearMonth = Ei -1 // one month before transitioning 
rename MT IDlse // manager ID
merge 1:1 IDlse YearMonth using "$managersdta/AllSnapshotMCulture.dta"
keep if _merge ==3 

gen day=dofm(YearMonth)
format day %td
gen quarter=qofd(day)
format quarter %tq

hist MonthsSJ  , xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash)) xline(30, lpattern(dash))
 
kdensity MonthsSJ , lcolor(navy) xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash) lcolor(maroon)) xline(35, lpattern(dash) lcolor(maroon)) title("") ysize(4) legend(off) note("")
graph  save "$analysis/Results/2.Descriptives/MTimingOut.gph", replace 
graph export "$analysis/Results/2.Descriptives/MTimingOut.png", replace 

cdfplot MonthsSJ, xlabel(0(5)150) xtitle("Months in previous position (manager)") title("") ysize(3.8) legend(off) note("")
graph save "$analysis/Results/2.Descriptives/MTimingOutcdf.gph", replace 
graph export "$analysis/Results/2.Descriptives/MTimingOutcdf.png", replace 
* tw  hist MonthsSJM if tm==1, color(*.5) || kdensity MonthsSJM if tm==1, lcolor(navy) xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash) lcolor(maroon)) xline(30, lpattern(dash) lcolor(maroon)) title("") ysize(4) legend(off)
*hist MonthsSubFuncM, xtitle("Months in previous position (manager)") xlabel(0(5)130)

* quarterly level

preserve

collapse (last) MonthsSJ, by(IDlse quarter)

gen qMonthsSJ=  MonthsSJ/3
hist qMonthsSJ

cdfplot qMonthsSJ , xlabel(0(4)40) xtitle("Quarters in previous position (manager)") title("") ysize(3.8) legend(off) note("")
graph save "$analysis/Results/2.Descriptives/MTimingOutcdfQ.gph", replace 
graph export "$analysis/Results/2.Descriptives/MTimingOutcdfQ.png", replace 
restore
*/
********************************************************************************
* Manager rotations across teams 
********************************************************************************

* how many teams within a given subfunction, month and country? 
egen tss = tag(IDlseMHR SubFunc YearMonth Country)
bys SubFunc YearMonth Country: egen tto = sum(tss)
su tto, d
su tto if tss==1, d

preserve 
collapse (sum) tss, by( SubFunc YearMonth Country)
su tss , d 
restore 

cap drop tss tto 

* how many teams within a given subfunction and month? 
egen tss = tag(IDlseMHR SubFunc YearMonth )
bys SubFunc YearMonth: egen tto = sum(tss)
su tto, d
su tto if tss==1, d

preserve 
collapse (sum) tss, by( SubFunc YearMonth )
su tss , d 
restore 

* does the manager change job/subfunction when rotating team? 
ta TransferSJM if KEi==0& WLM>1 // 75% do not change job title 
ta TransferInternalM if KEi==0& WLM>1 // 75% do not change job title 

////////////////////////////////////////////////////////////////////////////////
* TABLE/FIGURE DOCUMENTING MANAGER ROTATIONS - REASONS 
////////////////////////////////////////////////////////////////////////////////

* How many managers do this quasi-random rotations? 
use "$managersdta/Temp/ListEventsTeam" , clear // list of events 
distinct IDlseMHR  //  31788

use "$managersdta/AllSnapshotMCultureMType.dta"  , clear 
distinct IDlseMHR //   46944

 di     31788/  46944 // 70% 
 
********************************************************************************
* 1) reasons for departing managers 
********************************************************************************

* first take the list of manager-events 
use "$managersdta/Temp/ListEventsTeam" , clear // list of events 

* get the type of the post manager 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MType.dta" , keepusing(EarlyAgeM)
drop if _merge ==2
drop _merge 

* need to tailor to actual manager type considered 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50)
drop if _merge ==2
drop _merge

rename (IDlseMHR MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 EarlyAgeM) =Post
* now get the outgoing manager 

rename IDlseMHRPreMost IDlse 

gen YearMonthPre = YearMonth -1 // month before the event 
format (YearMonth YearMonthPre) %tm 
duplicates drop IDlse YearMonth , force 

sort IDlse YearMonth 
bys IDlse : gen dup = cond(_N==1,0,_n)
replace dup = 1 if dup ==0 

rename YearMonth Event 
reshape wide Event  , i(IDlse MFEBayesPromSG75Post MFEBayesPromWL75Post MFEBayesPromSG50Post MFEBayesPromWL50Post EarlyAgeMPost IDlseMHRPost) j(dup) // manager level, event wide 

gen OutgoingM = 1 

keep if EarlyAgeMPost!=. 
isid IDlse IDlseMHRPost
duplicates drop IDlse, force // some duplicates due to same pre manager being associated to different post manager 
* then merge with snapshot data to get characteristics 
merge 1:m  IDlse using "$managersdta/AllSnapshotMCultureMType.dta"  
keep if _merge ==3 
drop _merge
di 2/8 // 25% of managers in the dataset

forval i =1/3{ // 18 are the total number 
gen WindowEvent`i' = YearMonth - Event`i'
}

forval i =1/3{ // 18 are the total number 

forvalues l = 1/12 { // normalize -1 and r(min)
	gen F`l'Window`i' = WindowEvent`i'==-`l'
}

forvalues l = 0/12 { // normalize -1 and r(min)
	gen L`l'Window`i' = WindowEvent`i'==`l'
}
}

* Construct Possible reasons 
********************************************************************************

* Change in Office
gsort IDlse YearMonth
gen ChangeOffice = 0 & OfficeCode !=.
replace  ChangeOffice = 1 if IDlse == IDlse[_n-1] & OfficeCode != OfficeCode[_n-1] & OfficeCode !=.
label var ChangeOffice "Equals 1 when OfficeCode is different than in the preceding month"

* Job transfer variables: Org5 
gsort IDlse YearMonth
gen TransferOrg5 = 0 if Org5 !=.
replace  TransferOrg5 = 1 if IDlse == IDlse[_n-1] & Org5 != Org5[_n-1] & Org5 !=.
label var  TransferOrg5 "Dummy, equals 1 in the month when Org5 is diff. than in the preceding"

* Job transfer variables: EmpStatus 
gsort IDlse YearMonth
gen ChangeEmpStatus = 0 if EmpStatus !=.
replace  ChangeEmpStatus = 1 if IDlse == IDlse[_n-1] & EmpStatus != EmpStatus[_n-1] & EmpStatus !=.
label var  ChangeEmpStatus "Dummy, equals 1 in the month when EmpStatus is diff. than in the preceding"

* Job transfer variables: EmpType 
gsort IDlse YearMonth
gen ChangeEmpType = 0 if  EmpType  !=.
replace  ChangeEmpType  = 1 if IDlse == IDlse[_n-1] & EmpType != EmpType[_n-1] & EmpType !=.
label var  ChangeEmpType "Dummy, equals 1 in the month when EmpType is diff. than in the preceding"

* leave of absence dummy
gen ExclusionLeave = 1 if ExclusionGroup ==  "Leave of Absence" | ExclusionGroup == "Leave of absence"
replace ExclusionLeave = 0 if ExclusionGroup !="" & ExclusionLeave!=1

* no longer manager dummy 
gen NoManager = 1 - Manager 

* Changes to incoming manager around the time of the event (3 or 6 months)
foreach y in   PromWL ChangeSalaryGrade TransferInternal TransferOrg4 TransferOrg5 ChangeEmpType ChangeEmpStatus  ChangeOffice TransferSJ TransferPTitle ChangeM NoManager  {
	forval i = 1/3{ // 18 are the total number 
bys IDlse : egen `y'v3_`i' = max(cond( F1Window`i'==1 |  F2Window`i'==1  | F3Window`i'==1 | L0Window`i'==1 | L1Window`i'==1 |  L2Window`i'==1  | L3Window`i'==1 , `y' ,.))  

bys IDlse : egen `y'v6_`i' = max(cond( F1Window`i'==1 |  F2Window`i'==1  | F3Window`i'==1 | F4Window`i'==1 | F5Window`i'==1 | F6Window`i'==1 | L0Window`i'==1 | L1Window`i'==1 |  L2Window`i'==1  | L3Window`i'==1 | L4Window`i'==1 | L5Window`i'==1 | L6Window`i'==1 , `y' ,.)) 

} 
}

* Leave - LeaveReason* & Exit 
	forval i = 1/3{ // 18 are the total number 
		bys IDlse : egen LeaveTypeCleanv3_`i' = max(cond( F1Window`i'==1 & LeaveTypeClean!="" |  F2Window`i'==1 & LeaveTypeClean!="" | F3Window`i'==1 & LeaveTypeClean!="" | L0Window`i'==1 & LeaveTypeClean!="", 1 ,0)) 
		
	bys IDlse : egen LeaveTypeCleanv6_`i' = max(cond( F1Window`i'==1 & LeaveTypeClean!="" |  F2Window`i'==1 & LeaveTypeClean!="" | F3Window`i'==1 & LeaveTypeClean!="" | F4Window`i'==1 & LeaveTypeClean!="" | F5Window`i'==1 & LeaveTypeClean!="" | F6Window`i'==1 & LeaveTypeClean!="" | L0Window`i'==1 & LeaveTypeClean!="", 1 ,0)) 

	foreach y in ExclusionLeave LeaverPerm LeaverVol LeaverInv {
	bys IDlse : egen `y'v3_`i' = max(cond( L0Window`i'==1 | L1Window`i'==1 |  L2Window`i'==1  | L3Window`i'==1 , `y' ,.))  

	bys IDlse : egen `y'v6_`i' = max(cond( L0Window`i'==1 | L1Window`i'==1 |  L2Window`i'==1  | L3Window`i'==1 | L4Window`i'==1 | L5Window`i'==1 | L6Window`i'==1 , `y' ,.)) 
	}
	}

su TeamSize if ChangeEmpStatusv6_1 ==0 & LeaveTypeCleanv6_1==0 & PromWLv6_1==0 & ChangeSalaryGradev6_1==0 & TransferInternalv6_1==0 & TransferOrg5v6_1==0 & TransferSJv6_1==0 & TransferPTitlev6_1==0 & LeaverPermv6_1==0 & ExclusionLeavev6_1 ==0& MFEBayesPromSG75Post!=., d
	
* save dataset 
keep if YearMonth == Event1 
collapse EarlyAgeMPost MFEBayesPromSG75Post NoManagerv*_1 ChangeMv*_1 ExclusionLeavev*_1 ChangeEmpTypev*_1 LeaverPermv*_1 LeaverVolv*_1 LeaverInvv*_1 TransferInternalv*_1 TransferSJv*_1 TransferPTitlev*_1 PromWLv*_1 ChangeSalaryGradev*_1 TransferOrg4v*_1 TransferOrg5v*_1 ChangeOfficev*_1 ChangeEmpStatusv*_1 LeaveTypeCleanv*_1, by(IDlse)
save "$managersdta/Temp/OldManagerRotations.dta", replace 

* FINAL GRAPH
use "$managersdta/Temp/OldManagerRotations.dta", clear

*graph bar  *v6_1

egen OnLeavev6_1 = rowmax(ChangeEmpTypev6_1 ChangeEmpStatusv6_1  LeaveTypeCleanv6_1 ExclusionLeavev6_1) // leave 
egen Promv6_1 = rowmax( PromWLv6_1 ChangeSalaryGradev6_1) // promotion 
egen Transferv6_1 = rowmax( TransferInternalv6_1 TransferOrg5v6_1 TransferSJv6_1 TransferPTitlev6_1) // transfer 

* make choices mutually exclusive 
replace NoManagerv6_1 = 0 if Transferv6_1==1 |  Promv6_1==1 | LeaverPermv6_1==1 | OnLeavev6_1==1 | ChangeMv6_1==1 // change manager 
replace ChangeMv6_1 = 0 if Transferv6_1==1 |  Promv6_1==1 | LeaverPermv6_1==1 | OnLeavev6_1==1 | NoManagerv6_1==1 // change manager
replace LeaverPermv6_1 = 0 if Transferv6_1==1 |  Promv6_1==1 |  NoManagerv6_1==1 | OnLeavev6_1==1 | ChangeMv6_1==1 // leaverperm
replace Promv6_1 = 0 if Transferv6_1==1 |  OnLeavev6_1==1 | LeaverPermv6_1==1 | ChangeMv6_1 ==1 | NoManagerv6_1==1 // vertical promotion 
replace OnLeavev6_1 = 0 if Transferv6_1==1 |  Promv6_1==1 | LeaverPermv6_1==1 | ChangeMv6_1 ==1 | NoManagerv6_1==1 // on leave 
replace Transferv6_1 = 0 if Promv6_1==1 |  OnLeavev6_1==1 | LeaverPermv6_1==1 | ChangeMv6_1 ==1 | NoManagerv6_1==1 // lateral transfer 

* check mutually exclusive 
egen Explainedv6_1 = rowmax(Transferv6_1 Promv6_1 OnLeavev6_1 LeaverPermv6_1 ChangeMv6_1 NoManagerv6_1)
egen tot1 = rowtotal(Transferv6_1 Promv6_1 OnLeavev6_1 LeaverPermv6_1 ChangeMv6_1 NoManagerv6_1) 
ta tot1 Explainedv6_1

local list ""
foreach v in Transferv6_1 Promv6_1 OnLeavev6_1 LeaverPermv6_1 ChangeMv6_1 NoManagerv6_1{
	su `v'
	local `v'm = r(mean)	
	local list "`list' + ``v'm'"
}
di `list' 

ta NoManagerv6_1 // NOTE: basically everyone remains a manager after the event 
* the only last reason for the team transfer could be re-organization 
* graph
label def EarlyAgeMPost  0 "Incoming manager: non fast track" 1 "Incoming manager: fast track"
label value EarlyAgeMPost  EarlyAgeMPost 
cibar Promv6_1, over(EarlyAgeMPost )   graphopts(ytitle("Probability manager outgoing because of promotion", size(medium)) scheme(white_hue)  legend(position(1) rows(1)  size(medium))) 
graph save "$analysis/Results/2.Descriptives/RotationPromPost.gph", replace 
graph export "$analysis/Results/2.Descriptives/RotationPromPost.png", replace 

 graph bar Transferv6_1 ChangeMv6_1 LeaverPermv6_1 OnLeavev6_1 Promv6_1 , legend(label(1 "Internal Transfer") label(2 "Change of Reporting Lines") label(3 "Exit Firm") label(4 "On Leave")     label(5 "Promotion") ) title("Reasons for manager change: outgoing manager") 
graph save "$analysis/Results/2.Descriptives/RotationReasonOld.gph", replace 
graph export "$analysis/Results/2.Descriptives/RotationReasonOld.png", replace 

********************************************************************************
* 2) reasons for incoming managers 
********************************************************************************

* first take the list of manager-events 
use "$managersdta/Temp/ListEventsTeam" , clear // list of events 

rename IDlseMHR IDlseMHRNew
rename IDlseMHRPreMost IDlseMHR 
* get the manager type of the outgoing manager 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50)
drop if _merge ==2
drop _merge 

* need to tailor to actual manager type considered 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MType.dta" , keepusing(EarlyAgeM)
drop if _merge ==2
drop _merge 

rename IDlseMHRNew IDlse 

rename (MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 EarlyAgeM  IDlseMHR) =Pre

sort IDlse YearMonth 
bys IDlse : gen dup = cond(_N==1,0,_n)
replace dup = 1 if dup ==0 

rename YearMonth Event 
reshape wide Event  , i(IDlse IDlseMHRPre MFEBayesPromSG75Pre MFEBayesPromWL75Pre MFEBayesPromSG50Pre MFEBayesPromWL50Pre EarlyAgeMPre) j(dup) // manager level, event wide 

gen IncomingM = 1 
xtset IDlse IDlseMHRPre
duplicates drop IDlse , force 

* then merge with snapshot data to get characteristics 
merge 1:m  IDlse using "$managersdta/AllSnapshotMCultureMType.dta" 
keep if _merge ==3 

forval i =1/3{ // 14 are the total number 
gen WindowEvent`i' = YearMonth - Event`i'
}

forval i =1/3{ // 14 are the total number 

forvalues l = 1/12 { // normalize -1 and r(min)
	gen F`l'Window`i' = WindowEvent`i'==-`l'
}

forvalues l = 0/12 { // normalize -1 and r(min)
	gen L`l'Window`i' = WindowEvent`i'==`l'
}
}

* Construct Possible reasons 
********************************************************************************

* New hire 
gen NewHire = Tenure <1

* Change in Office
gsort IDlse YearMonth
gen ChangeOffice = 0 & OfficeCode !=.
replace  ChangeOffice = 1 if IDlse == IDlse[_n-1] & OfficeCode != OfficeCode[_n-1] & OfficeCode !=.
label var ChangeOffice "Equals 1 when OfficeCode is different than in the preceding month"

* Job transfer variables: Org5 
gsort IDlse YearMonth
gen TransferOrg5 = 0 if Org5 !=.
replace  TransferOrg5 = 1 if IDlse == IDlse[_n-1] & Org5 != Org5[_n-1] & Org5 !=.
label var  TransferOrg5 "Dummy, equals 1 in the month when Org5 is diff. than in the preceding"

* Job transfer variables: EmpStatus 
gsort IDlse YearMonth
gen ChangeEmpStatus = 0 if EmpStatus !=.
replace  ChangeEmpStatus = 1 if IDlse == IDlse[_n-1] & EmpStatus != EmpStatus[_n-1] & EmpStatus !=.
label var  ChangeEmpStatus "Dummy, equals 1 in the month when EmpStatus is diff. than in the preceding"

* Job transfer variables: EmpType 
gsort IDlse YearMonth
gen ChangeEmpType = 0 if  EmpType  !=.
replace  ChangeEmpType  = 1 if IDlse == IDlse[_n-1] & EmpType != EmpType[_n-1] & EmpType !=.
label var  ChangeEmpType "Dummy, equals 1 in the month when EmpType is diff. than in the preceding"

* leave of absence dummy
gen ExclusionLeave = 1 if ExclusionGroup ==  "Leave of Absence" | ExclusionGroup == "Leave of absence"
replace ExclusionLeave = 0 if ExclusionGroup !="" & ExclusionLeave!=1

* Changes to incoming manager around the time of the event (3 or 6 months)
foreach y in  ChangeM NewHire PromWL ChangeSalaryGrade TransferInternal TransferOrg4 TransferOrg5 ChangeEmpType ChangeEmpStatus  ChangeOffice TransferSJ TransferPTitle {
	forval i = 1/3{ // 14 are the total number 
bys IDlse : egen `y'v3_`i' = max(cond( F1Window`i'==1 |  F2Window`i'==1  | F3Window`i'==1 | L0Window`i'==1 | L1Window`i'==1 |  L2Window`i'==1  | L3Window`i'==1 , `y' ,.))  

bys IDlse : egen `y'v6_`i' = max(cond( F1Window`i'==1 |  F2Window`i'==1  | F3Window`i'==1 | F4Window`i'==1 | F5Window`i'==1 | F6Window`i'==1 | L0Window`i'==1 | L1Window`i'==1 |  L2Window`i'==1  | L3Window`i'==1 | L4Window`i'==1 | L5Window`i'==1 | L6Window`i'==1 , `y' ,.)) 

} 
}

* Leave - LeaveReason* & Exit 
	forval i = 1/3{ // 14 are the total number 
		bys IDlse : egen LeaveTypeCleanv3_`i' = max(cond( F1Window`i'==1 & LeaveTypeClean!="" |  F2Window`i'==1 & LeaveTypeClean!="" | F3Window`i'==1 & LeaveTypeClean!="" | L0Window`i'==1 & LeaveTypeClean!="", 1 ,0)) 
		
	bys IDlse : egen LeaveTypeCleanv6_`i' = max(cond( F1Window`i'==1 & LeaveTypeClean!="" |  F2Window`i'==1 & LeaveTypeClean!="" | F3Window`i'==1 & LeaveTypeClean!="" | F4Window`i'==1 & LeaveTypeClean!="" | F5Window`i'==1 & LeaveTypeClean!="" | F6Window`i'==1 & LeaveTypeClean!="" | L0Window`i'==1 & LeaveTypeClean!="", 1 ,0)) 

	foreach y in ExclusionLeave LeaverPerm LeaverVol LeaverInv {
	bys IDlse : egen `y'v3_`i' = max(cond( L0Window`i'==1 | L1Window`i'==1 |  L2Window`i'==1  | L3Window`i'==1 , `y' ,.))  

	bys IDlse : egen `y'v6_`i' = max(cond( L0Window`i'==1 | L1Window`i'==1 |  L2Window`i'==1  | L3Window`i'==1 | L4Window`i'==1 | L5Window`i'==1 | L6Window`i'==1 , `y' ,.)) 
	}
	}

su TeamSize if ChangeEmpStatusv6_1 ==0 & LeaveTypeCleanv6_1==0 & PromWLv6_1==0 & ChangeSalaryGradev6_1==0 & TransferInternalv6_1==0 & TransferOrg5v6_1==0 & TransferSJv6_1==0 & TransferPTitlev6_1==0 & LeaverPermv6_1==0 & ExclusionLeavev6_1 ==0& MFEBayesPromSG75Pre!=., d
	
* save dataset 
keep if YearMonth == Event1 
collapse EarlyAgeMPre MFEBayesPromSG75Pre ChangeMv*_1 NewHirev*_1 ExclusionLeavev*_1 ChangeEmpTypev*_1 LeaverPermv*_1 LeaverVolv*_1 LeaverInvv*_1 TransferInternalv*_1 TransferSJv*_1 TransferPTitlev*_1 PromWLv*_1 ChangeSalaryGradev*_1 TransferOrg4v*_1 TransferOrg5v*_1 ChangeOfficev*_1 ChangeEmpStatusv*_1 LeaveTypeCleanv*_1, by(IDlse)
save "$managersdta/Temp/NewManagerRotations.dta", replace 

* FINAL GRAPH
use "$managersdta/Temp/NewManagerRotations.dta", clear

*graph bar  *v6_1

egen OnLeavev6_1 = rowmax(ChangeEmpTypev6_1 ChangeEmpStatusv6_1  LeaveTypeCleanv6_1 ExclusionLeavev6_1) // leave 
egen Promv6_1 = rowmax( PromWLv6_1 ChangeSalaryGradev6_1) // promotion 
egen Transferv6_1 = rowmax( TransferInternalv6_1 TransferOrg5v6_1 TransferSJv6_1 TransferPTitlev6_1) // transfer 

* make choices mutually exclusive 
replace NewHirev6_1 = 0 if Transferv6_1==1 |  Promv6_1==1    |  OnLeavev6_1==1 | ChangeMv6_1==1 // on leave 
replace ChangeMv6_1 = 0 if Transferv6_1==1 |  Promv6_1==1    |  OnLeavev6_1==1 |  NewHirev6_1==1 // change manager 
replace Promv6_1 = 0 if Transferv6_1==1    |  OnLeavev6_1==1 |  NewHirev6_1==1 | ChangeMv6_1==1  // vertical promotion 
replace OnLeavev6_1 = 0 if Transferv6_1==1 |  Promv6_1==1    |  NewHirev6_1==1 | ChangeMv6_1==1 // on leave 
replace Transferv6_1 = 0 if Promv6_1==1    |  OnLeavev6_1==1 |  NewHirev6_1==1 | ChangeMv6_1==1  // lateral transfer 

* check mutually exclusive 
egen Explainedv6_1 = rowmax(Transferv6_1 Promv6_1 OnLeavev6_1  )
egen tot1 = rowtotal(Transferv6_1 Promv6_1 OnLeavev6_1 ) 
ta tot1 Explainedv6_1

local list ""
foreach v in Transferv6_1 Promv6_1 OnLeavev6_1  {
	su `v'
	local `v'm = r(mean)	
	local list "`list' + ``v'm'"
}
di `list' 

label def EarlyAgeMPre  0 "Outgoing manager: non fast track" 1 "Outgoing manager: fast track"
label value EarlyAgeMPre  EarlyAgeMPre 
cibar Promv6_1, over(EarlyAgeMPre )   graphopts(ytitle("Incoming manager due to promotion") scheme(burd5))  
graph save "$analysis/Results/2.Descriptives/RotationPromPre.gph", replace 
graph export "$analysis/Results/2.Descriptives/RotationPromPre.png", replace 
* the only last reason for the team transfer could be re-organization 
* graph 
 graph bar Transferv6_1 ChangeMv6_1 NewHirev6_1  OnLeavev6_1 Promv6_1  , legend(label(1 "Internal Transfer") label(2 "Change of Reporting Lines") label(3 "New Hire")  label(4 "On Leave") label(5 "Promotion")  ) title("Reasons for manager change: incoming manager") 
graph save "$analysis/Results/2.Descriptives/RotationReasonNew.gph", replace 
graph export "$analysis/Results/2.Descriptives/RotationReasonNew.png", replace 

////////////////////////////////////////////////////////////////////////////////
* MORE DETAILS ON MANAGER ROTATIONS 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/AllSnapshotMCulture.dta", clear 
merge m:1 IDlse using   "$managersdta/Temp/MRotating.dta" // panel of the rotating managers in the natural experiment 
keep if _merge ==3 
drop _merge 

reg TransferInternal EarlyAge if YearMonth >=TransitionMonth1 & WL==2, vce(cluster IDlse)


su TransferInternalC if WL==3 & PromWL==1 // at least 3 rotations before a WL promotion 

////////////////////////////////////////////////////////////////////////////////
* UNDERSTANDING MANAGER ROTATIONS after transition: does employee change job when changing manager? 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 

* transition manager 
bys IDlse: egen ManagerEvent = min(cond( KEi==0, IDlseMHR,. ))  // new manager from transition "event manager"
bys IDlse: egen LastMonth = max(cond(IDlseMHR == ManagerEvent, YearMonth,. ))  // latest month with the event mananger

* identify the first manager change after event 
sort IDlse YearMonth 
gen o =1 
bys IDlse IDlseMHR (YearMonth), sort: egen Managercum = sum(o)
bys IDlse: egen FirstManagerMonth = min(cond(ChangeM==1 & KEi>0 & Managercum>3 , YearMonth,. ))  // minimum of 1 quarter with next manager (If I remove this condition, the share of connected barely changes and if anything it decreases)
format  FirstManagerMonth  %tm

* consider job transfers under diff manager up to 6 months after manager change 
xtset IDlse YearMonth 
foreach v in TransferSJ TransferOrg4 {
	forval i = 1/6{
gen F`i'`v' = f.`v'
}
}
foreach var in TransferSJ  TransferOrg4{
egen F6m`var' = rowmax(`var' F1`var' F2`var' F3`var' F4`var' F5`var' F6`var' )
egen F3m`var' = rowmax(`var' F1`var' F2`var' F3`var' )
} 

ta F6mTransferSJ if YearMonth == FirstManagerMonth
ta F6mTransferOrg4 if YearMonth == FirstManagerMonth

ta F3mTransferSJ if YearMonth == FirstManagerMonth
ta F3mTransferSJ if YearMonth == FirstManagerMonth

////////////////////////////////////////////////////////////////////////////////
* UNDERSTANDING MANAGER ROTATIONS: EMPLOYEE DOES NOT CHANGE JOB TITLE but manager does
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

* 1) Sample restriction 1: I drop all employees with any instance of missing managers
bys IDlse: egen cM = count(cond(IDlseMHR==., YearMonth,.)) // count how many IDlse have missing manager info 
drop if cM > 0 // only keep IDlse for which manager id is never missing 
count if IDlseMHR==.

distinct IDlseMHR if TransferSJM ==1 | TransferInternalM==1 //  23787, number of distinct managers rotating internally
distinct IDlseMHR // 37202
* di   23787/37202 // 64%

* Employee job title changes 
forval i = 1/3{
	foreach var in TransferSJ TransferInternal{ 
	gen `var'F`i' = f`i'.`var'
	gen `var'L`i' = l`i'.`var'
	replace `var'F`i' = 0 if `var'F`i'==. 
	replace `var'L`i' = 0 if `var'L`i'==. 

}
}

* PREFERRED -2 & +2: Changing manager that transfers & employee does not transfer 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & MaxWLM>1 & (TransferInternalF1M==1 | TransferInternalM==1 | TransferInternalL1M==1  | TransferSJF1M==1 | TransferSJM==1 | TransferSJL1M==1   | TransferInternalF2M==1  | TransferInternalL2M==1  | TransferSJF2M==1 | TransferSJL2M==1   ) & (TransferInternalF1==0 & TransferInternal==0 & TransferInternalL1==0  & TransferSJF1==0 & TransferSJ==0 & TransferSJL1==0 & TransferInternalF2==0  & TransferInternalL2==0  & TransferSJF2==0 & TransferSJL2==0   )  // manager internal rotation 

* -1 and +1: Changing manager that transfers & employee does not transfer 
gen  ChangeMR1 = 0 
replace ChangeMR1 = 1 if ChangeM==1 & MaxWLM>1 & (TransferInternalF1M==1 | TransferInternalM==1 | TransferInternalL1M==1  | TransferSJF1M==1 | TransferSJM==1 | TransferSJL1M==1   ) & (TransferInternalF1==0 & TransferInternal==0 & TransferInternalL1==0  & TransferSJF1==0 & TransferSJ==0 & TransferSJL1==0   )  // manager internal rotation 

* ONLY SJ: Changing manager that transfers & employee does not transfer 
gen  ChangeMRSJ = 0 
replace ChangeMRSJ = 1 if ChangeM==1 & MaxWLM>1 & ( TransferSJF1M==1 | TransferSJM==1 | TransferSJL1M==1   ) & ( TransferSJF1==0 & TransferSJ==0 & TransferSJL1==0   )  // manager internal rotation 

* MORE MONTHS -2 & +1: Changing manager that transfers & employee does not transfer 
gen  ChangeMR4 = 0 
replace ChangeMR4 = 1 if ChangeM==1 & MaxWLM>1 & (TransferInternalF1M==1 | TransferInternalM==1 | TransferInternalL1M==1  | TransferSJF1M==1 | TransferSJM==1 | TransferSJL1M==1   | TransferInternalF2M==1  |  TransferSJF2M==1    ) & (TransferInternalF1==0 & TransferInternal==0 & TransferInternalL1==0  & TransferSJF1==0 & TransferSJ==0 & TransferSJL1==0 & TransferInternalF2==0   & TransferSJF2==0   )  // manager internal rotation 

* MORE MONTHS -3 & +3: Changing manager that transfers & employee does not transfer 
gen  ChangeMR3 = 0 
replace ChangeMR3 = 1 if ChangeM==1 & MaxWLM>1 & (TransferInternalF1M==1 | TransferInternalM==1 | TransferInternalL1M==1  | TransferSJF1M==1 | TransferSJM==1 | TransferSJL1M==1   | TransferInternalF2M==1  | TransferInternalL2M==1  | TransferSJF2M==1 | TransferSJL2M==1 | TransferInternalF3M==1  | TransferInternalL3M==1  | TransferSJF3M==1 | TransferSJL3M==1   ) & (TransferInternalF1==0 & TransferInternal==0 & TransferInternalL1==0  & TransferSJF1==0 & TransferSJ==0 & TransferSJL1==0 & TransferInternalF2==0  & TransferInternalL2==0  & TransferSJF2==0 & TransferSJL2==0 & TransferInternalF3==0  & TransferInternalL3==0  & TransferSJF3==0 & TransferSJL3==0   )  // manager internal rotation 

* REGRESSIONS 
gen ChangeM2 = ChangeM
replace ChangeM2 = 0 if FLTransferInternalM ==0 // only keeping manager changes due to manager moving laterally

gen ChangeMGrowth =  ChangeM2
replace 
esplot  TransferInternal if  insample==1,  event(ChangeM2  , replace )  window(-12 24)  period_length(3) vce(cluster IDlseMHR) absorb( CountryYM IDlse  ) estimate_reference
graph save  "$analysis/Results/2.Descriptives/ChangeM2.gph", replace

* general info on transfers 
ta TransferSJ TransferSubFunc // basically any change in Subfunc is reflected in standard job 
ta TransferSJ PromWL // basically any change in promotion is reflected in standard job 

xtset IDlse YearMonth 
distinct IDlseMHR if TransferInternalM ==1  // number of distinct managers rotating internally
distinct IDlseMHR
*  25435 /   42744 = 60% of manager 

distinct IDlseMHR if TransferSJM ==1  // number of distinct managers rotating internally
distinct IDlseMHR

* counting the number of transfers& taking into account lag/different reporting times  
gen FLTransferInternalM = TransferInternalM 
replace FLTransferInternalM = 1 if TransferInternalF1M  ==1 | TransferInternalF2M  ==1  | TransferInternalF3M  ==1  | TransferInternalL1M  ==1 | TransferInternalL2M  ==1 | TransferInternalL3M  ==1 

gen FLTransferInternal= TransferInternal
replace FLTransferInternal = 1 if l.TransferInternal  ==1 | l2.TransferInternal  ==1  | l3.TransferInternal  ==1  | f1.TransferInternal  ==1 | f2.TransferInternal  ==1 | f3.TransferInternal  ==1

/*
gen FLPromWLM= PromWLM
replace FLPromWLM = 1 if l.PromWLM  ==1 | l2.PromWLM  ==1  | l3.PromWLM  ==1  | f1.PromWLM  ==1 | f2.PromWLM  ==1 | f3.PromWLM  ==1
replace FLPromWLM = 0 if FLTransferInternalM==1

gen FLPromWL= PromWL
replace FLPromWL = 1 if l.PromWL  ==1 | l2.PromWL  ==1  | l3.PromWL  ==1  | f1.PromWL  ==1 | f2.PromWL  ==1 | f3.PromWL  ==1
replace FLPromWL = 0 if FLTransferInternal==1
*/

ta  TransferInternalM if ChangeM ==1 
ta  FLTransferInternalM if ChangeM ==1 // 30% of manager changes due to manager transfer 
ta  FLTransferInternal if ChangeM ==1 // 30% of manager changes due to employee transfer 
* the remaining 40% can be due to: manager leaving, promotions, 
*ta  FLPromWLM if ChangeM ==1 // 1.5% of manager changes due to employee prom WL 
*ta  FLPromWL if ChangeM ==1 // 1% of manager changes due to employee prom WL 


////////////////////////////////////////////////////////////////////////////////
* STATISTICS ON MANAGER ROTATIONS  
////////////////////////////////////////////////////////////////////////////////

use  "$managersdta/Switchers.dta", clear 
*use  "$managersdta/SwitchersNonMissing.dta", clear 
use  "$managersdta/SwitchersSameTeam.dta", clear 

xtset IDlse YearMonth 

global exitFE CountryYear AgeBand AgeBandM   WLM  Func Female

ta TransferInternal if YearMonth==Ei // 80% of workers do not transfer at the time of manager transfer 

gen eventT = Ei if YearMonth == Ei
format eventT %tm
format Ei %tm

egen group = group(Office SubFunc ) // transfer unit 
bys YearMonth group: egen ttI = count(IDlse) // how many workers in transfer unit each month 
egen ttag = tag(YearMonth group) // unit and month level 
su ttI  if ttag == 1,d

xtset IDlse YearMonth 
gen eventTF1 = f.eventT

bys IDlse: egen teamUnit = mean(cond(eventTF1!=., group, .))

bys IDlseMHR eventT: egen TeamEvent = count(IDlse) if eventT!=.
su  TeamEvent, d 
// 25% of employees experience at least one event at some point in the 10-year period, but only 16% experience two or more events. Each event will affect a median of 3 employees, and the inter-quartile range of events affects teams of 1 and 7 employees. to show that the sample of employees who experience a manager transition (25%) is quite representative of the whole firm in observable characteristics. Moreover, to show that the characteristics of employees and managers are similar across the different types of manager transitions.

bys YearMonth Office SubFunc: egen NoManagerperUnit = count(cond(Manager==1,IDlse,.)) // unit and month level, no. of managers 
su NoManagerperUnit if ttag==1, d // it is only 1 manager per unit until 90% obs 

bys YearMonth Country SubFunc: egen NoManagerperUnit2 = count(cond(Manager==1,IDlse,.)) // unit and month level, no. of managers 
egen ttag2 = tag(YearMonth Country SubFunc) // unit and month level 
su NoManagerperUnit2 if ttag2==1, d // it is only 1 manager per unit until 90% obs

********************************************************************************
* CHECKS ABOUT FAST TRACK MEASURE 
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType.dta", clear 

* CONCERN: fast track is time invariant but what about crappy WL1 (>29), that then become superstars in WL2 and get promoted fast to WL3 then? 
* or crappy WL2 (>39), become superstar in WL3 and then get promoted fast to WL4
* or crappy WL3 (>50), become superstar in WL4 and then get promoted fast to WL5
count if EarlyAge==1 & MaxWL==3 //  116,598
bys WL: ta AgeMinByWL if EarlyAge==1 & MaxWL==3 // 3% of obs in WL1, and of those 84% in the age range to be fast track if promoted to WL2
count if EarlyAge==1 & MaxWL==4 //    16,684
bys WL: ta AgeMinByWL if EarlyAge==1 & MaxWL==4 // 7% of obs in WL2, no crappy WL2
count if EarlyAge==1 & MaxWL>4 //  10,490
bys WL: ta AgeMinByWL if EarlyAge==1 & MaxWL>4 // 2% of obs in WL3, no crappy WL3


use "$managersdta/AllSnapshotMCultureMType.dta", clear 

gen o =1 
gcollapse EarlyAgeM (sum) o , by(ISOCode CountryS)

su o, d
gen m1 = r(p75)
gen m = r(p50)
su EarlyAgeM if o>m
graph bar EarlyAgeM if o>m, over(ISOCode, sort(o) label(angle(45))) ysize(2) yline(`r(mean)') title("Fast track") ytitle("")
graph export "$analysis/Results/2.Descriptives/FTbyCountry.png", replace 

********************************************************************************
* MISC INFO on isolating events - from Cullen et al 2020
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 
* how many managers transfer? 
bys IDlseMHR: egen m = max(TransferInternalM)
egen tt = tag(IDlseMHR)
ta m if tt==1 // 60% of managers do at least 1 transfer 

use  "$managersdta/AllSnapshotMCulture.dta", clear
merge m:1 IDlse Year using "$fulldta/UniVoice.dta" 
drop if _merge ==2 
drop _merge 

* changing role & manager >> less than 20% 
ta TransferInternal if ChangeM==1 
ta TransferSubFunc if ChangeM==1 

*Team ID 
sort IDlse YearMonth
bys IDlseMHR YearMonth: egen TeamID = sum(IDlse)
replace TeamID = . if IDlseMHR ==.
gen NoTeam = IDlse== TeamID
label var NoTeam "Single employee. There is no team."

*exclude managers who are temporary replacements by requiring the new manager to remain with the team for at least one quarter
egen ttt = tag(IDlseMHR TeamID YearMonth)
bys IDlseMHR TeamID: egen MTeamDuration = sum(ttt)
label var MTeamDuration "Manager-team pair duration"
drop ttt

* Change Team Event 
gsort IDlse YearMonth 
gen ChangeTeam = 0 
replace ChangeTeam = 1 if (IDlse[_n] == IDlse[_n-1] & TeamID[_n] != TeamID[_n-1]   )
replace ChangeTeam = . if TeamID ==. 
bys IDlse: egen mm = min(YearMonth)
replace ChangeTeam = 0  if YearMonth ==mm & ChangeTeam==1
drop mm

* Changing team & manager 
*new manager must assume responsibility for all employees in the team
* the whole team, rather than a specific employee, experiences the manager transition.
ta ChangeTeam if ChangeM==1 
* 94% employee who change manager also change team

* How many individuals in a given office-subfunc, month?
bys Office SubFunc YearMonth: egen  aaa = count(IDlse)
su aaa,d
* p50 = 35, mean = 125

* How many individuals are not colocated with manager? 
ta DiffOffice
* 27% of obs 

/* separating managers moves associated with manager moving and not employee moving 
distinct Org5 // 822
distinct Org4 // 573 
distinct Org3 // 239
distinct Org2 // 73
distinct Org1 // 22
distinct SubFunc // 117
distinct Office //  2605
* NOTE: it seems to consider org4 (organizational unit) / subfunc / office >> transfer internal 
*/

* Mid career recruit 
*>> need to do a combination of WL & tenure, like I did in the descriptives 
 
* HHI of share in different countries and functions 
bys IDlse: egen nn = count(YearMonth) // total months 
bys IDlse Func: egen fnn = count(YearMonth ) // total months in func
bys IDlse Country: egen cnn = count(YearMonth )  // total months in country
bys IDlse Func: egen fym = min(YearMonth)
bys IDlse Country: egen cym = min(YearMonth)
gen ft = YearMonth == fym
gen ct = YearMonth == cym
gen FuncShare = (fnn/nn)^2*ft // compute share and square 
gen CountryShare = (cnn/nn)^2*ct
bys IDlse (YearMonth), sort: gen HHIFunc = sum(FuncShare)
bys IDlse (YearMonth), sort: gen HHICountry = sum(CountryShare)
drop fnn cnn nn FuncShare CountryShare
* note that measure is no longer cumulative if employee changes function in the middle and then returns to the original one 
bys IDlse (YearMonth), sort: gen ind =  Func[1]!=Func[_N]
bys IDlse (YearMonth), sort: gen ind1 =  Func[1]==Func[_N]
br IDlse YearMonth  Func if ind1==1 & TransferFuncC>1

********************************************************************************
* Is there path dependency? prob of high/low manager depending on first manager transition 
********************************************************************************

* 1) choose the manager type: high prom 75, 50, FT etc 
use "$managersdta/SwitchersAllSameTeam2.dta", clear 

keep if WL2==1 

* manager of the transition
bys IDlse: egen IDlseMHR1 = mean(cond(KEi==0, IDlseMHR, . ))
bys IDlse: egen EarlyAgeM1 = mean(cond(KEi==0, EarlyAgeM, . ))
* checking the variable makes sense 
ta EarlyAgeM1 FTLHPost
ta EarlyAgeM1 FTLLPost

* first month of new manager 
bys IDlse: egen YearMonth2 = min(cond(IDlseMHR1!=IDlseMHR & KEi>0 & KEi!=., YearMonth, . ))
* next manager after transition manager 
bys IDlse: egen IDlseMHR2 = min(cond(YearMonth2 == YearMonth, IDlseMHR, . ))
bys IDlse: egen EarlyAgeM2 = mean(cond(IDlseMHR2==IDlseMHR & KEi>0 & KEi!=., EarlyAgeM, . ))

* Not more likely to have another HF if you were HF 
reghdfe  EarlyAgeM2 EarlyAgeM1 if YearMonth2 == YearMonth & (FTLL !=.| FTLH !=.) , a(Office##Func YearMonth ) cluster(IDlseMHR)
reghdfe  EarlyAgeM2 EarlyAgeM1 if YearMonth2 == YearMonth & (FTLL !=.| FTLH !=.) & WL==1 , a(Office##Func YearMonth ) cluster(IDlseMHR)
* this evidence is consistent / note that under HF more likely to be promoted - so you go up the hierarchy and you are more likely to have a HF manager
reghdfe  EarlyAgeM2 EarlyAgeM1 if YearMonth2 == YearMonth & (FTHL !=.| FTHH !=.), a(Office##Func YearMonth ) cluster(IDlseMHR)
reghdfe  EarlyAgeM2 EarlyAgeM1 if YearMonth2 == YearMonth & (FTHL !=.| FTHH !=.)& WL==1, a(Office##Func YearMonth ) cluster(IDlseMHR)

eststo clear 
eststo reg1: reghdfe  EarlyAgeM2 EarlyAgeM1 if YearMonth2 == YearMonth & (FTLH !=.| FTLL !=.), a(Office##Func YearMonth ) cluster(IDlseMHR)
eststo reg2: reghdfe  EarlyAgeM2 EarlyAgeM1 if YearMonth2 == YearMonth & (FTHL !=.| FTHH !=.), a(Office##Func YearMonth ) cluster(IDlseMHR)

* just for plot, creating ad hoc vars 
cap drop reg1 reg2
gen reg1 = 1 
gen reg2 = 1 
label var reg1 "Gaining a high-flyer manager"
label var reg2 "Losing a high-flyer manager"

coefplot  reg1 reg2 , ///
title("Probability next manager is high-flyer", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM1)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
graph export "$analysis/Results/2.Descriptives/NextManagerHF.png", replace 
graph save "$analysis/Results/2.Descriptives/NextManagerHF.gph", replace 

********************************************************************************
* Additional: Is there path dependency? prob of high/low manager depending on first manager transition 
********************************************************************************

*NUMBER OF NEXT HIGH/LOW MANAGERS 
*NEED TO COUNT FOR each worker how many high  manager it has later , fraction of high managers, prob of having a high manager 

foreach v in LH LL HL HH{
	gen `v'FT = FT`v'!=.
	foreach t in 75 50{
	gen `v'`t' = PromSG`t'`v'!=.
}
}

* 2) HIGH PROMOTION 
foreach t in 75 50{
	
* divide the manager changes by type 
gen ChangeMHigh`t' = cond( MFEBayesPromSG`t'==1 , ChangeM,0) 
gen ChangeMLow`t' = cond( MFEBayesPromSG`t'==0 , ChangeM,0) 

* manager changes after first transition 
bys IDlse: egen ccHigh`t' = total(cond(KEi>0, ChangeMHigh`t', .))
bys IDlse: egen ccLow`t' = total(cond(KEi>0, ChangeMLow`t', .))

gen ChangeM`t' = ChangeMHigh`t' +  ChangeMLow`t'

bys IDlse: egen ccAll`t' =  total(cond(KEi>0, ChangeM`t', .))

gen Frac`t' = ccHigh`t' /ccAll`t' 
}

* 3) FAST TRACK 
* divide the manager changes by type 
gen ChangeMHighFT = cond( EarlyAgeM==1 & WLM==2 , ChangeM,0) 
gen ChangeMLowFT = cond(EarlyAgeM==0 & WLM==2, ChangeM,0) 

* manager changes after first transition 
bys IDlse: egen ccHighFT = total(cond(KEi>0 , ChangeMHighFT, .))
bys IDlse: egen ccLowFT = total(cond(KEi>0 , ChangeMLowFT, .))

gen ChangeMFT = ChangeMHighFT +  ChangeMLowFT
bys IDlse (YearMonth), sort: gen ChangeMFTC = sum(ChangeMFT) // CUMULATIVE SUM OF MANAGER CHANGES 
bys IDlse: egen ccAllFT =  total(cond(KEi>0 , ChangeMFT, .))
gen FracFT = ccHighFT /ccAllFT

* REGRESSIONS: prob. moving to a future manager 

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
cap drop minEi  maxEi ii
local end = 36 // to be plugged in, window lenght 
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-1 &  maxEi >=`end'
ta ii

gen ProbFT = ChangeM & EarlyAgeM
gen ProbFT2 = ChangeM & EarlyAgeM if WLM==2
egen FTHigh = rowmax(LHFT HHFT  )
egen FTLow= rowmax(LLFT HLFT  )

* STAT IN THE PAPER:
*>>>>>>>>>>>>>* prob. FT manager next: there is no path dependence, probability of getting a high manager 
*>>>>>>>>>>>>>* is the same whether you had a bad or good manager, conditional on changing manager 
reghdfe ProbFT LHFT LLFT HLFT  if KEi>0 & WL2==1& ChangeMFTC==2 & ChangeMFT==1 & ii==1, cluster(IDlseMHR) a(Country##YearMonth##Func AgeBand##Female  )
reghdfe ProbFT FTHigh  if KEi>0 & WL2==1& ChangeMFTC==2 & ChangeMFT==1 & ii==1, cluster(IDlseMHR) a(Country##YearMonth##Func AgeBand##Female  )

* 4) collapse by IDlse 
collapse  LH75 HL75 LL75 HH75 LH50 HL50 LL50 HH50 LHFT HLFT LLFT HHFT Frac75 Frac50 FracFT ccHigh75 ccLow75 ccHigh50 ccLow50 ccAll75 ccAll50 ccAllFT, by(IDlse)

label def cat  1  "low to low" 2 "low to high" 3 "high to low" 4 "high to high" 

	foreach t in FT 75 50{
gen cat`t' = 1 if LL`t'==1
replace cat`t' = 2 if LH`t'==1
replace cat`t' = 3 if HL`t'==1
replace cat`t' = 4 if HH`t'==1
label value cat`t' cat 
	}

* 5) graphs - fraction
foreach v in 50 75{
cibar  Frac`v' , over(cat`v') graphopt( ytitle("Proportion of high type") title("Future managers: proportion of high type (`v')"))
graph save "$analysis/Results/2.Descriptives/PathDepSG`v'.gph", replace 
graph export "$analysis/Results/2.Descriptives/PathDepSG`v'.png", replace 
}
cibar  FracFT , over(catFT) graphopt( ytitle("Proportion of fast track managers") title("Future managers: proportion of fast track type"))
graph save "$analysis/Results/2.Descriptives/PathDepFT.gph", replace 
graph export "$analysis/Results/2.Descriptives/PathDepFT.png", replace 

* - number of manager changes 
foreach v in 50 75{
cibar  ccAll`v', over(cat`v') graphopt( ytitle("Number of future managers") title("Number of future managers after first transition"))
graph save "$analysis/Results/2.Descriptives/PathDepNoSG`v'.gph", replace 
graph export "$analysis/Results/2.Descriptives/PathDepNoSG`v'.png", replace 
}
cibar  ccAllFT, over(catFT) graphopt( ytitle("Number of future managers") title("Number of future managers after first transition"))
graph save "$analysis/Results/2.Descriptives/PathDepNoFT.gph", replace 
graph export "$analysis/Results/2.Descriptives/PathDepNoFT.png", replace 

////////////////////////////////////////////////////////////////////////////////
* CARD ET AL CHECKS ON SYMMETRIES IN THE TRANSITIONS 
////////////////////////////////////////////////////////////////////////////////

use "$managersdta/SwitchersAllSameTeam.dta", clear 

*bys IDlse: egen TM= mean(cond(KEi==0 & TransferInternalM==1 & PromWLM==0,1 ,.)) 

*keep if TM==1 
* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
* window lenght
local end = 24 // to be plugged in 
local end2 = 24 // to be plugged in 
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-(`end') &  maxEi >=(`end2') & Ei!=.
ta ii
keep if ii==1 // MANUAL INPUT - to remove if irrelevant

* Residualize 
reghdfe   ChangeSalaryGradeC Tenure TenureM, res(  ChangeSalaryGradeCR) a( AgeBand AgeBandM YearMonth Country Func)

collapse  ChangeSalaryGradeC   ChangeSalaryGradeCR  KEi (semean) sdChangeSalaryGradeC = ChangeSalaryGradeC  sdChangeSalaryGradeCR  = ChangeSalaryGradeCR , by( KFTHH KFTHL KFTLL KFTLH) // monthly

foreach v in  ChangeSalaryGradeC ChangeSalaryGradeCR {
gen lo`v' = `v' - (1.96*sd`v')
gen hi`v' = `v' + (1.96*sd`v')
}

preserve 

foreach v in KEi KFTHH KFTHL KFTLL KFTLH{
	gen Y`v' = -2 if `v' >=-24 & `v' <-12
	replace Y`v' = -1 if `v' >=-12 & `v' <0
	replace Y`v' = 0 if `v' >=0 & `v' <12
	replace Y`v' = 1 if `v' >=12 & `v' <24
}

collapse ChangeSalaryGradeCR  YKEi   loChangeSalaryGradeCR   hiChangeSalaryGradeCR , by( YKFTHH YKFTHL YKFTLL YKFTLH) // monthly

twoway connected ChangeSalaryGradeCR YKFTHH if YKEi >=-2 & YKEi <=1, lpattern(dot)  || rcap loChangeSalaryGradeCR hiChangeSalaryGradeCR YKFTHH if YKEi >=-2 & YKEi <=1, ///  
|| connected ChangeSalaryGradeCR YKFTHL if YKEi >=-2 & YKEi <=1, lpattern(dot) ||   rcap loChangeSalaryGradeCR hiChangeSalaryGradeCR YKFTHL if YKEi >=-2 & YKEi <=1, ///
||  connected ChangeSalaryGradeCR YKFTLH if YKEi >=-2 & YKEi <=1, lpattern(dot) ||  rcap loChangeSalaryGradeCR hiChangeSalaryGradeCR YKFTLH if YKEi >=-2 & YKEi <=1,   ///
|| connected ChangeSalaryGradeCR YKFTLL if YKEi >=-2 & YKEi <=1, lpattern(dot) || rcap loChangeSalaryGradeCR hiChangeSalaryGradeCR YKFTLL if YKEi >=-2 & YKEi <=1 , ///
legend(order(1 "High to High" 3 "High to Low" 5 "Low to High" 7 "Low to Low" ) size(medium)) title("Mean promotion rates (salary grade) of switchers", size(medium)) xtitle("Year since manager change" , size(medium)) ytitle("") ///
note("Notes. Mean promotion rates of manager switchers by fast-track status of" "outgoing and incoming manager. Residualized by age group and tenure of" "the manager and worker as well as year-month, function and country fixed effects.", size(medium)) ///
xlabel(-2(1)1) xscale(range(-2 1)) ylabel(-.2(.1).2) xscale(range(-.2 .2))   name(graphR, replace ) scheme(white_hue) ysize(3.3)
graph save "$analysis/Results/2.Descriptives/Card13.gph", replace 
graph export "$analysis/Results/2.Descriptives/Card13.png", replace 

* SEPARATELY HIGH AND LOW 
twoway connected ChangeSalaryGradeCR YKFTHH if YKEi >=-2 & YKEi <=1, lpattern(dot)  || rcap loChangeSalaryGradeCR hiChangeSalaryGradeCR YKFTHH if YKEi >=-2 & YKEi <=1, ///  
|| connected ChangeSalaryGradeCR YKFTHL if YKEi >=-2 & YKEi <=1, lpattern(dot) ||   rcap loChangeSalaryGradeCR hiChangeSalaryGradeCR YKFTHL if YKEi >=-2 & YKEi <=1, ///
legend(order(1 "High to High" 3 "High to Low" ) size(medium)) title("Mean promotion rates (salary grade) of switchers", size(medium)) xtitle("Year since manager change" , size(medium)) ytitle("") ///
note("Notes. Mean promotion rates of manager switchers by fast-track status of" "outgoing and incoming manager. Residualized by age group and tenure of" "the manager and worker as well as year-month, function and country fixed effects.", size(medium)) ///
xlabel(-2(1)1) xscale(range(-2 1)) ylabel(-.2(.1).2) xscale(range(-.2 .2))   name(graphRHigh, replace ) scheme(white_hue) ysize(3.3)
graph save "$analysis/Results/2.Descriptives/Card13High.gph", replace 
graph export "$analysis/Results/2.Descriptives/Card13High.png", replace 

twoway connected ChangeSalaryGradeCR YKFTLH if YKEi >=-2 & YKEi <=1, lpattern(dot) ||  rcap loChangeSalaryGradeCR hiChangeSalaryGradeCR YKFTLH if YKEi >=-2 & YKEi <=1,   ///
|| connected ChangeSalaryGradeCR YKFTLL if YKEi >=-2 & YKEi <=1, lpattern(dot) || rcap loChangeSalaryGradeCR hiChangeSalaryGradeCR YKFTLL if YKEi >=-2 & YKEi <=1 , ///
legend(order( 1 "Low to High" 3 "Low to Low" ) size(medium)) title("Mean promotion rates (salary grade) of switchers", size(medium)) xtitle("Year since manager change" , size(medium)) ytitle("") ///
note("Notes. Mean promotion rates of manager switchers by fast-track status of" "outgoing and incoming manager. Residualized by age group and tenure of" "the manager and worker as well as year-month, function and country fixed effects.", size(medium)) ///
xlabel(-2(1)1) xscale(range(-2 1)) ylabel(-.2(.1).2) xscale(range(-.2 .2))   name(graphRLow, replace ) scheme(white_hue) ysize(3.3)
graph save "$analysis/Results/2.Descriptives/Card13Low.gph", replace 
graph export "$analysis/Results/2.Descriptives/Card13Low.png", replace 





