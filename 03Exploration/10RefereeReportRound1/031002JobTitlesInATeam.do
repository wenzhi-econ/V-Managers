/* 
This do file conducts job title related analysis in the team level.

RA: WWZ 
Time: 2024-12-06
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. in the full sample
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear

sort IDlseMHR YearMonth IDlse
egen job_id = tag(IDlseMHR YearMonth StandardJob)
bysort IDlseMHR YearMonth: egen num_distinct_job = total(job_id)

order IDlse YearMonth IDlseMHR StandardJob job_id num_distinct_job

egen team_tag = tag(IDlseMHR YearMonth)
summarize num_distinct_job if IDlseMHR!=. & team_tag==1, detail 
    //&? a cross-sectional of teams

/* 
                      num_distinct_job
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs           2,018,062
25%            1              1       Sum of wgt.   2,018,062

50%            2                      Mean           1.980874
                        Largest       Std. dev.       1.43945
75%            2             39
90%            4             40       Variance       2.072016
95%            5             42       Skewness       2.726785
99%            7             55       Kurtosis       18.12362
*/

summarize num_distinct_job if IDlseMHR!=., detail 
    //&? each team can show up multiple times in the mean calculation, which depends on the team size 
/* 
                      num_distinct_job
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs          10,033,738
25%            1              1       Sum of wgt.    10033738

50%            2                      Mean           2.665892
                        Largest       Std. dev.      2.065319
75%            3             55
90%            5             55       Variance       4.265544
95%            7             55       Skewness       3.174785
99%           10             55       Kurtosis       28.97418
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. in the event study sample
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear
keep if FT_Rel_Time!=. & FT_Mngr_both_WL2==1
    //&? keep a panel of event workers

sort IDlseMHR YearMonth IDlse
egen job_id = tag(IDlseMHR YearMonth StandardJob)
bysort IDlseMHR YearMonth: egen num_distinct_job = total(job_id)

order IDlse YearMonth IDlseMHR StandardJob job_id num_distinct_job

egen team_tag = tag(IDlseMHR YearMonth)
summarize num_distinct_job if IDlseMHR!=. & team_tag==1, detail 
    //&? a cross-sectional of teams

/* 

                      num_distinct_job
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs             819,591
25%            1              1       Sum of wgt.     819,591

50%            1                      Mean            1.37528
                        Largest       Std. dev.      .7060637
75%            2             10
90%            2             11       Variance        .498526
95%            3             11       Skewness         2.4539
99%            4             13       Kurtosis       11.60583
*/

summarize num_distinct_job if IDlseMHR!=., detail 
    //&? each team can show up multiple times in the mean calculation, which depends on the team size 
