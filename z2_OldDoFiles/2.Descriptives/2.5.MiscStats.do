********************************************************************************
* Useful stats for paper 
********************************************************************************

*Average tenure for middle managers 
********************************************************************************

use "$fulldta/AllSnapshotWC.dta" , clear
su Tenure if WL>1
*keep if WL==2 
bys IDlse : egen cc = max(WL)
bys IDlse: egen tt = max(Tenure)
egen oo = tag(IDlse)
su tt if oo==1 & cc>1 & cc!=. // 11 years 

* cases of managers that exit and then return? 

* leaver flag 
bys IDlse: egen lf = max(Leaver)
bys IDlse: egen eM = min(cond(Leaver==1, YearMonth,.))
bys IDlse : egen ym = max(YearMonth)
gen diff = ym - eM
format eM ym %tm

sort IDlse YearMonth
br IDlse YearMonth Leaver ym eM if ym!=eM & lf==1

count if ym!=eM & lf==1 & oo==1 //   7,937 
ta Leaver
di 7937 /   147686

su diff if lf==1 & ym!=eM,d

count if ym!=eM & lf==1 & oo==1 & diff>3  //     7,653
di   7653 /   147686

*Jobs for BC workers 
********************************************************************************

use "$fulldta/AllSnapshotBC.dta" , clear 
ta StandardJob, sort // 87% in machine jobs 

* Compute the share of employment in managerial positions 
********************************************************************************

use "$cleveldta/3.ILO Emp Occ.dta", clear 
keep if Gender == "Total" 
keep if Year ==2019
keep if CountryS =="World"

egen EmpManagers = mean(cond( ISCO08=="1. Managers", Employment, .)) 
 egen EmpTot = mean(cond( ISCO08== "Total", Employment, .)) 
 egen EmpWC = total(cond( ISCO08=="1. Managers" | ISCO08== "2. Professionals" | ISCO08== "4. Clerical support workers"  | ISCO08== "5. Service and sales workers" , Employment, .)) 
egen EmpWC2= total(cond( ISCO08=="1. Managers"| ISCO08== "2. Professionals" | ISCO08=="3. Technicians and associate professionals" | ISCO08== "4. Clerical support workers" | ISCO08== "5. Service and sales workers" , Employment, .)) 
     
gen ShareTot = EmpManagers/ EmpTot 
gen ShareWC = EmpManagers/ EmpWC
gen ShareWC2 = EmpManagers/ EmpWC2

su ShareTot ShareWC  ShareWC2

* Compute the share of earnings in managerial positions 
********************************************************************************

use "$cleveldta/3.ILO Wage Occupation.dta", clear 
keep if Year ==2019
keep if ISOCode  !=""
collapse WageUSD, by(ISCO08 ISOCode )

bys ISOCode: egen EmpManagers = mean(cond( ISCO08=="1", WageUSD, .)) 
bys ISOCode: egen EmpTot = mean(cond( ISCO08== "TOTAL", WageUSD, .)) 
bys ISOCode: egen EmpWC = total(cond( ISCO08=="1" | ISCO08== "2" | ISCO08== "4"  | ISCO08== "5" , WageUSD, .)) 
bys ISOCode: egen EmpWC2= total(cond( ISCO08=="1"| ISCO08== "2" | ISCO08=="3" | ISCO08== "4" | ISCO08== "5" , WageUSD, .)) 
     
gen ShareTot = EmpManagers/ EmpTot 
gen ShareWC = EmpManagers/ EmpWC
gen ShareWC2 = EmpManagers/ EmpWC2

collapse ShareTot ShareWC  ShareWC2
su ShareTot ShareWC  ShareWC2

* Counting the transition events 
********************************************************************************
use "$managersdta/SwitchersAllSameTeam.dta" , clear

keep if YearMonth <=tm(2020m3)

* selecting on the managers 
bys IDlse: egen prewl = max(cond(KEi==-1 ,WLM,.))
bys IDlse: egen postwl = max(cond(KEi==0 ,WLM,.))
ge WL2 = prewl >1 & postwl>1 if prewl!=. & postwl!=. 

* Using FT manager as the type

distinct IDlse if EarlyAgeM!=. & WL2==1 //     59,929 employees 
distinct IDlseMHR if EarlyAgeM!=. & WL2==1 //   29,028 managers 
count if ChangeMR==1 &  EarlyAgeM!=. & WL2==1 //  59,929

*Using high promotion manager as the type 
distinct IDlse if MFEBayesPromSG75!=. //   63,867 employees 
distinct IDlseMHR if MFEBayesPromSG75!=. //    5,433 managers 
count if ChangeMR==1 &  MFEBayesPromSG75!=. // 25,267

distinct ISOCode // 113 countries 

