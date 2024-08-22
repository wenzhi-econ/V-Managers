********************************************************************************
* UNDERSTANDING MAGNITUDES 
********************************************************************************
global Label FT

*use "$managersdta/SwitchersAllSameTeam2.dta", clear 
use "$managersdta/AllSameTeam2.dta", clear 

* Months in function
bys IDlse TransferFuncC: egen MonthsFunc =  count(YearMonth)
label var MonthsFunc "Tot. Months in Function"

* New hires only
gen TenureMin1 = TenureMin <1 // 46%

* Looking at the middle cohorts 
bys IDlse: egen MinAge = min(AgeBand)
label val MinAge AgeBand
format Ei %tm 
gen cohort30 = 1 if Ei >=tm(2014m1) & Ei <=tm(2018m12) // cohorts that have at least 36 months pre and after manager rotation 

gen cohort60 = 1 if Ei >=tm(2012m1) & Ei <=tm(2015m3) // if I cut the window, I can do 12 months pre and then 60 after 

* Relevant event indicator  
rename (KEi Ei) (KEiAllTypes EiAllTypes)
local Label $Label
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

gen KEi  = YearMonth - Ei 

********************************************************************************
*5 % INCREASE IN SALARY MAGNITUDE 
********************************************************************************

* constant year (inflation etc): 2021
* ABSOLUTE VALUE - 5 YEARS AFTER
su PayBonus if WL2==1 &  KEi==60 & FTLLB==1 & ISOCode =="GBR" & Year==2021, d // mean:  48035.2
* conversion from EUR TO GBP: 
 
su PayBonus if WL2==1 &  KEi==60 & FTLLB==1 & ISOCode =="USA" & Year==2021, d //  mean:    110042.6
su PayBonus if WL2==1 &  KEi==84 & FTLLB==1 & ISOCode =="USA" & Year==2021, d //  mean:    97910.77
di 97910.77 *0.3 // in the paper 29373.231
* conversion from EUR TO USD: almost 1-1 as of August 2022
* >>>>So a 5% increase in salary is 5,500 USD 

* TENURE in real terms for new hires that start at entry level 
* it is in real terms as I am controlling for time FE
bys IDlse: egen minWL= min(WL)
reghdfe LogPayBonus Tenure if TenureMin <1 & minWL==1, a(YearMonth Country AgeBand##Female)
reghdfe LogPayBonus c.Tenure##c.Tenure if minWL==1, a(YearMonth Country AgeBand##Female) // work-level 1 workers   
di    .0376631 *1.3
reghdfe LogPayBonus c.Tenure##c.Tenure if TenureMin <1 & minWL==1, a(YearMonth Country AgeBand##Female) // new hire and WL1
 di  .0519644 *7  -.0011678 *(49)

reghdfe LogPayBonus c.Tenure##c.Tenure if minWL==1 , a(YearMonth IDlse ) // work-level 1 workers  


*>>> at least 3 years of tenure

* PDV >> look related dofile 

* START PAY
* pay at start of natural experiment
su PayBonus if WL2==1 &  KEi==0 & ISOCode =="USA" & Year==2021, d // mean:        83148.84
* PDV is 20%>> 17K USD
