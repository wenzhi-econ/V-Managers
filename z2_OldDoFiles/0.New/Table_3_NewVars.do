/* 
Major changes of the file:
    This do file makes a modified version of Table 3 (titled as "High-flyer managers").
    It adds the following variables into the summary table:
        function (4 types: biggest 3 + others)
        if the manager works in his home country 
        if the manager works in a developed economy 
    The latter two variables cannot be constructed using the original dataset only, so I use information stored in the raw dataset "${managersMNEdata}/AllSnapshotWC.dta".
    
    The codes are copied from "1.1.Descriptives Tables.do".
    I made a lot of changes to the original codes to keep only the relevant ones. 

Input files:
    "${tempdata}/MType.dta" (main)
    "${managersMNEdata}/EducationMax.dta" (raw data, education information)
    "${tempdata}/m2.dta" (no idea what it does, but it provides a key varible HF)
    "${managersMNEdata}/AllSnapshotWC.dta" (raw data, country information)

Output files:
    "${analysis}/Results/0.New/EarlyAgeMCombined_OldVersion.tex" (replication of the original table 3)

RA: WWZ 
Time: 19/3/2024
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1: obtain the final dataset for this table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

* main dataset 
use "${tempdata}/MType.dta", clear 

* education variable 
merge m:1 IDlseMHR  using "${managersMNEdata}/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge 

* in rotation 
merge m:1 IDlseMHR using "${tempdata}/m2.dta", keepusing(mT HF) // created in 2.4.MTypeRotation.do 
drop _merge 

bys IDlseMHR: egen minYM = min(YearMonth)
gen oo = YearMonth == minYM
*egen oo = tag(IDlseMHR)
order oo 


*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s3-0: keep only those managers used in our event study design 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

merge m:1 IDlseMHR using "${tempdata}/mSample.dta", keepusing(minAge)
keep if _merge==3 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2: generate relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-1: Monthly salary growth 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

xtset IDlseMHR YearMonth 
gen PayGrowth = d.LogPayBonusM 
label variable PayGrowth "Monthly salary growth"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-2: Promotion work-level 3
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

gen WLAgg = WLM
replace WLAgg = 3 if WLM>3 & WLM!=.
tab WLAgg , gen(WLAgg)
label variable WLAgg3 "Promotion work-level 3" 

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-3: Perf. rating (1-150)
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

/* summarize VPAM, detail  */
label variable VPAM "Perf. rating (1-150)"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-4: Effective leader (survey)
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

/* summarize LineManagerMean, detail  */
label variable LineManagerMean "Effective leader (survey)"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-5: Female 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

/* summarize FemaleM, detail */
label variable FemaleM "Female"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-6: MBA 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

gen Bachelor       =    QualHigh >=10 if QualHigh!=.
gen MBA            =    QualHigh ==13 if QualHigh!=.
gen AboveSecondary = QualHigh >=6 if QualHigh!=.

label variable MBA "MBA"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-7: field of study 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

gen Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
label variable Econ "Econ, Business, and Admin"

gen Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
    FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
    FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
label variable Sci "Sci, Tech, Engin, and Math"

gen Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | ///
    FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | ///
    FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label variable Hum "Social Sciences and Humanities"

gen Other = (Econ ==0 & Sci ==0 & Hum ==0  )  if FieldHigh1!=.
label variable Other "Other Educ"

gen Missing = FieldHigh1 ==. 
label variable Missing "Missing Education"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s2-8: Mid-career recruit 
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
bys IDlseMHR : egen FF= min(YearMonth)
bys IDlseMHR : egen FirstWL = mean(cond(YearMonth==FF, WLM, .)) // first WL observed 
bys IDlseMHR : egen FirstTenure = mean(cond(YearMonth==FF, TenureM, .)) // tenure in first month observed 

gen MidCareerHire = FirstWL>1 & FirstTenure<=1 & WLM!=. 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: produce the summary table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s3-1: performance-related variables  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

*!! important: we only consider the performance when managers achieves their maximum work-level 
*!! threfore, we need to restrict the sample in panel a of this table 

bys IDlseMHR: egen YearMaxWLM = min(cond(WLM == MaxWLM, YearMonth, .))
format YearMaxWLM %tm
gen Post = (YearMonth >= YearMaxWLM) if YearMonth != .

preserve 
    *!! s-3-1: keep only performance after managers achieves their maximum work-level
    keep if Post == 1 // sample restriction only to performance-releated variables 

    *!! s-3-2: average over all post periods 
    collapse EarlyAgeM PayGrowth WLAgg3 VPAM LineManagerMean, by(IDlseMHR)

    label variable PayGrowth       "Monthly salary growth"
    label variable WLAgg3          "Promotion work-level 3" 
    label variable VPAM            "Perf. rating (1-150)"
    label variable LineManagerMean "Effective leader (survey)"

    balancetable EarlyAgeM PayGrowth WLAgg3 VPAM LineManagerMean ///
        using "${analysis}/Results/0.New/EarlyAgeMCombined_OldVersion.tex", ///
        pval varla vce(cluster IDlseMHR) ctitles("Not High Flyer" "High Flyer" "Difference") ///
        prehead("\begin{tabular}{l*{3}{c}} \hline\hline") ///
        posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (a): performance after high-flyer status is determined}} \\\\[-1ex]") ///
        postfoot(" ") /// 
        noli noobs replace

