clear
cd "[DTA data folder]"
use "vignette-data-analyze.dta", clear

qui: tab wave, gen(wave)

global yvar pjltnt poleff pollaw plltnt encsat scltnt gensat polcom cpltnt gencom
global yvarall pjltnt pjfair pjresp pjfact pjvoic pjtrst poleff pollaw plltnt pltrst plconf plresp plrght encsat scltnt sctold scaccp sccomp gensat polcom cpltnt cprprt cpdang cpsusp cpinfo cpasst gencom 
global yall pjfair pjresp pjfact pjvoic pjtrst pltrst plconf plresp plrght sctold scaccp sccomp cprprt cpdang cpsusp cpinfo cpasst
global xvar age male white empl polvol polinv polstop poltick polbwc

egen xmiss=rowmiss($xvar)
sort clustid xmiss
egen tag=tag(clustid)
by clustid, sort: egen nclust=count(clustid)

*************************************
** TABLE 1: DESCRIPTIVE STATISTICS **
*************************************

*summarize, loneway - descriptives and ICCs

tab tx

foreach var of varlist $yvar $xvar wave? {
	qui: sum `var'
	di "`var': " _col(15) r(N) %9.2f r(mean) %9.2f r(sd) %9.0f r(min) %9.0f r(max)
}

sum nclust if tag==1

foreach var of varlist $yvar $xvar {
	qui: loneway `var' clustid
	di "`var': " _col(15) %9.2f r(rho)
}

******************************
** TABLE 2: FACTORIAL ANOVA **
******************************

*regress :: margins - means and effect sizes

foreach out of varlist $yvar $xvar wave? {
	qui: reg `out' i.txtyp##i.txbwc, vce(cluster clustid)
	qui: margins txtyp##txbwc, contrast(overall)
	local f1=r(F)[1,1]
	local f2=r(F)[1,2]
	local f3=r(F)[1,3]
	local p1=r(p)[1,1]
	local p2=r(p)[1,2]
	local p3=r(p)[1,3]
	local p=r(p)[1,4]
	qui: reg `out' i.txtyp##i.txbwc
	qui: estat esize
	local e1=sqrt(r(esize)[2,1])
	local e2=sqrt(r(esize)[3,1])
	local e3=sqrt(r(esize)[4,1])
	di "`out': " _col(10) %9.4f `p' %15.2f `f1' %7.2f `e1' %9.4f `p1' %15.2f `f2' %7.2f `e2' %9.4f `p2' %15.2f `f3' %7.2f `e3' %9.4f `p3'
}

*reshape :: regress :: margins - stacked outcomes

frame copy default stacked
frame change stacked
keep id clustid txtyp txbwc $yvar
local i=1
foreach y of varlist $yvar {
	egen y`i'=std(`y')
	local i=`i'+1
}
reshape long y, i(id) j(n)
qui: reg y i.n##i.txtyp##i.txbwc, vce(cluster clustid)
qui: margins n##txtyp##txbwc, contrast
local f1o=r(F)[1,2]
local f2o=r(F)[1,4]
local f3o=r(F)[1,6]
local p1o=r(p)[1,2]
local p2o=r(p)[1,4]
local p3o=r(p)[1,6]
local f1v=r(F)[1,3]
local f2v=r(F)[1,5]
local f3v=r(F)[1,7]
local p1v=r(p)[1,3]
local p2v=r(p)[1,5]
local p3v=r(p)[1,7]
qui: reg y i.n##i.txtyp##i.txbwc
qui: estat esize
local e1o=sqrt(r(esize)[3,1])
local e2o=sqrt(r(esize)[5,1])
local e3o=sqrt(r(esize)[7,1])
local e1v=sqrt(r(esize)[4,1])
local e2v=sqrt(r(esize)[6,1])
local e3v=sqrt(r(esize)[8,1])
di "`out' (overall): " _col(15) %9.2f `f1o' %7.2f `e1o' %9.4f `p1o' %15.2f `f2o' %7.2f `e2o' %9.4f `p2o' %15.2f `f3o' %7.2f `e3o' %9.4f `p3o'
di "`out' (variance): " _col(15) %9.2f `f1v' %7.2f `e1v' %9.4f `p1v' %15.2f `f2v' %7.2f `e2v' %9.4f `p2v' %15.2f `f3v' %7.2f `e3v' %9.4f `p3v'
frame change default
frame drop stacked

