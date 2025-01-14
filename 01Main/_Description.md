This folder contains all script files used to generate tables and figures used in the paper.

# General Structure of the Folder

- **0000Master.do** file is the master do file, specifying working directory, folder paths, and other general specifications.
- Do files starting with **01** are used to clean the raw data and generate datasets used in different analyses.
- Do files starting with **02** contain Stata programs used for those files starting with **03**. These programs are used to transform raw coefficients from TWFE regressions to the coefficients of interest -- difference in specific quarterly aggregated coefficients.
- Do files starting with **03** are used to generate all event study results in the paper.
- Do files starting with **04** are used to generate all tables in the main text.
- Do files starting with **05** are used to generate all tables in the appendix.
- Do files starting with **06** are used to generate all tables in the appendix.
- Do files starting with **07** are used to generate all figures in the appendix. 
- **z.StatisticsCitedInPaper.do** file contains the codes to calculate certain statistics cited in the paper.

# Output of Each Script File 



