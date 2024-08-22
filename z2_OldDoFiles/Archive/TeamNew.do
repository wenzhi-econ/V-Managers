
* TEAM level analysis for the subset of teams that entirely change the manager 

use  "$Managersdta/SwitchersEventSJ.dta", clear 

xtset IDlse YearMonth
gen eventT = Ei if YearMonth == Ei
format eventT %tm
format Ei %tm 
gen eventTF1 = f.eventT

bys IDlse: egen teamPre = mean(cond(eventTF1!=., IDlseMHR, .)) // team of the manager the employee was reporting before 
bys IDlse: egen teamPost = mean(cond(eventT!=., IDlseMHR, .)) // team of the manager the employee was reporting after

bys IDlseMHR eventT: egen Size = count(IDlse) // team unit at manager-transition event level 
replace Size = . if eventT ==. 

bys IDlse: egen SizeEvent = mean(Size)
bys IDlse: egen TeamSizeEvent = mean(cond(eventTF1!=., TeamSize, .))

keep if SizeEvent == TeamSizeEvent
drop if teamPre ==. // these are individuals who have gaps in the data 

* OUTCOME VARIABLES 
gen ExitTeam = IDlseMHR != teamPost & KEi>=1
gen EntryTeam = IDlseMHR != teamPre & KEi>=1

* CONTROL VARIABLES AT THE MANAGER LEVEL 
foreach var in TenureM FemaleM WLM  EarlyAgeM AgeBandM FuncM SubFuncM {
bys IDlse: egen `var'Pre = mean(cond(KEi == -1, `var' , .)) 
bys IDlse: egen `var'Post = mean(cond(KEi == 0, `var' , .)) 
} 

gen o =1 
* !TEAM LEVEL DATASET! 
collapse    ELH* ELL* EHL* EHH* TenureMPre FemaleMPre  WLMPre  EarlyAgeMPre  AgeBandMPre  FuncMPre  SubFuncMPre TenureMPost FemaleMPost  WLMPost  EarlyAgeMPost  AgeBandMPost  FuncMPost  SubFuncMPost ShareEntryTeam = EntryTeam ShareExitTeam = ExitTeam ShareFemale = Female ShareSameG = SameGender  ShareOutGroup = OutGroup ShareDiffOffice = DiffOffice TeamTenure=Tenure TeamPay = PayBonus  TeamVPA = VPA ShareLeaverVol = LeaverVol ShareLeaver = LeaverPerm  ///
ShareTransferSJ = TransferSJ  ShareTransferInternalSJ = TransferInternalSJ ShareTransferInternal= TransferInternal ShareTransferSubFunc= TransferSubFunc   ///
SharePromWL=  PromWL  ShareChangeSalaryGrade = ChangeSalaryGrade    ///
ShareTransferSJSameM = TransferSJSameM  ShareTransferInternalSJSameM = TransferInternalSJSameM  ShareTransferInternalSameM= TransferInternalSameM   SharePromWLSameM= PromWLSameM   ///
ShareTransferSJDiffM = TransferSJDiffM ShareTransferInternalSJDiffM = TransferInternalSJDiffM ShareTransferInternalDiffM= TransferInternalDiffM ShareChangeSalaryGradeDiffM = ChangeSalaryGradeDiffM SharePromWLDiffM=  PromWLDiffM  ///
(sd) TeamPaySD = PayBonus TeamVPASD = VPA (sum) SpanM = o , by(team KEi )

xtset team KEi 

gen TeamPayCV =  TeamPaySD / TeamPay 
gen TeamVPACV =  TeamVPASD / TeamVPA 

label var ShareExitTeam "Exit Team"
label var ShareLeaver "Exit Firm"
label var ShareTransferSJ  "Job Change"
label var ShareChangeSalaryGrade  "Prom. (salary)"
label var SharePromWL  "Prom. (work level)"
label var TeamPayCV  "Pay (CV)"
label var TeamVPACV  "Perf. Appraisals (CV)"

ta SpanM if KEi ==0


keep if KEi <13 & KEi >-13
bys team: egen minSpan = min(SpanM) 
gen Post = 0 
replace Post = 1 if  KEi <13 & KEi>=0 

ds team Post, not
collapse `r(varlist)' , by(team Post)


********************************************************************************
* TEAM LEVEL REGRESSIONS 
********************************************************************************

global controlFE  AgeBandM   WLM  FuncMPost 

eststo clear 
foreach y in ShareExitTeam ShareLeaver  ShareEntryTeam ShareTransferSJ   ShareChangeSalaryGrade SharePromWL TeamPayCV TeamVPACV {
eststo:	reghdfe `y' ELLPost ELHPost EHHPost EHLPost SpanM c.TenureMPre##c.TenureMPre c.TenureMPost##c.TenureMPost  if SpanM>1  , a(team FuncMPre FuncMPost ) cluster(team)
local lbl : variable label `y'
test ELLPost = ELHPost
estadd scalar pvalue1 = r(p)
test EHHPost = EHLPost
estadd scalar pvalue2= r(p)

mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
estadd local Controls "Yes" , replace
estadd local TeamFE "Yes" , replace
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
}

esttab,   label star(* 0.10 ** 0.05 *** 0.01) se r2
esttab using "$analysis/Results/8.Team/SharePrePost.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls FE cmean N1 r2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" ) ) interaction("$\times$ ")  nobaselevels  keep(ELLPost ELHPost EHHPost EHLPost ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team 12 months before and after manager change. Controls include: function FE, team size, age group, tenure and tenure squared of manager. ///
"\end{tablenotes}") replace

* cross section post 
foreach y in ShareExitTeam ShareLeaver  ShareEntryTeam ShareTransferSJ   ShareChangeSalaryGrade SharePromWL TeamPayCV TeamVPACV {
eststo:	reg `y' ELHPost EHHPost EHLPost  if SpanM>1  & Post==1,  cluster(team)
}

* cross section pre 
foreach var in ELH EHH EHL ELL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
}
 
foreach y in ShareExitTeam ShareLeaver  ShareEntryTeam ShareTransferSJ   ShareChangeSalaryGrade SharePromWL TeamPayCV TeamVPACV {
eststo:	reg `y' ELHPre EHHPre EHLPre if SpanM>1  & Post==0,  cluster(team)
}