restore 

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s3-2: demographics variables  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

balancetable HF FemaleM MBA Econ Sci Hum Other MidCareerHire if oo==1 ///
    using "${analysis}/Results/0.New/EarlyAgeMCombined_OldVersion.tex", ///
    pval varla vce(cluster IDlseMHR)  ///
    noli nonum append ///
    prehead(" ") ///
    posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (b): demographics}} \\\\[-1ex]") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
    "Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means in col. 3." ///
    "The difference in means is computed using standard errors clustered by manager. \emph{Perf. rating} refers to the performance assessment given annually to each employee; \emph{Effective leader (survey)} refers to the workers' anonymous upward feedback on the managers' leadership; and \emph{Mid-career recruit} refers to managers who have been hired directly as managers by the firm (at work-level 2 instead of work-level 1)." "\end{tablenotes}")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4: generate more new variables as required  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s4-1: function   
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

tabulate FuncM 
/* 
The largest three functions are 3, 9, 11 (or, Customer Development, Marketing, Supply Chain).
*/

generate func_cd = (FuncM==3)  if !missing(FuncM)
generate func_m  = (FuncM==9)  if !missing(FuncM)
generate func_sc = (FuncM==11) if !missing(FuncM)
generate func_o  = 1           if !missing(FuncM)
replace  func_o  = 0 if (func_cd==1 | func_m==1 | func_sc==1)


label variable func_cd "Customer development function"
label variable func_m  "Marketing function"
label variable func_sc "Supply chain function"
label variable func_o  "Other functions"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s4-2: local nationality  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

*!! s4-2-1: rename to merge with the original dataset to obtain working and home countries 
rename IDlseMHR IDlse 

*!! s4-2-2: obtain working and home countries 
capture drop _merge 
merge 1:1 IDlse YearMonth using "${managersMNEdata}/AllSnapshotWC.dta", keepusing(HomeCountryISOCode ISOCode)
drop if _merge==2
drop _merge 
rename IDlse IDlseMHR

*!! s4-2-3: generate the variable 
generate samecountry = (HomeCountryISOCode==ISOCode) if (!missing(ISOCode) & !missing(HomeCountryISOCode))
label variable samecountry "Working in the home country"

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s4-3: local nationality  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

*!! s4-3-1: rename to merge with the original dataset to obtain working and home countries 
rename IDlseMHR IDlse 

*!! s4-3-2: obtain working and home countries 
capture drop _merge 
merge 1:1 IDlse YearMonth using "${managersMNEdata}/AllSnapshotWC.dta", keepusing(Market)
drop if _merge==2
drop _merge 
rename IDlse IDlseMHR

*!! s4-3-3: generate the variable 
generate developed = (Market==1) if inrange(Market, 1, 2)
    // the condition is to set unknown marketplace to missing, as it equals to 3 in variable Market
label variable developed "Working in a developed country

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5: produce the new table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s5-1: performance-related variables  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

preserve 
    *!! s-3-1: keep only performance after managers achieves their maximum work-level
    keep if Post == 1 // sample restriction only to performance-releated variables 

    *!! s-3-2: average over all post periods 
    collapse EarlyAgeM PayGrowth WLAgg3 VPAM LineManagerMean, by(IDlseMHR)

    label variable PayGrowth       "Monthly salary growth"
    label variable WLAgg3          "Promotion work-level 3" 
    label variable VPAM            "Perf. rating (1-150)"
    label variable LineManagerMean "Effective leader (survey)"

    balancetable EarlyAgeM PayGrowth WLAgg3 VPAM LineManagerMean ///
        using "${analysis}/Results/0.New/EarlyAgeMCombined_NewVersion.tex", ///
        pval varla vce(cluster IDlseMHR) ctitles("Not High Flyer" "High Flyer" "Difference") ///
        prehead("\begin{tabular}{l*{3}{c}} \hline\hline") ///
        posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (a): performance after high-flyer status is determined}} \\\\[-1ex]") ///
        postfoot(" ") /// 
        noli noobs replace

restore 

*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
*-- s5-2: demographics variables  
*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--

balancetable HF FemaleM MBA Econ Sci Hum Other func_cd func_m func_sc func_o MidCareerHire samecountry developed if oo==1 ///
    using "${analysis}/Results/0.New/EarlyAgeMCombined_NewVersion.tex", ///
    pval varla vce(cluster IDlseMHR)  ///
    noli nonum append ///
    posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (b): demographics}} \\\\[-1ex]") ///
    prehead(" ") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
    "Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means in col. 3." ///
    "The difference in means is computed using standard errors clustered by manager. \emph{Perf. rating} refers to the performance assessment given annually to each employee; \emph{Effective leader (survey)} refers to the workers' anonymous upward feedback on the managers' leadership; and \emph{Mid-career recruit} refers to managers who have been hired directly as managers by the firm (at work-level 2 instead of work-level 1)." "\end{tablenotes}")