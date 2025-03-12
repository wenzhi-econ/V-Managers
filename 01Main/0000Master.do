/* 
This is the master do file for the project. 
It includes the following code blocks:
    specify default setups, e.g., Stata version to be used 
    create global macros to store paths of different folders
    ensure that executed user-written packages from the local library
    set figure scheme 
    execute do files used to replicate output used in the paper 
    (the dofile-output mapping is in the _Description.md file) 
        run do files for data cleaning 
        run do files for all results related to event studies 
        run do files for figures and tables in the paper 
        run do files for appendix figures and tables in the paper 
        run do files for calculating statistics cited in the paper

RA: WWZ 
Time: 2025-02-25
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

if	"`c(username)'" == "wang" {
    global user "E:/__RA/02MANAGERS"
}

if	"`c(username)'" == "wenzhi0" {

    //&? This is the path specified for usage on Booth high-performance computing cluster, Mercury.
    //&? Packages need to be installed when connecting to the server's Stata.

    global user "/home/wenzhi0/JMP"

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

if  "`c(username)'" == "virginiaminni" {
    global user "/Users/virginiaminni/Dropbox/JMP_Managers"
}

if 	"`c(username)'" == "virginia_m" {		
    global user = "C:/Users/virginia_m/Dropbox/JMP_Managers"
}

if 	"`c(username)'" == "ra" global user = "C:/Users/RA"

cd "${user}"

global Paper        "${user}/Paper Managers"
global DoFiles      "${user}/Paper Managers/DoFiles"
global Results      "${user}/Paper Managers/Results"

global FinalData    "${user}/Paper Managers/Data"
global RawMNEData   "${user}/Paper Managers/Data/01RawData/01MNEData"
global RawONETData  "${user}/Paper Managers/Data/01RawData/02ONET"
global RawCntyData  "${user}/Paper Managers/Data/01RawData/03Country"
global TempData     "${user}/Paper Managers/Data/02TempData"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. libraries (user-written procedures) to be used 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? install all necessary packages to a local directory
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* do "${DoFiles}/01Main/0001InstallPackages.do" */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? using libraries stored in the local Libraries folder
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

net set ado "${DoFiles}/Libraries"

tokenize `"$S_ADO"', parse(";")
while `"`1'"' != "" {
    if `"`1'"'!="BASE" capture adopath - `"`1'"'
    macro shift
}
adopath ++ "${DoFiles}/Libraries"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. set figure scheme 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

grstyle init white_tableau, path("${DoFiles}/Libraries") replace
grstyle set plain, horizontal grid

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. replicate results in the paper
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global if_erase_temp_file = 1
    //&? if it is set to 1, temporary auxiliary dta files produced in the data cleaning process will be erased

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-1. dataset construction
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* capture log close 
log using "${Results}/001DataCleaning/logfile_20250312_DataConstruction", replace text

do "${DoFiles}/01Main/0101GenerateWorkerOutcomes.do"
do "${DoFiles}/01Main/0102HFMeasure.do"
do "${DoFiles}/01Main/0103GenerateEventDummies.do"
do "${DoFiles}/01Main/0104GenerateHeterogeneityIndicators.do"
do "${DoFiles}/01Main/0105SalesProductivityDatasets.do"
do "${DoFiles}/01Main/0106TeamLevelDataset.do"
do "${DoFiles}/01Main/0107_01ONETRawScoreConstruction.do"
do "${DoFiles}/01Main/0107_02ONETPercentileRankConstruction.do"

//&? It takes around 15 min to create all the main datasets used in the paper.
log close */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-2. results that don't require Mercury
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-2-1. tales in the main text 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

do "${DoFiles}/01Main/0401SummaryStatistics_ObsSize.do"
do "${DoFiles}/01Main/0402SummaryStatistics_WholeSample.do"
do "${DoFiles}/01Main/0403SummaryStatistics_MngrHvsL_FullMngrSample.do"
do "${DoFiles}/01Main/0404ProdResultsConditionalOnLateralAndVerticalMoves.do"
do "${DoFiles}/01Main/0303FourMainOutcomes_Heterogeneity.do"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-2-2. tales in the appendix 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

