/* 
This do file conducts the analysis on job creation and destruction.


RA: WWZ 
Time: 2025-04-29
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. job creation and destruction
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*&? Within each (SubFuncS, Office) pair, the probability for a StandardJob that appears and disappears in the next month

use "${TempData}/FinalFullSample.dta", clear 

decode Func, gen(FuncS)
decode SubFunc, gen(SubFuncS)
capture drop CountryS
decode Country, gen(CountryS)

generate one=1 

collapse (sum) one, by(StandardJob YearMonth FuncS SubFuncS OfficeCode Office CountryS ISOCode)
isid StandardJob YearMonth FuncS SubFuncS Office

order SubFuncS Office StandardJob YearMonth

sort   SubFuncS Office StandardJob YearMonth
bysort SubFuncS Office StandardJob: generate NewJob = (StandardJob[_n]!=StandardJob[_n-1])
bysort SubFuncS Office StandardJob: generate OldJob = (StandardJob[_n]!=StandardJob[_n+1])

replace OldJob = . if YearMonth==tm(2020m3)
replace NewJob = . if YearMonth==tm(2011m1)

save "${TempData}/NewOldJobs.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. share of WL2 jobs
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear

decode Func, gen(FuncS)
decode SubFunc, gen(SubFuncS)
capture drop CountryS
decode Country, gen(CountryS)

generate one=1 

generate JobWL2 = (WL==2)

collapse JobWL2 (sum) one, by(Office OfficeCode ISOCode YearMonth FuncS SubFuncS)

label variable one "Number of jobs within office-subfunc-month"
rename one UnitSize

compress 
save "${TempData}/ManagerJobs.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear

keep if CA30_LtoL==1 | CA30_LtoH==1
    //&? keep a panel of LtoL and LtoH workers

decode Func, gen(FuncS)
decode SubFunc, gen(SubFuncS)

merge m:1 Office SubFuncS StandardJob YearMonth using "${TempData}/NewOldJobs.dta", keepusing(NewJob OldJob)
    drop _merge 

merge m:1  Office SubFuncS YearMonth using "${TempData}/ManagerJobs.dta", keepusing(JobWL2 UnitSize)
    keep if _merge==3
    drop _merge 

generate sampleN = (JobWL2!=.) & (OldJob!=.) & (NewJob!=.)

eststo clear 

foreach var in JobWL2 OldJob NewJob {
    eststo `var': reghdfe `var' CA30_LtoH if sampleN==1 & Rel_Time>0, cluster(IDlseMHR) absorb(Func#Office Female#AgeBand YearMonth)
        summarize `var' if (e(sample)==1 & CA30_LtoH==0)
        estadd scalar Mean = r(mean)
} 

label variable CA30_LtoH "LtoH"

esttab NewJob OldJob JobWL2 using "${Results}/CA30_NewJobA.tex" ///
    , replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_LtoH) ///
    order(CA30_LtoH) ///
    b(4) se(3) ///
    stats(Mean r2 N, labels("Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Probability of job created} & \multicolumn{1}{c}{Probability of job destroyed} & \multicolumn{1}{c}{Share of managerial jobs} \\ ") ///
    posthead("\hline") ///
    prefoot("\hline") ///
    postfoot("\hline" "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" "Notes. An observation is a worker-year-month. The outcomes are the probability that a new job is created, an old job is destroyed and the share of managerial (WL2+) jobs within an office-subfunction-month. Controls include year-month fixed effect, the interaction of gender and age band fixed effects, and the interaction of function and office fixed effects. Standard errors are clustered by manager. " "\end{tablenotes}")