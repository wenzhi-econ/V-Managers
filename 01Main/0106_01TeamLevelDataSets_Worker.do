/* 
This do file constructs a team level dataset focusing on those workers who experienced a manager change event. 

impt: The team id is uniquely defined by a (IDlseMHRPreMost, IDlseMHRPost, FT_Event_Time) pair.
impt: Managers identified by IDlseMHRPreMost is not necessarily the same pre-event manager for each individual.
impt: Team-level treatment status is not necessarily the same individual-level treatment status.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 

Output:
    "${TempData}/06SwitcherTeams.dta"

Description of the Output Dataset:
    A panel of teams defined by the (IDlseMHRPre IDlseMHRPrePost) pair.
    It contains the following variables:
        event-related variables that identify which event the team experienced;
        team-level variables in four panels: share of vertical moves, pay and productivity, homophily with managers, team diversity indices, share of leaves, share of lateral moves.

RA: WWZ 
Time: 2024-11-23
*/

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep only a panel of event workers

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate team id 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. pre-event team id: (IDlseMHRPreMost, FT_Event_Time) pair
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! pre-event manager id: non-missing only when FT_Rel_Time==0
sort IDlse YearMonth
generate long IDlseMHRPre=IDlseMHR[_n-1] if FT_Rel_Time==0 & FT_Rel_Time[_n-1]==-1

*!! event time: non-missing only when when FT_Rel_Time==0
generate FT_Event_Time_Missing = FT_Event_Time if FT_Rel_Time==0

*!! the mode across pre-event managers whose workers move to the same post-event manager in the same month
*!! non-missing only when FT_Rel_Time==0
sort   IDlseMHR FT_Event_Time_Missing
bysort IDlseMHR FT_Event_Time_Missing: egen temp_IDlseMHRPreMost = mode(IDlseMHRPre), minmode

