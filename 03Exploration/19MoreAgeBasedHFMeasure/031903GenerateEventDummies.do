/* 
This do file generates relevant event dummies used for event studies.

Input:
    "${TempData}/01WorkersOutcomes.dta" <== created in 0101 do file 
    "${TempData}/031902PreAndPostEventMngr_WideShape.dta" <== created in 031902

RA: WWZ 
Time: 2025-04-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge event dates to the outcome dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/01WorkersOutcomes.dta", clear 

merge m:1 IDlse using "${TempData}/031902PreAndPostEventMngr_WideShape.dta"
    keep if _merge==3
    drop _merge

codebook IDlse
    //&? expected to be 29,826; and it is; perfect

order IDlse YearMonth IDlseMHR Event_Time Event_Time_1monthbefore IDMngr_Pre IDMngr_Post

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

rename YearMonth YearMonth_Save

rename Event_Time YearMonth
merge m:1 IDMngr_Post YearMonth using "${TempData}/031902SixHighFlyerMeasures.dta"
    drop if _merge==2
    drop _merge 
order OM DA30 CA30 CA31 CA32 CA33, after(IDMngr_Post)
rename (OM DA30 CA30 CA31 CA32 CA33) (OM_Post DA30_Post CA30_Post CA31_Post CA32_Post CA33_Post)
rename YearMonth Event_Time

rename Event_Time_1monthbefore YearMonth
merge m:1 IDMngr_Pre YearMonth using "${TempData}/031902SixHighFlyerMeasures.dta"
    drop if _merge==2
    drop _merge 
order OM DA30 CA30 CA31 CA32 CA33, after(IDMngr_Pre)
rename (OM DA30 CA30 CA31 CA32 CA33) (OM_Pre DA30_Pre CA30_Pre CA31_Pre CA32_Pre CA33_Pre)
rename YearMonth Event_Time_1monthbefore

rename YearMonth_Save YearMonth

codebook IDlse
    //&? expected to be 29,826; and it is; perfect 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sort IDlse YearMonth

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. Rel_Time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Rel_Time = YearMonth - Event_Time, after(Event_Time)
drop Event_Time_1monthbefore

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach measure in OM DA30 CA30 CA31 CA32 CA33 {

    generate `measure'_LtoL = .
    replace  `measure'_LtoL = 1 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_LtoL = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_LtoL = 0 if `measure'_Pre==1 & `measure'_Post==0
    replace  `measure'_LtoL = 0 if `measure'_Pre==1 & `measure'_Post==1

    generate `measure'_LtoH = .
    replace  `measure'_LtoH = 1 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_LtoH = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_LtoH = 0 if `measure'_Pre==1 & `measure'_Post==0
    replace  `measure'_LtoH = 0 if `measure'_Pre==1 & `measure'_Post==1

    generate `measure'_HtoH = .
    replace  `measure'_HtoH = 1 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_HtoH = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_HtoH = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_HtoH = 0 if `measure'_Pre==1 & `measure'_Post==0

    generate `measure'_HtoL = .
    replace  `measure'_HtoL = 1 if `measure'_Pre==1 & `measure'_Post==0
    replace  `measure'_HtoL = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_HtoL = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_HtoL = 0 if `measure'_Pre==1 & `measure'_Post==1
}
order OM_LtoL - CA33_HtoL, after(Rel_Time)

order IDlse YearMonth IDlseMHR Event_Time Rel_Time IDMngr_Pre IDMngr_Post ///
    OM_Pre OM_Post OM_LtoL OM_LtoH OM_HtoH OM_HtoL ///
    DA30_Pre DA30_Post DA30_LtoL DA30_LtoH DA30_HtoH DA30_HtoL ///
    CA30_Pre CA30_Post CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL ///
    CA31_Pre CA31_Post CA31_LtoL CA31_LtoH CA31_HtoH CA31_HtoL ///
    CA32_Pre CA32_Post CA32_LtoL CA32_LtoH CA32_HtoH CA32_HtoL ///
    CA33_Pre CA33_Post CA33_LtoL CA33_LtoH CA33_HtoH CA33_HtoL 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. check the variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

codebook IDlse if OM_LtoL!=.
    //&? expected to be 29,610 (current reported numbers)
    //&? reality is 29,797
    //todo find out the sources of this inconsistency 

codebook IDlse if DA30_LtoL!=.

drop if OM_LtoL==.


save "${TempData}/031903FinalEventStudySample_SixHFMeasures.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/031903FinalEventStudySample_SixHFMeasures.dta", clear

foreach measure in OM DA30 CA30 CA31 CA32 CA33 {
    generate Group_`measure' = .
    replace  Group_`measure' = 1 if `measure'_LtoL==1
    replace  Group_`measure' = 2 if `measure'_LtoH==1
    replace  Group_`measure' = 3 if `measure'_HtoH==1
    replace  Group_`measure' = 4 if `measure'_HtoL==1
}

label define Group 1 "LtoL" 2 "LtoH" 3 "HtoH" 4 "HtoL"
label values Group_OM Group
label values Group_DA30 Group
label values Group_CA30 Group
label values Group_CA31 Group
label values Group_CA32 Group
label values Group_CA33 Group

codebook Group_OM Group_DA30 Group_CA30 Group_CA31 Group_CA32 Group_CA33

tab2 Group_OM Group_DA30 if Rel_Time==0, missing row column
/* 
+-------------------+
| Key               |
|-------------------|
|     frequency     |
|  row percentage   |
| column percentage |
+-------------------+

           |                 Group_DA30
  Group_OM |      LtoL       LtoH       HtoH       HtoL |     Total
-----------+--------------------------------------------+----------
      LtoL |    17,884      1,598        382      1,117 |    20,981 
           |     85.24       7.62       1.82       5.32 |    100.00 
           |     87.62      38.90      16.02      38.61 |     70.41 
-----------+--------------------------------------------+----------
      LtoH |     1,359      2,054        604        162 |     4,179 
           |     32.52      49.15      14.45       3.88 |    100.00 
           |      6.66      50.00      25.32       5.60 |     14.02 
-----------+--------------------------------------------+----------
      HtoH |       237        313        969        246 |     1,765 
           |     13.43      17.73      54.90      13.94 |    100.00 
           |      1.16       7.62      40.63       8.50 |      5.92 
-----------+--------------------------------------------+----------
      HtoL |       931        143        430      1,368 |     2,872 
           |     32.42       4.98      14.97      47.63 |    100.00 
           |      4.56       3.48      18.03      47.29 |      9.64 
-----------+--------------------------------------------+----------
     Total |    20,411      4,108      2,385      2,893 |    29,797 
           |     68.50      13.79       8.00       9.71 |    100.00 
           |    100.00     100.00     100.00     100.00 |    100.00 
*/

