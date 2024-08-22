********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* High fliers BALANCE TABLES 
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 

ta ISOCodeM if ProductivityStdM!=. & EarlyAgeM !=. // note that there are only 2 managers with Indian data, so cannot assess this correlation 

* education variable 
merge m:1 IDlseMHR  using "$fulldta/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge 

* in rotation 
merge m:1 IDlseMHR using "$managersdta/Temp/m2.dta", keepusing( mT HF) // created in 2.4.MTypeRotation.do 
drop _merge 

*UFLP status 
gen IDlse = IDlseMHR
merge 1:1 IDlse YearMonth using "$managersdta/AllSnapshotMCultureMType.dta", keepusing(FlagUFLP )
drop if _merge ==2
ta _merge // 99% are matched 
drop _merge 
rename FlagUFLP FlagUFLPM
drop IDlse  

merge m:1 IDlseMHR using  "$managersdta/Temp/MFEBayesPay.dta" , keepusing(MFEBayesLogPay MFEBayesLogPay75 MFEBayesLogPay50)
drop if _merge ==2
drop _merge

* manager type 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2015.dta", keepusing(MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50)
drop if _merge ==2
drop _merge

rename (MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50) =v2014

merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesLogPayF6075 MFEBayesLogPayF6050 MFEBayesLogPayF7275 MFEBayesLogPayF7250 MFEBayesLogPayF72 MFEBayesLogPayF60)
drop if _merge ==2
drop _merge

* get ex-post performance of the manager 
gen IDlse = IDlseMHR // for the merging below
merge m:1 IDlse YearMonth using "$managersdta/Temp/PromExitRes.dta", keepusing(TransferSJC TransferFuncC TransferInternalC PromWLC ChangeSalaryGradeC)
drop if _merge ==2
drop _merge
drop IDlse  

* correlation btw High Flyer manager and MFEBayesPromSG75
********************************************************************************

egen oo = tag(IDlseMHR)

reg EarlyAgeM MFEBayesPromSG75 if oo==1, robust 
reghdfe EarlyAgeM  MFEBayesPromSG75   if oo==1, cluster(IDlseMHR)  a(ISOCodeM WLM AgeBandM)

reg EarlyAgeM MFEBayesLogPayF6075 if oo==1, robust 
reghdfe EarlyAgeM  MFEBayesLogPayF6075  if oo==1, cluster(IDlseMHR)  a(ISOCodeM WLM AgeBandM) // MFEBayesLogPayF6075 MFEBayesLogPayF6050 MFEBayesLogPayF7275 MFEBayesLogPayF7250 MFEBayesLogPayF72 MFEBayesLogPayF60

/* FE correlation graph
********************************************************************************

**# ON PAPER
label define HF 0 "Low-flyer" 1 "High-flyer"
label value EarlyAgeM HF 
cibar MFEBayesLogPayF6075 if oo==1, over(EarlyAgeM )  graphopt(legend(size(medium)) ytitle("Manager value added in worker pay >=75th pc", size(medium) ) scheme(white_ptol) ylabel(0(0.1)0.4) ) 
graph export "$analysis/Results/2.Descriptives/HFCorrFE.png", replace 

cibar MFEBayesLogPay75 if oo==1, over(EarlyAgeM )   // very similar

********************************************************************************
*/

* Constructing relevant variables for the table 
* EDUCATION Groups 
gen Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
label var Econ "Econ, Business, and Admin"
gen Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
label var Sci "Sci, Tech, Engin, and Math"
gen Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label var Hum "Social Sciences and Humanities"
gen Other = (Econ ==0 & Sci ==0 & Hum ==0  )  if FieldHigh1!=.
label var Other "Other Educ"
gen Missing = FieldHigh1 ==. 
label var Missing "Missing Education"

gen Bachelor =    QualHigh >=10 if QualHigh!=.
gen MBA =    QualHigh ==13 if QualHigh!=.
gen AboveSecondary = QualHigh >=6 if QualHigh!=.

