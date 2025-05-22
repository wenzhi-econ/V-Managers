/* 
This do file calculates the unique values for different levels of observations.

Input:
    ${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file

Output:
    "${Results}/SummaryStatistics_DistinctObsAtDifferentLevels.tex"

RA: WWZ
Time: 2025-03-19
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. generate relevant statistics 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear 

global obs_total = _N 

egen tag_Ind = tag(IDlse)
count if tag_Ind==1
    global obs_employee = r(N)

codebook IDlseMHR if WLM>1 & IDlseMHR!=.
egen tag_Mngr = tag(IDlseMHR) if WLM>1
count if tag_Mngr==1
    global obs_mngr = r(N)

egen tag_Supervisor = tag(IDlseMHR)
count if tag_Supervisor==1
    global obs_supervisor = r(N)

egen tag_YearMonth = tag(YearMonth)
count if tag_YearMonth==1
    global obs_YearMonth = r(N)

egen tag_SJ = tag(StandardJob)
count if tag_SJ==1
    global obs_SJ = r(N)

egen tag_SubFuncWL = tag(SubFunc WL)
count if tag_SubFuncWL==1
    global obs_SubFuncWL = r(N)

egen tag_OfficeCode = tag(OfficeCode)
count if tag_OfficeCode==1
    global obs_office = r(N)

egen tag_ISOCode = tag(ISOCode)
count if tag_ISOCode==1
    global obs_country = r(N)

egen tag_ISOYear = tag(ISOCode Year)
count if tag_ISOYear==1
    global obs_country_year = r(N)

egen tag_OfficeCodeYear = tag(OfficeCode Year)
count if tag_OfficeCodeYear==1
    global obs_office_year = r(N)

egen tag_IDSJ = tag(IDlse StandardJob)
count if tag_IDSJ==1
    global obs_IDSJ = r(N)

global obs_total        = strofreal(${obs_total}, "%10.0fc")
global obs_employee     = strofreal(${obs_employee}, "%10.0fc")
global obs_mngr         = strofreal(${obs_mngr}, "%10.0fc")
global obs_supervisor   = strofreal(${obs_supervisor}, "%10.0fc")
global obs_YearMonth    = strofreal(${obs_YearMonth}, "%10.0fc")
global obs_SJ           = strofreal(${obs_SJ}, "%10.0fc")
global obs_SubFuncWL    = strofreal(${obs_SubFuncWL}, "%10.0fc")
global obs_office       = strofreal(${obs_office}, "%10.0fc")
global obs_country      = strofreal(${obs_country}, "%10.0fc")
global obs_country_year = strofreal(${obs_country_year}, "%10.0fc")
global obs_office_year  = strofreal(${obs_office_year}, "%10.0fc")
global obs_IDSJ         = strofreal(${obs_IDSJ}, "%10.0fc")

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. produce the table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture file close pub

local file "${Results}/SummaryStatistics_DistinctObsAtDifferentLevels.tex"

file open  pub using "`file'", write replace

file write pub "\begin{tabular}{ll}" _newline
file write pub "\toprule" _newline
file write pub "\toprule" _newline
file write pub "Variable & \multicolumn{1}{c}{No. unique values}\\ " _newline
file write pub "\hline" _newline
file write pub "\multicolumn{1}{l}{Total white collar $\times$ months} & ${obs_total}  \\" _newline
file write pub "\multicolumn{1}{l}{Employee} & ${obs_employee}  \\" _newline
file write pub "\multicolumn{1}{l}{Managers (work-level 2+)} & ${obs_mngr}  \\" _newline
file write pub "\multicolumn{1}{l}{Supervisors} & ${obs_supervisor}  \\" _newline
file write pub "\multicolumn{1}{l}{Year-month} & ${obs_YearMonth}  \\" _newline
file write pub "\multicolumn{1}{l}{Standard job} & ${obs_SJ}  \\" _newline
file write pub "\multicolumn{1}{l}{Sub-function $\times$ work-level} & ${obs_SubFuncWL}  \\" _newline
file write pub "\multicolumn{1}{l}{Offices} & ${obs_office}  \\" _newline
file write pub "\multicolumn{1}{l}{Countries} & ${obs_country}  \\" _newline
file write pub "\multicolumn{1}{l}{Country $\times$ Year} & ${obs_country_year}  \\" _newline
file write pub "\multicolumn{1}{l}{Office $\times$ Year} & ${obs_office_year}  \\" _newline
file write pub "\multicolumn{1}{l}{Employee $\times$ Job} & ${obs_IDSJ}  \\" _newline
file write pub "\hline" _newline
file write pub "\end{tabular}" _newline
file write pub "\begin{tablenotes}" _newline
file write pub "\footnotesize" _newline
file write pub "\item Notes. The data contain personnel records for the entire white-collar employee base from January 2011 until December 2021." _newline
file write pub "\end{tablenotes}" _newline

file close pub
