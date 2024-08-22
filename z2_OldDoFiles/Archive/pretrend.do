
********************************************************************************
* PROGRAMS for coefplots 
********************************************************************************

********************************************************************************
* JOINT PRE TRENDS TEST PVALUE & OUTCOME MEAN 
********************************************************************************

cap program drop pretrendDeltaM
program def pretrendDeltaM

syntax , c(real) y(string)
local d = (`c' - 1)/2  // half window

local t = `d'-1
local joint "F`d'EiDeltaM" 
forval i=`t'(-1)2{
	local joint "`joint' + F`i'EiDeltaM"
	di "`i'"
}


cap drop joint
lincom `joint'
gen joint =  (r(p))


cap drop ymeanF1
su `y' if KEi == -1
gen ymeanF1 = r(mean) 
end 


 
