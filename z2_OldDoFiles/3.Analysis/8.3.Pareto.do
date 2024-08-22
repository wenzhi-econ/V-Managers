********************************************************************************
* This do files conducts team level analysis at the month level - ASYMMETRIC
* OUTCOMES AT THE TEAM LEVEL TO THINK ABOUT PARETO IMPROVEMENTS 
********************************************************************************

use "$managersdta/Teams.dta" , clear 

*keep if Year>2013 // post sample only 

bys team: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys team: egen minK = min(KEi)
bys team: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

foreach var in FT {
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
} 

foreach Label in FT {
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
	replace `var'Pre = . if `Label'LH==. & `Label'LL ==. & `Label'HH ==. & `Label'HL ==. // missing for non-switchers
	
}
	label var  `Label'LHPre "Low to High"
	label  var `Label'LLPre "Low to Low"
	label  var `Label'HLPre "High to Low"
	label var  `Label'HHPre "High to High"
}

* Table: Prom. (salary) / Pay Growth / Pay (CV) /   Perf. Appraisals (CV)
* Table: exit firm / change team / join team /  job change same m 
* Table: ShareSameG ShareSameAge ShareSameNationality ShareSameOffice

* Define variable globals 
global perf  ShareChangeSalaryGrade  AvPayGrowth CVPay  CVVPA  
global move  ShareLeaver ShareTeamLeavers ShareTeamJoiners  ShareTransferSJ  
global homo  ShareSameG  ShareSameAge  ShareSameOffice ShareSameCountry F1ShareConnected F1ShareConnectedL F1ShareConnectedV
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracCountry    
global out   SharePromWL AvPay AvProductivityStd SDProductivityStd ShareExitTeam ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat 
* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 
global charsExitFirm  LeaverPermFemale LeaverPermAge20 LeaverPermEcon LeaverPermSci LeaverPermHum  LeaverPermNewHire LeaverPermTenure5 LeaverPermEarlyAge LeaverPermPayGrowth1yAbove1 
global charsExitTeam ExitTeamFemale ExitTeamAge20 ExitTeamEcon ExitTeamSci ExitTeamHum  ExitTeamNewHire ExitTeamTenure5 ExitTeamEarlyAge ExitTeamPayGrowth1yAbove1 
global charsJoinTeam  ChangeMFemale ChangeMAge20 ChangeMEcon ChangeMSci ChangeMHum  ChangeMNewHire ChangeMTenure5 ChangeMEarlyAge ChangeMPayGrowth1yAbove1 
global charsChangeTeam F1ChangeMFemale F1ChangeMAge20 F1ChangeMEcon F1ChangeMSci F1ChangeMHum  F1ChangeMNewHire F1ChangeMTenure5 F1ChangeMEarlyAge F1ChangeMPayGrowth1yAbove1  

* TeamEthFrac
global controls  FuncM WLM AgeBandM CountryM Year
global cont SpanM c.TenureM##c.TenureM##i.FemaleM 

* generate categories 
local var FT // FT PromSG75
gen trans = 1 if `var'LHPost==1 
replace trans = 2 if `var'LLPost==1
replace trans = 3 if `var'HLPost==1
replace trans = 4 if `var'HHPost==1
label def trans 1 "Low to High" 2 "Low to Low" 3 "High to Low" 4 "High to High" 
label value trans trans 
bys team: egen JobChange1 = mean(cond(KEi >=0 & KEi <=12, ShareTransferSJ,.))
bys team: egen SGChange1 = mean(cond(KEi >=0 & KEi <=12, ShareChangeSalaryGrade,.))
bys team: egen Leavers = mean(cond(KEi >=0 & KEi <=12, ShareTeamLeavers,.))
bys team: egen Joiners = mean(cond(KEi >=0 & KEi <=12, ShareTeamJoiners,.))

*   ShareChangeSalaryGrade
gen AvPayGrowthP = AvPayGrowth*100

bys team: egen p = mean(IDlseMHRPreMost)
bys team: egen b = mean(IDlseMHRPost)
bys team: egen prewl = max(cond(KEi<0 &  p   == IDlseMHR ,WLM,.))
bys team: egen postwl = max(cond(KEi>=0 &  b  == IDlseMHR,WLM,.))
ge WL2 = prewl >1 & postwl>1

