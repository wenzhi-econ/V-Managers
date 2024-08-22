* This do file looks at manager cultural mismatch on IA sample

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off
cd $analysis
use "$managersdta/IA.dta", clear
xtset IDlse YearMonth // set panel data
order Year, a(YearMonth)

********************************************************************************
* 1. Generate variables
********************************************************************************

* Standardize variables
egen  CulturalDistanceSTD = std( CulturalDistance)
egen  KinshipDistanceSTD = std( KinshipDistance)
egen  CultDistIndexSTD = std(CultDistIndex)
egen  CultDistIndexCSTD = std(CulDistIndexC)

* gen control FE
egen CountryYear = group(Country Year)

* Outcome variables
global outcomes LogPR LogPRSnapshot LogVPA LogPay LogBonus // leaving out: LogBenefit LogPackage 
global outcomesChange Leaver LeaverInv LeaverVol PromChange JobChange
* Independent vars
global distance OutGroup CulturalDistanceSTD DiffLanguage KinshipDistanceSTD  CultDistIndexSTD CultDistIndexCSTD 
global controls SameGender SameAge JointTenure
global FE HomeCountry HomeCountryManager Country Func RoundIAManager 

*global distanceOther  LinguisticDistance2Dominant GeneticDistance ReligionDistanceDominant CulDistIndexA CulDistIndexD CulDistIndexE CulDistIndexF CulDistIndexBinary CulDistIndexNonBinary
	    
********************************************************************************
* 3. Prepare data for Regressions - year level
********************************************************************************

* Choosing the maxmode of RoundIA for each IDlse and year combination
bys IDlse Year: egen RoundIAMode =mode(RoundIA), maxmode
bys IDlse Year: egen RoundIAManagerMode =mode(RoundIAManager) , maxmode
bys IDlse Year: egen OutGroupMode =mode(OutGroup), maxmode
bys IDlse Year: egen CulturalDistanceSTDMode =mode(CulturalDistanceSTD), maxmode

* Taking the mode for all variables
global YearVars  IDlseManager HomeCountryManager JointTenure TeamEthFrac TeamCDistance CountryYear Block TeamID
foreach var in $YearVars {
bys IDlse Year: gen `var'Mode = `var' if CulturalDistanceSTD == CulturalDistanceSTDMode
}

global ModeVars RoundIAMode RoundIAManagerMode OutGroupMode CulturalDistanceSTDMode IDlseManagerMode  HomeCountryManagerMode JointTenureMode TeamEthFracMode TeamCDistanceMode CountryYearMode BlockMode TeamIDMode

* Collapse at the year level 
collapse $outcomes  Tenure (max)   $ModeVars $outcomesChange , by(IDlse Year)
	
* Renaming 
foreach var in  $YearVars OutGroup CulturalDistanceSTD RoundIA RoundIAManager {
rename `var'Mode `var'
}

* Create window around manager switch
by IDlse: egen RoundIAMax= max(RoundIA)
drop if RoundIAMax ==0 // these are employees that have IA manager for less than 3 months
by IDlse (Year), sort: gen Count = _n
by IDlse (Year), sort: gen YearsIA1 = Count if (RoundIA[_n]==1 & RoundIA[_n-1]==0  )
by IDlse: egen YearsIA1Max = max(YearsIA1)
replace YearsIA1 = YearsIA1Max
label var YearsIA1 "Number of year  on IA1 for the employee"
drop YearsIA1Max
gen WindowIA1 = Count - YearsIA1
replace WindowIA1 = 999 if WindowIA1==.

* Save dataset
save "$analysis/Temp/IAFinalSampleYearly", replace 

********************************************************************************
* 4. Regressions - year level
********************************************************************************

* Run regression on full sample 

* 5 years window [-3, +4]
use "$analysis/Temp/IAFinalSampleYearly" , clear

su CulturalDistanceSTD, detail
gen CulturalDistanceAbove = 1 if CulturalDistanceSTD > r(p50)
replace CulturalDistanceAbove = 0 if CulturalDistanceAbove == .
replace CulturalDistanceAbove = . if CulturalDistanceSTD==.

* Discrete survival model using duration  - logit or xtcloglog
sort IDlse Year
by IDlse : generate t = _n
gen Duration = log(t) // or t + t^2

keep if (WindowIA1 <=4 & WindowIA1 >=-3) 
*| WindowIA1 == 999
egen WindowIA1E = group(WindowIA1) // to add the window FE

