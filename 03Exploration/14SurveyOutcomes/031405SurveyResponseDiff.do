/* 
This do file creates a balance table for some variables between survey respondents and non-respondents.

RA: WWZ 
Time: 2025-03-04
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate variables to be compared 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge the educ dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

merge m:1 IDlse using "${RawMNEData}/EducationMax.dta", keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
    drop if _merge ==2 
    drop _merge

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate the fields of study 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.

generate Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.

generate Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.

generate Other = (Econ ==0 & Sci ==0 & Hum ==0  )  if FieldHigh1!=.

generate Missing = FieldHigh1 ==. 
label variable Missing "Missing Education"

generate Bachelor =       QualHigh >= 10 if QualHigh!=.
generate MBA =            QualHigh == 13 if QualHigh!=.
generate AboveSecondary = QualHigh >= 6  if QualHigh!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. other relevant variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! work-level
replace WL = 3 if WL>3
tab WL, gen(WL)

*!! age cohort
replace AgeBand = 1 if AgeBand==7 //&? Age Under 18
replace AgeBand = 4 if AgeBand>4 & AgeBand!=. //&? age 50+
tab AgeBand, gen(Cohort)

*!! year and month of the observation
capture drop Year 
capture drop Month
generate Year  = year(dofm(YearMonth))
generate Month = month(dofm(YearMonth))


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. check if the employee is a survey respondent
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

merge 1:1 IDlse YearMonth using "${RawMNEData}/Univoice.dta"
    drop if _merge ==2 
    rename _merge mergeS

keep if Month==9 
    //impt: keep only September observations, but an employee can have multiple observations across different years
    //&? September is the month of the survey

generate SurveyInd = 1 if mergeS==3
replace  SurveyInd = 0 if mergeS==1

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. create the balance table
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*!! the list of variables 
global vars_list Female Cohort1 Cohort2 Cohort3 Cohort4 Econ Sci Hum Other Tenure WL1 WL2 WL3 EarlyAgeM

*!! variable labels 
label variable Female    "Female"
label variable WL1       "Work-level 1" 
label variable WL2       "Work-level 2" 
label variable WL3       "Work-level 3+" 
label variable Cohort1   "Age 18-29"  
label variable Cohort2   "Age 30-39"
label variable Cohort3   "Age 40-49"
label variable Cohort4   "Age 50+"
label variable Econ      "Econ, Business, and Admin"
label variable Sci       "Sci, Engin, Math, and Stat"
label variable Hum       "Social Sciences and Humanities"
label variable Other     "Other Educ"
label variable Tenure    "Tenure (years)"
label variable EarlyAgeM "Have a high-flyer manager"

balancetable SurveyInd $vars_list using "${Results}/BTableSurveyAnswer.tex", ///
    replace pval cov(Office Year) vce(cluster IDlse) varlabels ///
    ctitles( "Non-respondents" "Survey respondents" "Difference") ///
    groups("{Mean / (SE)}" "{Difference in means / (p-value)}", pattern(1 0 1)) ///
    postfoot("\hline\hline \end{tabular} \begin{tablenotes} \footnotesize \item" "Notes. An observation is a worker-year (in September for which year when the survey is administrated). This table compares average characteristics of the non-respondents (Column 1) to the subset of employees who responded to the employee survey (Column 2). Control variables include office and year fixed effects. Standard errors are clustered at the worker level." "\end{tablenotes}}")

