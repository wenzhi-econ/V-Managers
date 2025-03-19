This folder contains all script files used to generate tables and figures used in the paper.

# 1. General Structure of the Folder

- **0000Master.do** file is the master do file, specifying working directory, folder paths, and other general specifications.
- Do files starting with **01** are used to clean the raw data and generate datasets used in different analyses.
- Do files starting with **02** contain Stata programs used for those files starting with **03**. These programs are used to transform raw coefficients (which are monthly level) from TWFE regressions to the coefficients of interest -- difference in specific quarterly aggregated coefficients.
- Do files starting with **03** are used to generate all event study results in the paper.
- Do files starting with **04** are used to generate all tables in the main text.
- Do files starting with **05** are used to generate all tables in the appendix.
- Do files starting with **06** are used to generate all tables in the appendix.
- Do files starting with **07** are used to generate all figures in the appendix. 
- Do files with names **z\*.StatisticsCitedInPaper.do** contain codes to calculate certain statistics cited in the paper.
- Apart from the above do files, there are three python script files in the folder.
  - The "_pysetup.py" file is used to specify relevant paths and is imported to the other two python files.
  - "0704_01SkillsDescriptionLDA.py" is used for Figure A.11, where a 3-topic LDA model is estimated on the skills text data.
  - "0705_02OccTaskTransitionHeatMap.py" is used for Figure A.8, where the heatmap of occupation transitions is generated.

# 2. Mapping from Output to Script Files 

| Output in paper      | File(s)                                                                                            |
|----------------------|----------------------------------------------------------------------------------------------------|
| Figure Ia            | 0601DescriptiveFigure\_WLAgainstTenureDist.do                                                      |
| Figure Ib            | 0602DescriptiveFigure\_TenureAtPromDist.do                                                         |
| Figure IIa, IIb      | 0301\_01TwoMainOutcomesInEventStudies.do                                                           |
| Figure IIc, IId      | 0301\_06ExitOutcomes\_InvolAndVol.do                                                               |
| Figure III           | 0302Decomp\_TransferSJC.do                                                                         |
| Figure IVa, IVb, IVc | 0301\_02PayOutcomesInEventStudies.do                                                               |
| Figure IVd           | 0301\_03WLPromotionsInEventStudies.do                                                              |
| Figure V             | 0304FactoryLevel\_ProductivityAndCostOutcomes.do                                                   |
| Figure VIa, VIb      | 0301\_01TwoMainOutcomesInEventStudies.do                                                           |
| Figure VIc, VId      | 0301\_06ExitOutcomes\_InvolAndVol.do                                                               |
| Figure VII           | 0301\_01TwoMainOutcomesInEventStudies.do                                                           |
| Table I              | 0401SummaryStatistics\_ObsSize.do                                                                  |
| Table II             | 0402SummaryStatistics\_WholeSample.do                                                              |
| Table III            | 0403SummaryStatistics\_MngrHvsL\_FullMngrSample.do                                                 |
| Table IV             | 0404ProdResultsConditionalOnLateralAndVerticalMoves.do                                             |
| Table V              | 0303FourMainOutcomes\_Heterogeneity.do                                                             |
| Figure A.3           | 0701DescriptiveFigure\_WLYearProfiles.do                                                           |
| Figure A.5           | 0702DescriptiveFigure\_PayRelatedVarsCorrelation.do                                                |
| Figure A.6           | 0703DescriptiveFigure\_ShareMoversAcrossSubFuncs.do                                                |
| Figure A.7a          | 0301\_05ProbLateralTransferInEventStudies.do                                                       |
| Figure A.7b          | 0301\_04ONETTaskDistance.do                                                                        |
| Figure A.8           | 0705\_01SkillTransferHeatmap\_LtoLvsLtoH.do, 0705\_02OccTaskTransitionHeatMap.py                   |
| Figure A.9a, A.9b    | 0303\_04Robustness\_CohortDynamics\_LtoHvsLtoL.do                                                  |
| Figure A.9c, A.9d    | 0303\_05Robustness\_CohortDynamics\_HtoLvsHtoH.do                                                  |
| Figure A.10a, A.10b  | 0303\_01Robustness\_SingleCohortYear.do                                                            |
| Figure A.10c, A.10d  | 0303\_02Robustness\_NewHires.do                                                                    |
| Figure A.10e, A.10f  | 0303\_03Robustness\_Poisson.do                                                                     |
| Figure A.11          | 0704\_01SkillsDescriptionLDA.py, 0704\_02SkillsComparison.do                                       |
| Figure A.12          | 0305TeamLevel\_InequalityDynamics.do                                                               |
| Table B.1            | 0502EndogenousMobilityChecks\_toH.do                                                               |
| Table B.2            | 0503EndogenousMobilityChecks\_toHVStoL.do                                                          |
| Table B.3            | 0501HFIsNotAnLaggingIndicator.do                                                                   |
| Table B.4            | 0504TimeUse\_MngrHvsL.do                                                                           |
| Table B.5            | 0505ActiveLearning\_MngrHVsL.do                                                                    |
| Table B.6            | 0506FlexibleProjects\_MngrHVsL.do                                                                  |
| Table B.7            | 0507\_01Network\_WorkInfo.do, 0507\_02Network\_ColleagueInfo.do, 0507\_03\_Network\_Regressions.do |
| Table B.8            | 0508JobCreation.do                                                                                 |

