*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 1. calculate the quarter estimates from the monthly regression
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*?
/*  
*&& Program 1 evaluates the effects of gaining a FT manager.
*&& First, I will calculates \beta_{LtoH,s} - \beta_{LtoL,s}, and then aggregates the monthly coefficients to the quarter level. 
*&& This program is suitable for those variables that can only be defined after the manager change event.
*!! Month 0 is omitted in the regression, and Quarter 0 estimate is month 0 estimate, which is zero mechanically.
*!! Quarter +1 estimate is the average of months +1, +2, +3 estimates...
*/

capture program drop LH_minus_LL_OnlyPost
program define LH_minus_LL_OnlyPost, rclass 
syntax, event_prefix(string) [POST_window_len(integer 84) outcome(varname numeric min=1 max=1)] 
/*
This program has one mandatory option, and two optional options.
The required option specifies the variable name used to measure "High-flyer" managers.
The second option specifies the post-event window length, with default value 84.
The last option specify the outcome variable, which will be used in generation of new variables to store the results.
*/

local test_post_window_len = mod(`post_window_len', 3)
if `test_post_window_len'!=0 {
    display as result _n "Specified post-window length is not suitable for CP quarter aggregation."
    display as result _n "Program terminated."
    exit
}

/* 
I will take `post_window_len'==84 as an example and present corresponding local values in the comments.
*/
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 1. produce matrices to store the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local number_of_post_quarters = trunc(`post_window_len'/3) + 1 // 29
local total_quarters          = `number_of_post_quarters'      // 29

tempname coefficients_mat lower_bound_mat upper_bound_mat quarter_index_mat final_results

matrix `coefficients_mat'  = J(`total_quarters', 1, .)
matrix `lower_bound_mat'   = J(`total_quarters', 1, .)
matrix `upper_bound_mat'   = J(`total_quarters', 1, .)
matrix `quarter_index_mat' = J(`total_quarters', 1, .) 
    // all of them are 29 by 1 matrix to store the results for plotting the coefficients

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 2. store quarter 0 coefficient (which is zero mechanically)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

matrix `coefficients_mat'[1, 1]  = 0
matrix `lower_bound_mat'[1, 1]   = 0
matrix `upper_bound_mat'[1, 1]   = 0
matrix `quarter_index_mat'[1, 1] = 0 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 3. store the post-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
* reset these macros to avoid contamination from the pre-event coefficients
local right_month_index  = 0 
local middle_month_index = 0 
local left_month_index   = 0

forvalues right_month_index = 3(3)`post_window_len' { 
    local quarter_index = (`right_month_index')/3 + 1
        // 3 corresponds to 2, 6 corresponds to 3, ..., 84 corresponds to 29
    
    local middle_month_index = `right_month_index' - 1 // 2, 5, 8, ..., 83
    local left_month_index   = `right_month_index' - 2 // 1, 4, 7, ..., 82 

    lincom ///
        ((`event_prefix'_LtoH_X_Post`right_month_index' - `event_prefix'_LtoL_X_Post`right_month_index') + ///
        (`event_prefix'_LtoH_X_Post`middle_month_index' - `event_prefix'_LtoL_X_Post`middle_month_index') + ///
        (`event_prefix'_LtoH_X_Post`left_month_index' - `event_prefix'_LtoL_X_Post`left_month_index')) / 3, level(95)
    
    matrix `coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `quarter_index_mat'[`quarter_index', 1] = (`right_month_index')/3 
        // 3 corresponds to 1, 6 corresponds to 2, ..., 84 corresponds to 28 
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 4. store other summary statistics
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-4-1. baseline means
summarize `outcome' if e(sample)==1 & `event_prefix'_Rel_Time==0 & (`event_prefix'_LtoL==1)
    local LtoL_base_mean = r(mean)
    generate LtoL_`outcome' = `LtoL_base_mean' if inrange(_n, 1, `total_quarters')

summarize `outcome' if e(sample)==1 & `event_prefix'_Rel_Time==0 & (`event_prefix'_LtoH==1)
    local LtoH_base_mean = r(mean)
    generate LtoH_`outcome' = `LtoH_base_mean' if inrange(_n, 1, `total_quarters')

