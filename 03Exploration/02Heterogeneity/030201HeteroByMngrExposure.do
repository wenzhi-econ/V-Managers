/* 
This do file extends Table VII by investigating heterogeneity based on workers' exposure time to the new manager.

*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplified dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    TransferSJ TransferSJC TransferFunc TransferFuncC TransferSJSameM /// 
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    TransferSJ TransferSJC TransferFunc TransferFuncC TransferSJSameM /// 
    WL2 ///
    FTLL FTLH FTHH FTHL
        // IDs, manager info, outcome variables, sample restriction variable, treatment info

rename WL2 FT_Mngr_both_WL2 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. construct (individual level) event dummies 
*-?       and (individual-month level) relative dates to the event
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! calendar time of the event
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHH FT_Calend_Time_HtoH
rename FTHL FT_Calend_Time_HtoL

*!! five event dummies: 4 types of treatment + 1 never-treated
generate FT_LtoL = 0 
replace  FT_LtoL = 1 if FT_Calend_Time_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if FT_Calend_Time_LtoH != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if FT_Calend_Time_HtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if FT_Calend_Time_HtoL != .

generate FT_Never_ChangeM = . 
replace  FT_Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  FT_Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 

label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*!! "event * post" (ind-month level) for four treatment groups
generate FT_Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .
generate FT_LtoLXPost = FT_LtoL * FT_Post
generate FT_LtoHXPost = FT_LtoH * FT_Post
generate FT_HtoHXPost = FT_HtoH * FT_Post
generate FT_HtoLXPost = FT_HtoL * FT_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. construct exposure time variable (for heterogeneity)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate occurrence = _n

*!! post-event manager id 
generate long temp_Post_Mngr_ID = . //&& type notation is necessary
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_LtoL & FT_Calend_Time_LtoL != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_LtoH & FT_Calend_Time_LtoH != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_HtoH & FT_Calend_Time_HtoH != .
replace  temp_Post_Mngr_ID = IDlseMHR if YearMonth == FT_Calend_Time_HtoL & FT_Calend_Time_HtoL != .

bysort IDlse: egen long Post_Mngr_ID = mean(temp_Post_Mngr_ID) //&& type notation is necessary
label variable Post_Mngr_ID "Post-event manager ID"

drop temp_Post_Mngr_ID

*!! number of months working with the post-event manager
generate Post_Mngr = ((IDlseMHR == Post_Mngr_ID) & (FT_Post==1)) if Post_Mngr_ID!=.
label variable Post_Mngr "=1, if the worker is under the post-event manager"

sort IDlse YearMonth
bysort IDlse: egen FT_Exposure = total(Post_Mngr)
replace FT_Exposure = . if Post_Mngr==.
label variable FT_Exposure "Number of months a worker spends time with the post-event manager"

*!! summarize the FT_Exposure variable 
histogram FT_Exposure if occurrence==1, width(1) fraction
graph export "${Results}/DistributionOfFT_Exposure.png", replace as(png)

summarize FT_Exposure if occurrence==1, detail 
global FT_Exposure_Median = r(p50)

*!! Above and Below Median 
generate FT_Exp_AboveM = (FT_Exposure >= ${FT_Exposure_Median}) if FT_Exposure!=.
generate FT_Exp_BelowM = (FT_Exposure < ${FT_Exposure_Median}) if FT_Exposure!=.

*!! Interact with FT_LtoLXPost, FT_LtoHXPost, FT_HtoHXPost, FT_HtoLXPost
generate FT_LtoLXPostXFT_Exp_AboveM = FT_LtoLXPost * FT_Exp_AboveM
generate FT_LtoHXPostXFT_Exp_AboveM = FT_LtoHXPost * FT_Exp_AboveM
generate FT_HtoHXPostXFT_Exp_AboveM = FT_HtoHXPost * FT_Exp_AboveM
generate FT_HtoLXPostXFT_Exp_AboveM = FT_HtoLXPost * FT_Exp_AboveM

save "${TempData}/temp_HeteroByMngrExposure.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_HeteroByMngrExposure.dta", clear 

global hetero_regressors ///
    FT_LtoLXPost FT_LtoLXPostXFT_Exp_AboveM ///
    FT_LtoHXPost FT_LtoHXPostXFT_Exp_AboveM ///
    FT_HtoHXPost FT_HtoHXPostXFT_Exp_AboveM ///
    FT_HtoLXPost FT_HtoLXPostXFT_Exp_AboveM

foreach outcome in TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC {
    reghdfe `outcome' $hetero_regressors  ///
        if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) ///
        , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)

    xlincom (FT_LtoHXPostXFT_Exp_AboveM - FT_LtoLXPostXFT_Exp_AboveM), level(95) post

    if "`outcome'" == "TransferSJVC" {
        local outcome_name TSJVC
    }
    if "`outcome'" == "TransferFuncC" {
        local outcome_name TFC
    }
    if "`outcome'" == "PromWLC" {
        local outcome_name PWLC
    }
    if "`outcome'" == "ChangeSalaryGradeC" {
        local outcome_name CSGC
    }

    est store `outcome_name'
}

esttab TSJVC TFC PWLC CSGC using "${Results}/HeterogeneityByMngrExposure_OneQuarterEstimate.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Exposure length to post-event manager, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{Lateral moves} & \multicolumn{1}{c}{Cross-function moves} & \multicolumn{1}{c}{Vertical moves} & \multicolumn{1}{c}{Pay grade increase} \\") ///
    posthead("") prefoot("") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes." "\end{tablenotes}")



