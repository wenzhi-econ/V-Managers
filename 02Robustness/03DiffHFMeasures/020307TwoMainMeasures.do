/* 
This do file creates two HF measures (based on age and tenure).

Input:
    "${RawMNEData}/AllSnapshotWC.dta" <== raw data 

RA: WWZ 
Time: 2024-12-20
*/



use "${RawMNEData}/AllSnapshotWC.dta", clear 
xtset IDlse YearMonth 
sort  IDlse YearMonth

bysort IDlse: generate occurrence = _n 
order IDlse YearMonth occurrence IDlseMHR

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. manager id imputations 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in IDlseMHR {
	replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
	replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. 
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. who are fast-track managers - EarlyAgeM
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. a set of auxiliary variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate WLAgg = WL
replace  WLAgg = 5 if WL>4 & WL!=.

//&? starting work level 
bysort IDlse: egen MinWL = min(WLAgg)  
//&? last observed work level 
bysort IDlse: egen MaxWL = max(WLAgg)

//&? age when the worker starts his last observed WL 
bysort IDlse: egen AgeMinMaxWL = min(cond(WL == MaxWL, AgeBand, .)) 
//&? number of months a worker is in his last observed WL
bysort IDlse: egen TenureMaxWLMonths = count(cond(WL==MaxWL, YearMonth, .) ) 
//&? number of years a worker is in his last observed WL
generate TenureMaxWL = TenureMaxWLMonths/12 
//&? tenure when the worker starts his last observed WL 
bysort IDlse: egen TenureMinMaxWL = min(cond(WL==MaxWL, Tenure, .)) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. variable EarlyAge: if the worker is a fast-track manager 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate EarlyAge = 0 
replace  EarlyAge = 1 if MinWL==1 & MaxWL==2 & TenureMinMaxWL<=4 & TenureMaxWL<=6 
replace  EarlyAge = 1 if MaxWL==2 & AgeMinMaxWL==1 & TenureMaxWL<=6 
replace  EarlyAge = 1 if MaxWL==3 & AgeMinMaxWL<=2 & TenureMinMaxWL<=10 
replace  EarlyAge = 1 if MaxWL==4 & AgeMinMaxWL<=2 
replace  EarlyAge = 1 if MaxWL>4  & AgeMinMaxWL<=3 
label variable EarlyAge "Fast track manager based on age when promoted (WL)"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. LT (abbreviation for Low Tenure)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate LT = 0 
replace  LT = 1 if MinWL==1 & MaxWL==2 & TenureMinMaxWL<=4 & TenureMaxWL<=6 
replace  LT = 1 if MaxWL==2 & TenureMinMaxWL<=3
replace  LT = 1 if MaxWL==3 & TenureMinMaxWL<=7 
replace  LT = 1 if MaxWL==4 & TenureMinMaxWL<=13
replace  LT = 1 if MaxWL>4  & TenureMinMaxWL<=20
label variable LT "Fast track manager based on tenure when promoted"

tabulate LT EarlyAge if occurrence==1, missing 
/* 
Fast track |
   manager |
  based on |  Fast track manager
    tenure |   based on age when
      when |     promoted (WL)
  promoted |         0          1 |     Total
-----------+----------------------+----------
         0 |   204,042      1,755 |   205,797 
         1 |     9,720      8,600 |    18,320 
-----------+----------------------+----------
     Total |   213,762     10,355 |   224,117
*/

correlate LT EarlyAge if occurrence==1
/* 
             |       LT EarlyAge
-------------+------------------
          LT |   1.0000
    EarlyAge |   0.6015   1.0000
*/

keep IDlse EarlyAge LT 
duplicates drop 

compress
save "${TempData}/TwoHFMeasures_EarlyAge_LT.dta", replace 

