* PROGRAM TO QUICK GENERATE SET OF EVENT INDICATORS 

cap program drop eventd
program def eventd

syntax , i(real)  

local end = `i'0  
local LeventExit ""
local LeventDeltaExit ""
local Levent ""
local LeventDelta ""
foreach var in Ei {
forvalues l = 0/`end' {
	
	local Levent " `Levent' L`l'`var'"
	local LeventDelta "`LeventDelta' L`l'`var'DeltaM"
	
	if `l' > 0{
	local LeventExit " `LeventExit' L`l'`var'"
	local LeventDeltaExit "`LeventDeltaExit' L`l'`var'DeltaM"
	}
else {
}

}


local FeventExit ""
local FeventDeltaExit ""
local Fevent ""
local FeventDelta ""
foreach var in Ei {
forvalues l = 2/`end' {
	
	local Fevent " `Fevent' F`l'`var'"
	local FeventDelta "`FeventDelta' F`l'`var'DeltaM"
	

}
}
}
global Fevent "`Fevent' Fend`i'1"
global FeventDelta "`FeventDelta' FendDeltaM`i'1"
global Levent "`Levent' Lend`i'1"
global LeventDelta "`LeventDelta'  LendDeltaM`i'1"
global LeventExit "`LeventExit' Lend`i'1"
global LeventDeltaExit "`LeventDeltaExit' LendDeltaM`i'1"
end
