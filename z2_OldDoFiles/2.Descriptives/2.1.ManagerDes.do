* This dofile looks at managers of BC & WC workers 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"

********************************************************************************
* Share of higher fliers over countries, function, years 
********************************************************************************

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

gen FuncGroup =.
replace FuncGroup = 1 if Func == 3
replace FuncGroup = 2 if Func == 4
replace FuncGroup = 3 if Func == 6
replace FuncGroup = 4 if Func == 9 
replace FuncGroup = 5 if Func == 10
replace FuncGroup = 6 if Func == 11
replace FuncGroup = 7 if Func!=. & FuncGroup==.

ta FuncGroup, gen(FuncD)

* function 
preserve 
collapse EarlyAge (sum) o , by(FuncGroup)

label define FuncGroup 1 "Sales" 2 "Finance" 3 "HR" 4  "Marketing" 5 "R&D" 6 "Supply Chain" 7 "Other"
label value FuncGroup  FuncGroup 

graph bar EarlyAge , over(FuncGroup) ytitle("Share of high-flyer managers",size(medium)) yline(0.3, lcolor(maroon)) b1title("Function")
graph save "$analysis/Results/2.Descriptives/HFbyFunc.gph", replace
graph export "$analysis/Results/2.Descriptives/HFbyFunc.png", replace
restore 

* country
preserve 
collapse EarlyAge (sum) o , by(ISOCode)

egen r = rank( o), unique
graph bar EarlyAge if r>68 , over(ISOCode, lab(angle(45))) ytitle("Share of high-flyer managers", size(medium)) yline(0.3, lcolor(maroon)) ysize(3) b1title("Country")
graph save "$analysis/Results/2.Descriptives/HFbyCountry.gph", replace
graph export "$analysis/Results/2.Descriptives/HFbyCountry.png", replace
restore 

preserve 
collapse EarlyAge (sum) o , by(Year)

graph bar EarlyAge , over(Year, lab(angle(45))) ytitle("Share of high-flyer managers", size(medium)) yline(0.3, lcolor(maroon)) b1title("Year")

graph save "$analysis/Results/2.Descriptives/HFbyYear.gph", replace
graph export "$analysis/Results/2.Descriptives/HFbyYear.png", replace
restore 

********************************************************************************
* HOW MANY DIFFERENT WLs for a manager 
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 
egen t = tag(IDlseMHR WLM)
bys IDlseMHR: egen tt = total(t)
egen i = tag(IDlseMHR)
su tt if i==1, d

********************************************************************************
* how many lateral moves of manager during sample 
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 
egen o = tag(IDlseMHR)
bys IDlseMHR: egen y = max(TransferSJCM)
su y if o==1 // 2 

bys IDlse: egen it = max(cond(WL==2 & Manager  ==1, TransferSJC,. ))
egen i = tag(IDlse)

su it if i==1,d
su it if i==1 & YearHire  ==9999,d
su it if i==1 & YearHire  ==2011,d

su it if i==1 & YearHire  ==9999, d
su it if i==1 & YearHire  ==2011, d // People that I can follow from the start: 3

********************************************************************************
* FT MANAGER STATUS pre-determined for how my obs 
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

ta EarlyAgeM if WLM==MaxWLM
ta EarlyAgeM 

use  "$managersdta/Temp/MType.dta", clear

egen tt = tag(IDlseMHR)
count if EarlyAgeM==1 & WLM==MaxWLM & MaxWLM>1 
count if  EarlyAgeM & MaxWLM>1 
di    171324/242078 // 70%

* >>>> for most of managers FT predetermined 

********************************************************************************
* MISSING MANAGER DIAGNOSTICS 
********************************************************************************

use "$managersdta/AllSnapshotMCultureMType.dta", clear 

xtset IDlse YearMonth 
bys IDlse: egen missingM = count(cond(IDlseMHR==., YearMonth, .))
cap drop tt 
egen tt = tag(IDlse)

* Event Change manager
gsort IDlse YearMonth 
gen ChangeMM = 0 
replace ChangeMM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1] & IDlseMHR[_n-1]==. )

gen ChangeMM0 = 0 
replace ChangeMM0 = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n+1] & IDlseMHR[_n+1]==. ) 

* Much more frequent that one changes manager after a missing manager instance 
gen diffMM= 0 
replace diffMM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1] & ChangeMM==1 )

drop if IDlseMHR==. 
bys diffMM: su missingM if ChangeMM==1 ,d

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
**# ON PAPER
graph bar size0 size1 if  minAge<5, over(minAge)  bar(1, bfcolor("251 162 127")) bar(2, bfcolor("64 105 166"))   nofill legend(off) title("Age at promotion to work-level 2") ylabel(0(0.1)0.6)
graph export "$analysis/Results/2.Descriptives/AgeWL2FT.png", replace

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


**# ON PAPER
twoway    rarea Share0 Share1 Tenure if tw==1, sort  || rarea Share1 Share2 Tenure if tw==1, sort || rarea Share2 Share3 Tenure if tw==1, sort || rarea Share3 Share4 Tenure if  tw==1, sort  xlabel( 0(1)30, axis(1) )  ylabel( 0(.1)1 ) text( 0.4 5 "Work-level 1" 0.8 15  "Work-level 2"  0.94 20  "Work-level 3" 0.99  25 "Work-level 4+", size(medlarge)) ytitle(Percent of population, size(medlarge))  xtitle(Tenure, size(medlarge) axis(1))  legend(off)  scheme( white_ptol) 
graph export "$analysis/Results/2.Descriptives/WLTenure.png", replace

