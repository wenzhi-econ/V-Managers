/* 
This do file compares key variables between H- and L-type managers.

Notes:
    The sample includes all employees who have ever been WL2 in the dataset.

Input:
    "${TempData}/FinalFullSample.dta"              <== created in 0101_01 do file 
    "${TempData}/0102_03EverWL2WorkerPanel.dta"    <== created in 0102_03 do file
    "${TempData}/0102_03HFMeasure.dta"             <== created in 0102_03 do file
    "${RawMNEData}/Univoice.dta"                   <== raw data 
    "${RawMNEData}/EducationMax.dta"               <== raw data 
    "${RawCntyData}/6.WB IncomeGroup.dta"          <== raw data

Output:
    "${TempData}/0403EffectiveLeaderScores.dta"      <== dataset containing managers' scores on effective leader survey 
    "${TempData}/0403SummaryStatistics_MngrHvsL.dta" <== a simplified dataset containing only relevant variables for the result

Results:
    "${Results}/004ResultsBasedOnCA30/CA30_SummaryStatistics_MngrHvsL.tex"

RA: WWZ 
Time: 2025-03-12
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. process the survey variable
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
/* 
Notes: 
    (1) we are going to compare high-flyer managers and low-flyer managers.
    (2) in the main dataset constructed in step 1, I only keep a sample of managers and their variables.
    (3) however, the survey variable LineManager is associated with their subordinates sample.
    (4) this step creates a manager-level score on effective leader.
*/

use "${TempData}/FinalFullSample.dta", clear 

merge 1:1 IDlse YearMonth using "${RawMNEData}/Univoice.dta", keepusing(LineManager)
    keep if _merge==3
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                     9,926,048
        from master                 9,924,809  (_merge==1)
        from using                      1,239  (_merge==2)

    Matched                           158,829  (_merge==3)
    -----------------------------------------
*/

collapse (mean) LineManager, by(IDlseMHR YearMonth) 

rename IDlseMHR IDlse
keep IDlse YearMonth LineManager
    //&? The final dataset contains three variables:
    //&? IDlse is the manager id, LineManager is the manager's score on effective leader survey in month indicated by YearMonth

save "${TempData}/0403EffectiveLeaderScores.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain the final dataset used for manager comparison
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only those employees who have ever been WL2 in the data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
Notes:
    (1) HF measure CA30 is only defined on those employees who have ever been WL2 in the data.
    (2) The comparison between high-flyer managers and low-flyer managers do not occur in the sample of event managers.
    (3) The comparison takes place among all employees whose HF measure can be identified.
*/

use "${TempData}/FinalFullSample.dta", clear

merge 1:1 IDlse YearMonth using "${TempData}/0102_03EverWL2WorkerPanel.dta"
    keep if _merge==3
    drop _merge 
    //impt: keep the panel of employees who have ever been WL2 in the data

drop IDlseMHR
    //&? to avoid confusion, drop this variable
    //&? we are already considering these WL2 managers, we are not interested in their managers

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. obtain HF measure
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

rename IDlse IDlseMHR
    //&? for the sake of merge, as the id variable in the using dataset is IDlseMHR
merge 1:1 IDlseMHR YearMonth using "${TempData}/0102_03HFMeasure.dta"
    drop _merge 
    //&? as expected, all observations are matched 
rename IDlseMHR IDlse

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. merge the education dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlse using "${RawMNEData}/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
    drop if _merge==2 
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                     1,757,599
        from master                 1,721,875  (_merge==1)
        from using                     35,724  (_merge==2)

    Matched                           612,145  (_merge==3)
    -----------------------------------------
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. merge the survey dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:1 IDlse YearMonth using "${TempData}/0403EffectiveLeaderScores.dta", keepusing(LineManager)
    drop if _merge==2 
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                     2,315,100
        from master                 2,298,406  (_merge==1)
        from using                     16,694  (_merge==2)

    Matched                            35,614  (_merge==3)
    -----------------------------------------
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. keep only relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    IDlse CA30 YearMonth Female AgeBand ///
    QualHigh FieldHigh1 FieldHigh2 FieldHigh3 ///
    Func WL Tenure ISOCode ///
    LogPayBonus VPA LineManager