**************************************
** TABLE 3: LINEAR REGRESSION MODEL **
**************************************

*regress :: margins - fully crossed

foreach out of varlist $yvar {
	qui: regress `out' i.txtyp##i.txbwc, vce(cluster clustid)
	qui: margins, dydx(txtyp txbwc) post
	di "`out': " _col(10) %9.2f r(table)[1,2] %7.2f r(table)[2,2] %9.4f r(table)[4,2] ///
				 _col(40) %9.2f r(table)[1,3] %7.2f r(table)[2,3] %9.4f r(table)[4,3] ///
				 _col(70) %9.2f r(table)[1,5] %7.2f r(table)[2,5] %9.4f r(table)[4,5]
}

/*******************************/
/* TABLE 4: TESTS OF ASYMMETRY */
/*******************************/

*regress :: margins - sum of coeffs: me(2.txtyp) + me(3.txtyp) = 0

foreach out of varlist $yvar {
	qui: regress `out' i.txtyp##i.txbwc, vce(cluster clustid)
	qui: margins, dydx(txtyp) post
	qui: nlcom (sum: _b[2.txtyp]+_b[3.txtyp]), post
	di "`out': " _col(10) %9.2f r(table)[1,1] %7.2f r(table)[2,1] %9.4f r(table)[4,1]
}

*regress :: margins :: bootstrap - ratio of coeffs: abs(me(2.txtyp) / me(3.txtyp)) = 1

program bootratio
    syntax, command(string)
	`command'
    qui: margins, dydx(txtyp) post
	nlcom (ratio: abs(_b[2.txtyp]/_b[3.txtyp])), post
end

foreach out of varlist $yvar {
	qui: bootstrap _b[ratio], cluster(clustid) reps(500) seed(20230707): bootratio, command(qui: regress `out' i.txtyp##i.txbwc, vce(cluster clustid))
	di "`out': " _col(10) %9.2f e(b)[1,1] %9.2f e(ci_bc)[1,1] %9.2f e(ci_bc)[2,1]
}

***************************************
** FIGURE 2: POST-FLOYD INTERACTIONS **
***************************************

*regress :: margins :: coefplot - marginal effects, additive

global opts1 xline(0, lp(dot)) xtitle(Marginal Effect) legend(off) coeflabels(*1._at = "Pre-Floyd" *2._at = "Post-Floyd") eqlabels("{bf:Procedurally Unjust}" "{bf:Procedurally Just}" "{bf:Body Worn Camera}", asheadings) msize(thick) ciopts(lwidth(thick)) fxsize(100)

global opts2 xline(0, lp(dot)) xtitle(Marginal Effect) legend(off) coeflabels(*1._at = " " *2._at = " ") eqlabels(" " " " " ", asheadings) msize(thick) ciopts(lwidth(thick)) fxsize(60)

reg STDpjltnt i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts1 title("Procedural" "Justice") saving(FigOut1, replace)

reg STDpoleff i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts2 title("Police" "Effectiveness") saving(FigOut2, replace)

reg STDpollaw i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts2 title("Police" "Lawfulness") saving(FigOut3, replace)

reg STDplltnt i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts2 title("Police" "Legitimacy") saving(FigOut4, replace)

reg STDencsat i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts2 title("Encounter" "Satisfaction") saving(FigOut5, replace)

reg STDscltnt i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts1 title("Compliance" "with Police") saving(FigOut6, replace)

reg STDgensat i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts2 title("General" "Satisfaction") saving(FigOut7, replace)

reg STDpolcom i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts2 title("Police-Community" "Relations") saving(FigOut8, replace)

reg STDcpltnt i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts2 title("Cooperation" "with Police") saving(FigOut9, replace)

reg STDgencom i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
coefplot (, keep(*:1._at)) (, keep(*:2._at)), $opts2 title("Compliance" "with the Law") saving(FigOut10, replace)

graph combine FigOut1.gph FigOut2.gph FigOut3.gph FigOut4.gph FigOut5.gph FigOut6.gph FigOut7.gph FigOut8.gph FigOut9.gph FigOut10.gph, row(2) ysize(7.5) xsize(6.5) imargin(0 0 1 1) iscale(*0.7) xcommon

