********************************************************************************
* This dofile conducts heterogeneity analysis by diversity in the team 
* -  symmetric case first
* - asymmetric case second 
********************************************************************************

* symmetric case 
********************************************************************************

use "$managersdta/Teams.dta" , clear 

keep if Year>2013 // post sample only 

bys team: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys team: egen minK = min(KEi)
bys team: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

foreach var in FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015{
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
egen `var'Event = rowmax( `var'LHPost `var'LLPost `var'HLPost `var'HHPost ) 
gen `var'DEvent = `var'Event*Delta`var'
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
label var `var'Event "Event"
label var `var'DEvent "Event*Delta M. Talent"
label var Delta`var' "Delta M. Talent"
} 

foreach Label in FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015{
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
global homo  ShareSameG  ShareSameAge  ShareSameOffice ShareSameCountry F1ShareConnected
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracCountry    
global out  SpanM SharePromWL AvPay AvProductivityStd SDProductivityStd ShareExitTeam ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat
* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 
* TeamEthFrac

global charsExitFirm  LeaverPermFemale LeaverPermAge20  LeaverPermEcon LeaverPermSci LeaverPermHum  LeaverPermNewHire LeaverPermTenure5 LeaverPermEarlyAge LeaverPermPayGrowth1yAbove1
global charsExitTeam ExitTeamFemale ExitTeamAge20  ExitTeamEcon ExitTeamSci ExitTeamHum  ExitTeamNewHire ExitTeamTenure5 ExitTeamEarlyAge ExitTeamPayGrowth1yAbove1
global charsJoinTeam  ChangeMFemale ChangeMAge20  ChangeMEcon ChangeMSci ChangeMHum  ChangeMNewHire ChangeMTenure5 ChangeMEarlyAge ChangeMPayGrowth1yAbove1
global charsChangeTeam F1ChangeMFemale F1ChangeMAge20  F1ChangeMEcon F1ChangeMSci F1ChangeMHum  F1ChangeMNewHire F1ChangeMTenure5 F1ChangeMEarlyAge F1ChangeMPayGrowth1yAbove1 

global controls  FuncM WLM AgeBandM CountryM Year
global cont SpanM c.TenureM##c.TenureM##i.FemaleM 

* Heterogeneity by team diversity at baseline 
foreach var in TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracCountry  {
	bys team: egen `var'0 = mean(cond(KEi == -1,`var',.))
	su `var'0 , d
	gen `var'0B = `var'0 > r(p50) if `var'0!=. 
}

* gender balance 
foreach var in ShareFemale {
	bys team: egen `var'0 = mean(cond(KEi == -1,`var',.)) // variable at baseline 
	gen `var'0B =1 if `var'0 >0.4 & `var'0 <0.6 // diversity threshold btw 40% and 60%
	replace `var'0B = 0 if `var'0!=. & `var'0B!=1
	gen `var'0B2 =1 if `var'0 >0.3 & `var'0 <0.7 // diversity threshold btw 30% and 70%
	replace `var'0B2 = 0 if `var'0!=. & `var'0B2!=1
}

* gender of manager 
foreach var in FemaleM {
	bys team: egen `var'0 = mean(cond(KEi == 0,`var',.)) // variable at baseline 
}

********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE - GENDER QUOTAS 
* Are effects stronger where share female is nearer 0.5, (0.4,0.6) 
* Given there is a policy inside the firm of quotas, doing everything equally for female and male
* focus is on gender, not really on age/office/country (yet)
********************************************************************************

eststo clear

