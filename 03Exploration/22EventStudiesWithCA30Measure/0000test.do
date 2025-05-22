




//&? codes for the original output

use "${RawMNEData}/AllSnapshotWC.dta", clear 

keep if YearMonth == tm(2019m1)
generate one = 1
collapse (sum) OfficeSize = one, by(OfficeCode)
label variable OfficeSize "Office size"

summarize OfficeSize, detail 
    global Median = r(p50)
graph twoway ///
    (histogram OfficeSize, width(1) fraction), ///
    xline(${Median}, lcolor(maroon)) ///
    xlabel(0(50)1500, angle(45)) ///
    text(0.08 ${Median} "Median = ${Median}", place(e))









use "${RawMNEData}/OfficeSize.dta", clear 
keep if YearMonth == tm(2019m1)

summarize TotWorkersWC, detail 
    global Median = r(p50)
graph twoway ///
    (histogram TotWorkersWC, width(1) fraction), ///
    xline(${Median}, lcolor(maroon)) ///
    xlabel(0(50)1500, angle(45)) ///
    text(0.08 ${Median} "Median = ${Median}", place(e)) ///
    title("White collar workers") name(TotWorkersWC, replace)

summarize TotWorkers, detail 
    global Median = r(p50)
graph twoway ///
    (histogram TotWorkers, width(1) fraction), ///
    xline(${Median}, lcolor(maroon)) ///
    xlabel(0(50)1500, angle(45)) ///
    text(0.08 ${Median} "Median = ${Median}", place(e)) ///
    title("All workers") name(TotWorkers, replace)