do "${DoFiles}/01Main/0501HFIsNotAnLaggingIndicator.do"
do "${DoFiles}/01Main/0502EndogenousMobilityChecks_toH.do"
do "${DoFiles}/01Main/0503EndogenousMobilityChecks_toHVStoL.do"
do "${DoFiles}/01Main/0504TimeUse_MngrHvsL.do"
do "${DoFiles}/01Main/0505ActiveLearning_MngrHVsL.do"
do "${DoFiles}/01Main/0506FlexibleProjects_MngrHVsL.do"
do "${DoFiles}/01Main/0507_01Network_WorkInfo.do"
do "${DoFiles}/01Main/0507_02Network_ColleagueInfo.do"
do "${DoFiles}/01Main/0507_03_Network_Regressions.do"
do "${DoFiles}/01Main/0508JobCreation.do"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-2-3. tables in the supplementary material 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

do "${DoFiles}/01Main/0801SurveyResponseDiff.do"
do "${DoFiles}/01Main/0802SelfReportedSurveyOutcomes.do"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-2-4. figures in the main text 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

do "${DoFiles}/01Main/0304FactoryLevel_ProductivityAndCostOutcomes.do"
do "${DoFiles}/01Main/0601DescriptiveFigure_WLAgainstTenureDist.do"
do "${DoFiles}/01Main/0602DescriptiveFigure_TenureAtPromDist.do"

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-2-5. figures in the appendix 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

do "${DoFiles}/01Main/0701DescriptiveFigure_WLYearProfiles.do"
do "${DoFiles}/01Main/0702DescriptiveFigure_PayRelatedVarsCorrelation.do"
do "${DoFiles}/01Main/0703DescriptiveFigure_ShareMoversAcrossSubFuncs.do"
do "${DoFiles}/01Main/0704_02SkillsComparison.do"
    //&? This do file needs to be executed after the execution of 0704_01.py file 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-3. results that require Mercury -- event studies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-3-1. quarterly aggregation programs
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

do "${DoFiles}/01Main/0201CoefPrograms_LHminusLL.do" 
do "${DoFiles}/01Main/0202CoefPrograms_HLminusHH.do"
do "${DoFiles}/01Main/0203CoefPrograms_Dual_TestingforAsymmetries.do"
do "${DoFiles}/01Main/0204CoefPrograms_LHminusLL_OnlyPost.do" 
do "${DoFiles}/01Main/0205CoefPrograms_HLminusHH_OnlyPost.do"
do "${DoFiles}/01Main/0206CoefPrograms_Dual_TestingforAsymmetries_OnlyPost.do"
do "${DoFiles}/01Main/0207CoefPrograms_CohortDynamics.do"
    //&? These do files need to be executed for every event study results in the following two code blocks: s-5-3-2, and s-5-3-3.

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-3-2. main results 
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

do "${DoFiles}/01Main/0301_01TwoMainOutcomesInEventStudies.do" 
do "${DoFiles}/01Main/0301_02PayOutcomesInEventStudies.do" 
do "${DoFiles}/01Main/0301_03WLPromotionsInEventStudies.do" 
do "${DoFiles}/01Main/0301_04ONETTaskDistance.do" 
do "${DoFiles}/01Main/0301_05ProbLateralTransferInEventStudies.do" 
do "${DoFiles}/01Main/0301_06ExitOutcomes_InvolAndVol.do" 
do "${DoFiles}/01Main/0302Decomp_TransferSJC.do" 
do "${DoFiles}/01Main/0305TeamLevel_InequalityDynamics.do" 

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-5-3-3. robustness checks  
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

do "${DoFiles}/01Main/0303_01Robustness_SingleCohortYear.do" 
do "${DoFiles}/01Main/0303_02Robustness_NewHires.do" 
do "${DoFiles}/01Main/0303_03Robustness_Poisson.do" 
do "${DoFiles}/01Main/0303_04Robustness_CohortDynamics_LtoHvsLtoL.do" 
do "${DoFiles}/01Main/0303_05Robustness_CohortDynamics_HtoLvsHtoH.do" 
do "${DoFiles}/01Main/0303_06Robustness_PlaceboMngrHFStatus.do" 


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-4. statistics cited in the paper 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

do "${DoFiles}/01Main/z1.StatisticsCitedInPaper_Numbers.do" 
do "${DoFiles}/01Main/z2.StatisticsCitedInPaper_PayEffectsMagnitude.do" 
do "${DoFiles}/01Main/z3.StatisticsCitedInPaper_CostBenefitAnalysis.do" 
do "${DoFiles}/01Main/z4.StatisticsCitedInPaper_MediationAnalysis.do" 


