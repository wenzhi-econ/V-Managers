# Task 1. New HF measures

- Step 1: Impute a continuous age and continuous tenure measure (instead of bands).
- Step 2: Distribution of continuous age and continuous tenure at promotion to WL2. 
- Step 3: Distinguish between two groups of individuals and construct a HF measure.
  - Group 1: Individuals whose promotion from WL1 to WL2 are observed in the dataset. For those workers, we know their exact age at promotion. We first repeat Step 2 for this subsample.
  - Group 2: Individuals who start at WL2 when they first appear in the dataset. 
    - Group 2 - Case 1: If his age band when he first appears in the dataset is under 30, then he will be identified as HF.
    - Group 2 - Case 2: If his age band when he first appears in the dataset is above 30, then for this group of workers, conduct the following procedure. 
      - Get the minimum age observed for the individual and subtract it from the minimum tenure, this gives us the age of entry in the firm. 
      - Use age of entry + minimum tenure as the key indicator and tag an individual HF is that variable is <=33.
- Step 4: For Group 1 workers, construct another HF measure based on tenure only. The cutoff is determined by calculating the top tercile based on minimum tenure.


# Task 2. Time of within team vs. across team transfers

Compute time in months of within team vs across team transfers (this is related to the graph Figure IV) - I want to check whether within team transfers take less time to materialize. I'd like to know just number of months for LH and LL transitions.

# Task 3. Job tenure as a new outcome variable in the event study

- Instruction 1:  I want to use job tenure as a signal of better job matches. So ideally I want to run the same event study but with job tenure as an outcome. 
- Instruction 2: We need to experiment with different notion of jobs, try these for now: a) standard job code b) sub function c) function. 
- Instruction 3: For each job notion, create these variables carefully as the same worker can return for example in the same sub function after sometime, so you cannot simply do it via: bys IDlse SubFunction: egen XX = total(YearMonth). 
- Instruction 4: Do two versions: (a) the continuous variable (b) a binary variable using 1 if at least X1 years and then X2 years [where X1 and X2 are replaced by the sample median and p75.]

# Task 4. Job tenure as a new outcome variable in a cross-sectional regression

- Instruction 1: We focus on the a) standard job code b) sub function c) function a worker is in exactly 5 years after the manager change. 
- Instruction 2: Compute the total number of consecutive months in that job (from the first month they are in the job).
- Instruction 3: Take the log of the duration and run censored normal regressions where the X variable is LH, LL, HL, HH transition but then compute the gap. 
- Instruction 4: Control for country FE and time FE and function FE taken at the month of the manager transition (as the dataset is a cross section).

# Task 5. Skills data 

- Step 1: Categorize skills into topics by using the following two methods.
  - Method 1: word frequency analysis and word cloud
  - Method 2: topic modelling (LDA)
- Step 2: Contrast HF with non-HF over the above dimensions provided by Step 1.







