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
	N = 10000;
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
	
	*print LZ[1, ];
	
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
run;

proc datasets lib=work nolist nodetails;
	modify totalLoss;
	rename col1=LA col2=LP col3=totalLoss;
	format LA LP totalLoss comma10.2;
	label LA="Asset loss (LA)" LP="Liability loss (LP)" totalLoss = "Total loss (LA + LP)";
run;

ods graphics / reset width=6.4in height=6in imagemap noborder;


proc sgplot data=work.totalLoss;
 	scatter x = LA y = LP;
 	xaxis grid;
	yaxis grid;
run;



title 'Histograma';
proc sgplot data=work.totalLoss;
 	histogram totalLoss / fillattrs=(color=blue transparency=0.97);
 	density totalLoss / lineattrs=(color=red);
 	xaxis grid;
	yaxis grid;
run;

proc univariate data=work.totalLoss pctldef=1 noprint;
	var totalLoss;
	output out=work.var PCTLPRE=p pctlpts=0.005;
run;



