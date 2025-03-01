/* 
This do file calculates different transfer numbers across jobs (event date versus 5 years after the event) for different groups.

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== constructed in 0104 do file

Output:

RA: WWZ 
Time: 2025-01-30
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. a cross-section of event workers: function info
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep a panel of relevant workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
keep if FT_LtoH==1 | FT_LtoL==1
    //&? a panel of LtoL and LtoH event workers 
    //&? 25,001 unique workers

keep IDlse YearMonth FT_Rel_Time FT_Event_Time FT_LtoL FT_LtoH Func TransferSJ

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. 1-7 years after the event 
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
*-? s-1-3. function information at different times 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen Func0 = mean(cond(YearMonth==FT_Event_Time, Func, .))
bysort IDlse: egen Func1 = mean(cond(YearMonth==FT_1yrLater,   Func, .))
bysort IDlse: egen Func2 = mean(cond(YearMonth==FT_2yrLater,   Func, .))
bysort IDlse: egen Func3 = mean(cond(YearMonth==FT_3yrLater,   Func, .))
bysort IDlse: egen Func4 = mean(cond(YearMonth==FT_4yrLater,   Func, .))
bysort IDlse: egen Func5 = mean(cond(YearMonth==FT_5yrLater,   Func, .))
bysort IDlse: egen Func6 = mean(cond(YearMonth==FT_6yrLater,   Func, .))
bysort IDlse: egen Func7 = mean(cond(YearMonth==FT_7yrLater,   Func, .))

bysort IDlse: egen Movers_1yr = max(cond(inrange(FT_Rel_Time, 0, 12), TransferSJ, .))
bysort IDlse: egen Movers_2yr = max(cond(inrange(FT_Rel_Time, 0, 24), TransferSJ, .))
bysort IDlse: egen Movers_3yr = max(cond(inrange(FT_Rel_Time, 0, 36), TransferSJ, .))
bysort IDlse: egen Movers_4yr = max(cond(inrange(FT_Rel_Time, 0, 48), TransferSJ, .))
bysort IDlse: egen Movers_5yr = max(cond(inrange(FT_Rel_Time, 0, 60), TransferSJ, .))
bysort IDlse: egen Movers_6yr = max(cond(inrange(FT_Rel_Time, 0, 72), TransferSJ, .))
bysort IDlse: egen Movers_7yr = max(cond(inrange(FT_Rel_Time, 0, 84), TransferSJ, .))

forvalues i=1/7 {
    replace Movers_`i'yr = . if Func`i'==.
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. keep a cross section of relevant event workers 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if FT_Rel_Time==0
    //&? keep a cross-section of relevant event workers 
keep if Func0!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. investigate the function distribution over time 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

label list Func
/* 
           1 Audit
           2 Communications
           3 Customer Development
           4 Finance
           5 General Management
           6 Human Resources
           7 Information Technology
           8 Legal
           9 Marketing
          10 Research/Development
          11 Supply Chain
          12 Workplace Services
          13 UNKNW
          14 Information and Analytics
          15 Project Management
          16 Operations
          17 Data and Analytics
          18 Data & Analytics
*/
forvalues i = 0/7 {
    replace Func`i' = 17 if Func`i'==18
        //&? 18 is a duplicate of 17 (Data and Analytics) ==> a minor correction 
}
tab Func0
tab Func1
tab Func2
tab Func3
tab Func4
tab Func5
tab Func6
tab Func7
    //&? 13 (unknown) is not a concern, since none of these variables have 13
    //&? In total, there are 16 possible functions, with the following value label:
/* 
           1 Audit
           2 Communications
           3 Customer Development
           4 Finance
           5 General Management
           6 Human Resources
           7 Information Technology
           8 Legal
           9 Marketing
          10 Research/Development
          11 Supply Chain
          12 Workplace Services
          14 Information and Analytics
          15 Project Management
          16 Operations
          17 Data and Analytics
*/

keep IDlse FT_LtoL FT_LtoH Func0 Func1 Func2 Func3 Func4 Func5 Func6 Func7 Movers_*
    //&? keep only relevant variables 

save "${TempData}/temp_TranFunc_LtoLvsLtoH.dta", replace 

