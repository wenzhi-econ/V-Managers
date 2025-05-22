local i = 0 
foreach var in TransferSJVC ChangeSalaryGradeC {
    local i = `i' + 1
    graph drop _all 
    foreach result in Coef1_Gains Coef2_Loss Coef3_GainsMinusLoss {
        graph use "${Results}/007EventStudiesWithMngrFEBasedMeasures/FE50_Outcome`i'_`var'_`result'.gph"
        graph export "${Results}/007EventStudiesWithMngrFEBasedMeasures/FE50_Outcome`i'_`var'_`result'.pdf", replace as(pdf)
    }
}
local i = 0 
foreach var in TransferSJVC ChangeSalaryGradeC {
    local i = `i' + 1
    graph drop _all 
    foreach result in Coef1_Gains Coef2_Loss Coef3_GainsMinusLoss {
        graph use "${Results}/007EventStudiesWithMngrFEBasedMeasures/FE33_Outcome`i'_`var'_`result'.gph"
        graph export "${Results}/007EventStudiesWithMngrFEBasedMeasures/FE33_Outcome`i'_`var'_`result'.pdf", replace as(pdf)
    }
}




local i = 0 
foreach var in TransferSJVC ChangeSalaryGradeC {
    local i = `i' + 1
    graph drop _all 
    foreach result in Coef1_Gains Coef2_Loss Coef3_GainsMinusLoss {
        foreach measure in FE50 FE33 WL1FE50 WL1FE33 SJ50 SJ33 WL1SJ50 WL1SJ33 CS50 CS33 WL1CS50 WL1CS33 {
            graph use "${Results}/007EventStudiesWithMngrFEBasedMeasures/`measure'_Outcome`i'_`var'_`result'.gph"
            graph export "${Results}/007EventStudiesWithMngrFEBasedMeasures/`measure'_Outcome`i'_`var'_`result'.pdf", replace as(pdf)
        } 
    }
}