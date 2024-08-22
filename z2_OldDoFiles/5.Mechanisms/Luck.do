********************************************************************************
* This dofile looks at how manager quality mediates the luck effect 
* Luck: Office-function-yearmonth promotion rates
* heterogeneity by luck 
* If  high quality manager is going against the tyde I should observe higher promotions when average prom. is low while less difference btw high and low quality when average prom. is high 
* Using a jackknife approach and leaving out a worker’s own promotion status (and that of their teammates)
********************************************************************************

use "$managersdta/SwitchersAllSameTeam.dta", clear 

* Jackknife estimator of average promotion rates: remove workers and his team  
bys Office Func YearMonth : egen JKPromSG = total(ChangeSalaryGrade)
bys Office Func YearMonth : egen JKPromWL = total(PromWL)
bys Office Func YearMonth : egen noWorkers = count(IDlse)

foreach v in ChangeSalaryGrade PromWL {
	bys IDlseMHR YearMonth: egen Team`v' = total(`v')
}

replace  JKPromSG  = (JKPromSG - TeamChangeSalaryGrade )/ (noWorkers - TeamSize)
replace  JKPromWL  = (JKPromWL - TeamPromWL  )/ (noWorkers - TeamSize)

* binary indicator
foreach v in  JKPromSG  JKPromWL{
su  `v',d
gen `v'B = `v'>r(p50) if `v'!=.	
}