* here are the actual median ages within group computed in MType.do: 26 35 44 53 62 
gen AgeContinuous = .
replace AgeContinuous = 26 if AgeBandM == 1
replace AgeContinuous = 35 if AgeBandM == 2
replace AgeContinuous = 44 if AgeBandM == 3
replace AgeContinuous = 53 if AgeBandM == 4
replace AgeContinuous = 62 if AgeBandM == 5

winsor2 SpanM, suffix(W) cuts(0 99)

egen CountryY = group(CountryM Year) 

// other variables 
gen WLAgg = WLM
replace WLAgg = 3 if WLM>3 & WLM!=.
tab WLAgg , gen(WLAgg)

bys IDlseMHR: egen max = max(WLM) // max WL observed 
gen maxWLAgg = max 
replace maxWLAgg = 3 if max>3 & max!=.
tab maxWLAgg , gen(maxWLAgg)

// generate WL dummies 
label var WLAgg1 "Work Level 1"
label var maxWLAgg1 "Work Level 1 (max)"
label var WLAgg2 "Work Level 2"
label var maxWLAgg2 "Work Level 2 (max)"
label var WLAgg3 "Work Level 3+"
label var maxWLAgg3 "Work Level 3+ (max)"

* maximum tenure 
bys IDlseMHR: egen maxTenureM = max(TenureM ) // max tenure observed 

// performance ratings  
gen VPA100M = VPAM > 100 if VPAM!=.
gen VPA125M = VPAM >= 125 if VPAM!=.
gen LineManagerMeanB2 = LineManagerMean >=4.5 if LineManagerMean  !=. // effective LM 

xtset IDlseMHR YearMonth 
gen PayGrowth = d.LogPayBonusM 

bys IDlseMHR: egen minAge = min(AgeContinuous) // minimum age observed 

* generate age dummies 
replace AgeBandM = . if AgeBandM > 6 // age missing or under 18 (<0.01)
replace AgeBandM = 5 if AgeBandM>4 & AgeBandM !=. // 60+
tab AgeBandM, gen(Age)
label var Age1 "Age 18-29"  
label var Age2 "Age 30-39"
label var Age3 "Age 40-49"
label var Age4 "Age 50-59"
label var Age5 "Age +60"

* create mode of function & group functions in wider groups and make dummy 
gen FuncGroup = .
replace FuncGroup = 6 if !mi(FuncM)
replace FuncGroup = 1 if FuncM == 4
replace FuncGroup = 2 if FuncM == 3
replace FuncGroup = 3 if FuncM == 11
replace FuncGroup = 4 if FuncM == 10
replace FuncGroup = 5 if FuncM == 9
label define functiongroups 1 "Finance" 2 "Customer Development" 3 "Supply Chain" 4 "R\&D" 5 "Marketing" 6 "Other"
label values FuncGroup functiongroups

* mode
bys IDlseMHR: egen FuncMode = mode(FuncGroup), minmode

* dummies 
levelsof FuncMode, local(fugs)
foreach f of local fugs {
		gen FuncGroupMode`f' = FuncMode == `f'
}

label var FuncGroupMode1 "Finance"
label var FuncGroupMode2 "Customer Development"
label var FuncGroupMode3 "Supply Chain"
label var FuncGroupMode4 "R\&D"
label var FuncGroupMode5 "Marketing"
label var FuncGroupMode6 "Other Functions"

* Mid-career recruit 
bys IDlseMHR : egen FF= min(YearMonth)
bys IDlseMHR : egen FirstWL = mean(cond(YearMonth==FF, WLM, .)) // first WL observed 
bys IDlseMHR : egen FirstTenure = mean(cond(YearMonth==FF, TenureM, .)) // tenure in first month observed 

gen MidCareerHire = FirstWL>1 & FirstTenure<=1 & WLM!=. // they are only 10% of all managers!