********************************************************************************
* LOW TO HIGH 
********************************************************************************

local Label FT // FT PromSG75
distinct team if KEi >=0 & KEi <=12 & trans ==1 & JobChange1>0 & WL2==1
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==2 & JobChange1>0 & WL2==1
local n2 =     r(ndistinct)

gen HighF1 = trans==1
gen HighF2 = trans ==3

/* trials
gen JobChange1B = JobChange1>0  
eststo clear 
eststo reg1: reg AvPayGrowthP  HighF1 if KEi >=0 & KEi <=24 & trans <3 & WL2 ==1
eststo reg2: reg AvPayGrowthP  HighF1 if KEi >=0 & KEi <=24 & trans <3 & WL2 ==1 & JobChange1>0
eststo reg3: reg AvPayGrowthP  HighF1 if KEi >=0 & KEi <=24 & trans <3 & WL2 ==1 & JobChange1<=0 

coefplot  (reg1, keep(HighF1) rename(  HighF1  = "All teams")  ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) )  (reg2, keep(HighF1) rename(HighF1 = "At least one job change in team" ) ciopts(lwidth(2 ..) lcolor(orange))  msymbol(d) mcolor(white)   ) (reg3, keep(HighF1) rename( HighF1 = "No job change in team" ) ciopts(lwidth(2 ..) lcolor(cranberry))  msymbol(d) mcolor(white)   ),  legend(off) title("Gaining a high-flyer manager")  level(90) xline(0, lpattern(dash))  note("Notes. An observation is a team-year-month. Reporting 90% confidence intervals." "Looking at outcomes within 24 months after the manager transition." , span)    ysize(6) xsize(8)    aspectratio(.5)

*xscale(range(-0.2 0.2)) xlabel(-0.2(0.05)0.2)
*/

cibar AvPayGrowthP if KEi >=0 & KEi <=12 & trans <3 & JobChange1>0 & WL2 ==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Pay Growth, at least one job change within the team") note("Notes. Average monthly pay growth within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the low to high group and `n2' teams in the low to low group.", size(medsmall)) ytitle("Percentage points") scheme(white_ptol) legend(rows(1) position(1))) 
graph export "$analysis/Results/8.Team/`Label'Pareto1LH.png", replace 
graph save "$analysis/Results/8.Team/`Label'Pareto1LH.gph", replace

distinct team if KEi >=0 & KEi <=12 & trans ==1 & JobChange1==0 & WL2==1 
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==2 & JobChange1==0 & WL2==1
local n2 =     r(ndistinct)
cibar AvPayGrowthP if  KEi >=0 & KEi <=12 & trans <3 & JobChange1==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Pay Growth, no job change within the team")  note("Notes. Average monthly pay growth within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the low to high group and `n2' teams in the low to low group.") ytitle("Percentage points", size(medsmall)) scheme(white_ptol) legend(rows(1)  position(1)))
graph export "$analysis/Results/8.Team/`Label'Pareto2LH.png", replace 
graph save "$analysis/Results/8.Team/`Label'Pareto2LH.gph", replace 

local Label FT // FT PromSG75
graph combine "$analysis/Results/8.Team/`Label'Pareto1LH.gph" "$analysis/Results/8.Team/`Label'Pareto2LH.gph", ycomm ysize(3)
graph export "$analysis/Results/8.Team/`Label'ParetoLH.png", replace 

distinct team if KEi >=0 & KEi <=12 & trans ==1 & JobChange1>0 & WL2==1 &  Leavers==0
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==2 & JobChange1>0 & WL2==1 &  Leavers==0
local n2 =     r(ndistinct)
cibar AvPayGrowthP if KEi >=0 & KEi <=12 & trans <3 & JobChange1>0  &  Leavers==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Pay Growth, at least one job change within the team" "Team composition constant") note("Notes. Average monthly pay growth within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the low to high group and `n2' teams in the low to low group.", size(medsmall)) ytitle("Percentage points") scheme(white_ptol) legend(rows(1)  position(1))) 
graph export "$analysis/Results/8.Team/`Label'Pareto1LHConstant.png", replace 
graph save "$analysis/Results/8.Team/`Label'Pareto1LHConstant.gph", replace