local i = 1
local Label PromSG75 // FT 
foreach y in  $perf $move  $homo $div  {  

eststo reg`i'FE1:	reghdfe `y' `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if ShareFemale0B == 0 & SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)
local lbl : variable label `y'

eststo reg`i'FE2:	reghdfe `y' `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if ShareFemale0B == 1 & SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

coefplot reg`i'FE1 reg`i'FE2  , levels(90) ///
keep(*DEvent) vertical recast(bar )  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq title("`:variable label `y''", pos(12) span si(vlarge)) ///
coeflabels(  reg`i'FE1 = "{bf:Gender Unbalanced}"  reg`i'FE2 = "{bf:Gender Balanced}" ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span)  
graph export  "$analysis/Results/8.Team/`Label'`y'HetDivSym.png", replace

local i = `i' +1

}

* balance table of gender balanced teams before the manager comes in 
local Label PromSG75 // FT
label var SpanM "Team Size"
balancetable ShareFemale0B SpanM $perf $move   $div if KEi <0& KEi>=-36 & SpanM!=1  & Year>2013 using "$analysis/Results/8.Team/`Label'GenderBalance.tex" , varlabels pval vce(cluster IDlseMHR) ctitles("Unbalanced" "Balanced" "Difference") postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. An observation is a team-month. Only considering the 36 months before the manager change. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered at the manager level. Team is gender balanced if the female share is between 0.4 and 0.6." "\end{tablenotes}") replace 

********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE - GENDER OF MANAGER 
* Are effects different by the gender of the manager?
********************************************************************************

eststo clear

local i = 1
local Label PromSG75 // FT
foreach y in  $perf $move  $homo $div  {

eststo reg`i'FE1:	reghdfe `y' `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if FemaleM0 == 0 & SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)
local lbl : variable label `y'

eststo reg`i'FE2:	reghdfe `y' `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if FemaleM0 == 1 & SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

coefplot reg`i'FE1 reg`i'FE2  , levels(90) ///
keep(*DEvent) vertical recast(bar )  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq title("`:variable label `y''", pos(12) span si(vlarge)) ///
coeflabels(  reg`i'FE1 = "{bf:Male Manager}"  reg`i'FE2 = "{bf:Female Manager}" ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span)  
graph export  "$analysis/Results/8.Team/`Label'`y'HetFemaleMSym.png", replace

local i = `i' +1

}

* balance table of gender balanced teams before the manager comes in 
local Label PromSG75 // FT
label var SpanM "Team Size"
balancetable FemaleM0 SpanM $perf $move   $div if KEi <0& KEi>=-36 & SpanM!=1  & Year>2013 using "$analysis/Results/8.Team/`Label'FemaleM0Balance.tex" , varlabels pval vce(cluster IDlseMHR) ctitles("Male Manager" "Female Manager" "Difference") postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
"Notes. An observation is a team-month. Only considering the 36 months before the manager change. Showing mean and standard deviations (in parentheses) and p-values for the difference in means." ///
"The difference in means is computed using standard errors clustered at the manager level." "\end{tablenotes}") replace 

********************************************************************************
* Heterogeneity analysis by diversity in the team -  ASYMMETRIC CASE 
********************************************************************************

use "$managersdta/Teams.dta" , clear 

keep if Year>2013 // post sample only 

bys team: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys team: egen minK = min(KEi)
bys team: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

foreach var in FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015{
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
} 

foreach Label in FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015{
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
global homo  ShareSameG  ShareSameAge  ShareSameOffice ShareSameCountry F1ShareConnected
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracCountry    
global out   SharePromWL AvPay AvProductivityStd SDProductivityStd ShareExitTeam ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat 
* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 

* TeamEthFrac
global controls  FuncM WLM AgeBandM CountryM Year
global cont SpanM c.TenureM##c.TenureM##i.FemaleM 

* Heterogeneity by team diversity at baseline 
foreach var in TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracCountry  {
	bys IDlseMHR: egen `var'0 = mean(cond(KEi == -1,`var',.))
	su `var'0 , d
	gen `var'0B = `var'0 > r(p50) if `var'0!=. 
}

foreach var in ShareFemale {
	bys IDlseMHR: egen `var'0 = mean(cond(KEi == -1,`var',.)) // variable at baseline 
	gen `var'0B =1 if `var'0 >0.4 & `var'0 <0.6 // diversity threshold btw 40% and 60%
	replace `var'0B = 0 if `var'0!=. & `var'0B!=1
	gen `var'0B2 =1 if `var'0 >0.3 & `var'0 <0.7 // diversity threshold btw 30% and 70%
	replace `var'0B2 = 0 if `var'0!=. & `var'0B2!=1
}

pwcorr ShareFemale0B TeamFracGender0B // 70% correlation 

********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE - GENDER QUOTAS 
* Are effects stronger where share female is nearer 0.5, (0.4,0.6) 
* Given there is a policy inside the firm of quotas, doing everything equally for female and male
* focus is on gender, not really on age/office/country (yet)
********************************************************************************

eststo clear
sort IDlseMHR YearMonth
local i = 1

local Label PromSG75 // FT
foreach y in  $perf $move  $homo $div  {

/*mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
*/

eststo reg`i'FE1:	reghdfe `y' $`Label'  c.TenureM##c.TenureM##i.FemaleM if ShareFemale0B == 0 & SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)
local lbl : variable label `y'

lincom  `Label'LHPost - `Label'LLPost, level(90)
gen `y'LHLowdiff = r(estimate) in 1
gen `y'LHLowlb = r(lb) in 1
gen `y'LHLowub = r(ub) in 1

lincom  `Label'HLPost - `Label'HHPost, level(90)
gen `y'HLLowdiff = r(estimate) in 3
gen `y'HLLowlb = r(lb) in 3
gen `y'HLLowub = r(ub) in 3

eststo reg`i'FE2:	reghdfe `y' $`Label'  c.TenureM##c.TenureM##i.FemaleM if ShareFemale0B == 1 & SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

lincom  `Label'LHPost - `Label'LLPost, level(90)
gen `y'LHHighdiff = r(estimate) in 2
gen `y'LHHighlb = r(lb) in 2
gen `y'LHHighub = r(ub) in 2

lincom  `Label'HLPost - `Label'HHPost, level(90)
gen `y'HLHighdiff = r(estimate) in 4
gen `y'HLHighlb = r(lb) in 4
gen `y'HLHighub = r(ub) in 4


local i = `i' +1

}

* coefplot 
********************************************************************************

sort IDlseMHR YearMonth
global Label PromSG75  // FT 

gen post = 1 in 1
replace post = 2 in 2
replace post = 3 in 3
replace post = 4 in 4

cap label drop post   
label define  post 1 "Low to High - Unbal."  2  "Low to High - Bal."  3 "High to Low - Unbal." 4 "High to Low - Bal."
label value  post post

foreach var in   $perf $move  $homo $div   {
	
ge `var'coeff = .
replace `var'coeff = `var'LHLowdiff in 1
replace `var'coeff =  `var'LHHighdiff  in 2
replace `var'coeff = `var'HLLowdiff in 3
replace `var'coeff =  `var'HLHighdiff  in 4

ge `var'lb = `var'LHLowlb  in 1 
replace  `var'lb= `var'LHHighlb  in 2 
replace  `var'lb= `var'HLLowlb  in 3 
replace  `var'lb= `var'HLHighlb  in 4

ge `var'ub = `var'LHLowub  in 1 
replace `var'ub= `var'LHHighub  in 2 
replace `var'ub= `var'HLLowub  in 3 
replace `var'ub= `var'HLHighub  in 4


local lab: variable label `var'
graph twoway (bar `var'coeff post if post==1 |  post==2) (bar `var'coeff post if post==3 |  post==4) (rcap `var'lb `var'ub post), xlabel(1 "Low to High - Unbal." 2 "Low to High - Bal." 3  "High to Low - Unbal." 4 "High to Low - Bal." ) xtitle("") legend(off) title("`lab'") note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.")
graph export "$analysis/Results/8.Team/Div`var'$Label.png", replace 
graph save "$analysis/Results/8.Team/Div`var'$Label.gph", replace 

}

********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE - gender diversity - ASYMMETRIC CASE 
********************************************************************************

eststo clear
sort IDlseMHR YearMonth
local i = 1

local Label PromSG75  // FT 
foreach y in  $perf $move  $homo $div  {

/*mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
*/

eststo reg`i'FE1:	reghdfe `y' $`Label'  c.TenureM##c.TenureM##i.FemaleM if ShareFemale0B == 0 & SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)
local lbl : variable label `y'

lincom  `Label'LHPost - `Label'LLPost, level(90)
gen `y'LHLowdiff = r(estimate) in 1
gen `y'LHLowlb = r(lb) in 1
gen `y'LHLowub = r(ub) in 1

lincom  `Label'HLPost - `Label'HHPost, level(90)
gen `y'HLLowdiff = r(estimate) in 3
gen `y'HLLowlb = r(lb) in 3
gen `y'HLLowub = r(ub) in 3

eststo reg`i'FE2:	reghdfe `y' $`Label'  c.TenureM##c.TenureM##i.FemaleM if ShareFemale0B == 1 & SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

lincom  `Label'LHPost - `Label'LLPost, level(90)
gen `y'LHHighdiff = r(estimate) in 2
gen `y'LHHighlb = r(lb) in 2
gen `y'LHHighub = r(ub) in 2

lincom  `Label'HLPost - `Label'HHPost, level(90)
gen `y'HLHighdiff = r(estimate) in 4
gen `y'HLHighlb = r(lb) in 4
gen `y'HLHighub = r(ub) in 4


local i = `i' +1

}

* coefplot 
********************************************************************************

sort IDlseMHR YearMonth
global Label PromSG75 // FT 

gen post = 1 in 1
replace post = 2 in 2
replace post = 3 in 3
replace post = 4 in 4

cap label drop post   
label define  post 1 "Low to High - Low Diversity"  2  "Low to High - High Diversity"  3 "High to Low - Low Diversity" 4 "High to Low - High Diversity"
label value  post post

foreach var in   $perf $move  $homo $div   {
	
ge `var'coeff = .
replace `var'coeff = `var'LHLowdiff in 1
replace `var'coeff =  `var'LHHighdiff  in 2
replace `var'coeff = `var'HLLowdiff in 3
replace `var'coeff =  `var'HLHighdiff  in 4

ge `var'lb = `var'LHLowlb  in 1 
replace  `var'lb= `var'LHHighlb  in 2 
replace  `var'lb= `var'HLLowlb  in 3 
replace  `var'lb= `var'HLHighlb  in 4

ge `var'ub = `var'LHLowub  in 1 
replace `var'ub= `var'LHHighub  in 2 
replace `var'ub= `var'HLLowub  in 3 
replace `var'ub= `var'HLHighub  in 4


local lab: variable label `var'
graph twoway (bar `var'coeff post if post==1 |  post==2) (bar `var'coeff post if post==3 |  post==4) (rcap `var'lb `var'ub post), xlabel(1 "Low to High - Low Div." 2 "Low to High - High Div." 3  "High to Low - Low Div." 4 "High to Low - High Div." ) xtitle("") legend(off) title("`lab'") note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.")
graph export "$analysis/Results/8.Team/Div`var'$Label.png", replace 
graph save "$analysis/Results/8.Team/Div`var'$Label.gph", replace 

}
