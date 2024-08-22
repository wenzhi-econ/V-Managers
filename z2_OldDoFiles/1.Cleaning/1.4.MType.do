* This dofile looks at managers types 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* CREATE DATASET: LINE MANAGER SCORE 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

keep IDlse IDlseMHR YearMonth Year 
merge 1:1 IDlse YearMonth  using "$fulldta/Univoice.dta", keepusing(LineManager)
keep if _merge ==3 
drop _merge 

bys IDlseMHR YearMonth: egen LMScore = mean(LineManager)

gen o =1 
drop if IDlseMHR==. 
collapse  LMScore (sum) NumRespondents = o, by(IDlseMHR YearMonth Year)
isid IDlseMHR YearMonth
label var LMScore "Average score of LM (in year)" 
label var NumRespondents "Number of respondents per LM (in year)" 

compress
label data "LineManager score at the manager-year level (from Univoice)" 
save "$managersdta/LMScore.dta", replace 
 

********************************************************************************
* CREATE DATASET: LEAVE OUT MEAN OF PROMOTION AND EXIT 2011-2021
********************************************************************************

////////////////////////////////////////////
// Does not have to be re-rerun each time //
////////////////////////////////////////////

* 1) residualize promotion and exit. 
***
use  "$managersdta/AllSnapshotMCulture.dta", clear
egen OfficeYear = group(Office Year )
reghdfe  ChangeSalaryGrade c.Tenure##c.Tenure##i.Female, a(i.Func i.AgeBand OfficeYear  ) residuals(ChangeSalaryGradeR)
reghdfe  LeaverVol c.Tenure##c.Tenure##i.Female, a(i.Func i.AgeBand OfficeYear  ) residuals(LeaverVolR)

preserve 
keep ChangeSalaryGradeR LeaverVolR IDlse YearMonth TransferSJC TransferFuncC TransferInternalC PromWLC ChangeSalaryGradeC 
save "$managersdta/Temp/PromExitRes.dta", replace 
restore 
***

* 2) Create team mean for each manager. 
***
use  "$managersdta/AllSnapshotMCulture.dta", clear
merge 1:1 IDlse YearMonth using "$managersdta/Temp/PromExitRes.dta"

xtset IDlse YearMonth 
gen IDlseMHRMatch = l3.IDlseMHR // to account that manager may promote and employee changes team as a result

bys IDlse IDlseMHRMatch: egen ChangeSalaryGradeRIDlseMHR = mean(ChangeSalaryGradeR) if IDlseMHRMatch !=.
xtset IDlse YearMonth 
replace ChangeSalaryGradeRIDlseMHR = f3.ChangeSalaryGradeRIDlseMHR // to restore the accurate timing of an employee-manager match 
bys IDlse IDlseMHRMatch: egen LeaverVolRIDlseMHR = mean(LeaverVolR) if IDlseMHRMatch !=.
xtset IDlse YearMonth 
replace LeaverVolRIDlseMHR = f3.LeaverVolRIDlseMHR
bys IDlse Spell: gen ts = 1 if YearMonth==SpellEnd // end of the spell, can be changed to start spell to max no obs? 
replace ChangeSalaryGradeRIDlseMHR = . if ts ==. 
replace LeaverVolRIDlseMHR = . if ts ==. 

preserve 
collapse ChangeSalaryGradeRIDlseMHR LeaverVolRIDlseMHR  (sum) ts, by(IDlseMHR YearMonth)
drop if IDlseMHR ==.
xtset IDlseMHR YearMonth 
bys IDlseMHR (YearMonth), sort: gen CumReporteesM = sum(ts)
bys IDlseMHR (YearMonth), sort: gen ChangeSalaryGradeRM = sum(ChangeSalaryGradeRIDlseMHR)
bys IDlseMHR (YearMonth), sort: gen LeaverVolRM = sum(LeaverVolRIDlseMHR)
xtset IDlseMHR YearMonth
*gen lChangeSalaryGradeRM = l.ChangeSalaryGradeRM
*gen lCumReporteesM  = l.CumReporteesM 
*replace CumReporteesM = lCumReporteesM 
*replace ChangeSalaryGradeRM = lChangeSalaryGradeRM
gen  ChangeSalaryGradeRMMean =   ChangeSalaryGradeRM / CumReporteesM 
gen LeaverVolRMMean = LeaverVolRM / CumReporteesM 
keep ChangeSalaryGradeRMMean LeaverVolRMMean  ChangeSalaryGradeRM LeaverVolRM  CumReporteesM IDlseMHR YearMonth
save "$managersdta/Temp/PromExitResM.dta", replace 
restore 
***