* with fast track manager indicator 
gen max=1
gen y3=3
twoway   rarea Share0 Share1 Tenure if tw==1, sort  || rarea Share1 Share2 Tenure if tw==1, sort || rarea Share2 Share3 Tenure if tw==1, sort || dropline max y3 if tw==1, lwidth(thick) lpattern(shortdash) lcolor(maroon) mcolor(none) || rarea Share3 Share4 Tenure if  tw==1, sort  xlabel( 0(1)30, axis(2) )  yscale(range(0 1)) ylabel( 0(.1)1 ) text( 0.4 5 "Work-level 1" 0.8 15  "Work-level 2"  0.94 20  "Work-level 3" 0.99  25 "Work-level 4+", size(medlarge)) ytitle(Percent of population, size(medlarge))  xtitle(Tenure, size(medlarge) axis(2))  legend(off)  scheme( white_ptol)  xline(3, lwidth(thick) lcolor(maroon) axis(1)) xaxis(1 2) xlabel(3 "Median tenure at promotion, fast-track manager", axis(1) labcolor(maroon)) xtitle("", axis(1)) 
graph save "$analysis/Results/2.Descriptives/WLTenureFT.gph", replace
graph export "$analysis/Results/2.Descriptives/WLTenureFT.png", replace

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
graph export "$analysis/Results/2.Descriptives/Internal.png", replace

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
graph export "$analysis/Results/2.Descriptives/Tenure.png", replace

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

**# ON PAPER
label define HF 0 "Low-flyer" 1 "High-flyer"
label value EarlyAgeM HF 
cibar MFEBayesLogPayF6075 if oo==1, over(EarlyAgeM )  graphopt(legend(size(medium)) ytitle("Manager value added in worker pay >=75th pc", size(medium) ) scheme(white_ptol) ylabel(0(0.1)0.4) ) 
graph export "$analysis/Results/2.Descriptives/HFCorrFE.png", replace 

cibar MFEBayesLogPay75 if oo==1, over(EarlyAgeM )   // very similar

********************************************************************************

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

* here are the actual median ages within group computed in MType.do: 26 35 44 53 62 
gen AgeContinuous = .
replace AgeContinuous = 26 if AgeBandM == 1
replace AgeContinuous = 35 if AgeBandM == 2
replace AgeContinuous = 44 if AgeBandM == 3
replace AgeContinuous = 53 if AgeBandM == 4
replace AgeContinuous = 62 if AgeBandM == 5

winsor2 SpanM, suffix(W) cuts(0 99)

egen CountryY = group(CountryM Year) 

// other variables 
gen WLAgg = WLM
replace WLAgg = 3 if WLM>3 & WLM!=.
tab WLAgg , gen(WLAgg)

bys IDlseMHR: egen max = max(WLM) // max WL observed 
gen maxWLAgg = max 
replace maxWLAgg = 3 if max>3 & max!=.
tab maxWLAgg , gen(maxWLAgg)

// generate WL dummies 
label var WLAgg1 "Work Level 1"
label var maxWLAgg1 "Work Level 1 (max)"
label var WLAgg2 "Work Level 2"
label var maxWLAgg2 "Work Level 2 (max)"
label var WLAgg3 "Work Level 3+"
label var maxWLAgg3 "Work Level 3+ (max)"

* maximum tenure 
bys IDlseMHR: egen maxTenureM = max(TenureM ) // max tenure observed 

// performance appraisals  
gen VPA100M = VPAM > 100 if VPAM!=.
gen VPA125M = VPAM >= 125 if VPAM!=.
gen LineManagerMeanB2 = LineManagerMean >=4.5 if LineManagerMean  !=. // effective LM 

xtset IDlseMHR YearMonth 
gen PayGrowth = d.LogPayBonusM 

bys IDlseMHR: egen minAge = min(AgeContinuous) // minimum age observed 

* generate age dummies 
replace AgeBandM = . if AgeBandM > 6 // age missing or under 18 (<0.01)
replace AgeBandM = 5 if AgeBandM>4 & AgeBandM !=. // 60+
tab AgeBandM, gen(Age)
label var Age1 "Age 18-29"  
label var Age2 "Age 30-39"
label var Age3 "Age 40-49"
label var Age4 "Age 50-59"
label var Age5 "Age +60"

* create mode of function & group functions in wider groups and make dummy 
gen FuncGroup = .
replace FuncGroup = 6 if !mi(FuncM)
replace FuncGroup = 1 if FuncM == 4
replace FuncGroup = 2 if FuncM == 3
replace FuncGroup = 3 if FuncM == 11
replace FuncGroup = 4 if FuncM == 10
replace FuncGroup = 5 if FuncM == 9
label define functiongroups 1 "Finance" 2 "Customer Development" 3 "Supply Chain" 4 "R\&D" 5 "Marketing" 6 "Other"
label values FuncGroup functiongroups

* mode
bys IDlseMHR: egen FuncMode = mode(FuncGroup), minmode

* dummies 
levelsof FuncMode, local(fugs)
foreach f of local fugs {
		gen FuncGroupMode`f' = FuncMode == `f'
}

