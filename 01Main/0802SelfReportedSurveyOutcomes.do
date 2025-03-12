/* 
This do file analyzes the self-reported survey outcomes.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 
    "${RawMNEData}/Univoice.dta"                   <== raw data 

Results:
    "${Results}/.tex"

RA: WWZ
Time: 2025-02-28
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-0. generate variables used further  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

*!! Year 
capture drop Year
generate Year = year(dofm(YearMonth))

*!! mark the post-event periods for workers appeared in the event study 
capture drop Post
generate Post = FT_Rel_Time>=0 if (FT_Rel_Time!=. & FT_Mngr_both_WL2==1)

*!! mark if the employee makes any lateral transfer after the event
sort IDlse YearMonth
bysort IDlse: egen maxTransfer = max(cond(Post==1, TransferSJ, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge the survey dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! merge 
/* 
impt: merge based on IDlse and Year, even though the survey data is only in September.
*/
merge m:1 IDlse Year using "${RawMNEData}/Univoice.dta"
    rename _merge _mergeSurvey
    keep if _mergeSurvey==3

*!! keep only relevant variables

global SurveyVars ///
    LineManager Inclusive TeamAgility TrustLeadership LeadershipInclusion HeartCustomers ///
    WorkLifeBalance Satisfied Refer Proud LivePurpose Leaving ExtraMile ///
    AccessLearning PrioritiseControl DevOpportunity Wellbeing ReportUnethical ///
    StrategyWin USLP GoodTechnologies Competition EffectiveBarriers Integrity RecommendProducts

keep ///
    IDlse Year YearMonth IDlseMHR EarlyAgeM WLM ///
    AgeBand Female Country maxTransfer Office Func ///
    Post FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time ///
    $SurveyVars

order ///
    IDlse Year YearMonth IDlseMHR EarlyAgeM WLM ///
    AgeBand Female Country maxTransfer ///
    Post FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time ///
    $SurveyVars

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate outcomes of interest (variable aggregation) 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! transform into binary variables 
foreach var in $SurveyVars {
	generate `var'B = 0
	replace  `var'B = 1 if `var'>=5
	replace  `var'B = . if `var'==.
}

