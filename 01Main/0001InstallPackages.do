/* 
This do file installs necessary community-contributed packages to a directory in the project folder.

RA: WWZ
Date installed: 2025-02-25
*/

capture mkdir "${DoFiles}/Libraries"
net set ado "${DoFiles}/Libraries"

foreach pkg in egenmore ftools reghdfe ppmlhdfe xlincom balancetable estout coefplot grstyle palettes colrspace schemepack {
    local website_folder = substr("`pkg'", 1, 1)
    net from "http://fmwww.bc.edu/repec/bocode/`website_folder'"
    net install `pkg', replace
}

net install mediation, from("http://fmwww.bc.edu/repec/bocode/m") replace