label var FuncGroupMode1 "Finance"
label var FuncGroupMode2 "Customer Development"
label var FuncGroupMode3 "Supply Chain"
label var FuncGroupMode4 "R\&D"
label var FuncGroupMode5 "Marketing"
label var FuncGroupMode6 "Other Functions"

* Mid-career recruit 
bys IDlseMHR : egen FF= min(YearMonth)
bys IDlseMHR : egen FirstWL = mean(cond(YearMonth==FF, WLM, .)) // first WL observed 
bys IDlseMHR : egen FirstTenure = mean(cond(YearMonth==FF, TenureM, .)) // tenure in first month observed 

gen MidCareerHire = FirstWL>1 & FirstTenure<=1 & WLM!=. // they are only 10% of all managers!

* Only considering the performance after the observed maximum WL is achieved 
bys IDlseMHR: egen YearMaxWLM = min(cond(WLM == MaxWLM, YearMonth, .))
format YearMaxWLM %tm
gen Post = YearMonth >=  YearMaxWLM if YearMonth!=.
bys IDlseMHR: egen mm = min(Post)
ta mm if oo==1 // 87% of managers have their FT determined before the start of the data 

* List of variables
global CHARS  FemaleM AgeContinuous MBA TenureM WLM  TransferInternalM EarlyAgeMM
global TEAM SpanMW  ShareFemale   ShareOutGroup ShareDiffOffice  
global PRE ProductivityM LogPayBonusM PayBonusGrowthM PromWLCM SGSpeedM  VPAM   PRIM   
global LM LineManager ChangeSalaryGradeRMMean LeaverVolRMMean 

* Labels 
label var FemaleM "Female"
label var AgeBandM "Age Group" 
label var AgeContinuous "Age"
label var minAge "Age"
label var TenureM "Tenure (years)" 
label var maxTenureM "Tenure (years), max"
label var WLM   "Work Level"
label var max "Work Level, max"
label var SpanM "Span of Control"
label var SpanMW "Span of Control"
label var EarlyAgeM "High Flyer Manager"
label var ShareSameG "Team share, diff. gender"
label var ShareFemale "Team share, female"
label var ShareOutGroup  "Team share, diff. homecountry" 
label var ProductivityStdM "Sales achievement/target"
label var ProductivityM  "Sales achievement/target"
label var LogPayBonusM  "Pay + Bonus (logs)"
label var PayGrowth "Salary growth"
label var AvPayGrowth "Team pay growth"
label var MFEBayesPromSG75 "Workers' promotions >=75th pc"
label var MFEBayesLogPayF6075 "Manager value added in pay >=75th pc"
label var MFEBayesLogPay75 "Manager value added in pay >=75th pc"
*label var MFEBayesLogPay75v2 "Manager value added in pay >=75th pc"
label var MFEBayesLogPay50 "Manager value added in pay >=50th pc"
label var  MFEBayesLogPayF6050 "Manager value added in pay >=50th pc"
label var MFEBayesLogPayF7275 "Manager value added in pay >=75th pc"
label var  MFEBayesLogPayF7250 "Manager value added in pay >=50th pc"
label var LeaverPermM "Exit"
label var PromWLCM  "No. Prom. WL"
label var VPAM   "Perf. appraisal (1-150)"
label var PRIM "Perf. appraisal (1-5)"
label var LineManager "Effective leader (survey)"
label var LineManagerMean "Effective leader (survey)"
label var LineManagerMeanB "Effective leader (survey)"
label var ShareSameOffice  "Team share, same office"
label var PayBonusGrowthM  "Salary growth" 
label var ChangeSalaryGradeRMMean "Team mean prom. (salary)"
label var SGSpeedM "Prom. Speed (salary)"
label var LargeSpanM "Large span of control"
label var LeaverVolRMMean "Team mean vol. exit"
label var TransferInternalM "Internal rotations"
label var WLAgg3 "Promotion work-level 3" 
label var FuncMode "Function (mode)"
label var MidCareerHire "Mid-career recruit"
label var FlagUFLPM "Hired through graduate programme"

* High flyers in natural experiment 
merge m:1 IDlseMHR using "$managersdta/Temp/mSample.dta", keepusing(minAge)
keep if _merge==3 

********************************************************************************
* PRE-BALANCE TABLE (Characteristics determined before joining company), 
* ONLY KEEPING 1 MANAGER AND USING TIME INVARIANT CHARACTERISTICS 
********************************************************************************

global pre FemaleM minAge MidCareerHire FlagUFLPM MBA Econ Sci Hum Other 
*Missing FuncGroupMode1 FuncGroupMode2 FuncGroupMode3 FuncGroupMode4 FuncGroupMode5 FuncGroupMode6

global preFunc FemaleM minAge MidCareerHire FlagUFLPM MBA Econ Sci Hum  FuncGroupMode1 FuncGroupMode2 FuncGroupMode3 FuncGroupMode4 FuncGroupMode5
 
**# ON PAPER
balancetable HF FemaleM   MBA Econ Sci Hum Other MidCareerHire if oo==1  using "$analysis/Results/2.Descriptives/EarlyAgeMPre.tex", ///
replace  pval  varla vce(cluster IDlseMHR)  ctitles("Not High Flyer" "High Flyer" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}")
* observationscolumn // to show sample size

