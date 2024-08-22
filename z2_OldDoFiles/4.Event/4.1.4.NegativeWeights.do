********************************************************************************
* Analysing the weights from the twowayfe command by Chaisemartin 
* implement a test for the potential influence of negative weights 
* At the employee level, the total sum of negative weights equals XXX
* Given that all weights must sum to one, these results indicate that the negative weights are not influential in this setting.
********************************************************************************

use  "$managersdta/AllSameTeam.dta", clear 
*use "$managersdta/SwitchersAllSameTeam.dta", clear 

* choose the manager type !MANUAL INPUT!
global Label PromSG75

*renaming
foreach v in HL LL LH HH{
rename $Label`v' E`v'	
rename K$Label`v' KE`v'	
rename $Label`v'Post E`v'Post
}

********************************************************************************
* Checking for DID NEGATIVE WEIGHTS & CONTAMINATION WEIGHTS FROM OTHER TREATMENTS 
********************************************************************************

foreach var in LogPayBonus ChangeSalaryGradeC PromWLC VPA LeaverPerm TransferInternalC TransferInternalLLC TransferInternalVC  TransferFuncC TransferInternalSameMC  TransferInternalDiffMC {
twowayfeweights `var' IDlse YearMonth ELHPost , type(feTR) controls( Tenure TenureM Tenure2 Tenure2M ) other_treatments(ELLPost EHHPost EHLPost ) path("$analysis/Results/4.Event/twowayfeweights`var'.dta") 
}

gen lastcohort = Ei==. // never-treated cohort

* eventstudyweights 
* eventstudyweights F2ELH L1ELH L2ELH L3ELH, controls(i.IDlse i.YearMonth) cohort(Ei) rel_time(KEi) saveweights("$analysis/Results/4.Event/weights")


*did_multipleGT Y G T D, placebo(2) dynamic(1) breps(50) cluster(G)
*ereturn list

* Analysing weights 
********************************************************************************

use  "$analysis/Results/4.Event/twowayfeweightsLogPayBonus.dta" , clear 

isid Group Time 

* 1) Weights on coeff: they sum to 1, we want fewer and smaller possible negative weights 
gen i0 = weight>=0 // positive weights obs 
egen Possum0 = sum(weight) if i0==1
egen Negsum0 = sum(weight) if i0==0

* 2) Weights on contamination from other treatments, they need to sum zero, we want them as small as possible 
forval i = 1/3{

gen i`i' = weight_others`i'>=0 // positive weights obs 

egen Possum`i' = sum(weight_others`i') if i`i'==1
egen Negsum`i' = sum(weight_others`i') if i`i'==0

}

su Pos*
su Neg*

********************************************************************************
* The first weight are the ATT weights, they have to sum to 1, we want smallest possible negative weights  
* The following 3 weights are the contamination weights of the other treatments on the first treatment, we want them to be as small as possible (e.g. <0.05), they have to sum to zero. I have for all outcomes <0.06 so pretty small, with most of them having 0.00 
********************************************************************************