***********************
** APPENDIX MATERIAL **
***********************

* appendix c: principal component analysis *

local list1 "pjfair pjresp pjfact pjvoic pjtrst"
local list2 "pltrst plconf plresp plrght"
local list3 "sctold scaccp sccomp"
local list4 "cprprt cpdang cpsusp cpinfo cpasst"
forvalues i=1/4 {
	qui: alpha `list`i''
	local a=r(alpha)
	qui: factor `list`i'', pcf fac(1)
	di "LIST`i' : " _col(35) %7.2f `a' %9.2f e(Ev)[1,1]
	local n : word count `list`i''
	forvalues j=1/`n' {
		local y : word `j' of `list`i''
		qui: sum `y'
		di "`y' : " %8.0f r(N) %8.2f r(mean) %8.2f r(sd) %8.2f e(L)[`j',1] %9.2f e(Psi)[1,`j']
	}
	di ""
}

* appendix d: descriptives by treatment group *

tab1 txtyp txbwc tx

forvalues j=1/3 {
	foreach var of varlist $yvar {
		qui: sum `var' if txtyp==`j'
		di "`var': " _col(15) %9.2f r(mean) %9.2f r(sd)
	}
	di ""
}

forvalues j=0/1 {
	foreach var of varlist $yvar {
		qui: sum `var' if txbwc==`j'
		di "`var': " _col(15) %9.2f r(mean) %9.2f r(sd)
	}
	di ""
}

forvalues j=1/6 {
	foreach var of varlist $yvar {
		qui: sum `var' if tx==`j'
		di "`var': " _col(15) %9.2f r(mean) %9.2f r(sd)
	}
	di ""
}

* appendix e: factorial anova of control variables

foreach out of varlist $xvar wave? {
	qui: reg `out' i.txtyp##i.txbwc, vce(cluster clustid)
	qui: margins txtyp##txbwc, contrast(overall)
	local f1=r(F)[1,1]
	local f2=r(F)[1,2]
	local f3=r(F)[1,3]
	local p1=r(p)[1,1]
	local p2=r(p)[1,2]
	local p3=r(p)[1,3]
	local p=r(p)[1,4]
	qui: reg `out' i.txtyp##i.txbwc
	qui: estat esize
	local e1=sqrt(r(esize)[2,1])
	local e2=sqrt(r(esize)[3,1])
	local e3=sqrt(r(esize)[4,1])
	di "`out': " _col(10) %9.4f `p' %15.2f `f1' %7.2f `e1' %9.4f `p1' %15.2f `f2' %7.2f `e2' %9.4f `p2' %15.2f `f3' %7.2f `e3' %9.4f `p3'
}

frame copy default stacked
frame change stacked
keep id clustid txtyp txbwc $xvar wave?
local i=1
foreach y of varlist $xvar {
	egen x`i'=std(`y')
	local i=`i'+1
}
reshape long x, i(id) j(n)
qui: reg x i.n##i.txtyp##i.txbwc, vce(cluster clustid)
qui: margins n##txtyp##txbwc, contrast
local f1o=r(F)[1,2]
local f2o=r(F)[1,4]
local f3o=r(F)[1,6]
local p1o=r(p)[1,2]
local p2o=r(p)[1,4]
local p3o=r(p)[1,6]
local f1v=r(F)[1,3]
local f2v=r(F)[1,5]
local f3v=r(F)[1,7]
local p1v=r(p)[1,3]
local p2v=r(p)[1,5]
local p3v=r(p)[1,7]
qui: reg x i.n##i.txtyp##i.txbwc
qui: estat esize
local e1o=sqrt(r(esize)[3,1])
local e2o=sqrt(r(esize)[5,1])
local e3o=sqrt(r(esize)[7,1])
local e1v=sqrt(r(esize)[4,1])
local e2v=sqrt(r(esize)[6,1])
local e3v=sqrt(r(esize)[8,1])
di "`out' (overall): " _col(15) %9.2f `f1o' %7.2f `e1o' %9.4f `p1o' %15.2f `f2o' %7.2f `e2o' %9.4f `p2o' %15.2f `f3o' %7.2f `e3o' %9.4f `p3o'
di "`out' (variance): " _col(15) %9.2f `f1v' %7.2f `e1v' %9.4f `p1v' %15.2f `f2v' %7.2f `e2v' %9.4f `p2v' %15.2f `f3v' %7.2f `e3v' %9.4f `p3v'
frame change default
frame drop stacked

