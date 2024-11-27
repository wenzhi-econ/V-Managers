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
    "${RawMNEData}/AllSnapshotWC.dta"
    "${TempData}/01WorkersOutcomes.dta" <== constructed in 0101 do file 
    "${TempData}/03EventStudyDummies_EarlyAgeM.dta" <== constructed in 0103_01 do file 
    "${TempData}/05MngrWorkerRelations.dta" <== constructed in 0105 do file 
    "${RawCntyData}/2.WEF ProblemFactor.dta" ==> taken as raw datasets 
    "${TempData}/MType.dta" ==> Not self-constructed, taken as raw datasets for now
    
Output:
    "${TempData}/06MainOutcomesInEventStudies_Heterogeneity_WorkerPanel.dta"

RA: WWZ 
Time: 2024-10-21
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create new variables for heterogeneity indicators 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. manager characteristics
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawMNEData}/AllSnapshotWC.dta", clear 
sort IDlse YearMonth

global Mngr_Vars OfficeCode Female Tenure 

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

use "${RawMNEData}/03EventStudyDummies.dta", clear 
xtset IDlse YearMonth
sort  IDlse YearMonth

foreach var in IDlseMHR {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. 
}

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
generate LowFLFP1 = 1 if FMShareEducWB1<=0.89 // median
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

save "${TempData}/06MainOutcomesInEventStudies_Heterogeneity_WorkerPanel.dta", replace 