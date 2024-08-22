********************************************************************************
* June 2022
* TABLE OF MANAGER FE - R SQUARE 
********************************************************************************

use "$managersdta/AllSnapshotMCulture.dta", clear 

xtset IDlse YearMonth

gen F60LogPayBonus = f60.LogPayBonus // 5 years after 

* only take first manager  
bys IDlse: egen fM = min(YearMonth)
bys IDlse: egen fMM = mean(cond(fM== YearMonth,IDlseMHR,.))

gen one = IDlseMHR == fMM

* NOTE: ONLY REPOPRTING THE 5 YEARS HORIZON RESULTS AS CONTEMPORANEOUS PAY LOOK SIMILAR 
* ONLY REPORTING WHEN KEEPING SINGLE MANAGER (NO DUPLICATES) AS FULL SAMPLE RESULTS ARE VERY SIMILAR 

* all workers
foreach v in  LogPayBonus F60LogPayBonus {
	xtset IDlse YearMonth
areg `v' c.Tenure##c.Tenure##i.Female i.Func i.AgeBand i.Year , a(  Country  )   // residualize on managers FE
areg `v' c.Tenure##c.Tenure##i.Female i.Func i.AgeBand i.Year i.Country, a(  IDlseMHR  )   // residualize on managers FE

areg `v' c.Tenure##c.Tenure##i.Female i.Func  i.Year , a(  AgeBand )   // residualize on managers FE
areg `v' c.Tenure##c.Tenure##i.Female i.Func i.AgeBand i.Year  , a(  IDlseMHR  )   // residualize on managers FE

}

* no duplicate workers, only take the first manager 
foreach v in  LogPayBonus F60LogPayBonus {
areg `v' c.Tenure##c.Tenure##i.Female i.Func i.AgeBand i.Year if one==1, a(  Country  )   // residualize on managers FE

/* F60LogPayBonus
Linear regression, absorbing indicators         Number of obs     =  1,069,175
                                                F(  29,1069039)   =    5847.86
                                                Prob > F          =     0.0000
                                                R-squared         =     0.4855
                                                Adj R-squared     =     0.4855
                                                Root MSE          =     0.6450


*/

areg `v' c.Tenure##c.Tenure##i.Female i.Func i.AgeBand i.Year i.Country  if one==1, a(  IDlseMHR  )   // residualize on managers FE

/*  F60LogPayBonus
Linear regression, absorbing indicators         Number of obs     =  1,042,239
                                                F( 133,1024680)   =     697.06
                                                Prob > F          =     0.0000
                                                R-squared         =     0.8274
                                                Adj R-squared     =     0.8245
                                                Root MSE          =     0.3765

*/

areg `v' c.Tenure##c.Tenure##i.Female i.Func  i.Year if one==1 , a(  AgeBand )   // residualize on managers FE

/*  F60LogPayBonus
Linear regression, absorbing indicators         Number of obs     =  1,069,369
                                                F(  22,1069339)   =    9007.76
                                                Prob > F          =     0.0000
                                                R-squared         =     0.1988
                                                Adj R-squared     =     0.1988
                                                Root MSE          =     0.8048


*/

areg `v' c.Tenure##c.Tenure##i.Female i.Func i.AgeBand i.Year  if one==1, a(  IDlseMHR  )   // residualize on managers FE

/*  F60LogPayBonus
Linear regression, absorbing indicators         Number of obs     =  1,042,431
                                                F(  29,1024976)   =    2133.89
                                                Prob > F          =     0.0000
                                                R-squared         =     0.8225
                                                Adj R-squared     =     0.8195
                                                Root MSE          =     0.3818

*/

}
 
