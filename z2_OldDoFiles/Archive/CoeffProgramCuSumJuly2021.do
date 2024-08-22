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

matrix b[60,1] =0
matrix se[60,1] =0
matrix p[60,1] =0
matrix lo[60,1] =0
matrix hi[60,1] =0
matrix et[60,1] =-1

local j = 61
forval i=0(1)60{
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
* single differences - cumulative sum for exit 
********************************************************************************

cap program drop coeff1Sum
program def coeff1Sum

*Low to High

matrix bL = J(`c',1,.)
matrix seL = J(`c',1,.)
matrix pL = J(`c',1,.)
matrix loL = J(`c',1,.)
matrix hiL = J(`c',1,.)
matrix etL = J(`c',1,.)

matrix bLSum = J(`c',1,.)
matrix seLSum = J(`c',1,.)
matrix pLSum = J(`c',1,.)
matrix loLSum = J(`c',1,.)
matrix hiLSum = J(`c',1,.)

local j = 1
local c = 0

forval i=`d'(-1)2{
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

matrix bL[`d',1] =0
matrix seL[`d',1] =0
matrix pL[`d',1] =0
matrix loL[`d',1] =0
matrix hiL[`d',1] =0
matrix etL[`d',1] =-1

local j = `d' + 1
local c = 0
forval i=0(1)`d'{
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

matrix bH = J(`c',1,.)
matrix seH = J(`c',1,.)
matrix pH = J(`c',1,.)
matrix loH = J(`c',1,.)
matrix hiH = J(`c',1,.)
matrix etH = J(`c',1,.)

matrix bHSum = J(`c',1,.)
matrix seHSum = J(`c',1,.)
matrix pHSum = J(`c',1,.)
matrix loHSum = J(`c',1,.)
matrix hiHSum = J(`c',1,.)

local j = 1
local c = 0

forval i=`d'(-1)2{
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

matrix bH[`d',1] =0
matrix seH[`d',1] =0
matrix pH[`d',1] =0
matrix loH[`d',1] =0
matrix hiH[`d',1] =0
matrix etH[`d',1] =-1

local j = `d' + 1
local c = 0
forval i=0(1)`d'{
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
