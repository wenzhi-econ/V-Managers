
* This dofile does balance tables
* CORRELATES OF MANAGER TYPE - MANAGER LEVEL

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* Prepare data 
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 

ta ISOCodeM if ProductivityStdM!=. & EarlyAgeM !=. // note that there are only 2 managers with Indian data, so cannot assess this correlation 

* education variable 
merge m:1 IDlseMHR  using "$fulldta/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge 

* in rotation 
merge m:1 IDlseMHR using "$managersdta/Temp/m2.dta", keepusing( mT HF)
drop _merge 

* get the type of the post manager 
gen IDlse = IDlseMHR // for the merging below
merge m:1 IDlse YearMonth using "$managersdta/Temp/PromExitRes.dta", keepusing(TransferSJC TransferFuncC TransferInternalC PromWLC ChangeSalaryGradeC)
drop if _merge ==2
drop _merge
drop IDlse  

* manager type 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2015.dta", keepusing(MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50)
drop if _merge ==2
drop _merge

rename (MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50) =v2015

merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesLogPayF6075 MFEBayesLogPayF6050 MFEBayesLogPayF7275 MFEBayesLogPayF7250 MFEBayesLogPayF72 MFEBayesLogPayF60)
drop if _merge ==2
drop _merge 

*UFLP status 
gen IDlse = IDlseMHR
merge 1:1 IDlse YearMonth using "$managersdta/AllSnapshotMCultureMType.dta", keepusing(FlagUFLP )
drop if _merge ==2
ta _merge // 99% are matched 
drop _merge 
rename FlagUFLP FlagUFLPM
drop IDlse  

* correlation btw High Flyer manager and MFEBayesPromSG75
********************************************************************************

egen oo = tag(IDlseMHR)

reg MFEBayesPromSG75 EarlyAgeM  if oo==1, robust 
reghdfe MFEBayesPromSG75 EarlyAgeM  if oo==1, cluster(IDlseMHR)  a(ISOCodeM WLM AgeBandM)

reg MFEBayesLogPayF6075 EarlyAgeM  if oo==1, robust 
reghdfe MFEBayesLogPayF6075 EarlyAgeM  if oo==1, cluster(IDlseMHR)  a(ISOCodeM WLM AgeBandM) // MFEBayesLogPayF6075 MFEBayesLogPayF6050 MFEBayesLogPayF7275 MFEBayesLogPayF7250 MFEBayesLogPayF72 MFEBayesLogPayF60

* FE correlation graph
********************************************************************************

**# ON PAPER
label define HF 0 "Low-flyer" 1 "High-flyer"
label value EarlyAgeM HF 
cibar MFEBayesLogPayF6075 if oo==1, over(EarlyAgeM )  graphopt(legend(size(medium)) ytitle("Manager value added in pay >=75th pc", size(medium)))
graph export "$analysis/Results/2.Descriptives/HFCorrFE.png", replace 

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

// performance appraisals  
gen VPA100M = VPAM > 100 if VPAM!=.
gen VPA125M = VPAM >= 125 if VPAM!=.
gen LineManagerMeanB2 = LineManagerMean >=4.5 if LineManagerMean  !=. // effective LM 

xtset IDlseMHR YearMonth 
gen PayGrowth = d.LogPayBonusM 

egen t = tag(IDlseMHR) // tagging manager 
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
egen tt= tag(IDlseMHR)
bys IDlseMHR: egen mm = min(Post)
ta mm if tt==1 // 87% of managers have their FT determined before the start of the data 

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
label var PayGrowth "Salary growth"
label var MFEBayesPromSG75 "Workers' promotions >=75th pc"
label var MFEBayesLogPayF6075 "Manager value added >=75th pc"
label var  MFEBayesLogPayF6050 "Manager value added >=50th pc"
label var MFEBayesLogPayF7275 "Manager value added >=75th pc"
label var  MFEBayesLogPayF7250 "Manager value added >=50th pc"
label var LeaverPermM "Exit"
label var PromWLCM  "No. Prom. WL"
label var VPAM   "Perf. appraisal (1-150)"
label var PRIM "Perf. appraisal (1-5)"
label var LineManager "Effective leader (survey)"
label var LineManagerMean "Effective leader (survey)"
label var LineManagerMeanB "Effective leader (survey)"
label var ShareSameOffice  "Team share, same office"
label var PayBonusGrowthM  "Salary growth" 
label var ChangeSalaryGradeRMMean "Team mean prom. (salary)"
label var SGSpeedM "Prom. Speed (salary)"
label var LargeSpanM "Large span of control"
label var LeaverVolRMMean "Team mean vol. exit"
label var TransferInternalM "Internal rotations"
label var FuncMode "Function (mode)"
label var MidCareerHire "Mid-career recruit"
label var FlagUFLPM "Hired through graduate programme"

