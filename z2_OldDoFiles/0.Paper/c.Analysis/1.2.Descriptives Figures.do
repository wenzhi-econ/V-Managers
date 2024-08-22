********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* Work-level - age profiles: high fliers motivation
********************************************************************************

use  "$managersdta/Temp/MType.dta", clear
keep IDlseMHR
duplicates drop 
save "$managersdta/Temp/mList.dta", replace 

use  "$managersdta/AllSnapshotMCulture.dta", clear

keep if WL ==2 

bys IDlse: egen minAge = min(cond(WL==2 & Tenure<10, AgeBand,.))
keep if minAge!=. 
egen oo = tag(IDlse) 
keep if oo==1
drop IDlseMHR
gen  IDlseMHR= IDlse
merge 1:m IDlseMHR using "$managersdta/Temp/mList.dta" // making sure they are mostly managers 
keep if _merge ==3 

* save sample of WL2 managers with non missing age for future uses 
preserve 
keep  IDlseMHR  minAge
isid   IDlseMHR
save  "$managersdta/Temp/mSample.dta", replace 
restore 

* fast graph 
hist  minAge if oo==1 & minAge<5, xtitle(Age group ) discrete frac 

* prettier graph
egen tot = total(oo)
bys minAge: egen size = total(oo)
replace size = size/tot
ta minAge 
label value minAge AgeBand

separate size, by(minAge ==1)
**# ON PAPER FIGURE: AgeWL2FT.png
graph bar size0 size1 if  minAge<5, over(minAge)  bar(1, bfcolor("251 162 127")) bar(2, bfcolor("64 105 166"))   nofill legend(off) title("Age at promotion to work-level 2") ylabel(0(0.1)0.6)
graph save "$analysis/Results/0.Paper/1.2.Descriptives Figures/AgeWL2FT.gph", replace
graph export "$analysis/Results/0.Paper/1.2.Descriptives Figures/AgeWL2FT.pdf", replace

********************************************************************************
* Work-level - tenure profiles 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

gen WLD = WLM - WL 

decode  SalaryGrade, gen(t)
gen SG = substr(t, 2, .)
gen Senior = WLD >=1

reghdfe TransferInternal Senior Tenure , a(IDlse)
reghdfe PromWL Senior Tenure , a(IDlse)

* tenure- WL type of manager

forval i=1(1)5{
bys Tenure : egen noT`i' = count(cond(YearMonth == tm(2019m12) & WLAgg==`i',IDlse, .))  	 
}
bys Tenure: egen noTT = count(cond(YearMonth == tm(2019m12) ,IDlse, .))  
gen Share1 = noT1/noTT
gen Share2 = (noT1 + noT2)/noTT
gen Share3 = (noT1 + noT2 + noT3)/noTT
gen Share4 = (noT1 + noT2 + noT3 + noT4+ noT5)/noTT

egen tw = tag(Tenure )
 replace tw = 0 if Tenure > 30
gen Share0 = 0
gen upper = 1 
gen lower = 0

**# ON PAPER FIGURE: WLTenure.png
twoway    rarea Share0 Share1 Tenure if tw==1, sort  || rarea Share1 Share2 Tenure if tw==1, sort || rarea Share2 Share3 Tenure if tw==1, sort || rarea Share3 Share4 Tenure if  tw==1, sort  xlabel( 0(1)30, axis(1) )  ylabel( 0(.1)1 ) text( 0.4 5 "Work-level 1" 0.8 15  "Work-level 2"  0.94 20  "Work-level 3" 0.99  25 "Work-level 4+", size(medlarge)) ytitle(Percent of population, size(medlarge))  xtitle(Tenure, size(medlarge) axis(1))  legend(off)  scheme( white_ptol) 
graph save "$analysis/Results/0.Paper/1.2.Descriptives Figures/WLTenure.gph", replace
graph export "$analysis/Results/0.Paper/1.2.Descriptives Figures/WLTenure.pdf", replace

