/* 
This do file constructs a team level dataset focusing on those workers who experienced a manager change event. 

Notes: Here are the procedures to construct the team-level dataset.
    (1) Identify a qualified subset of event workers such that a proper notion of team applies.
    (2) Construct team ID, which is uniquely determined by the (IDlseMHRPreMost, IDlseMHRPost, FT_Event_Time) pair.
    (3) Generate team-level variables used in endogenous mobility check regressions.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 

Output:
    "${TempData}/06SwitcherTeams.dta"

Description of the Output Dataset:
    A panel of teams defined by the (IDlseMHRPreMost, IDlseMHRPost, FT_Event_Time) pair.
    It contains the following variables:
        event-related variables that identify which event the team experienced;
        team-level variables in four panels: share of vertical moves, pay and productivity, homophily with managers, team diversity indices, share of leaves, share of lateral moves.

RA: WWZ 
Time: 2024-11-26
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. specify a subset of events 
*??         such that a team can be properly specified
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

order IDlse YearMonth IDlseMHR ChangeMR TransferInternal TransferSJ
sort IDlse YearMonth

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep only a panel of event workers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. modify ChangeMR: the team composition restriction
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&? I only consider the events such that at the event time, 
*&? the number of workers who experience the manager change is >= 50% of the workers who are supervised by the post-event manager

*!! set FT_Event_Time to missing if not at the event time (originally, it is an individual-level variable)
replace FT_Event_Time = . if FT_Rel_Time!=0

*!! number of workers with the same (post-event manager, event time) combination
sort IDlseMHR FT_Event_Time
bysort IDlseMHR FT_Event_Time: egen no_workersinevent = count(IDlse)
replace no_workersinevent    = . if IDlseMHR==. | FT_Event_Time==.

*!! number of workers with the same (manager, year month) combination
sort IDlseMHR YearMonth
bysort IDlseMHR YearMonth: generate no_supervisedworkers = _N
replace no_supervisedworkers = . if IDlseMHR==.

*!! [# of workers in the (post-event manager, event time) pair] / [# of workers in the (manager, year month) pair]
generate prop_eventworkers = no_workersinevent / no_supervisedworkers

*!! apply the team composition restriction 
generate ChangeMR_Team = ChangeMR
replace  ChangeMR_Team = 0 if prop_eventworkers<0.5

sort IDlse YearMonth
order IDlse YearMonth IDlseMHR ChangeMR ChangeMR_Team

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. modify ChangeMR: the team inheritance restriction
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&? I only consider the events such that at the event time, 
*&? >= 50% of event workers are coming from the same pre-event manager

sort IDlse YearMonth
generate IDlseMHRPre=IDlseMHR[_n-1] if FT_Event_Time!=.

*!! identify a pre-event manager who supervised the maximum number of workers in a (post-event manager, event time) pair
*!! specifically, if rnkteam==rnkmode, then the worker comes from that pre-event manager  
sort   IDlseMHR FT_Event_Time
bysort IDlseMHR FT_Event_Time: egen rnkteam = rank(IDlseMHRPre)
bysort IDlseMHR FT_Event_Time: egen rnkmode = mode(rnkteam), minmode 

*!! proportion of workers in a (post-event manager, event time) pair that comes from that pre-event manager
sort   IDlseMHR FT_Event_Time
bys IDlseMHR FT_Event_Time: egen PropSameTeam = mean(cond(rnkteam==rnkmode, 1, 0))  if rnkmode!=.

*!! apply the team inheritance restriction 
replace ChangeMR_Team = 0 if PropSameTeam<0.5 | rnkmode==.

*&? Note: The team composition and inheritance restrictions together ensure that 
*&?       at least 50% of team members all shared same previous manager and all move to same next manager.

sort IDlse YearMonth
order IDlse YearMonth IDlseMHR ChangeMR ChangeMR_Team

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. modify ChangeMR: the manager duration restriction
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&? I only consider the events such that the post-event manager stayed in the team for at least 3 months.

*!! s-1-3-1. for a event worker, calculate his exposure time with the post-event manager 

*!! s-1-3-1-1. post-event manager id 
generate FT_Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .
sort IDlse YearMonth
generate long temp_Post_Mngr_ID = . //&& type notation is necessary
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_LtoL & FT_Calend_Time_LtoL != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_LtoH & FT_Calend_Time_LtoH != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_HtoH & FT_Calend_Time_HtoH != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_HtoL & FT_Calend_Time_HtoL != .
bysort IDlse: egen long Post_Mngr_ID = mean(temp_Post_Mngr_ID) //&& type notation is necessary
label variable Post_Mngr_ID "Post-event manager ID"
drop temp_Post_Mngr_ID

*!! s-1-3-1-2. if the month is supervised by the post-event manager
generate Post_Mngr = ((IDlseMHR == Post_Mngr_ID) & (FT_Post==1)) if Post_Mngr_ID!=.
label variable Post_Mngr "=1, if the worker is under the post-event manager"

*!! s-1-3-1-3. calculate the total number of months supervised by the post-event manager
sort IDlse YearMonth
bysort IDlse: egen FT_Exposure = total(Post_Mngr)
replace FT_Exposure = . if Post_Mngr==.
label variable FT_Exposure "Number of months a worker spends time with the post-event manager"

*!! s-1-3-2. for a (post-event manager, event time) pair, calculate the mode of exposure time across all event workers
sort IDlseMHR FT_Event_Time
bysort IDlseMHR FT_Event_Time: egen mode_FT_Exposure = mode(FT_Exposure)

*!! s-1-3-3. apply the manager duration restriction
replace ChangeMR_Team = 0 if mode_FT_Exposure < 3

sort IDlse YearMonth
order IDlse YearMonth IDlseMHR ChangeMR ChangeMR_Team

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. generate team id 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. ignore those events with ChangeMR_Team==0
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen q_TeamLevelData = max(ChangeMR_Team)
codebook q_TeamLevelData

sort IDlse YearMonth
order IDlse YearMonth IDlseMHR ChangeMR ChangeMR_Team q_TeamLevelData

keep if q_TeamLevelData==1
    //&? keep only those events such that a proper pre-event and a post-event team can be defined 
    //impt: important procedures!

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. pre-event team id: (IDlseMHRPreMost, FT_Event_Time) pair
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&? For a worker, instead of considering his real pre-event manager, 
*&? let's assign him the mode pre-evenet manager among all workers who share the same (post-event manager, event time) pair.

*!! an individual-level event time 
sort IDlse YearMonth
capture drop FT_Event_Time
generate FT_Event_Time = . 
replace  FT_Event_Time = FT_Calend_Time_LtoL if FT_Calend_Time_LtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_LtoH if FT_Calend_Time_LtoH!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoL if FT_Calend_Time_HtoL!=. & FT_Event_Time==.
replace  FT_Event_Time = FT_Calend_Time_HtoH if FT_Calend_Time_HtoH!=. & FT_Event_Time==.
format   FT_Event_Time %tm

*!! pre-event manager id: non-missing only when FT_Rel_Time==0
sort IDlse YearMonth
capture  drop IDlseMHRPre
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
*-? s-2-3. post-event team id: (IDlseMHRPost, FT_Event_Time) pair
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! IDlseMHRPost: worker-level
sort IDlse YearMonth
bysort IDlse: egen long IDlseMHRPost = mean(cond(FT_Rel_Time==0, IDlseMHR, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. team id: (IDlseMHRPreMost, IDlseMHRPost, FT_Event_Time) pair
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
*?? step 3. modify team-level treatment status 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
* impt: Our pre-event manager is manually assigned (according to the mode calculation).
* impt: Thus, team-level treatment status may not coincide with individual-level treatment status.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. reconstruct the manager id
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*&? for a worker, keep only two managers: (manually assigned) pre- and post-event managers
*&? note that the pre-event manager is manually assigned for some workers based on mode calculation

generate long IDlseMHR_Team = IDlseMHRPreMost if FT_Rel_Time<0
replace       IDlseMHR_Team = IDlseMHRPost    if FT_Rel_Time>=0

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. drop original event-related variables
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
*-? s-3-3. reconstruct event-related variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-3-3-1. obtain high-flyer measures
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

*&? The rename procedures make sure that we are considering only the 
*&? (manually assigned) pre-event managers and the post-event managers high-flyer status.

rename IDlseMHR IDlseMHR_temp
rename IDlseMHR_Team IDlseMHR

merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 

rename IDlseMHR IDlseMHR_Team
rename IDlseMHR_temp IDlseMHR

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-3-3-2. team-level pre- and post-event manager high-flyer status 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*&? First, IDlseMHR_Team is constructed based on IDlseMHRPreMost and IDlseMHRPost.
*&? Next, EarlyAgeM is merged based on IDlseMHR_Team.
*&? Therefore, the EarlyAgeM_Pre and EarlyAgeM_Post variables are at team-level.

sort IDlse YearMonth IDteam
bysort IDlse: egen EarlyAgeM_Post = mean(cond(FT_Rel_Time==0,  EarlyAgeM, .))
bysort IDlse: egen EarlyAgeM_Pre  = mean(cond(FT_Rel_Time==-1, EarlyAgeM, .))

order IDlse YearMonth FT_Rel_Time IDlseMHR EarlyAgeM EarlyAgeM_Pre EarlyAgeM_Post

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-3-3-3. team-level treatment status identifies
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
*?? step 4. create relevant team-level variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. create Herfindahl indices for diversity variables
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
*-? s-4-2. workers' homophily with managers 
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
*-? s-4-3. decompose variable TransferSJ
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! lateral transfer under the same manager
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*!! lateral transfer under different managers 
generate TransferSJDiffM = TransferSJ
replace  TransferSJDiffM = 0 if TransferSJSameM==1 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-4. get productivity data 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${TempData}/08SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. collapse into team-month level data
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-1. collapse 
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
*-? s-5-2. construct event-related variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_toL = .
replace  FT_toL = 1 if FT_LtoL==1 | FT_HtoL==1
replace  FT_toL = 0 if FT_HtoH==1 | FT_LtoH==1

generate FT_toH = .
replace  FT_toH = 1 if FT_HtoH==1 | FT_LtoH==1
replace  FT_toH = 0 if FT_LtoL==1 | FT_HtoL==1

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-3. save the dataset  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&? a panel of teams consisting of qualified switchers

order ///
    IDteam YearMonth Year IDlseMHRPreMost IDlseMHRPost FT_Event_Time spanM ///
    FT_Rel_Time FT_Mngr_both_WL2 FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    ISOCodeM FuncM 

save "${TempData}/06_02SwitcherTeams_WorkerAndTeamRestrictions.dta", replace