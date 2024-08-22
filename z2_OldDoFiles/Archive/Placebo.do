********************************************************************************
* PROGRAM TO COMPUTE Pre-trends p-value
* TEST FOR PARALLEL TRENDS ASSUMPTION
* placeboF, c(20)
* p-value of a joint test that all the placebos requested are equal to 0
********************************************************************************

cap program drop placeboF
program def placeboF

syntax , c(real) 

local d = (`c' - 1)/2  // half window

* single coeff.
foreach v in ELH ELL EHH EHL{
	local placebosF`v' F2`v'

forval i=`d'(-1)3{
	local placebosF`v'  "`placebosF`v'' + F`i'`v'"
} 
lincom `placebosF`v''
cap drop FTestb`v'  FTestse`v'  FTestp`v'
gen FTestb`v' = r(estimate)
gen FTestse`v' = r(se)
gen FTestp`v' = r(p)
}

* single differences ELH-ELL and EHL - EHH
foreach v in EL EH {
	local placebosF`v' "F2`v'H - F2`v'L"

forval i=`d'(-1)3{
	
	local placebosF`v'  "`placebosF`v'' + F`i'`v'H - F`i'`v'L"
} 
lincom `placebosF`v''
cap drop FTestb`v'  FTestse`v'  FTestp`v'
gen FTestb`v' = r(estimate)
gen FTestse`v' = r(se)
gen FTestp`v' = r(p)
}

end 