********************************************************************************
* CREATE DATASET: Manager Pay Growth 2016-2021
********************************************************************************

////////////////////////////////////////////
// Does not have to be re-rerun each time //
////////////////////////////////////////////

use  "$managersdta/AllSnapshotMCulture.dta", clear

*MonthsSGCumM   TimetoChangeSGM MonthsSGM
gen  PayBonusM =  PayM+BonusM
collapse PayBonusM, by(IDlseMHR Year) // collapse at the year level 
xtset IDlseMHR Year
gen LogPayBonusM = log(PayBonusM)
gen  PayBonusGrowthM = d.LogPayBonusM 
winsor2 PayBonusGrowthM, trim suffix(T) cut(1 99)
replace PayBonusGrowthM = PayBonusGrowthMT
keep PayBonusGrowthM LogPayBonusM IDlseMHR Year 
save "$managersdta/Temp/PayBonusGrowthM.dta", replace 

********************************************************************************
* CREATE DATASET: DATASET WITH ALL MANAGER TYPES - manager-month level dataset 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

* add social connections 
merge 1:1 IDlse YearMonth using "$managersdta/Temp/MTransferConnectedAll.dta", keepusing( ///
Connected ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4 ///
ConnectedC ConnectedManagerC ConnectedSubFuncC ConnectedOfficeC ConnectedOrg4C ///
ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
ConnectedLC ConnectedManagerLC ConnectedSubFuncLC ConnectedOfficeLC ConnectedOrg4LC ///
ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ConnectedVC ConnectedManagerVC ConnectedSubFuncVC ConnectedOfficeVC ConnectedOrg4VC ) 
drop if _merge ==2
drop _merge 

* these variables take value 1 for the entire duration of the manager-employee spell, to get accurate data change that so that they only take value 1 on the month of manager change 
foreach var in Connected ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4 ///
ConnectedC ConnectedManagerC ConnectedSubFuncC ConnectedOfficeC ConnectedOrg4C ///
ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
ConnectedLC ConnectedManagerLC ConnectedSubFuncLC ConnectedOfficeLC ConnectedOrg4LC ///
ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ConnectedVC ConnectedManagerVC ConnectedSubFuncVC ConnectedOfficeVC ConnectedOrg4VC{
	replace `var' = 0 if ChangeM==0 
}

********************************************************************************
* MERGE PRODUCTIVITY DATA 
********************************************************************************

* Monthly *
merge 1:1 IDlse YearMonth using "$produc/dta/CDProductivityMonth" , keepusing(Productivity* ProdGroup FreqMonth)
drop if _merge ==2 
drop _merge 

* Quarterly (Italy IH only as of 9 June 2021) *
preserve
use "$produc/dta/CDProductivityQuarter", clear
keep if FreqQuarter==1
tempfile quarterly
save `quarterly'
restore

gen Quarter = qofd(dofm(YearMonth))
merge m:1 IDlse Quarter using `quarterly' , keepusing(Productivity* ProdGroup FreqQuarter)  update
drop if _merge==2
drop _merge

* Yearly *
preserve
use "$produc/dta/CDProductivityYear", clear
keep if FreqYear==1
tempfile yearly
save `yearly'
restore

merge m:1 IDlse Year using `yearly', keepusing(Productivity* ProdGroup File FreqYear) update
drop if _merge==2
drop _merge

********************************************************************************
* M TYPE: UPWARD FEEDBACK SURVEY FROM UNIVOICE 2018-2019
********************************************************************************

merge m:1 IDlse Year using "$fulldta/UniVoice.dta" 
drop if _merge ==2 
drop _merge 
 
********************************************************************************
* M TYPE: WL3+ 2011-2021
********************************************************************************

replace WL =1 if WL == 0 
replace WLM =1 if WLM == 0 

gen DirectorM = WLM > 2 if WLM!=. // Manager is at least director 

********************************************************************************
* M TYPE: VPA  of manager 2017-2021
********************************************************************************

gen VPAHighM = VPAM >= 125 if VPAM!=.

********************************************************************************
* M TYPE:Speed / Time to Promotion (only defined if manager ever changes salary grade)
********************************************************************************

su YearstoChangeSGM 
gen SGSpeedM = 1/YearstoChangeSGM 

********************************************************************************
* M TYPE: LEAVE OUT MEAN OF PROMOTION AND EXIT 2011-2021
********************************************************************************

* IMPORT THE TEAM MEAN as a past leave out mean for employee level regressions 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/PromExitResM.dta", keepusing( ChangeSalaryGradeRMMean LeaverVolRMMean   )
drop _merge
bys IDlse Spell : egen z = max(cond(YearMonth == SpellStart, ChangeSalaryGradeRMMean,.)) // to make sure the measure excludes the current employee  as a proper leave out mean
replace ChangeSalaryGradeRMMean = z
drop z
bys IDlse Spell : egen z = max(cond(YearMonth == SpellStart, LeaverVolRMMean,.)) // to make sure the measure excludes the current employee  as a proper leave out mean
replace LeaverVolRMMean = z
drop z
 
/*
xtset IDlse YearMonth 
foreach var in PayBonus TransferSJ TransferInternalSJ TransferInternal ChangeSalaryGrade PromWL TransferSJDiffM TransferInternalSJDiffM TransferInternalDiffM ChangeSalaryGradeDiffM PromWLDiffM  TransferSJSameM TransferInternalSJSameM TransferInternalSameM ChangeSalaryGradeSameM PromWLSameM LeaverVol {
	gen `var'F3 = f3.`var'
	replace `var'= `var'F3 // ASSIGN TO THE MANAGER OUTCOMES THAT REALIZE within 3 months of manager change
}

