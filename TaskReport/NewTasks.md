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


<font color="red"> 

I have basically finished this task, but I didn't have time to offer you a reader-friendly summary for this task. Here are some bullet points for this task.
- I construct another accurate age measure: In principle, if we can observe an individual's `AgeBand` change, say, from 20-29 to 30-39, then we can identify their exact date of birth, and construct his age. (There are about 60% of workers whose age can be exactly identified. But I've also noticed some serious measurement error on the `AgeBand` variable.)
- Therefore, I have constructed three age-based HF measure:
  - exact age (<60%)
  - exact age + corrected measurement error ($\approx$ 60%)
  - exact age + corrected measurement error + imputed age (the original codes) (100%)
- Together with the tenure-based HF measure, we have 4 new HF measures.

My next step will be replicating some results using these new HF measures.
- My current plan is to focus only on Figures 3 and 5. What results do you want me to replicate so that we can compare different measurements?
- Another practical issue when I try to do this is the construction of the four treatment groups. 
  - The original data cleaning codes are a little confusing. Apart from simply comparing pre- and post-managers' types, you seem to impose some additional restrictions. I am not sure if I can follow your procedures exactly. 
  - I will try my best to follow your procedure. But this is a little tricky here, as ultimately, we don't know if the differences in results are caused by different data cleaning procedures or different HF measures. 

This task can really be time-consuming, as the regression itself takes quite a lot of time, let alone I have to understand the old codes and adapt them to current situation. 

 </font>


# Task 2. Time of within team vs. across team transfers

Compute time in months of within team vs across team transfers (this is related to the graph Figure IV) - I want to check whether within team transfers take less time to materialize. I'd like to know just number of months for LH and LL transitions.

<font color="red"> 

I have several questions about this task. 
1. I am a little confused by this "team" notion. My current understanding is: as long as workers are supervised by the same manager, they belong to the same team. Is my understanding correct?
2. What exactly statistics do you want? My current understanding is:
   - separately for the LtoL and LtoH groups, 
   - conditional on the worker have a transfer (defined as chaning his standard job),
   - distinguish between two types of transfers: within- and across-team transfers,
   - calculate the average time from the event to the two types of transfers.
   - There is no need to run regressions for this task. 

 </font>

# Task 3. Job tenure as a new outcome variable in the event study

- Instruction 1:  I want to use job tenure as a signal of better job matches. So ideally I want to run the same event study but with job tenure as an outcome. 
- Instruction 2: We need to experiment with different notion of jobs, try these for now: (a) standard job code (b) sub function (c) function. 
- Instruction 3: For each job notion, create these variables carefully as the same worker can return for example in the same sub function after sometime, so you cannot simply do it via: bys IDlse SubFunction: egen XX = total(YearMonth). 
- Instruction 4: Do two versions: (a) the continuous variable (b) a binary variable using 1 if at least X1 years and then X2 years [where X1 and X2 are replaced by the sample median and p75.]

<font color="red"> 

I have several questions about this task. 
1. Do you want the job tenure as an individual-level or individual-month level variable? If we wish to use it as outcome in an event study, it is better if we have an individual-month level outcome variable. However, this comes with a problem: When a worker transfers (to a new job, or a new subfunction or a new function), his corresponding job tenure mechanically drops to 0! It is a little weird to regard this measure as a signal of match quality, since our basic story is that good managers help workers find their better match inside the firm, which naturally means that this job tenure variable should drop to 0 at some point.
2. From certain perspective, the job tenure variable is like the "Exit" outcome (panel C in Figure IV). It is extremely hard to incorporate an individual-level variable in an event study design. Therefore, my thought is that Task 4 makes more sense than this task, and we should focus on the next task, instead of this one.

 </font>

# Task 4. Job tenure as a new outcome variable in a cross-sectional regression

- Instruction 1: We focus on the (a) standard job code (b) sub function (c) function a worker is in exactly 5 years after the manager change. 
- Instruction 2: Compute the total number of consecutive months in that job (from the first month they are in the job).
- Instruction 3: Take the log of the duration and run censored normal regressions where the X variable is LH, LL, HL, HH transition but then compute the gap. 
- Instruction 4: Control for country FE and time FE and function FE taken at the month of the manager transition (as the dataset is a cross section).

<font color="red"> 

Overall, this task is clear and easy to interpret. However, there is one practical issue: 
1. What is censored normal regression? 
2. Do we use this technique to account for the fact that we do not observe a worker's future job choice? In other words, we don't observe when the worker ends his current job, so we cannot calculate an accurate job tenure. 
3. Can you provide me with some guidance or examples?

 </font>

# Task 5. Skills data 

- Step 1: Categorize skills into topics by using the following two methods.
  - Method 1: word frequency analysis and word cloud
  - Method 2: topic modelling (LDA)
- Step 2: Contrast HF with non-HF over the above dimensions provided by Step 1.

<font color="red"> 

I have several questions about this task. 
1. Where is the new skills data? As time goes by, I forget which dataset contains this information. Sorry about this silly question.

 </font>






