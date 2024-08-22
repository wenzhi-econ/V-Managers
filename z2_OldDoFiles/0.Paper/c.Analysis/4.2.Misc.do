********************************************************************************
* Computing the cost/benefit ratio of high flyer managers 
********************************************************************************

* using income statement data from ORBIS - UNILEVER FINANCIALS 
********************************************************************************

* first compute average salaries 
use "$managersdta/SwitchersAllSameTeam2.dta", clear 
*use  "$managersdta/AllSnapshotMCulture.dta", clear

* salary 
su PayBonus if WL==1 & Year==2019,d
su PayBonus  if WL==2 &EarlyAge==0 & Year==2019,d

* team size 
egen tm = tag(IDlseMHR YearMonth)
su TeamSize if WLM==2 & tm==1 & Year==2019, d

use "$managersdta/Orbis/unilever_financial.dta", replace 

* figures are in 1,000millions 
* using 2019 data 
local op = 10213147 // operating profits 
local eb =  12045093  //   EBITDA  12045093
local n = 150000 
local exc = 1.12340 // Exchange rate: EUR/USD

* data from paper 
local prodIn = 0.27 
local wageIn = 0.079
local wageM = 0.06
local teamN = 3
local PayBonusWorker =   28991.95 * `exc' // su PayBonus if WL==1 & Year=2019 and convert to USD 
local PayBonusManager =     83003.26 * `exc' // su PayBonus  if WL==2 &EarlyAge==0 & Year=2019 and convert to USD 

*di "Benefit increase per manager: "  `teamN'*(`eb'*`prodIn' / `n') *1000 - `wageIn'*`PayBonusWorker'

di "Benefit increase per manager: "  `teamN'*(`op'*`prodIn' / `n') *1000 
local b =  `teamN'*(`op'*`prodIn' / `n') *1000 

di "Extra Costs per high flyer manager: " ( `wageM'*`PayBonusManager')  
local c = ( `wageM'*`PayBonusManager') 

di "Ratio cost/benefit: " `c'/`b'
local r = `c'/`b' 