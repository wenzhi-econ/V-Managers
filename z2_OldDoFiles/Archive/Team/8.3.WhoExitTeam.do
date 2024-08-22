********************************************************************************
* Profiles of people who exit team 
********************************************************************************

use "$Managersdta/SwitchersAllSameTeam.dta", clear 

local Label PromSG75 // manager type of interest 
drop  if `Label'LH==. &  `Label'LL==. & `Label'HL==. & `Label'HH==. 

xtset IDlse YearMonth 
gen F1ChangeM = f.ChangeM
bys IDlse: egen ExitEvent = mean(cond( F1ChangeM==1, YearMonth,. )) // exit month , LeaverPerm==1 |
format  ExitEvent %tm 

* flag for the manager in transition 
bys IDlse: egen IDlseMHREvent = mean(cond(YearMonth ==Ei,IDlseMHR, .))
gen SameMEvent = IDlseMHR ==IDlseMHREvent 

keep if ExitEvent!=. // only keep leavers

gen Diff = ExitEvent - Ei // difference between exit and event time 

* productivity
merge 1:1 IDlse YearMonth using  "$Managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

* generate pay growth and productivity averages in the months before the event 
xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus

foreach var in ExitEvent {
	gen K`var' = YearMonth - `var'

forvalues l = 1/24 { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}

