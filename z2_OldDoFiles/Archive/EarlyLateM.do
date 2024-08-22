********************************************************************************
* M TYPE: CHAMPIONS, FASTEST STARTEST 
********************************************************************************

/* tenure thresholds 
A. entry level WL1: 
WL2: 3-4 YEARS - 1 PERIOD [20-30 age 1]
WL3: 9-11 YEARS - 2 PERIOD  [30-40 age 2]
WL4: 19-21 YEARS - 3 PERIOD [40-50 age 3]
WL5: 30 YEARS [50-60 age 4]

B. entry level WL2: 
WL3: 5 YEARS - 2 PERIOD 
WL4: 15 YEARS - 3 PERIOD 
WL5: 25 YEARS

C. entry level WL3: 
WL4: 10 YEARS - 3 PERIOD 
WL5: 20 YEARS

D. entry level WL4:  
WL5: 10 YEARS

* In practice in my sample, 9 years, I only experience managers moving from to the next level 
gcollapse o Tenure , by(IDlse WL )
bys IDlse: egen mm = min(WL)
bys IDlse: egen mmA = max(WL)
distinct IDlse if  mm ==1 & mmA>2 // 240 employees 

*/

* tenure- WL type of manager
gen WLAgg = WL
replace  WLAgg = 5 if WL > 4 & WL!=.

bys IDlse WLAgg: egen TenureMinByWL = min(Tenure) // min tenure by WL 
bys IDlse: egen MinWL = min(WLAgg) // starting WL 

* from WL 1 to 2
gen Early = 1 if  WLAgg ==2 & TenureMinByWL<6 & MinWL ==1 // observed in data starting from WL1 
* from WL 2 to 3
replace Early =1 if WLAgg ==3 & TenureMinByWL<6   & MinWL ==2 // case 1: individual is mid-career recruit WL2
replace Early =1 if WLAgg ==3 & TenureMinByWL<11   & MinWL ==2 & AgeBand ==2 // case 2: individual started in WL1 but data censored 
* from WL 3 to 4
replace Early =1 if WLAgg ==4 & TenureMinByWL<11   & MinWL ==3 // case 1: individual is mid-career recruit WL3
replace Early =1 if WLAgg ==4 & TenureMinByWL<16   & MinWL ==3 & AgeBand ==3 // case 2: individual is grown internally from WL2
replace Early =1 if WLAgg ==4 & TenureMinByWL<21   & MinWL ==3 & AgeBand ==3 // case 3: individual is grown internally from WL1
* from WL 4 to 5/6
replace Early =1 if WLAgg >=5 & TenureMinByWL<11   & MinWL ==4 // case 1: individual is mid-career recruit WL4
replace Early =1 if WLAgg >=5 & TenureMinByWL<21   & MinWL ==4 & AgeBand ==4 // case 2: individual is grown internally from WL3 
replace Early =1 if WLAgg >=5 & TenureMinByWL<26   & MinWL ==4 & AgeBand ==4 // case 3: individual is grown internally from WL2 
replace Early =1 if WLAgg >=5 & TenureMinByWL<31   & MinWL ==4 & AgeBand ==4 // case 4: individual is grown internally from WL1

replace Early = 0 if Early ==. 
bys IDlse: egen z = max(Early)
replace Early = z 
drop z 
rename Early EarlyM 
label var EarlyM "Fast manager"

/* testing the early vs late starters hypothesis from chiappori 

* from WL1 to WL2 
gen y1= 0 
replace y1 =1 if WLAgg ==2 & TenureMinByWL<6 & MinWL ==1 // only considering workers that start from WL1
bys IDlse: egen y1M = max(y1)
* from WL2 to WL3 
gen y2= 0 
replace y2 =2 if WLAgg ==3 & TenureMinByWL<11   & MinWL ==1 
replace y2 =2 if WLAgg ==3 & TenureMinByWL<6   & MinWL ==2 
replace y2 =1 if WLAgg ==2 & TenureMinByWL<11 & y2!=2 & MinWL ==1  // only considering workers that start
bys IDlse: egen y2M = max(y2)
*from WL3 to WL4+ 
gen y3 = 2 
replace y3 =  3 if WLAgg >=4 & TenureMinByWL<21   & MinWL ==1 
replace y3 =  3 if WLAgg >=4 & TenureMinByWL<16   & MinWL ==2 
replace y3 =  3 if WLAgg >=4 & TenureMinByWL<11   & MinWL ==3 
bys IDlse: egen y3M = max(y3)

gen Late = 1 if y1M==0 & y2M==1
replace Late = 0 if Late  ==. 

egen yy = tag(IDlse)
egen N013 = total(cond(y1M==0 & y2M==1 & y3M==3,yy, .) )
egen N01 = total(cond(y1M==0 & y2M==1 ,yy, .) )
egen N113= total(cond(y1M==1 & y2M==1 & y3M==3,yy, .) )
egen N11= total(cond(y1M==1 & y2M==1 ,yy, .) )

gen p = N013/N01
gen =  N113/  N11
su PromWL if Early ==1
su PromWL if Late ==1
*/
