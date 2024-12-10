/* 
This do file compares different treatment group share across different event-time jobs/functions/subfunctions.

RA: WWZ 
Time: 2024-12-06
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. across different jobs 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear
keep if FT_Rel_Time==0 & FT_Mngr_both_WL2==1
    //&? a cross-section of event workers (at the event date)
    //&? 29,610 different event workers

generate one = 1
bysort StandardJob: egen num_workers_LtoL = total(FT_LtoL)
bysort StandardJob: egen num_workers_LtoH = total(FT_LtoH)
bysort StandardJob: egen num_workers_HtoH = total(FT_HtoH)
bysort StandardJob: egen num_workers_HtoL = total(FT_HtoL)
bysort StandardJob: egen num_workers      = total(one)

generate share_LtoL = num_workers_LtoL / num_workers
generate share_LtoH = num_workers_LtoH / num_workers
generate share_HtoH = num_workers_HtoH / num_workers
generate share_HtoL = num_workers_HtoL / num_workers

keep  StandardJob num_workers share_LtoL share_LtoH share_HtoH share_HtoL num_workers_*
order StandardJob num_workers share_LtoL share_LtoH share_HtoH share_HtoL num_workers_*
duplicates drop 
gsort -num_workers

summarize num_workers, detail 

egen StandardJob_id = group(StandardJob)

twoway ///
    (scatter share_LtoL StandardJob_id [weight=num_workers] if num_workers>=40, msymbol(Oh) mcolor(navy)) ///
    (scatter share_LtoH StandardJob_id [weight=num_workers] if num_workers>=40, msymbol(Th) mcolor(maroon)) ///
    , legend(label(1 "LtoL") label(2 "LtoH")) ///
    xtitle("Standard job", size(medsmall)) xscale(range(0 700)) xlabel(none) ///
    ytitle("Share", size(medsmall))

graph export "${Results}/ShareTreatmentGroups_AcrossJobs_40.pdf", replace as(pdf)

twoway ///
    (scatter share_LtoL StandardJob_id [weight=num_workers], msymbol(Oh) mcolor(navy)) ///
    (scatter share_LtoH StandardJob_id [weight=num_workers], msymbol(Th) mcolor(maroon)) ///
    , legend(label(1 "LtoL") label(2 "LtoH")) ///
    xtitle("Standard job", size(medsmall)) xscale(range(0 700)) xlabel(none) ///
    ytitle("Share", size(medsmall))

graph export "${Results}/ShareTreatmentGroups_AcrossJobs.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. across different subfunctions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear
keep if FT_Rel_Time==0 & FT_Mngr_both_WL2==1
    //&? a cross-section of event workers (at the event date)
    //&? 29,610 different event workers

generate one = 1
bysort SubFunc: egen num_workers_LtoL = total(FT_LtoL)
bysort SubFunc: egen num_workers_LtoH = total(FT_LtoH)
bysort SubFunc: egen num_workers_HtoH = total(FT_HtoH)
bysort SubFunc: egen num_workers_HtoL = total(FT_HtoL)
bysort SubFunc: egen num_workers      = total(one)

generate share_LtoL = num_workers_LtoL / num_workers
generate share_LtoH = num_workers_LtoH / num_workers
generate share_HtoH = num_workers_HtoH / num_workers
generate share_HtoL = num_workers_HtoL / num_workers

keep  SubFunc num_workers share_LtoL share_LtoH share_HtoH share_HtoL num_workers_*
order SubFunc num_workers share_LtoL share_LtoH share_HtoH share_HtoL num_workers_*
duplicates drop 
gsort -num_workers

summarize num_workers, detail 
/* 
                         num_workers
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            2              1       Obs                  95
25%           11              1       Sum of wgt.          95

50%           47                      Mean           311.6842
                        Largest       Std. dev.      805.4609
75%          324           1615
90%          883           2248       Variance       648767.2
95%         1254           2314       Skewness       6.096652
99%         6847           6847       Kurtosis       47.50451
*/

egen SubFunc_id = group(SubFunc)

twoway ///
    (scatter share_LtoL SubFunc_id [weight=num_workers], msymbol(Oh) mcolor(navy)) ///
    (scatter share_LtoH SubFunc_id [weight=num_workers], msymbol(Th) mcolor(maroon)) ///
    , legend(label(1 "LtoL") label(2 "LtoH")) ///
    xtitle("Subfunction", size(medsmall)) xscale(range(0 100)) xlabel(none) ///
    ytitle("Share", size(medsmall))

graph export "${Results}/ShareTreatmentGroups_AcrossSubfuncs.pdf", replace as(pdf)


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. across different functions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear
keep if FT_Rel_Time==0 & FT_Mngr_both_WL2==1
    //&? a cross-section of event workers (at the event date)
    //&? 29,610 different event workers

generate one = 1
bysort Func: egen num_workers_LtoL = total(FT_LtoL)
bysort Func: egen num_workers_LtoH = total(FT_LtoH)
bysort Func: egen num_workers_HtoH = total(FT_HtoH)
bysort Func: egen num_workers_HtoL = total(FT_HtoL)
bysort Func: egen num_workers      = total(one)

generate share_LtoL = num_workers_LtoL / num_workers
generate share_LtoH = num_workers_LtoH / num_workers
generate share_HtoH = num_workers_HtoH / num_workers
generate share_HtoL = num_workers_HtoL / num_workers

keep  Func num_workers share_LtoL share_LtoH share_HtoH share_HtoL num_workers_*
order Func num_workers share_LtoL share_LtoH share_HtoH share_HtoL num_workers_*
duplicates drop 
gsort -num_workers

summarize num_workers, detail 
/* 
                         num_workers
-------------------------------------------------------------
      Percentiles      Smallest
 1%            4              4
 5%            4              5
10%            5              8       Obs                  16
25%           17             12       Sum of wgt.          16

50%        193.5                      Mean           1850.625
                        Largest       Std. dev.      3077.234
75%       3062.5           3096
90%         7279           3241       Variance        9469366
95%        10622           7279       Skewness       1.860041
99%        10622          10622       Kurtosis       5.465155
*/


label define Func_titles ///
    1 "Audit" ///
    2 "Communications" ///
    3 "Customer Development" ///
    4 "Finance" ///
    5 "General Management" ///
    6 "Human Resources" ///
    7 "Information Technology" ///
    8 "Legal" ///
    9 "Marketing" ///
    10 "Research/Development" ///
    11 "Supply Chain" ///
    12 "Workplace Services" ///
    13 "UNKNW" ///
    14 "Information and Analytics" ///
    15 "Project Management" ///
    16 "Operations" ///
    17 "Data and Analytics" ///
    18 "Data & Analytics"

label values Func Func_titles

twoway ///
    (scatter share_LtoL Func [weight=num_workers], msymbol(Oh) mcolor(navy)) ///
    (scatter share_LtoH Func [weight=num_workers], msymbol(Th) mcolor(maroon)) ///
    , legend(label(1 "LtoL") label(2 "LtoH")) ///
    xtitle("Function", size(medsmall)) ///
    ytitle("Share", size(medsmall))

graph export "${Results}/ShareTreatmentGroups_AcrossFuncs.pdf", replace as(pdf)


graph hbar share_LtoL share_LtoH share_HtoH share_HtoL if num_workers>=50 ///
    , over(Func) stack percentages asyvars ///
    legend(label(1 "LtoL") label(2 "LtoH") label(3 "HtoH") label(4 "HtoL")) ///
    ytitle("Share", size(medsmall)) 

graph export "${Results}/ShareTreatmentGroups_AcrossFuncs_Bar.pdf", replace as(pdf)
