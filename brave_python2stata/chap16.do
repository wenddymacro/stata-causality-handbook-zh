********************************************************************
*原书名：Causal Inference for The Brave and True
*原作者：Matheus Facure
*中文译者：黄文喆（Wenzhe Huang）、许文立（Wenli Xu)｜澳门城市大学金融学院
*联系方式：carlzhe@outlook.com｜wlxu@cityu.edu.mo
* 注：原书为Python代码，鉴于中国经济学者使用stata的习惯，
*     我们特意将原Python代码转换成ststa
********************************************************************

* Load data (assuming CSV is in current directory)
import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/drinking.csv", clear

list in 1/5

//作散点图，观测跳跃
* 所有的死亡率
twoway scatter all agecell, xline(21,lp(dash)) saving(all)

* 交通死亡率
twoway scatter mva agecell, xline(21,lp(dash)) saving(mva)

* 自杀死亡率
twoway scatter suicide agecell,xline(21,lp(dash)) saving(suicide)

graph combine all.gph mva.gph suicide.gph,col(1)




// 回归法

gen d= agecell>=21

gen running=agecell-21

reg all running d i.d#c.running,r

twoway (scatter all agecell) (lfit all agecell if agecell<=21)(lfit all agecell if agecell>=21), xline(21,lp(dash)) saving(all1,replace)

twoway (scatter mva agecell) (lfit mva agecell if agecell<=21)(lfit mva agecell if agecell>=21), xline(21,lp(dash)) saving(mva1)

twoway (scatter suicide agecell) (lfit suicide agecell if agecell<=21)(lfit suicide agecell if agecell>=21), xline(21,lp(dash)) saving(suicide1)

graph combine all1.gph mva1.gph suicide1.gph,col(1)


// 散点拟合方法来观察跳跃

twoway (scatter all agecell, msymbol(+) msize(*0.4) mcolor(black*0.3)),   title("散点图") xline(21,lp(dash)) saving(scatter, replace)

twoway (scatter all agecell) (lfit all agecell if agecell<=21)(lfit all agecell if agecell>=21), xline(21,lp(dash)) saving(scatter1, replace)

rdplot all agecell, c(21) p(1) graph_options(title(线性拟合))
graph save rd1,replace // 线性拟合图

rdplot all agecell, c(21) p(2) graph_options(title(二次型拟合)) 
graph save rd2,replace //二次型拟合图

rdplot all agecell, c(21) p(3) graph_options(title(三次型拟合)) 
graph save rd3,replace //三次型拟合图


graph combine scatter.gph scatter1.gph rd1.gph rd2.gph rd3.gph


// 断点回归
rdplot all agecell,c(21)
* 局部线性回归
* ssc install rdrobust,replace
rdrobust all agecell,c(21) all

rdbwselect all agecell,c(21) all

rdplot all agecell,c(21) ci(95)

* 局部多项式回归

rdrobust all agecell,c(21) all p(1)

rdrobust all agecell,c(21) all p(2)

rdrobust all agecell,c(21) all p(3)

*全局多项式回归

sum agecell
local hvalueR=r(max)  
local hvalueL= abs(r(min))
 
rdrobust all agecell, c(21)  h(`hvalueL'  `hvalueR') all //自动选择阶数
rdrobust all agecell, c(21)  h(`hvalueL'  `hvalueR') all p(2) //二阶拟合
rdrobust all agecell, c(21)  h(`hvalueL'  `hvalueR') all p(3) //三阶拟合

* McCrary Test
rddensity agecell,c(21) plot bwselect(each)


// 模糊断点

import delimited "/Users/xuwenli/Library/CloudStorage/OneDrive-个人/DSGE建模及软件编程/教学大纲与讲稿/应用计量经济学讲稿/python-causality-handbook/causal-inference-for-the-brave-and-true/data/sheepskin.csv", clear

list in 1/5

twoway scatter receivehsd minscore, xline(0,lp(dash)) saving(all)

// 断点回归

rdrobust receivehsd minscore, all

rdbwselect receivehsd minscore, all

rdplot receivehsd minscore, ci(95)

rddensity minscore, all plot




