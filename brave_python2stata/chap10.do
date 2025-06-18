********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************




* Create the dataset
clear
input str1 sex drug days
"M" 1 5
"M" 1 5
"M" 1 5
"M" 1 5
"M" 1 5
"M" 0 8
"W" 1 2
"W" 0 4
"W" 1 2
"W" 0 4
end

* Label variables
label variable sex "Patient Sex"
label variable drug "Drug Treatment (1=Yes)"
label variable days "Recovery Days"

* Display the data
list, sepby(sex) noobs


* Calculate mean recovery days by treatment group
table drug, stat(mean days)

* Calculate ATE manually
sum days if drug == 1
scalar mean_treated = r(mean)

sum days if drug == 0
scalar mean_control = r(mean)

scalar ate = mean_treated - mean_control
display "Average Treatment Effect (ATE): " ate

* Run OLS regression with drug treatment and sex fixed effects
encode sex, gen(sex_numeric)
regress days drug i.sex_numeric


* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/trainees.csv", clear


list if trainees == 1


list if trainees == 0

* Calculate mean earnings by trainee status
table trainees, stat(mean earnings)

* Calculate ATE (Average Treatment Effect) manually
sum earnings if trainees == 1
scalar mean_treated = r(mean)

sum earnings if trainees == 0
scalar mean_control = r(mean)

scalar ate = mean_treated - mean_control
display "Average Treatment Effect (ATE): " ate


* Step 1: Create dataset of unique non-trainees by age
preserve
    keep if trainees == 0
    duplicates drop age, force
    rename earnings earnings_non_trainee
    save non_trainees_unique, replace
restore

* Step 2: Merge trainees with their matches
preserve
    keep if trainees == 1
    merge m:1 age using non_trainees_unique, keep(match)
    
    * Calculate earnings difference
    gen earnings_diff = earnings - earnings_non_trainee
    
    * Display first 7 matches
    list age earnings earnings_non_trainee earnings_diff in 1/7, noobs clean
    display "Average Treatment Effect (matched sample): " 
    sum earnings_diff
restore


* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/medicine_impact_recovery.csv", clear


list in 1/5

* Calculate mean recovery by medication status
tabstat recovery, by(medication) stat(mean)

* Calculate and display the average treatment effect
sum recovery if medication == 1
scalar mean_treated = r(mean)

sum recovery if medication == 0
scalar mean_control = r(mean)

scalar ate = mean_treated - mean_control
display "Average Treatment Effect (ATE): " ate


* 1. Standardize features (mean=0, std=1)
foreach var in severity age sex {
    egen `var'_std = std(`var')
}

* Keep original and standardized variables
list severity severity_std age age_std sex sex_std recovery in 1/5, noobs clean


* 2. Perform KNN matching (k=1) with Mahalanobis distance
teffects nnmatch (recovery severity_std age_std sex_std) (medication), ///
    nn(1)        ///     // 1 nearest neighbor
    metric(maha)  ///    // Mahalanobis distance (accounts for covariance)
    generate(match_id) // Create ID variable for matched pairs

* 3. Extract matched pairs for inspection
preserve
    * Keep only treated units and their matches
    keep if medication == 1 | match_id != .
    
    * Sort to display treated-control pairs together
    sort match_id medication  
    
    * Display first 5 matched pairs
    list match_id medication recovery severity age sex in 1/10, ///
        sepby(match_id) noobs clean
restore

* 4. Calculate ATT manually from matched pairs
preserve
    * Create matched dataset
    keep if medication == 1 | match_id != .
    
    * Calculate control group mean for each matched set
    bysort match_id: egen mean_control = mean(recovery * (medication == 0))
    
    * Keep only treated units and compute individual treatment effects
    keep if medication == 1
    gen treatment_effect = recovery - mean_control
    
    * Display ATT results
    sum treatment_effect
    display "Average Treatment Effect on Treated (ATT): " r(mean) 
    display "Standard Error: " r(sd)/sqrt(r(N))
restore


/* 
Alternative using kmatch package (more sklearn-like):
ssc install kmatch
kmatch ps medication severity age sex, att nn(1) // Propensity score matching
kmatch md medication severity age sex, att nn(1) // Mahalanobis distance matching
*/














