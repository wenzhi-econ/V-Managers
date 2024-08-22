********************************************************************************
* PROGRAMS for coefplots 
********************************************************************************

********************************************************************************
* JOINT PRE TRENDS TEST PVALUE & OUTCOME MEAN 
********************************************************************************

cap program drop pretrendDelta
program def pretrendDelta

syntax , c(real) y(string)
local d = (`c' - 1)/2  // half window

local t = `d'-1
local joint "F`d'EiDelta" 
forval i=`t'(-1)2{
	local joint "`joint' + F`i'EiDelta"
	di "`i'"
}


cap drop joint
lincom `joint'
gen joint =  (r(p))


cap drop ymeanF1
su `y' if KEi == -1
gen ymeanF1 = r(mean) 
end 


cap program drop pretrendDeltaW
program def pretrendDeltaW

syntax , c(real) y(string)

local t = `c'-1
local joint "F`c'EiDelta" 
forval i=`t'(-1)2{
	local joint "`joint' + F`i'EiDelta"
	di "`i'"
}


cap drop joint
lincom `joint'
gen joint =  (r(p))


cap drop ymeanF1
su `y' if KEi == -1
gen ymeanF1 = r(mean) 
end 

cap program drop pretrendDeltaHET
program def pretrendDeltaHET

syntax , c(real) y(string) het(string)
local d = (`c' - 1)/2  // half window

local t = `d'-1
local joint "F`d'EiDelta`het'" 
forval i=`t'(-1)2{
	local joint "`joint' + F`i'EiDelta`het'"
	di "`i'"
}


cap drop joint
lincom `joint'
gen joint =  (r(p))


cap drop ymeanF1
su `y' if KEi == -1
gen ymeanF1 = r(mean) 
end 

* CUT WINDOW
********************************************************************************

cap program drop pretrendDeltaHETW
program def pretrendDeltaHETW

syntax , c(real) y(string) het(string)

local t = `c'-1

local joint "F`c'EiDelta" 
forval i=`t'(-1)2{
	local joint "`joint' + F`i'EiDelta"
	di "`i'"
}


cap drop joint
lincom `joint'
gen joint =  (r(p))

local jointH "F`c'EiDelta`het'" 
forval i=`t'(-1)2{
	local jointH "`jointH' + F`i'EiDelta`het'"
	di "`i'"
}


cap drop jointH
lincom `jointH'
gen jointH =  (r(p))


cap drop ymeanF1
su `y' if KEi == -1
gen ymeanF1 = r(mean) 
end 

********************************************************************************
* PROGRAM TO QUICK GENERATE SET OF EVENT INDICATORS - ASYMMETRIC 
********************************************************************************

cap program drop eventd
program def eventd

syntax , end(real)  

local LExitLH ""
local LExitHH ""
local LExitLL ""
local LExitHL ""

local LLH ""
local LHH ""
local LLL ""
local LHL ""

foreach var in LL LH HL HH {
forvalues l = 0/`end' {
	
	local L`var' "`L`var'' L`l'E`var'"
	
	if `l' > 0{
	local LExit`var' " `LExit`var'' L`l'E`var'"
	}
else {
}

}


local FLH ""
local FHH ""
local FLL ""
local FHL ""

forvalues l = 2/`end' {
	
	local F`var' "`F`var'' F`l'E`var'"
	
}
global F`var' "`F`var'' endF`var'`end'"
global L`var' "`L`var'' endL`var'`end'"
global LExit`var' "`LExit`var'' endL`var'`end'"
}


end

* CUTTING THE WINDOW 
********************************************************************************

cap program drop eventdW
program def eventdW

syntax , endL(real)  endF(real)

local LExitLH ""
local LExitHH ""
local LExitLL ""
local LExitHL ""

local LLH ""
local LHH ""
local LLL ""
local LHL ""

foreach var in LL LH HL HH {
forvalues l = 0/`endL' {
	
	local L`var' "`L`var'' L`l'E`var'"
	
	if `l' > 0{
	local LExit`var' " `LExit`var'' L`l'E`var'"
	}
else {
}

}


local FLH ""
local FHH ""
local FLL ""
local FHL ""

forvalues l = 2/`endF' {
	
	local F`var' "`F`var'' F`l'E`var'"
	
}
global F`var' "`F`var'' endF`var'`endF'"
global L`var' "`L`var'' endL`var'`endL'"
global LExit`var' "`LExit`var'' endL`var'`endL'"
}


end


********************************************************************************
* PROGRAM TO QUICK GENERATE SET OF EVENT INDICATORS - SYMMETRIC 
********************************************************************************

cap program drop eventdDelta
program def eventdDelta

syntax , end(real)  

local LExit ""
local LExitDelta ""

local L ""
local LDelta ""

foreach var in Ei {
forvalues l = 0/`end' {
	
	local L`var' "`L`var'' L`l'`var'"
	local L`var'Delta "`L`var'Delta' L`l'`var'Delta"

	if `l' > 0{
	local LExit`var' " `LExit`var'' L`l'`var'"
	local LExit`var'Delta " `LExit`var'Delta' L`l'`var'Delta"

	}
else {
}

}

local F ""
local FDelta ""

forvalues l = 2/`end' {
	
	local F`var' "`F`var'' F`l'`var'"
	local F`var'Delta "`F`var'Delta' F`l'`var'Delta"
	
}
global F`var' "`F`var'' endF`var'`end'"
global F`var'Delta "`F`var'Delta' endF`var'`end'Delta"
global L`var' "`L`var'' endL`var'`end'"
global L`var'Delta "`L`var'Delta' endL`var'`end'Delta"
global LExit`var' "`LExit`var'' endL`var'`end'"
global LExit`var'Delta "`LExit`var'Delta' endL`var'`end'Delta"

}
end

cap program drop eventdDeltaHET
program def eventdDeltaHET

syntax , end(real)  het(string)

local LExit`het' ""
local LExitDelta`het' ""

local L ""
local LDelta ""

foreach var in Ei {
forvalues l = 0/`end' {
	
	local L`var'`het' "`L`var'`het'' L`l'`var'`het'"
	local L`var'Delta`het' "`L`var'Delta`het'' L`l'`var'Delta`het'"

	if `l' > 0{
	local LExit`var'`het' " `LExit`var'`het'' L`l'`var'`het'"
	local LExit`var'Delta`het' " `LExit`var'Delta`het'' L`l'`var'Delta`het'"

	}
else {
}

}

local F ""
local FDelta ""

forvalues l = 2/`end' {
	
	local F`var'`het' "`F`var'`het'' F`l'`var'`het'"
	local F`var'Delta`het' "`F`var'Delta`het'' F`l'`var'Delta`het'"
	
}
global F`var'`het' "`F`var'`het'' endF`var'`end'`het'"
global F`var'Delta`het' "`F`var'Delta`het'' endF`var'`end'Delta`het'"
global L`var'`het' "`L`var'`het'' endL`var'`end'`het'"
global L`var'Delta`het' "`L`var'Delta`het'' endL`var'`end'Delta`het'"
global LExit`var'`het' "`LExit`var'`het'' endL`var'`end'`het'"
global LExit`var'Delta`het' "`LExit`var'Delta`het'' endL`var'`end'Delta`het'"

}
end

* CUTTING THE WINDOW 
********************************************************************************

cap program drop eventdDeltaW
program def eventdDeltaW

syntax ,  endL(real)  endF(real)  

local LExit ""
local LExitDelta ""

local L ""
local LDelta ""

foreach var in Ei {
forvalues l = 0/`endL' {
	
	local L`var' "`L`var'' L`l'`var'"
	local L`var'Delta "`L`var'Delta' L`l'`var'Delta"

	if `l' > 0{
	local LExit`var' " `LExit`var'' L`l'`var'"
	local LExit`var'Delta " `LExit`var'Delta' L`l'`var'Delta"

	}
else {
}

}

local F ""
local FDelta ""

forvalues l = 2/`endF' {
	
	local F`var' "`F`var'' F`l'`var'"
	local F`var'Delta "`F`var'Delta' F`l'`var'Delta"
	
}
global F`var' "`F`var'' endF`var'`endF'"
global F`var'Delta "`F`var'Delta' endF`var'`endF'Delta"
global L`var' "`L`var'' endL`var'`endL'"
global L`var'Delta "`L`var'Delta' endL`var'`endL'Delta"
global LExit`var' "`LExit`var'' endL`var'`endL'"
global LExit`var'Delta "`LExit`var'Delta' endL`var'`endL'Delta"

}
end

cap program drop eventdDeltaHETW
program def eventdDeltaHETW

syntax ,  endL(real)  endF(real)  het(string)

local LExit`het' ""
local LExitDelta`het' ""

local L ""
local LDelta ""

foreach var in Ei {
forvalues l = 0/`endL' {
	
	local L`var'`het' "`L`var'`het'' L`l'`var'`het'"
	local L`var'Delta`het' "`L`var'Delta`het'' L`l'`var'Delta`het'"

	if `l' > 0{
	local LExit`var'`het' " `LExit`var'`het'' L`l'`var'`het'"
	local LExit`var'Delta`het' " `LExit`var'Delta`het'' L`l'`var'Delta`het'"

	}
else {
}

}

local F ""
local FDelta ""

forvalues l = 2/`endF' {
	
	local F`var'`het' "`F`var'`het'' F`l'`var'`het'"
	local F`var'Delta`het' "`F`var'Delta`het'' F`l'`var'Delta`het'"
	
}
global F`var'`het' "`F`var'`het'' endF`var'`endF'`het'"
global F`var'Delta`het' "`F`var'Delta`het'' endF`var'`endF'Delta`het'"
global L`var'`het' "`L`var'`het'' endL`var'`endL'`het'"
global L`var'Delta`het' "`L`var'Delta`het'' endL`var'`endL'Delta`het'"
global LExit`var'`het' "`LExit`var'`het'' endL`var'`endL'`het'"
global LExit`var'Delta`het' "`LExit`var'Delta`het'' endL`var'`endL'Delta`het'"

}
end

********************************************************************************
* JOINT PRE TRENDS TEST PVALUE & OUTCOME MEAN 
********************************************************************************

cap program drop pretrend
program def pretrend

syntax , end(real) y(string)

local t = `end'-1
local jointL "F`end'ELH - F`end'ELL" 
local jointH "F`end'EHL - F`end'EHH" 

forval i=`t'(-1)2{
	local jointL "`jointL' + F`i'ELH - F`i'ELL"
	local jointH "`jointH' + F`i'EHL - F`i'EHH"

	di "`i'"
}


