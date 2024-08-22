
********************************************************************************
**                     Cleaning Univoice with IDlseMHR                        **
**                            BC & WC workers                                 **
**                              7 Nov, 2020                                   **
/*******************************************************************************

Input: $dta/UniVoiceSnapshot.dta
Output:  $Managersdta/UniVoiceSnapshotM.dta
*/

cd "$Managersdta"

*********************************************************************************
*  UniVoice BC & WC: Identifying managers in the Original Dataset
*********************************************************************************

*I identify managers in UniVoiceSnapshot.dta using the tempfile.

use "$dta/UniVoiceSnapshot.dta", clear
merge 1:1 IDlse YearMonth using "$Managersdta/Temp/Mlist.dta"
drop if _merge == 2 // unmatched obs. from ManagerIDReports.dta. 60 of these are MV

* the matched invidiauls are managers. I tag them generating a dummy Manager.
gen Manager = 0
replace Manager = 1 if _merge == 3
label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"
drop _merge

* Merging with ManagerIDReports.dta as they do not exist in UniVoiceSnapshot dataset

tempfile temp
save `temp'
use "$dta/ManagerIDReports.dta", clear

merge 1:1 IDlse YearMonth using `temp'
drop if _merge == 1 // dropping unmatched obs. from ManagerIDReports
drop _merge

*saving as UniVoiceSnapshotM.dta
save "$Managersdta/UniVoiceSnapshotM.dta",replace

*********************************************************************************
* UniVoice: Adding ISOCodeHome.
*********************************************************************************

* use UniVoiceSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/UniVoiceSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/UniVoiceSnapshotM.dta",clear
}

* Merging isocode.dta with the original data.
merge m:1 HomeCountryS using "$Managersdta/Temp/isocode.dta"
drop if _merge==2
drop _merge HomeCountryS

order ISOCodeHome, a(HomeCountry)

* 6.b. Updating UniVoiceSnapshotMIDlse.dta
save "$Managersdta/UniVoiceSnapshotM.dta",replace

*********************************************************************************
* 7. UniVoice: Merging UniVoiceSnapshotM with Mchar and adding new variables
*********************************************************************************

* use UniVoiceSnapshotMIDlse.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/UniVoiceSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/UniVoiceSnapshotM.dta",clear
}
* 7.a. Adding MListchar variables by merging the tempfile with UniVoiceSnapshotM.dta

merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/MListChar.dta"
drop if _merge == 2
drop _merge

* 7.b. Generating additional variables & modifying some variables

* Span of control
bys YearMonth IDlseMHR: gen SpanControl = _N // number of direct reports
replace SpanControl =. if IDlseMHR==.
order SpanControl, a(IDlseMHR)
label var SpanControl "No. of employees reporting to same manager in current month"

* Country Size
bysort YearMonth Country: egen CountrySize = count(IDlse) // no. of employees by country and month
label var CountrySize "No. of employees in each country and month"

* Office
distinct Office 
distinct Country 
quietly bys Office: gen dup_location = cond(_N==1,0,_n)
bys Country YearMonth: egen OfficeNum = count(Office) if (dup_location ==0 & Office !=. | dup_location ==1 & Office !=.) 
label var OfficeNum "No. of offices in each Country and Month"

* Additional variables useful for the analysis
egen CountryYM = group(Country YearMonth)
egen IDlseMHRYM = group(IDlseMHR YearMonth)
decode HomeCountryM, gen(HomeCountrySM)
order HomeCountrySM, a(HomeCountryM)


compress
save "$Managersdta/UniVoiceSnapshotM.dta",replace
