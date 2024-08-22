*********************** Final dataset Preparation **************************

********************************************************************************
  * 0. Setting path to directory
********************************************************************************
  
clear all
set more off

cd "$analysis"

* set Matsize
//set matsize 11000
//set maxvar 32767

use "$managersdta/AllSnapshotM.dta", clear
xtset IDlse YearMonth // set panel data

replace WL =1 if WL == 0 
replace WLM =1 if WLM == 0 

* Working_cluster - relabeling
/*
Europe (including Central and Eastern Europe)
North Asia (Greater China and North East Asia)
South East Asia and Australasia
South Asia
Middle East (North Africa, Middle East, Turkey and Russia, Ukraine, Belarus )
Africa (Central Africa and South Africa)
North America
Latin America
*/

********************************************************************************
  * LOCATION VARS 
******************************************************************************** 

gen DiffCountry = 0
replace DiffCountry = 1 if CountryS !=CountrySM
replace DiffCountry = . if CountryS == ""  | CountrySM ==""
label var DiffCountry "=1 if manager in different country"
gen SameCountry = 1 - DiffCountry
label var SameCountry "=1 if manager in same country"

gen DiffOffice = 0
replace DiffOffice  = 1 if OfficeCode !=OfficeCodeM
replace DiffOffice  = . if OfficeCode == .  | OfficeCodeM ==.
label var DiffOffice "=1 if manager in different office"
gen SameOffice = 1 - DiffOffice 
label var SameOffice "=1 if manager in same office"

********************************************************************************
  * Merging with Culture
********************************************************************************

gen ISOCode1 = HomeCountryISOCode
gen ISOCode2 = HomeCountryISOCodeM
merge m:1 ISOCode1 ISOCode2 using "$cleveldta/1.WVSCultDist.dta" // WVS data
drop if _merge ==2
drop _merge
replace CulturalDistance  = 0 if  ISOCode1==  ISOCode2

/*merge m:1 ISOCode1 ISOCode2 using "$cleveldta/1.GeneDist.dta" // newgendist
drop if _merge ==2
drop _merge
replace GeneticDistance = 0 if ISOCode1== ISOCode2 
replace GeneticDistance1500 = 0 if ISOCode1== ISOCode2 
replace GeneticDistancePlural = 0 if ISOCode1== ISOCode2 

merge m:1 ISOCode1 ISOCode2 using "$cleveldta/1.CultDist.dta" // cultdist
drop if _merge ==2
drop _merge

replace ReligionDistance = 0 if  ISOCode1== ISOCode2 
replace LinguisticDistance = 0 if  ISOCode1== ISOCode2 

merge m:1 HomeCountryISOCode using "$cleveldta/1.Kinship.dta" // Enke data
drop if _merge ==2
drop _merge
rename KinshipScore KinshipScoreHome 
order KinshipScoreHome  HomeCountryISOCode, a(HomeCountry)

compress

merge m:1 HomeCountryISOCodeM using "$cleveldta/1.Kinship.dta" // Enke data
drop if _merge ==2
drop _merge
rename KinshipScore KinshipScoreHomeM 

order KinshipScoreHomeM HomeCountryISOCodeM, a(HomeCountryM)
* Kinship score differences 
gen KinshipDistance = abs(KinshipScoreHome - KinshipScoreHomeM) // Euclidean distance

*/
drop ISOCode1 ISOCode2

********************************************************************************
  * Generating CONTROL vars
********************************************************************************
  
* Diff nationality
gen OutGroup = 0
replace OutGroup = 1 if HomeCountryISOCode !=  HomeCountryISOCodeM
replace OutGroup = . if ( HomeCountryISOCode == "" |  HomeCountryISOCodeM=="")
label var OutGroup "=1 if employee has different HomeCountry of manager"

gen SameNationality = 1-OutGroup 
label var SameNationality "=1 if employee has same HomeCountry of manager"

* IA
bys IDlse IDlseMHR: egen maxIAM = max(IAM)
gen OutGroupIASame = . 
replace OutGroupIASame  =1 if OutGroup ==1 & maxIAM==1 & DiffCountry==0
replace OutGroupIASame  =0 if (OutGroup ==0 | maxIAM==0 | DiffCountry==1)
label var OutGroupIASame  "=1 if outgroup manager on IA, same location"

