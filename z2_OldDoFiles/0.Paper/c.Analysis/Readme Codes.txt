README - EVENT STUDY codes

- All codes are standard regression apart from ONET and Exit 

STANDARD LH: 

eststo: reghdfe ChangeSalaryGradeC  $LLH $LLL $FLH  $FLL if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1) )  , a( IDlse YearMonth  )  vce(cluster IDlseMHR)


ONET LH: 

eststo: reghdfe ONETSkillsDistanceC  $LLH $LLL $FLH  $FLL    if ( (WL2==1 & (FTLHB==1 | FTLLB==1)) | ( random==1 ) )   , a( Country YearMonth  AgeBand##Female   )  vce(cluster IDlseMHR)


STANDARD HL: 

eststo: reghdfe ChangeSalaryGradeC $LHL  $LHH  $FHL  $FHH     if ( (WL2==1 & (FTHLB==1 | FTHHB==1)) | ( random==1  & FTHLB==0 & FTHHB==0) )   , a( IDlse YearMonth )  vce(cluster IDlseMHR)


EXIT:

LeaverPerm (LH and HL and DUAL) & LeaverVol & LeaverInv
eststo: reghdfe LeaverPerm $event  if KEi>-1 & WL2==1 & cohort30==1 , a( Office##Func##YearMonth  AgeBand##Female   ) vce(cluster IDlseMHR) 


DUAL: 




