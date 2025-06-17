********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************
* 当"相关性"就是"因果性"
*******************************

clear
set obs 100
set seed 123

* 1. Generate tuition data (normal distribution)
gen tuition = round(rnormal(1000, 300))

* 2. Standardize tuition and calculate Logistic probability
sum tuition
gen z = (tuition - r(mean)) / r(sd)
gen p = invlogit(z)  // p = expit(z)

* 3. Generate tablet variable (binomial distribution)
gen tablet = runiform() < p  // Method 1
* Alternative: gen tablet = rbinomial(1, p)  // Method 2 (Stata 14+)

* 1. Define value labels
label define tablet_label 0 "False" 1 "True"

* 2. Apply labels to variable
label values tablet tablet_label

* 3. Check results (verify labels are applied)
tab tablet

* 4. Generate ENEM scores (with tablet and tuition effects)
gen enem_score = rnormal(200 - 50 * tablet + 0.7 * tuition, 200)

* 5. Standardize scores to 0-1000 range
sum enem_score
replace enem_score = (enem_score - r(min)) / (r(max) - r(min)) * 1000
* Drop observations where enem_score equals 0
drop if enem_score == 0

* Check results
tab tablet
sum enem_score tuition, detail

graph box enem_score, over(tablet) ///
    title("ENEM score by Tablet in Class") ///
    ytitle("ENEM Score") ///
    box(1, color(blue)) ///
    box(2, color(orange)) ///
    graphregion(color(white)) ///
    plotregion(color(white))


* Create scatterplot with different colors for Tablet groups
twoway (scatter enem_score tuition if tablet == 1, mcolor(blue) msymbol(Oh) msize(medlarge)) ///
       (scatter enem_score tuition if tablet == 0, mcolor(red) msymbol(X) msize(medlarge)), ///
       title("ENEM score by Tuition Cost") ///
       ytitle("ENEM Score") ///
       xtitle("Tuition Cost") ///
       legend(order(1 "Tablet: True" 2 "Tablet: False") ///
              position(11) ring(0) cols(1)) ///  
       graphregion(color(white)) ///
       plotregion(color(white)) ///
       xsize(10) ysize(6)

	
	
	
clear

* Create the dataset
input i Y0 Y1 T Y TE
1 500 450 0 500 -50
2 600 600 0 600 0
3 800 600 1 600 -200
4 700 750 1 750 50
end

* Label the variables
label variable i "Observation ID"
label variable Y0 "Outcome without treatment"
label variable Y1 "Outcome with treatment"
label variable T "Treatment status"
label variable Y "Observed outcome"
label variable TE "Treatment effect"

* Display the data
list

clear

* Create the dataset with missing values (.)
input i Y0 Y1 T Y TE
1 500 .  0 500 .
2 600 .  0 600 .
3 .  600 1 600 .
4 .  750 1 750 .
end

* Label the variables
label variable i "Observation ID"
label variable Y0 "Outcome without treatment (missing if treated)"
label variable Y1 "Outcome with treatment (missing if control)" 
label variable T "Treatment status"
label variable Y "Observed outcome"
label variable TE "Treatment effect (missing for all)"

* Format missing value display
format Y0 Y1 TE %8.0g  // Shows . for missing values

* Display the data
list


