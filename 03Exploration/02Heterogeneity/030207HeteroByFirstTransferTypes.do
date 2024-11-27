/* 
This do file extends Table VII by investigating heterogeneity based on workers' first transfer types after the event.

Input:
    "${TempData}/0104DataForMainOutcomesInEventStudies.dta" <== constructed in 0102 do file.

Output:


*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a simplest possible dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear

keep ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    TransferSJ TransferSJC TransferFunc TransferFuncC /// 
    IDlse YearMonth IDlseMHR EarlyAgeM ///
    FT_Mngr_both_WL2 ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Rel_Time

order ///
    IDlse YearMonth ///
    EarlyAgeM IDlseMHR ///
    TransferSJVC TransferFuncC PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus ///
    TransferSJ TransferSJC TransferFunc TransferFuncC /// 
    FT_Mngr_both_WL2 ///
    FT_LtoL FT_LtoH FT_HtoH FT_HtoL FT_Rel_Time

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. auxiliary variable: temp_first_month and ChangeM
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! first month for a worker
sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

*!! if the worker changes his manager 
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. decompose TransferSJ into three categories:
*-?         (1) within team (same manager, same function)
*-?         (2) different team (different manager), and different function
*-?         (3) different team (different manager), but same function
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! lateral transfer under the same manager
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*!! lateral transfer under different managers
generate TransferSJDiffM = TransferSJ
replace  TransferSJDiffM = 0 if TransferSJSameM==1

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
replace TransferFunc = 0 if TransferSJ==0
    //&? consider the case with IDlse==606619


*!! "event * post" (ind-month level) for four treatment groups
generate FT_Post = (FT_Rel_Time >= 0) if FT_Rel_Time != .
generate FT_LtoLXPost = FT_LtoL * FT_Post
generate FT_LtoHXPost = FT_LtoH * FT_Post
generate FT_HtoHXPost = FT_HtoH * FT_Post
generate FT_HtoLXPost = FT_HtoL * FT_Post

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. Transform these individual-month level decomposed transfer variables 
*-?        into individual level variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*&& First, make sure we are caring about the first transfer after the events (cumsum_TransferSJ==1) 
sort IDlse YearMonth 
bysort IDlse: generate cumsum_TransferSJ = sum(TransferSJ)

*&& Ignore any other transfer
generate AE_TransferSJ              = TransferSJ
generate AE_TransferSJSameMSameFunc = TransferSJSameMSameFunc
generate AE_TransferFunc            = TransferFunc
generate AE_TransferSJDiffMSameFunc = TransferSJDiffMSameFunc
replace  AE_TransferSJ              = 0 if cumsum_TransferSJ!=1 & AE_TransferSJ==1
replace  AE_TransferSJSameMSameFunc = 0 if cumsum_TransferSJ!=1 & AE_TransferSJSameMSameFunc==1
replace  AE_TransferFunc            = 0 if cumsum_TransferSJ!=1 & AE_TransferFunc==1
replace  AE_TransferSJDiffMSameFunc = 0 if cumsum_TransferSJ!=1 & AE_TransferSJDiffMSameFunc==1

sort IDlse YearMonth
bysort IDlse: egen Movers                 = max(cond(FT_Rel_Time>=0,  AE_TransferSJ, .))
bysort IDlse: egen WithinTeamMovers       = max(cond(FT_Rel_Time>=0,  AE_TransferSJSameMSameFunc, .))
bysort IDlse: egen DiffFuncMovers         = max(cond(FT_Rel_Time>=0,  AE_TransferFunc, .))
bysort IDlse: egen DiffTeamSameFuncMovers = max(cond(FT_Rel_Time>=0,  AE_TransferSJDiffMSameFunc, .))

order IDlse YearMonth FT_Rel_Time TransferSJ cumsum_TransferSJ Movers WithinTeamMovers DiffFuncMovers DiffTeamSameFuncMovers

save "${TempData}/temp_HeteroByTransferTypes.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/temp_HeteroByTransferTypes.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. one-quarter (q20) estimate
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach outcome in PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus {
    forvalues i = 1/4 {

        if `i'==1 { // All movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & ///
                    (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & ///
                    (Movers==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
                
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_One
        }

        if `i'==2 { // Within team movers 
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & ///
                (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & ///
                (WithinTeamMovers==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_One
        }

        if `i'==3 { // Cross function movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & ///
                    (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & ///
                    (DiffFuncMovers==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_One
        }

        if `i'==4 { // Different team, same function movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & ///
                    (FT_Rel_Time==-1 | FT_Rel_Time==-2 | FT_Rel_Time==-3 | FT_Rel_Time==58 | FT_Rel_Time==59 | FT_Rel_Time==60) & ///
                    (DiffTeamSameFuncMovers==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_One
        }
    }
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. DiD estimate 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach outcome in PromWLC ChangeSalaryGradeC LogPayBonus LogPay LogBonus {
    forvalues i = 1/4 {

        if `i'==1 { // All movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & (Movers==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
                
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_Whole
        }

        if `i'==2 { // Within team movers 
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & (WithinTeamMovers==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_Whole
        }

        if `i'==3 { // Cross function movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & (DiffFuncMovers==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_Whole
        }

        if `i'==4 { // Different team, same function movers
            reghdfe `outcome' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost ///
                if (FT_Mngr_both_WL2==1) & (DiffTeamSameFuncMovers==1) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
            xlincom (FT_LtoHXPost - FT_LtoLXPost), level(95) post
            eststo `outcome'_`i'_Whole
        }
    }
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce tables  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. one-quarter (q20) estimate results
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

esttab PromWLC_1_One PromWLC_2_One PromWLC_3_One PromWLC_4_One using "${Results}/HeterogeneityByFirstTransferTypes_OneQuarterEstimate.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Work level promotions") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{All lateral movers} & \multicolumn{1}{c}{Within team lateral movers} & \multicolumn{1}{c}{Cross function lateral movers} & \multicolumn{1}{c}{Different team, same function lateral movers} \\") ///
    posthead("\hline")
esttab ChangeSalaryGradeC_1_One ChangeSalaryGradeC_2_One ChangeSalaryGradeC_3_One ChangeSalaryGradeC_4_One using "${Results}/HeterogeneityByFirstTransferTypes_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Salary grade increase") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogPayBonus_1_One LogPayBonus_2_One LogPayBonus_3_One LogPayBonus_4_One using "${Results}/HeterogeneityByFirstTransferTypes_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Pay and bonus (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogPay_1_One LogPay_2_One LogPay_3_One LogPay_4_One using "${Results}/HeterogeneityByFirstTransferTypes_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Pay (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogBonus_1_One LogBonus_2_One LogBonus_3_One LogBonus_4_One using "${Results}/HeterogeneityByFirstTransferTypes_OneQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Bonus (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("\hline" "\hline" "\end{tabular}")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. DiD estimate results
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

esttab PromWLC_1_Whole PromWLC_2_Whole PromWLC_3_Whole PromWLC_4_Whole using "${Results}/HeterogeneityByFirstTransferTypes_WholeQuarterEstimate.tex" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Work level promotions") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("\begin{tabular}{lcccc}" "\hline\hline" "& \multicolumn{1}{c}{All lateral movers} & \multicolumn{1}{c}{Within team lateral movers} & \multicolumn{1}{c}{Cross function lateral movers} & \multicolumn{1}{c}{Different team, same function lateral movers} \\") ///
    posthead("\hline")
esttab ChangeSalaryGradeC_1_Whole ChangeSalaryGradeC_2_Whole ChangeSalaryGradeC_3_Whole ChangeSalaryGradeC_4_Whole using "${Results}/HeterogeneityByFirstTransferTypes_WholeQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Salary grade increase") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogPayBonus_1_Whole LogPayBonus_2_Whole LogPayBonus_3_Whole LogPayBonus_4_Whole using "${Results}/HeterogeneityByFirstTransferTypes_WholeQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Pay and bonus (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogPay_1_Whole LogPay_2_Whole LogPay_3_Whole LogPay_4_Whole using "${Results}/HeterogeneityByFirstTransferTypes_WholeQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Pay (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LogBonus_1_Whole LogBonus_2_Whole LogBonus_3_Whole LogBonus_4_Whole using "${Results}/HeterogeneityByFirstTransferTypes_WholeQuarterEstimate.tex" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Bonus (in logs)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("\hline" "\hline" "\end{tabular}")

