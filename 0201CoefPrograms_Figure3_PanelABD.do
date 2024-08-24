*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? Programs for Panel A, B, and D of Figure 3: 
*?? Programs 1, 2, and 3 evaluate the effects of gaining a FT mnager.
*??   First, I will calculates \beta_{LtoH,s} - \beta_{LtoL,s}, 
*??     and then aggregates the coefficients to the quarter level
*??     using three different aggregation routines. 
*?? Programs 4, 5, and 6 calcualte p-values for pre-trends.
*??   That is, p-value for the estimate: 
*??     \sum_{s<0} {\beta_{LtoH,s} - \beta_{LtoL,s}}
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* 
*&& Incomplete!
*&& There is something wrong with the outcome() option. 
*&& I didn't adjust the variable names to fit in current dataset. 
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 1. VM Aggregation
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture program drop LH_minus_LL_VM
program define LH_minus_LL_VM, rclass 
syntax, event_prefix(string) [PRE_window_len(integer 36) POST_window_len(integer 84) outcome(varname numeric min=1 max=1)] 
/*
This program has one mandatory option, and three optional options.
The required option specifies the variable name used to measure "High-flyer" managers. (FT)
The second two options sepcify the pre- and post-event window length, with default values 36 and 84, respectively.
The last option specify the outcome variable.
*/
local test_pre_window_len  = mod(`pre_window_len', 3)
local test_post_window_len = mod(`post_window_len', 3)
if `test_pre_window_len'!=0 | `test_post_window_len'!=0 {
    display as result _n "Specified pre- and/or post-window lengths are not suitable for VM quarter aggregation."
    display as result _n "Program terminated."
    exit
}

