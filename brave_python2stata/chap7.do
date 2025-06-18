********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* good/harmless controls
* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/collections_email.csv", clear


list in 1/5


* Calculate difference in means
sum payments if email == 1
scalar mean_treat = r(mean)

sum payments if email == 0
scalar mean_control = r(mean)

display "Difference in means: " %5.2f (mean_treat - mean_control)

* Run regression (equivalent to t-test)
regress payments email

* Create jittered email variable
gen email_jitter = email + rnormal(0, 0.01)

* Create scatterplot with jitter
twoway (scatter payments email_jitter, mcolor(blue%80) jitter(5)) ///
       (function y = _b[_cons] + _b[email]*x, range(-0.2 1.2) lcolor(orange) lwidth(medthick)), ///
       title("Payment by Email Treatment") ///
       xtitle("Email Treatment") ///
       ytitle("Payments") ///
       legend(off) ///
       graphregion(color(white)) ///
       plotregion(color(white)) ///
       xlabel(0 "Control" 1 "Treated", noticks) ///
       xscale(range(-0.3 1.3))


* Step 1: Regress email on covariates
regress email credit_limit risk_score
predict res_email, resid

* Step 2: Regress payments on same covariates
regress payments credit_limit risk_score
predict res_payments, resid

* Step 3: Regress payment residuals on email residuals
regress res_payments res_email


* Create the residuals plot
twoway (scatter res_payments res_email, mcolor(blue%50) msymbol(Oh)) ///
       (lfit res_payments res_email, lcolor(orange) lwidth(medthick)), ///
       title("Partial Regression Plot") ///
       xtitle("Email Residuals (orthogonal to covariates)") ///
       ytitle("Payments Residuals (orthogonal to covariates)") ///
       legend(off) ///
       graphregion(color(white)) ///
       plotregion(color(white)) ///
       xlabel(-0.7(0.2)1) ///
       ylabel(, angle(horizontal))


regress payments email credit_limit risk_score


* bad controls

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/hospital_treatment.csv", clear


list in 1/5

reg days treatment

reg days treatment if hospital == 0

reg days treatment if hospital == 1

reg days treatment severity

reg days treatment severity hospital

* Step 1: Regress treatment on covariates
regress treatment severity i.hospital
predict res_treatment, resid

* Step 2: Regress days on same covariates
regress days severity i.hospital
predict res_days, resid

* Step 3: Regress days residuals on treatment residuals
regress res_days res_treatment


* Calculate raw treatment variance
sum treatment
display "Treatment Variance: " %6.3f r(Var)

* Calculate residualized treatment variance
sum res_treatment
display "Treatment Residual Variance: " %6.3f r(Var)

* Calculate variance explained by covariates
display "Variance Explained by Controls: " %6.3f (`r(Var)' - r(Var))

* Calculate sigma_hat (MSE)
quietly regress res_days res_treatment
scalar sigma_hat = e(rmse)^2  // MSE = RMSE squared

* Calculate sum of squared residuals for treatment
quietly sum res_treatment
scalar ssr_treatment = r(Var)*(r(N)-1)  // Var*N = sum of squares

* Compute variance and SE of coefficient
scalar var_beta = sigma_hat/ssr_treatment
display "SE of the Coefficient: " %6.4f sqrt(var_beta)

* Verification against Stata's built-in calculation
matrix list e(V)  // Shows full variance-covariance matrix
display "Stata's SE: " %6.4f sqrt(e(V)[1,1])



* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/collections_email.csv", clear


list in 1/5

* Run the regression
regress payments email credit_limit risk_score
* Store results and display formatted table
estimates store email_model
esttab email_model, cells("b(star fmt(3)) se(par fmt(3))") ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    title("Email Treatment Effect with Controls") ///
    varwidth(25)

* Run regression with full controls
regress payments email credit_limit risk_score opened agreement

* Store and display results
estimates store email_full
esttab email_full, cells("b(star fmt(3)) se(par fmt(3))") ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    title("Email Treatment Effect with Full Controls") ///
    varwidth(25) ///
    order(email credit_limit risk_score opened agreement)

* Display both models
esttab email_model email_full, ///
    mtitle("email_model" "email_full") ///
    stats(N r2_a, fmt(0 3))	 


	
	
* Bad COP
* Generate the mixed distribution
clear
set obs 1700
gen spend = rgamma(5,50) in 1/1000  // Gamma-distributed spends
replace spend = 0 in 1001/1700       // Zero-spend customers

* Create histogram
hist spend, bin(20) ///
    title("Distribution of Customer Spend") ///
    xtitle("Customer Spend") ///
    ytitle("Frequency") ///
    graphregion(color(white)) ///
    plotregion(color(white))	///
    xlabel(0(100)800) ///
    note("Note: 700 zero-spend customers", size(small))















