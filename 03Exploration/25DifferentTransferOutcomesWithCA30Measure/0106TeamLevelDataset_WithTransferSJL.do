/* 
This do file constructs a team level dataset focusing on those workers who experienced a manager change event. 

impt: The team id is uniquely defined by a (IDlseMHRPreMost, IDlseMHRPost, FT_Event_Time) pair.
impt: Managers identified by IDlseMHRPreMost is not necessarily the same pre-event manager for each individual.
impt: Team-level treatment status is not necessarily identical to individual-level treatment status.

Input:
    "${TempData}/FinalAnalysisSample.dta"          <== created in 0103_03 do file 
    "${TempData}/0102_03HFMeasure.dta"             <== created in 0102_03 do file 
    "${TempData}/0104Mngr_Characteristics.dta"     <== created in 0104 do file 
    "${TempData}/0105SalesProdOutcomes.dta"        <== created in 0105 do file 

Output:
    "${TempData}/0106TeamLevelEventsAndOutcomes.dta"

Description of the Output Dataset:
    A panel of teams defined by the (IDlseMHRPreMost IDMngr_Post Event_Time) pair.
    It contains the following variables:
        (1) event-related variables that identify which event the team experienced; and
        (2) team-level outcome and control variables in two endogenous mobility checks tables.

RA: WWZ 
Time: 2025-04-21
*/

use "${TempData}/FinalAnalysisSample.dta", clear 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate team id 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. pre-event team id: (IDlseMHRPreMost, Event_Time) pair
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-1-1-1. pre-event manager id: non-missing only when Rel_Time==0
sort IDlse YearMonth
generate IDMngr_Pre_Missing = IDMngr_Pre if Rel_Time==0 

*!! s-1-1-2. post-event manager id: non-missing only when Rel_Time==0
generate IDMngr_Post_Missing = IDMngr_Post if Rel_Time==0 

*!! s-1-1-3. event time: non-missing only when when Rel_Time==0
generate Event_Time_Missing = Event_Time if Rel_Time==0
format Event_Time_Missing %tm

*!! s-1-1-4. manually assigned pre-event manager id: non-missing only when Rel_Time==0
*!! the mode across pre-event managers whose workers move to the same post-event manager in the same month
sort   IDMngr_Post_Missing Event_Time_Missing
bysort IDMngr_Post_Missing Event_Time_Missing: egen temp_IDMngr_Pre_Most = mode(IDMngr_Pre_Missing), minmode

/* 
Notes on the above procedures:
    (1) First, I make sure the three raw variables used to define pre-event team id have non-missing values only in the event month.
    (2) Then, for each (post-event manager, event time) pair, the mode is across a cross-section of event workers.
*/

*!! s-1-1-5. IDlseMHRPreMost: worker-level 
sort IDlse YearMonth
bysort IDlse: egen long IDlseMHRPreMost = mean(temp_IDMngr_Pre_Most)
drop temp_IDMngr_Pre_Most

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. post-event team id: (IDMngr_Post, Event_Time) pair
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
Notes: 
    (1) The post-event team id is always determined by employee's true post-event manager and his event time.
    (2) It is determined by two pre-existing variables: IDMngr_Post and Event_Time.
*/

*!! check: how many event workers are assigned to a different pre-event manager?
generate diff_IDMngr_Pre = (IDlseMHRPreMost!=IDMngr_Pre) 
tabulate diff_IDMngr_Pre if occurrence==1, missing
/* 
diff_IDMngr |
       _Pre |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     28,679       97.32       97.32
          1 |        791        2.68      100.00
------------+-----------------------------------
      Total |     29,470      100.00
*/
    //&? only around 3% of event workers are assigned to a different pre-event manager
    //&? not a big case, but it could potentially affect the event worker's event group classification, which will be accounted for later 
    //&? the manually assigned event group classification should be different from the true event group in less than 2.68% of event workers.

