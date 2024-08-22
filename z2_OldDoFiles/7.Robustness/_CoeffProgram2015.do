
********************************************************************************
* PROGRAMS for 2016-2020 dataset (robustness)
********************************************************************************

********************************************************************************
* PROGRAM FOR STATIC TABLE
********************************************************************************
**# PROGRAM USED IN "7.3.CohortStatic2015"
cap program drop coeffStaticCohort2015
program def coeffStaticCohort2015

local j = 1

* LOW LOW
matrix bLL = J(`j',1,.)
matrix seLL = J(`j',1,.)
matrix pLL = J(`j',1,.)
matrix loLL = J(`j',1,.)
matrix hiLL = J(`j',1,.)

lincom ( sharesELL2016[`j',1] * ELL_2016 + sharesELL2017[`j',1] * ELL_2017 + sharesELL2018[`j',1] * ELL_2018 + sharesELL2019[`j',1] * ELL_2019 + sharesELL2020[`j',1] * ELL_2020)

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

lincom (sharesELH2016[`j',1] * ELH_2016 + sharesELH2017[`j',1] * ELH_2017 + sharesELH2018[`j',1] * ELH_2018 + sharesELH2019[`j',1] * ELH_2019 + sharesELH2020[`j',1] * ELH_2020) 

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

lincom (sharesELH2016[`j',1] * ELH_2016 + sharesELH2017[`j',1] * ELH_2017 + sharesELH2018[`j',1] * ELH_2018 + sharesELH2019[`j',1] * ELH_2019 + sharesELH2020[`j',1] * ELH_2020) - (sharesELL2016[`j',1] * ELL_2016 + sharesELL2017[`j',1] * ELL_2017 + sharesELL2018[`j',1] * ELL_2018 + sharesELL2019[`j',1] * ELL_2019 + sharesELL2020[`j',1] * ELL_2020)
		
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

lincom ( sharesEHL2016[`j',1] * EHL_2016 + sharesEHL2017[`j',1] * EHL_2017 + sharesEHL2018[`j',1] * EHL_2018 + sharesEHL2019[`j',1] * EHL_2019 + sharesEHL2020[`j',1] * EHL_2020)

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

lincom (sharesEHH2016[`j',1] * EHH_2016 + sharesEHH2017[`j',1] * EHH_2017 + sharesEHH2018[`j',1] * EHH_2018 + sharesEHH2019[`j',1] * EHH_2019 + sharesEHH2020[`j',1] * EHH_2020) 

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

lincom (sharesEHH2016[`j',1] * EHH_2016 + sharesEHH2017[`j',1] * EHH_2017 + sharesEHH2018[`j',1] * EHH_2018 + sharesEHH2019[`j',1] * EHH_2019 + sharesEHH2020[`j',1] * EHH_2020) - ( sharesEHL2016[`j',1] * EHL_2016 + sharesEHL2017[`j',1] * EHL_2017 + sharesEHL2018[`j',1] * EHL_2018 + sharesEHL2019[`j',1] * EHL_2019 + sharesEHL2020[`j',1] * EHL_2020)
	
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
end
////////////////////////////////////////////////////////////////////////////////