/* 
                      num_distinct_job
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs           1,902,384
25%            1              1       Sum of wgt.   1,902,384

50%            1                      Mean           1.770222
                        Largest       Std. dev.      1.034931
75%            2             13
90%            3             13       Variance       1.071083
95%            4             13       Skewness       1.885566
99%            5             13       Kurtosis       8.233016
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. distinct job titles at the event date 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/04MainOutcomesInEventStudies.dta", clear
keep if FT_Rel_Time==0 & FT_Mngr_both_WL2==1
    //&? a cross-section of event workers (at the event date)
    //&? 29,610 different event workers

generate one = 1
bysort StandardJob: egen counts = total(one)

keep StandardJob counts
duplicates drop

gsort -counts
list in 1/100, sep(5)
    //&? 684 distinct jobs at the event date 
/*
     +------------------------------------------------+
     |                           StandardJob   counts |
     |------------------------------------------------|
  1. |             Field Sales Administrator     2357 |
  2. |                Field Sales Specialist     1741 |
  3. |                Field Sales Supervisor     1438 |
  4. |                Product Dev Technician     1177 |
  5. |                       Make Supervisor     1080 |
     |------------------------------------------------|
  6. |                      Finance BP Admin      876 |
  7. |                       Make Specialist      591 |
  8. |                    Make Administrator      544 |
  9. |                Procurement Specialist      518 |
 10. |            Supply Planning Specialist      509 |
     |------------------------------------------------|
 11. |             Brand Building Specialist      457 |
 12. |              Packaging Dev Technician      440 |
 13. |                 Supply Planning Admin      427 |
 14. |            Cust and Account Mgmt Spec      392 |
 15. |                  Brand Building Admin      390 |
     |------------------------------------------------|
 16. |               Record to Report  Admin      385 |
 17. |                      Brand Specialist      347 |
 18. |             Cust and Account Mgmt Adm      329 |
 19. |            Shopper & Custmr Mktg Spec      324 |
 20. |                  Logistics Specialist      298 |
     |------------------------------------------------|
 21. |            Science & Tech Dsc ScienL1      295 |
 22. |             Procurement Administrator      277 |
 23. |            Cust and Account Mgmt Supv      276 |
 24. |                Engineering Specialist      271 |
 25. |            Demand Planning Specialist      269 |
     |------------------------------------------------|
 26. |               Logistics Administrator      267 |
 27. |                        HRBP Assistant      265 |
 28. |                       UFLP Brand Bldg      256 |
 29. |                 Record to Report Spec      253 |
 30. |                 Finance BP Supervisor      247 |
     |------------------------------------------------|
 31. |              SC Customer Service Spec      240 |
 32. |             Processing Dev Technician      227 |
 33. |                             R&D Admin      223 |
 34. |                Customer Dev Ops Admin      221 |
 35. |             Brand Building Supervisor      216 |
     |------------------------------------------------|
 36. |                    Quality Specialist      200 |
 37. |                  Logistics Supervisor      196 |
 38. |                           Brand Admin      195 |
 39. |   Field Sales Administrator_Proximity      187 |
 40. |                        CMI Specialist      187 |
     |------------------------------------------------|
 41. |                Brand Development Spec      185 |
 42. |                      Brand Supervisor      183 |
 43. |                Engineering Supervisor      172 |
 44. |                 Demand Planning Admin      170 |
 45. |               Brand Development Admin      168 |
     |------------------------------------------------|
 46. |            Consumer Tech Insight Tech      158 |
 47. |                  UFLP Supply Chain GM      148 |
 48. |              Trade Category Mgmt Spec      147 |
 49. |             Cust and Account Mgmt Mgr      145 |
 50. |            Shopper & Custmr Mktg Admn      143 |
     |------------------------------------------------|
 51. |             Trade Category Mgmt Admin      142 |
 52. |                 Customer Dev Ops Spec      137 |
 53. |    Finance Business Partner - Analyst      131 |
 54. |               SC Customer Service Adm      128 |
 55. |            Exec Leadership Supervisor      125 |
     |------------------------------------------------|
 56. |                       UFLP Finance BP      115 |
 57. | Finance Business Partner - Supervisor      114 |
 58. |            Shopper & Custmr Mktg Supv      114 |
 59. |                 Customer Dev Ops Supv      112 |
 60. |                   Field Sales Manager      109 |
     |------------------------------------------------|
 61. |      Field Sales Specialist_Proximity      108 |
 62. |                UFLP Cust Dev Gen Mgmt      101 |
 63. |              Field Sales FS Pull Spec      100 |
 64. |            Supply Planning Supervisor       97 |
 65. |                 Record to Report Supv       95 |
     |------------------------------------------------|
 66. |            Service Mgmt Administrator       91 |
 67. |                Brand Building Manager       88 |
 68. |             Supply Chain Gen Mgmt Adm       86 |
 69. |                Procurement Supervisor       82 |
 70. |               Service Mgmt Specialist       80 |
     |------------------------------------------------|
 71. |                        UFLP Marketing       79 |
 72. |        Customer Management Specialist       78 |
 73. |     Customer Management Administrator       77 |
 74. |      Field Sales Supervisor_Proximity       76 |
 75. |             IT Business Partnerg Spec       76 |
     |------------------------------------------------|
 76. |                        CMI Supervisor       75 |
 77. |                       SEAC Specialist       74 |
 78. |            Regulatory Affairs Techncn       74 |
 79. |                          SEAC Manager       72 |
 80. |             UFLP Customer Development       72 |
     |------------------------------------------------|
 81. |                Field Sales Ops Worker       71 |
 82. |              HR Shared Services Admin       68 |
 83. |            SC Customer Service Superv       67 |
 84. |                       UFLP Brand Devl       63 |
 85. |            Report and Info Mgmt Admin       63 |
     |------------------------------------------------|
 86. |              Trade Category Mgmt Supv       61 |
 87. |                     CMI Administrator       61 |
 88. |                     UFLP Supply Chain       59 |
 89. |                        HRS Specialist       59 |
 90. |                  Site SHE Coordinator       58 |
     |------------------------------------------------|
 91. |              Workplace Services Admin       58 |
 92. |                         UFLP R&D Mgmt       57 |
 93. |                 FS SC Accounting Spec       56 |
 94. |   Field Sales Specialist_Modern Trade       53 |
 95. |            Demand Planning Supervisor       52 |
     |------------------------------------------------|
 96. |                   Site Quality Leader       51 |
 97. |            Exec Leadership Specialist       50 |
 98. |                          UFLP Finance       47 |
 99. |            IT Business Partnerg Admin       47 |
100. |                Brand Development Supv       46 |
*/