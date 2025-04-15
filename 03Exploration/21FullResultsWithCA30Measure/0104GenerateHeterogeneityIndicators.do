/* 
This do file constructs a set of variables that are used in heterogeneity analysis:
    TenureMHigh1
    SameOffice1
    Young1
    SameGender1
    OfficeSizeHigh1
    JobNum1
    LaborRegHigh1
    LowFLFP1
    WPerf1
    WPerf0p10p901
    TeamPerfMBase1

Notes:
    (1) The final output dataset contains only the analysis sample (i.e., employees that are in event studies).
    (2) The heterogeneity indicators are calculated based on the median among the analysis sample. That is, employees that are not in event studies do not affect the calculation of these indicators.
    (3) The above principle does not apply to the calculation of team-level salary growth and office-level size and job diversity, where all members for a given team are used to calculate the team-level average salary growth rate.

Input:
    "${RawMNEData}/AllSnapshotWC.dta"                <== raw data 
    "${RawCntyData}/2.WEF ProblemFactor.dta"         <== raw data (country level)
    "${RawCntyData}/3.WB FMShares Decade"            <== raw data (country level)
    "${TempData}/01WorkersOutcomes.dta"              <== created in 0101 do file 
    "${TempData}/FinalAnalysisSample.dta"            <== created in 0103_03 do file 
    
Output:
    "${TempData}/0104Mngr_Characteristics.dta"                  <== auxiliary dataset 
    "${TempData}/0104Mngr_TeamPayGrowth.dta"                    <== auxiliary dataset
    "${TempData}/0104Office_Size.dta"                           <== auxiliary dataset
    "${TempData}/0104AnalysisSample_WithHeteroIndicators.dta"   <== main output dataset

Description of the Output Dataset:
    (1) It adds heterogeneity indicators used in heterogeneity table to the basic final analysis sample dataset "FinalAnalysisSample.dta".

RA: WWZ 
Time: 2025-04-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. auxiliary datasets with manager and office-level variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

//&? the construction of these variables need to be based on the full sample, instead of only the analysis sample.
//&? thus, I use "${TempData}/0101_01WorkersOutcomes.dta" (created in 0101_01) as the starting point.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. managers' personal characteristics
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/0101_01WorkersOutcomes.dta", clear 
sort IDlse YearMonth

global Mngr_Vars Female WL Tenure AgeBand Func OfficeCode ISOCode HomeCountryISOCode
keep IDlse YearMonth $Mngr_Vars
foreach var in $Mngr_Vars {
    rename `var' `var'M 
}
rename IDlse IDlseMHR
label drop _all 
save "${TempData}/0104Mngr_Characteristics.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. managers' team-level average pay growth rates
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/0101_01WorkersOutcomes.dta", clear 
sort  IDlse YearMonth
xtset IDlse YearMonth

generate PayGrowth = LogPayBonus - l.LogPayBonus
collapse (mean) AvPayGrowth = PayGrowth, by(IDlseMHR YearMonth)

save "${TempData}/0104Mngr_TeamPayGrowth.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. offices' sizes and job diversity variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/0101_01WorkersOutcomes.dta", clear 
sort  IDlse YearMonth

keep IDlse YearMonth OfficeCode StandardJob
sort OfficeCode YearMonth StandardJob IDlse

bysort OfficeCode YearMonth: egen OfficeSize    = count(IDlse)
bysort OfficeCode YearMonth: egen OfficeJobSize = count(StandardJob) 

keep OfficeCode YearMonth OfficeSize OfficeJobSize
duplicates drop 

save "${TempData}/0104Office_Size.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. merge manager- and office-level variables to analysis sample 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
xtset IDlse YearMonth
sort  IDlse YearMonth

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. merge the three datasets into the analysis sample 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR YearMonth using "${TempData}/0104Mngr_Characteristics.dta", keep(match master) nogenerate
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                         6,948
        from master                     6,948  
        from using                          0  

    Matched                         1,904,711  
    -----------------------------------------
*/

merge m:1 IDlseMHR YearMonth using "${TempData}/0104Mngr_TeamPayGrowth.dta", keepusing(AvPayGrowth) keep(match master) nogenerate
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                         1,911,659  
    -----------------------------------------
*/

merge m:1 OfficeCode YearMonth using "${TempData}/0104Office_Size.dta", keep(match master) nogenerate
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                         1,911,659  
    -----------------------------------------
*/

//&? notice that the resulting dataset is based on "${TempData}/FinalAnalysisSample.dta", which contains only the analysis sample.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. check the new variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