/* 
I will take `pre_window_len'==36 and `post_window_len'==84 as an example and present corresponding local values in the comments.
*/
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 1. produce matrices to store the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
local number_of_pre_quarters  = trunc(`pre_window_len'/3) // 12 
local number_of_post_quarters = trunc(`post_window_len'/3) + 1 // 29
local total_quarters          = `number_of_pre_quarters' + `number_of_post_quarters' // 41

tempname coefficients_mat lower_bound_mat upper_bound_mat quarter_index_mat final_results

matrix `coefficients_mat'  = J(`total_quarters', 1, .)
matrix `lower_bound_mat'   = J(`total_quarters', 1, .)
matrix `upper_bound_mat'   = J(`total_quarters', 1, .)
matrix `quarter_index_mat' = J(`total_quarters', 1, .) 
    // all of them are 41 by 1 matrix to store the results for plotting the coefficients

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 2. store those pre-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
forvalues left_month_index = `pre_window_len'(-3)4 { // 36, 33, 30, ..., 6
    local quarter_index = `number_of_pre_quarters' + 1 - (`left_month_index'/3) 
        // 36 corresponds to 1, 31 corresponds to 2, ..., 4 corresponds to 11
    
    local middle_month_index = `left_month_index' - 1 // 35, 32, 29, ..., 5
    local right_month_index  = `left_month_index' - 2 // 34, 31, 28, ..., 4

    lincom ///
        ((`event_prefix'_LtoH_X_Pre`left_month_index' - `event_prefix'_LtoL_X_Pre`left_month_index') + ///
        (`event_prefix'_LtoH_X_Pre`middle_month_index' - `event_prefix'_LtoL_X_Pre`middle_month_index') + ///
        (`event_prefix'_LtoH_X_Pre`right_month_index' - `event_prefix'_LtoL_X_Pre`right_month_index')) / 3, level(95)
    
    matrix `coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `quarter_index_mat'[`quarter_index', 1] = -(`left_month_index')/3
        // 36 corresponds to -12, 33 corresponds to -11, ..., 6 corresponds to -2
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 3. store period -1 and period 0 coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `coefficients_mat'[`number_of_pre_quarters', 1]  = 0
matrix `lower_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `upper_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `quarter_index_mat'[`number_of_pre_quarters', 1] = -1 


lincom ///
    (`event_prefix'_LtoH_X_Post0 - `event_prefix'_LtoL_X_Post0), level(95)
matrix `coefficients_mat'[`number_of_pre_quarters' + 1, 1]  = r(estimate)
matrix `lower_bound_mat'[`number_of_pre_quarters' + 1, 1]   = r(lb)
matrix `upper_bound_mat'[`number_of_pre_quarters' + 1, 1]   = r(ub)
matrix `quarter_index_mat'[`number_of_pre_quarters' + 1, 1] = 0 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 4. store the post-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
* reset these macros to avoid contamination from the pre-event coefficients
local right_month_index  = 0 
local middle_month_index = 0 
local left_month_index   = 0

forvalues right_month_index = 3(3)`post_window_len' { 
    local quarter_index = (`right_month_index')/3 + `number_of_pre_quarters' + 1
        // 3 corresponds to 14, 6 corresponds to 15, ..., 84 corresponds to 41
    
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
*-? step 5. store other results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* if "`outcome'" != "" {
    quietly summarize `outcome' if inrange(Month_to_First_ChangeM, -3, -1) & (`event_prefix'_LtoL==1 | `event_prefix'_LtoH==1)
    local outcome_base_mean = r(mean)
    local `outcome_base_mean' = string(outcome_base_mean, "%9.3f")
    return local base_mean `outcome_base_mean'
} */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 6. save the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `final_results' = `quarter_index_mat', `coefficients_mat', `lower_bound_mat', `upper_bound_mat'
    // a 41 by 4 matrix
matrix colnames `final_results' = quarter_index coefficients lower_bound upper_bound

capture drop quarter_index coefficients lower_bound upper_bound
svmat `final_results', names(col)

return matrix coefmatrix = `final_results'

end 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 2. WZ Aggregation
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture program drop LH_minus_LL_WZ
program define LH_minus_LL_WZ, rclass  
syntax, event_prefix(string) [PRE_window_len(integer 34) POST_window_len(integer 86) outcome(varname numeric min=1 max=1)] 
/*
This program takes four arguments as input.
The first one indicates the length of pre-event window.
The second one indicates the length of post-event window.
The third argument indicates the outcome variable in the regression.
The fourth argument indicates the identifier of the event.
*/
local test_pre_window_len  = mod(`pre_window_len', 3)
local test_post_window_len = mod(`post_window_len', 3)
if `test_pre_window_len'!=1 | `test_post_window_len'!=2 {
    display "Specified pre- and/or post-window lengths are not suitable for WZ quarter aggregation."
    display "Program terminated."
    exit
}

/* 
I will take `pre_window_len'==34 and `post_window_len'==86 as an example 
    and present local values in the comments.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 1. produce matrices to store the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
local number_of_pre_quarters  = trunc(`pre_window_len'/3) + 1 // 12 
local number_of_post_quarters = trunc(`post_window_len'/3) + 1 // 29
local total_quarters          = `number_of_pre_quarters' + `number_of_post_quarters'

tempname coefficients_mat lower_bound_mat upper_bound_mat quarter_index_mat final_results

matrix `coefficients_mat'  = J(`total_quarters', 1, .)
matrix `lower_bound_mat'   = J(`total_quarters', 1, .)
matrix `upper_bound_mat'   = J(`total_quarters', 1, .)
matrix `quarter_index_mat' = J(`total_quarters', 1, .) 
    // all of them are 41 by 1 matrix to store the results for plotting the coefficients

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 2. store those pre-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-? 
forvalues left_month_index = `pre_window_len'(-3)4 { 
    local quarter_index = `number_of_pre_quarters' - (`left_month_index'-1)/3 
        // 34 corresponds to 1, 31 corresponds to 2, ..., 4 corresponds to 11
    
    local middle_month_index = `left_month_index' - 1 // 33, 30, 27, ..., 3
    local right_month_index  = `left_month_index' - 2 // 32, 29, 26, ..., 2

    lincom ///
        ((`event_prefix'_LtoH_X_Pre`left_month_index' - `event_prefix'_LtoL_X_Pre`left_month_index') + ///
        (`event_prefix'_LtoH_X_Pre`middle_month_index' - `event_prefix'_LtoL_X_Pre`middle_month_index') + ///
        (`event_prefix'_LtoH_X_Pre`right_month_index' - `event_prefix'_LtoL_X_Pre`right_month_index')) / 3, level(95)
    
    matrix `coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `quarter_index_mat'[`quarter_index', 1] = -(`left_month_index'-1)/3 - 1 
        // 34 corresponds to -12, 31 corresponds to -11, ..., 4 corresponds to -2
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 3. store period -1 coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `coefficients_mat'[`number_of_pre_quarters', 1]  = 0
matrix `lower_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `upper_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `quarter_index_mat'[`number_of_pre_quarters', 1] = -1 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 4. store the post-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
* reset these macros to avoid contamination from the pre-event coefficients
local right_month_index  = 0 
local middle_month_index = 0 
local left_month_index   = 0
forvalues right_month_index = 2(3)`post_window_len' { 
    local quarter_index = (`right_month_index'-2)/3 + `number_of_pre_quarters' + 1
        // 2 corresponds to 13, 5 corresponds to 14, ..., 86 corresponds to 41
    
    local middle_month_index = `right_month_index' - 1 // 1, 4, 7, ..., 85
    local left_month_index   = `right_month_index' - 2 // 0, 3, 6, ..., 84 

    lincom ///
        ((`event_prefix'_LtoH_X_Post`right_month_index' - `event_prefix'_LtoL_X_Post`right_month_index') + ///
        (`event_prefix'_LtoH_X_Post`middle_month_index' - `event_prefix'_LtoL_X_Post`middle_month_index') + ///
        (`event_prefix'_LtoH_X_Post`left_month_index' - `event_prefix'_LtoL_X_Post`left_month_index')) / 3, level(95)
    
    matrix `coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `quarter_index_mat'[`quarter_index', 1] = (`right_month_index'-2)/3 
        // 2 corresponds to 0, 5 corresponds to 1, ..., 86 corresponds to 28 
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 5. store other results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* if "`outcome'" != "" {
    quietly summarize `outcome' if inrange(Month_to_First_ChangeM, -3, -1) & (`event_prefix'_LtoL==1 | `event_prefix'_LtoH==1)
    local outcome_base_mean = r(mean)
    local `outcome_base_mean' = string(outcome_base_mean, "%9.3f")
    return local base_mean `outcome_base_mean'
} */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 6. save the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `final_results' = `quarter_index_mat', `coefficients_mat', `lower_bound_mat', `upper_bound_mat'
    // a 41 by 4 matrix
matrix colnames `final_results' = quarter_index coefficients lower_bound upper_bound

capture drop quarter_index coefficients lower_bound upper_bound
svmat `final_results', names(col)

return matrix coefmatrix = `final_results'

end 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 3. CP Aggregation
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& It is the same program as the VM aggregation, as neither of them use month -2 and month -1 coefficients. 
*&& So there is actually no need to change the program. 
*&& I define this program only for notational convenience.

capture program drop LH_minus_LL_CP
program define LH_minus_LL_CP, rclass 
syntax, event_prefix(string) [PRE_window_len(integer 36) POST_window_len(integer 84) outcome(varname numeric min=1 max=1)] 
/*
This program has one mandatory option, and three optional options.
The required option specifies the variable name used to measure "High-flyer" managers. (FT)
The second two options sepcify the pre- and post-event window length, with default values 36 and 84, respectively.
The last option specify the outcome variable.
*/
local test_pre_window_len  = mod(`pre_window_len', 3)
local test_post_window_len = mod(`post_window_len', 3)
if `test_pre_window_len'!=0 | `test_post_window_len'!=0 {
    display as result _n "Specified pre- and/or post-window lengths are not suitable for CP quarter aggregation."
    display as result _n "Program terminated."
    exit
}

/* 
I will take `pre_window_len'==36 and `post_window_len'==84 as an example and present corresponding local values in the comments.
*/
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 1. produce matrices to store the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
local number_of_pre_quarters  = trunc(`pre_window_len'/3) // 12 
local number_of_post_quarters = trunc(`post_window_len'/3) + 1 // 29
local total_quarters          = `number_of_pre_quarters' + `number_of_post_quarters' // 41

tempname coefficients_mat lower_bound_mat upper_bound_mat quarter_index_mat final_results

matrix `coefficients_mat'  = J(`total_quarters', 1, .)
matrix `lower_bound_mat'   = J(`total_quarters', 1, .)
matrix `upper_bound_mat'   = J(`total_quarters', 1, .)
matrix `quarter_index_mat' = J(`total_quarters', 1, .) 
    // all of them are 41 by 1 matrix to store the results for plotting the coefficients

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 2. store those pre-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
forvalues left_month_index = `pre_window_len'(-3)4 { // 36, 33, 30, ..., 6
    local quarter_index = `number_of_pre_quarters' + 1 - (`left_month_index'/3) 
        // 36 corresponds to 1, 31 corresponds to 2, ..., 4 corresponds to 11
    
    local middle_month_index = `left_month_index' - 1 // 35, 32, 29, ..., 5
    local right_month_index  = `left_month_index' - 2 // 34, 31, 28, ..., 4

    lincom ///
        ((`event_prefix'_LtoH_X_Pre`left_month_index' - `event_prefix'_LtoL_X_Pre`left_month_index') + ///
        (`event_prefix'_LtoH_X_Pre`middle_month_index' - `event_prefix'_LtoL_X_Pre`middle_month_index') + ///
        (`event_prefix'_LtoH_X_Pre`right_month_index' - `event_prefix'_LtoL_X_Pre`right_month_index')) / 3, level(95)
    
    matrix `coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `quarter_index_mat'[`quarter_index', 1] = -(`left_month_index')/3
        // 36 corresponds to -12, 33 corresponds to -11, ..., 6 corresponds to -2
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 3. store period -1 and period 0 coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `coefficients_mat'[`number_of_pre_quarters', 1]  = 0
matrix `lower_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `upper_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `quarter_index_mat'[`number_of_pre_quarters', 1] = -1 


lincom ///
    (`event_prefix'_LtoH_X_Post0 - `event_prefix'_LtoL_X_Post0), level(95)
matrix `coefficients_mat'[`number_of_pre_quarters' + 1, 1]  = r(estimate)
matrix `lower_bound_mat'[`number_of_pre_quarters' + 1, 1]   = r(lb)
matrix `upper_bound_mat'[`number_of_pre_quarters' + 1, 1]   = r(ub)
matrix `quarter_index_mat'[`number_of_pre_quarters' + 1, 1] = 0 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 4. store the post-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
* reset these macros to avoid contamination from the pre-event coefficients
local right_month_index  = 0 
local middle_month_index = 0 
local left_month_index   = 0

forvalues right_month_index = 3(3)`post_window_len' { 
    local quarter_index = (`right_month_index')/3 + `number_of_pre_quarters' + 1
        // 3 corresponds to 14, 6 corresponds to 15, ..., 84 corresponds to 41
    
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
*-? step 5. store other results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* if "`outcome'" != "" {
    quietly summarize `outcome' if inrange(Month_to_First_ChangeM, -3, -1) & (`event_prefix'_LtoL==1 | `event_prefix'_LtoH==1)
    local outcome_base_mean = r(mean)
    local `outcome_base_mean' = string(outcome_base_mean, "%9.3f")
    return local base_mean `outcome_base_mean'
} */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 6. save the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `final_results' = `quarter_index_mat', `coefficients_mat', `lower_bound_mat', `upper_bound_mat'
    // a 41 by 4 matrix
matrix colnames `final_results' = quarter_index coefficients lower_bound upper_bound

capture drop quarter_index coefficients lower_bound upper_bound
svmat `final_results', names(col)

return matrix coefmatrix = `final_results'

end 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 4. pretrend LH_minus_LL_VM
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
capture program drop pretrend_LH_minus_LL_VM
program def pretrend_LH_minus_LL_VM, rclass

syntax , event_prefix(string) [PRE_window_len(integer 36)]

local jointL "`event_prefix'_LtoH_X_Pre_Before`pre_window_len' - `event_prefix'_LtoL_X_Pre_Before`pre_window_len'" 

forval t = `pre_window_len'(-1)2 {
	local jointL "`jointL' + `event_prefix'_LtoH_X_Pre`t' - `event_prefix'_LtoL_X_Pre`t'"
}

lincom `jointL'

return scalar pretrend = r(p)

end 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 5. pretrend LH_minus_LL_WZ
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
capture program drop pretrend_LH_minus_LL_WZ
program def pretrend_LH_minus_LL_WZ, rclass

syntax , event_prefix(string) [PRE_window_len(integer 34)]

local jointL "`event_prefix'_LtoH_X_Pre_Before`pre_window_len' - `event_prefix'_LtoL_X_Pre_Before`pre_window_len'" 

forval t = `pre_window_len'(-1)2 {
	local jointL "`jointL' + `event_prefix'_LtoH_X_Pre`t' - `event_prefix'_LtoL_X_Pre`t'"
}

lincom `jointL'

return scalar pretrend = r(p)

end 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 6. pretrend LH_minus_LL_CP
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
capture program drop pretrend_LH_minus_LL_CP
program def pretrend_LH_minus_LL_CP, rclass

syntax , event_prefix(string) [PRE_window_len(integer 36)]

local jointL "`event_prefix'_LtoH_X_Pre_Before`pre_window_len' - `event_prefix'_LtoL_X_Pre_Before`pre_window_len'" 

forval t = `pre_window_len'(-1)4 {
	local jointL "`jointL' + `event_prefix'_LtoH_X_Pre`t' - `event_prefix'_LtoL_X_Pre`t'"
}

lincom `jointL'

return scalar pretrend = r(p)

end 