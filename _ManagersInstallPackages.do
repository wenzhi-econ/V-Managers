*******
* This script installs all necessary Stata packages into Libraries
* To do a fresh install of all Stata packages, delete the entire Libraries folder
*******

* Create and define a local installation directory for the packages
cap mkdir "$dofiles/Libraries"
net set ado "$dofiles/Libraries"

* Install packages from SSC
global SSCpackages ivreghdfe hmap tabplot plotmatrix moremata mediation cdfplot groups xls2dta drarea xlincom dsconcat plotbeta ppmlhdfe findregex  winsor2 avar eventstudyinteract event_plot did_imputation fese eventstudyweights fuzzydid did_multiplegt twowayfeweights xtevent coefplot blindschemes ranktest ivreg2 balancetable binscatter carryforward cem cibar distinct dsconcat ///
dyads egenmore estout gtools _gwtmean insheetjson kountry labutil ///
libjson lincomest matsort numdate opencagegeo outreg2 parmest povcalnet radar ///
reghdfe regsave scheme-burd sxpose texresults wid winsor winsor2 

foreach p in $SSCpackages {
	local ltr = substr(`"`p'"',1,1)
	qui net from "http://fmwww.bc.edu/repec/bocode/`ltr'"
	net install `p', replace
}

net install grc1leg, from("http://www.stata.com/users/vwiggins/") replace
net install allston, from("https://raw.githubusercontent.com/dballaelliott/allston/master/") replace 
net install esplot,  from("https://raw.githubusercontent.com/dballaelliott/esplot/pkg/") 	 replace
net install grstyle, from("https://raw.githubusercontent.com/benjann/grstyle/master") 		 replace
ssc install schemepack, replace // (2023/07/04)
net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/") replace
net install honestdid, from("https://raw.githubusercontent.com/mcaceresb/stata-honestdid/main") replace
*honestdid _plugin_check