label variable FuncM               "Manager's function"   
label variable ISOCodeM            "Manager's working country"
label variable OfficeCodeM         "Manager's working office"
label variable HomeCountryISOCodeM "Manager's home country"
label variable FemaleM             "Female (manager)"
label variable AgeBandM            "Manager's age band"
label variable TenureM             "Manager's tenure"
label variable WLM                 "Manager's work level"
label variable AvPayGrowth         "Average pay growth among employees supervised by the manager"
label variable OfficeSize          "Office size"
label variable OfficeJobSize       "Number of different standard jobs in an office"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. heterogeneity indicators based on manager-worker relationship
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
/* 
impt: On the construction of these heterogeneity indicators: 
Take the "TenureMHigh1" heterogeneity indicator as an example. 
Current sample is a panel of workers appeared in the event studies. 
"TenureM1" is the tenure of the post-event manager at the time of event (individual-level variable).
I wish to classify these post-event managers into two categories: High-tenure vs Low-tenure managers.
The median cannot be calculated based on a cross-section of these managers, since one manager can be involved in multiple events, and thus have different tenures at the time of event.
It is not good to calculate the median based on a cross-section of manager-eventtime pairs, since this naturally puts more weights on those managers that are involved in more events. (Ideally, we want the weights to be based on workers, which are the analysis units in the event studies).
Therefore, all heterogeneity indicators (whether they are manager characteristics, worker characteristics, or office/country characteristics) are calculated by a naive command like the following:
    summarize TenureM1, detail 
    generate TenureMHigh1 = (TenureM1>=r(p50)) if TenureM1!=.
*/
/* 
Notes on the naming convention: 
    (1) TenureM is the manager's tenure, which varies with time.
    (2) TenureM1 is the tenure of the event worker's manager at the event time.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. manager tenure, high 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen TenureM1= mean(cond(Rel_Time==0, TenureM, .))
summarize TenureM1, detail 
generate TenureMHigh1 = (TenureM1>=r(p50)) if TenureM1!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. same office as manager
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate DiffOffice = 0
replace  DiffOffice = 1 if OfficeCode!=OfficeCodeM
replace  DiffOffice = . if ((OfficeCode==.)  | (OfficeCodeM==.))
generate SameOffice = 1 - DiffOffice 

sort IDlse YearMonth
bysort IDlse: egen SameOffice1= mean(cond(Rel_Time==0, SameOffice, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. same gender as manager
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate SameGender = 0
replace  SameGender = 1 if Female==FemaleM
replace  SameGender = . if ((Female==.) | (FemaleM==.))

sort IDlse YearMonth
bysort IDlse: egen SameGender1= mean(cond(Rel_Time==0, SameGender, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. worker age, young 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Age1 = mean(cond(Rel_Time==0, AgeBand, .))
generate Young1 = (Age1==1) if Age1!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-5. office size, large  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen OfficeSize1= mean(cond(Rel_Time==0, OfficeSize, .))
summarize OfficeSize1, detail 
generate OfficeSizeHigh1 = (OfficeSize1>r(p50)) if OfficeSize1!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-6. office job diversity, high  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

bysort IDlse: egen JobNumOffice1= mean(cond(Rel_Time==0, OfficeJobSize, .))
summarize JobNumOffice1, detail 
generate JobNum1 = (JobNumOffice1 >= r(p50)) if JobNumOffice1!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-7. labor laws, high  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 ISOCode Year using "${RawCntyData}/2.WEF ProblemFactor.dta", keepusing(LaborRegWEF LaborRegWEFB)
    keep if _merge!=2
    drop _merge 
bysort IDlse: egen LaborReg= mean(cond(Rel_Time==0, LaborRegWEF, .))

summarize LaborReg, detail
generate  LaborRegHigh1 = 1 if LaborReg>=r(p50)
replace   LaborRegHigh1 = 0 if LaborRegHigh1==. & LaborReg!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-8. female labor force participation, low  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Cohort = AgeBand
merge m:1 ISOCode Cohort using "${RawCntyData}/3.WB FMShares Decade.dta", keepusing(FMShareEducWB FMShareWB)
    drop if _merge==2
    drop _merge  

sort IDlse YearMonth
bysort IDlse: egen FMShareEducWB1= mean(cond(Rel_Time==0, FMShareEducWB, .))

summarize FMShareEducWB1, detail
generate LowFLFP1 = 1 if FMShareEducWB1<=r(p50)
replace  LowFLFP1 = 0 if LowFLFP1==. & FMShareEducWB1!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-9. worker performance, high   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

xtset IDlse YearMonth 
generate PayGrowth = d.LogPayBonus 

sort IDlse YearMonth
bysort IDlse: egen PayGrowth1 = mean(cond(inrange(Rel_Time, -24, -1), PayGrowth , .))
summarize PayGrowth1, detail
generate WPerf0B    = (PayGrowth1 >= r(p50)) if PayGrowth1!=.
generate WPerf0p10B = (PayGrowth1 <= r(p10)) if PayGrowth1!=.
generate WPerf0p90B = (PayGrowth1 >= r(p90)) if PayGrowth1!=.

generate WPerf0p10p90B = .
replace  WPerf0p10p90B = 0 if WPerf0p10B==1
replace  WPerf0p10p90B = 1 if WPerf0p90B==1

rename WPerf0B WPerf1
rename WPerf0p10p90B WPerf0p10p901

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-9. team performance, high   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen TeamPerf1 = mean(cond(inrange(Rel_Time, -24, -1), AvPayGrowth, .))

summarize TeamPerf1, detail
generate TeamPerfM0B = (TeamPerf1>=r(p50)) if TeamPerf1!=.
rename TeamPerfM0B TeamPerfMBase1

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. save the dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

label variable TenureMHigh1      "Post-event manager has a high tenure at the event time"
label variable SameOffice1       "Post-event manager shares the same office with the worker"
label variable SameGender1       "Post-event manager shares the same gender with the worker"
label variable Young1            "The worker at the event time is below 30 years old"
label variable OfficeSizeHigh1   "Post-event office size is large" 
label variable JobNum1           "Post-event office has a large number of different StandardJobs" 
label variable LaborRegHigh1     "Country is highly labor law regulated"
label variable LowFLFP1          "Country has a low female labor force participation rate"
label variable WPerf1            "The worker's baseline pay growth is above 50%"
label variable WPerf0p10p901     "=1, if the worker's baseline pay growth is above 90%; =0, if below 10%"
label variable TeamPerfMBase1    "The worker's associated team has a high baseline pay growth"

keep Year - OfficeJobSize ///
    TenureMHigh1 SameOffice1 SameGender1 Young1 ///
    OfficeSizeHigh1 JobNum1 LaborRegHigh1 LowFLFP1 ///
    WPerf1 WPerf0p10p901 TeamPerfMBase1


sort IDlse YearMonth
save "${TempData}/0104AnalysisSample_WithHeteroIndicators.dta", replace 

