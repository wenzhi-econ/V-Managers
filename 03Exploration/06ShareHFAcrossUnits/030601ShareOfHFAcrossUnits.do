/* 
This do file calculates the share of H-managers among all WL2 managers inside an office.

Input:
    "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta" <== constructed in 0104 do file 
    "${TempData}/02Mngr_EarlyAgeM.dta" <== constructed in 0102 do file 

RA: WWZ 
Time: 2024-11-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. get employees' HF status 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies_EarlyAgeM.dta", clear 

drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 
rename (IDlseMHR EarlyAgeM) (IDlse EarlyAge)

keep  IDlse WL YearMonth Year EarlyAge Office SubFunc Func 
order IDlse WL YearMonth Year EarlyAge Office SubFunc Func 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. count manager and hf managers at different levels 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*!! for an employee, in a given year-month, is he a manager, is he a high-flyer manager?
generate manager = (WL==2)
generate hf_manager = (WL==2 & EarlyAge==1)

*!! office level count 
sort Office IDlse YearMonth
bysort Office: egen NOM_O   = total(manager)
bysort Office: egen NOHFM_O = total(hf_manager)
generate ShareHF_O = NOHFM_O / NOM_O

*!! office-year level count 
sort Office Year IDlse YearMonth
bysort Office Year: egen NOM_OY   = total(manager)
bysort Office Year: egen NOHFM_OY = total(hf_manager)
generate ShareHF_OY = NOHFM_OY / NOM_OY

*!! office-function level count 
sort Office Func IDlse YearMonth
bysort Office Func: egen NOM_OF   = total(manager)
bysort Office Func: egen NOHFM_OF = total(hf_manager)
generate ShareHF_OF = NOHFM_OF / NOM_OF

*!! office-year-function level count 
sort Office Func Year IDlse YearMonth
bysort Office Func Year: egen NOM_OFY   = total(manager)
bysort Office Func Year: egen NOHFM_OFY = total(hf_manager)
generate ShareHF_OFY = NOHFM_OFY / NOM_OFY

*!! subfunction level count 
sort SubFunc IDlse YearMonth
bysort SubFunc: egen NOM_SF   = total(manager)
bysort SubFunc: egen NOHFM_SF = total(hf_manager)
generate ShareHF_SF = NOHFM_SF / NOM_SF

save "${TempData}/temp_ShareOfHFAcrossUnits.dta", replace 


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce plots 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. office level 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_ShareOfHFAcrossUnits.dta", clear 

keep Office ShareHF_O NOM_O NOHFM_O
duplicates drop 

summarize ShareHF_O, detail
global Mean = r(mean)

graph twoway scatter ShareHF_O Office [aweight=NOM_O] ///
    , msymbol(Oh) ///
    yline(${Mean}, lcolor(red)) ///
    xtitle("Office code") ytitle("Share of high-flyer managers") ///
    title("Share of H-managers across offices")

kdensity ShareHF_O, xtitle("Share of high-flyer managers")
histogram ShareHF_O, fraction xtitle("Share of high-flyer managers")
cdfplot ShareHF_O, xtitle("Share of high-flyer managers") ytitle("Cumulative probability")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. office-year level 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_ShareOfHFAcrossUnits.dta", clear 

keep Office Year ShareHF_OY NOM_OY NOHFM_OY
duplicates drop 

egen OY_group = group(Office Year)

summarize ShareHF_OY, detail
global Mean = r(mean)

graph twoway scatter ShareHF_OY OY_group [aweight=NOM_OY] ///
    , msymbol(Oh) ///
    yline(${Mean}, lcolor(red)) ///
    xtitle("Office-year code") ytitle("Share of high-flyer managers") ///
    title("Share of H-managers across office-year pairs")

kdensity ShareHF_OY, xtitle("Share of high-flyer managers")
histogram ShareHF_OY, fraction xtitle("Share of high-flyer managers")
cdfplot ShareHF_OY, xtitle("Share of high-flyer managers") ytitle("Cumulative probability")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. office-function level 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_ShareOfHFAcrossUnits.dta", clear 

keep Office Func ShareHF_OF NOM_OF NOHFM_OF
duplicates drop 

egen OF_group = group(Office Func)

summarize ShareHF_OF, detail
global Mean = r(mean)

graph twoway scatter ShareHF_OF OF_group [aweight=NOM_OF] ///
    , msymbol(Oh) ///
    yline(${Mean}, lcolor(red)) ///
    xtitle("Office-function code") ytitle("Share of high-flyer managers") ///
    title("Share of H-managers across office-year pairs")

kdensity ShareHF_OF, xtitle("Share of high-flyer managers")
histogram ShareHF_OF, fraction xtitle("Share of high-flyer managers")

cdfplot ShareHF_OF ///
    , xline(${Mean}, lcolor(red)) ///
    xtitle("Share of high-flyer managers") ytitle("Cumulative probability")


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-4. office-year-function level 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_ShareOfHFAcrossUnits.dta", clear 

keep Office Year Func ShareHF_OFY NOM_OFY NOHFM_OFY
duplicates drop 

egen OFY_group = group(Office Func Year)

summarize ShareHF_OFY, detail
global Mean = r(mean)

graph twoway scatter ShareHF_OFY OFY_group [aweight=NOM_OFY] ///
    , msymbol(Oh) ///
    yline(${Mean}, lcolor(red)) ///
    xtitle("Office-function-year code") ytitle("Share of high-flyer managers") ///
    title("Share of H-managers across office-year pairs")

kdensity ShareHF_OFY, xtitle("Share of high-flyer managers")
histogram ShareHF_OFY, fraction xtitle("Share of high-flyer managers")

cdfplot ShareHF_OFY ///
    , xline(${Mean}, lcolor(red)) ///
    xtitle("Share of high-flyer managers") ytitle("Cumulative probability")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. subfunction level 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_ShareOfHFAcrossUnits.dta", clear 

keep SubFunc ShareHF_SF NOM_SF NOHFM_SF
duplicates drop 

summarize ShareHF_SF, detail
global Mean = r(mean)

graph twoway scatter ShareHF_SF SubFunc [aweight=NOM_SF] ///
    , msymbol(Oh) ///
    yline(${Mean}, lcolor(red)) ///
    xtitle("Subfunction code") ytitle("Share of high-flyer managers") ///
    title("Share of H-managers across subfunctions")

kdensity ShareHF_SF, xtitle("Share of high-flyer managers")
histogram ShareHF_SF, fraction xtitle("Share of high-flyer managers")

cdfplot ShareHF_SF ///
    , xline(${Mean}, lcolor(red)) ///
    xtitle("Share of high-flyer managers") ytitle("Cumulative probability")