/* Reporting below the results when running twowayfe command (which can be replicated using the saved dta with weights):

>>>>>>>>>>>>>>>>>>LogPayBonus
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 76635 ATTs of the treatment.
51297 ATTs receive a positive weight, and 25338 receive a negative weight.
The sum of the positive weights is equal to 1.008618.
The sum of the negative weights is equal to -.00861799.
The next term is a weighted sum of 236238 ATTs of treatment 1 included in the other_treatments option.
99718 ATTs receive a positive weight, and 136520 receive a negative weight.
The sum of the positive weights is equal to .04142933.
The sum of the negative weights is equal to -.04142933.
The next term is a weighted sum of 34704 ATTs of treatment 2 included in the other_treatments option.
14230 ATTs receive a positive weight, and 20474 receive a negative weight.
The sum of the positive weights is equal to .00636833.
The sum of the negative weights is equal to -.00636833.
The next term is a weighted sum of 77655 ATTs of treatment 3 included in the other_treatments option.
32143 ATTs receive a positive weight, and 45512 receive a negative weight.
The sum of the positive weights is equal to .01395776.
The sum of the negative weights is equal to -.01395776.

>>>>>>>>>>>>>>>>>>ChangeSalaryGradeC
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .027953.
The sum of the negative weights is equal to -.027953.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434115.
The sum of the negative weights is equal to -.00434115.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .00962289.
The sum of the negative weights is equal to -.00962289.

>>>>>>>>>>>>>>>>>>PromWLC
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .02795302.
The sum of the negative weights is equal to -.02795302.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434116.
The sum of the negative weights is equal to -.00434116.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .0096229.
The sum of the negative weights is equal to -.0096229.

>>>>>>>>>>>>>>>>>>VPA
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 40057 ATTs of the treatment.
21128 ATTs receive a positive weight, and 18929 receive a negative weight.
The sum of the positive weights is equal to 1.0161823.
The sum of the negative weights is equal to -.01618223.
The next term is a weighted sum of 115352 ATTs of treatment 1 included in the other_treatments option.
52101 ATTs receive a positive weight, and 63251 receive a negative weight.
The sum of the positive weights is equal to .05296967.
The sum of the negative weights is equal to -.05296967.
The next term is a weighted sum of 18712 ATTs of treatment 2 included in the other_treatments option.
8486 ATTs receive a positive weight, and 10226 receive a negative weight.
The sum of the positive weights is equal to .0086489.
The sum of the negative weights is equal to -.0086489.
The next term is a weighted sum of 39607 ATTs of treatment 3 included in the other_treatments option.
17757 ATTs receive a positive weight, and 21850 receive a negative weight.
The sum of the positive weights is equal to .01803502.
The sum of the negative weights is equal to -.01803502.

>>>>>>>>>>>>>>>>>>LeaverPerm
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .027953.
The sum of the negative weights is equal to -.027953.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434115.
The sum of the negative weights is equal to -.00434115.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .00962289.
The sum of the negative weights is equal to -.00962289.

>>>>>>>>>>>>>>>>>> TransferInternalC
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .027953.
The sum of the negative weights is equal to -.027953.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434115.
The sum of the negative weights is equal to -.00434115.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .00962289.
The sum of the negative weights is equal to -.00962289.

>>>>>>>>>>>>>>>>>>TransferInternalLLC 
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .027953.
The sum of the negative weights is equal to -.027953.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434115.
The sum of the negative weights is equal to -.00434115.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .00962289.
The sum of the negative weights is equal to -.00962289.

>>>>>>>>>>>>>>>>>>TransferInternalVC
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .027953.
The sum of the negative weights is equal to -.027953.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434115.
The sum of the negative weights is equal to -.00434115.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .00962289.
The sum of the negative weights is equal to -.00962289.

>>>>>>>>>>>>>>>>>>TransferFuncC
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .027953.
The sum of the negative weights is equal to -.027953.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434115.
The sum of the negative weights is equal to -.00434115.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .00962289.
The sum of the negative weights is equal to -.00962289.

>>>>>>>>>>>>>>>>>> TransferInternalSameMC 
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .027953.
The sum of the negative weights is equal to -.027953.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434115.
The sum of the negative weights is equal to -.00434115.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .00962289.
The sum of the negative weights is equal to -.00962289.

>>>>>>>>>>>>>>>>>> TransferInternalDiffMC
Under the common trends assumption, beta estimates the sum of several terms.
The first term is a weighted sum of 91598 ATTs of the treatment.
90831 ATTs receive a positive weight, and 767 receive a negative weight.
The sum of the positive weights is equal to 1.0001869.
The sum of the negative weights is equal to -.00018691.
The next term is a weighted sum of 283476 ATTs of treatment 1 included in the other_treatments option.
127400 ATTs receive a positive weight, and 156076 receive a negative weight.
The sum of the positive weights is equal to .027953.
The sum of the negative weights is equal to -.027953.
The next term is a weighted sum of 42320 ATTs of treatment 2 included in the other_treatments option.
18263 ATTs receive a positive weight, and 24057 receive a negative weight.
The sum of the positive weights is equal to .00434115.
The sum of the negative weights is equal to -.00434115.
The next term is a weighted sum of 94781 ATTs of treatment 3 included in the other_treatments option.
41427 ATTs receive a positive weight, and 53354 receive a negative weight.
The sum of the positive weights is equal to .00962289.
The sum of the negative weights is equal to -.00962289.
*/
