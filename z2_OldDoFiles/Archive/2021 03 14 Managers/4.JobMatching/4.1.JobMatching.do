********************************************************************************
* JOB MATCHING
********************************************************************************

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

use "$Managersdta/Managers.dta", clear

xtset IDlse YearMonth 
gen zl  = l12.TenureM
gen o = 1 
bys IDlse Spell: gen SpellMonth = sum(o)

encode StandardJob, gen(StandardJobE)
replace WL =4 if WL >=4
replace WLM =4 if WLM >=4

merge m:1 StandardJobCode StandardJob SubFunc using "$data/ONET/Standard Job/SJ.dta", keepusing( SJCodeNew SJNew)
drop _merge 

* STATISTICS OF JOB TITLE 
egen tt = tag(SJNew IDlse) 
egen o = tag(SJNew)
bys SJNew: egen NN = sum(tt)
bys SJNew: egen N = count(IDlse) if YearMonth==tm(2019m12)
egen t = tag(SJNew) if  YearMonth==tm(2019m12)
hist NN if o==1, frac width(200) xlabel(0(1000)18000,labsize(tiny)) note(The width of each bar is 200 employees) title("Distribution of employees per job title, Dec 2019") xtitle(Number of employees per job title) ysize(2)
graph export "$Results/4.1.JobMatching/SJNew.png", replace 


hist N if N>2000, frac width(1000) 
xlabel(2000(1000)2000,labsize(small)) 


********************************************************************************
* Estimate job match 
********************************************************************************

reghdfe  ChangeSalaryGradeC c.Tenure##c.Tenure##i.Female , a( i.AgeBand i.CountryYear JobMatchSG = i.IDlse#i.StandardJobE  ) 
/*
HDFE Linear regression                            Number of obs   = 14,862,315
Absorbing 3 HDFE groups                           F(   5,14246660)=   28821.34
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.9222
                                                  Adj R-squared   =     0.9188
                                                  Within R-sq.    =     0.0100
                                                  Root MSE        =     0.2706
*/
reghdfe  LogPayBonus c.Tenure##c.Tenure##i.Female , a( i.AgeBand i.CountryYear JobMatchPay = i.IDlse#i.StandardJobE  ) 

												  
preserve 
keep IDlse YearMonth StandardJobE  JobMatchSG JobMatchPay BC WL 
save "$Managersdta/Temp/JobMatchFE.dta", replace 
restore 

reghdfe  LogPayBonus c.Tenure##c.Tenure##i.Female , a( i.AgeBand i.CountryYear EFEPay= i.IDlse JFEPay = i.StandardJobE JobMatchPay = i.IDlse#i.StandardJobE  ) 

/*
HDFE Linear regression                            Number of obs   =  6,249,293
Absorbing 3 HDFE groups                           F(   5,5923155) =    4005.14
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.8653
                                                  Adj R-squared   =     0.8579
                                                  Within R-sq.    =     0.0034
                                                  Root MSE        =     0.3804

 												  */
egen IJ = group(IDlse SJCodeNew)

* distinct jobs: 1574

reghdfe  LogPayBonus c.Tenure##c.Tenure##i.Female , a( i.AgeBand i.CountryYear EFEPay= i.IDlse JFEPay = i.SJCodeNew IJFE = i.IJ  ) 
												  
preserve 
keep IDlse YearMonth SJCodeNew SJNew  JFEPay EFEPay  IJFE BC WL 
save "$Managersdta/Temp/JobMatchFE2.dta", replace 
restore 

* Job Match FE
use "$Managersdta/Temp/JobMatchFE.dta", clear

xtset  IDlse YearMonth
egen JobMatchPayZ = std(JobMatchPay)

xtsum JobMatchPayZ

/*
Variable         |      Mean   Std. Dev.       Min        Max |    Observations
-----------------+--------------------------------------------+----------------
JobMat~Z overall |  6.57e-11          1  -11.20209   6.270927 |     N = 6249293
         between |             1.020361  -8.858781    5.79501 |     n =  208395
         within  |             .1344471  -4.953458   3.494193 | T-bar = 29.9877

*/
		 
