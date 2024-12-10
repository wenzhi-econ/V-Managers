
/* 
This do file runs regressions for endogenous mobility checks on the team-level dataset.

Notes on the regressions:
    (1) The regression sample consists of teams who experienced manager change in relative period [-36, -6], with the restrictions listed in (2) and (3).
    (2) The team contains more than 1 worker, and both the pre- and post-event managers are of WL2.
    (3) The worker does not have a simultaneous internal or lateral move.

Input: 
    "${TempData}/06_02SwitcherTeams_WorkerAndTeamRestrictions.dta" <== created in 0106_02 do file

Output:
    "${Results}/logfile_20241123_EndogenousMobilityChecks_FullTransition.txt"

RA: WWZ 
Time: 2024-11-23
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. preparations for regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/06_02SwitcherTeams_WorkerAndTeamRestrictions.dta", clear 


generate lAvPay = log(AvPay)

global perf  lAvPay                ShareChangeSalaryGrade ShareTransferSJ     ShareTransferFunc
global div   TeamFracFemale        TeamFracAgeBand        TeamFracOfficeCode  TeamFracCountry
global homo  ShareSameGender       ShareSameAge           ShareSameOffice     ShareSameNationality  

label variable lAvPay                 "Salary (logs)"
label variable ShareChangeSalaryGrade "Salary grade increase"
label variable ShareTransferSJ        "Lateral move"
label variable ShareTransferFunc      "Cross-functional move"

label variable TeamFracFemale         "Diversity, gender"
label variable TeamFracAgeBand        "Diversity, age"
label variable TeamFracOfficeCode     "Diversity, office"
label variable TeamFracCountry        "Diversity, nationality"

label variable ShareSameGender        "Same gender"
label variable ShareSameAge           "Same age"
label variable ShareSameOffice        "Same office"
label variable ShareSameNationality   "Same nationality" 

codebook IDteam if spanM>1 & inrange(FT_Rel_Time, -36, -6) & FT_Mngr_both_WL2==1 // 3,472 teams

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global controls FuncM ISOCodeM Year

local i = 1
foreach y in  $perf $div $homo {
	
    reghdfe `y' FT_LtoH FT_HtoH FT_HtoL if spanM>1 & inrange(FT_Rel_Time, -36, -6) & FT_Mngr_both_WL2==1, cluster(IDlseMHRPreMost) absorb($controls)
        eststo reg`i'
        lincom FT_LtoH 
            estadd scalar diff1 = r(estimate)
            estadd scalar p_value1 = r(p)
            estadd scalar se_diff1 = r(se)
        lincom FT_HtoL-FT_HtoH
            estadd scalar diff2 = r(estimate)
            estadd scalar p_value2 = r(p)
            estadd scalar se_diff2 = r(se)
        summarize `y' if e(sample)==1 & FT_LtoL==1
        estadd scalar mean_LtoL = r(mean)

    local i = `i' +1
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: produce the table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

esttab reg1 reg2 reg3 reg4 using "${Results}/EndogenousMobilityChecks_FullTransition_WorkerAndTeamRestrictions.tex", ///
    replace fragment nofloat nonotes nocons label nobaselevels interaction("$\times$") ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{4}{c}}" "\hline\hline \\" "\multicolumn{5}{c}{\textit{Panel (a): team performance}} \\\\[-1ex]")

esttab reg5 reg6 reg7 reg8 using "${Results}/EndogenousMobilityChecks_FullTransition_WorkerAndTeamRestrictions.tex", ///
    append fragment nofloat nonotes nocons label nobaselevels interaction("$\times$") ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (b): team diversity}} \\\\[-1ex]") 

esttab reg9 reg10 reg11 reg12 using "${Results}/EndogenousMobilityChecks_FullTransition_WorkerAndTeamRestrictions.tex", ///
    append fragment nofloat nonotes nocons label nobaselevels interaction("$\times$") ///
    drop(FT_* _cons) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    stats(diff1 p_value1 diff2 p_value2 mean_LtoL r2 N, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean, LtoL group" "R-squared" "N") fmt(%9.4f %9.3f %9.4f %9.3f %9.3f %9.3f %9.0g)) ///
    prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (c): team homophily with manager}} \\\\[-1ex]") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item"  "Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. In Panel (a), \textit{Salary (logs)} is the log of the average salary in the team; \textit{Salary grade increase} is share of workers with a salary increase; \textit{Lateral move} is the share of workers that experience a lateral move; \textit{Cross-functional move} is the share of workers that experience a function change. In Panel (b), each outcome variable is a fractionalization index (1- Herfindahl-Hirschman index) for the relevant characteristic; it is 0 when all team members are the same and it is 1 when there is maximum team diversity. In Panel (c), each outcome variable is the share of workers that share the same characteristic with the manager (gender, age group, office, nationality)." "\end{tablenotes}")
