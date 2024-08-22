* Calculate standard errors for fixed effects
* Adam Sacarny
* The latest version of this program can be found at http://www.sacarny.com/programs/

* fese_fast depvar indepvars [if], homosced() [heterosced()]

* depvar indepvars - the regressor and regressands (other than the fixed effects)
*                    this should match the arguments given to xtreg or areg

* all arguments below are optional:

* homosced() - variable to place the homoscedastic standard errors on the fixed effects
* heterosced() - (NOT RECOMMENDED) variable to place heteroscedasticity-robust standard
*                errors on the fixed effects
*                USING THIS OPTION WILL DRAMATICALLY SLOW DOWN THIS PROGRAM
* ehat() - the variable containing regression fitted errors. if you do not specify this
*          variable the program will calculate it itself by re-running xtreg and then
*          'predict [var], e'. that slows things down a lot. so if you have already
*          run xtreg (and why wouldn't you have?), then run 'predict [var], e' and
*          pass [var] to fese_fast to save time.

* NOTE: you should make sure that fese_fast is running on the same sample as your original
* xtreg or areg. For example, you may want to invoke fese_fast in the following way:
* xtreg depvar indepvars if [ zzz ], fe
* fese_fast depvar indepvars if e(sample), homosced(se_estimate)

* This program is based on fese by Austin Nichols
* See https://ideas.repec.org/c/boc/bocode/s456914.html

program fese_fast, sortpreserve
	syntax varlist(numeric) [ if ] , ///
		HOmosced(name) [HEterosced(name) Ehat(varname)]
	
	* deal with grouping variable
	local group :char _dta[iis]
	
	* deal with varlist (LHS and RHS vars)
	if "`:word 2 of `varlist''"=="" {
		display as error "need at least 1 LHS and 1 RHS var"
		error 198
	}
	
	* deal with collinearity... bluntly
	* FIXME: this doesn't seem to deal with collinearity the only appears after
	* sweeping out the fixed effects...
	_rmdcoll `varlist'
	if (r(k_omitted) > 0) {
		display as error "collinearity in RHS variables"
		error 198
	}
		
	gettoken y x: varlist
	
	* deal with if()
	marksample touse
	
	* placeholders for standard errors
	qui gen `homosced' = .
	if ("`heterosced'"!="") {
		qui gen `heterosced' = .
	}

	if ("`ehat'"=="") {
		tempvar ehat
		qui xtreg `y' `x' if `touse', fe
		predict `ehat' , e
	}
	
	sort `group'

	if ("`heterosced'"=="") {
		mata: fese_o("`y'","`x'","`ehat'","`group'","`touse'","`homosced'")
	}
	else {
		mata: fese_oh("`y'","`x'","`ehat'","`group'","`touse'","`homosced' `heterosced'")
	}
	
end

version 9.2
mata:
void fese_o(string scalar depvar, string scalar x, string scalar r, string scalar G, string scalar tousename, string scalar s) {

	st_view(y, ., tokens(depvar), tousename)
	st_view(X, ., tokens(x), tousename)
	st_view(e, ., tokens(r), tousename)
	st_view(gp, ., tokens(G), tousename)
	st_view(sv, ., tokens(s), tousename)
	
	info = panelsetup(gp, 1)

	Ng=rows(info)
	N=rows(X)
	k=cols(X)+Ng

	sse=sum(e:^2)

	printf("sigma^2: ")
	printf(strofreal(sse/(N-k)))
	printf("\n")

	Xt=J(N,cols(X),0)
	
	for (i=1; i<=rows(info); i++) {
		Xi = panelsubmatrix(X, i, info)
		Xt[|info[i,1],1 \ info[i,2],cols(X) |] = Xi:-mean(Xi)
	}

	XtXt=cross(Xt,Xt)
	_invsym(XtXt)

	for (i=1; i<=rows(info); i++) {
	
		Ti =(info[i,2]-info[i,1]+1)

		Xdi = colsum(panelsubmatrix(X, i, info))'
		Xtdi = colsum(panelsubmatrix(Xt, i, info))'

		XtXtXdi = cross(XtXt,Xdi)

		dKDi = cross(Xtdi,XtXtXdi)
		dKKDi = cross(Xdi,XtXtXdi)
		
		oi=Ti-2*dKDi+dKKDi

		ooi=sqrt(sse/(N-k)*oi)/Ti
		
		sv[| info[i,1],1 \ info[i,2],1 |] = J(Ti,1,ooi)
		
	}

	st_matrix("ov",ov)
}

void fese_oh(string scalar depvar, string scalar x, string scalar r, string scalar G, string scalar tousename, string scalar s) {
	st_view(y, ., tokens(depvar), tousename)
	st_view(X, ., tokens(x), tousename)
	st_view(e, ., tokens(r), tousename)
	st_view(gp, ., tokens(G), tousename)
	st_view(sv, ., tokens(s), tousename)
	
	info = panelsetup(gp, 1)
	
	Ng=rows(info)
	N=rows(X)
	k=cols(X)+Ng
	
	sse=sum(e:^2)

	printf("sigma^2: ")
	printf(strofreal(sse/(N-k)))
	printf("\n")
	
	Xt=J(N,cols(X),0)
	
	for (i=1; i<=rows(info); i++) {
		Xi = panelsubmatrix(X, i, info)
		Xt[|info[i,1],1 \ info[i,2],cols(X) |] = Xi:-mean(Xi)
	}
	
	XtXt=cross(Xt,Xt)
	_invsym(XtXt)

	OV=J(N,1,0)
	RV=J(N,1,0)
	
	ov=J(Ng,1,0)
	rv=J(Ng,1,0)

	for (i=1; i<=rows(info); i++) {
	
		ei = panelsubmatrix(e, i, info)
		eiei=ei*ei'
		ei2=diag(ei:^2)

		Ti =(info[i,2]-info[i,1]+1)
		
		di=J(info[i,1]-1,1,0)\J(Ti,1,1)\J(N-info[i,2],1,0)
		KDi=cross(Xt',cross(XtXt,cross(X,di)))
		KDii=KDi[info[i,1]..info[i,2],1]
		
		ri=sum(ei2)-2*cross(rowsum(ei2),KDii)
		oi=Ti-2*cross(rowsum(I(Ti)),KDii)
		
		for (j=1; j<=rows(info); j++) {
			
			ej = panelsubmatrix(e, j, info)
			ej2=diag(ej:^2)
			
			KDji=KDi[info[j,1]..info[j,2],1]
			
			ri=ri+cross(KDji,cross(ej2,KDji))
			oi=oi+cross(KDji,cross(I(rows(ej)),KDji))

		}
		
		ooi=sqrt(sse/(N-k)*oi)/Ti
		rri=sqrt(N/(N-k)*ri)/Ti
		
		ov[i,1]=ooi
		rv[i,1]=rri
		
		OV[| info[i,1],1 \ info[i,2],1 |] = J(Ti,1,ooi)
		RV[| info[i,1],1 \ info[i,2],1 |] = J(Ti,1,rri)

	}
	
	st_matrix("ov",ov)
	st_matrix("rv",rv)
	sv[.,.]=OV,RV
}
end
exit