order Year YearMonth occurrence IDlse IDlseMHR Rel_Time Event_Time IDMngr_Pre IDlseMHRPreMost IDMngr_Post
drop  IDMngr_Pre_Missing IDMngr_Post_Missing Event_Time_Missing diff_IDMngr_Pre
label variable IDlseMHRPreMost "Manually assigned pre-event manager ID"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. team id: (IDlseMHRPreMost, IDMngr_Post, Event_Time) pair
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! team id
*&? All three variables (IDlseMHRPreMost IDMngr_Post Event_Time) are at individual-level
capture drop IDteam
egen IDteam = group(IDlseMHRPreMost IDMngr_Post Event_Time)
order IDteam, before(IDlseMHRPreMost)
label variable IDteam "Team ID (defined by (IDlseMHRPreMost, IDMngr_Post, Event_Time) pair)"

sort IDteam IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. modify team-level treatment status 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
* impt: Our pre-event manager is manually assigned (according to the mode calculation).
* impt: Thus, team-level treatment status may not coincide with individual-level treatment status.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. rename original event-related variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

order  IDMngr_Pre, before(CA30_LtoL)
rename IDMngr_Pre      IDMngr_Pre_True
rename CA30_LtoL       CA30_LtoL_True
rename CA30_LtoH       CA30_LtoH_True
rename CA30_HtoH       CA30_HtoH_True
rename CA30_HtoL       CA30_HtoL_True
rename CA30Mngr_Pre    CA30Mngr_Pre_True
rename CA30Mngr_Post   CA30Mngr_Post_True

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. reconstruct event-related variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-2-1. obtain high-flyer measures
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

rename YearMonth YearMonth_Save
rename IDlseMHRPreMost IDMngr_Pre

rename Event_Time YearMonth
merge m:1 IDMngr_Post YearMonth using "${TempData}/0102_03HFMeasure.dta"
    drop if _merge==2
    drop _merge 
rename CA30 CA30_Post
rename YearMonth Event_Time

generate Event_Time_1monthbefore = Event_Time - 1
rename Event_Time_1monthbefore YearMonth
merge m:1 IDMngr_Pre YearMonth using "${TempData}/0102_03HFMeasure.dta"
    drop if _merge==2
    drop _merge 
rename CA30 CA30_Pre
rename YearMonth Event_Time_1monthbefore

rename YearMonth_Save YearMonth
rename IDMngr_Pre IDlseMHRPreMost

sort IDteam IDlse YearMonth
drop Event_Time_1monthbefore
order CA30_Pre CA30_Post, after(IDMngr_Post)
label variable CA30_Pre  "Pre-event manager (team-level) is a high-flyer"
label variable CA30_Post "Post-event manager (team-level) is a high-flyer"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-2-2. team-level treatment status identifies
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate CA30_LtoL = .
replace  CA30_LtoL = 1 if CA30_Pre==0 & CA30_Post==0
replace  CA30_LtoL = 0 if CA30_Pre==0 & CA30_Post==1
replace  CA30_LtoL = 0 if CA30_Pre==1 & CA30_Post==1
replace  CA30_LtoL = 0 if CA30_Pre==1 & CA30_Post==0

generate CA30_LtoH = .
replace  CA30_LtoH = 0 if CA30_Pre==0 & CA30_Post==0
replace  CA30_LtoH = 1 if CA30_Pre==0 & CA30_Post==1
replace  CA30_LtoH = 0 if CA30_Pre==1 & CA30_Post==1
replace  CA30_LtoH = 0 if CA30_Pre==1 & CA30_Post==0

generate CA30_HtoH = .
replace  CA30_HtoH = 0 if CA30_Pre==0 & CA30_Post==0
replace  CA30_HtoH = 0 if CA30_Pre==0 & CA30_Post==1
replace  CA30_HtoH = 1 if CA30_Pre==1 & CA30_Post==1
replace  CA30_HtoH = 0 if CA30_Pre==1 & CA30_Post==0