* TeamPayBonus TeamTransferSJ TeamTransferInternalSJ TeamTransferInternal TeamChangeSalaryGrade TeamPromWL TeamTransferSJDiffM TeamTransferInternalSJDiffM TeamTransferInternalDiffM TeamChangeSalaryGradeDiffM TeamPromWLDiffM  TeamTransferSJSameM TeamTransferInternalSJSameM TeamTransferInternalSameM TeamChangeSalaryGradeSameM TeamPromWLSameM TeamLeaverVol

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
*/

* gen pay growth & team exit 
xtset IDlse YearMonth
gen PayGrowth = LogPayBonus - l.LogPayBonus 
* create forward version for the transfers under a different manager 
foreach v in Connected ConnectedManager ConnectedOffice ConnectedOrg4 ConnectedSubFunc ///
 ConnectedL ConnectedManagerL ConnectedSubFuncL ConnectedOfficeL ConnectedOrg4L ///
 ConnectedV ConnectedManagerV ConnectedSubFuncV ConnectedOfficeV ConnectedOrg4V ///
ChangeM TransferSJDiffM TransferInternalSJDiffM TransferInternalDiffM ChangeSalaryGradeDiffM PromWLDiffM {
	forval i = 1/6{
gen F`i'`v' = f.`v'
}
}

egen ExitTeam = rowmax(F1ChangeM LeaverPerm)

* consider job transfers under diff manager up to 6 months after manager change 
foreach var in TransferSJDiffM TransferInternalSJDiffM TransferInternalDiffM ChangeSalaryGradeDiffM PromWLDiffM {
egen F6m`var' = rowmax( F1`var' F2`var' F3`var' F4`var' F5`var' F6`var' )
egen F3m`var' = rowmax(F1`var' F2`var' F3`var' )
} 

********************************************************************************
* COLLAPSE AT THE MANAGER LEVEL
********************************************************************************

drop if IDlseMHR==.

