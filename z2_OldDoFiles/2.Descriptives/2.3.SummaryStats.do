* This dofile looks at managers of BC & WC workers 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* RELATIONSHIP BETWEEN PROMOTIONS AND PRODUCTIVITY 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
keep if _merge ==3
drop _merge 
xtset IDlse YearMonth

* probability of promotion next year 
gen fPromWLC = f.PromWLC
gen fChangeSalaryGradeC = f.ChangeSalaryGradeC 
gen fChangeSalaryGrade = f.ChangeSalaryGrade
gen lfChangeSalaryGradeC =log(fChangeSalaryGradeC+1)

* log productivity, in india productivity is all in rupees  
gen lp = log(Productivity+1)

reg LogPayBonus lp i.Year $lcontrol if ISOCode == "IND", cluster(IDlse)

collapse  ProductivityStd Productivity LogPayBonus PayBonus (max) ChangeSalaryGradeC (max) PromWLC (max)  ChangeSalaryGrade (first) ISOCode, by(IDlse Year)
xtset IDlse Year

gen fChangeSalaryGradeC = f.ChangeSalaryGradeC 
gen fPromWLC= f.PromWLC 
gen fChangeSalaryGrade= f.ChangeSalaryGrade
gen lProductivityStd= l.ProductivityStd
gen lPayBonus = log(PayBonus)
gen flPayBonus = f.lPayBonus

gen fLogPayBonus = f.LogPayBonus
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 

* probability of promotion 
gen fChangeSalaryGradeC1 = 0 if fChangeSalaryGradeC !=.
replace fChangeSalaryGradeC1 = 1 if fChangeSalaryGradeC >1 & fChangeSalaryGradeC !=.

reghdfe fChangeSalaryGradeC ProductivityStd if ISOCode == "IND", a(Year) vce(cluster IDlse)
reghdfe lPayBonus ProductivityStd if ISOCode == "IND", a(Year) vce(cluster IDlse) // 9% higher pay 

* final graph 
reg fChangeSalaryGradeC1 ProductivityStd if ISOCode == "IND"
su fChangeSalaryGradeC1 if ISOCode == "IND"
binscatter fChangeSalaryGradeC1 ProductivityStd if ISOCode == "IND", xtitle("Productivity (s.d.)") ytitle("Probability of salary grade increase,t+1") ///
text(.3 -1  "Slope = 0.08 (0.006)" ) text(.285 -1.2  "N = 6386" ) text(.27 -0.9  "Mean, prob. promotion = 0.10" ) ///
note("Notes. Increasing productivity by 0.1 s.d. is associated with a 8% higher probability of salary grade increase in the next year." ) ///
title("") ysize(8) xsize(13.5)
*Relationship between productivity and promotions
graph save "$analysis/Results/2.Descriptives/ProdPromotion.gph", replace 
graph export "$analysis/Results/2.Descriptives/ProdPromotion.png", replace 

gen Productivity1000 = Productivity/1000
reg fChangeSalaryGradeC1 Productivity if ISOCode == "IND"
reg fChangeSalaryGradeC1 Productivity1000 if ISOCode == "IND"

su fChangeSalaryGradeC1 if ISOCode == "IND"
**# ON PAPER
binscatter fChangeSalaryGradeC1 Productivity if ISOCode == "IND", xtitle("Productivity (indian rupees)", size(medium)) ytitle("Probability of salary grade increase,t+1", size(medium)) ///
title("") ysize(8) xsize(10)
*Relationship between productivity and promotions
graph save "$analysis/Results/2.Descriptives/ProdPromotionCurrency.gph", replace 
graph export "$analysis/Results/2.Descriptives/ProdPromotionCurrency.png", replace 
*text(.3 3000 "Slope = 0.02 (0.001)" ) text(.285 3000  "N = 6386" ) text(.27 3300  "Mean, prob. promotion = 0.10" ) ///

********************************************************************************
* RELATIONSHIP BETWEEN PROMOTIONS AND SALARY
********************************************************************************

use  "$managersdta/AllSnapshotMCultureMType.dta", clear