collapse JobMatchSG JobMatchPay, by(IDlse BC StandardJobE )
egen JobMatchPayZ = std(JobMatchPay)
tw hist JobMatchPayZ if BC==0 & JobMatchPayZ>=-4 & JobMatchPayZ <=4 ,  frac bcolor(teal%60) || hist JobMatchPayZ if BC==1 & JobMatchPayZ>=-4 & JobMatchPayZ <=4,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac xtitle(Employee-Job Match FE in Tot. Pay (logs)) ytitle("") 
*xlabel(1(1)25)
graph save "$Results/4.1.JobMatching/JobMatchPay.gph", replace 
graph export "$Results/4.1.JobMatching/JobMatchPay.png", replace 

tw hist JobMatchSG if BC==0 ,  frac bcolor(teal%60) || hist JobMatchSG if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac xtitle(Employee-Job Match FE in Salary Grade) ytitle("") 
*xlabel(1(1)25)
graph save "$Results/4.1.JobMatching/JobMatchSG.gph", replace 
graph export "$Results/4.1.JobMatching/JobMatchSG.png", replace 

su JobMatchPay
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
 JobMatchPay |    325,466   -.0858085    .9128667  -10.18309   5.700494

*/
su JobMatchSG
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  JobMatchSG |    614,514   -.0344447    .8578889  -2.131458   29.24711
*/

********************************************************************************
* A good manager is one that creates good matches
********************************************************************************

use "$Managersdta/Managers.dta", clear

replace WL =4 if WL >=4
replace WLM =4 if WLM >=4


*merge 1:1 IDlse YearMonth using "$Managersdta/Temp/JobMatchFE.dta", keepusing( StandardJobE  JobMatchSG JobMatchPay)
merge 1:1 IDlse YearMonth using "$Managersdta/Temp/JobMatchFE2.dta", keepusing(  JFEPay EFEPay  IJFE)
drop _merge

bys StandardJobCode: egen NStandardJobCode = count(IDlse )
su  NStandardJobCode, d
 
* I assign to the manager also the 6 months post spell for the match effects - the value of the match he created while
* assigning employee to another manager 
* I take the average among all employees of a manager in a given month 
* I take the cum sum of that average and divide it by the cum sum of months in a manager-month panel  
xtset IDlse YearMonth
gen SpellMatch =  l6.Spell
gen IDlseMHRMatch = l6.IDlseMHR

bys IDlse IDlseMHRMatch: egen JobMatchPayIDlseMHR = mean(JobMatchPay) if IDlseMHRMatch !=.
bys IDlse IDlseMHRMatch: egen JobMatchSGIDlseMHR = mean(JobMatchSG) if IDlseMHRMatch !=.

* alternative 
bys IDlse IDlseMHRMatch (YearMonth), sort : gen JobMatchPayDIDlseMHR = JobMatchPay[_N] - JobMatchPay[1]  if IDlseMHRMatch !=.
bys IDlse IDlseMHRMatch (YearMonth), sort: gen JobMatchSGDIDlseMHR = JobMatchSG[_N] - JobMatchSG[1]  if IDlseMHRMatch !=.
*bys IDlse IDlseMHRMatch: egen JobMatchSGDIDlseMHR = mean(JobMatchSG) if IDlseMHRMatch !=.

* Creating the cumulative measure of MQ: effect of manager on all employees he had previous to this one  
********************************************************************************

bys IDlseMHR YearMonth: egen ReporteesSize = count(IDlse)
label var ReporteesSize  "Number of IDlse reporting to given manager in a given month" 
bys IDlse Spell: gen t = 1 if YearMonth==SpellStart

preserve 
collapse JobMatchPayIDlseMHR JobMatchSGIDlseMHR JobMatchPayDIDlseMHR JobMatchSGDIDlseMHR  (sum) t, by(IDlseMHR YearMonth)
drop if IDlseMHR ==.
bys IDlseMHR (YearMonth), sort: gen CumReporteesM = sum(t)
gen o = 1
bys IDlseMHR (YearMonth), sort: gen NN = sum(o)

bys IDlseMHR (YearMonth), sort: gen JobMatchPayM = sum(JobMatchPayIDlseMHR)
bys IDlseMHR (YearMonth), sort: gen JobMatchSGM = sum(JobMatchSGIDlseMHR)