order ///
    IDlse CA30 YearMonth Female AgeBand ///
    QualHigh FieldHigh1 FieldHigh2 FieldHigh3 ///
    Func WL Tenure ISOCode ///
    LogPayBonus VPA LineManager

sort IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. generate relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. demographics 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Bachelor       = QualHigh>=10 if QualHigh!=.
generate MBA            = QualHigh==13 if QualHigh!=.
generate AboveSecondary = QualHigh>=6  if QualHigh!=.

generate Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
generate Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
    FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
    FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
generate Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | ///
    FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | ///
    FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
generate Other = (Econ == 0 & Sci == 0 & Hum == 0)  if FieldHigh1!=.
generate Missing = (FieldHigh1==.) 

label variable Female  "Female"
label variable MBA     "MBA"
label variable Econ    "Econ, Business, and Admin"
label variable Sci     "Sci, Tech, Engin, and Math"
label variable Hum     "Social Sciences and Humanities"
label variable Other   "Other Educ"
label variable Missing "Missing Education"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. work characteristics  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-2-2-1. function information 

generate func_cd = (Func==3)  if !missing(Func)
generate func_m  = (Func==9)  if !missing(Func)
generate func_sc = (Func==11) if !missing(Func)
generate func_rd = (Func==10) if !missing(Func)
generate func_fi = (Func==4)  if !missing(Func)
generate func_o  = 1           if !missing(Func)
replace  func_o  = 0 if (func_cd==1 | func_m==1 | func_sc==1 | func_rd==1 | func_fi==1)

label variable func_cd "Sales function"
label variable func_m  "Marketing function"
label variable func_sc "Supply chain function"
label variable func_rd "Research/Development function"
label variable func_fi "Finance function"
label variable func_o  "Other functions"

*!! s-2-2-2. mid-career hire 

sort IDlse YearMonth
bysort IDlse: egen FF          = min(YearMonth)
bysort IDlse: egen FirstWL     = mean(cond(YearMonth==FF, WL, .)) // first WL observed 
bysort IDlse: egen FirstTenure = mean(cond(YearMonth==FF, Tenure, .)) // tenure in first month observed 
generate MidCareerHire = (FirstWL>1 & FirstTenure<=1 & WL!=.)

label variable MidCareerHire "Mid career hire"

*!! s-2-2-3. working countries 

merge m:1 ISOCode using "${RawCntyData}/6.WB IncomeGroup.dta", keep(match master)

generate LowIncome      = .
replace  LowIncome      = 1 if IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"
replace  LowIncome      = 0 if IncomeGroup=="High income" | IncomeGroup=="Upper middle income"
generate UpperMidIncome = .
replace  UpperMidIncome = 1 if IncomeGroup=="Upper middle income" 
replace  UpperMidIncome = 0 if IncomeGroup=="High income" | IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"
generate HighIncome     = . 
replace  HighIncome     = 1 if IncomeGroup=="High income"
replace  HighIncome     = 0 if IncomeGroup=="Upper middle income" | IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"

label variable LowIncome      "Low income countries"
label variable UpperMidIncome "Middle income countries"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. performance metrics (post-promotion)  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-2-3-0. post-promotion-to-WL2 indicator

generate Post_Promotion = (WL>=2) if WL!=. 

*!! s-2-3-1. monthly salary growth 

xtset IDlse YearMonth 
generate PayGrowth = d.LogPayBonus

label variable PayGrowth "Monthly salary growth"

*!! s-2-3-2. promotion to WL3+

