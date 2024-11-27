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
    LowFLFP1
    WPerf1
    WPerf0p10p901
    TeamPerfMBase1
    DiffM2y1

Input:
    "${RawMNEData}/AllSnapshotWC.dta"        <== raw data 
    "${TempData}/03EventStudyDummies.dta"    <== created in 0103 do file 
    "${RawCntyData}/2.WEF ProblemFactor.dta" <== raw data (country level)
    "${RawCntyData}/3.WB FMShares Decade"    <== raw data (country level)
    "${FinalData}/MType.dta"                 ==> not self-constructed, taken as raw datasets for now
    
Output:
    ${TempData}/temp_Mngr_Characteristics.dta <== auxiliary dataset 
    "${TempData}/04MainOutcomesInEventStudies.dta" <== key output dataset

Description of the Output Dataset:
    On the one hand, it adds more heterogeneity indicators used in analysis to the "${TempData}/03EventStudyDummies.dta" dataset.
    On the other hand, it excludes many not so relevant variables in the raw dataset and auxiliary variables from the dataset to reduce the size.
    In particular, a set of heterogeneity indicators used in the heterogeneity table.
    Note: 
        All subsequent individual-level analysis will be mainly using this dataset!

RA: WWZ 
Time: 2024-11-26
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create new variables for heterogeneity indicators 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. manager characteristics
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawMNEData}/AllSnapshotWC.dta", clear 
sort IDlse YearMonth

global Mngr_Vars Female Tenure AgeBand Func OfficeCode ISOCode HomeCountryISOCode

keep IDlse YearMonth $Mngr_Vars

foreach var in $Mngr_Vars {
    rename `var' `var'M 
}
rename IDlse IDlseMHR

label drop _all 

save "${TempData}/temp_Mngr_Characteristics.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge manager characteristics back to the main datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/03EventStudyDummies.dta", clear 
xtset IDlse YearMonth
sort  IDlse YearMonth

merge m:1 IDlseMHR YearMonth using "${TempData}/temp_Mngr_Characteristics.dta", keep(match master) nogenerate

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. construct relevant variables on manager-worker relationship
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! SameOffice
generate DiffOffice = 0
replace  DiffOffice  = 1 if OfficeCode!=OfficeCodeM
replace  DiffOffice  = . if ((OfficeCode==.)  | (OfficeCodeM==.))
label variable DiffOffice "=1 if manager in different office"

generate SameOffice = 1 - DiffOffice 
label variable SameOffice "=1 if manager in same office"

*!! SameGender
generate SameGender = 0
replace  SameGender = 1 if Female==FemaleM
replace  SameGender = . if ((Female==.) | (FemaleM==.))
label variable SameGender "=1 if employee has same gender as manager"

*!! OfficeSize
sort Office YearMonth
bysort Office YearMonth: egen OfficeSize = count(IDlse)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. create heterogeneity indicators 
*??         based on different variable values at the time of event 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. a variable that indicates the worker is in event studies analysis 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate q_eventstudies = (FT_Rel_Time!=. & FT_Mngr_both_WL2==1)
    //&? All median calculation should be in the sample restricted by if q_eventstudies==1
    //&? A panel of workers used in event studies
    //&? All medians are calculated among these event workers.
    //&? The sample matters as I need to calculate different medians as heterogeneity indicators.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. generate heterogeneity indicators 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* 
impt: On the construction of these heterogeneity indicators: 
Take the "TenureMHigh1" heterogeneity indicator as an example. 
Current sample (restricted by if q_eventstudies==1) is a panel of workers appeared in the event studies. 
"TenureM1" is the tenure of the post-event manager at the time of event (individual-level variable).
I wish to classify these post-event managers into two categories: High-tenure vs Low-tenure managers.
The median cannot be calculated based on a cross-section of these managers, since one manager can be involved in multiple events, and thus have different tenures at the time of event.
It is not good to calculate the median based on a cross-section of manager-eventtime pairs, since this naturally puts more weights on those managers that are involved in more events. (Ideally, we want the weights to be based on workers, which are the analysis units in the event studies).
Therefore, all heterogeneity indicators (whether they are manager characteristics, worker characteristics, or office/country characteristics) are calculated by a naive command like the following:
    summarize TenureM1, detail 
    generate TenureMHigh1 = (TenureM1>=r(p50)) if TenureM1!=.
*/

*!! SameOffice1 SameGender1
foreach v in SameOffice SameGender {
    bysort IDlse: egen `v'1= mean(cond(FT_Rel_Time==0, `v', .))
}

