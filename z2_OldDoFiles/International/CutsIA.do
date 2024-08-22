reghdfe LogPayBonus $leads_ChangeM $lags_ChangeM  $leads_OutGroupIASameM $lags_OutGroupIASameM Lend_ChangeM Fend_ChangeM Lend_OutGroupIASameM Fend_OutGroupIASameM   c.Tenure##c.Tenure  , absorb(CountryYM  Func WL WLM  DiffCountry IDlse IDlseMHR ) vce(cluster IDlseMHR)
regsave  $leads_ChangeM $lags_ChangeM  $leads_OutGroupIASameM $lags_OutGroupIASameM using "$analysis/Results/2.Analysis/OutGroupIASameMEventPay.dta", ci replace

* events 
xtset IDlse YearMonth 
local max_delta = `r(tmax)' - `r(tmin)'
local first_period = -24
local last_period = 36
global event ChangeM OutGroupIASameM 

* lags
foreach x in $event {
	forvalues i = 0/`max_delta'{
		gen L`i'_`x' = L`i'.`x' == 1
}
}

*leads 
local omitted_threshold = - 1
foreach x in $event {
	forvalues i = -`max_delta'/`omitted_threshold'{
		local j = abs(`i')
		gen F`j'_`x' = F`j'.`x' == 1	
}
}

xtset IDlse YearMonth 
local max_delta = `r(tmax)' - `r(tmin)'
local first_period = -24
local last_period = 36
local omitted_threshold = - 1

foreach x in $event {
		forvalues i = 0/`max_delta'{
		if `i' > `last_period'{
			local L_absorb_`x' "`L_absorb_`x'' L`i'_`x' "  // absorbing end points

	}

	}
	*else di as text "Lags are less than specified"
	forvalues i = -`max_delta'/`omitted_threshold'{
		if `i' < `first_period'{
	local j = abs(`i')
	local F_absorb_`x' " `F_absorb_`x'' F`j'_`x'" // absorbing end points 
	}
	*else di as text "Leads are less than specified"

	}
	egen Lend_`x' = rowmax(`L_absorb_`x'')
	egen Fend_`x' = rowmax(`F_absorb_`x'')
}

* define global 
foreach x in $event  {
	forvalues i = 0/36{
	local lags_`x' "`lags_`x'' L`i'_`x' " 


	}
	global lags_`x' "`lags_`x''"

	}

foreach x in $event {
	forvalues i = 2/24{

	local leads_`x' "`leads_`x'' F`i'_`x'  "

	}	
	global leads_`x' "`leads_`x''"

	}
	
global absorb Lend_ChangeM Fend_ChangeM


gsort IDlse YearMonth 
gen OutGroupIASameM = 0 
replace OutGroupIASameM = 1 if (IDlse[_n] == IDlse[_n-1] & IDlseMHR[_n] != IDlseMHR[_n-1] & OutGroupIASame[_n] ==1 & OutGroupIASame[_n-1] ==0   ) | ( OutGroupIASame[1] ==1 & FirstYM==1) // event = 1 if change to IAM or start with IA manager 
replace OutGroupIASameM = . if IDlseMHR ==. 


* GENERATE LEADS AND LAGS TO PUT INTO MODEL
********************************************************************************

gen IAW = YearMonth - EventFirstIAM 
su IAW
recode IAW (.=-1) (`r(min)'/-25=-25) (37/`r(max)'=37 ) 
char IAW[omit] -1
xi i.IAW , pref(tt)