********************************************************************************
* PRE-BALANCE TABLE (Characteristics determined before joining company), 
* ONLY KEEPING 1 MANAGER AND USING TIME INVARIANT CHARACTERISTICS 
********************************************************************************

global pre FemaleM minAge MidCareerHire FlagUFLPM MBA Econ Sci Hum Other 
*Missing FuncGroupMode1 FuncGroupMode2 FuncGroupMode3 FuncGroupMode4 FuncGroupMode5 FuncGroupMode6

global preFunc FemaleM minAge MidCareerHire FlagUFLPM MBA Econ Sci Hum  FuncGroupMode1 FuncGroupMode2 FuncGroupMode3 FuncGroupMode4 FuncGroupMode5

* without function 
********************************************************************************

* 1) in or out rotation - selection into rotation
***********************************

*HF
balancetable mT FemaleM   MBA Econ Sci Hum Other MidCareerHire FlagUFLPM if t==1 & max!=1 & EarlyAgeM==1 using "$analysis/Results/2.Descriptives/HFRotationPre.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("No rotation" "Rotation" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")
* observationscolumn // to show sample size
*LF
balancetable mT FemaleM   MBA Econ Sci Hum Other MidCareerHire FlagUFLPM if t==1 & max!=1 & EarlyAgeM==0 using "$analysis/Results/2.Descriptives/LFRotationPre.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("No rotation" "Rotation" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")
* observationscolumn // to show sample size

* 2) ALL HF
***********************************
**# ON PAPER
balancetable EarlyAgeM FemaleM   MBA Econ Sci Hum Other MidCareerHire FlagUFLPM if t==1 & max!=1  using "$analysis/Results/2.Descriptives/EarlyAgeMPre.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Not High Flyer" "High Flyer" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")
* observationscolumn // to show sample size

*3) other FE
***********************************
balancetable MFEBayesLogPayF6075 FemaleM   MBA Econ Sci Hum Other MidCareerHire FlagUFLPM if t==1 & MFEBayesLogPayF6075!=.  using "$analysis/Results/2.Descriptives/PayVAMPre.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Low Value Added" "High Value Added" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")
* observationscolumn // to show sample size
* MFEBayesLogPayF6050 MFEBayesLogPayF7275 MFEBayesLogPayF7250 MFEBayesLogPayF72 MFEBayesLogPayF60

balancetable MFEBayesPromSG75 $pre if t==1  & MFEBayesPromSG75 !=. using "$analysis/Results/2.Descriptives/MTypePromSG75Pre.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Low Prom." "High Prom." "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager. Age is the minimum age observed in the data." "\end{tablenotes}")

balancetable MFEBayesPromSG50 $pre if t==1  & MFEBayesPromSG50 !=. using "$analysis/Results/2.Descriptives/MTypePromSG50Pre.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Low Prom." "High Prom." "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")

* with function 
********************************************************************************

balancetable MFEBayesPromSG75 $preFunc if t==1  & MFEBayesPromSG75 !=. using "$analysis/Results/2.Descriptives/MTypePromSG75PreFunc.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Low Prom." "High Prom." "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "Computing the mode for the function." "Leaving out some categories due to space constraints:" "\textit{Other Educ}, \textit{Missing Educ}, \textit{Other Function}." "\end{tablenotes}")

balancetable MFEBayesPromSG50 $preFunc if t==1  & MFEBayesPromSG50 !=. using "$analysis/Results/2.Descriptives/MTypePromSG50PreFunc.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Low Prom." "High Prom." "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "Computing the mode for the function." "Leaving out some categories due to space constraints:" "\textit{Other Educ}, \textit{Missing Educ}, \textit{Other Function}." "\end{tablenotes}")

balancetable EarlyAgeM $preFunc if t==1 & max!=1  using "$analysis/Results/2.Descriptives/EarlyAgeMPreFunc.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Not High Flyer" "High Flyer" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "Computing the mode for the function." "Leaving out some categories due to space constraints:" "\textit{Other Educ}, \textit{Missing Educ}, \textit{Other Function}." "\end{tablenotes}")
* observationscolumn // to show sample size

********************************************************************************
* POST-BALANCE TABLE, ONLY KEEPING 1 MANAGER AND USING AVERAGES OVER THE MONTHS 
********************************************************************************

