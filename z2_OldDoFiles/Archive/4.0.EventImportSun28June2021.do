********************************************************************************
* IMPORT DATASET - only consider first event 
********************************************************************************

use "$Managersdta/AllSnapshotMCultureMType.dta", clear 
xtset IDlse YearMonth 

********************************************************************************
* Event study dummies 
********************************************************************************

* Changing manager that transfers 
gen  ChangeMR = 0 
replace ChangeMR = 1 if ChangeM==1 & (TransferInternalL1M==1 | TransferInternalL2M==1 | TransferInternalL3M==1 | TransferInternalF1M==1  | TransferInternalF2M==1  | TransferInternalF3M==1) 
replace  ChangeMR  = . if ChangeM==.
replace  ChangeMR  = . if IDlseMHR ==. 
 
* For Sun & Abraham only consider first event 
bys IDlse: egen    Ei = min(cond(ChangeMR==1, YearMonth ,.)) // for single differences 
replace ChangeMR = 0 if YearMonth > Ei & ChangeMR==1

* Early age 
gsort IDlse YearMonth 
* low high
gen ChangeAgeMLowHigh = 0 
replace ChangeAgeMLowHigh = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==0    )
replace ChangeAgeMLowHigh = . if IDlseMHR ==. 
replace ChangeAgeMLowHigh = 0 if ChangeMR ==0
* high low
gsort IDlse YearMonth 
gen ChangeAgeMHighLow = 0 
replace ChangeAgeMHighLow = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==1    )
replace ChangeAgeMHighLow = . if IDlseMHR ==. 
replace ChangeAgeMHighLow = 0 if ChangeMR ==0
* high high 
gsort IDlse YearMonth 
gen ChangeAgeMHighHigh = 0 
replace ChangeAgeMHighHigh = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==1 & EarlyAgeM[_n-1]==1    )
replace ChangeAgeMHighHigh = . if IDlseMHR ==. 
replace ChangeAgeMHighHigh = 0 if ChangeMR ==0
* low low 
gsort IDlse YearMonth 
gen ChangeAgeMLowLow = 0 
replace ChangeAgeMLowLow = 1 if (IDlse[_n] == IDlse[_n-1] & EarlyAgeM[_n]==0 & EarlyAgeM[_n-1]==0   )
replace ChangeAgeMLowLow = . if IDlseMHR ==. 
replace ChangeAgeMLowLow = 0 if ChangeMR ==0

* for single differences 
egen ChangeAgeMLow = rowmax(ChangeAgeMLowHigh ChangeAgeMLowLow) // for single differences 
egen ChangeAgeMHigh = rowmax(ChangeAgeMHighHigh ChangeAgeMHighLow) // for single differences 

egen ChangeAgeMtoLow = rowmax(ChangeAgeMHighLow ChangeAgeMLowLow) // for single differences 
egen ChangeAgeMtoHigh = rowmax(ChangeAgeMHighHigh ChangeAgeMLowHigh) // for single differences 

* only consider first event 
foreach v in toLow toHigh High Low LowHigh LowLow HighHigh HighLow{
bys IDlse: egen   ChangeAgeM`v'Month = min(cond(ChangeAgeM`v'==1, YearMonth ,.)) // for single	
replace ChangeAgeM`v'= 0 if YearMonth > ChangeAgeM`v'Month  & ChangeAgeM`v'==1
}

* Add categorical variables for imputation estimator 
*bys IDlse: egen m = max(YearMonth) // time of event
* Single differences 
gen EL = ChangeAgeMLowMonth
format EL %tm 
gen EH = ChangeAgeMHighMonth
format EH %tm 
gen EtoL = ChangeAgeMtoLowMonth
format EtoL %tm 
gen EtoH = ChangeAgeMtoHighMonth
format EtoH %tm 
* Single coefficients 
gen ELH = ChangeAgeMLowHighMonth 
*replace ELH = m + 1 if ELH==.
format ELH %tm 
gen EHH = ChangeAgeMHighHighMonth 
*replace EHH = m + 1 if EHH==.
format EHH %tm 
gen ELL = ChangeAgeMLowLowMonth 
*replace ELL = m + 1 if ELL==.
format ELL %tm 
gen EHL = ChangeAgeMHighLowMonth 
*replace EHL = m + 1 if EHL==.
format EHL %tm 

* select ONLY relevant variables 
keep IDlse YearMonth IDlseMHR Ei EL EH ELH EHH ELL EHL CountryYM Tenure Female AgeBand WL Func EarlyAgeM TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow LogPayBonus  LeaverPerm  TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC ChangeSalaryGradeC  PromWLC insample insample1

* FE and control vars 
gen Tenure2 = Tenure*Tenure 
gen  Tenure2M = TenureM*TenureM

compress
keep if insample1==1 // 1mill 

