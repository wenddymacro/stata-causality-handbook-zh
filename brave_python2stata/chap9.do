********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/app_engagement_push.csv", clear


list in 1/5

* Run OLS regression
regress in_app_purchase push_assigned push_delivered

* First-stage regression
regress push_delivered push_assigned

* Reduced form regression
regress in_app_purchase push_assigned


* Run 2SLS regression (recommended approach)
ivregress 2sls in_app_purchase (push_delivered = push_assigned)

