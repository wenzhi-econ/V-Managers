********************************************************************************
* DEFINE VALUE LABELS FOR ALL VARIABLES - DICTIONARY 
********************************************************************************

* MANAGER TYPES AND OUTCOMES 
********************************************************************************

label var TeamSize "Team Size"
label var PayBonusCV "CV (salary)"
label var VPACV "CV (perf. appraisal)"
label var TeamTransferSJ "Job change (all)"
label var TeamTransferInternalSJ "Job change (all)"
label var TeamTransferInternalSJDiffM  "Job change (outside team)"
label var TeamTransferInternalSJSameM  "Job change (within team)"
label var TeamLeaverVol "Exit"
label var ShareInternalSJMoves "Share job moves within team"
label var WLM "Work Level"
label var DirectorM "LM Director +"
label var VPAHighM "Perf. appr. M >=125"
label var LineManager "Effective Leader"
label var LineManagerB "Effective Leader"
label var PayBonusGrowthM "Salary Growth M"
label var PayBonusGrowthMB "Salary Growth M"
label var SGSpeedM "Prom. Speed (salary)"
label var SGSpeedMB "Prom. Speed (salary)"
label var ChangeSalaryGradeRMMean "Team mean prom. (salary)"
label var ChangeSalaryGradeRMMeanB "Team mean prom. (salary)"
label var LeaverVolRMMean "Team mean vol. exit"
label var LeaverVolRMMeanB "Team mean vol. exit"
label var EarlyAgeM "Fast track M."
label var EarlyTenureM  "Fast track M. (tenure)"
label var TeamChangeSalaryGrade "Promotion (salary)"
label var LargeSpanM "Large span of control"

* MANAGER BALANCE TABLES 
********************************************************************************

* PRE- TEAM CHARS VARIABLES 
label var PrePayBonusCV "CV (salary)"
label var PreVPACV "CV (perf. appraisal)"
label var PreTeamTransferInternalSJ "Job change (all)"
label var PreTeamTransferInternalSJDiffM  "Job change (outside team)"
label var PreTeamTransferInternalSJSameM  "Job change (within team)"
label var PreTeamLeaverVol "Exit"
label var PreShareInternalSJMoves "Share job moves within team"
label var PreTeamChangeSalaryGrade "Promotion (salary)"

* STANDARD BALANCE TABLE 
label var FemaleM "Female"
label var AgeBandM "Age Group" 
label var AgeContinuous "Age"
label var TenureM "Tenure (years)" 
label var WLM   "WL"
label var TeamSize "Team Size"
label var ShareSameG "Team share, same gender"
label var ShareFemale "Team share, female"
label var ShareOutGroup  "Team share, diff. homecountry" 
label var LogPayBonusM  "Pay + Bonus (logs)"
label var LeaverPermM "Exit"
label var PromWLCM  "No. Prom. WL"
label var VPAM   "Perf. appraisal (1-150)"
label var PRIM "Perf. appraisal (1-5)"
label var LineManager "LM effective leader"
label var ShareDiffOffice  "Team share, diff. office"
label var PayBonusGrowthM  "Salary growth"

* EMPLOYEE BALANCE TABLES 
********************************************************************************

label var Female "Female"
label var AgeBand "Age Group" 
label var AgeContinuous "Age"
label var Tenure "Tenure (years)" 
label var WL  "WL"
label var OutGroup  "Diff. homecountry from LM" 
label var LogPayBonus  "Pay + Bonus (logs)"
label var LeaverPerm "Exit"
label var PromWLC  "No. Prom. WL"
label var VPA   "Perf. appraisal (1-150)"
label var PRI "Perf. appraisal (1-5)"
label var PayBonusGrowth  "Salary growth"
label var DiffOffice "Diff. office from LM"


* EMPLOYEE OUTCOMES 
********************************************************************************

label var LogPayBonus  "Pay + Bonus (logs)"

label var LeaverPerm "Exit"
label var LeaverVol "Exit (Vol.)"
label var LeaverInv "Exit (Inv.)"

label var PromWL "Prom. (work-level)"
label var PromWLC "Prom. (work-level)"

label var ChangeSalaryGrade "Salary Grade Increase"
label var ChangeSalaryGradeC "Salary Grade Increase"

