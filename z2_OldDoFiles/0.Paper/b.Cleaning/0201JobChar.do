
/* 
Description of this do file:
    This do file generates new variables about the skill content of employees' jobs using the ONET dataset.
    The variables include:
        the skill content of a job based on ONET dataset, and the skill difference if the employee changes his job 
        the employee's education field versus the most prevalent in his job 


This is copied from "1.Cleaning/1.3.CleanCulture".
Major changes of this file:
    I changed paths which contain raw datasets.
    To facilitate understanding of this do file, I added several comments.
    I deleted some unnecessary that were originally commented out.

Input files:
    "${managersdta}/AllSnapshotWC_NewVars_Mngr.dta" (output of "0102Managers.do")
    "${managersMNEdata}/SJ Crosswalk.dta" (taken as raw data)
    "${managersONETdata}/Distance.dta" (taken as raw data)
    "${managersMNEdata}/EducationMainField.dta" (taken as raw data)
    "${managersMNEdata}/EducationMax.dta" (taken as raw data)

Output files:
    "${managersdta}/AllSnapshotWC_NewVars_Mngr_ONET.dta"

RA: WWZ 
Time: 18/3/2024
*/

use "${managersdta}/AllSnapshotWC_NewVars_Mngr.dta", clear 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s1: job characteristics based on ONET dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

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
merge m:1 FuncS SubFuncS StandardJob  StandardJobCode  using  "${managersMNEdata}/SJ Crosswalk.dta", keepusing(ONETCode ONETName)
drop if _merge ==2
drop _merge 

merge m:1 FuncSBefore SubFuncSBefore StandardJobBefore  StandardJobCodeBefore  using  "${managersMNEdata}/SJ Crosswalk.dta", keepusing(ONETCodeBefore ONETNameBefore)
drop if _merge ==2
drop _merge 

* ONET Activities Distance 
merge m:1 ONETCode ONETCodeBefore using  "${managersONETdata}/Distance.dta" , keepusing(ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance)
drop if _merge ==2
drop _merge  

foreach var in ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance {
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

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? s2: employees' education field versus most prevalent field in that job
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

* education field most prevalent in the job 
merge m:1 FuncS SubFuncS StandardJob StandardJobCode using "${managersMNEdata}/EducationMainField.dta", keepusing( MajorField MajorFieldShare)
drop if _merge ==2 
drop _merge 

merge m:1 IDlse using "${managersMNEdata}/EducationMax.dta", keepusing(QualHigh   FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge

* outcome for regressions: indicator if worker studied in different field compared to most prevalent in the job 
gen DiffField = (FieldHigh1 != MajorField & FieldHigh2!= MajorField &  FieldHigh3!= MajorField) if (MajorField!=. & FieldHigh1!=. )

save "${managersdta}/AllSnapshotWC_NewVars_Mngr_ONET.dta", replace 
