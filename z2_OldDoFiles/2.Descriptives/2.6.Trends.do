********************************************************************************
* TRENDS  
********************************************************************************

* Establishment size 
********************************************************************************

use  "$fulldta/AllSnapshot.dta", clear

bys Office YearMonth: egen OfficeSize= count(IDlse)
bys YearMonth: egen tot = count(IDlse)
bys YearMonth Country: egen totC = count(IDlse)

gen Share = OfficeSize/tot
gen ShareC = OfficeSize/totC

* DETERMINE 3 BIGGEST SITES WORLDWIDE 
ta OfficeCode if ISOCode =="GBR", sort //  2897 
ta OfficeCode if ISOCode =="IND", sort //  2274
ta OfficeCode if ISOCode =="USA", sort // 1220,  1222 
 
* office-month level 
gcollapse OfficeSize tot Share ShareC, by( OfficeCode Office ISOCode Country YearMonth)
quietly bys OfficeCode YearMonth:  gen dup = cond(_N==1,0,_n)
drop if OfficeSize== 1 & YearMonth ==tm(2012m8) & OfficeCode == 2644  // drop one duplicate
xtset OfficeCode YearMonth
gen Year = year(dofm(YearMonth))

* individual offices 
*br ISOCode OfficeCode if OfficeCode== 3745 | OfficeCode== 588 | OfficeCode== 1220 // 2897
* UK: 1406 (port),  1407, 2897 (100ve), 3745 (leatherhead),
* US:  1220, 1029 , 1027, 3743, 1222
* NLD: 588, 580

*GRAPH FOR 3 BIGGEST SITES
ta  Office if OfficeCode== 2897  | OfficeCode== 2274 | OfficeCode== 1220 // 100VE, Englewood Cliffs -700 Sylvan, Mumbai HQ
xtset OfficeCode YearMonth
tw connected  OfficeSize YearMonth if OfficeCode== 2897  || connected OfficeSize YearMonth if OfficeCode== 1220 || connected OfficeSize YearMonth if OfficeCode== 2274, legend(label(1 "UK") label(2 "USA") label(3 "IND")) ytitle("Establishment size: number of employees")
gr export "$analysis/Results/2.Descriptives/BiggestSize.png", replace

xtset OfficeCode YearMonth
tw connected  ShareC YearMonth if OfficeCode== 2897 || connected ShareC YearMonth if OfficeCode== 1220  || connected ShareC YearMonth if OfficeCode== 2274 , legend(label(1 "UK") label(2 "USA") label(3 "IND") ) ytitle("Establishment size (share): number of employees/total employees")
gr export "$analysis/Results/2.Descriptives/BiggestShare.png", replace

xtset OfficeCode YearMonth
tw connected  ShareC YearMonth if OfficeCode== 2897 || connected ShareC YearMonth if OfficeCode== 1220  , legend(label(1 "UK") label(2 "USA")  ) ytitle("Establishment size (share): number of employees/total employees")
gr export "$analysis/Results/2.Descriptives/BiggestShareC.png", replace

* collapse at year level
preserve
collapse OfficeSize Share ShareC, by( Year OfficeCode)

xtset OfficeCode Year
tw connected  OfficeSize Year if OfficeCode== 2897 || connected OfficeSize Year if OfficeCode== 1220  || connected OfficeSize Year if OfficeCode== 2274 , legend(label(1 "UK") label(2 "USA") label(3 "IND") ) ytitle("Number of employees in establishment over total employees") xlabel(2011(2)2021) title("Number of employees in establishment as a share of total employees over time", size(medsmall)) ylabel(800(100)1500)
gr export "$analysis/Results/2.Descriptives/BiggestSizey.png", replace

xtset OfficeCode Year
tw connected  Share Year if OfficeCode== 2897 || connected Share Year if OfficeCode== 1220  || connected Share Year if OfficeCode== 2274 , legend(label(1 "UK") label(2 "USA") label(3 "IND") ) ytitle("Number of employees in establishment over total employees") xlabel(2011(2)2021) title("Number of employees in establishment as a share of total employees over time", size(medsmall)) ylabel(0.006(0.001)0.012)
gr export "$analysis/Results/2.Descriptives/BiggestSharey.png", replace

xtset OfficeCode Year
tw connected  ShareC Year if OfficeCode== 2897 || connected ShareC Year if OfficeCode== 1220  , legend(label(1 "UK") label(2 "USA") ) ytitle("Number of employees in establishment over total employees in country") xlabel(2011(2)2021) title("Number of employees in establishment as a share of total employees in country", size(medsmall)) ylabel(0.06(0.02)0.20)
gr export "$analysis/Results/2.Descriptives/BiggestShareCy.png", replace

restore

* creating groups
***************** ***************** ***************** *****************  
*sort OfficeSize YearMonth 
*br  OfficeSize  ISOCode Office OfficeCode if YearMonth== tm(2011m1)
* 3 main sites: 
decode Office, gen(OfficeS)
gen Group = 1 if OfficeCode== 1406 | OfficeCode== 1407
replace Group = 2 if OfficeCode==1220 | OfficeCode==1029 | OfficeCode==1027 | OfficeCode== 3743 
replace Group = 3 if  OfficeS == "Mumbai" | OfficeS == "Mumbai Exports Office" | OfficeS == "Mumbai HO" | OfficeS == "Mumbai HURC" | OfficeS == "Mumbai Ho" | OfficeS == "Mumbai Hurc" | OfficeS == "Mumbai New Ventures Office" | OfficeS == "Mumbai Regional Office"
ta Office Group