label var TransferSJ "Transfer: job"
label var TransferSJC "Transfer: job"
label var TransferSJSameMC "Transfer: job, same M."
label var TransferSJSameM "Transfer: job, same M."
label var TransferSJDiffMC "Transfer: job, diff. M."
label var TransferSJDiffM "Transfer: job, diff. M."

label var TransferSJL "Transfer: job (lateral)"
label var TransferSJLC "Transfer: job (lateral)"
label var TransferSJSameMLC "Transfer: job (lateral), same M."
label var TransferSJSameML "Transfer: job (lateral), same M."
label var TransferSJDiffMLC "Transfer: job (lateral), diff. M."
label var TransferSJDiffML "Transfer: job (lateral), diff. M."

label var TransferSJLL "Transfer: job (lateral)"
label var TransferSJLLC "Transfer: job (lateral)"
label var TransferSJSameMLLC "Transfer: job (lateral), same M."
label var TransferSJSameMLL "Transfer: job (lateral), same M."
label var TransferSJDiffMLLC "Transfer: job (lateral), diff. M."
label var TransferSJDiffMLL "Transfer: job (lateral), diff. M."


label var TransferInternal "Transfer: office/sub-division"
label var TransferInternalC "Transfer: office/sub-division"
label var TransferInternalSameMC "Transfer: office/sub-division, same M."
label var TransferInternalSameM "Transfer: office/sub-division, same M."
label var TransferInternalDiffMC "Transfer: office/sub-division, diff. M."
label var TransferInternalDiffM "Transfer: office/sub-division, diff. M."

label var TransferInternalL "Transfer: office/sub-division (lateral)"
label var TransferInternalLC "Transfer: office/sub-division (lateral)"
label var TransferInternalSameMLC "Transfer: office/sub-division (lateral), same M."
label var TransferInternalSameML "Transfer: office/sub-division (lateral), same M."
label var TransferInternalDiffMLC "Transfer: office/sub-division (lateral), diff. M."
label var TransferInternalDiffML "Transfer: office/sub-division (lateral), diff. M."

label var TransferInternalLL "Transfer: office/sub-division (lateral)"
label var TransferInternalLLC "Transfer: office/sub-division (lateral)"
label var TransferInternalSameMLLC "Transfer: office/sub-division (lateral), same M."
label var TransferInternalSameMLL "Transfer: office/sub-division (lateral), same M."
label var TransferInternalDiffMLLC "Transfer: office/sub-division (lateral), diff. M."
label var TransferInternalDiffMLL "Transfer: office/sub-division (lateral), diff. M."


label var TransferInternalSJ "Transfer: job/office/sub-division"
label var TransferInternalSJC "Transfer: job/office/sub-division"
label var TransferInternalSJSameMC "Transfer: job/office/sub-division, same M."
label var TransferInternalSJSameM "Transfer: job/office/sub-division, same M."
label var TransferInternalSJDiffMC "Transfer: job/office/sub-division, diff. M."
label var TransferInternalSJDiffM "Transfer: job/office/sub-division, diff. M."

label var TransferInternalSJL "Transfer: job/office/sub-division (lateral)"
label var TransferInternalSJLC "Transfer: job/office/sub-division (lateral)"
label var TransferInternalSJSameMLC "Transfer: job/office/sub-division (lateral), same M."
label var TransferInternalSJSameML "Transfer: job/office/sub-division (lateral), same M."
label var TransferInternalSJDiffMLC "Transfer: job/office/sub-division (lateral), diff. M."
label var TransferInternalSJDiffML "Transfer: job/office/sub-division (lateral), diff. M."

label var TransferInternalSJLL "Transfer: job/office/sub-division (lateral)"
label var TransferInternalSJLLC "Transfer: job/office/sub-division (lateral)"
label var TransferInternalSJSameMLLC "Transfer: job/office/sub-division (lateral), same M."
label var TransferInternalSJSameMLL "Transfer: job/office/sub-division (lateral), same M."
label var TransferInternalSJDiffMLLC "Transfer: job/office/sub-division (lateral), diff. M."
label var TransferInternalSJDiffMLL "Transfer: job/office/sub-division (lateral), diff. M."

* SCALE OF GRAPHS AT 1S.D. WITHIN INDIVIDUAL 
use "$managersdta/AllSwitchersSameTeam2.dta", clear 

xtsum ChangeSalaryGradeC TransferSJC TransferFuncC PromWLC // 0.5  / 0.9 / 0.2 / 0.1