*!! TenureMHigh1
bysort IDlse: egen TenureM1= mean(cond(FT_Rel_Time==0, TenureM, .))
summarize TenureM1 if q_eventstudies==1, detail 
generate TenureMHigh1 = (TenureM1>=r(p50)) if TenureM1!=.

*!! Young1
bysort IDlse: egen Age1 = mean(cond(FT_Rel_Time==0, AgeBand, .))
generate Young1 = Age1==1 if Age1!=.

*!! TenureLow1
bysort IDlse: egen Tenure1 = mean(cond(FT_Rel_Time==0, Tenure, .))
summarize Tenure1 if q_eventstudies==1, detail
generate TenureLow1 = (Tenure1<=r(p50)) if Tenure1!=.

*!! OfficeSizeHigh1
bysort IDlse: egen OfficeSize1= mean(cond(FT_Rel_Time==0, OfficeSize, .))
summarize OfficeSize1 if q_eventstudies==1, detail 
generate OfficeSizeHigh1 = (OfficeSize1>r(p50)) if OfficeSize1!=.

*!! JobNum1
capture drop StandardJobE
encode StandardJob, gen(StandardJobE)
egen oj = group(Office StandardJobE)
bysort Office YearMonth: egen JobNumOffice = total(oj) 
bysort IDlse: egen JobNumOffice1= mean(cond(FT_Rel_Time==0, JobNumOffice, .))
summarize JobNumOffice1 if q_eventstudies==1, detail 
generate JobNum1 = (JobNumOffice1 >= r(p50)) if JobNumOffice1!=.

*!! LaborRegHigh1
merge m:1 ISOCode Year using "${RawCntyData}/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF LaborRegWEFB)
    keep if _merge!=2
    drop _merge 
bysort IDlse: egen LaborRegHigh1= mean(cond(FT_Rel_Time==0, LaborRegWEFB, .))

*!! LowFLFP1
generate Cohort = AgeBand
merge m:1 ISOCode Cohort using "${RawCntyData}/3.WB FMShares Decade.dta", keepusing(FMShareEducWB FMShareWB)
    drop if _merge==2
    drop _merge  

sort IDlse YearMonth
bysort IDlse: egen FMShareEducWB1= mean(cond(FT_Rel_Time==0, FMShareEducWB, .))

summarize FMShareEducWB1 if q_eventstudies==1, detail
generate LowFLFP1 = 1 if FMShareEducWB1<=0.89 & q_eventstudies==1 // median
replace  LowFLFP1 = 0 if LowFLFP1==. & FMShareEducWB1!=.

