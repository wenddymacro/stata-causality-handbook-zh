********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/ak91.csv", clear


list in 1/5


* 1. Create grouped data
preserve
    collapse (mean) log_wage years_of_schooling, by(year_of_birth quarter_of_birth)
    gen time_of_birth = year_of_birth + (quarter_of_birth-1)/4
    
* 2. Create the plot
    #delimit ;
    twoway (line years_of_schooling time_of_birth, lcolor(gs8) lwidth(medthin))
           (scatter years_of_schooling time_of_birth if quarter_of_birth==1, 
               msymbol(S) msize(large) mcolor(blue))
           (scatter years_of_schooling time_of_birth if quarter_of_birth==2, 
               msymbol(S) msize(large) mcolor(orange))
           (scatter years_of_schooling time_of_birth if quarter_of_birth==3, 
               msymbol(S) msize(large) mcolor(green))
           (scatter years_of_schooling time_of_birth if quarter_of_birth==4, 
               msymbol(S) msize(large) mcolor(red))
           (scatter years_of_schooling time_of_birth, 
               mlabel(quarter_of_birth) mlabcolor(white) mlabsize(medium) 
               msymbol(none) msize(zero)),
           title("Years of Education by Quarter of Birth (first stage)")
           xtitle("Year of Birth")
           ytitle("Years of Schooling")
           legend(off)
           graphregion(color(white))
           plotregion(color(white))
           xsize(15) ysize(6)
           xlabel(, grid)
           ylabel(, grid);
    #delimit cr
restore

* Create dummy variables for each quarter
foreach q in 1 2 3 4 {
    gen q`q' = (quarter_of_birth == `q') if !missing(quarter_of_birth)
    label variable q`q' "Quarter `q' of birth"
}

* Display first 5 observations with new dummies
list year_of_birth quarter_of_birth q1 q2 q3 q4 in 1/5, noobs clean

* Run first-stage regression
regress years_of_schooling i.year_of_birth i.state_of_birth q4

* 1. Prepare grouped data if not already done
preserve
    collapse (mean) log_wage, by(year_of_birth quarter_of_birth)
    gen time_of_birth = year_of_birth + (quarter_of_birth-1)/4
    
    * 2. Create the plot
    #delimit ;
    twoway (line log_wage time_of_birth, lcolor(gs8) lwidth(medthin))
           (scatter log_wage time_of_birth if quarter_of_birth==1, 
               msymbol(S) msize(large) mcolor(blue))
           (scatter log_wage time_of_birth if quarter_of_birth==2, 
               msymbol(S) msize(large) mcolor(orange))
           (scatter log_wage time_of_birth if quarter_of_birth==3, 
               msymbol(S) msize(large) mcolor(green))
           (scatter log_wage time_of_birth if quarter_of_birth==4, 
               msymbol(S) msize(large) mcolor(red))
           (scatter log_wage time_of_birth, 
               mlabel(quarter_of_birth) mlabcolor(white) mlabsize(medium) 
               msymbol(none) msize(zero)),
           title("Average Weekly Wage by Quarter of Birth")
           subtitle("Reduced Form")
           xtitle("Year of Birth")
           ytitle("Log Weekly Earnings")
           legend(off)
           graphregion(color(white))
           plotregion(color(white))
           xsize(15) ysize(6)
           xlabel(, grid)
           ylabel(, grid angle(horizontal));
    #delimit cr
restore

* Run reduced form regression
regress log_wage i.year_of_birth i.state_of_birth q4


* Full 2SLS (preferred approach)
ivregress 2sls log_wage (years_of_schooling = q4) i.year_of_birth i.state_of_birth

* Run 2SLS with multiple instruments
ivregress 2sls log_wage i.year_of_birth i.state_of_birth (years_of_schooling = q1 q2 q3)

* Run OLS with categorical controls
regress log_wage years_of_schooling i.state_of_birth i.year_of_birth i.quarter_of_birth

* Show first-stage F-stat for comparison (if needed)
quietly regress years_of_schooling i.quarter_of_birth i.state_of_birth i.year_of_birth
display "First-stage F-stat: " %5.2f e(F)