********************************************************************************
* POST-BALANCE TABLE, ONLY KEEPING 1 MANAGER AND USING AVERAGES OVER THE MONTHS 
********************************************************************************

reg TransferInternalM  HF if Post==1, vce(cluster IDlseMHR) // they are NOT more likely to transfer while being wl2

global perf  TenureM LogPayBonusM WLAgg1 WLAgg2 WLAgg3 VPAM LineManagerMean 
global other MidCareerHire FlagUFLPM maxTenureM max maxWLAgg1 maxWLAgg2 maxWLAgg3 PayGrowth ProductivityStdM ProductivityM TransferInternalM  TransferInternalC TransferSJC TransferFuncC
global mtype EarlyAgeM HF AvPayGrowth MFEBayesLogPay75 MFEBayesLogPay50 MFEBayesLogPayF6075 MFEBayesPromSG75 MFEBayesPromSG50 MFEBayesPromWL75 MFEBayesPromWL50
* LineManagerMeanB  
* EarlyAgeMM ChangeSalaryGradeRMMean LeaverVolRMMean  

preserve 
keep if Post==1 // only keeping the post performance (87% of managers) - after the High Flyer status is determined 
 foreach v of var  $mtype $perf $other {
 local l`v' : variable label `v'
       if `"`l`v''"' == "" {
		local l`v' "`v'"
}
}

collapse  $mtype $perf $other , by(IDlseMHR)

foreach v of var $mtype $perf $other {
 label var `v' `"`l`v''"'
}

reg TransferInternalM  EarlyAgeM
ta HF 
*  13,814  5,484     19,298 
**# ON PAPER
balancetable EarlyAgeM PayGrowth WLAgg3 VPAM LineManagerMean  using "$analysis/Results/2.Descriptives/EarlyAgeMPost.tex", ///
replace  pval  varla vce(cluster IDlseMHR)     ctitles("Not High Flyer" "High Flyer" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}") //  observationscolumn
*  MFEBayesLogPay75


* 1) in or out rotation - selection into rotation 
*************************************************
* HF
balancetable mT  PayGrowth TransferInternalM VPAM LineManagerMean MFEBayesLogPayF6075 if max!=1  &  EarlyAgeM==1 using "$analysis/Results/2.Descriptives/HFRotationPost.tex", ///
replace  pval  varla vce(cluster IDlseMHR)     ctitles("No rotation" "Rotation" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}") //  observationscolumn
*
* LF
balancetable mT  PayGrowth TransferInternalM VPAM LineManagerMean MFEBayesLogPayF6075 if max!=1  &  EarlyAgeM==0 using "$analysis/Results/2.Descriptives/LFRotationPost.tex", ///
replace  pval  varla vce(cluster IDlseMHR)     ctitles("No rotation" "Rotation" "Difference" "N")  ///
postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered by manager." "\end{tablenotes}") //  observationscolumn

restore 

********************************************************************************
* ARE MANAGERS MANAGER MORE LIKELY TO BE HIGH FLYERS IF MANAGER IS HIGH FLYER 
********************************************************************************

use "$managersdta/Temp/MType.dta", clear 
gen IDlse = IDlseMHR // my list of managers
rename EarlyAgeM EarlyAge
merge 1:1 IDlse YearMonth using "$managersdta/AllSnapshotMCulture.dta", keepusing(EarlyAgeM PromWL WL AgeBand Tenure)
keep if _merge ==3 
rename EarlyAgeM EarlyAgeMM
bys IDlse: egen mWL = min(WL)
bys IDlse: egen maxWL = max(WL)
bys IDlse: egen mm = min(cond(mWL==1 & maxWL>1 & WL==2 & PromWL==1,YearMonth-1,.)) // having had a high flyer before being promoted, identify the month before

* 14% higher chance of being FT manager if her own manager was FT
distinct IDlse if YearMonth==mm
reg  EarlyAge EarlyAgeMM if YearMonth==mm // 15%, having had a high flyer before being promoted, N=  2075
pwcorr  EarlyAge EarlyAgeMM if YearMonth==mm //13%
 
********************************************************************************
* DESCRIPTIVE STATS 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

bys YearMonth IDlseMHR: gen NoReportees = _N // number of direct reports
replace NoReportees =. if IDlseMHR==.
order NoReportees, a(IDlseMHR)
label var NoReportees "No. of employees reporting to same manager in current month"

gen ChangeM2=  ChangeM
replace ChangeM2 = 0 if ChangeM ==. 
bys IDlse: egen NoManagers = sum(ChangeM2)
replace NoManagers = NoManagers  +1 
egen t = tag(IDlse )
replace NoManagers = . if t==0 

gen o =1
bys IDlse: egen NoMonths = total(o)
replace NoMonths = . if t==0 

egen t0 = tag(IDlseMHR YearMonth)
bys IDlseMHR: egen NoReporteesMean = mean(cond(t0==1,NoReportees,.))
egen t1 = tag(IDlseMHR )
replace NoReporteesMean = . if t1==0 
su NoReportees IDlseMHR if NoReportees==.

egen tt = tag(IDlse IDlseMHR)
bys IDlseMHR: egen TotUniqueReportees = sum(tt)
replace TotUniqueReportees = . if t1==0 
bys IDlse: egen NoUniqueManagers = sum(tt)
replace NoUniqueManagers = . if t==0 

