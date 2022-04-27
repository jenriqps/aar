/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Requerimiento de Capital por Riesgos Tecnicos y Financieros de Seguros
This exercise is based on Exercise 2 of Chapter 4
*/


/*
Simulating values
*/

proc iml;
	* Fixing the seed of random numbers for replicability;
	call randseed(2020);
	* Number of simulations;
	N = 100000;
	muA = 0;
	muP = 0;
	* Vector of standard deviations for assets and liabilities, respectively;
	sigma = {500 500};
	* Independent normal standard numbers for Assets (A);
	ZA = j(N,1);
	call randgen(ZA,"Normal",0,1);
	* Independent normal standard numbers for liabilities (P);
	ZP = j(N,1);
	call randgen(ZP,"Normal",0,1);
	* Mixing the two previous vectors in a matrix;
	Z = ZA||ZP;

	* Correlation matrix;
	R = {1 0.25,0.25 1};
	
	* Choleski decomposition;
	L = t(root(R));
	
	* Correlating the independent normal standard numbers;	
	LZ = L*Z`;
	
	*print LZ;
	
	* Calculating the asset loss;
	LA = sigma[1] * LZ[1, ]; 
	*print LA;

	* Calculating the liability loss;
	LP = sigma[2] * LZ[2, ]; 
	*print LP;
	
	L = LA` + LP`;
	
	LAP = LA`||LP`||L;

	create work.totalLoss from LAP;
	append from LAP;
	close work.totalLoss;
	
	* Copula t-student;
	
	* Gamma random numbers;
	g = j(N,1);
	call randgen(g,"Gamma",1,2);
	*print g;
	
	* t-student random numbers;
	t = t(LZ[1,])#((1/(g/2))##0.5)||t(LZ[2,])#((1/(g/2))##0.5);
	*print t;
	
	* Cumulative probabilities computed with t-student distribution;
	vt = cdf('T',t,2);
	*print vt;
	
	* Percentiles of the marginal distributions ;
	LA_t = quantile('NORMAL',vt[,1],0,sigma[1]);
	LP_t = quantile('NORMAL',vt[,2],0,sigma[2]);
	
	*print LA_t LP_t;
	
	L_t = LA_t + LP_t;
	
	*print L_t;
	
	LAP_t = LA_t || LP_t || L_t;
	
	*print LAP_t;
	
	create work.totalLoss_t from LAP_t;
	append from LAP_t;
	close work.totalLoss_t;
	
run;

proc datasets lib=work nolist nodetails;
	modify totalLoss;
	rename col1=LA col2=LP col3=totalLoss;
	format LA LP totalLoss comma10.2;
	label LA="Asset loss (LA)" LP="Liability loss (LP)" totalLoss = "Total loss (LA + LP)";
	modify totalLoss_t;
	rename col1=LA col2=LP col3=totalLoss;
	format LA LP totalLoss comma10.2;
	label LA="Asset loss (LA)" LP="Liability loss (LP)" totalLoss = "Total loss (LA + LP)";
quit;

ods graphics / reset imagemap noborder;

title "Distribución conjunta de las pérdidas y ganancias de los activos y pasivos (cópula gaussiana)";
title2 "Mapa de calor";
proc sgplot data=work.totalLoss;
 	heatmap x = LA y = LP;
 	xaxis grid;
	yaxis grid;
run;

proc univariate data=work.totalLoss pctldef=1;
	var totalLoss;
	output out=work.var PCTLPRE=p pctlpts=0.005;
run;

title "Distribución conjunta de las pérdidas y ganancias de los activos y pasivos (cópula t)";
title2 "Mapa de calor";
proc sgplot data=work.totalLoss_t;
 	heatmap x = LA y = LP;
 	xaxis grid;
	yaxis grid;
run;

proc univariate data=work.totalLoss_t pctldef=1;
	var totalLoss;
	output out=work.var_t PCTLPRE=p pctlpts=0.005;
run;


title "Requerimiento de Capital por Riesgos Técnicos y Financieros de Seguros (cópula gaussiana)";
proc sql;
	select * into: var
 	from work.var
 	;
quit;

%put &=var.;

title "Expected Shortfall";
proc sql;
	select mean(totalLoss) into: es
 	from work.totalLoss
 	where totalLoss < &var.
 	;
run;

%put &=es.;

title 'Pérdida total';
title2 "Histograma";
proc sgplot data=work.totalLoss;
 	histogram totalLoss / fillattrs=(color=green transparency=0.97);
 	density totalLoss / lineattrs=(color=red);
  	refline &var. / axis=x lineattrs=(color=red pattern=15) label = ("RCTyFS = &var.");
  	refline &es. / axis=x lineattrs=(color=blue pattern=15) label = ("Expected Shortfall = &es.");
 	xaxis grid;
	yaxis grid;
run;

title "Requerimiento de Capital por Riesgos Técnicos y Financieros de Seguros (cópula t)";
proc sql;
	select * into: var
 	from work.var_t
 	;
quit;

%put &=var.;

title "Expected Shortfall";
proc sql;
	select mean(totalLoss) into: es
 	from work.totalLoss_t
 	where totalLoss < &var.
 	;
run;

%put &=es.;

title 'Pérdida total';
title2 "Histograma";
proc sgplot data=work.totalLoss_t;
 	histogram totalLoss / fillattrs=(color=green transparency=0.97);
 	density totalLoss / lineattrs=(color=red);
  	refline &var. / axis=x lineattrs=(color=red pattern=15) label = ("RCTyFS = &var.");
  	refline &es. / axis=x lineattrs=(color=blue pattern=15) label = ("Expected Shortfall = &es.");
 	xaxis grid;
	yaxis grid;
run;



