********************************************************************************
* TEAM ANALYSIS KEEPING COMPOSITION CONSTANT - FIXING THE TEAM AT THE TRANSITION TIME 
********************************************************************************

use "$managersdta/SwitchersAllSameTeam.dta", clear

bys IDlse: egen IDlseMHRPost = mean( cond(KEi==0 ,IDlseMHR,.))
bys IDlse: egen IDlseMHRPre = mean( cond(KEi==0 ,IDlseMHRPreMost,.))

egen IDteam = group(IDlseMHRPost IDlseMHRPre) // all workers with same pre and post manager 

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
* M TYPE: WL3+ 2011-2020
********************************************************************************

replace WL =1 if WL == 0 
replace WLM =1 if WLM == 0 

gen DirectorM = WLM > 2 if WLM!=. // Manager is at least director 

********************************************************************************
* M TYPE: VPA  of manager 2017-2020
********************************************************************************

gen VPAHighM = VPAM >= 125 if VPAM!=.

********************************************************************************
* M TYPE:Speed / Time to Promotion (only defined if manager ever changes salary grade)
********************************************************************************

su YearstoChangeSGM 
gen SGSpeedM = 1/YearstoChangeSGM 

********************************************************************************
* M TYPE: Manager Pay Growth 2016-2020
********************************************************************************

merge m:1 IDlseMHR  Year using "$managersdta/Temp/PayBonusGrowthM.dta", keepusing(PayBonusGrowthM )
drop if _merge ==2
drop _merge 

