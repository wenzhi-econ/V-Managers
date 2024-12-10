

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate network-related variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. manager and his subordinates lists 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies", clear 
drop if IDlseMHR==.

sort IDlseMHR YearMonth IDlse
bysort IDlseMHR YearMonth: generate TeamSize = _N

summarize TeamSize, detail
    global MaxTeamSize = r(p95)
keep if TeamSize <= ${MaxTeamSize}
    //&? an innocent sample restriction

sort IDlseMHR YearMonth IDlse
bysort IDlseMHR YearMonth: generate No = _n 

keep IDlse IDlseMHR YearMonth No
rename IDlse Coll 
reshape wide Coll, i(IDlseMHR YearMonth) j(No)

compress 
save "${TempData}/MConnectionsPeople.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. employees' work info 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies", clear 
drop if IDlseMHR==.

keep IDlse YearMonth Office Org4 SubFunc IDlseMHR

rename (Office Org4 SubFunc IDlseMHR) (=YM)
generate IDlseMHR = IDlse
    //&? for the convenience of merge
drop IDlse 

compress 
save "${TempData}/MConnectionsPlaces.dta" , replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. merge and identify manager transition events  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/04MainOutcomesInEventStudies", clear 
xtset IDlse YearMonth 

*!! (1) look at places: is the worker new place is the old manager's previous place?  
merge m:1 IDlseMHR YearMonth using "${TempData}/MConnectionsPlaces.dta"
    drop if _merge ==2 
    drop _merge 

*!! (2) look at people: is the worker new manager the old manager's manager or colleague? 
merge m:1 IDlseMHR YearMonth using "${TempData}/MConnectionsPeople.dta"
    drop if _merge ==2 
    drop _merge 

*!! for each individual, index all their experienced manager transition events 
sort   IDlse YearMonth
bysort IDlse: generate ChangeMCum = sum(ChangeM)

*!! month at manager change event 
sort   IDlse ChangeMCum
bysort IDlse ChangeMCum: egen FirstMonth = min(cond(ChangeM==1, YearMonth, .))

*!! month at manager change event - 1
sort IDlse YearMonth
generate ChangeM_LastMonth = f.ChangeM
sort   IDlse ChangeMCum
bysort IDlse ChangeMCum: egen LastMonth = min(cond(ChangeM_LastMonth==1, YearMonth, .))
format (FirstMonth LastMonth) %tm

summarize ChangeMCum, detail //&? max: 28 