gen o =1 
collapse EarlyAgeM MaxWLM MinWLM EarlyAgeTenureM IAM EarlyTenureM CountryM OfficeCodeM  SubFuncM FuncM FemaleM AgeBandM TenureM WLM DirectorM VPAM VPAHighM PRIM  PromWLCM LogPayBonusM  LeaverPermM LeaverVolM LeaverInvM LineManager SGSpeedM TransferInternalM TransferSJM ChangeSalaryGradeRMMean LeaverVolRMMean  ///
TeamHHI* TeamFrac* ShareFemale = Female ShareOutGroup = OutGroup  ShareSameG = SameGender  ShareSameOffice = SameOffice ShareSameCountry = SameCountry ShareSameNationality = SameNationality ShareSameLanguage = SameLanguage ShareSameAge = SameAge F1ShareConnected = F1Connected F1ShareConnectedManager= F1ConnectedManager F1ShareConnectedOffice=  F1ConnectedOffice F1ShareConnectedOrg4 =F1ConnectedOrg4 F1ShareConnectedSubFunc= F1ConnectedSubFunc ///
F1ShareConnectedL= F1ConnectedL F1ShareConnectedManagerL =F1ConnectedManagerL F1ShareConnectedSubFuncL= F1ConnectedSubFuncL F1ShareConnectedOfficeL= F1ConnectedOfficeL F1ShareConnectedOrg4L= F1ConnectedOrg4L ///
F1ShareConnectedV = F1ConnectedV F1ShareConnectedManagerV=F1ConnectedManagerV F1ShareConnectedSubFuncV=F1ConnectedSubFuncV F1ShareConnectedOfficeV=F1ConnectedOfficeV F1ShareConnectedOrg4V =F1ConnectedOrg4V  ///  
AvProductivityStd = ProductivityStd AvProductivity = Productivity AvTenure=Tenure AvPay = PayBonus  AvVPA = VPA AvPayGrowth = PayGrowth ///
ShareChangeOffice= ChangeOffice ShareLeaverVol = LeaverVol ShareLeaverInv = LeaverInv  ShareLeaver = LeaverPerm ShareOrg4 = TransferOrg4 ShareTransferSJ = TransferSJ  ShareTransferInternalSJ = TransferInternalSJ   ShareTransferInternal= TransferInternal ShareTransferSJSameM = TransferSJSameM ShareTransferFunc = TransferFunc  ///
SharePromWL=  PromWL  ShareChangeSalaryGrade = ChangeSalaryGrade ShareNewHire = NewHire ShareTenureBelow1 = TenureBelow1 ShareTenureBelowEq1 = TenureBelowEq1 ShareTeamJoiners = ChangeM ShareTeamLeavers = F1ChangeM  ShareExitTeam =  ExitTeam ///
F1ShareTransferSJDiffM = F1TransferSJDiffM F1ShareTransferInternalSJDiffM = F1TransferInternalSJDiffM  F1ShareTransferInternalDiffM= F1TransferInternalDiffM F1ShareChangeSalaryGradeDiffM = F1ChangeSalaryGradeDiffM  F1SharePromWLDiffM=  F1PromWLDiffM  ///
F3mShareTransferSJDiffM = F3mTransferSJDiffM F3mShareTransferInternalSJDiffM = F3mTransferInternalSJDiffM  F3mShareTransferInternalDiffM= F3mTransferInternalDiffM F3mShareChangeSalaryGradeDiffM = F3mChangeSalaryGradeDiffM  F3mSharePromWLDiffM=  F3mPromWLDiffM /// 
F6mShareTransferSJDiffM = F6mTransferSJDiffM F6mShareTransferInternalSJDiffM = F6mTransferInternalSJDiffM  F6mShareTransferInternalDiffM= F6mTransferInternalDiffM F6mShareChangeSalaryGradeDiffM = F6mChangeSalaryGradeDiffM  F6mSharePromWLDiffM=  F6mPromWLDiffM ///
(sd) SDProductivityStd = ProductivityStd SDProductivity = Productivity SDPay = PayBonus SDVPA = VPA (sum) SpanM = o (first) StandardJobM ISOCodeM, by(IDlseMHR YearMonth Year )

* taken out: TeamTransferSJC = TransferSJC TeamPromWLSameMC= PromWLSameMC TeamChangeSalaryGradeC = ChangeSalaryGradeC TeamChangeSalaryGradeSameMC = ChangeSalaryGradeSameMC TeamTransferInternalSJSameMC = TransferInternalSJSameMC TeamChangeSalaryGradeDiffMC = ChangeSalaryGradeDiffMC TeamPromWLDiffMC=  PromWLDiffMC TeamTransferInternalC= TransferInternalC TeamPromWLC=  PromWLC TeamTransferInternalSJC = TransferInternalSJC TeamTransferInternalSJDiffMC = TransferInternalSJDiffMC TeamID NoTeam MTeamDuration

