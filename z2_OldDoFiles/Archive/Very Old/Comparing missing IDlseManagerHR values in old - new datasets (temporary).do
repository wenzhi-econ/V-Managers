

use "$data/OldDatasetUnmatched.dta", replace
keep IDlse YearMonth
tempfile temp
save `temp', replace

use "$data/NewDatasetUnmatched.dta", replace
keep IDlse YearMonth

merge 1:1 IDlse YearMonth using `temp'

keep if _merge == 2
drop _merge

save `temp', replace

use "$dta/AllSnapshotWCMIDlse.dta",replace

merge 1:1 IDlse YearMonth using `temp'
keep if _merge == 3

save "$dta/PresentinNew.dta",replace
use "$dta/AllSnapshotWCM.dta", clear

