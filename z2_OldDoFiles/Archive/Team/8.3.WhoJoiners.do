********************************************************************************
* Profiles of new team joiners 
********************************************************************************

* 1) First create manager level dataset with the events 
********************************************************************************
use  "$Managersdta/Teams.dta", clear

local Label PromSG75 // manager type of interest 
drop  if `Label'LH==. &  `Label'LL==. & `Label'HL==. & `Label'HH==. 
keep if Post==1 // post managers 

gen o = 1 
collapse o, by(IDlseMHR Event `Label'LLPost `Label'LHPost `Label'HLPost `Label'HHPost )
bys IDlseMHR : gen dup = cond(_N==1,0,_n)
drop o 
replace dup = 1 if dup ==0 
reshape wide Event `Label'LLPost `Label'LHPost `Label'HLPost `Label'HHPost , i(IDlseMHR) j(dup) // manager level, event wide 

save "$Managersdta/Temp/EventNewJoiners.dta", replace 

* 2) Then get the new joiners as those that get the new manager after the manager transition event  
********************************************************************************

use "$Managersdta/AllSnapshotMCulture.dta", clear 
xtset IDlse YearMonth 

/* 1) Sample restriction #0: I drop all employees with any instance of missing managers
bys IDlse: egen cM = count(cond(IDlseMHR==., YearMonth,.)) // count how many IDlse have missing manager info 
drop if cM > 0 // only keep IDlse for which manager id is never missing 
count if IDlseMHR==.
*/

* 2) Sample restriction #1: only consider time after manager type is defined 
keep if Year>2013 

* merge with manager type 
merge m:1 IDlseMHR using "$Managersdta/Temp/MFEBayes2014.dta" , keepusing(MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50)
drop if _merge ==2
drop _merge 

* merge with the events 
merge m:1 IDlseMHR using  "$Managersdta/Temp/EventNewJoiners.dta"
drop if _merge ==2
drop _merge 

forval i = 1/8{
gen Diff`i' = YearMonth - Event`i'
bys IDlse IDlseMHR: egen minDiff`i' = min(Diff`i') // min distance at worker-manager level 
replace Event`i' = . if minDiff`i'<1 // replace any event where the individual had the manager before or at the event month 
foreach v in LH LL HL HH{
replace PromSG75`v'Post`i' = .  if minDiff`i'<1  
}
replace Diff`i' =. if minDiff`i'<1
drop minDiff`i'
bys IDlse IDlseMHR: egen minDiff`i' = min(Diff`i') // re-create the min 

}

egen minDiff = rowmin(minDiff1 minDiff2 minDiff3 minDiff4 minDiff5 minDiff6 minDiff7 minDiff8) // absolute minimum 

forval i = 1/8{
replace Event`i' = . if minDiff`i' != minDiff
foreach v in LH LL HL HH{
replace PromSG75`v'Post`i' = .  if minDiff`i' != minDiff
}
}

egen Event = rowtotal(Event1 Event2 Event3 Event4 Event5 Event6 Event7 Event8) 
replace Event = . if Event ==0 
format Event %tm 

foreach v in LH LL HL HH{
egen PromSG75`v'Post =rowtotal(PromSG75`v'Post1 PromSG75`v'Post2 PromSG75`v'Post3 PromSG75`v'Post4 PromSG75`v'Post5 PromSG75`v'Post6 PromSG75`v'Post7 PromSG75`v'Post8)
}

egen Diff = rowtotal(Diff1 Diff2 Diff3 Diff4 Diff5 Diff6 Diff7 Diff8) 
replace Diff = . if Diff ==0 
egen minDifftotal = rowtotal(minDiff1 minDiff2 minDiff3 minDiff4 minDiff5 minDiff6 minDiff7 minDiff8) 
replace minDifftotal = . if minDifftotal ==0 

gen flag = 1 if (Event != Event1 &  Event != Event2 &  Event != Event3 &  Event != Event4 & Event != Event5 & Event != Event6 & Event != Event7 & Event != Event8)       

ta flag // all missing, all good! 

bys IDlse IDlseMHR: egen HireEvent = min(cond(Diff==minDifftotal & Diff!=., YearMonth, .)) // hire event at worker - manager
format HireEvent %tm 