bys IDlseMHR (YearMonth), sort: gen JobMatchPayDM = sum(JobMatchPayDIDlseMHR)
bys IDlseMHR (YearMonth), sort: gen JobMatchSGDM = sum(JobMatchSGDIDlseMHR)

replace JobMatchSGM = JobMatchSGM / NN
replace JobMatchPayM = JobMatchPayM / NN

replace JobMatchSGDM = JobMatchSGDM / NN
replace JobMatchPayDM = JobMatchPayDM / NN

xtset IDlseMHR YearMonth

gen lJobMatchPayM = l.JobMatchPayM
gen lJobMatchSGM = l.JobMatchSGM

gen lJobMatchPayDM = l.JobMatchPayDM
gen lJobMatchSGDM = l.JobMatchSGDM

gen lCumReporteesM  = l.CumReporteesM 
replace CumReporteesM = lCumReporteesM 

replace JobMatchSGM = lJobMatchSGM
replace JobMatchPayM = lJobMatchPayM

replace JobMatchSGDM = lJobMatchSGDM
replace JobMatchPayDM = lJobMatchPayDM

drop lJobMatchSGM lJobMatchPayM  lJobMatchPayDM lJobMatchSGDM NN lCumReporteesM  o 
*JobMatchPayIDlseMHR JobMatchSGIDlseMHR

save "$Managersdta/Temp/JobMatchM.dta", replace 
 
restore 

*STANDARD TO LOAD DATA 
********************************************************************************

use "$Managersdta/Managers.dta", clear

merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/JobMatchM.dta", keepusing( JobMatchSGM JobMatchPayM JobMatchSGDM JobMatchPayDM CumReporteesM )
drop _merge

preserve 
keep JobMatchSGM JobMatchPayM JobMatchSGDM JobMatchPayDM CumReporteesM  IDlseMHR WLM AgeBandM TenureM YearMonth
save "$Managersdta/Temp/JobMatchPayMChar.dta" , replace 
restore

replace JobMatchPayM = . if YearMonth < = tm(2015m12)
replace JobMatchPayDM = . if YearMonth < = tm(2015m12)

bys IDlse Spell : egen zSG = max(cond(YearMonth == SpellStart, JobMatchSGM,.))
bys IDlse Spell : egen zPay = max(cond(YearMonth == SpellStart, JobMatchPayM,.))

bys IDlse Spell : egen zSGD = max(cond(YearMonth == SpellStart, JobMatchSGDM,.))
bys IDlse Spell : egen zPayD = max(cond(YearMonth == SpellStart, JobMatchPayDM,.))

replace JobMatchSGM = zSG
replace JobMatchPayM = zPay

replace JobMatchSGDM = zSGD
replace JobMatchPayDM = zPayD

egen JobMatchSGMZ= std(JobMatchSGM)
egen JobMatchPayMZ= std(JobMatchPayM)

egen JobMatchSGDMZ= std(JobMatchSGDM)
egen JobMatchPayDMZ= std(JobMatchPayDM)

egen z = cut(CumReporteesM), group(6)
replace CumReporteesM = z
drop z

replace WL = 1 if WL ==0
replace WL =4 if WL >=4
replace WLM =4 if WLM >=4

* Job transfer variables: standard job change  OVERALL
gsort IDlse YearMonth
gen TransferSJ = 0 if PositionTitle!="" & EmployeeNum!=.
replace  TransferSJ = 1 if (IDlse == IDlse[_n-1] & StandardJob != StandardJob[_n-1] & StandardJob!=""  ) 
label var  TransferSJ "Dummy, equals 1 in the month when Standard Job is diff. than in the preceding"

gen z = TransferSJ
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & StandardJob!="" 
gen TransferSJC = z 
drop z 

label var  TransferSJC "CUMSUM from dummy=1 in the month when  Standard Job is diff. than in the preceding"
********************************************************************************


* TIME IN STANDARD JOB 
bys IDlse TransferSJC: egen MonthsTransferSJ = count(YearMonth)
egen tt= tag(IDlse TransferSJC)
winsor2   MonthsTransferSJ  , by( BC) suffix(T) cuts(5 95) trim
su MonthsTransferSJT if tt ==1, d

