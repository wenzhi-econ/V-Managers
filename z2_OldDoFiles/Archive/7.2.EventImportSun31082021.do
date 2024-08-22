********************************************************************************
* IMPORT DATASET - only consider first event 
********************************************************************************

use "$Managersdta/AllSnapshotMCultureMType2015.dta", clear 

* select ONLY relevant variables 
*keep IDlse YearMonth IDlseMHR Ei EL EH ELH EHH ELL EHL CountryYM Tenure Female AgeBand WL Func EarlyAgeM EarlyAge2015M TenureM FemaleM AgeBandM WLM FuncM ChangeMR ChangeAgeMLowHigh ChangeAgeMHighLow  ChangeAgeMHighHigh ChangeAgeMLowLow LogPayBonus  LeaverPerm  TransferInternalC TransferInternalSJC TransferInternalSJSameMC TransferInternalSJDiffMC ChangeSalaryGradeC  PromWLC insample insample1
*keep if insample==1 // 1mill 

********************************************************************************
* PROGRAMS 
********************************************************************************

********************************************************************************
* double difference estimates 
********************************************************************************

cap program drop coeff
program def coeff
matrix b = J(101,1,.)
matrix se = J(101,1,.)
matrix p = J(101,1,.)
matrix lo = J(101,1,.)
matrix hi = J(101,1,.)
matrix et = J(101,1,.)

