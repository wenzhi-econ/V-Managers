********************************************************************************
* PROGRAM FOR STATIC TABLE
********************************************************************************

cap program drop coeffStaticCohortVPA
program def coeffStaticCohortVPA

local j = 1

foreach h in _VL _VM _VH {

* LOW LOW

matrix bLL`h' = J(`j',1,.)
matrix seLL`h' = J(`j',1,.)
matrix pLL`h' = J(`j',1,.)
matrix loLL`h' = J(`j',1,.)
matrix hiLL`h' = J(`j',1,.)

lincom (sharesELL2011`h'[`j',1] * ELL_2011`h' + sharesELL2012`h'[`j',1] * ELL_2012`h' + sharesELL2013`h'[`j',1] * ELL_2013`h' + sharesELL2014`h'[`j',1] * ELL_2014`h' + sharesELL2015`h'[`j',1] * ELL_2015`h' + sharesELL2016`h'[`j',1] * ELL_2016`h' + sharesELL2017`h'[`j',1] * ELL_2017`h' + sharesELL2018`h'[`j',1] * ELL_2018`h' + sharesELL2019`h'[`j',1] * ELL_2019`h' + sharesELL2020`h'[`j',1] * ELL_2020`h')

	mat bLL`h' = (r(estimate))
	mat seLL`h' = (r(se))
	mat pLL`h' = (r(p))
	mat loLL`h' = (r(lb))
	mat hiLL`h' = (r(ub))
	
	matrix bLL`h'[`j',1] =bLL`h'
	matrix seLL`h'[`j',1] =seLL`h'
	matrix pLL`h'[`j',1] =pLL`h'
	matrix loLL`h'[`j',1] =loLL`h'
	matrix hiLL`h'[`j',1] =hiLL`h'
	

* LOW HIGH
matrix bLH`h' = J(`j',1,.)
matrix seLH`h' = J(`j',1,.)
matrix pLH`h' = J(`j',1,.)
matrix loLH`h' = J(`j',1,.)
matrix hiLH`h' = J(`j',1,.)

lincom (sharesELH2011`h'[`j',1] * ELH_2011`h' + sharesELH2012`h'[`j',1] * ELH_2012`h' + sharesELH2013`h'[`j',1] * ELH_2013`h' + sharesELH2014`h'[`j',1] * ELH_2014`h' + sharesELH2015`h'[`j',1] * ELH_2015`h' + sharesELH2016`h'[`j',1] * ELH_2016`h' + sharesELH2017`h'[`j',1] * ELH_2017`h' + sharesELH2018`h'[`j',1] * ELH_2018`h' + sharesELH2019`h'[`j',1] * ELH_2019`h' + sharesELH2020`h'[`j',1] * ELH_2020`h')

	mat bLH`h' = (r(estimate))
	mat seLH`h' = (r(se))
	mat pLH`h'= (r(p))
	mat loLH`h' = (r(lb))
	mat hiLH`h' = (r(ub))
	
	matrix bLH`h'[`j',1] =bLH`h'
	matrix seLH`h'[`j',1] =seLH`h'
	matrix pLH`h'[`j',1] =pLH`h'
	matrix loLH`h'[`j',1] =loLH`h'
	matrix hiLH`h'[`j',1] =hiLH`h'

	
* DOUBLE DIFF: LOW TO HIGH 
matrix bL`h' = J(`j',1,.)
matrix seL`h' = J(`j',1,.)
matrix pL`h' = J(`j',1,.)
matrix loL`h' = J(`j',1,.)
matrix hiL`h' = J(`j',1,.)