keep if Diff == minDiff & Diff!=. // only keep at the month of the hire event into the new team 
isid IDlse IDlseMHR
bys IDlse : gen dup = cond(_N==1,0,_n)
replace dup = 1 if dup==0

********************************************************************************
* might not need to be re-run each time 
********************************************************************************

* create pay growth to match to the time of the new hire joining the team after a transition event

preserve 

keep IDlse IDlseMHR HireEvent dup
reshape wide HireEvent IDlseMHR, i(IDlse) j(dup)
save "$Managersdta/Temp/EventNewJoinersWide.dta", replace

use "$Managersdta/AllSnapshotMCulture.dta", clear 
merge m:1 IDlse using "$Managersdta/Temp/EventNewJoinersWide.dta" 
keep if _merge ==3 
drop _merge

merge 1:1 IDlse YearMonth using  "$Managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus

* generate pay growth in the year before the event 
foreach var in HireEvent1 HireEvent2 HireEvent3 HireEvent4 HireEvent5 HireEvent6 {
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

collapse HireEvent1 HireEvent2 HireEvent3 HireEvent4 HireEvent5 HireEvent6 PayGrowthv* ProductivityStdv* IDlseMHR1 IDlseMHR2 IDlseMHR3 IDlseMHR4 IDlseMHR5 IDlseMHR6   , by(IDlse)
reshape long HireEvent PayGrowthv8HireEvent PayGrowthv12HireEvent PayGrowthv18HireEvent PayGrowthv24HireEvent ProductivityStdv8HireEvent ProductivityStdv12HireEvent ProductivityStdv18HireEvent ProductivityStdv24HireEvent  IDlseMHR , i(IDlse) j(dup)
drop if HireEvent==.
gen YearMonth = HireEvent 
save "$Managersdta/Temp/EventNewJoinersPayG.dta", replace

restore 

********************************************************************************

merge 1:1 IDlse IDlseMHR using  "$Managersdta/Temp/EventNewJoinersPayG.dta", keepusing(PayGrowthv8HireEvent PayGrowthv12HireEvent PayGrowthv18HireEvent PayGrowthv24HireEvent ProductivityStdv8HireEvent ProductivityStdv12HireEvent ProductivityStdv18HireEvent ProductivityStdv24HireEvent )
drop if _merge ==2 
drop _merge 

gen Cohort = AgeBand 
merge m:1 ISOCode Cohort using "$Talent/FMShare.dta", keepusing( FMShareFirmCohort FShareDecade MShareDecade FMShareWB FShareEducDecade MShareEducDecade FMShareEducWB FShareNoEducDecade MShareNoEducDecade FMShareNoEducWB FMShareNoChild FMShareChild FMShareMarried FMShareUnmarried RealGDP2011 LogRealGDP2011 GDPCapita LogGDPCapita)
keep if _merge !=2
drop _merge

* 3) PROFILES OF NEW JOINERS 
gen PromEvent = 1 if PromSG75LHPost==1
replace PromEvent = 2 if PromSG75LLPost==1
replace PromEvent = 3 if PromSG75HLPost==1
replace PromEvent = 4 if PromSG75HHPost==1

label define PromEvent 1 "Low to high"  2 "Low to low"  3 "High to low"  4 "High to high"
label value  PromEvent PromEvent

* prepare variables  
* Constructing relevant variables for the table 

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

gen Age20 = AgeBand ==1 
gen Age30 = AgeBand ==2 
gen Age40 = AgeBand ==3 
gen Age50 = AgeBand >=4 if AgeBand!=.

gen VPA125 = VPA>=125 if VPA!=. 
gen LogTenure = log(Tenure)

foreach v in PayGrowthv8HireEvent PayGrowthv12HireEvent PayGrowthv18HireEvent PayGrowthv24HireEvent{
gen `v'B = `v' >0 if `v'!=.
} 

gen LHPost = PromSG75LHPost
replace LHPost = . if PromSG75HLPost==1 | PromSG75HHPost==1

gen HLPost = PromSG75HLPost
replace HLPost = . if PromSG75LHPost==1 | PromSG75LLPost==1

