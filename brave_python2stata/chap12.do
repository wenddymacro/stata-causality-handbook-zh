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


* ------------------------------------------------------------------------------
* Manual Implementation of Doubly Robust Estimation
* ------------------------------------------------------------------------------
global contvar "school_mindset school_achievement school_ethnic_minority school_poverty school_size"

global categvar "ethnicity_* gender_* school_urbanicity_*"

* Step 1: Estimate propensity scores (treatment model)
logit intervention $contvar i.${categvar}  // Include all covariates
predict ps, pr  // Generate propensity scores

* Step 2: Create inverse probability weights
gen ipw = intervention/ps + (1-intervention)/(1-ps)

* Step 3: Estimate weighted outcome model (outcome regression)
reg achievement_score intervention $contvar i.${categvar} [pw=ipw]

* Step 4: Extract ATE estimate
lincom intervention  // Get average treatment effect with confidence intervals

* Clean up
drop ps ipw

* teffects：ipwra - double robust estimator, the result as same as above
teffects ipwra (achievement_score $contvar i.${categvar}) ///
               (intervention $contvar i.${categvar}, logit)
			   

* (1) wrong propensity score
* Set random seed for reproducibility
set seed 654

* Generate wrong propensity scores (uniform between 0.1 and 0.9)
gen ps = runiform(0.1, 0.9)

* View summary statistics to verify
summarize ps

* Step 1: Create inverse probability weights
gen ipw = intervention/ps + (1-intervention)/(1-ps)

* Step 2: Estimate weighted outcome model (outcome regression)
reg achievement_score intervention $contvar i.${categvar} [pw=ipw]

* Step 3: Extract ATE estimate
lincom intervention  // Get average treatment effect with confidence intervals

* Clean up
drop ps ipw

* (2) wrong mu(x) model:wrong linear model
* Step 1: Estimate propensity scores (treatment model)
logit intervention $contvar i.${categvar}  // Include all covariates
predict ps, pr  // Generate propensity scores

* Step 2: Create inverse probability weights
gen ipw = intervention/ps + (1-intervention)/(1-ps)

* Step 3: Estimate weighted outcome model (outcome regression)
reg achievement_score intervention [pw=ipw]

* Step 4: Extract ATE estimate
lincom intervention  // Get average treatment effect with confidence intervals

* Clean up
drop ps ipw