gen MW = YearMonth - EventChangeM 
su MW
recode MW (.=-1) (`r(min)'/-25=-25) (37/`r(max)'=37 ) 
char MW[omit] -1
xi i.MW , pref(TT)

reghdfe LogPayBonus ttIAW* TTMW* c.Tenure##c.Tenure , absorb(Country#YearMonth Func  IDlse DiffCountry ) vce(cluster IDlseMHR)
* IDlse IDlseMHR 
regsave ttIAW* TTMW* using "$analysis/Results/2.Analysis/EventPay.dta", ci replace 

frame create graphs 
frame change graphs 
use "$analysis/Results/2.Analysis/EventPay.dta", clear 
gen t1 = _n - 26
replace t1 =  t1 + 1 if t1>-2
replace t1 = . if t1 >=37
replace t1 = . if t1 ==-25  // dropping endpoints 
gen t2 = _n  - 88
replace t2 = . if t2 <=-25
replace t2 =  t2 + 1 if t2>-2
replace t2 = . if t2 ==37 // dropping endpoints 

twoway (scatter coef t1, color(orange) ) (line  coef t2, color(blue) ) (rcap ci_lower ci_upper t1, color(orange)) (rcap ci_lower ci_upper t2, color(blue))  , xtitle("Event Time (months)") ///
ytitle("Pay + bonus (logs)") xlabel(-24(3)36) yline(0) xline(-1,lpattern(-)) legend(order(1 "IA" 2 "Change M")) title("IA M Effect")
graph export "$analysis/Results/2.Analysis/EventPay.png", replace

********************************************************************************


xtset IDlse YearMonth 
local max_delta = `r(tmax)' - `r(tmin)'
local first_period = -24
local last_period = 36

* lags
foreach x in FirstIAM  ChangeM {
	forvalues i = 0/`max_delta'{
		gen L`i'_`x' = L`i'.`x' == 1

	if `i' > `last_period'{
	local L_absorb_`x' "`L_absorb_`x'' L`i'_`x' " 
	}
}

}

*leads 
local omitted_threshold = - 1
foreach x in FirstIAM  ChangeM {
	forvalues i = -`max_delta'/`omitted_threshold'{
		local j = abs(`i')
		gen F`j'_`x' = F`j'.`x' == 1

			if `i' < `first_period'{
	 local F_absorb_`x' " `F_absorb_`x'' F`j'_`x'"
	}
}
}

* absorb last lags/ leads 
foreach x in FirstIAM  ChangeM {
egen Lend_`x' = rowmax(`L_absorb_`x'')
egen Fend_`x' = rowmax(`F_absorb_`x'')
}

* list of leads and lags for regression  
foreach x in FirstIAM   {
	forvalues i = 0/36{
	local lagsIA "`lagsIA' L`i'_`x' " 
	}
	}

foreach x in FirstIAM  {
	forvalues i = 2/24{
	local leadsIA "`leadsIA' F`i'_`x' " 
	}	
	}
	
foreach x in ChangeM {
	forvalues i = 2/24{
	local leadsM "`leadsM' F`i'_`x' " 
	}	
	}
	
foreach x in  ChangeM {
	forvalues i = 0/36{
	local lagsM "`lagsM' L`i'_`x' " 
	}
	}

reghdfe LogPayBonus `leadsIA' `lagsIA' `leadsM' `lagsM'  Lend_FirstIAM Fend_FirstIAM Lend_ChangeM Fend_ChangeM c.Tenure##c.Tenure if YearMonth>=tm(2018m9) , absorb(Country#YearMonth Func  DiffCountry IDlse IDlseMHR ) vce(cluster IDlseMHR)

regsave `leadsIA' `lagsIA' `leadsM' `lagsM' using "$analysis/Results/2.Analysis/pay.dta", ci replace 
twoway (scatter coef t2, color(orange) ) (line  coef t2, color(orange) )  (rcap ci_lower ci_upper t2, color(orange))  , xtitle("Event Time (months)") ///
ytitle("Pay + bonus (logs)") xlabel(-3(1)4) yline(0) xline(-1,lpattern(-)) legend(off) title("IA M Effect")
graph save "$analysis/Results/2.RegIA/LogBonusCD.gph", replace
graph export "$analysis/Results/2.RegIA/LogBonusCD.png", replace


* languages 

gen SpeakEngl = 0
replace SpeakEngl = 1 if HomeCountryS=="United Kingdom" |  HomeCountryS=="South Africa" ///
 | HomeCountryS=="United States of America" | HomeCountryS=="India" | HomeCountryS=="India" ///
 | HomeCountryS=="Australia"  | HomeCountryS=="Canada" |  HomeCountryS=="New Zealand" ///
|  HomeCountryS=="Ireland" |  HomeCountryS=="Singapore" | HomeCountryS=="Hong Kong" // as classified by UK gov https://www.sheffield.ac.uk/international/english-speaking-countries
replace SpeakEngl = . if  HomeCountry==.
label var SpeakEngl "From English speaking country"

