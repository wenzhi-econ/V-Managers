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

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

drop IDlseMHR
rename IDlse IDlseMHR
merge m:1 IDlseMHR YearMonth using "${TempData}/02Mngr_EarlyAgeM.dta", keep(match master) nogenerate 
rename (IDlseMHR EarlyAgeM) (IDlse EarlyAge)

generate Year = year(dofm(YearMonth))

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
*-? s-3-3. subfunction level 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/temp_ShareOfHFAcrossUnits.dta", clear 

keep SubFunc ShareHF_SF NOM_SF NOHFM_SF
duplicates drop 

summarize NOM_SF, detail
global top25 = r(p25)
global top50 = r(p50)

preserve 

    keep if NOM_SF >= ${top25}
    summarize ShareHF_SF, detail
        global Mean = r(mean)
    graph twoway scatter ShareHF_SF SubFunc [aweight=NOM_SF] ///
        , msymbol(Oh) ///
        yline(${Mean}, lcolor(red)) ///
        xtitle("Subfunction code") ytitle("Share of high-flyer managers") ///
        title("Share of H-managers across subfunctions")
    graph export "${Results}/ShareHFAcrossSubFuncs_Top25.pdf", as(pdf) replace 

restore 

preserve 

    keep if NOM_SF >= ${top50}
    summarize ShareHF_SF, detail
        global Mean = r(mean)
    graph twoway scatter ShareHF_SF SubFunc [aweight=NOM_SF] ///
        , msymbol(Oh) ///
        yline(${Mean}, lcolor(red)) ///
        xtitle("Subfunction code") ytitle("Share of high-flyer managers") ///
        title("Share of H-managers across subfunctions")
    graph export "${Results}/ShareHFAcrossSubFuncs_Top50.pdf", as(pdf) replace 

restore 

kdensity ShareHF_SF, xtitle("Share of high-flyer managers")
histogram ShareHF_SF, fraction xtitle("Share of high-flyer managers") width(0.05)

cdfplot ShareHF_SF ///
    , xline(${Mean}, lcolor(red)) ///
    xtitle("Share of high-flyer managers") ytitle("Cumulative probability")