* Same gender
gen SameGender = 0
replace SameGender = 1 if Female == FemaleM
replace SameGender = . if (Female== . | FemaleM == .)
label var SameGender "=1 if employee has same gender as manager"

* Same age
gen SameAge=0
replace SameAge = 1 if AgeBand == AgeBandM 
replace SameAge= . if (AgeBand ==. | AgeBandM ==.)
label var SameAge "=1 if employee has same ageband of manager"

* Same PW
gen BothPW=0
replace BothPW = 1 if (DidPWPost ==1 &  DidPWPostM ==1)
replace BothPW= . if (DidPWPost ==. | DidPWPostM ==.)
label var BothPW "=1 if employee & manager have done PW"

* Average cultural distance & performance in the team
bysort IDlseMHR YearMonth: egen TeamCDistanceT = total(CulturalDistance)
bysort IDlseMHR YearMonth: egen TeamPRT = total(PR)
bysort IDlseMHR YearMonth: gen TeamSizeT = _N
order TeamSizeT, a(IDlseMHR)
gen TeamSize  = TeamSizeT 
replace TeamSize =. if IDlseMHR==.
gen TeamPR = (TeamPRT - PR)/(TeamSize-1)
gen TeamCDistance = (TeamCDistanceT - CulturalDistance)/(TeamSize-1)
label var TeamSize "Team Size"
label var TeamPR  "Team average perf score minus employee"
label var TeamCDistance  "Team average cultural distance minus employee"

