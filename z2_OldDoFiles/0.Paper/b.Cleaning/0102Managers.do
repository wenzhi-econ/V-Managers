/* 
Description of this do file:
    This do file generates new variables about the employee's manager.
    The variables include:
        if the employee is a manager in a given year-month
        the characteristics of the employee's manager in a given year-month 
        size (# of employees) in each country-moth cell 
        size (# of offices) in each country-moth cell 
        indicators
        flags
        a dummy indicating manager changes
        how many managers an employee has experienced, and the start and end time?
        how many times an employee has changed his manager?
        promotions & transfers with and without manager changes 

This is copied from "1.Cleaning/1.1.CleanData.do" and "1.Cleaning/1.3.CleanCulture".
Major changes of this file:
    I combined the two files to make this do file more about generating variables for employees' managers.
    I changed paths which contain raw datasets.
    To facilitate understanding of this do file, I added several comments.
    I slightly changed the order of several code blocks to make it easier to understand.
    I deleted some unnecessary that were originally commented out.
    I commented out the PW block, as it seems more relevant to another project. 

Input files:
    "${managersMNEdata}/ManagerIDReports.dta" (considered as raw data)
    "${managersMNEdata}/AllSnapshotWC_NewVars.dta" (output of "0101NewVars.do")

Temp files:
    "${tempdata}/Mlist.dta"
    "${tempdata}/MListChar.dta"

Output files:
    "${managersdta}/AllSnapshotWC_NewVars_Mngr.dta"

RA: WWZ 
Time: 18/3/2024
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s1: identifying managers in the original dataset & adding manager IDlse
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-- step 1-1 creating Mlist

* using ManagerIDReports to create tempfile Mlist, which has IDlse of all
* employees who also happen to be a manager in given month.

use "${managersMNEdata}/ManagerIDReports.dta", clear

keep IDlseMHR YearMonth
rename IDlseMHR IDlse

duplicates drop IDlse YearMonth, force

*-- step 1-2 I identify managers in AllSnapshot.dta using the tempfile

drop if IDlse == . // 60 missing values, which is due to the missing values in IDlseMHR

save "${tempdata}/Mlist.dta", replace


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s2: identify managers in the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${managersdta}/AllSnapshotWC_NewVars.dta", clear 

* merge with the dataset generated in s1 which contains manager id 
merge 1:1 IDlse YearMonth using "${tempdata}/Mlist.dta"
drop if _merge == 2 // 12,956 unmatched obs. from ManagerIDReports.dta.

* the matched individuals are managers. I tag them generating a dummy Manager.
gen Manager = 0
replace Manager = 1 if _merge == 3
label var Manager "=1 if employee also appears as a manager in the same monthly snapshot
drop _merge

* save the resulting dataset  
compress
save "${managersdta}/AllSnapshotM.dta",replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s3: manager characteristics (manager-year-month level variables)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s3-1: store manager characteristics in a temp data file 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
    use "$managersdta/AllSnapshotM.dta", clear
}

*Dropping non-manager employees and unnecessary variables
keep if Manager ==1

* adding some leads and lags in manager transfers variables to account to differences in reporting times 
xtset IDlse YearMonth 
foreach var in TransferInternal TransferSubFunc TransferSJ{
    forval i=1(1)3{
        gen `var'L`i' = l`i'.`var'
        gen `var'F`i' = f`i'.`var'
    }
} 
gen PayBonusGrowthAnnual = LogPayBonus - l12.LogPayBonus

* MANAGERS CHARS 
global Mvariables EarlyAge EarlyAgeTenure EarlyTenure MaxWL MinWL AgeMinMaxWL HomeCountry HomeCountryISOCode Country CountryS Office OfficeCode ISOCode Cluster Market PositionTitle StandardJob StandardJobCode Func SubFunc Female WL AgeBand Tenure EmpType MasterType LeaverType LeaverInv LeaverVol LeaverPerm LeaverTemp SalaryGrade LogPayBonus Pay Benefit Bonus PR PRI PRSnapshot VPA PayIn  TransferCountry TransferCountryC PromWL PromWLC  TransferPTitle TransferPTitleC TransferSubFunc TransferSubFuncL1 TransferSubFuncL2 TransferSubFuncL3 TransferSubFuncF1 TransferSubFuncF2 TransferSubFuncF3  TransferSubFuncC TransferFunc TransferFuncC TransferInternal TransferInternalL1 TransferInternalL2 TransferInternalL3 TransferInternalF1 TransferInternalF2 TransferInternalF3  TransferInternalC MonthsSJ MonthsSubFunc MonthsWL MonthsSG MonthsSGCum   ChangeSalaryGrade ChangeSalaryGradeC YearstoChangeSG TransferSJ TransferSJL1 TransferSJL2 TransferSJL3 TransferSJF1 TransferSJF2 TransferSJF3 TransferSJC PayBonusGrowthAnnual TransferOrg5 TransferOrg5C ChangeOffice ChangeOfficeC PLeave LeaveType // DidPWPost

keep IDlse YearMonth Year $Mvariables

*Renaming variables
rename IDlse IDlseMHR
foreach var in $Mvariables  {
    rename `var' `var'M
}

* Compressing and saving MListChar
compress
save "${tempdata}/MListChar.dta", replace

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s3-2: merge manager characteristics with the master dataset 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
    use "$managersdta/AllSnapshotM.dta", clear
}
merge m:1 IDlseMHR YearMonth using "${tempdata}/MListChar.dta"
drop if _merge ==2 
drop _merge
compress
save "$managersdta/AllSnapshotM.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s4: generate additional variables & modify some variables
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s4-1: size (# of employees) in each country-moth cell  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

* Country Size
bysort YearMonth Country: egen CountrySize = count(IDlse) // no. of employees by country and month
label var CountrySize "No. of employees in each country and month"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s4-2: size (# of offices) in each country-moth cell  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

* Office
distinct Office 
distinct Country 
quietly bys Office: gen dup_location = cond(_N==1,0,_n)
bys Country YearMonth: egen OfficeNum = count(Office) if (dup_location ==0 & Office !=. | dup_location ==1 & Office !=.)
drop dup_location 
label var OfficeNum "No. of offices in each Country and Month"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s4-3: indicators
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

* Additional variables useful for the analysis
egen CountryYM = group(Country YearMonth)
egen IDlseMHRYM = group(IDlseMHR YearMonth)
decode HomeCountryM, gen(HomeCountrySM)
order HomeCountrySM, after(HomeCountryM)

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s4-4: flags 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
* first year-month 
bys IDlse (YearMonth), sort: gen FirstYM = YearMonth == YearMonth[1]
label var FirstYM "=1 if first YM for employee"

* IAManager
gen IAM = 1 if MasterTypeM ==1 | MasterTypeM ==4
replace IAM =0 if IAM ==. & IDlseMHR!=.
label var IAM "=1 if IDlse's manager is on IA"

* FlagManager
bys IDlse: egen FlagManager= max(Manager)
label var FlagManager "=1 if IDlse ever was a manager"

* FlagIA
gen IA = 1 if MasterType ==1 | MasterType ==4
replace IA =0 if IA==.
by IDlse: egen FlagIA= max(IA)
label var FlagIA "=1 if IDlse ever did an IA"

* FlagIAManager
bys IDlse: egen FlagIAM= max(  IAM )
label var FlagIAM "=1 if IDlse ever had an IA manager"

* FlagUFLP 
by IDlse: egen FlagUFLP= max(UFLPStatus)
label var FlagUFLP "=1 if IDlse ever was UFLP"

* Manager round  
by IDlse (YearMonth), sort: gen ManagerRound = (IDlseMHR != IDlseMHR[_n-1] & _n > 1)
by IDlse (YearMonth), sort: gen ManagerRoundcum = sum(ManagerRound)
replace ManagerRound =  ManagerRoundcum +1
drop ManagerRoundcum
label var ManagerRound "How many managers employee changes"

* RoundIA for Employee
by IDlse (YearMonth), sort: gen Count = _n
by IDlse (YearMonth), sort: gen RoundIAM = (IDlseMHR != IDlseMHR[_n-1] & _n > 1  &  IAM   ==1)
replace RoundIAM = 1 if IAM==1 & FirstYM==1
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIAM)
replace RoundIAM =  RoundIAcum 
drop RoundIAcum Count

by IDlse: egen RoundIAMMax = max(RoundIAM)
label var RoundIAM "Number of time the employee has had a manager on IA"

* Compressing and saving in AllSnapshotM.dta.
compress
save "$managersdta/AllSnapshotM.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s5: dummies for the event study design 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "$managersdta/AllSnapshotM.dta", clear 

replace WL =1 if WL == 0 
replace WLM =1 if WLM == 0 

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s5-1: manager changes  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

* Event Change manager
gsort IDlse YearMonth 
gen ChangeM = 0 
replace ChangeM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1]   )
bys IDlse: egen mm = min(YearMonth)
replace ChangeM = 0  if YearMonth ==mm & ChangeM==1
drop mm 

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s5-2: how many managers an employee has experienced, 
*--       and the start and end time?
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

* Spell with manager
sort IDlse YearMonth
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

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s5-3: how many times an employee has changed his manager?
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

* NUMBER OF TEAM TRANSFERS
bys IDlse (YearMonth), sort: gen ChangeMC = sum(ChangeM)
lab var ChangeMC "Transfer (team)"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s6: promotions & transfers with and without manager changes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s6-1: does job changes (lateral or verticle) coincide with manager changes?
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

* this is to account for the lags in reporting manager/position changes 
foreach v in ChangeSalaryGrade PromWL TransferInternalSJ TransferInternal TransferSJ {
    gen `v'SameM = `v'
    replace `v'SameM = 0 if ChangeM==1 // only count job changes without manager changes 
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

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s6-2: distinguish betweeen lateral and vertical moves 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

*!! s6-2-1: lateral moves 
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

*!! s6-2-2: vertical promotion 
foreach var in PromWL ChangeSalaryGrade {
	gen `var'V = `var'
	replace `var'V = 0 if TransferInternal==1
	bys  IDlse (YearMonth) : gen `var'VC= sum(`var'V)

}

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s6-3: create cumulative measures for job changes (lateral and vertical)
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

foreach v in ChangeSalaryGradeSameM ChangeSalaryGradeDiffM {
    gen z = `v'
    by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
    replace z = 0 if z ==. & SalaryGrade!=. 
    gen `v'C = z 
    drop z 
}
label var  ChangeSalaryGradeSameMC "CUMSUM from dummy=1 in the month when salary grade is diff. than in the preceding without manager change"
label var  ChangeSalaryGradeDiffMC "CUMSUM from dummy=1 in the month when salary grade is diff. than in the preceding with manager change"

foreach v in PromWLSameM PromWLDiffM {
    gen z = `v'
    by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
    replace z = 0 if z ==. & WL!=. 
    gen `v'C = z 
    drop z 
} 
label var  PromWLSameMC "CUMSUM from dummy=1 in the month when WL is diff. than in the preceding without manager change"
label var  PromWLDiffMC "CUMSUM from dummy=1 in the month when WL is diff. than in the preceding with manager change"

foreach v in TransferInternalSJSameM TransferInternalSJDiffM {
    gen z = `v'
    by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
    replace z = 0 if z ==. & StandardJob!="" & OfficeCode!=.  & Org4!=. 
    gen `v'C = z 
    drop z 
} 
label var  TransferInternalSJSameMC "CUMSUM from dummy=1 in the month when standard job is diff. than in the preceding without manager change"
label var  TransferInternalSJDiffMC "CUMSUM from dummy=1 in the month when standard job is diff. than in the preceding with manager change"

foreach v in TransferSJSameM TransferSJDiffM {
    gen z = `v'
    by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
    replace z = 0 if z ==. & StandardJob!=""  
    gen `v'C = z 
    drop z 
} 
label var  TransferSJSameMC "CUMSUM from dummy=1 in the month when standard job is diff. than in the preceding without manager change"
label var  TransferSJDiffMC "CUMSUM from dummy=1 in the month when standard job is diff. than in the preceding with manager change"

foreach v in TransferInternalSameM TransferInternalDiffM {
    gen z = `v'
    by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
    replace z = 0 if z ==.  & SubFunc!=. & OfficeCode!=.  & Org4!=.  
    gen `v'C = z 
    drop z 
} 
label var  TransferInternalSameMC "CUMSUM from dummy=1 in the month when either subfunc or Office or org4 is diff. than in the preceding without manager change"
label var  TransferInternalDiffMC "CUMSUM from dummy=1 in the month when either subfunc or Office or org4 is diff. than in the preceding with manager change"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s7: save the dataset  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

compress 
save "${managersdta}/AllSnapshotWC_NewVars_Mngr.dta", replace

/* * IA dataset
keep if FlagIA ==1 
compress
save "$managersdta/IAManager.dta", replace

* UFLP dataset 
use "$managersdta/AllSnapshotM.dta" 
keep if FlagUFLP==1 
compress 
save "$managersdta/GraduatesRaw.dta", replace  */

