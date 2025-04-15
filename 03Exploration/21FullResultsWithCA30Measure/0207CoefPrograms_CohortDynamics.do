*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 1. LtoH - LtoL 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*?
/*  
*&& Program 1 evaluates the effects of gaining a FT manager.
*&& First, I will calculates \beta_{LtoH,s} - \beta_{LtoL,s}, and then aggregates the monthly coefficients to the quarter level. 
*&& Importantly, the aggregation weights will be adjusted accordingly by the cohort weights.
*!! Months -3, -2, -1 are omitted in the regression, so that quarter -1 estimate is guaranteed to be zero. 
*!! Quarter 0 estimate is month 0 estimate. 
*!! Quarter +1 estimate is the average of months +1, +2, +3 estimates...
*/

capture program drop LH_minus_LL_CohortDynamics
program define LH_minus_LL_CohortDynamics, rclass 
syntax, event_prefix(string) [PRE_window_len(integer 36) POST_window_len(integer 84) outcome(varname numeric min=1 max=1)] 
/*
This program has one mandatory option, and three optional options.
The required option specifies the variable name used to measure "High-flyer" managers.
The second two options specify the pre- and post-event window length, with default values 36 and 84, respectively.
The last option specify the outcome variable, which will be used in generation of new variables to store the results.
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

tempname Lto_coefficients_mat Lto_lower_bound_mat Lto_upper_bound_mat Lto_quarter_index_mat Lto_final_results

matrix `Lto_coefficients_mat'  = J(`total_quarters', 1, .)
matrix `Lto_lower_bound_mat'   = J(`total_quarters', 1, .)
matrix `Lto_upper_bound_mat'   = J(`total_quarters', 1, .)
matrix `Lto_quarter_index_mat' = J(`total_quarters', 1, .) 
    // all of them are 41 by 1 matrix to store the results for plotting the coefficients

tempname Hto_coefficients_mat Hto_lower_bound_mat Hto_upper_bound_mat Hto_quarter_index_mat Hto_final_results

matrix `Hto_coefficients_mat'  = J(`total_quarters', 1, .)
matrix `Hto_lower_bound_mat'   = J(`total_quarters', 1, .)
matrix `Hto_upper_bound_mat'   = J(`total_quarters', 1, .)
matrix `Hto_quarter_index_mat' = J(`total_quarters', 1, .) 
    // all of them are 41 by 1 matrix to store the results for plotting the coefficients

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 2. cohort share calculation  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local total_month = `pre_window_len' + `post_window_len' + 1 // 121

*&& cs stands for cohort share 
tempname cs_LtoL_2011 cs_LtoH_2011
tempname cs_LtoL_2012 cs_LtoH_2012
tempname cs_LtoL_2013 cs_LtoH_2013
tempname cs_LtoL_2014 cs_LtoH_2014
tempname cs_LtoL_2015 cs_LtoH_2015
tempname cs_LtoL_2016 cs_LtoH_2016
tempname cs_LtoL_2017 cs_LtoH_2017
tempname cs_LtoL_2018 cs_LtoH_2018
tempname cs_LtoL_2019 cs_LtoH_2019
tempname cs_LtoL_2020 cs_LtoH_2020

forvalues yy = 2011(1)2020 {
    matrix `cs_LtoL_`yy'' = J(`total_month', 1, .)
    matrix `cs_LtoH_`yy'' = J(`total_month', 1, .)
}

    // all of them (in total, 2 * 10 matrices) are 121 by 1 matrix to store the monthly weights for quarterly aggregations 

forvalues yy = 2011(1)2020 {
    forvalues month_index = `pre_window_len'(-1)1 { // 36, 35, 34, ..., 1
        local month_index_for_weights = `pre_window_len' + 1 - `month_index' // 36 corresponds to 1, 35 corresponds to 2, ... 1 corresponds to 36
        summarize cohort`yy' if `event_prefix'_Rel_Time==-`month_index' & `event_prefix'_LtoL==1 & e(sample)==1
            matrix `cs_LtoL_`yy''[`month_index_for_weights', 1] = r(mean)
        summarize cohort`yy' if `event_prefix'_Rel_Time==-`month_index' & `event_prefix'_LtoH==1 & e(sample)==1
            matrix `cs_LtoH_`yy''[`month_index_for_weights', 1] = r(mean)
    }

    forvalues month_index = 0(1)`post_window_len' { // 0, 1, 2, ...., 84
        local month_index_for_weights = `pre_window_len' + 1 + `month_index' // 0 corresponds to 37, 1 corresponds to 38, ... 84 corresponds to 121
        summarize cohort`yy' if `event_prefix'_Rel_Time==`month_index' & `event_prefix'_LtoL==1 & e(sample)==1
            matrix `cs_LtoL_`yy''[`month_index_for_weights', 1] = r(mean)
        summarize cohort`yy' if `event_prefix'_Rel_Time==`month_index' & `event_prefix'_LtoH==1 & e(sample)==1
            matrix `cs_LtoH_`yy''[`month_index_for_weights', 1] = r(mean)
    }
    
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 3. store pre-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

forvalues left_month_index = `pre_window_len'(-3)6 { // 36, 33, 30, ..., 6

    local quarter_index = `number_of_pre_quarters' + 1 - (`left_month_index'/3) 
        // 36 corresponds to 1, 31 corresponds to 2, ..., 4 corresponds to 11
    
    local middle_month_index = `left_month_index' - 1 // 35, 32, 29, ..., 5
    local right_month_index  = `left_month_index' - 2 // 34, 31, 28, ..., 4

    //&& indices for the weighting matrices
    local li_weight = `pre_window_len' + 1 - `left_month_index'   // 36 corresponds to 1, ..., 6 corresponds to 31
    local mi_weight = `pre_window_len' + 1 - `middle_month_index' // 35 corresponds to 2, ..., 5 corresponds to 32
    local ri_weight = `pre_window_len' + 1 - `right_month_index'  // 34 corresponds to 3, ..., 4 corresponds to 33

    lincom ///
        ( ///
            (`cs_LtoH_2011'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2011 + `cs_LtoH_2012'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2012 + `cs_LtoH_2013'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2013 + `cs_LtoH_2014'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2014 +  `cs_LtoH_2015'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2015 + `cs_LtoH_2016'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2016 + `cs_LtoH_2017'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2017 + `cs_LtoH_2018'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2018 + `cs_LtoH_2019'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2019 + `cs_LtoH_2020'[`li_weight', 1] * `event_prefix'_LtoH_X_Pre`left_month_index'_2020) - ///
            (`cs_LtoL_2011'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2011 + `cs_LtoL_2012'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2012 + `cs_LtoL_2013'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2013 + `cs_LtoL_2014'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2014 + `cs_LtoL_2015'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2015 + `cs_LtoL_2016'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2016 + `cs_LtoL_2017'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2017 + `cs_LtoL_2018'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2018 + `cs_LtoL_2019'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2019 + `cs_LtoL_2020'[`li_weight', 1] * `event_prefix'_LtoL_X_Pre`left_month_index'_2020) ///
        )/3 + ///
        ( ///
            (`cs_LtoH_2011'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2011 + `cs_LtoH_2012'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2012 + `cs_LtoH_2013'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2013 + `cs_LtoH_2014'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2014 + `cs_LtoH_2015'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2015 + `cs_LtoH_2016'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2016 + `cs_LtoH_2017'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2017 + `cs_LtoH_2018'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2018 + `cs_LtoH_2019'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2019 + `cs_LtoH_2020'[`mi_weight', 1] * `event_prefix'_LtoH_X_Pre`middle_month_index'_2020) - ///
            (`cs_LtoL_2011'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2011 + `cs_LtoL_2012'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2012 + `cs_LtoL_2013'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2013 + `cs_LtoL_2014'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2014 + `cs_LtoL_2015'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2015 + `cs_LtoL_2016'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2016 + `cs_LtoL_2017'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2017 + `cs_LtoL_2018'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2018 + `cs_LtoL_2019'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2019 + `cs_LtoL_2020'[`mi_weight', 1] * `event_prefix'_LtoL_X_Pre`middle_month_index'_2020) ///
        )/3 + ///
        ( ///
            (`cs_LtoH_2011'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2011 + `cs_LtoH_2012'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2012 + `cs_LtoH_2013'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2013 + `cs_LtoH_2014'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2014 + `cs_LtoH_2015'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2015 + `cs_LtoH_2016'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2016 + `cs_LtoH_2017'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2017 + `cs_LtoH_2018'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2018 + `cs_LtoH_2019'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2019 + `cs_LtoH_2020'[`ri_weight', 1] * `event_prefix'_LtoH_X_Pre`right_month_index'_2020) - ///
            (`cs_LtoL_2011'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2011 + `cs_LtoL_2012'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2012 + `cs_LtoL_2013'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2013 + `cs_LtoL_2014'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2014 + `cs_LtoL_2015'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2015 + `cs_LtoL_2016'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2016 + `cs_LtoL_2017'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2017 + `cs_LtoL_2018'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2018 + `cs_LtoL_2019'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2019 + `cs_LtoL_2020'[`ri_weight', 1] * `event_prefix'_LtoL_X_Pre`right_month_index'_2020) ///
        )/3, level(95)
    
    matrix `Lto_coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `Lto_lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `Lto_upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `Lto_quarter_index_mat'[`quarter_index', 1] = -(`left_month_index')/3
        // 36 corresponds to -12, 33 corresponds to -11, ..., 6 corresponds to -2
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 4. store period -1 and period 0 coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-4-1. period -1
matrix `Lto_coefficients_mat'[`number_of_pre_quarters', 1]  = 0
matrix `Lto_lower_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `Lto_upper_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `Lto_quarter_index_mat'[`number_of_pre_quarters', 1] = -1 

local pre_window_len_plus1 = `pre_window_len' + 1

*!! s-4-2. period 0
lincom ///
    (`cs_LtoH_2011'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2011 + `cs_LtoH_2012'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2012 + `cs_LtoH_2013'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2013 + `cs_LtoH_2014'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2014 + `cs_LtoH_2015'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2015 + `cs_LtoH_2016'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2016 + `cs_LtoH_2017'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2017 + `cs_LtoH_2018'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2018 + `cs_LtoH_2019'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2019 + `cs_LtoH_2020'[`pre_window_len_plus1', 1] * `event_prefix'_LtoH_X_Post0_2020) - (`cs_LtoL_2011'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2011 + `cs_LtoL_2012'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2012 + `cs_LtoL_2013'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2013 + `cs_LtoL_2014'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2014 + `cs_LtoL_2015'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2015 + `cs_LtoL_2016'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2016 + `cs_LtoL_2017'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2017 + `cs_LtoL_2018'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2018 + `cs_LtoL_2019'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2019 + `cs_LtoL_2020'[`pre_window_len_plus1', 1] * `event_prefix'_LtoL_X_Post0_2020), level(95)

matrix `Lto_coefficients_mat'[`number_of_pre_quarters' + 1, 1]  = r(estimate)
matrix `Lto_lower_bound_mat'[`number_of_pre_quarters' + 1, 1]   = r(lb)
matrix `Lto_upper_bound_mat'[`number_of_pre_quarters' + 1, 1]   = r(ub)
matrix `Lto_quarter_index_mat'[`number_of_pre_quarters' + 1, 1] = 0 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 5. store the post-event coefficients  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local right_month_index  = 0 
local middle_month_index = 0 
local left_month_index   = 0

forvalues right_month_index = 3(3)`post_window_len' { 

    local quarter_index = (`right_month_index')/3 + `number_of_pre_quarters' + 1
        // 3 corresponds to 14, 6 corresponds to 15, ..., 84 corresponds to 41
    
    local middle_month_index = `right_month_index' - 1 // 2, 5, 8, ..., 83
    local left_month_index   = `right_month_index' - 2 // 1, 4, 7, ..., 82 

    //&& indices for the weighting matrices
    local li_weight = `pre_window_len' + 1 + `left_month_index'   // 1 corresponds to 38, ..., 82 corresponds to 119
    local mi_weight = `pre_window_len' + 1 + `middle_month_index' // 2 corresponds to 39, ..., 83 corresponds to 120
    local ri_weight = `pre_window_len' + 1 + `right_month_index'  // 3 corresponds to 40, ..., 84 corresponds to 121

    lincom ///
        ( ///
            (`cs_LtoH_2011'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2011 + `cs_LtoH_2012'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2012 + `cs_LtoH_2013'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2013 + `cs_LtoH_2014'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2014 +  `cs_LtoH_2015'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2015 + `cs_LtoH_2016'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2016 + `cs_LtoH_2017'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2017 + `cs_LtoH_2018'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2018 + `cs_LtoH_2019'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2019 + `cs_LtoH_2020'[`li_weight', 1] * `event_prefix'_LtoH_X_Post`left_month_index'_2020) - ///
            (`cs_LtoL_2011'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2011 + `cs_LtoL_2012'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2012 + `cs_LtoL_2013'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2013 + `cs_LtoL_2014'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2014 + `cs_LtoL_2015'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2015 + `cs_LtoL_2016'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2016 + `cs_LtoL_2017'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2017 + `cs_LtoL_2018'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2018 + `cs_LtoL_2019'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2019 + `cs_LtoL_2020'[`li_weight', 1] * `event_prefix'_LtoL_X_Post`left_month_index'_2020) ///
        )/3 + ///
        ( ///
            (`cs_LtoH_2011'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2011 + `cs_LtoH_2012'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2012 + `cs_LtoH_2013'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2013 + `cs_LtoH_2014'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2014 + `cs_LtoH_2015'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2015 + `cs_LtoH_2016'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2016 + `cs_LtoH_2017'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2017 + `cs_LtoH_2018'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2018 + `cs_LtoH_2019'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2019 + `cs_LtoH_2020'[`mi_weight', 1] * `event_prefix'_LtoH_X_Post`middle_month_index'_2020) - ///
            (`cs_LtoL_2011'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2011 + `cs_LtoL_2012'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2012 + `cs_LtoL_2013'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2013 + `cs_LtoL_2014'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2014 + `cs_LtoL_2015'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2015 + `cs_LtoL_2016'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2016 + `cs_LtoL_2017'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2017 + `cs_LtoL_2018'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2018 + `cs_LtoL_2019'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2019 + `cs_LtoL_2020'[`mi_weight', 1] * `event_prefix'_LtoL_X_Post`middle_month_index'_2020) ///
        )/3 + ///
        ( ///
            (`cs_LtoH_2011'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2011 + `cs_LtoH_2012'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2012 + `cs_LtoH_2013'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2013 + `cs_LtoH_2014'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2014 + `cs_LtoH_2015'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2015 + `cs_LtoH_2016'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2016 + `cs_LtoH_2017'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2017 + `cs_LtoH_2018'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2018 + `cs_LtoH_2019'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2019 + `cs_LtoH_2020'[`ri_weight', 1] * `event_prefix'_LtoH_X_Post`right_month_index'_2020) - ///
            (`cs_LtoL_2011'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2011 + `cs_LtoL_2012'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2012 + `cs_LtoL_2013'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2013 + `cs_LtoL_2014'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2014 + `cs_LtoL_2015'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2015 + `cs_LtoL_2016'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2016 + `cs_LtoL_2017'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2017 + `cs_LtoL_2018'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2018 + `cs_LtoL_2019'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2019 + `cs_LtoL_2020'[`ri_weight', 1] * `event_prefix'_LtoL_X_Post`right_month_index'_2020) ///
        )/3, level(95)
    
    matrix `Lto_coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `Lto_lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `Lto_upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `Lto_quarter_index_mat'[`quarter_index', 1] = (`right_month_index')/3
        // 3 corresponds to 1, 6 corresponds to 2, ..., 84 corresponds to 28 
}


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 6. save the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `Lto_final_results' = `Lto_quarter_index_mat', `Lto_coefficients_mat', `Lto_lower_bound_mat', `Lto_upper_bound_mat'
    // a 41 by 4 matrix
matrix colnames `Lto_final_results' = quarter_`outcome'_gains coeff_`outcome'_gains lb_`outcome'_gains ub_`outcome'_gains

capture drop quarter_`outcome'_gains coeff_`outcome'_gains lb_`outcome'_gains ub_`outcome'_gains
svmat `Lto_final_results', names(col)

return matrix coefmatrix = `Lto_final_results'

end 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 2. HtoL - HtoH 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*?
/*  
*&& Program 2 evaluates the effects of losing a FT manager.
*&& First, I will calculates \beta_{HtoL,s} - \beta_{HtoH,s}, and then aggregates the monthly coefficients to the quarter level. 
*&& Importantly, the aggregation weights will be adjusted accordingly by the cohort weights.
*!! Months -3, -2, -1 are omitted in the regression, so that quarter -1 estimate is guaranteed to be zero. 
*!! Quarter 0 estimate is month 0 estimate. 
*!! Quarter +1 estimate is the average of months +1, +2, +3 estimates...
*/

