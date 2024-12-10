/* 
This do file runs DID regressions on team-level performance and mover measures.

Notes on the regressions:
    (1) The regression only includes LtoL and LtoH groups.
    (2) The regression includes relative time period [-24, +24].
    (3) I run DID style regressions on these outcomes.

Input: 
    "${TempData}/06SwitcherTeams.dta" <== created in 0106 do file

Output:
    "${Results}/logfile_20241206TeamLevelPerfAndMovers.txt"

RA: WWZ 
Time: 2024-12-06
*/


capture log close
log using "${Results}/logfile_20241206TeamLevelPerfAndMovers", replace text

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant team-level dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep only a panel of event workers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. generate team id 
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

*!! IDlseMHRPost: worker-level
sort IDlse YearMonth
bysort IDlse: egen long IDlseMHRPost = mean(cond(FT_Rel_Time==0, IDlseMHR, .))

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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. modify team-level treatment status 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
* impt: Our pre-event manager is manually assigned (according to the mode calculation).
* impt: Thus, team-level treatment status may not coincide with individual-level treatment status.

*!! reconstruct the manager id
*&? for a worker, keep only two managers: (manually assigned) pre- and post-event managers
*&? note that the pre-event manager is manually assigned for some workers based on mode calculation

generate long IDlseMHR_Team = IDlseMHRPreMost if FT_Rel_Time<0
replace       IDlseMHR_Team = IDlseMHRPost    if FT_Rel_Time>=0

*!! drop original event-related variables
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

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-1. obtain high-flyer measures
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

*&? The rename procedures make sure that we are considering only the (manually assigned) pre-event managers and the post-event managers high-flyer status.

rename IDlseMHR IDlseMHR_temp
rename IDlseMHR_Team IDlseMHR

merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 

rename IDlseMHR IDlseMHR_Team
rename IDlseMHR_temp IDlseMHR

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-2. team-level pre- and post-event manager high-flyer status 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*&? First, IDlseMHR_Team is constructed based on IDlseMHRPreMost and IDlseMHRPost.
*&? Next, EarlyAgeM is merged based on IDlseMHR_Team.
*&? Therefore, the EarlyAgeM_Pre and EarlyAgeM_Post variables are at team-level.

sort IDlse YearMonth IDteam
bysort IDlse: egen EarlyAgeM_Post = mean(cond(FT_Rel_Time==0,  EarlyAgeM, .))
bysort IDlse: egen EarlyAgeM_Pre  = mean(cond(FT_Rel_Time==-1, EarlyAgeM, .))

order IDlse YearMonth FT_Rel_Time IDlseMHR EarlyAgeM EarlyAgeM_Pre EarlyAgeM_Post

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-3. team-level treatment status identifies
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

generate FT_LtoL = 0
replace  FT_LtoL = 1 if EarlyAgeM_Pre==0 & EarlyAgeM_Post==0

generate FT_LtoH = 0
replace  FT_LtoH = 1 if EarlyAgeM_Pre==0 & EarlyAgeM_Post==1

generate FT_HtoH = 0
replace  FT_HtoH = 1 if EarlyAgeM_Pre==1 & EarlyAgeM_Post==1

generate FT_HtoL = 0
replace  FT_HtoL = 1 if EarlyAgeM_Pre==1 & EarlyAgeM_Post==0

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. create outcome variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! PayGrowth
xtset IDlse YearMonth 
generate PayGrowth = d.LogPayBonus

*!! VPA
merge 1:1 IDlse YearMonth using "${RawMNEData}/AllSnapshotWC.dta" , keepusing(VPA)
    drop if _merge==2 
    drop _merge 

*!! VPA101
generate VPA101 = (VPA > 100) if VPA!=.

*!! VPAL80
generate VPAL80 = (VPA <= 80) if VPA!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. collapse into team level dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate one = 1 

generate Year = year(dofm(YearMonth))

collapse ///
    (mean) ShareTransferSJ=TransferSJ ShareTransferFunc=TransferFunc ShareChangeSalaryGrade=ChangeSalaryGrade ///
    (mean) IDlseMHRPreMost IDlseMHRPost FT_Event_Time FT_Rel_Time FT_Mngr_both_WL2 FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    (mean) AvVPA=VPA VPA101=VPA101 VPAL80=VPAL80 ///
    (sd) SDVPA=VPA ///
    (sum) spanM=one ///
    , by(IDteam YearMonth)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. generate other variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CVVPA = SDVPA / AvVPA

generate FT_Post = (FT_Rel_Time>=0) if FT_Rel_Time!=.
generate FT_LtoL_X_Post = FT_LtoL * FT_Post
generate FT_LtoH_X_Post = FT_LtoH * FT_Post
generate FT_HtoH_X_Post = FT_HtoH * FT_Post
generate FT_HtoL_X_Post = FT_HtoL * FT_Post

save "${TempData}/TeamLevelGainingHF.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/TeamLevelGainingHF.dta", clear

eststo clear 

reghdfe AvVPA FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & (inrange(FT_Rel_Time, -24, 24)), absorb(IDteam YearMonth) cluster(IDlseMHRPost)
    eststo AvVPA
    summarize AvVPA if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe CVVPA FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & (inrange(FT_Rel_Time, -24, 24)), absorb(IDteam YearMonth) cluster(IDlseMHRPost)
    eststo CVVPA
    summarize CVVPA if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe VPA101 FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & (inrange(FT_Rel_Time, -24, 24)), absorb(IDteam YearMonth) cluster(IDlseMHRPost)
    eststo VPA101
    summarize VPA101 if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe VPAL80 FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & (inrange(FT_Rel_Time, -24, 24)), absorb(IDteam YearMonth) cluster(IDlseMHRPost)
    eststo VPAL80
    summarize VPAL80 if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ShareTransferSJ FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & (inrange(FT_Rel_Time, -24, 24)), absorb(IDteam YearMonth) cluster(IDlseMHRPost)
    eststo ShareTransferSJ
    summarize ShareTransferSJ if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ShareTransferFunc FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & (inrange(FT_Rel_Time, -24, 24)), absorb(IDteam YearMonth) cluster(IDlseMHRPost)
    eststo ShareTransferFunc
    summarize ShareTransferFunc if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

reghdfe ShareChangeSalaryGrade FT_Post FT_LtoH_X_Post if (FT_LtoL==1 | FT_LtoH==1) & (inrange(FT_Rel_Time, -24, 24)), absorb(IDteam YearMonth) cluster(IDlseMHRPost)
    eststo ShareChangeSalaryGrade
    summarize ShareChangeSalaryGrade if e(sample)==1 & FT_LtoL==1
    estadd scalar cmean = r(mean)

esttab AvVPA CVVPA VPA101 VPAL80, keep(FT_LtoH_X_Post FT_Post)

esttab ShareTransferSJ ShareChangeSalaryGrade ShareTransferFunc, keep(FT_LtoH_X_Post FT_Post)