forval i = 1/28 {
    sort   IDlse YearMonth
	bysort IDlse: egen Manager`i'    = mean(cond(ChangeMCum==`i',                            IDlseMHR,   .))
	bysort IDlse: egen FirstMonth`i' = mean(cond(ChangeMCum==`i',                            FirstMonth, .))
	bysort IDlse: egen LastMonth`i'  = mean(cond(ChangeMCum==`i',                            LastMonth,  .))
	bysort IDlse: egen SubFunc`i'    = mean(cond(ChangeMCum==`i' & YearMonth==FirstMonth`i', SubFunc,    .))
	bysort IDlse: egen Office`i'     = mean(cond(ChangeMCum==`i' & YearMonth==FirstMonth`i', Office,     .))
	bysort IDlse: egen Org4`i'       = mean(cond(ChangeMCum==`i' & YearMonth==FirstMonth`i', Org4,       .))
	format (FirstMonth`i' LastMonth`i') %tm
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. is the new manager is their previous manager's subordinates before 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

findregex, re("^Coll")

*!! for the first manager change event 
bysort IDlse: egen ConnectedManager1 = ///
    max(cond(Manager1!=. & (YearMonth<FirstMonth1) & (Manager1==IDlseMHRYM | Manager1==Coll1 | Manager1==Coll2 | Manager1==Coll3 | Manager1==Coll4 | Manager1==Coll5 | Manager1==Coll6 | Manager1==Coll7 | Manager1==Coll8 | Manager1==Coll9 | Manager1==Coll10 | Manager1==Coll11 | Manager1==Coll12 | Manager1==Coll13 | Manager1==Coll14 | Manager1==Coll15 | Manager1==Coll16 | Manager1==Coll17 | Manager1==Coll18 | Manager1==Coll19 | Manager1==Coll20 | Manager1==Coll21 | Manager1==Coll22 | Manager1==Coll23 | Manager1==Coll24 | Manager1==Coll25 | Manager1==Coll26 | Manager1==Coll27 | Manager1==Coll28 | Manager1==Coll29 | Manager1==Coll30 | Manager1==Coll31 | Manager1==Coll32 | Manager1==Coll33 | Manager1==Coll34 | Manager1==Coll35 | Manager1==Coll36 | Manager1==Coll37 | Manager1==Coll38 | Manager1==Coll39 | Manager1==Coll40 | Manager1==Coll41 | Manager1==Coll42 | Manager1==Coll43 | Manager1==Coll44 | Manager1==Coll45 | Manager1==Coll46) , 1, 0)) 

*!! for all subsequent manager change events
forval i = 2/28{ 
	local j = `i' - 1 
    bysort IDlse: egen ConnectedManager`i' = ///
        max(cond(Manager`i'!=. & (YearMonth<FirstMonth`i') & (YearMonth>=FirstMonth`j') & (Manager`i'==IDlseMHRYM | Manager`i'==Coll1 | Manager`i'==Coll2 | Manager`i'==Coll3 | Manager`i'==Coll4 | Manager`i'==Coll5 | Manager`i'==Coll6 | Manager`i'==Coll7 | Manager`i'==Coll8 | Manager`i'==Coll9 | Manager`i'==Coll10 | Manager`i'==Coll11 | Manager`i'==Coll12 | Manager`i'==Coll13 | Manager`i'==Coll14 | Manager`i'==Coll15 | Manager`i'==Coll16 | Manager`i'==Coll17 | Manager`i'==Coll18 | Manager`i'==Coll19 | Manager`i'==Coll20 | Manager`i'==Coll21 | Manager`i'==Coll22 | Manager`i'==Coll23 | Manager`i'==Coll24 | Manager`i'==Coll25 | Manager`i'==Coll26 | Manager`i'==Coll27 | Manager`i'==Coll28 | Manager`i'==Coll29 | Manager`i'==Coll30 | Manager`i'==Coll31 | Manager`i'==Coll32 | Manager`i'==Coll33 | Manager`i'==Coll34 | Manager`i'==Coll35 | Manager`i'==Coll36 | Manager`i'==Coll37 | Manager`i'==Coll38 | Manager`i'==Coll39 | Manager`i'==Coll40 | Manager`i'==Coll41 | Manager`i'==Coll42 | Manager`i'==Coll43 | Manager`i'==Coll44 | Manager`i'==Coll45 | Manager`i'==Coll46), 1, 0)) 
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. did the worker move to new manager's work
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in SubFunc Office Org4 {

    *!! the worker's work info at the month of manager change and one month before 
	bysort IDlse ChangeMCum: egen `var'TempBeforeFirst = mean(cond(YearMonth==FirstMonth, `var', .)) 
	bysort IDlse ChangeMCum: egen `var'TempBeforeLast = mean(cond(YearMonth==LastMonth, `var', .)) 

    *!! for the first manager change event 
	bysort IDlse: egen Connected`var'1 = ///
        max(cond( (`var'1==`var'YM & (YearMonth<FirstMonth1) & `var'1!=`var'TempBeforeLast & `var'1!=`var'TempBeforeFirst & `var'1!=.), 1, 0)) 
	
    *!! for all subsequent manager change events
	forval i = 2/28{
        local j = `i' - 1 
        bysort IDlse: egen Connected`var'`i' = ///
            max(cond((`var'`i'==`var'YM & (YearMonth<FirstMonth`i') & (YearMonth>=FirstMonth`j') & `var'`i'!=`var'TempBeforeLast & `var'`i'!=`var'TempBeforeFirst & `var'`i'!=.), 1, 0)) 
	}
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-6. aggregated network variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in Manager SubFunc Org4 Office {
	generate Connected`var' = Connected`var'1 if ChangeMCum==1 
	forval i = 2/28 {
        replace Connected`var' = Connected`var'`i' if ChangeMCum==`i'	
    }
    replace Connected`var' = 0 if ChangeMCum==0 
}

egen Connected = rowmax(ConnectedManager ConnectedSubFunc ConnectedOffice ConnectedOrg4)

*!! distinguish between lateral and vertical moves

foreach v in Connected ConnectedManager ConnectedOffice ConnectedOrg4 ConnectedSubFunc { 

	generate `v'ChangeM = `v' if ChangeM==1 

	*&& connected lateral transfer
	generate `v'LChangeM = `v'ChangeM
	replace  `v'LChangeM = 0 if ChangeSalaryGrade==1 & ChangeM==1

	*&& connected promotion
	generate `v'VChangeM = `v'ChangeM
	replace  `v'VChangeM = 0 if ChangeSalaryGrade==0 & ChangeM==1

    sort   IDlse ChangeMCum
	bysort IDlse ChangeMCum: egen `v'L = max(`v'LChangeM)
	bysort IDlse ChangeMCum: egen `v'V = max(`v'VChangeM)

    sort   IDlse YearMonth
	bysort IDlse: generate `v'C  = sum(`v'ChangeM)
	bysort IDlse: generate `v'LC = sum(`v'LChangeM)
	bysort IDlse: generate `v'VC = sum(`v'VChangeM)
} 

save "${TempData}/temp_WithinNetworkTransfers.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. event study framework
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_WithinNetworkTransfers.dta", clear 

sort   IDlse YearMonth
bysort IDlse: generate ChangeMC = sum(ChangeM)

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep a panel of event workers

order IDlse YearMonth IDlseMHR ChangeM ChangeMCum ChangeMC Connected ConnectedL ConnectedV

generate FT_Post = (FT_Rel_Time > 0) if FT_Rel_Time!=.
generate FT_LtoLXPost = FT_LtoL * FT_Post
generate FT_LtoHXPost = FT_LtoH * FT_Post
generate FT_HtoHXPost = FT_HtoH * FT_Post
generate FT_HtoLXPost = FT_HtoL * FT_Post

foreach var in ChangeMC ConnectedC ConnectedLC ConnectedVC {

    reghdfe `var' FT_LtoLXPost FT_LtoHXPost FT_HtoHXPost FT_HtoLXPost if (FT_Mngr_both_WL2==1) & (FT_Rel_Time==0 | FT_Rel_Time==22 | FT_Rel_Time==23 | FT_Rel_Time==24), absorb(IDlse YearMonth) vce(cluster IDlseMHR)
        local r = e(r2)

    xlincom (lc_1 = FT_LtoHXPost - FT_LtoLXPost), level(95) post
        eststo conn`var'
        estadd scalar r2 = `r' 
    
    summarize `var' if FT_LtoL==1 & e(sample)==1 & (FT_Rel_Time==22 | FT_Rel_Time==23 | FT_Rel_Time==24)
        estadd scalar Mean_lm = r(mean)

}

esttab connChangeMC connConnectedC connConnectedLC connConnectedVC using "${Results}/NetworkDecomp_EventStudies.tex" ///
    , replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(lc_1) coeflabels(lc_1 "$\beta_{LtoH, 8} - \beta_{LtoL, 8}$") ///
    b(4) se(3) ///
    stats(Mean_lm r2 N, labels("8th quarter mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{All moves} & \multicolumn{1}{c}{Move within manager's network} & \multicolumn{1}{c}{Lateral move within manager's network} & \multicolumn{1}{c}{Vertical move within manager's network} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. Coefficients at the 8th quarter are reported (as 8 quarters is the average duration of a manager assignment to a team). The outcome variable is the number of different types of internal moves. I define a socially connected move based on whether the manager has ever worked (i) with the new manager the worker moves to and/or (ii) in the same sub-function and/or office as the job the worker moves to. Controlling for individual and year-month FE. Standard errors are clustered by manager." "\end{tablenotes}")


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. cross-sectional regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_WithinNetworkTransfers.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? First, keep a panel of event workers

keep if inrange(FT_Rel_Time, 1, 24)
    //&? Second, keep only 8 quarters (i.e., 24 months, 2 years) after the first manager change event.

sort   IDlse YearMonth
bysort IDlse: egen Connected_2yrs  = max(Connected)
bysort IDlse: egen ConnectedL_2yrs = max(ConnectedL)
bysort IDlse: egen ConnectedV_2yrs = max(ConnectedV)
bysort IDlse: egen ChangeM_2yrs    = max(ChangeM)

keep if FT_Rel_Time==24
    //&? Finally, keep only a cross-section of workers.

eststo clear 

foreach var in ChangeM_2yrs Connected_2yrs ConnectedL_2yrs ConnectedV_2yrs {

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL, absorb(Country YearMonth) vce(cluster IDlseMHR)
        local r = e(r2)

    xlincom (lc_1 = FT_LtoH), level(95) post
        eststo `var'
        estadd scalar r2 = `r' 
    
    summarize `var' if FT_LtoL==1
        estadd scalar Mean_lm = r(mean)

}

esttab ChangeM_2yrs Connected_2yrs ConnectedL_2yrs ConnectedV_2yrs using "${Results}/NetworkDecomp_CrossSection.tex" ///
    , replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(lc_1) coeflabels(lc_1 "LtoH - LtoL") ///
    b(4) se(3) ///
    stats(Mean_lm r2 N, labels("8th quarter mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{All moves} & \multicolumn{1}{c}{Move within manager's network} & \multicolumn{1}{c}{Lateral move within manager's network} & \multicolumn{1}{c}{Vertical move within manager's network} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. The outcome variable is whether the worker has the type of move within 24 months after the first manager change event (as 2 years is the average duration of a manager assignment to a team). I define a socially connected move based on whether the manager has ever worked (i) with the new manager the worker moves to and/or (ii) in the same sub-function and/or office as the job the worker moves to. Controlling for individual and year-month FE. Standard errors are clustered by manager." "\end{tablenotes}")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. original regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_WithinNetworkTransfers.dta", clear 

keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? First, keep a panel of event workers

keep if FT_Rel_Time==24
    //&? Second, keep 24 months after the first manager change event.

foreach var in Connected ConnectedL ConnectedV {

    reghdfe `var' FT_LtoH FT_HtoH FT_HtoL, absorb(Country YearMonth) vce(cluster IDlseMHR)
        local r = e(r2)

    xlincom (lc_1 = FT_LtoH), level(95) post
        eststo conn`var'
        estadd scalar r2 = `r' 
    
    summarize `var' if FT_LtoL==1
        estadd scalar Mean_lm = r(mean)

}

esttab connConnected connConnectedL connConnectedV using "${Results}/NetworkDecomp_OriginalResults.tex" ///
    , replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(lc_1) coeflabels(lc_1 "LtoH - LtoL") ///
    b(4) se(3) ///
    stats(Mean_lm r2 N, labels("8th quarter mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Move within manager's network} & \multicolumn{1}{c}{Lateral move within manager's network} & \multicolumn{1}{c}{Vertical move within manager's network} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker. Coefficients at the 8th quarter are reported (as 8 quarters is the average duration of a manager assignment to a team). I define a socially connected move based on whether the manager has ever worked (i) with the new manager the worker moves to and/or (ii) in the same sub-function and/or office as the job the worker moves to. Controlling for country and year-month FE. Standard errors are clustered by manager." "\end{tablenotes}")