*  TEAM SIZE 
bys IDlseMHR YearMonth: egen TeamSize = count(IDlse)
egen tt = tag(IDlseMHR YearMonth)
winsor2   TeamSize  , by(WLM BC) suffix(T) cuts(5 95) trim
bys WLM BC: su   TeamSizeT  if tt==1, d
drop tt

egen TeamSizeC = cut(TeamSize) , group(10) // need to control for this 

* match data 
preserve 
keep JobMatchPayMZ  JobMatchSGMZ JobMatchPayDMZ  JobMatchSGDMZ IDlseMHR WLM AgeBandM TenureM YearMonth
save "$Managersdta/Temp/JobMatchPayMZChar.dta" , replace 
restore

* PLOTS
********************************************************************************

use "$Managersdta/Temp/JobMatchPayMZChar.dta" , replace 
collapse JobMatchPayDMZ JobMatchSGDMZ  , by(IDlseMHR YearMonth )
egen z = std(JobMatchSGDMZ)
hist JobMatchSGDMZ if JobMatchSGDMZ <=2.1 & JobMatchSGDMZ >= -2.1, frac bcolor(green%60) xtitle("Employee-job match values (log pay) per manager-month") 
graph export "$Results/4.1.JobMatching/JobMatchSGDMZ.png", replace 


* Plots by tenure 
use "$Managersdta/Temp/JobMatchPayMZChar.dta" , replace 
collapse JobMatchSGDMZ (max) WLM  , by(IDlseMHR )
label def WLM  1 "WL 1" 2 "WL 2" 3 "WL 3" 4 "WL 4+"
label value WLM WLM
hist  JobMatchSGDMZ if JobMatchSGDMZ <=2.1 & JobMatchSGDMZ >= -2.1,by(WLM, note("")) color(green%80) frac xtitle("Manager Match Value of Reportees")
graph export "$Results/4.1.JobMatching/JobMatchSGDMZhistWL.png", replace

* Plots by WL 
use "$Managersdta/Temp/JobMatchPayMZChar.dta" , clear 
egen TenureBand = cut(TenureM), group(6)
collapse JobMatchSGDMZ (max) TenureBand   , by(IDlseMHR )
label def TenureBand 0 "Tenure 0-2" 1 "Tenure 3-5" 2 "Tenure 6-9" 3 "Tenure 10-15" 4 "Tenure 16-21" 5 "Tenure 22+" 
label value  TenureBand  TenureBand 
hist JobMatchSGDMZ if JobMatchSGDMZ <=2.1 & JobMatchSGDMZ >= -2.1,by(TenureBand, note("")) color(green%80) frac xtitle("Manager Match Value of Reportees") 
graph export "$Results/4.1.JobMatching/JobMatchSGDMZhistTenure.png", replace 


preserve 
use "$Managersdta/Temp/JobMatchFE.dta", clear 

********************************************************************************

* SPELL DURATION MEAN/MEDIAN = 1.5 y and SD of 1 year. min 6 months max 5 years
bys IDlse Spell: egen MonthsSpell = count(IDlse)
egen tt = tag(IDlse Spell)
winsor2 MonthsSpell , suffix(W) cuts(10 90)
winsor2 MonthsSpell , suffix(T2) cuts(10 90) trim
winsor2 MonthsSpell , suffix(T) cuts(5 95) trim
su  MonthsSpell if tt==1, d
su  MonthsSpellT if tt==1, d
su  MonthsSpellT2 if tt==1, d
drop tt

* Number of matches 
use "$Managersdta/Temp/JobMatchFE.dta", clear 
egen g = group(IDlse StandardJobE)
distinct g if JobMatchPay !=.
count if JobMatchPay !=.
distinct StandardJobE if JobMatchPay !=.

********************************************************************************
* DESCRIPTIVE STATS 

eststo: estpost  su LogPayBonus LogBonus BonusPayRatio VPA TransferSJ  PromSalaryGrade LeaverPerm 

esttab using "$Results/4.1.JobMatching/suStats.tex", ci(3)  label nonotes cells("mean(fmt(1)) sd(fmt(1)) min(fmt(1)) max(fmt(1)) count(fmt(0))") noobs nomtitles nonumbers replace

********************************************************************************
* BALANCE TABLE 
* does not make much sense with individual FE 
********************************************************************************



