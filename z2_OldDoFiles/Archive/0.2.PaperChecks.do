********************************************************************************
* Paper checks 
********************************************************************************

* Set globals 
********************************************************************************

* choose the manager type !MANUAL INPUT!
global Label  FT  // PromWL75 PromSG75 PromWL50 PromSG50  FT odd  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 pay75F60
global typeM  EarlyAgeM  // EarlyAgeM LineManagerMeanB MFEBayesPromSG75 MFEBayesPromWL75 MFEBayesPromSG50 MFEBayesPromWL50 oddManager  pcaFTSG50 pcaFTPay50  pcaFTSG75 pcaFTPay75 MFEBayesLogPayF6075 MFEBayesLogPayF7275 

global cont   c.TenureM##c.TenureM
* global abs CountryYear AgeBand AgeBandM IDlse  // usual 
global abs YearMonth  IDlse   // alternative, to try WLM AgeBandM YearMonth AgeBand Tenure

* global analysis  "/Users/virginiaminni/Desktop/Managers Temp" // Globals already defined in 0.0.Managers Master

********************************************************************************
* Probability you are with same manager after 18 months 
********************************************************************************

*use "$managersdta/SwitchersAllSameTeam2.dta", clear 
use "$managersdta/AllSameTeam2.dta", clear 

bys IDlse: egen IDlseMHREi = mean(cond(KEi==0, IDlseMHR , .))
gen SameM = IDlseMHR == IDlseMHREi if IDlseMHR!=. & IDlseMHREi!=.
bys IDlseMHR YearMonth: egen totSameM = sum(SameM)
gen shareSameM =    totSameM /TeamSize


foreach y in   FTLHPost   FTLLPost   FTHLPost   FTHHPost{
su shareSameM  if KEi==6 & `y'==1 , d
su shareSameM  if KEi==12 & `y'==1 , d 
su shareSameM  if KEi==18 & `y'==1, d
su shareSameM  if KEi==24 & `y'==1, d
}

*use results collapsed at the team level
preserve
collapse shareSameM (max) KEi FTLHPost   FTLLPost   FTHLPost   FTHHPost , by(IDlseMHR YearMonth)


foreach y in   FTLHPost   FTLLPost   FTHLPost   FTHHPost{
su shareSameM  if KEi==12 & `y'==1 , d
su shareSameM  if KEi==18 & `y'==1, d // key indicator, and look at p25 - it is 0 for all groups  
}
restore 

