********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/smoking.csv", clear

list in 1/5


* Create California/Other States indicator
gen state_group = "Other States"
replace state_group = "California" if california == "True"

encode state_group, gen(state_group1)  // Creates numeric version with value labels

* Calculate mean cigsale by year and state group
collapse (mean) cigsale, by(year state_group1)

* Reshape for plotting
reshape wide cigsale, i(year) j(state_group1)

twoway ///
    (connected cigsale1 year, lwidth(2) lcolor(blue) mcolor(blue)) /// 
    (connected cigsale2 year, lwidth(2) lcolor(red) mcolor(red)) ///
    (function y = 0, range(1988 1989) lcolor(black) lpattern(dash) lwidth(2)), ///
    title("Gap in per-capita cigarette sales (in packs)") ///
    ytitle("Cigarette Sales Trend") ///
    xline(1988.5,lp(dash) lwidth(2)) xtitle("Year") ///
    legend(order(1 "California" 2 "Other States" 3 "Proposition 99") position(6) rows(1)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    xsize(10) ysize(5) ///
    ylabel(40(20)140)


* ==============================================================================
* SYNTHETIC CONTROL METHOD VIA LINEAR REGRESSION
* Objective: Find optimal weights for control units to match treated unit (California)
*            in the pre-treatment period using cigsale and retprice
* ==============================================================================

* Setup panel data structure
xtset state year  // Declare panel structure with state and year

* ------------------------------------------------------------------------------
* STEP 1: DATA PREPARATION
* ------------------------------------------------------------------------------
* Keep only pre-treatment period (before Proposition 99)
keep if after_treatment == "False"

* ------------------------------------------------------------------------------
* STEP 2: EXTRACT TREATED UNIT DATA (CALIFORNIA)
* ------------------------------------------------------------------------------
preserve
keep if state == 3  // California is state=3 (adjust if different)
mkmat cigsale retprice, matrix(Y_cal)  // Store outcomes as matrix
restore

* ------------------------------------------------------------------------------
* STEP 3: PREPARE CONTROL UNITS DATA (OTHER STATES)
* ------------------------------------------------------------------------------
* Drop California to create donor pool
drop if state == 3  

keep cigsale retprice year state
* Reshape control data to wide format (one column per state)
reshape wide cigsale retprice, i(year) j(state)

* ------------------------------------------------------------------------------
* STEP 4: LINEAR REGRESSION TO ESTIMATE WEIGHTS
* ------------------------------------------------------------------------------
/* 
Regression specification:
Y_cal = β1*Control1_cigsale + β2*Control2_cigsale + ... 
       + γ1*Control1_retprice + γ2*Control2_retprice + ...
*/
matrix Y = Y_cal'  // Transpose for conformability
mkmat cigsale* retprice*, matrix(X_controls)  // Predictor matrix

* Unconstrained OLS (may produce negative weights)
matrix XX = X_controls' * X_controls
matrix XY = X_controls' * Y'
matrix beta = invsym(XX) * XY 
matrix beta = beta'          
matrix list beta  // Display estimated weights

restore

* ------------------------------------------------------------------------------
* STEP 5: CREATE SYNTHETIC CONTROL AND VISUALIZE
* ------------------------------------------------------------------------------
* ReLoad data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/smoking.csv", clear

preserve
keep if state == 3  // California is state=3 (adjust if different)
mkmat cigsale retprice, matrix(Y_cal)  // Store outcomes as matrix
restore

* Drop California to create donor pool
drop if state == 3  

keep cigsale retprice year state
* Reshape control data to wide format (one column per state)
reshape wide cigsale retprice, i(year) j(state)

mkmat cigsale* retprice*, matrix(X_controls)  // Predictor matrix

*Calculate synthetic control using unconstrained weights
matrix Y_synth = X_controls * beta'

svmat Y_cal, names(cal_)  // Creates cal_1 (cigsale) and cal_2 (retprice)
svmat Y_synth, names(synth_)

* Plot comparison
twoway ///
    (line cal_1 year, lcolor(blue) lwidth(2)) ///
    (line synth_1 year, lcolor(red) lpattern(dash) lwidth(2)), ///
    legend(order(1 "California" 2 "Synthetic Control")) ///
    title("Cigarette Sales: California vs. Synthetic Control") ///
    xtitle("Year") ytitle("Cigarette Sales")


* SC
* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/smoking.csv", clear

* Declare the dataset as a panel:
tsset state year

synth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) fig


* Use allsynth exactly as you would use synth to reconstruct the estimate from the synth help file:
allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989)  fig

* Use allsynth exactly as you would use synth to reconstruct the estimate from the synth help file:
allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989)  gapfig(classic)

* Calculate, display, and save the classic RMSPE-ranked p-values from in-space placebo runs, and plot the dynamic paths of classic gaps for the treated unit and for each of the donor pool units (placebo treated units), with the dotted vertical line indicating the period immediately preceding treatment:
allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) gapfig(classic placebos lineback) pvalues(rmspe) keep(smokingresults) rep
	
* bias-corrected

allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) bcor(merge) gapfig(bcorrect placebos lineback) pvalues(rmspe) keep(smokingresults) replace
	
	
	
	
	
	
	
	
	
	




















