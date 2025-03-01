/* 
This do file shows the evolution of the task intensity of event workers over time.

RA: WWZ 
Time: 2025-02-17
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
    //&? 67 unique ONET occupation codes in all periods

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
*-? s-2-1. at the event time 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if Year==0, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity at the event time", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Cognitive0.png", replace as(png)

cdfplot prank_routine if Year==0, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity at the event time", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Routine0.png", replace as(png)

cdfplot prank_social if Year==0, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity at the event time", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Social0.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. 1 year later
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if Year==1, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity 1 year after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Cognitive1.png", replace as(png)

cdfplot prank_routine if Year==1, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity 1 year after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Routine1.png", replace as(png)

cdfplot prank_social if Year==1, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity 1 year after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Social1.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. 2 year later
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if Year==2, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity 2 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Cognitive2.png", replace as(png)

cdfplot prank_routine if Year==2, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity 2 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Routine2.png", replace as(png)

cdfplot prank_social if Year==2, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity 2 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Social2.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. 3 year later
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if Year==3, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity 3 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Cognitive3.png", replace as(png)

cdfplot prank_routine if Year==3, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity 3 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Routine3.png", replace as(png)

cdfplot prank_social if Year==3, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity 3 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Social3.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. 4 year later
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if Year==4, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity 4 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Cognitive4.png", replace as(png)

cdfplot prank_routine if Year==4, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity 4 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Routine4.png", replace as(png)

cdfplot prank_social if Year==4, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity 4 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Social4.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-6. 5 year later
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if Year==5, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity 5 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Cognitive5.png", replace as(png)

cdfplot prank_routine if Year==5, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity 5 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Routine5.png", replace as(png)

cdfplot prank_social if Year==5, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity 5 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Social5.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-7. 6 year later
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if Year==6, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity 6 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Cognitive6.png", replace as(png)

cdfplot prank_routine if Year==6, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity 6 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Routine6.png", replace as(png)

cdfplot prank_social if Year==6, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity 6 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Social6.png", replace as(png)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-8. 7 year later
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

cdfplot prank_cognitive if Year==7, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Cognitive task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of cognitive task intensity 7 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Cognitive7.png", replace as(png)

cdfplot prank_routine if Year==7, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Routine task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of routine task intensity 7 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Routine7.png", replace as(png)

cdfplot prank_social if Year==7, by(FT_LtoL)  scheme(white_tableau) ///
    legend(label(1 "LtoH") label(2 "LtoL") position(6) ring(1) rows(1)) ///
    xtitle("Social task intensity (percentile rank)", size(medlarge)) xlabel(0(0.1)1, grid gstyle(dot)) /// 
    ytitle("Cumulative probability", size(medlarge)) ylabel(0(0.1)1, grid gstyle(dot)) /// 
    title("Distribution of social task intensity 7 years after the event", size(medlarge))
graph export "${Results}/ONET_LtoLvsLtoH_Social7.png", replace as(png)


