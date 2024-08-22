preserve 
collapse P75P25* P90P10* Share*  o , by(Country ISOCode Market )
keep if o>=100
twoway (scatter P90P10 P90P10Country , mlabel(ISOCode) msymbol(Oh) mcolor(navy%80) mlabcolor(navy%80)) || (fpfit P90P10 P90P10Country , lcolor(maroon) lwidth(thick)),  title() ytitle(P90P10 Ratio in Annual Compensation) xtitle(P90P10 in the country) legend(off) 
*yscale(range(0(2)10)) ylabel(0(2)10)  xscale(range(0(10)50)) xlabel(0(10)50)   
graph export "$Full/Results/2.2.CLCorr/P90P10.png", replace

twoway (scatter ShareP90P100 ShareP90P100Country , mlabel(ISOCode) msymbol(Oh) mcolor(navy%80) mlabcolor(navy%80)) || (lpoly ShareP90P100 ShareP90P100Country , lcolor(maroon) lwidth(thick)),  title() ytitle(Top 10% income share ) xtitle(Top 10% income share) legend(off) 
*yscale(range(0(.1)1)) ylabel(0(.1)1)  xscale(range(0(.1)1)) xlabel(0(.1)1)   
graph export "$Full/Results/2.2.CLCorr/ShareP90P100.png", replace

twoway (scatter ShareP0P1 ShareP0P1Country , mlabel(ISOCode) msymbol(Oh) mcolor(navy%80) mlabcolor(navy%80)) || (lpoly ShareP0P1 ShareP0P1Country , lcolor(maroon) lwidth(thick)),  title() ytitle(Bottom 1% income share ) xtitle(Bottom 1% income share) legend(off)
* yscale(range(0(.1)1)) ylabel(0(.1)1)  xscale(range(0(.01).01)) xlabel(0(.01).01)   
graph export "$Full/Results/2.2.CLCorr/ShareP0P1.png", replace

twoway (scatter ShareP0P10 ShareP0P10Country , mlabel(ISOCode) msymbol(Oh) mcolor(navy%80) mlabcolor(navy%80)) || (lpoly ShareP0P10 ShareP0P10Country , lcolor(maroon) lwidth(thick)),  title() ytitle(Bottom 10% income share ) xtitle(Bottom 10% income share) legend(off) 
*yscale(range(0(.1)1)) ylabel(0(.1)1)  xscale(range(0(.01).05)) xlabel(0(.01).05)      
graph export "$Full/Results/2.2.CLCorr/ShareP0P10.png", replace

twoway (scatter ShareP99P100 ShareP99P100Country , mlabel(ISOCode) msymbol(Oh) mcolor(navy%80) mlabcolor(navy%80)) || (lpoly ShareP99P100 ShareP99P100Country , lcolor(maroon) lwidth(thick)),  title() ytitle(Top 1% income share ) xtitle(Top 1% income share) legend(off) 
*yscale(range(0(.1)1)) ylabel(0(.1)1)  xscale(range(0(.1)1)) xlabel(0(.1)1)   
graph export "$Full/Results/2.2.CLCorr/ShareP99P100.png", replace

twoway (scatter P75P25 P75P25Country , mlabel(ISOCode) msymbol(Oh) mcolor(navy%80) mlabcolor(navy%80)) || (fpfit P75P25 P75P25Country , lcolor(maroon) lwidth(thick)),  title() ytitle(P75P25 Ratio in Annual Compensation) xtitle(P75P25 in the country) legend(off) 
*yscale(range(0(2)6)) ylabel(0(2)6)  xscale(range(0(2)6)) xlabel(0(2)6)   
graph export "$Full/Results/2.2.CLCorr/P75P25.png", replace

restore 



gen teamPre12 = teamPre == IDlseMHR & (KEi >= -12 & KEi <0) if IDlseMHR!=.
gen teamPost12 = teamPost == IDlseMHR & (KEi <= 12 & KEi >=0)  if IDlseMHR!=.

bys IDlse: egen mm = min(cond(teamPre == IDlseMHR,KEi,.)) 
bys IDlse: egen mmp = max(cond(teamPost == IDlseMHR,KEi,.)) 
su mm, d
su mmp, d 

keep if teamPre12 ==1 | teamPost12==1 // time window of one year before and after change 


