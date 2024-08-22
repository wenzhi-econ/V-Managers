* This dofile looks at jobs and matching 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* JOB-WORKER MATCH
********************************************************************************
* Most of the variation in pay in the firm is due to careers rather than differences in immutable traits 

use "$managersdta/AllSnapshotMCulture.dta", clear 

* how many are lateral moves 
su TransferSJ TransferSJLL 
 di   .0199692/.0254508 // .78461974
 
su TransferSJ TransferSJLL TransferSJVV PromWL // 2.5 and 2 monthly 
* 2.5*12 = 30% of moves per year 
* 2.5*12 = 24% of moves per year 
bys EarlyAgeM: su TransferSJ
bys EarlyAgeM: su TransferSJLL 
bys EarlyAgeM: su TransferSJ if WLM==2 // there is an annual gap in transfers of 60percentage points on average 
bys EarlyAgeM: su TransferSJLL if WLM==2 // there is an annual gap in transfers of 48percentage points on average 
bys EarlyAgeM: su TransferSJV if WLM==2 // there is an annual gap in transfers of 48percentage points on average 

egen match = group(  IDlse  StandardJobE )

reghdfe LogPayBonus if BC ==0 , a(   IDlse YearMonth StandardJob   ) vce(cluster IDlseMHR)
reghdfe LogPayBonus if BC ==0 , a(   match YearMonth   ) vce(cluster IDlseMHR)

* JOB MOVES AND WAGES 
xtset IDlse YearMonth
reghdfe  LogPayBonus l12.TransferSJC , a(YearMonth Country) // 10% ON WAGES 

********************************************************************************
* TASK DISTANCE SUMMARY STATS 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

* summary stats
su ONET*Skills*C, d 
sort  ONETSkillsDistanceC

* inspect IDlse job moves for lowest and highest distances 
br IDlse ONETSkillsDistanceC if  ONETSkillsDistanceC>0 & ONETSkillsDistanceC!=. // get the IDlse 
* highest: 
br IDlse YearMonth  StandardJob  ONETSkillsDistanceC SubFunc Func if IDlse==529118 // from tax administrator to 


* zero distance 
br IDlse  StandardJob Func SubFunc ONETSkillsDistanceC if  ONETSkillsDistanceC==0 & TransferSJ==1 & ONETSkillsDistanceC!=.
* lowest:
br IDlse YearMonth  StandardJob  ONETSkillsDistanceC SubFunc Func if IDlse==285

********************************************************************************
* Descriptives about career paths - no dead end jobs 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear
xtset IDlse YearMonth 

gen SubFunc1 = f.SubFunc // next SF
gen Func1 = f.Func
gen StandardJob1 = f.StandardJobE // NEXT JOB
label value  StandardJob1  StandardJobE
bys SubFunc YearMonth : egen SizeSF = count(IDlse)
bys StandardJob YearMonth : egen SizeSJ = count(IDlse)

* Career paths examples: CD and R&D
********************************************************************************

ta StandardJob1 if StandardJob=="Field Sales Specialist", sort
* Field sales specialist: Field Sales Supervisor or Cust and Account Mgmt Supervisor
ta StandardJob1 if StandardJob=="Product Dev Technician", sort
* Product Dev Technician:  Processing Dev Technician or  Packaging Dev Technician 
egen t = tag(PositionTitle )
br  PositionTitle  if StandardJob== "Processing Dev Technician" &t==1 // Process development engineers find issues with efficiency on production lines. T
br  PositionTitle  if StandardJob== "Packaging Dev Technician" &t==1

* PLOT: prob job transfer by subfunc
********************************************************************************

preserve 
gen o =1 
collapse (mean) ChangeSalaryGrade TransferSJV PromWL TransferSubFunc TransferSJ  SizeSF (sum) o, by(SubFunc)

su SizeSF,d // average size per month 
local p25 =r(p25) 