* Final table 
label var PayGrowthv8HireEvent "Pay Growth 8 months"
label var PayGrowthv12HireEvent "Pay Growth 12 months"
label var PayGrowthv18HireEvent "Pay Growth 18 months"
label var PayGrowthv24HireEvent "Pay Growth 24 months"
label var PayGrowthv8HireEventB "Pay Growth 3-12 months>0"
label var PayGrowthv12HireEventB "Pay Growth 12 months>0"
label var PayGrowthv18HireEventB "Pay Growth 18 months>0"
label var PayGrowthv24HireEventB "Pay Growth 24 months>0"
label var Female "Female"
label var AgeContinuous "Age"
label var Tenure "Tenure (years)" 
label var LogTenure "Tenure (logs)" 
label var WL   "Work Level"
label var TeamSize "Team Size"
label var EarlyAge "Fast track"
label var ProductivityStdv12HireEvent "Sales achievement/target 12 months"
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

* VARIABLES 
global charsCoef Female  Econ Sci Hum  Age20   LogTenure NewHire LogPayBonus PayGrowthv12HireEventB ChangeSalaryGradeC EarlyAge
* Age30 Age40 Age50 
global FE Country  
global cont  i.Year i.Func  
* c.TenureM##c.TenureM##i.FemaleM

balancetable   (mean if PromSG75LHPost==1) (mean if PromSG75LLPost==1) (diff LHPost if LHPost!=. ) (mean if PromSG75HLPost==1) (mean if PromSG75HHPost==1) (diff HLPost if HLPost!=. )  $charsCoef   if Diff<=12 using "$analysis/Results/8.Team/NewJoinerPromSG75.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  covariates( $cont ) fe( $FE )     ctitles("Low-High" "Low-Low" "Diff." "High-Low" "High-High" "Diff" )  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered at the manager level and controlling for country, year and function FE." "\end{tablenotes}")

* figure 
global charsCoef Female Age20 Econ Sci Hum      LogTenure  LogPayBonus  ChangeSalaryGradeC EarlyAge NewHire
* Age30 Age40 Age50 PayGrowthv12HireEventB Econ Sci Hum
global most    Female Age20  LogTenure  LogPayBonus  ChangeSalaryGradeC EarlyAge NewHire
global edu  Econ Sci Hum  

eststo clear 
local i = 1
foreach var in  $charsCoef {
	eststo `var': reghdfe `var' LHPost  if Diff<=36, a( $FE $cont ) vce(cluster IDlseMHR) 
	local i = `i' + 1
}

coefplot $most , keep(LHPost) ci(90)  xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) note("Notes. Standard errors clustered at the manager level." "Controlling for country, year and function FE." "New team joiners within 36 months of the manager transition event.", size(small))   headings(Female = "{bf:Demographics}" LogTenure = "{bf:Performance at work}" , labgap(0)) title("Team joiners: Low to High versus Low to Low")
graph export "$analysis/Results/8.Team/NewJoinLH.png", replace 
graph save "$analysis/Results/8.Team/NewJoinLH.gph", replace 

* Are patterns of female hiring stronger in less developed countries? > YES, although estimates get noisier
forval i=0.3(0.1)1{
reghdfe Female LHPost  if Diff<=36 & FMShareWB<=`i', a( $FE $cont ) vce(cluster IDlseMHR) 
}

eststo clear 
local i = 1
foreach var in  $charsCoef {
	eststo `var': reghdfe `var' HLPost  if  Diff<=36  , a( $FE $cont ) vce(cluster IDlseMHR) 
	local i = `i' + 1
}

coefplot $most , keep(HLPost) ci(90)  xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) note("Notes. Standard errors clustered at the manager level." "Controlling for country, year and function FE." "New team joiners within 36 months of the manager transition event.", size(small))   headings(Female = "{bf:Demographics}" LogTenure = "{bf:Performance at work}" , labgap(0)) title("Team joiners: High to Low versus High to High")
graph export "$analysis/Results/8.Team/NewJoinHL.png", replace 
graph save "$analysis/Results/8.Team/NewJoinHL.gph", replace 