bys Group YearMonth: egen GroupSize= total(OfficeSize)
gen ShareG = GroupSize/tot

preserve
keep if Group!=.
collapse GroupSize ShareG , by( Year Group)
 xtset Group Year
 
tw connected  GroupSize Year if Group==1 || connected GroupSize Year if Group==2  || connected GroupSize Year if Group==3 , legend(label(1 "UK") label(2 "USA") label(3 "IND") ) ytitle("Number of employees in establishment over total employees") xlabel(2011(2)2021) title("Number of employees in establishment as a share of total employees over time", size(medsmall)) note(Notes. Three biggest sites at the firm worldwide. )
gr export "$analysis/Results/2.Descriptives/BiggestSize.png", replace

tw connected  ShareG Year if Group==1 || connected ShareG Year if Group==2  || connected ShareG Year if Group==3 , legend(label(1 "UK") label(2 "USA") label(3 "IND") ) ytitle("Number of employees in establishment over total employees") xlabel(2011(2)2021) title("Number of employees in establishment as a share of total employees over time", size(medsmall)) note(Notes. Three biggest sites at the firm worldwide. )
gr export "$analysis/Results/2.Descriptives/BiggestShare.png", replace

restore
********************************************************************************

preserve
collapse OfficeSize, by( YearMonth)
OfficeCode== 3745 || OfficeCode== 588 || OfficeCode== 1220
 tw connected OfficeSize YearMonth 
restore
preserve 
collapse OfficeSize, by( YearMonth)
tw connected OfficeSize YearMonth
restore 

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

**# SHARE WL (ON PAPER)
tw connected ShareWL1  Year ,     ||  connected  ShareWL2 Year  ,   || connected ShareWL3  Year ,  || connected ShareWL4  Year  ,  || connected ShareWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Share", size(medium)) ylabel(0(0.2)1)
gr export "$analysis/Results/2.Descriptives/ShareWL.png", replace

* SIZE WL
tw  connected     NoWL2 Year  , yaxis(1) lcolor(orange) mcolor(orange)  || connected NoWL3  Year , yaxis(1) lcolor(green) mcolor(green)  || connected NoWL4  Year  , yaxis(1) lcolor(red) mcolor(red)   || connected NoWL5  Year  , yaxis(1) lcolor(purple) mcolor(purple)  legend(  label(1 "WL2") label(2 "WL3") label(3 "WL4") label(4 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Number of workers", size(medium)) ylabel(0(15000)150000)
gr export "$analysis/Results/2.Descriptives/SizeWL.png", replace

**# Tenure (ON PAPER)
tw connected TenureWL1  Year ,     ||  connected  TenureWL2 Year  ,   || connected TenureWL3  Year , || connected TenureWL4  Year  ,  || connected TenureWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Tenure", size(medium)) ylabel(0(5)30)
gr export "$analysis/Results/2.Descriptives/TenureWL.png", replace

**# AGE (ON PAPER)
tw connected AgeWL1  Year ,     ||  connected  AgeWL2 Year  ,   || connected AgeWL3  Year , || connected AgeWL4  Year  ,  || connected AgeWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Age", size(medium)) ylabel(30(5)60)
gr export "$analysis/Results/2.Descriptives/AgeWL.png", replace

* Female
tw connected ShareFemaleWL1  Year ,     ||  connected  ShareFemaleWL2 Year  ,   || connected ShareFemaleWL3  Year , || connected ShareFemaleWL4  Year  ,  || connected ShareFemaleWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Share of women", size(medium)) ylabel(0(0.1)0.8)
gr export "$analysis/Results/2.Descriptives/FemaleWL.png", replace

* PROMOTIONS
tw connected SharePromWL1  Year ,     ||  connected  SharePromWL2 Year  ,   || connected SharePromWL3  Year ,  || connected SharePromWL4  Year  ,  || connected SharePromWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Share", size(medium)) ylabel(0(0.01)0.05)
gr export "$analysis/Results/2.Descriptives/PromShareWL.png", replace

* EXIT 
tw connected ShareExitWL1  Year ,     ||  connected  ShareExitWL2 Year  ,   || connected ShareExitWL3  Year ,  || connected ShareExitWL4  Year  ,  || connected ShareExitWL5  Year  , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Share", size(medium)) ylabel(0(0.05)0.15)
gr export "$analysis/Results/2.Descriptives/ExitShareWL.png", replace

* ENTRY 
tw connected ShareEntryWL1  Year if Year>2011,     ||  connected  ShareEntryWL2 Year if Year>2011 ,   || connected ShareEntryWL3  Year if Year>2011,  || connected ShareEntryWL4  Year  if Year>2011,  || connected ShareEntryWL5  Year if Year>2011 , legend(label(1 "WL1") label(2 "WL2") label(3 "WL3") label(4 "WL4") label(5 "WL5+") cols(1)) xscale(range(2011(1)2021) ) xlabel(2011(1)2021,labsize(small) )  xtitle("Year", size(medium)) ytitle("Share", size(medium)) ylabel(0(0.05)0.2)
gr export "$analysis/Results/2.Descriptives/EntryShareWL.png", replace




