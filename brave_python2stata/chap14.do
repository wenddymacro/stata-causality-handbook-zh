********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* 无法获得原书中的wage_panel数据
webuse nlswork, clear  // Similar panel wage data in Stata

list year msp in 1/5

reg ln_wage i.year

tabstat ln_wage, by(year) stat(mean)

* Method 2: Using statsby (more flexible)
statsby _b, by(nr) clear: summarize lwage educ exper
collapse (sum) sd_lwage=lwage sd_educ=educ sd_exper=exper
list






