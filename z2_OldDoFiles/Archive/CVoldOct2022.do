* separately by time horizon 
********************************************************************************

forval i = 1/12{
foreach v in lhp`i' hlp`i' {
gen `v' = 1 
label var `v' "-`i'"
}
}

forval j = 1/21 {
foreach v in lh`j' hl`j'  {
gen `v' = 1 
local c = `j'-1
label var `v' "`c'"
}
}


gen HighF1p = FTLH!=. & KEi<0
gen HighF2p = FTHL!=. & KEi<0

eststo clear
eststo lhp1: reg CVPay HighF1p if KEi >=-3  & KEi <0 & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp1: reg CVPay HighF2p if KEi >=-3 & KEi <0 & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = -3
forval i = 2/12{
local m = `i'*3

eststo lhp`i': reg CVPay HighF1p if KEi >=-`m'  & KEi <-`m1' & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp`i': reg CVPay HighF2p if KEi >=-`m' & KEi <-`m1' & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = `m'
} 

eststo lh1: reg CVPay HighF1 if KEi >=0  & KEi <4 & trans <3  & WL2 ==1, vce( cluster IDlseMHR)
eststo hl1: reg CVPay HighF2 if KEi >=0 & KEi <4 & trans >=3 & trans!=.  & WL2 ==1, vce( cluster IDlseMHR)
local m1 = 3
forval i = 2/21{
local m = `i'*3

eststo lh`i': reg CVPay HighF1 if KEi >=`m1'  & KEi <=`m' & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hl`i': reg CVPay HighF2 if KEi >=`m1' & KEi <=`m' & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)
local m1 = `m'
} 


* option for all coefficient plots
* lwidth(0.8 ..)  msymbol() aspect(0.4) ysize(8) xsize(8)
global coefopts keep(HighF*)  levels(95) ///
ciopts(recast(rcap) lcolor(ebblue))  mcolor(ebblue) /// 
 aseq swapnames xline(12, lcolor(maroon))  yline(0, lcolor(maroon)) ///
scale(1)  vertical legend(off) ///
 coeflabels(, )   ytick(,grid glcolor(black))  xtitle(Quarters since manager change) omitted
 
su CVPay  if KEi >=48 & KEi<60 & FTLL!=.
di   .049607/.2756408   

eststo lhp1: reg CVPay HighF1p if KEi >=1  & KEi <=1 & (FTLL !=. | FTLH!=.)  & WL2 ==1, vce( cluster IDlseMHR)
eststo hlp1: reg CVPay HighF2p if KEi >=1 & KEi <=1 & (FTHL !=. | FTHH!=.)   & WL2 ==1, vce( cluster IDlseMHR)

coefplot lhp12 lhp11 lhp10 lhp9 lhp8 lhp7 lhp6 lhp5 lhp4 lhp3 lhp2 lhp1 lh1 lh2 lh3 lh4 lh5 lh6 lh7 lh8 lh9 lh10 lh11 lh12 lh13 lh14 lh15 lh16 lh17 lh18 lh19 lh20 lh21  ,   ///
 title("Coefficient of variation in pay, team-level") $coefopts  yscale(range(-.06 .06)) ylabel(-.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotYearLH.png", replace 
graph save "$analysis/Results/8.Team/CVPlotYearLH.gph", replace 

coefplot hlp12 hlp11 hlp10 hlp9 hlp8 hlp7 hlp6 hlp5 hlp4 hlp3 hlp2 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10 hl11 hl12 hl13 hl14 hl15 hl16 hl17 hl18 hl19 hl20 hl21 ,   ///
 title("Coefficient of variation in pay, team-level")  $coefopts yline(0, lpattern(dash)) yscale(range(-.1 .1)) ylabel(-.1(0.02)0.1)
graph export "$analysis/Results/8.Team/CVPlotYearHL.png", replace 
graph save "$analysis/Results/8.Team/CVPlotYearHL.gph", replace 