*!! WPerf1 WPerf0p10p901
xtset IDlse YearMonth 
generate PayGrowth = d.LogPayBonus 
foreach var in PayGrowth { 
	bysort IDlse: egen `var'1 = mean(cond(inrange(FT_Rel_Time, -24, -1), `var' , .))
	summarize `var'1 if q_eventstudies==1, detail
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

summarize TeamPerf1 if q_eventstudies==1, detail
generate TeamPerfM0B = (TeamPerf1>=r(p50)) if TeamPerf1!=.
rename TeamPerfM0B TeamPerfMBase1

*!! DiffM2y1
bysort IDlse: egen MPost2y = mean(cond(FT_Rel_Time==24, IDlseMHR, .))
bysort IDlse: egen MPre    = mean(cond(FT_Rel_Time==0,  IDlseMHR, .)) 
generate DiffM2y = (MPost2y!=MPre) if MPost2y!=. & MPre!=.
rename DiffM2y DiffM2y1

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? final step. save only necessary variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep ///
    IDlse YearMonth ///
    IDlseMHR EarlyAgeM ChangeM ChangeMR ///
    FT_Mngr_both_WL2 FT_Never_ChangeM ///
    FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time FT_Calend_Time_* ///
    TransferSJV TransferSJVC TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC ///
    TransferSJ TransferSJC TransferInternal TransferInternalC TransferInternalSJ TransferInternalSJC ///
    ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC ///
    Leaver LeaverPerm LeaverInv LeaverVol ///
    LogPayBonus LogPay LogBonus ///
    Female AgeBand Tenure WL Func SubFunc Office OfficeCode SalaryGrade ///
    ISOCode Country HomeCountryISOCode ///
    Org4 Org5 Pay Bonus PayBonus BonusPayRatio Benefit LogBenefit Package LogPackage ///
    StandardJob ONETName ONETCode ONETDistance ONETDistanceC ONETB ONETBC ONETSkillsDistance ONETContextDistance ONETActivitiesDistance ONETAbilitiesDistance ONETAbilitiesDistanceC ONETActivitiesDistanceC ONETContextDistanceC ONETSkillsDistanceC ///
    WLM FemaleM TenureM AgeBandM FuncM OfficeCodeM ISOCodeM HomeCountryISOCodeM ///
    q_eventstudies TenureMHigh1 SameOffice1 Young1 TenureLow1 SameGender1 OfficeSizeHigh1 JobNum1 LaborRegHigh1 LowFLFP1 WPerf1 WPerf0p10p901 TeamPerfMBase1 DiffM2y1

order ///
    IDlse YearMonth ///
    IDlseMHR EarlyAgeM ChangeM ChangeMR ///
    FT_Mngr_both_WL2 FT_Never_ChangeM ///
    FT_Rel_Time FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Event_Time FT_Calend_Time_* ///
    TransferSJV TransferSJVC TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC ///
    TransferSJ TransferSJC TransferInternal TransferInternalC TransferInternalSJ TransferInternalSJC ///
    ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC ///
    Leaver LeaverPerm LeaverInv LeaverVol ///
    LogPayBonus LogPay LogBonus ///
    Female AgeBand Tenure WL Func SubFunc Office OfficeCode SalaryGrade ///
    ISOCode Country HomeCountryISOCode ///
    Org4 Org5 Pay Bonus PayBonus BonusPayRatio Benefit LogBenefit Package LogPackage ///
    StandardJob ONETName ONETCode ONETDistance ONETDistanceC ONETB ONETBC ONETSkillsDistance ONETContextDistance ONETActivitiesDistance ONETAbilitiesDistance ONETAbilitiesDistanceC ONETActivitiesDistanceC ONETContextDistanceC ONETSkillsDistanceC ///
    WLM FemaleM TenureM AgeBandM FuncM OfficeCodeM ISOCodeM HomeCountryISOCodeM ///
    q_eventstudies TenureMHigh1 SameOffice1 Young1 TenureLow1 SameGender1 OfficeSizeHigh1 JobNum1 LaborRegHigh1 LowFLFP1 WPerf1 WPerf0p10p901 TeamPerfMBase1 DiffM2y1

label variable IDlse      "Employee ID"
label variable YearMonth  "Year-Month"
label variable IDlseMHR   "Employee's manager ID"
label variable EarlyAgeM  "=1, if the manager is a high-flyer (determined by age at promotion)"
label variable ChangeM    "=1, at the month when the manager is different from that in previous month"
label variable ChangeMR   "=1, at the month when the worker experiences his first pure manager change event"

label variable Leaver     "=1, at the month when the employee leaves the firm"
label variable LeaverPerm "=1, at the month when the employee permanently leaves the firm"
label variable LeaverVol  "=1, at the month when the employee voluntarily leaves (quits) the firm"
label variable LeaverInv  "=1, at the month when the employee involuntarily leaves (gets laidoff) the firm"

label variable Female     "=1, if the employee is a female"
label variable AgeBand    "Age band (in ten years)"
label variable Tenure     "Years within the firm"
label variable WL         "Work level"
label variable Func       "Function"
label variable SubFunc    "Subfunction"

label variable WLM                 "Manager's work level"
label variable FemaleM             "Manager's gender"
label variable TenureM             "Manager's years within the firm"
label variable AgeBandM            "Manager's age band (in ten years)"
label variable FuncM               "Manager's function"
label variable ISOCodeM            "Manager's working country"
label variable HomeCountryISOCodeM "Manager's home country"
label variable OfficeCodeM         "Manager's office code"

*&? The following indicators are only defined for workers in the event studies sample, i.e., under q_eventstudies==1

label variable TenureMHigh1      "Post-event manager has a high tenure at the event time"
label variable SameOffice1       "Post-event manager shares the same office with the worker"
label variable Young1            "The worker at the event time is below 30 years old"
label variable TenureLow1        "The worker at the event time has a short tenure"
label variable SameGender1       "Post-event manager shares the same gender with the worker"
label variable OfficeSizeHigh1   "Post-event office size is large" 
label variable JobNum1           "Post-event office has a large number of different StandardJobs" 
label variable LaborRegHigh1     "Country is highly labor law regulated"
label variable LowFLFP1          "Country has a low female labor force participation rate"
label variable WPerf1            "The worker's baseline pay growth is above 50%"
label variable WPerf0p10p901     "=1, if the worker's baseline pay growth is above 90%; =0, if below 10%"
label variable TeamPerfMBase1    "The worker's associated team has a high baseline pay growth"
label variable DiffM2y1          "=1, if post-event manager is no longer 24 months after the event"

compress
sort IDlse YearMonth
save "${TempData}/04MainOutcomesInEventStudies.dta", replace 