tab2 Group_OM Group_CA30 if Rel_Time==0, missing row column
/* 
+-------------------+
| Key               |
|-------------------|
|     frequency     |
|  row percentage   |
| column percentage |
+-------------------+

           |                 Group_CA30
  Group_OM |      LtoL       LtoH       HtoH       HtoL |     Total
-----------+--------------------------------------------+----------
      LtoL |    16,474      2,327        749      1,431 |    20,981 
           |     78.52      11.09       3.57       6.82 |    100.00 
           |     89.27      48.57      22.27      44.90 |     70.41 
-----------+--------------------------------------------+----------
      LtoH |     1,096      2,054        872        157 |     4,179 
           |     26.23      49.15      20.87       3.76 |    100.00 
           |      5.94      42.87      25.92       4.93 |     14.02 
-----------+--------------------------------------------+----------
      HtoH |       155        259      1,157        194 |     1,765 
           |      8.78      14.67      65.55      10.99 |    100.00 
           |      0.84       5.41      34.39       6.09 |      5.92 
-----------+--------------------------------------------+----------
      HtoL |       730        151        586      1,405 |     2,872 
           |     25.42       5.26      20.40      48.92 |    100.00 
           |      3.96       3.15      17.42      44.09 |      9.64 
-----------+--------------------------------------------+----------
     Total |    18,455      4,791      3,364      3,187 |    29,797 
           |     61.94      16.08      11.29      10.70 |    100.00 
           |    100.00     100.00     100.00     100.00 |    100.00 
*/

