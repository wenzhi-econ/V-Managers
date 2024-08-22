********************************************************************************
* Generate month-subfunc-office level data about managerial jobs 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

gen o =1 

gen JobWL2 = WL==2
gen JobWL3 = WL==3
gen JobWL4Agg = WL>3 if WL!=.

gcollapse JobWL2 JobWL3 JobWL4Agg (sum) o, by(Office OfficeCode ISOCode YearMonth FuncS SubFuncS  )

label var o "Number of jobs within office-subfunc-month"
rename o UnitSize
compress 

save "$managersdta/Temp/ManagerJobs.dta", replace 

********************************************************************************
* Generate job-office level data about disappering and new jobs 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth 

gen o =1 

gcollapse (sum) o, by(StandardJob YearMonth FuncS SubFuncS OfficeCode Office CountryS ISOCode )
isid StandardJob YearMonth FuncS SubFuncS Office

sort Office SubFuncS StandardJob YearMonth

* Two equivalent methods: 
*1) looking for changes within subfunction and office 
bys SubFuncS Office StandardJob (YearMonth), sort: gen NewJob = StandardJob[_n] != StandardJob[_n-1]
bys SubFuncS Office StandardJob (YearMonth), sort: gen OldJob = StandardJob[_n] != StandardJob[_n+1]

bys SubFuncS Office StandardJob: egen mi  = min(YearMonth) 
bys SubFuncS Office StandardJob: egen ma  = max(YearMonth)

*2) using the minimum and maximum date 
bys SubFuncS Office StandardJob:  gen NewJob1 = cond(YearMonth==mi & mi!=tm(2011m1), 1 ,0,.)
replace OldJob =  . if YearMonth == tm(2020m3)
replace NewJob1 = . if YearMonth == tm(2011m1)

*StandardJob[_n] != StandardJob[_n-1]

replace OldJob = . if YearMonth == tm(2020m3)
replace NewJob = . if YearMonth == tm(2011m1)

compress 

save "$managersdta/NewOldJobs.dta", replace 

********************************************************************************
* Generate job-manager level data about disappering and new jobs 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth 

gen o =1 

gcollapse (sum) o, by(StandardJob YearMonth SubFuncM IDlseMHR Office OfficeCode CountryS ISOCode )
drop if IDlseMHR ==.
drop if  SubFuncM ==.

isid StandardJob  YearMonth IDlseMHR Office 

order IDlseMHR YearMonth StandardJob , first
sort IDlseMHR  YearMonth StandardJob

* using the minimum and maximum date
bys IDlseMHR   SubFuncM: egen miM  = min(YearMonth) 
bys IDlseMHR   SubFuncM: egen maM  = max(YearMonth) 
bys IDlseMHR  SubFuncM StandardJob: egen mi  = min(YearMonth) 
bys IDlseMHR  SubFuncM StandardJob: egen ma  = max(YearMonth)

bys IDlseMHR StandardJob  SubFuncM:  gen NewJobManager = cond(YearMonth==mi  & miM!=mi, 1 ,0,.)
bys IDlseMHR StandardJob  SubFuncM:  gen OldJobManager = cond(YearMonth==ma  & maM!=ma, 1 ,0,.)

compress 
drop miM maM mi ma
save "$managersdta/NewOldJobsManager.dta", replace 

********************************************************************************
* REGRESSION RESULTS TABLE/FIGURE
********************************************************************************

use "$managersdta/AllSameTeam2.dta", clear 

* choose the manager type !MANUAL INPUT!
global Label  FT  
global typeM  EarlyAgeM

* Relevant event indicator  
local Label $Label 
rename (KEi Ei) (KEiAllTypes EiAllTypes)
bys IDlse: egen Ei = max(cond( (`Label'LowLow ==1 | `Label'LowHigh ==1 | `Label'HighLow ==1 | `Label'HighHigh ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

local Label $Label 
bys IDlse: egen `Label'LHB = max(`Label'LowHigh)
bys IDlse: egen `Label'HLB = max(`Label'HighLow)
bys IDlse: egen `Label'HHB = max(`Label'HighHigh)
bys IDlse: egen `Label'LLB = max(`Label'LowLow)

*keep if Ei!=. 
gen KEi  = YearMonth - Ei 
gen Post = KEi >=0 if KEi!=.

gen JobbWL2 = WL==2
gen JobbWL3 = WL==3
gen JobbWL4Agg = WL>3 if WL!=.

merge m:1 Office SubFuncS StandardJob YearMonth using "$managersdta/NewOldJobs.dta" , keepusing(NewJob OldJob)
drop _merge 

merge m:1 StandardJob  YearMonth IDlseMHR Office  using "$managersdta/NewOldJobsManager.dta", keepusing(NewJobManager OldJobManager)
keep if _merge==3
drop _merge 

merge m:1  Office SubFuncS YearMonth using "$managersdta/Temp/ManagerJobs.dta", keepusing(JobWL2 JobWL3 JobWL4Agg UnitSize )
keep if _merge==3
drop _merge 

eststo clear 
foreach v in  JobWL2 OldJob NewJob  { // JobWL3 JobWL4Agg  NewJobManager OldJobManager
eststo `v': reghdfe `v' EarlyAgeM  if WL2==1 , cluster(IDlseMHR) a( Func YearMonth)
*eststo `v': reghdfe `v' EarlyAgeM  if WL2==1 , cluster(IDlseMHR) a( Func Country YearMonth)

} 

su JobWL2 OldJob NewJob if EarlyAgeM==0 & WL2==1

label var NewJob "Probability of job created"
label var OldJob "Probability of job destroyed"
label var  JobWL2 "Share of managerial jobs"

coefplot    NewJob OldJob   JobWL2  ,  keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) note("Switchers sample." "Controls include: function, year, month and country FE" "Standard errors clustered at the manager level. 90% Confidence Intervals.", span size(small)) legend(off) ///
aspect(0.4) xlabel(-0.008(0.002) 0.008) coeflabels(, ) ysize(6) xsize(8) ytick(,grid glcolor(black)) xline(0, lpattern(dash))
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/2.Descriptives/NewJob.png", replace

**# ON PAPER
coefplot    NewJob OldJob   JobWL2  ,  keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq  xlabel(-0.008(0.002) 0.008) ///
scale(1)  legend(off) coeflabels(, ) ysize(6) xsize(8) aspect(0.5) ytick(,grid glcolor(black)) xline(0, lpattern(dash))
graph export  "$analysis/Results/2.Descriptives/NewJobA.png", replace