scatter TransferSubFunc SubFunc [w=SizeSF] if  TransferSubFunc<1, || scatter TransferSubFunc SubFunc  if TransferSubFunc==0 & SizeSF>`p25', mcolor(red) yline(0) legend(off) ytitle("Average monthly probability of transfer", size(medlarge)) xtitle("Sub-function", size(medlarge)) ylabel(0(0.02)0.2)
graph export  "$analysis/Results/2.Descriptives/JobMoves.png", replace 
graph save  "$analysis/Results/2.Descriptives/JobMoves.gph", replace 

su TransferSJ [w=SizeSF], d 
local med = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local p99 = 0.1 // r(p99)

**# ON PAPER
scatter TransferSJ SubFunc [w=SizeSF] if  TransferSJ<`p99', ///
ylabel(0(0.025)0.1) yline(`p25', lcolor(maroon))  ylabel(`p25' "p25", add custom labcolor(maroon)) yline(`p75',lcolor(maroon) ) ylabel(`p75' "p75", add custom labcolor(maroon)) yline(0, lcolor(maroon)) ylabel(0 "0", add custom labcolor(maroon)) legend(off) ///
ytitle("") title("Average monthly probability of job transfer", size(medlarge)) xtitle("Sub-function", size(medlarge)) 
graph export  "$analysis/Results/2.Descriptives/MovesSJ.png", replace 
graph save  "$analysis/Results/2.Descriptives/MovesSJ.gph", replace 

su ChangeSalaryGrade [w=SizeSF], d 
local med = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local p99 = r(p99)

**# ON PAPER
scatter ChangeSalaryGrade  SubFunc [w=SizeSF] if  ChangeSalaryGrade <`p99', ///
ylabel(0(0.015)0.03) yline(`p25', lcolor(maroon))  ylabel(`p25' "p25", add custom labcolor(maroon)) yline(`p75',lcolor(maroon) ) ylabel(`p75' "p75", add custom labcolor(maroon)) yline(0, lcolor(maroon)) ylabel(0 "0", add custom labcolor(maroon)) legend(off) ///
ytitle("") title("Average monthly probability of salary grade increase", size(medlarge)) xtitle("Sub-function", size(medlarge)) 
graph export  "$analysis/Results/2.Descriptives/MovesSG.png", replace 
graph save  "$analysis/Results/2.Descriptives/MovesSG.gph", replace

restore

* Most common job moves 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear
gen o = 1 
keep if TransferSJ==1 
collapse (sum) o , by(StandardJob StandardJobBefore)
sort o 

********************************************************************************
* Descriptives about jobs 
********************************************************************************

* number of distinct jobs within a team 
use  "$managersdta/AllSnapshotMCulture.dta", clear
xtset IDlse YearMonth 

egen jj = tag(IDlseMHR YearMonth StandardJob)

bys IDlseMHR YearMonth: egen jjC = total(jj)


gcollapse jjC, by(IDlseMHR YearMonth)


hist jjC if jjC<=5 & jjC>0 & YearMonth == tm(2019m3), discrete title(Number of distinct job positions within a team) xtitle("") frac xlabel(1(1)5) note("Notes. Data from March 2019.")
graph export  "$analysis/Results/2.Descriptives/DistinctJobsTeamMarch2019.png", replace 

gcollapse jjC, by(IDlseMHR ) // average over the months 
su jjC,d

hist jjC if jjC<=5 & jjC>0, title(Number of distinct job positions within a team) xtitle("") frac xlabel(1(1)5) note("Notes. Averaging over the months.")
graph export  "$analysis/Results/2.Descriptives/DistinctJobsTeam.png", replace 

use  "$fulldta/AllSnapshot.dta", clear
xtset IDlse YearMonth 

* Standard job in total 2017 
distinct StandardJob if BC==0 // 2017 
distinct StandardJob if BC==1 // 20 

* subfunction-wl pair 
egen g = group(SubFunc WL )
distinct g 

use  "$managersdta/AllSnapshotMCulture.dta", clear
xtset IDlse YearMonth 

* random sample to make estimation faster 
egen t = tag(IDlse)
generate random = runiform() if t ==1 
bys IDlse: egen r = min(random)
sort r 
generate insample = _n <= 1000000

* How many workers work in same subfunction/org4/office than the one they started in? 
bys IDlse : egen FirstJob = mean(cond(FirstYM==1, StandardJobCode,. ))
bys IDlse : egen FirstSubFunc = mean(cond(FirstYM==1, SubFunc, . ))
bys IDlse : egen FirstFunc = mean(cond(FirstYM==1, Func, . ))
bys IDlse : egen FirstOffice = mean(cond(FirstYM==1, Office, .))
bys IDlse : egen FirstOrg4 = mean(cond(FirstYM==1, Org4, . ))
bys IDlse : egen FirstYearMonth = mean(cond(FirstYM==1, YearMonth , .))
format  FirstYearMonth  %tm
label value FirstFunc Func
label value FirstSubFunc SubFunc
label value FirstOffice Office
label value FirstOrg4 Org4

forval i=1(1)10{
bys IDlse : egen y`i'Job = mean(cond(YearMonth==FirstYearMonth+12*`i', StandardJobCode,. ))
bys IDlse : egen y`i'SubFunc = mean(cond(YearMonth==FirstYearMonth+12*`i', SubFunc, . ))
bys IDlse : egen y`i'Func = mean(cond(YearMonth==FirstYearMonth+12*`i', Func, . ))
bys IDlse : egen y`i'Office = mean(cond(YearMonth==FirstYearMonth+12*`i', Office, .))
bys IDlse : egen y`i'Org4 = mean(cond(YearMonth==FirstYearMonth+12*`i', Org4, . ))
}

