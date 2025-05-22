
/* 
This do file runs regressions for endogenous mobility checks on the team-level dataset.

Notes on the regressions:
    (1) The regression sample consists of teams who experienced manager change in relative period [-36, -6], with the restrictions listed in (2) and (3).
    (2) The team contains more than 1 worker, and both the pre- and post-event managers are of WL2.
    (3) The worker does not have a simultaneous internal or lateral move.

Input: 
    "${TempData}/0106TeamLevelEventsAndOutcomes.dta" <== created in 0106 do file

Output:
    

RA: WWZ 
Time: 2025-05-20
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. preparations for regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0106TeamLevelEventsAndOutcomes_WithTransferSJL.dta", clear 


generate lAvPay = log(AvPay)

global perf  lAvPay                ShareChangeSalaryGrade ShareTransferSJL    ShareTransferFunc
global div   TeamFracFemale        TeamFracAgeBand        TeamFracOfficeCode  TeamFracCountry
global homo  ShareSameGender       ShareSameAge           ShareSameOffice     ShareSameNationality  

label variable lAvPay                 "Salary (logs)"
label variable ShareChangeSalaryGrade "Salary grade increase"
label variable ShareTransferSJL       "Lateral move"
label variable ShareTransferFunc      "Cross-functional move"

label variable TeamFracFemale         "Diversity, gender"
label variable TeamFracAgeBand        "Diversity, age"
label variable TeamFracOfficeCode     "Diversity, office"
label variable TeamFracCountry        "Diversity, nationality"

label variable ShareSameGender        "Same gender"
label variable ShareSameAge           "Same age"
label variable ShareSameOffice        "Same office"
label variable ShareSameNationality   "Same nationality" 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global controls FuncM ISOCodeM Year

local i = 1
foreach y in  $perf $div $homo {
	
    reghdfe `y' CA30_LtoH CA30_HtoH CA30_HtoL if spanM>1 & inrange(Rel_Time, -24, -1), cluster(IDlseMHRPreMost) absorb($controls)
        local r_squared = e(r2)
        summarize `y' if e(sample)==1 & CA30_LtoL==1
            local cmean = r(mean)
        xlincom (CA30_LtoH) (CA30_HtoL-CA30_HtoH), post
            eststo reg`i'
            estadd scalar mean_LtoL = `cmean'
            estadd scalar r_squared = `r_squared'

    local i = `i' +1
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: produce the table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_file         "${Results}/004ResultsBasedOnCA30/CA30_EndogenousMobilityChecks_FullTransition_Pre24toPre1_TransferSJL.tex"

esttab reg1 reg2 reg3 reg4 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    keep(lc_1 lc_2) order(lc_1 lc_2) varlabels(lc_1 "LtoH - LtoL" lc_2 "HtoL - HtoH") ///
    stats(mean_LtoL r_squared N, labels("\hline Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "\multicolumn{5}{c}{\textit{Panel (a): team performance}} \\ [7pt]" "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)}  & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} \\" "& \multicolumn{1}{c}{Salary (logs)} & \multicolumn{1}{c}{Salary grade increase}  & \multicolumn{1}{c}{Lateral move} & \multicolumn{1}{c}{Cross-functional move} \\") ///
    posthead("\midrule") ///
    prefoot("")  ///
    postfoot("\midrule")

esttab reg5 reg6 reg7 reg8 using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    keep(lc_1 lc_2) order(lc_1 lc_2) varlabels(lc_1 "LtoH - LtoL" lc_2 "HtoL - HtoH") ///
    stats(mean_LtoL r_squared N, labels("\hline Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\multicolumn{5}{c}{\textit{Panel (b): team diversity}} \\ [7pt]") ///
    posthead("& \multicolumn{1}{c}{Diversity, gender} & \multicolumn{1}{c}{Diversity, age}  & \multicolumn{1}{c}{Diversity, office} & \multicolumn{1}{c}{Diversity, nationality} \\" "\midrule") ///
    prefoot("")  ///
    postfoot("\midrule")

esttab reg9 reg10 reg11 reg12 using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    keep(lc_1 lc_2) order(lc_1 lc_2) varlabels(lc_1 "LtoH - LtoL" lc_2 "HtoL - HtoH") ///
    stats(mean_LtoL r_squared N, labels("\hline Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\multicolumn{5}{c}{\textit{Panel (c): team homophily with manager}} \\ [7pt]") ///
    posthead("& \multicolumn{1}{c}{Same gender} & \multicolumn{1}{c}{Same age}  & \multicolumn{1}{c}{Same office} & \multicolumn{1}{c}{Same nationality} \\" "\midrule") ///
    prefoot("") ///
    postfoot("\midrule" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item"  "Notes. An observation is a team-month. Sample restricted to observations between 1 and 24 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. In Panel (a), \textit{Salary (logs)} is the log of the average salary in the team; \textit{Salary grade increase} is share of workers with a salary increase; \textit{Lateral move} is the share of workers that experience a lateral move; \textit{Cross-functional move} is the share of workers that experience a function change. In Panel (b), each outcome variable is a fractionalization index (1- Herfindahl-Hirschman index) for the relevant characteristic; it is 0 when all team members are the same and it is 1 when there is maximum team diversity. In Panel (c), each outcome variable is the share of workers that share the same characteristic with the manager (gender, age group, office, nationality)." "\end{tablenotes}")