global perf  TenureM LogPayBonusM WLAgg1 WLAgg2 WLAgg3 VPAM LineManagerMean 
global other MidCareerHire FlagUFLPM maxTenureM max maxWLAgg1 maxWLAgg2 maxWLAgg3 PayGrowth ProductivityStdM ProductivityM TransferInternalM  TransferInternalC TransferSJC TransferFuncC
global mtype mT HF EarlyAgeM MFEBayesLogPayF6075 MFEBayesPromSG75 MFEBayesPromSG50 MFEBayesPromWL75 MFEBayesPromWL50
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

* 1) in or out rotation - selection into rotation 
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

* 2) ALL HF 
*************************************************
**# ON PAPER
balancetable EarlyAgeM  PayGrowth TransferInternalM VPAM LineManagerMean  if max!=1   using "$analysis/Results/2.Descriptives/EarlyAgeMPost.tex", ///
replace  pval  varla vce(cluster IDlseMHR)     ctitles("Not High Flyer" "High Flyer" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}") //  observationscolumn

*MFEBayesLogPayF6075
* 3) other FE
*************************************************
balancetable MFEBayesLogPayF6075  PayGrowth TransferInternalM VPAM LineManagerMean  EarlyAgeM  if MFEBayesLogPayF6075!=.    using "$analysis/Results/2.Descriptives/PayVAMPost.tex", ///
replace  pval  varla vce(cluster IDlseMHR)     ctitles("Low Value Added" "High Value Added" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}") //  observationscolumn

balancetable MFEBayesPromSG75  PayGrowth max TransferInternalM VPAM LineManagerMean MFEBayesPromSG75 maxTenureM MidCareerHire FlagUFLPM  if MFEBayesPromSG75 !=. using "$analysis/Results/2.Descriptives/MTypePromSG75Post.tex", ///
replace  pval  varla vce(cluster IDlseMHR)    ctitles("Low Prom." "High Prom." "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager. Measures are the overall average in the whole sample." "\end{tablenotes}") //  observationscolumn
* Alternative construction: Measures are the overall average in the hold-out sample (2011-2013). but then lost salary and VPA

balancetable MFEBayesPromSG50  $perf   if MFEBayesPromSG50 !=. using "$analysis/Results/2.Descriptives/MTypePromSG50Post.tex", ///
replace  pval  varla vce(cluster IDlseMHR)    ctitles("Low Prom." "High Prom." "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager. Measures are the overall in the whole sample." "\end{tablenotes}") // observationscolumn 

reg  EarlyAgeM FlagUFLPM, cluster(IDlseMHR)
ta EarlyAgeM FlagUFLPM, row
restore 

********************************************************************************
* Balance table High Flyer manager 
********************************************************************************

