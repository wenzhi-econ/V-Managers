/* 
This do file explores if we can construct a binary effective leader indicator used in the paper.

RA: WWZ 
Time: 2025-04-02
*/

/* 
This do file compares key variables between H- and L-type managers.

Notes:
    The sample includes all employees who have ever been WL2 in the dataset.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== constructed in 0104 do file
    "${RawMNEData}/Univoice.dta"                   <== raw data 
    "${RawMNEData}/EducationMax.dta"               <== raw data 
    "${RawCntyData}/6.WB IncomeGroup.dta"          <== raw data

Auxiliary files:
    "${TempData}/temp_EverWL2WorkerPanel.dta"       <== auxiliary dataset, will be removed if $if_erase_temp_file==1
    "${TempData}/temp_MngrEffectiveness_Survey.dta" <== auxiliary dataset, will be removed if $if_erase_temp_file==1

Output:
    "${TempData}/temp_EventMngrStatisticsHFVsNHF.dta"

Results:
    "${TempData}/temp_Table3_SummaryStatistics_MngrHvsL_FullMngrSample.dta" <== dataset used to create the summary statistics table 
    "${Results}/MngrHFvsNHFStatistics.tex"                                  <== final table 

RA: WWZ 
Time: 2025-03-12
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain the final dataset consisting of event managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. generate a list of managers who have been WL2 in the data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

*!! get any employee who is of WL2 at any point in the data 
generate WL2 = (WL==2) if WL!=.
sort IDlse YearMonth
bysort IDlse: egen Ever_WL2 = max(WL2)

keep if Ever_WL2==1
    //&? a panel of workers who are ever WL2 in the data 

*!! generate a Post variable indicating the worker has reached manager level
generate Post = (WL>=2) if WL!=. 

keep IDlse YearMonth Post Ever_WL2
duplicates drop 

save "${TempData}/temp_EverWL2WorkerPanel.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. process survey variable:  LineManagerMean
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

merge 1:1 IDlse YearMonth using "${RawMNEData}/Univoice.dta", keepusing(LineManager)
    keep if _merge==3
    drop _merge 

collapse (mean) LineManager, by(IDlseMHR YearMonth) 

bysort IDlseMHR: egen LineManagerMean = mean(LineManager)

generate LineManagerMean_High = .
replace  LineManagerMean_High = 1 if LineManagerMean>4 & LineManagerMean!=.
replace  LineManagerMean_High = 0 if LineManagerMean<=4

generate LineManagerMean_Low  = .
replace  LineManagerMean_Low  = 1 if LineManagerMean==1 
replace  LineManagerMean_Low  = 0 if LineManagerMean>1 & LineManagerMean!=.

rename IDlseMHR IDlse
keep IDlse LineManagerMean LineManagerMean_High LineManagerMean_Low
duplicates drop 

save "${TempData}/temp_MngrEffectiveness_Survey.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. have a panel of event managers with key variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

merge 1:1 IDlse YearMonth using "${TempData}/temp_EverWL2WorkerPanel.dta", keep(match) nogenerate 
    //&? keep only those matched workers 
    //&? who are also in the "${TempData}/temp_EverWL2WorkerPanel.dta" dataset 

drop IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 FT_Never_ChangeM FT_Rel_Time ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL ///
    FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL ///
    ChangeMR
        //&? To avoid confusion, this dataset consists of managers in the event studies. 
        //&? They are not analysis units in event studies, so these variables are useless.

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-1. education variables 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

merge m:1 IDlse using "${RawMNEData}/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
    drop if _merge==2 
    drop _merge 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-2. H-type or L-type identifiers 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

rename IDlse IDlseMHR
    //&? temporary step: for the purpose of merge

merge 1:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta" , keepusing(EarlyAgeM)
    drop if _merge==2 
    drop _merge 

rename EarlyAgeM EarlyAge
rename IDlseMHR IDlse

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-3. Survey variables 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

merge m:1 IDlse using "${TempData}/temp_MngrEffectiveness_Survey.dta", keepusing(LineManagerMean LineManagerMean_High LineManagerMean_Low)
    drop if _merge==2 
    drop _merge 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-1-2-4. productivity (sales bonus)
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

merge 1:1 IDlse YearMonth using "${TempData}/05SalesProdOutcomes.dta" , keepusing(ProductivityStd)
    drop if _merge==2 
    drop _merge 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2: generate relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1: Monthly salary growth 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
xtset IDlse YearMonth 
generate PayGrowth = d.LogPayBonus

label variable PayGrowth "Monthly salary growth"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2: Promotion work-level 3
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
generate WLAgg = WL
replace  WLAgg = 3 if WL>3 & WL!=.
tab WLAgg , gen(WLAgg)

label variable WLAgg3 "Promotion work-level 3" 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3: Perf. rating (1-150)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
label variable VPA "Perf. rating (1-150)"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4: Effective leader (survey)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
label variable LineManagerMean "Effective leader (survey)"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5: Female 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
label variable Female "Female"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-6: MBA 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
generate Bachelor       = QualHigh>=10 if QualHigh!=.
generate MBA            = QualHigh==13 if QualHigh!=.
generate AboveSecondary = QualHigh>=6  if QualHigh!=.

label variable MBA "MBA"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-7: field of study 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
generate Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
label variable Econ "Econ, Business, and Admin"

generate Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
    FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
    FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
label variable Sci "Sci, Tech, Engin, and Math"

generate Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | ///
    FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | ///
    FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label variable Hum "Social Sciences and Humanities"

generate Other = (Econ == 0 & Sci == 0 & Hum == 0)  if FieldHigh1!=.
label variable Other "Other Educ"

generate Missing = (FieldHigh1==.) 
label variable Missing "Missing Education"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-8: Mid-career recruit 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
bysort IDlse : egen FF= min(YearMonth)
bysort IDlse : egen FirstWL = mean(cond(YearMonth==FF, WL, .)) // first WL observed 
bysort IDlse : egen FirstTenure = mean(cond(YearMonth==FF, Tenure, .)) // tenure in first month observed 

generate MidCareerHire = (FirstWL>1 & FirstTenure<=1 & WL!=.)
label variable MidCareerHire "Mid career hire"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-9: Function
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
tabulate Func
    //&? The largest big functions are 3, 9, 11, 10, 4 (or, Customer Development, Marketing, Supply Chain, R&D, Fin).

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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-10: Income group 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 ISOCode using "${RawCntyData}/6.WB IncomeGroup.dta", keep(match master)

codebook IncomeGroup

generate LowIncome = .
replace  LowIncome = 1 if IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"
replace  LowIncome = 0 if IncomeGroup=="High income" | IncomeGroup=="Upper middle income"

generate UpperMidIncome = .
replace  UpperMidIncome = 1 if IncomeGroup=="Upper middle income" 
replace  UpperMidIncome = 0 if IncomeGroup=="High income" | IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"

generate HighIncome = . 
replace  HighIncome = 1 if IncomeGroup=="High income"
replace  HighIncome = 0 if IncomeGroup=="Upper middle income" | IncomeGroup=="Low income" | IncomeGroup=="Lower middle income"

label variable LowIncome      "Low income countries"
label variable UpperMidIncome "Middle income countries"

order IDlse YearMonth EarlyAge ///
    PayGrowth WLAgg3 VPA LineManagerMean ///
    Female ///
    MBA Econ Sci Hum Other ///
    MidCareerHire ///
    func_cd func_m func_sc func_o func_rd func_fi ///
    LowIncome UpperMidIncome

save "${TempData}/temp_Table3_SummaryStatistics_MngrHvsL_FullMngrSample.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: produce the summary statistics table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_Table3_SummaryStatistics_MngrHvsL_FullMngrSample.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1: demographics variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

* impt: These variables are time-invariant. 
*!! Therefore, for each person, we need only one observation for comparison

capture drop occurrence
sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 

balancetable EarlyAge Female MBA Econ Sci Hum Other if occurrence==1 ///
    using "${Results}/MngrHFvsNHFStatistics_FullMngrSample_EffectiveLeader.tex", ///
    pval varla vce(cluster IDlse) ctitles("Not High Flyer" "High Flyer" "Difference")   ///
    noli noobs replace ///
    prehead("\begin{tabular}{l*{3}{c}} \hline\hline") ///
    posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (a): demographics}} \\\\[-1ex]") ///
    prefoot("\hline") ///
    postfoot("")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2: work-related variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

label variable LowIncome      "Low income countries"
label variable UpperMidIncome "Middle income countries"
    
balancetable EarlyAge func_cd MidCareerHire LowIncome UpperMidIncome if occurrence==1 ///
    using "${Results}/MngrHFvsNHFStatistics_FullMngrSample_EffectiveLeader.tex", ///
    pval varla vce(cluster IDlse)  ///
    noli noobs nonum append ///
    prehead("") ///
    posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (b): work-related variables}} \\\\[-1ex]") ///
    prefoot("\hline") ///
    postfoot("")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3: performance-related variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

* impt: We only consider the performance after managers reach WL2 or above

preserve 
    *!! s-3-1-1: keep only performance after managers reach WL2 or above
    keep if Post == 1 
        //&? sample restriction only to performance-releated variables 

    *!! s-3-1-2: average over all post periods 
    collapse EarlyAge PayGrowth WLAgg3 VPA LineManagerMean LineManagerMean_High LineManagerMean_Low, by(IDlse)

    label variable PayGrowth           "Monthly salary growth"
    label variable WLAgg3              "Promotion work-level 3" 
    label variable VPA                 "Perf. rating (1-150)"
    label variable LineManagerMean     "Effective leader (survey)"
    label variable LineManagerMean_High "High effective leader (survey)"
    label variable LineManagerMean_Low  "Low effective leader (survey)"

    balancetable EarlyAge PayGrowth WLAgg3 VPA LineManagerMean LineManagerMean_High LineManagerMean_Low ///
        using "${Results}/MngrHFvsNHFStatistics_FullMngrSample_EffectiveLeader.tex", ///
        pval varla vce(cluster IDlse) ///
        noli nonum append ///
        prehead("") ///
        posthead("\hline \\ \multicolumn{4}{c}{\textit{Panel (c): performance after high-flyer status is determined}} \\\\[-1ex]") ///
        prefoot("\hline") ///
        postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item Notes. The table reports means, standard deviations (in parentheses), and p-values for differences in means, which are computed using standard errors clustered by manager. \emph{Mid-career recruit} refers to managers who have been hired directly as managers by the firm (at work-level 2 instead of work-level 1). Working countries' income groups are classified by World Bank, and the omitted income group is high income country. \emph{Perf. rating} refers to the performance assessment given annually to each employee; and \emph{Effective leader (survey)} refers to the workers' anonymous upward feedback on the managers' leadership. " "\end{tablenotes}")

restore 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. remove auxiliary datasets 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

if $if_erase_temp_file==1 {
    erase "${TempData}/temp_EverWL2WorkerPanel.dta"
    erase "${TempData}/temp_MngrEffectiveness_Survey.dta"
}