lincom (sharesELH2011`h'[`j',1] * ELH_2011`h' + sharesELH2012`h'[`j',1] * ELH_2012`h' + sharesELH2013`h'[`j',1] * ELH_2013`h' + sharesELH2014`h'[`j',1] * ELH_2014`h' + sharesELH2015`h'[`j',1] * ELH_2015`h' + sharesELH2016`h'[`j',1] * ELH_2016`h' + sharesELH2017`h'[`j',1] * ELH_2017`h' + sharesELH2018`h'[`j',1] * ELH_2018`h' + sharesELH2019`h'[`j',1] * ELH_2019`h' + sharesELH2020`h'[`j',1] * ELH_2020`h')- (sharesELL2011`h'[`j',1] * ELL_2011`h' + sharesELL2012`h'[`j',1] * ELL_2012`h' + sharesELL2013`h'[`j',1] * ELL_2013`h' + sharesELL2014`h'[`j',1] * ELL_2014`h' + sharesELL2015`h'[`j',1] * ELL_2015`h' + sharesELL2016`h'[`j',1] * ELL_2016`h' + sharesELL2017`h'[`j',1] * ELL_2017`h' + sharesELL2018`h'[`j',1] * ELL_2018`h' + sharesELL2019`h'[`j',1] * ELL_2019`h' + sharesELL2020`h'[`j',1] * ELL_2020`h')
		
	mat bL`h' = (r(estimate))
	mat seL`h' = (r(se))
	mat pL`h' = (r(p))
	mat loL`h' = (r(lb))
	mat hiL`h' = (r(ub))
	
	matrix bL`h'[`j',1] =bL`h'
	matrix seL`h'[`j',1] =seL`h'
	matrix pL`h'[`j',1] =pL`h'
	matrix loL`h'[`j',1] =loL`h'
	matrix hiL`h'[`j',1] =hiL`h'


cap drop bL`h'1  loL`h'1 hiL`h'1 pL`h'1	seL`h'1 
cap drop bLL`h'1 seLL`h'1 bLH`h'1 seLH`h'1
svmat bL`h' 
svmat bLL`h'
svmat bLH`h'
svmat seL`h'
svmat seLL`h'
svmat seLH`h'
svmat pL`h'
svmat loL`h' 
svmat hiL`h' 

* HIGH LOW
matrix bHL`h' = J(`j',1,.)
matrix seHL`h' = J(`j',1,.)
matrix pHL`h' = J(`j',1,.)
matrix loHL`h' = J(`j',1,.)
matrix hiHL`h' = J(`j',1,.)

lincom (sharesEHL2011`h'[`j',1] * EHL_2011`h' + sharesEHL2012`h'[`j',1] * EHL_2012`h' + sharesEHL2013`h'[`j',1] * EHL_2013`h' + sharesEHL2014`h'[`j',1] * EHL_2014`h' + sharesEHL2015`h'[`j',1] * EHL_2015`h' + sharesEHL2016`h'[`j',1] * EHL_2016`h' + sharesEHL2017`h'[`j',1] * EHL_2017`h' + sharesEHL2018`h'[`j',1] * EHL_2018`h' + sharesEHL2019`h'[`j',1] * EHL_2019`h' + sharesEHL2020`h'[`j',1] * EHL_2020`h')

	mat bHL`h' = (r(estimate))
	mat seHL`h' = (r(se))
	mat pHL`h' = (r(p))
	mat loHL`h' = (r(lb))
	mat hiHL`h' = (r(ub))
	
	matrix bHL`h'[`j',1] =bHL`h'
	matrix seHL`h'[`j',1] =seHL`h'
	matrix pHL`h'[`j',1] =pHL`h'
	matrix loHL`h'[`j',1] =loHL`h'
	matrix hiHL`h'[`j',1] =hiHL`h'
	


* LOW HIGH
matrix bHH`h' = J(`j',1,.)
matrix seHH`h' = J(`j',1,.)
matrix pHH`h' = J(`j',1,.)
matrix loHH`h' = J(`j',1,.)
matrix hiHH`h' = J(`j',1,.)

lincom (sharesEHH2011`h'[`j',1] * EHH_2011`h' + sharesEHH2012`h'[`j',1] * EHH_2012`h' + sharesEHH2013`h'[`j',1] * EHH_2013`h' + sharesEHH2014`h'[`j',1] * EHH_2014`h' + sharesEHH2015`h'[`j',1] * EHH_2015`h' + sharesEHH2016`h'[`j',1] * EHH_2016`h' + sharesEHH2017`h'[`j',1] * EHH_2017`h' + sharesEHH2018`h'[`j',1] * EHH_2018`h' + sharesEHH2019`h'[`j',1] * EHH_2019`h' + sharesEHH2020`h'[`j',1] * EHH_2020`h')

	mat bHH`h' = (r(estimate))
	mat seHH`h' = (r(se))
	mat pHH`h'= (r(p))
	mat loHH`h' = (r(lb))
	mat hiHH`h' = (r(ub))
	
	matrix bHH`h'[`j',1] =bHH`h'
	matrix seHH`h'[`j',1] =seHH`h'
	matrix pHH`h'[`j',1] =pHH`h'
	matrix loHH`h'[`j',1] =loHH`h'
	matrix hiHH`h'[`j',1] =hiHH`h'
	
	
	* HIGH TO LOW 
matrix bH`h' = J(`j',1,.)
matrix seH`h' = J(`j',1,.)
matrix pH`h' = J(`j',1,.)
matrix loH`h' = J(`j',1,.)
matrix hiH`h' = J(`j',1,.)

