/* 
This is an example master do file to be uploaded to the Mercury cluster.

RA: WWZ 
Time: 2025-03-19
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. default setups
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

version 16

clear all
set more off
set maxvar 32767
set varabbrev off

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. global macros to store folder paths
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

if	"`c(username)'" == "wenzhi0" {

    //&? it is necessary to install necessary packages each time running programs on the cluster

    global user "/project/Managers"
    ssc install grstyle, replace
    ssc install palettes, replace

    ssc install colrspace, replace
    ssc install schemepack, replace
    ssc install ftools, replace
    ssc install reghdfe, replace
    ssc install xlincom, replace
    ssc install coefplot, replace
    ssc install estout, replace
    ssc install ppmlhdfe, replace
}


cd "${user}"

* Paper Managers folder
global Paper        "${user}/Paper Managers"
global DoFiles      "${user}/Paper Managers/DoFiles"
global Results      "${user}/Paper Managers/Results"

global FinalData    "${user}/Paper Managers/Data"
global RawMNEData   "${user}/Paper Managers/Data/01RawData/01MNEData"
global RawONETData  "${user}/Paper Managers/Data/01RawData/02ONET"
global RawCntyData  "${user}/Paper Managers/Data/01RawData/03Country"
global TempData     "${user}/Paper Managers/Data/02TempData"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. set figure scheme 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

set scheme white_tableau
grstyle init
grstyle set plain, horizontal grid

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? IMPORTANT main programs 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

do "${DoFiles}/030710PayOutcomesInEventStudies_LosingHF.do"

    //&? This is the only step you are going to change every time you want to run a different do file on the cluster.