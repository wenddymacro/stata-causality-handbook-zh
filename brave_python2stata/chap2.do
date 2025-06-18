********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Direct import from GitHub URL (Recommended for Stata 16+)
* import delimited "https://raw.githubusercontent.com/matheusfacure/python-causality-handbook/master/causal-inference-for-the-brave-and-true/data/online_classroom.csv", clear

* Clear any existing data from memory
clear

* Import the CSV file from local path
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/online_classroom.csv", encoding(UTF-8) 

* Alternative import command (for Stata versions before 14)
* insheet using "/Users/xuwenli/.../online_classroom.csv", clear

* Check if data loaded correctly
describe  // Display variable names and types
list in 1/5  // Show first 5 observations

* Step 1: Create class_format variable
gen class_format = "face_to_face"  // Set default value
replace class_format = "online" if format_ol == 1
replace class_format = "blended" if format_blended == 1

* Step 2: Calculate means by group
collapse (mean) asian black falsexam format_blended format_ol gender, by(class_format)

* Step 3: Display results
list, noobs clean