lincom  (sharesEHL2011`h'[`j',1] * EHL_2011`h' + sharesEHL2012`h'[`j',1] * EHL_2012`h' + sharesEHL2013`h'[`j',1] * EHL_2013`h' + sharesEHL2014`h'[`j',1] * EHL_2014`h' + sharesEHL2015`h'[`j',1] * EHL_2015`h' + sharesEHL2016`h'[`j',1] * EHL_2016`h' + sharesEHL2017`h'[`j',1] * EHL_2017`h' + sharesEHL2018`h'[`j',1] * EHL_2018`h' + sharesEHL2019`h'[`j',1] * EHL_2019`h' + sharesEHL2020`h'[`j',1] * EHL_2020`h') - (sharesEHH2011`h'[`j',1] * EHH_2011`h' + sharesEHH2012`h'[`j',1] * EHH_2012`h' + sharesEHH2013`h'[`j',1] * EHH_2013`h' + sharesEHH2014`h'[`j',1] * EHH_2014`h' + sharesEHH2015`h'[`j',1] * EHH_2015`h' + sharesEHH2016`h'[`j',1] * EHH_2016`h' + sharesEHH2017`h'[`j',1] * EHH_2017`h' + sharesEHH2018`h'[`j',1] * EHH_2018`h' + sharesEHH2019`h'[`j',1] * EHH_2019`h' + sharesEHH2020`h'[`j',1] * EHH_2020`h')
	
	mat bH`h' = (r(estimate))
	mat seH`h' = (r(se))
	mat pH`h' = (r(p))
	mat loH`h' = (r(lb))
	mat hiH`h' = (r(ub))
	
	matrix bH`h'[`j',1] =bH`h'
	matrix seH`h'[`j',1] =seH`h'
	matrix pH`h'[`j',1] =pH`h'
	matrix loH`h'[`j',1] =loH`h'
	matrix hiH`h'[`j',1] =hiH`h'
	
cap drop bH`h'1  loH`h'1 hiH`h'1 pH`h'1	seH`h'1
cap drop bHL`h'1 seHL`h'1 bHH`h'1 seHH`h'1
svmat bH`h' 
svmat bHL`h'
svmat bHH`h'
svmat seH`h'
svmat seHL`h'
svmat seHH`h'
svmat pH`h'
svmat loH`h'
svmat hiH`h' 
}
end
////////////////////////////////////////////////////////////////////////////////

* PROGRAM FOR PAY  
////////////////////////////////////////////////////////////////////////////////

cap program drop coeffStaticCohortPayGrowth
program def coeffStaticCohortPayGrowth

syntax , het(string) 

local j = 1

foreach h in `het' {

* LOW LOW

matrix bLL`h' = J(`j',1,.)
matrix seLL`h' = J(`j',1,.)
matrix pLL`h' = J(`j',1,.)
matrix loLL`h' = J(`j',1,.)
matrix hiLL`h' = J(`j',1,.)

lincom (sharesELL2011`h'[`j',1] * ELL_2011`h' + sharesELL2012`h'[`j',1] * ELL_2012`h' + sharesELL2013`h'[`j',1] * ELL_2013`h' + sharesELL2014`h'[`j',1] * ELL_2014`h' + sharesELL2015`h'[`j',1] * ELL_2015`h' + sharesELL2016`h'[`j',1] * ELL_2016`h' + sharesELL2017`h'[`j',1] * ELL_2017`h' + sharesELL2018`h'[`j',1] * ELL_2018`h' + sharesELL2019`h'[`j',1] * ELL_2019`h' + sharesELL2020`h'[`j',1] * ELL_2020`h')

	mat bLL`h' = (r(estimate))
	mat seLL`h' = (r(se))
	mat pLL`h' = (r(p))
	mat loLL`h' = (r(lb))
	mat hiLL`h' = (r(ub))
	
	matrix bLL`h'[`j',1] =bLL`h'
	matrix seLL`h'[`j',1] =seLL`h'
	matrix pLL`h'[`j',1] =pLL`h'
	matrix loLL`h'[`j',1] =loLL`h'
	matrix hiLL`h'[`j',1] =hiLL`h'
	

* LOW HIGH
matrix bLH`h' = J(`j',1,.)
matrix seLH`h' = J(`j',1,.)
matrix pLH`h' = J(`j',1,.)
matrix loLH`h' = J(`j',1,.)
matrix hiLH`h' = J(`j',1,.)