* How many workers in a given sub-function-office? 
* this is to understand how much career mobility there is within an office and there is a lot
* typically a given subfunction would have roles spanning from WL1 to WL4 
********************************************************************************
use "$managersdta/AllSnapshotMCultureMType.dta", clear 

bys SubFunc YearMonth Country: egen cc = count(IDlse)
egen ttt= tag(SubFunc YearMonth Country)
 su cc if ttt==1, d
 
bys SubFunc YearMonth: egen c = count(IDlse)
egen tto= tag(SubFunc YearMonth)

su c if tto==1, d // median is  241 and p10 is 16 and p90 is 2112     

* How many horizontally differentiated jobs? 
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType.dta", clear 
distinct StandardJob if WL==1 & BC==0 //  989

su FTE, d // 97

* How many managers in WL2, fast track? 
********************************************************************************
* idea is to only look at workers that switch WL2 managers, so LH/LL/HL/HH are all between work level two managers 
use "$managersdta/SwitchersAllSameTeam.dta" , clear 
bys IDlse: egen FirstWL2M = max(cond(WLM==2 & KEi==-1,1,0))
bys IDlse: egen LastWL2M = max(cond(WLM==2 & KEi==0,1,0))
gen WL2 = FirstWL2M ==1 & LastWL2M ==1

* Annual Pay growth 
********************************************************************************

keep if Year<2020
keep if YearMonth == tm(2011m12) | YearMonth == tm(2012m12) | YearMonth == tm(2013m12) | YearMonth == tm(2014m12) | YearMonth == tm(2015m12) | YearMonth == tm(2016m12) | YearMonth == tm(2017m12) | YearMonth == tm(2018m12) | YearMonth == tm(2019m12)
xtset IDlse Year 
gen PayGrowth = d.LogPayBonus

su PayGrowth ,d  // median annual pay growth is 3% 

* How many WL promotions can I observe   
********************************************************************************
use "$managersdta/AllSnapshotMCulture.dta" , clear 

bys IDlse: egen mP = max(PromWLC)
egen t = tag(IDlse)

su mP if t==1, d

ta mP if t==1

/* for 0.25% of workers I can observe 2 promotions so I can at most observe 1 promotion

         mP |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    210,619       93.98       93.98
          1 |     12,920        5.76       99.74
          2 |        566        0.25       99.99
          3 |         12        0.01      100.00
------------+-----------------------------------
      Total |    224,117      100.00
*/
	  
* What does a worker that stays all the time in WL1 do?  
********************************************************************************

use "$managersdta/SwitchersAllSameTeam.dta" , clear 
gen ind1 = WL==1
bys IDlse: egen T1 = sum(ind1)
distinct YearMonth
keep if T1==129
sort IDlse YearMonth 
br IDlse YearMonth  StandardJob ChangeSalaryGradeC TransferSJC
su  ChangeSalaryGradeC TransferSJC, d 

egen tagt = tag(IDlse)
bys IDlse: egen mmSJ = max(TransferSJC)
bys IDlse: egen mmP = max(ChangeSalaryGradeC)

su mmSJ mmP if tagt ==1 // median job change is 2 and promotion is 1 over 10 years 

* Average response rate surveys 
********************************************************************************

* Univoice 
use "$managersdta/AllSnapshotMCulture.dta", clear 
merge 1:1 IDlse YearMonth using "$fulldta/Univoice.dta"
drop if _merge ==2 

rename _merge mergeS