reg LogPayBonus PromWLC, cluster(IDlse)
reghdfe LogPayBonus PromWLC, cluster(IDlse) a(Country Func Year)

binscatter LogPayBonus PromWLC, line(qfit) xtitle("Number of work-level promotions") ytitle("Pay (logs)") text(12 0.5  "Slope = .77 (0.007)" ) text(11.9 0.5  "N =  4,767,313" ) title("") note("Notes. Slope coefficient obtained by controlling for country function and year fixed effects." "Standard errors clustered at the worker level.")
*Relationship between salary and promotions
graph save "$analysis/Results/2.Descriptives/PayPromotionWL.gph", replace 
graph export "$analysis/Results/2.Descriptives/PayPromotionWL.png", replace 

reg  LogPayBonus ChangeSalaryGradeC, cluster(IDlse)
reghdfe LogPayBonus ChangeSalaryGradeC, cluster(IDlse) a(Country Func Year)

**# ON PAPER
binscatter LogPayBonus ChangeSalaryGradeC, line(qfit) xtitle("Number of salary grade increases", size(medium)) ytitle("Pay (logs)", size(medium) )
*text(11.5 1.2  "Slope = .20 (0.002)" ) text(11.4 1.2  "N =  4,767,313" ) title("") 
*note("Notes. Slope coefficient obtained by controlling for country function and year fixed effects." "Standard errors clustered at the worker level.")
*Relationship between salary and promotions
graph save "$analysis/Results/2.Descriptives/PayPromotionSG.gph", replace 
graph export "$analysis/Results/2.Descriptives/PayPromotionSG.png", replace 

********************************************************************************
* SUMMARY STATS tables 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
drop if _merge ==2 
drop _merge 

* TIME REFERENCE
********************************************************************************

xtset IDlse YearMonth 
*keep if YearMonth<=tm(2020m3)

* COMPUTING NUMBERS for the table in slides: number of workers and managers 
********************************************************************************
count 
distinct IDlse 
distinct IDlse if WL==1
distinct IDlseMHR  if  IDlseMHR!=.
distinct IDlseMHR if WLM>1 & IDlseMHR!=.
distinct YearMonth 
distinct StandardJob   if StandardJob!=""
egen sfWL = group(WL SubFunc) if WL!=. & SubFunc!=.
distinct sfWL
distinct OfficeCode if OfficeCode !=.
distinct ISOCode if ISOCode !=""
egen cY = group(ISOCode Year ) if ISOCode !=""
distinct cY
egen oY = group(OfficeCode Year ) if OfficeCode !=.
distinct oY
egen iJ = group(IDlse StandardJob) if StandardJob!=""
distinct iJ 

* OUTCOME VARIABLES
********************************************************************************

gen BonusPay = Bonus/Pay

egen tM = tag(IDlseMHR)
egen tI = tag(IDlse)

gen LogP = log(Productivity + 1) if ISOCode=="IND"