*foreach var in PayBonus TransferSJ TransferInternalSJ TransferInternal ChangeSalaryGrade PromWL TransferSJDiffM TransferInternalSJDiffM TransferInternalDiffM ChangeSalaryGradeDiffM PromWLDiffM LeaverVol

********************************************************************************
* M TYPE: Manager Pay Growth 2016-2021
********************************************************************************

merge m:1 IDlseMHR  Year using "$managersdta/Temp/PayBonusGrowthM.dta", keepusing(PayBonusGrowthM )
drop if _merge ==2
drop _merge 

********************************************************************************
* M TYPE: VPA & Line Manager High 2018-2021
********************************************************************************

bys IDlseMHR: egen VPAMMean = mean(VPAM)

bys IDlseMHR: egen LineManagerMean = mean(LineManager )
gen LineManagerMeanB = LineManagerMean >4 if LineManagerMean  !=. // effective LM 
gen LineManagerB = LineManager >4 if LineManager  !=. // effective LM 

********************************************************************************
* ALL M TYPES
********************************************************************************

foreach var in  Pay VPA Productivity  ProductivityStd {
	gen CV`var' = SD`var' / Av`var'
}
egen CountryMYear = group(CountryM Year)

foreach var in VPAMMean PayBonusGrowthM SGSpeedM ChangeSalaryGradeRMMean LeaverVolRMMean {
	su `var', d 
	gen `var'B = `var' > r(p50) if `var'!=.
}

/* Change Team Event 
gsort IDlseMHR YearMonth 
gen ChangeTeam = 0 
replace ChangeTeam = 1 if (IDlseMHR[_n] == IDlseMHR[_n-1] & TeamID[_n] != TeamID[_n-1]   )
replace ChangeTeam = . if TeamID ==. 
bys IDlseMHR: egen mm = min(YearMonth)
replace ChangeTeam = 0  if YearMonth ==mm & ChangeTeam==1
drop mm
*/

* first month as a manager 
bys IDlseMHR: egen FirstYMManager = min(YearMonth)
format FirstYMManager  %tm
label var FirstYMManager "First month observed as a manager (2011m1 obs censored)"

* Manager type based on span of control at the max WL observed 
bys IDlseMHR : egen MaxWLFuncM = mode(FuncM) if WLM==MaxWLM, maxmode // take the function at the maximum WL
bys IDlseMHR : egen MaxWLCountryM = mode(CountryM) if WLM==MaxWLM , maxmode // take the country at the maximum WL

bys IDlseMHR: egen MaxWLSpanM = max(cond(WLM ==MaxWLM, SpanM, .)) // take the maximum team size at the manager max WL 
bys WLM FuncM CountryM:  egen bb = pctile(SpanM), p(80) // take the p90 team size within WL. func and country
gen LargeSpanM  = MaxWLSpanM >bb if FuncM == MaxWLFuncM & CountryM == MaxWLCountryM & MaxWLSpanM!=.
bys IDlseMHR: egen maxLargeSpanM = max(LargeSpanM)
replace LargeSpanM= maxLargeSpanM 
drop maxLargeSpanM bb  MaxWLSpanM MaxWLFuncM   MaxWLCountryM

su EarlyAgeM  LargeSpanM EarlyTenureM DirectorM VPAHighM LineManagerB PayBonusGrowthM ChangeSalaryGradeRMMean LeaverVolRMMean SGSpeedM
pwcorr EarlyAgeM  LargeSpanM EarlyTenureM DirectorM VPAHighM LineManagerB PayBonusGrowthM ChangeSalaryGradeRMMean LeaverVolRMMean SGSpeedM

compress 
save "$managersdta/Temp/MType.dta", replace 

********************************************************************************
* Add productivity data for the manager 
********************************************************************************

use  "$managersdta/Temp/MType.dta", clear 
rename IDlseMHR IDlse 

* Monthly *
merge 1:1 IDlse YearMonth using "$produc/dta/CDProductivityMonth" , keepusing(Productivity* ProdGroup ISOCode FreqMonth)
drop if _merge ==2 
drop _merge 

* Quarterly (Italy IH only as of 9 June 2021) *
preserve
use "$produc/dta/CDProductivityQuarter", clear
keep if FreqQuarter==1
tempfile quarterly
save `quarterly'
restore

gen YearQuarter = qofd(dofm(YearMonth))
merge m:1 IDlse YearQuarter using `quarterly' , keepusing(Productivity* ProdGroup ISOCode FreqQuarter)  update
drop if _merge==2
drop _merge

* Yearly *
preserve
use "$produc/dta/CDProductivityYear", clear
keep if FreqYear==1
tempfile yearly
save `yearly'
restore

merge m:1 IDlse Year using `yearly', keepusing(Productivity* ProdGroup File FreqYear) update
drop if _merge==2
drop _merge

rename ISOCode ISOCodeProd

rename IDlse IDlseMHR
rename ProductivityStd ProductivityStdM
rename Productivity ProductivityM 
rename ProdGroup ProdGroupM
compress 
save "$managersdta/Temp/MType.dta", replace 

////////////////////////////////////////////////////////////////////////////////
* Additional dataset with team characteristics  
* looks at the characteristics of team joiners, leavers and firm leavers 
////////////////////////////////////////////////////////////////////////////////

use  "$managersdta/AllSnapshotMCulture.dta", clear

merge m:1 Office SubFuncS StandardJob YearMonth using "$managersdta/NewOldJobs.dta" , keepusing(NewJob OldJob)
drop _merge 

*do "$analysis/DoFiles/4.Event/4.0.TWFEPrep" // only consider first event as with new did estimators 

merge m:1 StandardJob  YearMonth IDlseMHR Office  using "$managersdta/NewOldJobsManager.dta", keepusing(NewJobManager OldJobManager)
drop _merge
 
* Prepare variables
xtset IDlse YearMonth   
gen F1ChangeM = f.ChangeM
egen ExitTeam = rowmax(F1ChangeM LeaverPerm)

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

* tenure 
gen Tenure5 = Tenure <5 & NewHire!=1
gen Tenure10 = Tenure <10 & NewHire!=1 & Tenure5!=1

* pay growth
xtset IDlse YearMonth 
gen PayGrowth = d.LogPayBonus
bys IDlse Year: egen PayGrowth1y = mean( PayGrowth) 
su PayGrowth1y,d
gen PayGrowth1yAbove0 = PayGrowth1y>0 if PayGrowth1y!=.
gen PayGrowth1yAbove1 = PayGrowth1y>=0.01 if PayGrowth1y!=.

 
global charsCoef Female Age20 MBA Econ Sci Hum  NewHire Tenure5 EarlyAge PayGrowth1yAbove0 PayGrowth1yAbove1
*  ChangeSalaryGradeC  

* generate the interaction variables 
foreach y in LeaverPerm ExitTeam ChangeM F1ChangeM {
foreach var in $charsCoef{
gen `y'`var' = `y'*`var'
}
}