lincom (sharesELH2011`h'[`j',1] * ELH_2011`h' + sharesELH2012`h'[`j',1] * ELH_2012`h' + sharesELH2013`h'[`j',1] * ELH_2013`h' + sharesELH2014`h'[`j',1] * ELH_2014`h' + sharesELH2015`h'[`j',1] * ELH_2015`h' + sharesELH2016`h'[`j',1] * ELH_2016`h' + sharesELH2017`h'[`j',1] * ELH_2017`h' + sharesELH2018`h'[`j',1] * ELH_2018`h' + sharesELH2019`h'[`j',1] * ELH_2019`h' + sharesELH2020`h'[`j',1] * ELH_2020`h')

	mat bLH`h' = (r(estimate))
	mat seLH`h' = (r(se))
	mat pLH`h'= (r(p))
	mat loLH`h' = (r(lb))
	mat hiLH`h' = (r(ub))
	
	matrix bLH`h'[`j',1] =bLH`h'
	matrix seLH`h'[`j',1] =seLH`h'
	matrix pLH`h'[`j',1] =pLH`h'
	matrix loLH`h'[`j',1] =loLH`h'
	matrix hiLH`h'[`j',1] =hiLH`h'

	
* DOUBLE DIFF: LOW TO HIGH 
matrix bL`h' = J(`j',1,.)
matrix seL`h' = J(`j',1,.)
matrix pL`h' = J(`j',1,.)
matrix loL`h' = J(`j',1,.)
matrix hiL`h' = J(`j',1,.)

lincom (sharesELH2011`h'[`j',1] * ELH_2011`h' + sharesELH2012`h'[`j',1] * ELH_2012`h' + sharesELH2013`h'[`j',1] * ELH_2013`h' + sharesELH2014`h'[`j',1] * ELH_2014`h' + sharesELH2015`h'[`j',1] * ELH_2015`h' + sharesELH2016`h'[`j',1] * ELH_2016`h' + sharesELH2017`h'[`j',1] * ELH_2017`h' + sharesELH2018`h'[`j',1] * ELH_2018`h' + sharesELH2019`h'[`j',1] * ELH_2019`h' + sharesELH2020`h'[`j',1] * ELH_2020`h')- (sharesELL2011`h'[`j',1] * ELL_2011`h' + sharesELL2012`h'[`j',1] * ELL_2012`h' + sharesELL2013`h'[`j',1] * ELL_2013`h' + sharesELL2014`h'[`j',1] * ELL_2014`h' + sharesELL2015`h'[`j',1] * ELL_2015`h' + sharesELL2016`h'[`j',1] * ELL_2016`h' + sharesELL2017`h'[`j',1] * ELL_2017`h' + sharesELL2018`h'[`j',1] * ELL_2018`h' + sharesELL2019`h'[`j',1] * ELL_2019`h' + sharesELL2020`h'[`j',1] * ELL_2020`h')
		
	mat bL`h' = (r(estimate))
	mat seL`h' = (r(se))
	mat pL`h' = (r(p))
	mat loL`h' = (r(lb))
	mat hiL`h' = (r(ub))
	
	matrix bL`h'[`j',1] =bL`h'
	matrix seL`h'[`j',1] =seL`h'
	matrix pL`h'[`j',1] =pL`h'
	matrix loL`h'[`j',1] =loL`h'
	matrix hiL`h'[`j',1] =hiL`h'


cap drop bL`h'1  loL`h'1 hiL`h'1 pL`h'1	seL`h'1 
cap drop bLL`h'1 seLL`h'1 bLH`h'1 seLH`h'1
svmat bL`h' 
svmat bLL`h'
svmat bLH`h'
svmat seL`h'
svmat seLL`h'
svmat seLH`h'
svmat pL`h'
svmat loL`h' 
svmat hiL`h' 

* HIGH LOW
matrix bHL`h' = J(`j',1,.)
matrix seHL`h' = J(`j',1,.)
matrix pHL`h' = J(`j',1,.)
matrix loHL`h' = J(`j',1,.)
matrix hiHL`h' = J(`j',1,.)

lincom (sharesEHL2011`h'[`j',1] * EHL_2011`h' + sharesEHL2012`h'[`j',1] * EHL_2012`h' + sharesEHL2013`h'[`j',1] * EHL_2013`h' + sharesEHL2014`h'[`j',1] * EHL_2014`h' + sharesEHL2015`h'[`j',1] * EHL_2015`h' + sharesEHL2016`h'[`j',1] * EHL_2016`h' + sharesEHL2017`h'[`j',1] * EHL_2017`h' + sharesEHL2018`h'[`j',1] * EHL_2018`h' + sharesEHL2019`h'[`j',1] * EHL_2019`h' + sharesEHL2020`h'[`j',1] * EHL_2020`h')

	mat bHL`h' = (r(estimate))
	mat seHL`h' = (r(se))
	mat pHL`h' = (r(p))
	mat loHL`h' = (r(lb))
	mat hiHL`h' = (r(ub))
	
	matrix bHL`h'[`j',1] =bHL`h'
	matrix seHL`h'[`j',1] =seHL`h'
	matrix pHL`h'[`j',1] =pHL`h'
	matrix loHL`h'[`j',1] =loHL`h'
	matrix hiHL`h'[`j',1] =hiHL`h'
	


* LOW HIGH
matrix bHH`h' = J(`j',1,.)
matrix seHH`h' = J(`j',1,.)
matrix pHH`h' = J(`j',1,.)
matrix loHH`h' = J(`j',1,.)
matrix hiHH`h' = J(`j',1,.)