balancetable EarlyAgeM $CHARS $TEAM $PRE  $LM   using "$analysis/Results/2.Descriptives/EarlyAgeM.tex", ///
replace  pval  varla vce(cluster IDlseMHR) cov(i.CountryY i.FuncM) ctitles("Not High Flyer" "High Flyer" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered at the manager level and controlling for CountryXYear and function fixed effects." "\end{tablenotes}")

* DO High Flyer MANAGERS TRANSFER MORE 
********************************************************************************

bys IDlseMHR (YearMonth): gen TransferInternalCM = sum(TransferInternalM)
reghdfe TransferInternal EarlyAgeM , a(   AgeBandM i.CountryY i.FuncM) vce(cluster IDlseMHR) // 0.4% MORE 

* only look at max WL 
bys IDlseMHR: egen MaxWL = max(WL) // last observed WL 
bys IDlseMHR: egen MinYMMaxWL = min(cond(WL ==MaxWL,YearMonth, .))  // last observed WL 
format MinYMMaxWL %tm
*keep if WL== MaxWL or keep if WL< MaxWL
keep if YearMonth == MinYMMaxWL

balancetable EarlyAgeM $CHARS $TEAM $LM  $PRE using "$analysis/Results/2.Descriptives/EarlyAgeMMaxWL.tex", ///
replace  pval  varla vce(cluster IDlseMHR) cov(i.CountryY) ctitles("Not High Flyer" "High Flyer" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")

balancetable LargeSpanM $CHARS $TEAM $LM  $PRE using "$analysis/Results/2.Descriptives/LargeSpanM.tex", ///
replace  pval  varla vce(cluster IDlseMHR) cov(i.CountryY) ctitles("Small Span of control" "Large Span of control" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")

balancetable LineManagerB  $CHARS $TEAM $LM  $PRE using "$analysis/Results/2.Descriptives/LineManagerB.tex", ///
replace  varla pval vce(cluster IDlseMHR) cov(i.CountryY) ctitles("Not effective leader" "Effective leader" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")

* Effective LM more likely to be male??
reghdfe LineManagerB FemaleM i.WLM ShareF ShareOutGroup TeamSize, a(CountryY)
reghdfe Senior FemaleM i.WLM ShareF ShareOutGroup TeamSize, a(CountryY)

********************************************************************************
* BALANCE CHECKS AT THE MANAGER LEVEL - PRE TEAM CHARS 
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 

egen TeamSizeC = cut(TeamSize), group(5)
gen ChangeTeamYM = YearMonth if ChangeTeam ==1 

* only look at max WL 
bys IDlseMHR: egen MaxWL = max(WL) // last observed WL 
bys IDlseMHR: egen MinYMMaxWL = min(cond(WL ==MaxWL,YearMonth, .))  // last observed WL 
format MinYMMaxWL %tm
*keep if WL== MaxWL or keep if WL< MaxWL
keep if YearMonth == MinYMMaxWL & MaxWL>1

foreach var in   PayBonusCV VPACV TeamTransferInternalSJ TeamTransferInternalSJDiffM TeamTransferInternalSJSameM   TeamLeaverVol TeamChangeSalaryGrade TeamChangeSalaryGradeC TeamTransferInternalSJC TeamTransferInternalSJDiffMC TeamTransferInternalSJSameMC  TeamTenure TeamSize  ShareFemale   ShareOutGroup ShareDiffOffice   {
gen Pre`var' = `var' if YearMonth== FirstYMManager    // first month manager starts as a manager 
replace Pre`var' = . if FirstYMManager  == tm(2011m1) // take away censored obs (were managers before 2011m1)
gen Pre`var'1 = `var' if YearMonth==  MinYMMaxWL   // first month manager starts at max WL
replace Pre`var'1 = . if FirstYMManager  == tm(2011m1) // take away censored obs (were managers before 2011m1)
} 

label var PrePayBonusCV "CV (salary)"
label var PreVPACV "CV (perf. appraisals)"
label var PreTeamTransferInternalSJ "Job change (all)"
label var PreTeamTransferInternalSJDiffM  "Job change (outside team)"
label var PreTeamTransferInternalSJSameM  "Job change (within team)"
label var PreTeamChangeSalaryGrade "Promotion (salary)"
label var PreTeamTransferInternalSJC "Job change, cum (all)"
label var PreTeamTransferInternalSJDiffMC  "Job change, cum (outside team)"
label var PreTeamTransferInternalSJSameMC  "Job change, cum (within team)"
label var PreTeamChangeSalaryGradeC "Promotion, cum (salary)"
label var PreTeamLeaverVol "Exit"

label var PreTeamTenure "Team Tenure"
label var PreTeamSize "Team Size"
label var PreShareFemale "Team share, female"
label var PreShareOutGroup  "Team share, diff. homecountry" 
label var PreShareDiffOffice  "Team share, diff. office"
	
global CHARS  PrePayBonusCV PreTeamChangeSalaryGrade PreTeamTransferInternalSJ PreTeamTransferInternalSJDiffM PreTeamTransferInternalSJSameM  PreTeamChangeSalaryGradeC PreTeamTransferInternalSJC PreTeamTransferInternalSJDiffMC PreTeamTransferInternalSJSameMC    PreTeamLeaverVol
global TEAM PreTeamTenure PreTeamSize  PreShareFemale   PreShareOutGroup PreShareDiffOffice  

* cross section 
balancetable EarlyAgeM  $CHARS $TEAM using "$analysis/Results/2.Descriptives/BalanceTeamEarlyAgeM.tex", ///
replace  pval vce(cluster IDlseMHR) cov(i.CountryMYear i.FuncM i.WLM  ) varlabels ctitles("Not High Flyer" "High Flyer" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." ///
"The difference in means is computed using standard errors clustered by manager." "Controlling for country X year, function, and WL." "\end{tablenotes}")

global CHARS1  PrePayBonusCV1 PreTeamChangeSalaryGrade1 PreTeamTransferInternalSJ1 PreTeamTransferInternalSJDiffM1 PreTeamTransferInternalSJSameM1  PreTeamChangeSalaryGradeC1 PreTeamTransferInternalSJC1 PreTeamTransferInternalSJDiffMC1 PreTeamTransferInternalSJSameMC1    PreTeamLeaverVol1
global TEAM1 PreTeamTenure1 PreTeamSize1  PreShareFemale1   PreShareOutGroup1 PreShareDiffOffice1

label var PrePayBonusCV1 "CV (salary)"
label var PreVPACV1 "CV (perf. appraisals)"
label var PreTeamTransferInternalSJ1 "Job change (all)"
label var PreTeamTransferInternalSJDiffM1  "Job change (outside team)"
label var PreTeamTransferInternalSJSameM1  "Job change (within team)"
label var PreTeamChangeSalaryGrade1 "Promotion (salary)"
label var PreTeamTransferInternalSJC1 "Job change, cum (all)"
label var PreTeamTransferInternalSJDiffMC1  "Job change, cum (outside team)"
label var PreTeamTransferInternalSJSameMC1  "Job change, cum (within team)"
label var PreTeamChangeSalaryGradeC1 "Promotion, cum (salary)"
label var PreTeamLeaverVol1 "Exit"

label var PreTeamTenure1 "Team Tenure"
label var PreTeamSize1 "Team Size"
label var PreShareFemale1 "Team share, female"
label var PreShareOutGroup1  "Team share, diff. homecountry" 
label var PreShareDiffOffice1  "Team share, diff. office"

balancetable EarlyAgeM  $CHARS1 $TEAM1 using "$analysis/Results/2.Descriptives/BalanceTeamEarlyAgeMMaxWL.tex", ///
replace  pval vce(cluster IDlseMHR) cov(i.CountryMYear i.FuncM i.WLM  ) varlabels ctitles("Not High Flyer" "High Flyer" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." ///
"The difference in means is computed using standard errors clustered by manager." "Controlling for country X year, function, and WL." "\end{tablenotes}")

********************************************************************************
* CORRELATES OF MANAGER TYPE - Characteristics of reportees 
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType.dta", clear 

xtset IDlse YearMonth
gen PayBonusGrowth = d.LogPayBonus

global CHARS Female  AgeContinuous Tenure  WL  OutGroup DiffOffice   VPA  PRI PromWLC  LogPayBonus  PayBonusGrowth LeaverPerm  

keep if  YearMonth == FirstYMManager &  FirstYMManager  != tm(2011m1) // select the first month of a manager 
distinct IDlse // repeated obs for IDlse as they can have multiple managers 

label var Female "Female"
label var AgeBand "Age Group" 
label var AgeContinuous "Age"
label var Tenure "Tenure (years)" 
label var WL  "WL"
label var OutGroup  "Diff. homecountry from LM" 
label var LogPayBonus  "Pay + Bonus (logs)"
label var LeaverPerm "Exit"
label var PromWLC  "No. Prom. WL"
label var VPA   "Perf. appraisal (1-150)"
label var PRI "Perf. appraisal (1-5)"
label var PayBonusGrowth  "Salary growth"
label var DiffOffice "Diff. office from LM"

balancetable EarlyAgeM  $CHARS  using "$analysis/Results/2.Descriptives/EarlyAgeMReportee.tex", ///
replace varla pval vce(cluster IDlse) cov(i.Country i.Year ) ctitles("Not High Flyer" "High Flyer" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." ///
"The difference in means is computed using clustered standard errors at the employee level." "\end{tablenotes}")

********************************************************************************
* CORRELATES OF MANAGER TYPE - Characteristics of reportees 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear
merge m:1 IDlse Year using "$fulldta/UniVoice.dta" 
drop if _merge ==2 
drop _merge 
keep if LineManager!=.
gen o = 1
gen WLD = WLM - WL 
gen Senior = WLD >=1 
replace Senior = . if WLD==.
*gen BothF = 1 if Female==1 & FemaleM==1
*replace  BothF = 0 if Female!=. & FemaleM!=.  & Female!=1 & FemaleM!=1

gen date = dofm(YearMonth)
gen Month=month(date)

preserve 
bys IDlse Year: egen Leaver1 = sum(cond(Month>=9 & Month <=12, Leaver,.)) 
keep if YearMonth == tm(2018m9) |  YearMonth == tm(2019m9)  | YearMonth == tm(2020m9)
egen CountryY = group(Country Year)
gen LineManagerB= LineManager > 4
global CHARS WL Female AgeBand Tenure MonthsWL MonthsSJ  VPA PromWLC  PRI LogPayBonus  Leaver1  TeamSize  SameGender OutGroup Senior 

balancetable LineManagerB  $CHARS using "$analysis/Results/2.Descriptives/LineManagerBReportee.tex", ///
replace  pval vce(cluster IDlse) cov(i.CountryY) ctitles("Not effective leader" "Effective leader" "Difference" "N") observationscolumn ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses)." ///
"The difference in means is computed using standard errors clustered by worker." "\end{tablenotes}")
restore 