clear
set obs 10000
set seed 12

* Generate base variables
gen X = rnormal(0, 2)
gen U = rnormal(0, 2)
gen T = rnormal(1 + 0.5*U, 5)
gen Y = rnormal(2 + X - 0.5*U + 2*T, 5)

* Create 50 instruments with decreasing strength
forvalues i = 1/50 {
    local s = 0.1 + (100-0.1)*(`i'-1)/49  // Linear spacing from 0.1 to 100
    gen Z_`i' = rnormal(T, `s')
    label variable Z_`i' "Instrument (SD=`=round(`s',0.1)')"
}

* Display first 5 observations
list U T Y Z_1 Z_2 in 1/5, noobs clean

* Verify instrument strength pattern
foreach z in 1 10 20 30 40 50 {
    corr T Z_`z'
    display "Z_`z' Cov(T,Z): " %5.3f r(cov_12)
}


* 1. Clear memory and set random seed
clear all
set seed 12
set obs 10000

* 2. Generate base variables (identical to Python code)
gen X = rnormal(0, 2)  // Observable covariate
gen U = rnormal(0, 2)  // Unobserved confounder
gen T = rnormal(1 + 0.5*U, 5)  // Endogenous treatment
gen Y = rnormal(2 + X - 0.5*U + 2*T, 5)  // Outcome

* 3. Create 50 instruments with decreasing strength
forvalues i = 1/50 {
    local s = 0.1 + (100-0.1)*(`i'-1)/49  // Linear spacing of SDs from 0.1 to 100
    gen Z_`i' = rnormal(T, `s')  // Instruments with increasing noise
    label var Z_`i' "Instrument `i' (SD=`=round(`s',0.1)')"
}

* 4. Initialize postfile for storing results
capture postclose results
postfile results z_num b_T se_T corr using iv_simulation, replace

* 5. Run IV regressions and store results
forvalues z = 1/50 {
    * Run 2SLS regression
    quietly ivregress 2sls Y X (T = Z_`z')
    
    * Calculate correlation between T and current Z
    quietly corr T Z_`z'
    local curr_corr = r(rho)
    
    * Post results to file
    post results (`z') (_b[T]) (_se[T]) (`curr_corr')
    
    * Display progress
    display "Processed instrument Z_`z' (Corr = " %4.2f `curr_corr' ")"
}

* 6. Close postfile and load results
postclose results
use iv_simulation, clear

* 7. Create diagnostic plot
twoway (scatter se_T corr, mcolor(blue%80) msymbol(Oh)), ///
       title("IV Standard Errors by Instrument Strength") ///
       subtitle("As Cov(Z,T) decreases, SE increases") ///
       xtitle("Correlation between Z and T") ///
       ytitle("Standard Error of Treatment Effect") ///
       graphregion(color(white)) ///
       plotregion(color(white)) ///
       xlabel(0(0.2)1, grid) ///
       ylabel(, grid angle(horizontal))

* 8. Save plot
graph export "iv_diagnostic_plot.png", replace width(2000)

* 9. Show strongest instruments
gsort -corr
list in 1/10, noobs clean


* Load the simulation results if not already in memory
use iv_simulation, clear

* Generate confidence interval bounds
gen ci_upper = b_T + 1.96*se_T
gen ci_lower = b_T - 1.96*se_T

* Create the enhanced scatterplot with CIs
twoway (rarea ci_upper ci_lower corr, fcolor(blue%30) lcolo(blue%30)) ///
       (scatter b_T corr, mcolor(blue) msymbol(Oh)) ///
	   (function y = 2, range(0 1) lcolor(red) lpattern(dash)), ///
       title("IV ATE Estimates by 1st Stage Strength") ///
       xtitle("Correlation between Z and T") ///
       ytitle("ATE Estimate") ///
       legend(off) ///
       graphregion(color(white)) ///
	   plotregion(color(white)) ///
       xlabel(, grid) ///
       ylabel(, grid angle(horizontal)) ///
       note("Shaded area represents 95% confidence interval", size(small))
