tab2 Group_OM Group_CA31 if Rel_Time==0, missing row column
/* 
+-------------------+
| Key               |
|-------------------|
|     frequency     |
|  row percentage   |
| column percentage |
+-------------------+

           |                 Group_CA31
  Group_OM |      LtoL       LtoH       HtoH       HtoL |     Total
-----------+--------------------------------------------+----------
      LtoL |    15,274      2,920      1,032      1,755 |    20,981 
           |     72.80      13.92       4.92       8.36 |    100.00 
           |     89.87      55.86      25.70      49.33 |     70.41 
-----------+--------------------------------------------+----------
      LtoH |       969      1,964      1,038        208 |     4,179 
           |     23.19      47.00      24.84       4.98 |    100.00 
           |      5.70      37.57      25.85       5.85 |     14.02 
-----------+--------------------------------------------+----------
      HtoH |       130        201      1,240        194 |     1,765 
           |      7.37      11.39      70.25      10.99 |    100.00 
           |      0.76       3.85      30.88       5.45 |      5.92 
-----------+--------------------------------------------+----------
      HtoL |       623        142        706      1,401 |     2,872 
           |     21.69       4.94      24.58      48.78 |    100.00 
           |      3.67       2.72      17.58      39.38 |      9.64 
-----------+--------------------------------------------+----------
     Total |    16,996      5,227      4,016      3,558 |    29,797 
           |     57.04      17.54      13.48      11.94 |    100.00 
           |    100.00     100.00     100.00     100.00 |    100.00 
*/

tab2 Group_OM Group_CA32 if Rel_Time==0, missing row column
/* 
+-------------------+
| Key               |
|-------------------|
|     frequency     |
|  row percentage   |
| column percentage |
+-------------------+

           |                 Group_CA32
  Group_OM |      LtoL       LtoH       HtoH       HtoL |     Total
-----------+--------------------------------------------+----------
      LtoL |    13,699      3,494      1,470      2,318 |    20,981 
           |     65.29      16.65       7.01      11.05 |    100.00 
           |     90.29      61.44      30.30      56.74 |     70.41 
-----------+--------------------------------------------+----------
      LtoH |       870      1,884      1,201        224 |     4,179 
           |     20.82      45.08      28.74       5.36 |    100.00 
           |      5.73      33.13      24.75       5.48 |     14.02 
-----------+--------------------------------------------+----------
      HtoH |       103        168      1,306        188 |     1,765 
           |      5.84       9.52      73.99      10.65 |    100.00 
           |      0.68       2.95      26.92       4.60 |      5.92 
-----------+--------------------------------------------+----------
      HtoL |       501        141        875      1,355 |     2,872 
           |     17.44       4.91      30.47      47.18 |    100.00 
           |      3.30       2.48      18.03      33.17 |      9.64 
-----------+--------------------------------------------+----------
     Total |    15,173      5,687      4,852      4,085 |    29,797 
           |     50.92      19.09      16.28      13.71 |    100.00 
           |    100.00     100.00     100.00     100.00 |    100.00 
*/

tab2 Group_OM Group_CA33 if Rel_Time==0, missing row column
/* 
+-------------------+
| Key               |
|-------------------|
|     frequency     |
|  row percentage   |
| column percentage |
+-------------------+

           |                 Group_CA33
  Group_OM |      LtoL       LtoH       HtoH       HtoL |     Total
-----------+--------------------------------------------+----------
      LtoL |    11,885      4,075      2,198      2,823 |    20,981 
           |     56.65      19.42      10.48      13.46 |    100.00 
           |     91.18      66.25      36.07      62.47 |     70.41 
-----------+--------------------------------------------+----------
      LtoH |       686      1,767      1,444        282 |     4,179 
           |     16.42      42.28      34.55       6.75 |    100.00 
           |      5.26      28.73      23.70       6.24 |     14.02 
-----------+--------------------------------------------+----------
      HtoH |        83        143      1,353        186 |     1,765 
           |      4.70       8.10      76.66      10.54 |    100.00 
           |      0.64       2.32      22.21       4.12 |      5.92 
-----------+--------------------------------------------+----------
      HtoL |       380        166      1,098      1,228 |     2,872 
           |     13.23       5.78      38.23      42.76 |    100.00 
           |      2.92       2.70      18.02      27.17 |      9.64 
-----------+--------------------------------------------+----------
     Total |    13,034      6,151      6,093      4,519 |    29,797 
           |     43.74      20.64      20.45      15.17 |    100.00 
           |    100.00     100.00     100.00     100.00 |    100.00 
*/