cap drop jointL
lincom `jointL'
gen jointL =  (r(p))

cap drop jointH
lincom `jointH'
gen jointH =  (r(p))

end 

cap program drop pretrendDual
program def pretrendDual

syntax , end(real) y(string)

local t = `end'-1
local joint "(F`end'ELH - F`end'ELL) - (F`end'EHL - F`end'EHH)" 

forval i=`t'(-1)2{
	local joint "`joint' + (F`i'ELH - F`i'ELL) - (F`i'EHL - F`i'EHH)"

	di "`i'"
}

cap drop joint
lincom `joint'
gen joint =  (r(p))

end 


cap program drop postDual
program def postDual

syntax , end(real) y(string)

local jointPost "(L`end'ELH - L`end'ELL) - (L`end'EHL - L`end'EHH)" 

forval i=0(1)`end'{
	local jointPost "`jointPost' + (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH)"

	di "`i'"
}

cap drop jointPost
lincom `jointPost'
gen jointPost =  (r(p))

end 


cap program drop postDualDelta
program def postDualDelta

syntax , end(real) y(string)

local jointPost "L`end'EiDelta" 

forval i=0(1)`end'{
	local jointPost "`jointPost' + L`i'EiDelta"

	di "`i'"
}

cap drop jointPost
lincom `jointPost'
gen jointPost =  (r(p))

end 


********************************************************************************
* JOINT PRE TRENDS TEST PVALUE & OUTCOME MEAN (only HL vs HH to speed up estimation)
********************************************************************************

cap program drop pretrendHL
program def pretrendHL

syntax , end(real) y(string)

local t = `end'-1
local jointH "F`end'EHL - F`end'EHH" 

forval i=`t'(-1)2{
	local jointH "`jointH' + F`i'EHL - F`i'EHH"

	di "`i'"
}

