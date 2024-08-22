/* 
Description of this do-file:

This do file creates a set of variables used to describe managers in the firm.

Step 1. Identify these individuals who show up as managers in the raw data.
Step 2. Introduce the most important indicator to identify a "good" manager. 
Step 3. Create other variables to measure managers' performance to validate our main measure.

Input files:
    "${RawMNEData}/AllSnapshotWC.dta" (raw data)

Output files:
    "${TempData}/Mlist.dta" (a list of employee ids who are reported as managers in a given month)
    "${FinalData}/Mangers.dta" (a panel dataset storing managers' full history)

RA: WWZ 
Time: 24/06/2024
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. who are managers? 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step1_1. create a manager list "Mlist.dta"
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/*
The variable IDlseMHR in raw data "${managersMNEdata}/AllSnapshotWC.dta" 
    contains all employees' id who are reported as managers in a given month.
I collect all distinct IDs in file "${tempdata}/Mlist.dta", 
    so that I have an exhaustive list of managers in this firm. 
*/

use "${RawMNEData}/AllSnapshotWC.dta", clear
keep IDlseMHR
rename IDlseMHR IDlse
duplicates drop IDlse, force
drop if IDlse == . 

sort IDlse
save "${TempData}/Mlist.dta", replace 
    // 47,816 distinct managers 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step1_2. merge with the dataset containing all employees in the firm 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawMNEData}/AllSnapshotWC.dta", clear 

merge m:1 IDlse using "${TempData}/Mlist.dta"
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                     6,590,995
        from master                 6,590,967  (_merge==1)
        from using                         28  (_merge==2)

    Matched                         3,492,671  (_merge==3)
    -----------------------------------------
*/
keep if _merge == 3 
drop _merge 


sort IDlse YearMonth
keep IDlse YearMonth AgeBand Tenure WL
codebook IDlse 
    // 47,788 distinct managers 
codebook AgeBand Tenure WL 
    // 115 observations with unknwon age, 8 observations with unknwon work level 
replace AgeBand = . if AgeBand == 8

/* 
Now, we have a panel data consisting of those employees who have ever been managers in this firm. 
Once an employee has been identified as a manager, I will keep his full records in the firm, 
    including his history before he becomes a manager, so that I can tell them if they fast-trackers.
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. identify "High Flyer" managers based on age of promotion 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s2_1. necessary variables related to age, tenure, and work level (WL)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s2_1_0. individual tag 
egen ind_tag = tag(IDlse)

*!! s2_1_1. generate an aggregated work level variable 
sort IDlse YearMonth
generate WLAgg = WL
replace  WLAgg = 5 if WL>4 & WL!=.
bysort IDlse: replace WLAgg = WLAgg[_n-1] if WLAgg==. & WLAgg[_n-1]!=. & IDlse==IDlse[_n-1]
    // impute 8 missing work levels with the individual's work level in the previous month 
label variable WLAgg "Aggregated work level (WLAgg = 5 for all workers whose WL > 4)"

tabulate WL, missing 
    // 0.33% managers with work level 5, 0.05% managers with work level 6
tabulate WL if ind_tag==1, missing 
    // for the first occurrence in the dataset, 0.24% managers with work level 5, 0.03% managers with work level 6
tabulate WLAgg, missing
tabulate WLAgg if ind_tag==1, missing
    // for the first occurrence in the dataset, 59.45% managers with WL1, 32.46% with WL2 

*!! s2_1_2. how many different work levels a manager has
egen ind_wl_tag = tag(IDlse WLAgg) 
bysort IDlse: egen DistinctWL = total(ind_wl_tag)
label variable DistinctWL "Number of WL per employee"
drop ind_wl_tag 
tabulate DistinctWL if ind_tag==1, missing 
    // 70.26% managers have only 1 work level in the panel we can observe
    // 28.65% managers have 2 work levels, 1.08% managers have 3 work levels, 0.01% managers with 4 work levels 

*!! s2_1_3. at what age a manager is promoted to his highest work level 
* an individual's observed lowest work level 
bysort IDlse: egen MinWL             = min(WLAgg) 
* an individual's observed highest work level 
bysort IDlse: egen MaxWL             = max(WLAgg) 
* lowest observed age when an individual is at his highest work level 
bysort IDlse: egen AgeMinMaxWL       = min( cond(WL == MaxWL, AgeBand, .) ) 
* lowest observed tenure when an individual is at his highest work level 
bysort IDlse: egen TenureMinMaxWL    = min( cond(WL == MaxWL, Tenure, .) ) 
* total number of months an individual is observed at his highest work level 
bysort IDlse: egen TenureMaxWLMonths = count(cond(WL==MaxWL, YearMonth, .) ) 
* total number of years an individual is observed at his highest work level
generate TenureMaxWL = TenureMaxWLMonths/12 

label variable MinWL             "an individual's lowest observed work level"
label variable MaxWL             "an individual's highest observed work level"
label variable AgeMinMaxWL       "lowest observed age when an individual is at his highest work level"
label variable TenureMinMaxWL    "lowest observed tenure when an individual is at his highest work level"
label variable TenureMaxWLMonths "total number of months an individual is observed at his highest work level"
label variable TenureMaxWL       "total number of years an individual is observed at his highest work level"
label values   AgeMinMaxWL AgeBand

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s2_2. fast track manager measure 1: HighFlyer1
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
TODO This issue is to be discussed!
This measure is constructed based on the orginal do file. 
However, it does not share the same procedure with that described in the paper.
In particular, all managers are identified as a fast-track manager or a slow-track manager, while there are some ambiguous cases. 
See more discussion at step s2_3.
*/

