* This dofile looks at managers of BC & WC workers 

********************************************************************************
* 0. Setting path to directory
********************************************************************************

clear all
set more off

cd "$analysis"


********************************************************************************
* Preliminary graphs
********************************************************************************


use "$Managersdta/Managers.dta", clear 

/*bys IDlse : egen TenureMin = min(Tenure)
count if FirstYear ==2011 & TenureMin<=0
keep if (FirstYear >2011) | (FirstYear ==2011 & TenureMin==0)
save "$Managersdta/ManagersNew.dta", replace 
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
graph save "$Results/3.1.ManagerDes/EntryRate.gph", replace 
graph export "$Results/3.1.ManagerDes/EntryRate.png", replace 

restore 

use "$Managersdta/Managers.dta", clear 

* Number of spells 
preserve 
collapse (max) Spell, by(IDlse BC)
winsor2 Spell, suffix(W) cuts(1 99)
tw hist Spell if BC==0 ,  frac bcolor(teal%60) || hist Spell if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac xtitle(Number of manager spells per employee) ytitle("") xlabel(1(1)25)
graph save "$Results/3.1.ManagerDes/NoSpell.gph", replace 
graph export "$Results/3.1.ManagerDes/NoSpell.png", replace 

restore 

* Job changes overall
preserve 
collapse (max) TransferPTitle TransferPTitleC, by(IDlse BC)
winsor2 TransferPTitleC, suffix(W) cuts(1 99)
tw hist TransferPTitleC if BC==0 ,  frac bcolor(teal%60) || hist TransferPTitleC if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of job changes per employee) xlabel(0(1)25)
graph save "$Results/3.1.ManagerDes/NoJobChange.gph", replace 
graph export "$Results/3.1.ManagerDes/NoJobChange.png", replace 
restore 

* Promotions 
preserve 
collapse (max) ChangeSalaryGradeC PromSalaryGradeC, by(IDlse BC)
winsor2 ChangeSalaryGradeC, suffix(W) cuts(1 99)
tw hist ChangeSalaryGradeCW if BC==0 ,  frac bcolor(teal%60) || hist ChangeSalaryGradeCW if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of promotions per employee) xlabel(0(1)4)

graph save "$Results/3.1.ManagerDes/NoProm.gph", replace 
graph export "$Results/3.1.ManagerDes/NoProm.png", replace 
restore 

* Job changes lateral
preserve 
collapse (max)  TransferPTitleLateralC, by(IDlse BC)
tw hist TransferPTitleLateralC if BC==0 ,  frac bcolor(teal%60) || hist TransferPTitleLateralC if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of job changes per employee (lateral only)) xlabel(0(1)25)
graph save "$Results/3.1.ManagerDes/NoJobChangeNoProm.gph", replace 
graph export "$Results/3.1.ManagerDes/NoJobChangeNoProm.png", replace 
restore 

* Job changes under same manager 
preserve 
collapse (max) TransferPTitleDuringSpell TransferPTitleDuringSpellC, by(ID BC)
tw hist TransferPTitleDuringSpellC if BC==0 ,  frac bcolor(teal%60) || hist TransferPTitleDuringSpellC if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of job changes per employee-manager spell)
graph save "$Results/3.1.ManagerDes/NoJobChangeSpell.gph", replace 
graph export "$Results/3.1.ManagerDes/NoJobChangeSpell.png", replace 
restore 

* Job changes lateral under same manager 
preserve 
collapse (max)  TransferPTitleLateralDuringSC, by(ID BC)
tw hist TransferPTitleLateralDuringSC if BC==0 ,  frac bcolor(teal%60) || hist TransferPTitleLateralDuringSC if BC==1,  legend(label(1 "WC") label(2 "BC") ) bcolor(ebblue%60) frac ytitle("") xtitle(Number of job changes per employee (lateral only) per employee-manager spell) xlabel(0(1)9)
graph save "$Results/3.1.ManagerDes/NoJobChangeSpellNoProm.gph", replace 
graph export "$Results/3.1.ManagerDes/NoJobChangeSpellNoProm.png", replace 
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

use "$Managersdta/Managers.dta", clear

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
graph save "$Results/3.1.ManagerDes/NoReportees.gph", replace
graph export "$Results/3.1.ManagerDes/NoReportees.png", replace

********************************************************************************
* Internal promotions  
********************************************************************************

use "$Managersdta/Managers.dta", clear

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
graph save "$Results/3.1.ManagerDes/Internal.gph", replace
graph export "$Results/3.1.ManagerDes/Internal.png", replace


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
gr export "$Results/3.1.ManagerDes/PTransfer.png" ,replace 
restore

egen t = tag( IDlse IDlseMHR)
egen distinctM = total(t), by(IDlse)

collapse distinctM, by(IDlse BC)
su distinctM, d
* median number of managers is 2, mean is 3, 65% of employees have more than 1 manager
tw hist distinctM if BC==0, frac   xtitle("") discrete xlabel(0(1)13) bcolor(blue%80) || hist distinctM if BC==1, frac   xtitle("") discrete xlabel(0(1)13)  title(Number of different managers per employee) ysize(2)  bcolor(red%80) legend(label(1 "WC") label(2 "BC") )
gr export "$Results/3.1.ManagerDes/distinctM.png" ,replace 


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
gr save "$Results/3.1.ManagerDes/LeaverVol.gph" ,replace 

cibar LeaverInv, over(WL) graphopts( yscale(range(0(2)10)) ylabel(0(2)10) title("Layoffs") ytitle("%") legend(  cols(6)))
gr save "$Results/3.1.ManagerDes/LeaverInv.gph" ,replace 

gr combine "$Results/3.1.ManagerDes/LeaverVol.gph" "$Results/3.1.ManagerDes/LeaverInv.gph" , ysize(2) title(Distribution of exit by WL) note("Note. Only WC employees, averaging over 2011-2020. ")
gr export "$Results/3.1.ManagerDes/Exit.png" ,replace 