global suvarsT LogPayBonus BonusPayRatio VPA Tenure NoManagers NoReportees NoReporteesMean TotUniqueReportees NoUniqueManagers

foreach v in $suvarsT {
winsor2 `v', suffix(W) cuts(1 99) 
replace `v' = `v'W
}

global suvars  TransferInternalSJ  ChangeSalaryGrade PromWL LeaverPerm LogPayBonus BonusPayRatio VPA Tenure NoReportees NoMonths   NoManagers  NoUniqueManagers   NoReporteesMean TotUniqueReportees

label var LogPayBonus "Pay + bonus (logs)"
label var LogBonus "Bonus (logs)"
label var BonusPayRatio "Bonus over pay"
label var VPA "Perf. Appraisals"
label var TransferInternalSJ "Job Change"
label var ChangeSalaryGrade "Promotion (salary)"
label var PromWL  "Promotion (work-level)"
label var LeaverPerm "Exit"
label var Tenure  "Tenure (years)"
label var NoMonths "No. of months per worker"
label var NoReportees "Monthly team size" 
label var NoManagers "No. managers per worker"
label var NoUniqueManagers "No. unique managers per worker"
label var NoReporteesMean "Average no. of reportees per manager"
label var TotUniqueReportees "No. unique reportees per manager"

eststo clear 
eststo: estpost  su  $suvars 

esttab using "$Results/2.Descriptives/suStats.tex", ci(3)  label nonotes cells("mean(fmt(3) label(Mean)) sd(fmt(2) label(SD)) min(fmt(1) label(Min)) max(fmt(1) label(Max)) count(fmt(0) label(N))" ) noobs nomtitles nonumbers nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a worker-month-year. WC only. The data contain personnel records for the entire employee base from January 2011 until March 2020.  ///
"\end{tablenotes}")  replace

********************************************************************************
* Other graphs
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

/*bys IDlse : egen TenureMin = min(Tenure)
count if FirstYear ==2011 & TenureMin<=0
keep if (FirstYear >2011) | (FirstYear ==2011 & TenureMin==0)
save "$managersdta/ManagersNew.dta", replace 
*/

preserve 
drop if Year ==2011
egen t = tag(Year IDlse) // total employees 
keep if t ==1 
collapse (max) Entry (mean) t, by(Year WL BC IDlse) fast

bys WL BC Year: egen EntryN = sum(Entry)
bys WL BC Year: egen TotN = sum(t)
gen EntryRate = EntryN/TotN

egen tt = tag( WL BC Year)

drop if Year ==2020
label def BC 0 "WC" 1 "BC"
label value BC BC 
gen WL1 = WL
replace WL1 = 0 if BC==1
replace WL1 = 4 if WL>=4

graph bar EntryRate if tt==1,  asyvars over(WL1, label(labsize(small))) over(Year) ytitle(Entry Rate) bar(3, color(lavender)) legend(label(1 "BC" ) label(2 "WL1") label(3 "WL2" ) label(4 "WL3") label(5 "WL4+") rows(1)  )
graph save "$analysis/Results/2.Descriptives/EntryRate.gph", replace 
graph export "$analysis/Results/2.Descriptives/EntryRate.png", replace 

restore 

use  "$managersdta/AllSnapshotMCulture.dta", clear 

* Changing manager that transfers 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & (TransferInternalL1M==1 | TransferInternalL2M==1 | TransferInternalL3M==1 | TransferInternalF1M==1  | TransferInternalF2M==1  | TransferInternalF3M==1) 
replace  ChangeMR  = . if ChangeM==. 

* Number of spells 
preserve 
collapse (sum) ChangeM ChangeMR, by(IDlse )

winsor2 ChangeM, suffix(W) cuts(1 99)
replace ChangeM = ChangeM+ 1
replace ChangeMW = ChangeMW+ 1

tw hist ChangeM ,   bcolor(teal%60) frac xtitle(Number of manager spells per employee) ytitle("") xlabel(1(1)25) note("Notes. WC only.")
graph save "$analysis/Results/2.Descriptives/NoManagers.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoManagers.png", replace 

winsor2 ChangeMR, suffix(W) cuts(1 99)
replace ChangeMR = ChangeMR+ 1
tw hist ChangeMR ,    frac xtitle(Number of manager spells per employee) ytitle("") xlabel(1(1)10) note("Notes. WC only. Managers internal rotations only.")
graph save "$analysis/Results/2.Descriptives/NoManagersRotations.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoManagersRotations.png", replace 

