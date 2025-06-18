********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/enem_scores.csv", clear

* Create basic scatterplot	   
* Find max values
sum number_of_students, meanonly
local max_students = r(max)
sum avg_score, meanonly
local max_score = r(max)

twoway (scatter avg_score number_of_students) ///
       (scatter avg_score number_of_students if number_of_students == `max_students', ///
           mlabel(school_id) mlabcolor(black)) ///
       (scatter avg_score number_of_students if avg_score == `max_score', ///
           mlabel(school_id) mlabcolor(black)), ///
       title("ENEM Score by Number of Students") ///
       legend(off)
	   
	   
	   
* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/wage.csv", clear	   
	   
list in 1/5	  


* Run regression and store results
regress lhwage educ
eststo model1

* Export publication-ready table (English output)
esttab model1 using "wage_regression.rtf", ///
    replace ///
    b(3) se(3) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N r2_a, fmt(0 3) labels("Observations" "Adj. R-squared")) ///
    title("Returns to Schooling: Wage Regression Results") ///
    label ///
    varwidth(20) ///
    addnotes("*** p<0.001, ** p<0.01, * p<0.05") ///
    nogaps

* Simplified console output
esttab model1, cells("b(fmt(3) star)") ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N r2_a, fmt(0 3)) ///
    mtitle("Model (1)") ///
    noomitted
	
* Alternative using tabstat
tabstat lhwage, by(educ) stat(mean count) nototal		
	
* Correct way to collapse with counts
preserve
    * First create an ID variable for counting
    gen id = 1
    
    * Then collapse
    collapse (mean) lhwage (sum) count=id, by(educ)
    
    * Now run WLS regression
    regress lhwage educ [aweight=count]
    eststo model2
    * Display results
    esttab model2, cells("b(star fmt(3))") ///
        stats(N r2_a, labels("N" "Adj. R2"))
restore	
	
* Display both models
esttab model1 model2, ///
    mtitle("OLS" "WLS") ///
    stats(N r2_a, fmt(0 3))	   
	   
	   
* First create the grouped data
preserve
    gen id = 1
    collapse (mean) lhwage (sum) count=id, by(educ)
    
    * Run OLS on group means (unweighted)
    regress lhwage educ
    
    * Display formatted results
    eststo model3
    esttab model3, cells("b(star fmt(3))") ///
        stats(N r2, labels("Groups" "R-squared")) ///
        title("OLS on Group Means") ///
        varwidth(15)
restore	 


esttab model1 model2 model3, ///
    mtitle("Original OLS" "WLS" "Grouped OLS") ///
    stats(N r2, fmt(0 3))  
	   
	   
* Create grouped data if not already done
preserve
    gen id = 1
    collapse (mean) lhwage (sum) count=id, by(educ)
    
    * Run both regressions
    regress lhwage educ [aweight=count]  // Weighted
    predict weighted_pred
    regress lhwage educ                  // Unweighted
    predict unweighted_pred
    
    * Create the plot
    twoway (scatter lhwage educ [weight=count], ///
               msymbol(Oh) msize(*.5) mcolor(blue)) ///
           (line weighted_pred educ, lcolor(orange) lwidth(medthick)) ///
           (line unweighted_pred educ, lcolor(green) lwidth(medthick)), ///
           title("Log Wage by Education") ///
           xtitle("Years of Education") ///
           ytitle("Log Hourly Wage") ///
           legend(order(2 "Weighted" 3 "Non Weighted") pos(6) row(1)) ///
           graphregion(color(white)) ///
           plotregion(color(white)) ///
           xlabel(8(2)20) ///
           ylabel(, angle(horizontal))
restore	   
	   
	   
* Create grouped data with means and counts
preserve
    gen count = 1
    collapse (mean) lhwage iq (sum) count, by(educ)
    
    * Run WLS regression
    regress lhwage educ iq [aweight=count]
    
    * Display results
    estimates store model4
    display "Number of observations: " e(N)
    esttab model4, cells("b(star fmt(3))") ///
        stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
        title("WLS Results with IQ") ///
        varwidth(20)
restore	   
	   
esttab model1 model2 model3 model4, ///
    mtitle("Original OLS" "WLS" "Grouped OLS" "With Covariate") ///
    stats(N r2, fmt(0 3))	   
	   
	   