*!! IDlseMHRPreMost: worker-level 
sort IDlse YearMonth
bysort IDlse: egen long IDlseMHRPreMost = mean(temp_IDlseMHRPreMost)
drop temp_IDlseMHRPreMost

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. post-event team id: (IDlseMHRPost, FT_Event_Time) pair
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! IDlseMHRPost: worker-level
sort IDlse YearMonth
bysort IDlse: egen long IDlseMHRPost = mean(cond(FT_Rel_Time==0, IDlseMHR, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. team id: (IDlseMHRPreMost, IDlseMHRPost, FT_Event_Time) pair
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! team id
*&? All three variables (IDlseMHRPreMost IDlseMHRPost FT_Event_Time) are at individual-level
capture drop IDteam
egen IDteam = group(IDlseMHRPreMost IDlseMHRPost FT_Event_Time)

label variable IDlseMHRPreMost   "Pre-event manager ID (manually assigned)"
label variable IDlseMHRPost      "Post-event manager ID"
label variable FT_Event_Time     "Event time"
label variable IDteam            "Team ID (defined by (IDlseMHRPreMost, IDlseMHRPost, FT_Event_Time) pair)"

sort IDteam IDlse YearMonth 
order IDteam IDlse YearMonth FT_Rel_Time IDlseMHRPreMost IDlseMHRPost FT_Event_Time

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. modify team-level treatment status 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
* impt: Our pre-event manager is manually assigned (according to the mode calculation).
* impt: Thus, team-level treatment status may not coincide with individual-level treatment status.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. reconstruct the manager id
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*&? for a worker, keep only two managers: (manually assigned) pre- and post-event managers
*&? note that the pre-event manager is manually assigned for some workers based on mode calculation

generate long IDlseMHR_Team = IDlseMHRPreMost if FT_Rel_Time<0
replace       IDlseMHR_Team = IDlseMHRPost    if FT_Rel_Time>=0

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. drop original event-related variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop EarlyAgeM
capture drop FT_LtoL 
capture drop FT_LtoH 
capture drop FT_HtoH 
capture drop FT_HtoL 
/* capture drop FT_Never_ChangeM 
capture drop FT_Calend_Time_LtoL 
capture drop FT_Calend_Time_LtoH 
capture drop FT_Calend_Time_HtoH 
capture drop FT_Calend_Time_HtoL */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. reconstruct event-related variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-3-1. obtain high-flyer measures
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

*&? The rename procedures make sure that we are considering only the (manually assigned) pre-event managers and the post-event managers high-flyer status.

rename IDlseMHR IDlseMHR_temp
rename IDlseMHR_Team IDlseMHR

merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 

rename IDlseMHR IDlseMHR_Team
rename IDlseMHR_temp IDlseMHR

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-3-2. team-level pre- and post-event manager high-flyer status 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*&? First, IDlseMHR_Team is constructed based on IDlseMHRPreMost and IDlseMHRPost.
*&? Next, EarlyAgeM is merged based on IDlseMHR_Team.
*&? Therefore, the EarlyAgeM_Pre and EarlyAgeM_Post variables are at team-level.

sort IDlse YearMonth IDteam
bysort IDlse: egen EarlyAgeM_Post = mean(cond(FT_Rel_Time==0,  EarlyAgeM, .))
bysort IDlse: egen EarlyAgeM_Pre  = mean(cond(FT_Rel_Time==-1, EarlyAgeM, .))

order IDlse YearMonth FT_Rel_Time IDlseMHR EarlyAgeM EarlyAgeM_Pre EarlyAgeM_Post

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-3-3. team-level treatment status identifies
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate FT_LtoL = 0
replace  FT_LtoL = 1 if EarlyAgeM_Pre==0 & EarlyAgeM_Post==0

generate FT_LtoH = 0
replace  FT_LtoH = 1 if EarlyAgeM_Pre==0 & EarlyAgeM_Post==1

generate FT_HtoH = 0
replace  FT_HtoH = 1 if EarlyAgeM_Pre==1 & EarlyAgeM_Post==1

generate FT_HtoL = 0
replace  FT_HtoL = 1 if EarlyAgeM_Pre==1 & EarlyAgeM_Post==0

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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. get productivity data 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${TempData}/08SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. collapse into team-month level data
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. collapse 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate one = 1 

generate Year = year(dofm(YearMonth))

collapse ///
    (mean) AvPay=PayBonus ShareChangeSalaryGrade=ChangeSalaryGrade SharePromWL=PromWL AvProductivityStd=ProductivityStd ///
    (mean) TeamFracFemale TeamFracAgeBand TeamFracOfficeCode TeamFracCountry ///
    (mean) ShareSameGender=SameGender ShareSameAge=SameAge ShareSameOffice=SameOffice ShareSameNationality=SameNationality ///
    (mean) ShareTransferSJ=TransferSJ ShareTransferFunc=TransferFunc ///
    (mean) IDlseMHRPreMost IDlseMHRPost FT_Event_Time FT_Rel_Time FT_Mngr_both_WL2 FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    (mean) FuncM Year ///
    (firstnm) ISOCodeM ///
    (sum)  spanM=one ///
    , by(IDteam YearMonth)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. construct event-related variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_toL = .
replace  FT_toL = 1 if FT_LtoL==1 | FT_HtoL==1
replace  FT_toL = 0 if FT_HtoH==1 | FT_LtoH==1

generate FT_toH = .
replace  FT_toH = 1 if FT_HtoH==1 | FT_LtoH==1
replace  FT_toH = 0 if FT_LtoL==1 | FT_HtoL==1

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. save the dataset  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

order ///
    IDteam YearMonth Year IDlseMHRPreMost IDlseMHRPost FT_Event_Time spanM ///
    FT_Rel_Time FT_Mngr_both_WL2 FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    ISOCodeM FuncM 

save "${TempData}/06_01SwitcherTeams_WorkerRestrictions.dta", replace