/* with fast track manager indicator 
gen max=1
gen y3=3
twoway   rarea Share0 Share1 Tenure if tw==1, sort  || rarea Share1 Share2 Tenure if tw==1, sort || rarea Share2 Share3 Tenure if tw==1, sort || dropline max y3 if tw==1, lwidth(thick) lpattern(shortdash) lcolor(maroon) mcolor(none) || rarea Share3 Share4 Tenure if  tw==1, sort  xlabel( 0(1)30, axis(2) )  yscale(range(0 1)) ylabel( 0(.1)1 ) text( 0.4 5 "Work-level 1" 0.8 15  "Work-level 2"  0.94 20  "Work-level 3" 0.99  25 "Work-level 4+", size(medlarge)) ytitle(Percent of population, size(medlarge))  xtitle(Tenure, size(medlarge) axis(2))  legend(off)  scheme( white_ptol)  xline(3, lwidth(thick) lcolor(maroon) axis(1)) xaxis(1 2) xlabel(3 "Median tenure at promotion, fast-track manager", axis(1) labcolor(maroon)) xtitle("", axis(1)) 
graph save "$analysis/Results/2.Descriptives/WLTenureFT.gph", replace
graph export "$analysis/Results/2.Descriptives/WLTenureFT.pdf", replace

* bcolor(gs14) base(10) // grey color
*white_hue white_w3d
* xaxis(1 2) 
*replace Share0 = 0.6
*tw rarea Share0 Share1 Tenure if tw==1, sort  || rarea Share1 Share2 Tenure if tw==1, sort || rarea Share2 Share3 Tenure if tw==1, sort || rarea Share3 Share4 Tenure if  tw==1, sort  xlabel( 0(1)30 )  ylabel( .6(.05)1 ) text( 0.65 6 "Work-level 1" 0.8 15  "Work-level 2"  0.94 20  "Work-level 3" 0.99  25 "Work-level 4+") ytitle(Percent of population)  legend(off) scheme(aurora)

/*drarea upper lower upper lower Tenure if tw==1 & Tenure >=2 & Tenure<=5, twoway (   rarea Share0 Share1 Tenure if tw==1, sort  || rarea Share1 Share2 Tenure if tw==1, sort || rarea Share2 Share3 Tenure if tw==1, sort || rarea Share3 Share4 Tenure if  tw==1, sort  xlabel( 0(1)30, axis(1) )  ylabel( 0(.1)1 ) text( 0.4 5 "Work-level 1" 0.8 15  "Work-level 2"  0.94 20  "Work-level 3" 0.99  25 "Work-level 4+", size(medlarge)) ytitle(Percent of population, size(medlarge))  xtitle(Tenure, size(medlarge) axis(1))  legend(off)  )
*/

*Another tenure graph 
bys IDlse YearMonth: gen FromWL1temp = 1 if WL == 1
bys IDlse : egen FromWL1 = min(FromWL1temp)
replace FromWL1 = 0 if FromWL1 == .

bys IDlse YearMonth: gen FromWL2temp = 1 if WL == 2 & FromWL1==0
bys IDlse : egen FromWL2 = min(FromWL2temp)
replace FromWL2 = 0  if FromWL2 == . 

bys IDlse YearMonth: gen FromWL3temp = 1 if WL == 3 & FromWL1==0 & FromWL2==0
bys IDlse : egen FromWL3 = min(FromWL3temp)
replace FromWL3 = 0  if FromWL3 == . 

/*
bys IDlse YearMonth: gen FromWL4temp = 1 if WL == 4 & FromWL1==0 & FromWL2==0  & FromWL3==0
bys IDlse : egen FromWL4 = min(FromWL4temp)
replace FromWL4 = 0 if FromWL4 == . 

bys IDlse YearMonth: gen FromWL5temp = 1 if WL == 4 & FromWL1==0 & FromWL2==0  & FromWL3==0 & FromWL4==0
bys IDlse : egen FromWL5 = min(FromWL5temp)
replace FromWL5 = 0 if FromWL5 == . 
*/

gen Internal = 0 if WL ==1
replace Internal = FromWL1 if WL ==2
replace Internal = FromWL1 + FromWL2   if WL ==3
replace Internal = FromWL1 + FromWL2 + FromWL3   if WL >=4
*replace Internal = FromWL1 + FromWL2 + FromWL3   + FromWL4  if WL ==5
*replace Internal = FromWL1 + FromWL2 + FromWL3   + FromWL4 + FromWL5  if WL ==6

keep if YearMonth == ym(2019,12)

replace WL = 4 if WL>4

graph hbar   Internal, over(WL, relabel(1 "WL1 - lowest entry level" 2 "WL2" 3 "WL3" 4 "WL4+" )) ytitle("") title("Proportion of employees promoted internally", size(medium)) bar(1, fcolor(green%60) lcolor(green%70)) note("Notes. Snapshot from December 2019.")
graph save "$analysis/Results/2.Descriptives/Internal.gph", replace
graph export "$analysis/Results/2.Descriptives/Internal.pdf", replace

********************************************************************************
* Tenure profile 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

bys IDlse: egen mYear = min(Year)
*drop if mYear ==2011 & Tenure > 1 // only keep new entrants 

