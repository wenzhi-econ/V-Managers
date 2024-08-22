* Manager skills 
* platform to list skills, certified by supervisor - snapshot 2019m9

* [can also look at workers and whether they have high flier manager in the 2 years before: 2017m9 2019m9? but not priority for now] 

********************************************************************************
* CLEANING & SETUP 
********************************************************************************

* Data on skills: export data to excel 
use "$fulldta/Skills2019M9.dta", clear  
encode Skills , gen(SkillsE)
gen SkillsCode = SkillsE +0
drop SkillsE
save  "$managersdta/TempNew/SkillsInput.dta", replace  
keep Skills SkillsCode
duplicates drop SkillsCode , force 
isid SkillsCode 
export excel "$managersdta/TempNew/SkillsInput.xlsx" , replace firstrow(variables)


* data for number of skills only (COLLAPSED dataset)
use "$fulldta/Skills2019M9collapse.dta", clear  

* import excel with added topics by chatgpt
********************************************************************************

import excel "$managersdta/TempNew/UpdatedSkillsInput.xlsx", sheet("Sheet1") firstrow clear
isid SkillsCode
encode Topic, gen(TopicE)
ta Topic
local n 5 // number of topics identified !MANUAL INPUT REQUIRED!
save "$managersdta/TempNew/UpdatedSkillsWithTopics.dta", replace 


* Number & type of skills
********************************************************************************
 
use "$managersdta/Temp/MType.dta", clear 
gen IDlse = IDlseMHR
keep if WLM==2
drop if EarlyAgeM == . 
drop if IDlse==. 

bys IDlseMHR: egen mYM = max(YearMonth) // take latest month 
keep if YearMonth == mYM  

* merge number of skills 
merge 1:1 IDlse using "$fulldta/Skills2019M9collapse.dta"
gen SkillB = _merge ==3 
drop _merge 

* merge type of skills 
merge 1:m IDlse using "$managersdta/TempNew/SkillsInput.dta" 
gen SkillTypeB = _merge ==3 
drop _merge 
merge m:1 SkillsCode  using "$managersdta/TempNew/UpdatedSkillsWithTopics.dta"

* Create binary indicator 
forval i=1/`n' {
	gen Topic`i' = TopicE==`i'
}

********************************************************************************
* ANALYSIS
********************************************************************************

collapse SkillB SkillTypeB  NumSkills CountryM  FuncM EarlyAgeM (sum) Topic1-Topic`n' , by(IDlse)

* 1) number of skills 

*tw kdensity   NumSkills  if    EarlyAgeM==0 || kdensity NumSkills  if    EarlyAgeM==1, bcolor(erose) xtitle("Number of skills") ytitle("") legend( label(1 "Low Flyer") label(2 "High Flyer"))

gen lskill = log( NumSkills)
reg NumSkills EarlyAgeM
reg lskill EarlyAgeM

foreach v in  NumSkills lskill SkillB SkillTypeB {
	reg `v' EarlyAgeM , robust

reghdfe `v' EarlyAgeM , a(CountryM  FuncM ) vce(robust) //  SkillB  lskill [FIRST 2 columns of table]
}


* 2) type of skills - IN PROGRESS AS TOPIC CATEGORIZATION NOT GREAT 
egen tot = rowtotal(Topic1-Topic`n')

forval i=1/`n' {
	gen Topic`i'S = Topic`i'/tot
	gen Topic`i'B = Topic`i'>0 if Topic`i'!=.
}


forval i=1/`n' {
reghdfe Topic`i'S EarlyAgeM , a(CountryM  FuncM ) vce(robust) // topic shares, 1 column for each topic 
*reg Topic`i' EarlyAgeM , vce(robust)
*reg Topic`i'B EarlyAgeM , vce(robust)
}