* OLS Regression
foreach y in PromChange JobChange LogPR LogPRSnapshot LogVPA LogPay LogBonus{

reghdfe `y' b3.WindowIA1E Tenure JointTenure TeamEthFrac   , cluster(Block) a(IDlse  CountryYear  RoundIAManager)
preserve
regsave using "$analysis/Results/2.RegIA/`y'Level.dta", ci replace level(90) 
restore

reghdfe `y' CulturalDistanceAbove##b3.WindowIA1E Tenure JointTenure TeamEthFrac   CulturalDistanceAbove#c.TeamCDistance, cluster(Block) a(IDlse  CountryYear  RoundIAManager)
* TeamEthFrac   CulturalDistanceAbove#TeamCDistance
preserve
regsave using "$analysis/Results/2.RegIA/`y'.dta", ci replace level(90) 
restore


}

* Survival Analysis - !Discrete Time Models! *

*Promotion and transfers 
foreach y in PromChange JobChange{

xtcloglog `y' b3.WindowIA1E  Tenure JointTenure Duration i.RoundIAManager , nolog vce(cluster IDlse) i(IDlse)
*i.HomeCountryManager i.CountryYear
preserve
regsave using "$analysis/Results/2.RegIA/`y'LevelH.dta", ci replace level(90) 
restore

xtcloglog `y' CulturalDistanceAbove##b3.WindowIA1E  Tenure JointTenure Duration ///
TeamEthFrac CulturalDistanceAbove#c.TeamCDistance i.RoundIAManager , nolog vce(cluster IDlse) i(IDlse)
*i.HomeCountryManager i.CountryYear
preserve
regsave using "$analysis/Results/2.RegIA/`y'H.dta", ci replace level(90) 
restore

}
*OLS: reghdfe `y' CulturalDistanceAbove##b4.WindowIA1E Tenure JointTenure TeamEthFrac Duration  CulturalDistanceAbove#c.TeamCDistance, cluster(Block) a(IDlse IDlseManager  CountryYear  RoundIAManager)


* Attrition
keep if WindowIA1 >=0 // for leaver variables

foreach y in Leaver LeaverInv LeaverVol{

xtcloglog `y' b4.WindowIA1E  Tenure JointTenure Duration i.RoundIAManager , nolog vce(cluster IDlse) i(IDlse)
*i.HomeCountryManager i.CountryYear
 
preserve
regsave using "$analysis/Results/2.RegIA/`y'Level.dta", ci replace level(90) 
restore

xtcloglog `y' CulturalDistanceAbove##b4.WindowIA1E  Tenure JointTenure Duration ///
TeamEthFrac CulturalDistanceAbove#c.TeamCDistance i.RoundIAManager , nolog vce(cluster IDlse) i(IDlse)
*i.HomeCountryManager i.CountryYear
 
preserve
regsave using "$analysis/Results/2.RegIA/`y'.dta", ci replace level(90) 
restore


}


* Plots 

*/*use "$analysis/Results/2.RegIA/LogPay", clear
keep in 3/26
drop in 9/16

gen t1 = [_n]-4
replace t1 = . if t1>4
gen  t2 = [_n]-12 if t1 == . // formula: [_n]-(#of lags +1)

twoway (scatter coef t1, color(blue) ) (line  coef t1, color(blue) )  (rcap ci_lower ci_upper t1, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Annual pay (logs)") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/LogPay.gph", replace
graph export "$analysis/Results/2.RegIA/LogPay.png", replace

drop if t2 ==.
twoway (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (years)") ///
ytitle("Annual pay (logs)") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/LogPayCD.gph", replace
graph export "$analysis/Results/2.RegIA/LogPayCD.png", replace

gr combine  "$analysis/Results/2.RegIA/LogPay" "$analysis/Results/2.RegIA/LogPayCD"
graph export "$analysis/Results/2.RegIA/LogPayALL.png", replace
*/

* BONUS

use "$analysis/Results/2.RegIA/LogBonus", clear
keep in 3/26
drop in 9/16

gen t1 = [_n]-4
replace t1 = . if t1>4
gen  t2 = [_n]-12 if t1 == . // formula: [_n]-(#of lags +1)