su ChangeMW ,d
local mean1 = string(round(`r(p50)', 0.01), "%9.2f")
su ChangeMR ,d
local mean2 = string(round(`r(p50)', 0.01), "%9.2f")

tw    hist ChangeMW ,  bcolor(olive_teal) frac width(0.5) || hist ChangeMR ,  bcolor(teal) width(0.3) frac legend( label(1 "All managers' transitions")  label( 2 "Managers' internal rotations"))  xtitle(Number of manager spells per employee) ytitle("") xlabel(1(1)12) note("Notes. WC only.") 
*text(  0.47 5 "Mean (all) = `mean1'") text(  0.37 5 "Mean (internal rotation) = `mean2'") 
graph save "$analysis/Results/2.Descriptives/NoManagersAll.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoManagersAll.png", replace 

restore 

/*

collapse (max) Spell, by(IDlse BC)
winsor2 Spell, suffix(W) cuts(1 99)
tw hist Spell if BC==0 ,  frac bcolor(teal%60) || hist Spell if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac xtitle(Number of manager spells per employee) ytitle("") xlabel(1(1)25)
graph save "$analysis/Results/2.Descriptives/NoSpell.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoSpell.png", replace 

*/

* Job changes overall
preserve 
collapse (max)  TransferInternalSJC, by(IDlse )
winsor2 TransferInternalSJC, suffix(W) cuts(1 99)
replace  TransferInternalSJC =  TransferInternalSJC +1
tw hist TransferInternalSJC ,  frac bcolor(teal%60)  ytitle("") xtitle(Number of jobs per employee) xlabel(1(1)25) note("Notes. A job change is a change in either standard job title, office or org4 description (WC only).")
graph save "$analysis/Results/2.Descriptives/NoJobChange.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoJobChange.png", replace 
restore 

* sub-func (internal definition)
preserve 
collapse (max)  TransferInternalC, by(IDlse )
winsor2 TransferInternalC, suffix(W) cuts(1 99)
replace  TransferInternalC =  TransferInternalC +1
tw hist TransferInternalC ,  frac bcolor(teal%60)  ytitle("") xtitle(Number of jobs per employee (sub-func)) xlabel(1(1)25) note("Notes. A job change is a change in either sub-func, office or org4 description (WC only).")
graph save "$analysis/Results/2.Descriptives/NoSFChange.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoSFChange.png", replace 
restore 

/*
collapse (max)  TransferInternalSJC, by(IDlse BC )
winsor2 TransferPTitleC, suffix(W) cuts(1 99)
tw hist TransferPTitleC if BC==0 ,  frac bcolor(teal%60) || hist TransferPTitleC if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of job changes per employee) xlabel(0(1)25)
graph save "$analysis/Results/2.Descriptives/NoJobChange.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoJobChange.png", replace 
*/

* Promotions 
preserve 
collapse (max) ChangeSalaryGradeC PromWLC, by(IDlse BC)
winsor2 ChangeSalaryGradeC, suffix(W) cuts(1 99)
tw hist ChangeSalaryGradeCW if BC==0 ,  frac bcolor(teal%60) || hist ChangeSalaryGradeCW if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of promotions per employee) xlabel(0(1)4)

graph save "$analysis/Results/2.Descriptives/NoProm.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoProm.png", replace 
restore 

* Job changes lateral
preserve 
collapse (max)  TransferPTitleLateralC, by(IDlse BC)
tw hist TransferPTitleLateralC if BC==0 ,  frac bcolor(teal%60) || hist TransferPTitleLateralC if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of job changes per employee (lateral only)) xlabel(0(1)25)
graph save "$analysis/Results/2.Descriptives/NoJobChangeNoProm.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoJobChangeNoProm.png", replace 
restore 

