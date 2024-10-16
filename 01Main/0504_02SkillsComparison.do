/* 
This do file gets the HF measure for each individual, so that they can be merged with the skills data in the next step to contrast different skills by H-type managers and L-type managers.

Input:
    "${FinalData}/AllSnapshotMCulture.dta"

Output:
    "${TempData}/temp_HFMeasure.dta"

RA: WWZ 
Time: 2024-09-22
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge managers' quality measure and topic distribution after LDA
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-? managers' quality measure 
use "${TempData}/temp_Mngr_EarlyAgeM.dta", clear 
keep IDlseMHR EarlyAgeM
rename IDlseMHR IDlse
duplicates drop 

*-? managers' topic distribution after LDA
merge 1:1 IDlse using "${TempData}/temp_SkillsAfterLDA.dta", keep(match) nogenerate

*-? assign names to each topic 
label variable Topic1_3 "Project management skills"
label variable Topic2_3 "Strategy management skills"
label variable Topic3_3 "Talent management skills"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. compare results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
/* 
balancetable (mean if EarlyAgeM == 0) (mean if EarlyAgeM == 1) (diff EarlyAgeM if EarlyAgeM != .) Topic1_3 Topic2_3 Topic3_3 using "${Results}/SkillsAfterLDA_HvsL.tex", ///
    replace nonumbers nohead varlabels vce(robust) ///
    prehead("\begin{tabular}{l*{3}c}" "\hline\hline \\ [-1.5ex]" "\hline" "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "& \multicolumn{1}{c}{L-type} & \multicolumn{1}{c}{H-type} & \multicolumn{1}{c}{Difference} \\""\hline" ) ///
    posthead("") ///
    postfoot("\hline\hline \end{tabular}") */


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. generate results using a figure 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
matrix coeff_mat = J(3, 1, .)
matrix lb_mat    = J(3, 1, .)
matrix ub_mat    = J(3, 1, .)

regress Topic1_3 EarlyAgeM
    lincom EarlyAgeM
    matrix coeff_mat[1,1] = r(estimate)
    matrix lb_mat[1,1] = r(lb)
    matrix ub_mat[1,1] = r(ub)

regress Topic2_3 EarlyAgeM
    lincom EarlyAgeM
    matrix coeff_mat[2,1] = r(estimate)
    matrix lb_mat[2,1] = r(lb)
    matrix ub_mat[2,1] = r(ub)

regress Topic3_3 EarlyAgeM
    lincom EarlyAgeM
    matrix coeff_mat[3,1] = r(estimate)
    matrix lb_mat[3,1] = r(lb)
    matrix ub_mat[3,1] = r(ub)


matrix final_res = coeff_mat, lb_mat, ub_mat
matrix colnames final_res = coeff lb ub
svmat  final_res, names(col)

generate topic = _n if inrange(_n, 1, 3)

twoway ///
    (scatter coeff topic, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb ub topic, lcolor(ebblue)) ///
    , yline(0, lcolor(maroon)) ///
    xlabel(1 "     Project skills" 2 "Strategy skills" 3 "Talent skills     ") ///
    xtitle("Skills given by LDA", size(medium)) title("Mean difference between H and L-type managers", span pos(12)) ///
    legend(off)
graph export "${Results}/SkillsAfterLDA_HvsL.pdf", replace as(pdf)




