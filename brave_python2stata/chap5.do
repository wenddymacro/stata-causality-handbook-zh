********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/online_classroom.csv", clear

* Filter to exclude blended format
keep if format_blended == 0

* Run OLS regression
regress falsexam format_ol
eststo online_model
* Display in results window
esttab online_model, cells("b(fmt(3) star)") ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N r2_a, labels("Observations" "Adj. R-squared"))  ///
    mtitle("Online vs Face-to-Face") ///
    nobaselevels ///
    interaction(" × ")
	
* Calculate mean falsexam by format_ol
collapse (mean) falsexam, by(format_ol)

* Display results with labels
list format_ol falsexam, noobs clean


* Load data and keep needed variables
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/online_classroom.csv", clear

* keep falsexam format_ol
keep if format_blended == 0

* Create intercept column
gen intercept = 1

* Prepare matrices
mkmat falsexam, matrix(y)
mkmat format_ol intercept, matrix(X)

* Calculate regression coefficients using matrix algebra
matrix XpX = X'*X
matrix Xpy = X'*y
matrix beta = invsym(XpX)*Xpy

* Display results
matrix list beta


* Calculate covariance and variance
correlate falsexam format_ol, covariance
matrix C = r(C)
scalar cov_falsexam_format = C[2,1]

summarize format_ol
scalar var_format = r(Var)

* Compute kappa (regression coefficient)
scalar kappa = cov_falsexam_format / var_format

* Display result
display "Kappa (regression coefficient) = " %5.3f kappa


* 1. Calculate residuals
predict e, resid

* 2. Verify orthogonality (dot product should be zero)
matrix accum Xe = format_ol intercept e, noconstant
matrix list Xe

* 3. Display orthogonality check results
display "Orthogonality check - dot product of residuals and:"
display " format_ol: " %9.6f Xe[1,3]
display " intercept: " %9.6f Xe[2,3]

* 4. Calculate correlation between residuals and format_ol
correlate format_ol e
matrix list r(C)

* 5. Alternative table format (similar to pandas .corr())
estpost correlate format_ol e, matrix
esttab, unstack not noobs compress


* Load data and keep needed variables
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/wage.csv", clear

* Remove observations with missing values
drop if missing(wage, hours, educ)

* Create hourly wage variable (annual wage divided by hours worked)
gen hwage = wage/hours

* Create natural log of hourly wage for regression
gen lnhwage = ln(hwage)

/*
Run OLS regression:
Dependent variable: log hourly wage
Independent variable: years of education
*/
regress lnhwage educ


* Generate education years range (5-19)
range educ_vals 5 19 15

* Calculate predicted log hourly wage using regression coefficients
predict yhat
gen pred_wage = exp(yhat) if educ == 5  // Initialize with first value

* Calculate predicted wages for all education levels
forvalues i = 6/19 {
    replace pred_wage = exp(_b[_cons] + _b[educ]*`i') if educ_vals == `i'
}

* Create the plot
twoway (line pred_wage educ_vals), ///
       title("Impact of Education on Hourly Wage") ///
       xtitle("Years of Education") ///
       ytitle("Hourly Wage")

list in 1/5

// Define control variables
global controls iq exper tenure age married black south urban sibs brthord meduc feduc

// Create constant term (intercept)
gen intercep = 1

// Step 1: Auxiliary regression of education (endogenous treatment) on controls
reg educ $controls intercep

// Step 2: Compute residuals from auxiliary regression
predict t_tilde, residuals

// Step 3: Calculate covariance between residuals and outcome variable (lhwage)
corr t_tilde lhwage, covariance
scalar cov_ty = r(cov_12)  // Stores covariance in scalar

// Step 4: Calculate variance of residuals
sum t_tilde
scalar var_t = r(Var)  // Stores residual variance in scalar

// Step 5: Compute kappa estimator (local treatment effect)
scalar kappa = cov_ty/var_t

// Display the final result
display "Local average treatment effect (kappa) = " kappa


// Run OLS regression with estout output
reg lhwage educ $controls
eststo ols_model

// Display results using esttab
* ssc install estout, replace
esttab ols_model, ///
    cells(b(star fmt(3)) se(par fmt(2))) ///
    stats(N r2, fmt(0 3)) ///
    title("OLS Estimation Results") ///
    label


