*!! what is the distribution of AgeMinMaxWL like 
tabulate AgeMinMaxWL if ind_tag==1, missing
    // 24.95% managers aged 18-29 
tabulate AgeMinMaxWL if MaxWL==2 & ind_tag==1, missing
    // 22.13% managers are aged 18-29 in 23,703 managers who satisfying the condition (MaxWL==2 & ind_tag==1)
tabulate AgeMinMaxWL if MaxWL>=2 & ind_tag==1, missing
    // 17.43% managers are aged 18-29 in 30,185 managers who satisfying the condition (MaxWL>=2 & ind_tag==1)

generate EarlyAge_Mngr = 0 
*!! from WL1 to WL2
replace  EarlyAge_Mngr = 1 if MaxWL==2 & AgeMinMaxWL==1 & TenureMaxWL<=6  
replace  EarlyAge_Mngr = 1 if MaxWL==2 & TenureMinMaxWL<=4 & MinWL==1 & TenureMaxWL<=6 
*!! from WL2 to WL3
replace  EarlyAge_Mngr = 1 if MaxWL==3 & AgeMinMaxWL<=2 & TenureMinMaxWL <=10 
*!! from WL3 to WL4 
replace  EarlyAge_Mngr = 1 if MaxWL==4 & AgeMinMaxWL<=2 
*!! from WL4 to WL5+ 
replace  EarlyAge_Mngr = 1 if MaxWL>4  & AgeMinMaxWL<=3 

label variable EarlyAge_Mngr "Fast track manager based on age when promoted (WL)"
tabulate EarlyAge_Mngr if ind_tag==1, missing 
    // 16.91% managers are identified as fast track managers

generate HighFlyer1 = EarlyAge_Mngr 
label variable HighFlyer1 "=1, if the manager is a high-flyer (original measure)"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s2_3. fast track manager measure 2: HighFlyer2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s2_3_1. auxiliary variables
* lowest observed age at work level 2 
bysort IDlse: egen AgeMinWL2    = min(cond(WL==2, AgeBand, .)) 
* highest observed age at work level 1 
bysort IDlse: egen AgeMaxWL1    = max(cond(WL==1, AgeBand, .))
* highest observed age when a manager is at his highest observed WL 
bysort IDlse: egen AgeMaxMaxWL  = max(cond(WL==MaxWL, AgeBand, .))
* lowest observed tenure when a manager is observed at his WL2 
bysort IDlse: egen TenureMinWL2 = min(cond(WL==2, Tenure, .))

label variable AgeMinWL2    "lowest observed age at work level 2"
label variable AgeMaxWL1    "highest observed age at work level 1"
label variable AgeMaxMaxWL  "highest observed age when a manager is at his highest observed WL"
label variable TenureMinWL2 "lowest observed tenure when a manager is observed at his WL2"
label values   AgeMinWL2 AgeBand 
label values   AgeMaxMaxWL AgeBand

tabulate MinWL MaxWL if ind_tag==1, missing 
/* 
        an |
individual |
 's lowest |
  observed |      an individual's highest observed work level
work level |         1          2          3          4          5 |     Total
-----------+-------------------------------------------------------+----------
         1 |    17,603     10,945        413         15          3 |    28,979 
         2 |         0     12,758      2,208        111          1 |    15,078 
         3 |         0          0      2,550        422         18 |     2,990 
         4 |         0          0          0        534         78 |       612 
         5 |         0          0          0          0        129 |       129 
-----------+-------------------------------------------------------+----------
     Total |    17,603     23,703      5,171      1,082        229 |    47,788 
*/