* appendix f: linear regression with covariates *

foreach out of varlist $yvar {
	qui: regress `out' i.txtyp##i.txbwc $xvar wave2 wave3, vce(cluster clustid)
	qui: margins, dydx(txtyp txbwc) post
	di "`out': " _col(10) %9.2f r(table)[1,2] %7.2f r(table)[2,2]  %9.4f r(table)[4,2] ///
				 _col(30) %9.2f r(table)[1,3] %7.2f r(table)[2,3]  %9.4f r(table)[4,3] ///
				 _col(50) %9.2f r(table)[1,5] %7.2f r(table)[2,5]  %9.4f r(table)[4,5] 
}

foreach out of varlist $yvar {
	qui: teffects ra (`out' i.txbwc $xvar wave2 wave3) (txtyp), ate vce(cluster clustid)
	di "`out': " _col(10) %9.2f r(table)[1,1] %7.2f r(table)[2,1] %9.4f r(table)[4,1] ///
				 _col(40) %9.2f r(table)[1,2] %7.2f r(table)[2,2] %9.4f r(table)[4,2]
}

foreach out of varlist $yvar {
	qui: teffects ra (`out' i.txtyp $xvar wave2 wave3) (txbwc), ate vce(cluster clustid)
	di "`out': " _col(10) %9.2f r(table)[1,1] %7.2f r(table)[2,1] %9.4f r(table)[4,1]
}

* appendix g: post-floyd interactions *

foreach out of varlist $yvar {
	qui: reg `out' i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
	qui: margins postfloyd##txtyp##txbwc, contrast(overall)
	di "`out': " _col(10) %9.2f r(F)[1,3] %9.4f r(p)[1,3] %9.2f r(F)[1,5] %9.4f r(p)[1,5] %9.2f r(F)[1,7] %9.4f r(p)[1,7]
}

frame copy default stacked
frame change stacked
local i=1
foreach y of varlist STD* {
	gen y`i'=`y'
	local i=`i'+1
}
reshape long y, i(id) j(n)
qui: reg y i.n##i.postfloyd##i.txtyp##i.txbwc, vce(cluster clustid)
qui: margins n##postfloyd##txtyp##txbwc, contrast
di %9.2f r(F)[1,6] %9.4f r(p)[1,6] %9.2f r(F)[1,10] %9.4f r(p)[1,10] %9.2f r(F)[1,14] %9.4f r(p)[1,14]
di %9.2f r(F)[1,7] %9.4f r(p)[1,7] %9.2f r(F)[1,11] %9.4f r(p)[1,11] %9.2f r(F)[1,15] %9.4f r(p)[1,15]
qui: reg y i.n##i.postfloyd##i.txtyp##i.txbwc
qui: estat esize
di %9.2f sqrt(r(esize)[7,1]) %9.2f sqrt(r(esize)[11,1]) %9.2f sqrt(r(esize)[15,1])
di %9.2f sqrt(r(esize)[8,1]) %9.2f sqrt(r(esize)[12,1]) %9.2f sqrt(r(esize)[16,1])
frame change default
frame drop stacked

* appendix h: pre- and post-floyd marginal effects *

foreach out of varlist $yvar {
	qui: reg `out' i.txtyp##i.txbwc##i.postfloyd, vce(cluster clustid)
	qui: margins, dydx(txtyp txbwc) at(postfloyd=(0 1)) post
	di "`out': " _col(10) %9.2f r(table)[1,3] %8.4f r(table)[4,3] %9.2f r(table)[1,4] %8.4f r(table)[4,4] %9.2f r(table)[1,5] %8.4f r(table)[4,5] %9.2f r(table)[1,6] %8.4f r(table)[4,6] %9.2f r(table)[1,9] %8.4f r(table)[4,9] %9.2f r(table)[1,10] %8.4f r(table)[4,10] 
}
