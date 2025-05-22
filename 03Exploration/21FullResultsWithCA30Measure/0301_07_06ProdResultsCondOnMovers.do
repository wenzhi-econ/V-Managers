/* 
This do file runs correlational regressions on productivity outcomes conditional on lateral and vertical movers.

Input: 
    "${TempData}/FinalAnalysisSample.dta"   <== created in 0103_03 do file
    "${TempData}/0105SalesProdOutcomes.dta" <== created in 0105 do file 

RA: WWZ 
Time: 2025-05-12
*/


use "${TempData}/FinalAnalysisSample.dta", clear

merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge

keep if CA30_LtoL==1 | CA30_LtoH==1

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. do lateral movers gain more  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*!! movers within 2 years after the event 
sort IDlse YearMonth
bysort IDlse: egen Movers_2yrs = max(cond(inrange(Rel_Time, 0, 24), TransferSJ, .))

reghdfe LogPayBonus CA30_LtoH if Movers_2yrs==1 & Post_Event==1, absorb(YearMonth Office#Func Female#AgeBand) cluster(IDlseMHR)
    eststo LateralMovers 
    summarize LogPayBonus if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. do LtoH workers have better outcomes after promotion  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

reghdfe LogPayBonus CA30_LtoH if Post_Event==1 & WL==2, absorb(YearMonth Office#Func Female#AgeBand) cluster(IDlseMHR)
    eststo VerticalMovers 
    summarize LogPayBonus if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)

merge m:1 IDlse YearMonth using "${TempData}/0403EffectiveLeaderScores.dta"
keep if _merge==3
drop _merge
    //&? keep only those employees with a score on his manager survey 
    //&? notice that the manager score is only used in regressions conditional on promotion to WL2

rename LineManager MScore
generate MScoreB = (MScore>4) if MScore!=.
sort IDlse YearMonth

reghdfe MScore CA30_LtoH if WL==2 & Post_Event==1, absorb(YearMonth Office#Func Female#AgeBand) cluster(IDlseMHR)
    eststo MScore_Gain
    summarize MScore if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)
	
reghdfe MScoreB CA30_LtoH if WL==2 & Post_Event==1, absorb(YearMonth Office#Func Female#AgeBand) cluster(IDlseMHR)
    eststo MScoreB_Gain
    summarize MScoreB if e(sample)==1 & CA30_LtoL==1
    estadd scalar cmean = r(mean)



