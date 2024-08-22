* salary for decade window

********************************************************************************
* BONUS AND PAY
********************************************************************************

global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH // no binning 
*global event $LLH $LLL $LHL  $LHH  $FLH  $FLL $FHL  $FHH // binning 

label var LogPayBonus "Pay + bonus (logs)"
label var LogPay "Pay (logs)"
label var LogBonus "Bonus (logs)"

* special graph for salary 

* GAINING A HIGH FLYER 
foreach  y in LogPay LogPayBonus LogBonus { //   $Keyoutcome $other
* regression
********************************************************************************

* MAIN 
eststo `y': reghdfe `y'  L*ELH  L*ELL  F*ELH  F*ELL if ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 )  )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR) //  this regression is for all other outcomes ( WL2==1 & ( FTLHB==1 | FTLLB==1) | (random==1 & Ei!=.)  )

local lab: variable label `y'

* single differences 
********************************************************************************


xlincom (L36ELH - L36ELL) (L60ELH - L60ELL) (L84ELH - L84ELL)  (L120ELH - L120ELL) (L24ELH - L24ELL) , level(90) post
est store `y'

coefplot  (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
    (`y' , keep(lc_4) rename(  lc_4  = "40 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(90)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(0(0.1)1.5) note("Notes. Plotting estimates at 12, 20 and 28 quarters after manager transition. Reporting 90% confidence intervals.", span)
graph export "$analysis/Results/4.Event/`y'PlotLHDecade.png", replace 
graph save "$analysis/Results/4.Event/`y'PlotLHDecade.gph", replace 


coefplot  (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
     (`y' , keep(lc_4) rename(  lc_4  = "40 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(90)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(0(0.1)1.5)
graph export "$analysis/Results/4.Event/`y'PlotLHADecade.png", replace 
graph save "$analysis/Results/4.Event/`y'PlotLHADecade.gph", replace 

coefplot (`y' , keep(lc_5) rename(  lc_5  = "8 quarters") ciopts(lwidth(2 ..) lcolor(ebblue))) ///
 (`y' , keep(lc_1) rename(  lc_1  = "12 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
 (`y', keep(lc_2) rename(  lc_2  = "20 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)))  ///
  (`y' , keep(lc_3) rename(  lc_3  = "28 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
      (`y' , keep(lc_4) rename(  lc_4  = "40 quarters") ciopts(lwidth(2 ..) lcolor(ebblue)) )  ///
 , ciopts(lwidth(2 ..))  msymbol(d) mcolor(white) aspect(0.4) legend(off) levels(90)  ///
 title("`lab'", size(medsmall))   xline(0, lpattern(dash))  xlabel(0(0.1)1.5)
graph export "$analysis/Results/4.Event/`y'PlotLHA2yDecade.png", replace 
graph save "$analysis/Results/4.Event/`y'PlotLHA2yDecade.gph", replace 

}
