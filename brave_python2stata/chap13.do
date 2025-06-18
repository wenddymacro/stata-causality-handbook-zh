********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/billboard_impact.csv", clear


list in 1/5

* 用处理组处理前作为反事实结果
* Calculate mean deposits for POA group before event (jul==0)
quietly summarize deposits if poa == 1 & jul == 0
local poa_before = r(mean)

* Calculate mean deposits for POA group after event (jul==1)
quietly summarize deposits if poa == 1 & jul == 1
local poa_after = r(mean)

* Calculate the difference
local diff = `poa_after' - `poa_before'

* Display results
display "POA Before: " `poa_before'
display "POA After: " `poa_after'
display "Difference (After - Before): " `diff'

* 用控制组处理后作为反事实结果
* Calculate mean deposits for FL group after event (jul==1)
quietly summarize deposits if poa == 0 & jul == 1
local fl_after = r(mean)

* Calculate mean deposits for POA group after event (jul==1)
quietly summarize deposits if poa == 1 & jul == 1
local poa_after = r(mean)

* Calculate the difference
local diff = `poa_after' - `fl_after'

* Display results
display "FL After: " `fl_after'
display "POA After: " `poa_after'
display "Difference (After - Before): " `diff'


* DID
* Calculate mean deposits for POA group before event (jul==0)
quietly summarize deposits if poa == 1 & jul == 0
local poa_before = r(mean)

* Calculate mean deposits for POA group after event (jul==1)
quietly summarize deposits if poa == 1 & jul == 1
local poa_after = r(mean)

* Calculate mean deposits for FL group before event (jul==0)
quietly summarize deposits if poa == 0 & jul == 0
local fl_before = r(mean)

* Calculate mean deposits for FL group after event (jul==1)
quietly summarize deposits if poa == 0 & jul == 1
local fl_after = r(mean)

* Calculate the difference in difference
local did = (`poa_after' - `poa_before') - (`fl_after' - `fl_before')


* Display results
display "FL trends: " `fl_after' - `fl_before'
display "POA trends: " `poa_after' - `poa_before'
display "Difference in difference: " `did'

clear
input period str3 month fl_values poa_values counterfactual
1 "May" 171.642308 46.016 46.016
2 "Jul" 206.1655 87.06375 80.539192
end

* Create the plot with proper legend labeling
twoway ///
    (connected fl_values period, lwidth(2) lcolor(blue) mcolor(blue)) ///
    (connected poa_values period, lwidth(2) lcolor(red) mcolor(red)) ///
    (line counterfactual period, lwidth(2) lcolor(green) lpattern(dash)), ///
    xlabel(1 "May" 2 "Jul") ///
    xtitle("Month") ytitle("Deposits") ///
    title("Deposit Trends Comparison") ///
    legend(order(1 "FL" 2 "POA" 3 "Counterfactual") position(6) rows(1)) ///
    graphregion(color(white)) plotregion(color(white))

* diff_plot: A Stata Module to Visualize Two-Period, Two-Group Difference-In-Differences
* ssc install elabel, replace //installing elabel 
* ssc install diff_plot //installing diff_plot

* TWFE 
reg deposits i.poa##i.jul



* Non PT
* Create temporary dataset for plotting
clear
input period str3 month fl_values poa_values counterfactual
1 "Jan" 120 60 .
2 "Mar" 150 50 .
3 "May" 171.642308 46.016 46.016
4 "Jul" 206.1655 87.06375 80.539192
end

* Create the plot
twoway ///
    (connected fl_values period, lwidth(2) lcolor(blue) mcolor(blue)) ///
    (connected poa_values period, lwidth(2) lcolor(red) mcolor(red)) ///
    (line counterfactual period if period >= 3, lwidth(2) lcolor(green) lpattern(dash)), ///
    xline(3, lpattern(dash) lcolor(gs10) lwidth(1)) ///
	xlabel(1 "Jan" 2 "Mar" 3 "May" 4 "Jul", angle(45)) ///
    xtitle("") ytitle("Deposits") ///
    title("Deposit Trends Comparison", size(medium)) ///
    legend(order(1 "FL" 2 "POA" 3 "Counterfactual") position(6) rows(1)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    scheme(s1color) ///
    xsize(10) ysize(5)  // Sets figure size to 10x5 inches