generate CA30_HtoL = .
replace  CA30_HtoL = 0 if CA30_Pre==0 & CA30_Post==0
replace  CA30_HtoL = 0 if CA30_Pre==0 & CA30_Post==1
replace  CA30_HtoL = 0 if CA30_Pre==1 & CA30_Post==1
replace  CA30_HtoL = 1 if CA30_Pre==1 & CA30_Post==0

order CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL, after(CA30_Post)
label variable CA30_LtoL "LtoL (team-level)"
label variable CA30_LtoH "LtoH (team-level)"
label variable CA30_HtoH "HtoH (team-level)"
label variable CA30_HtoL "HtoL (team-level)"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. create relevant team-level variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. create Herfindahl indices for diversity variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&? Recall that IDlseMHR here is the real manager id.
*&? In this way, there can be time variation in these team-level Herfindahl indices.

sort IDlseMHR YearMonth
bysort IDlseMHR YearMonth: generate TeamSize = _N

foreach var in Female AgeBand OfficeCode Country {

    bysort IDlseMHR YearMonth `var': generate Team`var'No  = _N
    bysort IDlseMHR YearMonth `var': generate First`var'No = 1                        if _n==1
    bysort IDlseMHR YearMonth      : generate Team`var'Sq  = (Team`var'No/TeamSize)^2 if First`var'No==1
    bysort IDlseMHR YearMonth      : egen     TeamHHI`var' = sum(Team`var'Sq)
    bysort IDlseMHR YearMonth      : generate TeamFrac`var'= (1 - TeamHHI`var')
    capture drop Team`var'No First`var'No Team`var'Sq

    label variable TeamHHI`var'  "Herfindahl Index (0,1] of `var' in team; 1 is max homophily"
    label variable TeamFrac`var' "Frac Index [0,1): 1-HHI`var'; 0 when all have same `var'; 1 is max diversity"
    local i = `i' + 1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. workers' homophily with managers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR YearMonth using "${TempData}/0104Mngr_Characteristics.dta" ///
    , keep(match master) nogenerate keepusing(FemaleM AgeBandM OfficeCodeM HomeCountryISOCodeM FuncM ISOCodeM)

capture drop SameGender
generate SameGender = 0
replace  SameGender = 1 if Female==FemaleM
/* replace  SameGender = . if (Female==. | FemaleM==.) */
label variable SameGender "=1 if employee has same gender as manager"

capture drop SameAge
generate SameAge = 0
replace  SameAge = 1 if AgeBand==AgeBandM 
replace  SameAge = . if (AgeBand==. | AgeBandM==.)
label variable SameAge "=1 if employee has same ageband of manager"

capture drop DiffOffice
capture drop SameOffice
generate DiffOffice = 0
replace  DiffOffice = 1 if OfficeCode!=OfficeCodeM
replace  DiffOffice = . if (OfficeCode==. | OfficeCodeM ==.)
generate SameOffice = 1 - DiffOffice 
label variable DiffOffice "=1 if manager in different office"
label variable SameOffice "=1 if manager in same office"

capture drop OutGroup
capture drop SameNationality
generate OutGroup = 0
replace  OutGroup = 1 if HomeCountryISOCode!=HomeCountryISOCodeM
/* replace  OutGroup = . if ( HomeCountryISOCode=="" | HomeCountryISOCodeM=="") */
generate SameNationality = 1 - OutGroup 
label variable OutGroup "=1 if employee has different HomeCountry of manager"
label variable SameNationality "=1 if employee has same HomeCountry of manager"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. decompose variable TransferSJ
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! lateral transfer under the same manager
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*!! lateral transfer under different managers 
generate TransferSJDiffM = TransferSJ
replace  TransferSJDiffM = 0 if TransferSJSameM==1 

capture drop TransferSJL 
capture drop TransferSJLC
foreach var in TransferSJ {
    generate `var'L =`var'
    replace  `var'L = 0 if PromWL==1

    sort IDlse YearMonth
    bysort IDlse (YearMonth): generate `var'LC  = sum(`var'L)
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. get productivity data 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. collapse into team-month level data
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. collapse 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate one = 1 