* Team diversity/ethnic fractionalization
local i = 1
local Labels Nat Office Gender Age Country
foreach var in HomeCountry OfficeCode Female AgeBand Country {
	local Label: word `i' of `Labels'
bysort IDlseMHR YearMonth `var': gen Team`Label'No = _N
bysort IDlseMHR YearMonth `var': gen First`Label'No = 1 if  _n == 1
bysort IDlseMHR YearMonth: gen Team`Label'Sq = (Team`Label'No/TeamSize)^2 if First`Label'No==1
bysort IDlseMHR YearMonth: egen TeamHHI`Label' = sum(Team`Label'Sq)
bysort IDlseMHR YearMonth: gen TeamFrac`Label' = (1 - TeamHHI`Label')
drop Team`Label'No First`Label'No Team`Label'Sq

label var TeamHHI`Label' "Herfindahl Index (0,1] of `var' in team; 1 is max homophily"
label var TeamFrac`Label' "Frac Index [0,1): 1-HHI`Label'; 0 when all have same `var'; 1 is max diversity"
loc i = `i' + 1
}

order  TeamHHI* TeamFrac*, a(TeamSize)

* Number of months spent with same manager 
by IDlse IDlseMHR, sort: gen JointTenure = _n if IDlseMHR!=.

********************************************************************************
* Diff Language Indicator 
********************************************************************************

merge m:1 HomeCountryISOCode using  "$cleveldta/6.Languages.dta" , keepusing(Language SpeakAra SpeakDut SpeakEng SpeakFre SpeakGer SpeakGre SpeakChi SpeakPor SpeakRus SpeakSpa) 
drop if _merge ==2 
drop _merge 

merge m:1 HomeCountryISOCodeM using "$cleveldta/6.Languages.dta" , keepusing(LanguageM SpeakAraM SpeakDutM SpeakEngM SpeakFreM SpeakGerM SpeakGreM SpeakChiM SpeakPorM SpeakRusM SpeakSpaM) 
drop if _merge ==2 
drop _merge 

gen DiffLanguage = 1
replace DiffLanguage = 0 if (SpeakEng ==1 &  SpeakEngM ==1) | (SpeakFre ==1 &  SpeakFreM ==1) | ///
(SpeakPor ==1 &  SpeakPorM ==1) | (SpeakSpa ==1 &  SpeakSpaM ==1) | (SpeakRus ==1 &  SpeakRusM ==1) | ///
(SpeakAra ==1 &  SpeakAraM ==1) | (SpeakDut ==1 &  SpeakDutM ==1) | (SpeakGer ==1 &  SpeakGerM ==1) | (SpeakGre ==1 &  SpeakGreM ==1) | (SpeakChi ==1 &  SpeakChiM ==1)
replace DiffLanguage = 0 if  HomeCountryS== HomeCountrySM
replace DiffLanguage = . if HomeCountry==. | HomeCountryM==.
label var DiffLanguage "Employee and manager speak different language"
gen SameLanguage = 1 - DiffLanguage
label var DiffLanguage "Employee and manager speak same language"

********************************************************************************
* EVENT STUDY DUMMIES 
********************************************************************************

* Event Change manager
gsort IDlse YearMonth 
gen ChangeM = 0 
replace ChangeM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1]   )
bys IDlse: egen mm = min(YearMonth)
replace ChangeM = 0  if YearMonth ==mm & ChangeM==1
drop mm 

* Spell with manager
by IDlse (YearMonth) , sort : gen Spell = sum(ChangeM)
replace Spell = Spell + 1 
label var Spell "Employee spell w. Manager"
replace ChangeM = . if IDlseMHR ==. 

sort IDlse YearMonth
bys IDlse Spell : egen SpellStart = min(YearMonth)
label var SpellStart  "Start month of employee spell w. Manager"
format SpellStart %tm
bys IDlse Spell : egen SpellEnd = max(YearMonth)
label var SpellEnd  "End month of employee spell w. Manager"
format SpellEnd %tm

* NUMBER OF TEAM TRANSFERS
bys IDlse (YearMonth), sort: gen ChangeMC = sum(ChangeM)
lab var ChangeMC "Transfer (team)"

* Event IA 
gsort IDlse YearMonth 
gen OutGroupIASameM = 0 
replace OutGroupIASameM   = 1 if (IDlse[_n] == IDlse[_n-1] & OutGroupIASame[_n] ==1 & OutGroupIASame[_n-1] ==0  )
replace OutGroupIASameM  = . if IDlseMHR ==.

* Event Outgroup
gsort IDlse YearMonth 
gen OutGroupM = 0 
replace OutGroupM   = 1 if (IDlse[_n] == IDlse[_n-1] & OutGroup[_n] ==1 & OutGroup[_n-1] ==0  )
replace OutGroupM  = . if IDlseMHR ==.  

* IA Cultural distance 
gen OutGroupIASameMHighD = OutGroupIASameM
su CulturalDistance if CulturalDistance!=0,d 
replace OutGroupIASameMHighD = 0 if CulturalDistance <= r(p50)

gen OutGroupIASameMLowD = OutGroupIASameM
su CulturalDistance if CulturalDistance!=0, d 
replace OutGroupIASameMLowD = 0 if CulturalDistance > r(p50) &  CulturalDistance!=.

* indicator for high distance IA event 
gen CultureDEvent = OutGroupIASameM
su CulturalDistance if CulturalDistance!=0 &OutGroupIASameM==1,d 
replace CultureDEvent = 2 if CulturalDistance > r(p50) & CulturalDistance!=. &OutGroupIASameM==1
bys IDlse: egen z = max(CultureDEvent)
replace CultureDEvent = z 
drop z 

* PW
gen ChangeMPW = ChangeM
replace ChangeMPW = 0 if BothPW==0

gen ChangeMNoPW = ChangeM
replace ChangeMNoPW = 0 if BothPW==1

* IA PW
gen OutGroupIASameMPW = OutGroupIASameM
replace OutGroupIASameMPW = 0 if BothPW==0

gen OutGroupIASameMNoPW = OutGroupIASameM
replace OutGroupIASameMNoPW = 0 if BothPW==1

********************************************************************************
  * Promotions & transfers under same manager 
********************************************************************************

* this is to account for the lags in reporting manager/position changes 
foreach v in ChangeSalaryGrade PromWL TransferInternalSJ TransferInternal TransferSJ{
gen `v'SameM = `v'
replace `v'SameM = 0 if ChangeM==1 // only count job changes without manager changes 
*replace `v'SameM = 0 if f.ChangeM==1 // NOTE: for now just keeping it simple and avoiding leads and lags 
*replace `v'SameM = 0 if f2.ChangeM==1 
*replace `v'SameM = 0 if f3.ChangeM==1 
*replace `v'SameM = 0 if l.ChangeM==1 
*replace `v'SameM = 0 if l2.ChangeM==1 
*replace `v'SameM = 0 if l3.ChangeM==1 
gen `v'DiffM = `v'
replace `v'DiffM = 0 if `v'SameM==1 // only count job changes with manager changes
}

