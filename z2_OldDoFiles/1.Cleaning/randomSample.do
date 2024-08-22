********************************************************************************
* Create random samples of workers 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 
keep IDlse 
duplicates drop IDlse , force 

set seed 1234
sample 50

gen random50 = 1 

save "$managersdta/Temp/Random50.dta", replace 


use "$managersdta/AllSnapshotMCulture.dta", clear 
keep IDlse 
duplicates drop IDlse , force 

set seed 1234
sample 25

gen random25 = 1 

save "$managersdta/Temp/Random25.dta", replace 

use "$managersdta/AllSnapshotMCulture.dta", clear 
keep IDlse 
duplicates drop IDlse , force 

set seed 1234
sample 10

gen random10 = 1 

save "$managersdta/Temp/Random10.dta", replace 

use "$managersdta/AllSnapshotMCulture.dta", clear 

bys IDlse: egen mWL= min(WL)
keep if mWL==1

keep IDlse 
duplicates drop IDlse , force 

sort IDlse
set seed 25081993
sample 15

gen random15 = 1 

save "$managersdta/Temp/Random15v.dta", replace 

* only WL1
use "$managersdta/AllSnapshotMCulture.dta", clear 

bys IDlse: egen mWL= min(WL)
keep if mWL==1

keep IDlse 
duplicates drop IDlse , force 
sort IDlse
set seed 25011882
sample 20

gen random20 = 1 

save "$managersdta/Temp/Random20vw.dta", replace

* only WL1
use "$managersdta/AllSnapshotMCulture.dta", clear 

bys IDlse: egen mWL= min(WL)
keep if mWL==1

keep IDlse 
duplicates drop IDlse , force 
sort IDlse
set seed 25011882
sample 50

gen random50 = 1 

save "$managersdta/Temp/Random50vw.dta", replace

* only WL1
use "$managersdta/AllSnapshotMCulture.dta", clear 

bys IDlse: egen mWL= min(WL)
keep if mWL==1

keep IDlse 
duplicates drop IDlse , force 
sort IDlse
set seed 25081993
sample 10

gen random10 = 1 

save "$managersdta/Temp/Random10v.dta", replace 

* only WL1
use "$managersdta/AllSnapshotMCulture.dta", clear 

bys IDlse: egen mWL= min(WL)
keep if mWL==1

keep IDlse 
duplicates drop IDlse , force 
sort IDlse
set seed 25081993
sample 25

gen random25 = 1 

save "$managersdta/Temp/Random25v.dta", replace 

* only WL1
use "$managersdta/AllSnapshotMCulture.dta", clear 

bys IDlse: egen mWL= min(WL)
keep if mWL==1

keep IDlse 
duplicates drop IDlse , force 
sort IDlse
set seed 17081993
sample 10 

gen random10 = 1 

save "$managersdta/Temp/Random10s.dta", replace 





