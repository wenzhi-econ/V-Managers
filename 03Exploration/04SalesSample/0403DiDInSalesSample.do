/* 
This do file aims to replicate Table VI in the paper.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== created in 0104 do file 
    "${TempData}/08SalesProdOutcomes.dta" <== created in 0108 do file 

Output:

RA: WWZ 
Time: 2024-11-08
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge prod data to the main event datasets 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear
merge 1:1 IDlse YearMonth using "${TempData}/08SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

save "${TempData}/temp_SalesProdOutcomes.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. generate relevant variables  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_SalesProdOutcomes.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. event-related variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! Post variables 
generate FT_Post = (FT_Rel_Time>=0) if FT_Rel_Time!=.
generate FT_LtoL_X_Post = FT_LtoL * FT_Post
generate FT_LtoH_X_Post = FT_LtoH * FT_Post

order IDlse YearMonth FT_Never_ChangeM FT_LtoL FT_LtoH FT_Post FT_LtoL_X_Post FT_LtoH_X_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. sample restrictions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if (FT_LtoL==1) | (FT_LtoH==1)
    //&? keep a panel of these two event group workers 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. regressions   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe ProductivityStd FT_Post FT_LtoH_X_Post if (LogPayBonus!=.), absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo ProductivityStd
    summarize ProductivityStd if e(sample)==1 & FT_LtoL==1
    estadd scalar Mean = r(mean)

reghdfe LogPayBonus FT_Post FT_LtoH_X_Post, absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo LogPayBonus
    summarize LogPayBonus if e(sample)==1 & FT_LtoL==1
    estadd scalar Mean = r(mean)

reghdfe TransferSJVC FT_Post FT_LtoH_X_Post if (LogPayBonus!=.), absorb(IDlse YearMonth) cluster(IDlseMHR)
    eststo TransferSJVC
    summarize TransferSJVC if e(sample)==1 & FT_LtoL==1
    estadd scalar Mean = r(mean)

label variable FT_LtoH_X_Post "LtoH - LtoL"

esttab ProductivityStd LogPayBonus TransferSJVC using "${Results}/DiDInSalesSample.tex", ///
    replace label nonotes collabels(none) ///
    keep(FT_LtoH_X_Post)  ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
    stats(Mean N r2, fmt(3 0 4) labels("Mean, LtoL" "N" "R-squared")) ///
    prehead("\begin{tabular}{l*{5}{c}} \\ \hline\hline") ///
    mtitles("Sales bonus (std)" "Pay (in logs, EUR)" "Lateral moves" "Sales bonus (in logs, INR), Movers") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Standard errors are clustered by manager. Estimates obtained by running the model in equation \ref{eq:sales}. Regression sample consists of those Indian workers who eperienced a LtoL or a LtoH event. The sales bonus is measured in Indian Rupees and standardized 0-1 (outcome mean under a low-flyer manager = INR 9,800); pay is measured in euros (outcome mean under a low-flyer manager =EUR 10,600). Controls include: worker FE and year-month FE." "\end{tablenotes}")