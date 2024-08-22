* This dofile creates new variables for the analysis of managers 

//STEP 1A: Impute age [TODO: check code]
use "$managersdta/AllSnapshotMCulture.dta", clear
cap drop minage-YobB
gen minage = ///
	(AgeBand == 1) * 18 + ///
	(AgeBand == 2) * 30 + ///
	(AgeBand == 3) * 40 + ///
	(AgeBand == 4) * 50 + ///
	(AgeBand == 5) * 60 + ///
	(AgeBand == 6) * 70 + ///
	(AgeBand == 7) * 16
gen maxage = ///
	(AgeBand == 1) * 29 + ///
	(AgeBand == 2) * 39 + ///
	(AgeBand == 3) * 49 + ///
	(AgeBand == 4) * 59 + ///
	(AgeBand == 5) * 69 + ///
	(AgeBand == 6) * 79 + ///
	(AgeBand == 7) * 18
replace minage = . if AgeBand == 8
replace maxage = . if AgeBand == 8
gen minyob = Year - maxage
gen maxyob = Year - minage
bysort IDlse: egen MINyob = max(minyob)
bysort IDlse: egen MAXyob = min(maxyob)
gen Yob = (MINyob + MAXyob)/2
replace Yob = Yob - 0.5 if mod(MINyob + MAXyob, 2) == 1




//STEP 1B: Plot distribution of age at promotion for WL2 [TODO]


//STEP 2: Construct manager chain [TODO]
* have a look at Dropbox\Managers\Paper Culture\Dofiles\3.0.Construct manager chain

use "$managersdta/AllSnapshotMCulture.dta", clear
* output should be a dataset at the IDlse YearMonth level that shows first manager, second manager higher in the hierarchy etc 