bys IDlse: egen mWL = min(WL)
drop if WL ==0 
keep if YearMonth == ym(2019,12)

replace WL = 4 if WL>4
gen mWL1 = mWL == 1

winsor2 Tenure, suffix(W) cuts(0 99.9)

label def WL 1 "WL1 - lowest entry level" 2 "WL2" 3 "WL3" 4 "WL4+" 
label value WL WL
tw hist   TenureW, by(WL, title("Tenure (years in the firm)", size(medium) ) note("Notes. Snapshot from December 2019.") ) ytitle("") xtitle("") bcolor(green%60) xline(5 10 20,lcolor(ebblue))  xaxis(1 2)  xsc(noline axis(2)) xla(5 "5"  10 "10"  20 "20", axis(2) labcolor(ebblue)  ) 
* || scatteri 0 5 .15 5 .15  42 0  42,   recast(area) color(gs12%50) || scatteri 0 10 .15 10 .15  42 0  42,   recast(area) color(gs12%30) ||  scatteri 0 20 .15 20 .15  42 0  42,   recast(area) color(gs12%10)
*graph save "$analysis/Results/2.Descriptives/Tenure.gph", replace
graph export "$analysis/Results/2.Descriptives/Tenure.pdf", replace

gen t0 = TenureW <5
gen t5 = TenureW >=5
replace t5 = 0 if TenureW >=10
gen t10 = TenureW >=10
replace t10 = 0 if TenureW >=20
gen t20 = TenureW >=20

graph bar t0 t5 t10 t20, over(WL, relabel(1 "WL1 - lowest entry level" 2 "WL2" 3 "WL3" 4 "WL4+" )) legend(label(1 "0-5") label(2 "5-10") label( 3 "10-20") label(4 "20+" ) col(4)) title(Tenure in intervals) 
graph export "$analysis/Results/2.Descriptives/TenureBins.png", replace

tw scatteri 0 0 .15 0 .15  5 0  5,   recast(area) color(gs12) || hist TenureW if WL==1
tw scatteri 0 5 .15 5 .15  42 0  42,   recast(area) color(gs12) || hist TenureW if WL==2

tw scatteri 0 10 .15 10 .15  42 0  42,   recast(area) color(gs12) || hist TenureW if WL==3
tw scatteri 0 20 .15 20 .15  42 0  42,   recast(area) color(gs12) || hist TenureW if WL==4
*/

********************************************************************************
* High fliers BALANCE TABLES 
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 

ta ISOCodeM if ProductivityStdM!=. & EarlyAgeM !=. // note that there are only 2 managers with Indian data, so cannot assess this correlation 

* education variable 
merge m:1 IDlseMHR  using "$fulldta/EducationMax.dta" , keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
drop if _merge ==2 
drop _merge 

* in rotation 
merge m:1 IDlseMHR using "$managersdta/Temp/m2.dta", keepusing( mT HF) // created in 2.4.MTypeRotation.do 
drop _merge 

*UFLP status 
gen IDlse = IDlseMHR
merge 1:1 IDlse YearMonth using "$managersdta/AllSnapshotMCultureMType.dta", keepusing(FlagUFLP )
drop if _merge ==2
ta _merge // 99% are matched 
drop _merge 
rename FlagUFLP FlagUFLPM
drop IDlse  

merge m:1 IDlseMHR using  "$managersdta/Temp/MFEBayesPay.dta" , keepusing(MFEBayesLogPay MFEBayesLogPay75 MFEBayesLogPay50)
drop if _merge ==2
drop _merge

* manager type 
merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2015.dta", keepusing(MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50)
drop if _merge ==2
drop _merge

rename (MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50) =v2014

merge m:1 IDlseMHR using "$managersdta/Temp/MFEBayes2014.dta" , keepusing(MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesLogPayF6075 MFEBayesLogPayF6050 MFEBayesLogPayF7275 MFEBayesLogPayF7250 MFEBayesLogPayF72 MFEBayesLogPayF60)
drop if _merge ==2
drop _merge

* get ex-post performance of the manager 
gen IDlse = IDlseMHR // for the merging below
merge m:1 IDlse YearMonth using "$managersdta/Temp/PromExitRes.dta", keepusing(TransferSJC TransferFuncC TransferInternalC PromWLC ChangeSalaryGradeC)
drop if _merge ==2
drop _merge
drop IDlse  

* correlation btw High Flyer manager and MFEBayesPromSG75
********************************************************************************

egen oo = tag(IDlseMHR)