* Only considering the performance after the observed maximum WL is achieved 
bys IDlseMHR: egen YearMaxWLM = min(cond(WLM == MaxWLM, YearMonth, .))
format YearMaxWLM %tm
gen Post = YearMonth >=  YearMaxWLM if YearMonth!=.
bys IDlseMHR: egen mm = min(Post)
ta mm if oo==1 // 87% of managers have their FT determined before the start of the data 

* List of variables
global CHARS  FemaleM AgeContinuous MBA TenureM WLM  TransferInternalM EarlyAgeMM
global TEAM SpanMW  ShareFemale   ShareOutGroup ShareDiffOffice  
global PRE ProductivityM LogPayBonusM PayBonusGrowthM PromWLCM SGSpeedM  VPAM   PRIM   
global LM LineManager ChangeSalaryGradeRMMean LeaverVolRMMean 

* Labels 
label var FemaleM "Female"
label var AgeBandM "Age Group" 
label var AgeContinuous "Age"
label var minAge "Age"
label var TenureM "Tenure (years)" 
label var maxTenureM "Tenure (years), max"
label var WLM   "Work Level"
label var max "Work Level, max"
label var SpanM "Span of Control"
label var SpanMW "Span of Control"
label var EarlyAgeM "High Flyer Manager"
label var ShareSameG "Team share, diff. gender"
label var ShareFemale "Team share, female"
label var ShareOutGroup  "Team share, diff. homecountry" 
label var ProductivityStdM "Sales achievement/target"
label var ProductivityM  "Sales achievement/target"
label var LogPayBonusM  "Pay + Bonus (logs)"
label var PayGrowth "Monthly salary growth"
label var AvPayGrowth "Team pay growth"
label var MFEBayesPromSG75 "Workers' promotions >=75th pc"
label var MFEBayesLogPayF6075 "Manager value added in pay >=75th pc"
label var MFEBayesLogPay75 "Manager value added in pay >=75th pc"
*label var MFEBayesLogPay75v2 "Manager value added in pay >=75th pc"
label var MFEBayesLogPay50 "Manager value added in pay >=50th pc"
label var  MFEBayesLogPayF6050 "Manager value added in pay >=50th pc"
label var MFEBayesLogPayF7275 "Manager value added in pay >=75th pc"
label var  MFEBayesLogPayF7250 "Manager value added in pay >=50th pc"
label var LeaverPermM "Exit"
label var PromWLCM  "No. Prom. WL"
label var VPAM   "Perf. rating (1-150)"
label var PRIM "Perf. rating (1-5)"
label var LineManager "Effective leader (survey)"
label var LineManagerMean "Effective leader (survey)"
label var LineManagerMeanB "Effective leader (survey)"
label var ShareSameOffice  "Team share, same office"
label var PayBonusGrowthM  "Monthly salary growth" 
label var ChangeSalaryGradeRMMean "Team mean prom. (salary)"
label var SGSpeedM "Prom. Speed (salary)"
label var LargeSpanM "Large span of control"
label var LeaverVolRMMean "Team mean vol. exit"
label var TransferInternalM "Internal rotations"
label var WLAgg3 "Promotion work-level 3" 
label var FuncMode "Function (mode)"
label var MidCareerHire "Mid-career recruit"
label var FlagUFLPM "Hired through graduate programme"

* High flyers in natural experiment 
merge m:1 IDlseMHR using "$managersdta/Temp/mSample.dta", keepusing(minAge)
keep if _merge==3 

********************************************************************************
* PRE-BALANCE TABLE (Characteristics determined before joining company), 
* ONLY KEEPING 1 MANAGER AND USING TIME INVARIANT CHARACTERISTICS 
********************************************************************************

global pre FemaleM minAge MidCareerHire FlagUFLPM MBA Econ Sci Hum Other 
*Missing FuncGroupMode1 FuncGroupMode2 FuncGroupMode3 FuncGroupMode4 FuncGroupMode5 FuncGroupMode6