local j = 1
forval i=50(-1)2{
	lincom 0.5*( (F`i'ELH - F`i'ELL) - (F`i'EHL - F`i'EHH) )
	
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
	lincom 0.5*( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) )
	
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
* double difference estimates 
********************************************************************************

cap program drop coeffExit
program def coeffExit
matrix b = J(101,1,.)
matrix se = J(101,1,.)
matrix p = J(101,1,.)
matrix lo = J(101,1,.)
matrix hi = J(101,1,.)
matrix et = J(101,1,.)

matrix b[51,1] =0
matrix se[51,1] =0
matrix p[51,1] =0
matrix lo[51,1] =0
matrix hi[51,1] =0
matrix et[51,1] =0

local j = 52
forval i=1(1)50{
	lincom 0.5*( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) )
	
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
matrix b = J(101,1,.)
matrix se = J(101,1,.)
matrix p = J(101,1,.)
matrix lo = J(101,1,.)
matrix hi = J(101,1,.)
matrix et = J(101,1,.)

matrix bSum = J(101,1,.)
matrix seSum = J(101,1,.)
matrix pSum = J(101,1,.)
matrix loSum = J(101,1,.)
matrix hiSum = J(101,1,.)

local c = 0
local j = 1
forval i=50(-1)2{
	lincom 0.5*( (F`i'ELH - F`i'ELL) - (F`i'EHL - F`i'EHH) )
	

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

matrix b[50,1] =0
matrix se[50,1] =0
matrix p[50,1] =0
matrix lo[50,1] =0
matrix hi[50,1] =0
matrix et[50,1] =-1

local j = 51
forval i=0(1)50{
	lincom 0.5*( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) )
	
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
		local c   "0.5*( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) ) +  `c' "
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
* single  difference estimates 
********************************************************************************

cap program drop coeff1
program def coeff1

* LOW TO HIGH 
matrix bL = J(101,1,.)
matrix seL = J(101,1,.)
matrix pL = J(101,1,.)
matrix loL = J(101,1,.)
matrix hiL = J(101,1,.)
matrix etL = J(101,1,.)

local j = 1
forval i=50(-1)2{
	lincom  (F`i'ELH - F`i'ELL) 
	
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
	lincom  (L`i'ELH - L`i'ELL) 
	
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
	lincom  (F`i'EHL - F`i'EHH) 
	
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
	lincom  (L`i'EHL - L`i'EHH)  
	
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
* single  difference estimates - exit 
********************************************************************************

cap program drop coeffExit1
program def coeffExit1

* LOW TO HIGH 
matrix bL = J(101,1,.)
matrix seL = J(101,1,.)
matrix pL = J(101,1,.)
matrix loL = J(101,1,.)
matrix hiL = J(101,1,.)
matrix etL = J(101,1,.)

matrix bL[51,1] =0
matrix seL[51,1] =0
matrix pL[51,1] =0
matrix loL[51,1] =0
matrix hiL[51,1] =0
matrix etL[51,1] =0

local j = 52
forval i=1(1)50{
	lincom  (L`i'ELH - L`i'ELL) 
	
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

matrix bH[51,1] =0
matrix seH[51,1] =0
matrix pH[51,1] =0
matrix loH[51,1] =0
matrix hiH[51,1] =0
matrix etH[51,1] =0

local j = 52
forval i=1(1)50{
	lincom  (L`i'EHL - L`i'EHH)  
	
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
* cumulative sum for exit 
********************************************************************************

cap program drop coeff1Sum
program def coeff1Sum

*Low to High

matrix bL = J(101,1,.)
matrix seL = J(101,1,.)
matrix pL = J(101,1,.)
matrix loL = J(101,1,.)
matrix hiL = J(101,1,.)
matrix etL = J(101,1,.)

matrix bLSum = J(101,1,.)
matrix seLSum = J(101,1,.)
matrix pLSum = J(101,1,.)
matrix loLSum = J(101,1,.)
matrix hiLSum = J(101,1,.)

local j = 1
local c = 0

forval i=50(-1)2{
	lincom (F`i'ELH - F`i'ELL )
	

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

matrix bL[50,1] =0
matrix seL[50,1] =0
matrix pL[50,1] =0
matrix loL[50,1] =0
matrix hiL[50,1] =0
matrix etL[50,1] =-1

local j = 51
local c = 0
forval i=0(1)50{
	lincom  (L`i'ELH - L`i'ELL)
	
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
		local c   " (L`i'ELH - L`i'ELL ) +  `c' "
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

matrix bH = J(101,1,.)
matrix seH = J(101,1,.)
matrix pH = J(101,1,.)
matrix loH = J(101,1,.)
matrix hiH = J(101,1,.)
matrix etH = J(101,1,.)

matrix bHSum = J(101,1,.)
matrix seHSum = J(101,1,.)
matrix pHSum = J(101,1,.)
matrix loHSum = J(101,1,.)
matrix hiHSum = J(101,1,.)

local j = 1
local c = 0

forval i=50(-1)2{
	lincom (F`i'ELH - F`i'ELL )
	

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

matrix bH[50,1] =0
matrix seH[50,1] =0
matrix pH[50,1] =0
matrix loH[50,1] =0
matrix hiH[50,1] =0
matrix etH[50,1] =-1

local j = 51
local c = 0
forval i=0(1)50{
	lincom  (L`i'ELH - L`i'ELL)
	
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
		local c   " (L`i'ELH - L`i'ELL ) +  `c' "
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
forval i=50(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom (( (F`i'ELH - F`i'ELL) - (F`i'EHL - F`i'EHH) ) + ///
	( (F`k'ELH - F`k'ELL) - (F`k'EHL - F`k'EHH) ) + ///
	( (F`h'ELH - F`h'ELL) - (F`h'EHL - F`h'EHH) ) )/6
	
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
forval i=0(3)50{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) ) + ///
	( (L`k'ELH - L`k'ELL) - (L`k'EHL - L`k'EHH) ) + ///
	( (L`h'ELH - L`h'ELL) - (L`h'EHL - L`h'EHH) )) / 6
	
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
forval i=50(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom ( F`i'ELH - F`i'ELL  ) + ///
	( F`k'ELH - F`k'ELL  ) + ///
	( F`h'ELH - F`h'ELL  ) ) /3
	
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
forval i=0(3)50{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'ELH - L`i'ELL  ) + ///
	( L`k'ELH - L`k'ELL  ) + ///
	( L`h'ELH - L`h'ELL  )) / 3
	
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
forval i=50(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom ( F`i'EHL - F`i'EHH  ) + ///
	( F`k'EHL - F`k'EHH  ) + ///
	( F`h'EHL - F`h'EHH  ) ) /3
	
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
forval i=0(3)50{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'EHL - L`i'EHH  ) + ///
	( L`k'EHL - L`k'EHH  ) + ///
	( L`h'EHL - L`h'EHH  )) / 3
	
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