foreach var in Ei EH EL EHL ELL EHH ELH {
gen K`var' = YearMonth - `var'

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
global event L*ELH  L*ELL L*EHL  L*EHH  F*ELH  F*ELL F*EHL  F*EHH
*global event L*EL   L*EH    F*EL   F*EH  
global epost ELHPost EHHPost ELLPost EHLPost
*****

/*
////////////////////////////////////////////////////////////////////////////////
* estimate all the lags and leads 
////////////////////////////////////////////////////////////////////////////////

esplot LogPayBonus ,  event(ChangeAgeMHighLow , save ) compare(ChangeAgeMHighHigh , save) window(-12 12)   estimate_reference // estimate reference 
esplot LogPayBonus ,  event(ChangeAgeMLowHigh , save ) compare(ChangeAgeMLowLow , save) window(-12 12)   estimate_reference // estimate reference 

drop F1_ChangeAgeMLowHigh F1_ChangeAgeMLowLow F1_ChangeAgeMHighHigh F1_ChangeAgeMHighLow

*/
********************************************************************************
* PROGRAMS 
********************************************************************************

********************************************************************************
* double difference estimates 
********************************************************************************

cap program drop coeff
program def coeff
matrix b = J(121,1,.)
matrix se = J(121,1,.)
matrix p = J(121,1,.)
matrix lo = J(121,1,.)
matrix hi = J(121,1,.)
matrix et = J(121,1,.)

local j = 1
forval i=60(-1)2{
	lincom 0.5*( (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) - (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) )
	
	mat b_F`i' = (r(estimate))
	mat se_F`i' = (r(se))
	mat p_F`i' = (r(p))
	mat lo_F`i' = (r(lb))
	mat hi_F`i' = (r(ub))
	
	matrix b[`j',1] =b_F`i'
	matrix se[`j',1] =se_F`i'
	matrix p[`j',1] =p_F`i'
	matrix lo[`j',1] =lo_F`i'
	matrix hi[`j',1] =hi_F`i'
	mat et[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix b[60,1] =0
matrix se[60,1] =0
matrix p[60,1] =0
matrix lo[60,1] =0
matrix hi[60,1] =0
matrix et[60,1] =-1

local j = 61
forval i=0(1)60{
	lincom 0.5*( (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) - (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh) )
	
	mat b_L`i' = (r(estimate))
	mat se_L`i' = (r(se))
	mat p_L`i' = (r(p))
	mat lo_L`i' = (r(lb))
	mat hi_L`i' = (r(ub))
	
	matrix b[`j',1] =b_L`i'
	matrix se[`j',1] =se_L`i'
	matrix p[`j',1] =p_L`i'
	matrix lo[`j',1] =lo_L`i'
	matrix hi[`j',1] =hi_L`i'
	mat et[`j',1] = `i'
	local j = `j' + 1

}

cap drop b1 et1 lo1 hi1 p1	se1
svmat b 
svmat se
svmat p
svmat et 
svmat lo 
svmat hi 
end 


********************************************************************************
* double difference estimates - productivity 
********************************************************************************

cap program drop coeffProd
program def coeffProd
matrix b = J(41,1,.)
matrix se = J(41,1,.)
matrix p = J(41,1,.)
matrix lo = J(41,1,.)
matrix hi = J(41,1,.)
matrix et = J(41,1,.)

local j = 1
forval i=20(-1)2{
	lincom 0.5*( (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) - (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) )
	
	mat b_F`i' = (r(estimate))
	mat se_F`i' = (r(se))
	mat p_F`i' = (r(p))
	mat lo_F`i' = (r(lb))
	mat hi_F`i' = (r(ub))
	
	matrix b[`j',1] =b_F`i'
	matrix se[`j',1] =se_F`i'
	matrix p[`j',1] =p_F`i'
	matrix lo[`j',1] =lo_F`i'
	matrix hi[`j',1] =hi_F`i'
	mat et[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix b[20,1] =0
matrix se[20,1] =0
matrix p[20,1] =0
matrix lo[20,1] =0
matrix hi[20,1] =0
matrix et[20,1] =-1

local j = 21
forval i=0(1)20{
	lincom 0.5*( (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) - (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh) )
	
	mat b_L`i' = (r(estimate))
	mat se_L`i' = (r(se))
	mat p_L`i' = (r(p))
	mat lo_L`i' = (r(lb))
	mat hi_L`i' = (r(ub))
	
	matrix b[`j',1] =b_L`i'
	matrix se[`j',1] =se_L`i'
	matrix p[`j',1] =p_L`i'
	matrix lo[`j',1] =lo_L`i'
	matrix hi[`j',1] =hi_L`i'
	mat et[`j',1] = `i'
	local j = `j' + 1

}

cap drop b1 et1 lo1 hi1 p1	se1
svmat b 
svmat se
svmat p
svmat et 
svmat lo 
svmat hi 
end 

********************************************************************************
* cumulative sum for exit 
********************************************************************************

cap program drop coeffSum
program def coeffSum
matrix b = J(121,1,.)
matrix se = J(121,1,.)
matrix p = J(121,1,.)
matrix lo = J(121,1,.)
matrix hi = J(121,1,.)
matrix et = J(121,1,.)

matrix bSum = J(121,1,.)
matrix seSum = J(121,1,.)
matrix pSum = J(121,1,.)
matrix loSum = J(121,1,.)
matrix hiSum = J(121,1,.)

local c = 0
local j = 1
forval i=60(-1)2{
	lincom 0.5*( (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) - (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) )
	

	mat b_F`i' = (r(estimate))
	mat se_F`i' = (r(se))
	mat p_F`i' = (r(p))
	mat lo_F`i' = (r(lb))
	mat hi_F`i' = (r(ub))
	
	matrix b[`j',1] =b_F`i'
	matrix se[`j',1] =se_F`i'
	matrix p[`j',1] =p_F`i'
	matrix lo[`j',1] =lo_F`i'
	matrix hi[`j',1] =hi_F`i'
	mat et[`j',1] = -`i'
	
	matrix bSum[`j',1] =b_F`i'
	matrix seSum[`j',1] =se_F`i'
	matrix pSum[`j',1] =p_F`i'
	matrix loSum[`j',1] =lo_F`i'
	matrix hiSum[`j',1] =hi_F`i'
	
	local j = `j' + 1
}

matrix b[60,1] =0
matrix se[60,1] =0
matrix p[60,1] =0
matrix lo[60,1] =0
matrix hi[60,1] =0
matrix et[60,1] =-1

local j = 61
forval i=0(1)60{
	lincom 0.5*( (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) - (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh) )
	
	mat b_L`i' = (r(estimate))
	mat se_L`i' = (r(se))
	mat p_L`i' = (r(p))
	mat lo_L`i' = (r(lb))
	mat hi_L`i' = (r(ub))
	
	matrix b[`j',1] =b_L`i'
	matrix se[`j',1] =se_L`i'
	matrix p[`j',1] =p_L`i'
	matrix lo[`j',1] =lo_L`i'
	matrix hi[`j',1] =hi_L`i'
	mat et[`j',1] = `i'
	
		* Cumulative sum 
		local c   "0.5*( (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) - (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh) ) +  `c' "
		lincom `c'

	mat bSum_L`i' = (r(estimate))
	mat seSum_L`i' = (r(se))
	mat pSum_L`i' = (r(p))
	mat loSum_L`i' = (r(lb))
	mat hiSum_L`i' = (r(ub))
	
	matrix bSum[`j',1] =bSum_L`i'
	matrix seSum[`j',1] =seSum_L`i'
	matrix pSum[`j',1] =pSum_L`i'
	matrix loSum[`j',1] =loSum_L`i'
	matrix hiSum[`j',1] =hiSum_L`i'
	
	local j = `j' + 1

}

cap drop b1 et1 lo1 hi1 p1	se1 bSum1 loSum1 hiSum1 pSum1	seSum1
svmat b 
svmat se
svmat p
svmat et 
svmat lo 
svmat hi 
svmat bSum 
svmat seSum
svmat pSum
svmat loSum 
svmat hiSum  
end 

********************************************************************************
* double difference estimates - split sample 
********************************************************************************

cap program drop coeffSplit
program def coeffSplit
matrix b = J(101,1,.)
matrix se = J(101,1,.)
matrix p = J(101,1,.)
matrix lo = J(101,1,.)
matrix hi = J(101,1,.)
matrix et = J(101,1,.)

local j = 1
forval i=50(-1)2{
	lincom 0.5*( (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) - (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) )
	
	mat b_F`i' = (r(estimate))
	mat se_F`i' = (r(se))
	mat p_F`i' = (r(p))
	mat lo_F`i' = (r(lb))
	mat hi_F`i' = (r(ub))
	
	matrix b[`j',1] =b_F`i'
	matrix se[`j',1] =se_F`i'
	matrix p[`j',1] =p_F`i'
	matrix lo[`j',1] =lo_F`i'
	matrix hi[`j',1] =hi_F`i'
	mat et[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix b[50,1] =0
matrix se[50,1] =0
matrix p[50,1] =0
matrix lo[50,1] =0
matrix hi[50,1] =0
matrix et[50,1] =-1

local j = 51
forval i=0(1)50{
	lincom 0.5*( (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) - (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh) )
	
	mat b_L`i' = (r(estimate))
	mat se_L`i' = (r(se))
	mat p_L`i' = (r(p))
	mat lo_L`i' = (r(lb))
	mat hi_L`i' = (r(ub))
	
	matrix b[`j',1] =b_L`i'
	matrix se[`j',1] =se_L`i'
	matrix p[`j',1] =p_L`i'
	matrix lo[`j',1] =lo_L`i'
	matrix hi[`j',1] =hi_L`i'
	mat et[`j',1] = `i'
	local j = `j' + 1

}

cap drop b1 et1 lo1 hi1 p1	se1
svmat b 
svmat se
svmat p
svmat et 
svmat lo 
svmat hi 
end 

********************************************************************************
* single  difference estimates 
********************************************************************************

cap program drop coeff1
program def coeff1

* LOW TO HIGH 
matrix bL = J(121,1,.)
matrix seL = J(121,1,.)
matrix pL = J(121,1,.)
matrix loL = J(121,1,.)
matrix hiL = J(121,1,.)
matrix etL = J(121,1,.)

local j = 1
forval i=60(-1)2{
	lincom  (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) 
	
	mat bL_F`i' = (r(estimate))
	mat seL_F`i' = (r(se))
	mat pL_F`i' = (r(p))
	mat loL_F`i' = (r(lb))
	mat hiL_F`i' = (r(ub))
	
	matrix bL[`j',1] =bL_F`i'
	matrix seL[`j',1] =seL_F`i'
	matrix pL[`j',1] =pL_F`i'
	matrix loL[`j',1] =loL_F`i'
	matrix hiL[`j',1] =hiL_F`i'
	mat etL[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix bL[60,1] =0
matrix seL[60,1] =0
matrix pL[60,1] =0
matrix loL[60,1] =0
matrix hiL[60,1] =0
matrix etL[60,1] =-1

local j = 61
forval i=0(1)60{
	lincom  (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) 
	
	mat bL_L`i' = (r(estimate))
	mat seL_L`i' = (r(se))
	mat pL_L`i' = (r(p))
	mat loL_L`i' = (r(lb))
	mat hiL_L`i' = (r(ub))
	
	matrix bL[`j',1] =bL_L`i'
	matrix seL[`j',1] =seL_L`i'
	matrix pL[`j',1] =pL_L`i'
	matrix loL[`j',1] =loL_L`i'
	matrix hiL[`j',1] =hiL_L`i'
	mat etL[`j',1] = `i'
	local j = `j' + 1
}

cap drop bL1 etL1 loL1 hiL1 pL1	seL1
svmat bL 
svmat seL
svmat pL
svmat etL 
svmat loL 
svmat hiL 

	* HIGH TO LOW 
matrix bH = J(121,1,.)
matrix seH = J(121,1,.)
matrix pH = J(121,1,.)
matrix loH = J(121,1,.)
matrix hiH = J(121,1,.)
matrix etH = J(121,1,.)

local j = 1
forval i=60(-1)2{
	lincom  (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) 
	
	mat bH_F`i' = (r(estimate))
	mat seH_F`i' = (r(se))
	mat pH_F`i' = (r(p))
	mat loH_F`i' = (r(lb))
	mat hiH_F`i' = (r(ub))
	
	matrix bH[`j',1] =bH_F`i'
	matrix seH[`j',1] =seH_F`i'
	matrix pH[`j',1] =pH_F`i'
	matrix loH[`j',1] =loH_F`i'
	matrix hiH[`j',1] =hiH_F`i'
	mat etH[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix bH[60,1] =0
matrix seH[60,1] =0
matrix pH[60,1] =0
matrix loH[60,1] =0
matrix hiH[60,1] =0
matrix etH[60,1] =-1

local j = 61
forval i=0(1)60{
	lincom  (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh)  
	
	mat bH_L`i' = (r(estimate))
	mat seH_L`i' = (r(se))
	mat pH_L`i' = (r(p))
	mat loH_L`i' = (r(lb))
	mat hiH_L`i' = (r(ub))
	
	matrix bH[`j',1] =bH_L`i'
	matrix seH[`j',1] =seH_L`i'
	matrix pH[`j',1] =pH_L`i'
	matrix loH[`j',1] =loH_L`i'
	matrix hiH[`j',1] =hiH_L`i'
	mat etH[`j',1] = `i'
	local j = `j' + 1

}

cap drop bH1 etH1 loH1 hiH1 pH1	seH1
svmat bH 
svmat seH
svmat pH
svmat etH 
svmat loH 
svmat hiH 
end 

********************************************************************************
* single  difference estimates 
********************************************************************************

cap program drop coeffProd1
program def coeffProd1

* LOW TO HIGH 
matrix bL = J(41,1,.)
matrix seL = J(41,1,.)
matrix pL = J(41,1,.)
matrix loL = J(41,1,.)
matrix hiL = J(41,1,.)
matrix etL = J(41,1,.)

local j = 1
forval i=20(-1)2{
	lincom  (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) 
	
	mat bL_F`i' = (r(estimate))
	mat seL_F`i' = (r(se))
	mat pL_F`i' = (r(p))
	mat loL_F`i' = (r(lb))
	mat hiL_F`i' = (r(ub))
	
	matrix bL[`j',1] =bL_F`i'
	matrix seL[`j',1] =seL_F`i'
	matrix pL[`j',1] =pL_F`i'
	matrix loL[`j',1] =loL_F`i'
	matrix hiL[`j',1] =hiL_F`i'
	mat etL[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix bL[20,1] =0
matrix seL[20,1] =0
matrix pL[20,1] =0
matrix loL[20,1] =0
matrix hiL[20,1] =0
matrix etL[20,1] =-1

local j = 21
forval i=0(1)20{
	lincom  (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) 
	
	mat bL_L`i' = (r(estimate))
	mat seL_L`i' = (r(se))
	mat pL_L`i' = (r(p))
	mat loL_L`i' = (r(lb))
	mat hiL_L`i' = (r(ub))
	
	matrix bL[`j',1] =bL_L`i'
	matrix seL[`j',1] =seL_L`i'
	matrix pL[`j',1] =pL_L`i'
	matrix loL[`j',1] =loL_L`i'
	matrix hiL[`j',1] =hiL_L`i'
	mat etL[`j',1] = `i'
	local j = `j' + 1
}

cap drop bL1 etL1 loL1 hiL1 pL1	seL1
svmat bL 
svmat seL
svmat pL
svmat etL 
svmat loL 
svmat hiL 

	* HIGH TO LOW 
matrix bH = J(41,1,.)
matrix seH = J(41,1,.)
matrix pH = J(41,1,.)
matrix loH = J(41,1,.)
matrix hiH = J(41,1,.)
matrix etH = J(41,1,.)

local j = 1
forval i=20(-1)2{
	lincom  (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) 
	
	mat bH_F`i' = (r(estimate))
	mat seH_F`i' = (r(se))
	mat pH_F`i' = (r(p))
	mat loH_F`i' = (r(lb))
	mat hiH_F`i' = (r(ub))
	
	matrix bH[`j',1] =bH_F`i'
	matrix seH[`j',1] =seH_F`i'
	matrix pH[`j',1] =pH_F`i'
	matrix loH[`j',1] =loH_F`i'
	matrix hiH[`j',1] =hiH_F`i'
	mat etH[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix bH[20,1] =0
matrix seH[20,1] =0
matrix pH[20,1] =0
matrix loH[20,1] =0
matrix hiH[20,1] =0
matrix etH[20,1] =-1

local j = 21
forval i=0(1)20{
	lincom  (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh)  
	
	mat bH_L`i' = (r(estimate))
	mat seH_L`i' = (r(se))
	mat pH_L`i' = (r(p))
	mat loH_L`i' = (r(lb))
	mat hiH_L`i' = (r(ub))
	
	matrix bH[`j',1] =bH_L`i'
	matrix seH[`j',1] =seH_L`i'
	matrix pH[`j',1] =pH_L`i'
	matrix loH[`j',1] =loH_L`i'
	matrix hiH[`j',1] =hiH_L`i'
	mat etH[`j',1] = `i'
	local j = `j' + 1

}

cap drop bH1 etH1 loH1 hiH1 pH1	seH1
svmat bH 
svmat seH
svmat pH
svmat etH 
svmat loH 
svmat hiH 
end 


********************************************************************************
* single differences - cumulative sum for exit 
********************************************************************************

cap program drop coeff1Sum
program def coeff1Sum

*Low to High

matrix bL = J(121,1,.)
matrix seL = J(121,1,.)
matrix pL = J(121,1,.)
matrix loL = J(121,1,.)
matrix hiL = J(121,1,.)
matrix etL = J(121,1,.)

matrix bLSum = J(121,1,.)
matrix seLSum = J(121,1,.)
matrix pLSum = J(121,1,.)
matrix loLSum = J(121,1,.)
matrix hiLSum = J(121,1,.)

local j = 1
local c = 0

forval i=60(-1)2{
	lincom (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow )
	

	mat bL_F`i' = (r(estimate))
	mat seL_F`i' = (r(se))
	mat pL_F`i' = (r(p))
	mat loL_F`i' = (r(lb))
	mat hiL_F`i' = (r(ub))
	
	matrix bL[`j',1] =bL_F`i'
	matrix seL[`j',1] =seL_F`i'
	matrix pL[`j',1] =pL_F`i'
	matrix loL[`j',1] =loL_F`i'
	matrix hiL[`j',1] =hiL_F`i'
	mat etL[`j',1] = -`i'
	
	matrix bLSum[`j',1] =bL_F`i'
	matrix seLSum[`j',1] =seL_F`i'
	matrix pLSum[`j',1] =pL_F`i'
	matrix loLSum[`j',1] =loL_F`i'
	matrix hiLSum[`j',1] =hiL_F`i'
	
	local j = `j' + 1
}

matrix bL[60,1] =0
matrix seL[60,1] =0
matrix pL[60,1] =0
matrix loL[60,1] =0
matrix hiL[60,1] =0
matrix etL[60,1] =-1

local j = 61
local c = 0
forval i=0(1)60{
	lincom  (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow)
	
	mat bL_L`i' = (r(estimate))
	mat seL_L`i' = (r(se))
	mat pL_L`i' = (r(p))
	mat loL_L`i' = (r(lb))
	mat hiL_L`i' = (r(ub))
	
	matrix bL[`j',1] =bL_L`i'
	matrix seL[`j',1] =seL_L`i'
	matrix pL[`j',1] =pL_L`i'
	matrix loL[`j',1] =loL_L`i'
	matrix hiL[`j',1] =hiL_L`i'
	mat etL[`j',1] = `i'
	
		* Cumulative sum 
		local c   " (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow ) +  `c' "
		lincom "`c'"

	mat bLSum_L`i' = (r(estimate))
	mat seLSum_L`i' = (r(se))
	mat pLSum_L`i' = (r(p))
	mat loLSum_L`i' = (r(lb))
	mat hiLSum_L`i' = (r(ub))
	
	matrix bLSum[`j',1] =bLSum_L`i'
	matrix seLSum[`j',1] =seLSum_L`i'
	matrix pLSum[`j',1] =pLSum_L`i'
	matrix loLSum[`j',1] =loLSum_L`i'
	matrix hiLSum[`j',1] =hiLSum_L`i'
	
	local j = `j' + 1

}

cap drop bL1 etL1 loL1 hiL1 pL1	seL1 bLSum1 loLSum1 hiLSum1 pLSum1	seLSum1
svmat bL 
svmat seL
svmat pL
svmat etL 
svmat loL 
svmat hiL 
svmat bLSum 
svmat seLSum
svmat pLSum
svmat loLSum 
svmat hiLSum 

* HIGH TO LOW 

matrix bH = J(121,1,.)
matrix seH = J(121,1,.)
matrix pH = J(121,1,.)
matrix loH = J(121,1,.)
matrix hiH = J(121,1,.)
matrix etH = J(121,1,.)

matrix bHSum = J(121,1,.)
matrix seHSum = J(121,1,.)
matrix pHSum = J(121,1,.)
matrix loHSum = J(121,1,.)
matrix hiHSum = J(121,1,.)

local j = 1
local c = 0

forval i=60(-1)2{
	lincom (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow )
	

	mat bH_F`i' = (r(estimate))
	mat seH_F`i' = (r(se))
	mat pH_F`i' = (r(p))
	mat loH_F`i' = (r(lb))
	mat hiH_F`i' = (r(ub))
	
	matrix bH[`j',1] =bH_F`i'
	matrix seH[`j',1] =seH_F`i'
	matrix pH[`j',1] =pH_F`i'
	matrix loH[`j',1] =loH_F`i'
	matrix hiH[`j',1] =hiH_F`i'
	mat etH[`j',1] = -`i'
	
	matrix bHSum[`j',1] =bH_F`i'
	matrix seHSum[`j',1] =seH_F`i'
	matrix pHSum[`j',1] =pH_F`i'
	matrix loHSum[`j',1] =loH_F`i'
	matrix hiHSum[`j',1] =hiH_F`i'
	
	local j = `j' + 1
}

matrix bH[60,1] =0
matrix seH[60,1] =0
matrix pH[60,1] =0
matrix loH[60,1] =0
matrix hiH[60,1] =0
matrix etH[60,1] =-1

local j = 61
local c = 0
forval i=0(1)60{
	lincom  (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow)
	
	mat bH_L`i' = (r(estimate))
	mat seH_L`i' = (r(se))
	mat pH_L`i' = (r(p))
	mat loH_L`i' = (r(lb))
	mat hiH_L`i' = (r(ub))
	
	matrix bH[`j',1] =bH_L`i'
	matrix seH[`j',1] =seH_L`i'
	matrix pH[`j',1] =pH_L`i'
	matrix loH[`j',1] =loH_L`i'
	matrix hiH[`j',1] =hiH_L`i'
	mat etH[`j',1] = `i'
	
		* Cumulative sum 
		local c   " (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow ) +  `c' "
		lincom "`c'"

	mat bHSum_L`i' = (r(estimate))
	mat seHSum_L`i' = (r(se))
	mat pHSum_L`i' = (r(p))
	mat loHSum_L`i' = (r(lb))
	mat hiHSum_L`i' = (r(ub))
	
	matrix bHSum[`j',1] =bHSum_L`i'
	matrix seHSum[`j',1] =seHSum_L`i'
	matrix pHSum[`j',1] =pHSum_L`i'
	matrix loHSum[`j',1] =loHSum_L`i'
	matrix hiHSum[`j',1] =hiHSum_L`i'
	
	local j = `j' + 1

}

cap drop bH1 etH1 loH1 hiH1 pH1	seH1 bHSum1 loHSum1 hiHSum1 pHSum1	seHSum1
svmat bH 
svmat seH
svmat pH
svmat etH 
svmat loH 
svmat hiH 
svmat bHSum 
svmat seHSum
svmat pHSum
svmat loHSum 
svmat hiHSum



end 


********************************************************************************
* single differences - cumulative sum for exit 
********************************************************************************

cap program drop coeffSplit1
program def coeffSplit1

* LOW TO HIGH 
matrix bL = J(101,1,.)
matrix seL = J(101,1,.)
matrix pL = J(101,1,.)
matrix loL = J(101,1,.)
matrix hiL = J(101,1,.)
matrix etL = J(101,1,.)

local j = 1
forval i=50(-1)2{
	lincom  (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) 
	
	mat bL_F`i' = (r(estimate))
	mat seL_F`i' = (r(se))
	mat pL_F`i' = (r(p))
	mat loL_F`i' = (r(lb))
	mat hiL_F`i' = (r(ub))
	
	matrix bL[`j',1] =bL_F`i'
	matrix seL[`j',1] =seL_F`i'
	matrix pL[`j',1] =pL_F`i'
	matrix loL[`j',1] =loL_F`i'
	matrix hiL[`j',1] =hiL_F`i'
	mat etL[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix bL[50,1] =0
matrix seL[50,1] =0
matrix pL[50,1] =0
matrix loL[50,1] =0
matrix hiL[50,1] =0
matrix etL[50,1] =-1

local j = 51
forval i=0(1)50{
	lincom  (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) 
	
	mat bL_L`i' = (r(estimate))
	mat seL_L`i' = (r(se))
	mat pL_L`i' = (r(p))
	mat loL_L`i' = (r(lb))
	mat hiL_L`i' = (r(ub))
	
	matrix bL[`j',1] =bL_L`i'
	matrix seL[`j',1] =seL_L`i'
	matrix pL[`j',1] =pL_L`i'
	matrix loL[`j',1] =loL_L`i'
	matrix hiL[`j',1] =hiL_L`i'
	mat etL[`j',1] = `i'
	local j = `j' + 1
}

cap drop bL1 etL1 loL1 hiL1 pL1	seL1
svmat bL 
svmat seL
svmat pL
svmat etL 
svmat loL 
svmat hiL 

	* HIGH TO LOW 
matrix bH = J(101,1,.)
matrix seH = J(101,1,.)
matrix pH = J(101,1,.)
matrix loH = J(101,1,.)
matrix hiH = J(101,1,.)
matrix etH = J(101,1,.)

local j = 1
forval i=50(-1)2{
	lincom  (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) 
	
	mat bH_F`i' = (r(estimate))
	mat seH_F`i' = (r(se))
	mat pH_F`i' = (r(p))
	mat loH_F`i' = (r(lb))
	mat hiH_F`i' = (r(ub))
	
	matrix bH[`j',1] =bH_F`i'
	matrix seH[`j',1] =seH_F`i'
	matrix pH[`j',1] =pH_F`i'
	matrix loH[`j',1] =loH_F`i'
	matrix hiH[`j',1] =hiH_F`i'
	mat etH[`j',1] = -`i'
	
	local j = `j' + 1
}

matrix bH[50,1] =0
matrix seH[50,1] =0
matrix pH[50,1] =0
matrix loH[50,1] =0
matrix hiH[50,1] =0
matrix etH[50,1] =-1

local j = 51
forval i=0(1)50{
	lincom  (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh)  
	
	mat bH_L`i' = (r(estimate))
	mat seH_L`i' = (r(se))
	mat pH_L`i' = (r(p))
	mat loH_L`i' = (r(lb))
	mat hiH_L`i' = (r(ub))
	
	matrix bH[`j',1] =bH_L`i'
	matrix seH[`j',1] =seH_L`i'
	matrix pH[`j',1] =pH_L`i'
	matrix loH[`j',1] =loH_L`i'
	matrix hiH[`j',1] =hiH_L`i'
	mat etH[`j',1] = `i'
	local j = `j' + 1

}

cap drop bH1 etH1 loH1 hiH1 pH1	seH1
svmat bH 
svmat seH
svmat pH
svmat etH 
svmat loH 
svmat hiH 
end 

********************************************************************************
*double differences and average monthly estimates into quarterly  
********************************************************************************

cap program drop coeffQ
program def coeffQ
matrix bQ = J(41,1,.)
matrix seQ = J(41,1,.)
matrix pQ = J(41,1,.)
matrix loQ = J(41,1,.)
matrix hiQ = J(41,1,.)
matrix etQ = J(41,1,.)

local j = 1
forval i=60(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom (( (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) - (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) ) + ///
	( (F`k'_ChangeAgeMLowHigh - F`k'_ChangeAgeMLowLow) - (F`k'_ChangeAgeMHighLow - F`k'_ChangeAgeMHighHigh) ) + ///
	( (F`h'_ChangeAgeMLowHigh - F`h'_ChangeAgeMLowLow) - (F`h'_ChangeAgeMHighLow - F`h'_ChangeAgeMHighHigh) ) )/6
	
	mat bQ_F`i' = (r(estimate))
	mat seQ_F`i' = (r(se))
	mat pQ_F`i' = (r(p))
	mat loQ_F`i' = (r(lb))
	mat hiQ_F`i' = (r(ub))
	
	matrix bQ[`j',1] =bQ_F`i'
	matrix seQ[`j',1] =seQ_F`i'
	matrix pQ[`j',1] =pQ_F`i'
	matrix loQ[`j',1] =loQ_F`i'
	matrix hiQ[`j',1] =hiQ_F`i'
	mat etQ[`j',1] =  - 21 + `j'
	
	local j = `j' + 1
}

matrix bQ[20,1] =0
matrix seQ[20,1] =0
matrix pQ[20,1] =0
matrix loQ[20,1] =0
matrix hiQ[20,1] =0
matrix etQ[20,1] =-1

local j = 21
forval i=0(3)60{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) - (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh) ) + ///
	( (L`k'_ChangeAgeMLowHigh - L`k'_ChangeAgeMLowLow) - (L`k'_ChangeAgeMHighLow - L`k'_ChangeAgeMHighHigh) ) + ///
	( (L`h'_ChangeAgeMLowHigh - L`h'_ChangeAgeMLowLow) - (L`h'_ChangeAgeMHighLow - L`h'_ChangeAgeMHighHigh) )) / 6
	
	mat bQ_L`i' = (r(estimate))
	mat seQ_L`i' = (r(se))
	mat pQ_L`i' = (r(p))
	mat loQ_L`i' = (r(lb))
	mat hiQ_L`i' = (r(ub))
	
	matrix bQ[`j',1] =bQ_L`i'
	matrix seQ[`j',1] =seQ_L`i'
	matrix pQ[`j',1] =pQ_L`i'
	matrix loQ[`j',1] =loQ_L`i'
	matrix hiQ[`j',1] =hiQ_L`i'
	mat etQ[`j',1] = `j' - 21
	local j = `j' + 1

}

cap drop bQ1 etQ1 loQ1 hiQ1 pQ1	seQ1
svmat bQ 
svmat seQ
svmat pQ
svmat etQ 
svmat loQ 
svmat hiQ
end


********************************************************************************
* single differences and average monthly estimates into quarterly  
********************************************************************************

cap program drop coeffQ1
program def coeffQ1

* LOW TO HIGH 
matrix bQL = J(41,1,.)
matrix seQL = J(41,1,.)
matrix pQL = J(41,1,.)
matrix loQL = J(41,1,.)
matrix hiQL = J(41,1,.)
matrix etQL = J(41,1,.)

local j = 1
forval i=60(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom ( F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow  ) + ///
	( F`k'_ChangeAgeMLowHigh - F`k'_ChangeAgeMLowLow  ) + ///
	( F`h'_ChangeAgeMLowHigh - F`h'_ChangeAgeMLowLow  ) ) /3
	
	mat bQL_F`i' = (r(estimate))
	mat seQL_F`i' = (r(se))
	mat pQL_F`i' = (r(p))
	mat loQL_F`i' = (r(lb))
	mat hiQL_F`i' = (r(ub))
	
	matrix bQL[`j',1] =bQL_F`i'
	matrix seQL[`j',1] =seQL_F`i'
	matrix pQL[`j',1] =pQL_F`i'
	matrix loQL[`j',1] =loQL_F`i'
	matrix hiQL[`j',1] =hiQL_F`i'
	mat etQL[`j',1] =  - 21 + `j'
	
	local j = `j' + 1
}

matrix bQL[20,1] =0
matrix seQL[20,1] =0
matrix pQL[20,1] =0
matrix loQL[20,1] =0
matrix hiQL[20,1] =0
matrix etQL[20,1] =-1

local j = 21
forval i=0(3)60{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow  ) + ///
	( L`k'_ChangeAgeMLowHigh - L`k'_ChangeAgeMLowLow  ) + ///
	( L`h'_ChangeAgeMLowHigh - L`h'_ChangeAgeMLowLow  )) / 3
	
	mat bQL_L`i' = (r(estimate))
	mat seQL_L`i' = (r(se))
	mat pQL_L`i' = (r(p))
	mat loQL_L`i' = (r(lb))
	mat hiQL_L`i' = (r(ub))
	
	matrix bQL[`j',1] =bQL_L`i'
	matrix seQL[`j',1] =seQL_L`i'
	matrix pQL[`j',1] =pQL_L`i'
	matrix loQL[`j',1] =loQL_L`i'
	matrix hiQL[`j',1] =hiQL_L`i'
	mat etQL[`j',1] = `j' - 21
	local j = `j' + 1

}

cap drop bQL1 etQL1 loQL1 hiQL1 pQL1	seQL1
svmat bQL 
svmat seQL
svmat pQL
svmat etQL 
svmat loQL 
svmat hiQL

*HIGH TO LOW 

matrix bQH = J(41,1,.)
matrix seQH = J(41,1,.)
matrix pQH = J(41,1,.)
matrix loQH = J(41,1,.)
matrix hiQH = J(41,1,.)
matrix etQH = J(41,1,.)

local j = 1
forval i=60(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom ( F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh  ) + ///
	( F`k'_ChangeAgeMHighLow - F`k'_ChangeAgeMHighHigh  ) + ///
	( F`h'_ChangeAgeMHighLow - F`h'_ChangeAgeMHighHigh  ) ) /3
	
	mat bQH_F`i' = (r(estimate))
	mat seQH_F`i' = (r(se))
	mat pQH_F`i' = (r(p))
	mat loQH_F`i' = (r(lb))
	mat hiQH_F`i' = (r(ub))
	
	matrix bQH[`j',1] =bQH_F`i'
	matrix seQH[`j',1] =seQH_F`i'
	matrix pQH[`j',1] =pQH_F`i'
	matrix loQH[`j',1] =loQH_F`i'
	matrix hiQH[`j',1] =hiQH_F`i'
	mat etQH[`j',1] =  - 21 + `j'
	
	local j = `j' + 1
}

matrix bQH[20,1] =0
matrix seQH[20,1] =0
matrix pQH[20,1] =0
matrix loQH[20,1] =0
matrix hiQH[20,1] =0
matrix etQH[20,1] =-1

local j = 21
forval i=0(3)60{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh  ) + ///
	( L`k'_ChangeAgeMHighLow - L`k'_ChangeAgeMHighHigh  ) + ///
	( L`h'_ChangeAgeMHighLow - L`h'_ChangeAgeMHighHigh  )) / 3
	
	mat bQH_L`i' = (r(estimate))
	mat seQH_L`i' = (r(se))
	mat pQH_L`i' = (r(p))
	mat loQH_L`i' = (r(lb))
	mat hiQH_L`i' = (r(ub))
	
	matrix bQH[`j',1] =bQH_L`i'
	matrix seQH[`j',1] =seH_L`i'
	matrix pQH[`j',1] =pQH_L`i'
	matrix loQH[`j',1] =loQH_L`i'
	matrix hiQH[`j',1] =hiQH_L`i'
	mat etQH[`j',1] = `j' - 21
	local j = `j' + 1

}


cap drop bQH1 etQH1 loQH1 hiQH1 pQH1	seQH1
svmat bQH 
svmat seQH
svmat pQH
svmat etQH 
svmat loQH 
svmat hiQH
end