forval i=1(1)10{
gen y`i'SameJob = y`i'Job == FirstJob if y`i'Job!=.
gen y`i'SameSubFunc =  y`i'SubFunc == FirstSubFunc if y`i'SubFunc!=.
gen y`i'SameFunc=  y`i'Func == FirstFunc if y`i'Func!=.
gen y`i'SameOffice=  y`i'Office == FirstOffice if y`i'Office!=.
gen y`i'SameOrg4=  y`i'Org4 == FirstOrg4 if y`i'Org4!=.
egen y`i'SameInternal = rowmin(y`i'SameSubFunc y`i'SameOffice y`i'SameOrg4)
label var y`i'SameJob "`i'"
}
* to know who survived along the years 
forval i=1(1)10{
gen y`i'FuncMissing = y`i'Func != . 
}
 
bys IDlse: egen MT = min(Tenure)
gen NoCensor = 1 if FirstYearMonth>tm(2011m1) | (FirstYearMonth==tm(2011m1)  & MT <2) // obs that are not left censored

* how many people are left?  
*distinct IDlse if y2Func!=.  // 121,149
*distinct IDlse if y6Func!=. //  51,256
*distinct IDlse if y10Func!=.

graph bar  y*FuncMissing  if t==1 & NoCensor == 1 , ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in MNE") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/WorkersSurvive.png", replace 

graph bar  y*SameJob  if t==1 & NoCensor == 1 , ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same job") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameJob.png", replace 

graph bar  y*SameInternal  if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same sub-func/office/org4") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameInternal.png", replace 

graph bar  y*SameSubFunc if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same sub-func") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameSubFunc.png", replace 

graph bar  y*SameFunc  if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same func") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameFunc.png", replace 

graph bar  y*SameOffice  if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same office") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameOffice.png", replace 

graph bar  y*SameOrg4  if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same org4") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameOrg4.png", replace 

* transition matrix at the spell level 
* only 6 biggest Func 
gen Funca = 99 
replace Funca = Func if (Func == 3 | Func == 4 | Func == 6 | Func == 9 |  Func == 10 |  Func ==  11 ) 

gen FirstFunca = 99 
replace FirstFunca = FirstFunc if (FirstFunc == 3 | FirstFunc == 4 | FirstFunc == 6 | FirstFunc == 9 |  FirstFunc == 10 |  FirstFunc ==  11 ) 

label value FirstFunca Func
label value Funca Func

eststo clear
eststo: estpost tab FirstFunca Funca , 
esttab using "$analysis/Results/2.Descriptives/Transition.tex", ///
	cell(rowpct(fmt(2))) unstack collabels("") nonumber noobs postfoot("\hline"  "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. ///
 "\end{tablenotes}") replace 

* Is there variation in pay within a job 
bys Office StandardJob YearMonth: egen PayBonusSD = sd(PayBonus)
egen ttt = tag(Office StandardJob YearMonth)

