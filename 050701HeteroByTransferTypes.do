/* 
This do file extends Table VII by investigating heterogeneity based on workers' latest transfer types within 2 years after the event.

*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplest possible dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${FinalData}/AllSameTeam2.dta", clear

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    TransferSJ TransferSJC TransferFunc TransferFuncC TransferSJSameM /// 
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    WL2 ///
    FTHL FTLL FTHH FTLH

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    TransferSJ TransferSJC TransferFunc TransferFuncC TransferSJSameM /// 
    WL2 ///
    FTLL FTLH FTHH FTHL
        // IDs, manager info, outcome variables, sample restriction variable, treatment info

rename WL2 FT_Mngr_both_WL2 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. construct (individual level) event dummies 
*-?       and (individual-month level) relative dates to the event
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! calendar time of the event
rename FTLL FT_Calend_Time_LtoL
rename FTLH FT_Calend_Time_LtoH
rename FTHH FT_Calend_Time_HtoH
rename FTHL FT_Calend_Time_HtoL

*!! five event dummies: 4 types of treatment + 1 never-treated
generate FT_LtoL = 0 
replace  FT_LtoL = 1 if FT_Calend_Time_LtoL != .

generate FT_LtoH = 0 
replace  FT_LtoH = 1 if FT_Calend_Time_LtoH != .

generate FT_HtoH = 0 
replace  FT_HtoH = 1 if FT_Calend_Time_HtoH != .

generate FT_HtoL = 0 
replace  FT_HtoL = 1 if FT_Calend_Time_HtoL != .

generate FT_Never_ChangeM = . 
replace  FT_Never_ChangeM = 1 if FT_LtoH==0 & FT_HtoL==0 & FT_HtoH==0 & FT_LtoL==0
replace  FT_Never_ChangeM = 0 if FT_LtoH==1 | FT_HtoL==1 | FT_HtoH==1 | FT_LtoL==1

label variable FT_LtoL "=1, if the worker experiences a low- to low-type manager change"
label variable FT_LtoH "=1, if the worker experiences a low- to high-type manager change"
label variable FT_HtoH "=1, if the worker experiences a high- to high-type manager change"
label variable FT_HtoL "=1, if the worker experiences a high- to low-type manager change"
label variable FT_Never_ChangeM "=1, if the worker never experiences a manager change"

*!! relative date to the event 
generate FT_Rel_Time = . 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoL if FT_Calend_Time_LtoL !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_LtoH if FT_Calend_Time_LtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoH if FT_Calend_Time_HtoH !=. 
replace  FT_Rel_Time = YearMonth - FT_Calend_Time_HtoL if FT_Calend_Time_HtoL !=. 
label variable FT_Rel_Time "relative date to event, . if no manager change or with unidentified manager"


*!! "event * post" (ind-month level) for four treatment groups
generate FT_Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .
generate FT_LtoLXPost = FT_LtoL * FT_Post
generate FT_LtoHXPost = FT_LtoH * FT_Post
generate FT_HtoHXPost = FT_HtoH * FT_Post
generate FT_HtoLXPost = FT_HtoL * FT_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. decompose TransferSJ into three categories:
*-?         (1) within team (same manager, same function)
*-?         (2) different team (different manager), and different function
*-?         (3) different team (different manager), but same function
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! category (3): differnt manager + same function
generate TransferSJDiffMSameFunc = TransferSJ 
replace  TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace  TransferSJDiffMSameFunc = 0 if TransferSJSameM==1

*!! category (1): same manager + same function
generate TransferSJSameMSameFunc = TransferSJ 
replace  TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace  TransferSJSameMSameFunc = 0 if TransferSJDiffMSameFunc==1

*!! category (2): different manager + different function
*&& variable TransferFunc can accurately describe this category

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. Transform these individual-month level decomposed transfer variables 
*-?        into individual level variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*&& First, make sure we are caring about the latest transfer within 2 years after the events 
*&& Only if max_cumsum_TransferSJ==cumsum_TransferSJ, are workers in their latest transfer within 2 years after the events
sort IDlse YearMonth 
bysort IDlse: generate cumsum_TransferSJ = sum(TransferSJ) if inrange(FT_Rel_Time, 0, 24)
sort IDlse YearMonth 
bysort IDlse: egen max_cumsum_TransferSJ = max(cumsum_TransferSJ) if inrange(FT_Rel_Time, 0, 24)

order IDlse YearMonth FT_Rel_Time TransferSJ cumsum_TransferSJ max_cumsum_TransferSJ

*&& Ignore any other transfer
generate AE_TransferSJ              = TransferSJ
generate AE_TransferSJSameMSameFunc = TransferSJSameMSameFunc
generate AE_TransferFunc            = TransferFunc
generate AE_TransferSJDiffMSameFunc = TransferSJDiffMSameFunc
replace  AE_TransferSJ              = 0 if cumsum_TransferSJ!=max_cumsum_TransferSJ & AE_TransferSJ==1
replace  AE_TransferSJSameMSameFunc = 0 if cumsum_TransferSJ!=max_cumsum_TransferSJ & AE_TransferSJSameMSameFunc==1
replace  AE_TransferFunc            = 0 if cumsum_TransferSJ!=max_cumsum_TransferSJ & AE_TransferFunc==1
replace  AE_TransferSJDiffMSameFunc = 0 if cumsum_TransferSJ!=max_cumsum_TransferSJ & AE_TransferSJDiffMSameFunc==1

sort IDlse YearMonth
bysort IDlse: egen Movers_2yrs                 = max(cond(inrange(FT_Rel_Time, 0, 24),  AE_TransferSJ, .))
bysort IDlse: egen WithinTeamMovers_2yrs       = max(cond(inrange(FT_Rel_Time, 0, 24),  AE_TransferSJSameMSameFunc, .))
bysort IDlse: egen DiffFuncMovers_2yrs         = max(cond(inrange(FT_Rel_Time, 0, 24),  AE_TransferFunc, .))
bysort IDlse: egen DiffTeamSameFuncMovers_2yrs = max(cond(inrange(FT_Rel_Time, 0, 24),  AE_TransferSJDiffMSameFunc, .))

save "${TempData}/temp_HeteroByTransferTypes.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_HeteroByTransferTypes.dta", clear 

foreach outcome in PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus {
    forvalues i = 1/4 {

        if `i'==1 { // All movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & ///
                    (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & ///
                    (Movers_2yrs==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
                
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_One
        }

        if `i'==2 { // Within team movers 
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & ///
                (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & ///
                (WithinTeamMovers_2yrs==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_One
        }

        if `i'==3 { // Cross function movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & ///
                    (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & ///
                    (DiffFuncMovers_2yrs==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_One
        }

        if `i'==4 { // Different team, same function movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & ///
                    (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & ///
                    (DiffTeamSameFuncMovers_2yrs==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_One
        }
    }
}

foreach outcome in PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus {
    forvalues i = 1/4 {

        if `i'==1 { // All movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & (Movers_2yrs==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
                
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_Whole
        }

        if `i'==2 { // Within team movers 
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & (WithinTeamMovers_2yrs==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_Whole
        }

        if `i'==3 { // Cross function movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & (DiffFuncMovers_2yrs==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_Whole
        }

        if `i'==4 { // Different team, same function movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & (DiffTeamSameFuncMovers_2yrs==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_Whole
        }
    }
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce tables  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

esttab PromWLC_1_One PromWLC_2_One PromWLC_3_One PromWLC_4_One using "${Results}/HeterogeneityByTransferTypes_OneQuarterEstimate.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Work level promotions") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{All lateral movers} & \multicolumn{1}{c}{Within team lateral movers} & \multicolumn{1}{c}{Cross function lateral movers} & \multicolumn{1}{c}{Different team, same function lateral movers} \\") ///
    posthead("")
esttab ChangeSalaryGradeC_1_One ChangeSalaryGradeC_2_One ChangeSalaryGradeC_3_One ChangeSalaryGradeC_4_One using "${Results}/HeterogeneityByTransferTypes_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Salary grade increase") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogPayBonus_1_One LogPayBonus_2_One LogPayBonus_3_One LogPayBonus_4_One using "${Results}/HeterogeneityByTransferTypes_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Pay and bonus (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogPay_1_One LogPay_2_One LogPay_3_One LogPay_4_One using "${Results}/HeterogeneityByTransferTypes_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Pay (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogBonus_1_One LogBonus_2_One LogBonus_3_One LogBonus_4_One using "${Results}/HeterogeneityByTransferTypes_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Bonus (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("\hline" "\hline" "\end{tabular}")

esttab PromWLC_1_Whole PromWLC_2_Whole PromWLC_3_Whole PromWLC_4_Whole using "${Results}/HeterogeneityByTransferTypes_WholeQuarterEstimate.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Work level promotions") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{All lateral movers} & \multicolumn{1}{c}{Within team lateral movers} & \multicolumn{1}{c}{Cross function lateral movers} & \multicolumn{1}{c}{Different team, same function lateral movers} \\") ///
    posthead("")
esttab ChangeSalaryGradeC_1_Whole ChangeSalaryGradeC_2_Whole ChangeSalaryGradeC_3_Whole ChangeSalaryGradeC_4_Whole using "${Results}/HeterogeneityByTransferTypes_WholeQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Salary grade increase") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogPayBonus_1_Whole LogPayBonus_2_Whole LogPayBonus_3_Whole LogPayBonus_4_Whole using "${Results}/HeterogeneityByTransferTypes_WholeQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Pay and bonus (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogPay_1_Whole LogPay_2_Whole LogPay_3_Whole LogPay_4_Whole using "${Results}/HeterogeneityByTransferTypes_WholeQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Pay (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogBonus_1_Whole LogBonus_2_Whole LogBonus_3_Whole LogBonus_4_Whole using "${Results}/HeterogeneityByTransferTypes_WholeQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Bonus (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("\hline" "\hline" "\end{tabular}")




