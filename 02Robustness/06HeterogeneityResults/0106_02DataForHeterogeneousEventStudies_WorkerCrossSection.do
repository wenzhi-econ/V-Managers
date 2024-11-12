/* 
This do file constructs a set of variables that are used in heterogeneity analysis:
    TenureMHigh1 
    SameOffice1 
    Young1 
    TenureLow1 
    SameGender1 
    OfficeSizeHigh1 
    JobNum1 
    LaborRegHigh1 
    WPerf1 
    WPerf0p10p901 
    TeamPerfMBase1 
    DiffM2y1

Input:
    "${TempData}/01WorkersOutcomes.dta" <== constructed in 0101 do file 
    "${TempData}/03EventStudyDummies_EarlyAgeM.dta" <== constructed in 0103_01 do file 
    "${TempData}/05MngrWorkerRelations.dta" <== constructed in 0105 do file 
    "${RawCntyData}/2.WEF ProblemFactor.dta" ==> taken as raw datasets 
    "${TempData}/MType.dta" ==> Not self-constructed, taken as raw datasets for now
    
Output:
    "${TempData}/06MainOutcomesInEventStudies_Heterogeneity_WorkerCrossSection.dta"

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
*-? s-1-2. keep only workers in the event studies sample  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1 
    //&? a panel of workers used in event studies
    //&? all medians are calculated among these event workers
    //&? the sample matters as I need to calculate median as heterogeneity indicators 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. replace manager ID and generate tags  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

egen Mngr_tag = tag(IDlseMHR)
egen Ind_tag  = tag(IDlse)
    //&? Only Ind_tag variable matters 
    //&? (see the TenureMHigh1 example on why the Mngr_tag should not be used even if we are caring about managers' characteristics)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. generate heterogeneity indicators 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! SameOffice1 SameGender1
foreach v in SameOffice SameGender {
    bysort IDlse: egen `v'1= mean(cond(FT_Rel_Time==0, `v', .))
}

*!! TenureMHigh1
*&& First, calculate the tenure of the post-event manager at the event date (individual-level variable).
bysort IDlse: egen TenureM1= mean(cond(FT_Rel_Time==0, TenureM, .))

*&& Next, calculate the median tenure among the sample of event workers.
* impt: Note that this calculation should not be based on a sample of managers like the original codes do (summarize TenureM0 if Mngr_tag==1, detail).
* impt: Because a manager can be involved in multiple events at multiple dates.
* impt: This means that TenureM1 is at worker-level instead of manager-level.
* impt: The following calculation is based on the worker sample, 
* impt: so one manager can be calculated multiple times 
* impt: (based on how many his subordinate workers are in event studies), 
* impt: which can be justified by some kinds of weighting.
summarize TenureM1 if Ind_tag==1, detail 
generate TenureMHigh1 = (TenureM1>=r(p50)) if TenureM1!=.

*!! Young1
bysort IDlse: egen Age1 = mean(cond(FT_Rel_Time==0, AgeBand, .))
generate Young1 = Age1==1 if Age1!=.

*!! TenureLow1
bysort IDlse: egen Tenure1 = mean(cond(FT_Rel_Time==0, Tenure, .))
summarize Tenure1 if Ind_tag==1, detail
generate TenureLow1 = (Tenure1<=r(p50)) if Tenure1!=. 

*!! OfficeSizeHigh1
bysort IDlse: egen OfficeSize1= mean(cond(FT_Rel_Time==0, OfficeSize, .))
summarize OfficeSize1 if Ind_tag==1, detail 
generate OfficeSizeHigh1 = (OfficeSize1>r(p50)) if OfficeSize1!=.

*!! JobNum1
encode StandardJob, gen(StandardJobE)
egen oj = group(Office StandardJobE)
bysort Office YearMonth: egen JobNumOffice = total(oj) 
bysort IDlse: egen JobNumOffice1= mean(cond(FT_Rel_Time==0, JobNumOffice, .))
summarize JobNumOffice1 if Ind_tag==1, detail 
generate JobNum1 = (JobNumOffice1 >= r(p50)) if JobNumOffice1!=. 

*!! LaborRegHigh1
merge m:1 ISOCode Year using "${RawCntyData}/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF LaborRegWEFB)
    keep if _merge!=2
    drop _merge 
bysort IDlse: egen LaborRegHigh1= mean(cond(FT_Rel_Time==0, LaborRegWEFB, .))

*!! LowFLFP1 LowWholeFLFP1
generate Cohort = AgeBand
merge m:1 ISOCode Cohort using "${RawCntyData}/3.WB FMShares Decade.dta", keepusing(FMShareEducWB FMShareWB)
    drop if _merge==2
    drop _merge  

sort IDlse YearMonth
bysort IDlse: egen FMShareEducWB1= mean(cond(FT_Rel_Time==0, FMShareEducWB, .))

sort IDlse YearMonth
bysort IDlse: egen FMShareWB1= mean(cond(FT_Rel_Time==0, FMShareWB, .))

summarize FMShareEducWB1 if Ind_tag==1, detail
generate LowFLFP1 = 1 if FMShareEducWB1<=r(p50)
replace  LowFLFP1 = 0 if LowFLFP1==. & FMShareEducWB1!=.

summarize FMShareWB1 if Ind_tag==1, detail
generate LowWholeFLFP1 = 1 if FMShareWB1<=r(p50)
replace  LowWholeFLFP1 = 0 if LowFLFP1==. & FMShareWB1!=.

*!! WPerf1 WPerf0p10p901
xtset IDlse YearMonth 
generate PayGrowth = d.LogPayBonus 
foreach var in PayGrowth { 
	bysort IDlse: egen `var'1 = mean(cond(inrange(FT_Rel_Time, -24, -1), `var' , .))
	summarize `var'1 if Ind_tag==1, detail
	generate WPerf0B    = (`var'1 >  r(p50)) if `var'1!=.
	generate WPerf0p10B = (`var'1 <= r(p10)) if `var'1!=.
	generate WPerf0p90B = (`var'1 >= r(p90)) if `var'1!=.
}
generate WPerf0p10p90B = 0 if WPerf0p10B==1
replace  WPerf0p10p90B = 1 if WPerf0p90B==1

rename WPerf0B WPerf1
rename WPerf0p10p90B WPerf0p10p901

*!! TeamPerfMBase1
merge m:1 IDlseMHR YearMonth using "${FinalData}/MType.dta", keepusing(AvPayGrowth)
    keep if _merge!=2
    drop _merge 
bysort IDlse: egen TeamPerf1 = mean(cond(inrange(FT_Rel_Time, -24, -1), AvPayGrowth, .))

summarize TeamPerf1 if Ind_tag==1, detail
generate TeamPerfM0B = (TeamPerf1>r(p50)) if TeamPerf1!=.
rename TeamPerfM0B TeamPerfMBase1

*!! DiffM2y1
bysort IDlse: egen MPost2y = mean(cond(FT_Rel_Time==24, IDlseMHR, .))
bysort IDlse: egen MPre    = mean(cond(FT_Rel_Time==0,  IDlseMHR, .)) 
generate DiffM2y = (MPost2y!=MPre) if MPost2y!=. & MPre!=.
rename DiffM2y DiffM2y1


save "${TempData}/06MainOutcomesInEventStudies_Heterogeneity_WorkerCrossSection.dta", replace 