/* 
In the paper, you describe the construction of high-flyer measure as 
    "workers who attain work-level 2 before the age of 30"

According to the description in the paper, we can, in principle, only identify those managers in (1,2), (1,3), (1,4), and (1,5), 
    that is, we can only identify those managers whose promotion into WL2 can be observed in the dataset. 
But, there are some managers in other cells that are also identifiable. 
See my construction below.
*/

*!! high-flyer managers: the second measure
generate HighFlyer2 = . 
*!! s2_3_2. only one case is identifiable in (1,1) cell 
replace  HighFlyer2 = 0 if MinWL==1 & MaxWL==1 & AgeMaxMaxWL>1
    // these managers in (1,1) cell can never be promoted to WL2 before age 30, as their highest observed age in WL1 is greater than 30 
*!! s2_3_3. both cases are identifiable in (1,2) cell 
replace  HighFlyer2 = 1 if MinWL==1 & MaxWL==2 & AgeMinMaxWL==1
    // these managers in (1,2) cell are high-flyers as their lowest observed age in WL2 is under 30 
replace  HighFlyer2 = 0 if MinWL==1 & MaxWL==2 & AgeMinMaxWL>1
    // these managers in (1,2) cell are low-flyers as their lowest observed age in WL2 is above 30 
*!! s2_3_4. both cases are identifiable in (1,3), (1,4), (1,5) cells
replace  HighFlyer2 = 1 if MinWL==1 & MaxWL>2 & AgeMinWL2==1
    // these managers in (1,3), (1,4), (1,5) cells are high-flyers as their lowest observed age in WL2 is under 30 
replace  HighFlyer2 = 0 if MinWL==1 & MaxWL>2 & AgeMinWL2>1
    // these managers in (1,3), (1,4), (1,5) cells are low-flyers as their lowest observed age in WL2 is above 30 
*!! s2_3_5. for (2,2), (2,3), (2,4), and (2,5) cell managers, 
*!! we need to combine information about their tenure at WL2 and back out some cases 
replace  HighFlyer2 = 1 if MinWL==2 & MaxWL>=2 & AgeMinWL2==1
    // these managers in (2,2) cell are definitely high-flyers 
    // as their lowest observed age in WL2 is under 30 
replace  HighFlyer2 = 1 if MinWL==2 & MaxWL>=2 & AgeMinWL2==2 & TenureMinWL2>10 
    // these managers in (2,2) cell are definitely high-flyers 
    // their lowest observed age in WL2 is 30-39, but their lowest observed tenure in WL2 is above 10 years, 
    // implying that they must be at WL2 before the age of 30 
replace  HighFlyer2 = 1 if MinWL==2 & MaxWL>=2 & AgeMinWL2==3 & TenureMinWL2>20 
    // these managers in (2,2) cell are definitely high-flyers 
    // their lowest observed age in WL2 is 40-49, but their lowest observed tenure in WL2 is above 20 years, 
    // implying that they must be at WL2 before the age of 30 
replace  HighFlyer2 = 1 if MinWL==2 & MaxWL>=2 & AgeMinWL2==4 & TenureMinWL2>30 
    // these managers in (2,2) cell are definitely high-flyers 
    // their lowest observed age in WL2 is 50-59, but their lowest observed tenure in WL2 is above 30 years, 
    // implying that they must be at WL2 before the age of 30 

replace  HighFlyer2 = 0 if MinWL==2 & MaxWL>=2 & AgeMinWL2==3 & TenureMinWL2<=10 
    // these managers in (2,2) cell are definitely high-flyers 
    // their lowest observed age in WL2 is 40-49, but their lowest observed tenure in WL2 is below 10 years, 
    // implying that they must be at WL2 after the age of 30 
replace  HighFlyer2 = 0 if MinWL==2 & MaxWL>=2 & AgeMinWL2==4 & TenureMinWL2<=20 
    // these managers in (2,2) cell are definitely high-flyers 
    // their lowest observed age in WL2 is 50-59, but their lowest observed tenure in WL2 is below 20 years, 
    // implying that they must be at WL2 after the age of 30 
replace  HighFlyer2 = 0 if MinWL==2 & MaxWL>=2 & AgeMinWL2==5 & TenureMinWL2<=30 
    // these managers in (2,2) cell are definitely high-flyers 
    // their lowest observed age in WL2 is 60-69, but their lowest observed tenure in WL2 is below 30 years, 
    // implying that they must be at WL2 after the age of 30 