* Job changes under same manager 
xtset IDlse YearMonth 
foreach var in TransferInternalSJ  TransferInternal TransferSJ TransferSubFunc{
gen `var'MM = `var'
replace `var'MM = 0 if ChangeM==1
replace `var'MM = 0 if f.ChangeM==1 // accounting for lags in reporting 
replace `var'MM = 0 if f2.ChangeM==1 // accounting for lags in reporting 
replace `var'MM = 0 if f3.ChangeM==1 // accounting for lags in reporting 
replace `var'MM = 0 if l.ChangeM==1
replace `var'MM = 0 if l2.ChangeM==1
replace `var'MM = 0 if l3.ChangeM==1

} 

preserve 
collapse (sum) TransferInternalSJMM TransferInternalSJ TransferInternalMM TransferInternal, by(IDlse)
su TransferInternalSJMM  
local mean1 = string(round(`r(mean)', 0.01), "%9.2f")
su TransferInternalSJ
local mean2 = string(round(`r(mean)', 0.01), "%9.2f")
tw hist TransferInternalSJMM ,  frac bcolor(teal%60)  ytitle("") xtitle(Number of job changes per employee) ||  hist TransferInternalSJ  ,  frac bcolor(ebblue%60)  legend(label(1 "Job changes under same manager") label(2 "All job changes") ) text(  0.4 5 "Mean (same manager) = `mean1'") text(  0.37 5 "Mean (all) = `mean2'") 
graph save "$analysis/Results/2.Descriptives/NoJobChangeM.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoJobChangeM.png", replace 

su TransferInternalMM  
local mean1 = string(round(`r(mean)', 0.01), "%9.2f")
su TransferInternal
local mean2 = string(round(`r(mean)', 0.01), "%9.2f")
tw hist TransferInternalMM ,  frac bcolor(teal%60)  ytitle("") xtitle(Number of sub-func changes per employee) ||  hist TransferInternal  ,  frac bcolor(ebblue%60)  legend(label(1 "Sub-func changes under same manager") label(2 "All sub-func changes") ) text( 0.5 5 "Mean (same manager) = `mean1'") text( 0.47 5 "Mean (all) = `mean2'") 
graph save "$analysis/Results/2.Descriptives/NoSFChangeM.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoSFChangeM.png", replace
restore

/*preserve 
collapse (max) TransferPTitleDuringSpell TransferPTitleDuringSpellC, by(ID BC)
tw hist TransferPTitleDuringSpellC if BC==0 ,  frac bcolor(teal%60) || hist TransferPTitleDuringSpellC if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of job changes per employee-manager spell)
graph save "$analysis/Results/2.Descriptives/NoJobChangeSpell.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoJobChangeSpell.png", replace 
restore 
*/

* Job changes lateral under same manager 
preserve 
collapse (max)  TransferPTitleLateralDuringSC, by(ID BC)
tw hist TransferPTitleLateralDuringSC if BC==0 ,  frac bcolor(teal%60) || hist TransferPTitleLateralDuringSC if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of job changes per employee (lateral only) per employee-manager spell) xlabel(0(1)9)
graph save "$analysis/Results/2.Descriptives/NoJobChangeSpellNoProm.gph", replace 
graph export "$analysis/Results/2.Descriptives/NoJobChangeSpellNoProm.png", replace 
restore 

*CHECK HOW MANY JOB CHANGES ARE ALSO PROMOTIONS 
gen a = TransferPTitleDuringSpell
replace a = 0 if PromSalaryGrade ==1
bys IDlse Spell: egem maxChange = max(TransferPTitleDuringSpell)
bys IDlse Spell: egen maxChangeNoProm = max(a)
/* su maxChange maxChangeNoProm

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
   maxChange | 14,894,908    .3716612    .4832486          0          1
maxChangeN~m | 14,894,908     .355149    .4785585          0          1

*/

********************************************************************************
* Team size   
********************************************************************************

use  "$managersdta/AllSnapshotMCulture.dta", clear

gen o = 1
keep if YearMonth == ym(2019,12)

collapse (sum) o , by(IDlseMHR WLM BC )
rename o TeamSize
gen TeamSizeInt = int(TeamSize)
replace WLM  = 4 if WLM >4
replace BC = . if WLM >1 & BC ==1
label define BC 0 "WC" 1 "BC"
label value BC BC 
graph hbar (median) TeamSizeInt , over(BC) over(WLM, descending relabel(1 "WL 1 Manager" 2 "WL 2 Manager" 3 "WL 3 Manager" 4 "WL 4+ Manager")  ) b1title(Median number of direct reportees per manager) bar(1, color(green%60)) bargap(0) ///
blabel(bar, position(outside)  color(dkgreen) size( medium)) ytitle("") note("Notes. Snapshot from December 2019.")
graph save "$analysis/Results/2.Descriptives/NoReportees.gph", replace
graph export "$analysis/Results/2.Descriptives/NoReportees.png", replace

********************************************************************************
* 2020 UNIVOICE - most important   
********************************************************************************

use "$fulldta/UniVoice.dta", clear

ta Year if Top3LM!=. // 2020, 2021

keep if Year==2020
drop if Top3LM==.

loc n = _N
di `n'

collapse (mean) Top3*

foreach v of varl * {
	replace `v'=100*`v'
	format `v' %9.2f
} 


xpose, varname clear

gen label = "My Line Manager" if _varname == "Top3LM"
replace label = "Senior Leadership" if _varname == "Top3Senior" 
replace label = "Purpose and Sustainability" if _varname == "Top3Purpose" 
replace label = "Wellbeing" if _varname == "Top3Wellbeing" 
replace label = "Learning" if _varname == "Top3Learning" 
replace label = "Career Opportunities" if _varname == "Top3Career"
replace label = "Growth Mindset" if _varname == "Top3Growth" 
replace label = "Diversity and Inclusion" if _varname == "Top3Diverse" 
replace label = "Business integrity" if _varname == "Top3Integrity" 
replace label = "Working for a company I am proud of" if _varname == "Top3Pride" 
replace label = "Simplification and agility" if _varname == "Top3agility" 

graph hbar v1, over(label, desc sort(v1)) scheme(aurora) ytitle("% responses (out of `n')") title("Responses to: Which top 3 areas are most important to you?") note("2020 UniVoice Survey, all countries.")
graph export "$analysis/Results/2.Descriptives/TopAreas.png", replace


********************************************************************************
* SPAN OF CONTROL: does it grow over time for each manager? 
********************************************************************************
  
use  "$managersdta/Temp/MType.dta", clear

isid IDlseMHR YearMonth
keep if WLM >1 // only manager title 
xtset IDlseMHR YearMonth 

winsor2 SpanM, trim suffix(T) cuts(0 99)
ta WLM
cibar SpanMT, over(WLM) graphopt(ylabel(2(2)14) title("Team size over manager work-level") ytitle("Team Size") xtitle("Work-level") ///
note("Notes. Plotting the average number of reportees at each manager work-level." "75% of managers are WL2, 20% are WL3 and 4% are WL4 and 1% are WL5+. "))
graph export "$analysis/Results/2.Descriptives/SpanWBar.png", replace 


gen o =1 
sort IDlseMHR YearMonth 

bys IDlseMHR: gen t = sum(o)

bys IDlseMHR: egen x = sd(WLM)
su x, d

reg SpanM WLM, a(FuncM)
binscatter SpanM WLM , absorb(FuncM ) title(Team Size) xtitle(Work level) ytitle(Team Size) note("Notes. Controlling for function FE. Coeff=2")
graph export "$analysis/Results/2.Descriptives/SpanWL.png", replace 

reg SpanM TenureM, a(IDlseMHR)
binscatter SpanM TenureM , absorb(IDlseMHR) title(Team Size) xtitle(Tenure) ytitle(Team Size) note("Notes. Controlling for manager FE. Coeff=0.08")
graph export "$analysis/Results/2.Descriptives/SpanTenure.png", replace 

preserve 
collapse SpanMG, by(t  )
tw connected SpanMG t
restore 

preserve
collapse SpanMG, by(TenureM )
tw connected SpanMG TenureM 
restore 

********************************************************************************
* MEETINGS WITH MANAGER - WPA WORKPLACE ANALYTICS DATA 
********************************************************************************
* Data is for 2019, Home care division, 2000 employees, calendar data weekly hours  

use "$managersdta/WPAHC.dta", clear 
global y  multitasking_meeting_hours meeting_hours__short_ meeting_hours__small_ internal_network_size external_network_size meeting_hours_with_skip_level total_focus_hours after_hours_email_hours email_hours conflicting_meeting_hours redundant_meeting_hours collaboration_hours_external low_quality_meeting_hours after_hours_meeting_hours meeting_hours_with_manager meeting_hours_with_manager_11 meeting_hours workweek_span

foreach var in $y{
ge l`var'  = log(`var' +1)
} 

ta Month // 2012m12-2019m11 
gen EarlyAgeM = (AgeBand ==1 & WL==2) 

foreach y in $y {
reghdfe  `y' EarlyAgeM if WL==2, a(Month ) vce( cluster IDlseMS)
}

* STATISTICS IN THE PAPER 
reghdfe  meeting_hours_with_manager   EarlyAgeM if WL==2, a(Month ) vce( cluster IDlseMS)
su meeting_hours_with_manager if WL==2
* 0.7 hours and 21% relative to mean

reghdfe   meeting_hours__small_   EarlyAgeM if WL==2, a(Month ) vce( cluster IDlseMS)
su  meeting_hours__small_ if WL==2

*use "$managersdta/WPAHCQuery.dta", clear 

/********************************************************************************
* TOT NO OF MANAGERS OVER CAREER
********************************************************************************

use "$data/dta/AllSnapshotMBC", clear 
append using "$dta/AllSnapshotWCCultureC.dta"

*preserve 
*sample 5
*save "$temp/5percent.dta", replace 
*restore 

tab BCM
tab WLM
tab FuncM

gsort IDlse YearMonth
bys IDlse IDlseMHR: egen r = rank(YearMonth) 
bys IDlse IDlseMHR: egen a = sum(TransferPTitle ) if r !=1

preserve
collapse a, by(IDlse IDlseMHR BC)
tw hist a if BC == 0, bcolor(blue%80) frac || hist a if BC==1, frac  bcolor(red%80) legend(label(1 "WC") label(2 "BC") )
gr export "$analysis/Results/2.Descriptives/PTransfer.png" ,replace 
restore

egen t = tag( IDlse IDlseMHR)
egen distinctM = total(t), by(IDlse)

collapse distinctM, by(IDlse BC)
su distinctM, d
* median number of managers is 2, mean is 3, 65% of employees have more than 1 manager
tw hist distinctM if BC==0, frac   xtitle("") discrete xlabel(0(1)13) bcolor(blue%80) || hist distinctM if BC==1, frac   xtitle("") discrete xlabel(0(1)13)  title(Number of different managers per employee) ysize(2)  bcolor(red%80) legend(label(1 "WC") label(2 "BC") )
gr export "$analysis/Results/2.Descriptives/distinctM.png" ,replace 


********************************************************************************
* WC
********************************************************************************

use "$dta/AllSnapshotWCCultureC.dta", clear 
xtset IDlse YearMonth
reghdfe LeaverPerm l.PromSalaryGrade l2.PromSalaryGrade l3.PromSalaryGrade l4.PromSalaryGrade l5.PromSalaryGrade l6.PromSalaryGrade c.Tenure##c.Tenure , a(AgeBand Country Year Func) vce(robust)
* people no more likely to leave after promotion 

collapse (max) LeaverPerm LeaverVol LeaverInv WL, by(IDlse Year )
drop if WL==0
replace LeaverVol = LeaverVol*100
replace LeaverInv = LeaverInv*100
replace LeaverPerm = LeaverPerm*100

cibar LeaverPerm , over(WL) graphopts(legend(  cols(6)))

cibar LeaverVol, over(WL) graphopts( yscale(range(0(2)10)) ylabel(0(2)10) title("Quits") ytitle("%") legend(  cols(6)))
gr save "$analysis/Results/2.Descriptives/LeaverVol.gph" ,replace 

cibar LeaverInv, over(WL) graphopts( yscale(range(0(2)10)) ylabel(0(2)10) title("Layoffs") ytitle("%") legend(  cols(6)))
gr save "$analysis/Results/2.Descriptives/LeaverInv.gph" ,replace 

gr combine "$analysis/Results/2.Descriptives/LeaverVol.gph" "$analysis/Results/2.Descriptives/LeaverInv.gph" , ysize(2) title(Distribution of exit by WL) note("Note. Only WC employees, averaging over 2011-2020. ")
gr export "$analysis/Results/2.Descriptives/Exit.png" ,replace 