* Create hourly wage (wage divided by hours)
gen hwage = wage / hours

* Create treatment indicator (education > 12 years)
gen T = (educ > 12) if !missing(educ)

* Label variables
label variable hwage "Hourly wage"
label variable T "Higher education (educ > 12)"

* Display first 5 observations of selected variables
list hwage iq T in 1/5, noobs clean	   
	   
	   
* Run OLS regression of hourly wage on treatment indicator
regress hwage T

* Display formatted coefficient table
eststo model5

* Alternative using esttab for publication-quality output
esttab model5, cells("b(star fmt(3))") ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    title("Treatment Effect of Higher Education on Hourly Wage") ///
    varwidth(20)	   
	   	   
	   
* Run OLS regression with treatment and IQ
regress hwage T iq

* Store fitted values
predict y_hat, xb

* Create separate prediction lines
twoway (line y_hat iq if T == 1, lcolor(orange) lwidth(medthick)) ///
       (line y_hat iq if T == 0, lcolor(green) lwidth(medthick)), ///
       title("Treatment Effect Conditional on IQ") ///
       subtitle("E[T=1|IQ] - E[T=0|IQ] = " + string(_b[T], "%4.2f")) ///
       ytitle("Predicted Hourly Wage") ///
       xtitle("IQ Score") ///
       legend(order(1 "T=1 (educ >12)" 2 "T=0 (educ ≤12)")) ///
       graphregion(color(white)) ///
       plotregion(color(white))	   
	   
	   
* 1. Run regression with interaction term
regress hwage c.T##c.iq

* 2. Store coefficients for dynamic title
scalar T_effect = _b[T]
scalar IQ_effect = _b[iq]
scalar interaction = _b[T#c.iq]

* 3. Generate predicted values
predict y_hat1, xb

* 4. Create plot with interaction lines
twoway (line y_hat1 iq if T == 1, lcolor(orange) lwidth(medthick)) ///
       (line y_hat1 iq if T == 0, lcolor(green) lwidth(medthick)), ///
       title("Treatment Effect with IQ Interaction") ///
       ytitle("Predicted Hourly Wage") ///
       xtitle("IQ Score") ///
       legend(order(1 "T=1 (educ >12)" 2 "T=0 (educ ≤12)")) ///
       graphregion(color(white)) ///
       plotregion(color(white))	   
	   
	   
* Create IQ quartile bins (4 equal-sized groups)
xtile iq_bins = iq, nq(4)

* Label the bins for clarity
label define iq_bins 1 "Q1 (Lowest)" 2 "Q2" 3 "Q3" 4 "Q4 (Highest)"
label values iq_bins iq_bins

* Keep only needed variables
keep hwage educ iq_bins

* Display first 5 observations
list in 1/5, noobs clean	   
	   
* Run regression with education category dummies
regress hwage i.educ

* Display formatted coefficient table
eststo model6

* Alternative using esttab for publication-quality output
esttab model6, cells("b(star fmt(3))") ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    title("Hourly Wage by Education Level") ///
    varwidth(20)
	
	
predict y_hat2, xb

* Create scatterplot with regression line
twoway (scatter hwage educ, mcolor(blue%50) msymbol(Oh)) ///
       (line y_hat2 educ, sort lcolor(orange) lwidth(medthick)), ///
       title("Hourly Wage by Education") ///
       xtitle("Years of Education") ///
       ytitle("Hourly Wage") ///
       legend(off) ///
       graphregion(color(white)) ///
       plotregion(color(white)) ///
       xlabel(8(2)20)
	   
	   
* Calculate means for educ==9 and educ==17
sum hwage if educ == 9
scalar t0_mean = r(mean)
display "E[Y|T=9]: " %5.2f t0_mean

sum hwage if educ == 17
scalar t1_mean = r(mean)
scalar diff = t1_mean - t0_mean
display "E[Y|T=17]-E[Y|T=9]: " %5.2f diff

* Run regression with both sets of dummies
regress hwage i.educ i.iq_bins

* Store results and display formatted table
eststo model_dummy2
esttab model_dummy2, cells("b(star fmt(3))") ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    title("Wage Regression with Education and IQ Dummies") ///
    varwidth(25)	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   