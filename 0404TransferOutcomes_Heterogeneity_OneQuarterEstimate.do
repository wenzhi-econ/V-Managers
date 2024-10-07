/* 
This do file aims to replicate Table VII in the paper (June 14, 2024 version).

RA: WWZ 
Time: 2024-10-01
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplest possible dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

keep ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC ///
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH ///
    TenureM SameOffice SameGender AgeBand Tenure OfficeSize Office StandardJobE ISOCode Year LogPayBonus 

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC ///
    WL2 ///
    FTLL FTLH FTHH FTHL ///
    TenureM SameOffice SameGender AgeBand Tenure OfficeSize Office StandardJobE ISOCode Year LogPayBonus 
        // IDs, manager info, outcome variables, sample restriction variable, treatment info, heterogeneity indicators

rename WL2 FT_Mngr_both_WL2 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. construct (individual level) event dummies 
*-?       and (individual-month level) relative dates to the event
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

*!! "event * post" (ind-month level) for four treatment groups
generate FT_Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .
generate FT_LtoLXPost = FT_LtoL * FT_Post
generate FT_LtoHXPost = FT_LtoH * FT_Post
generate FT_HtoHXPost = FT_HtoH * FT_Post
generate FT_HtoLXPost = FT_HtoL * FT_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate heterogeneity indicators 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

egen Mngr_tag = tag(IDlseMHR)
egen Ind_tag  = tag(IDlse)

*!! SameOffice0 SameGender0
foreach v in TenureM SameOffice SameGender {
    bysort IDlse: egen `v'0= mean(cond(FT_Rel_Time==0, `v', .))
}

*!! TenureMHigh0
summarize TenureM0 if Mngr_tag==1 & EarlyAgeM==1, detail
summarize TenureM0 if Mngr_tag==1 & EarlyAgeM==0, detail
generate TenureMHigh0 = (TenureM0>=7) // median value for FT manager 

*!! Young0
bysort IDlse: egen Age0 = mean(cond(FT_Rel_Time==0, AgeBand, .))
generate Young0 = Age0==1 if Age0!=.

*!! TenureLow0
bysort IDlse: egen Tenure0 = mean(cond(FT_Rel_Time==0, Tenure, .))
summarize Tenure0 if Ind_tag==1, detail
generate TenureLow0 = (Tenure0<=2) if Tenure0!=. 

*!! OfficeSizeHigh0
bysort IDlse: egen OfficeSize0= mean(cond(FT_Rel_Time==0, OfficeSize, .))
generate OfficeSizeHigh0 = (OfficeSize0>300) if OfficeSize0!=.

*!! JobNum0
egen oj = group(Office StandardJobE)
bysort Office YearMonth: egen JobNumOffice = total(oj) 
bysort IDlse: egen JobNumOffice0= mean(cond(FT_Rel_Time==0, JobNumOffice, .))
summarize JobNumOffice0 if Ind_tag==1, detail 
generate JobNum0 = (JobNumOffice0 > `r(p50)') if JobNumOffice0!=. 

*!! LaborRegHigh0
merge m:1 ISOCode Year using "${RawCntyData}/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF LaborRegWEFB) // /2.WB EmployingWorkers.dta ; 2.ILO EPLex.dta (EPLex )
    keep if _merge!=2
    drop _merge 
bysort IDlse: egen LaborRegHigh0= mean(cond(FT_Rel_Time==0, LaborRegWEFB, .))

*!! WPerf0 WPerf0p10p900
xtset IDlse YearMonth 
generate PayGrowth = d.LogPayBonus 
foreach var in PayGrowth { 
	bysort IDlse: egen `var'0 = mean(cond(inrange(FT_Rel_Time, -24, -1), `var' , .))
	summarize `var'0 if Ind_tag==1, detail
	generate WPerf0B    = `var'0 > `r(p50)'     if `var'0!=.
	generate WPerf0p10B = `var'0 <= `r(p10)'    if `var'0!=.
	generate WPerf0p90B = `var'0 >= `r(p90)'    if `var'0!=.
}
generate WPerf0p10p90B = 0 if WPerf0p10B==1
replace  WPerf0p10p90B = 1 if WPerf0p90B==1

rename WPerf0B WPerf0
rename WPerf0p10p90B WPerf0p10p900

*!! TeamPerfMBase0
merge m:1 IDlseMHR YearMonth using "${TempData}/MType.dta", keepusing(AvPayGrowth)
    keep if _merge!=2
    drop _merge 
bysort IDlse: egen TeamPerf0 = mean(cond(inrange(FT_Rel_Time, -24, -1), AvPayGrowth, .))

summarize TeamPerf0 if Mngr_tag==1, detail
generate TeamPerfM0B = TeamPerf0 > `r(p50)' if TeamPerf0!=.
rename TeamPerfM0B TeamPerfMBase0

*!! DiffM2y0
bysort IDlse: egen MPost2y = mean(cond(FT_Rel_Time==24, IDlseMHR, .))
bysort IDlse: egen MPre    = mean(cond(FT_Rel_Time==0,  IDlseMHR, .)) 
generate DiffM2y = (MPost2y!=MPre) if MPost2y!=. & MPre!=.
rename DiffM2y DiffM2y0

*!! "event * post * heterogeneity indicator" for four treatment groups 

global Hetero_Vars TenureMHigh SameOffice Young TenureLow SameGender OfficeSizeHigh JobNum LaborRegHigh WPerf WPerf0p10p90 TeamPerfMBase DiffM2y

foreach var in $Hetero_Vars {
    generate FT_LtoLXPostX`var' = FT_LtoLXPost * `var'0
    generate FT_LtoHXPostX`var' = FT_LtoHXPost * `var'0
    generate FT_HtoHXPostX`var' = FT_HtoHXPost * `var'0
    generate FT_HtoLXPostX`var' = FT_HtoLXPost * `var'0
}

save "${TempData}/temp_MainOutcomes_BaselineHeterogeneity.dta", replace 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_MainOutcomes_BaselineHeterogeneity.dta", clear 

global Hetero_Vars TenureMHigh SameOffice Young TenureLow SameGender OfficeSizeHigh JobNum LaborRegHigh WPerf WPerf0p10p90 TeamPerfMBase DiffM2y

foreach hetero_var in $Hetero_Vars {
    global hetero_regressors ///
        FT_LtoLXPost FT_LtoLXPostX`hetero_var' ///
        FT_LtoHXPost FT_LtoHXPostX`hetero_var' ///
        FT_HtoHXPost FT_HtoHXPostX`hetero_var' ///
        FT_HtoLXPost FT_HtoLXPostX`hetero_var'

    foreach outcome in TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC {
        reghdfe `outcome' $hetero_regressors  ///
            if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) ///
            , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
    
        xlincom (FT_LtoHXPostX`hetero_var' - FT_LtoLXPostX`hetero_var'), level(95) post

        if "`outcome'" == "TransferSJVC" {
            local outcome_name TSJVC
        }
        if "`outcome'" == "TransferFuncC" {
            local outcome_name TFC
        }
        if "`outcome'" == "PromWLC" {
            local outcome_name PWLC
        }
        if "`outcome'" == "ChangeSalaryGradeC" {
            local outcome_name CSGC
        }

        est store `hetero_var'_`outcome_name'
    }
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

esttab TenureMHigh_TSJVC TenureMHigh_TFC TenureMHigh_PWLC TenureMHigh_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager tenure, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{Lateral moves} & \multicolumn{1}{c}{Cross-function moves} & \multicolumn{1}{c}{Vertical moves} & \multicolumn{1}{c}{Pay grade increase} \\") ///
    posthead("\hline \\ \multicolumn{5}{c}{\textit{Panel (a): worker and manager characteristics}} \\\\[-1ex]")
esttab SameOffice_TSJVC SameOffice_TFC SameOffice_PWLC SameOffice_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same office as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab Young_TSJVC Young_TFC Young_PWLC Young_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker age, young") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab TenureLow_TSJVC TenureLow_TFC TenureLow_PWLC TenureLow_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker tenure, low") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab SameGender_TSJVC SameGender_TFC SameGender_PWLC SameGender_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same gender as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab OfficeSizeHigh_TSJVC OfficeSizeHigh_TFC OfficeSizeHigh_PWLC OfficeSizeHigh_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office size, large") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel (b): environment characteristics}} \\\\[-1ex]") posthead("") prefoot("") postfoot("")
esttab JobNum_TSJVC JobNum_TFC JobNum_PWLC JobNum_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office job diversity, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LaborRegHigh_TSJVC LaborRegHigh_TFC LaborRegHigh_PWLC LaborRegHigh_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Labor laws, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab WPerf_TSJVC WPerf_TFC WPerf_PWLC WPerf_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\hline \\ \multicolumn{5}{c}{\textit{Panel c: worker performance and moves}} \\\\[-1ex]") posthead("") prefoot("") postfoot("")
esttab WPerf0p10p90_TSJVC WPerf0p10p90_TFC WPerf0p10p90_PWLC WPerf0p10p90_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p90)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab TeamPerfMBase_TSJVC TeamPerfMBase_TFC TeamPerfMBase_PWLC TeamPerfMBase_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Team performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab DiffM2y_TSJVC DiffM2y_TFC DiffM2y_PWLC DiffM2y_CSGC using "${Results}/TransferOutcomes_Heterogeneity_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager change, post transition") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. 95\% confidence intervals used and standard errors are clustered by manager. Coefficients are estimated from a regression as in equation \ref{eq:het} and the figure reports the coefficient at the 20th quarter since the manager transition. Controls include worker FE and year months FE. Each row displays the differential heterogeneous impact of each respective variable. Panel (a): the first row looks at the differential impact between having the manager with over and under 7 years of tenure (the median tenure years for high-flyers managers); the second row looks at the differential impact between sharing and not sharing the office with the manager; the third row looks at the differential impact between being under and over 30 years old; the fourth row looks at the differential impact between being under and over 2 years of tenure; the fifth row looks at the differential impact between sharing and not sharing the same gender with the manager. Panel (b): the first row looks at the differential impact between large and small offices (above and below the median number of workers); the second row looks at the differential impact between offices with high and low number of different jobs (above and below median); the third row looks at the differential impact between countries having stricter and laxer labor laws (above and below median); the fourth row looks at the differential impact between the gender gap (women - men) in countries with the female over male labor force participation ratio above and below median. Panel (c): the first row looks at the differential impact between better and worse performing workers at baseline in terms of salary growth; the second row looks at the differential impact between the top 10\% and the bottom 10\% workers in terms of salary growth; the third row looks at the differential impact between better and worse performing teams at baseline in terms of salary growth; the fourth row looks at the differential impact between workers changing and not changing the manager 2 years after the transition." "\end{tablenotes}")