label var ChangeSalaryGradeSameM "ChangeSalaryGrade without manager change"
label var PromWLSameM "PromWL without manager change"
label var TransferInternalSJSameM "TransferInternalSJ without manager change"
label var TransferSJSameM "TransferSJ without manager change"
label var TransferInternalSameM "TransferInternal without manager change"

label var ChangeSalaryGradeDiffM "ChangeSalaryGrade with manager change"
label var PromWLDiffM "PromWL with manager change"
label var TransferInternalSJDiffM "TransferInternalSJ with manager change"
label var TransferSJDiffM "TransferSJ with manager change"
label var TransferInternalDiffM "TransferInternal with manager change"

foreach var in TransferSJ TransferSJSameM TransferSJDiffM TransferInternal TransferInternalSameM TransferInternalDiffM TransferInternalSJ TransferInternalSJSameM TransferInternalSJDiffM {
	
gen `var'LL =`var'
replace `var'LL = 0 if ChangeSalaryGrade==1	| PromWL==1

gen `var'V =`var'
replace `var'V = 0 if ChangeSalaryGrade==0	

gen `var'VV =`var'
replace `var'VV= 0 if PromWL==0

bys  IDlse (YearMonth) : gen `var'LLC= sum(`var'LL)
bys  IDlse (YearMonth) : gen `var'VVC= sum(`var'VV)
bys  IDlse (YearMonth) : gen `var'VC= sum(`var'V)
} 

* Vertical promotion
foreach var in PromWL ChangeSalaryGrade {
	gen `var'V = `var'
	replace `var'V = 0 if TransferInternal==1
	bys  IDlse (YearMonth) : gen `var'VC= sum(`var'V)

}
* create cumulative measures 
foreach v in ChangeSalaryGradeSameM ChangeSalaryGradeDiffM{
gen z = `v'
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SalaryGrade!=. 
gen `v'C = z 
drop z 
}
label var  ChangeSalaryGradeSameMC "CUMSUM from dummy=1 in the month when salary grade is diff. than in the preceding without manager change"
label var  ChangeSalaryGradeDiffMC "CUMSUM from dummy=1 in the month when salary grade is diff. than in the preceding with manager change"
 
foreach v in PromWLSameM PromWLDiffM{
gen z = `v'
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & WL!=. 
gen `v'C = z 
drop z 
} 
label var  PromWLSameMC "CUMSUM from dummy=1 in the month when WL is diff. than in the preceding without manager change"
label var  PromWLDiffMC "CUMSUM from dummy=1 in the month when WL is diff. than in the preceding with manager change"

foreach v in TransferInternalSJSameM TransferInternalSJDiffM{
gen z = `v'
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & StandardJob!="" & OfficeCode!=.  & Org4!=. 
gen `v'C = z 
drop z 
} 
label var  TransferInternalSJSameMC "CUMSUM from dummy=1 in the month when standard job is diff. than in the preceding without manager change"
label var  TransferInternalSJDiffMC "CUMSUM from dummy=1 in the month when standard job is diff. than in the preceding with manager change"

foreach v in TransferSJSameM TransferSJDiffM{
gen z = `v'
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & StandardJob!=""  
gen `v'C = z 
drop z 
} 
label var  TransferSJSameMC "CUMSUM from dummy=1 in the month when standard job is diff. than in the preceding without manager change"
label var  TransferSJDiffMC "CUMSUM from dummy=1 in the month when standard job is diff. than in the preceding with manager change"

foreach v in TransferInternalSameM TransferInternalDiffM{
gen z = `v'
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==.  & SubFunc!=. & OfficeCode!=.  & Org4!=.  
gen `v'C = z 
drop z 
} 
label var  TransferInternalSameMC "CUMSUM from dummy=1 in the month when either subfunc or Office or org4 is diff. than in the preceding without manager change"
label var  TransferInternalDiffMC "CUMSUM from dummy=1 in the month when either subfunc or Office or org4 is diff. than in the preceding with manager change"

* Cohort - year of hire
bys IDlse: egen YearHire = min(Year)
bys IDlse: egen TenureMin = min(Tenure)
replace YearHire = 9999 if YearHire == 2011 & TenureMin >=1 // censoring 

* New hire dummy 
gen NewHire =  YearHire==Year 
gen TenureBelow1 = Tenure<1 
gen TenureBelowEq1 = Tenure<=1 

********************************************************************************
  * Adding info on jobs 
********************************************************************************

