/* 
This do file investigates heterogeneity in event studies by the number of jobs in a team (at event time).

Input:
    "${TempData}/06MainOutcomesInEventStudies_Heterogeneity.dta" <== constructed in 0106 do file 

RA: WWZ 
Time: 2024-10-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/06MainOutcomesInEventStudies_Heterogeneity.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. generate relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! number of different jobs inside a team-year cell
sort IDlseMHR Year
egen Job_tag = tag(StandardJobE IDlseMHR YearMonth)
bysort IDlseMHR YearMonth: egen Num_Jobs = total(Job_tag)

*!! number of different jobs for treated workers at the time of event
sort IDlse YearMonth
bysort IDlse: egen Num_Jobs_Team0 = mean(cond(FT_Rel_Time==0, Num_Jobs, .))

*!! above median number of different jobs for treated workers at the time of event
summarize Num_Jobs_Team0 if Ind_tag==1, detail 
generate JobTeamNum0 = (Num_Jobs_Team0 > `r(p50)') if Num_Jobs_Team0!=. 

*!! "event * post * heterogeneity indicator" for four treatment groups 
global Hetero_Vars JobTeamNum
foreach var in $Hetero_Vars {
    generate FT_LtoLXPostX`var' = FT_LtoLXPost * `var'0
    generate FT_LtoHXPostX`var' = FT_LtoHXPost * `var'0
    generate FT_HtoHXPostX`var' = FT_HtoHXPost * `var'0
    generate FT_HtoLXPostX`var' = FT_HtoLXPost * `var'0
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global hetero_regressors ///
    FT_LtoLXPost FT_LtoLXPostXJobTeamNum ///
    FT_LtoHXPost FT_LtoHXPostXJobTeamNum ///
    FT_HtoHXPost FT_HtoHXPostXJobTeamNum ///
    FT_HtoLXPost FT_HtoLXPostXJobTeamNum

foreach outcome in TransferSJVC TransferFuncC ChangeSalaryGradeC {
    reghdfe `outcome' $hetero_regressors  ///
        if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) ///
        , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)

    xlincom (FT_LtoHXPostXJobTeamNum - FT_LtoLXPostXJobTeamNum), level(95) post

    if "`outcome'" == "TransferSJVC" {
        local outcome_name TSJVC
    }
    if "`outcome'" == "TransferFuncC" {
        local outcome_name TFC
    }
    if "`outcome'" == "ChangeSalaryGradeC" {
        local outcome_name CSGC
    }

    est store JobTeamNum_`outcome_name'
}


esttab JobTeamNum_TSJVC JobTeamNum_TFC JobTeamNum_CSGC using "${Results}/TransferOutcomes_HeterogeneityByTeamJobNumbers.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Team job diversity, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\begin{tabular}{lccc}" "\hline\hline" "& \multicolumn{1}{c}{Lateral moves} & \multicolumn{1}{c}{Cross-function moves} & \multicolumn{1}{c}{Pay grade increase} \\") ///
    posthead("\hline \\") ///
    prefoot("") postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. The heterogeneity indicator is whether the number of different jobs inside a team is above the median. " "\end{tablenotes}")




