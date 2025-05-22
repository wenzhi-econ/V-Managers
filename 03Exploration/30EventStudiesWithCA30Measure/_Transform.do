/* 
This do file transforms the gph files to pdf files.

RA: WWZ 
Time: 2025-04-15
*/

foreach type in Type1_Pre24Post84 Type2_NewHires Type3_Poisson Type4_CohortDynamics Type5_Cohort1315 {
    if "`type'" == "Type1_Pre24Post84" {
        foreach result in Coef1_Gains Coef2_Loss Coef3_GainsMinusLoss {
            graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_`result'_`type'.gph"
            graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_`result'_`type'.pdf", replace as(pdf)
            graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_`result'_`type'.gph"
            graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_`result'_`type'.pdf", replace as(pdf)
        }
    }
    else {
        foreach result in Coef1_Gains Coef2_Loss {
            graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_`result'_`type'.gph"
            graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_`result'_`type'.pdf", replace as(pdf)
            graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_`result'_`type'.gph"
            graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_`result'_`type'.pdf", replace as(pdf)
        }
    }
}

foreach outcome in 2_0_TransferSJC 2_1_SameMC 2_2_DiffMC 2_3_TransferFuncC {
    foreach result in Coef1_Gains Coef2_Loss Coef3_GainsMinusLoss {
        graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome`outcome'_`result'.gph"
        graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome`outcome'_`result'.pdf", replace as(pdf)
    }
}
graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_Decomp_Q8.gph"
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_Decomp_Q8.pdf", replace as(pdf)
graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_Decomp_Q28.gph"
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome2_TransferSJC_Decomp_Q28.pdf", replace as(pdf)


foreach outcome in 3_0_TransferSJLC 3_1_SameMLC 3_2_DiffMLC 3_3_DiffFuncSJLC {
    foreach result in Coef1_Gains Coef2_Loss Coef3_GainsMinusLoss {
        graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome`outcome'_`result'.gph"
        graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome`outcome'_`result'.pdf", replace as(pdf)
    }
}
graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_Decomp_Q8.gph"
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_Decomp_Q8.pdf", replace as(pdf)
graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_Decomp_Q28.gph"
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome3_TransferSJLC_Decomp_Q28.pdf", replace as(pdf)



foreach outcome in 4_LogPayBonus {
    foreach result in Coef1_Gains Coef2_Loss Coef3_GainsMinusLoss {
        graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome`outcome'_`result'_Type1_Pre24Post84.gph"
        graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome`outcome'_`result'_Type1_Pre24Post84.pdf", replace as(pdf)
    }
}
graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome7_PromWLC_Coef1_Gains_Typez_YearlyAggregation.gph"
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome7_PromWLC_Coef1_Gains_Typez_YearlyAggregation.pdf", replace as(pdf)
graph use "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome8_CVPay_Coef1_Gains_Typez_YearlyAggregation.gph"
graph export "${Results}/010EventStudiesResultsWithCA30Measure/CA30_Outcome8_CVPay_Coef1_Gains_Typez_YearlyAggregation.pdf", replace as(pdf)