* Share VPA >= 125
gen VPA115 = VPA >= 115 if VPA!=. 
gen VPA101 = VPA >= 101 if VPA!=. 
gen VPAL100 = VPA <= 100 if VPA!=. 
gen VPAL80 = VPA <= 80 if VPA!=. 

* Collapse 
gcollapse VPAL80 VPAL100 VPA125 VPA115 VPA101 LeaverPerm* ExitTeam* ChangeM* F1ChangeM* $charsCoef Age30 Age40 Age50 NewJobManager OldJobManager NewJob OldJob , by(IDlseMHR YearMonth)

drop LeaverPerm LeaverPermM  ExitTeam ChangeM F1ChangeM ChangeMPW  ChangeMNoPW  

* New jobs and old jobs 
label var NewJob "Share new jobs"
label var OldJob "Share old jobs"
label var NewJobManager "Share new jobs"
label var OldJobManager "Share old jobs"

* OVERALL TEAM COMPOSITION SHARES 
label var Female "Share Female"
label var Age20  "Share Age < 20"
label var MBA "Share MBA"
label var Econ "Share Econ"
label var Sci "Share STEM"
label var Hum  "Share Humanities"
label var NewHire "Share New Hire"
label var Tenure5 "Share Tenure <5"
label var EarlyAge "Share Fast Track"
label var PayGrowth1yAbove0 "Share PayGrowth>0"
label var PayGrowth1yAbove1 "Share PayGrowth>0.01"

