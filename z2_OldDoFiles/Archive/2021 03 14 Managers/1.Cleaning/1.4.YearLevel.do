* This dofile collapses data at year level for summary stats 

clear all

********************************************************************************
* CREATING !FINAL YEAR LEVEL DATASET! BC & WC 
********************************************************************************

use "$Managersdta/Managers.dta", clear 

 global mode  ISOCode CountryS Office OfficeCode Market Func SubFunc PositionTitle BC Female AgeBand Tenure WL SalaryGrade SalaryGradeC FTE EmpType EmpStatus LeaveType IDlseMHR PromSalaryGradeM PromSalaryGradeCM PromSalaryGradeLateralM PromSalaryGradeLateralCM PromSalaryGradeVerticalM PromSalaryGradeVerticalCM TransferCountryM TransferCountryCM TransferFuncM TransferFuncCM TransferSubFuncM TransferSubFuncCM TransferSubFuncLateralM TransferSubFuncLateralCM TransferFuncLateralM TransferFuncLateralCM TransferPTitleM TransferPTitleCM TransferPTitleLateralM TransferPTitleLateralCM PRM VPAM LeaverPermM LeaverInvM LeaverVolM FemaleM AgeBandM TenureM BCM

 foreach var in $mode{
bys IDlse Year: egen `var'Mode = mode(`var')
replace `var' = `var'Mode
}

* leaving out the Months* variables as they require thinking about how to collapse 

global mean FirstYear VPA  PR PRI Pay Bonus Benefit Package PayBonus LogPayBonus LogPay LogBonus PRSnapshot

 global sum TransferCountry TransferCountryC TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC TransferSubFuncLateral TransferSubFuncLateralC TransferFuncLateral TransferFuncLateralC TransferPTitle TransferPTitleC TransferPTitleLateral TransferPTitleLateralC   PromSalaryGrade PromSalaryGradeC PromSalaryGradeLateral PromSalaryGradeLateralC PromSalaryGradeVertical PromSalaryGradeVerticalC LeaverPerm LeaverInv LeaverVol
 
collapse $mean  (max) $sum  (firstnm) $mode , by(IDlse Year)

save "$Managersdta/AllSnapshotY", replace 
