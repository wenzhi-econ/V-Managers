/* 
This do file constructs a set of variables that are used in heterogeneity analysis:
    TenureMHigh0 
    SameOffice0 
    Young0 
    TenureLow0 
    SameGender0 
    OfficeSizeHigh0 
    JobNum0 
    LaborRegHigh0 
    WPerf0 
    WPerf0p10p900 
    TeamPerfMBase0 
    DiffM2y0

Input:
    "${TempData}/01WorkersOutcomes.dta" <== constructed in 0101 do file 
    "${TempData}/03EventStudyDummies_EarlyAgeM.dta" <== constructed in 0103_01 do file 
    "${TempData}/05MngrWorkerRelations.dta" <== constructed in 0105 do file 
    "${RawCntyData}/2.WEF ProblemFactor.dta" ==> taken as raw datasets 
    "${TempData}/MType.dta" ==> Not self-constructed, taken as raw datasets for now
    
Output:
    "${TempData}/06MainOutcomesInEventStudies_Heterogeneity.dta"

RA: WWZ 
Time: 2024-10-21
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplest possible dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. obtain relevant variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/01WorkersOutcomes.dta", clear 

global eventdummies IDlseMHR ChangeMR EarlyAgeM FT_Mngr_both_WL2 FT_Rel_Time ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Never_ChangeM ///
    FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL

merge 1:1 IDlse YearMonth using "${TempData}/03EventStudyDummies_EarlyAgeM.dta", generate(_merge_outcome_eventdummies) keepusing($eventdummies)

merge 1:1 IDlse YearMonth using "${TempData}/05MngrWorkerRelations.dta", generate(_merge_mngrworkerrelation)

order IDlse YearMonth ///
    IDlseMHR ChangeMR EarlyAgeM FT_Mngr_both_WL2 ///
    FT_Rel_Time FT_Mngr_both_WL2 FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Never_ChangeM ///
    FT_Calend_Time_LtoL FT_Calend_Time_LtoH FT_Calend_Time_HtoH FT_Calend_Time_HtoL ///
    TenureM SameOffice SameGender OfficeSize ///
    TransferSJVC TransferFuncC LogPayBonus LogPay LogBonus ChangeSalaryGradeC ///
    StandardJob Func SalaryGrade Office SubFunc Org4 OfficeCode Pay Bonus Benefit Package

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
generate TenureMHigh0 = (TenureM0>=7)

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
encode StandardJob, gen(StandardJobE)
egen oj = group(Office StandardJobE)
bysort Office YearMonth: egen JobNumOffice = total(oj) 
bysort IDlse: egen JobNumOffice0= mean(cond(FT_Rel_Time==0, JobNumOffice, .))
summarize JobNumOffice0 if Ind_tag==1, detail 
generate JobNum0 = (JobNumOffice0 > `r(p50)') if JobNumOffice0!=. 

*!! LaborRegHigh0
merge m:1 ISOCode Year using "${RawCntyData}/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF LaborRegWEFB)
    keep if _merge!=2
    drop _merge 
bysort IDlse: egen LaborRegHigh0= mean(cond(FT_Rel_Time==0, LaborRegWEFB, .))

*!! LowFLFP0
generate Cohort = AgeBand
merge m:1 ISOCode Cohort using "${RawCntyData}/3.WB FMShares Decade.dta", keepusing(FMShareEducWB)
    drop if _merge==2
    drop _merge  

sort IDlse YearMonth
bysort IDlse: egen FMShareEducWB0= mean(cond(FT_Rel_Time==0, FMShareEducWB, .))

summarize FMShareEducWB0, detail
generate LowFLFP0 = 1 if FMShareEducWB0<=0.89
replace  LowFLFP0 = 0 if LowFLFP0 ==. & FMShareEducWB0!=.

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


save "${TempData}/06MainOutcomesInEventStudies_Heterogeneity.dta", replace 