capture drop PayBonus
generate PayBonus = Pay + Bonus

collapse ///
    (mean) AvPay=PayBonus ShareChangeSalaryGrade=ChangeSalaryGrade SharePromWL=PromWL AvProductivityStd=ProductivityStd ///
    (mean) TeamFracFemale TeamFracAgeBand TeamFracOfficeCode TeamFracCountry ///
    (mean) ShareSameGender=SameGender ShareSameAge=SameAge ShareSameOffice=SameOffice ShareSameNationality=SameNationality ///
    (mean) ShareTransferSJ=TransferSJ ShareTransferFunc=TransferFunc ShareTransferSJL=TransferSJL ///
    (mean) IDlseMHRPreMost IDMngr_Post Event_Time Rel_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL ///
    (mean) FuncM Year ///
    (sd) SDPay=PayBonus ///
    (firstnm) ISOCodeM ///
    (sum)  spanM=one ///
    , by(IDteam YearMonth)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. construct event-related variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CA30_toL = .
replace  CA30_toL = 1 if CA30_LtoL==1 | CA30_HtoL==1
replace  CA30_toL = 0 if CA30_HtoH==1 | CA30_LtoH==1

generate CA30_toH = .
replace  CA30_toH = 1 if CA30_HtoH==1 | CA30_LtoH==1
replace  CA30_toH = 0 if CA30_LtoL==1 | CA30_HtoL==1

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. save the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable AvPay                  "Team-level average pay plus bonus"
label variable ShareChangeSalaryGrade "Team-level share of employees that experienced a salary grade increase"
label variable SharePromWL            "Team-level share of employees that experienced a work level promotion"
label variable AvProductivityStd      "Team-level average sales bonus (s.d.)"
label variable TeamFracFemale         "Team-level gender diversity"
label variable TeamFracAgeBand        "Team-level age band diversity"
label variable TeamFracOfficeCode     "Team-level office diversity"
label variable TeamFracCountry        "Team-level home country diversity"

label variable ShareSameGender        "Team-level share of employees that have the same gender as the manager"
label variable ShareSameAge           "Team-level share of employees that have the same age band as the manager"
label variable ShareSameOffice        "Team-level share of employees that are in the same office as the manager"
label variable ShareSameNationality   "Team-level share of employees that have the same home country as the manager"
label variable ShareTransferSJ        "Team-level share of employees that experienced a standard job change"
label variable ShareTransferSJL       "Team-level share of employees that experienced a lateral move"
label variable ShareTransferFunc      "Team-level share of employees that experienced a function change"

label variable IDlseMHRPreMost        "Pre-event manager ID (manually assigned)"
label variable IDMngr_Post            "Post-event manager ID"
label variable Event_Time             "Event time"
label variable Rel_Time               "YearMonth - Event_Time"
label variable CA30_LtoL              "LtoL (team level)"
label variable CA30_LtoH              "LtoH (team level)"
label variable CA30_HtoH              "HtoH (team level)"
label variable CA30_HtoL              "HtoL (team level)"
label variable CA30_toL               "LtoL and HtoL (team-level)"
label variable CA30_toH               "LtoH and HtoH (team-level)"
label variable spanM                  "Team size (the artificial team)"
label variable Year                   "Year"
label variable FuncM                  "Manager's function"
label variable ISOCodeM               "Manager's working country"

order Year YearMonth IDteam ///
    Rel_Time Event_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL CA30_toL CA30_toH ///
    FuncM ISOCodeM ///
    AvPay ShareChangeSalaryGrade ShareTransferSJ ShareTransferSJL ShareTransferFunc ///
    TeamFracFemale TeamFracAgeBand TeamFracOfficeCode TeamFracCountry ///
    ShareSameGender ShareSameAge ShareSameOffice ShareSameNationality

save "${TempData}/0106TeamLevelEventsAndOutcomes_WithTransferSJL.dta", replace