distinct team if KEi >=0 & KEi <=12 & trans ==1 & JobChange1==0 & WL2==1  &  Leavers==0
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==2 & JobChange1==0 & WL2==1 &  Leavers==0
local n2 =     r(ndistinct)
cibar AvPayGrowthP if  KEi >=0 & KEi <=12 & trans <3 & JobChange1==0 &  Leavers==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Pay Growth, no job change within the team" "Team composition constant")  note("Notes. Average monthly pay growth within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the low to high group and `n2' teams in the low to low group.", size(medsmall)) ytitle("Percentage points") scheme(white_ptol) legend(rows(1)  position(1)))
graph export "$analysis/Results/8.Team/`Label'Pareto2LHConstant.png", replace 
graph save "$analysis/Results/8.Team/`Label'Pareto2LHConstant.gph", replace 

local Label FT // FT PromSG75
graph combine  "$analysis/Results/8.Team/`Label'Pareto1LHConstant.gph" "$analysis/Results/8.Team/`Label'Pareto2LHConstant.gph", ycomm ysize(3)
graph export "$analysis/Results/8.Team/`Label'ParetoLHConstant.png", replace 

********************************************************************************
* HIGH TO LOW 
********************************************************************************

local Label FT // FT PromSG75
distinct team if KEi >=0 & KEi <=12 & trans ==3 & JobChange1>0 & WL2==1
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==4 & JobChange1>0 & WL2==1
local n2 =     r(ndistinct) 
cibar AvPayGrowthP if KEi >=0 & KEi <=12 & trans >=3 & trans<=4 & JobChange1>0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Pay Growth, at least one job change within the team") note("Notes. Average monthly pay growth within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue)  legend(rows(1) position(1))) 
graph export "$analysis/Results/8.Team/`Label'Pareto1HL.png", replace 
graph save "$analysis/Results/8.Team/`Label'Pareto1HL.gph", replace

distinct team if KEi >=0 & KEi <=12 & trans ==3 & JobChange1==0 & WL2==1
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==4 & JobChange1==0 & WL2==1
local n2 =     r(ndistinct)
cibar AvPayGrowthP if  KEi >=0 & KEi <=12 & trans >=3 & trans<=4 & JobChange1==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Pay Growth, no job change within the team")  note("Notes. Average monthly pay growth within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue) legend(rows(1)  position(1)))
graph export "$analysis/Results/8.Team/`Label'Pareto2HL.png", replace 
graph save "$analysis/Results/8.Team/`Label'Pareto2HL.gph", replace 

local Label FT // FT PromSG75
graph combine "$analysis/Results/8.Team/`Label'Pareto1HL.gph" "$analysis/Results/8.Team/`Label'Pareto2HL.gph", ycomm ysize(3)
graph export "$analysis/Results/8.Team/`Label'ParetoHL.png", replace 

distinct team if KEi >=0 & KEi <=12 & trans ==3 & JobChange1>0 & WL2==1  &  Leavers==0
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==4 & JobChange1>0 & WL2==1  &  Leavers==0
local n2 =     r(ndistinct) 
cibar AvPayGrowthP if KEi >=0 & KEi <=12 & trans >=3 & trans<=4 & JobChange1>0  &  Leavers==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Pay Growth, at least one job change within the team" "Team composition constant") note("Notes. Average monthly pay growth within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue) legend(rows(1)  position(1))) 
graph export "$analysis/Results/8.Team/`Label'Pareto1HLConstant.png", replace 
graph save "$analysis/Results/8.Team/`Label'Pareto1HLConstant.gph", replace

distinct team if KEi >=0 & KEi <=12 & trans ==3 & JobChange1==0 & WL2==1  &  Leavers==0
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==4 & JobChange1==0 & WL2==1  &  Leavers==0
local n2 =     r(ndistinct)
cibar AvPayGrowthP if  KEi >=0 & KEi <=12 & trans >=3 & trans<=4 & JobChange1==0 &  Leavers==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Pay Growth, no job change within the team" "Team composition constant")  note("Notes. Average monthly pay growth within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue) legend(rows(1)  position(1)))
graph export "$analysis/Results/8.Team/`Label'Pareto2HLConstant.png", replace 
graph save "$analysis/Results/8.Team/`Label'Pareto2HLConstant.gph", replace 

