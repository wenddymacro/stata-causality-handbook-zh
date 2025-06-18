********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Clear any existing data from memory
clear

* Import the CSV file from local path
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/enem_scores.csv", encoding(UTF-8) 

* Sort the dataset by avg_score in descending order
gsort -avg_score

* Display the top 10 observations
list in 1/10, clean noobs


* Calculate percentiles for thresholds
sum avg_score, detail
local top_score_p99 = r(p99)  // 99th percentile of avg_score

sum number_of_students, detail
local students_p98 = r(p98)   // 98th percentile of number_of_students

* Create top_school indicator (1 = top 1% school, 0 = others)
gen top_school = (avg_score >= `top_score_p99') if !missing(avg_score)
label define top_school_label 0 "Other Schools" 1 "Top 1% Schools"
label values top_school top_school_label

* Filter data (remove outliers in number_of_students)
preserve
    keep if number_of_students < `students_p98' & !missing(number_of_students)
    
    * Create boxplot
    graph box number_of_students, over(top_school) ///
        title("Number of Students of 1% Top Schools (Right)") ///
        ytitle("Number of Students") ///
        box(1, color(blue)) ///
        box(2, color(orange)) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        xsize(6) ysize(6)
restore



* Calculate percentiles
sum avg_score, detail
local q_99 = r(p99)  // 99th percentile
local q_01 = r(p1)    // 1st percentile

* Take random sample and create groups
preserve
    if _N > 10000 {
        sample 10000, count
    }
    
    gen Group = "Middle"
    replace Group = "Top" if avg_score > `q_99' & !missing(avg_score)
    replace Group = "Bottom" if avg_score < `q_01' & !missing(avg_score)
    
    * Create scatterplot with legend inside
    twoway (scatter avg_score number_of_students if Group == "Top", mcolor(red) msymbol(Oh)) ///
           (scatter avg_score number_of_students if Group == "Middle", mcolor(blue) msymbol(Oh)) ///
           (scatter avg_score number_of_students if Group == "Bottom", mcolor(green) msymbol(Oh)), ///
           title("ENEM Score by Number of Students in the School") ///
           ytitle("Average ENEM Score") ///
           xtitle("Number of Students in School") ///
           legend(order(1 "Top 1%" 2 "Middle 98%" 3 "Bottom 1%") ///
                  position(13) ring(0) cols(1) region(lcolor(none))) ///
           graphregion(color(white)) ///
           plotregion(color(white)) ///
           xsize(10) ysize(5)
restore


* Clear any existing data from memory
clear

* Import the CSV file from local path
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/online_classroom.csv", encoding(UTF-8) 

* Calculate standard error for online group (format_ol==1)
sum falsexam if format_ol == 1
local se_online = r(sd)/sqrt(r(N))
display "SE for Online: " `se_online'

* Calculate standard error for face-to-face group (format_ol==0 & format_blended==0)
sum falsexam if format_ol == 0 & format_blended == 0
local se_ftf = r(sd)/sqrt(r(N))
display "SE for Face to Face: " `se_ftf'

* Alternative approach using Stata's built-in standard error calculation:
* For online group
ci mean falsexam if format_ol == 1
local se_online = r(se)
display "SE for Online: " `se_online'

* For face-to-face group
ci mean falsexam if format_ol == 0 & format_blended == 0
local se_ftf = r(se)
display "SE for Face to Face: " `se_ftf'



clear all
set seed 42

* Parameters
local true_mean = 74
local true_std = 2
local n = 500

* Define the experiment program correctly
capture program drop run_experiment
program define run_experiment, rclass
    quietly {
        clear
        set obs `n'
        gen x = rnormal(`true_mean', `true_std')
        summarize x
        return scalar mean = r(mean)
    }
end

* Run the simulation
simulate mean=r(mean), reps(10000) nodots: run_experiment

* Create the histogram
hist mean, bin(40) ///
    title("Distribution of Sample Means") ///
    xtitle("Sample Mean") ///
    ytitle("Frequency") ///
    xline(`true_mean', lpattern(dash) lcolor(orange)) ///
    legend(label(1 "Experiment Means") label(2 "True Mean")) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(8) ysize(5)
	
	
clear	
* Set random seed for reproducibility
set seed 321

* Parameters (same as before)
local true_mean = 74
local true_std = 2
local n = 500

* Run one experiment
clear
set obs `n'
gen x = rnormal(`true_mean', `true_std')

* Calculate statistics
sum x
local exp_mu = r(mean)
local exp_se = r(sd)/sqrt(r(N))
local ci_lower = exp_mu - 2 * exp_se
local ci_upper = exp_mu + 2 * exp_se

* Display results
display "95% Confidence Interval: (" %4.2f ci_lower ", " %4.2f ci_upper ")"	
	
* Generate x values (4 SEs around mean)
drop x
range x `=exp_mu - 4*exp_se' `=exp_mu + 4*exp_se' 100

* Calculate normal PDF values
gen y = normalden(x, `=exp_mu', `=exp_se')

* Create the plot
twoway (line y x, lcolor(blue)) ///
       (function y = 0, range(`=ci_lower' `=ci_upper') lcolor(none) ///
           recast(area) color(gs12) legend(label(2 "95% CI"))) ///
       , ///
       title("Sampling Distribution") ///
       ytitle("Density") ///
       xtitle("Sample Mean") ///
       legend(order(1 "Normal PDF" 2 "95% CI")) ///
       graphregion(color(white)) ///
       plotregion(color(white))	

	
	
	
	
	
	
	
	
	
	