foreach y in PayGrowth ProductivityStd{
bys IDlse : egen `y'v8`var' = mean(cond( F3`var'==1 | F4`var'==1 | F5`var'==1 | F6`var'==1 | F7`var'==1 | F8`var'==1 | F9`var'==1 | F10`var'==1 | F11`var'==1 | F12`var'==1 , `y' ,.)) // mean 3-12 months before meeting new manager 

bys IDlse : egen `y'v12`var' = mean(cond( F1`var'==1  | F2`var'==1 | F3`var'==1 | F4`var'==1 | F5`var'==1 | F6`var'==1 | F7`var'==1 | F8`var'==1 | F9`var'==1 | F10`var'==1 | F11`var'==1 | F12`var'==1 , `y' ,.)) // mean 1-12 months before meeting new manager 


bys IDlse : egen `y'v18`var' = mean(cond( F1`var'==1  | F2`var'==1 | F3`var'==1 | F4`var'==1 | F5`var'==1 | F6`var'==1 | F7`var'==1 | F8`var'==1 | F9`var'==1 | F10`var'==1 | F11`var'==1 | F12`var'==1 | F13`var'==1 | F14`var'==1 | F15`var'==1 | F16`var'==1 | F17`var'==1 | F18`var'==1, `y' ,.)) // mean 18 months before meeting new manager 

bys IDlse : egen `y'v24`var' = mean(cond( F1`var'==1  | F2`var'==1 | F3`var'==1 | F4`var'==1 | F5`var'==1 | F6`var'==1 | F7`var'==1 | F8`var'==1 | F9`var'==1 | F10`var'==1 | F11`var'==1 | F12`var'==1 | F13`var'==1 | F14`var'==1 | F15`var'==1 | F16`var'==1 | F17`var'==1 | F18`var'==1 | F19`var'==1 | F20`var'==1 | F21`var'==1 | F22`var'==1 | F23`var'==1 | F24`var'==1, `y' ,.)) // mean 24 months before meeting new manager 
}

}

* only keep obs at the time of exit, cross section  
keep if YearMonth == ExitEvent 
isid IDlse

* Prepare variables  
* EDUCATION Groups 
merge m:1 IDlse  using "$fulldta/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge 

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

* Age 
gen Age20 = AgeBand ==1 
gen Age30 = AgeBand ==2 
gen Age40 = AgeBand ==3 
gen Age50 = AgeBand >=4 if AgeBand!=.

gen LogTenure = log(Tenure)

foreach v in PayGrowthv8ExitEvent PayGrowthv12ExitEvent PayGrowthv18ExitEvent PayGrowthv24ExitEvent{
gen `v'B = `v' >0 if `v'!=.
} 

gen LHPost = PromSG75LHPost
replace LHPost = . if PromSG75HLPost==1 | PromSG75HHPost==1

gen HLPost = PromSG75HLPost
replace HLPost = . if PromSG75LHPost==1 | PromSG75LLPost==1

* Final table 
label var PayGrowthv8ExitEvent "Pay Growth 8 months"
label var PayGrowthv12ExitEvent "Pay Growth 12 months"
label var PayGrowthv18ExitEvent "Pay Growth 18 months"
label var PayGrowthv24ExitEvent "Pay Growth 24 months"
label var PayGrowthv8ExitEventB "Pay Growth 3-12 months>0"
label var PayGrowthv12ExitEventB "Pay Growth 12 months>0"
label var PayGrowthv18ExitEventB "Pay Growth 18 months>0"
label var PayGrowthv24ExitEventB "Pay Growth 24 months>0"
label var Female "Female"
label var AgeContinuous "Age"
label var Tenure "Tenure (years)" 
label var LogTenure "Tenure (logs)" 
label var WL   "Work Level"
label var TeamSize "Team Size"
label var EarlyAge "Fast track"
label var ProductivityStdv12ExitEvent "Sales achievement/target"
label var LogPayBonus  "Pay + Bonus (logs)"
label var LogBonus  "Bonus (logs)"
label var PromWLC  "No. Prom. WL"
label var ChangeSalaryGradeC  "No. Prom. Salary"
label var VPA   "Perf. appraisal (1-150)"
label var Age20 "Age <30"
label var Age30 "30 <Age < 40"
label var Age40 "40 < Age < 50"
label var Age50 "Age >50"
label var NewHire "New hire, tenure <1"
label var LeaverVol "Vol. Exit"
label var LeaverInv "Inv. Exit"

* VARIABLES 
global charsCoef Female  Econ Sci Hum  Age20    LogTenure NewHire LogPayBonus PayGrowthv12ExitEventB ProductivityStdv12ExitEvent ChangeSalaryGradeC EarlyAge

* Age30 Age40 Age50 
global FE Country  
global cont  i.Year i.Func  
* c.TenureM##c.TenureM##i.FemaleM

balancetable   (mean if PromSG75LHPost==1) (mean if PromSG75LLPost==1) (diff LHPost if LHPost!=. ) (mean if PromSG75HLPost==1) (mean if PromSG75HHPost==1) (diff HLPost if HLPost!=. )  $charsCoef   if Diff<=36 using "$analysis/Results/8.Team/ExitTeamPromSG75.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  covariates( $cont ) fe( $FE )     ctitles("Low-High" "Low-Low" "Diff." "High-Low" "High-High" "Diff" )  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered at the manager level and controlling for country, year and function FE." "\end{tablenotes}")

* FIGURES 
* Age30 Age40 Age50 Econ Sci Hum 
global charsCoef Female Age20 Econ Sci Hum      LogTenure  LogPayBonus  ChangeSalaryGradeC EarlyAge NewHire
global most    Female Age20  LogTenure  LogPayBonus  ChangeSalaryGradeC EarlyAge NewHire

eststo clear 
local i = 1
foreach var in  $charsCoef {
	eststo `var': reghdfe `var' LHPost if  Diff>2   & SameMEvent==1 , a( $FE  $cont   ) vce(cluster IDlseMHR)  // using 12 is too few exits 
	local i = `i' + 1
}

coefplot $most , keep(LHPost) ci(90)  xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) note("Notes. Standard errors clustered at the manager level." "Controlling for country, year and function FE." "Change manager under the manager of the transition event.", size(small))   headings(Female = "{bf:Demographics}" LogTenure = "{bf:Performance at work}" , labgap(0)) title("Team leavers: Low to High versus Low to Low")
graph export "$analysis/Results/8.Team/ExitTeamLH.png", replace 
graph save "$analysis/Results/8.Team/ExitTeamLH.gph", replace 


eststo clear 
local i = 1
foreach var in  $most {
	eststo `var': reghdfe `var' HLPost  if Diff>2 & SameMEvent==1 , a( $FE $cont ) vce(cluster IDlseMHR) 
	local i = `i' + 1
}

coefplot $most , keep(HLPost) ci(90)  xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) note("Notes. Standard errors clustered at the manager level." "Controlling for country, year and function FE." "Change manager under the  manager of the transition event.", size(small))   headings(Female = "{bf:Demographics}" LogTenure = "{bf:Performance at work}" , labgap(0)) title("Team leavers: High to Low versus High to High")
graph export "$analysis/Results/8.Team/ExitTeamHL.png", replace 
graph save "$analysis/Results/8.Team/ExitTeamHL.gph", replace 