global preFunc FemaleM minAge MidCareerHire FlagUFLPM MBA Econ Sci Hum  FuncGroupMode1 FuncGroupMode2 FuncGroupMode3 FuncGroupMode4 FuncGroupMode5

/* 
**# ON PAPER TABLE: EarlyAgeMPre.tex
balancetable HF FemaleM MBA Econ Sci Hum Other MidCareerHire if oo==1  using "$analysis/Results/0.Paper/1.1.Descriptives Tables/EarlyAgeMPre.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Not High Flyer" "High Flyer" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")
* observationscolumn // to show sample size
*/

********************************************************************************
* POST-BALANCE TABLE, ONLY KEEPING 1 MANAGER AND USING AVERAGES OVER THE MONTHS 
********************************************************************************

reg TransferInternalM  HF if Post==1, vce(cluster IDlseMHR) // they are NOT more likely to transfer while being wl2

global perf  TenureM LogPayBonusM WLAgg1 WLAgg2 WLAgg3 VPAM LineManagerMean 
global other MidCareerHire FlagUFLPM maxTenureM max maxWLAgg1 maxWLAgg2 maxWLAgg3 PayGrowth ProductivityStdM ProductivityM TransferInternalM  TransferInternalC TransferSJC TransferFuncC
global mtype EarlyAgeM HF AvPayGrowth MFEBayesLogPay75 MFEBayesLogPay50 MFEBayesLogPayF6075 MFEBayesPromSG75 MFEBayesPromSG50 MFEBayesPromWL75 MFEBayesPromWL50
* LineManagerMeanB  
* EarlyAgeMM ChangeSalaryGradeRMMean LeaverVolRMMean  

preserve 
keep if Post==1 // only keeping the post performance (87% of managers) - after the High Flyer status is determined 
 foreach v of var  $mtype $perf $other {
 local l`v' : variable label `v'
       if `"`l`v''"' == "" {
		local l`v' "`v'"
}
}

collapse  $mtype $perf $other , by(IDlseMHR)

foreach v of var $mtype $perf $other {
 label var `v' `"`l`v''"'
}

reg TransferInternalM  EarlyAgeM
ta HF 
* 13,814 5,484 19,298

/* 
**# ON PAPER TABLE: EarlyAgeMPost.tex
balancetable EarlyAgeM PayGrowth WLAgg3 VPAM LineManagerMean  using "$analysis/Results/0.Paper/1.1.Descriptives Tables/EarlyAgeMPost.tex", ///
replace  pval  varla vce(cluster IDlseMHR)     ctitles("Not High Flyer" "High Flyer" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}") //  observationscolumn
*  MFEBayesLogPay75
*/

* merge two tables above into one with 2 panels
********************************************************************************

* Manual adjustments for tex table to be done after running the code
* 1) add before the row of observations a \hline manually
* 2) delete these two lines to make it a single table:
* \end{tabular}
* \begin{tabular}{l*{3}{c}}

**# ON PAPER TABLE: EarlyAgeMCombined.tex (Panel A)
balancetable EarlyAgeM PayGrowth WLAgg3 VPAM LineManagerMean using "$analysis/Results/0.Paper/1.1.Descriptives Tables/EarlyAgeMCombined.tex", ///
replace pval varla vce(cluster IDlseMHR) ctitles("Not High Flyer" "High Flyer" "Difference")  ///
prehead("\begin{tabular}{l*{3}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (a): performance after high-flyer status is determined}} \\\\[-1ex]") ///
noli noobs

restore 

* EarlyAgeMCombined.tex (Panel B)
balancetable HF FemaleM MBA Econ Sci Hum Other MidCareerHire if oo==1 using "$analysis/Results/0.Paper/1.1.Descriptives Tables/EarlyAgeMCombined.tex", ///
posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (b): demographics}} \\\\[-1ex]") ///
pval varla vce(cluster IDlseMHR)  ///
noli nonum  ///
append ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager. \emph{Perf. rating} refers to the performance assessment given annually to each employee; \emph{Effective leader (survey)} refers to the workers' anonymous upward feedback on the managers' leadership; and \emph{Mid-career recruit} refers to managers who have been hired directly as managers by the firm (at work-level 2 instead of work-level 1)." "\end{tablenotes}")