gen SpeakEnglM = 0
replace SpeakEnglM = 1 if HomeCountrySM=="United Kingdom" |  HomeCountrySM=="South Africa" ///
 | HomeCountrySM=="United States of America" | HomeCountrySM=="India" | HomeCountrySM=="India" ///
 | HomeCountrySM=="Australia"  | HomeCountrySM=="Canada" |  HomeCountrySM=="New Zealand" ///
|  HomeCountrySM=="Ireland" |  HomeCountrySM=="Singapore" | HomeCountrySM=="Hong Kong" // as classified by UK gov https://www.sheffield.ac.uk/international/english-speaking-countries
replace SpeakEnglM = . if  HomeCountryM==.
label var SpeakEnglM "Manager from English speaking country"

gen SpeakFr = 0
replace SpeakFr = 1 if HomeCountryS=="France" |  HomeCountryS=="Belgium" ///
 | HomeCountryS=="Cameroon" | HomeCountryS==" Burkina Faso" | HomeCountryS=="Burundi" ///
 | HomeCountryS=="Cote d Ivoire"  | HomeCountryS=="Mali" |  HomeCountryS=="Niger" ///
|  HomeCountryS=="Togo" 
replace SpeakFr = . if  HomeCountry==.
label var SpeakFr "From French speaking country"

gen SpeakFrM = 0
replace SpeakFrM = 1 if HomeCountrySM=="France" |  HomeCountrySM=="Belgium" ///
 | HomeCountrySM=="Cameroon" | HomeCountrySM==" Burkina Faso" | HomeCountrySM=="Burundi" ///
 | HomeCountrySM=="Cote d Ivoire"  | HomeCountrySM=="Mali" |  HomeCountrySM=="Niger" ///
|  HomeCountrySM=="Togo" 
replace SpeakFrM = . if  HomeCountryM==.
label var SpeakFrM "Manager from French speaking country"

gen SpeakSpan = 0
replace SpeakSpan = 1 if HomeCountryS=="Argentina" | HomeCountryS=="Bolivia" | HomeCountryS=="Chile" | ///
HomeCountryS=="Colombia" |  HomeCountryS=="Costa Rica" | HomeCountryS=="Dominican Republic" | ///
HomeCountryS=="Ecuador" | HomeCountryS=="El Salvador" | HomeCountryS=="Guatemala" | ///
HomeCountryS=="Honduras" | HomeCountryS=="Mexico" |  HomeCountryS=="Nicaragua" | ///
HomeCountryS=="Panama" | HomeCountryS=="Paraguay" | HomeCountryS=="Peru" | HomeCountryS=="Puerto Rico" | ///
HomeCountryS=="Spain" | HomeCountryS=="Uruguay" | HomeCountryS=="Bolivia" | HomeCountryS=="Venezuela" 
replace SpeakSpan = . if  HomeCountry==.
label var SpeakSpan "From Spanish speaking country"


gen SpeakSpanM = 0
replace SpeakSpanM = 1 if HomeCountrySM=="Argentina" | HomeCountrySM=="Bolivia" | HomeCountrySM=="Chile" | ///
HomeCountrySM=="Colombia" |  HomeCountrySM=="Costa Rica" | HomeCountrySM=="Dominican Republic" | ///
HomeCountrySM=="Ecuador" | HomeCountrySM=="El Salvador" | HomeCountrySM=="Guatemala" | ///
HomeCountrySM=="Honduras" | HomeCountrySM=="Mexico" |  HomeCountrySM=="Nicaragua" | ///
HomeCountrySM=="Panama" | HomeCountrySM=="Paraguay" | ///
HomeCountrySM=="Peru" | HomeCountrySM=="Puerto Rico" | ///
HomeCountrySM=="Spain" | HomeCountrySM=="Uruguay"  | HomeCountrySM=="Bolivia" | HomeCountrySM=="Venezuela" 
replace SpeakSpanM = . if  HomeCountryM==.
label var SpeakSpanM "Manager from Spanish speaking country"


gen SpeakPor = 0
replace SpeakPor = 1 if HomeCountryS=="Portugal" | HomeCountryS=="Portugal" | ///
HomeCountryS=="Mozambique" | HomeCountryS=="Brazil" | HomeCountryS=="Angola" | ///
HomeCountryS=="Cape Verde"
replace SpeakPor = . if  HomeCountry==.
label var  SpeakPor "From Portuguese speaking country"


