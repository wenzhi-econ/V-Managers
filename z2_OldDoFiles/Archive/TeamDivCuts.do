* team diversit balanced or not 
* baseline differences 
eststo clear
local i = 1
local Label PromSG75
foreach y in  $perf $move  $homo $div  {

eststo reg`i'FE1:	reg `y'  Delta`Label'  c.TenureM##c.TenureM##i.FemaleM if ShareFemale0B == 0 & SpanM>1 & Year>2013 & KEi<=-1 & KEi>=-36,  cluster(IDlseMHR)
local lbl : variable label `y'

eststo reg`i'FE2:	reg `y'  Delta`Label'  c.TenureM##c.TenureM##i.FemaleM if ShareFemale0B == 1 & SpanM>1 & Year>2013 & KEi<=-1 & KEi>=-36,  cluster(IDlseMHR)

coefplot reg`i'FE1 reg`i'FE2  , levels(90) ///
keep(Delta*) vertical recast(bar )  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq title("`:variable label `y'' Baseline", pos(12) span si(vlarge)) ///
coeflabels(  reg`i'FE1 = "{bf:Gender Unbalanced}"  reg`i'FE2 = "{bf:Gender Balanced}" ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Team is gender balanced if the female share is between 0.4 and 0.6. Reporting 90% confidence intervals.", span)  
graph export  "$analysis/Results/8.Team/`y'HetDivSym0.png", replace

local i = `i' +1

}