lincom (sharesEHH2011`h'[`j',1] * EHH_2011`h' + sharesEHH2012`h'[`j',1] * EHH_2012`h' + sharesEHH2013`h'[`j',1] * EHH_2013`h' + sharesEHH2014`h'[`j',1] * EHH_2014`h' + sharesEHH2015`h'[`j',1] * EHH_2015`h' + sharesEHH2016`h'[`j',1] * EHH_2016`h' + sharesEHH2017`h'[`j',1] * EHH_2017`h' + sharesEHH2018`h'[`j',1] * EHH_2018`h' + sharesEHH2019`h'[`j',1] * EHH_2019`h' + sharesEHH2020`h'[`j',1] * EHH_2020`h')

	mat bHH`h' = (r(estimate))
	mat seHH`h' = (r(se))
	mat pHH`h'= (r(p))
	mat loHH`h' = (r(lb))
	mat hiHH`h' = (r(ub))
	
	matrix bHH`h'[`j',1] =bHH`h'
	matrix seHH`h'[`j',1] =seHH`h'
	matrix pHH`h'[`j',1] =pHH`h'
	matrix loHH`h'[`j',1] =loHH`h'
	matrix hiHH`h'[`j',1] =hiHH`h'
	
	
	* HIGH TO LOW 
matrix bH`h' = J(`j',1,.)
matrix seH`h' = J(`j',1,.)
matrix pH`h' = J(`j',1,.)
matrix loH`h' = J(`j',1,.)
matrix hiH`h' = J(`j',1,.)

lincom (sharesEHL2011`h'[`j',1] * EHL_2011`h' + sharesEHL2012`h'[`j',1] * EHL_2012`h' + sharesEHL2013`h'[`j',1] * EHL_2013`h' + sharesEHL2014`h'[`j',1] * EHL_2014`h' + sharesEHL2015`h'[`j',1] * EHL_2015`h' + sharesEHL2016`h'[`j',1] * EHL_2016`h' + sharesEHL2017`h'[`j',1] * EHL_2017`h' + sharesEHL2018`h'[`j',1] * EHL_2018`h' + sharesEHL2019`h'[`j',1] * EHL_2019`h' + sharesEHL2020`h'[`j',1] * EHL_2020`h') - (sharesEHH2011`h'[`j',1] * EHH_2011`h' + sharesEHH2012`h'[`j',1] * EHH_2012`h' + sharesEHH2013`h'[`j',1] * EHH_2013`h' + sharesEHH2014`h'[`j',1] * EHH_2014`h' + sharesEHH2015`h'[`j',1] * EHH_2015`h' + sharesEHH2016`h'[`j',1] * EHH_2016`h' + sharesEHH2017`h'[`j',1] * EHH_2017`h' + sharesEHH2018`h'[`j',1] * EHH_2018`h' + sharesEHH2019`h'[`j',1] * EHH_2019`h' + sharesEHH2020`h'[`j',1] * EHH_2020`h')
	
	mat bH`h' = (r(estimate))
	mat seH`h' = (r(se))
	mat pH`h' = (r(p))
	mat loH`h' = (r(lb))
	mat hiH`h' = (r(ub))
	
	matrix bH`h'[`j',1] =bH`h'
	matrix seH`h'[`j',1] =seH`h'
	matrix pH`h'[`j',1] =pH`h'
	matrix loH`h'[`j',1] =loH`h'
	matrix hiH`h'[`j',1] =hiH`h'
	
cap drop bH`h'1  loH`h'1 hiH`h'1 pH`h'1	seH`h'1
cap drop bHL`h'1 seHL`h'1 bHH`h'1 seHH`h'1
svmat bH`h' 
svmat bHL`h'
svmat bHH`h'
svmat seH`h'
svmat seHL`h'
svmat seHH`h'
svmat pH`h'
svmat loH`h'
svmat hiH`h' 
}
end
////////////////////////////////////////////////////////////////////////////////

