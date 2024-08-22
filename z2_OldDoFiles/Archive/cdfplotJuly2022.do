rename MT IDlseMHR // manager ID

merge 1:m IDlseMHR YearMonth using "$Managersdta/AllSnapshotMCulture.dta"
keep if _merge ==3 

keep IDlseMHR YearMonth
rename YearMonth EventTime

save "$Managersdta/Temp/TimingM.dta", replace

bys IDlseMHR: egen JTm= max(JointTenure)
bys IDlseMHR: egen MSJm= min( MonthsSJM)

preserve
collapse JointTenure MonthsSJM MonthsSubFuncM JTm MSJm, by(IDlseMHR )
hist MonthsSJM  , xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash)) xline(30, lpattern(dash))
 hist JointTenure   , xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash)) xline(30, lpattern(dash))
 
  hist  MSJm  , xtitle("Months in previous position (manager)") xlabel(0(5)130) xline(15, lpattern(dash)) xline(30, lpattern(dash))
  gen
cdfplot MSJm 
restore

********************************************************************************
* TIMING OF MANAGER ROTATION: INCOMING MANAGER 
********************************************************************************

use "$Managersdta/SwitchersAllSameTeam2.dta", clear 

bys IDlse: egen MT = mean(cond(KEi==0 & WL2==1, IDlseMHR,.)) // take the manager that transitions

keep MT Ei 
duplicates drop 
rename MT IDlseMHR // manager ID
save "$Managersdta/Temp/TimingInM2.dta", replace // list of incoming managers, one month before transitions

use "$Managersdta/Temp/TimingInM2.dta", clear
sort IDlseMHR  Ei 
duplicates drop IDlseMHR, force // drops all but the first occurrence of each group of duplicated observations.
merge 1:m  IDlseMHR using "$Managersdta/Temp/MType.dta"
keep if _merge==3

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
ge mmASJ  = StandardJobME if Window==0 // job after
bys IDlseMHR: egen JobAfter= min( mmASJ) 
la val JobBefore mmSJ

* subfunc
ge mmSF  = SubFuncM if Window==-1
bys IDlseMHR: egen SFBefore= min( mmSF)
ge mmASF  = SubFuncM if Window==0
bys IDlseMHR: egen SFAfter= min( mmASF)

* min window
bys IDlseMHR: egen mW= min(Window) // min window
gen minWSJ= StandardJobME if mW == Window // first ever job 
bys  IDlseMHR: egen mminWSJ= min(minWSJ)
gen minWSF= SubFuncM if mW == Window // first ever SF
bys IDlseMHR: egen mminWSF= min(minWSF)

*indicator for same job as job before
gen i =  (StandardJobME == JobBefore  & Window<0 ) if  mminWSJ != JobBefore &  mW <0 &JobBefore!= JobAfter
gen iSF =  ( SubFuncM == SFBefore  & Window<0 ) if  mminWSF != SFBefore &  mW <0 & SFBefore!= SFAfter 

* total months in previous position
bys IDlseMHR : egen tot = sum(i) if  mminWSJ != JobBefore &  mW <0 & JobBefore!= JobAfter
bys IDlseMHR : egen totSF = sum(iSF) if  mminWSF != SFBefore &  mW <0 & SFBefore!= SFAfter 



* FINAL GRAPH
cdfplot tot if Window==-1  & Ei>=tm(2015m1) &   Ei<=tm(2015m12), xlabel(0(3)150) ysize(3)






* FINAL GRAPH
cdfplot totSF if Window==-1, xlabel(0(3)150) ysize(3)