decode SubFunc, gen(SubFuncS) // merge strings to avoid label conflicts 
decode Func, gen(FuncS) // merge strings to avoid label conflicts 

xtset IDlse YearMonth 
encode StandardJob, gen(StandardJobE)
gen StandardJobEBefore = l.StandardJobE
label value StandardJobEBefore StandardJobE
decode StandardJobEBefore , gen(StandardJobBefore)

gen StandardJobCodeBefore = l.StandardJobCode

gen SubFuncBefore = l.SubFunc
label value SubFuncBefore SubFunc
decode SubFuncBefore, gen(SubFuncSBefore)

gen FuncBefore = l.Func
label value FuncBefore Func
decode FuncBefore, gen(FuncSBefore)

* get ONET codes 
merge m:1 FuncS SubFuncS StandardJob  StandardJobCode  using  "$fulldta/SJ Crosswalk.dta", keepusing(ONETCode ONETName)
drop if _merge ==2
drop _merge 

merge m:1 FuncSBefore SubFuncSBefore StandardJobBefore  StandardJobCodeBefore  using  "$fulldta/SJ Crosswalk.dta", keepusing(ONETCodeBefore ONETNameBefore)
drop if _merge ==2
drop _merge 

* ONET Activities Distance 
merge m:1 ONETCode ONETCodeBefore using  "$ONET/Distance.dta" , keepusing(ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance)
drop if _merge ==2
drop _merge  

foreach var in ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance{
replace `var' = 0 if (ONETCode == ONETCodeBefore & ONETCodeBefore!="" & ONETCode!="")
replace `var' = 0 if TransferSJC==0 
gen z =  `var'
by IDlse (YearMonth), sort: replace z =  z[_n-1] if _n>1 & StandardJob[_n] == StandardJob[_n-1]
replace z = 0 if z ==. & ONETCode == ONETCodeBefore  & ONETCodeBefore!="" & ONETCode!=""
gen `var'C = z 
replace `var'C = 0 if TransferSJC==0

drop z 
}

* Activities ONET
egen ONETDistance = rowmean(ONETContextDistance ONETActivitiesDistance ONETAbilitiesDistance ONETSkillsDistance) 
egen ONETDistanceC = rowmean(ONETContextDistanceC ONETActivitiesDistanceC ONETAbilitiesDistanceC ONETSkillsDistanceC) 

foreach var in  ONETDistance ONETContextDistance ONETActivitiesDistance ONETAbilitiesDistance ONETSkillsDistance {
gen `var'B = `var'>0 if `var'!=. 
gen `var'B1 = `var'>0 if `var'!=. 
replace `var'B1 = 0 if `var'==. 

bys IDlse (YearMonth), sort: gen `var'BC = sum(`var'B)
}

/*gen z = ONETActDistance 
by IDlse StandardJob (YearMonth), sort: replace z =  z[_n-1] if _n>1 & z[_n-1]!=.
replace z = 0 if z ==. & SubFunc!=. & OfficeCode!=.  & Org4!=.
gen  ONETActDistanceC = z 
drop z 

br IDlse YearMonth ONETActDistance ONETName   StandardJob* z
*/

////////////////////////////////////////////////////////////////////////////////
* EDUCATION 
////////////////////////////////////////////////////////////////////////////////

* education field most prevalent in the job 
merge m:1 FuncS SubFuncS StandardJob StandardJobCode using "$fulldta/EducationMainField.dta", keepusing( MajorField MajorFieldShare)
drop if _merge ==2 
drop _merge 

merge m:1 IDlse using "$fulldta/EducationMax.dta", keepusing(QualHigh   FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge

* outcome for regressions: indicator if worker studied in different field compared to most prevalent in the job 
gen DiffField = (FieldHigh1 != MajorField & FieldHigh2!= MajorField &  FieldHigh3!= MajorField) if (MajorField!=. & FieldHigh1!=. )

********************************************************************************
  * Saving Analysis data
********************************************************************************

compress
save "$managersdta/AllSnapshotMCulture.dta", replace


/* code to temporarily add manager characteristics 

use "$managersdta/AllSnapshotMCulture.dta", clear 
keep IDlse YearMonth PLeave LeaveTypeClean
rename IDlse IDlseMHR 
rename (PLeave LeaveTypeClean) (=M)
save "$managersdta/Temp/mVars.dta", replace 

