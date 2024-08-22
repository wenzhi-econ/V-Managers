clear all
set more off

/*                       Setting paths and installing packages    */
if              "`c(username)'" == "Oriana"    {
                        global user "/Users/Oriana/Dropbox/UDocuments"
                }
				
				if              "`c(username)'" == "podMac"    {
                        global user "/Users/podMac/Dropbox/UDocuments"
						}
				
if                 "`c(username)'" =="minni" {
						global user "C:/Users/minni/Dropbox/UDocuments"
											
}

if                 "`c(username)'" =="virginiaminni" {
						global user "/Users/virginiaminni/Dropbox/UDocuments"
											
}

if                 "`c(username)'" =="seong" {
						global user  "C:/Users/seong/Dropbox/UDocuments" 
											
}

if                 "`c(username)'" =="mishanyom" {
						global user  "/Users/mishanyom/Dropbox/UDocuments" 
											
}

if                 "`c(username)'" =="myungwonseong" {
						global user  "/Users/mishanyom/Dropbox/UDocuments" 
											
}

cd "$user"

global data "${user}/Data/FullSample/Data"
global dta "${user}/Data/FullSample/Data/dta"
global Managersdta "${user}/Managers/Data"
global clevel "${user}/Data/CountryLevel"
global cleveldta "${user}/Data/CountryLevel/CLdta"
global temp "${user}/Managers/Data/Temp"
global ManagersCL "${user}/Managers/Data/CL"
global Talent "${user}/TalentPaper/Data/dta"


global analysis "${user}/Managers"
global Results "${user}/Managers/Results"

* Temp as onedrive uses giga to sync 
global Managersdta "/Users/virginiaminni/Managers/Data"
global temp "/Users/virginiaminni/Managers/Data/Temp"


/*
* !TEMP PATHS!
global user "/Users/virginiaminni/OneDrive - London School of Economics/ManagerTalent" // OneDrive 

global data "/Users/virginiaminni/Desktop/ManagerTalent/Data/FullSample/Data"
global dta "/Users/virginiaminni/Desktop/ManagerTalent/Data/FullSample/Data/dta"
global Managersdta "/Users/virginiaminni/Desktop/ManagerTalent/Managers/Data"
global temp "/Users/virginiaminni/Desktop/ManagerTalent/Managers/Data/Temp"
global Talent "/Users/virginiaminni/Desktop/ManagerTalent/TalentPaper/Data/dta"
*/

grstyle init
grstyle set plain, horizontal grid

set scheme burd5
*set scheme s1color
set varabbrev off

* Stata version control
*version 16.1

*set matsize 11000
*set maxvar 32767

