
* choose the manager type !MANUAL INPUT!
global Label FT // odd FT PromSG75
global MType  EarlyAgeM  // odd EarlyAgeM MFEBayesPromSG75

do "$analysis/DoFiles/4.Event/_CoeffProgram.do"

use "$managersdta/SwitchersAllSameTeam2.dta", clear 

* odd or even Manager id for placebo events 
*gen odd = mod(IDlseMHR,2) 
gen odd = mod(ManagerNum,2) 

* Delta 
xtset IDlse YearMonth 
foreach var in odd EarlyAgeM MFEBayesPromSG75{
	cap drop diffM Deltatag
	gen diffM = d.`var' // can be replaced with F1ChangeSalaryGradeMixed F1PromWLMixed MFEBayesPromSG MFEBayesPromWL MFEBayesPromSG MFEBayesPromSG75 	MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 MFEBayesPromSG75v2015 MFEBayesPromWL75v2015 MFEBayesPromSG50v2015 MFEBayesPromWL50v2015  EarlyAgeM LineManagerMeanB; for placebo use manager ID odd or even? 
	gen Deltatag = diffM if YearMonth == Ei
	bys IDlse: egen DeltaM`var' = mean(Deltatag) 
}

* BALANCED SAMPLE FOR OUTCOMES 30 WINDOW
* window lenght
local end = 30 // to be plugged in 
local window = 61 // to be plugged in
bys IDlse: egen minEi = min(KEi) 
bys IDlse: egen maxEi = max(KEi)
gen ii = minEi <=-(`end') &  maxEi >=(`end') & Ei!=.
ta ii
*keep if ii==1 // MANUAL INPUT - to remove if irrelevant

* only keep relevant switchers 
keep if DeltaM$MType!=. 

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
}
* create leads and lags 
foreach var in Ei {

gen `var'Post = K`var'>=0 & K`var' !=.
gen `var'PostDelta = `var'Post*DeltaM$MType
}

gen TenureM2 = TenureM*TenureM
gen Post = KEi >=0 if KEi!=.

merge 1:1 IDlse YearMonth using "$fulldta/ActiveLearn.dta", keepusing(NumRecommend NumRecommendB NumRecommendYTD NumRecommendYTDF NumRecommendYTDB NumCompleted NumCompletedB NumCompletedYTD NumCompletedYTDF NumCompletedYTDB NumSkills NumSkillsF NumSkillsB ActiveLearner ActiveLearnerYTD ActiveLearnerC)

keep if _merge ==3
drop _merge 

save "$managersdta/TempNew/temp_ActiveLearn.dta", replace 


use "$managersdta/TempNew/temp_ActiveLearn.dta", clear 
eststo clear 
foreach var in  ActiveLearnerYTD   NumCompletedYTDB  NumRecommendYTDB NumSkillsB {
eststo `var':reghdfe `var'  EarlyAgeM  if Post==1 , cluster(IDlseMHR) a( Year )	// WL2 takes away 2/3 of sample 
}

* baseline mean: 
su ActiveLearnerYTD   NumCompletedYTDB  NumRecommendYTDB NumSkillsB if Post==1  & EarlyAgeM ==0

label var ActiveLearnerYTD "Meeting all conditions: active learner"
label var NumRecommendYTDB "Shared items with colleagues>0"
label var  NumCompletedYTDB "Completed items>=5"
label var NumSkillsB  "Number of skills>=3"

/*
coefplot    NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD , ///
title("", pos(12) span si(large)) xline(0, lpattern(dash)) keep(EarlyAgeM)  levels(90) ///
ciopts(lwidth(2 ..) lcolor(ebblue))  msymbol(d) mcolor(white) ///
swapnames aseq ///
scale(1) legend(off) ///
 aspect(0.4) coeflabels(, ) ysize(5) xsize(8)  ytick(,grid glcolor(black)) 
graph export  "$analysis/Results/5.Mechanisms/FTActiveLearnA.png", replace
*/

esttab NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD

esttab NumSkillsB NumCompletedYTDB  NumRecommendYTDB ActiveLearnerYTD using "${results}/0.New/FTActiveLearn.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    keep(EarlyAgeM) varlabels(EarlyAgeM "High-flyer manager ") ///
    stats(cmean N, labels("Mean, low-flyer" "N" "R-squared") fmt(%9.3f %9.0f)) ///
    prehead("\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{\shortstack{Number of \\ skills $\geq$ 3}} & \multicolumn{1}{c}{\shortstack{Completed \\ items $\geq$ 5}}  & \multicolumn{1}{c}{\shortstack{Shared items with \\ colleagues>0}} & \multicolumn{1}{c}{\shortstack{Meeting all conditions: \\ active learner}}  \\") ///
    prefoot("\hline")  ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. Data from the internal talent matching platform." "\end{tablenotes}")