reg EarlyAgeM MFEBayesPromSG75 if oo==1, robust 
reghdfe EarlyAgeM  MFEBayesPromSG75   if oo==1, cluster(IDlseMHR)  a(ISOCodeM WLM AgeBandM)

reg EarlyAgeM MFEBayesLogPayF6075 if oo==1, robust 
reghdfe EarlyAgeM  MFEBayesLogPayF6075  if oo==1, cluster(IDlseMHR)  a(ISOCodeM WLM AgeBandM) // MFEBayesLogPayF6075 MFEBayesLogPayF6050 MFEBayesLogPayF7275 MFEBayesLogPayF7250 MFEBayesLogPayF72 MFEBayesLogPayF60

* FE correlation graph
********************************************************************************

**# ON PAPER FIGURE: HFCorrFE.png
label define HF 0 "Low-flyer" 1 "High-flyer"
label value EarlyAgeM HF 
cibar MFEBayesLogPayF6075 if oo==1, over(EarlyAgeM )  graphopt(legend(size(medium)) ytitle("Manager value added in worker pay >=75th pc", size(medium) ) scheme(white_ptol) ylabel(0(0.1)0.4) )
graph save "$analysis/Results/0.Paper/1.2.Descriptives Figures/HFCorrFE.gph", replace  
graph export "$analysis/Results/0.Paper/1.2.Descriptives Figures/HFCorrFE.pdf", replace 

cibar MFEBayesLogPay75 if oo==1, over(EarlyAgeM )   // very similar


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

/*
scatter TransferSubFunc SubFunc [w=SizeSF] if  TransferSubFunc<1, || scatter TransferSubFunc SubFunc  if TransferSubFunc==0 & SizeSF>`p25', mcolor(red) yline(0) legend(off) ytitle("Average monthly probability of transfer", size(medlarge)) xtitle("Sub-function", size(medlarge)) ylabel(0(0.02)0.2)
graph export  "$analysis/Results/2.Descriptives/JobMoves.pdf", replace 
graph save  "$analysis/Results/2.Descriptives/JobMoves.gph", replace 
*/

su TransferSJ [w=SizeSF], d 
local med = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local p99 = 0.1 // r(p99)