local Label FT // FT PromSG75
graph combine  "$analysis/Results/8.Team/`Label'Pareto1HLConstant.gph" "$analysis/Results/8.Team/`Label'Pareto2HLConstant.gph", ycomm ysize(3)
graph export "$analysis/Results/8.Team/`Label'ParetoHLConstant.png", replace 


/* COEFF VAR IN PAY 
********************************************************************************
* LOW TO HIGH 
********************************************************************************

local Label FT // FT PromSG75
distinct team if KEi >=0 & KEi <=12 & trans ==1 & JobChange1>0 & WL2==1
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==2 & JobChange1>0 & WL2==1
local n2 =     r(ndistinct)
cibar CVPay if KEi >=0 & KEi <=12 & trans <3 & JobChange1>0 & WL2 ==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay, at least one job change within the team") note("Notes. Average monthly coeff. var in pay within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the low to high group and `n2' teams in the low to low group.", size(medsmall)) ytitle("Percentage points") scheme(white_ptol) legend(rows(1) position(1))) 
graph export "$analysis/Results/8.Team/`Label'ParetoCV1LH.png", replace 
graph save "$analysis/Results/8.Team/`Label'ParetoCV1LH.gph", replace

distinct team if KEi >=0 & KEi <=12 & trans ==1 & JobChange1==0 & WL2==1
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==2 & JobChange1==0 & WL2==1
local n2 =     r(ndistinct)
cibar CVPay if  KEi >=0 & KEi <=12 & trans <3 & JobChange1==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay, no job change within the team")  note("Notes. Average monthly coeff. var in pay within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the low to high group and `n2' teams in the low to low group.") ytitle("Percentage points", size(medsmall)) scheme(white_ptol) legend(rows(1)  position(1)))
graph export "$analysis/Results/8.Team/`Label'ParetoCV2LH.png", replace 
graph save "$analysis/Results/8.Team/`Label'ParetoCV2LH.gph", replace 

local Label FT // FT PromSG75
graph combine "$analysis/Results/8.Team/`Label'ParetoCV1LH.gph" "$analysis/Results/8.Team/`Label'ParetoCV2LH.gph", ycomm ysize(3)
graph export "$analysis/Results/8.Team/`Label'ParetoCVLH.png", replace 

distinct team if KEi >=0 & KEi <=12 & trans ==1 & JobChange1>0 & WL2==1 &  Leavers==0
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==2 & JobChange1>0 & WL2==1 &  Leavers==0
local n2 =     r(ndistinct)
cibar CVPay if KEi >=0 & KEi <=12 & trans <3 & JobChange1>0  &  Leavers==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay, at least one job change within the team" "Team composition constant") note("Notes. Average monthly coeff. var in pay within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the low to high group and `n2' teams in the low to low group.", size(medsmall)) ytitle("Percentage points") scheme(white_ptol) legend(rows(1)  position(1))) 
graph export "$analysis/Results/8.Team/`Label'ParetoCV1LHConstant.png", replace 
graph save "$analysis/Results/8.Team/`Label'ParetoCV1LHConstant.gph", replace

distinct team if KEi >=0 & KEi <=12 & trans ==1 & JobChange1==0 & WL2==1  &  Leavers==0
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==2 & JobChange1==0 & WL2==1 &  Leavers==0
local n2 =     r(ndistinct)
cibar CVPay if  KEi >=0 & KEi <=12 & trans <3 & JobChange1==0 &  Leavers==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay, no job change within the team" "Team composition constant")  note("Notes. Average monthly coeff. var in pay within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the low to high group and `n2' teams in the low to low group.", size(medsmall)) ytitle("Percentage points") scheme(white_ptol) legend(rows(1)  position(1)))
graph export "$analysis/Results/8.Team/`Label'ParetoCV2LHConstant.png", replace 
graph save "$analysis/Results/8.Team/`Label'ParetoCV2LHConstant.gph", replace 

local Label FT // FT PromSG75
graph combine  "$analysis/Results/8.Team/`Label'ParetoCV1LHConstant.gph" "$analysis/Results/8.Team/`Label'ParetoCV2LHConstant.gph", ycomm ysize(3)
graph export "$analysis/Results/8.Team/`Label'ParetoCVLHConstant.png", replace 

********************************************************************************
* HIGH TO LOW 
********************************************************************************

local Label FT // FT PromSG75
distinct team if KEi >=0 & KEi <=12 & trans ==3 & JobChange1>0 & WL2==1
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==4 & JobChange1>0 & WL2==1
local n2 =     r(ndistinct) 
cibar CVPay if KEi >=0 & KEi <=12 & trans >=3 & trans<=4 & JobChange1>0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay, at least one job change within the team") note("Notes. Average monthly coeff. var in pay within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue)  legend(rows(1) position(1))) 
graph export "$analysis/Results/8.Team/`Label'ParetoCV1HL.png", replace 
graph save "$analysis/Results/8.Team/`Label'ParetoCV1HL.gph", replace

distinct team if KEi >=0 & KEi <=12 & trans ==3 & JobChange1==0 & WL2==1
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==4 & JobChange1==0 & WL2==1
local n2 =     r(ndistinct)
cibar CVPay if  KEi >=0 & KEi <=12 & trans >=3 & trans<=4 & JobChange1==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay, no job change within the team")  note("Notes. Average monthly coeff. var in pay within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals""`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue) legend(rows(1)  position(1)))
graph export "$analysis/Results/8.Team/`Label'ParetoCV2HL.png", replace 
graph save "$analysis/Results/8.Team/`Label'ParetoCV2HL.gph", replace 

local Label FT // FT PromSG75
graph combine "$analysis/Results/8.Team/`Label'ParetoCV1HL.gph" "$analysis/Results/8.Team/`Label'ParetoCV2HL.gph", ycomm ysize(3)
graph export "$analysis/Results/8.Team/`Label'ParetoCVHL.png", replace 

distinct team if KEi >=0 & KEi <=12 & trans ==3 & JobChange1>0 & WL2==1  &  Leavers==0
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==4 & JobChange1>0 & WL2==1  &  Leavers==0
local n2 =     r(ndistinct) 
cibar CVPay if KEi >=0 & KEi <=12 & trans >=3 & trans<=4  &  Leavers==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("Coeff. Var Pay, at least one job change within the team" "Team composition constant") note("Notes. Average monthly coeff. var in pay within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue) legend(rows(1)  position(1))) 
graph export "$analysis/Results/8.Team/`Label'ParetoCV1HLConstant.png", replace 
graph save "$analysis/Results/8.Team/`Label'ParetoCV1HLConstant.gph", replace

distinct team if KEi >=0 & KEi <=12 & trans ==3 & JobChange1==0 & WL2==1  &  Leavers==0
local n1 =     r(ndistinct) 
distinct team if KEi >=0 & KEi <=12 & trans ==4 & JobChange1==0 & WL2==1  &  Leavers==0
local n2 =     r(ndistinct)
cibar CVPay if  KEi >=0 & KEi <=12 & trans >=3 & trans<=4 & JobChange1==0 &  Leavers==0 & WL2==1, level(90) over(trans)  vce( cluster IDlseMHR) graphopts(title("coeff. var in pay, no job change within the team" "Team composition constant")  note("Notes. Average monthly coeff. var in pay within 1 year of the manager transition." "Standard errors clustered at the manager level. 90% confidence intervals" "`n1' teams in the high to low group and `n2' teams in the high to high group.", size(medsmall)) ytitle("Percentage points") scheme(white_hue) legend(rows(1)  position(1)))
graph export "$analysis/Results/8.Team/`Label'ParetoCV2HLConstant.png", replace 
graph save "$analysis/Results/8.Team/`Label'ParetoCV2HLConstant.gph", replace 

local Label FT // FT PromSG75
graph combine  "$analysis/Results/8.Team/`Label'ParetoCV1HLConstant.gph" "$analysis/Results/8.Team/`Label'ParetoCV2HLConstant.gph", ycomm ysize(3)
graph export "$analysis/Results/8.Team/`Label'ParetoCVHLConstant.png", replace 