////////////////////////////////////////////////////////////////////////////////
* Additional dataset with team characteristics  
* looks at the characteristics of team joiners, leavers and firm leavers 
////////////////////////////////////////////////////////////////////////////////

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
foreach y in LeaverPerm ChangeM {
foreach var in $charsCoef{
gen `y'`var' = `y'*`var'
}
}

********************************************************************************
* COLLAPSE AT THE MANAGER LEVEL
********************************************************************************

gen o =1 
collapse LeaverPerm* ChangeM*  $charsCoef Age30 Age40 Age50 EarlyAgeM MaxWLM MinWLM EarlyAgeTenureM IAM EarlyTenureM CountryM OfficeCodeM  SubFuncM FuncM FemaleM AgeBandM TenureM WLM DirectorM VPAM VPAHighM PRIM  PromWLCM LogPayBonusM   LeaverVolM LeaverInvM LineManager PayBonusGrowthM SGSpeedM TransferInternalM TransferSJM  FTL* FTH*  EffectiveL* EffectiveH* PromSG75L* PromSG75H* PromWL75L* PromWL75H*  PromSG50L* PromSG50H* PromWL50L* PromWL50H* oddL* oddH* ///
TeamHHI* TeamFrac* ShareFemale = Female ShareOutGroup = OutGroup  ShareSameG = SameGender  ShareSameOffice = SameOffice ShareSameCountry = SameCountry ShareSameNationality = SameNationality ShareSameLanguage = SameLanguage ShareSameAge = SameAge ShareConnected = Connected ShareConnectedManager= ConnectedManager ShareConnectedOffice=  ConnectedOffice ShareConnectedOrg4 =ConnectedOrg4 ShareConnectedSubFunc= ConnectedSubFunc ///
ShareConnectedL= ConnectedL ShareConnectedManagerL =ConnectedManagerL ShareConnectedSubFuncL= ConnectedSubFuncL ShareConnectedOfficeL= ConnectedOfficeL ShareConnectedOrg4L= ConnectedOrg4L ///
ShareConnectedV = ConnectedV ShareConnectedManagerV=ConnectedManagerV ShareConnectedSubFuncV=ConnectedSubFuncV ShareConnectedOfficeV=ConnectedOfficeV ShareConnectedOrg4V =ConnectedOrg4V  ///  
AvProductivityStd = ProductivityStd AvProductivity = Productivity AvTenure=Tenure AvPay = PayBonus AvPayOnly = Pay AvBonus = Bonus  AvVPA = VPA AvPayGrowth = PayGrowth ///
ShareChangeOffice= ChangeOffice ShareLeaverVol = LeaverVol ShareLeaverInv = LeaverInv  ShareLeaver = LeaverPerm ShareOrg4 = TransferOrg4 ShareTransferSJ = TransferSJ  ShareTransferInternalSJ = TransferInternalSJ   ShareTransferInternal= TransferInternal ShareTransferSJSameM = TransferSJSameM ShareTransferFunc = TransferFunc  ///
SharePromWL=  PromWL  ShareChangeSalaryGrade = ChangeSalaryGrade ShareNewHire = NewHire ShareTenureBelow1 = TenureBelow1 ShareTenureBelowEq1 = TenureBelowEq1  ShareTeamLeavers = ChangeM  ///
ShareTransferSJDiffM = TransferSJDiffM ShareTransferInternalSJDiffM = TransferInternalSJDiffM  ShareTransferInternalDiffM= TransferInternalDiffM ShareChangeSalaryGradeDiffM = ChangeSalaryGradeDiffM  SharePromWLDiffM= PromWLDiffM  ///
(sd) SDProductivityStd = ProductivityStd SDProductivity = Productivity SDPayGrowth = PayGrowth SDBonus = Bonus SDPay = PayBonus SDPayOnly = Pay SDVPA = VPA (sum) SpanM = o (first) StandardJobM ISOCodeM, by(IDlseMHRPre IDlseMHRPost IDteam YearMonth Year KEi )

* taken out: TeamTransferSJC = TransferSJC TeamPromWLSameMC= PromWLSameMC TeamChangeSalaryGradeC = ChangeSalaryGradeC TeamChangeSalaryGradeSameMC = ChangeSalaryGradeSameMC TeamTransferInternalSJSameMC = TransferInternalSJSameMC TeamChangeSalaryGradeDiffMC = ChangeSalaryGradeDiffMC TeamPromWLDiffMC=  PromWLDiffMC TeamTransferInternalC= TransferInternalC TeamPromWLC=  PromWLC TeamTransferInternalSJC = TransferInternalSJC TeamTransferInternalSJDiffMC = TransferInternalSJDiffMC TeamID NoTeam MTeamDuration

*foreach var in PayBonus TransferSJ TransferInternalSJ TransferInternal ChangeSalaryGrade PromWL TransferSJDiffM TransferInternalSJDiffM TransferInternalDiffM ChangeSalaryGradeDiffM PromWLDiffM LeaverVol

********************************************************************************
* ALL M TYPES
********************************************************************************

foreach var in  Pay VPA Productivity  ProductivityStd Bonus PayGrowth PayOnly {
	gen CV`var' = SD`var' / Av`var'
}
egen CountryMYear = group(CountryM Year)

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
label var ChangeMFemale "Join Team, Female" 
label var LeaverPermFemale "Exit Firm, Female" 

label var ChangeMAge20 "Join Team, Age<30" 
label var LeaverPermAge20 "Exit Firm, Age<30"

label var ChangeMEcon "Join Team, Econ" 
label var LeaverPermEcon "Exit Firm, Econ"

label var ChangeMMBA "Join Team, MBA" 
label var LeaverPermMBA "Exit Firm, MBA"

label var ChangeMSci "Join Team, STEM" 
label var LeaverPermSci "Exit Firm, STEM"

label var ChangeMHum "Join Team, Hum" 
label var LeaverPermHum "Exit Firm, Hum"

label var ChangeMNewHire "Join Team, New Hire" 
label var LeaverPermNewHire "Exit Firm, New Hire"

label var ChangeMTenure5 "Join Team, Tenure<5" 
label var LeaverPermTenure5 "Exit Firm, Tenure<5"

label var ChangeMEarlyAge "Join Team, Fast Track" 
label var LeaverPermEarlyAge "Exit Firm, Fast Track"

label var ChangeMPayGrowth1yAbove0 "Join Team, PayGrowth>0" 
label var LeaverPermPayGrowth1yAbove0 "Exit Firm, PayGrowth>0"

label var ChangeMPayGrowth1yAbove1 "Join Team, PayGrowth>0.01" 
label var LeaverPermPayGrowth1yAbove1 "Exit Firm, PayGrowth>0.01"

compress 
save "$managersdta/Temp/TeamSwitchers.dta", replace 

********************************************************************************
* Add productivity data for the manager 
********************************************************************************

use  "$managersdta/Temp/TeamSwitchers.dta", clear 
xtset IDteam YearMonth
 
gen IDlseMHR = IDlseMHRPre if KEi <0
replace IDlseMHR = IDlseMHRPost if KEi >=0
rename IDlseMHR IDlse 

* Monthly *
merge m:1 IDlse YearMonth using "$produc/dta/CDProductivityMonth" , keepusing(Productivity* ProdGroup ISOCode FreqMonth) // merge m:1 because some managers are repeated twice 
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
merge m:1 IDlse Quarter using `quarterly' , keepusing(Productivity* ProdGroup ISOCode FreqQuarter)  update
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

rename IDlse IDlseMHRPrePost
rename ProductivityStd ProductivityStdM
rename Productivity ProductivityM 
rename ProdGroup ProdGroupM


* OUTCOME VARIABLES 
label var ShareLeaver "Exit Firm"
label var ShareLeaverVol "Exit Firm (Vol.)"
label var ShareLeaverInv "Exit Firm (Inv.)"
label var ShareTransferInternal  "Sub-func Change"
label var ShareOrg4  "Org. Unit Change"
label var ShareChangeSalaryGrade  "Prom. (salary)"
label var SharePromWL  "Prom. (work level)"
label var ShareTeamLeavers "Change Team"
label var ShareTenureBelow1 "New Hire"
label var ShareTenureBelowEq1 "New Hire"
label var ShareNewHire "New Hire"
label var ShareTransferSJ  "Job Change, same team"
label var ShareTransferSJSameM  "Job Change, same team"
label var CVPay  "Pay + Bonus (CV)"
label var CVPayOnly  "Pay (CV)"
label var CVPayGrowth "Pay Growth (CV)"
label var CVBonus  "Bonus (CV)"
label var CVVPA  "Perf. Appraisals (CV)"
label var SDProductivityStd "Productivity (SD)"
label var AvPayGrowth "Pay Growth"
label var AvPay "Av. Pay+Bonus"
label var AvProductivityStd "Productivity"

* Diversity / homophily
label var ShareFemale "Female Share"
label var ShareSameOffice "Same Office"
label var ShareSameG "Same Gender"
label var ShareOutGroup "Diff. Hiring Office"
label var ShareSameNationality "Same First Country"
label var ShareSameCountry "Same Country"
label var ShareSameAge "Same Age Band"
label var ShareConnected "Move within Manager's network"
label var ShareConnectedL "Lateral Move within Manager's network"
label var ShareConnectedV "Prom. within Manager's network"
label var TeamFracGender "Diversity, gender"
label var TeamFracOffice "Diversity, office"
label var TeamFracAge "Diversity, age"
label var TeamFracCountry "Diversity, country"
label var TeamFracNat "Diversity, nationality"

compress 
save "$managersdta/Temp/TeamSwitchers.dta", replace 


