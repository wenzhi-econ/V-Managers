/* 
This do file plots the distribution of pay, the correlation between sales bonus and probability of salary grade increase, and the correlation between pay and salary grade increases.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 

Results:
    "${Results}/DistributionOfStdOfPayBonus.pdf"
    "${Results}/CorrBetweenPayAndSalaryGradeIncrease.pdf"
    "${Results}/CorrBetweenProdAndSalaryGradeIncrease.pdf"

RA: WWZ 
Time: 2024-12-06
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. distribution of sd of PayBonus
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

bysort Office StandardJob YearMonth: egen PayBonusSD = sd(PayBonus)
egen OfficeJobYM_tag = tag(Office StandardJob YearMonth)

winsor2 PayBonusSD, suffix(T) cuts(5 95) trim
summarize PayBonusSDT, detail
    global median = r(p50)

histogram PayBonusSDT if OfficeJobYM_tag==1, ///
    frac bcolor(ebblue) lcolor(none) ///
    ytitle("Fraction", size(medsmall)) ylabel(, grid gstyle(dot)) ///
    xline(${median}, lcolor(red)) text(0.044 ${median} "Median") ///
    xtitle("Standard deviation of annual pay (euros) within job-office-month", size(medsmall)) title("")

graph export "${Results}/DistributionOfStdOfPayBonus.pdf", as(pdf) replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. pay and salary grade increases
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

binscatter LogPayBonus ChangeSalaryGradeC ///
    , line(qfit) mcolors(ebblue) lcolors(red) ///
    xtitle("Number of salary grade increases", size(medium)) ///
    ytitle("Pay (logs)", size(medium)) ylabel(, grid gstyle(dot))

graph export "${Results}/CorrBetweenPayAndSalaryGradeIncrease.pdf", as(pdf) replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. correlation between sales bonus and salary grade increases
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

*-? get productivity data 
merge 1:1 IDlse YearMonth using "${TempData}/05SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

*-? collapse into individual-year level 
generate Year = year(dofm(YearMonth))
collapse (mean) ProductivityStd Productivity (max) ChangeSalaryGradeC (first) ISOCode, by(IDlse Year)

*-? plotting 
binscatter ChangeSalaryGradeC ProductivityStd ///
    , xtitle("Sales bonus (normalized)", size(medlarge)) ///
    ytitle("Number of salary grade increases", size(medlarge)) ylabel(, grid gstyle(dot)) ///
    mcolors(ebblue) lcolors(red) ///
    title("") xsize(5) ysize(4)

graph export "${Results}/CorrBetweenProdAndSalaryGradeIncrease.pdf", as(pdf) replace