merge m:1 IDlse using "$fulldta/EducationMax.dta", keepusing(QualHigh   FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge

* Constructing relevant variables for the table 
* EDUCATION Groups 
gen Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
label var Econ "Econ, Business, and Admin"
gen Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
label var Sci "Sci, Engin, Math, and Stat"
gen Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
label var Hum "Social Sciences and Humanities"
gen Other = (Econ ==0 & Sci ==0 & Hum ==0  )  if FieldHigh1!=.
label var Other "Other Educ"
gen Missing = FieldHigh1 ==. 
label var Missing "Missing Education"

gen Bachelor =    QualHigh >=10 if QualHigh!=.
gen MBA =    QualHigh ==13 if QualHigh!=.
gen AboveSecondary = QualHigh >=6 if QualHigh!=.

* OTHER VARIABLES
********************************************************************************

* generate work level dummies 
replace  WL = 3 if WL >3
tab WL, gen(WL)

* generate age dummies
replace AgeBand =  1 if  AgeBand==7 //18
replace AgeBand =  4 if  AgeBand>4 & AgeBand!=. // above 50
tab AgeBand, gen(Cohort)

global des Female Cohort1 Cohort2 Cohort3 Cohort4 Econ Sci Hum Other  Tenure WL1 WL2 WL3  EarlyAgeM  
label var WL1 "Share in Work-level 1" 
label var WL2 "Share in Work-level 2" 
label var WL3 "Share in Work-level 3+" 
label var Cohort1 "Share in Cohort 18-29"  
label var Cohort2 "Share in Cohort 30-39"
label var Cohort3 "Share in Cohort 40-49"
label var Cohort4 "Share in Cohort 50+"
label var Tenure "Tenure (years)"
label var TeamSize "No. of workers per supervisor"
label var EarlyAgeM "High-flyer manager"

gen SurveyInd = 1 if mergeS==3
replace SurveyInd = 0 if mergeS==1

gen Month = month(dofm(YearMonth))

preserve 
keep if Month==9 // when the survey is done
**# ON PAPER
balancetable SurveyInd $des if Month ==9  using "$analysis/Results/2.Descriptives/BTableSurveyAnswer.tex"   , pval replace cov(Office Year) vce( cluster IDlse )  varlabels  ///
ctitles( "Non-respondents" "Survey respondents" "Difference" ) groups("\textbf{Mean / (SE)}" "\textbf{Difference in means / (p-value)}" , pattern(1 0 1 ) ) postfoot("\hline\hline \end{tabular} \begin{tablenotes} \footnotesize \item" ///
Notes. This table compares average characteristics of the non-respondents (Column 1) to the subset of employees who responded to the employee survey (Column 2). ///
Standard errors clustered at the worker level used. Controlling for office year fixed effects.  "\end{tablenotes}}")
restore

* Wellbeing 
use "$managersdta/AllSnapshotMCultureMType.dta", clear 
merge 1:1 IDlse YearMonth using "$fulldta/Wellbeing.dta"
drop if _merge ==2 

bys IDlse Year: egen maxMerge = max(_merge)

egen ss = tag(IDlse Year)

keep if ss==1 

bys Year: ta maxMerge

* Do women managers promote more women? 
********************************************************************************
use "$managersdta/AllSnapshotMCultureMType.dta", clear 

reghdfe PromWLC SameGender##Female , a(ISOCode YearMonth Func AgeBandM WLM ) cluster(IDlseMHR)
* FEMALE MANAGERS PROMOTE WOMEN LESS, results: 0.01 SameGender + 0.02 Female -0.04 Female*SameGender (interacted coeff)

reghdfe PromWLC SameGender##Female c.Tenure##c.Tenure c.TenureM##c.TenureM, a(ISOCode YearMonth Func AgeBandM AgeBand) cluster(IDlseMHR)
* FEMALE MANAGERS PROMOTE WOMEN LESS, results: 0.002 SameGender + 0.01 Female -0.03 Female*SameGender (interacted coeff)

* MOST COMMON JOB IN THE UK (TO COMPARE TO GLASSDOOR)
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
groups StandardJob if ISOCode=="GBR" & YearMonth==tm(2021m12), order(h) select(10)
su PayBonus if StandardJob == "Product Dev Technician" & ISOCode=="GBR" & YearMonth==tm(2021m12), d 
* Median salary is 45576.56 in euros, convert to pounds and it is 39k as of June 2022

* FLAG FACTORIES IN THE DATA 
********************************************************************************

use "$fulldta/AllSnapshot.dta", clear 

bys Office YearMonth: egen NoBC = total(BC)
bys Office YearMonth: egen TotW = count(IDlse)
gen ShareBC = NoBC/TotW

egen o = tag(Office YearMonth)
keep if o==1 

gen Factory = ShareBC> 0.4 if NoBC!=.

bys Office: egen tt = sum(Factory)
bys Office: egen oo = count(YearMonth)
gen ShareFactory = tt/oo 

replace Factory = 1 if ShareFactory >0.4 & ShareFactory!=. 

egen ii = tag(Office)
keep if ii==1 
 
keep Office Factory NoBC TotW ShareBC
gen OfficeM = Office
label var OfficeM "for easy merging"

label var NoBC "Number of BC workers"
label var TotW "Number of workers"
label var Factory "Indicator for factory"

compress 
save "$managersdta/FactoryInd.dta", replace 

* How many WC in sample are in factories? 
use "$managersdta/AllSnapshotMCulture.dta", clear 
merge m:1 OfficeM using "$managersdta/FactoryInd.dta" 
egen oo = tag(IDlse)
ta Factory if oo==1 // 24%
ta Factory // 20%

* How many WC in sample are in factories? 
use "$managersdta/AllSnapshotMCultureMType.dta", clear 

merge m:1 OfficeM using "$managersdta/FactoryInd.dta" 

ta Factory // 20% of workers are supervised by a manager in a factory 

egen m = tag(IDlseMHR)
ta Factory if m==1 // 24% of managers 