drop if t2 ==.
twoway (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (years)") ///
ytitle("Annual bonus (logs)") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/LogBonusCD.gph", replace
graph export "$analysis/Results/2.RegIA/LogBonusCD.png", replace

use "$analysis/Results/2.RegIA/LogBonusLevel", clear
drop in 9/12

gen t1 = [_n]-4

twoway (scatter coef t1, color(blue) ) (line  coef t1, color(blue) )  (rcap ci_lower ci_upper t1, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Annual bonus (logs)") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/LogBonus.gph", replace
graph export "$analysis/Results/2.RegIA/LogBonus.png", replace

gr combine  "$analysis/Results/2.RegIA/LogBonus" "$analysis/Results/2.RegIA/LogBonusCD"
graph export "$analysis/Results/2.RegIA/LogBonusALL.png", replace


use "$analysis/Results/2.RegIA/PromChange", clear
keep in 3/26
drop in 9/16

gen t1 = [_n]-4
replace t1 = . if t1>4
gen  t2 = [_n]-12 if t1 == . // formula: [_n]-(#of lags +1)

twoway (scatter coef t1, color(blue) ) (line  coef t1, color(blue) )  (rcap ci_lower ci_upper t1, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Promotion") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/Promotion.gph", replace
graph export "$analysis/Results/2.RegIA/Promotion.png", replace

drop if t2 ==.
twoway (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (years)") ///
ytitle("Promotion") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/PromotionCD.gph", replace
graph export "$analysis/Results/2.RegIA/PromotionCD.png", replace

gr combine  "$analysis/Results/2.RegIA/Promotion" "$analysis/Results/2.RegIA/PromotionCD"
graph export "$analysis/Results/2.RegIA/PromotionALL.png", replace


use "$analysis/Results/2.RegIA/LogPRSnapshot", clear
keep in 3/26
drop in 9/16

gen t1 = [_n]-4
replace t1 = . if t1>4
gen  t2 = [_n]-12 if t1 == . // formula: [_n]-(#of lags +1)

twoway (scatter coef t1, color(blue) ) (line  coef t1, color(blue) )  (rcap ci_lower ci_upper t1, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Performance Score (logs)") xlabel(-3(1)3) yline(0) xline(-1,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/PRSnapshot.gph", replace
graph export "$analysis/Results/2.RegIA/PRSnapshot.png", replace

drop if t2 ==.
twoway (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (years)") ///
ytitle("Performance Score (logs)") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/PRSnapshotCD.gph", replace
graph export "$analysis/Results/2.RegIA/PRSnapshotCD.png", replace

gr combine  "$analysis/Results/2.RegIA/PRSnapshot" "$analysis/Results/2.RegIA/PRSnapshotCD"
graph export "$analysis/Results/2.RegIA/PRSnapshotALL.png", replace


use "$analysis/Results/2.RegIA/LeaverLevel", clear
drop in 6/15

gen t = [_n]-1

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Leave") xlabel(0(1)4) yline(0) xline(0,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/Leave.gph", replace
graph export "$analysis/Results/2.RegIA/Leave.png", replace

use "$analysis/Results/2.RegIA/Leaver", clear
keep in 13/17

gen t = [_n]-1

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Leave") xlabel(0(1)4) yline(0) xline(0,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/LeaveCD.gph", replace
graph export "$analysis/Results/2.RegIA/LeaveCD.png", replace

gr combine  "$analysis/Results/2.RegIA/Leave" "$analysis/Results/2.RegIA/LeaveCD"
graph export "$analysis/Results/2.RegIA/LeaveALL.png", replace



use "$analysis/Results/2.RegIA/LeaverInvLevel", clear
drop in 6/15

gen t = [_n]-1

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Involuntary Leave") xlabel(0(1)4) yline(0) xline(0,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/LeaveInv.gph", replace
graph export "$analysis/Results/2.RegIA/LeaveInv.png", replace

use "$analysis/Results/2.RegIA/LeaverInv", clear
keep in 13/17

gen t = [_n]-1

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Involuntary Leave") xlabel(0(1)4) yline(0) xline(0,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/LeaveInvCD.gph", replace
graph export "$analysis/Results/2.RegIA/LeaveInvCD.png", replace

gr combine  "$analysis/Results/2.RegIA/LeaveInv" "$analysis/Results/2.RegIA/LeaveInvCD"
graph export "$analysis/Results/2.RegIA/LeaveInvALL.png", replace

use "$analysis/Results/2.RegIA/LeaverVolLevel", clear
drop in 6/15

gen t = [_n]-1

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Voluntary Leave") xlabel(0(1)4) yline(0) xline(0,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/LeaveVol.gph", replace
graph export "$analysis/Results/2.RegIA/LeaveVol.png", replace

use "$analysis/Results/2.RegIA/LeaverVol", clear
keep in 13/17

gen t = [_n]-1

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Voluntary Leave") xlabel(0(1)4) yline(0) xline(0,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/LeaveVolCD.gph", replace
graph export "$analysis/Results/2.RegIA/LeaveVolCD.png", replace

gr combine  "$analysis/Results/2.RegIA/LeaveVol" "$analysis/Results/2.RegIA/LeaveVolCD"
graph export "$analysis/Results/2.RegIA/LeaveVolALL.png", replace


use "$analysis/Results/2.RegIA/PromChangeLevelH", clear
drop in 9/18

gen t = [_n]-4

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Promotion") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/PromH.gph", replace
graph export "$analysis/Results/2.RegIA/PromH.png", replace

use "$analysis/Results/2.RegIA/PromChangeH", clear
drop in 1/18
drop in 9/21

gen t = [_n]-4

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Promotion") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/PromHCD.gph", replace
graph export "$analysis/Results/2.RegIA/PromHCD.png", replace

gr combine  "$analysis/Results/2.RegIA/PromH" "$analysis/Results/2.RegIA/PromHCD"
graph export "$analysis/Results/2.RegIA/PromHALL.png", replace



use "$analysis/Results/2.RegIA/JobChangeLevelH", clear
drop in 9/18

gen t = [_n]-4

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Job Change") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/JobChangeH.gph", replace
graph export "$analysis/Results/2.RegIA/JobChangeH.png", replace

use "$analysis/Results/2.RegIA/JobChangeH", clear
drop in 1/18
drop in 9/21

gen t = [_n]-4

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Job Change") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/JobChangeHCD.gph", replace
graph export "$analysis/Results/2.RegIA/JobChangeHCD.png", replace

gr combine  "$analysis/Results/2.RegIA/JobChangeH" "$analysis/Results/2.RegIA/JobChangeHCD"
graph export "$analysis/Results/2.RegIA/JobChangeHALL.png", replace

use "$analysis/Results/2.RegIA/JobChangeLevelH", clear
drop in 9/18

gen t = [_n]-4

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Job Change") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/JobChangeH.gph", replace
graph export "$analysis/Results/2.RegIA/JobChangeH.png", replace

use "$analysis/Results/2.RegIA/JobChangeH", clear
drop in 1/18
drop in 9/21

gen t = [_n]-4

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Job Change") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/JobChangeHCD.gph", replace
graph export "$analysis/Results/2.RegIA/JobChangeHCD.png", replace

gr combine  "$analysis/Results/2.RegIA/JobChangeH" "$analysis/Results/2.RegIA/JobChangeHCD"
graph export "$analysis/Results/2.RegIA/JobChangeHALL.png", replace



use "$analysis/Results/2.RegIA/JobChangeLevel", clear
drop in 9/12

gen t = [_n]-4

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Job Change") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("IA Boss Effect")
graph save "$analysis/Results/2.RegIA/JobChange.gph", replace
graph export "$analysis/Results/2.RegIA/JobChange.png", replace

use "$analysis/Results/2.RegIA/JobChange", clear
drop in 1/18
drop in 9/14

gen t = [_n]-4

twoway (scatter coef t, color(blue) ) (line  coef t, color(blue) )  (rcap ci_lower ci_upper t, color(blue))  , xtitle("Event Time (years)") ///
ytitle("Job Change") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("Cultural Distance Effect")
graph save "$analysis/Results/2.RegIA/JobChangeCD.gph", replace
graph export "$analysis/Results/2.RegIA/JobChangeCD.png", replace

gr combine  "$analysis/Results/2.RegIA/JobChange" "$analysis/Results/2.RegIA/JobChangeCD"
graph export "$analysis/Results/2.RegIA/JobChangeALL.png", replace


********************************************************************************
* 2. Regressions - month level
********************************************************************************

* Select a window
keep if (WindowIA1 <=24 & WindowIA1 >=-12) | WindowIA1 == 999
egen WindowIA1E = group(WindowIA1)

* Proportional hazard model- replace manager FE with HomecountryManager FE
xtcloglog Leaver CulturalDistanceAbove##b13.WindowIA1E  JointTenure ///
i.HomeCountryManager i.Year, nolog vce(cluster IDlse) 
outreg2 using "$analysis/Results/2.RegIA/`y'.tex", replace keep(c.`x'##c.teamCDistance  )
preserve
regsave using "$analysis/Results/2.RegIA/`y'xctlog.dta", ci replace level(95) 
restore

foreach y is $outcomesChange{
reghdfe Leaver CulturalDistanceAbove##b13.WindowIA1E JointTenure , cluster(Block) a(IDlse IDlseManager Year  RoundIAManager)

preserve
regsave using "$analysis/Results/2.RegIA/`y'.dta", ci replace level(95) 
restore

reghdfe Leaver OutGroup##b13.WindowIA1E JointTenure , cluster(Block) a(IDlse IDlseManager Year  RoundIAManager)

preserve
regsave using "$analysis/Results/2.RegIA/`y'OutGroup.dta", ci replace level(95) 
restore
}	
