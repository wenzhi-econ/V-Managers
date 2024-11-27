*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 1. calculate the quarter estimates from the monthly regression
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*?
/*  
*&& Program 1 evaluates the effects of losing a FT manager.
*&& First, I will calculates \beta_{HtoL,s} - \beta_{HtoH,s}, and then aggregates the monthly coefficients to the quarter level. 
*&& This program is suitable for those variables that can only be defined after the manager change event.
*!! Month 0 is omitted in the regression, and Quarter 0 estimate is month 0 estimate, which is zero mechanically.
*!! Quarter +1 estimate is the average of months +1, +2, +3 estimates...
*/

capture program drop HL_minus_HH_OnlyPost
program define HL_minus_HH_OnlyPost, rclass 
syntax, event_prefix(string) [POST_window_len(integer 84) outcome(varname numeric min=1 max=1)] 
/*
This program has one mandatory option, and two optional options.
The required option specifies the variable name used to measure "High-flyer" managers.
The second option sepcifies the post-event window length, with default value 84.
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
        ((`event_prefix'_HtoL_X_Post`right_month_index' - `event_prefix'_HtoH_X_Post`right_month_index') + ///
        (`event_prefix'_HtoL_X_Post`middle_month_index' - `event_prefix'_HtoH_X_Post`middle_month_index') + ///
        (`event_prefix'_HtoL_X_Post`left_month_index' - `event_prefix'_HtoH_X_Post`left_month_index')) / 3, level(95)
    
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
summarize `outcome' if e(sample)==1 & FT_Rel_Time==0 & (`event_prefix'_HtoH==1)
    local HtoH_base_mean = r(mean)
    generate HtoH_`outcome' = `HtoH_base_mean' if inrange(_n, 1, `total_quarters')

summarize `outcome' if e(sample)==1 & FT_Rel_Time==0 & (`event_prefix'_HtoL==1)
    local HtoL_base_mean = r(mean)
    generate HtoL_`outcome' = `HtoL_base_mean' if inrange(_n, 1, `total_quarters')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 5. save the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `final_results' = `quarter_index_mat', `coefficients_mat', `lower_bound_mat', `upper_bound_mat'
    // a 29 by 4 matrix
matrix colnames `final_results' = quarter_`outcome'_loss coeff_`outcome'_loss lb_`outcome'_loss ub_`outcome'_loss

capture drop quarter_`outcome'_loss coeff_`outcome'_loss lb_`outcome'_loss ub_`outcome'_loss
svmat `final_results', names(col)

return matrix coefmatrix = `final_results'

end 
