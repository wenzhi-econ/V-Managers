/* 
This do file constructs cognitive, routine, and social task intensity scores for each occupation in the O*NET dataset.

Input:
    "${RawONETData}/Abilities.xlsx" <== raw data (version 29.1 ONET)
    "${RawONETData}/Skills.xlsx" <== raw data (version 29.1 ONET)
    "${RawONETData}/Knowledge.xlsx" <== raw data (version 29.1 ONET)
    "${RawONETData}/Work Context.xlsx" <== raw data (version 29.1 ONET)
    "${RawONETData}/SJ Crosswalk.xlsx" <== taken as raw data -- not sure about the construction procedures

Output:
    "${TempData}/temp_ONET_RawTaskIntensity.dta"

RA: WWZ 
Time: 2025-02-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. Abilities questionnaire
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

import excel using "${RawONETData}/Abilities.xlsx", firstrow clear

keep if ElementID=="1.A.1.c.1" & ScaleName=="Level"
    //&? mathematical reasoning

keep ONETSOCCode DataValue

generate intensity_cognitive_a = ((DataValue-1)/(7-1)) * 10

keep ONETSOCCode intensity_cognitive_a

save "${TempData}/temp_ONET_Abilities.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. Skills questionnaire
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

import excel using "${RawONETData}/Skills.xlsx", firstrow clear

keep if ///
    (ElementID=="2.A.1.e" & ScaleName=="Level") /// //&? mathematical reasoning
    | (ElementID=="2.B.5.b" & ScaleName=="Level") /// //&? management of financial resources
    | (ElementID=="2.B.5.c" & ScaleName=="Level") /// //&? management of material resources
    | (ElementID=="2.B.5.d" & ScaleName=="Level") /// //&? management of personnel resources
    | (ElementID=="2.B.1.a" & ScaleName=="Level") /// //&? social perceptiveness
    | (ElementID=="2.B.1.b" & ScaleName=="Level") /// //&? coordination
    | (ElementID=="2.B.1.c" & ScaleName=="Level") /// //&? persuasion
    | (ElementID=="2.B.1.d" & ScaleName=="Level") //&? negotiation

generate task_type = ""
replace  task_type = "cognitive_b" if ElementID=="2.A.1.e"
replace  task_type = "cognitive_d" if ElementID=="2.B.5.b"
replace  task_type = "cognitive_e" if ElementID=="2.B.5.c"
replace  task_type = "cognitive_f" if ElementID=="2.B.5.d"

replace  task_type = "social_i" if ElementID=="2.B.1.a"
replace  task_type = "social_j" if ElementID=="2.B.1.b"
replace  task_type = "social_k" if ElementID=="2.B.1.c"
replace  task_type = "social_l" if ElementID=="2.B.1.d"

keep  ONETSOCCode ElementName task_type DataValue 
order ONETSOCCode ElementName task_type DataValue

generate intensity_ = ((DataValue-1)/(7-1)) * 10

keep ONETSOCCode intensity_ task_type

reshape wide intensity_, i(ONETSOCCode) j(task_type) string

save "${TempData}/temp_ONET_Skills.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. Knowledge questionnaire
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

import excel using "${RawONETData}/Knowledge.xlsx", firstrow clear

keep if ElementID=="2.C.4.a" & ScaleName=="Level"
    //&? mathematical reasoning

keep ONETSOCCode DataValue

generate intensity_cognitive_c = ((DataValue-1)/(7-1)) * 10

keep ONETSOCCode intensity_cognitive_c

save "${TempData}/temp_ONET_Knowledge.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. Work Context questionnaire
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

import excel using "${RawONETData}/Work Context.xlsx", firstrow clear

keep if ///
    (ElementID=="4.C.3.b.2" & ScaleName=="Context") /// 
    | (ElementID=="4.C.3.b.7" & ScaleName=="Context") 

generate task_type = ""
replace  task_type = "routine_g" if ElementID=="4.C.3.b.2"
replace  task_type = "routine_h" if ElementID=="4.C.3.b.7"

keep  ONETSOCCode ElementName task_type DataValue 
order ONETSOCCode ElementName task_type DataValue

generate intensity_ = ((DataValue-1)/(5-1)) * 10

keep ONETSOCCode intensity_ task_type

reshape wide intensity_, i(ONETSOCCode) j(task_type) string

save "${TempData}/temp_ONET_WorkContext.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. occupation-level raw task intensity scores
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-1. obtain the crosswalk between MNE job titles and ONET SOC codes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawONETData}/SJ Crosswalk.dta", clear

keep StandardJobCode StandardJob ONETCode
duplicates drop 

rename ONETCode ONETSOCCode

sort ONETSOCCode StandardJobCode
bysort StandardJob: generate occurrence = _n 
bysort StandardJob: generate num_occurrence = _N 

summarize num_occurrence, detail
/* 
                       num_occurrence
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs               2,151
25%            1              1       Sum of wgt.       2,151

50%            1                      Mean           1.015807
                        Largest       Std. dev.      .1247557
75%            1              2
90%            1              2       Variance        .015564
95%            1              2       Skewness       7.764069
99%            2              2       Kurtosis       61.28077
*/