*!! s-4-2. coefficients on the "LtoL * relative period" dummies
lincom `event_prefix'_LtoL_X_Post24
    local coef = r(estimate)
    local p    = r(p)
    generate coef1_`outcome'  = `coef' if inrange(_n, 1, `total_quarters')
    generate coefp1_`outcome' = `p'    if inrange(_n, 1, `total_quarters')

lincom `event_prefix'_LtoL_X_Post60
    local coef = r(estimate)
    local p    = r(p)
    generate coef2_`outcome'  = `coef' if inrange(_n, 1, `total_quarters')
    generate coefp2_`outcome' = `p'    if inrange(_n, 1, `total_quarters')

lincom `event_prefix'_LtoL_X_Post84
    local coef = r(estimate)
    local p    = r(p)
    generate coef3_`outcome'  = `coef' if inrange(_n, 1, `total_quarters')
    generate coefp3_`outcome' = `p'    if inrange(_n, 1, `total_quarters')

*!! s-4-3. coefficients on the "LtoH * relative period" dummies
lincom `event_prefix'_LtoH_X_Post24
    local coef = r(estimate)
    local p    = r(p)
    generate coef4_`outcome'  = `coef' if inrange(_n, 1, `total_quarters')
    generate coefp4_`outcome' = `p'    if inrange(_n, 1, `total_quarters')

lincom `event_prefix'_LtoH_X_Post60
    local coef = r(estimate)
    local p    = r(p)
    generate coef5_`outcome'  = `coef' if inrange(_n, 1, `total_quarters')
    generate coefp5_`outcome' = `p'    if inrange(_n, 1, `total_quarters')

lincom `event_prefix'_LtoH_X_Post84
    local coef = r(estimate)
    local p    = r(p)
    generate coef6_`outcome'  = `coef' if inrange(_n, 1, `total_quarters')
    generate coefp6_`outcome' = `p'    if inrange(_n, 1, `total_quarters')

*!! s-4-4. relative increase 
nlcom (_b[`event_prefix'_LtoH_X_Post24] - _b[`event_prefix'_LtoL_X_Post24]) / _b[`event_prefix'_LtoL_X_Post24]
    local coef = r(table)["b", 1]
    local p    = r(table)["pvalue", 1]
    generate RI1_`outcome'  = `coef' if inrange(_n, 1, `total_quarters')
    generate rip1_`outcome' = `p'    if inrange(_n, 1, `total_quarters')

nlcom (_b[`event_prefix'_LtoH_X_Post60] - _b[`event_prefix'_LtoL_X_Post60]) / _b[`event_prefix'_LtoL_X_Post60]
    local coef = r(table)["b", 1]
    local p    = r(table)["pvalue", 1]
    generate RI2_`outcome'   = `coef' if inrange(_n, 1, `total_quarters')
    generate rip2_`outcome'  = `p'    if inrange(_n, 1, `total_quarters')

nlcom (_b[`event_prefix'_LtoH_X_Post84] - _b[`event_prefix'_LtoL_X_Post84]) / _b[`event_prefix'_LtoL_X_Post84]
    local coef = r(table)["b", 1]
    local p    = r(table)["pvalue", 1]
    generate RI3_`outcome'   = `coef' if inrange(_n, 1, `total_quarters')
    generate rip3_`outcome'  = `p'    if inrange(_n, 1, `total_quarters')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 5. save the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `final_results' = `quarter_index_mat', `coefficients_mat', `lower_bound_mat', `upper_bound_mat'
    // a 29 by 4 matrix
matrix colnames `final_results' = quarter_`outcome'_gains coeff_`outcome'_gains lb_`outcome'_gains ub_`outcome'_gains

capture drop quarter_`outcome'_gains coeff_`outcome'_gains lb_`outcome'_gains ub_`outcome'_gains
svmat `final_results', names(col)

return matrix coefmatrix = `final_results'

end 
