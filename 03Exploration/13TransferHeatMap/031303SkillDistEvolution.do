/* 
This do file shows the evolution of the task intensity of event workers over time.

RA: WWZ 
Time: 2025-02-12
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of event workers: task info
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep a panel of relevant workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
keep if FT_LtoH==1 | FT_LtoL==1
    //&? a panel of LtoL and LtoH event workers 
    //&? 25,001 unique workers

keep IDlse YearMonth FT_Rel_Time FT_Event_Time FT_LtoL FT_LtoH Func StandardJob

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. obtain ONET task intensity measures 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 StandardJob using "${TempData}/temp_ONET_FinalJobLevelPrank.dta"
    //&? constructed in 030709_02 do file 
    keep if _merge==3
    drop _merge 
/* 
    Result                      Number of obs
    -----------------------------------------
    Not matched                       139,475
        from master                   138,700  (_merge==1)
        from using                        775  (_merge==2)

    Matched                         1,517,845  (_merge==3)
    -----------------------------------------
*/

codebook ONETSOCCode
    //&? 48 unique ONET occupation codes in all periods

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. 1-7 years after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate FT_1yrLater = FT_Event_Time + 12
generate FT_2yrLater = FT_Event_Time + 24
generate FT_3yrLater = FT_Event_Time + 36
generate FT_4yrLater = FT_Event_Time + 48
generate FT_5yrLater = FT_Event_Time + 60
generate FT_6yrLater = FT_Event_Time + 72
generate FT_7yrLater = FT_Event_Time + 84

format   FT_1yrLater %tm 
format   FT_2yrLater %tm 
format   FT_3yrLater %tm 
format   FT_4yrLater %tm 
format   FT_5yrLater %tm 
format   FT_6yrLater %tm 
format   FT_7yrLater %tm 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. task information at different times 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

foreach var in cognitive routine social {
    bysort IDlse: egen prank_`var'0 = mean(cond(YearMonth==FT_Event_Time, prank_`var', .))
    bysort IDlse: egen prank_`var'1 = mean(cond(YearMonth==FT_1yrLater,   prank_`var', .))
    bysort IDlse: egen prank_`var'2 = mean(cond(YearMonth==FT_2yrLater,   prank_`var', .))
    bysort IDlse: egen prank_`var'3 = mean(cond(YearMonth==FT_3yrLater,   prank_`var', .))
    bysort IDlse: egen prank_`var'4 = mean(cond(YearMonth==FT_4yrLater,   prank_`var', .))
    bysort IDlse: egen prank_`var'5 = mean(cond(YearMonth==FT_5yrLater,   prank_`var', .))
    bysort IDlse: egen prank_`var'6 = mean(cond(YearMonth==FT_6yrLater,   prank_`var', .))
    bysort IDlse: egen prank_`var'7 = mean(cond(YearMonth==FT_7yrLater,   prank_`var', .))
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. keep a cross section of relevant event workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time==0
    //&? keep a cross-section of relevant event workers 
    //&? 19,580 unique workers 
keep if prank_cognitive0!=.

codebook prank_cognitive0
    //&? 49 unique values 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-6. reshape long so that cdfplot command can be used
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep IDlse FT_LtoL FT_LtoH prank_cognitive0 - prank_social7

reshape long prank_cognitive prank_routine prank_social, i(IDlse) j(Year)

save "${TempData}/temp_ONET_TaskIntensityEvolution.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. plot the evolution of cdf over time 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_ONET_TaskIntensityEvolution.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. all workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity over time, LtoL + LtoH", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Cognitive_All.png", replace as(png)

cdfplot prank_routine, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity over time, LtoL + LtoH", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Routine_All.png", replace as(png)

cdfplot prank_social, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity over time, LtoL + LtoH", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Social_All.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. LtoL workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if FT_LtoL==1, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity over time, LtoL", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Cognitive_LtoL.png", replace as(png)

cdfplot prank_routine if FT_LtoL==1, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity over time, LtoL", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Routine_LtoL.png", replace as(png)

cdfplot prank_social if FT_LtoL==1, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity over time, LtoL", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Social_LtoL.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. LtoH workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if FT_LtoH==1, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity over time, LtoH", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Cognitive_LtoH.png", replace as(png)

cdfplot prank_routine if FT_LtoH==1, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity over time, LtoH", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Routine_LtoH.png", replace as(png)

cdfplot prank_social if FT_LtoH==1, by(Year) scheme(white_tableau) ///
    legend(label(1 "At the event") label(2 "1 year later") label(3 "2 year later") label(4 "3 year later") label(5 "4 year later") label(6 "5 year later") label(7 "6 year later") label(8 "7 year later") position(6) ring(1) rows(2)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity over time, LtoH", size(medlarge))
graph export "${Results}/ONET_EvolutionOverTime_Social_LtoH.png", replace as(png)