* team joiners and leavers profiles 
label var F1ChangeMFemale "Change Team, Female" 
label var ChangeMFemale "Join Team, Female" 
label var LeaverPermFemale "Exit Firm, Female" 
label var ExitTeamFemale "Exit Team, Female" 

label var F1ChangeMAge20 "Change Team, Age<30" 
label var ChangeMAge20 "Join Team, Age<30" 
label var LeaverPermAge20 "Exit Firm, Age<30"
label var ExitTeamAge20 "Exit Team, Age<30"

label var F1ChangeMEcon "Change Team, Econ" 
label var ChangeMEcon "Join Team, Econ" 
label var LeaverPermEcon "Exit Firm, Econ"
label var ExitTeamEcon "Exit Team, Econ"

label var F1ChangeMMBA "Change Team, MBA" 
label var ChangeMMBA "Join Team, MBA" 
label var LeaverPermMBA "Exit Firm, MBA"
label var ExitTeamMBA "Exit Team, MBA"

label var F1ChangeMSci "Change Team, STEM" 
label var ChangeMSci "Join Team, STEM" 
label var LeaverPermSci "Exit Firm, STEM"
label var ExitTeamSci "Exit Team, STEM"

label var F1ChangeMHum "Change Team, Hum" 
label var ChangeMHum "Join Team, Hum" 
label var LeaverPermHum "Exit Firm, Hum"
label var ExitTeamHum "Exit Team, Hum"

label var F1ChangeMNewHire "Change Team, New Hire" 
label var ChangeMNewHire "Join Team, New Hire" 
label var LeaverPermNewHire "Exit Firm, New Hire"
label var ExitTeamNewHire "Exit Team, New Hire"

label var F1ChangeMTenure5 "Change Team, Tenure<5" 
label var ChangeMTenure5 "Join Team, Tenure<5" 
label var LeaverPermTenure5 "Exit Firm, Tenure<5"
label var ExitTeamTenure5 "Exit Team, Tenure<5"

label var F1ChangeMEarlyAge "Change Team, Fast Track" 
label var ChangeMEarlyAge "Join Team, Fast Track" 
label var LeaverPermEarlyAge "Exit Firm, Fast Track"
label var ExitTeamEarlyAge "Exit Team, Fast Track"

label var F1ChangeMPayGrowth1yAbove0 "Change Team, PayGrowth>0" 
label var ChangeMPayGrowth1yAbove0 "Join Team, PayGrowth>0" 
label var LeaverPermPayGrowth1yAbove0 "Exit Firm, PayGrowth>0"
label var ExitTeamPayGrowth1yAbove0 "Exit Team, PayGrowth>0"

label var F1ChangeMPayGrowth1yAbove1 "Change Team, PayGrowth>0.01" 
label var ChangeMPayGrowth1yAbove1 "Join Team, PayGrowth>0.01" 
label var LeaverPermPayGrowth1yAbove1 "Exit Firm, PayGrowth>0.01"
label var ExitTeamPayGrowth1yAbove1 "Exit Team, PayGrowth>0.01"

* VPA  
label var VPAL80 "Share perf. appraisals <=80"
label var VPAL100 "Share perf. appraisals <=100"
label var VPA125 "Share perf. appraisals =125"
label var VPA115 "Share perf. appraisals >=115"
label var VPA101 "Share perf. appraisals >100"

compress 
save "$managersdta/Temp/TeamChurn.dta", replace 

********************************************************************************
* CREATE DATASET: SPAN OF CONTROL OF MANAGER'S MANAGER
********************************************************************************

* first get the manager's manager 
use "$managersdta/Temp/MType.dta", clear 
rename  IDlseMHR IDlse
merge 1:1 IDlse YearMonth using "$fulldta/ManagerIDReports.dta", keepusing(IDlseMHR)
keep if _merge ==3
drop _merge
save "$managersdta/Temp/MTypeMM.dta", replace  // manager's manager dataset 

keep IDlse YearMonth SpanM EarlyAgeM 

*Renaming variables
rename IDlse IDlseMHR
rename SpanM SpanMM // select team size 
rename EarlyAgeM EarlyAgeMM
* Compressing and saving MListChar
compress
save "$managersdta/Temp/MMListChar.dta", replace

