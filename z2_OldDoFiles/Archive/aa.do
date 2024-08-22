* LOOKING AT TIME IN NEW JOB  
gcollapse LogPayBonus  Tenure  ONETActivitiesDistanceC   AgeContinuous   TeamSize ELHPost ELLPost EHHPost EHLPost (max)   WLM AgeBandM FemaleM TenureM WL Func SubFunc Female AgeBand  Country LeaverVol LeaverPerm PromWL ChangeSalaryGrade VPA IDlseMHR (count) InternalTenure = YearMonth, by(IDlse EiPost  TransferInternalC)

rename (EiPost EHLPost ELLPost EHHPost ELHPost) (Ei EHL ELL EHH ELH)
foreach var in  Ei EHL ELL EHH ELH {
	bys IDlse: egen T`var' = min(cond(`var'==1,TransferInternalC,.))
gen K`var' = TransferInternalC - T`var'

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min) (needed when using balanced sample)
	gen F`l'`var' = K`var'==-`l'
}
}


eststo: reghdfe InternalTenure F*ELH L*ELH F*ELL L*ELL F*EHH L*EHH F*EHL L*EHL $cont , a( Country AgeBand AgeBandM IDlse   ) vce(cluster IDlseMHR)


local c = 5 // !PLUG! specify window 
coeff, c(`c') 

 tw connected b1 et1 if et1>-3 & et1<3, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-3 & et1<3, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-2(1)2) ///
xtitle(Jobs since manager change) title("Months in sub-division", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TimeInternal.gph", replace
graph export "$analysis/Results/4.Event/TimeInternal.png", replace


* LOOKING AT TIME IN NEW JOB  
gcollapse LogPayBonus  Tenure  ONETActivitiesDistanceC   AgeContinuous   TeamSize ELHPost ELLPost EHHPost EHLPost (max)   WLM AgeBandM FemaleM TenureM WL Func SubFunc Female AgeBand  Country LeaverVol LeaverPerm PromWL ChangeSalaryGrade VPA IDlseMHR (count) InternalTenure = YearMonth, by(IDlse EiPost  TransferInternalSJC)

rename (EiPost EHLPost ELLPost EHHPost ELHPost) (Ei EHL ELL EHH ELH)
foreach var in  Ei EHL ELL EHH ELH {
	bys IDlse: egen T`var' = min(cond(`var'==1,TransferInternalSJC,.))
gen K`var' = TransferInternalSJC - T`var'

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min) (needed when using balanced sample)
	gen F`l'`var' = K`var'==-`l'
}
}


eststo: reghdfe InternalTenure F*ELH L*ELH F*ELL L*ELL F*EHH L*EHH F*EHL L*EHL $cont , a( Country AgeBand AgeBandM IDlse   ) vce(cluster IDlseMHR)


local c = 5 // !PLUG! specify window 
coeff, c(`c') 

 tw connected b1 et1 if et1>-3 & et1<3, lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>-3 & et1<3, lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-2(1)2) ///
xtitle(Jobs since manager change) title("Months in job", span pos(12)) legend(off)
graph save  "$analysis/Results/4.Event/TimeInternalSJ.gph", replace
graph export "$analysis/Results/4.Event/TimeInternalSJ.png", replace