**# ON PAPER FIGURE: MovesSJ.pdf
scatter TransferSJ SubFunc [w=SizeSF] if  TransferSJ<`p99', ///
ylabel(0(0.025)0.1) yline(`p25', lcolor(maroon))  ylabel(`p25' "p25", add custom labcolor(maroon)) yline(`p75',lcolor(maroon) ) ylabel(`p75' "p75", add custom labcolor(maroon)) yline(0, lcolor(maroon)) ylabel(0 "0", add custom labcolor(maroon)) legend(off) ///
ytitle("") title("Average monthly probability of job transfer", size(medlarge)) xtitle("Sub-function", size(medlarge)) 
graph export  "$analysis/Results/0.Paper/1.2.Descriptives Figures/MovesSJ.pdf", replace 
graph save  "$analysis/Results/0.Paper/1.2.Descriptives Figures/MovesSJ.gph", replace 

su ChangeSalaryGrade [w=SizeSF], d 
local med = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local p99 = r(p99)

**# ON PAPER FIGURE: MovesSG.pdf
scatter ChangeSalaryGrade  SubFunc [w=SizeSF] if  ChangeSalaryGrade <`p99', ///
ylabel(0(0.015)0.03) yline(`p25', lcolor(maroon))  ylabel(`p25' "p25", add custom labcolor(maroon)) yline(`p75',lcolor(maroon) ) ylabel(`p75' "p75", add custom labcolor(maroon)) yline(0, lcolor(maroon)) ylabel(0 "0", add custom labcolor(maroon)) legend(off) ///
ytitle("") title("Average monthly probability of salary grade increase", size(medlarge)) xtitle("Sub-function", size(medlarge)) 
graph export  "$analysis/Results/0.Paper/1.2.Descriptives Figures/MovesSG.pdf", replace 
graph save  "$analysis/Results/0.Paper/1.2.Descriptives Figures/MovesSG.gph", replace

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

/*
hist jjC if jjC<=5 & jjC>0 & YearMonth == tm(2019m3), discrete title(Number of distinct job positions within a team) xtitle("") frac xlabel(1(1)5) note("Notes. Data from March 2019.")
graph export  "$analysis/Results/2.Descriptives/DistinctJobsTeamMarch2019.png", replace 
*/

gcollapse jjC, by(IDlseMHR ) // average over the months 
su jjC,d

/*
hist jjC if jjC<=5 & jjC>0, title(Number of distinct job positions within a team) xtitle("") frac xlabel(1(1)5) note("Notes. Averaging over the months.")
graph export  "$analysis/Results/2.Descriptives/DistinctJobsTeam.png", replace 
*/

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

/*
graph bar  y*FuncMissing  if t==1 & NoCensor == 1 , ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in MNE") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/WorkersSurvive.pdf", replace 

graph bar  y*SameJob  if t==1 & NoCensor == 1 , ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same job") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameJob.pdf", replace 

graph bar  y*SameInternal  if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same sub-func/office/org4") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameInternal.pdf", replace 

graph bar  y*SameSubFunc if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same sub-func") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameSubFunc.pdf", replace 

graph bar  y*SameFunc  if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same func") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameFunc.pdf", replace 

graph bar  y*SameOffice  if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same office") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameOffice.pdf", replace 

graph bar  y*SameOrg4  if t==1 & NoCensor == 1 , vertical ascategory yvar(relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10")) ytitle("Fraction working in same org4") note("Tenure (years)",  pos(6))
graph export  "$analysis/Results/2.Descriptives/SameOrg4.pdf", replace 
*/

* transition matrix at the spell level 
* only 6 biggest Func 
gen Funca = 99 
replace Funca = Func if (Func == 3 | Func == 4 | Func == 6 | Func == 9 |  Func == 10 |  Func ==  11 ) 

gen FirstFunca = 99 
replace FirstFunca = FirstFunc if (FirstFunc == 3 | FirstFunc == 4 | FirstFunc == 6 | FirstFunc == 9 |  FirstFunc == 10 |  FirstFunc ==  11 ) 

label value FirstFunca Func
label value Funca Func

/*
eststo clear
eststo: estpost tab FirstFunca Funca , 
esttab using "$analysis/Results/2.Descriptives/Transition.tex", ///
	cell(rowpct(fmt(2))) unstack collabels("") nonumber noobs postfoot("\hline"  "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. ///
 "\end{tablenotes}") replace 
*/ 

* Is there variation in pay within a job 
bys Office StandardJob YearMonth: egen PayBonusSD = sd(PayBonus)
egen ttt = tag(Office StandardJob YearMonth)

**# ON PAPER FIGURE: PaySDJob.png
winsor2 PayBonusSD, suffix(T) cuts(5 95) trim
su PayBonusSDT, d
local median = r(p50)
label var PayBonusSDT "" 
hist PayBonusSDT if ttt==1, xline(`median') xaxis(1 2) xlabel(`median' "Median", axis(2))  frac xtitle("Standard deviation of annual pay (euros) within job-office-month") title("") xtitle("", axis(2))
*scheme(burd5)
graph save "$analysis/Results/0.Paper/1.2.Descriptives Figures/PaySDJob.gph", replace
graph export "$analysis/Results/0.Paper/1.2.Descriptives Figures/PaySDJob.pdf", replace

bys Office SubFunc WL YearMonth: egen PayBonusSD2 = sd(PayBonus)
bys Office SubFunc WL YearMonth: egen SGSD2 = sd(ChangeSalaryGradeC)

egen tt2 = tag(Office SubFunc WL YearMonth)

/*
winsor2 PayBonusSD2, suffix(T) cuts(1 99) trim
hist PayBonusSD2T if tt2==1, frac xtitle("Standard deviation of pay within office-subfunction-WL-month")
graph export "$analysis/Results/2.Descriptives/PaySDSubfunc.pdf", replace

winsor2 SGSD2, suffix(T) cuts(1 99) trim
hist SGSD2T if tt2==1, frac xtitle("Standard deviation of promotions within office-subfunction-WL-month")
graph export "$analysis/Results/2.Descriptives/SGSDSubfunc.pdf", replace
*/


********************************************************************************
* RELATIONSHIP BETWEEN PROMOTIONS AND PRODUCTIVITY 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear
merge 1:1 IDlse YearMonth using  "$managersdta/Temp/ProductivityManagers.dta", keepusing(ProductivityStd Productivity )
keep if _merge ==3
drop _merge 
xtset IDlse YearMonth

* probability of promotion next year 
gen fPromWLC = f.PromWLC
gen fChangeSalaryGradeC = f.ChangeSalaryGradeC 
gen fChangeSalaryGrade = f.ChangeSalaryGrade
gen lfChangeSalaryGradeC =log(fChangeSalaryGradeC+1)

* log productivity, in india productivity is all in rupees  
gen lp = log(Productivity+1)

reg LogPayBonus lp i.Year $lcontrol if ISOCode == "IND", cluster(IDlse)

collapse  ProductivityStd Productivity LogPayBonus PayBonus (max) ChangeSalaryGradeC (max) PromWLC (max)  ChangeSalaryGrade (first) ISOCode, by(IDlse Year)
xtset IDlse Year

gen fChangeSalaryGradeC = f.ChangeSalaryGradeC 
gen fPromWLC= f.PromWLC 
gen fChangeSalaryGrade= f.ChangeSalaryGrade
gen lProductivityStd= l.ProductivityStd
gen lPayBonus = log(PayBonus)
gen flPayBonus = f.lPayBonus

gen fLogPayBonus = f.LogPayBonus
gen lp = log(Productivity+1) // log of productivity, in india productivity is all in rupees 

* probability of promotion 
gen fChangeSalaryGradeC1 = 0 if fChangeSalaryGradeC !=.
replace fChangeSalaryGradeC1 = 1 if fChangeSalaryGradeC >1 & fChangeSalaryGradeC !=.

reghdfe fChangeSalaryGradeC ProductivityStd if ISOCode == "IND", a(Year) vce(cluster IDlse)
reghdfe lPayBonus ProductivityStd if ISOCode == "IND", a(Year) vce(cluster IDlse) // 9% higher pay 

/* final graph 
reg fChangeSalaryGradeC1 ProductivityStd if ISOCode == "IND"
su fChangeSalaryGradeC1 if ISOCode == "IND"
binscatter fChangeSalaryGradeC1 ProductivityStd if ISOCode == "IND", xtitle("Productivity (s.d.)") ytitle("Probability of salary grade increase,t+1") ///
text(.3 -1  "Slope = 0.08 (0.006)" ) text(.285 -1.2  "N = 6386" ) text(.27 -0.9  "Mean, prob. promotion = 0.10" ) ///
note("Notes. Increasing productivity by 0.1 s.d. is associated with a 8% higher probability of salary grade increase in the next year." ) ///
title("") ysize(8) xsize(13.5)
*Relationship between productivity and promotions
graph save "$analysis/Results/2.Descriptives/ProdPromotion.pdf", replace 
graph export "$analysis/Results/2.Descriptives/ProdPromotion.png", replace 
*/

gen Productivity1000 = Productivity/1000
reg fChangeSalaryGradeC1 Productivity if ISOCode == "IND"
reg fChangeSalaryGradeC1 Productivity1000 if ISOCode == "IND"

su fChangeSalaryGradeC1 if ISOCode == "IND"

**# ON PAPER FIGURE: ProdPromotionCurrency.pdf
binscatter fChangeSalaryGradeC1 Productivity if ISOCode == "IND", xtitle("Productivity (indian rupees)", size(medium)) ytitle("Probability of salary grade increase,t+1", size(medium)) ///
title("") ysize(8) xsize(10)
*Relationship between productivity and promotions
graph save "$analysis/Results/0.Paper/1.2.Descriptives Figures/ProdPromotionCurrency.gph", replace 
graph export "$analysis/Results/0.Paper/1.2.Descriptives Figures/ProdPromotionCurrency.pdf", replace 
*text(.3 3000 "Slope = 0.02 (0.001)" ) text(.285 3000  "N = 6386" ) text(.27 3300  "Mean, prob. promotion = 0.10" ) ///

********************************************************************************
* RELATIONSHIP BETWEEN PROMOTIONS AND SALARY
********************************************************************************

use  "$managersdta/AllSnapshotMCultureMType.dta", clear

reg LogPayBonus PromWLC, cluster(IDlse)
reghdfe LogPayBonus PromWLC, cluster(IDlse) a(Country Func Year)

/*
binscatter LogPayBonus PromWLC, line(qfit) xtitle("Number of work-level promotions") ytitle("Pay (logs)") text(12 0.5  "Slope = .77 (0.007)" ) text(11.9 0.5  "N =  4,767,313" ) title("") note("Notes. Slope coefficient obtained by controlling for country function and year fixed effects." "Standard errors clustered at the worker level.")
*Relationship between salary and promotions
graph save "$analysis/Results/2.Descriptives/PayPromotionWL.gph", replace 
graph export "$analysis/Results/2.Descriptives/PayPromotionWL.pdf", replace 
*/

reg  LogPayBonus ChangeSalaryGradeC, cluster(IDlse)
reghdfe LogPayBonus ChangeSalaryGradeC, cluster(IDlse) a(Country Func Year)

**# ON PAPER FIGURE: PayPromotionSG.pdf
binscatter LogPayBonus ChangeSalaryGradeC, line(qfit) xtitle("Number of salary grade increases", size(medium)) ytitle("Pay (logs)", size(medium) )
*text(11.5 1.2  "Slope = .20 (0.002)" ) text(11.4 1.2  "N =  4,767,313" ) title("") 
*note("Notes. Slope coefficient obtained by controlling for country function and year fixed effects." "Standard errors clustered at the worker level.")
*Relationship between salary and promotions
graph save "$analysis/Results/0.Paper/1.2.Descriptives Figures/PayPromotionSG.gph", replace 
graph export "$analysis/Results/0.Paper/1.2.Descriptives Figures/PayPromotionSG.pdf", replace 


********************************************************************************
* TIMING OF MANAGER ROTATION: INCOMING MANAGER 
********************************************************************************

use "$managersdta/SwitchersAllSameTeam2.dta", clear 

* panel of the rotating managers, USEFUL TO LOOK AT MANAGER CHARACTERISTICS (LATER IN CODE) 
preserve 
keep  if KEi == 0 
keep IDlseMHR YearMonth 
duplicates  drop IDlseMHR YearMonth, force 
gen o = 1 
bys IDlseMHR (YearMonth), sort : gen TransitionNum = sum(o)
rename YearMonth TransitionMonth
reshape wide TransitionMonth, i(IDlseMHR) j(TransitionNum)
isid IDlseMHR
rename IDlseMHR IDlse  
save "$managersdta/Temp/MRotating.dta" , replace 
restore 

format Ei %tm
ta Ei, sort 
gen EiYear = year(dofm(Ei))
ta EiYear, sort // 75% of events before 2016
* note that 2016 is the middle year: there are 5 years before it and 5 years after it 

bys IDlse: egen MT = mean(cond(KEi==0 & WL2==1, IDlseMHR,.)) // take the manager that transitions

keep MT Ei 
duplicates drop 
rename MT IDlseMHR // manager ID
save "$managersdta/Temp/TimingInM2.dta", replace // list of incoming managers, one month before transitions

use "$managersdta/Temp/TimingInM2.dta", clear
sort IDlseMHR  Ei 
duplicates drop IDlseMHR, force // drops all but the first occurrence of each group of duplicated observations.
merge 1:m  IDlseMHR using "$managersdta/Temp/MType.dta"
keep if _merge==3
drop _merge
* get cumulative
gen IDlse = IDlseMHR
merge 1:1  IDlse YearMonth using "$managersdta/AllSnapshotMCulture.dta", keepusing(TransferSJC TransferSubFuncC)
keep if _merge==3
drop _merge 

sort IDlseMHR YearMonth

gen Window = YearMonth- Ei

* new hires - so to have non censored time in previous job 
* but might not be accurate because you could have been a worker before (this is min month of manager)
bys IDlseMHR: egen yearm = min(YearMonth)
format yearm %tm

* job before transition
encode  StandardJobM, gen( StandardJobME)
ge mmSJ  = StandardJobME if Window==-1 // job before
bys IDlseMHR: egen JobBefore= min( mmSJ) 
ge mmSJC  = TransferSJC if Window==-1 // job before C
bys IDlseMHR: egen JobBeforeC= min( mmSJC) 

ge mmASJ  = StandardJobME if Window==0 // job after
bys IDlseMHR: egen JobAfter= min( mmASJ) 
la val JobBefore mmSJ

* subfunc
ge mmSF  = SubFuncM if Window==-1
bys IDlseMHR: egen SFBefore= min( mmSF)
ge mmASF  = SubFuncM if Window==0
bys IDlseMHR: egen SFAfter= min( mmASF)
ge mmSFC  = TransferSubFuncC if Window==-1 // job before C
bys IDlseMHR: egen SFBeforeC= min( mmSFC) 

* min window
bys IDlseMHR: egen mW= min(Window) // min window
gen minWSJ= StandardJobME if mW == Window // first ever job 
bys  IDlseMHR: egen mminWSJ= min(minWSJ)
gen minWSF= SubFuncM if mW == Window // first ever SF
bys IDlseMHR: egen mminWSF= min(minWSF)

*indicator for same job as job before
gen i =  (StandardJobME == JobBefore   & Window<0 ) if  mminWSJ != JobBefore &  mW <0 &JobBefore!= JobAfter
gen iSF =  ( SubFuncM == SFBefore  & Window<0 ) if  mminWSF != SFBefore &  mW <0 & SFBefore!= SFAfter 

* total months in previous position
bys IDlseMHR : egen tot = sum(i) if  mminWSJ != JobBefore &  mW <0 & JobBefore!= JobAfter
bys IDlseMHR : egen totSF = sum(iSF) if  mminWSF != SFBefore &  mW <0 & SFBefore!= SFAfter 

**# ON PAPER FIGURE: MTimingInSFcdf.pdf
cdfplot totSF if Window==-1 & Ei>=tm(2019m1) &   Ei<=tm(2019m12), xlabel(0(5)85)  ylabel(0(0.1)1) xtitle("Months in previous position (manager)") xline(14) xline(31)
graph save "$analysis/Results/0.Paper/1.2.Descriptives Figures/MTimingInSFcdf.gph", replace 
graph export "$analysis/Results/0.Paper/1.2.Descriptives Figures/MTimingInSFcdf.pdf", replace 

 
********************************************************************************
* MACRO STATS/GRAPHS 
********************************************************************************

use  "$managersdta/AllSnapshotMCultureMType.dta", clear

gen o =1

gen Entry = Year ==  YearHire
drop if WLAgg ==0 

bys IDlse Year: egen minWLAgg = min(WLAgg)
replace WLAgg = minWLAgg

foreach v in TransferSJ TransferInternalLL TransferInternal PromWL ChangeSalaryGrade  LeaverPerm LeaverVol LeaverInv Entry{
bys IDlse Year: egen max`v' = max(`v')
replace `v' = max`v'	
}

gcollapse (mean) PayBonus Pay Bonus  BonusPayRatio Tenure  AgeContinuous Female  (sum) TransferSJ TransferInternalLL TransferInternal PromWL ChangeSalaryGrade  LeaverPerm LeaverVol LeaverInv Entry  o , by(Year WLAgg  )
bys Year: egen tot = sum(o)

forval i = 1/5{
	bys Year: egen NoWL`i' = mean(cond(WLAgg==`i',o,.))
	bys Year: egen ShareWL`i' = mean(cond(WLAgg==`i',o/tot,.))
	bys Year: egen SharePromWL`i' = mean(cond(WLAgg==`i',PromWL/o,.))
	bys Year: egen ShareExitWL`i' = mean(cond(WLAgg==`i',LeaverPerm/o,.))
	bys Year: egen TenureWL`i' = mean(cond(WLAgg==`i',Tenure,.))
	bys Year: egen AgeWL`i' = mean(cond(WLAgg==`i',AgeContinuous,.))
	bys Year: egen ShareEntryWL`i' = mean(cond(WLAgg==`i',Entry/o,.))
	bys Year: egen ShareFemaleWL`i' = mean(cond(WLAgg==`i',Female,.))

}

**# ON PAPER FIGURE: ShareWL.png
tw connected ShareWL1  Year ,     ||  connected  ShareWL2 Year  ,   || connected ShareWL3  Year ,  || connected ShareWL4  Year  ,  || connected ShareWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Share", size(medium)) ylabel(0(0.2)1)
gr save "$analysis/Results/0.Paper/1.2.Descriptives Figures/ShareWL.gph", replace
gr export "$analysis/Results/0.Paper/1.2.Descriptives Figures/ShareWL.pdf", replace

/* SIZE WL
tw  connected     NoWL2 Year  , yaxis(1) lcolor(orange) mcolor(orange)  || connected NoWL3  Year , yaxis(1) lcolor(green) mcolor(green)  || connected NoWL4  Year  , yaxis(1) lcolor(red) mcolor(red)   || connected NoWL5  Year  , yaxis(1) lcolor(purple) mcolor(purple)  legend(  label(1 "WL2") label(2 "WL3") label(3 "WL4") label(4 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Number of workers", size(medium)) ylabel(0(15000)150000)
gr export "$analysis/Results/2.Descriptives/SizeWL.pdf", replace
*/

**# ON PAPER FIGURE: TenureWL.png
tw connected TenureWL1  Year ,     ||  connected  TenureWL2 Year  ,   || connected TenureWL3  Year , || connected TenureWL4  Year  ,  || connected TenureWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Tenure", size(medium)) ylabel(0(5)30)
gr save "$analysis/Results/0.Paper/1.2.Descriptives Figures/TenureWL.gph", replace
gr export "$analysis/Results/0.Paper/1.2.Descriptives Figures/TenureWL.pdf", replace

**# ON PAPER FIGURE: AgeWL.png
tw connected AgeWL1  Year ,     ||  connected  AgeWL2 Year  ,   || connected AgeWL3  Year , || connected AgeWL4  Year  ,  || connected AgeWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Age", size(medium)) ylabel(30(5)60)
gr save "$analysis/Results/0.Paper/1.2.Descriptives Figures/AgeWL.gph", replace
gr export "$analysis/Results/0.Paper/1.2.Descriptives Figures/AgeWL.pdf", replace




