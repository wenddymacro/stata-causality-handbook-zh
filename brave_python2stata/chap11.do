********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/learning_mindset.csv", clear


list in 1/5


* Calculate mean intervention rate by success_expect categories
table success_expect, stat(mean intervention)


* run ols 
reg achievement_score intervention

* Set graph style
set scheme s1color
color_style tableau

* Create combined histogram
twoway (histogram achievement_score, bin(20) color(blue%30) legend(label(1 "All"))) ///
       (histogram achievement_score if intervention == 0, bin(20) color(green%30) legend(label(2 "Untreated"))) ///
       (histogram achievement_score if intervention == 1, bin(20) color(red%30) legend(label(3 "Treated"))) ///
       (function y = 0, range(-4 4) lcolor(green) lpattern(solid) lwidth(0.4) legend(label(4 "Untreated Mean"))) ///
       (function y = 0, range(-4 4) lcolor(red) lpattern(solid) lwidth(0.4) legend(label(5 "Treated Mean"))), ///
       title("Achievement Score Distribution") ///
       xtitle("Achievement Score") ///
       ytitle("Frequency") ///
       legend(position(6) rows(1)) ///
       graphregion(color(white)) ///
       plotregion(color(white)) ///
       xlabel(-4(1)4, grid) ///
       ylabel(, grid)

	   
	   