cap drop jointH
lincom `jointH'
gen jointH =  (r(p))

end 

********************************************************************************
* COHORT STATIC - PROGRAM FOR STATIC TABLE
********************************************************************************

cap program drop coeffStaticCohort
program def coeffStaticCohort

syntax , y(string)

local j = 1

* LOW LOW
matrix bLL = J(`j',1,.)
matrix seLL = J(`j',1,.)
matrix pLL = J(`j',1,.)
matrix loLL = J(`j',1,.)
matrix hiLL = J(`j',1,.)

lincom (sharesELL2011[`j',1] * ELL_2011 + sharesELL2012[`j',1] * ELL_2012 + sharesELL2013[`j',1] * ELL_2013 + sharesELL2014[`j',1] * ELL_2014 + sharesELL2015[`j',1] * ELL_2015 + sharesELL2016[`j',1] * ELL_2016 + sharesELL2017[`j',1] * ELL_2017 + sharesELL2018[`j',1] * ELL_2018 + sharesELL2019[`j',1] * ELL_2019 + sharesELL2020[`j',1] * ELL_2020)

	mat bLL = (r(estimate))
	mat seLL = (r(se))
	mat pLL = (r(p))
	mat loLL = (r(lb))
	mat hiLL = (r(ub))
	
	matrix bLL[`j',1] =bLL
	matrix seLL[`j',1] =seLL
	matrix pLL[`j',1] =pLL
	matrix loLL[`j',1] =loLL
	matrix hiLL[`j',1] =hiLL
	

* LOW HIGH
matrix bLH = J(`j',1,.)
matrix seLH = J(`j',1,.)
matrix pLH = J(`j',1,.)
matrix loLH = J(`j',1,.)
matrix hiLH = J(`j',1,.)

lincom (sharesELH2011[`j',1] * ELH_2011 + sharesELH2012[`j',1] * ELH_2012 + sharesELH2013[`j',1] * ELH_2013 + sharesELH2014[`j',1] * ELH_2014 + sharesELH2015[`j',1] * ELH_2015 + sharesELH2016[`j',1] * ELH_2016 + sharesELH2017[`j',1] * ELH_2017 + sharesELH2018[`j',1] * ELH_2018 + sharesELH2019[`j',1] * ELH_2019 + sharesELH2020[`j',1] * ELH_2020) 

	mat bLH = (r(estimate))
	mat seLH = (r(se))
	mat pLH= (r(p))
	mat loLH = (r(lb))
	mat hiLH = (r(ub))
	
	matrix bLH[`j',1] =bLH
	matrix seLH[`j',1] =seLH
	matrix pLH[`j',1] =pLH
	matrix loLH[`j',1] =loLH
	matrix hiLH[`j',1] =hiLH
	
* DOUBLE DIFF: LOW TO HIGH 
matrix bL = J(`j',1,.)
matrix seL = J(`j',1,.)
matrix pL = J(`j',1,.)
matrix loL = J(`j',1,.)
matrix hiL = J(`j',1,.)

lincom (sharesELH2011[`j',1] * ELH_2011 + sharesELH2012[`j',1] * ELH_2012 + sharesELH2013[`j',1] * ELH_2013 + sharesELH2014[`j',1] * ELH_2014 + sharesELH2015[`j',1] * ELH_2015 + sharesELH2016[`j',1] * ELH_2016 + sharesELH2017[`j',1] * ELH_2017 + sharesELH2018[`j',1] * ELH_2018 + sharesELH2019[`j',1] * ELH_2019 + sharesELH2020[`j',1] * ELH_2020) - (sharesELL2011[`j',1] * ELL_2011 + sharesELL2012[`j',1] * ELL_2012 + sharesELL2013[`j',1] * ELL_2013 + sharesELL2014[`j',1] * ELL_2014 + sharesELL2015[`j',1] * ELL_2015 + sharesELL2016[`j',1] * ELL_2016 + sharesELL2017[`j',1] * ELL_2017 + sharesELL2018[`j',1] * ELL_2018 + sharesELL2019[`j',1] * ELL_2019 + sharesELL2020[`j',1] * ELL_2020)
		
	mat bL = (r(estimate))
	mat seL = (r(se))
	mat pL = (r(p))
	mat loL = (r(lb))
	mat hiL = (r(ub))
	
	matrix bL[`j',1] =bL
	matrix seL[`j',1] =seL
	matrix pL[`j',1] =pL
	matrix loL[`j',1] =loL
	matrix hiL[`j',1] =hiL


cap drop bL1  loL1 hiL1 pL1	seL1 
cap drop bLL1 seLL1 bLH1 seLH1
svmat bL 
svmat bLL
svmat bLH
svmat seL
svmat seLL
svmat seLH
svmat pL
svmat loL 
svmat hiL 

* HIGH LOW
matrix bHL = J(`j',1,.)
matrix seHL = J(`j',1,.)
matrix pHL = J(`j',1,.)
matrix loHL = J(`j',1,.)
matrix hiHL = J(`j',1,.)

lincom (sharesEHL2011[`j',1] * EHL_2011 + sharesEHL2012[`j',1] * EHL_2012 + sharesEHL2013[`j',1] * EHL_2013 + sharesEHL2014[`j',1] * EHL_2014 + sharesEHL2015[`j',1] * EHL_2015 + sharesEHL2016[`j',1] * EHL_2016 + sharesEHL2017[`j',1] * EHL_2017 + sharesEHL2018[`j',1] * EHL_2018 + sharesEHL2019[`j',1] * EHL_2019 + sharesEHL2020[`j',1] * EHL_2020)

	mat bHL = (r(estimate))
	mat seHL = (r(se))
	mat pHL = (r(p))
	mat loHL = (r(lb))
	mat hiHL = (r(ub))
	
	matrix bHL[`j',1] =bHL
	matrix seHL[`j',1] =seHL
	matrix pHL[`j',1] =pHL
	matrix loHL[`j',1] =loHL
	matrix hiHL[`j',1] =hiHL
	

* LOW HIGH
matrix bHH = J(`j',1,.)
matrix seHH = J(`j',1,.)
matrix pHH = J(`j',1,.)
matrix loHH = J(`j',1,.)
matrix hiHH = J(`j',1,.)

lincom (sharesEHH2011[`j',1] * EHH_2011 + sharesEHH2012[`j',1] * EHH_2012 + sharesEHH2013[`j',1] * EHH_2013 + sharesEHH2014[`j',1] * EHH_2014 + sharesEHH2015[`j',1] * EHH_2015 + sharesEHH2016[`j',1] * EHH_2016 + sharesEHH2017[`j',1] * EHH_2017 + sharesEHH2018[`j',1] * EHH_2018 + sharesEHH2019[`j',1] * EHH_2019 + sharesEHH2020[`j',1] * EHH_2020) 

	mat bHH = (r(estimate))
	mat seHH = (r(se))
	mat pHH= (r(p))
	mat loHH = (r(lb))
	mat hiHH = (r(ub))
	
	matrix bHH[`j',1] =bHH
	matrix seHH[`j',1] =seHH
	matrix pHH[`j',1] =pHH
	matrix loHH[`j',1] =loHH
	matrix hiHH[`j',1] =hiHH
	
	* HIGH TO LOW 
matrix bH = J(`j',1,.)
matrix seH = J(`j',1,.)
matrix pH = J(`j',1,.)
matrix loH = J(`j',1,.)
matrix hiH = J(`j',1,.)

lincom (sharesEHL2011[`j',1] * EHL_2011 + sharesEHL2012[`j',1] * EHL_2012 + sharesEHL2013[`j',1] * EHL_2013 + sharesEHL2014[`j',1] * EHL_2014 + sharesEHL2015[`j',1] * EHL_2015 + sharesEHL2016[`j',1] * EHL_2016 + sharesEHL2017[`j',1] * EHL_2017 + sharesEHL2018[`j',1] * EHL_2018 + sharesEHL2019[`j',1] * EHL_2019 + sharesEHL2020[`j',1] * EHL_2020) - (sharesEHH2011[`j',1] * EHH_2011 + sharesEHH2012[`j',1] * EHH_2012 + sharesEHH2013[`j',1] * EHH_2013 + sharesEHH2014[`j',1] * EHH_2014 + sharesEHH2015[`j',1] * EHH_2015 + sharesEHH2016[`j',1] * EHH_2016 + sharesEHH2017[`j',1] * EHH_2017 + sharesEHH2018[`j',1] * EHH_2018 + sharesEHH2019[`j',1] * EHH_2019 + sharesEHH2020[`j',1] * EHH_2020)  
	
	mat bH = (r(estimate))
	mat seH = (r(se))
	mat pH = (r(p))
	mat loH = (r(lb))
	mat hiH = (r(ub))
	
	matrix bH[`j',1] =bH
	matrix seH[`j',1] =seH
	matrix pH[`j',1] =pH
	matrix loH[`j',1] =loH
	matrix hiH[`j',1] =hiH
	

cap drop bH1  loH1 hiH1 pH1	seH1
cap drop bHL1 seHL1 bHH1 seHH1
svmat bH 
svmat bHL
svmat bHH
svmat seH
svmat seHL
svmat seHH
svmat pH
svmat loH 
svmat hiH 

su `y' if KEi == -1
cap drop ymeanF1
gen ymeanF1 = r(mean) 
end
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
* COHORT STATIC - PROGRAM FOR STATIC TABLE
********************************************************************************

cap program drop coeffStaticCohort14
program def coeffStaticCohort14

	syntax , y(string)

	cap drop bH1  loH1 hiH1 pH1 seH1
	cap drop bHL1 seHL1 bHH1 seHH1
	cap drop bL1  loL1 hiL1 pL1 seL1 
	cap drop bLL1 seLL1 bLH1 seLH1

	local j = 1

	* LOW LOW
	matrix bLL = J(`j',1,.)
	matrix seLL = J(`j',1,.)
	matrix pLL = J(`j',1,.)
	matrix loLL = J(`j',1,.)
	matrix hiLL = J(`j',1,.)

lincom ( sharesELL2014[`j',1] * ELL_2014 + sharesELL2015[`j',1] * ELL_2015 + sharesELL2016[`j',1] * ELL_2016 + sharesELL2017[`j',1] * ELL_2017 + sharesELL2018[`j',1] * ELL_2018 + sharesELL2019[`j',1] * ELL_2019 + sharesELL2020[`j',1] * ELL_2020 )

	mat bLL = (r(estimate))
	mat seLL = (r(se))
	mat pLL = (r(p))
	mat loLL = (r(lb))
	mat hiLL = (r(ub))
	
	matrix bLL[`j',1] =bLL
	matrix seLL[`j',1] =seLL
	matrix pLL[`j',1] =pLL
	matrix loLL[`j',1] =loLL
	matrix hiLL[`j',1] =hiLL
	

	* LOW HIGH
	matrix bLH = J(`j',1,.)
	matrix seLH = J(`j',1,.)
	matrix pLH = J(`j',1,.)
	matrix loLH = J(`j',1,.)
	matrix hiLH = J(`j',1,.)

lincom (sharesELH2014[`j',1] * ELH_2014 + sharesELH2015[`j',1] * ELH_2015 + sharesELH2016[`j',1] * ELH_2016 + sharesELH2017[`j',1] * ELH_2017 + sharesELH2018[`j',1] * ELH_2018 + sharesELH2019[`j',1] * ELH_2019 + sharesELH2020[`j',1] * ELH_2020) 

	mat bLH = (r(estimate))
	mat seLH = (r(se))
	mat pLH= (r(p))
	mat loLH = (r(lb))
	mat hiLH = (r(ub))
	
	matrix bLH[`j',1] =bLH
	matrix seLH[`j',1] =seLH
	matrix pLH[`j',1] =pLH
	matrix loLH[`j',1] =loLH
	matrix hiLH[`j',1] =hiLH
	
	* DOUBLE DIFF: LOW TO HIGH 
	matrix bL = J(`j',1,.)
	matrix seL = J(`j',1,.)
	matrix pL = J(`j',1,.)
	matrix loL = J(`j',1,.)
	matrix hiL = J(`j',1,.)

lincom (sharesELH2014[`j',1] * ELH_2014 + sharesELH2015[`j',1] * ELH_2015 + sharesELH2016[`j',1] * ELH_2016 + sharesELH2017[`j',1] * ELH_2017 + sharesELH2018[`j',1] * ELH_2018 + sharesELH2019[`j',1] * ELH_2019 + sharesELH2020[`j',1] * ELH_2020 ) - ( sharesELL2014[`j',1] * ELL_2014 + sharesELL2015[`j',1] * ELL_2015 + sharesELL2016[`j',1] * ELL_2016 + sharesELL2017[`j',1] * ELL_2017 + sharesELL2018[`j',1] * ELL_2018 + sharesELL2019[`j',1] * ELL_2019 + sharesELL2020[`j',1] * ELL_2020 )
		
	mat bL = (r(estimate))
	mat seL = (r(se))
	mat pL = (r(p))
	mat loL = (r(lb))
	mat hiL = (r(ub))
	
	matrix bL[`j',1] =bL
	matrix seL[`j',1] =seL
	matrix pL[`j',1] =pL
	matrix loL[`j',1] =loL
	matrix hiL[`j',1] =hiL

	svmat bL , name(bL)
	svmat bLL , name(bLL)
	svmat bLH , name(bLH)
	svmat seL , name(seL)
	svmat seLL , name(seLL)
	svmat seLH , name(seLH)
	svmat pL , name(pL)
	svmat loL , name(loL)
	svmat hiL , name(hiL)

	* HIGH LOW
	matrix bHL = J(`j',1,.)
	matrix seHL = J(`j',1,.)
	matrix pHL = J(`j',1,.)
	matrix loHL = J(`j',1,.)
	matrix hiHL = J(`j',1,.)

lincom ( sharesEHL2014[`j',1] * EHL_2014 + sharesEHL2015[`j',1] * EHL_2015 + sharesEHL2016[`j',1] * EHL_2016 + sharesEHL2017[`j',1] * EHL_2017 + sharesEHL2018[`j',1] * EHL_2018 + sharesEHL2019[`j',1] * EHL_2019 + sharesEHL2020[`j',1] * EHL_2020 )

	mat bHL = (r(estimate))
	mat seHL = (r(se))
	mat pHL = (r(p))
	mat loHL = (r(lb))
	mat hiHL = (r(ub))
	
	matrix bHL[`j',1] =bHL
	matrix seHL[`j',1] =seHL
	matrix pHL[`j',1] =pHL
	matrix loHL[`j',1] =loHL
	matrix hiHL[`j',1] =hiHL
	

* HIGH HIGH
	matrix bHH = J(`j',1,.)
	matrix seHH = J(`j',1,.)
	matrix pHH = J(`j',1,.)
	matrix loHH = J(`j',1,.)
	matrix hiHH = J(`j',1,.)

lincom ( sharesEHH2014[`j',1] * EHH_2014 + sharesEHH2015[`j',1] * EHH_2015 + sharesEHH2016[`j',1] * EHH_2016 + sharesEHH2017[`j',1] * EHH_2017 + sharesEHH2018[`j',1] * EHH_2018 + sharesEHH2019[`j',1] * EHH_2019 + sharesEHH2020[`j',1] * EHH_2020 ) 

	mat bHH = (r(estimate))
	mat seHH = (r(se))
	mat pHH= (r(p))
	mat loHH = (r(lb))
	mat hiHH = (r(ub))
	
	matrix bHH[`j',1] =bHH
	matrix seHH[`j',1] =seHH
	matrix pHH[`j',1] =pHH
	matrix loHH[`j',1] =loHH
	matrix hiHH[`j',1] =hiHH
	
	* HIGH TO LOW 
	matrix bH = J(`j',1,.)
	matrix seH = J(`j',1,.)
	matrix pH = J(`j',1,.)
	matrix loH = J(`j',1,.)
	matrix hiH = J(`j',1,.)

lincom ( sharesEHL2014[`j',1] * EHL_2014 + sharesEHL2015[`j',1] * EHL_2015 + sharesEHL2016[`j',1] * EHL_2016 + sharesEHL2017[`j',1] * EHL_2017 + sharesEHL2018[`j',1] * EHL_2018 + sharesEHL2019[`j',1] * EHL_2019 + sharesEHL2020[`j',1] * EHL_2020 ) - ( sharesEHH2014[`j',1] * EHH_2014 + sharesEHH2015[`j',1] * EHH_2015 + sharesEHH2016[`j',1] * EHH_2016 + sharesEHH2017[`j',1] * EHH_2017 + sharesEHH2018[`j',1] * EHH_2018 + sharesEHH2019[`j',1] * EHH_2019 + sharesEHH2020[`j',1] * EHH_2020)  
	
	mat bH = (r(estimate))
	mat seH = (r(se))
	mat pH = (r(p))
	mat loH = (r(lb))
	mat hiH = (r(ub))
	
	matrix bH[`j',1] =bH
	matrix seH[`j',1] =seH
	matrix pH[`j',1] =pH
	matrix loH[`j',1] =loH
	matrix hiH[`j',1] =hiH
	
	svmat bH , name(bH)
	svmat bHL , name(bHL)
	svmat bHH , name(bHH)
	svmat seH , name(seH)
	svmat seHL , name(seHL)
	svmat seHH , name(seHH)
	svmat pH , name(pH)
	svmat loH , name(loH)
	svmat hiH , name(hiH)

su `y' if KEi == -1
cap drop ymeanF1
gen ymeanF1 = r(mean) 
end
////////////////////////////////////////////////////////////////////////////////


********************************************************************************
* COHORT DYNAMIC- single difference estimates 
********************************************************************************

cap program drop coeffCohort1
program def coeffCohort1

syntax , c(real) y(string)

local d = (`c' - 1)/2  // half window

* LOW TO HIGH 
matrix bL = J(`c',1,.)
matrix seL = J(`c',1,.)
matrix pL = J(`c',1,.)
matrix loL = J(`c',1,.)
matrix hiL = J(`c',1,.)
matrix etL = J(`c',1,.)

local j = 1
local jointLH " (sharesELH2011[`j',1] * F`d'ELH_2011 + sharesELH2012[`j',1] * F`d'ELH_2012 + sharesELH2013[`j',1] * F`d'ELH_2013 + sharesELH2014[`j',1] * F`d'ELH_2014 + sharesELH2015[`j',1] * F`d'ELH_2015 + sharesELH2016[`j',1] * F`d'ELH_2016 + sharesELH2017[`j',1] * F`d'ELH_2017 + sharesELH2018[`j',1] * F`d'ELH_2018 + sharesELH2019[`j',1] * F`d'ELH_2019 + sharesELH2020[`j',1] * F`d'ELH_2020) - (sharesELL2011[`j',1] * F`d'ELL_2011 + sharesELL2012[`j',1] * F`d'ELL_2012 + sharesELL2013[`j',1] * F`d'ELL_2013 + sharesELL2014[`j',1] * F`d'ELL_2014 + sharesELL2015[`j',1] * F`d'ELL_2015 + sharesELL2016[`j',1] * F`d'ELL_2016 + sharesELL2017[`j',1] * F`d'ELL_2017 + sharesELL2018[`j',1] * F`d'ELL_2018 + sharesELL2019[`j',1] * F`d'ELL_2019 + sharesELL2020[`j',1] * F`d'ELL_2020)"
	
forval i=`d'(-1)2{
	if `i'>2 {
local t = `i'-1
	local fLH " (sharesELH2011[`j',1] * F`t'ELH_2011 + sharesELH2012[`j',1] * F`t'ELH_2012 + sharesELH2013[`j',1] * F`t'ELH_2013 + sharesELH2014[`j',1] * F`t'ELH_2014 + sharesELH2015[`j',1] * F`t'ELH_2015 + sharesELH2016[`j',1] * F`t'ELH_2016 + sharesELH2017[`j',1] * F`t'ELH_2017 + sharesELH2018[`j',1] * F`t'ELH_2018 + sharesELH2019[`j',1] * F`t'ELH_2019 + sharesELH2020[`j',1] * F`t'ELH_2020) - (sharesELL2011[`j',1] * F`t'ELL_2011 + sharesELL2012[`j',1] * F`t'ELL_2012 + sharesELL2013[`j',1] * F`t'ELL_2013 + sharesELL2014[`j',1] * F`t'ELL_2014 + sharesELL2015[`j',1] * F`t'ELL_2015 + sharesELL2016[`j',1] * F`t'ELL_2016 + sharesELL2017[`j',1] * F`t'ELL_2017 + sharesELL2018[`j',1] * F`t'ELL_2018 + sharesELL2019[`j',1] * F`t'ELL_2019 + sharesELL2020[`j',1] * F`t'ELL_2020)"
}
else {
local fLH " " 
}

lincom (sharesELH2011[`j',1] * F`i'ELH_2011 + sharesELH2012[`j',1] * F`i'ELH_2012 + sharesELH2013[`j',1] * F`i'ELH_2013 + sharesELH2014[`j',1] * F`i'ELH_2014 + sharesELH2015[`j',1] * F`i'ELH_2015 + sharesELH2016[`j',1] * F`i'ELH_2016 + sharesELH2017[`j',1] * F`i'ELH_2017 + sharesELH2018[`j',1] * F`i'ELH_2018 + sharesELH2019[`j',1] * F`i'ELH_2019 + sharesELH2020[`j',1] * F`i'ELH_2020) - (sharesELL2011[`j',1] * F`i'ELL_2011 + sharesELL2012[`j',1] * F`i'ELL_2012 + sharesELL2013[`j',1] * F`i'ELL_2013 + sharesELL2014[`j',1] * F`i'ELL_2014 + sharesELL2015[`j',1] * F`i'ELL_2015 + sharesELL2016[`j',1] * F`i'ELL_2016 + sharesELL2017[`j',1] * F`i'ELL_2017 + sharesELL2018[`j',1] * F`i'ELL_2018 + sharesELL2019[`j',1] * F`i'ELL_2019 + sharesELL2020[`j',1] * F`i'ELL_2020)
		
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

	if `i'>2 {
	local jointLH "`jointLH' + `fLH'" 
}
else {
}

}
cap drop jointLH
lincom `jointLH'
gen jointLH =  (r(p))

matrix bL[`d',1] =0
matrix seL[`d',1] =0
matrix pL[`d',1] =0
matrix loL[`d',1] =0
matrix hiL[`d',1] =0
matrix etL[`d',1] =-1

local j = `d' 
forval i=0(1)`d'{
	
lincom (sharesELH2011[`j',1] * L`i'ELH_2011 + sharesELH2012[`j',1] * L`i'ELH_2012 + sharesELH2013[`j',1] * L`i'ELH_2013 + sharesELH2014[`j',1] * L`i'ELH_2014 + sharesELH2015[`j',1] * L`i'ELH_2015 + sharesELH2016[`j',1] * L`i'ELH_2016 + sharesELH2017[`j',1] * L`i'ELH_2017 + sharesELH2018[`j',1] * L`i'ELH_2018 + sharesELH2019[`j',1] * L`i'ELH_2019 + sharesELH2020[`j',1] * L`i'ELH_2020) - (sharesELL2011[`j',1] * L`i'ELL_2011 + sharesELL2012[`j',1] * L`i'ELL_2012 + sharesELL2013[`j',1] * L`i'ELL_2013 + sharesELL2014[`j',1] * L`i'ELL_2014 + sharesELL2015[`j',1] * L`i'ELL_2015 + sharesELL2016[`j',1] * L`i'ELL_2016 + sharesELL2017[`j',1] * L`i'ELL_2017 + sharesELL2018[`j',1] * L`i'ELL_2018 + sharesELL2019[`j',1] * L`i'ELL_2019 + sharesELL2020[`j',1] * L`i'ELL_2020)
	
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
matrix bH = J(`c',1,.)
matrix seH = J(`c',1,.)
matrix pH = J(`c',1,.)
matrix loH = J(`c',1,.)
matrix hiH = J(`c',1,.)
matrix etH = J(`c',1,.)


local j = 1
local jointHL " (sharesEHH2011[`j',1] * F`d'EHH_2011 + sharesEHH2012[`j',1] * F`d'EHH_2012 + sharesEHH2013[`j',1] * F`d'EHH_2013 + sharesEHH2014[`j',1] * F`d'EHH_2014 + sharesEHH2015[`j',1] * F`d'EHH_2015 + sharesEHH2016[`j',1] * F`d'EHH_2016 + sharesEHH2017[`j',1] * F`d'EHH_2017 + sharesEHH2018[`j',1] * F`d'EHH_2018 + sharesEHH2019[`j',1] * F`d'EHH_2019 + sharesEHH2020[`j',1] * F`d'EHH_2020) - (sharesEHL2011[`j',1] * F`d'EHL_2011 + sharesEHL2012[`j',1] * F`d'EHL_2012 + sharesEHL2013[`j',1] * F`d'EHL_2013 + sharesEHL2014[`j',1] * F`d'EHL_2014 + sharesEHL2015[`j',1] * F`d'EHL_2015 + sharesEHL2016[`j',1] * F`d'EHL_2016 + sharesEHL2017[`j',1] * F`d'EHL_2017 + sharesEHL2018[`j',1] * F`d'EHL_2018 + sharesEHL2019[`j',1] * F`d'EHL_2019 + sharesEHL2020[`j',1] * F`d'EHL_2020)"
	
forval i=`d'(-1)2{
	
	if `i'>2 {
local t = `i'-1
	
	local fHL "(sharesEHH2011[`j',1] * F`t'EHH_2011 + sharesEHH2012[`j',1] * F`t'EHH_2012 + sharesEHH2013[`j',1] * F`t'EHH_2013 + sharesEHH2014[`j',1] * F`t'EHH_2014 + sharesEHH2015[`j',1] * F`t'EHH_2015 + sharesEHH2016[`j',1] * F`t'EHH_2016 + sharesEHH2017[`j',1] * F`t'EHH_2017 + sharesEHH2018[`j',1] * F`t'EHH_2018 + sharesEHH2019[`j',1] * F`t'EHH_2019 + sharesEHH2020[`j',1] * F`t'EHH_2020) - (sharesEHL2011[`j',1] * F`t'EHL_2011 + sharesEHL2012[`j',1] * F`t'EHL_2012 + sharesEHL2013[`j',1] * F`t'EHL_2013 + sharesEHL2014[`j',1] * F`t'EHL_2014 + sharesEHL2015[`j',1] * F`t'EHL_2015 + sharesEHL2016[`j',1] * F`t'EHL_2016 + sharesEHL2017[`j',1] * F`t'EHL_2017 + sharesEHL2018[`j',1] * F`t'EHL_2018 + sharesEHL2019[`j',1] * F`t'EHL_2019 + sharesEHL2020[`j',1] * F`t'EHL_2020)"
	}
else {
local fHL " " 
}

lincom   (sharesEHL2011[`j',1] * F`i'EHL_2011 + sharesEHL2012[`j',1] * F`i'EHL_2012 + sharesEHL2013[`j',1] * F`i'EHL_2013 + sharesEHL2014[`j',1] * F`i'EHL_2014 + sharesEHL2015[`j',1] * F`i'EHL_2015 + sharesEHL2016[`j',1] * F`i'EHL_2016 + sharesEHL2017[`j',1] * F`i'EHL_2017 + sharesEHL2018[`j',1] * F`i'EHL_2018 + sharesEHL2019[`j',1] * F`i'EHL_2019 + sharesEHL2020[`j',1] * F`i'EHL_2020) - (sharesEHH2011[`j',1] * F`i'EHH_2011 + sharesEHH2012[`j',1] * F`i'EHH_2012 + sharesEHH2013[`j',1] * F`i'EHH_2013 + sharesEHH2014[`j',1] * F`i'EHH_2014 + sharesEHH2015[`j',1] * F`i'EHH_2015 + sharesEHH2016[`j',1] * F`i'EHH_2016 + sharesEHH2017[`j',1] * F`i'EHH_2017 + sharesEHH2018[`j',1] * F`i'EHH_2018 + sharesEHH2019[`j',1] * F`i'EHH_2019 + sharesEHH2020[`j',1] * F`i'EHH_2020)
	
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
	
	if `i'>2 {
	local jointHL "`jointHL' + `fHL'" 
}
else {
}

}

cap drop jointHL
lincom `jointHL'
gen jointHL =  (r(p))

matrix bH[`d',1] =0
matrix seH[`d',1] =0
matrix pH[`d',1] =0
matrix loH[`d',1] =0
matrix hiH[`d',1] =0
matrix etH[`d',1] =-1

local j = `d' 
forval i=0(1)`d'{
lincom (sharesEHL2011[`j',1] * L`i'EHL_2011 + sharesEHL2012[`j',1] * L`i'EHL_2012 + sharesEHL2013[`j',1] * L`i'EHL_2013 + sharesEHL2014[`j',1] * L`i'EHL_2014 + sharesEHL2015[`j',1] * L`i'EHL_2015 + sharesEHL2016[`j',1] * L`i'EHL_2016 + sharesEHL2017[`j',1] * L`i'EHL_2017 + sharesEHL2018[`j',1] * L`i'EHL_2018 + sharesEHL2019[`j',1] * L`i'EHL_2019 + sharesEHL2020[`j',1] * L`i'EHL_2020) - (sharesEHH2011[`j',1] * L`i'EHH_2011 + sharesEHH2012[`j',1] * L`i'EHH_2012 + sharesEHH2013[`j',1] * L`i'EHH_2013 + sharesEHH2014[`j',1] * L`i'EHH_2014 + sharesEHH2015[`j',1] * L`i'EHH_2015 + sharesEHH2016[`j',1] * L`i'EHH_2016 + sharesEHH2017[`j',1] * L`i'EHH_2017 + sharesEHH2018[`j',1] * L`i'EHH_2018 + sharesEHH2019[`j',1] * L`i'EHH_2019 + sharesEHH2020[`j',1] * L`i'EHH_2020) 
	
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

cap drop ymeanF1
su `y' if KEi == -1
gen ymeanF1 = r(mean) 

end


********************************************************************************
* TWFE - single  difference estimates 
********************************************************************************

cap program drop coeff1
program def coeff1

syntax , c(real) y(string) type(string)
local d = (`c' - 1)/2  // half window

* LOW TO HIGH 
matrix bL = J(`c',1,.)
matrix seL = J(`c',1,.)
matrix pL = J(`c',1,.)
matrix loL = J(`c',1,.)
matrix hiL = J(`c',1,.)
matrix etL = J(`c',1,.)

local j =1
local jointLH "(F`d'ELH - F`d'ELL)"
forval i=`d'(-1)2{
	
		if `i'>2 {
local t = `i'-1
		local fLH "(F`t'ELH - F`t'ELL)"
}
else {
local fLH " " 
}
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

		if `i'>2 {
	local jointLH "`jointLH' + `fLH'" 
}
else {
}

}

cap drop jointLH
lincom `jointLH'
gen jointLH =  (r(p))

matrix bL[`d',1] =0
matrix seL[`d',1] =0
matrix pL[`d',1] =0
matrix loL[`d',1] =0
matrix hiL[`d',1] =0
matrix etL[`d',1] =-1

local j = `d' + 1
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
matrix bH = J(`c',1,.)
matrix seH = J(`c',1,.)
matrix pH = J(`c',1,.)
matrix loH = J(`c',1,.)
matrix hiH = J(`c',1,.)
matrix etH = J(`c',1,.)

local j =1
local jointHL "(F`d'EHL - F`d'EHH)"

forval i=`d'(-1)2{
	
		if `i'>2 {
local t = `i'-1
		local fHL "(F`t'EHL - F`t'EHH)"
}
else {
local fHL " " 
}
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

	if `i'>2 {
	local jointHL "`jointHL' + `fHL'" 
}
else {
}

}

cap drop jointHL
lincom `jointHL'
gen jointHL =  (r(p))

matrix bH[`d',1] =0
matrix seH[`d',1] =0
matrix pH[`d',1] =0
matrix loH[`d',1] =0
matrix hiH[`d',1] =0
matrix etH[`d',1] =-1

local j = `d' + 1
forval i=0(1)`d'{
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

* Low baseline 
cap drop ymeanF1L
su `y' if KEi == -1 &  (`type'LLB==1 | `type'LHB==1  )  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

* High baseline 
cap drop ymeanF1H
su `y' if KEi == -1 &  (`type'HLB==1   | `type'HHB==1  )  // modified 
gen ymeanF1H = r(mean) 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)
 
end 

********************************************************************************
* TWFE - single differences and average monthly estimates into quarterly  - ONLY HL vs HH (to speed up estimation)
********************************************************************************

cap program drop coeffQHL1
program def coeffQHL1

syntax , c(real) y(string) type(string)
local d = (`c' - 1)/2  // half window
local x = `d' - 2


*HIGH TO LOW 

matrix bQH = J(`c',1,.)
matrix seQH = J(`c',1,.)
matrix pQH = J(`c',1,.)
matrix loQH = J(`c',1,.)
matrix hiQH = J(`c',1,.)
matrix etQH = J(`c',1,.)

local j = 1
forval i=`d'(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom (( F`i'EHL - F`i'EHH  ) + ///
	( F`k'EHL - F`k'EHH  ) + ///
	( F`h'EHL - F`h'EHH  ) ) /3,  level(95)
	
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
	mat etQH[`j',1] =  - `i'/3
	
	local j = `j' + 1
}

matrix bQH[`d',1] =0
matrix seQH[`d',1] =0
matrix pQH[`d',1] =0
matrix loQH[`d',1] =0
matrix hiQH[`d',1] =0
matrix etQH[`d',1] =-1

local j = `d' + 1

* for quarter 0, just take month 0 
	lincom  ( L0EHL - L0EHH  ),  level(95)
	mat bQH_L0 = (r(estimate))
	mat seQH_L0 = (r(se))
	mat pQH_L0 = (r(p))
	mat loQH_L0 = (r(lb))
	mat hiQH_L0 = (r(ub))
	
	matrix bQH[`j',1] =bQH_L0
	matrix seQH[`j',1] =seQH_L0
	matrix pQH[`j',1] =pQH_L0
	matrix loQH[`j',1] =loQH_L0
	matrix hiQH[`j',1] =hiQH_L0
	mat etQH[`j',1] = 0
	
local j = `d' + 2
forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'EHL - L`i'EHH  ) + ///
	( L`k'EHL - L`k'EHH  ) + ///
	( L`h'EHL - L`h'EHH  )) / 3,  level(95)
	
	mat bQH_L`i' = (r(estimate))
	mat seQH_L`i' = (r(se))
	mat pQH_L`i' = (r(p))
	mat loQH_L`i' = (r(lb))
	mat hiQH_L`i' = (r(ub))
	
	matrix bQH[`j',1] =bQH_L`i'
	matrix seQH[`j',1] =seQH_L`i'
	matrix pQH[`j',1] =pQH_L`i'
	matrix loQH[`j',1] =loQH_L`i'
	matrix hiQH[`j',1] =hiQH_L`i'
	mat etQH[`j',1] = (`i'+2)/3 
	local j = `j' + 1

}


cap drop bQH1 etQH1 loQH1 hiQH1 pQH1	seQH1
svmat bQH 
svmat seQH
svmat pQH
svmat etQH 
svmat loQH 
svmat hiQH

* High baseline 
cap drop ymeanF1H
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (`type'HLB==1   | `type'HHB==1  )  // modified 
gen ymeanF1H = r(mean) 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)
end


********************************************************************************
* TWFE - single  difference estimates - only HL vs. HH (to speed up estimation)
********************************************************************************

cap program drop coeffHL1
program def coeffHL1

syntax , c(real) y(string) type(string)
local d = (`c' - 1)/2  // half window


	* HIGH TO LOW 
matrix bH = J(`c',1,.)
matrix seH = J(`c',1,.)
matrix pH = J(`c',1,.)
matrix loH = J(`c',1,.)
matrix hiH = J(`c',1,.)
matrix etH = J(`c',1,.)

local j =1
local jointHL "(F`d'EHL - F`d'EHH)"

forval i=`d'(-1)2{
	
		if `i'>2 {
local t = `i'-1
		local fHL "(F`t'EHL - F`t'EHH)"
}
else {
local fHL " " 
}
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

	if `i'>2 {
	local jointHL "`jointHL' + `fHL'" 
}
else {
}

}

cap drop jointHL
lincom `jointHL'
gen jointHL =  (r(p))

matrix bH[`d',1] =0
matrix seH[`d',1] =0
matrix pH[`d',1] =0
matrix loH[`d',1] =0
matrix hiH[`d',1] =0
matrix etH[`d',1] =-1

local j = `d' + 1
forval i=0(1)`d'{
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

* High baseline 
cap drop ymeanF1H
su `y' if KEi == -1 &  (`type'HLB==1   | `type'HHB==1  )  // modified 
gen ymeanF1H = r(mean) 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)
 
end 
********************************************************************************
* TWFE - double difference estimates 
********************************************************************************

cap program drop coeff
program def coeff

syntax , c(real) y(string)
local d = (`c' - 1)/2  // half window

matrix b = J(`c',1,.)
matrix se = J(`c',1,.)
matrix p = J(`c',1,.)
matrix lo = J(`c',1,.)
matrix hi = J(`c',1,.)
matrix et = J(`c',1,.)

local j = 1
forval i=`d'(-1)2{
	lincom ( (F`i'ELH - F`i'ELL) - (F`i'EHL - F`i'EHH) ) // testing if the asymmetries are significant 
	
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

matrix b[`d',1] =0
matrix se[`d',1] =0
matrix p[`d',1] =0
matrix lo[`d',1] =0
matrix hi[`d',1] =0
matrix et[`d',1] =-1

local j = `d' + 1 
forval i=0(1)`d'{
	lincom ( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) )
	
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

cap drop ymeanF1
su `y' if KEi == -1
gen ymeanF1 = r(mean) 
su ymeanF1
local ymeanF1 = round(r(mean), 0.001)
end 

********************************************************************************
* TWFE - single differences and average monthly estimates into quarterly  
********************************************************************************

cap program drop coeffQ1
program def coeffQ1

syntax , c(real) y(string) type(string)
local d = (`c' - 1)/2  // half window
local x = `d' - 2

* LOW TO HIGH 
matrix bQL = J(`c',1,.)
matrix seQL = J(`c',1,.)
matrix pQL = J(`c',1,.)
matrix loQL = J(`c',1,.)
matrix hiQL = J(`c',1,.)
matrix etQL = J(`c',1,.)

local j = 1
forval i=`d'(-3)6{
	local k = `i' - 1
	local h = `i' - 2

	lincom ( ( F`i'ELH - F`i'ELL  ) + ///
	( F`k'ELH - F`k'ELL  ) + ///
	( F`h'ELH - F`h'ELL  ) ) /3,  level(95)
	
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
	mat etQL[`j',1] =  - `i'/3
	
	local j = `j' + 1
}

matrix bQL[`d',1] =0
matrix seQL[`d',1] =0
matrix pQL[`d',1] =0
matrix loQL[`d',1] =0
matrix hiQL[`d',1] =0
matrix etQL[`d',1] =-1

local j = `d' + 1 

* for quarter 0, just take month 0 
	lincom  ( L0ELH - L0ELL  ),  level(95) 
	
	mat bQL_L0 = (r(estimate))
	mat seQL_L0 = (r(se))
	mat pQL_L0 = (r(p))
	mat loQL_L0 = (r(lb))
	mat hiQL_L0 = (r(ub))
	
	matrix bQL[`j',1] =bQL_L0
	matrix seQL[`j',1] =seQL_L0
	matrix pQL[`j',1] =pQL_L0
	matrix loQL[`j',1] =loQL_L0
	matrix hiQL[`j',1] =hiQL_L0
	mat etQL[`j',1] = 0
	

local j = `d' + 2

forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'ELH - L`i'ELL  ) + ///
	( L`k'ELH - L`k'ELL  ) + ///
	( L`h'ELH - L`h'ELL  )) / 3,  level(95)
	
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
	mat etQL[`j',1] = (`i'+2)/3 
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

matrix bQH = J(`c',1,.)
matrix seQH = J(`c',1,.)
matrix pQH = J(`c',1,.)
matrix loQH = J(`c',1,.)
matrix hiQH = J(`c',1,.)
matrix etQH = J(`c',1,.)

local j = 1
forval i=`d'(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom (( F`i'EHL - F`i'EHH  ) + ///
	( F`k'EHL - F`k'EHH  ) + ///
	( F`h'EHL - F`h'EHH  ) ) /3,  level(95)
	
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
	mat etQH[`j',1] =  - `i'/3
	
	local j = `j' + 1
}

matrix bQH[`d',1] =0
matrix seQH[`d',1] =0
matrix pQH[`d',1] =0
matrix loQH[`d',1] =0
matrix hiQH[`d',1] =0
matrix etQH[`d',1] =-1

local j = `d' + 1

* for quarter 0, just take month 0 
	lincom  ( L0EHL - L0EHH  ),  level(95)
	mat bQH_L0 = (r(estimate))
	mat seQH_L0 = (r(se))
	mat pQH_L0 = (r(p))
	mat loQH_L0 = (r(lb))
	mat hiQH_L0 = (r(ub))
	
	matrix bQH[`j',1] =bQH_L0
	matrix seQH[`j',1] =seQH_L0
	matrix pQH[`j',1] =pQH_L0
	matrix loQH[`j',1] =loQH_L0
	matrix hiQH[`j',1] =hiQH_L0
	mat etQH[`j',1] = 0
	
local j = `d' + 2
forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'EHL - L`i'EHH  ) + ///
	( L`k'EHL - L`k'EHH  ) + ///
	( L`h'EHL - L`h'EHH  )) / 3,  level(95)
	
	mat bQH_L`i' = (r(estimate))
	mat seQH_L`i' = (r(se))
	mat pQH_L`i' = (r(p))
	mat loQH_L`i' = (r(lb))
	mat hiQH_L`i' = (r(ub))
	
	matrix bQH[`j',1] =bQH_L`i'
	matrix seQH[`j',1] =seQH_L`i'
	matrix pQH[`j',1] =pQH_L`i'
	matrix loQH[`j',1] =loQH_L`i'
	matrix hiQH[`j',1] =hiQH_L`i'
	mat etQH[`j',1] = (`i'+2)/3 
	local j = `j' + 1

}


cap drop bQH1 etQH1 loQH1 hiQH1 pQH1	seQH1
svmat bQH 
svmat seQH
svmat pQH
svmat etQH 
svmat loQH 
svmat hiQH

* Low baseline 
cap drop ymeanF1L
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (`type'LLB==1   | `type'LHB==1  )  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

* High baseline 
cap drop ymeanF1H
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (`type'HLB==1   | `type'HHB==1  )  // modified 
gen ymeanF1H = r(mean) 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)
end

********************************************************************************
* TWFE - double differences and average monthly estimates into quarterly  
********************************************************************************

cap program drop coeffQ
program def coeffQ
syntax , c(real) y(string)
local d = (`c' - 1)/2  // half window
local x = `d' - 2

matrix bQ = J(`c',1,.)
matrix seQ = J(`c',1,.)
matrix pQ = J(`c',1,.)
matrix loQ = J(`c',1,.)
matrix hiQ = J(`c',1,.)
matrix etQ = J(`c',1,.)

local j = 1
forval i=`d'(-3)6{
	local k = `i' - 1
	local h = `i' - 2

	lincom (( (F`i'ELH - F`i'ELL) - (F`i'EHL - F`i'EHH) ) + ///
	( (F`k'ELH - F`k'ELL) - (F`k'EHL - F`k'EHH) ) + ///
	( (F`h'ELH - F`h'ELL) - (F`h'EHL - F`h'EHH) ) )/3,  level(95)
	
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
	mat etQ[`j',1] =  -`i'/3
	
	local j = `j' + 1
}

matrix bQ[`d',1] =0
matrix seQ[`d',1] =0
matrix pQ[`d',1] =0
matrix loQ[`d',1] =0
matrix hiQ[`d',1] =0
matrix etQ[`d',1] =-1

local j = `d' + 1 

* for quarter 0, just take month 0 
	lincom (  (L0ELH - L0ELL) - (L0EHL - L0EHH) ) ,  level(95)
	
	mat bQ_L0 = (r(estimate))
	mat seQ_L0 = (r(se))
	mat pQ_L0 = (r(p))
	mat loQ_L0 = (r(lb))
	mat hiQ_L0 = (r(ub))
	
	matrix bQ[`j',1] =bQ_L0
	matrix seQ[`j',1] =seQ_L0
	matrix pQ[`j',1] =pQ_L0
	matrix loQ[`j',1] =loQ_L0
	matrix hiQ[`j',1] =hiQ_L0
	mat etQ[`j',1] = 0
	
local j = `d' + 2
forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) ) + ///
	( (L`k'ELH - L`k'ELL) - (L`k'EHL - L`k'EHH) ) + ///
	( (L`h'ELH - L`h'ELL) - (L`h'EHL - L`h'EHH) )) / 3,  level(95)
	
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
	mat etQ[`j',1] = (`i'+2)/3 // to align with the time 
	local j = `j' + 1

}

cap drop bQ1 etQ1 loQ1 hiQ1 pQ1	seQ1
svmat bQ 
svmat seQ
svmat pQ
svmat etQ 
svmat loQ 
svmat hiQ

su `y' if (KEi == -1 | KEi == -2  | KEi == -3 )
cap drop ymeanF1
gen ymeanF1 = r(mean) 
end

********************************************************************************
* TWFE - double differences and average monthly estimates into quarterly  - for SYMMETRIC MODEL
********************************************************************************

cap program drop coeffDeltaQ
program def coeffDeltaQ
syntax , c(real) y(string)
local d = (`c' - 1)/2  // half window
local x = `d' - 2

matrix bQ = J(`c',1,.)
matrix seQ = J(`c',1,.)
matrix pQ = J(`c',1,.)
matrix loQ = J(`c',1,.)
matrix hiQ = J(`c',1,.)
matrix etQ = J(`c',1,.)

local j = 1
forval i=`d'(-3)6{
	local k = `i' - 1
	local h = `i' - 2

	lincom ( F`i'EiDelta + F`k'EiDelta + F`h'EiDelta  )/3,  level(95)
	
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
	mat etQ[`j',1] =  -`i'/3
	
	local j = `j' + 1
}

matrix bQ[`d',1] =0
matrix seQ[`d',1] =0
matrix pQ[`d',1] =0
matrix loQ[`d',1] =0
matrix hiQ[`d',1] =0
matrix etQ[`d',1] =-1

local j = `d' + 1 

* for quarter 0, just take month 0 
	lincom (  L0EiDelta ) ,  level(95)
	
	mat bQ_L0 = (r(estimate))
	mat seQ_L0 = (r(se))
	mat pQ_L0 = (r(p))
	mat loQ_L0 = (r(lb))
	mat hiQ_L0 = (r(ub))
	
	matrix bQ[`j',1] =bQ_L0
	matrix seQ[`j',1] =seQ_L0
	matrix pQ[`j',1] =pQ_L0
	matrix loQ[`j',1] =loQ_L0
	matrix hiQ[`j',1] =hiQ_L0
	mat etQ[`j',1] = 0
	
local j = `d' + 2
forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( L`i'EiDelta + L`k'EiDelta + L`h'EiDelta) / 3,  level(95)
	
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
	mat etQ[`j',1] = (`i'+2)/3 // to align with the time 
	local j = `j' + 1

}

cap drop bQ1 etQ1 loQ1 hiQ1 pQ1	seQ1
svmat bQ 
svmat seQ
svmat pQ
svmat etQ 
svmat loQ 
svmat hiQ

su `y' if (KEi == -1 | KEi == -2  | KEi == -3 )
cap drop ymeanF1
gen ymeanF1 = r(mean) 
end

********************************************************************************
* EXIT TWFE - single  difference estimates 
********************************************************************************

cap program drop coeffExit1
program def coeffExit1

syntax , c(real) y(string) type(string)
local d = (`c' - 1)/2  // half window

* LOW TO HIGH 
matrix bL = J(`c',1,.)
matrix seL = J(`c',1,.)
matrix pL = J(`c',1,.)
matrix loL = J(`c',1,.)
matrix hiL = J(`c',1,.)
matrix etL = J(`c',1,.)

matrix bL[`d',1] =0
matrix seL[`d',1] =0
matrix pL[`d',1] =0
matrix loL[`d',1] =0
matrix hiL[`d',1] =0
matrix etL[`d',1] =0

local j = `d' + 1
forval i=1(1)`d'{
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
matrix bH = J(`c',1,.)
matrix seH = J(`c',1,.)
matrix pH = J(`c',1,.)
matrix loH = J(`c',1,.)
matrix hiH = J(`c',1,.)
matrix etH = J(`c',1,.)


matrix bH[`d',1] =0
matrix seH[`d',1] =0
matrix pH[`d',1] =0
matrix loH[`d',1] =0
matrix hiH[`d',1] =0
matrix etH[`d',1] =0

local j = `d' + 1
forval i=1(1)`d'{
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

* Low baseline 
cap drop ymeanF1L
su `y' if (KEi ==0 ) &  (`type'LLB==1   | `type'LHB==1  )  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

* High baseline 
cap drop ymeanF1H
su `y' if (KEi == 0) &  (`type'HLB==1   | `type'HHB==1  )  // modified 
gen ymeanF1H = r(mean) 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

end 

********************************************************************************
* EXIT TWFE - single differences and average monthly estimates into quarterly
********************************************************************************

cap program drop coeffExitQ1
program def coeffExitQ1

syntax , c(real) y(string) type(string)
local d = (`c' - 1)/2  // half window
local x = `d' - 2

* LOW TO HIGH 
matrix bQL = J(`c',1,.)
matrix seQL = J(`c',1,.)
matrix pQL = J(`c',1,.)
matrix loQL = J(`c',1,.)
matrix hiQL = J(`c',1,.)
matrix etQL = J(`c',1,.)


matrix bQL[`d',1] =0
matrix seQL[`d',1] =0
matrix pQL[`d',1] =0
matrix loQL[`d',1] =0
matrix hiQL[`d',1] =0
matrix etQL[`d',1] =0

local j = `d' + 1 

forval i=1(3)`x'{
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
	mat etQL[`j',1] = (`i'+2)/3 
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
matrix bQH = J(`c',1,.)
matrix seQH = J(`c',1,.)
matrix pQH = J(`c',1,.)
matrix loQH = J(`c',1,.)
matrix hiQH = J(`c',1,.)
matrix etQH = J(`c',1,.)

matrix bQH[`d',1] =0
matrix seQH[`d',1] =0
matrix pQH[`d',1] =0
matrix loQH[`d',1] =0
matrix hiQH[`d',1] =0
matrix etQH[`d',1] =0

local j = `d' + 1
	
forval i=1(3)`x'{
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
	matrix seQH[`j',1] =seQH_L`i'
	matrix pQH[`j',1] =pQH_L`i'
	matrix loQH[`j',1] =loQH_L`i'
	matrix hiQH[`j',1] =hiQH_L`i'
	mat etQH[`j',1] = (`i'+2)/3 
	local j = `j' + 1

}


cap drop bQH1 etQH1 loQH1 hiQH1 pQH1	seQH1
svmat bQH 
svmat seQH
svmat pQH
svmat etQH 
svmat loQH 
svmat hiQH

* Low baseline 
cap drop ymeanF1L
su `y' if (KEi ==0 | KEi ==1 | KEi ==2 ) &  (`type'LLB==1   | `type'LHB==1  )  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

* High baseline 
cap drop ymeanF1H
su `y' if (KEi == 0 | KEi ==1 | KEi ==2) &  (`type'HLB==1   | `type'HHB==1  )  // modified 
gen ymeanF1H = r(mean) 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

end

********************************************************************************
* EXIT TWFE - double differences and average monthly estimates into quarterly  
********************************************************************************

cap program drop coeffExitQ
program def coeffExitQ
syntax , c(real) y(string)
local d = (`c' - 1)/2  // half window
local x = `d' - 2

matrix bQ = J(`c',1,.)
matrix seQ = J(`c',1,.)
matrix pQ = J(`c',1,.)
matrix loQ = J(`c',1,.)
matrix hiQ = J(`c',1,.)
matrix etQ = J(`c',1,.)

matrix bQ[`d',1] =0
matrix seQ[`d',1] =0
matrix pQ[`d',1] =0
matrix loQ[`d',1] =0
matrix hiQ[`d',1] =0
matrix etQ[`d',1] =0

local j = `d' + 1 

forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) ) + ///
	( (L`k'ELH - L`k'ELL) - (L`k'EHL - L`k'EHH) ) + ///
	( (L`h'ELH - L`h'ELL) - (L`h'EHL - L`h'EHH) )) / 3
	
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
	mat etQ[`j',1] = (`i'+2)/3 // to align with the time 
	local j = `j' + 1

}

cap drop bQ1 etQ1 loQ1 hiQ1 pQ1	seQ1
svmat bQ 
svmat seQ
svmat pQ
svmat etQ 
svmat loQ 
svmat hiQ

cap drop ymeanF1
su `y' if (KEi == 0 | KEi ==1 | KEi ==2 )
gen ymeanF1 = r(mean) 

end


********************************************************************************
* TWFE - double difference estimates 
********************************************************************************

cap program drop coeffExit
program def coeffExit

syntax , c(real) y(string)
local d = (`c' - 1)/2  // half window

matrix b = J(`c',1,.)
matrix se = J(`c',1,.)
matrix p = J(`c',1,.)
matrix lo = J(`c',1,.)
matrix hi = J(`c',1,.)
matrix et = J(`c',1,.)

matrix b[`d',1] =0
matrix se[`d',1] =0
matrix p[`d',1] =0
matrix lo[`d',1] =0
matrix hi[`d',1] =0
matrix et[`d',1] =0

local j = `d' + 1 
forval i=1(1)`d'{
	lincom ( (L`i'ELH - L`i'ELL) - (L`i'EHL - L`i'EHH) ) // testing if the asymmetries are significant 
	
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

cap drop ymeanF1
su `y' if KEi == 0
gen ymeanF1 = r(mean) 
end 


********************************************************************************
* TWFE HET - single differences and average monthly estimates into quarterly  
********************************************************************************

cap program drop coeffQH1
program def coeffQH1

syntax , c(real) y(string) type(string) het(string) b(real)
local d = (`c' - 1)/2  // half window
local x = `d' - 2

* LOW TO HIGH 
matrix bQL`het'`b' = J(`c',1,.)
matrix seQL`het'`b' = J(`c',1,.)
matrix pQL`het'`b' = J(`c',1,.)
matrix loQL`het'`b' = J(`c',1,.)
matrix hiQL`het'`b' = J(`c',1,.)
matrix etQL`het'`b' = J(`c',1,.)

local j = 1
forval i=`d'(-3)6{
	local k = `i' - 1
	local h = `i' - 2

	lincom ( ( F`i'ELH - F`i'ELL  ) + ///
	( F`k'ELH - F`k'ELL  ) + ///
	( F`h'ELH - F`h'ELL  ) ) /3,  level(95)
	
	mat bQL_F`i' = (r(estimate))
	mat seQL_F`i' = (r(se))
	mat pQL_F`i' = (r(p))
	mat loQL_F`i' = (r(lb))
	mat hiQL_F`i' = (r(ub))
	
	matrix bQL`het'`b'[`j',1] =bQL_F`i'
	matrix seQL`het'`b'[`j',1] =seQL_F`i'
	matrix pQL`het'`b'[`j',1] =pQL_F`i'
	matrix loQL`het'`b'[`j',1] =loQL_F`i'
	matrix hiQL`het'`b'[`j',1] =hiQL_F`i'
	mat etQL`het'`b'[`j',1] =  - `i'/3
	
	local j = `j' + 1
}

matrix bQL`het'`b'[`d',1] =0
matrix seQL`het'`b'[`d',1] =0
matrix pQL`het'`b'[`d',1] =0
matrix loQL`het'`b'[`d',1] =0
matrix hiQL`het'`b'[`d',1] =0
matrix etQL`het'`b'[`d',1] =-1

local j = `d' + 1 

* for quarter 0, just take month 0 
	lincom  ( L0ELH - L0ELL  ),  level(95) 
	
	mat bQL_L0 = (r(estimate))
	mat seQL_L0 = (r(se))
	mat pQL_L0 = (r(p))
	mat loQL_L0 = (r(lb))
	mat hiQL_L0 = (r(ub))
	
	matrix bQL`het'`b'[`j',1] =bQL_L0
	matrix seQL`het'`b'[`j',1] =seQL_L0
	matrix pQL`het'`b'[`j',1] =pQL_L0
	matrix loQL`het'`b'[`j',1] =loQL_L0
	matrix hiQL`het'`b'[`j',1] =hiQL_L0
	mat etQL`het'`b'[`j',1] = 0
	
local j = `d' + 2

forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'ELH - L`i'ELL  ) + ///
	( L`k'ELH - L`k'ELL  ) + ///
	( L`h'ELH - L`h'ELL  )) / 3,  level(95)
	
	mat bQL_L`i' = (r(estimate))
	mat seQL_L`i' = (r(se))
	mat pQL_L`i' = (r(p))
	mat loQL_L`i' = (r(lb))
	mat hiQL_L`i' = (r(ub))
	
	matrix bQL`het'`b'[`j',1] =bQL_L`i'
	matrix seQL`het'`b'[`j',1] =seQL_L`i'
	matrix pQL`het'`b'[`j',1] =pQL_L`i'
	matrix loQL`het'`b'[`j',1] =loQL_L`i'
	matrix hiQL`het'`b'[`j',1] =hiQL_L`i'
	mat etQL`het'`b'[`j',1] = (`i'+2)/3 
	local j = `j' + 1

}

cap drop bQL`het'`b'1 etQL`het'`b'1 loQL`het'`b'1 hiQL`het'`b'1 pQL`het'`b'1	seQL`het'`b'1
svmat bQL`het'`b' 
svmat seQL`het'`b'
svmat pQL`het'`b'
svmat etQL`het'`b'
svmat loQL`het'`b' 
svmat hiQL`het'`b'

*HIGH TO LOW 

matrix bQH`het'`b' = J(`c',1,.)
matrix seQH`het'`b' = J(`c',1,.)
matrix pQH`het'`b' = J(`c',1,.)
matrix loQH`het'`b' = J(`c',1,.)
matrix hiQH`het'`b' = J(`c',1,.)
matrix etQH`het'`b' = J(`c',1,.)

local j = 1
forval i=`d'(-3)4{
	local k = `i' - 1
	local h = `i' - 2

	lincom (( F`i'EHL - F`i'EHH  ) + ///
	( F`k'EHL - F`k'EHH  ) + ///
	( F`h'EHL - F`h'EHH  ) ) /3,  level(95)
	
	mat bQH_F`i' = (r(estimate))
	mat seQH_F`i' = (r(se))
	mat pQH_F`i' = (r(p))
	mat loQH_F`i' = (r(lb))
	mat hiQH_F`i' = (r(ub))
	
	matrix bQH`het'`b'[`j',1] =bQH_F`i'
	matrix seQH`het'`b'[`j',1] =seQH_F`i'
	matrix pQH`het'`b'[`j',1] =pQH_F`i'
	matrix loQH`het'`b'[`j',1] =loQH_F`i'
	matrix hiQH`het'`b'[`j',1] =hiQH_F`i'
	mat etQH`het'`b'[`j',1] =  - `i'/3
	
	local j = `j' + 1
}

matrix bQH`het'`b'[`d',1] =0
matrix seQH`het'`b'[`d',1] =0
matrix pQH`het'`b'[`d',1] =0
matrix loQH`het'`b'[`d',1] =0
matrix hiQH`het'`b'[`d',1] =0
matrix etQH`het'`b'[`d',1] =-1

local j = `d' + 1

* for quarter 0, just take month 0 
	lincom  ( L0EHL - L0EHH  ),  level(95)
	mat bQH_L0 = (r(estimate))
	mat seQH_L0 = (r(se))
	mat pQH_L0 = (r(p))
	mat loQH_L0 = (r(lb))
	mat hiQH_L0 = (r(ub))
	
	matrix bQH`het'`b'[`j',1] =bQH_L0
	matrix seQH`het'`b'[`j',1] =seQH_L0
	matrix pQH`het'`b'[`j',1] =pQH_L0
	matrix loQH`het'`b'[`j',1] =loQH_L0
	matrix hiQH`het'`b'[`j',1] =hiQH_L0
	mat etQH`het'`b'[`j',1] = 0
	
local j = `d' + 2
forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'EHL - L`i'EHH  ) + ///
	( L`k'EHL - L`k'EHH  ) + ///
	( L`h'EHL - L`h'EHH  )) / 3,  level(95)
	
	mat bQH_L`i' = (r(estimate))
	mat seQH_L`i' = (r(se))
	mat pQH_L`i' = (r(p))
	mat loQH_L`i' = (r(lb))
	mat hiQH_L`i' = (r(ub))
	
	matrix bQH`het'`b'[`j',1] =bQH_L`i'
	matrix seQH`het'`b'[`j',1] =seQH_L`i'
	matrix pQH`het'`b'[`j',1] =pQH_L`i'
	matrix loQH`het'`b'[`j',1] =loQH_L`i'
	matrix hiQH`het'`b'[`j',1] =hiQH_L`i'
	mat etQH`het'`b'[`j',1] = (`i'+2)/3 
	local j = `j' + 1

}


cap drop bQH`het'`b'1 etQH`het'`b'1 loQH`het'`b'1 hiQH`het'`b'1 pQH`het'`b'1 seQH`het'`b'1
svmat bQH`het'`b' 
svmat seQH`het'`b'
svmat pQH`het'`b'
svmat etQH`het'`b' 
svmat loQH`het'`b' 
svmat hiQH`het'`b'

* Low baseline 
cap drop ymeanF1L
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (`type'LLB==1   | `type'LHB==1  )  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

* High baseline 
cap drop ymeanF1H
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (`type'HLB==1   | `type'HHB==1  )  // modified 
gen ymeanF1H = r(mean) 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)
end

********************************************************************************
* EXIT TWFE HET - single differences and average monthly estimates into quarterly
********************************************************************************

cap program drop coeffExitQH1
program def coeffExitQH1

syntax , c(real) y(string) type(string) het(string) b(real)
local d = (`c' - 1)/2  // half window
local x = `d' - 2

* LOW TO HIGH 
matrix bQL`het'`b' = J(`c',1,.)
matrix seQL`het'`b' = J(`c',1,.)
matrix pQL`het'`b' = J(`c',1,.)
matrix loQL`het'`b' = J(`c',1,.)
matrix hiQL`het'`b' = J(`c',1,.)
matrix etQL`het'`b' = J(`c',1,.)

matrix bQL`het'`b'[`d',1] =0
matrix seQL`het'`b'[`d',1] =0
matrix pQL`het'`b'[`d',1] =0
matrix loQL`het'`b'[`d',1] =0
matrix hiQL`het'`b'[`d',1] =0
matrix etQL`het'`b'[`d',1] =0

local j = `d' + 1 

forval i=1(3)`x'{
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
	
	matrix bQL`het'`b'[`j',1] =bQL_L`i'
	matrix seQL`het'`b'[`j',1] =seQL_L`i'
	matrix pQL`het'`b'[`j',1] =pQL_L`i'
	matrix loQL`het'`b'[`j',1] =loQL_L`i'
	matrix hiQL`het'`b'[`j',1] =hiQL_L`i'
	mat etQL`het'`b'[`j',1] = (`i'+2)/3 
	local j = `j' + 1

}

cap drop bQL`het'`b'1 etQL`het'`b'1 loQL`het'`b'1 hiQL`het'`b'1 pQL`het'`b'1	seQL`het'`b'1
svmat bQL`het'`b' 
svmat seQL`het'`b'
svmat pQL`het'`b'
svmat etQL`het'`b' 
svmat loQL`het'`b' 
svmat hiQL`het'`b'

*HIGH TO LOW 
matrix bQH`het'`b' = J(`c',1,.)
matrix seQH`het'`b' = J(`c',1,.)
matrix pQH`het'`b' = J(`c',1,.)
matrix loQH`het'`b' = J(`c',1,.)
matrix hiQH`het'`b' = J(`c',1,.)
matrix etQH`het'`b' = J(`c',1,.)

matrix bQH`het'`b'[`d',1] =0
matrix seQH`het'`b'[`d',1] =0
matrix pQH`het'`b'[`d',1] =0
matrix loQH`het'`b'[`d',1] =0
matrix hiQH`het'`b'[`d',1] =0
matrix etQH`het'`b'[`d',1] =0

local j = `d' + 1
	
forval i=1(3)`x'{
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
	
	matrix bQH`het'`b'[`j',1] =bQH_L`i'
	matrix seQH`het'`b'[`j',1] =seQH_L`i'
	matrix pQH`het'`b'[`j',1] =pQH_L`i'
	matrix loQH`het'`b'[`j',1] =loQH_L`i'
	matrix hiQH`het'`b'[`j',1] =hiQH_L`i'
	mat etQH`het'`b'[`j',1] = (`i'+2)/3 
	local j = `j' + 1

}


cap drop bQH`het'`b'1 etQH`het'`b'1 loQH`het'`b'1 hiQH`het'`b'1 pQH`het'`b'1	seQH`het'`b'1
svmat bQH`het'`b' 
svmat seQH`het'`b'
svmat pQH`het'`b'
svmat etQH`het'`b' 
svmat loQH`het'`b' 
svmat hiQH`het'`b'

* Low baseline 
cap drop ymeanF1L
su `y' if (KEi ==0 | KEi ==1 | KEi ==2 ) &  (`type'LLB==1   | `type'LHB==1  )  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

* High baseline 
cap drop ymeanF1H
su `y' if (KEi == 0 | KEi ==1 | KEi ==2) &  (`type'HLB==1   | `type'HHB==1  )  // modified 
gen ymeanF1H = r(mean) 

su ymeanF1H
local ymeanF1H = round(r(mean), 0.001)

end


********************************************************************************
* TWFE - single  difference estimates - LH  vs LL only to speed up estimation
********************************************************************************

cap program drop coeffLH1
program def coeffLH1

syntax , c(real) y(string) type(string)
local d = (`c' - 1)/2  // half window

* LOW TO HIGH 
matrix bL = J(`c',1,.)
matrix seL = J(`c',1,.)
matrix pL = J(`c',1,.)
matrix loL = J(`c',1,.)
matrix hiL = J(`c',1,.)
matrix etL = J(`c',1,.)

local j =1
local jointLH "(F`d'ELH - F`d'ELL)"
forval i=`d'(-1)2{
	
		if `i'>2 {
local t = `i'-1
		local fLH "(F`t'ELH - F`t'ELL)"
}
else {
local fLH " " 
}
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

		if `i'>2 {
	local jointLH "`jointLH' + `fLH'" 
}
else {
}

}

cap drop jointLH
lincom `jointLH'
gen jointLH =  (r(p))

matrix bL[`d',1] =0
matrix seL[`d',1] =0
matrix pL[`d',1] =0
matrix loL[`d',1] =0
matrix hiL[`d',1] =0
matrix etL[`d',1] =-1

local j = `d' + 1
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
	local j = `j' + 1
}

cap drop bL1 etL1 loL1 hiL1 pL1	seL1
svmat bL 
svmat seL
svmat pL
svmat etL 
svmat loL 
svmat hiL 


* Low baseline 
cap drop ymeanF1L
su `y' if KEi == -1 &  (`type'LLB==1 | `type'LHB==1  )  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)
 
end 



********************************************************************************
* TWFE - single differences and average monthly estimates into quarterly  - LH  vs LL only to speed up estimation
********************************************************************************

cap program drop coeffQLH1
program def coeffQLH1

syntax , c(real) y(string) type(string)
local d = (`c' - 1)/2  // half window
local x = `d' - 2

* LOW TO HIGH 
matrix bQL = J(`c',1,.)
matrix seQL = J(`c',1,.)
matrix pQL = J(`c',1,.)
matrix loQL = J(`c',1,.)
matrix hiQL = J(`c',1,.)
matrix etQL = J(`c',1,.)

local j = 1
forval i=`d'(-3)6{
	local k = `i' - 1
	local h = `i' - 2

	lincom ( ( F`i'ELH - F`i'ELL  ) + ///
	( F`k'ELH - F`k'ELL  ) + ///
	( F`h'ELH - F`h'ELL  ) ) /3,  level(95)
	
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
	mat etQL[`j',1] =  - `i'/3
	
	local j = `j' + 1
}

matrix bQL[`d',1] =0
matrix seQL[`d',1] =0
matrix pQL[`d',1] =0
matrix loQL[`d',1] =0
matrix hiQL[`d',1] =0
matrix etQL[`d',1] =-1

local j = `d' + 1 

* for quarter 0, just take month 0 
	lincom  ( L0ELH - L0ELL  ),  level(95) 
	
	mat bQL_L0 = (r(estimate))
	mat seQL_L0 = (r(se))
	mat pQL_L0 = (r(p))
	mat loQL_L0 = (r(lb))
	mat hiQL_L0 = (r(ub))
	
	matrix bQL[`j',1] =bQL_L0
	matrix seQL[`j',1] =seQL_L0
	matrix pQL[`j',1] =pQL_L0
	matrix loQL[`j',1] =loQL_L0
	matrix hiQL[`j',1] =hiQL_L0
	mat etQL[`j',1] = 0
	

local j = `d' + 2

forval i=1(3)`x'{
	local k = `i' + 1
	local h = `i' + 2
	lincom ( ( L`i'ELH - L`i'ELL  ) + ///
	( L`k'ELH - L`k'ELL  ) + ///
	( L`h'ELH - L`h'ELL  )) / 3,  level(95)
	
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
	mat etQL[`j',1] = (`i'+2)/3 
	local j = `j' + 1

}

cap drop bQL1 etQL1 loQL1 hiQL1 pQL1	seQL1
svmat bQL 
svmat seQL
svmat pQL
svmat etQL 
svmat loQL 
svmat hiQL

* Low baseline 
cap drop ymeanF1L
su `y' if (KEi == -1 | KEi == -2  | KEi == -3 ) &  (`type'LLB==1   | `type'LHB==1  )  // modified 
gen ymeanF1L = r(mean) 

su ymeanF1L
local ymeanF1L = round(r(mean), 0.001)

end

**********


********************************************************************************
* JOINT PRE TRENDS TEST PVALUE & OUTCOME MEAN - LH  vs LL only to speed up estimation
********************************************************************************

cap program drop pretrendLH
program def pretrendLH

syntax , end(real) y(string)

local t = `end'-1
local jointL "F`end'ELH - F`end'ELL" 

forval i=`t'(-1)2{
	local jointL "`jointL' + F`i'ELH - F`i'ELL"

	di "`i'"
}


cap drop jointL
lincom `jointL'
gen jointL =  (r(p))


end 

 