keep if occurrence==1
    //&? if a standard job title in the MNE can be matched to multiple ONETSOCCode, I will keep only the first one

save "${TempData}/temp_ONET_SJCrosswalk.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-2. average across ONET descriptors 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_ONET_Abilities.dta", clear 
merge 1:1 ONETSOCCode using "${TempData}/temp_ONET_Skills.dta", nogenerate
merge 1:1 ONETSOCCode using "${TempData}/temp_ONET_Knowledge.dta", nogenerate
merge 1:1 ONETSOCCode using "${TempData}/temp_ONET_WorkContext.dta", nogenerate

order ///
    ONETSOCCode ///
    intensity_cognitive_a intensity_cognitive_b intensity_cognitive_d intensity_cognitive_e intensity_cognitive_f ///
    intensity_routine_g intensity_routine_h ///
    intensity_social_i intensity_social_j intensity_social_k intensity_social_l

label variable intensity_cognitive_a "Cognitive task intensity: mathematical reasoning (Abilities questionnaire)"
label variable intensity_cognitive_b "Cognitive task intensity: mathematical reasoning (Skills questionnaire)"
label variable intensity_cognitive_c "Cognitive task intensity: mathematical reasoning (Knowledge questionnaire)"
label variable intensity_cognitive_d "Cognitive task intensity: management of financial resources"
label variable intensity_cognitive_e "Cognitive task intensity: management of material resources"
label variable intensity_cognitive_f "Cognitive task intensity: management of personnel resources"
label variable intensity_routine_g "Routine task intensity: degree of automation"
label variable intensity_routine_h "Routine task intensity: extent of repetitive tasks"
label variable intensity_social_i "Social task intensity: social perceptiveness"
label variable intensity_social_j "Social task intensity: coordination"
label variable intensity_social_k "Social task intensity: persuasion"
label variable intensity_social_l "Social task intensity: negotiation"

egen intensity_cognitive = rowmean(intensity_cognitive_*)
egen intensity_routine   = rowmean(intensity_routine_*)
egen intensity_social    = rowmean(intensity_social_*)

label variable intensity_cognitive "Cognitive task intensity (raw)"
label variable intensity_routine   "Routine task intensity (raw)"
label variable intensity_social    "Social task intensity (raw)"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-3. get the ONET SOC codes for MNE job titles
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge 1:m ONETSOCCode using "${TempData}/temp_ONET_SJCrosswalk.dta", keep(match)
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             1,880  (_merge==3)
    -----------------------------------------
*/
rename _merge _mrg_SJtoONETCode

order StandardJobCode StandardJob ONETSOCCode

codebook StandardJob
    //&? 1,880 standard job titles can be matched to ONETSOCCode
    //&? same as the observations in the final dataset
codebook ONETSOCCode
    //&? 79 unique ONET occupation codes

save "${TempData}/temp_ONET_RawTaskIntensity.dta", replace