/* 1) in or out rotation - selection into rotation 
*************************************************
* HF
balancetable mT  PayGrowth TransferInternalM VPAM LineManagerMean MFEBayesLogPayF6075 if max!=1  &  EarlyAgeM==1 using "$analysis/Results/2.Descriptives/HFRotationPost.tex", ///
replace  pval  varla vce(cluster IDlseMHR)     ctitles("No rotation" "Rotation" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}") //  observationscolumn
*
* LF
balancetable mT  PayGrowth TransferInternalM VPAM LineManagerMean MFEBayesLogPayF6075 if max!=1  &  EarlyAgeM==0 using "$analysis/Results/2.Descriptives/LFRotationPost.tex", ///
replace  pval  varla vce(cluster IDlseMHR)     ctitles("No rotation" "Rotation" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}") //  observationscolumn
*/


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
label var VPA "Perf. ratings"
label var LeaverPerm "Monthly Exit"
label var BonusPay "Bonus over Pay"
label var ProductivityStd "Productivity, sales (std)"

/*
eststo clear 
**# ON PAPER TABLE: suStatsOutcomes.tex
estpost su   ChangeSalaryGradeCm TransferSJLLCm PromWLCm LeaverPerm  LogPayBonus BonusPay VPA LogP , d
esttab using "$analysis/Results/0.Paper/1.1.Descriptives Tables/suStatsOutcomes.tex", ci(3)  label nonotes cells( "mean(fmt(%9.2fc) label(Mean)) sd(fmt(%8.1fc) label(SD)) p1(fmt(%8.1fc) label(P1)) p99(fmt(%8.1fc) label(P99)) count(fmt(%9.0fc) label(N))") noobs  nomtitles  nonumbers postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-month-year. The data contain personnel records for the entire white-collar employee base from January 2011 until December 2021. ///
Salary information is only available since January 2015 and the data on performance ratings start in January 2017. 	"\end{tablenotes}") replace 
*/

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
label var Sci "Sci, Tech, Engin, and Math"
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

/*
eststo clear 
**# ON PAPER TABLE: suStats.tex
estpost su   $des   , d
esttab using "$analysis/Results/0.Paper/1.1.Descriptives Tables/suStats.tex", ci(3)  label nonotes cells( "mean(fmt(%9.2fc) label(Mean)) sd(fmt(%8.1fc) label(SD)) p1(fmt(%8.1fc) label(P1)) p99(fmt(%8.1fc) label(P99)) count(fmt(%9.0fc) label(N))") noobs  nomtitles  nonumbers postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-month-year. The data contain personnel records for the entire white-collar employee base from January 2011 until December 2021. ///
Cohort refers to the age group and work level denotes the hierarchical tier (from level 1 at the bottom to level 6)."\end{tablenotes}") replace 
*/

* merge two tables above into one with 3 panels
********************************************************************************

eststo clear
**# ON PAPER TABLE: suStatsAll.tex (Panel A)
estpost su   Female Cohort1 Cohort2 Cohort3 Cohort4 Econ Sci Hum Other , d
esttab using "$analysis/Results/0.Paper/1.1.Descriptives Tables/suStatsAll.tex", replace ///
prehead("\begin{tabular}{l*{5}{c}} \hline\hline") ///
posthead("\hline \\ \multicolumn{6}{c}{\textit{Panel (a): gender, age and education}} \\\\[-1ex]") ///
fragment ///
ci(3) label nonotes cells( "mean(fmt(%9.2fc) label(Mean)) sd(fmt(%8.1fc) label(SD)) p1(fmt(%8.1fc) label(P1)) p99(fmt(%8.1fc) label(P99)) count(fmt(%12.0fc) label(N))") noobs  nomtitles  nonumbers nofloat 

