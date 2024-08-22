********************************************************************************
* Where do these workers transfer to? 
* Transition matrix - evaluating starting func and func 3 years after 
* only 6 biggest Func 
********************************************************************************

*use "$managersdta/SwitchersAllSameTeam.dta", clear 
use "$managersdta/SwitchersAllSameTeam2.dta", clear 

global Label FT // PromSG75  FT odd 

* Relevant event indicator  
rename (KEi Ei) =AllTypes
local Label $Label 
bys IDlse: egen Ei = mean(cond( (`Label'LLPost ==1 | `Label'LHPost ==1 | `Label'HLPost ==1 | `Label'HHPost ==1 ) & YearMonth==EiAllTypes ,EiAllTypes ,. ))

keep if Ei!=. 
gen KEi  = YearMonth - Ei

* only select WL2+ managers 
bys IDlse: egen WLMEi =mean(cond(Ei == YearMonth, WLM,.))
bys IDlse: egen WLMEiPre =mean(cond(Ei- 1 == YearMonth, WLM,.))
gen WLM2 = WLMEi > 1 & WLMEiPre  >1

* Re-labelling some functions and subfunctions  
label define Func 99 `"Other"', modify // add label 
label define SubFunc 999 `"Other, Same Func."', modify // add label 
label define SubFunc 9999 `"Other, Diff. Func."', modify // add label 
label define SubFunc 63 `"Science\&Tech Discovery"', modify // add label 
label define SubFunc 56  `"R\&D General Mgmt"', modify // add label 
label define SubFunc 67 `"SC General Mgmt"', modify // add label 

******* SubFunctionS
ta SubFunc if Func ==11 , sort // SC (25% of employment)
ta SubFunc if Func ==10, sort // R&D (8% of employment)
ta SubFunc if Func ==3 , sort // CD (40% of employment)
ta SubFunc if Func ==9 , sort // MARKETING

local Label $Label 
foreach v in LLPost  LHPost HLPost HHPost {
	
bys IDlse: egen Func0`v' = mean(cond(KEi==0 & `Label'`v' == 1, Func, .))
bys IDlse: egen Func1`v' = mean(cond(KEi==36 & `Label'`v' == 1, Func, .))
bys IDlse: egen SubFunc0`v' = mean(cond(KEi==0 & `Label'`v' == 1, SubFunc, .))
bys IDlse: egen SubFunc1`v' = mean(cond(KEi==36 & `Label'`v' == 1, SubFunc, .))

* Function
********************************************************************************

gen BigFunc0`v' = 99 if Func0`v'!=.
replace BigFunc0`v' = Func0`v' if (Func0`v' == 3 | Func0`v' == 4 | Func0`v' == 5 | Func0`v' == 6 | Func0`v' == 7 | Func0`v' == 9 |  Func0`v' == 10 |  Func0`v' ==  11 ) 

gen BigFunc1`v' = 99 if Func1`v'!=.
replace BigFunc1`v' = Func1`v' if (Func1`v' == 3 | Func1`v' == 4 | Func1`v' == 5 | Func1`v' == 6 | Func1`v' == 7 | Func1`v' == 9 |  Func1`v' == 10 |  Func1`v' ==  11 ) 

label value BigFunc0`v' Func
label value BigFunc1`v' Func
label var BigFunc0`v' "Function at t=0"
label var BigFunc1`v' "Function at t=36"

* R&D 
********************************************************************************

gen BigSubFuncRD0`v' = 9999 if  SubFunc0`v'!=. // R&D FOCUS 
replace BigSubFuncRD0`v' = 999 if  BigFunc0`v'==10 // R&D FOCUS 

replace BigSubFuncRD0`v' = SubFunc0`v' if (SubFunc0`v' == 53 | SubFunc0`v' == 63 | SubFunc0`v' == 56 | SubFunc0`v' == 45 | SubFunc0`v' == 51 | SubFunc0`v' == 8 ) 

gen BigSubFuncRD1`v' = 9999 if  SubFunc1`v'!=.
replace BigSubFuncRD1`v' = 999 if  BigFunc1`v'==10 // R&D FOCUS 
replace BigSubFuncRD1`v' = SubFunc1`v' if (SubFunc1`v' == 53 | SubFunc1`v' == 63 | SubFunc1`v' == 56 | SubFunc1`v' == 45 | SubFunc1`v' == 51 | SubFunc1`v' == 8 ) 

* SC
********************************************************************************
gen BigSubFuncSC0`v' = 9999  if  SubFunc0`v'!=. // SC FOCUS 
replace BigSubFuncSC0`v' = 999 if  BigFunc0`v'==11 // SC FOCUS 

replace BigSubFuncSC0`v' = SubFunc0`v' if (SubFunc0`v' == 37 | SubFunc0`v' == 35 | SubFunc0`v' == 50 | SubFunc0`v' == 60 | SubFunc0`v' == 52 | SubFunc0`v' == 17 | SubFunc0`v' == 55 | SubFunc0`v' == 67 | SubFunc0`v' == 16) 

gen BigSubFuncSC1`v' = 9999 if  SubFunc1`v'!=.
replace BigSubFuncSC1`v' = 999 if  BigFunc1`v'==11 // SC FOCUS 

replace BigSubFuncSC1`v' = SubFunc1`v' if (SubFunc1`v' == 37 | SubFunc1`v' == 35 | SubFunc1`v' == 50 | SubFunc1`v' == 60 | SubFunc1`v' == 52 | SubFunc1`v' == 17 | SubFunc1`v' == 55 | SubFunc1`v' == 67 | SubFunc1`v' == 16 ) 

label value BigSubFuncSC0`v' SubFunc
label value BigSubFuncSC1`v' SubFunc
label value BigSubFuncRD0`v' SubFunc
label value BigSubFuncRD1`v' SubFunc

label var BigSubFuncRD0`v' "R\&D at t=0"
label var BigSubFuncRD1`v' "R\&D at t=36"
label var BigSubFuncSC0`v' "SC at t=0"
label var BigSubFuncSC1`v' "SC at t=36"

}

* TRANSITION MATRIX 
********************************************************************************

egen o = tag(IDlse)

local Label $Label 
**# ON PAPER: TransitionFTLLPost.tex, TransitionFTLHPost.tex, TransitionFTHLPost.tex, TransitionFTHHPost.tex
foreach v in LLPost  LHPost HLPost HHPost {
eststo clear
eststo: estpost tab BigFunc0`v'  BigFunc1`v' if o==1 & WLM2==1 , 
esttab using "$analysis/Results/5.Mechanisms/Transition`Label'`v'.tex", ///
	cell(rowpct(fmt(2))) unstack collabels("") nonumber noobs postfoot("\hline"  "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. Biggest eight functions only (98\% of employment). Rows indicate the functions at the start while columns indicate the functions 36 months after the manager transition.   ///
 "\end{tablenotes}") replace 
}
*eststo: estpost tab BigFunc0`v'  BigFunc1`v' if o==1 & WLM2==1

* R&D
local Label $Label 
**# ON PAPER: TransitionRDFTLHPost.tex, TransitionRDFTLLPost.tex
foreach v in LLPost  LHPost HLPost HHPost {
eststo clear
eststo: estpost tab BigSubFuncRD0`v'  BigSubFuncRD1`v' if o==1  & WLM2==1, 
esttab using "$analysis/Results/5.Mechanisms/TransitionRD`Label'`v'.tex",  ///
	cell(rowpct(fmt(2))) unstack collabels("") varlabels(`e(labels)') eqlabels(`e(eqlabels)') nonumber noobs postfoot("\hline"  "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. R\&D only (8\% of employment). Rows indicate the functions at the start while columns indicate the functions 36 months after the manager transition.   ///
 "\end{tablenotes}") replace 
}

* SC
local Label $Label 
**# ON PAPER: TransitionSCFTLHPost.tex, TransitionSCFTLLPost.tex
foreach v in LLPost  LHPost HLPost HHPost {
eststo clear
eststo: estpost tab BigSubFuncSC0`v'  BigSubFuncSC1`v' if o==1  & WLM2==1, 
esttab using "$analysis/Results/5.Mechanisms/TransitionSC`Label'`v'.tex",  ///
	cell(rowpct(fmt(2))) unstack collabels("") varlabels(`e(labels)') eqlabels(`e(eqlabels)') nonumber noobs postfoot("\hline"  "\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. Supply Chain (SC) only (25\% of employment). Rows indicate the functions at the start while columns indicate the functions 36 months after the manager transition.   ///
 "\end{tablenotes}") replace 
}