gen SpeakPorM = 0
replace SpeakPorM = 1 if HomeCountrySM=="Portugal" | HomeCountrySM=="Portugal" | ///
HomeCountrySM=="Mozambique" | HomeCountrySM=="Brazil" | HomeCountrySM=="Angola" | ///
HomeCountrySM=="Cape Verde" 
replace SpeakPorM = . if  HomeCountryM==.

label var SpeakPorM "Manager from Portuguese speaking country"

gen SpeakArab = 0
replace SpeakArab = 1 if HomeCountryS=="Egypt" | HomeCountryS=="Algeria" | ///
HomeCountryS=="Sudan" | HomeCountryS=="Saudi Arabia" | HomeCountryS=="Tunisia" | ///
HomeCountryS=="Syria" | HomeCountryS=="Morocco" | HomeCountryS=="Mauritania" ///
| HomeCountryS=="Lybia" | HomeCountryS=="Somalia" | HomeCountryS=="Jordan" ///
| HomeCountryS=="Iraq" | HomeCountryS=="Kuwait" | HomeCountryS=="Yemen" | HomeCountryS=="Oman" ///
| HomeCountryS=="Qatar" | HomeCountryS=="Somalia"  | HomeCountryS=="Bahrain" | HomeCountryS=="United Arab Emirates" ///
  | HomeCountryS=="Lebanon" |  HomeCountryS=="Kuwait"
  replace SpeakArab = . if  HomeCountry==.

label var SpeakArab "From  Arabic speaking country"

gen SpeakArabM = 0
replace SpeakArabM = 1 if HomeCountrySM=="Egypt" | HomeCountrySM=="Algeria" | ///
HomeCountrySM=="Sudan" | HomeCountrySM=="Saudi Arabia" | HomeCountrySM=="Tunisia" | ///
HomeCountrySM=="Syria" | HomeCountrySM=="Morocco" | HomeCountrySM=="Mauritania" ///
| HomeCountrySM=="Lybia" | HomeCountrySM=="Somalia" | HomeCountrySM=="Jordan" ///
| HomeCountrySM=="Iraq" | HomeCountrySM=="Bahrain" | HomeCountrySM=="Kuwait" | HomeCountrySM=="Yemen" | HomeCountrySM=="Oman" ///
| HomeCountrySM=="Qatar" | HomeCountrySM=="Somalia"  | HomeCountrySM=="United Arab Emirates" ///
  | HomeCountrySM=="Lebanon" |  HomeCountrySM=="Kuwait"
  replace SpeakArabM = . if  HomeCountryM==.

label var SpeakArabM "Manager from Arabic speaking country"

gen SpeakRus=0
replace  SpeakRus=1 if HomeCountryS=="Russian Federation" | HomeCountryS=="Belarus" | HomeCountryS=="Kyrgyzstan" ///
| HomeCountryS=="Kazakhstan" | HomeCountryS=="Ukraine" | HomeCountryS=="Azerbaijan" ///
| HomeCountryS=="Estonia" | HomeCountryS=="Georgia" | HomeCountryS=="Latvia" | HomeCountryS=="Lithuania" ///
| HomeCountryS=="Moldova" | HomeCountryS=="Tajikistan"  | HomeCountryS=="Turkmenistan" | HomeCountryS=="Uzbekistan"
replace SpeakRus = . if  HomeCountry==.
label var SpeakRus "From  Russian speaking country"

gen SpeakRusM=0
replace  SpeakRusM=1 if HomeCountrySM=="Russian Federation" | HomeCountrySM=="Belarus" | HomeCountrySM=="Kyrgyzstan" ///
| HomeCountrySM=="Kazakhstan" | HomeCountrySM=="Ukraine" | HomeCountrySM=="Azerbaijan" ///
| HomeCountrySM=="Estonia" | HomeCountrySM=="Georgia" | HomeCountrySM=="Latvia" | HomeCountrySM=="Lithuania" ///
| HomeCountrySM=="Moldova" | HomeCountrySM=="Tajikistan"  | HomeCountrySM=="Turkmenistan" | HomeCountrySM=="Uzbekistan"
replace SpeakRusM = . if  HomeCountryM==.
label var SpeakRusM "Manager from  Russian speaking country"