* suStatsAll.tex (Panel B) 
estpost su   Tenure WL1 WL2 WL3 NoMonths ChangeMTot TeamSize  , d
esttab using "$analysis/Results/0.Paper/1.1.Descriptives Tables/suStatsAll.tex", ///
posthead("\hline \\ \multicolumn{6}{c}{\textit{Panel (b): tenure, hierarchy and team size}} \\\\[-1ex]") ///
fragment ///
append ///
ci(3) label nonotes cells( "mean(fmt(%9.2fc)) sd(fmt(%8.1fc)) p1(fmt(%8.1fc)) p99(fmt(%8.1fc)) count(fmt(%12.0fc))") ///
noobs  nomtitles  nonumbers nofloat nolines collabels(none)

* suStatsAll.tex (Panel C) 
estpost su  ChangeSalaryGradeCm TransferSJLLCm PromWLCm LeaverPerm  LogPayBonus BonusPay VPA LogP  , d
esttab using "$analysis/Results/0.Paper/1.1.Descriptives Tables/suStatsAll.tex", ///
posthead("\hline \\ \multicolumn{6}{c}{\textit{Panel (c): outcome variables}} \\\\[-1ex]") ///
ci(3) label nonotes cells( "mean(fmt(%9.2fc)) sd(fmt(%8.1fc)) p1(fmt(%8.1fc)) p99(fmt(%8.1fc)) count(fmt(%12.0fc))") ///
noobs  nomtitles  nonumbers nofloat nolines collabels(none) ///
fragment ///
append ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-month-year. The data contain personnel records for the entire white-collar employee base from January 2011 until December 2021. ///
In Panel (a) cohort refers to the age group and education data is only available for a subset of workers. In Panel (b) work level denotes the hierarchical tier (from level 1 at the bottom to level 6). ///
In Panel (c) salary information is only available since January 2015 and the data on performance ratings start in January 2017. ///
"\end{tablenotes}")  

* Average response rate surveys 
********************************************************************************

* Univoice 
use "$managersdta/AllSnapshotMCulture.dta", clear 
merge 1:1 IDlse YearMonth using "$fulldta/Univoice.dta"
drop if _merge ==2 

rename _merge mergeS

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
label var Sci "Sci, Tech, Engin, and Math"
gen Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label var Hum "Social Sciences and Humanities"
gen Other = (Econ ==0 & Sci ==0 & Hum ==0  )  if FieldHigh1!=.
label var Other "Other Educ"
gen Missing = FieldHigh1 ==. 
label var Missing "Missing Education"

gen Bachelor =    QualHigh >=10 if QualHigh!=.
gen MBA =    QualHigh ==13 if QualHigh!=.
gen AboveSecondary = QualHigh >=6 if QualHigh!=.

* OTHER VARIABLES
********************************************************************************

* generate work level dummies 
replace  WL = 3 if WL >3
tab WL, gen(WL)

* generate age dummies
replace AgeBand =  1 if  AgeBand==7 //18
replace AgeBand =  4 if  AgeBand>4 & AgeBand!=. // above 50
tab AgeBand, gen(Cohort)

global des Female Cohort1 Cohort2 Cohort3 Cohort4 Econ Sci Hum Other  Tenure WL1 WL2 WL3  EarlyAgeM  
label var WL1 "Share in Work-level 1" 
label var WL2 "Share in Work-level 2" 
label var WL3 "Share in Work-level 3+" 
label var Cohort1 "Share in Cohort 18-29"  
label var Cohort2 "Share in Cohort 30-39"
label var Cohort3 "Share in Cohort 40-49"
label var Cohort4 "Share in Cohort 50+"
label var Tenure "Tenure (years)"
label var TeamSize "No. of workers per supervisor"
label var EarlyAgeM "High-flyer manager"

gen SurveyInd = 1 if mergeS==3
replace SurveyInd = 0 if mergeS==1

gen Month = month(dofm(YearMonth))

preserve 
keep if Month==9 // when the survey is done