use "$managersdta/Temp/MTypeMM.dta", clear 
merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MMListChar.dta", keepusing(SpanMM EarlyAgeMM) // get the team size of manager's manager 
drop if _merge ==2 
drop _merge
compress
rename IDlseMHR IDlseMHR2 // indicates the manager's manager 
rename IDlse IDlseMHR
save "$managersdta/Temp/MTypeMM.dta", replace 

use "$managersdta/Temp/MTypeMM.dta"
keep IDlseMHR YearMonth SpanM
rename IDlseMHR IDlse 
rename SpanM Span 
save "$managersdta/Temp/Span.dta", replace 


********************************************************************************
* CREATE DATASET: EMPLOYEE-LEVEL DATASET WITH ALL MANAGER TYPES 
********************************************************************************
		
use  "$managersdta/AllSnapshotMCulture.dta", clear

////////////////////////////////////////////////////////////////////////////////
* IMPORT THE TEAM MEAN as a past leave out mean for employee level regressions 
////////////////////////////////////////////////////////////////////////////////

merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/PromExitResM.dta", keepusing( ChangeSalaryGradeRMMean LeaverVolRMMean   )
drop _merge
bys IDlse Spell : egen z = max(cond(YearMonth == SpellStart, ChangeSalaryGradeRMMean,.)) // to make sure the measure excludes the current employee  as a proper leave out mean
replace ChangeSalaryGradeRMMean = z
drop z
bys IDlse Spell : egen z = max(cond(YearMonth == SpellStart, LeaverVolRMMean,.)) // to make sure the measure excludes the current employee  as a proper leave out mean
replace LeaverVolRMMean = z
drop z

su ChangeSalaryGradeRMMean, d
gen  ChangeSalaryGradeRMMeanB =  ChangeSalaryGradeRMMean >=r(p50)  if ChangeSalaryGradeRMMean !=.
su LeaverVolRMMean, d
gen  LeaverVolRMMeanB =  LeaverVolRMMean >=r(p50) if LeaverVolRMMean !=.

////////////////////////////////////////////////////////////////////////////////
* IMPORT THE OTHER MANAGER TYPES 
////////////////////////////////////////////////////////////////////////////////

merge m:1 IDlseMHR YearMonth using "$managersdta/Temp/MType.dta", keepusing( DirectorM VPAHighM LineManagerMean  PayBonusGrowthM PayBonusGrowthMB SGSpeedM SGSpeedMB  LargeSpanM FirstYMManager ) // manager type variables 
drop if _merge ==2
drop _merge 

////////////////////////////////////////////////////////////////////////////////
* UNIVOICE 
////////////////////////////////////////////////////////////////////////////////

merge m:1 IDlse Year using "$fulldta/UniVoice.dta" 
drop if _merge ==2 
drop _merge 
replace LineManagerMean = (LineManagerMean*TeamSize -  LineManager)/ (TeamSize -1) // leave out mean  
su LineManagerMean, d
gen LineManagerMeanB = LineManagerMean > r(p50) if LineManagerMean!=.

////////////////////////////////////////////////////////////////////////////////
* random sample to make estimation faster 
////////////////////////////////////////////////////////////////////////////////

set seed 25081993
egen t = tag(IDlse)
generate random = runiform() if t ==1 
bys IDlse: egen r = min(random)
sort r 
generate insample5 = _n <= 5000000
generate insample4 = _n <= 4000000
generate insample3 = _n <= 3000000
generate insample1 = _n <= 1000000
generate insamplesmaller = _n <= 200000
drop t r random
* manager WL cleaning 
replace WL =1 if WL == 0 
replace WLM =1 if WLM == 0 

/*Team ID 
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
*/

////////////////////////////////////////////////////////////////////////////////
* Education data 
////////////////////////////////////////////////////////////////////////////////

merge m:1 IDlseMHR using "$fulldta/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge 
foreach var in QualHigh FieldHigh1 FieldHigh2 FieldHigh3{
	rename `var'  `var'M
}

merge m:1 IDlse using "$fulldta/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge 

compress 
save "$managersdta/AllSnapshotMCultureMType.dta", replace 


