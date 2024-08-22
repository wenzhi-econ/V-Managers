********************************************************************************

* YM SERIES GRAPHS 
* Edited: 1 Oct 2020

********************************************************************************

*use "$dta/AllSnapshotWCM.dta", clear
use "$dta/AllSnapshotWCCultureC.dta", clear 
xtset IDlse YearMonth 

********************************************************************************
* GEN VARs
********************************************************************************

* Share of income to top managers and share of top managers  
tempvar total totalC TopManagerSC NTopManagerSC TopManagerS NTopManagerS WL1S WL2S WL3S WL4S WL5S
bys IDlse Year: egen TopManager = max(cond(WL>3, 1, 0))
bys IDlse Year: egen Others = max(cond( WL<=3, 1, 0))
bys ISOCode Year: egen `total' = total(PayBonus)
bys ISOCode Year: egen `totalC' = count(IDlse)
bys ISOCode Year: egen `TopManagerS' = total(cond(TopManager==1, PayBonus,0) )
bys ISOCode Year: egen `TopManagerSC' = count(cond(TopManager==1,IDlse,.) )
bys ISOCode Year: gen ShareTop = `TopManagerS'/`total'
bys ISOCode Year: gen ShareTopC = `TopManagerSC'/`totalC'
bys ISOCode Year: egen `NTopManagerS' = total(cond(TopManager==0, PayBonus,0) )
bys ISOCode Year: gen ShareNTop = `NTopManagerS'/`total'
replace WL = 5 if WL ==6
forval i=1(1)5{
	bys ISOCode Year: egen `WL`i'S' = total(cond(WL==`i', PayBonus,0) )
bys ISOCode Year: gen ShareWL`i' = `WL`i'S'/`total'
}

* time in same salary grade 
bys SalaryGrade IDlse: egen MonthsSalaryGrade = count(IDlse) // 

* cohort data
bys IDlse: egen TenureMin = min(Tenure)
bys IDlse: egen WLMin = min(WL)
replace FirstYear = . if TenureMin>=1 & FirstYear ==2011
bys Year FirstYear ISOCode WLMin: egen PRIsd = sd(PRI)
bys Year FirstYear ISOCode WLMin: egen LogPayBonussd = sd(LogPayBonus)

* Tenure bands
egen TenureB = cut(Tenure) , at(0,2, 5,10,20,30, 70 )

* Pay growth 
xtset IDlse YearMonth 
gen PayDelta = D.LogPay 
gen PayBonusDelta = D.LogPayBonus
gen BonusDelta = D.LogBonus 

global vars PayBonus Pay Bonus  BonusPayRatio  PayDelta BonusDelta PayBonusDelta TransferPTitleLateral TransferSubFuncLateral PromSalaryGradeLateral PromSalaryGradeVertical TransferPTitle TransferSubFunc PromSalaryGrade  LeaverPerm LeaverVol LeaverInv MonthsPromSalaryGrade MonthsSalaryGrade MonthsPTitle   MonthsSubFunc Tenure ShareTop ShareTopC ShareNTop ShareWL1 ShareWL2 ShareWL3 ShareWL4 ShareWL5 Entry PRIsd

preserve 
* residualize by country
foreach var in $vars { 
quietly: reg `var' i.Country
predict `var'R , res
replace `var' = `var'R
drop `var'R
}
gen o =1
bys YearMonth  ISOCode: egen AW = sum(o)
gcollapse $vars AW [aweight=AW], by(YearMonth Year  ISOCode CountryS Market )
gen LogPayBonus = log(PayBonus)
encode CountryS, gen(Country)
save "$temp/CLR.dta", replace 
restore 


* Save country level dataset
preserve 
gen o =1
bys YearMonth  ISOCode: egen AW = sum(o)
gcollapse $vars AW [aweight=AW], by(YearMonth Year  ISOCode CountryS Market)
gen LogPayBonus = log(PayBonus)
encode CountryS, gen(Country)
save "$temp/CL.dta", replace 
restore

global varsWL PayBonus Pay Bonus BonusPayRatio  TransferPTitleLateral TransferSubFuncLateral PromSalaryGradeLateral PromSalaryGradeVertical TransferPTitle TransferSubFunc PromSalaryGrade  LeaverPerm LeaverVol LeaverInv MonthsPromSalaryGrade MonthsPTitle  MonthsSalaryGrade  MonthsSubFunc Tenure Entry PRIsd

* Save -Year-WL level dataset
preserve 
gen o =1
bys YearMonth  ISOCode: egen AW = sum(o)
gcollapse $varsWL AW [aweight=AW], by(WL YearMonth Year ISOCode CountryS Market)
gen LogPayBonus = log(PayBonus)
encode CountryS, gen(Country)
save "$temp/CLWL.dta", replace 
restore

* Save -Year-Tenure level dataset
preserve 
gen o =1
bys YearMonth  ISOCode: egen AW = sum(o)
gcollapse $varsWL AW [aweight=AW], by(TenureB YearMonth Year ISOCode CountryS Market)
gen LogPayBonus = log(PayBonus)
encode CountryS, gen(Country)
save "$temp/CLTenure.dta", replace 
restore


********************************************************************************
* BY YEAR 
********************************************************************************

use "$temp/CL.dta", clear

gen o =1
drop if Market == 3

gcollapse (mean) PayBonus Pay Bonus PayDelta BonusDelta PayBonusDelta BonusPayRatio  MonthsPromSalaryGrade MonthsSalaryGrade MonthsPTitle   MonthsSubFunc Tenure  ShareTop ShareTopC ShareNTop ShareWL1 ShareWL2 ShareWL3 ShareWL4 ShareWL5 (sum) TransferPTitleLateral TransferSubFuncLateral PromSalaryGradeLateral PromSalaryGradeVertical TransferPTitle TransferSubFunc PromSalaryGrade  LeaverPerm LeaverVol LeaverInv Entry o [aweight=AW], by(Year  Market)

tw connected ShareTop  Year if Year >=2015 &  Year <2020  , yaxis(1)  ytitle( "Income share of top managers" ,axis(1) ) ytitle( "Employee share of top managers" ,axis(2) )  ||  connected  ShareTopC Year if Year >=2015 &  Year <2020 , yaxis(2) ytitle( "Employee share of top managers" ,axis(2) ) legend(label(1 "Income share") label(2 "Employee share")) xscale(range(2015(1)2019) ) xlabel(2015(1)2019)  by(Market, note("Top manager is defined as WL4+")) ysize(1.5)
gr export "$analysis/Full/Results/2.1.DesStats/ShareTop.jpg", replace

tw connected ShareWL1  Year if Year >=2015 &  Year <2020 , yaxis(1)  ytitle( "Income share WL1-WL3" ,axis(1) )  ||  connected  ShareWL2 Year if Year >=2015 &  Year <2020 , yaxis(1)  || connected ShareWL3  Year if Year >=2015 &  Year <2020 , lcolor(green) mcolor(green) yaxis(2) ytitle( "Income share WL3+" , axis(2) ) || connected ShareWL4  Year if Year >=2015 &  Year <2020 , yaxis(2) || connected ShareWL5  Year if Year >=2015 &  Year <2020 , yaxis(2) legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+")) xscale(range(2015(1)2019) ) xlabel(2015(1)2019) 
gr export "$analysis/Full/Results/2.1.DesStats/ShareWL.jpg", replace

tw connected PromSalaryGrade Year if Year<2020 , name(Promotion, replace) xlabel(#10) || connected PromSalaryGradeVertical Year if Year<2020 || connected PromSalaryGradeLateral Year if Year<2020, lcolor(green) mcolor(green) ysize(2) legend(label(1 "All Prom.") label(2 "Vertical Prom.") label(3 "Lateral Prom"))
gr export "$analysis/Full/Results/2.1.DesStats/PromotionY.jpg", replace

tw connected  LeaverPerm Year if Year<2020 , name(Exit, replace) xlabel(#10) || connected  LeaverVol Year if Year<2020  || connected  LeaverInv Year if Year<2020 , lcolor(green) mcolor(green) ysize(2) legend(label(1 "Exit") label(2 "Vol. Exit") label(3 "Inv. Exit"))
gr export "$analysis/Full/Results/2.1.DesStats/ExitY.jpg", replace

tw connected  TransferPTitle Year if Year<2020 ,  name(TransferPTitle, replace) xlabel(#10) ysize(2) legend(label(1 "Position Change") label(2 "Position Change Lateral") ) || connected  TransferPTitleLateral Year if Year<2020
gr export "$analysis/Full/Results/2.1.DesStats/TransferPTitleY.jpg", replace

tw connected TransferSubFunc Year if Year<2020 || connected  TransferSubFuncLateral Year if Year<2020,  ysize(2) legend(label(1 "SubFunc Change") label(2 "SubFunc Change Lateral")) name(TransferSubFunc, replace)  xlabel(2011(1)2019)
gr export "$analysis/Full/Results/2.1.DesStats/TransferSubFuncY.jpg", replace

tw connected MonthsSalaryGrade Year if Year<2020 ,  name(Promotion, replace) xlabel(#10) yaxis(1) || connected MonthsPTitle Year if Year<2020,  yaxis(1) || connected  MonthsSubFunc Year if Year<2020, lcolor(green) mcolor(green) ysize(2) legend(label(1 "Time in salary grade (months)") label(2 "Time in position (months)") label(3 "Time in subfunction (months)") label(4 "Tenure (years)"))  yaxis(1) ||  connected  Tenure Year if Year<2020, yaxis(2)  ytitle("Months", axis(1)) ytitle("Years", axis(2))
gr export "$analysis/Full/Results/2.1.DesStats/TenurePlusY.jpg", replace

tw connected  Tenure Year if Year<2020,    ytitle("Tenure (years)")
gr export "$analysis/Full/Results/2.1.DesStats/TenureY.jpg", replace

tw connected  Entry Year if Year<2020 & Year >2011,    ytitle("Entry rate")
gr export "$analysis/Full/Results/2.1.DesStats/EntryY.jpg", replace

tw connected PayBonus Year if Year>=2015 & Year<2020,  name(Salary, replace) xlabel(#10) || connected Pay Year if Year>=2015 & Year<2020 ||  connected Bonus Year if Year>=2015 & Year<2020, lcolor(green) mcolor(green) legend(label(1 "Pay+Bonus") label(2 "Pay") label(3 "Bonus")) xlabel(2015(1)2019) xscale(range(2015 2019))
gr export "$analysis/Full/Results/2.1.DesStats/SalaryY.jpg" , replace

tw connected PayBonusDelta Year if Year>=2015 & Year<2020,  name(SalaryDelta, replace) xlabel(#10) ||  connected PayDelta Year if Year>=2015 & Year<2020 || connected BonusDelta Year if Year>=2015 & Year<2020, lcolor(green) mcolor(green) legend(label(1 "Pay+Bonus Growth") label(2 "Pay Growth") label(3 "Bonus Growth")) xlabel(2015(1)2019) xscale(range(2015 2019))
gr export "$analysis/Full/Results/2.1.DesStats/SalaryDeltaY.jpg" , replace

********************************************************************************
* WL SPLIT
********************************************************************************

use "$temp/CLWL.dta", clear
drop if WL ==0

gcollapse (mean) PayBonus Pay Bonus BonusPayRatio  MonthsPromSalaryGrade MonthsPTitle   MonthsSubFunc Tenure  (sum) TransferPTitleLateral TransferSubFuncLateral PromSalaryGradeLateral PromSalaryGradeVertical TransferPTitle TransferSubFunc PromSalaryGrade  LeaverPerm LeaverVol LeaverInv Entry [aweight=AW], by(Year WL  )

tw connected PromSalaryGrade Year if Year<2020 & WL==1 , name(Promotion, replace) xlabel(#10) || connected PromSalaryGrade Year if Year<2020 & WL==2 || connected PromSalaryGrade Year if Year<2020 & WL==3, lcolor(green) mcolor(green) || connected PromSalaryGrade Year if Year<2020 & WL==4 || connected PromSalaryGrade Year if Year<2020 & WL==5   , ysize(2) legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+")) ytitle(Promotion rate (percent))
gr export "$analysis/Full/Results/2.1.DesStats/PromotionYWL.jpg", replace

tw connected BonusPayRatio  Year if Year<2020 & Year>=2015 & WL==1 , name(BonusPayRatio , replace) xlabel(#10) || connected BonusPayRatio  Year if Year<2020 & Year>=2015 & WL==2 || connected BonusPayRatio  Year if Year<2020 & Year>=2015 & WL==3, lcolor(green) mcolor(green) || connected BonusPayRatio  Year if Year<2020 & Year>=2015 & WL==4 || connected BonusPayRatio  Year if Year<2020 & Year>=2015 & WL==5   , ysize(2) legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+")) ytitle(Bonus over Pay (percent))  xscale(range(2015(1)2019)) xlabel(2015(1)2019)
gr export "$analysis/Full/Results/2.1.DesStats/BonusPayRatioYWL.jpg", replace

tw connected PayBonus  Year if Year<2020 & Year>=2015 & WL==1 , name(PayBonus , replace) xlabel(#10) || connected PayBonus  Year if Year<2020 & Year>=2015 & WL==2 || connected PayBonus  Year if Year<2020 & Year>=2015 & WL==3, lcolor(green) mcolor(green) || connected PayBonus  Year if Year<2020 & Year>=2015 & WL==4 || connected PayBonus  Year if Year<2020 & Year>=2015 & WL==5   , ysize(2) legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+")) ytitle("Total Compensation") xscale(range(2015(1)2019)) xlabel(2015(1)2019)
gr export "$analysis/Full/Results/2.1.DesStats/PayBonusYWL.jpg", replace

tw connected MonthsPromSalaryGrade  Year if Year<2020 & WL==1 , name(MonthsPromSalaryGrade , replace) xlabel(#10) || connected MonthsPromSalaryGrade  Year if Year<2020 & WL==2 || connected MonthsPromSalaryGrade  Year if Year<2020 & WL==3, lcolor(green) mcolor(green) || connected MonthsPromSalaryGrade  Year if Year<2020 & WL==4 || connected MonthsPromSalaryGrade  Year if Year<2020 & WL==5   , ysize(2) legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+")) ytitle("Time since promotion (months)")
gr export "$analysis/Full/Results/2.1.DesStats/MonthsPromSalaryGradeYWL.jpg", replace

tw connected Tenure  Year if Year<2020 & WL==1 , name(Tenure , replace) xlabel(#10) || connected Tenure  Year if Year<2020 & WL==2 || connected Tenure  Year if Year<2020 & WL==3, lcolor(green) mcolor(green) || connected Tenure  Year if Year<2020 & WL==4 || connected Tenure  Year if Year<2020 & WL==5   , ysize(2) legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+")) ytitle("Tenure (years)")
gr export "$analysis/Full/Results/2.1.DesStats/TenureYWL.jpg", replace

tw connected  LeaverPerm Year if Year<2020 & WL==1 , name( LeaverPerm , replace) xlabel(#10) || connected  LeaverPerm  Year if Year<2020 & WL==2 || connected  LeaverPerm  Year if Year<2020 & WL==3, lcolor(green) mcolor(green) || connected  LeaverPerm  Year if Year<2020 & WL==4 || connected  LeaverPerm  Year if Year<2020 & WL==5   , ysize(2) legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+")) ytitle("Exit rate (percent)")
gr export "$analysis/Full/Results/2.1.DesStats/LeaverPermYWL.jpg", replace

tw connected  Entry Year if Year<2020 & Year >2011 & WL==1 , name( Entry , replace) xlabel(#10) || connected  Entry Year if Year<2020 & Year >2011 & WL==2 || connected  Entry  Year if Year<2020 & Year >2011 & WL==3, lcolor(green) mcolor(green) || connected  Entry  Year if Year<2020 & Year >2011 & WL==4 || connected  Entry  Year if Year<2020 & Year >2011 & WL==5   , ysize(2) legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+"))    ytitle("Entry rate")
gr export "$analysis/Full/Results/2.1.DesStats/EntryYWL.jpg", replace

********************************************************************************
* TENURE SPLIT
********************************************************************************

use "$temp/CLTenure.dta", clear

gcollapse (mean) PayBonus Pay Bonus BonusPayRatio PayBonusDelta  MonthsPromSalaryGrade MonthsPTitle   MonthsSubFunc Tenure  (sum) TransferPTitleLateral TransferSubFuncLateral PromSalaryGradeLateral PromSalaryGradeVertical TransferPTitle TransferSubFunc PromSalaryGrade  LeaverPerm LeaverVol LeaverInv [aweight=AW], by(Year TenureB  )

tw connected  LeaverPerm Year if Year<2020 & TenureB==0 , name( LeaverPerm , replace) xlabel(#10) || connected  LeaverPerm  Year if Year<2020 & TenureB==2 || connected  LeaverPerm  Year if Year<2020 & TenureB==5, lcolor(green) mcolor(green) || connected  LeaverPerm  Year if Year<2020 & TenureB==10 || connected  LeaverPerm  Year if Year<2020 & TenureB==20 || connected  LeaverPerm  Year if Year<2020 & TenureB==30 , ysize(2) legend(label(1 "Tenure 0-1") label(2 "Tenure 2-4") label(3 "Tenure 5-9") label(4 "Tenure 10-19") label(5 "Tenure 20-29") label(6 "Tenure 30+") ) ytitle("Exit rate (percent)")
gr export "$analysis/Full/Results/2.1.DesStats/LeaverPermYTenure.jpg", replace

tw connected  PromSalaryGrade Year if Year<2020 & TenureB==0 , name( PromSalaryGrade, replace) xlabel(#10) || connected  PromSalaryGrade  Year if Year<2020 & TenureB==2 || connected  PromSalaryGrade  Year if Year<2020 & TenureB==5, lcolor(green) mcolor(green) || connected PromSalaryGrade  Year if Year<2020 & TenureB==10 || connected  PromSalaryGrade  Year if Year<2020 & TenureB==20 || connected  PromSalaryGrade Year if Year<2020 & TenureB==30  , ysize(2) legend(label(1 "Tenure 0-1") label(2 "Tenure 2-4") label(3 "Tenure 5-9") label(4 "Tenure 10-19") label(5 "Tenure 20-29") label(6 "Tenure 30+")) ytitle("Promotion rate (percent)")
gr export "$analysis/Full/Results/2.1.DesStats/PromSalaryGradeYTenure.jpg", replace


*(0,2, 5,10,20,30,40, 70 )

/*
gcollapse $vars , by(Year)

foreach var in $move{  
tw connected `var' Year if Year<2020, name(`var', replace) xlabel(#10)

gr save "$analysis/Full/Results/2.1.DesStats/`var'Y.gph", replace

}

foreach var in $pay{
	tw connected `var' Year if Year>2014 &  Year<2020,  name(`var', replace) xlabel(#6)
gr save "$analysis/Full/Results/2.1.DesStats/`var'Y.gph" , replace
	
}
gr combine "$analysis/Full/Results/2.1.DesStats/PayBonusY.gph" "$analysis/Full/Results/2.1.DesStats/PayY.gph" "$analysis/Full/Results/2.1.DesStats/BonusY.gph"
gr export "$analysis/Full/Results/2.1.DesStats/SalaryY.png", replace 

gr combine "$analysis/Full/Results/2.1.DesStats/TransferPTitleY.gph" "$analysis/Full/Results/2.1.DesStats/TransferPTitleLateralY.gph"  "$analysis/Full/Results/2.1.DesStats/TransferSubFuncY.gph"  
gr export "$analysis/Full/Results/2.1.DesStats/MoveY.png", replace 

gr combine "$analysis/Full/Results/2.1.DesStats/PromSalaryGradeY.gph" "$analysis/Full/Results/2.1.DesStats/PromSalaryGradeVerticalY.gph" "$analysis/Full/Results/2.1.DesStats/PromSalaryGradeLateralY.gph"
gr export "$analysis/Full/Results/2.1.DesStats/PromY.png", replace 

gr combine "$analysis/Full/Results/2.1.DesStats/LeaverPermY.gph" "$analysis/Full/Results/2.1.DesStats/LeaverVolY.gph" "$analysis/Full/Results/2.1.DesStats/LeaverInvY.gph"
gr export "$analysis/Full/Results/2.1.DesStats/ExitY.png", replace 
*/

********************************************************************************
* BY YEAR MONTH
********************************************************************************

use "$temp/CL.dta", clear
drop o
gen o =1
gcollapse $vars (sum) o, by(YearMonth Year  )

bys Year: su $vars


tw connected PromSalaryGrade YearMonth if Year<2020 , tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) tline(2015m4) tline(2014m4) tline(2013m4) tline(2012m4) tline(2011m4) name(Promotion, replace) xlabel(#10) || connected PromSalaryGradeVertical YearMonth if Year<2020 || connected PromSalaryGradeLateral YearMonth if Year<2020, lcolor(green) mcolor(green) ysize(2) legend(label(1 "All Prom.") label(2 "Vertical Prom.") label(3 "Lateral Prom"))
gr save "$analysis/Full/Results/2.1.DesStats/PromotionYM.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/PromotionYM.jpg", replace

tw connected  LeaverPerm YearMonth if Year<2020 , tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) tline(2015m4) tline(2014m4) tline(2013m4) tline(2012m4) tline(2011m4) name(Exit, replace) xlabel(#10) || connected  LeaverVol YearMonth if Year<2020  || connected  LeaverInv YearMonth if Year<2020 , lcolor(green) mcolor(green) ysize(2) legend(label(1 "Exit") label(2 "Vol. Exit") label(3 "Inv. Exit"))
gr save "$analysis/Full/Results/2.1.DesStats/ExitYM.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/ExitYM.jpg", replace

tw connected  TransferPTitle YearMonth if Year<2020 & YearMonth!=tm(2015m11)   , tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) tline(2015m4) tline(2014m4) tline(2013m4) tline(2012m4) tline(2011m4) name(TransferPTitle, replace) xlabel(#10) ysize(2) legend(label(1 "Position Change") label(2 "Position Change Lateral") ) || connected  TransferPTitleLateral YearMonth if Year<2020 & YearMonth!=tm(2015m11) 
gr save "$analysis/Full/Results/2.1.DesStats/TransferPTitleYM.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/TransferPTitleYM.jpg", replace

tw connected TransferSubFunc YearMonth if Year<2020 || connected  TransferSubFuncLateral YearMonth if Year<2020,  ysize(2) legend(label(1 "SubFunc Change") label(2 "SubFunc Change Lateral")) name(TransferSubFunc, replace) tmlabel(2011m1(12)2019m1)  xlabel(none)
gr save "$analysis/Full/Results/2.1.DesStats/TransferSubFuncYM.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/TransferSubFuncYM.jpg", replace

tw connected MonthsPromSalaryGrade YearMonth if Year<2020 ,  name(Promotion, replace) xlabel(#10) yaxis(1) || connected MonthsPTitle YearMonth if Year<2020,  yaxis(1) || connected  MonthsSubFunc YearMonth if Year<2020, lcolor(green) mcolor(green) ysize(2) legend(label(1 "Time since Prom.") label(2 "Time in position") label(3 "Time in subfunction") label(4 "Years in Company"))  yaxis(1) ||  connected  Tenure YearMonth if Year<2020, yaxis(2)
gr save "$analysis/Full/Results/2.1.DesStats/TenureYM.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/TenureYM.jpg", replace

tw connected PayBonus YearMonth if YearMonth>=tm(2015m12) & Year<2020, tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) name(Salary, replace) xlabel(#10) || connected Pay YearMonth if YearMonth>=tm(2015m12) & Year<2020 ||  connected Bonus YearMonth if YearMonth>=tm(2015m12) & Year<2020, lcolor(green) mcolor(green) legend(label(1 "Pay+Bonus") label(2 "Pay") label(3 "Bonus")) xlabel(, angle(45))
gr save "$analysis/Full/Results/2.1.DesStats/SalaryYM.gph" , replace
gr export "$analysis/Full/Results/2.1.DesStats/SalaryYM.jpg" , replace

tw connected PayBonusDelta YearMonth if YearMonth>=tm(2015m12) & Year<2020,  yaxis(1) tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) name(SalaryDelta, replace) xlabel(#10) ||  connected PayDelta YearMonth if YearMonth>=tm(2015m12) & Year<2020,  yaxis(1) || connected BonusDelta YearMonth if YearMonth>=tm(2015m12) & Year<2020,  yaxis(2) lcolor(green) mcolor(green) legend(label(1 "Pay+Bonus Growth") label(2 "Pay Growth") label(3 "Bonus Growth")) xlabel(, angle(45))
gr save "$analysis/Full/Results/2.1.DesStats/SalaryDeltaYM.gph" , replace
gr export "$analysis/Full/Results/2.1.DesStats/SalaryDeltaYM.jpg" , replace

********************************************************************************
* BY YEAR MONTH - residualized by country
********************************************************************************

use "$temp/CLR.dta", clear
drop o
gen o =1

gcollapse $vars (sum) o, by(YearMonth Year  )

bys Year: su $vars

tw connected PromSalaryGrade YearMonth if Year<2020 , tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) tline(2015m4) tline(2014m4) tline(2013m4) tline(2012m4) tline(2011m4) name(Promotion, replace) xlabel(#10) || connected PromSalaryGradeVertical YearMonth if Year<2020 || connected PromSalaryGradeLateral YearMonth if Year<2020, lcolor(green) mcolor(green) ysize(2) legend(label(1 "All Prom.") label(2 "Vertical Prom.") label(3 "Lateral Prom"))
gr save "$analysis/Full/Results/2.1.DesStats/PromotionYMR.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/PromotionYMR.jpg", replace

tw connected  LeaverPerm YearMonth if Year<2020 , tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) tline(2015m4) tline(2014m4) tline(2013m4) tline(2012m4) tline(2011m4) name(Exit, replace) xlabel(#10) || connected  LeaverVol YearMonth if Year<2020  || connected  LeaverInv YearMonth if Year<2020 , lcolor(green) mcolor(green) ysize(2) legend(label(1 "Exit") label(2 "Vol. Exit") label(3 "Inv. Exit"))
gr save "$analysis/Full/Results/2.1.DesStats/ExitYMR.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/ExitYMR.jpg", replace

tw connected  TransferPTitle YearMonth if Year<2020 & YearMonth!=tm(2015m11)   , tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) tline(2015m4) tline(2014m4) tline(2013m4) tline(2012m4) tline(2011m4) name(TransferPTitle, replace) xlabel(#10) ysize(2) legend(label(1 "Position Change") label(2 "Position Change Lateral") ) || connected  TransferPTitleLateral YearMonth if Year<2020 & YearMonth!=tm(2015m11) 
gr save "$analysis/Full/Results/2.1.DesStats/TransferPTitleYMR.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/TransferPTitleYMR.jpg", replace

tw connected TransferSubFunc YearMonth if Year<2020 || connected  TransferSubFuncLateral YearMonth if Year<2020,  ysize(2) legend(label(1 "SubFunc Change") label(2 "SubFunc Change Lateral")) name(TransferSubFunc, replace) tmlabel(2011m1(12)2019m1)  xlabel(none)
gr save "$analysis/Full/Results/2.1.DesStats/TransferSubFuncYMR.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/TransferSubFuncYMR.jpg", replace

tw connected MonthsPromSalaryGrade YearMonth if Year<2020 ,  name(Promotion, replace) xlabel(#10) yaxis(1) || connected MonthsPTitle YearMonth if Year<2020,  yaxis(1) || connected  MonthsSubFunc YearMonth if Year<2020, lcolor(green) mcolor(green) ysize(2) legend(label(1 "Time since Prom.") label(2 "Time in position") label(3 "Time in subfunction") label(4 "Years in Company"))  yaxis(1) ||  connected  Tenure YearMonth if Year<2020, yaxis(2)
gr save "$analysis/Full/Results/2.1.DesStats/TenureYMR.gph", replace
gr export "$analysis/Full/Results/2.1.DesStats/TenureYMR.jpg", replace

tw connected PayBonus YearMonth if YearMonth>=tm(2015m12) & Year<2020, tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) name(Salary, replace) xlabel(#10) || connected Pay YearMonth if YearMonth>=tm(2015m12) & Year<2020 ||  connected Bonus YearMonth if YearMonth>=tm(2015m12) & Year<2020, lcolor(green) mcolor(green) legend(label(1 "Pay+Bonus") label(2 "Pay") label(3 "Bonus")) xlabel(, angle(45))
gr save "$analysis/Full/Results/2.1.DesStats/SalaryYMR.gph" , replace
gr export "$analysis/Full/Results/2.1.DesStats/SalaryYMR.jpg" , replace

tw connected PayBonusDelta YearMonth if YearMonth>=tm(2015m12) & Year<2020,  yaxis(1) tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) name(SalaryDelta, replace) xlabel(#10) ||  connected PayDelta YearMonth if YearMonth>=tm(2015m12) & Year<2020,  yaxis(1) || connected BonusDelta YearMonth if YearMonth>=tm(2015m12) & Year<2020,  yaxis(2) lcolor(green) mcolor(green) legend(label(1 "Pay+Bonus Growth") label(2 "Pay Growth") label(3 "Bonus Growth")) xlabel(, angle(45))
gr save "$analysis/Full/Results/2.1.DesStats/SalaryDeltaYMR.gph" , replace
gr export "$analysis/Full/Results/2.1.DesStats/SalaryDeltaYMR.jpg" , replace


/*
global move TransferPTitleLateral  TransferSubFuncLateral PromSalaryGradeLateral PromSalaryGradeVertical TransferPTitle TransferSubFunc PromSalaryGrade  LeaverPerm LeaverVol LeaverInv
foreach var in $move{  
tw connected `var' YearMonth if Year<2020 , tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) tline(2015m4) tline(2014m4) tline(2013m4) tline(2012m4) tline(2011m4) name(`var', replace) xlabel(#10)

gr save "$analysis/Full/Results/2.1.DesStats/`var'YM.gph", replace
}

global pay  PayBonus Pay Bonus
foreach var in $pay{
	tw connected `var' YearMonth if YearMonth>=tm(2015m12) & Year<2020, tline(2019m04) tline(2018m4) tline(2017m4) tline(2016m4) name(`var'pre, replace) xlabel(#10)
gr save "$analysis/Full/Results/2.1.DesStats/`var'YM.gph" , replace	
}

gr combine "$analysis/Full/Results/2.1.DesStats/PayBonusYM.gph" "$analysis/Full/Results/2.1.DesStats/PayYM.gph" "$analysis/Full/Results/2.1.DesStats/BonusYM.gph"
gr export "$analysis/Full/Results/2.1.DesStats/SalaryYM.png", replace 

gr combine "$analysis/Full/Results/2.1.DesStats/TransferPTitleYM.gph" "$analysis/Full/Results/2.1.DesStats/TransferPTitleLateralYM.gph"  "$analysis/Full/Results/2.1.DesStats/TransferSubFuncYM.gph"  
gr export "$analysis/Full/Results/2.1.DesStats/MoveYM.png", replace 

gr combine "$analysis/Full/Results/2.1.DesStats/PromSalaryGradeYM.gph" "$analysis/Full/Results/2.1.DesStats/PromSalaryGradeVerticalYM.gph" "$analysis/Full/Results/2.1.DesStats/PromSalaryGradeLateralYM.gph"
gr export "$analysis/Full/Results/2.1.DesStats/PromYM.png", replace 

gr combine "$analysis/Full/Results/2.1.DesStats/LeaverPermYM.gph" "$analysis/Full/Results/2.1.DesStats/LeaverVolYM.gph" "$analysis/Full/Results/2.1.DesStats/LeaverInvYM.gph"
gr export "$analysis/Full/Results/2.1.DesStats/ExitYM.png", replace 
*/


********************************************************************************
* BY COHORT
********************************************************************************

* Graph by cohort 
collapse  PRIsd LogPayBonussd, by( Year  ISOCode CountryS FirstYear Market WLMin )
collapse  PRIsd LogPayBonussd, by( Year   FirstYear WLMin )

preserve 
keep if WLMin ==1 
tw connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2011 || connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2012 , name( PRIsd , replace) xlabel(#10) || connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2013, lcolor(green) mcolor(green) || connected PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2014,  || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2015 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2016 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2017 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2018 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2019   , ysize(2) legend(label(1 "2011") label(2 "2012") label(3 "2013") label(4 "2014") label(5 "2015") label(6 "2016") label(7 "2017") label(8 "2018") label(9 "2019") rows(2))  ytitle("WL 1 hires")
gr save "$analysis/Full/Results/2.1.DesStats/CohortPRIsd1.gph", replace
restore 

preserve 
keep if WLMin ==2
tw connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2011 || connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2012 , name( PRIsd , replace) xlabel(#10) || connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2013, lcolor(green) mcolor(green) || connected PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2014,  || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2015 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2016 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2017 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2018 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2019   , ysize(2) legend(label(1 "2011") label(2 "2012") label(3 "2013") label(4 "2014") label(5 "2015") label(6 "2016") label(7 "2017") label(8 "2018") label(9 "2019") rows(2))  ytitle("WL 2 hires")
gr save "$analysis/Full/Results/2.1.DesStats/CohortPRIsd2.gph", replace
restore

preserve 
keep if WLMin ==3
tw connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2011 || connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2012 , name( PRIsd , replace) xlabel(#10) || connected  PRIsd Year if Year<2020 & Year >2012 & FirstYear==2013, lcolor(green) mcolor(green) || connected PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2014,  || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2015 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2016 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2017 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2018 || connected  PRIsd  Year if Year<2020 & Year >2012 & FirstYear==2019   , ysize(2) legend(label(1 "2011") label(2 "2012") label(3 "2013") label(4 "2014") label(5 "2015") label(6 "2016") label(7 "2017") label(8 "2018") label(9 "2019") rows(2))  ytitle("WL 3 hires")
gr save "$analysis/Full/Results/2.1.DesStats/CohortPRIsd3.gph", replace
restore 

preserve 
keep if WLMin ==1 
tw connected  LogPayBonussd Year if Year<2020 & Year >2012 & FirstYear==2011 || connected  LogPayBonussd Year if Year<2020 & Year >2012 & FirstYear==2012 , name( PRIsd , replace) xlabel(#10) || connected  LogPayBonussd Year if Year<2020 & Year >2012 & FirstYear==2013, lcolor(green) mcolor(green) || connected LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2014,  || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2015 || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2016 || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2017 || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2018 || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2019   , ysize(2) legend(label(1 "2011") label(2 "2012") label(3 "2013") label(4 "2014") label(5 "2015") label(6 "2016") label(7 "2017") label(8 "2018") label(9 "2019") rows(2))  ytitle("WL 1 hires")
gr save "$analysis/Full/Results/2.1.DesStats/CohortLogPayBonussd1.gph", replace
restore

preserve 
keep if WLMin ==2
tw connected  LogPayBonussd Year if Year<2020 & Year >2012 & FirstYear==2011 || connected  LogPayBonussd Year if Year<2020 & Year >2012 & FirstYear==2012 , name( PRIsd , replace) xlabel(#10) || connected  LogPayBonussd Year if Year<2020 & Year >2012 & FirstYear==2013, lcolor(green) mcolor(green) || connected LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2014,  || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2015 || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2016 || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2017 || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2018 || connected  LogPayBonussd  Year if Year<2020 & Year >2012 & FirstYear==2019   , ysize(2) legend(label(1 "2011") label(2 "2012") label(3 "2013") label(4 "2014") label(5 "2015") label(6 "2016") label(7 "2017") label(8 "2018") label(9 "2019") rows(2))  ytitle("WL 2 hires")
gr save "$analysis/Full/Results/2.1.DesStats/CohortLogPayBonussd2.gph", replace
restore 
 
grc1leg "$analysis/Full/Results/2.1.DesStats/CohortPRIsd1.gph" "$analysis/Full/Results/2.1.DesStats/CohortPRIsd2.gph", col(2) legendfrom("$analysis/Full/Results/2.1.DesStats/CohortPRIsd2.gph") title(Cross-sectional variation in PR)
gr export "$analysis/Full/Results/2.1.DesStats/PRIsd.jpg", replace

grc1leg "$analysis/Full/Results/2.1.DesStats/CohortLogPayBonussd1.gph" "$analysis/Full/Results/2.1.DesStats/CohortLogPayBonussd2.gph", col(2) legendfrom("$analysis/Full/Results/2.1.DesStats/CohortLogPayBonussd2.gph")  title(Cross-sectional variation in log wages) ysize(1)
gr export "$analysis/Full/Results/2.1.DesStats/CohortLogPayBonussd.jpg", replace

collapse LogPayBonus , by( Year  ISOCode CountryS FirstYear Market )
collapse LogPayBonus , by( Year   FirstYear Market )

preserve 
keep if Market ==1 & Year>=2015
tw connected  LogPayBonus Year if Year<2020 & Year >2011 & FirstYear==2012 , name( LogPayBonus , replace) xlabel(#10) || connected  LogPayBonus Year if Year<2020 & Year >2011 & FirstYear==2013 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2014, lcolor(green) mcolor(green) || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2015 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2016 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2017 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2018 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2019   , ysize(2) legend(label(1 "2012") label(2 "2013") label(3 "2014") label(4 "2015") label(5 "2016") label(6 "2017") label(7 "2018") label(8 "2019") rows(2))      xscale(range(2015(1)2019) ) xlabel(2015(1)2019)    ytitle("Developed Country")
gr save "$analysis/Full/Results/2.1.DesStats/CohortDev1.gph", replace
restore 

preserve 
keep if Market ==2 & Year>=2015
tw connected  LogPayBonus Year if Year<2020 & Year >2011 & FirstYear==2012 , name( LogPayBonus , replace) xlabel(#10) || connected  LogPayBonus Year if Year<2020 & Year >2011 & FirstYear==2013 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2014, lcolor(green) mcolor(green) || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2015 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2016 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2017 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2018 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2019   , ysize(2) legend(label(1 "2012") label(2 "2013") label(3 "2014") label(4 "2015") label(5 "2016") label(6 "2017") label(7 "2018") label(8 "2019") rows(2))    ytitle("Developing Country")  xscale(range(2015(1)2019) ) xlabel(2015(1)2019) 
gr save "$analysis/Full/Results/2.1.DesStats/CohortDev2.gph", replace
restore 

grc1leg "$analysis/Full/Results/2.1.DesStats/CohortDev1.gph" "$analysis/Full/Results/2.1.DesStats/CohortDev2.gph", col(1) legendfrom("$analysis/Full/Results/2.1.DesStats/CohortDev2.gph") title("Wage (logs) by entry cohort")
gr export "$analysis/Full/Results/2.1.DesStats/CohortDev.jpg", replace

collapse LogPayBonus, by( Year   FirstYear  )
tw connected  LogPayBonus Year if Year<2020 & Year >2011 & FirstYear==2012 , name( LogPayBonus , replace) xlabel(#10) || connected  LogPayBonus Year if Year<2020 & Year >2011 & FirstYear==2013 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2014, lcolor(green) mcolor(green) || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2015 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2016 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2017 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2018 || connected  LogPayBonus  Year if Year<2020 & Year >2011 & FirstYear==2019   , ysize(2) legend(label(1 "2012") label(2 "2013") label(3 "2014") label(4 "2015") label(5 "2016") label(6 "2017") label(7 "2018") label(8 "2019") rows(2))    ytitle("Wage (logs) by entry cohort")  xscale(range(2015(1)2019) ) xlabel(2015(1)2019) 