generate WLAgg = WL
replace  WLAgg = 3 if WL>3 & WL!=.
generate WLAgg3 = (WLAgg==3) if WLAgg!=.

label variable WLAgg3 "Promotion work-level 3" 

*!! s-2-3-3. two other performance metrics 

label variable VPA "Perf. rating (1-150)"
label variable LineManager "Effective leader (survey)"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. save the dataset   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    IDlse CA30 YearMonth Post_Promotion ///
    Female MBA Econ Sci Hum Other ///
    func_cd func_m func_sc func_o func_rd func_fi ///
    MidCareerHire LowIncome UpperMidIncome ///
    PayGrowth WLAgg3 VPA LineManager

order ///
    IDlse CA30 YearMonth Post_Promotion ///
    Female MBA Econ Sci Hum Other ///
    func_cd func_m func_sc func_o func_rd func_fi ///
    MidCareerHire LowIncome UpperMidIncome ///
    PayGrowth WLAgg3 VPA LineManager

save "${TempData}/0403SummaryStatistics_MngrHvsL.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: produce the summary statistics table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0403SummaryStatistics_MngrHvsL.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1: demographics variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop occurrence
sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
    //&? impt: these variables are time-invariant. 
    //&? thus, for each person, we need only one observation (restricted by condition if occurrence==1)

balancetable CA30 Female MBA Econ Sci Hum Other if occurrence==1 ///
    using "${Results}/004ResultsBasedOnCA30/CA30_SummaryStatistics_MngrHvsL.tex", ///
    pval varla vce(cluster IDlse) ctitles("Not High Flyer" "High Flyer" "Difference")   ///
    noli noobs replace ///
    prehead("\begin{tabular}{l*{3}{c}} \hline\hline") ///
    posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (a): demographics}} \\\\[-1ex]") ///
    prefoot("\hline") ///
    postfoot("")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2: work-related variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    
balancetable CA30 func_cd MidCareerHire LowIncome UpperMidIncome if occurrence==1 ///
    using "${Results}/004ResultsBasedOnCA30/CA30_SummaryStatistics_MngrHvsL.tex", ///
    pval varla vce(cluster IDlse)  ///
    noli noobs nonum append ///
    prehead("") ///
    posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (b): work-related variables}} \\\\[-1ex]") ///
    prefoot("\hline") ///
    postfoot("")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3: performance-related variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

//impt: We only consider the performance after managers reach WL2.

preserve 

    *!! s-3-1-1: keep only performance after managers reach WL2 or above
    keep if Post_Promotion == 1 
        //&? sample restriction only to performance-related variables 

    *!! s-3-1-2: average over all post periods 
    collapse (mean) CA30 PayGrowth VPA LineManager (max) WLAgg3, by(IDlse)

    label variable PayGrowth           "Monthly salary growth"
    label variable WLAgg3              "Promotion work-level 3" 
    label variable VPA                 "Perf. rating (1-150)"
    label variable LineManager     "Effective leader (survey)"

    balancetable CA30 PayGrowth WLAgg3 VPA LineManager ///
        using "${Results}/004ResultsBasedOnCA30/CA30_SummaryStatistics_MngrHvsL.tex", ///
        pval varla vce(cluster IDlse) ///
        noli nonum append ///
        prehead("") ///
        posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (c): performance after high-flyer status is determined}} \\\\[-1ex]") ///
        prefoot("\hline") ///
        postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item Notes. The table reports means, standard deviations (in parentheses), and p-values for differences in means, which are computed using standard errors clustered by manager. \emph{Mid-career recruit} refers to managers who have been hired directly as managers by the firm (at work-level 2 instead of work-level 1). Working countries' income groups are classified by World Bank, and the omitted income group is high income country. \emph{Perf. rating} refers to the performance assessment given annually to each employee; and \emph{Effective leader (survey)} refers to the workers' anonymous upward feedback on the managers' leadership. " "\end{tablenotes}")

restore 