*!! pca to get the first component
global Uteampc    LineManagerB InclusiveB TeamAgilityB TrustLeadershipB LeadershipInclusionB HeartCustomersB
global Uhappypc   WorkLifeBalanceB SatisfiedB ReferB ProudB LivePurposeB LeavingB ExtraMileB   
global Ufocuspc   AccessLearningB PrioritiseControlB DevOpportunityB WellbeingB ReportUnethicalB
global Ucompanypc StrategyWinB USLPB GoodTechnologiesB CompetitionB EffectiveBarriersB IntegrityB RecommendProductsB
foreach group in Uteampc Uhappypc Ufocuspc Ucompanypc {
    pca ${`group'}
    predict `group'1, score 
    egen `group'Mean = rowmean($`group')
}

*!! outcome variables of interest 
label variable Uteampc1       "Team Effectiveness"
label variable Ufocuspc1      "Autonomy"
label variable Uhappypc1      "Job Satisfaction"
label variable Ucompanypc1    "Company Effectiveness"
label variable UteampcMean    "Team Effectiveness"
label variable UfocuspcMean   "Autonomy"
label variable UhappypcMean   "Job Satisfaction"
label variable UcompanypcMean "Company Effectiveness"
label variable LineManagerB   "Effective Leader"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. generate other variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! a consistent regression sample 
generate SurveySample = ((LineManagerB!=.) & (Uteampc1!=.) & (Ufocuspc1!=.) & (Uhappypc1!=.) & (Ucompanypc1!=.))

*!! interact lateral job movers with manager's high-flyer status 
generate EarlyAgeM_X_maxTransfer = EarlyAgeM * maxTransfer
label variable EarlyAgeM_X_maxTransfer "High-flyer manager $\times$ worker changed job"

save "${TempData}/temp_SurveyOutcomesAgainstHF.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_SurveyOutcomesAgainstHF.dta", clear

label variable EarlyAgeM "High-flyer manager"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. using the pca-generated outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo clear 
foreach var in LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 { 
    reghdfe `var' EarlyAgeM if Post==1 & WLM==2 & SurveySample==1, cluster(IDlseMHR) absorb(AgeBand##Female Year Office##Func)
        eststo `var'
        summarize `var' if (e(sample)==1 & Post==1 & EarlyAgeM==0 & WLM==2), detail
            estadd scalar Mean = r(mean)	
}
esttab LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. using the mean-generated outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean { 
    reghdfe `var' EarlyAgeM if Post==1 & WLM==2 & SurveySample==1, cluster(IDlseMHR) absorb(AgeBand##Female Year Office##Func)
        eststo `var'
        summarize `var' if (e(sample)==1 & Post==1 & EarlyAgeM==0 & WLM==2), detail
            estadd scalar Mean = r(mean)	
}
esttab LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. using the mean of the raw outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean { 
    reghdfe `var' EarlyAgeM maxTransfer EarlyAgeM_X_maxTransfer if Post==1 & WLM==2 & SurveySample==1, cluster(IDlseMHR) absorb(AgeBand##Female Year Office##Func)
        eststo `var'_Heter
        summarize `var' if (e(sample)==1 & EarlyAgeM==0 & Post==1 & WLM==2), detail
            estadd scalar Mean = r(mean)	
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. using the mean of the raw outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

esttab LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean using "${Results}/SelfReportedSurveyOutcomes_PCAAndMean.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(EarlyAgeM) ///
    order(EarlyAgeM) ///
    b(3) se(2) ///
    stats(r2 Mean N, labels("R-squared" "Mean, low-flyers" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Effective Leader} & \multicolumn{1}{c}{Team Effectiveness} & \multicolumn{1}{c}{Job Satisfaction} & \multicolumn{1}{c}{Autonomy} & \multicolumn{1}{c}{Company Effectiveness} \\ ") ///
    posthead("\hline \\ [-10pt]" "\multicolumn{6}{c}{\emph{Panel (a): using averages for the indices}} \\ [5pt]") ///
    prefoot("\hline") ///
    postfoot("")

esttab LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 using "${Results}/SelfReportedSurveyOutcomes_PCAAndMean.tex", ///
    append style(tex) fragment nocons label nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(EarlyAgeM) ///
    order(EarlyAgeM) ///
    b(3) se(2) ///
    stats(r2 Mean N, labels("R-squared" "Mean, low-flyers" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("") ///
    posthead("\hline \\ [-10pt]" "\multicolumn{6}{c}{\emph{Panel (b): using the first component of PCA for the indices}} \\ [5pt]") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year. Estimates are obtained by running the model in equation S.1. Data comes from the annual pulse survey run by the firm since 2017. Standard errors are clustered by manager. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender, and year fixed effects. In panel (a), survey indices are the averages of various survey questions, grouped together by theme as detailed in Table S.3. In panel (b), survey indices are the first component of PCA using variables from to the same group. I use binary variables to construct the first principal components and averages: probability of answering 5 out of 5-point Likert Scale." "\end{tablenotes}")


esttab LineManagerB_Heter UteampcMean_Heter UfocuspcMean_Heter UhappypcMean_Heter UcompanypcMean_Heter using "${Results}/SelfReportedSurveyOutcomes_HeteroByTransfer.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(EarlyAgeM EarlyAgeM_X_maxTransfer) ///
    order(EarlyAgeM EarlyAgeM_X_maxTransfer) ///
    b(3) se(2) ///
    stats(r2 Mean N, labels("R-squared" "Mean, low-flyers" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Effective Leader} & \multicolumn{1}{c}{Team Effectiveness} & \multicolumn{1}{c}{Job Satisfaction} & \multicolumn{1}{c}{Autonomy} & \multicolumn{1}{c}{Company Effectiveness} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year. Estimates are obtained by running the model in equation S.1 interacting indicator for high-flyer manager with an indicator for whether the worker changes job after the event. Data comes from the annual pulse survey run by the firm since 2017. Standard errors are clustered by manager. Control variables include the fixed effects of the interaction of office and function, as well as the interaction between age band and gender, and year fixed effects. Survey indices are the averages of various survey questions, grouped together by theme as detailed in Table S.3. I use binary variables to construct the averages: probability of answering 5 out of 5-point Likert Scale." "\end{tablenotes}")