**# ON PAPER TABLE: BTableSurveyAnswer.tex
balancetable SurveyInd $des if Month ==9  using "$analysis/Results/0.Paper/1.1.Descriptives Tables/BTableSurveyAnswer.tex"   , pval replace cov(Office Year) vce( cluster IDlse )  varlabels  ///
ctitles( "Non-respondents" "Survey respondents" "Difference" ) groups("\textbf{Mean / (SE)}" "\textbf{Difference in means / (p-value)}" , pattern(1 0 1 ) ) postfoot("\hline\hline \end{tabular} \begin{tablenotes} \footnotesize \item" ///
Notes. This table compares average characteristics of the non-respondents (Column 1) to the subset of employees who responded to the employee survey (Column 2). ///
Standard errors clustered at the worker level used. Controlling for office year fixed effects.  "\end{tablenotes}}")
restore

********************************************************************************
* Generate month-subfunc-office level data about managerial jobs 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

gen o =1 

gen JobWL2 = WL==2
gen JobWL3 = WL==3
gen JobWL4Agg = WL>3 if WL!=.

gcollapse JobWL2 JobWL3 JobWL4Agg (sum) o, by(Office OfficeCode ISOCode YearMonth FuncS SubFuncS  )

label var o "Number of jobs within office-subfunc-month"
rename o UnitSize
compress 

save "$managersdta/Temp/ManagerJobs.dta", replace 

********************************************************************************
* Generate job-office level data about disappering and new jobs 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth 

gen o =1 

gcollapse (sum) o, by(StandardJob YearMonth FuncS SubFuncS OfficeCode Office CountryS ISOCode )
isid StandardJob YearMonth FuncS SubFuncS Office

sort Office SubFuncS StandardJob YearMonth

* Two equivalent methods: 
*1) looking for changes within subfunction and office 
bys SubFuncS Office StandardJob (YearMonth), sort: gen NewJob = StandardJob[_n] != StandardJob[_n-1]
bys SubFuncS Office StandardJob (YearMonth), sort: gen OldJob = StandardJob[_n] != StandardJob[_n+1]

bys SubFuncS Office StandardJob: egen mi  = min(YearMonth) 
bys SubFuncS Office StandardJob: egen ma  = max(YearMonth)

*2) using the minimum and maximum date 
bys SubFuncS Office StandardJob:  gen NewJob1 = cond(YearMonth==mi & mi!=tm(2011m1), 1 ,0,.)
replace OldJob =  . if YearMonth == tm(2020m3)
replace NewJob1 = . if YearMonth == tm(2011m1)

*StandardJob[_n] != StandardJob[_n-1]

replace OldJob = . if YearMonth == tm(2020m3)
replace NewJob = . if YearMonth == tm(2011m1)

compress 

save "$managersdta/NewOldJobs.dta", replace 

********************************************************************************
* Generate job-manager level data about disappering and new jobs 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth 

gen o =1 

gcollapse (sum) o, by(StandardJob YearMonth SubFuncM IDlseMHR Office OfficeCode CountryS ISOCode )
drop if IDlseMHR ==.
drop if  SubFuncM ==.

isid StandardJob  YearMonth IDlseMHR Office 

order IDlseMHR YearMonth StandardJob , first
sort IDlseMHR  YearMonth StandardJob

* using the minimum and maximum date
bys IDlseMHR   SubFuncM: egen miM  = min(YearMonth) 
bys IDlseMHR   SubFuncM: egen maM  = max(YearMonth) 
bys IDlseMHR  SubFuncM StandardJob: egen mi  = min(YearMonth) 
bys IDlseMHR  SubFuncM StandardJob: egen ma  = max(YearMonth)

bys IDlseMHR StandardJob  SubFuncM:  gen NewJobManager = cond(YearMonth==mi  & miM!=mi, 1 ,0,.)
bys IDlseMHR StandardJob  SubFuncM:  gen OldJobManager = cond(YearMonth==ma  & maM!=ma, 1 ,0,.)

