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
*?? step 2. seemingly unrelated regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. run regressions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture noisily {
    sureg (Skills_Project = EarlyAgeM) (Skills_Strategy = EarlyAgeM) (Skills_Talent = EarlyAgeM)
}
    //&? multicollinearity issue 

sureg (Skills_Strategy = EarlyAgeM) (Skills_Talent = EarlyAgeM)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. store the results
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! topic index 
generate topic = _n if inrange(_n, 1, 3)

*!! coefficients
generate coeff_SUR = _b["Skills_Strategy:EarlyAgeM"] if _n ==2 
replace  coeff_SUR = _b["Skills_Talent:EarlyAgeM"]   if _n ==3

*!! lower bound 
generate lb_SUR = _b["Skills_Strategy:EarlyAgeM"] - 1.96 * _se["Skills_Strategy:EarlyAgeM"] if _n ==2 
replace  lb_SUR = _b["Skills_Talent:EarlyAgeM"]   - 1.96 * _se["Skills_Talent:EarlyAgeM"]   if _n ==3

*!! upper bound 
generate ub_SUR = _b["Skills_Strategy:EarlyAgeM"] + 1.96 * _se["Skills_Strategy:EarlyAgeM"] if _n ==2 
replace  ub_SUR = _b["Skills_Talent:EarlyAgeM"]   + 1.96 * _se["Skills_Talent:EarlyAgeM"]   if _n ==3

graph twoway ///
    (bar coeff_SUR topic if inrange(topic, 2, 3), bfcolor(ebblue) barw(0.4)) ///
    (rcap ub_SUR lb_SUR topic if inrange(topic, 2, 3), lcolor(red) lwidth(medthick)) ///
    , legend(off) /// 
    xlabel(2 "Strategy skills" 3 "Talent skills", labsize(large)) ///
    xscale(range(1.5 3.5)) ylabel(, grid gstyle(dot)) ///
    title("Mean difference between H and L-type managers", span pos(12)) xtitle("")

graph export "${Results}/SkillsAfterLDA_HvsL_SUR.pdf", replace as(pdf)