**# ON PAPER
winsor2 PayBonusSD, suffix(T) cuts(5 95) trim
su PayBonusSDT, d
local median = r(p50)
label var PayBonusSDT "" 
hist PayBonusSDT if ttt==1, xline(`median') xaxis(1 2) xlabel(`median' "Median", axis(2))  frac xtitle("Standard deviation of annual pay (euros) within job-office-month") title("") xtitle("", axis(2))
*scheme(burd5)
graph export "$analysis/Results/2.Descriptives/PaySDJob.png", replace

bys Office SubFunc WL YearMonth: egen PayBonusSD2 = sd(PayBonus)
bys Office SubFunc WL YearMonth: egen SGSD2 = sd(ChangeSalaryGradeC)

egen tt2 = tag(Office SubFunc WL YearMonth)

winsor2 PayBonusSD2, suffix(T) cuts(1 99) trim
hist PayBonusSD2T if tt2==1, frac xtitle("Standard deviation of pay within office-subfunction-WL-month")
graph export "$analysis/Results/2.Descriptives/PaySDSubfunc.png", replace

winsor2 SGSD2, suffix(T) cuts(1 99) trim
hist SGSD2T if tt2==1, frac xtitle("Standard deviation of promotions within office-subfunction-WL-month")
graph export "$analysis/Results/2.Descriptives/SGSDSubfunc.png", replace

********************************************************************************
* Descriptives about transfers 
********************************************************************************

use  "$managersdta/AllSnapshotMCultureMType.dta", clear
xtset IDlse YearMonth

merge m:1 IDlse Year using "$fulldta/UniVoice.dta" 
drop if _merge ==2 
drop _merge 
su LineManager 
gen LineManagerB = LineManager >4 if LineManager !=. // effective LM

* generate other variables 
gen VPAHigh = VPA >=125 if VPA!=.
gen ONETActivitiesDistanceCB = ONETActivitiesDistanceC>0 if ONETActivitiesDistanceC!=. 

* MAXIMUM TASK DISTANCE 
* using observed flows 
bys StandardJob: egen meanO = mean(ONETActivitiesDistanceC)
bys StandardJob: egen maxO = max(ONETActivitiesDistanceC)
egen sj = tag(StandardJob)
hist meanO if sj==1, frac xtitle(Mean ONET Activities Distance  (job-level) )
graph export  "$analysis/Results/2.Descriptives/ONETActivitiesDistanceCMean.png", replace
hist maxO if sj==1, frac xtitle(Max ONET Activities Distance (job-level) )
graph export  "$analysis/Results/2.Descriptives/ONETActivitiesDistanceCMax.png", replace

* job distance in the population of jobs 
preserve 
gen o = 1
collapse o, by(ONETCode)
dyads ONETCode // create all possible dyads from MNE jobs
rename ONETCode_d ONETCodeBefore
merge 1:1 ONETCode ONETCodeBefore using  "$ONET/Distance.dta" , keepusing(ONETAbilitiesDistance ONETActivitiesDistance ONETContextDistance ONETSkillsDistance)
keep if _merge ==3
drop _merge  
hist ONETActivitiesDistance , frac xtitle(ONET Activities Distance)
graph export  "$analysis/Results/2.Descriptives/ONETActivitiesDistancePopulation.png", replace

restore 

* FIG Density
hist  ONETActivitiesDistanceC , frac xtitle(ONET Activities Distance )
graph save  "$analysis/Results/2.Descriptives/ONETActivitiesDistanceC.gph", replace
graph export  "$analysis/Results/2.Descriptives/ONETActivitiesDistanceC.png", replace

* FIG transfers over tenure profile  
preserve 
collapse (mean) ONETActivitiesDistanceC (max) TransferInternal TransferInternalSJ, by(Tenure IDlse)
collapse ONETActivitiesDistanceC TransferInternal TransferInternalSJ, by(Tenure)
tw connected ONETActivitiesDistanceC Tenure if Tenure<=40 , ytitle(ONET Activities Distance )
graph save  "$analysis/Results/2.Descriptives/DistanceTenure.gph", replace
graph export  "$analysis/Results/2.Descriptives/DistanceTenure.png", replace
tw connected TransferInternal Tenure if Tenure<=40 , ytitle(Transfer subfunction/office/org4)
graph save  "$analysis/Results/2.Descriptives/TransferInternalTenure.gph", replace
graph export  "$analysis/Results/2.Descriptives/TransferInternalTenure.png", replace
tw connected TransferInternalSJ Tenure if Tenure<=40, ytitle(Transfer job title/office/org4) 
graph save  "$analysis/Results/2.Descriptives/TransferInternalSJTenure.gph", replace 
graph export  "$analysis/Results/2.Descriptives/TransferInternalSJTenure.png", replace

restore 

********************************************************************************
* Table on numbers *WC ONLY*
********************************************************************************

egen SubFuncWL = group(SubFunc WL )
egen OfficeYear = group(Office Year) 
egen CountryYear = group(Country Year) 
egen JobMatch = group(IDlse StandardJob) 

count 
distinct IDlse //  213228
distinct IDlseMHR //  213228
distinct YearMonth // 122 
distinct StandardJob // 2017 
distinct SubFuncWL // 463
distinct Office //   2663
distinct Country // 117
distinct OfficeYear //   14750
distinct CountryYear //  1186
distinct JobMatch //  439677

* Number of FE estimate 
di "Number of FE want to estimate: " 213228 +    439677  +  2017  + 14750 //  669672
di "Number of FE want to estimate: " 213228 +    439677  +  2017  +  1186 // 656108
di "employee-month observations per total number of FE to estimate: " 9386861/669672 // 14

* estimate job-employee FE
* to run with full sample 
reghdfe  ChangeSalaryGradeC c.Tenure##c.Tenure##i.Female if insample==1, a( i.AgeBand i.CountryYear JobFE = StandardJob JobMatchFE = JobMatch EFE = IDlse)
 
/*
HDFE Linear regression                            Number of obs   =    997,578
Absorbing 5 HDFE groups                           F(   5, 951807) =    2635.61
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.9281
                                                  Adj R-squared   =     0.9246
                                                  Within R-sq.    =     0.0137
                                                  Root MSE        =     0.2469
*/
egen tt3 = tag(JobMatch)
egen tt4 = tag(IDlse)
egen tt5 = tag(StandardJob)

winsor2 JobMatchFE, suffix(T) cuts(1 99) trim
hist JobMatchFET if tt3==1, frac xtitle("Employee Job Match FE in promotions")
graph export "$analysis/Results/2.Descriptives/JobMatchFEProm.png", replace

winsor2 EFE, suffix(T) cuts(1 99) trim
hist EFET if tt4==1, frac xtitle("Employee FE in promotions")
graph export "$analysis/Results/2.Descriptives/EFEProm.png", replace

winsor2 JobFE, suffix(T) cuts(1 99) trim
hist JobFET if tt5==1, frac xtitle("Job FE in promotions")
graph export "$analysis/Results/2.Descriptives/JobFEProm.png", replace

su JobMatchFET if tt3==1
su EFET if tt4==1
su  JobFET if tt5==1

* how many job transfers per worker? 
bys IDlse: egen mT = max(TransferSJC ) 
hist mT if tt4==1, frac  xtitle("Max job transfers per employee")
graph export "$analysis/Results/2.Descriptives/NoJobChange.png", replace

bys IDlse: egen mT = max(TransferInternalC ) 
hist mT if tt4==1, frac  xtitle("No. of internal transfers per employee") note("Notes. Transfer: sub-function | office | organizational unit.")
graph export "$analysis/Results/2.Descriptives/NoInternalChange.png", replace

su mT if tt4==1,d



* compare R2 without match FE 
reghdfe  ChangeSalaryGradeC c.Tenure##c.Tenure##i.Female if insample==1, a( i.AgeBand i.CountryYear  StandardJob   IDlse)

/*
HDFE Linear regression                            Number of obs   =    999,038
Absorbing 4 HDFE groups                           F(   5, 974650) =    4396.77
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.8480
                                                  Adj R-squared   =     0.8442
                                                  Within R-sq.    =     0.0221
                                                  Root MSE        =     0.3551

*/
* improvement in R squared of 9.5% or 8ppts

* Pay FE 
reghdfe  LogPayBonus c.Tenure##c.Tenure##i.Female , a( i.AgeBand i.CountryYear JobFEPay = StandardJob JobMatchFEPay = JobMatch EFEPay = IDlse  ) 

/*
HDFE Linear regression                            Number of obs   =  4,270,553
Absorbing 5 HDFE groups                           F(   5,4032389) =    1095.53
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.9533
                                                  Adj R-squared   =     0.9506
                                                  Within R-sq.    =     0.0014
                                                  Root MSE        =     0.2061



*/
winsor2 JobMatchFEPay, suffix(T) cuts(1 99) trim
hist JobMatchFEPayT if tt3==1, frac xtitle("Employee Job Match FE in pay")
graph export "$analysis/Results/2.Descriptives/JobMatchFEPay.png", replace

winsor2 EFEPay, suffix(T) cuts(1 99) trim
hist EFEPayT if tt4==1, frac xtitle("Employee FE in pay")
graph export "$analysis/Results/2.Descriptives/EFEPay.png", replace

winsor2 JobFEPay, suffix(T) cuts(1 99) trim
hist JobFEPayT if tt5==1, frac xtitle("Job FE in pay")
graph export "$analysis/Results/2.Descriptives/JobFEPay.png", replace

su JobMatchFEPayT if tt3==1
su EFEPayT if tt4==1
su  JobFEPayT if tt5==1

* save FE 												  
preserve 
keep IDlse YearMonth StandardJob JobFEPay JobFE  JobMatchFEPay JobMatchFE EFE EFEPay WL Office Country
save "$managersdta/Temp/JobMatchFE.dta", replace 
restore 

********************************************************************************
* mixed effect model varying intercept model
********************************************************************************

mixed LogPayBonus c.Tenure##c.Tenure##i.Female i.AgeBand i.CountryYear if insample==1   || IDlse: || JobMatch: || StandardJob:  , 

reghdfe  LogPayBonus c.Tenure##c.Tenure##i.Female , a( i.AgeBand i.CountryYear JobFEPay = StandardJob JobMatchFEPay = JobMatch EFEPay = IDlse  )

********************************************************************************
* Do transfers lead to promotion? 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear
xtset IDlse YearMonth

egen CountryYearFunc = group(Country Year Func)
* do we have number of promotions?

eststo clear 
eststo reg1: reghdfe PromWLC l6.TransferInternalC  c.Tenure##c.Tenure , a(CountryYearFunc  AgeBand Female )
eststo reg2: reghdfe PromWLC l12.TransferInternalC  c.Tenure##c.Tenure , a(CountryYearFunc  AgeBand Female )
eststo reg3: reghdfe PromWLC  l24.TransferInternalC c.Tenure##c.Tenure , a(CountryYearFunc  AgeBand Female ) 
eststo reg4: reghdfe PromWLC  l36.TransferInternalC c.Tenure##c.Tenure , a(CountryYearFunc  AgeBand Female ) 

coefplot reg1 reg2 reg3 reg4 , yline(0) keep(*TransferInternalC) rename(l6.TransferInternalC = 6months l12.TransferInternalC = 12months l24.TransferInternalC = 24months  l36.TransferInternalC = 36months ) vertical nolabel legend(off) title("Correlation between promotions (work-level) and transfers") note("Notes. Estimates based on a regression on lagged transfers controlling for tenure, tenure squared," "age group, gender and coountry-year-func dummies.")
graph export "$analysis/Results/2.Descriptives/PromTransfer.png", replace

eststo reg1b: reghdfe ChangeSalaryGradeC l6.TransferInternalC  c.Tenure##c.Tenure , a(CountryYearFunc  AgeBand Female )
eststo reg2b: reghdfe ChangeSalaryGradeC l12.TransferInternalC c.Tenure##c.Tenure , a(CountryYearFunc  AgeBand Female ) 
eststo reg3b: reghdfe ChangeSalaryGradeC  l24.TransferInternalC c.Tenure##c.Tenure , a(CountryYearFunc  AgeBand Female ) 
eststo reg4b: reghdfe ChangeSalaryGradeC  l36.TransferInternalC c.Tenure##c.Tenure , a(CountryYearFunc  AgeBand Female ) 

coefplot reg1b reg2b reg3b reg4b , yline(0) keep(*TransferInternalC) rename(l6.TransferInternalC = 6months l12.TransferInternalC = 12months l24.TransferInternalC = 24months  l36.TransferInternalC = 36months ) vertical nolabel legend(off) title("Correlation between promotions (salary) and transfers") note("Notes. Estimates based on a regression on lagged transfers controlling for tenure, tenure squared," "age group, gender and coountry-year-func dummies.")
graph export "$analysis/Results/2.Descriptives/PromSGTransfer.png", replace

********************************************************************************
* SNAPSHOT DATA - OFFICE SIZE INCLUDING BC 
********************************************************************************

use "$fulldta/AllSnapshot.dta", clear 

gen TotWorkers =1 
gen WC = 1-BC
drop if OfficeCode==. 
collapse (sum) TotWorkers (sum) BC (sum) WC, by(OfficeCode YearMonth)

rename BC TotWorkersBC
rename WC TotWorkersWC
compress 
save "$managersdta/OfficeSize.dta", replace 
