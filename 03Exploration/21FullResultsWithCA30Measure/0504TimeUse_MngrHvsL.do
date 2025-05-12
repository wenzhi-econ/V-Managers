/* 
This do file contrasts H-type managers' time use data with L-managers.

Input:
    "${RawMNEData}/timeuse.dta" <== raw data
        this data contains WL2 managers, taking the weekly annual average for each variable over 2019 

Notes about the dataset:
    (1) Weekly data over 2019 entire year, random sample of 2000 employees spanning multiple work levels, gender, age, countries and functions. 
    (2) From the calendar data, I do not know who reports to who, so I cannot track the behavior of the worker, but I can track the behavior of the manager. I can look on average how do high flyers spend their time differently from the rest of the managers. 
    (3) Managerial talent interpretation: the results are actually consistent with manager selection rather than training: different time use behavior + accumulate experience (tenure) differently
*/


use "${RawMNEData}/timeuse.dta", clear 

generate meeting_hours_internal = meeting_hours - meeting_hours_with_manager - meeting_hours_external

label variable meeting_hours_with_manager "Meeting hours 1-1 with reportees"
label variable meeting_hours_internal "Meeting hours internal"

global var_list ///
    workweek_span ///
    meeting_hours meeting_hours_with_manager meeting_hours_internal meeting_hours_external ///
    emails_sent open_1_hour_block multitasking_meeting_hours

balancetable HF2 $var_list if WL==2 ///
    using "${Results}/TimeUseBalanceTable.tex", ///
    replace /// 
    pvalues varlabels vce(robust)  ///
    nolines nonumbers ///
    ctitles("Not High Flyer" "High Flyer" "Difference") ///
    prehead("\begin{tabular}{l*{3}{c}} \hline\hline ") ///
    posthead("\hline \\") ///
    prefoot("\hline") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
    "Notes. This dataset documents how high- and low-flyer managers use their time differently. The original dataset is at weekly frequency spanning over the entire 2019, and contains a random sample of 2000 employees from multiple work levels, gender, age, countries and functions. All variables are the average across all weeks in a year. The table shows the mean and standard deviations (in parentheses) for high- and low-flyer managers and p-values for the difference in means. p-valuses are calculated using robust standard errors." "\end{tablenotes}")
