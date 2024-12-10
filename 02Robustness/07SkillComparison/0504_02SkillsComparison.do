/* 
This do file gets the HF measure for each individual, so that they can be merged with the skills data in the next step to contrast different skills by H-type managers and L-type managers.

Input:
    "${TempData}/02Mngr_EarlyAgeM.dta" <== constructed in 0102_01 do file
    "${TempData}/temp_SkillsAfterLDA.dta" <== constructed in "0504_01SkillsDescriptionLDA.py"

Results:
    "${Results}/SkillsAfterLDA_HvsL.pdf"
    "${Results}/SkillsAfterLDA_HvsL_Robust.pdf"
    "${Results}/SkillsAfterLDA_HvsL_SUR.pdf"

RA: WWZ 
Time: 2024-10-17
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge managers' quality measure and topic distribution after LDA
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-? managers' quality measure 
use "${TempData}/02Mngr_EarlyAgeM.dta", clear 
keep IDlseMHR EarlyAgeM
rename IDlseMHR IDlse
duplicates drop 

*-? managers' topic distribution after LDA
merge 1:1 IDlse using "${TempData}/temp_SkillsAfterLDA.dta", keep(match) nogenerate

*-? assign names to each topic 
label variable Topic1_3 "Project management skills"
label variable Topic2_3 "Strategy management skills"
label variable Topic3_3 "Talent management skills"

rename Topic1_3 Skills_Project 
rename Topic2_3 Skills_Strategy 
rename Topic3_3 Skills_Talent 

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
*?? step 3. naive simple regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate topic = _n if inrange(_n, 1, 3)

matrix coeff_mat = J(3, 1, .)
matrix lb_mat    = J(3, 1, .)
matrix ub_mat    = J(3, 1, .)

regress Skills_Project EarlyAgeM
    lincom EarlyAgeM
    matrix coeff_mat[1,1] = r(estimate)
    matrix lb_mat[1,1] = r(lb)
    matrix ub_mat[1,1] = r(ub)

regress Skills_Strategy EarlyAgeM
    lincom EarlyAgeM
    matrix coeff_mat[2,1] = r(estimate)
    matrix lb_mat[2,1] = r(lb)
    matrix ub_mat[2,1] = r(ub)

regress Skills_Talent EarlyAgeM
    lincom EarlyAgeM
    matrix coeff_mat[3,1] = r(estimate)
    matrix lb_mat[3,1] = r(lb)
    matrix ub_mat[3,1] = r(ub)

matrix final_res = coeff_mat, lb_mat, ub_mat
matrix colnames final_res = coeff lb ub
svmat  final_res, names(col)

twoway ///
    (rbar ub lb topic, bcolor(ebblue) barwidth(0.03) vertical) ///
    (scatter coeff topic, lcolor(ebblue) mcolor(white) mfcolor(white) msymbol(D) msize(0.9)) ///
    , yline(0, lcolor(maroon)) ///
    xlabel(1 "Project skills" 2 "Strategy skills" 3 "Talent skills", labsize(large)) xscale(range(0.5 3.5)) ///
    title("Mean difference between H and L-type managers", span pos(12)) xtitle("") ///
    legend(off)
graph export "${Results}/SkillsAfterLDA_HvsL.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. regressions using robust standard errors 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

matrix coeff_mat = J(3, 1, .)
matrix lb_mat    = J(3, 1, .)
matrix ub_mat    = J(3, 1, .)

regress Skills_Project EarlyAgeM, robust
    lincom EarlyAgeM
    matrix coeff_mat[1,1] = r(estimate)
    matrix lb_mat[1,1] = r(lb)
    matrix ub_mat[1,1] = r(ub)

regress Skills_Strategy EarlyAgeM, robust
    lincom EarlyAgeM
    matrix coeff_mat[2,1] = r(estimate)
    matrix lb_mat[2,1] = r(lb)
    matrix ub_mat[2,1] = r(ub)

regress Skills_Talent EarlyAgeM, robust
    lincom EarlyAgeM
    matrix coeff_mat[3,1] = r(estimate)
    matrix lb_mat[3,1] = r(lb)
    matrix ub_mat[3,1] = r(ub)

matrix final_res = coeff_mat, lb_mat, ub_mat
matrix colnames final_res = coeff_Robust lb_Robust ub_Robust
svmat  final_res, names(col)

twoway ///
    (rbar ub_Robust lb_Robust topic, bcolor(ebblue) barwidth(0.03) vertical) ///
    (scatter coeff_Robust topic, lcolor(ebblue) mcolor(white) mfcolor(white) msymbol(D) msize(0.9)) ///
    , yline(0, lcolor(maroon)) ///
    xlabel(1 "Project skills" 2 "Strategy skills" 3 "Talent skills", labsize(large)) xscale(range(0.5 3.5)) ///
    title("Mean difference between H and L-type managers", span pos(12)) xtitle("") ///
    legend(off)
graph export "${Results}/SkillsAfterLDA_HvsL_Robust.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5.  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
capture noisily {
    sureg (Skills_Project = EarlyAgeM) (Skills_Strategy = EarlyAgeM) (Skills_Talent = EarlyAgeM)
}
    //&? multicollinearity issue 

sureg (Skills_Strategy = EarlyAgeM) (Skills_Talent = EarlyAgeM)

di _b["Skills_Strategy:EarlyAgeM"] - 1.96 * _se["Skills_Strategy:EarlyAgeM"]
di _b["Skills_Strategy:EarlyAgeM"] + 1.96 * _se["Skills_Strategy:EarlyAgeM"]

di _b["Skills_Talent:EarlyAgeM"] - 1.96 * _se["Skills_Talent:EarlyAgeM"]
di _b["Skills_Talent:EarlyAgeM"] + 1.96 * _se["Skills_Talent:EarlyAgeM"]

generate coeff_SUR = _b["Skills_Strategy:EarlyAgeM"] if _n ==2 
replace  coeff_SUR = _b["Skills_Talent:EarlyAgeM"]   if _n ==3

generate lb_SUR = _b["Skills_Strategy:EarlyAgeM"] - 1.96 * _se["Skills_Strategy:EarlyAgeM"] if _n ==2 
replace  lb_SUR = _b["Skills_Talent:EarlyAgeM"]   - 1.96 * _se["Skills_Talent:EarlyAgeM"]   if _n ==3

generate ub_SUR = _b["Skills_Strategy:EarlyAgeM"] + 1.96 * _se["Skills_Strategy:EarlyAgeM"] if _n ==2 
replace  ub_SUR = _b["Skills_Talent:EarlyAgeM"]   + 1.96 * _se["Skills_Talent:EarlyAgeM"]   if _n ==3

twoway ///
    (rbar ub_SUR lb_SUR topic if inrange(topic, 2, 3), bcolor(ebblue) barwidth(0.03) vertical) ///
    (scatter coeff_SUR topic if inrange(topic, 2, 3), lcolor(ebblue) mcolor(white) mfcolor(white) msymbol(D) msize(0.9)) ///
    , yline(0, lcolor(maroon)) /// 
    xlabel(2 "Strategy skills" 3 "Talent skills", labsize(large)) ///
    xscale(range(1.5 3.5)) ///
    title("Mean difference between H and L-type managers", span pos(12)) xtitle("") ///
    legend(off)
graph export "${Results}/SkillsAfterLDA_HvsL_SUR.pdf", replace as(pdf)