replace  HighFlyer2 = 0 if MinWL==2 & MaxWL>=2 & AgeMinWL2==6 & TenureMinWL2<=40 
    // these managers in (2,2) cell are definitely high-flyers 
    // their lowest observed age in WL2 is 70-79, but their lowest observed tenure in WL2 is below 40 years, 
    // implying that they must be at WL2 after the age of 30 
*!! s2_3_6. for managers in (3,), (4,), and (5,) cells, we can never back out their promotion age to WL2

label variable HighFlyer2 "=1, if the manager is a high-flyer (paper-based measure)"

*!! s2_3_7. compare two measures cell by cell 
correlate HighFlyer1 HighFlyer2 if ind_tag==1 // 0.5169 (obs=32,558)
tabulate HighFlyer1 HighFlyer2 if MinWL==1 & MaxWL==1 & ind_tag==1, missing 
    //&& some unidentifiable managers in HighFlyer2 are tagged as low-flyers in HighFlyer1
/* 
=1, if the |
manager is |
         a | =1, if the manager is
high-flyer |     a high-flyer
 (original | (paper-based measure)
  measure) |         0          . |     Total
-----------+----------------------+----------
         0 |    15,213      2,390 |    17,603 
-----------+----------------------+----------
     Total |    15,213      2,390 |    17,603 
*/
tabulate HighFlyer1 HighFlyer2 if MinWL==1 & MaxWL==2 & ind_tag==1, missing 
    //&& regarding identifiability, both measures are the same 
    //&& differences in values come from the additional restrictions other than age imposed in HighFlyer1
/* 
=1, if the |
manager is |
         a | =1, if the manager is
high-flyer |     a high-flyer
 (original | (paper-based measure)
  measure) |         0          1 |     Total
-----------+----------------------+----------
         0 |     4,677        825 |     5,502 
         1 |     2,139      3,304 |     5,443 
-----------+----------------------+----------
     Total |     6,816      4,129 |    10,945 
*/
tabulate HighFlyer1 HighFlyer2 if MinWL==1 & MaxWL>=3 & ind_tag==1, missing 
    //&& regarding identifiability, both measures are the same 
    //&& differences in values come from the additional restrictions other than age imposed in HighFlyer1
/* 
=1, if the |
manager is |
         a | =1, if the manager is
high-flyer |     a high-flyer
 (original | (paper-based measure)
  measure) |         0          1 |     Total
-----------+----------------------+----------
         0 |       115         86 |       201 
         1 |        65        165 |       230 
-----------+----------------------+----------
     Total |       180        251 |       431
*/

tabulate HighFlyer1 HighFlyer2 if MinWL==2 & MaxWL>=2 & ind_tag==1, missing 
/* 
=1, if the |
manager is |
         a |
high-flyer |     =1, if the manager is a
 (original | high-flyer (paper-based measure)
  measure) |         0          1          . |     Total
-----------+---------------------------------+----------
         0 |     2,720      2,294      8,416 |    13,430 
         1 |         1        954        693 |     1,648 
-----------+---------------------------------+----------
     Total |     2,721      3,248      9,109 |    15,078 
*/

tabulate HighFlyer1 HighFlyer2 if MinWL>=3 & ind_tag==1, missing 
/* 
           | =1, if the
           | manager is
=1, if the |     a
manager is | high-flyer
         a | (paper-bas
high-flyer |     ed
 (original |  measure)
  measure) |         . |     Total
-----------+-----------+----------
         0 |     2,970 |     2,970 
         1 |       761 |       761 
-----------+-----------+----------
     Total |     3,731 |     3,731 
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step X. store manager types 
*??         panel data, each manager has a complete history   
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

order IDlse YearMonth WLAgg HighFlyer1 HighFlyer2 MinWL MaxWL AgeMinMaxWL AgeMaxMaxWL AgeMinWL2

correlate HighFlyer1 HighFlyer2 if ind_tag==1 // 0.5169
tabulate HighFlyer1 HighFlyer2 if ind_tag==1, missing 
/* 
=1, if the |
manager is |
         a |
high-flyer |     =1, if the manager is a
 (original | high-flyer (paper-based measure)
  measure) |         0          1          . |     Total
-----------+---------------------------------+----------
         0 |    22,725      3,205     13,776 |    39,706 
         1 |     2,205      4,423      1,454 |     8,082 
-----------+---------------------------------+----------
     Total |    24,930      7,628     15,230 |    47,788
*/

compress
rename IDlse IDlseMHR 
    // this dataset will be appended to workers' panel dataset through key word IDlseMHR

foreach var in WLAgg {
    rename `var' `var'_Mngr 
}
save "${FinalData}/Managers.dta", replace 