* 1. Create dummy variables for categorical features
foreach var in ethnicity gender school_urbanicity {
    tab `var', gen(`var'_)
    label var `var'_1 "`var' category 1"
    * Drop reference category if needed (uncomment)
    * drop `var'_1
}

* 2. Keep only continuous variables and new dummies
keep achievement_score intervention ///
     school_mindset school_achievement school_ethnic_minority ///
     school_poverty school_size ethnicity_* gender_* school_urbanicity_* ///
	 schoolid frst_in_family schoolid success_expect

* 3. Display new dataset structure
describe
display "New dataset dimensions: " c(N) " observations, " c(k) " variables"

	   
	   
* 1. Run high-regularization logistic regression 
logit intervention school_mindset school_achievement school_ethnic_minority ///
                school_poverty school_size ethnicity_* gender_* school_urbanicity_*

* 2. Predict propensity scores
predict propensity_score, pr

* 3. Create new dataset with key variables
preserve
    keep schoolid intervention achievement_score propensity_score
    order schoolid intervention achievement_score propensity_score
    
    * Display first 5 observations
    list in 1/5, noobs clean
    
    * Save for analysis
    save propensity_scores, replace
restore


* 1. Calculate inverse probability weights
gen ipw = .
replace ipw = 1/propensity_score if intervention == 1
replace ipw = 1/(1-propensity_score) if intervention == 0

* 2. Calculate and display sample sizes
count
display "Original Sample Size: " r(N)

sum ipw if intervention == 1
display "Treated Population Sample Size: " r(sum)

sum ipw if intervention == 0
display "Untreated Population Sample Size: " r(sum)


* Set modern graph style
set scheme s2color
color_style tableau

* Create boxplot with enhanced formatting
graph box propensity_score, over(success_expect) ///
    title("Confounding Evidence", size(medium)) ///
    ytitle("Propensity Score", size(small)) ///
    box(1, color(blue%50)) ///
    box(2, color(orange%50)) ///
    box(3, color(green%50)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    ylabel(0.2(0.05)0.5, grid gmin gmax) ///
    legend(off)


*  Check propensity score distribution
twoway (histogram propensity_score if intervention==1, color(red%30)) ///
       (histogram propensity_score if intervention==0, color(blue%30)), ///
       legend(order(1 "Treated" 2 "Untreated")) ///
       title("Propensity Score Distribution") ///
       xtitle("Propensity Score") ///
       graphregion(color(white))

* 1. Calculate normalized IP weights
gen ipw1 = (intervention - propensity_score) / (propensity_score * (1 - propensity_score))

* 2. Calculate potential outcomes
sum achievement_score [aw=ipw1] if intervention == 1
scalar y1 = r(mean)

sum achievement_score [aw=ipw1] if intervention == 0
scalar y0 = r(mean)

* 3. Calculate ATE
scalar ate = y1 - y0

* 4. Display results with 95% CIs
display "Potential Outcomes and ATE:"
display "Y1: " %5.3f y1 " [95% CI: " %5.3f (y1 - invttail(r(N)-1,0.025)*r(sd)/sqrt(r(N))) ", " %5.3f (y1 + invttail(r(N)-1,0.025)*r(sd)/sqrt(r(N))) "]"
display "Y0: " %5.3f y0 " [95% CI: " %5.3f (y0 - invttail(r(N)-1,0.025)*r(sd)/sqrt(r(N))) ", " %5.3f (y0 + invttail(r(N)-1,0.025)*r(sd)/sqrt(r(N))) "]"
display "ATE: " %5.3f ate " [95% CI: " %5.3f (ate - invttail(r(N)-1,0.025)*r(sd)/sqrt(r(N))) ", " %5.3f (ate + invttail(r(N)-1,0.025)*r(sd)/sqrt(r(N))) "]"

* 5. Recommended: Use teffects for proper inference
teffects ipw (achievement_score) (intervention, logit), ///
    osample(overlap) ///
    vce(robust)


* 倾向得分法的常见问题	   
* Template from Hernán‘s book

clear all
set seed 42  // Set random seed for reproducibility (matches Python's np.random.seed(42))

// Create data for School A
set obs 400  // Create 400 observations
gen school = 0  // School identifier (0 for School A)
gen intercept = 1  // Constant/intercept term
gen T = rbinomial(1, 0.99)  // Generate treatment variable (99% probability of 1)
tempfile school_a  // Create temporary file to store School A data
save `school_a'  // Save School A data

// Create data for School B
clear  // Clear memory
set obs 400  // Create 400 observations
gen school = 1  // School identifier (1 for School B)
gen intercept = 1  // Constant/intercept term
gen T = rbinomial(1, 0.01)  // Generate treatment variable (1% probability of 1)
tempfile school_b  // Create temporary file to store School B data
save `school_b'  // Save School B data

// Combine datasets (equivalent to pd.concat in Python)
use `school_a', clear  // Load School A data
append using `school_b'  // Append School B data

// Generate outcome variable y (equivalent to .assign() in Python)
gen y = rnormal(1 + 0.1 * T)  // y ~ N(1 + 0.1*T, 1)

// Display first 5 observations (equivalent to .head() in Python)
list in 1/5	


// Define program to estimate ATE
capture program drop run_ps
program define run_ps, rclass
    syntax varlist, TREATment(varname) OUTcome(varname)
    
	// Remove existing ps variable if it exists
    capture drop ps
    capture drop weight
	
    // Logistic regression for propensity score
    logit `treatment' `varlist'
    predict ps, pr  // Get propensity scores
    
    // IPW estimation (inverse probability weighting)
    tempvar weight
    gen `weight' = `treatment'/ps + (1-`treatment')/(1-ps)
    
    // Weighted regression for ATE
    reg `outcome' `treatment' [pw=`weight']
    
    // Return coefficient on treatment
    return scalar ate = _b[`treatment']
end

// Initialize matrices to store results (equivalent to np.array)
matrix ate_w_f = J(500, 1, .)  // With school fixed effect
matrix ate_wo_f = J(500, 1, .)  // Without school fixed effect

// Bootstrap loop (500 replications)
forvalues i = 1/500 {
    preserve  // Preserve original data
    
    // Resample with replacement (equivalent to sample(frac=1, replace=True))
    bsample
    
    // Run estimation with school fixed effect
    run_ps school, treatment(T) outcome(y)
    matrix ate_w_f[`i', 1] = r(ate)
    
    // Run estimation with only intercept
    run_ps intercept, treatment(T) outcome(y)
    matrix ate_wo_f[`i', 1] = r(ate)
    
    restore  // Restore original data
}

// Convert matrices to Stata variables for analysis
clear
svmat ate_w_f, names(ate_with_fixed)
svmat ate_wo_f, names(ate_without_fixed)

// Summarize results
summarize ate_with_fixed ate_without_fixed

// Create kernel density plots with histograms
twoway ///
    (histogram ate_with_fixed, color(blue%30) bin(30) legend(label(1 "PS W School"))) ///
    (histogram ate_without_fixed, color(red%30) bin(30) legend(label(2 "PS W/O School"))) ///
    (kdensity ate_with_fixed, lcolor(blue) lwidth(medthick)) ///
    (kdensity ate_without_fixed, lcolor(red) lwidth(medthick)), ///
    legend(order(1 2) position(6) rows(1)) ///
    title("Distribution of ATE Estimates") ///
    xtitle("ATE Estimate") ytitle("Density") ///
    graphregion(color(white)) plotregion(color(white))
   
// Set seed for reproducibility
set seed 42

// Generate Beta-distributed data (500 obs each)
set obs 500
gen non_treated = rbeta(4,1)  // Beta(4,1) distribution
gen treated = rbeta(1,3)      // Beta(1,3) distribution

// Create histogram plot for positivity check
twoway ///
    (histogram non_treated, color(blue%30) bin(30) legend(label(1 "Treated"))) ///
    (histogram treated, color(red%30) bin(30) legend(label(2 "Non-Treated"))), ///
    title("Positivity Check") ///
    xtitle("Propensity Score") ytitle("Frequency") ///
    legend(order(1 2) position(6) rows(1)) ///
    graphregion(color(white)) plotregion(color(white))	   
	   
* 控制倾向得分的ols
reg achievement_score intervention propensity_score,vce(robust)	   
	   
* Recommended: Use teffects for proper inference
teffects ipw (achievement_score) (intervention, logit), ///
    osample(overlap) ///
    vce(robust)	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   