capture program drop HL_minus_HH_CohortDynamics
program define HL_minus_HH_CohortDynamics, rclass 
syntax, event_prefix(string) [PRE_window_len(integer 36) POST_window_len(integer 60) outcome(varname numeric min=1 max=1)] 
/*
This program has one mandatory option, and three optional options.
The required option specifies the variable name used to measure "High-flyer" managers.
The second two options specify the pre- and post-event window length, with default values 36 and 84, respectively.
The last option specify the outcome variable, which will be used in generation of new variables to store the results.
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
local number_of_post_quarters = trunc(`post_window_len'/3) + 1 // 21
local total_quarters          = `number_of_pre_quarters' + `number_of_post_quarters' // 33

tempname Hto_coefficients_mat Hto_lower_bound_mat Hto_upper_bound_mat Hto_quarter_index_mat Hto_final_results

matrix `Hto_coefficients_mat'  = J(`total_quarters', 1, .)
matrix `Hto_lower_bound_mat'   = J(`total_quarters', 1, .)
matrix `Hto_upper_bound_mat'   = J(`total_quarters', 1, .)
matrix `Hto_quarter_index_mat' = J(`total_quarters', 1, .) 
    // all of them are 33 by 1 matrix to store the results for plotting the coefficients

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 2. cohort share calculation  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local total_month = `pre_window_len' + `post_window_len' + 1 // 97

*&& cs stands for cohort share 
tempname cs_HtoH_2011 cs_HtoL_2011
tempname cs_HtoH_2012 cs_HtoL_2012
tempname cs_HtoH_2013 cs_HtoL_2013
tempname cs_HtoH_2014 cs_HtoL_2014
tempname cs_HtoH_2015 cs_HtoL_2015
tempname cs_HtoH_2016 cs_HtoL_2016
tempname cs_HtoH_2017 cs_HtoL_2017
tempname cs_HtoH_2018 cs_HtoL_2018
tempname cs_HtoH_2019 cs_HtoL_2019
tempname cs_HtoH_2020 cs_HtoL_2020

forvalues yy = 2011(1)2020 {
    matrix `cs_HtoH_`yy'' = J(`total_month', 1, .)
    matrix `cs_HtoL_`yy'' = J(`total_month', 1, .) 
}
    // all of them (in total, 4 * 10 matrices) are 97 by 1 matrix to store the monthly weights for quarterly aggregations 

forvalues yy = 2011(1)2020 {

    forvalues month_index = `pre_window_len'(-1)1 { // 36, 35, 34, ..., 1
        local month_index_for_weights = `pre_window_len' + 1 - `month_index' // 36 corresponds to 1, 35 corresponds to 2, ... 1 corresponds to 36
        summarize cohort`yy' if `event_prefix'_Rel_Time==-`month_index' & `event_prefix'_HtoH==1 & e(sample)==1
            matrix `cs_HtoH_`yy''[`month_index_for_weights', 1] = r(mean)
        summarize cohort`yy' if `event_prefix'_Rel_Time==-`month_index' & `event_prefix'_HtoL==1 & e(sample)==1
            matrix `cs_HtoL_`yy''[`month_index_for_weights', 1] = r(mean)
    }

    forvalues month_index = 0(1)`post_window_len' { // 0, 1, 2, ...., 60
        local month_index_for_weights = `pre_window_len' + 1 + `month_index' // 0 corresponds to 37, 1 corresponds to 38, ... 60 corresponds to 97
        summarize cohort`yy' if `event_prefix'_Rel_Time==`month_index' & `event_prefix'_HtoH==1 & e(sample)==1
            matrix `cs_HtoH_`yy''[`month_index_for_weights', 1] = r(mean)
        summarize cohort`yy' if `event_prefix'_Rel_Time==`month_index' & `event_prefix'_HtoL==1 & e(sample)==1
            matrix `cs_HtoL_`yy''[`month_index_for_weights', 1] = r(mean)
    }
    
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 3. store pre-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

forvalues left_month_index = `pre_window_len'(-3)6 { // 36, 33, 30, ..., 6

    local quarter_index = `number_of_pre_quarters' + 1 - (`left_month_index'/3) 
        // 36 corresponds to 1, 31 corresponds to 2, ..., 4 corresponds to 11
    
    local middle_month_index = `left_month_index' - 1 // 35, 32, 29, ..., 5
    local right_month_index  = `left_month_index' - 2 // 34, 31, 28, ..., 4

    local li_weight   = `pre_window_len' + 1 - `left_month_index'   // 36 corresponds to 1, ..., 6 corresponds to 31
    local mi_weight = `pre_window_len' + 1 - `middle_month_index' // 35 corresponds to 2, ..., 5 corresponds to 32
    local ri_weight  = `pre_window_len' + 1 - `right_month_index'  // 34 corresponds to 3, ..., 4 corresponds to 33

    lincom ///
        ( ///
            (`cs_HtoL_2011'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2011 + `cs_HtoL_2012'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2012 + `cs_HtoL_2013'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2013 + `cs_HtoL_2014'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2014 +  `cs_HtoL_2015'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2015 + `cs_HtoL_2016'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2016 + `cs_HtoL_2017'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2017 + `cs_HtoL_2018'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2018 + `cs_HtoL_2019'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2019 + `cs_HtoL_2020'[`li_weight', 1] * `event_prefix'_HtoL_X_Pre`left_month_index'_2020) - ///
            (`cs_HtoH_2011'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2011 + `cs_HtoH_2012'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2012 + `cs_HtoH_2013'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2013 + `cs_HtoH_2014'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2014 + `cs_HtoH_2015'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2015 + `cs_HtoH_2016'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2016 + `cs_HtoH_2017'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2017 + `cs_HtoH_2018'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2018 + `cs_HtoH_2019'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2019 + `cs_HtoH_2020'[`li_weight', 1] * `event_prefix'_HtoH_X_Pre`left_month_index'_2020) ///
        )/3 + ///
        ( ///
            (`cs_HtoL_2011'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2011 + `cs_HtoL_2012'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2012 + `cs_HtoL_2013'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2013 + `cs_HtoL_2014'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2014 + `cs_HtoL_2015'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2015 + `cs_HtoL_2016'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2016 + `cs_HtoL_2017'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2017 + `cs_HtoL_2018'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2018 + `cs_HtoL_2019'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2019 + `cs_HtoL_2020'[`mi_weight', 1] * `event_prefix'_HtoL_X_Pre`middle_month_index'_2020) - ///
            (`cs_HtoH_2011'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2011 + `cs_HtoH_2012'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2012 + `cs_HtoH_2013'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2013 + `cs_HtoH_2014'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2014 + `cs_HtoH_2015'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2015 + `cs_HtoH_2016'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2016 + `cs_HtoH_2017'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2017 + `cs_HtoH_2018'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2018 + `cs_HtoH_2019'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2019 + `cs_HtoH_2020'[`mi_weight', 1] * `event_prefix'_HtoH_X_Pre`middle_month_index'_2020) ///
        )/3 + ///
        ( ///
            (`cs_HtoL_2011'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2011 + `cs_HtoL_2012'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2012 + `cs_HtoL_2013'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2013 + `cs_HtoL_2014'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2014 + `cs_HtoL_2015'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2015 + `cs_HtoL_2016'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2016 + `cs_HtoL_2017'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2017 + `cs_HtoL_2018'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2018 + `cs_HtoL_2019'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2019 + `cs_HtoL_2020'[`ri_weight', 1] * `event_prefix'_HtoL_X_Pre`right_month_index'_2020) - ///
            (`cs_HtoH_2011'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2011 + `cs_HtoH_2012'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2012 + `cs_HtoH_2013'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2013 + `cs_HtoH_2014'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2014 + `cs_HtoH_2015'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2015 + `cs_HtoH_2016'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2016 + `cs_HtoH_2017'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2017 + `cs_HtoH_2018'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2018 + `cs_HtoH_2019'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2019 + `cs_HtoH_2020'[`ri_weight', 1] * `event_prefix'_HtoH_X_Pre`right_month_index'_2020) ///
        )/3, level(95)
    
    matrix `Hto_coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `Hto_lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `Hto_upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `Hto_quarter_index_mat'[`quarter_index', 1] = -(`left_month_index')/3
        // 36 corresponds to -12, 33 corresponds to -11, ..., 6 corresponds to -2
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 4. store period -1 and period 0 coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-4-1. period -1
matrix `Hto_coefficients_mat'[`number_of_pre_quarters', 1]  = 0
matrix `Hto_lower_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `Hto_upper_bound_mat'[`number_of_pre_quarters', 1]   = 0
matrix `Hto_quarter_index_mat'[`number_of_pre_quarters', 1] = -1 

local pre_window_len_plus1 = `pre_window_len' + 1

*!! s-4-2. period 0
lincom ///
    (`cs_HtoL_2011'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2011 + `cs_HtoL_2012'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2012 + `cs_HtoL_2013'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2013 + `cs_HtoL_2014'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2014 + `cs_HtoL_2015'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2015 + `cs_HtoL_2016'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2016 + `cs_HtoL_2017'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2017 + `cs_HtoL_2018'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2018 + `cs_HtoL_2019'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2019 + `cs_HtoL_2020'[`pre_window_len_plus1', 1] * `event_prefix'_HtoL_X_Post0_2020) - ///
    (`cs_HtoH_2011'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2011 + `cs_HtoH_2012'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2012 + `cs_HtoH_2013'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2013 + `cs_HtoH_2014'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2014 + `cs_HtoH_2015'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2015 + `cs_HtoH_2016'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2016 + `cs_HtoH_2017'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2017 + `cs_HtoH_2018'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2018 + `cs_HtoH_2019'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2019 + `cs_HtoH_2020'[`pre_window_len_plus1', 1] * `event_prefix'_HtoH_X_Post0_2020), level(95)

matrix `Hto_coefficients_mat'[`number_of_pre_quarters' + 1, 1]  = r(estimate)
matrix `Hto_lower_bound_mat'[`number_of_pre_quarters' + 1, 1]   = r(lb)
matrix `Hto_upper_bound_mat'[`number_of_pre_quarters' + 1, 1]   = r(ub)
matrix `Hto_quarter_index_mat'[`number_of_pre_quarters' + 1, 1] = 0 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 5. store the post-event coefficients  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local right_month_index  = 0 
local middle_month_index = 0 
local left_month_index   = 0

forvalues right_month_index = 3(3)`post_window_len' { 

    local quarter_index = (`right_month_index')/3 + `number_of_pre_quarters' + 1
        // 3 corresponds to 14, 6 corresponds to 15, ..., 60 corresponds to 33
    
    local middle_month_index = `right_month_index' - 1 // 2, 5, 8, ..., 59
    local left_month_index   = `right_month_index' - 2 // 1, 4, 7, ..., 58 

    //&& indices for the weighting matrices
    local li_weight = `pre_window_len' + 1 + `left_month_index'   // 1 corresponds to 38, ..., 58 corresponds to 95
    local mi_weight = `pre_window_len' + 1 + `middle_month_index' // 2 corresponds to 39, ..., 59 corresponds to 96
    local ri_weight = `pre_window_len' + 1 + `right_month_index'  // 3 corresponds to 40, ..., 60 corresponds to 97

    lincom ///
        ( ///
            (`cs_HtoL_2011'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2011 + `cs_HtoL_2012'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2012 + `cs_HtoL_2013'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2013 + `cs_HtoL_2014'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2014 +  `cs_HtoL_2015'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2015 + `cs_HtoL_2016'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2016 + `cs_HtoL_2017'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2017 + `cs_HtoL_2018'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2018 + `cs_HtoL_2019'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2019 + `cs_HtoL_2020'[`li_weight', 1] * `event_prefix'_HtoL_X_Post`left_month_index'_2020) - ///
            (`cs_HtoH_2011'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2011 + `cs_HtoH_2012'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2012 + `cs_HtoH_2013'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2013 + `cs_HtoH_2014'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2014 + `cs_HtoH_2015'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2015 + `cs_HtoH_2016'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2016 + `cs_HtoH_2017'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2017 + `cs_HtoH_2018'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2018 + `cs_HtoH_2019'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2019 + `cs_HtoH_2020'[`li_weight', 1] * `event_prefix'_HtoH_X_Post`left_month_index'_2020) ///
        )/3 + ///
        ( ///
            (`cs_HtoL_2011'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2011 + `cs_HtoL_2012'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2012 + `cs_HtoL_2013'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2013 + `cs_HtoL_2014'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2014 + `cs_HtoL_2015'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2015 + `cs_HtoL_2016'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2016 + `cs_HtoL_2017'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2017 + `cs_HtoL_2018'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2018 + `cs_HtoL_2019'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2019 + `cs_HtoL_2020'[`mi_weight', 1] * `event_prefix'_HtoL_X_Post`middle_month_index'_2020) - ///
            (`cs_HtoH_2011'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2011 + `cs_HtoH_2012'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2012 + `cs_HtoH_2013'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2013 + `cs_HtoH_2014'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2014 + `cs_HtoH_2015'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2015 + `cs_HtoH_2016'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2016 + `cs_HtoH_2017'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2017 + `cs_HtoH_2018'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2018 + `cs_HtoH_2019'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2019 + `cs_HtoH_2020'[`mi_weight', 1] * `event_prefix'_HtoH_X_Post`middle_month_index'_2020) ///
        )/3 + ///
        ( ///
            (`cs_HtoL_2011'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2011 + `cs_HtoL_2012'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2012 + `cs_HtoL_2013'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2013 + `cs_HtoL_2014'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2014 + `cs_HtoL_2015'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2015 + `cs_HtoL_2016'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2016 + `cs_HtoL_2017'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2017 + `cs_HtoL_2018'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2018 + `cs_HtoL_2019'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2019 + `cs_HtoL_2020'[`ri_weight', 1] * `event_prefix'_HtoL_X_Post`right_month_index'_2020) - ///
            (`cs_HtoH_2011'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2011 + `cs_HtoH_2012'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2012 + `cs_HtoH_2013'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2013 + `cs_HtoH_2014'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2014 + `cs_HtoH_2015'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2015 + `cs_HtoH_2016'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2016 + `cs_HtoH_2017'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2017 + `cs_HtoH_2018'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2018 + `cs_HtoH_2019'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2019 + `cs_HtoH_2020'[`ri_weight', 1] * `event_prefix'_HtoH_X_Post`right_month_index'_2020) ///
        )/3, level(95)
    
    matrix `Hto_coefficients_mat'[`quarter_index', 1]  = r(estimate)
    matrix `Hto_lower_bound_mat'[`quarter_index', 1]   = r(lb)
    matrix `Hto_upper_bound_mat'[`quarter_index', 1]   = r(ub)
    matrix `Hto_quarter_index_mat'[`quarter_index', 1] = (`right_month_index')/3
        // 3 corresponds to 1, 6 corresponds to 2, ..., 60 corresponds to 20 
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 6. save the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `Hto_final_results' = `Hto_quarter_index_mat', `Hto_coefficients_mat', `Hto_lower_bound_mat', `Hto_upper_bound_mat'
    // a 33 by 4 matrix
matrix colnames `Hto_final_results' = quarter_`outcome'_loss coeff_`outcome'_loss lb_`outcome'_loss ub_`outcome'_loss

capture drop quarter_`outcome'_loss coeff_`outcome'_loss lb_`outcome'_loss ub_`outcome'_loss
svmat `Hto_final_results', names(col)

return matrix coefmatrix = `Hto_final_results'

end 