TeamTransferSJ = TransferSJ TeamTransferSJC = TransferSJC TeamTransferInternalSJ = TransferInternalSJ TeamTransferInternalSJC = TransferInternalSJC  TeamTransferInternal= TransferInternal TeamTransferInternalC= TransferInternalC  ///
TeamPromWL=  PromWL TeamPromWLC=  PromWLC  TeamChangeSalaryGrade = ChangeSalaryGrade TeamChangeSalaryGradeC = ChangeSalaryGradeC    ///
TeamTransferSJSameM = TransferSJSameM  TeamTransferInternalSJSameM = TransferInternalSJSameM TeamTransferInternalSJSameMC = TransferInternalSJSameMC TeamTransferInternalSameM= TransferInternalSameM TeamChangeSalaryGradeSameMC = ChangeSalaryGradeSameMC  TeamPromWLSameM= PromWLSameM  TeamPromWLSameMC= PromWLSameMC  ///
TeamTransferSJDiffM = TransferSJDiffM TeamTransferInternalSJDiffM = TransferInternalSJDiffM TeamTransferInternalSJDiffMC = TransferInternalSJDiffMC TeamTransferInternalDiffM= TransferInternalDiffM TeamChangeSalaryGradeDiffM = ChangeSalaryGradeDiffM TeamChangeSalaryGradeDiffMC = ChangeSalaryGradeDiffMC TeamPromWLDiffM=  PromWLDiffM TeamPromWLDiffMC=  PromWLDiffMC ///
(sd) TeamPaySD = PayBonus TeamVPASD = VPA (sum) SpanM = o , by(team KEi teamPre teamPost )



gen L1EarlyAgeM = l.EarlyAgeM
bys team (KEi), sort: egen DeltaM =  mean(cond(KEi==0, EarlyAgeM - L1EarlyAgeM ,.))

bys team: egen PreEarlyAgeM = mean(cond(KEi<0, EarlyAgeM,.))
bys team: egen PostEarlyAgeM = mean(cond(KEi>=0, EarlyAgeM,.))

gen KELL =. 
replace KELL = KEi if PostEarlyAgeM==0 & PreEarlyAgeM==0
gen KELH =.
replace KELH = KEi if PostEarlyAgeM==1 & PreEarlyAgeM==0
gen KEHH =.
replace KEHH = KEi if PostEarlyAgeM==1 & PreEarlyAgeM==1
gen KEHL = .
replace KEHL = KEi if PostEarlyAgeM==0 & PreEarlyAgeM==1

foreach var in Ei EHL ELL EHH ELH {

gen `var'Post = 1 if K`var'>=0 & K`var'!=. 
replace `var'Post = 0 if  `var'Post ==.

su K`var'
forvalues l = 0/`r(max)' {
	gen L`l'`var' = K`var'==`l'
}
local mmm = -(`r(min)' +1)
forvalues l = 2/`mmm' { // normalize -1 and r(min)
	gen F`l'`var' = K`var'==-`l'
}

}


foreach y in ShareFemale TeamLeaver ShareOutGroup TeamPaySD TeamVPASD TeamChangeSalaryGrade TeamPromWL {
	reghdfe `y' ELLPost ELHPost EHHPost EHLPost  if SpanM>0 , a(team ) cluster(team)
}

global event L*ELL L*ELH L*EHL L*EHH F*ELL F*ELH F*EHL F*EHH
 
local end = 12 // to be plugged in 
local window = 24 // to be plugged in

foreach y in ShareFemale TeamLeaver ShareOutGroup TeamPaySD TeamVPASD TeamChangeSalaryGrade TeamPromWL {
	reghdfe `y' $event  if SpanM>0 , a(team ) cluster(team)
* double differences 
coeff, c(`window') y(`y') // program 

 tw connected b1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap lo1 hi1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ylabel(0 "0(`ymeanF1')", add custom labcolor(maroon))  ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)
graph save  "$analysis/Results/8.Team/`y'Dual.gph", replace
graph export "$analysis/Results/8.Team/`y'Dual.png", replace

* single differences 
coeff1, c(`window') y(`y') // program 
pretrend , end(`end') y(`y')

su jointL
local jointL = round(r(mean), 0.01)

su jointH 
local jointH = round(r(mean), 0.01)

 tw connected bL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loL1 hiL1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off)  note("Pretrends p-value=`jointL'")
graph save  "$analysis/Results/8.Team/`y'ELH.gph", replace
graph export "$analysis/Results/8.Team/`y'ELH.png", replace

 tw connected bH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) mcolor(ebblue) || rcap loH1 hiH1 et1 if et1>=-`end' & et1<=`end', lcolor(ebblue) yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) xlabel(-`end'(3)`end') ///
xtitle(Months since manager change) title("`lab'", span pos(12)) legend(off) note("Pretrends p-value=`jointH'")
graph save  "$analysis/Results/8.Team/`y'EHL.gph", replace
graph export "$analysis/Results/8.Team/`y'EHL.png", replace
	
}


