/* 
The codes are copied from "3.3.Other Analysis.do".
I made a lot of changes to the original codes to keep only the relevant ones. 

Input files:
    "${FinalData}/AllSnapshotMCulture.dta" (main)
    "${FinalData}/EducationMax.dta" (raw data, education information)
    "${TempData}/ProductivityManagers.dta"

Output files:
    "${Results}/Table2_SummaryStatistics.tex"

RA: WWZ 
Time: 26/08/2024
*/

/* 
Major changes of the file:
    This do file makes a modified version of Table V (titled as "Endogenous mobility checks (transitions)").
    It replaces the outcome variable of column (4) in panel (a) with AvProductivityStd.
    It adds another panel (as the second panel) using the following outcome variables:
        ShareTransferSJSameM "Lateral move, same team "
        ShareTransferSJDiffM "Lateral move, diff. team  "
        ShareTransferFunc "Cross-func move "  
        ShareLeaverVol "Exit"
    
    The codes are copied from "3.3.Other Analysis.do".

Input files:
    "${tempdata}/TeamSwitchers.dta"
    "${tempdata}/Temp/MType.dta"

Output files:
    "${analysis}/Results/0.New/PreFTCombinedTR_NewVars.tex"

RA: WWZ 
Time: 2024-09-19
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1: obtain the dataset used in the analysis 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/TeamSwitchers.dta" , clear 

capture drop EarlyAgeM 
generate IDlseMHR = IDlseMHRPrePost 
merge m:1 IDlseMHR YearMonth using "${TempData}/MType.dta", keepusing(EarlyAgeM)
drop if _merge ==2 
drop _merge 

keep ///
    IDteam YearMonth Year IDlseMHR EarlyAgeM ///
    SpanM WLM ///
    FTLL FTLH FTHH FTHL
order ///
    IDteam YearMonth Year IDlseMHR EarlyAgeM ///
    SpanM WLM ///
    FTLL FTLH FTHH FTHL
sort IDteam YearMonth

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. event-related variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! calendar time of the event
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHH FT_Calend_Time_HtoH
rename FTHL FT_Calend_Time_HtoL

*!! five event dummies: 4 types of treatment + 1 never-treated
generate FT_LtoL = 0 
replace  FT_LtoL = 1 if FT_Calend_Time_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if FT_Calend_Time_LtoH != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if FT_Calend_Time_HtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if FT_Calend_Time_HtoL != .

generate FT_Never_ChangeM = . 
replace  FT_Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  FT_Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 

label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2: generate relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

bys IDteam: egen mSpan= min(SpanM)

bys IDteam: egen minK = min(KEi)
bys IDteam: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

foreach var in FT {
	
    xtset IDteam YearMonth 
    gen diff`var' = d.EarlyAgeM
    gen Delta`var'tag = diff`var' if KEi==0
    bys IDteam: egen Delta`var' = mean(Delta`var'tag)

    drop  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
    gen `var'LHPost = KEi >=0 & `var'LH!=.
    gen `var'LLPost = KEi >=0 & `var'LL!=.
    gen `var'HHPost = KEi >=0 & `var'HH!=.
    gen `var'HLPost = KEi >=0 & `var'HL!=.

    egen `var'Post = rowmax( `var'LHPost `var'LLPost `var'HLPost `var'HHPost ) 

    gen `var'PostDelta = `var'Post*Delta`var'
    label var  `var'LHPost "Low to High"
    label  var `var'LLPost "Low to Low"
    label  var `var'HLPost "High to Low"
    label var  `var'HHPost "High to High"
    label var `var'Post "Event"
    label var `var'PostDelta "Event*Delta M. Talent"
    label var Delta`var' "Delta M. Talent"
} 

foreach Label in FT { 
    foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
        gen `var'Pre = 1-`var'Post
        replace `var'Pre = 0 if `var'==. 
        replace `var'Pre = . if `Label'LH==. & `Label'LL ==. & `Label'HH ==. & `Label'HL ==. // missing for non-switchers
        
    }
    label var  `Label'LHPre "Low to High"
    label  var `Label'LLPre "Low to Low"
    label  var `Label'HLPre "High to Low"
    label var  `Label'HHPre "High to High"
}

* fix double counting issue 
ta FTLLPre FTHLPre 
ta FTLHPre FTHHPre 
ta FTLLPost FTHLPost 
ta FTLHPost FTHHPost

replace FTLLPre=0 if FTHLPre ==1
replace FTLHPre=0 if FTHHPre ==1

replace FTLLPost=0 if FTHLPost ==1
replace FTLHPost=0 if FTHHPost ==1

foreach var in FT {
    global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
    label var  `var'LHPost "Low to High"
    label var  `var'LLPost "Low to Low"
    label var  `var'HLPost "High to Low"
    label var  `var'HHPost "High to High"
} 

gen lAvPay = log(AvPay)


global perf  lAvPay ShareChangeSalaryGrade SharePromWL ShareTransferSJ
global div   TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracNat
global homo  ShareSameG  ShareSameAge  ShareSameOffice  ShareSameNationality  

label var lAvPay                 "Salary (logs)"
label var ShareChangeSalaryGrade "Salary grade increase"
label var SharePromWL            "Vertical move (WL)"
label var ShareTransferSJ        "Lateral move"

label var TeamFracGender         "Diversity, gender"
label var TeamFracAge            "Diversity, age"
label var TeamFracOffice         "Diversity, office"
label var TeamFracNat            "Diversity, nationality"

label var ShareSameG             "Same gender"
label var ShareSameAge           "Same age"
label var ShareSameOffice        "Same office"
label var ShareSameNationality   "Same nationality" 

foreach var in FuncM WLM AgeBandM CountryM  FemaleM {
    bys IDteam YearMonth: egen m`var' = mode(`var'), max
    replace m`var'  = round(m`var' ,1)
    replace `var' = m`var'
}

local Label FT 
egen `Label'HPre = rowmax( `Label'LHPre `Label'HHPre )
egen `Label'LPre = rowmax( `Label'LLPre `Label'HLPre )

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: run regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

eststo clear

global controls FuncM CountryM Year // FuncM WLM AgeBandM 
global cont  // c.TenureM##c.TenureM##i.FemaleM

local i = 1
local Label FT 

foreach y in $perf $move $div $homo {
	
	eststo reg`i'A: reghdfe `y' `Label'LHPre `Label'HHPre `Label'HLPre `Label'LLPre $cont if SpanM>1 & KEi<=-6 & KEi >=-36 & WLM==2 , cluster(IDlseMHR) a($controls)
	local lbl : variable label `y'
	lincom `Label'HLPre - `Label'HHPre
	estadd scalar pvalue2 = r(p)
	estadd scalar diff2 = r(estimate)
	estadd scalar se_diff2 = r(se)  
	lincom `Label'LHPre - `Label'LLPre
	estadd scalar pvalue1 = r(p)
	estadd scalar diff1 = r(estimate)
	estadd scalar se_diff1 = r(se)  
	estadd local Controls "Yes", replace
	estadd local TeamFE "No", replace
	estadd ysumm 
	local i = `i' + 1
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4: produce the table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- panel a: lAvPay ShareChangeSalaryGrade SharePromWL AvProductivityStd
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

esttab reg1A reg2A reg3A reg4A using "${analysis}/Results/0.New/PreFTCombinedTR_NewVars.tex", ///
    replace ///
    prehead("\begin{tabular}{l*{4}{c}} \hline\hline \\ \multicolumn{5}{c}{\textit{Panel (a): team performance}} \\\\[-1ex]") ///
    fragment ///
    label ///
    stats( diff1 pvalue1 diff2 pvalue2 ymean N r2, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean" "N" "R-squared") ) ///
    interaction("$\times$") nobaselevels nofloat nonotes  noobs ///
    drop( *LHPre *HHPre *HLPre *LLPre _cons ) 


*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- panel b: ShareTransferSJSameM  ShareTransferSJDiffM ShareTransferFunc ShareLeaverVol
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

esttab reg5A reg6A reg7A reg8A using "${analysis}/Results/0.New/PreFTCombinedTR_NewVars.tex", ///
    prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (b): team movements}} \\\\[-1ex]") ///
    fragment ///
    append ///
    label ///
    s( diff1 pvalue1 diff2 pvalue2 ymean N r2, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean" "N" "R-squared") ) ///  
    interaction("$\times$ ") nofloat nonotes nobaselevels noobs ///
    drop( *LHPre *HHPre *HLPre *LLPre _cons )

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- panel c: TeamFracGender TeamFracAge TeamFracOffice TeamFracNat
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

esttab reg9A reg10A reg11A reg12A using "${analysis}/Results/0.New/PreFTCombinedTR_NewVars.tex", ///
    prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (c): team diversity}} \\\\[-1ex]") ///
    fragment ///
    append ///
    label ///
    s( diff1 pvalue1 diff2 pvalue2 ymean N r2, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean" "N" "R-squared") ) ///  
    interaction("$\times$ ") nofloat nonotes nobaselevels noobs ///
    drop( *LHPre *HHPre *HLPre *LLPre _cons )

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- panel d: ShareSameG ShareSameAge ShareSameOffice ShareSameNationality  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

esttab reg13A reg14A reg15A reg16A using "${analysis}/Results/0.New/PreFTCombinedTR_NewVars.tex", ///
    prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (d): team homophily with manager}} \\\\[-1ex]") ///
    fragment ///
    append ///
    label ///
    s( diff1 pvalue1 diff2 pvalue2 ymean N r2, labels("LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" "\hline Mean" "N" "R-squared") ) /// 
    interaction("$\times$ ") nobaselevels nofloat nonotes noobs ///
    drop( *LHPre *HHPre *HLPre *LLPre _cons ) ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
    Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Standard errors clustered at the manager level. Controls include: function, country and year FE. In Panel (a), \textit{Salary (logs)} is the log of the average salary in the team; \textit{Salary grade increase} is share of workers with a salary increase; \textit{Vertical move (WL)} is share of workers with a work-level promotion; and \textit{Productivity} is {\color{red} i am not so sure}. In Panel (b), {\color{red} not so sure about my interpretation. \textit{Lateral move, same team} is the share of workers that experience a lateral move within the same team. \textit{Lateral move, diff. team} is the share of workers that experience a lateral move to a different team. \textit{Cross-func move} is the share of workers that experience function changes. \textit{Exit} is the share of workers that exit the company.} In Panel (c), each outcome variable is a fractionalization index (1- Herfindahl-Hirschman index) for the relevant characteristic; it is 0 when all team members are the same and it is 1 when there is maximum team diversity. In Panel (d), each outcome variable is the share of workers that share the same characteristic with the manager (gender, age group, office, nationality). ///
    "\end{tablenotes}")