foreach v in PromWLC ChangeSalaryGradeC TransferSJLLC TransferInternalLLC Tenure {
	bys IDlse: egen `v'm = max(`v')
	replace `v'm = . if tI==0 
}

label var ChangeSalaryGradeCm "Number of salary grade increases"
label var PromWLCm "Number of promotions (work-level)"
label var TransferInternalLLCm "Transfers (sub-func), lateral"
label var TransferSJLLCm "Number of lateral job transfers"
label var ChangeSalaryGradeC "Number of salary grade increases"
label var PromWLC "Prom. (work-level)"
label var TransferInternalC "Transfer (sub-func), lateral"
label var TransferInternalLLC "Transfer (sub-func), lateral"
label var TransferSJLLC "Job Change, lateral"
label var TransferFuncC "Transfer (function)"
label var LogPayBonus "Pay + bonus (logs)"
label var BonusPay "Bonus over Pay"
label var LogP "Productivity (sales in logs)"
label var VPA "Perf. appraisals"
label var LeaverPerm "Monthly Exit"
label var BonusPay "Bonus over Pay"
label var ProductivityStd "Productivity, sales (std)"

eststo clear 
**# ON PAPER
estpost su   ChangeSalaryGradeCm TransferSJLLCm PromWLCm LeaverPerm  LogPayBonus BonusPay VPA LogP , d
esttab using "$analysis/Results/2.Descriptives/suStatsOutcomes.tex", ci(3)  label nonotes cells( "mean(fmt(%9.2fc) label(Mean)) sd(fmt(%8.1fc) label(SD)) p1(fmt(%8.1fc) label(P1)) p99(fmt(%8.1fc) label(P99)) count(fmt(%9.0fc) label(N))") noobs  nomtitles  nonumbers postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-month-year. WC only. The data contain personnel records for the entire employee base from January 2011 until December 2021. ///
Salary information is only available since January 2015 and the data on performance appraisals start in January 2017. 	"\end{tablenotes}") replace 

* OTHER VARIABLES
********************************************************************************

* generate work level dummies 
replace  WL = 3 if WL >3
tab WL, gen(WL)

* generate age dummies
replace AgeBand =  1 if  AgeBand==7 //18
replace AgeBand =  4 if  AgeBand>4 & AgeBand!=. // above 50
tab AgeBand, gen(Cohort)

gen o = 1
bys IDlse: egen NoMonths = sum(o)
bys IDlse: egen ChangeMTot = sum(ChangeM)

replace TeamSize = . if tM==0 
replace NoMonths = . if tI==0 
replace ChangeMTot = . if tI==0 

* merge education 
********************************************************************************

merge m:1 IDlse using "$fulldta/EducationMax.dta", keepusing(QualHigh   FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge

* Constructing relevant variables for the table 
* EDUCATION Groups 
gen Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
label var Econ "Econ, Business, and Admin"
gen Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
label var Sci "Sci, Engin, Math, and Stat"
gen Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label var Hum "Social Sciences and Humanities"
gen Other = (Econ ==0 & Sci ==0 & Hum ==0  )  if FieldHigh1!=.
label var Other "Other Educ"
gen Missing = FieldHigh1 ==. 
label var Missing "Missing Education"

gen Bachelor =    QualHigh >=10 if QualHigh!=.
gen MBA =    QualHigh ==13 if QualHigh!=.
gen AboveSecondary = QualHigh >=6 if QualHigh!=.

global des Female Cohort1 Cohort2 Cohort3 Cohort4 Econ Sci Hum Other  Tenure WL1 WL2 WL3 NoMonths ChangeMTot TeamSize  
label var WL1 "Share in Work-level 1" 
label var WL2 "Share in Work-level 2" 
label var WL3 "Share in Work-level 3+" 
label var Cohort1 "Share in Cohort 18-29"  
label var Cohort2 "Share in Cohort 30-39"
label var Cohort3 "Share in Cohort 40-49"
label var Cohort4 "Share in Cohort 50+"
label var Tenure "Tenure (years)"
label var NoMonths "No. of months per worker"
label var TeamSize "No. of workers per supervisor"
lab var ChangeMTot "No. of supervisors per worker"

eststo clear 
**# ON PAPER
estpost su   $des   , d
esttab using "$analysis/Results/2.Descriptives/suStats.tex", ci(3)  label nonotes cells( "mean(fmt(%9.2fc) label(Mean)) sd(fmt(%8.1fc) label(SD)) p1(fmt(%8.1fc) label(P1)) p99(fmt(%8.1fc) label(P99)) count(fmt(%9.0fc) label(N))") noobs  nomtitles  nonumbers postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-month-year. WC only. The data contain personnel records for the entire employee base from January 2011 until December 2021. ///
Cohort refers to the age group and work level denotes the hierarchical tier (from level 1 at the bottom to level 6)."\end{tablenotes}") replace 

********************************************************************************
* Salary increase when promoted to HIGHER work level   
********************************************************************************

use  "$managersdta/AllSnapshotMCultureMType.dta", clear
xtset IDlse YearMonth 

* Determine the earnings ration wrt to WL1, using UK where the HQs are 
use "$managersdta/AllSnapshotMCulture.dta", clear 

* A) WL
* Salary approximately doubles at each work level increase
bys WL: su PayBonus if ISOCode =="GBR" ,d 
di  (72712) / 43692 // 1.7
di  (174367 ) / 43692 // 4 
di  (338788 ) / 43692 // 8 
di  (849750 ) / 43692 // 20
di  (1855282) / 43692 // 43

* B) SALARY GRADE 
decode  SalaryGrade, gen(SalaryGradeS)
su PayBonus if SalaryGradeS =="2A" & ISOCode =="GBR", d
su PayBonus if SalaryGradeS =="2B" & ISOCode =="GBR", d
su PayBonus if SalaryGradeS =="2C" & ISOCode =="GBR",d
su PayBonus if WL==3 & ISOCode =="GBR",d

su PayBonus if SalaryGradeS =="1A" & ISOCode =="GBR", d
su PayBonus if SalaryGradeS =="1B" & ISOCode =="GBR", d
su PayBonus if SalaryGradeS =="1C" & ISOCode =="GBR",d

* salary increases by 20-30% within WL

********************************************************************************
* Need to understand how HIRING works - UFLP and mid career hiring
* PORTS OF ENTRY  
********************************************************************************

use  "$managersdta/AllSnapshotMCultureMType.dta", clear

bys IDlse: egen maxUFLP = max(UFLPStatus) // was worker ever UFLP? 
gen NewHire = Tenure<1 // NEW HIRE 
egen iitag= tag(IDlse NewHire) // unique IDlse 
ta  maxUFLP  if NewHire==1 & iitag==1 // how many of new hires are UFLP? 5% of obs 
 ta UFLPStatus if AgeBand==1
ta AgeBand if UFLPStatus==1 // UFLP, 94% under 30 

ta WL if Tenure>=1
ta WL if Tenure<1
bys IDlse: egen TenureMin = min(Tenure) // define min tenure for each individuals 
egen tt = tag(IDlse)
gen NewHire = Tenure ==0 
ta WL if TenureMin ==0 & tt==1 // over the 10 years, what is the entry WL of new hires? 92% of workers are hired at WL1, then 7% hired at WL2 and the remaining 1% split WL3+ 
keep if TenureMin <1 & Tenure==TenureMin

ta AgeBand WL // there are people hired at WL1 event if at 40 years old 
ta NewHire WL , row // given I am new hire, what is entry WL? for 93% it is WL1 and then 6% in WL2 and then rest is WL3+ 
ta WL // in contrast the employee base is 81% WL1 and 15% in WL2 and then 3% in WL3 and remaining 1% in WL4+ 
ta WL  NewHire  , row // given I am in a given WL, how many are new hires? 
* WL1: 13% NEW HIRES 
* WL2: 4% NEW HIRES 
* WL3: 3% NEW HIRES 
* WL4: 2% NEW HIRES 
* WL5: 2% NEW HIRES 

graph bar WL, over(NewHire )
* Mean of outcomes 

use  "$managersdta/AllSnapshotMCultureMType.dta", clear

su PromWLC 
su PromWLC if insample==1

su LeaverPerm
su LeaverPerm if insample==1

su TransferInternalSJC 
su TransferInternalSJC if insample==1

su TransferInternalSJLC 
su TransferInternalSJLC if insample==1

su TransferInternalSJLLC 
su TransferInternalSJLLC if insample==1

su TransferInternalSJSameMLLC 
su TransferInternalSJSameMLLC if insample==1

su TransferInternalSJDiffMLLC 
su TransferInternalSJDiffMLLC if insample==1

********************************************************************************
* Need to understand how FIRING works
* PORTS OF EXIT  
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

keep if EmpType ==7  // regular worker 
drop  WLAgg
gen WLAgg = WL 
replace WLAgg = 4 if WL>=4 & WL!=.

preserve
*keep if ISOCode == "USA"
gcollapse (max) LeaverPerm WLAgg, by(Year IDlse)

su LeaverPerm if Year==2017 
su LeaverPerm if Year==2018
su LeaverPerm if Year==2019 // slightly less than 15% 

label define WL 1 "WL1" 2 "WL2" 3 "WL3" 4 "WL4+"
label value  WLAgg WL
graph bar  LeaverPerm if Year==2019 , over(WLAgg)  ytitle("Annual Exit Rate, 2019", size(medlarge)) b1title("Work level", size(medlarge)) scheme(white_hue)
graph save "$analysis/Results/2.Descriptives/PortsExit.gph", replace 
graph export "$analysis/Results/2.Descriptives/PortsExit.png", replace 
restore 

********************************************************************************
* How many promotions involve changing manager  
********************************************************************************

use  "$managersdta/AllSnapshotMCultureMType.dta", clear
ta PromWL ChangeM , row // 63%
ta ChangeSalaryGrade ChangeM , row // 38%
ta TransferInternal ChangeM , row // 32%

********************************************************************************
* AGE DISTRIBUTIONS AND MEDIAN 
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 

su TenureM if FemaleM==1
su TenureM if FemaleM==0

* women
graph twoway (function y=normalden(x,40,8), range(18 78) lw(medthick) lcolor(green)) , xline(20) xline(30) xline(40, lcolor(lavender)) xline(50, lcolor(lavender)) xline(60, lcolor(blue))  xline(70, lcolor(blue)) xtitle(Age) title(Women) xlabel(18(2)78)  

* men 
graph twoway (function y=normalden(x,42,9), range(18 75) lw(medthick)  lcolor(pink) ) , xline(20) xline(30) xline(40, lcolor(lavender)) xline(50, lcolor(lavender)) xline(60, lcolor(blue))  xline(70, lcolor(blue)) xtitle(Age) title(Men) xlabel(18(2)78) 

* median for 20-29
di invnormal((normal(((29-40)/8)) - normal(((20-40)/8 )) )/2 + normal(((20-40)/8 )) )*8 + 40 //  26
di invnormal((normal(((29-42)/9)) - normal(((20-42)/9 )) )/2 + normal(((20-42)/9 )) )*9 + 42 //  26

* median for 30-39
di invnormal((normal(((39-40)/8)) - normal(((30-40)/8 )) )/2 + normal(((30-40)/8 )))*8 + 40 //  35
di invnormal((normal(((39-42)/9)) - normal(((30-42)/9 )) )/2 + normal(((30-42)/9 )) )*9 + 42 //  35

* median for 40-49
di invnormal( (normal(((49-40)/8)) - normal(((40-40)/8 )) )/2 + normal(((40-40)/8 )) )*8 + 40  //  44
di invnormal(  (normal(((49-42)/9)) - normal(((40-42)/9 )) )/2 + normal(((40-42)/8 ))    )*9 + 42 //  44

* median for 50-59
di invnormal(  (normal(((59-40)/8)) - normal(((50-40)/8 )) )/2 + normal(((50-40)/8 )))  *8 + 40 //  53
di invnormal((normal(((59-42)/9)) - normal(((50-42)/9 )) )/2 + normal(((50-42)/9 )) ) *9 + 42 // 53

* median for 60-69
di invnormal( (normal(((69-40)/8)) - normal(((60-40)/8 )) )/2 + normal(((60-40)/8 ))  )  *8 + 40 //  62
di invnormal((normal(((69-42)/9)) - normal(((60-42)/9 )) )/2 + normal(((60-42)/9 ))  ) *9 + 42 // 62

********************************************************************************
* ARE THERE BC WORKERS EVER PROMOTED TO WC?  
********************************************************************************

use "$fulldta/AllSnapshot.dta", clear 

gen WC = 1 - BC
bys IDlse: egen everWC = max(WC)
bys IDlse: egen everBC = max(BC)
bys IDlse: egen maxWL = max(WL)
egen tt = tag(IDlse)

ta everWC if everBC==1 & tt==1 // 15% of BC workers become WC 
ta maxWL if everBC==1 & tt==1  // all of them are WL1 