compress 
drop miM maM mi ma
save "$managersdta/NewOldJobsManager.dta", replace 

********************************************************************************
* REGRESSION RESULTS TABLE/FIGURE
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 

* choose the manager type !MANUAL INPUT!
global Label  FT  
global typeM  EarlyAgeM

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

*keep if Ei!=. 
gen KEi  = YearMonth - Ei 
gen Post = KEi >=0 if KEi!=.

gen JobbWL2 = WL==2
gen JobbWL3 = WL==3
gen JobbWL4Agg = WL>3 if WL!=.

merge m:1 Office SubFuncS StandardJob YearMonth using "$managersdta/NewOldJobs.dta" , keepusing(NewJob OldJob)
drop _merge 

merge m:1 StandardJob  YearMonth IDlseMHR Office  using "$managersdta/NewOldJobsManager.dta", keepusing(NewJobManager OldJobManager)
keep if _merge==3
drop _merge 

merge m:1  Office SubFuncS YearMonth using "$managersdta/Temp/ManagerJobs.dta", keepusing(JobWL2 JobWL3 JobWL4Agg UnitSize )
keep if _merge==3
drop _merge 

gen sampleN = (JobWL2!=.) & (OldJob!=.) & (NewJob!=.) // to keep the same number of observations 
eststo clear 
foreach v in  JobWL2 OldJob NewJob  { // JobWL3 JobWL4Agg  NewJobManager OldJobManager
eststo `v': reghdfe `v' EarlyAgeM  if WL2==1 & sampleN==1, cluster(IDlseMHR) a( Func YearMonth)
*eststo `v': reghdfe `v' EarlyAgeM  if WL2==1 , cluster(IDlseMHR) a( Func Country YearMonth)
qui sum `e(depvar)' if (e(sample) & EarlyAgeM==0 & WL2==1)
estadd scalar Mean = r(mean)
} 

su JobWL2 OldJob NewJob if EarlyAgeM==0 & WL2==1

label var NewJob "Probability of job created"
label var OldJob "Probability of job destroyed"
label var  JobWL2 "Share of managerial jobs"


label var EarlyAgeM "High-flyer manager"
**#ON  PAPER TABLE: NewJobA.tex
esttab NewJob OldJob JobWL2 using "$analysis/Results/0.Paper/1.2.Descriptives Figures/NewJobA.tex", replace ///
cells(b(star fmt(4)) se(par fmt(4))) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(Mean N r2, fmt(3 0 4) labels("Mean, Low-flyer" "N" "R-squared")) ///
label nofloat nonotes collabels(none) ///
keep(EarlyAgeM) ///
mtitles("Probability of job created" "Probability of job destroyed" "Share of managerial jobs") ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-year-month. The outcomes are the probability that a new job is created, an old job is destroyed and the share of managerial (WL2+) jobs within an office-subfunction-month. Controls include function and year-month FE. Standard errors are clustered by manager.  ///
"\end{tablenotes}")

/** previously a figure ON PAPER FIGURE: NewJobAE.png
coefplot    NewJob OldJob   JobWL2  ,  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq  xlabel(-0.008(0.002) 0.008) ///
scale(1)  legend(off) coeflabels(, ) ysize(6) xsize(8) aspect(0.5) ytick(,grid glcolor(black)) xline(0, lpattern(dash))
graph export  "$analysis/Results/0.Paper/1.2.Descriptives Figures/NewJobA.pdf", replace
*/

/*
coefplot    NewJob OldJob   JobWL2  ,  keep(EarlyAgeM)  levels(95) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample." "Controls include: function, year, month and country FE" "Standard errors clustered at the manager level. 95% Confidence Intervals.", span size(small)) legend(off) ///
aspect(0.4) xlabel(-0.008(0.002) 0.008) coeflabels(, ) ysize(6) xsize(8) ytick(,grid glcolor(black)) xline(0, lpattern(dash))
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/2.Descriptives/NewJob.pdf", replace
*/
